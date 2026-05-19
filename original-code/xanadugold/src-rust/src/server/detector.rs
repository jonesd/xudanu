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
    fn subscription_id(&self) -> u16 { u16::MAX }
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
