use std::sync::atomic::{AtomicBool, AtomicU64, Ordering};
use std::sync::{Arc, Condvar, Mutex};

use super::detector::{Detector, Event};

pub struct OperationGuard {
    tracker: Arc<ConsequenceTracker>,
    op_id: u64,
}

impl OperationGuard {
    pub fn new(tracker: Arc<ConsequenceTracker>, op_id: u64) -> Self {
        OperationGuard { tracker, op_id }
    }
}

impl Drop for OperationGuard {
    fn drop(&mut self) {
        self.tracker.end_operation(self.op_id);
    }
}

pub struct WriteGuard {
    barrier: Arc<WriteBarrier>,
}

impl WriteGuard {
    pub fn new(barrier: Arc<WriteBarrier>) -> Self {
        barrier.begin_write();
        WriteGuard { barrier }
    }
}

impl Drop for WriteGuard {
    fn drop(&mut self) {
        self.barrier.end_write();
    }
}

pub struct WaitDetector {
    triggered: AtomicBool,
    operation_id: u64,
    on_done: Mutex<Option<Box<dyn FnOnce() + Send + Sync>>>,
}

impl std::fmt::Debug for WaitDetector {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("WaitDetector")
            .field("triggered", &self.triggered)
            .field("operation_id", &self.operation_id)
            .finish()
    }
}

impl WaitDetector {
    pub fn new(operation_id: u64) -> Self {
        WaitDetector {
            triggered: AtomicBool::new(false),
            operation_id,
            on_done: Mutex::new(None),
        }
    }

    pub fn with_callback(operation_id: u64, callback: Box<dyn FnOnce() + Send + Sync>) -> Self {
        WaitDetector {
            triggered: AtomicBool::new(false),
            operation_id,
            on_done: Mutex::new(Some(callback)),
        }
    }

    pub fn done(&self) {
        if !self.triggered.swap(true, Ordering::SeqCst) {
            if let Some(cb) = self.on_done.lock().unwrap().take() {
                cb();
            }
        }
    }

    pub fn is_done(&self) -> bool {
        self.triggered.load(Ordering::SeqCst)
    }

    pub fn operation_id(&self) -> u64 {
        self.operation_id
    }
}

impl Detector for WaitDetector {
    fn on_event(&mut self, event: &Event) {
        if let Event::Done { operation_id } = event {
            if *operation_id == self.operation_id {
                self.done();
            }
        }
    }
}

#[derive(Debug)]
pub struct BlockingWaitDetector {
    inner: WaitDetector,
    trigger: Arc<(Mutex<bool>, Condvar)>,
}

impl BlockingWaitDetector {
    pub fn new(operation_id: u64) -> Self {
        let trigger = Arc::new((Mutex::new(false), Condvar::new()));
        let trigger_clone = trigger.clone();
        BlockingWaitDetector {
            inner: WaitDetector::with_callback(
                operation_id,
                Box::new(move || {
                    let (lock, cvar) = &*trigger_clone;
                    let mut done = lock.lock().unwrap();
                    *done = true;
                    cvar.notify_all();
                }),
            ),
            trigger,
        }
    }

    pub fn wait(&self) {
        let (lock, cvar) = &*self.trigger;
        let mut done = lock.lock().unwrap();
        while !*done {
            done = cvar.wait(done).unwrap();
        }
    }

    pub fn wait_timeout(&self, timeout: std::time::Duration) -> bool {
        let (lock, cvar) = &*self.trigger;
        let mut done = lock.lock().unwrap();
        let start = std::time::Instant::now();
        while !*done {
            let remaining = timeout.saturating_sub(start.elapsed());
            if remaining.is_zero() {
                return false;
            }
            let result = cvar.wait_timeout(done, remaining).unwrap();
            done = result.0;
            if result.1.timed_out() {
                return false;
            }
        }
        true
    }

    pub fn is_done(&self) -> bool {
        self.inner.is_done()
    }
}

impl Detector for BlockingWaitDetector {
    fn on_event(&mut self, event: &Event) {
        self.inner.on_event(event);
    }
}

