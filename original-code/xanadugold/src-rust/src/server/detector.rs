use crate::edition::BeId;
use crate::edition::XnRegion;

#[derive(Debug, Clone)]
#[cfg_attr(feature = "serde", derive(serde::Serialize, serde::Deserialize))]
pub enum Event {
    WorkGrabbed {
        work_be_id: BeId,
        session_id: super::session::SessionId,
    },
    WorkReleased {
        work_be_id: BeId,
        session_id: super::session::SessionId,
    },
    WorkRevised {
        work_be_id: BeId,
        revision: u64,
        session_id: super::session::SessionId,
    },
    RangeFilled {
        edition_be_id: BeId,
        region: XnRegion,
    },
    ElementFilled {
        element_be_id: BeId,
    },
    Done {
        operation_id: u64,
    },
}

pub trait Detector: Send + Sync + std::fmt::Debug {
    fn on_event(&mut self, event: &Event);
    fn subscription_id(&self) -> u16 {
        u16::MAX
    }
}

pub struct FnDetector<F>
where
    F: FnMut(&Event) + Send + Sync,
{
    callback: F,
}

impl<F> FnDetector<F>
where
    F: FnMut(&Event) + Send + Sync,
{
    pub fn new(callback: F) -> Self {
        FnDetector { callback }
    }
}

impl<F> Detector for FnDetector<F>
where
    F: FnMut(&Event) + Send + Sync,
{
    fn on_event(&mut self, event: &Event) {
        (self.callback)(event)
    }
}

impl<F> std::fmt::Debug for FnDetector<F>
where
    F: FnMut(&Event) + Send + Sync,
{
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("FnDetector").finish()
    }
}

#[derive(Debug, Default)]
pub(crate) struct DetectorList {
    detectors: Vec<Box<dyn Detector>>,
}

impl DetectorList {
    pub fn new() -> Self {
        DetectorList {
            detectors: Vec::new(),
        }
    }

    pub fn add(&mut self, detector: Box<dyn Detector>) {
        self.detectors.push(detector);
    }

    pub fn fire(&mut self, event: &Event) {
        for detector in &mut self.detectors {
            detector.on_event(event);
        }
    }

    pub fn _len(&self) -> usize {
        self.detectors.len()
    }

    pub fn _is_empty(&self) -> bool {
        self.detectors.is_empty()
    }

    pub fn remove(&mut self, sub_id: u16) -> bool {
        let before = self.detectors.len();
        self.detectors.retain(|d| d.subscription_id() != sub_id);
        self.detectors.len() < before
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::server::SessionId;
    use std::sync::{Arc, Mutex};

    #[derive(Debug)]
    struct IdDetector {
        id: u16,
    }
    impl IdDetector {
        fn new(id: u16) -> Self {
            Self { id }
        }
    }
    impl Detector for IdDetector {
        fn on_event(&mut self, _event: &Event) {}
        fn subscription_id(&self) -> u16 {
            self.id
        }
    }

    fn tag_from(ev: &Event) -> &'static str {
        match ev {
            Event::WorkGrabbed { .. } => "grabbed",
            Event::WorkReleased { .. } => "released",
            Event::WorkRevised { .. } => "revised",
            Event::RangeFilled { .. } => "range",
            Event::ElementFilled { .. } => "element",
            Event::Done { .. } => "done",
        }
    }

    #[test]
    fn fn_detector_invokes_callback() {
        let log: Arc<Mutex<Vec<&'static str>>> = Arc::new(Mutex::new(Vec::new()));
        let lc = log.clone();
        let mut det = FnDetector::new(move |ev: &Event| {
            lc.lock().unwrap().push(tag_from(ev));
        });
        det.on_event(&Event::Done { operation_id: 1 });
        det.on_event(&Event::ElementFilled { element_be_id: 9 });
        assert_eq!(log.lock().unwrap().as_slice(), &["done", "element"]);
    }

    #[test]
    fn fn_detector_default_subscription_id() {
        let det = FnDetector::new(|_ev: &Event| {});
        assert_eq!(det.subscription_id(), u16::MAX);
    }

    #[test]
    fn detector_list_new_is_empty() {
        let list = DetectorList::new();
        assert!(list._is_empty());
        assert_eq!(list._len(), 0);
    }

    #[test]
    fn detector_list_add_increments_len() {
        let mut list = DetectorList::new();
        list.add(Box::new(FnDetector::new(|_: &Event| {})));
        list.add(Box::new(FnDetector::new(|_: &Event| {})));
        assert_eq!(list._len(), 2);
        assert!(!list._is_empty());
    }

