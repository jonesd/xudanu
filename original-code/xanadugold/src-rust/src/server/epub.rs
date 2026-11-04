//! In-house EPUB reader for the import path. An EPUB is a ZIP with a
//! `mimetype` entry, a `META-INF/container.xml` pointing at the OPF
//! package, and the OPF's spine giving the reading order. Replaces
//! the dormant epub-parser crate (0.3.4, last release 2026-02), whose
//! zip ^2 pin carried the critical zip advisories with no fixed
//! release in sight; built instead on zip 9 and quick-xml, both MIT
//! and both already in the dependency graph.

use std::collections::HashMap;
use std::io::Read;

use quick_xml::events::Event;

/// Uncompressed caps for wire-facing input: decompression bombs are
/// refused before extraction, not after.
const MAX_ENTRY_BYTES: u64 = 64 << 20;
const MAX_TEXT_BYTES: usize = 64 << 20;

const SKIP_ELEMENTS: [&[u8]; 3] = [b"head", b"style", b"script"];
const BLOCK_ELEMENTS: [&[u8]; 10] = [
    b"p", b"div", b"h1", b"h2", b"h3", b"h4", b"h5", b"h6", b"li", b"tr",
];

#[derive(Debug)]
pub struct Epub {
    pub title: Option<String>,
    pub author: Option<String>,
    /// Chapter text in spine (reading) order.
    pub pages: Vec<String>,
}

pub fn parse(data: &[u8]) -> Result<Epub, String> {
    let mut zip = zip::ZipArchive::new(std::io::Cursor::new(data))
        .map_err(|e| format!("not a ZIP archive: {e}"))?;
    let mimetype = read_entry(&mut zip, "mimetype").map_err(|_| "no mimetype entry".to_string())?;
    if mimetype.trim() != "application/epub+zip" {
        return Err(format!("not an EPUB: mimetype is {mimetype:?}"));
    }
    let container = read_entry(&mut zip, "META-INF/container.xml")?;
    let opf_path = container_rootfile(&container)?;
    let opf = parse_opf(&read_entry(&mut zip, &opf_path)?);
    let dir = match opf_path.rfind('/') {
        Some(i) => &opf_path[..i],
        None => "",
    };
    let mut pages = Vec::new();
    let mut total = 0usize;
    for idref in &opf.spine {
        let href = opf
            .manifest
            .get(idref)
            .ok_or_else(|| format!("spine idref {idref:?} is not in the manifest"))?;
        let path = resolve_href(dir, href);
        let xml =
            read_entry(&mut zip, &path).map_err(|e| format!("spine document {path:?}: {e}"))?;
        let text = extract_text(&xml)?;
        total += text.len();
        if total > MAX_TEXT_BYTES {
            return Err(format!("spine text exceeds {MAX_TEXT_BYTES} bytes"));
        }
        pages.push(text);
    }
    Ok(Epub {
        title: opf.title,
        author: opf.author,
        pages,
    })
}

fn read_entry(
    zip: &mut zip::ZipArchive<std::io::Cursor<&[u8]>>,
    name: &str,
) -> Result<String, String> {
    let mut file = zip.by_name(name).map_err(|e| format!("{name:?}: {e}"))?;
    if file.size() > MAX_ENTRY_BYTES {
        return Err(format!(
            "{name:?} declares {} uncompressed bytes (cap {MAX_ENTRY_BYTES})",
            file.size()
        ));
    }
    let mut bytes = Vec::with_capacity(file.size().min(1 << 20) as usize);
    file.read_to_end(&mut bytes)
        .map_err(|e| format!("reading {name:?}: {e}"))?;
    if bytes.len() as u64 > MAX_ENTRY_BYTES {
        return Err(format!("{name:?} exceeds {MAX_ENTRY_BYTES} bytes"));
    }
    String::from_utf8(bytes).map_err(|e| format!("{name:?} is not UTF-8: {e}"))
}

fn local_is(name: &quick_xml::name::LocalName, wanted: &[u8]) -> bool {
    name.as_ref() == wanted
}

/// The OPF path from `META-INF/container.xml`'s `rootfile` element.
fn container_rootfile(xml: &str) -> Result<String, String> {
    let mut reader = quick_xml::Reader::from_str(xml);
    let mut buf = Vec::new();
    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(e)) | Ok(Event::Empty(e)) => {
                if local_is(&e.name().local_name(), b"rootfile") {
                    for attr in e.attributes().flatten() {
                        if attr.key.as_ref() == b"full-path" {
                            return attr
                                .unescape_value()
                                .map(|v| v.into_owned())
                                .map_err(|e| format!("container.xml: {e}"));
                        }
                    }
                }
            }
            Ok(Event::Eof) => break,
            Err(e) => return Err(format!("container.xml: {e}")),
            _ => {}
        }
        buf.clear();
    }
    Err("container.xml declares no rootfile".into())
}

