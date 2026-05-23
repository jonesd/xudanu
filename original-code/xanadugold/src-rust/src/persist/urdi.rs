use std::io::{self, Read, Seek, SeekFrom, Write};
use std::path::Path;

const FILE_MAGIC: [u8; 4] = *b"XUD1";
const GUARD_MAGIC: [u8; 4] = *b"XNSR";
const FILE_HEADER_SIZE: usize = 32;
const GUARD_SIZE: usize = 32;
const GUARD_VALID_FLAG: u32 = 1;

fn fnv1a_32(data: &[u8]) -> u32 {
    let mut hash: u32 = 0x811c9dc5;
    for &byte in data {
        hash ^= byte as u32;
        hash = hash.wrapping_mul(0x01000193);
    }
    hash
}

#[derive(Debug, Clone)]
pub struct UrdiHeader {
    pub snarf_size: u32,
    pub snarf_count: u32,
    pub stage_count: u32,
    pub data_start: u32,
}

impl UrdiHeader {
    fn to_bytes(&self) -> [u8; FILE_HEADER_SIZE] {
        let mut buf = [0u8; FILE_HEADER_SIZE];
        buf[0..4].copy_from_slice(&FILE_MAGIC);
        buf[4..8].copy_from_slice(&1u32.to_le_bytes());
        buf[8..12].copy_from_slice(&self.snarf_size.to_le_bytes());
        buf[12..16].copy_from_slice(&self.snarf_count.to_le_bytes());
        buf[16..20].copy_from_slice(&self.stage_count.to_le_bytes());
        buf[20..24].copy_from_slice(&self.data_start.to_le_bytes());
        let crc = fnv1a_32(&buf[0..24]);
        buf[24..28].copy_from_slice(&crc.to_le_bytes());
        buf
    }

    fn from_bytes(data: &[u8]) -> io::Result<Self> {
        if data.len() < FILE_HEADER_SIZE {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "header too short",
            ));
        }
        if data[0..4] != FILE_MAGIC {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "bad magic"));
        }
        let stored_crc = u32::from_le_bytes(data[24..28].try_into().unwrap());
        let computed_crc = fnv1a_32(&data[0..24]);
        if stored_crc != computed_crc {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "header checksum mismatch",
            ));
        }
        let version = u32::from_le_bytes(data[4..8].try_into().unwrap());
        if version != 1 {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!("unsupported version {}", version),
            ));
        }
        Ok(UrdiHeader {
            snarf_size: u32::from_le_bytes(data[8..12].try_into().unwrap()),
            snarf_count: u32::from_le_bytes(data[12..16].try_into().unwrap()),
            stage_count: u32::from_le_bytes(data[16..20].try_into().unwrap()),
            data_start: u32::from_le_bytes(data[20..24].try_into().unwrap()),
        })
    }
}

#[derive(Debug)]
struct Guard {
    snarf_id: u32,
    cycle: u32,
    data_len: u32,
    data_hash: u32,
    flags: u32,
}

impl Guard {
    fn new(snarf_id: u32, cycle: u32, data: &[u8]) -> Self {
        Guard {
            snarf_id,
            cycle,
            data_len: data.len() as u32,
            data_hash: fnv1a_32(data),
            flags: GUARD_VALID_FLAG,
        }
    }

    fn to_bytes(&self) -> [u8; GUARD_SIZE] {
        let mut buf = [0u8; GUARD_SIZE];
        buf[0..4].copy_from_slice(&GUARD_MAGIC);
        buf[4..8].copy_from_slice(&self.snarf_id.to_le_bytes());
        buf[8..12].copy_from_slice(&self.cycle.to_le_bytes());
        buf[12..16].copy_from_slice(&self.data_len.to_le_bytes());
        buf[16..20].copy_from_slice(&self.data_hash.to_le_bytes());
        buf[20..24].copy_from_slice(&self.flags.to_le_bytes());
        let crc = fnv1a_32(&buf[0..24]);
        buf[24..28].copy_from_slice(&crc.to_le_bytes());
        buf
    }

