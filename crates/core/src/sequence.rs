use std::collections::HashMap;

use xanadu_types::*;

use crate::state_vector::StateVector;

#[derive(Debug, Clone)]
pub struct Sequence {
    start: ItemId,
    end: ItemId,
    items: HashMap<ItemId, SeqItem>,
    state_vector: StateVector,
    char_count: usize,
}

#[derive(Debug, Clone)]
struct SeqItem {
    id: ItemId,
    left_id: Option<ItemId>,
    right_id: Option<ItemId>,
    origin_left: Option<ItemId>,
    origin_right: Option<ItemId>,
    content: ItemContent,
    is_deleted: bool,
    deleted_ranges: Vec<(usize, usize)>,
    author: AuthorId,
    lamport: u64,
}

impl SeqItem {
    fn content_len(&self) -> usize {
        match &self.content {
            ItemContent::Text { text, .. } => text.len(),
            ItemContent::BlockStart(_) | ItemContent::BlockEnd => 0,
            ItemContent::Transclusion(_) => 1,
            ItemContent::Embedded(_) => 1,
        }
    }

    fn visible_char_count(&self) -> usize {
        if self.is_deleted {
            0
        } else {
            let deleted: usize = self.deleted_ranges.iter().map(|(s, e)| e - s).sum();
            self.content_len() - deleted
        }
    }

    fn add_deleted_range(&mut self, start: usize, len: usize) {
        if len == 0 || self.is_deleted {
            return;
        }
        let end = start + len;
        let mut new_ranges = Vec::new();
        let mut merged_start = start;
        let mut merged_end = end;
        let mut inserted = false;

        for &(s, e) in &self.deleted_ranges {
            if e < start && !inserted {
                new_ranges.push((s, e));
            } else if s > end {
                if !inserted {
                    new_ranges.push((merged_start, merged_end));
                    inserted = true;
                }
                new_ranges.push((s, e));
            } else {
                merged_start = merged_start.min(s);
                merged_end = merged_end.max(e);
            }
        }
        if !inserted {
            new_ranges.push((merged_start, merged_end));
        }
        self.deleted_ranges = new_ranges;

        if self.deleted_ranges.len() == 1
            && self.deleted_ranges[0].0 == 0
            && self.deleted_ranges[0].1 == self.content_len()
        {
            self.is_deleted = true;
            self.deleted_ranges.clear();
        }
    }

    fn is_fully_deleted(&self) -> bool {
        self.is_deleted
    }

    fn visible_text(&self) -> String {
        if self.is_deleted {
            return String::new();
        }
        match &self.content {
            ItemContent::Text { text, .. } => {
                if self.deleted_ranges.is_empty() {
                    return text.clone();
                }
                let mut result = String::with_capacity(text.len());
                let mut pos = 0;
                for &(ds, de) in &self.deleted_ranges {
                    if ds > pos {
                        result.push_str(&text[pos..ds]);
                    }
                    pos = de;
                }
                if pos < text.len() {
                    result.push_str(&text[pos..]);
                }
                result
            }
            _ => String::new(),
        }
    }

    fn map_visible_to_content(&self, visible_pos: usize) -> usize {
        if self.deleted_ranges.is_empty() {
            return visible_pos;
        }
        let mut visible = 0;
        let mut content_pos = 0;
        let text_len = self.content_len();
        let mut ri = 0;
        while visible < visible_pos && content_pos < text_len {
            if ri < self.deleted_ranges.len() && content_pos >= self.deleted_ranges[ri].0 {
                content_pos = self.deleted_ranges[ri].1;
                ri += 1;
                continue;
            }
            visible += 1;
            content_pos += 1;
        }
        content_pos
    }
}

impl Sequence {
    pub fn new(site: SiteId) -> Self {
        let start = ItemId::sentinel_start(site);
        let end = ItemId::new(site, u64::MAX);

        let start_item = SeqItem {
            id: start,
            left_id: None,
            right_id: Some(end),
            origin_left: None,
            origin_right: Some(end),
            content: ItemContent::plain(""),
            is_deleted: true,
            deleted_ranges: Vec::new(),
            author: [0u8; 32],
            lamport: 0,
        };

        let end_item = SeqItem {
            id: end,
            left_id: Some(start),
            right_id: None,
            origin_left: Some(start),
            origin_right: None,
            content: ItemContent::plain(""),
            is_deleted: true,
            deleted_ranges: Vec::new(),
            author: [0u8; 32],
            lamport: 0,
        };

        let mut items = HashMap::new();
        items.insert(start, start_item);
        items.insert(end, end_item);

        Self {
            start,
            end,
            items,
            state_vector: StateVector::new(),
            char_count: 0,
        }
    }