#[derive(Debug, Default)]
pub struct ConsequenceTracker {
    pending_count: AtomicU64,
    next_op_id: AtomicU64,
    waiters: Mutex<Vec<Arc<(Mutex<bool>, Condvar)>>>,
}

impl ConsequenceTracker {
    pub fn new() -> Self {
        ConsequenceTracker::default()
    }

    pub fn begin_operation(&self) -> u64 {
        self.pending_count.fetch_add(1, Ordering::SeqCst);
        self.next_op_id.fetch_add(1, Ordering::SeqCst)
    }

    pub fn end_operation(&self, operation_id: u64) {
        let _ = operation_id;
        let prev = self.pending_count.fetch_sub(1, Ordering::SeqCst);
        if prev == 1 {
            let mut waiters = self.waiters.lock().unwrap();
            for waiter in waiters.drain(..) {
                let (lock, cvar) = &*waiter;
                let mut done = lock.lock().unwrap();
                *done = true;
                cvar.notify_all();
            }
        }
    }

    pub fn pending_count(&self) -> u64 {
        self.pending_count.load(Ordering::SeqCst)
    }

    pub fn wait_for_consequences(&self) {
        if self.pending_count.load(Ordering::SeqCst) == 0 {
            return;
        }
        let waiter = Arc::new((Mutex::new(false), Condvar::new()));
        self.waiters.lock().unwrap().push(waiter.clone());
        if self.pending_count.load(Ordering::SeqCst) == 0 {
            let (lock, cvar) = &*waiter;
            let mut done = lock.lock().unwrap();
            *done = true;
            cvar.notify_all();
            return;
        }
        let (lock, cvar) = &*waiter;
        let mut done = lock.lock().unwrap();
        while !*done {
            done = cvar.wait(done).unwrap();
        }
    }

    pub fn wait_for_consequences_timeout(&self, timeout: std::time::Duration) -> bool {
        if self.pending_count.load(Ordering::SeqCst) == 0 {
            return true;
        }
        let waiter = Arc::new((Mutex::new(false), Condvar::new()));
        self.waiters.lock().unwrap().push(waiter.clone());
        if self.pending_count.load(Ordering::SeqCst) == 0 {
            return true;
        }
        let (lock, cvar) = &*waiter;
        let mut done = lock.lock().unwrap();
        let start = std::time::Instant::now();
        while !*done {
            let remaining = timeout.saturating_sub(start.elapsed());
            if remaining.is_zero() {
                return false;
            }
            let result = cvar.wait_timeout(done, remaining).unwrap();
            done = result.0;
            if result.1.timed_out() {
                return false;
            }
        }
        true
    }
}

#[derive(Debug)]
pub struct WriteBarrier {
    pending_writes: AtomicU64,
    write_seq: AtomicU64,
    waiters: Mutex<Vec<Arc<(Mutex<bool>, Condvar)>>>,
}

impl Default for WriteBarrier {
    fn default() -> Self {
        WriteBarrier {
            pending_writes: AtomicU64::new(0),
            write_seq: AtomicU64::new(0),
            waiters: Mutex::new(Vec::new()),
        }
    }
}

impl WriteBarrier {
    pub fn new() -> Self {
        WriteBarrier::default()
    }

    pub fn begin_write(&self) -> u64 {
        self.pending_writes.fetch_add(1, Ordering::SeqCst);
        self.write_seq.fetch_add(1, Ordering::SeqCst)
    }

    pub fn end_write(&self) {
        let prev = self.pending_writes.fetch_sub(1, Ordering::SeqCst);
        if prev == 1 {
            let mut waiters = self.waiters.lock().unwrap();
            for waiter in waiters.drain(..) {
                let (lock, cvar) = &*waiter;
                let mut done = lock.lock().unwrap();
                *done = true;
                cvar.notify_all();
            }
        }
    }

    pub fn pending_writes(&self) -> u64 {
        self.pending_writes.load(Ordering::SeqCst)
    }

    pub fn write_seq(&self) -> u64 {
        self.write_seq.load(Ordering::SeqCst)
    }