struct Opf {
    title: Option<String>,
    author: Option<String>,
    /// manifest item id -> href (relative to the OPF's directory).
    manifest: HashMap<String, String>,
    /// manifest ids in spine order.
    spine: Vec<String>,
}

#[derive(Clone, Copy)]
enum MetaText {
    Title,
    Creator,
}

/// manifest item id -> href, from either form of the element.
fn manifest_item(e: &quick_xml::events::BytesStart) -> Option<(String, String)> {
    let mut id = None;
    let mut href = None;
    for attr in e.attributes().flatten() {
        match attr.key.as_ref() {
            b"id" => id = attr.unescape_value().ok().map(|v| v.into_owned()),
            b"href" => href = attr.unescape_value().ok().map(|v| v.into_owned()),
            _ => {}
        }
    }
    Some((id?, href?))
}

fn itemref_id(e: &quick_xml::events::BytesStart) -> Option<String> {
    e.attributes()
        .flatten()
        .find(|a| a.key.as_ref() == b"idref")
        .and_then(|a| a.unescape_value().ok().map(|v| v.into_owned()))
}

fn parse_opf(xml: &str) -> Opf {
    let mut opf = Opf {
        title: None,
        author: None,
        manifest: HashMap::new(),
        spine: Vec::new(),
    };
    let mut reader = quick_xml::Reader::from_str(xml);
    let mut buf = Vec::new();
    let mut pending: Option<MetaText> = None;
    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(e)) => match e.name().local_name().as_ref() {
                b"item" => {
                    if let Some((id, href)) = manifest_item(&e) {
                        opf.manifest.entry(id).or_insert(href);
                    }
                }
                b"itemref" => {
                    if let Some(idref) = itemref_id(&e) {
                        opf.spine.push(idref);
                    }
                }
                b"title" => pending = Some(MetaText::Title),
                b"creator" => pending = Some(MetaText::Creator),
                _ => {}
            },
            Ok(Event::Empty(e)) => match e.name().local_name().as_ref() {
                b"item" => {
                    if let Some((id, href)) = manifest_item(&e) {
                        opf.manifest.entry(id).or_insert(href);
                    }
                }
                b"itemref" => {
                    if let Some(idref) = itemref_id(&e) {
                        opf.spine.push(idref);
                    }
                }
                _ => {}
            },
            Ok(Event::Text(t)) => {
                if let Some(target) = pending.take() {
                    if let Ok(text) = t.unescape() {
                        let trimmed = text.trim();
                        if !trimmed.is_empty() {
                            match target {
                                MetaText::Title if opf.title.is_none() => {
                                    opf.title = Some(trimmed.to_string())
                                }
                                MetaText::Creator if opf.author.is_none() => {
                                    opf.author = Some(trimmed.to_string())
                                }
                                _ => {}
                            }
                        }
                    }
                }
            }
            Ok(Event::End(_)) => pending = None,
            Ok(Event::Eof) => break,
            Err(_) => break,
            _ => {}
        }
        buf.clear();
    }
    opf
}

/// Manifest hrefs are relative to the OPF's directory, URL-encoded,
/// and may carry a fragment.
fn resolve_href(dir: &str, href: &str) -> String {
    let no_fragment = match href.find('#') {
        Some(i) => &href[..i],
        None => href,
    };
    let decoded = percent_decode(no_fragment);
    if dir.is_empty() || decoded.starts_with('/') {
        decoded
    } else {
        format!("{dir}/{decoded}")
    }
}

fn percent_decode(s: &str) -> String {
    let bytes = s.as_bytes();
    let mut out = Vec::with_capacity(bytes.len());
    let mut i = 0;
    while i < bytes.len() {
        if bytes[i] == b'%' && i + 2 < bytes.len() {
            let hex = std::str::from_utf8(&bytes[i + 1..i + 3])
                .ok()
                .and_then(|h| u8::from_str_radix(h, 16).ok());
            match hex {
                Some(b) => {
                    out.push(b);
                    i += 3;
                }
                None => {
                    out.push(bytes[i]);
                    i += 1;
                }
            }
        } else {
            out.push(bytes[i]);
            i += 1;
        }
    }
    String::from_utf8_lossy(&out).into_owned()
}