    fn from_bytes(data: &[u8]) -> io::Result<Self> {
        if data.len() < GUARD_SIZE {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "guard too short",
            ));
        }
        if data[0..4] != GUARD_MAGIC {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "bad guard magic",
            ));
        }
        let stored_crc = u32::from_le_bytes(data[24..28].try_into().unwrap());
        let computed_crc = fnv1a_32(&data[0..24]);
        if stored_crc != computed_crc {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                "guard checksum mismatch",
            ));
        }
        Ok(Guard {
            snarf_id: u32::from_le_bytes(data[4..8].try_into().unwrap()),
            cycle: u32::from_le_bytes(data[8..12].try_into().unwrap()),
            data_len: u32::from_le_bytes(data[12..16].try_into().unwrap()),
            data_hash: u32::from_le_bytes(data[16..20].try_into().unwrap()),
            flags: u32::from_le_bytes(data[20..24].try_into().unwrap()),
        })
    }

    fn is_valid(&self) -> bool {
        self.flags & GUARD_VALID_FLAG != 0
    }
}

#[derive(Debug)]
pub struct UrdiFile {
    file: std::fs::File,
    header: UrdiHeader,
    cycles: Vec<u32>,
}

impl UrdiFile {
    pub fn create(
        path: &Path,
        snarf_size: u32,
        initial_count: u32,
        stage_count: u32,
        data_start: u32,
    ) -> io::Result<Self> {
        let header = UrdiHeader {
            snarf_size,
            snarf_count: initial_count,
            stage_count,
            data_start,
        };
        let mut file = std::fs::OpenOptions::new()
            .read(true)
            .write(true)
            .create(true)
            .truncate(true)
            .open(path)?;
        file.write_all(&header.to_bytes())?;

        let slot_size = GUARD_SIZE + snarf_size as usize;
        file.set_len(FILE_HEADER_SIZE as u64 + initial_count as u64 * slot_size as u64)?;
        file.flush()?;

        let cycles = vec![0u32; initial_count as usize];
        Ok(UrdiFile {
            file,
            header,
            cycles,
        })
    }

    pub fn open(path: &Path) -> io::Result<Self> {
        let mut file = std::fs::OpenOptions::new()
            .read(true)
            .write(true)
            .open(path)?;
        let mut header_buf = [0u8; FILE_HEADER_SIZE];
        file.read_exact(&mut header_buf)?;
        let header = UrdiHeader::from_bytes(&header_buf)?;

        let mut cycles = vec![0u32; header.snarf_count as usize];
        for i in 0..header.snarf_count {
            if let Ok(guard) = Self::read_guard_at(&mut file, i, header.snarf_size) {
                cycles[i as usize] = guard.cycle;
            }
        }

        Ok(UrdiFile {
            file,
            header,
            cycles,
        })
    }

    pub fn header(&self) -> &UrdiHeader {
        &self.header
    }

    pub fn snarf_size(&self) -> usize {
        self.header.snarf_size as usize
    }

    pub fn snarf_count(&self) -> u32 {
        self.header.snarf_count
    }

    pub fn stage_count(&self) -> u32 {
        self.header.stage_count
    }

    pub fn data_start(&self) -> u32 {
        self.header.data_start
    }