    pub fn wait_for_write(&self) {
        if self.pending_writes.load(Ordering::SeqCst) == 0 {
            return;
        }
        let waiter = Arc::new((Mutex::new(false), Condvar::new()));
        self.waiters.lock().unwrap().push(waiter.clone());
        if self.pending_writes.load(Ordering::SeqCst) == 0 {
            let (lock, cvar) = &*waiter;
            let mut done = lock.lock().unwrap();
            *done = true;
            cvar.notify_all();
            return;
        }
        let (lock, cvar) = &*waiter;
        let mut done = lock.lock().unwrap();
        while !*done {
            done = cvar.wait(done).unwrap();
        }
    }

    pub fn wait_for_write_timeout(&self, timeout: std::time::Duration) -> bool {
        if self.pending_writes.load(Ordering::SeqCst) == 0 {
            return true;
        }
        let waiter = Arc::new((Mutex::new(false), Condvar::new()));
        self.waiters.lock().unwrap().push(waiter.clone());
        if self.pending_writes.load(Ordering::SeqCst) == 0 {
            return true;
        }
        let (lock, cvar) = &*waiter;
        let mut done = lock.lock().unwrap();
        let start = std::time::Instant::now();
        while !*done {
            let remaining = timeout.saturating_sub(start.elapsed());
            if remaining.is_zero() {
                return false;
            }
            let result = cvar.wait_timeout(done, remaining).unwrap();
            done = result.0;
            if result.1.timed_out() {
                return false;
            }
        }
        true
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn wait_detector_done() {
        let wd = WaitDetector::new(1);
        assert!(!wd.is_done());
        wd.done();
        assert!(wd.is_done());
    }

    #[test]
    fn wait_detector_idempotent() {
        let wd = WaitDetector::new(1);
        wd.done();
        wd.done();
        assert!(wd.is_done());
    }

    #[test]
    fn wait_detector_responds_to_done_event() {
        let mut wd = WaitDetector::new(42);
        wd.on_event(&Event::Done { operation_id: 99 });
        assert!(!wd.is_done());
        wd.on_event(&Event::Done { operation_id: 42 });
        assert!(wd.is_done());
    }

    #[test]
    fn blocking_wait_detector_wait() {
        let mut wd = BlockingWaitDetector::new(1);
        assert!(!wd.is_done());
        wd.on_event(&Event::Done { operation_id: 1 });
        wd.wait();
        assert!(wd.is_done());
    }

    #[test]
    fn blocking_wait_detector_timeout() {
        let wd = BlockingWaitDetector::new(1);
        let result = wd.wait_timeout(std::time::Duration::from_millis(10));
        assert!(!result);
    }

    #[test]
    fn blocking_wait_detector_timeout_success() {
        let mut wd = BlockingWaitDetector::new(1);
        wd.on_event(&Event::Done { operation_id: 1 });
        let result = wd.wait_timeout(std::time::Duration::from_secs(5));
        assert!(result);
    }

    #[test]
    fn consequence_tracker_begin_end() {
        let ct = ConsequenceTracker::new();
        assert_eq!(ct.pending_count(), 0);

        let op1 = ct.begin_operation();
        let op2 = ct.begin_operation();
        assert_eq!(ct.pending_count(), 2);

        ct.end_operation(op1);
        assert_eq!(ct.pending_count(), 1);

        ct.end_operation(op2);
        assert_eq!(ct.pending_count(), 0);
    }

    #[test]
    fn consequence_tracker_wait_immediate() {
        let ct = ConsequenceTracker::new();
        ct.wait_for_consequences();
    }

    #[test]
    fn consequence_tracker_wait_resolves() {
        let ct = Arc::new(ConsequenceTracker::new());
        let ct_clone = ct.clone();

        let op = ct.begin_operation();
        assert_eq!(ct.pending_count(), 1);

        let handle = std::thread::spawn(move || {
            std::thread::sleep(std::time::Duration::from_millis(20));
            ct_clone.end_operation(op);
        });

        ct.wait_for_consequences();
        assert_eq!(ct.pending_count(), 0);
        handle.join().unwrap();
    }

    #[test]
    fn consequence_tracker_timeout_returns_false() {
        let ct = ConsequenceTracker::new();
        let _op = ct.begin_operation();
        let result = ct.wait_for_consequences_timeout(std::time::Duration::from_millis(10));
        assert!(!result);
    }

    #[test]
    fn consequence_tracker_multiple_waiters() {
        let ct = Arc::new(ConsequenceTracker::new());
        let mut handles = Vec::new();

        let op = ct.begin_operation();

        for _ in 0..3 {
            let ct_clone = ct.clone();
            handles.push(std::thread::spawn(move || {
                ct_clone.wait_for_consequences();
                true
            }));
        }

        std::thread::sleep(std::time::Duration::from_millis(20));
        ct.end_operation(op);

        for handle in handles {
            assert!(handle.join().unwrap());
        }
        assert_eq!(ct.pending_count(), 0);
    }

    #[test]
    fn write_barrier_begin_end() {
        let wb = WriteBarrier::new();
        assert_eq!(wb.pending_writes(), 0);

        wb.begin_write();
        assert_eq!(wb.pending_writes(), 1);

        wb.end_write();
        assert_eq!(wb.pending_writes(), 0);
    }

    #[test]
    fn write_barrier_wait_immediate() {
        let wb = WriteBarrier::new();
        wb.wait_for_write();
    }

    #[test]
    fn write_barrier_wait_resolves() {
        let wb = Arc::new(WriteBarrier::new());
        let wb_clone = wb.clone();

        wb.begin_write();

        let handle = std::thread::spawn(move || {
            std::thread::sleep(std::time::Duration::from_millis(20));
            wb_clone.end_write();
        });

        wb.wait_for_write();
        assert_eq!(wb.pending_writes(), 0);
        handle.join().unwrap();
    }

    #[test]
    fn write_barrier_timeout_returns_false() {
        let wb = WriteBarrier::new();
        wb.begin_write();
        let result = wb.wait_for_write_timeout(std::time::Duration::from_millis(10));
        assert!(!result);
    }

    #[test]
    fn write_barrier_multiple_waiters() {
        let wb = Arc::new(WriteBarrier::new());
        let mut handles = Vec::new();

        wb.begin_write();

        for _ in 0..3 {
            let wb_clone = wb.clone();
            handles.push(std::thread::spawn(move || {
                wb_clone.wait_for_write();
                true
            }));
        }

        std::thread::sleep(std::time::Duration::from_millis(20));
        wb.end_write();

        for handle in handles {
            assert!(handle.join().unwrap());
        }
        assert_eq!(wb.pending_writes(), 0);
    }

    #[test]
    fn write_barrier_seq_increments() {
        let wb = WriteBarrier::new();
        let s1 = wb.begin_write();
        let s2 = wb.begin_write();
        assert!(s2 > s1);
        assert_eq!(wb.write_seq(), s2 + 1);
    }

    #[test]
    fn wait_detector_with_callback() {
        let called = Arc::new(AtomicBool::new(false));
        let called_clone = called.clone();
        let wd = WaitDetector::with_callback(
            1,
            Box::new(move || {
                called_clone.store(true, Ordering::SeqCst);
            }),
        );
        assert!(!called.load(Ordering::SeqCst));
        wd.done();
        assert!(called.load(Ordering::SeqCst));
    }

    #[test]
    fn consequence_tracker_nested_ops() {
        let ct = ConsequenceTracker::new();
        let op1 = ct.begin_operation();
        let op2 = ct.begin_operation();
        let op3 = ct.begin_operation();
        assert_eq!(ct.pending_count(), 3);

        ct.end_operation(op2);
        assert_eq!(ct.pending_count(), 2);

        ct.end_operation(op1);
        assert_eq!(ct.pending_count(), 1);

        ct.end_operation(op3);
        assert_eq!(ct.pending_count(), 0);
    }

    #[test]
    fn write_barrier_nested_writes() {
        let wb = WriteBarrier::new();
        wb.begin_write();
        wb.begin_write();
        wb.begin_write();
        assert_eq!(wb.pending_writes(), 3);

        wb.end_write();
        assert_eq!(wb.pending_writes(), 2);

        wb.end_write();
        wb.end_write();
        assert_eq!(wb.pending_writes(), 0);
    }
}
