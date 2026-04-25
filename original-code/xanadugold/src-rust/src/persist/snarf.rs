use std::io::{self, Cursor, Read};

use super::persistent::FlockLocation;
use super::urdi::UrdiFile;

const FLAG_BIT: u32 = 1 << 25;
const VALUE_MASK: u32 = (1 << 25) - 1;
const MAP_OVERHEAD: usize = 8;
const MAP_CELL_SIZE: usize = 8;
const HEADER_SIZE: usize = 8;

#[derive(Debug, Clone)]
struct MapCell {
    offset: u32,
    size: u32,
}

impl MapCell {
    fn empty() -> Self {
        MapCell { offset: 0, size: 0 }
    }

    fn is_allocated(&self) -> bool {
        self.size != 0
    }

    fn is_forwarded(&self) -> bool {
        (self.offset & FLAG_BIT) != 0
    }

    fn is_forgotten(&self) -> bool {
        (self.size & FLAG_BIT) != 0
    }

    fn raw_offset(&self) -> u32 {
        self.offset & VALUE_MASK
    }

    fn raw_size(&self) -> u32 {
        self.size & VALUE_MASK
    }

    fn set_forwarded(&mut self, snarf_id: u32) {
        self.offset = (snarf_id & VALUE_MASK) | FLAG_BIT;
    }

    fn set_forgotten(&mut self, forgotten: bool) {
        if forgotten {
            self.size |= FLAG_BIT;
        } else {
            self.size &= VALUE_MASK;
        }
    }

    fn forward_target(&self) -> Option<u32> {
        if self.is_forwarded() {
            Some(self.offset & VALUE_MASK)
        } else {
            None
        }
    }

    fn forward_index(&self) -> u32 {
        self.size & VALUE_MASK
    }

    fn set_forward_to(&mut self, new_snarf_id: u32, new_index: u32) {
        self.offset = (new_snarf_id & VALUE_MASK) | FLAG_BIT;
        self.size = new_index & VALUE_MASK;
    }
}

#[derive(Debug, Clone)]
pub struct Snarf {
    snarf_size: usize,
    map_cells: Vec<MapCell>,
    data: Vec<u8>,
    dirty: bool,
}

impl Snarf {
    pub fn new(snarf_size: usize) -> Self {
        let mut data = vec![0u8; snarf_size];
        let initial_space = snarf_size.saturating_sub(HEADER_SIZE) as u32;
        Self::write_header(&mut data, 0, initial_space);
        Snarf {
            snarf_size,
            map_cells: Vec::new(),
            data,
            dirty: true,
        }
    }

    pub fn from_bytes(snarf_size: usize, data: Vec<u8>) -> io::Result<Self> {
        if data.len() < HEADER_SIZE {
            return Err(io::Error::new(io::ErrorKind::InvalidData, "snarf too small"));
        }
        let mut cursor = Cursor::new(&data);
        let mut header = [0u8; 8];
        cursor.read_exact(&mut header)?;
        let map_count = u32::from_le_bytes(header[0..4].try_into().unwrap()) as usize;
        let _space_left = u32::from_le_bytes(header[4..8].try_into().unwrap());

        let mut map_cells = Vec::with_capacity(map_count);
        let mut cell_data = vec![0u8; map_count * MAP_CELL_SIZE];
        cursor.read_exact(&mut cell_data)?;
        for i in 0..map_count {
            let off = i * MAP_CELL_SIZE;
            let offset = u32::from_le_bytes(cell_data[off..off + 4].try_into().unwrap());
            let size = u32::from_le_bytes(cell_data[off + 4..off + 8].try_into().unwrap());
            map_cells.push(MapCell { offset, size });
        }

        Ok(Snarf {
            snarf_size,
            map_cells,
            data,
            dirty: false,
        })
    }

    pub fn to_bytes(&self) -> &[u8] {
        &self.data
    }

    pub fn is_dirty(&self) -> bool {
        self.dirty
    }

    pub fn clear_dirty(&mut self) {
        self.dirty = false;
    }

    pub fn space_left(&self) -> u32 {
        let (_, space) = Self::read_header(&self.data);
        space
    }

    pub fn map_count(&self) -> usize {
        self.map_cells.len()
    }