/// Plain text from an XHTML content document: text nodes with
/// entities resolved, head/style/script dropped, block boundaries
/// kept as newlines.
fn extract_text(xml: &str) -> Result<String, String> {
    let mut out = String::new();
    let mut reader = quick_xml::Reader::from_str(xml);
    let mut buf = Vec::new();
    let mut skip_depth: usize = 0;
    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(e)) => {
                let name = e.name().local_name();
                if SKIP_ELEMENTS.iter().any(|s| local_is(&name, s)) {
                    skip_depth += 1;
                }
            }
            Ok(Event::Empty(e)) => {
                if local_is(&e.name().local_name(), b"br") {
                    out.push('\n');
                }
            }
            Ok(Event::Text(t)) => {
                if skip_depth == 0 {
                    out.push_str(&t.unescape().map_err(|e| format!("content text: {e}"))?);
                }
            }
            Ok(Event::CData(c)) => {
                if skip_depth == 0 {
                    out.push_str(&String::from_utf8_lossy(c.as_ref()));
                }
            }
            Ok(Event::End(e)) => {
                let name = e.name().local_name();
                if SKIP_ELEMENTS.iter().any(|s| local_is(&name, s)) {
                    skip_depth = skip_depth.saturating_sub(1);
                } else if BLOCK_ELEMENTS.iter().any(|s| local_is(&name, s)) {
                    out.push('\n');
                }
            }
            Ok(Event::Eof) => break,
            Err(e) => return Err(format!("content document: {e}")),
            _ => {}
        }
        buf.clear();
    }
    Ok(out)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn build_epub(entries: &[(&str, &[u8])]) -> Vec<u8> {
        use std::io::Write;
        let mut zip = zip::ZipWriter::new(std::io::Cursor::new(Vec::new()));
        let options: zip::write::FileOptions<'_, '_, ()> =
            zip::write::FileOptions::default().compression_method(zip::CompressionMethod::Stored);
        for (name, data) in entries {
            zip.start_file(name, options).unwrap();
            zip.write_all(data).unwrap();
        }
        zip.finish().unwrap().into_inner()
    }

    const CONTAINER: &str = r#"<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>"#;

    #[test]
    fn parses_metadata_spine_text() {
        let opf = r#"<?xml version="1.0"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="uid">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>Cats &amp; Dogs</dc:title>
    <dc:creator>Jane Author</dc:creator>
  </metadata>
  <manifest>
    <item id="c2" href="ch2.xhtml" media-type="application/xhtml+xml"/>
    <item id="c1" href="ch%201.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine>
    <itemref idref="c1"/>
    <itemref idref="c2"/>
  </spine>
</package>"#;
        let ch1 = r#"<html xmlns="http://www.w3.org/1999/xhtml"><head><title>head title skipped</title><style>p { color: red }</style></head><body><p>First chapter.</p></body></html>"#;
        let ch2 = r#"<html xmlns="http://www.w3.org/1999/xhtml"><body><p>Second <em>chapter</em>.</p><br/>After the break.</body></html>"#;
        let bytes = build_epub(&[
            ("mimetype", b"application/epub+zip"),
            ("META-INF/container.xml", CONTAINER.as_bytes()),
            ("OEBPS/content.opf", opf.as_bytes()),
            ("OEBPS/ch 1.xhtml", ch1.as_bytes()),
            ("OEBPS/ch2.xhtml", ch2.as_bytes()),
        ]);
        let epub = parse(&bytes).expect("parses");
        assert_eq!(epub.title.as_deref(), Some("Cats & Dogs"));
        assert_eq!(epub.author.as_deref(), Some("Jane Author"));
        assert_eq!(epub.pages.len(), 2, "spine order is the page order");
        assert!(epub.pages[0].contains("First chapter."));
        assert!(
            !epub.pages[0].contains("head title skipped") && !epub.pages[0].contains("color: red"),
            "head and style content are dropped: {:?}",
            epub.pages[0]
        );
        assert!(
            epub.pages[1].contains("Second chapter."),
            "inline tags keep their spacing: {:?}",
            epub.pages[1]
        );
        assert!(epub.pages[1].contains("After the break."));
    }

    #[test]
    fn rejects_non_zip_input() {
        assert!(parse(b"this is not an epub").is_err());
    }

    #[test]
    fn rejects_zip_without_epub_mimetype() {
        let bytes = build_epub(&[("readme.txt", b"hello")]);
        let err = parse(&bytes).expect_err("a plain zip is not an epub");
        assert!(err.contains("mimetype"), "{err}");
    }

    #[test]
    fn rejects_container_without_rootfile() {
        let bytes = build_epub(&[
            ("mimetype", b"application/epub+zip"),
            ("META-INF/container.xml", b"<container></container>"),
        ]);
        let err = parse(&bytes).expect_err("no rootfile");
        assert!(err.contains("rootfile"), "{err}");
    }
}