    pub fn read_snarf(&mut self, snarf_id: u32) -> io::Result<Option<Vec<u8>>> {
        if snarf_id >= self.header.snarf_count {
            return Ok(None);
        }
        let guard = Self::read_guard_at(&mut self.file, snarf_id, self.header.snarf_size)?;
        if !guard.is_valid() || guard.data_len == 0 {
            return Ok(None);
        }
        if guard.snarf_id != snarf_id {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!(
                    "guard snarf_id mismatch: expected {} got {}",
                    snarf_id, guard.snarf_id
                ),
            ));
        }
        let data_offset = Self::slot_offset(snarf_id, self.header.snarf_size) + GUARD_SIZE as u64;
        self.file.seek(SeekFrom::Start(data_offset))?;
        let mut data = vec![0u8; guard.data_len as usize];
        self.file.read_exact(&mut data)?;

        let hash = fnv1a_32(&data);
        if hash != guard.data_hash {
            return Err(io::Error::new(
                io::ErrorKind::InvalidData,
                format!("snarf {} data hash mismatch", snarf_id),
            ));
        }
        self.cycles[snarf_id as usize] = guard.cycle;
        Ok(Some(data))
    }

    pub fn write_snarf(&mut self, snarf_id: u32, data: &[u8]) -> io::Result<()> {
        if data.len() > self.header.snarf_size as usize {
            return Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                format!(
                    "data {}B exceeds snarf_size {}B",
                    data.len(),
                    self.header.snarf_size
                ),
            ));
        }
        if snarf_id >= self.header.snarf_count {
            self.extend_to(snarf_id + 1)?;
        }
        let cycle = self.cycles[snarf_id as usize].wrapping_add(1);
        self.cycles[snarf_id as usize] = cycle;

        let guard = Guard::new(snarf_id, cycle, data);
        let slot_offset = Self::slot_offset(snarf_id, self.header.snarf_size);
        self.file.seek(SeekFrom::Start(slot_offset))?;
        self.file.write_all(&guard.to_bytes())?;

        let data_offset = slot_offset + GUARD_SIZE as u64;
        self.file.seek(SeekFrom::Start(data_offset))?;
        self.file.write_all(data)?;

        if data.len() < self.header.snarf_size as usize {
            let zero_start = data_offset + data.len() as u64;
            let zero_end = data_offset + self.header.snarf_size as u64;
            self.file.seek(SeekFrom::Start(zero_start))?;
            let zeros = vec![0u8; (zero_end - zero_start) as usize];
            self.file.write_all(&zeros)?;
        }
        Ok(())
    }

    pub fn flush(&mut self) -> io::Result<()> {
        self.file.flush()
    }

    pub fn sync_all(&mut self) -> io::Result<()> {
        self.file.sync_all()
    }

    pub fn extend(&mut self, additional: u32) -> io::Result<()> {
        let new_count = self.header.snarf_count + additional;
        self.extend_to(new_count)
    }

    pub fn read_header_only(path: &Path) -> io::Result<UrdiHeader> {
        let mut file = std::fs::File::open(path)?;
        let mut buf = [0u8; FILE_HEADER_SIZE];
        file.read_exact(&mut buf)?;
        UrdiHeader::from_bytes(&buf)
    }

    fn slot_offset(snarf_id: u32, snarf_size: u32) -> u64 {
        FILE_HEADER_SIZE as u64 + snarf_id as u64 * (GUARD_SIZE + snarf_size as usize) as u64
    }

    fn read_guard_at(
        file: &mut std::fs::File,
        snarf_id: u32,
        snarf_size: u32,
    ) -> io::Result<Guard> {
        let offset = Self::slot_offset(snarf_id, snarf_size);
        file.seek(SeekFrom::Start(offset))?;
        let mut buf = [0u8; GUARD_SIZE];
        match file.read_exact(&mut buf) {
            Ok(()) => {
                if buf[0..4] == [0u8; 4] && buf[4..8] == [0u8; 4] {
                    return Ok(Guard {
                        snarf_id,
                        cycle: 0,
                        data_len: 0,
                        data_hash: 0,
                        flags: 0,
                    });
                }
                Guard::from_bytes(&buf)
            }
            Err(e) if e.kind() == io::ErrorKind::UnexpectedEof => Ok(Guard {
                snarf_id,
                cycle: 0,
                data_len: 0,
                data_hash: 0,
                flags: 0,
            }),
            Err(e) => Err(e),
        }
    }

    fn extend_to(&mut self, new_count: u32) -> io::Result<()> {
        if new_count <= self.header.snarf_count {
            return Ok(());
        }
        let slot_size = GUARD_SIZE + self.header.snarf_size as usize;
        let new_len = FILE_HEADER_SIZE as u64 + new_count as u64 * slot_size as u64;
        self.file.set_len(new_len)?;

        self.header.snarf_count = new_count;
        self.file.seek(SeekFrom::Start(0))?;
        self.file.write_all(&self.header.to_bytes())?;
        self.file.flush()?;

        self.cycles.resize(new_count as usize, 0);
        Ok(())
    }
}

pub const DEFAULT_SNARF_SIZE_FILE: u32 = 1_048_576;
pub const DEFAULT_INITIAL_COUNT: u32 = 8;
pub const DEFAULT_STAGE_COUNT: u32 = 2;
pub const DEFAULT_DATA_START: u32 = 2;

struct TempDir(std::path::PathBuf);

impl TempDir {
    fn new(name: &str) -> Self {
        let dir = std::env::temp_dir().join(format!("xudanu_test_{}_{}", name, std::process::id()));
        let _ = std::fs::create_dir_all(&dir);
        TempDir(dir)
    }

    fn path(&self) -> &std::path::Path {
        &self.0
    }