    pub fn len(&self) -> usize {
        self.char_count
    }

    pub fn is_empty(&self) -> bool {
        self.char_count == 0
    }

    pub fn state_vector(&self) -> &StateVector {
        &self.state_vector
    }

    pub fn has_item(&self, id: &ItemId) -> bool {
        self.items.contains_key(id)
    }

    pub fn local_insert(
        &mut self,
        char_index: usize,
        content: ItemContent,
        site: SiteId,
        author: AuthorId,
    ) -> Op {
        let clock = self.state_vector.get(&site) + 1;
        let id = ItemId::new(site, clock);

        let (left_id, right_id, origin_left, origin_right) =
            self.find_or_split_char_position(char_index, site, author, clock + 1);

        let op = Op::Insert {
            id,
            left_id: Some(origin_left),
            right_id: Some(origin_right),
            content: content.clone(),
            author,
        };

        self.apply_insert_at(
            id,
            left_id,
            right_id,
            Some(origin_left),
            Some(origin_right),
            content,
            author,
            clock,
        );

        let max_clock = self
            .items
            .keys()
            .filter(|k| k.site == site && k.clock < u64::MAX)
            .map(|k| k.clock)
            .max()
            .unwrap_or(clock);
        self.state_vector.set(site, max_clock);

        op
    }

    pub fn local_delete(
        &mut self,
        char_index: usize,
        char_len: usize,
        site: SiteId,
        author: AuthorId,
    ) -> Vec<Op> {
        let mut ops = Vec::new();
        let mut remaining = char_len;
        let mut visible_offset = 0usize;
        let mut current = Some(self.start);
        let mut base_clock = self.state_vector.get(&site) + 1;

        let mut pending_deletes: Vec<(ItemId, usize, usize)> = Vec::new();

        while let Some(id) = current {
            if remaining == 0 || id == self.end {
                break;
            }

            let item = match self.items.get(&id) {
                Some(i) => i,
                None => break,
            };
            let next = item.right_id.clone();

            if item.is_fully_deleted() {
                current = next;
                continue;
            }

            let item_visible = item.visible_char_count();
            if item_visible == 0 {
                current = next;
                continue;
            }

            let item_start = visible_offset;
            let item_end = visible_offset + item_visible;

            if item_end <= char_index {
                visible_offset = item_end;
                current = next;
                continue;
            }

            let del_vis_start = char_index.max(item_start) - item_start;
            let del_vis_end = (char_index + char_len).min(item_end) - item_start;
            let del_vis_len = del_vis_end - del_vis_start;

            if del_vis_len == 0 {
                visible_offset = item_end;
                current = next;
                continue;
            }

            let content_start = item.map_visible_to_content(del_vis_start);
            let content_end = item.map_visible_to_content(del_vis_end);
            let content_len = content_end - content_start;

            if content_len > 0 {
                let delete_id = ItemId::new(site, base_clock);
                base_clock += 1;

                ops.push(Op::Delete {
                    id: delete_id,
                    target_id: id,
                    start: content_start,
                    len: content_len,
                    author,
                });

                pending_deletes.push((id, content_start, content_len));
                self.char_count -= del_vis_len;
                remaining -= del_vis_len;
            }

            visible_offset = item_end;
            current = next;
        }

        for (target_id, start, len) in pending_deletes {
            if let Some(item) = self.items.get_mut(&target_id) {
                item.add_deleted_range(start, len);
            }
        }

        if base_clock > self.state_vector.get(&site) + 1 {
            self.state_vector.set(site, base_clock - 1);
        }

        ops
    }

    pub fn integrate_op(&mut self, op: &Op) {
        match op {
            Op::Insert {
                id,
                left_id,
                right_id,
                content,
                author,
            } => {
                if self.items.contains_key(id) {
                    return;
                }

                let lamport = self.state_vector.get(&id.site) + 1;

                let (actual_left, actual_right) =
                    self.find_integrate_position(left_id, right_id, op);

                self.apply_insert_at(
                    *id,
                    actual_left,
                    actual_right,
                    left_id.clone(),
                    right_id.clone(),
                    content.clone(),
                    *author,
                    lamport,
                );
                self.state_vector.set(id.site, id.clock);
            }
            Op::Delete {
                target_id,
                start,
                len,
                ..
            } => {
                if let Some(item) = self.items.get_mut(target_id) {
                    if item.is_fully_deleted() {
                        return;
                    }
                    let old_visible = item.visible_char_count();
                    item.add_deleted_range(*start, *len);
                    let new_visible = item.visible_char_count();
                    let removed = old_visible - new_visible;
                    if removed > 0 {
                        self.char_count -= removed;
                    }
                }
            }
            Op::Transclude { .. } => {}
        }
    }

