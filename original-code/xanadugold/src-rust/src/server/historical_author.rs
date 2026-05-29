use std::collections::HashMap;

use crate::edition::BeId;

const HISTORICAL_AUTHOR_ID_OFFSET: u64 = 1_000_000_000_000;

#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct HistoricalAuthor {
    pub be_id: BeId,
    pub name: String,
    pub display_name: String,
    pub birth_year: Option<i32>,
    pub death_year: Option<i32>,
    pub external_ids: HashMap<String, String>,
    pub source_bibliography: String,
    pub created_by: BeId,
    pub created_at: u64,
}

#[derive(Debug, Clone, PartialEq, Eq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct HistoricalAuthorRegistry {
    authors: HashMap<BeId, HistoricalAuthor>,
    name_index: HashMap<String, BeId>,
    next_id: u64,
}

impl HistoricalAuthorRegistry {
    pub fn new() -> Self {
        Self {
            authors: HashMap::new(),
            name_index: HashMap::new(),
            next_id: HISTORICAL_AUTHOR_ID_OFFSET,
        }
    }

    pub fn register(
        &mut self,
        name: String,
        display_name: String,
        birth_year: Option<i32>,
        death_year: Option<i32>,
        external_ids: HashMap<String, String>,
        source_bibliography: String,
        created_by: BeId,
        created_at: u64,
    ) -> Result<HistoricalAuthor, String> {
        let normalizedName = name.to_lowercase();
        if self.name_index.contains_key(&normalizedName) {
            return Err(format!("historical author '{}' already registered", name));
        }

        let be_id = self.next_id;
        self.next_id += 1;

        let author = HistoricalAuthor {
            be_id,
            name,
            display_name,
            birth_year,
            death_year,
            external_ids,
            source_bibliography,
            created_by,
            created_at,
        };

        self.name_index.insert(normalizedName, be_id);
        self.authors.insert(be_id, author.clone());
        Ok(author)
    }

    pub fn get(&self, be_id: BeId) -> Option<&HistoricalAuthor> {
        self.authors.get(&be_id)
    }

    pub fn get_by_name(&self, name: &str) -> Option<&HistoricalAuthor> {
        self.name_index
            .get(&name.to_lowercase())
            .and_then(|id| self.authors.get(id))
    }

    pub fn list(&self) -> Vec<&HistoricalAuthor> {
        let mut authors: Vec<&HistoricalAuthor> = self.authors.values().collect();
        authors.sort_by_key(|a| a.name.to_lowercase());
        authors
    }

    pub fn search(&self, query: &str) -> Vec<&HistoricalAuthor> {
        let lower = query.to_lowercase();
        self.authors
            .values()
            .filter(|a| {
                a.name.to_lowercase().contains(&lower)
                    || a.display_name.to_lowercase().contains(&lower)
            })
            .collect()
    }

    pub fn is_historical_id(be_id: BeId) -> bool {
        be_id >= HISTORICAL_AUTHOR_ID_OFFSET
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn register_and_get() {
        let mut reg = HistoricalAuthorRegistry::new();
        let author = reg
            .register(
                "Vitruvius".into(),
                "Vitruvius (c. 80\u{2013}15 BC)".into(),
                Some(-80),
                Some(-15),
                HashMap::new(),
                "De Architectura".into(),
                1,
                1000,
            )
            .unwrap();

        assert!(HistoricalAuthorRegistry::is_historical_id(author.be_id));

        let got = reg.get(author.be_id).unwrap();
        assert_eq!(got.name, "Vitruvius");
        assert_eq!(got.birth_year, Some(-80));
    }

    #[test]
    fn duplicate_name_rejected() {
        let mut reg = HistoricalAuthorRegistry::new();
        reg.register(
            "Shakespeare".into(),
            "William Shakespeare".into(),
            Some(1564),
            Some(1616),
            HashMap::new(),
            String::new(),
            1,
            1000,
        )
        .unwrap();

        let result = reg.register(
            "shakespeare".into(),
            "Different".into(),
            None,
            None,
            HashMap::new(),
            String::new(),
            1,
            1000,
        );
        assert!(result.is_err());
    }

    #[test]
    fn get_by_name_case_insensitive() {
        let mut reg = HistoricalAuthorRegistry::new();
        reg.register(
            "Vitruvius".into(),
            "Vitruvius".into(),
            None,
            None,
            HashMap::new(),
            String::new(),
            1,
            1000,
        )
        .unwrap();

        assert!(reg.get_by_name("vitruvius").is_some());
        assert!(reg.get_by_name("VITRUVIUS").is_some());
    }

    #[test]
    fn search_by_partial_name() {
        let mut reg = HistoricalAuthorRegistry::new();
        reg.register(
            "Vitruvius".into(),
            "Vitruvius (c. 80\u{2013}15 BC)".into(),
            None,
            None,
            HashMap::new(),
            String::new(),
            1,
            1000,
        )
        .unwrap();
        reg.register(
            "Shakespeare".into(),
            "William Shakespeare".into(),
            None,
            None,
            HashMap::new(),
            String::new(),
            1,
            1000,
        )
        .unwrap();

        let results = reg.search("ruv");
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].name, "Vitruvius");
    }

    #[test]
    fn list_sorted_alphabetically() {
        let mut reg = HistoricalAuthorRegistry::new();
        reg.register(
            "Shakespeare".into(),
            "William Shakespeare".into(),
            None,
            None,
            HashMap::new(),
            String::new(),
            1,
            1000,
        )
        .unwrap();
        reg.register(
            "Austen".into(),
            "Jane Austen".into(),
            None,
            None,
            HashMap::new(),
            String::new(),
            1,
            1000,
        )
        .unwrap();

        let list = reg.list();
        assert_eq!(list[0].name, "Austen");
        assert_eq!(list[1].name, "Shakespeare");
    }
}