    fn join(&self, name: &str) -> std::path::PathBuf {
        self.0.join(name)
    }
}

impl Drop for TempDir {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.0);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;

    #[test]
    fn urdi_create_and_open() {
        let dir = TempDir::new("create_open");
        let path = dir.join("test.xu");

        let urdi = UrdiFile::create(&path, 256, 4, 1, 2).unwrap();
        assert_eq!(urdi.snarf_count(), 4);
        assert_eq!(urdi.snarf_size(), 256);

        drop(urdi);
        let urdi2 = UrdiFile::open(&path).unwrap();
        assert_eq!(urdi2.snarf_count(), 4);
        assert_eq!(urdi2.snarf_size(), 256);
        assert_eq!(urdi2.stage_count(), 1);
        assert_eq!(urdi2.data_start(), 2);
    }

    #[test]
    fn urdi_write_read_snarf() {
        let dir = TempDir::new("write_read");
        let path = dir.join("test.xu");

        let mut urdi = UrdiFile::create(&path, 256, 4, 1, 2).unwrap();
        let data = vec![0xABu8; 100];
        urdi.write_snarf(2, &data).unwrap();
        urdi.flush().unwrap();

        let read = urdi.read_snarf(2).unwrap().unwrap();
        assert_eq!(read, data);
    }

    #[test]
    fn urdi_empty_snarf_returns_none() {
        let dir = TempDir::new("empty");
        let path = dir.join("test.xu");

        let mut urdi = UrdiFile::create(&path, 256, 4, 1, 2).unwrap();
        assert!(urdi.read_snarf(0).unwrap().is_none());
        assert!(urdi.read_snarf(1).unwrap().is_none());
    }

    #[test]
    fn urdi_out_of_range_returns_none() {
        let dir = TempDir::new("out_of_range");
        let path = dir.join("test.xu");

        let mut urdi = UrdiFile::create(&path, 256, 4, 1, 2).unwrap();
        assert!(urdi.read_snarf(99).unwrap().is_none());
    }

    #[test]
    fn urdi_data_too_large() {
        let dir = TempDir::new("too_large");
        let path = dir.join("test.xu");

        let mut urdi = UrdiFile::create(&path, 64, 4, 1, 2).unwrap();
        let data = vec![0u8; 100];
        assert!(urdi.write_snarf(0, &data).is_err());
    }

    #[test]
    fn urdi_persist_across_close() {
        let dir = TempDir::new("persist");
        let path = dir.join("test.xu");

        {
            let mut urdi = UrdiFile::create(&path, 256, 4, 1, 2).unwrap();
            urdi.write_snarf(0, &vec![1u8; 50]).unwrap();
            urdi.write_snarf(3, &vec![2u8; 80]).unwrap();
            urdi.sync_all().unwrap();
        }
        {
            let mut urdi = UrdiFile::open(&path).unwrap();
            let d0 = urdi.read_snarf(0).unwrap().unwrap();
            assert_eq!(d0, vec![1u8; 50]);
            let d3 = urdi.read_snarf(3).unwrap().unwrap();
            assert_eq!(d3, vec![2u8; 80]);
        }
    }

    #[test]
    fn urdi_cycle_increments() {
        let dir = TempDir::new("cycle");
        let path = dir.join("test.xu");

        {
            let mut urdi = UrdiFile::create(&path, 256, 4, 1, 2).unwrap();
            urdi.write_snarf(0, &vec![1u8; 10]).unwrap();
            urdi.sync_all().unwrap();
        }
        {
            let mut urdi = UrdiFile::open(&path).unwrap();
            assert_eq!(urdi.cycles[0], 1);
            urdi.write_snarf(0, &vec![2u8; 10]).unwrap();
            urdi.sync_all().unwrap();
        }
        {
            let urdi = UrdiFile::open(&path).unwrap();
            assert_eq!(urdi.cycles[0], 2);
        }
    }

    #[test]
    fn urdi_extend_grows_file() {
        let dir = TempDir::new("extend");
        let path = dir.join("test.xu");

        let mut urdi = UrdiFile::create(&path, 256, 4, 1, 2).unwrap();
        assert_eq!(urdi.snarf_count(), 4);
        urdi.extend(4).unwrap();
        assert_eq!(urdi.snarf_count(), 8);
        urdi.write_snarf(7, &vec![0xFFu8; 20]).unwrap();
        let d = urdi.read_snarf(7).unwrap().unwrap();
        assert_eq!(d, vec![0xFFu8; 20]);
    }

    #[test]
    fn urdi_write_beyond_end_auto_extends() {
        let dir = TempDir::new("auto_extend");
        let path = dir.join("test.xu");

        let mut urdi = UrdiFile::create(&path, 256, 4, 1, 2).unwrap();
        urdi.write_snarf(10, &vec![42u8; 30]).unwrap();
        assert_eq!(urdi.snarf_count(), 11);
        let d = urdi.read_snarf(10).unwrap().unwrap();
        assert_eq!(d, vec![42u8; 30]);
    }

    #[test]
    fn urdi_corrupt_data_detected() {
        let dir = TempDir::new("corrupt_data");
        let path = dir.join("test.xu");

        {
            let mut urdi = UrdiFile::create(&path, 256, 4, 1, 2).unwrap();
            urdi.write_snarf(0, &vec![1u8; 50]).unwrap();
            urdi.sync_all().unwrap();
        }
        {
            let mut file = std::fs::OpenOptions::new().write(true).open(&path).unwrap();
            let data_offset = UrdiFile::slot_offset(0, 256) + GUARD_SIZE as u64 + 10;
            file.seek(SeekFrom::Start(data_offset)).unwrap();
            file.write_all(&[0xDE, 0xAD]).unwrap();
        }
        {
            let mut urdi = UrdiFile::open(&path).unwrap();
            let result = urdi.read_snarf(0);
            assert!(result.is_err());
        }
    }

    #[test]
    fn urdi_corrupt_guard_detected() {
        let dir = TempDir::new("corrupt_guard");
        let path = dir.join("test.xu");

        {
            let mut urdi = UrdiFile::create(&path, 256, 4, 1, 2).unwrap();
            urdi.write_snarf(0, &vec![1u8; 50]).unwrap();
            urdi.sync_all().unwrap();
        }
        {
            let mut file = std::fs::OpenOptions::new().write(true).open(&path).unwrap();
            let guard_offset = UrdiFile::slot_offset(0, 256) + 5;
            file.seek(SeekFrom::Start(guard_offset)).unwrap();
            file.write_all(&[0xFF, 0xFF, 0xFF, 0xFF]).unwrap();
        }
        {
            let mut urdi = UrdiFile::open(&path).unwrap();
            let result = urdi.read_snarf(0);
            assert!(result.is_err());
        }
    }

    #[test]
    fn urdi_corrupt_header_detected() {
        let dir = TempDir::new("corrupt_header");
        let path = dir.join("test.xu");

        {
            let _urdi = UrdiFile::create(&path, 256, 4, 1, 2).unwrap();
        }
        {
            let mut file = std::fs::OpenOptions::new().write(true).open(&path).unwrap();
            file.seek(SeekFrom::Start(10)).unwrap();
            file.write_all(&[0xFF, 0xFF, 0xFF, 0xFF]).unwrap();
        }
        assert!(UrdiFile::open(&path).is_err());
    }

    #[test]
    fn urdi_read_header_only() {
        let dir = TempDir::new("header_only");
        let path = dir.join("test.xu");

        UrdiFile::create(&path, 512, 8, 2, 3).unwrap();
        let hdr = UrdiFile::read_header_only(&path).unwrap();
        assert_eq!(hdr.snarf_size, 512);
        assert_eq!(hdr.snarf_count, 8);
        assert_eq!(hdr.stage_count, 2);
        assert_eq!(hdr.data_start, 3);
    }

    #[test]
    fn urdi_multiple_snarfs_roundtrip() {
        let dir = TempDir::new("multi_roundtrip");
        let path = dir.join("test.xu");

        {
            let mut urdi = UrdiFile::create(&path, 256, 8, 1, 2).unwrap();
            for i in 0u32..6 {
                urdi.write_snarf(i, &vec![i as u8; (i as usize + 1) * 10])
                    .unwrap();
            }
            urdi.sync_all().unwrap();
        }
        {
            let mut urdi = UrdiFile::open(&path).unwrap();
            for i in 0u32..6 {
                let d = urdi.read_snarf(i).unwrap().unwrap();
                assert_eq!(d, vec![i as u8; (i as usize + 1) * 10]);
            }
        }
    }
}