    fn apply_insert_at(
        &mut self,
        id: ItemId,
        actual_left: ItemId,
        actual_right: Option<ItemId>,
        origin_left: Option<ItemId>,
        origin_right: Option<ItemId>,
        content: ItemContent,
        author: AuthorId,
        lamport: u64,
    ) {
        let char_count = if content.is_empty() {
            0
        } else {
            match &content {
                ItemContent::Text { text, .. } => text.len(),
                ItemContent::BlockStart(_) | ItemContent::BlockEnd => 0,
                ItemContent::Transclusion(_) => 1,
                ItemContent::Embedded(_) => 1,
            }
        };

        let new_item = SeqItem {
            id,
            left_id: Some(actual_left),
            right_id: actual_right.clone(),
            origin_left,
            origin_right,
            content,
            is_deleted: false,
            deleted_ranges: Vec::new(),
            author,
            lamport,
        };

        if let Some(left) = self.items.get_mut(&actual_left) {
            left.right_id = Some(id);
        }
        if let Some(right) = &actual_right {
            if let Some(right_item) = self.items.get_mut(right) {
                right_item.left_id = Some(id);
            }
        }

        self.char_count += char_count;
        self.items.insert(id, new_item);
    }

    fn find_or_split_char_position(
        &mut self,
        char_index: usize,
        site: SiteId,
        author: AuthorId,
        base_clock: u64,
    ) -> (ItemId, Option<ItemId>, ItemId, ItemId) {
        let mut offset = 0usize;
        let mut current = self.start;

        loop {
            if current == self.end {
                if let Some(end_item) = self.items.get(&self.end) {
                    if let Some(left) = &end_item.left_id {
                        return (
                            *left,
                            Some(self.end),
                            *left,
                            self.end,
                        );
                    }
                }
                return (self.start, Some(self.end), self.start, self.end);
            }

            let item = match self.items.get(&current) {
                Some(i) => i,
                None => return (self.start, Some(self.end), self.start, self.end),
            };

            if !item.is_fully_deleted() {
                if let Some(text) = item.content.text() {
                    let item_visible = item.visible_char_count();
                    if offset + item_visible >= char_index {
                        if offset + item_visible == char_index {
                            let right = item.right_id.clone();
                            return (
                                current,
                                right,
                                current,
                                item.right_id.unwrap_or(self.end),
                            );
                        }

                        if offset < char_index {
                            let vis_split_pos = char_index - offset;
                            return self.split_item(
                                current,
                                vis_split_pos,
                                site,
                                author,
                                base_clock,
                            );
                        }

                        let left = item.left_id.unwrap_or(self.start);
                        let right = item.right_id.unwrap_or(self.end);
                        return (
                            left,
                            Some(current),
                            left,
                            current,
                        );
                    }
                    offset += item_visible;
                }
            }

            match &item.right_id {
                Some(next) => current = *next,
                None => return (current, None, current, self.end),
            }
        }
    }

