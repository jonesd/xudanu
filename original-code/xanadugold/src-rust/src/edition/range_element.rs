#[derive(Debug, Clone, PartialEq, Eq, Hash)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct RangeElementId(pub u64);

impl RangeElementId {
    pub fn new(id: u64) -> Self {
        RangeElementId(id)
    }
}

#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub enum RangeElement {
    Data {
        bytes: Vec<u8>,
    },
    Text {
        text: String,
    },
    Edition {
        edition_id: RangeElementId,
    },
    Label {
        label_id: RangeElementId,
        inner: Box<RangeElement>,
    },
    PlaceHolder {
        id: RangeElementId,
    },
    IDHolder {
        id: u64,
    },
    Work {
        work_id: RangeElementId,
    },
}

impl RangeElement {
    pub fn data(bytes: Vec<u8>) -> Self {
        RangeElement::Data { bytes }
    }

    pub fn text(s: impl Into<String>) -> Self {
        RangeElement::Text { text: s.into() }
    }

    pub fn edition(id: u64) -> Self {
        RangeElement::Edition {
            edition_id: RangeElementId::new(id),
        }
    }

    pub fn placeholder(id: u64) -> Self {
        RangeElement::PlaceHolder {
            id: RangeElementId::new(id),
        }
    }

    pub fn label(id: u64, inner: RangeElement) -> Self {
        RangeElement::Label {
            label_id: RangeElementId::new(id),
            inner: Box::new(inner),
        }
    }

    pub fn id_holder(id: u64) -> Self {
        RangeElement::IDHolder { id }
    }

    pub fn work(id: u64) -> Self {
        RangeElement::Work {
            work_id: RangeElementId::new(id),
        }
    }

    pub fn is_data(&self) -> bool {
        matches!(self, RangeElement::Data { .. })
    }

    pub fn is_text(&self) -> bool {
        matches!(self, RangeElement::Text { .. })
    }

    pub fn is_edition(&self) -> bool {
        matches!(self, RangeElement::Edition { .. })
    }

    pub fn as_text(&self) -> Option<&str> {
        match self {
            RangeElement::Text { text } => Some(text),
            _ => None,
        }
    }

    pub fn as_bytes(&self) -> Option<&[u8]> {
        match self {
            RangeElement::Data { bytes } => Some(bytes),
            _ => None,
        }
    }
}

#[derive(Debug, Clone, PartialEq)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub struct Carrier {
    pub label: Option<RangeElementId>,
    pub element: RangeElement,
}

impl Carrier {
    pub fn new(element: RangeElement) -> Self {
        Carrier {
            label: None,
            element,
        }
    }

    pub fn labelled(label_id: RangeElementId, element: RangeElement) -> Self {
        Carrier {
            label: Some(label_id),
            element,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn text_element() {
        let e = RangeElement::text("hello");
        assert!(e.is_text());
        assert_eq!(e.as_text(), Some("hello"));
        assert!(!e.is_data());
    }

    #[test]
    fn data_element() {
        let e = RangeElement::data(vec![1, 2, 3]);
        assert!(e.is_data());
        assert_eq!(e.as_bytes(), Some(&[1u8, 2, 3][..]));
    }

    #[test]
    fn edition_element() {
        let e = RangeElement::edition(42);
        assert!(e.is_edition());
    }

    #[test]
    fn label_wraps_inner() {
        let inner = RangeElement::text("hi");
        let labelled = RangeElement::label(7, inner.clone());
        match &labelled {
            RangeElement::Label { label_id, inner: boxed } => {
                assert_eq!(label_id.0, 7);
                assert_eq!(**boxed, inner);
            }
            _ => panic!("expected Label"),
        }
    }

    #[test]
    fn serde_round_trip_text() {
        #[cfg(feature = "serde")]
        {
            let e = RangeElement::text("hello world");
            let json = serde_json::to_string(&e).unwrap();
            let e2: RangeElement = serde_json::from_str(&json).unwrap();
            assert_eq!(e, e2);
        }
    }

    #[test]
    fn serde_round_trip_label() {
        #[cfg(feature = "serde")]
        {
            let e = RangeElement::label(7, RangeElement::text("hi"));
            let json = serde_json::to_string(&e).unwrap();
            let e2: RangeElement = serde_json::from_str(&json).unwrap();
            assert_eq!(e, e2);
        }
    }

    #[test]
    fn carrier_unlabelled() {
        let c = Carrier::new(RangeElement::text("x"));
        assert!(c.label.is_none());
    }

    #[test]
    fn carrier_labelled() {
        let c = Carrier::labelled(RangeElementId::new(1), RangeElement::text("x"));
        assert!(c.label.is_some());
    }
}
