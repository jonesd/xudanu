//! Backend dispatch benchmarks.
//!
//! Run:  cargo bench --features server
//! Compare baselines:
//!   cargo bench --features server -- --save-baseline before
//!   cargo bench --features server -- --baseline before
//!
//! Results land in `target/criterion/`.

mod common;

use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;

use criterion::{criterion_group, criterion_main, BenchmarkId, Criterion, Throughput};
use xudanu::server::transport::{EditionPayload, WireRequest};

/// Concurrent read-only ops (work_list) at various work counts.
fn bench_work_list(c: &mut Criterion) {
    let mut group = c.benchmark_group("work_list");
    for &n in &[100, 500, 1000, 5000] {
        group.throughput(Throughput::Elements(n as u64));
        group.bench_with_input(BenchmarkId::from_parameter(n), &n, |b, &n| {
            let bench = common::BenchState::seeded(n);
            b.iter(|| {
                bench.dispatch(WireRequest::WorkList {
                    offset: None,
                    limit: None,
                });
            });
        });
    }
    group.finish();
}

/// WorkGetEdition — single-work read latency.
fn bench_work_get_edition(c: &mut Criterion) {
    let bench = common::BenchState::seeded(100);
    let work_id = bench.work_ids[0];

    c.bench_function("work_get_edition", |b| {
        b.iter(|| {
            bench.dispatch(WireRequest::WorkGetEdition { work_id });
        });
    });
}

/// WorkCreate — write-path latency.
fn bench_work_create(c: &mut Criterion) {
    let bench = common::BenchState::seeded(0);

    c.bench_function("work_create", |b| {
        let mut i = 0u64;
        b.iter(|| {
            i += 1;
            bench.dispatch(WireRequest::WorkCreate {
                edition: EditionPayload::Text(format!("Bench work {}", i)),
            });
        });
    });
}

/// Concurrent read throughput: many WorkList calls in sequence.
/// (B7 will make these truly concurrent via read-lock; this measures the
/// serialized baseline.)
fn bench_concurrent_reads_serial(c: &mut Criterion) {
    let bench = common::BenchState::seeded(100);

    c.bench_function("concurrent_reads_serial_8x", |b| {
        b.iter(|| {
            for _ in 0..8 {
                bench.dispatch(WireRequest::WorkList {
                    offset: None,
                    limit: None,
                });
            }
        });
    });
}

/// CrdtSyncFullState — the read path B7 aims to speed up.
fn bench_crdt_full_state(c: &mut Criterion) {
    let bench = common::BenchState::seeded(1);
    let work_id = bench.work_ids[0];

    c.bench_function("crdt_sync_full_state", |b| {
        b.iter(|| {
            bench.dispatch_discard(WireRequest::CrdtSyncFullState { work_id });
        });
    });
}

/// Dispatch latency during checkpoint vs idle (B6 verification).
fn bench_checkpoint_impact(c: &mut Criterion) {
    let mut group = c.benchmark_group("checkpoint_impact");

    let data_dir = std::env::temp_dir().join(format!(
        "xudanu_bench_ckpt_{}_{}",
        std::process::id(),
        std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_millis()
    ));
    let _ = std::fs::remove_dir_all(&data_dir);
    std::fs::create_dir_all(&data_dir).unwrap();

    let bench = common::BenchState::seeded_with_data_dir(100, &data_dir);

    group.bench_function("idle", |b| {
        b.iter(|| {
            bench.dispatch(WireRequest::WorkList {
                offset: None,
                limit: None,
            });
        });
    });

    let cancel = Arc::new(AtomicBool::new(false));
    let server_handle = bench.state.clone();
    let cancel_clone = cancel.clone();
    let ckpt_thread = std::thread::spawn(move || {
        let rt = tokio::runtime::Runtime::new().unwrap();
        rt.block_on(async move {
            while !cancel_clone.load(Ordering::Relaxed) {
                let _ = server_handle.server.checkpoint_async().await;
            }
        });
    });

    std::thread::sleep(std::time::Duration::from_millis(100));

    group.bench_function("during_checkpoint", |b| {
        b.iter(|| {
            bench.dispatch(WireRequest::WorkList {
                offset: None,
                limit: None,
            });
        });
    });

    cancel.store(true, Ordering::Relaxed);
    let _ = ckpt_thread.join();
    let _ = std::fs::remove_dir_all(&data_dir);

    group.finish();
}

/// 8 truly concurrent reads via threads — the B7 target metric.
/// Measures wall-clock time for 8 threads to each complete one read, starting simultaneously.
fn bench_concurrent_reads_parallel(c: &mut Criterion) {
    let bench = common::BenchState::seeded(100);
    let state = std::sync::Arc::new(bench.state.clone());
    let session = bench.session;

    let mut group = c.benchmark_group("concurrent_reads");
    for &nthreads in &[1, 8] {
        group.bench_function(format!("parallel_{}x", nthreads), |b| {
            b.iter(|| {
                let barrier = std::sync::Arc::new(std::sync::Barrier::new(nthreads));
                let handles: Vec<_> = (0..nthreads)
                    .map(|_| {
                        let state = state.clone();
                        let barrier = barrier.clone();
                        std::thread::spawn(move || {
                            barrier.wait();
                            let _ = xudanu::server::transport::dispatch::dispatch(
                                &state,
                                session,
                                WireRequest::WorkList {
                                    offset: None,
                                    limit: None,
                                },
                            );
                        })
                    })
                    .collect();
                for h in handles {
                    h.join().unwrap();
                }
            });
        });
    }
    group.finish();
}

criterion_group!(
    benches,
    bench_work_list,
    bench_work_get_edition,
    bench_work_create,
    bench_concurrent_reads_serial,
    bench_concurrent_reads_parallel,
    bench_crdt_full_state,
    bench_checkpoint_impact,
);
criterion_main!(benches);