    #[test]
    fn detector_list_fire_fans_out_to_all() {
        let a: Arc<Mutex<usize>> = Arc::new(Mutex::new(0));
        let b: Arc<Mutex<usize>> = Arc::new(Mutex::new(0));
        let la = a.clone();
        let lb = b.clone();
        let mut list = DetectorList::new();
        list.add(Box::new(FnDetector::new(move |_: &Event| {
            *la.lock().unwrap() += 1;
        })));
        list.add(Box::new(FnDetector::new(move |_: &Event| {
            *lb.lock().unwrap() += 1;
        })));
        list.fire(&Event::Done { operation_id: 0 });
        assert_eq!(*a.lock().unwrap(), 1);
        assert_eq!(*b.lock().unwrap(), 1);
        list.fire(&Event::Done { operation_id: 1 });
        assert_eq!(*a.lock().unwrap(), 2);
        assert_eq!(*b.lock().unwrap(), 2);
    }

    #[test]
    fn detector_list_fire_work_grabbed_variant() {
        let log: Arc<Mutex<Vec<u64>>> = Arc::new(Mutex::new(Vec::new()));
        let lc = log.clone();
        let mut list = DetectorList::new();
        list.add(Box::new(FnDetector::new(move |ev: &Event| {
            if let Event::WorkGrabbed { work_be_id, .. } = ev {
                lc.lock().unwrap().push(*work_be_id);
            }
        })));
        list.fire(&Event::WorkGrabbed {
            work_be_id: 5,
            session_id: SessionId::new(1),
        });
        assert_eq!(log.lock().unwrap().as_slice(), &[5]);
    }

    #[test]
    fn detector_list_fire_work_revised_variant() {
        let log: Arc<Mutex<Vec<(u64, u64)>>> = Arc::new(Mutex::new(Vec::new()));
        let lc = log.clone();
        let mut list = DetectorList::new();
        list.add(Box::new(FnDetector::new(move |ev: &Event| {
            if let Event::WorkRevised {
                work_be_id,
                revision,
                ..
            } = ev
            {
                lc.lock().unwrap().push((*work_be_id, *revision));
            }
        })));
        list.fire(&Event::WorkRevised {
            work_be_id: 9,
            revision: 3,
            session_id: SessionId::new(2),
        });
        assert_eq!(log.lock().unwrap().as_slice(), &[(9, 3)]);
    }

    #[test]
    fn detector_list_fire_range_element_done_variants() {
        let log: Arc<Mutex<Vec<&'static str>>> = Arc::new(Mutex::new(Vec::new()));
        let lc = log.clone();
        let mut list = DetectorList::new();
        list.add(Box::new(FnDetector::new(move |ev: &Event| {
            lc.lock().unwrap().push(tag_from(ev));
        })));
        list.fire(&Event::RangeFilled {
            edition_be_id: 1,
            region: XnRegion::interval(0, 10),
        });
        list.fire(&Event::ElementFilled { element_be_id: 2 });
        list.fire(&Event::Done { operation_id: 7 });
        assert_eq!(
            log.lock().unwrap().as_slice(),
            &["range", "element", "done"]
        );
    }

    #[test]
    fn detector_list_remove_default_subscription_returns_true() {
        let mut list = DetectorList::new();
        list.add(Box::new(FnDetector::new(|_: &Event| {})));
        assert!(list.remove(u16::MAX));
        assert_eq!(list._len(), 0);
        assert!(list._is_empty());
    }

    #[test]
    fn detector_list_remove_unknown_returns_false() {
        let mut list = DetectorList::new();
        assert!(!list.remove(u16::MAX));
        assert!(!list.remove(7));
    }

    #[test]
    fn detector_list_removed_detector_stops_receiving() {
        let log: Arc<Mutex<usize>> = Arc::new(Mutex::new(0));
        let lc = log.clone();
        let mut list = DetectorList::new();
        list.add(Box::new(FnDetector::new(move |_: &Event| {
            *lc.lock().unwrap() += 1;
        })));
        list.fire(&Event::Done { operation_id: 0 });
        assert_eq!(*log.lock().unwrap(), 1);
        assert!(list.remove(u16::MAX));
        list.fire(&Event::Done { operation_id: 1 });
        list.fire(&Event::Done { operation_id: 2 });
        assert_eq!(*log.lock().unwrap(), 1);
    }

    #[test]
    fn detector_list_remove_is_selective_by_subscription_id() {
        let mut list = DetectorList::new();
        list.add(Box::new(IdDetector::new(1)));
        list.add(Box::new(IdDetector::new(2)));
        assert_eq!(list._len(), 2);

        assert!(list.remove(1));
        assert_eq!(list._len(), 1);
        assert!(!list.remove(1));

        assert!(list.remove(2));
        assert_eq!(list._len(), 0);
    }

    #[test]
    fn detector_list_default_removes_all_default_detectors() {
        let mut list = DetectorList::new();
        list.add(Box::new(FnDetector::new(|_: &Event| {})));
        list.add(Box::new(FnDetector::new(|_: &Event| {})));
        list.add(Box::new(FnDetector::new(|_: &Event| {})));
        assert_eq!(list._len(), 3);
        assert!(list.remove(u16::MAX));
        assert_eq!(list._len(), 0);
    }
}