    pub fn allocate(&mut self, index: usize, flock_size: u32) -> bool {
        self.dirty = true;
        let needed = flock_size as usize;

        while index >= self.map_cells.len() {
            if self.space_left() < MAP_CELL_SIZE as u32 {
                return false;
            }
            self.map_cells.push(MapCell::empty());
            self.write_map_count(self.map_cells.len());
            self.decrease_space(MAP_CELL_SIZE as u32);
        }

        let space = self.space_left() as usize;
        if space < needed {
            return false;
        }

        let map_end = self.data_start();
        let offset = map_end + space - needed;

        self.map_cells[index].offset = offset as u32;
        self.map_cells[index].size = needed as u32;

        self.decrease_space(needed as u32);
        self.write_map_cell(index);

        true
    }

    pub fn write_flock(&mut self, index: usize, data: &[u8]) -> io::Result<()> {
        self.dirty = true;
        if index >= self.map_cells.len() {
            return Err(io::Error::new(io::ErrorKind::InvalidInput, "index out of range"));
        }
        let cell = &self.map_cells[index];
        if cell.is_forwarded() {
            return Err(io::Error::new(io::ErrorKind::InvalidInput, "cell is forwarded"));
        }
        let offset = cell.raw_offset() as usize;
        let size = cell.raw_size() as usize;
        if data.len() > size {
            return Err(io::Error::new(io::ErrorKind::InvalidInput, "data too large for cell"));
        }
        self.data[offset..offset + data.len()].copy_from_slice(data);
        Ok(())
    }

    pub fn read_flock(&self, index: usize) -> io::Result<Vec<u8>> {
        if index >= self.map_cells.len() {
            return Err(io::Error::new(io::ErrorKind::InvalidInput, "index out of range"));
        }
        let cell = &self.map_cells[index];
        if cell.is_forwarded() {
            return Err(io::Error::new(io::ErrorKind::InvalidInput, "cell is forwarded"));
        }
        if !cell.is_allocated() {
            return Err(io::Error::new(io::ErrorKind::InvalidInput, "cell not allocated"));
        }
        let offset = cell.raw_offset() as usize;
        let size = cell.raw_size() as usize;
        Ok(self.data[offset..offset + size].to_vec())
    }

    pub fn wipe_flock(&mut self, index: usize) {
        self.dirty = true;
        if index >= self.map_cells.len() {
            return;
        }
        let cell = &self.map_cells[index];
        if !cell.is_allocated() || cell.is_forwarded() {
            return;
        }
        let freed = cell.raw_size() as u32;
        self.map_cells[index] = MapCell::empty();
        self.increase_space(freed);
        self.write_map_cell(index);
    }

    pub fn store_forget(&mut self, index: usize, forgotten: bool) {
        self.dirty = true;
        if index >= self.map_cells.len() {
            return;
        }
        self.map_cells[index].set_forgotten(forgotten);
        self.write_map_cell(index);
    }

    pub fn is_forgotten(&self, index: usize) -> bool {
        if index >= self.map_cells.len() {
            return false;
        }
        self.map_cells[index].is_forgotten()
    }

    pub fn forward_to(&mut self, index: usize, new_snarf_id: u32, new_index: u32) {
        self.dirty = true;
        if index >= self.map_cells.len() {
            return;
        }
        self.map_cells[index].set_forward_to(new_snarf_id, new_index);
        self.write_map_cell(index);
    }

    pub fn fetch_forward(&self, index: usize) -> Option<FlockLocation> {
        if index >= self.map_cells.len() {
            return None;
        }
        let cell = &self.map_cells[index];
        if cell.is_forwarded() {
            Some(FlockLocation::new(
                cell.forward_target()?,
                cell.forward_index(),
            ))
        } else {
            None
        }
    }

    pub fn flock_size(&self, index: usize) -> Option<u32> {
        if index >= self.map_cells.len() {
            return None;
        }
        let cell = &self.map_cells[index];
        if cell.is_allocated() && !cell.is_forwarded() {
            Some(cell.raw_size())
        } else {
            None
        }
    }

