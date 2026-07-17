// Xudanu Documentation Auto-Linker
// Scans <code> elements for source file references and wraps them in
// GitHub links. Include this script at the bottom of any doc page.
(function() {
  var RUST_BASE = 'original-code/xanadugold/src-rust/';
  var WEB_BASE = 'web/app/';

  // Map of short filenames to full paths relative to repo root
  var FILE_MAP = {
    // Rust - server
    'server.rs': RUST_BASE + 'src/server/server.rs',
    'otree_crdt.rs': RUST_BASE + 'src/server/otree_crdt.rs',
    'rate_limiter.rs': RUST_BASE + 'src/server/rate_limiter.rs',
    'federation.rs': RUST_BASE + 'src/server/federation.rs',
    'federation_active.rs': RUST_BASE + 'src/server/transport/federation_active.rs',
    'identity.rs': RUST_BASE + 'src/server/identity.rs',
    'keymaster.rs': RUST_BASE + 'src/server/keymaster.rs',
    'lock.rs': RUST_BASE + 'src/server/lock.rs',
    'session.rs': RUST_BASE + 'src/server/session.rs',
    'admin.rs': RUST_BASE + 'src/server/admin.rs',
    'ollama.rs': RUST_BASE + 'src/server/ollama.rs',
    'historical_author.rs': RUST_BASE + 'src/server/historical_author.rs',
    'detector.rs': RUST_BASE + 'src/server/detector.rs',
    'club.rs': RUST_BASE + 'src/server/club.rs',
    'source_matcher.rs': RUST_BASE + 'src/server/source_matcher.rs',
    // Rust - transport
    'handler.rs': RUST_BASE + 'src/server/transport/handler.rs',
    'dispatch.rs': RUST_BASE + 'src/server/transport/dispatch.rs',
    'codec.rs': RUST_BASE + 'src/server/transport/codec.rs',
    'protocol.rs': RUST_BASE + 'src/server/transport/protocol.rs',
    'channel.rs': RUST_BASE + 'src/server/transport/channel.rs',
    'federation_handler.rs': RUST_BASE + 'src/server/transport/federation_handler.rs',
    'chained_log.rs': RUST_BASE + 'src/server/transport/chained_log.rs',
    'audit.rs': RUST_BASE + 'src/server/transport/audit.rs',
    'attribution_log.rs': RUST_BASE + 'src/server/transport/attribution_log.rs',
    'shared.rs': RUST_BASE + 'src/server/transport/shared.rs',
    // Rust - edition
    'edition.rs': RUST_BASE + 'src/edition/edition.rs',
    'orgl.rs': RUST_BASE + 'src/edition/orgl.rs',
    'canopy.rs': RUST_BASE + 'src/edition/canopy.rs',
    'backfollow.rs': RUST_BASE + 'src/edition/backfollow.rs',
    'three_way.rs': RUST_BASE + 'src/edition/three_way.rs',
    'provenance.rs': RUST_BASE + 'src/edition/provenance.rs',
    'content_address.rs': RUST_BASE + 'src/edition/content_address.rs',
    'range_element.rs': RUST_BASE + 'src/edition/range_element.rs',
    'transclusion.rs': RUST_BASE + 'src/edition/transclusion.rs',
    'links.rs': RUST_BASE + 'src/edition/links.rs',
    'wrapper.rs': RUST_BASE + 'src/edition/wrapper.rs',
    'shared_mapping.rs': RUST_BASE + 'src/edition/shared_mapping.rs',
    'grandmap.rs': RUST_BASE + 'src/edition/grandmap.rs',
    'range_transclusion.rs': RUST_BASE + 'src/edition/range_transclusion.rs',
    'bundle.rs': RUST_BASE + 'src/edition/bundle.rs',
    // Rust - space
    // Rust - crypto
    'aead.rs': RUST_BASE + 'src/crypto/aead.rs',
    'sign.rs': RUST_BASE + 'src/crypto/sign.rs',
    'kex.rs': RUST_BASE + 'src/crypto/kex.rs',
    'kdf.rs': RUST_BASE + 'src/crypto/kdf.rs',
    'password.rs': RUST_BASE + 'src/crypto/password.rs',
    'keys.rs': RUST_BASE + 'src/crypto/keys.rs',
    'server_identity.rs': RUST_BASE + 'src/crypto/server_identity.rs',
    // Rust - persist
    'manifest.rs': RUST_BASE + 'src/persist/manifest.rs',
    'chunk_store.rs': RUST_BASE + 'src/persist/chunk_store.rs',
    'wal.rs': RUST_BASE + 'src/persist/wal.rs',
    'edition_chunks.rs': RUST_BASE + 'src/persist/edition_chunks.rs',
    'migrations.rs': RUST_BASE + 'src/persist/migrations.rs',
    'packer.rs': RUST_BASE + 'src/persist/packer.rs',
    'verify.rs': RUST_BASE + 'src/persist/verify.rs',
    // Rust - ent
    'dagwood.rs': RUST_BASE + 'src/ent/dagwood.rs',
    'htree.rs': RUST_BASE + 'src/ent/htree.rs',
    'trace.rs': RUST_BASE + 'src/ent/trace.rs',
    // Rust - bin
    'xudanu-server.rs': RUST_BASE + 'src/bin/xudanu-server.rs',
    'xudanu-cli.rs': RUST_BASE + 'src/bin/xudanu-cli.rs',
    // Rust - crate roots
    'lib.rs': RUST_BASE + 'src/lib.rs',
    'wasm.rs': RUST_BASE + 'src/wasm.rs',
    'Cargo.toml': RUST_BASE + 'Cargo.toml',
    // Frontend
    'crdt_sync.ts': WEB_BASE + 'src/api/crdt_sync.ts',
    'useCrdtSync.ts': WEB_BASE + 'src/hooks/useCrdtSync.ts',
    'useTransclusion.ts': WEB_BASE + 'src/hooks/useTransclusion.ts',
    'useCompoundEdition.ts': WEB_BASE + 'src/hooks/useCompoundEdition.ts',
    'CollaborativeEditor.tsx': WEB_BASE + 'src/components/CollaborativeEditor.tsx',
    'AppShell.tsx': WEB_BASE + 'src/components/shell/AppShell.tsx',
    'ConnectionsSection.tsx': WEB_BASE + 'src/components/panels/ConnectionsSection.tsx',
    'ContextPanel.tsx': WEB_BASE + 'src/components/shell/ContextPanel.tsx',
    'CompoundPanel.tsx': WEB_BASE + 'src/components/CompoundPanel.tsx',
    'CompoundBuilder.tsx': WEB_BASE + 'src/components/CompoundBuilder.tsx',
    'PerspectiveView.tsx': WEB_BASE + 'src/components/PerspectiveView.tsx',
    'AdminDashboard.tsx': WEB_BASE + 'src/components/AdminDashboard.tsx',
    'RelatedFooter.tsx': WEB_BASE + 'src/components/RelatedFooter.tsx',
    'LinkCreator.tsx': WEB_BASE + 'src/components/LinkCreator.tsx',
    'ComparePanel.tsx': WEB_BASE + 'src/components/ComparePanel.tsx',
    'link-markers.ts': WEB_BASE + 'src/link-markers.ts',
    'app-shell.css': WEB_BASE + 'src/app-shell.css',
  };

  function makeLink(href, text) {
    var a = document.createElement('a');
    a.href = href;
    a.textContent = text;
    a.target = '_blank';
    a.rel = 'noopener noreferrer';
    a.style.color = '#58a6ff';
    a.style.textDecoration = 'none';
    a.style.borderBottom = '1px dotted rgba(88,166,255,0.4)';
    return a;
  }

  function linkifyNode(node) {
    if (node.nodeType !== Node.TEXT_NODE) return;

    var text = node.textContent;
    var found = [];

    // Pattern 1: file.rs:line or file.tsx:line or file.ts:line
    var pattern1 = /([a-z_][a-z0-9_./-]*\.(rs|ts|tsx|css|toml)):(\d+)/g;
    // Pattern 2: src/path/file.rs or web/app/src/...
    var pattern2 = /((?:src|web\/app\/src)\/[a-z0-9_./-]+\.(rs|ts|tsx|css))/g;
    // Pattern 3: standalone filename.ext
    var pattern3 = /([a-z_][a-z0-9_-]*\.(rs|ts|tsx|css|toml))\b/g;

    // Collect all matches
    var collect = function(regex, resolver) {
      var m;
      while ((m = regex.exec(text)) !== null) {
        var path = resolver(m);
        if (path) {
          found.push({ start: m.index, end: m.index + m[0].length, text: m[0], path: path });
        }
      }
    };

    collect(pattern1, function(m) {
      var basename = m[1].split('/').pop();
      var mapped = FILE_MAP[basename] || FILE_MAP[m[1]];
      if (mapped) return mapped + '#L' + m[3];
      return null;
    });

    collect(pattern2, function(m) {
      if (m[1].startsWith('src/')) return RUST_BASE + m[1];
      return m[1];
    });

    collect(pattern3, function(m) {
      var mapped = FILE_MAP[m[1]];
      if (mapped) return mapped;
      return null;
    });

    if (found.length === 0) return;

    // Sort by position and remove overlaps
    found.sort(function(a, b) { return a.start - b.start; });
    var filtered = [];
    var lastEnd = -1;
    for (var i = 0; i < found.length; i++) {
      if (found[i].start >= lastEnd) {
        filtered.push(found[i]);
        lastEnd = found[i].end;
      }
    }

    // Build replacement nodes
    var parent = node.parentNode;
    var frag = document.createDocumentFragment();
    var pos = 0;
    for (var j = 0; j < filtered.length; j++) {
      var f = filtered[j];
      if (f.start > pos) {
        frag.appendChild(document.createTextNode(text.slice(pos, f.start)));
      }
      frag.appendChild(makeLink(f.path, f.text));
      pos = f.end;
    }
    if (pos < text.length) {
      frag.appendChild(document.createTextNode(text.slice(pos)));
    }
    parent.replaceChild(frag, node);
  }

  function processAll() {
    var codes = document.querySelectorAll('code');
    for (var i = 0; i < codes.length; i++) {
      var code = codes[i];
      if (code.children.length === 0) {
        // Simple text node - process directly
        for (var j = 0; j < code.childNodes.length; j++) {
          linkifyNode(code.childNodes[j]);
        }
      } else {
        // Has child elements - process text nodes within
        var walker = document.createTreeWalker(code, NodeFilter.SHOW_TEXT, null);
        var textNodes = [];
        while (walker.nextNode()) textNodes.push(walker.currentNode);
        for (var k = 0; k < textNodes.length; k++) {
          linkifyNode(textNodes[k]);
        }
      }
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', processAll);
  } else {
    processAll();
  }
})();