    fn split_item(
        &mut self,
        item_id: ItemId,
        vis_split_pos: usize,
        site: SiteId,
        author: AuthorId,
        base_clock: u64,
    ) -> (ItemId, Option<ItemId>, ItemId, ItemId) {
        let (text, marks, item_left, item_right) = {
            let item = self.items.get(&item_id).expect("item must exist");
            let t = match &item.content {
                ItemContent::Text { text, marks } => (text.clone(), marks.clone()),
                _ => {
                    let left = item.left_id.unwrap_or(self.start);
                    let right = item.right_id.unwrap_or(self.end);
                    return (left, Some(item_id), left, item_id);
                }
            };
            (t.0, t.1, item.left_id, item.right_id.clone())
        };

        let content_split_pos = {
            let item = self.items.get(&item_id).unwrap();
            item.map_visible_to_content(vis_split_pos)
        };

        let before: String = text.chars().take(content_split_pos).collect();
        let after: String = text.chars().skip(content_split_pos).collect();

        let origin_left = item_left.unwrap_or(self.start);
        let origin_right = item_right.unwrap_or(self.end);

        let mut clock = base_clock;

        if !before.is_empty() {
            let before_id = ItemId::new(site, clock);
            clock += 1;

            let before_item = SeqItem {
                id: before_id,
                left_id: item_left,
                right_id: Some(item_id),
                origin_left: Some(origin_left),
                origin_right: Some(item_id),
                content: ItemContent::styled(&before, marks.clone()),
                is_deleted: false,
                deleted_ranges: Vec::new(),
                author,
                lamport: clock,
            };

            if let Some(left) = self.items.get_mut(&origin_left) {
                left.right_id = Some(before_id);
            }
            if let Some(orig) = self.items.get_mut(&item_id) {
                orig.left_id = Some(before_id);
            }
            self.items.insert(before_id, before_item);
        }

        if !after.is_empty() {
            let after_id = ItemId::new(site, clock);
            clock += 1;

            let after_item = SeqItem {
                id: after_id,
                left_id: Some(item_id),
                right_id: item_right.clone(),
                origin_left: Some(item_id),
                origin_right: Some(origin_right),
                content: ItemContent::styled(&after, marks),
                is_deleted: false,
                deleted_ranges: Vec::new(),
                author,
                lamport: clock,
            };

            if let Some(orig) = self.items.get_mut(&item_id) {
                orig.right_id = Some(after_id);
            }
            if let Some(right) = &item_right {
                if let Some(ri) = self.items.get_mut(right) {
                    ri.left_id = Some(after_id);
                }
            }
            self.items.insert(after_id, after_item);
        }

        if let Some(orig) = self.items.get_mut(&item_id) {
            orig.is_deleted = true;
            orig.deleted_ranges.clear();
        }

        let insert_left = if !before.is_empty() {
            let before_id = ItemId::new(site, base_clock);
            before_id
        } else {
            item_left.unwrap_or(self.start)
        };

        let insert_right = if !after.is_empty() {
            let after_id = ItemId::new(site, if !before.is_empty() { base_clock + 1 } else { base_clock });
            Some(after_id)
        } else {
            item_right.clone()
        };

        (
            insert_left,
            insert_right,
            item_id,
            item_right.unwrap_or(self.end),
        )
    }

    fn find_integrate_position(
        &self,
        left_id: &Option<ItemId>,
        right_id: &Option<ItemId>,
        new_item: &Op,
    ) -> (ItemId, Option<ItemId>) {
        let left = match left_id {
            Some(id) if self.items.contains_key(id) => *id,
            _ => self.start,
        };

        let right = match right_id {
            Some(id) if self.items.contains_key(id) => *id,
            _ => self.end,
        };

        let (new_site, new_clock) = match new_item {
            Op::Insert { id, .. } => (id.site, id.clock),
            Op::Transclude { id, .. } => (id.site, id.clock),
            _ => return (left, Some(right)),
        };

        let resolved_left_id = match left_id {
            Some(id) if self.items.contains_key(id) => *id,
            _ => left,
        };

        let mut scan = left;

        loop {
            let item = match self.items.get(&scan) {
                Some(i) => i,
                None => break,
            };

            let Some(next_id) = &item.right_id else {
                break;
            };

            if *next_id == right || *next_id == self.end {
                break;
            }

            let next_item = match self.items.get(next_id) {
                Some(i) => i,
                None => break,
            };

            let next_origin_resolved = match &next_item.origin_left {
                Some(ol) if self.items.contains_key(ol) => *ol,
                Some(_) => resolved_left_id,
                None => resolved_left_id,
            };

            let shares_context = next_origin_resolved == resolved_left_id;

            if !shares_context {
                scan = *next_id;
                continue;
            }

            if next_item.id.site == new_site {
                if new_clock > next_item.id.clock {
                    scan = *next_id;
                    continue;
                }
                break;
            }

            if new_site < next_item.id.site {
                break;
            }

            scan = *next_id;
        }

        let insert_after = scan;
        let insert_before = self
            .items
            .get(&insert_after)
            .and_then(|i| i.right_id.clone());

        (insert_after, insert_before)
    }

    pub fn to_string(&self) -> String {
        let mut result = String::new();
        let mut current = Some(self.start);

        while let Some(id) = current {
            if id == self.end {
                break;
            }
            let item = self.items.get(&id).expect("item must exist");
            if !item.is_fully_deleted() {
                result.push_str(&item.visible_text());
            }
            current = item.right_id.clone();
        }

        result
    }

    pub fn iter_visible(&self) -> impl Iterator<Item = (&ItemId, &ItemContent, &AuthorId)> {
        let mut current = Some(self.start);
        let end = self.end;

        std::iter::from_fn(move || {
            loop {
                let id = current.take()?;
                if id == end {
                    return None;
                }
                let item = self.items.get(&id)?;
                let right = item.right_id.clone();
                current = right;
                if !item.is_fully_deleted() && item.visible_char_count() > 0 {
                    return Some((&item.id, &item.content, &item.author));
                }
            }
        })
    }
}