    pub fn compact(&mut self) {
        self.dirty = true;
        let mut allocated: Vec<(usize, u32, u32, bool)> = self.map_cells.iter()
            .enumerate()
            .filter(|(_, c)| c.is_allocated() && !c.is_forwarded())
            .map(|(i, c)| (i, c.raw_offset(), c.raw_size(), c.is_forgotten()))
            .collect();

        allocated.sort_by_key(|(_, offset, _, _)| std::cmp::Reverse(*offset));

        let mut new_offset = self.snarf_size;
        for (idx, old_off, size, forgotten) in &allocated {
            let old_off = *old_off as usize;
            let size = *size as usize;
            new_offset -= size;
            if new_offset != old_off {
                self.data.copy_within(old_off..old_off + size, new_offset);
                self.map_cells[*idx].offset = new_offset as u32;
                self.map_cells[*idx].set_forgotten(*forgotten);
            }
        }

        let data_start = self.data_start();
        let new_space = new_offset.saturating_sub(data_start);
        self.set_space(new_space as u32);

        for i in 0..self.map_cells.len() {
            self.write_map_cell(i);
        }
    }

    fn data_start(&self) -> usize {
        let map_bytes = self.map_cells.len() * MAP_CELL_SIZE;
        HEADER_SIZE + map_bytes
    }

    fn write_header(data: &mut [u8], map_count: u32, space_left: u32) {
        data[0..4].copy_from_slice(&map_count.to_le_bytes());
        data[4..8].copy_from_slice(&space_left.to_le_bytes());
    }

    fn read_header(data: &[u8]) -> (u32, u32) {
        let map_count = u32::from_le_bytes(data[0..4].try_into().unwrap());
        let space_left = u32::from_le_bytes(data[4..8].try_into().unwrap());
        (map_count, space_left)
    }

    fn write_map_count(&mut self, count: usize) {
        self.data[0..4].copy_from_slice(&(count as u32).to_le_bytes());
    }

    fn decrease_space(&mut self, amount: u32) {
        let (_, space) = Self::read_header(&self.data);
        let new_space = space.saturating_sub(amount);
        self.set_space(new_space);
    }

    fn increase_space(&mut self, amount: u32) {
        let (_, space) = Self::read_header(&self.data);
        self.set_space(space + amount);
    }

    fn set_space(&mut self, space: u32) {
        self.data[4..8].copy_from_slice(&space.to_le_bytes());
    }

    fn write_map_cell(&mut self, index: usize) {
        let offset = HEADER_SIZE + index * MAP_CELL_SIZE;
        if offset + MAP_CELL_SIZE > self.data.len() {
            return;
        }
        self.data[offset..offset + 4].copy_from_slice(&self.map_cells[index].offset.to_le_bytes());
        self.data[offset + 4..offset + 8].copy_from_slice(&self.map_cells[index].size.to_le_bytes());
    }
}

pub const DEFAULT_SNARF_SIZE: usize = 4096;
pub const SNARF_INFO_COUNT: u32 = 4;

#[derive(Debug)]
pub struct SnarfStore {
    snarfs: Vec<Snarf>,
    snarf_size: usize,
}

impl SnarfStore {
    pub fn new(snarf_size: usize) -> Self {
        let mut store = SnarfStore {
            snarfs: Vec::new(),
            snarf_size,
        };
        for _ in 0..SNARF_INFO_COUNT {
            store.snarfs.push(Snarf::new(snarf_size));
        }
        store
    }

    pub fn snarf_count(&self) -> u32 {
        self.snarfs.len() as u32
    }

    pub fn get(&self, snarf_id: u32) -> Option<&Snarf> {
        self.snarfs.get(snarf_id as usize)
    }

    pub fn get_mut(&mut self, snarf_id: u32) -> Option<&mut Snarf> {
        self.snarfs.get_mut(snarf_id as usize)
    }

    pub fn allocate_snarf(&mut self) -> u32 {
        let id = self.snarfs.len() as u32;
        self.snarfs.push(Snarf::new(self.snarf_size));
        id
    }

    pub fn find_space(&self, size: u32) -> Option<u32> {
        for (i, snarf) in self.snarfs.iter().enumerate() {
            let id = i as u32;
            if id < SNARF_INFO_COUNT {
                continue;
            }
            if snarf.space_left() >= size {
                return Some(id);
            }
        }
        None
    }

    pub fn find_or_create(&mut self, size: u32) -> u32 {
        if let Some(id) = self.find_space(size) {
            return id;
        }
        let id = self.allocate_snarf();
        id
    }

    pub fn write_flock(&mut self, location: &FlockLocation, data: &[u8]) -> io::Result<()> {
        let snarf = self.snarfs.get_mut(location.snarf_id as usize)
            .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "bad snarf id"))?;
        snarf.write_flock(location.index as usize, data)
    }

    pub fn read_flock(&self, location: &FlockLocation) -> io::Result<Vec<u8>> {
        let snarf = self.snarfs.get(location.snarf_id as usize)
            .ok_or_else(|| io::Error::new(io::ErrorKind::InvalidInput, "bad snarf id"))?;
        if let Some(forward) = snarf.fetch_forward(location.index as usize) {
            if forward.snarf_id == location.snarf_id && forward.index == location.index {
                return Err(io::Error::new(io::ErrorKind::InvalidData, "forward cycle detected"));
            }
            return self.read_flock(&forward);
        }
        snarf.read_flock(location.index as usize)
    }

    pub fn allocate_and_write(&mut self, flock_data: &[u8]) -> Option<FlockLocation> {
        let size = flock_data.len() as u32;
        let snarf_id = self.find_or_create(size);
        let snarf = self.get_mut(snarf_id)?;

        let index = snarf.map_count();
        if !snarf.allocate(index, size) {
            let snarf_id = self.allocate_snarf();
            let snarf = self.get_mut(snarf_id)?;
            let index = snarf.map_count();
            if !snarf.allocate(index, size) {
                return None;
            }
            snarf.write_flock(index, flock_data).ok()?;
            return Some(FlockLocation::new(snarf_id, index as u32));
        }

        snarf.write_flock(index, flock_data).ok()?;
        Some(FlockLocation::new(snarf_id, index as u32))
    }

    pub fn dirty_snarf_ids(&self) -> Vec<u32> {
        self.snarfs.iter()
            .enumerate()
            .filter(|(_, s)| s.is_dirty())
            .map(|(i, _)| i as u32)
            .collect()
    }

    pub fn flush_to_urdi(&mut self, urdi: &mut UrdiFile) -> io::Result<()> {
        self.flush_to_urdi_with_offset(urdi, 0)
    }

    pub fn flush_to_urdi_with_offset(&mut self, urdi: &mut UrdiFile, offset: u32) -> io::Result<()> {
        for (id, snarf) in self.snarfs.iter_mut().enumerate() {
            if snarf.is_dirty() {
                urdi.write_snarf(offset + id as u32, snarf.to_bytes())?;
                snarf.clear_dirty();
            }
        }
        urdi.flush()?;
        Ok(())
    }

    pub fn load_from_urdi(urdi: &mut UrdiFile) -> io::Result<Self> {
        Self::load_from_urdi_with_offset(urdi, 0)
    }

    pub fn load_from_urdi_with_offset(urdi: &mut UrdiFile, offset: u32) -> io::Result<Self> {
        let snarf_size = urdi.snarf_size();
        let count = urdi.snarf_count().saturating_sub(offset);
        let mut snarfs = Vec::with_capacity(count as usize);
        for id in 0..count {
            match urdi.read_snarf(offset + id)? {
                Some(data) => {
                    snarfs.push(Snarf::from_bytes(snarf_size, data)?);
                }
                None => {
                    snarfs.push(Snarf::new(snarf_size));
                }
            }
        }
        Ok(SnarfStore { snarfs, snarf_size })
    }

    pub fn ensure_capacity(&mut self, min_count: u32) {
        while self.snarfs.len() < min_count as usize {
            self.snarfs.push(Snarf::new(self.snarf_size));
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn snarf_new_has_header() {
        let snarf = Snarf::new(256);
        assert_eq!(snarf.map_count(), 0);
        assert_eq!(snarf.space_left(), (256 - HEADER_SIZE) as u32);
    }

    #[test]
    fn snarf_allocate_write_read() {
        let mut snarf = Snarf::new(256);
        assert!(snarf.allocate(0, 16));
        let data = vec![0xABu8; 16];
        snarf.write_flock(0, &data).unwrap();
        let read = snarf.read_flock(0).unwrap();
        assert_eq!(read, data);
    }

    #[test]
    fn snarf_multiple_flocks() {
        let mut snarf = Snarf::new(256);
        assert!(snarf.allocate(0, 16));
        assert!(snarf.allocate(1, 32));
        snarf.write_flock(0, &vec![1u8; 16]).unwrap();
        snarf.write_flock(1, &vec![2u8; 32]).unwrap();
        assert_eq!(snarf.read_flock(0).unwrap(), vec![1u8; 16]);
        assert_eq!(snarf.read_flock(1).unwrap(), vec![2u8; 32]);
    }

    #[test]
    fn snarf_out_of_space() {
        let mut snarf = Snarf::new(64);
        assert!(!snarf.allocate(0, 200));
    }

    #[test]
    fn snarf_wipe_flock() {
        let mut snarf = Snarf::new(256);
        snarf.allocate(0, 16);
        snarf.write_flock(0, &vec![1u8; 16]).unwrap();
        let space_before = snarf.space_left();
        snarf.wipe_flock(0);
        assert!(snarf.read_flock(0).is_err());
        assert!(snarf.space_left() > space_before);
    }

    #[test]
    fn snarf_forget_flag() {
        let mut snarf = Snarf::new(256);
        snarf.allocate(0, 16);
        snarf.write_flock(0, &vec![1u8; 16]).unwrap();
        assert!(!snarf.is_forgotten(0));
        snarf.store_forget(0, true);
        assert!(snarf.is_forgotten(0));
        snarf.store_forget(0, false);
        assert!(!snarf.is_forgotten(0));
    }

    #[test]
    fn snarf_forward_pointer() {
        let mut snarf = Snarf::new(256);
        snarf.allocate(0, 16);
        snarf.forward_to(0, 5, 3);
        let loc = snarf.fetch_forward(0).unwrap();
        assert_eq!(loc.snarf_id, 5);
        assert_eq!(loc.index, 3);
    }

    #[test]
    fn snarf_roundtrip() {
        let mut snarf = Snarf::new(256);
        snarf.allocate(0, 16);
        snarf.write_flock(0, &vec![42u8; 16]).unwrap();
        let bytes = snarf.to_bytes().to_vec();
        let restored = Snarf::from_bytes(256, bytes).unwrap();
        let data = restored.read_flock(0).unwrap();
        assert_eq!(data, vec![42u8; 16]);
    }

    #[test]
    fn snarf_store_allocate_and_write() {
        let mut store = SnarfStore::new(256);
        let loc = store.allocate_and_write(&vec![1u8; 16]).unwrap();
        assert!(loc.snarf_id >= SNARF_INFO_COUNT);
        let data = store.read_flock(&loc).unwrap();
        assert_eq!(data, vec![1u8; 16]);
    }

    #[test]
    fn snarf_store_multiple() {
        let mut store = SnarfStore::new(256);
        let loc1 = store.allocate_and_write(&vec![1u8; 16]).unwrap();
        let loc2 = store.allocate_and_write(&vec![2u8; 16]).unwrap();
        assert_eq!(store.read_flock(&loc1).unwrap(), vec![1u8; 16]);
        assert_eq!(store.read_flock(&loc2).unwrap(), vec![2u8; 16]);
    }

    #[test]
    fn snarf_store_forward_resolves() {
        let mut store = SnarfStore::new(256);
        let data = vec![0xCCu8; 16];
        let real_loc = store.allocate_and_write(&data).unwrap();
        let fwd_loc = store.allocate_and_write(&vec![0u8; 16]).unwrap();
        store.get_mut(fwd_loc.snarf_id).unwrap().forward_to(
            fwd_loc.index as usize,
            real_loc.snarf_id,
            real_loc.index,
        );
        let read = store.read_flock(&fwd_loc).unwrap();
        assert_eq!(read, data);
    }

    #[test]
    fn snarf_store_forward_cycle_detected() {
        let mut store = SnarfStore::new(256);
        let loc = store.allocate_and_write(&vec![1u8; 16]).unwrap();
        store.get_mut(loc.snarf_id).unwrap().forward_to(
            loc.index as usize,
            loc.snarf_id,
            loc.index,
        );
        let result = store.read_flock(&loc);
        assert!(result.is_err());
    }

    #[test]
    fn snarf_compact_reclaims_space() {
        let mut snarf = Snarf::new(128);
        snarf.allocate(0, 16);
        snarf.write_flock(0, &vec![1u8; 16]).unwrap();
        snarf.allocate(1, 16);
        snarf.write_flock(1, &vec![2u8; 16]).unwrap();
        snarf.wipe_flock(0);
        let space_before = snarf.space_left();
        snarf.compact();
        assert!(snarf.space_left() >= space_before);
        assert_eq!(snarf.read_flock(1).unwrap(), vec![2u8; 16]);
    }

    #[test]
    fn snarf_flock_size() {
        let mut snarf = Snarf::new(256);
        snarf.allocate(0, 42);
        assert_eq!(snarf.flock_size(0), Some(42));
        assert_eq!(snarf.flock_size(1), None);
    }

    #[test]
    fn snarf_dirty_tracking() {
        let mut snarf = Snarf::new(256);
        assert!(snarf.is_dirty());
        snarf.clear_dirty();
        assert!(!snarf.is_dirty());
        snarf.allocate(0, 16);
        assert!(snarf.is_dirty());
    }

    #[test]
    fn snarf_write_marks_dirty() {
        let mut snarf = Snarf::new(256);
        snarf.allocate(0, 16);
        snarf.clear_dirty();
        assert!(!snarf.is_dirty());
        snarf.write_flock(0, &vec![1u8; 16]).unwrap();
        assert!(snarf.is_dirty());
    }

    #[test]
    fn snarf_wipe_marks_dirty() {
        let mut snarf = Snarf::new(256);
        snarf.allocate(0, 16);
        snarf.clear_dirty();
        snarf.wipe_flock(0);
        assert!(snarf.is_dirty());
    }

    struct TempDir(std::path::PathBuf);

    impl TempDir {
        fn new(name: &str) -> Self {
            let dir = std::env::temp_dir().join(format!(
                "xudanu_snarf_test_{}_{}", name, std::process::id()
            ));
            let _ = std::fs::create_dir_all(&dir);
            TempDir(dir)
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

    #[test]
    fn snarf_store_flush_and_load() {
        let dir = TempDir::new("flush_load");
        let path = dir.join("test.xu");
        let snarf_size = 256;

        let loc1;
        let loc2;
        {
            let mut store = SnarfStore::new(snarf_size);
            loc1 = store.allocate_and_write(&vec![0xAAu8; 20]).unwrap();
            loc2 = store.allocate_and_write(&vec![0xBBu8; 30]).unwrap();

            let mut urdi = UrdiFile::create(
                &path, snarf_size as u32, store.snarf_count(), 0, SNARF_INFO_COUNT,
            ).unwrap();
            store.flush_to_urdi(&mut urdi).unwrap();
            urdi.sync_all().unwrap();
        }
        {
            let mut urdi = UrdiFile::open(&path).unwrap();
            let mut store = SnarfStore::load_from_urdi(&mut urdi).unwrap();
            assert_eq!(store.read_flock(&loc1).unwrap(), vec![0xAAu8; 20]);
            assert_eq!(store.read_flock(&loc2).unwrap(), vec![0xBBu8; 30]);
        }
    }

    #[test]
    fn snarf_store_incremental_flush() {
        let dir = TempDir::new("incremental");
        let path = dir.join("test.xu");
        let snarf_size = 256;

        let loc1;
        let loc2;
        {
            let mut store = SnarfStore::new(snarf_size);
            let mut urdi = UrdiFile::create(
                &path, snarf_size as u32, 8, 0, SNARF_INFO_COUNT,
            ).unwrap();

            loc1 = store.allocate_and_write(&vec![1u8; 10]).unwrap();
            store.flush_to_urdi(&mut urdi).unwrap();
            urdi.sync_all().unwrap();

            assert!(store.dirty_snarf_ids().is_empty());

            loc2 = store.allocate_and_write(&vec![2u8; 10]).unwrap();
            assert!(!store.dirty_snarf_ids().is_empty());
            store.flush_to_urdi(&mut urdi).unwrap();
            urdi.sync_all().unwrap();
        }
        {
            let mut urdi = UrdiFile::open(&path).unwrap();
            let store = SnarfStore::load_from_urdi(&mut urdi).unwrap();
            assert_eq!(store.read_flock(&loc1).unwrap(), vec![1u8; 10]);
            assert_eq!(store.read_flock(&loc2).unwrap(), vec![2u8; 10]);
        }
    }

    #[test]
    fn snarf_store_load_empty_slots() {
        let dir = TempDir::new("empty_slots");
        let path = dir.join("test.xu");
        let snarf_size = 256;

        {
            let mut store = SnarfStore::new(snarf_size);
            let mut urdi = UrdiFile::create(
                &path, snarf_size as u32, store.snarf_count(), 0, SNARF_INFO_COUNT,
            ).unwrap();
            store.flush_to_urdi(&mut urdi).unwrap();
            urdi.sync_all().unwrap();
        }
        {
            let mut urdi = UrdiFile::open(&path).unwrap();
            let store = SnarfStore::load_from_urdi(&mut urdi).unwrap();
            assert_eq!(store.snarf_count(), SNARF_INFO_COUNT);
        }
    }
}
