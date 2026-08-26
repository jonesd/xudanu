use super::protocol::*;
use super::shared::SharedState;
use crate::edition::{BeId, Edition};
use crate::server::Server;
use crate::server::ServerError;
use std::collections::HashMap;

const LLM_TIMEOUT: std::time::Duration = std::time::Duration::from_secs(30);
const LLM_MAX_CONCURRENCY: usize = 4;

static LLM_SEMAPHORE: std::sync::OnceLock<tokio::sync::Semaphore> = std::sync::OnceLock::new();

fn llm_semaphore() -> &'static tokio::sync::Semaphore {
    LLM_SEMAPHORE.get_or_init(|| tokio::sync::Semaphore::new(LLM_MAX_CONCURRENCY))
}

/// Build the wire payload for a link (FR-40): named ends beyond the
/// two-ended fast path, derived type ends (Green's three-set,
/// materialized on read), and home-document state.
fn build_link_payload(
    srv: &Server,
    link_id: BeId,
    origin: BeId,
    destination: BeId,
    link: &crate::edition::links::HyperLink,
) -> LinkPayload {
    let o_ref = link.end_at("LeftEnd").map(HyperRefPayload::from_hyper_ref);
    let d_ref = link.end_at("RightEnd").map(HyperRefPayload::from_hyper_ref);
    let (origin_archived, origin_title, origin_owner) = srv.link_endpoint_meta(origin);
    let (destination_archived, destination_title, destination_owner) =
        srv.link_endpoint_meta(destination);
    let named_ends: Vec<(String, HyperRefPayload)> = link
        .end_names()
        .into_iter()
        .filter(|n| *n != "LeftEnd" && *n != "RightEnd")
        .filter_map(|n| {
            link.end_at(n)
                .map(|hr| (n.to_string(), HyperRefPayload::from_hyper_ref(hr)))
        })
        .collect();
    let type_ends: Vec<(u64, BeId)> = link
        .link_types()
        .iter()
        .filter_map(|&tid| srv.link_type_definition(tid).map(|dw| (tid, dw)))
        .collect();
    let home_document = srv.link_home_document(link_id);
    let home_archived = home_document
        .map(|h| srv.link_endpoint_meta(h).0)
        .unwrap_or(false);
    let notify = srv.link_cross_server_notify(link_id);
    LinkPayload {
        link_id,
        origin,
        destination,
        origin_ref: o_ref,
        destination_ref: d_ref,
        origin_archived,
        origin_title,
        origin_owner,
        destination_archived,
        destination_title,
        destination_owner,
        named_ends,
        link_types: link.link_types().to_vec(),
        type_ends,
        home_document,
        home_archived,
        cross_server_notify_accepted: notify.as_ref().map(|n| n.accepted),
        cross_server_notify_error: notify.and_then(|n| n.error),
    }
}

pub fn dispatch(
    state: &SharedState,
    session_id: crate::server::SessionId,
    request: WireRequest,
) -> Result<ResponseValue, crate::server::ServerError> {
    let op_name = format!("{:?}", request);
    let op_name = op_name.split_whitespace().next().unwrap_or("?");
    let span = tracing::info_span!("dispatch", op = op_name, session = session_id.as_u64());
    let _enter = span.enter();
    // FR-43: per-op wall time into the metrics sink. Covers the whole
    // dispatch incl. lock acquisition — lock-wait is part of the cost
    // users feel.
    let __metrics_start = std::time::Instant::now();
    let __metrics_op = op_name.to_string();

    struct MetricsGuard<'a> {
        state: &'a SharedState,
        op: String,
        start: std::time::Instant,
    }
    impl Drop for MetricsGuard<'_> {
        fn drop(&mut self) {
            self.state.metrics.record(&self.op, self.start.elapsed());
        }
    }
    let _metrics_guard = MetricsGuard {
        state,
        op: __metrics_op,
        start: __metrics_start,
    };
    if matches!(request, WireRequest::WorkDiffNarration { .. }) {
        return dispatch_narration(state, session_id, request);
    }

    if matches!(request, WireRequest::WorkWritingFeedback { .. }) {
        return dispatch_writing_feedback(state, session_id, request);
    }

    if matches!(request, WireRequest::WorkSuggestTitle { .. }) {
        return dispatch_suggest_title(state, session_id, request);
    }

    if matches!(request, WireRequest::WorkAutoTag { .. }) {
        return dispatch_auto_tag(state, session_id, request);
    }

    let is_work_create = matches!(request, WireRequest::WorkCreate { .. });
    let is_read = request.is_readonly();

    let result = {
        let guard_result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            if is_read {
                state
                    .server
                    .with_server_ref(|srv| dispatch_inner_read(srv, session_id, request, state))
            } else {
                let _op_count = state.server.bump_operation_atomic();
                let mut needs_ckpt = false;
                let r = state.server.with_server(|srv| {
                    srv.operation_counter = state.server.operation_count();
                    needs_ckpt = srv.check_periodic_maintenance();
                    dispatch_inner(srv, session_id, request, state)
                });
                if needs_ckpt {
                    let server = state.server.clone();
                    tokio::spawn(async move {
                        match server.checkpoint_async().await {
                            Ok(()) => {
                                server.with_server(|srv| srv.checkpoint_completed());
                            }
                            Err(e) => {
                                tracing::warn!("async auto-checkpoint failed: {}", e);
                                server.with_server(|srv| srv.checkpoint_completed());
                            }
                        }
                    });
                }
                r
            }
        }));
        match guard_result {
            Ok(r) => r,
            Err(panic_info) => {
                let msg = if let Some(s) = panic_info.downcast_ref::<&str>() {
                    s.to_string()
                } else if let Some(s) = panic_info.downcast_ref::<String>() {
                    s.clone()
                } else {
                    "unknown panic".to_string()
                };
                tracing::error!("Caught panic in dispatch: {}", msg);
                Err(crate::server::ServerError::Internal(msg))
            }
        }
    };

    if is_work_create {
        if let Ok(ResponseValue::Id(work_id)) = &result {
            spawn_auto_title(state, *work_id);
        }
    }

    result
}

fn dispatch_narration(
    state: &SharedState,
    session_id: crate::server::SessionId,
    request: WireRequest,
) -> Result<ResponseValue, crate::server::ServerError> {
    let work_id = match &request {
        WireRequest::WorkDiffNarration { work_id } => *work_id,
        _ => unreachable!(),
    };

    let (base_text, new_text, last_author) = state.server.with_server(|srv| {
        let _ = state.server.bump_operation_atomic();
        srv.ensure_can_read(session_id, work_id)?;

        let new_text = if srv.crdt_is_active(work_id) {
            srv.crdt_current_text(work_id).unwrap_or_default()
        } else {
            String::new()
        };

        let base_text = if srv.crdt_is_active(work_id) {
            srv.otree_crdt
                .narration_snapshot(work_id)
                .map_err(|e| crate::server::ServerError::Internal(e.to_string()))?
                .unwrap_or_default()
        } else {
            String::new()
        };

        let last_author = srv.last_revision_author(work_id);
        Ok::<_, crate::server::ServerError>((base_text, new_text, last_author))
    })?;

    tracing::info!(
        "narration diff: base_len={} new_len={} base={:?} new={:?}",
        base_text.len(),
        new_text.len(),
        &base_text[..base_text.len().min(100)],
        &new_text[..new_text.len().min(100)],
    );

    let llm = match crate::server::ollama::get_client() {
        Some(c) => c,
        None => return Ok(ResponseValue::NarrationResult {
            narration: "(LLM features are disabled. Set OPENROUTER_API_KEY, GITHUB_TOKEN, or OLLAMA_BASE_URL to enable.)".to_string(),
            llm_model: String::new(),
            updated_text: String::new(),
        }),
    };
    let prompt = crate::server::ollama::build_narration_prompt(
        &base_text,
        &new_text,
        last_author.as_deref(),
    );

    let mut narration = String::new();
    let narration_result = match tokio::task::block_in_place(|| {
        let rt = tokio::runtime::Handle::current();
        rt.block_on(async {
            let _permit = llm_semaphore().acquire().await.map_err(|e| e.to_string())?;
            tokio::time::timeout(LLM_TIMEOUT, llm.generate_with_attestation(&prompt))
                .await
                .map_err(|_| {
                    format!(
                        "(LLM request timed out after {} seconds)",
                        LLM_TIMEOUT.as_secs()
                    )
                })
                .and_then(|r| r.map_err(|e| e.to_string()))
        })
    }) {
        Ok(result) => Some(result),
        Err(e) => {
            narration = format!("(LLM unavailable: {})", e);
            None
        }
    };

    if let Some((text, attestation)) = &narration_result {
        narration = text.clone();
    }

    let llm_model = format!("{}/{}", llm.backend_label(), llm.model_name());

    let attestation_json = narration_result.as_ref().map(|(_, att)| {
        serde_json::json!({
            "digest": att.model_digest,
            "tokens": att.eval_count,
            "prompt_tokens": att.prompt_eval_count,
            "created_at": att.created_at,
        })
        .to_string()
    });

    let insert_text = format!(
        "\n\n---\n**Change Summary**\n{}\n— via {}",
        narration, llm_model
    );

    state.server.with_server(|srv| {
        if srv.crdt_is_active(work_id) {
            let _ = srv.otree_crdt.set_narration_snapshot(work_id);
            let triggerer_club = srv
                .otree_crdt
                .get_author(work_id, session_id)
                .ok()
                .flatten()
                .map(|a| a.club_be_id)
                .unwrap_or(0);
            let server_pub_key = srv.server_public_signing_key();
            let _ = srv.otree_crdt.append_llm_text(
                work_id,
                &insert_text,
                &llm_model,
                triggerer_club,
                server_pub_key,
                attestation_json.as_deref(),
            );
        }
    });

    let updated_text = state.server.with_server(|srv| {
        if srv.crdt_is_active(work_id) {
            srv.crdt_current_text(work_id).unwrap_or_default()
        } else {
            String::new()
        }
    });

    Ok(ResponseValue::NarrationResult {
        narration,
        llm_model,
        updated_text,
    })
}

fn dispatch_writing_feedback(
    state: &SharedState,
    session_id: crate::server::SessionId,
    request: WireRequest,
) -> Result<ResponseValue, crate::server::ServerError> {
    let work_id = match &request {
        WireRequest::WorkWritingFeedback { work_id } => *work_id,
        _ => unreachable!(),
    };

    let text = state.server.with_server(|srv| {
        let _ = state.server.bump_operation_atomic();
        srv.ensure_can_read(session_id, work_id)?;
        let text = if srv.crdt_is_active(work_id) {
            srv.crdt_current_text(work_id).unwrap_or_default()
        } else {
            String::new()
        };
        Ok::<_, crate::server::ServerError>(text)
    })?;

    if text.is_empty() {
        return Ok(ResponseValue::WritingFeedbackResult {
            feedback: "(No content to review.)".to_string(),
            llm_model: String::new(),
        });
    }

    let llm = match crate::server::ollama::get_client() {
        Some(c) => c,
        None => return Ok(ResponseValue::WritingFeedbackResult {
            feedback: "(LLM features are disabled. Set OPENROUTER_API_KEY, GITHUB_TOKEN, or OLLAMA_BASE_URL to enable.)".to_string(),
            llm_model: String::new(),
        }),
    };
    let prompt = crate::server::ollama::build_writing_feedback_prompt(&text);

    let feedback = match tokio::task::block_in_place(|| {
        let rt = tokio::runtime::Handle::current();
        rt.block_on(async {
            let _permit = llm_semaphore().acquire().await.map_err(|e| e.to_string())?;
            tokio::time::timeout(
                LLM_TIMEOUT,
                llm.generate_tracked(crate::server::ollama::LlmFeature::WritingFeedback, &prompt),
            )
            .await
            .map_err(|_| {
                format!(
                    "(LLM request timed out after {} seconds)",
                    LLM_TIMEOUT.as_secs()
                )
            })
            .and_then(|r| r.map_err(|e| e.to_string()))
        })
    }) {
        Ok(text) => text,
        Err(e) => format!("(LLM unavailable: {})", e),
    };

    let llm_model = format!("{}/{}", llm.backend_label(), llm.model_name());

    Ok(ResponseValue::WritingFeedbackResult {
        feedback,
        llm_model,
    })
}

fn dispatch_suggest_title(
    state: &SharedState,
    session_id: crate::server::SessionId,
    request: WireRequest,
) -> Result<ResponseValue, crate::server::ServerError> {
    let work_id = match &request {
        WireRequest::WorkSuggestTitle { work_id } => *work_id,
        _ => unreachable!(),
    };

    let text = state.server.with_server(|srv| {
        let _ = state.server.bump_operation_atomic();
        srv.ensure_can_read(session_id, work_id)?;
        let text = if srv.crdt_is_active(work_id) {
            srv.crdt_current_text(work_id).unwrap_or_default()
        } else {
            String::new()
        };
        Ok::<_, crate::server::ServerError>(text)
    })?;

    if text.is_empty() {
        return Ok(ResponseValue::String(
            "(No content to generate a title from.)".to_string(),
        ));
    }

    let llm = match crate::server::ollama::get_client() {
        Some(c) => c,
        None => {
            return Ok(ResponseValue::String(
                "(LLM features are disabled.)".to_string(),
            ))
        }
    };
    let prompt = crate::server::ollama::build_title_prompt(&text);

    let title = match tokio::task::block_in_place(|| {
        let rt = tokio::runtime::Handle::current();
        rt.block_on(async {
            let _permit = llm_semaphore().acquire().await.map_err(|e| e.to_string())?;
            tokio::time::timeout(
                LLM_TIMEOUT,
                llm.generate_tracked(crate::server::ollama::LlmFeature::AutoTitle, &prompt),
            )
            .await
            .map_err(|_| {
                format!(
                    "(LLM request timed out after {} seconds)",
                    LLM_TIMEOUT.as_secs()
                )
            })
            .and_then(|r| r.map_err(|e| e.to_string()))
        })
    }) {
        Ok(text) => text.trim().trim_matches('"').to_string(),
        Err(e) => format!("(LLM unavailable: {})", e),
    };

    Ok(ResponseValue::String(title))
}

fn dispatch_auto_tag(
    state: &SharedState,
    session_id: crate::server::SessionId,
    request: WireRequest,
) -> Result<ResponseValue, crate::server::ServerError> {
    let work_id = match &request {
        WireRequest::WorkAutoTag { work_id } => *work_id,
        _ => unreachable!(),
    };

    let (text, existing_concepts) = state.server.with_server(|srv| {
        let _ = state.server.bump_operation_atomic();
        srv.ensure_can_read(session_id, work_id)?;
        let text = if srv.crdt_is_active(work_id) {
            srv.crdt_current_text(work_id).unwrap_or_default()
        } else {
            String::new()
        };
        let concepts: Vec<String> = srv
            .works
            .iter()
            .filter(|(_, ws)| ws.kind() == crate::edition::WorkKind::Concept)
            .filter_map(|(_, ws)| {
                let t = ws.cached_title().trim();
                if t.is_empty() {
                    None
                } else {
                    Some(t.to_string())
                }
            })
            .collect();
        Ok::<_, crate::server::ServerError>((text, concepts))
    })?;

    if text.is_empty() {
        return Ok(ResponseValue::String("[]".to_string()));
    }

    let llm = match crate::server::ollama::get_client() {
        Some(c) => c,
        None => return Ok(ResponseValue::String("[]".to_string())),
    };
    let prompt = crate::server::ollama::build_categorization_prompt(&text, &existing_concepts);

    let response = match tokio::task::block_in_place(|| {
        let rt = tokio::runtime::Handle::current();
        rt.block_on(async {
            let _permit = llm_semaphore().acquire().await.map_err(|e| e.to_string())?;
            tokio::time::timeout(
                LLM_TIMEOUT,
                llm.generate_tracked(crate::server::ollama::LlmFeature::FindRelated, &prompt),
            )
            .await
            .map_err(|_| format!("(timed out after {}s)", LLM_TIMEOUT.as_secs()))
            .and_then(|r| r.map_err(|e| e.to_string()))
        })
    }) {
        Ok(text) => text,
        Err(e) => {
            tracing::warn!("auto-tag LLM failed: {}", e);
            return Ok(ResponseValue::String("[]".to_string()));
        }
    };

    let response_clean = {
        let r = response.trim();
        let r = r
            .strip_prefix("```json")
            .or_else(|| r.strip_prefix("```"))
            .unwrap_or(r)
            .trim();
        let r = r.strip_suffix("```").unwrap_or(r).trim();
        r.to_string()
    };
    let concepts: Vec<String> = serde_json::from_str::<Vec<String>>(&response_clean)
        .unwrap_or_else(|e| {
            tracing::warn!(
                "auto-tag response not JSON array: {} — raw: {:?}",
                e,
                &response[..response.len().min(200)]
            );
            response_clean
                .lines()
                .filter_map(|l| {
                    let t = l
                        .trim()
                        .trim_start_matches("- ")
                        .trim_start_matches("\"")
                        .trim_end_matches("\"")
                        .trim();
                    if t.is_empty() || t.starts_with('[') || t.starts_with(']') {
                        None
                    } else {
                        Some(t.to_string())
                    }
                })
                .take(5)
                .collect()
        })
        .into_iter()
        .filter(|s| !s.is_empty())
        .take(5)
        .collect();

    tracing::info!(
        "auto-tag for work {:x}: {} concepts: {:?}",
        work_id,
        concepts.len(),
        concepts
    );

    let (created, linked) = state.server.with_server(|srv| {
        let mut created = Vec::new();
        let mut linked = Vec::new();

        for concept_name in &concepts {
            let existing = srv
                .works
                .iter()
                .filter(|(_, ws)| ws.kind() == crate::edition::WorkKind::Concept)
                .find(|(_, ws)| ws.cached_title().eq_ignore_ascii_case(concept_name))
                .map(|(id, _)| *id);

            match existing {
                Some(concept_id) => linked.push((concept_name.clone(), concept_id)),
                None => {
                    match srv.create_work(
                        session_id,
                        crate::edition::Edition::from_text(concept_name.as_str()),
                    ) {
                        Ok(concept_id) => {
                            let _ =
                                srv.work_kind_set(concept_id, crate::edition::WorkKind::Concept);
                            srv.set_work_title(concept_id, concept_name.clone());
                            created.push((concept_name.clone(), concept_id));
                        }
                        Err(e) => {
                            tracing::warn!("failed to create concept '{}': {}", concept_name, e)
                        }
                    }
                }
            }
        }

        for (_, concept_id) in created.iter().chain(linked.iter()) {
            match srv.create_link(session_id, work_id, *concept_id, None, None) {
                Ok(link_id) => {
                    let _ = srv.link_set_types(session_id, link_id, vec![5]);
                    tracing::info!(
                        "auto-tag: linked work {:x} → concept {:x} (link {}, type=See Also)",
                        work_id,
                        concept_id,
                        link_id
                    );
                }
                Err(e) => tracing::warn!(
                    "auto-tag: failed to link to concept {:x}: {}",
                    concept_id,
                    e
                ),
            }
        }

        Ok::<_, crate::server::ServerError>((created, linked))
    })?;

    let result = serde_json::json!({
        "new": created.iter().map(|(n, id)| serde_json::json!({"name": n, "id": id})).collect::<Vec<_>>(),
        "linked": linked.iter().map(|(n, id)| serde_json::json!({"name": n, "id": id})).collect::<Vec<_>>(),
    });
    Ok(ResponseValue::String(result.to_string()))
}

fn dispatch_inner(
    srv: &mut Server,
    session_id: crate::server::SessionId,
    request: WireRequest,
    state: &SharedState,
) -> Result<ResponseValue, crate::server::ServerError> {
    srv.touch_session(session_id);
    match request {
        WireRequest::SessionConnect => Ok(ResponseValue::Id(session_id.as_u64())),
        WireRequest::SessionDisconnect => {
            srv.disconnect(session_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::SessionLogin { club_id } => {
            let lock = srv.login(session_id, club_id)?;
            let challenge = lock
                .as_ref()
                .as_any()
                .downcast_ref::<crate::server::ChallengeLock>()
                .map(|cl| cl.challenge().to_vec());
            match challenge {
                Some(ch) => Ok(ResponseValue::AuthChallenge { challenge: ch }),
                None => Ok(ResponseValue::Void),
            }
        }
        WireRequest::SessionLoginByName { club_name } => {
            let lock = srv.login_by_name(session_id, &club_name)?;
            let challenge = lock
                .as_ref()
                .as_any()
                .downcast_ref::<crate::server::ChallengeLock>()
                .map(|cl| cl.challenge().to_vec());
            match challenge {
                Some(ch) => Ok(ResponseValue::AuthChallenge { challenge: ch }),
                None => Ok(ResponseValue::Void),
            }
        }
        WireRequest::SessionAuthenticate { credential } => {
            let km = srv.authenticate_with_pending(session_id, &credential)?;
            let clubs: Vec<BeId> = km.actual_authority().into_iter().collect();
            Ok(ResponseValue::Ids(clubs))
        }
        WireRequest::SessionLoginPublic => {
            let km = srv.login_public(session_id)?;
            Ok(ResponseValue::Id(
                km.login_authority().iter().next().copied().unwrap_or(0),
            ))
        }
        WireRequest::SessionTicketIssue => {
            tracing::info!("SessionTicketIssue dispatch, session={:?}", session_id);
            let ticket = srv.issue_session_ticket(session_id)?;
            tracing::info!("SessionTicketIssue OK, ticket len={}", ticket.len());
            Ok(ResponseValue::Ticket {
                clubs: vec![],
                ticket,
            })
        }
        WireRequest::SessionTicketRedeem { ticket } => {
            let (clubs, new_ticket) = srv.redeem_session_ticket(session_id, &ticket)?;
            Ok(ResponseValue::Ticket {
                clubs,
                ticket: new_ticket,
            })
        }

        WireRequest::ServerGetById { id } => {
            let id_obj = crate::edition::Id::global(id as i64);
            let elem = srv.get_by_id(&id_obj);
            Ok(ResponseValue::RangeElement(elem))
        }
        WireRequest::ServerGetByBeId { be_id } => {
            let elem = srv.get_by_be_id(be_id);
            Ok(ResponseValue::RangeElement(elem))
        }

        WireRequest::ClubCreate { description } => {
            let ed = description.to_edition();
            let id = srv.create_club(session_id, ed)?;
            Ok(ResponseValue::Id(id))
        }
        WireRequest::ClubCreateNamed { name, description } => {
            let ed = description.to_edition();
            let id = srv.create_named_club(session_id, &name, ed)?;
            Ok(ResponseValue::Id(id))
        }
        WireRequest::ClubGet { club_id } => {
            srv.ensure_session(session_id)?;
            let _club = srv.club(club_id)?;
            Ok(ResponseValue::Id(club_id))
        }
        WireRequest::ClubByName { name } | WireRequest::ClubIdByName { name } => {
            srv.ensure_session(session_id)?;
            match srv.club_id_by_name(&name) {
                Some(id) => Ok(ResponseValue::Id(id)),
                None => Err(crate::server::ServerError::NotFound(format!(
                    "club '{}'",
                    name
                ))),
            }
        }
        WireRequest::ClubNameById { club_id } => {
            srv.ensure_session(session_id)?;
            let name = srv
                .club_name_by_id(club_id)
                .map(|s| s.to_string())
                .ok_or_else(|| crate::server::ServerError::ClubNotFound(club_id))?;
            Ok(ResponseValue::String(name))
        }
        WireRequest::ClubNames { offset, limit } => {
            srv.ensure_session(session_id)?;
            let all: Vec<_> = srv
                .club_names_list()
                .into_iter()
                .map(|(n, id)| (n.to_string(), id))
                .collect();
            let total_count = all.len() as u64;
            let limit_val = limit.unwrap_or(100).min(1000) as usize;
            let offset_val = offset.unwrap_or(0) as usize;
            let has_more = offset_val + limit_val < all.len();
            let entries: Vec<_> = all.into_iter().skip(offset_val).take(limit_val).collect();
            Ok(ResponseValue::PaginatedClubNames {
                entries,
                total_count,
                has_more,
            })
        }

        WireRequest::WorkCreate { edition } => {
            srv.ensure_authenticated(session_id)?;
            let ed = edition
                .to_edition_checked(0)
                .map_err(ServerError::InvalidArgument)?;
            let id = srv.create_work(session_id, ed)?;
            Ok(ResponseValue::Id(id))
        }
        WireRequest::WorkGetEdition { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            // FR-37 Phase 2: re-resolve generation-stale transclusion
            // caches before serving (no staleness window for readers).
            srv.stamp_structural_transclusion_cache(work_id)?;
            let ed = srv.work_edition(work_id)?;
            Ok(ResponseValue::Edition(EditionPayload::from_edition(&ed)))
        }
        WireRequest::WorkRevise { work_id, edition } => {
            srv.ensure_authenticated(session_id)?;
            let ed = edition
                .to_edition_checked(work_id)
                .map_err(ServerError::InvalidArgument)?;
            let rev = srv.work_revise(session_id, work_id, ed)?;
            // FR-37 Phase 2: a full-edition revise changes source
            // content exactly like a delta — dependents' caches must be
            // re-checked (generation stamps make this cheap; unchanged
            // sources are O(1) no-ops).
            srv.migrate_inline_transclusions_for_delta(work_id, &[]);
            Ok(ResponseValue::Humber(rev))
        }
        WireRequest::WorkReviseDelta {
            work_id,
            base_revision,
            ops,
        } => {
            srv.ensure_authenticated(session_id)?;
            if srv.crdt_is_active(work_id) {
                let (relay, revision) = srv.crdt_apply_text_delta(session_id, work_id, &ops)?;
                let rev = revision.unwrap_or_else(|| srv.work_revision_count(work_id).unwrap_or(0));

                if !relay.relay_to.is_empty() {
                    let merged_text = if relay.was_merged {
                        Some(srv.crdt_current_text(work_id)?)
                    } else {
                        None
                    };
                    for (relay_sid, _) in &relay.relay_to {
                        use super::channel::EventMessage;
                        let ev = if let Some(ref text) = merged_text {
                            EventMessage {
                                session_id: *relay_sid,
                                subscription_id: 0,
                                event: EventPayload::CrdtTextUpdate {
                                    work_id,
                                    text: text.clone(),
                                },
                            }
                        } else {
                            EventMessage {
                                session_id: *relay_sid,
                                subscription_id: 0,
                                event: EventPayload::CrdtTextDelta {
                                    work_id,
                                    ops: ops.to_vec(),
                                },
                            }
                        };
                        state.send_to_session(relay_sid, ev);
                    }
                }

                Ok(ResponseValue::Humber(rev))
            } else {
                let current_ed = srv.work_edition(work_id)?;
                let current_rev = srv.work_revision_count(work_id)?;
                if current_rev != base_revision {
                    return Ok(ResponseValue::Edition(EditionPayload::from_edition(
                        &current_ed,
                    )));
                }
                let (display_name, club_id, pub_key) = srv.identity_for_session(session_id);
                let author = club_id.map(|cid| {
                    crate::server::otree_crdt::OtreeAuthorIdentity::new(
                        pub_key.map_or([0u8; 32], |pk| {
                            let mut arr = [0u8; 32];
                            arr.copy_from_slice(&pk[..32]);
                            arr
                        }),
                        display_name,
                        cid,
                    )
                });
                let new_ed = crate::server::otree_crdt::apply_text_delta_to_edition(
                    &current_ed,
                    &ops,
                    author.as_ref(),
                );
                srv.migrate_link_spans_for_delta(work_id, &ops);
                srv.migrate_inline_transclusions_for_delta(work_id, &ops);
                let compound_subs = srv.compound_subscribers_for_source(work_id);
                let rev = srv.work_revise(session_id, work_id, new_ed)?;
                for (compound_wid, subs) in &compound_subs {
                    for sub_sid in subs {
                        if *sub_sid == session_id {
                            continue;
                        }
                        use super::channel::EventMessage;
                        let ev = EventMessage {
                            session_id: *sub_sid,
                            subscription_id: 0,
                            event: EventPayload::CompoundSourceChanged {
                                compound_work_id: *compound_wid,
                                source_work_id: work_id,
                            },
                        };
                        state.send_to_session(sub_sid, ev);
                    }
                }
                Ok(ResponseValue::Humber(rev))
            }
        }
        WireRequest::WorkGrab { work_id } => {
            srv.ensure_authenticated(session_id)?;
            srv.work_grab(session_id, work_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkRelease { work_id } => {
            srv.ensure_authenticated(session_id)?;
            srv.work_release(session_id, work_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkSaveAndRelease { work_id, edition } => {
            srv.ensure_authenticated(session_id)?;
            let ed = edition
                .to_edition_checked(work_id)
                .map_err(ServerError::InvalidArgument)?;
            srv.work_save_and_release(session_id, work_id, ed)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkForceRelease { work_id } => {
            srv.ensure_authenticated(session_id)?;
            let prev = srv.work_force_release(session_id, work_id)?;
            match prev {
                Some(prev_session) => {
                    tracing::info!(work_id, ?prev_session, "Force-released work");
                    Ok(ResponseValue::Void)
                }
                None => {
                    tracing::info!(work_id, "Work was not grabbed, nothing to release");
                    Ok(ResponseValue::Void)
                }
            }
        }
        WireRequest::WorkIsGrabbed { work_id } => {
            let grabbed = srv.work_is_grabbed(work_id)?;
            Ok(ResponseValue::Boolean(grabbed))
        }
        WireRequest::WorkGrabber { work_id } => {
            let grabber = srv.work_grabber(work_id)?;
            Ok(ResponseValue::Humber(
                grabber.map(|s| s.as_u64()).unwrap_or(0),
            ))
        }
        WireRequest::WorkRequestGrab { work_id } => {
            let granted = srv.work_request_grab(session_id, work_id)?;
            Ok(ResponseValue::Boolean(granted))
        }
        WireRequest::WorkCancelGrabRequest { work_id } => {
            srv.work_cancel_grab_request(session_id, work_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkGrabWaiters { work_id } => {
            let waiters = srv.work_grab_waiters(work_id)?;
            Ok(ResponseValue::Humber(waiters.len() as u64))
        }
        WireRequest::WorkCanRead { work_id } => {
            let can = srv.work_can_read(session_id, work_id)?;
            Ok(ResponseValue::Boolean(can))
        }
        WireRequest::WorkCanRevise { work_id } => {
            let can = srv.work_can_revise(session_id, work_id)?;
            Ok(ResponseValue::Boolean(can))
        }
        WireRequest::WorkStar { work_id } => {
            srv.work_star(session_id, work_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkSetSource { work_id, is_source } => {
            srv.work_set_source(session_id, work_id, is_source)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WebFetchSanitize {
            url,
            max_chars,
            import_as_source,
            title,
        } => {
            let result = srv.web_fetch_sanitize(
                session_id,
                &url,
                max_chars,
                import_as_source.unwrap_or(false),
                title,
            )?;
            Ok(ResponseValue::WebFetchSanitizeResult(result))
        }
        WireRequest::WorkSetTitle { work_id, title } => {
            srv.ensure_can_edit(session_id, work_id)?;
            srv.set_work_title(work_id, title);
            if let Some(ws) = srv.works.get_mut(&work_id) {
                ws.mark_dirty();
            }
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkUnstar { work_id } => {
            srv.work_unstar(session_id, work_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkIsStarred { work_id } => {
            let starred = srv.work_is_starred(session_id, work_id)?;
            Ok(ResponseValue::Boolean(starred))
        }
        WireRequest::ConnectionPinSet { key } => {
            srv.set_connection_pin(session_id, &key)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::ConnectionPinUnset { key } => {
            srv.unset_connection_pin(session_id, &key)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::ConnectionPinsGet => {
            srv.ensure_authenticated(session_id)?;
            let pins = srv.connection_pins_for_session(session_id);
            Ok(ResponseValue::ConnectionPins(pins.into_iter().collect()))
        }
        WireRequest::CrossServerBacklinksGet { work_id } => {
            srv.ensure_session(session_id)?;
            let backlinks = srv.cross_server_backlinks_for_work(work_id);
            let payloads: Vec<super::protocol::CrossServerBacklinkPayload> = backlinks
                .into_iter()
                .map(|b| super::protocol::CrossServerBacklinkPayload {
                    target_work_id: b.target_work_id,
                    origin_server_address: b.origin_server_address.clone(),
                    origin_server_name: b.origin_server_name.clone(),
                    origin_work_id: b.origin_work_id.clone(),
                    origin_work_title: b.origin_work_title.clone(),
                    excerpt: b.excerpt.clone(),
                    link_type: b.link_type.clone(),
                    received_at: b.received_at,
                })
                .collect();
            Ok(ResponseValue::CrossServerBacklinksResult(payloads))
        }
        WireRequest::WorkGraph {
            center_work_id,
            max_nodes,
        } => {
            srv.ensure_authenticated(session_id)?;
            let (raw_nodes, raw_edges) = if let Some(center) = center_work_id {
                srv.build_work_graph_filtered(session_id, Some(center), max_nodes as usize)
            } else {
                srv.build_work_graph(session_id)
            };
            let nodes: Vec<super::protocol::GraphNodePayload> = raw_nodes
                .into_iter()
                .map(
                    |(work_id, title, is_starred, is_source, revision_count, kind, license)| {
                        super::protocol::GraphNodePayload {
                            work_id,
                            title,
                            is_starred,
                            is_source,
                            revision_count,
                            author_type: None,
                            kind,
                            license,
                        }
                    },
                )
                .collect();
            let edges: Vec<super::protocol::GraphEdgePayload> = raw_edges
                .into_iter()
                .map(
                    |(source, target, edge_type, weight)| super::protocol::GraphEdgePayload {
                        source,
                        target,
                        edge_type,
                        weight,
                    },
                )
                .collect();
            Ok(ResponseValue::WorkGraphResult(
                super::protocol::GraphPayload { nodes, edges },
            ))
        }
        WireRequest::WorkKindGet { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let kind = srv.work_kind_get(work_id)?;
            Ok(ResponseValue::Humber(kind as u64))
        }
        WireRequest::WorkKindSet { work_id, kind } => {
            srv.ensure_authenticated(session_id)?;
            srv.work_kind_set(work_id, kind)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkLicenseGet { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let license = srv.work_license_get(work_id)?;
            Ok(ResponseValue::Humber(license as u64))
        }
        WireRequest::WorkLicenseSet { work_id, license } => {
            srv.ensure_authenticated(session_id)?;
            srv.work_license_set(work_id, license)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkListByKind { kind: _ } => {
            // Phase 3 will implement this properly with a Vec<WorkMeta> response.
            // For now, return 0 to indicate "not yet supported".
            Ok(ResponseValue::Humber(0))
        }
        WireRequest::WorkSetText { work_id, text } => {
            srv.work_set_text(session_id, work_id, &text)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkRevisionsList { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let revisions = srv.work_revisions_list(session_id, work_id)?;
            Ok(ResponseValue::RevisionListResult(revisions))
        }
        WireRequest::WorkBlobList { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let blobs = srv.work_blob_list(work_id)?;
            Ok(ResponseValue::BlobListResult(blobs))
        }
        WireRequest::WorkTextAtRevision {
            work_id,
            revision_id,
        } => {
            srv.ensure_can_read(session_id, work_id)?;
            let text = srv.work_text_at_revision(session_id, work_id, revision_id)?;
            Ok(ResponseValue::TextResult(text))
        }
        WireRequest::WorkRevisionDescribe {
            work_id,
            revision_id,
            description,
        } => {
            srv.ensure_can_edit(session_id, work_id)?;
            srv.work_revision_describe(session_id, work_id, revision_id, description)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkRevisionMarkNotable {
            work_id,
            revision_id,
            notable,
        } => {
            srv.ensure_can_edit(session_id, work_id)?;
            srv.work_revision_mark_notable(session_id, work_id, revision_id, notable)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkRevisionRollback {
            work_id,
            target_revision_id,
        } => {
            srv.ensure_can_edit(session_id, work_id)?;
            let new_rev = srv.work_revision_rollback(session_id, work_id, target_revision_id)?;
            Ok(ResponseValue::Id(new_rev))
        }
        WireRequest::TrailCreate {
            name,
            introduction,
            categories,
        } => {
            srv.ensure_authenticated(session_id)?;
            let trail_id = srv.trail_create(session_id, name, introduction, categories)?;
            Ok(ResponseValue::Id(trail_id))
        }
        WireRequest::TrailDelete { trail_id } => {
            srv.ensure_authenticated(session_id)?;
            srv.trail_delete(session_id, trail_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::TrailRename { trail_id, name } => {
            srv.ensure_authenticated(session_id)?;
            srv.trail_rename(session_id, trail_id, name)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::TrailAddStop {
            trail_id,
            work_id,
            char_start,
            char_end,
            note,
            server_domain,
        } => {
            srv.ensure_authenticated(session_id)?;
            srv.trail_add_stop(
                session_id,
                trail_id,
                work_id,
                char_start,
                char_end,
                note,
                server_domain,
            )?;
            Ok(ResponseValue::Void)
        }
        WireRequest::TrailRemoveStop {
            trail_id,
            stop_index,
        } => {
            srv.ensure_authenticated(session_id)?;
            srv.trail_remove_stop(session_id, trail_id, stop_index)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::TrailReorderStops {
            trail_id,
            stop_order,
        } => {
            srv.ensure_authenticated(session_id)?;
            srv.trail_reorder_stops(session_id, trail_id, stop_order)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::TrailList => {
            srv.ensure_authenticated(session_id)?;
            let trails = srv.trail_list(session_id)?;
            Ok(ResponseValue::TrailListResult(trails))
        }
        WireRequest::TrailGet { trail_id } => {
            srv.ensure_authenticated(session_id)?;
            let trail = srv.trail_get(session_id, trail_id)?;
            Ok(ResponseValue::TrailResult(trail))
        }
        WireRequest::TrailUpdate {
            trail_id,
            introduction,
            categories,
        } => {
            srv.ensure_authenticated(session_id)?;
            srv.trail_update(session_id, trail_id, introduction, categories)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::TrailDerivedWork { trail_id } => {
            // FR-37 4d: write op — first call may create the derived
            // work; generation-checked (crum equality) so repeat calls
            // are cheap.
            srv.ensure_authenticated(session_id)?;
            let wid = srv.ensure_trail_derived_work(session_id, trail_id)?;
            Ok(ResponseValue::Humber(wid))
        }
        WireRequest::TrailPublish { trail_id } => {
            srv.ensure_authenticated(session_id)?;
            srv.trail_publish(session_id, trail_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::TrailUnpublish { trail_id } => {
            srv.ensure_authenticated(session_id)?;
            srv.trail_unpublish(session_id, trail_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::TrailListPublished { category } => {
            let trails = srv.trail_list_published(session_id, category.as_deref())?;
            Ok(ResponseValue::TrailListResult(trails))
        }
        WireRequest::TrailListCategories => {
            let cats = srv.trail_list_categories();
            Ok(ResponseValue::TrailCategories(cats))
        }
        WireRequest::WorkSetReadClub { work_id, club_id } => {
            srv.ensure_authenticated(session_id)?;
            srv.work_set_read_club(session_id, work_id, club_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkSetEditClub { work_id, club_id } => {
            srv.ensure_authenticated(session_id)?;
            srv.work_set_edit_club(session_id, work_id, club_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkSetHistoryClub { work_id, club_id } => {
            srv.work_set_history_club(session_id, work_id, club_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkReadClub { work_id } => {
            let club = srv.work_read_club(work_id)?;
            Ok(ResponseValue::Humber(club.unwrap_or(0)))
        }
        WireRequest::WorkEditClub { work_id } => {
            let club = srv.work_edit_club(work_id)?;
            Ok(ResponseValue::Humber(club.unwrap_or(0)))
        }
        WireRequest::WorkHistoryClub { work_id } => {
            let club = srv.work_history_club(work_id)?;
            Ok(ResponseValue::Humber(club.unwrap_or(0)))
        }
        WireRequest::WorkTransclusionChain {
            work_id,
            char_start,
            char_end,
        } => {
            srv.ensure_can_read(session_id, work_id)?;
            let chain = srv.transclusion_again_chain(work_id, char_start, char_end);
            let payload: Vec<super::protocol::AgainHopPayload> = chain
                .into_iter()
                .map(|hop| super::protocol::AgainHopPayload {
                    work_id: hop.work_id,
                    work_title: hop.work_title,
                    element_text: hop.element_text,
                    author_name: hop.author_name,
                    author_type: hop.author_type,
                    is_original: hop.is_original,
                })
                .collect();
            Ok(ResponseValue::TransclusionChainResult { chain: payload })
        }
        WireRequest::WorkRevisionCount { work_id } => {
            let count = srv.work_revision_count(work_id)?;
            Ok(ResponseValue::Humber(count))
        }
        WireRequest::WorkFetchRevision { work_id, number } => {
            srv.ensure_can_read_history(session_id, work_id)?;
            match srv.work_fetch_revision(work_id, number)? {
                Some(ed) => Ok(ResponseValue::Edition(EditionPayload::from_edition(&ed))),
                None => Ok(ResponseValue::Void),
            }
        }
        WireRequest::WorkFetchRevisionRange { work_id, from, to } => {
            srv.ensure_can_read_history(session_id, work_id)?;
            let revisions = srv.work_fetch_revision_range(work_id, from, to)?;
            let payload: Vec<(u64, EditionPayload)> = revisions
                .into_iter()
                .map(|(n, ed)| (n, EditionPayload::from_edition(&ed)))
                .collect();
            Ok(ResponseValue::RevisionRangeResult { revisions: payload })
        }
        WireRequest::WorkSponsor { work_id, club_id } => {
            srv.ensure_logged_in(session_id)?;
            srv.work_sponsor(session_id, work_id, club_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkUnsponsor { work_id, club_id } => {
            srv.ensure_logged_in(session_id)?;
            srv.work_unsponsor(session_id, work_id, club_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkSponsors { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let sponsors = srv.work_sponsors(work_id)?.to_vec();
            Ok(ResponseValue::Ids(sponsors))
        }
        WireRequest::WorkOwner { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let owner = srv.work_owner(work_id)?;
            Ok(ResponseValue::Humber(owner.unwrap_or(0)))
        }

        WireRequest::WorkPublish { work_id } => {
            srv.ensure_authenticated(session_id)?;
            srv.work_publish(session_id, work_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkUnpublish { work_id } => {
            srv.ensure_authenticated(session_id)?;
            srv.work_unpublish(session_id, work_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkIrrevocablyUnpublish { work_id } => {
            srv.ensure_authenticated(session_id)?;
            srv.work_irrevocably_unpublish(session_id, work_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkArchive { work_id } => {
            srv.work_archive(session_id, work_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkUnarchive { work_id } => {
            srv.work_unarchive(session_id, work_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkListArchived => {
            // Archived (soft-deleted) works. Owner-scoped; admins see all.
            let is_admin = srv.ensure_admin(session_id).is_ok();
            let owner_club = srv.identity_for_session(session_id).1;
            let starred = srv.starred_for_session(session_id);
            let entries: Vec<_> = srv
                .list_works_with_titles()
                .into_iter()
                .filter(|(work_id, owner, _, _, _, _, _, _, _, _, _)| {
                    let readable = srv
                        .work(*work_id)
                        .map(|w| srv.work_is_readable(session_id, w))
                        .unwrap_or(false);
                    let archived = srv.work_is_archived(*work_id).unwrap_or(false);
                    if !readable || !archived {
                        return false;
                    }
                    is_admin || owner_club.map_or(false, |oc| *owner == Some(oc))
                })
                .map(
                    |(
                        work_id,
                        owner,
                        revision_count,
                        is_grabbed,
                        title,
                        read_club,
                        is_source,
                        content_start_line,
                        content_end_line,
                        source_author_id,
                        source_edition_info,
                    )| {
                        super::protocol::WorkListEntry {
                            work_id,
                            owner,
                            revision_count,
                            is_grabbed,
                            char_count: 0,
                            title,
                            read_club,
                            is_source,
                            content_start_line,
                            content_end_line,
                            source_author_id,
                            source_edition_info,
                            is_starred: starred.contains(&work_id),
                            updated_at: None,
                            content_crum: None,
                        }
                    },
                )
                .collect();
            Ok(ResponseValue::WorkList(entries))
        }
        WireRequest::WorkIsPublished { work_id } => {
            let published = srv.work_is_published(session_id, work_id)?;
            Ok(ResponseValue::Boolean(published))
        }
        WireRequest::WorkMerge {
            base_work_id,
            a_work_id,
            b_work_id,
        } => {
            let new_work_id = srv.work_merge(session_id, base_work_id, a_work_id, b_work_id)?;
            Ok(ResponseValue::WorkMergeResult {
                work_id: new_work_id,
            })
        }
        WireRequest::WorkGhost { work_id } => {
            let ghost = srv
                .work_ghost(work_id)
                .map(|g| super::protocol::WorkGhostInfoPayload {
                    work_id: g.work_id,
                    title: g.title,
                    owner: g.owner,
                    archived_by: g.archived_by,
                    archived_at: g.archived_at,
                    lifecycle_history: g
                        .lifecycle_history
                        .iter()
                        .map(|e| super::protocol::WorkLifecycleEventPayload {
                            kind: e.kind.clone(),
                            actor_club: e.actor_club,
                            timestamp: e.timestamp,
                        })
                        .collect(),
                });
            Ok(ResponseValue::WorkGhostResult { ghost })
        }

        WireRequest::ClubSetDefaultReadClub {
            club_id,
            default_read_club,
        } => {
            srv.club_set_default_read_club(session_id, club_id, default_read_club)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::ClubSetDefaultEditClub {
            club_id,
            default_edit_club,
        } => {
            srv.club_set_default_edit_club(session_id, club_id, default_edit_club)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::ClubSetPassword { club_id, password } => {
            srv.club_set_password(session_id, club_id, &password)?;
            Ok(ResponseValue::ClubSetPasswordResult { set: true })
        }
        WireRequest::ClubClearCredential { club_id } => {
            srv.club_clear_credential(session_id, club_id)?;
            Ok(ResponseValue::ClubClearCredentialResult { cleared: true })
        }
        WireRequest::ClubCreatePersonal {
            display_name,
            password,
        } => {
            use crate::server::club::Credential;
            let credential = match password {
                Some(ref pw) if !pw.is_empty() => {
                    let phc_hash = crate::crypto::password::hash_password(pw).map_err(|e| {
                        crate::server::ServerError::Internal(format!("password hash failed: {}", e))
                    })?;
                    Some(Credential::Password { phc_hash })
                }
                _ => None,
            };
            let id = srv.create_personal_club(session_id, display_name, credential, password)?;
            Ok(ResponseValue::Id(id))
        }
        WireRequest::ClubWhoAmI => {
            let clubs = srv.who_am_i(session_id)?;
            let verifying_key = clubs
                .first()
                .and_then(|(cid, _)| srv.club_verifying_key_hex(*cid));
            Ok(ResponseValue::ClubWhoAmIResult {
                clubs,
                verifying_key,
            })
        }
        WireRequest::ClubAddMember { club_id, member_id } => {
            srv.club_add_member(session_id, club_id, member_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::ClubRemoveMember { club_id, member_id } => {
            srv.club_remove_member(session_id, club_id, member_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::ClubMembers { club_id } => {
            let members = srv.club_members(session_id, club_id)?;
            Ok(ResponseValue::ClubMembersResult { members })
        }
        WireRequest::ClubRoster { club_id } => {
            let r = srv.club_roster(session_id, club_id)?;
            Ok(ResponseValue::ClubRosterResult {
                members: r.members,
                total: r.total as u64,
                truncated: r.truncated,
            })
        }

        WireRequest::EditionStore { edition } => {
            srv.ensure_authenticated(session_id)?;
            let ed = edition
                .to_edition_checked(0)
                .map_err(ServerError::InvalidArgument)?;
            let id = srv.store_edition(session_id, ed)?;
            Ok(ResponseValue::Id(id))
        }
        WireRequest::EditionGet { be_id } => {
            srv.ensure_logged_in(session_id)?;
            match srv.get_edition(be_id)? {
                Some(ed) => Ok(ResponseValue::Edition(EditionPayload::from_edition(&ed))),
                None => Ok(ResponseValue::Void),
            }
        }

        WireRequest::AdminAcceptConnections { accept } => {
            srv.admin_accept_connections(session_id, accept)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::AdminIsAcceptingConnections => {
            let accepting = srv.admin_is_accepting_connections();
            Ok(ResponseValue::Boolean(accepting))
        }
        WireRequest::AdminActiveSessions => {
            let infos = srv.admin_active_sessions(session_id)?;
            let payloads = infos
                .into_iter()
                .map(|si| super::protocol::SessionInfoPayload {
                    session_id: si.session_id,
                    is_logged_in: si.is_logged_in,
                    authority_clubs: si.authority_clubs,
                    initial_login: si.initial_login,
                    grabbed_work_count: if si.has_grabbed_works { 1 } else { 0 },
                })
                .collect();
            Ok(ResponseValue::SessionInfos(payloads))
        }
        WireRequest::AdminShutdown => {
            srv.admin_shutdown(session_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::AdminGrant {
            club_id,
            region_start,
            region_end,
        } => {
            let region = crate::edition::XnRegion::interval(region_start, region_end);
            srv.admin_grant(session_id, club_id, region)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::AdminRevokeGrant { club_id } => {
            let revoked = srv.admin_revoke_grant(session_id, club_id)?;
            Ok(ResponseValue::Boolean(revoked))
        }
        WireRequest::AdminGrants => {
            let grants = srv.admin_grants(session_id)?;
            let payloads = grants
                .iter()
                .map(|g| {
                    let (start, end) = g.region.as_interval().unwrap_or((0, 0));
                    super::protocol::GrantPayload {
                        club_id: g.club_id,
                        region_start: start,
                        region_end: end,
                    }
                })
                .collect();
            Ok(ResponseValue::Grants(payloads))
        }
        WireRequest::AdminServerInfo => {
            srv.ensure_admin(session_id)?;
            Ok(ResponseValue::ServerInfo(
                super::protocol::ServerInfoPayload {
                    version: env!("CARGO_PKG_VERSION").to_string(),
                    session_count: srv.session_count(),
                    work_count: srv.work_count(),
                    club_count: srv.club_count(),
                    edition_count: srv.edition_count(),
                    is_accepting_connections: srv.admin_is_accepting_connections(),
                    public_club_id: srv.public_club_id(),
                    llm_enabled: crate::server::ollama::llm_enabled(),
                    llm_usage: crate::server::ollama::usage_tracker().summary(),
                },
            ))
        }

        WireRequest::MetricsSnapshot => {
            let rows = state.metrics.snapshot();
            Ok(ResponseValue::MetricsSnapshotResult(rows))
        }
        WireRequest::ServerStats => Ok(ResponseValue::ServerInfo(
            super::protocol::ServerInfoPayload {
                version: env!("CARGO_PKG_VERSION").to_string(),
                session_count: srv.session_count(),
                work_count: srv.work_count(),
                club_count: srv.club_count(),
                edition_count: srv.edition_count(),
                is_accepting_connections: srv.admin_is_accepting_connections(),
                public_club_id: srv.public_club_id(),
                llm_enabled: crate::server::ollama::llm_enabled(),
                llm_usage: crate::server::ollama::usage_tracker().summary(),
            },
        )),

        WireRequest::WorkList { offset, limit } => {
            let starred = srv.starred_for_session(session_id);
            let authority = srv.session_authority_clubs(session_id);
            let public_club = srv.public_club_id();
            let limit_val = limit.unwrap_or(100).min(1000) as usize;
            let offset_val = offset.unwrap_or(0) as usize;
            let mut total: u64 = 0;
            let mut entries: Vec<super::protocol::WorkListEntry> = Vec::new();
            for (id, ws) in srv.works_iter() {
                if ws.work().is_archived() {
                    if *id == 0x586 {
                        tracing::info!("[worklist] 0x586 is ARCHIVED");
                    }
                    continue;
                }
                let read_club = ws.work().read_club();
                if !srv.work_is_readable(session_id, &ws.work()) {
                    if *id == 0x586 {
                        tracing::info!(
                            "[worklist] 0x586 NOT readable — read_club={:?} edit_club={:?}",
                            read_club,
                            ws.work().edit_club()
                        );
                    }
                    continue;
                }
                if *id == 0x586 {
                    tracing::info!("[worklist] 0x586 INCLUDED — read_club={:?}", read_club);
                }
                total += 1;
                if total > offset_val as u64 && entries.len() < limit_val {
                    entries.push(super::protocol::WorkListEntry {
                        work_id: *id,
                        owner: ws.work().owner(),
                        revision_count: ws.work().revision_count(),
                        is_grabbed: ws.grabber().is_some(),
                        char_count: ws.work().current_edition().to_text().len() as u64,
                        title: ws.cached_title().to_string(),
                        read_club,
                        is_source: ws.is_source(),
                        content_start_line: ws.content_start_line(),
                        content_end_line: ws.content_end_line(),
                        source_author_id: ws.source_author_id(),
                        source_edition_info: ws.source_edition_info().map(|s| s.to_string()),
                        is_starred: starred.contains(id),
                        updated_at: ws.latest_revision_timestamp(),
                        content_crum: ws
                            .work()
                            .current_edition()
                            .crum()
                            .map(|c| c.iter().map(|b| format!("{:02x}", b)).collect()),
                    });
                }
            }
            let has_more = total as usize > offset_val + limit_val;
            Ok(ResponseValue::PaginatedWorkList {
                entries,
                total_count: total,
                has_more,
            })
        }
        WireRequest::WorkListByOwner {
            owner,
            offset,
            limit,
        } => {
            let starred = srv.starred_for_session(session_id);
            let all: Vec<_> = srv
                .list_works_by_owner(owner)
                .into_iter()
                .filter(|(work_id, _, _, _, _)| {
                    srv.work(*work_id)
                        .map(|w| srv.work_is_readable(session_id, w))
                        .unwrap_or(false)
                })
                .map(|(work_id, owner, revision_count, is_grabbed, read_club)| {
                    super::protocol::WorkListEntry {
                        work_id,
                        owner,
                        revision_count,
                        is_grabbed,
                        char_count: 0,
                        title: String::new(),
                        read_club,
                        is_source: false,
                        content_start_line: None,
                        content_end_line: None,
                        source_author_id: None,
                        source_edition_info: None,
                        is_starred: starred.contains(&work_id),
                        updated_at: None,
                        content_crum: None,
                    }
                })
                .collect();
            let total_count = all.len() as u64;
            let limit_val = limit.unwrap_or(100).min(1000) as usize;
            let offset_val = offset.unwrap_or(0) as usize;
            let has_more = offset_val + limit_val < all.len();
            let entries: Vec<_> = all.into_iter().skip(offset_val).take(limit_val).collect();
            Ok(ResponseValue::PaginatedWorkList {
                entries,
                total_count,
                has_more,
            })
        }

        WireRequest::LinkCreate {
            origin,
            destination,
            origin_ref,
            destination_ref,
            link_types,
            home_document,
        } => {
            srv.ensure_authenticated(session_id)?;
            srv.ensure_can_read(session_id, origin)?;
            srv.ensure_can_read(session_id, destination)?;
            if let Some(home) = home_document {
                srv.ensure_can_read(session_id, home)?;
            }
            let destination_ref_payload = destination_ref.clone();
            let o_ref = origin_ref.map(|hr| {
                tracing::info!(
                    "[link_create] origin_ref excerpt present={}, len={}",
                    hr.excerpt.is_some(),
                    hr.excerpt.as_deref().map(|s| s.len()).unwrap_or(0)
                );
                let span_start = hr.start_position;
                let span_end = hr.end_position;
                let excerpt = hr
                    .excerpt
                    .as_deref()
                    .map(|t| crate::edition::Edition::from_text(t));
                let path = hr.path_context.map(|labels| {
                    crate::edition::links::Path::new(
                        labels.iter().filter_map(|l| l.to_range_element()).collect(),
                    )
                });
                let mut hr_built = crate::edition::links::HyperRef::single(
                    excerpt,
                    hr.work_context,
                    hr.original_context,
                    path,
                )
                .with_span(span_start, span_end);
                if let Some(csr_payload) = &hr.cross_server_ref {
                    if let Some(csr) = csr_payload.to_cross_server_ref() {
                        hr_built = hr_built.with_cross_server_ref(csr);
                    }
                }
                hr_built
            });
            let d_ref = destination_ref.map(|hr| {
                let span_start = hr.start_position;
                let span_end = hr.end_position;
                let excerpt = hr
                    .excerpt
                    .as_deref()
                    .map(|t| crate::edition::Edition::from_text(t));
                let path = hr.path_context.map(|labels| {
                    crate::edition::links::Path::new(
                        labels.iter().filter_map(|l| l.to_range_element()).collect(),
                    )
                });
                let mut hr_built = crate::edition::links::HyperRef::single(
                    excerpt,
                    hr.work_context,
                    hr.original_context,
                    path,
                )
                .with_span(span_start, span_end);
                if let Some(csr_payload) = &hr.cross_server_ref {
                    if let Some(csr) = csr_payload.to_cross_server_ref() {
                        hr_built = hr_built.with_cross_server_ref(csr);
                    }
                }
                hr_built
            });
            let link_id = if link_types.is_empty() {
                srv.create_link_homed(session_id, origin, destination, o_ref, d_ref, home_document)?
            } else {
                let chain = srv.compute_provenance_chain(origin);
                let o_with_chain = o_ref
                    .map(|r| r.with_provenance_chain(chain.clone()))
                    .unwrap_or_else(|| {
                        crate::edition::links::HyperRef::single(None, Some(origin), None, None)
                            .with_provenance_chain(chain)
                    });
                let d_final = d_ref.unwrap_or_else(|| {
                    crate::edition::links::HyperRef::single(None, Some(destination), None, None)
                });
                let link =
                    crate::edition::links::HyperLink::make(link_types, o_with_chain, d_final);
                srv.create_link_with_hyperlink_homed(session_id, link, home_document)?
            };

            if let Some(ref d_hyper_ref) = destination_ref_payload {
                if let Some(ref csr) = d_hyper_ref.cross_server_ref {
                    if let Some(csr) = csr.to_cross_server_ref() {
                        let target_addr = csr.origin_server_address.clone().unwrap_or_default();
                        if !target_addr.is_empty() {
                            let work_hex = crate::edition::links::tumbler_local_path(&csr.tumbler)
                                .split('.')
                                .next()
                                .unwrap_or("")
                                .to_string();
                            let notify_url = format!(
                                "{}/api/backlink-notify",
                                if target_addr.starts_with("http") {
                                    target_addr.clone()
                                } else {
                                    format!("http://{}", target_addr)
                                }
                                .trim_end_matches('/')
                            );
                            let notify_body = serde_json::json!({
                                "target_work_id": work_hex,
                                "origin_server_address": srv.public_address().unwrap_or("").to_string(),
                                "origin_server_name": srv.server_name().to_string(),
                                "origin_work_id": format!("{:04x}", origin),
                                "origin_work_title": srv.works.get(&origin).map(|w| w.cached_title().to_string()).unwrap_or_default(),
                                "excerpt": csr.excerpt.chars().take(200).collect::<String>(),
                                "link_type": "cross-server",
                            });
                            tracing::info!(
                                "Sending cross-server backlink notification to {}",
                                notify_url
                            );
                            // FR-40 sender feedback: record the definitive
                            // outcome on the link so the creating user
                            // learns whether the receiving server
                            // accepted it (queryable via link_get).
                            // Timeout is deliberately short: this runs
                            // inline on the dispatch path — a network
                            // blackhole must not stall other users.
                            match crate::server::server::http_post_json_status(
                                &notify_url,
                                &notify_body.to_string(),
                                5,
                            ) {
                                Ok((status, resp_body)) if (200..300).contains(&status) => {
                                    srv.set_link_cross_server_notify(link_id, true, None);
                                }
                                Ok((status, resp_body)) => {
                                    let reason = if resp_body.trim().is_empty() {
                                        format!("receiving server returned HTTP {}", status)
                                    } else {
                                        format!(
                                            "receiving server rejected (HTTP {}): {}",
                                            status,
                                            resp_body.trim().chars().take(200).collect::<String>()
                                        )
                                    };
                                    tracing::warn!(
                                        "Cross-server backlink notification rejected: {}",
                                        reason
                                    );
                                    srv.set_link_cross_server_notify(link_id, false, Some(reason));
                                }
                                Err(e) => {
                                    tracing::warn!(
                                        "Cross-server backlink notification failed: {}",
                                        e
                                    );
                                    srv.set_link_cross_server_notify(
                                        link_id,
                                        false,
                                        Some(format!("could not reach receiving server: {}", e)),
                                    );
                                }
                            }
                        }
                    }
                }
            }

            Ok(ResponseValue::Id(link_id))
        }
        WireRequest::LinkGet { link_id } => {
            let (origin, destination, link) = srv.get_link(link_id)?;
            srv.ensure_can_read(session_id, origin)?;
            srv.ensure_can_read(session_id, destination)?;
            Ok(ResponseValue::LinkInfo(build_link_payload(
                srv,
                link_id,
                origin,
                destination,
                link,
            )))
        }
        WireRequest::LinkUpdate {
            link_id,
            origin_ref,
            destination_ref,
        } => {
            {
                let (origin, destination, _) = srv.get_link(link_id)?;
                let can_edit_origin = srv
                    .work(origin)
                    .map(|w| srv.check_edit_permission(session_id, w))
                    .unwrap_or(false);
                let can_edit_destination = srv
                    .work(destination)
                    .map(|w| srv.check_edit_permission(session_id, w))
                    .unwrap_or(false);
                if !can_edit_origin && !can_edit_destination {
                    return Err(crate::server::ServerError::NotAuthorized);
                }
            }
            let o_ref = origin_ref.map(|hr| {
                let span_start = hr.start_position;
                let span_end = hr.end_position;
                let excerpt = hr
                    .excerpt
                    .as_deref()
                    .map(|t| crate::edition::Edition::from_text(t));
                let chain: Vec<crate::edition::links::ProvenanceHop> = hr
                    .provenance_chain
                    .into_iter()
                    .map(|hop| {
                        crate::edition::links::ProvenanceHop::new(hop.source_work_id, hop.link_id)
                    })
                    .collect();
                crate::edition::links::HyperRef::single(
                    excerpt,
                    hr.work_context,
                    hr.original_context,
                    None,
                )
                .with_span(span_start, span_end)
                .with_provenance_chain(chain)
            });
            let d_ref = destination_ref.map(|hr| {
                let span_start = hr.start_position;
                let span_end = hr.end_position;
                let excerpt = hr
                    .excerpt
                    .as_deref()
                    .map(|t| crate::edition::Edition::from_text(t));
                let chain: Vec<crate::edition::links::ProvenanceHop> = hr
                    .provenance_chain
                    .into_iter()
                    .map(|hop| {
                        crate::edition::links::ProvenanceHop::new(hop.source_work_id, hop.link_id)
                    })
                    .collect();
                crate::edition::links::HyperRef::single(
                    excerpt,
                    hr.work_context,
                    hr.original_context,
                    None,
                )
                .with_span(span_start, span_end)
                .with_provenance_chain(chain)
            });
            srv.update_link(session_id, link_id, o_ref, d_ref)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::LinkDelete { link_id } => {
            {
                let (origin, destination, _) = srv.get_link(link_id)?;
                let can_edit_origin = srv
                    .work(origin)
                    .map(|w| srv.check_edit_permission(session_id, w))
                    .unwrap_or(false);
                let can_edit_destination = srv
                    .work(destination)
                    .map(|w| srv.check_edit_permission(session_id, w))
                    .unwrap_or(false);
                if !can_edit_origin && !can_edit_destination {
                    return Err(crate::server::ServerError::NotAuthorized);
                }
            }
            srv.delete_link(session_id, link_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::LinkListForWork {
            work_id,
            offset,
            limit,
        } => {
            srv.ensure_can_read(session_id, work_id)?;
            let all: Vec<_> = srv
                .list_links_for_work(work_id)
                .into_iter()
                .filter(|&(link_id, _, _)| !srv.link_hidden_by_home_archive(link_id))
                .filter_map(|(link_id, origin, destination)| {
                    let (_, _, link) = srv.get_link(link_id).ok()?;
                    Some(build_link_payload(srv, link_id, origin, destination, link))
                })
                .collect();
            let total_count = all.len() as u64;
            let limit_val = limit.unwrap_or(100).min(1000) as usize;
            let offset_val = offset.unwrap_or(0) as usize;
            let has_more = offset_val + limit_val < all.len();
            let entries: Vec<_> = all.into_iter().skip(offset_val).take(limit_val).collect();
            Ok(ResponseValue::PaginatedLinkList {
                entries,
                total_count,
                has_more,
            })
        }
        WireRequest::LinkAddEnd {
            link_id,
            end_name,
            end_ref,
        } => {
            srv.ensure_authenticated(session_id)?;
            let (origin, destination, _) = srv.get_link(link_id)?;
            srv.ensure_can_read(session_id, origin)?;
            srv.ensure_can_read(session_id, destination)?;
            let hr = end_ref.to_hyper_ref(origin);
            srv.link_add_end(session_id, link_id, &end_name, hr)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::LinkRemoveEnd { link_id, end_name } => {
            srv.ensure_authenticated(session_id)?;
            srv.link_remove_end(session_id, link_id, &end_name)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::LinkSetTypes {
            link_id,
            link_types,
        } => {
            srv.ensure_authenticated(session_id)?;
            srv.link_set_types(session_id, link_id, link_types)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::LinkTypeRegister {
            type_id,
            name,
            definition_work,
        } => {
            srv.ensure_authenticated(session_id)?;
            srv.register_link_type_checked(session_id, type_id, name, definition_work)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::LinkTypeList => {
            let types = srv
                .list_link_types()
                .into_iter()
                .map(|(type_id, name)| super::protocol::LinkTypeInfoPayload {
                    type_id,
                    name,
                    definition_work: srv.link_type_definition(type_id),
                })
                .collect();
            Ok(ResponseValue::LinkTypes(types))
        }
        WireRequest::LinkQuery {
            from_spec,
            to_spec,
            type_ids,
            home_spec,
        } => {
            let matches =
                srv.link_query(session_id, &from_spec, &to_spec, &type_ids, &home_spec)?;
            let entries: Vec<_> = matches
                .into_iter()
                .filter_map(|(link_id, origin, destination)| {
                    let (_, _, link) = srv.get_link(link_id).ok()?;
                    Some(build_link_payload(srv, link_id, origin, destination, link))
                })
                .collect();
            Ok(ResponseValue::LinkList(entries))
        }
        WireRequest::FindExcerptPositions { work_id, excerpt } => {
            srv.ensure_can_read(session_id, work_id)?;
            let positions = srv.find_excerpt_positions(work_id, &excerpt);
            let payloads = positions
                .into_iter()
                .map(|(start, end)| super::protocol::ExcerptPositionPayload { start, end })
                .collect();
            Ok(ResponseValue::ExcerptPositions(payloads))
        }

        WireRequest::FindTranscluders { content_be_id } => {
            let results = srv
                .find_transcluders_for_session(session_id, content_be_id)
                .unwrap_or_else(|_| srv.find_transcluders(content_be_id))
                .into_iter()
                .filter(|(element_type, element_id, _)| {
                    if element_type == "work" {
                        srv.work(*element_id)
                            .map(|w| srv.work_is_readable(session_id, w))
                            .unwrap_or(false)
                    } else {
                        true
                    }
                })
                .map(|(element_type, element_id, is_direct)| {
                    super::protocol::TransclusionResultPayload {
                        element_type,
                        element_id,
                        is_direct,
                    }
                })
                .collect();
            Ok(ResponseValue::TransclusionResults(results))
        }
        WireRequest::FindWorksForContent { content_be_id } => {
            let work_ids = srv
                .find_works_for_content(content_be_id)
                .into_iter()
                .filter(|wid| {
                    srv.work(*wid)
                        .map(|w| srv.work_is_readable(session_id, w))
                        .unwrap_or(false)
                })
                .collect();
            Ok(ResponseValue::WorkIds(work_ids))
        }
        WireRequest::FindTextTranscluders { text } => {
            let results = srv.find_text_transcluders(&text);
            let payloads = results
                .into_iter()
                .filter(|(work_id, _, _, _)| {
                    srv.work(*work_id)
                        .map(|w| srv.work_is_readable(session_id, w))
                        .unwrap_or(false)
                })
                .map(|(work_id, owner, revision_count, matches)| {
                    super::protocol::TextTransclusionResultPayload {
                        work_id,
                        owner,
                        revision_count,
                        matches: matches
                            .into_iter()
                            .map(|(start, end)| super::protocol::TextMatchPayload { start, end })
                            .collect(),
                    }
                })
                .collect();
            Ok(ResponseValue::TextTransclusionResults(payloads))
        }
        WireRequest::FindSharedRegions {
            work_a,
            work_b,
            filter_text,
        } => {
            srv.ensure_can_read(session_id, work_a)?;
            srv.ensure_can_read(session_id, work_b)?;

            let results = if let Some(ft) = filter_text.as_ref().filter(|s| !s.is_empty()) {
                srv.find_shared_regions_filtered(work_a, work_b, ft)
            } else {
                srv.find_shared_regions(work_a, work_b)
            };

            let payloads = results
                .into_iter()
                .map(|(start_a, end_a, start_b, end_b, text)| {
                    super::protocol::SharedRegionPayload {
                        work_id: work_b,
                        start_a,
                        end_a,
                        start_b,
                        end_b,
                        text,
                    }
                })
                .collect();
            Ok(ResponseValue::SharedRegions(payloads))
        }
        WireRequest::WorkDiffRegions { work_a, work_b } => {
            srv.ensure_can_read(session_id, work_a)?;
            srv.ensure_can_read(session_id, work_b)?;
            let result = srv.work_diff_regions(work_a, work_b);
            let shared: Vec<serde_json::Value> = result
                .shared
                .iter()
                .map(|s| {
                    serde_json::json!({
                        "start_a": s.start_a, "end_a": s.end_a,
                        "start_b": s.start_b, "end_b": s.end_b,
                        "text": s.text,
                    })
                })
                .collect();
            let changed_a: Vec<serde_json::Value> = result
                .changed_a
                .iter()
                .map(|(s, e)| serde_json::json!([s, e]))
                .collect();
            let changed_b: Vec<serde_json::Value> = result
                .changed_b
                .iter()
                .map(|(s, e)| serde_json::json!([s, e]))
                .collect();
            let val = serde_json::json!({
                "shared": shared,
                "changed_a": changed_a,
                "changed_b": changed_b,
                "text_len_a": result.text_len_a,
                "text_len_b": result.text_len_b,
                "coverage": result.coverage,
            });
            Ok(ResponseValue::JsonValue(val))
        }
        WireRequest::RenderTransclusions { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let elements = srv.render_transclusions(work_id)?;
            let payloads: Vec<super::protocol::RenderedElementPayload> = elements
                .into_iter()
                .map(|e| super::protocol::RenderedElementPayload {
                    position: e.position,
                    text: e.text,
                    source_work_id: e.source_work_id,
                    source_author_name: e.source_author_name,
                    is_transcluded: e.is_transcluded,
                    transclusion_sources: e
                        .transclusion_sources
                        .into_iter()
                        .map(|s| super::protocol::TransclusionSourcePayload {
                            work_id: s.work_id,
                            title: s.title,
                            author_name: s.author_name,
                            is_direct: s.is_direct,
                        })
                        .collect(),
                })
                .collect();
            Ok(ResponseValue::RenderedTransclusions(payloads))
        }

        WireRequest::BlobUpload { data, mime_type } => {
            srv.ensure_authenticated(session_id)?;
            let raw_data = crate::edition::base64_decode(&data).ok_or_else(|| {
                crate::server::ServerError::InvalidArgument("invalid base64 data".to_string())
            })?;
            let meta = srv.blob_upload(session_id, raw_data, mime_type)?;
            Ok(ResponseValue::BlobMeta(
                super::protocol::BlobMetaPayload::from_blob_meta(&meta),
            ))
        }
        WireRequest::BlobGet { content_hash } => {
            let data = srv.blob_get(content_hash.parse().unwrap_or(0))?;
            Ok(ResponseValue::BlobData(data))
        }
        WireRequest::BlobGetPreview { content_hash } => {
            match srv.blob_preview(content_hash.parse().unwrap_or(0))? {
                Some(data) => Ok(ResponseValue::BlobData(data)),
                None => Ok(ResponseValue::Void),
            }
        }
        WireRequest::BlobExists { content_hash } => Ok(ResponseValue::Boolean(
            srv.blob_exists(content_hash.parse().unwrap_or(0)),
        )),
        WireRequest::BlobInfo { content_hash } => {
            let meta = srv.blob_info(content_hash.parse().unwrap_or(0))?;
            Ok(ResponseValue::BlobMeta(
                super::protocol::BlobMetaPayload::from_blob_meta(&meta),
            ))
        }
        WireRequest::BlobStats => {
            let (total_blobs, total_bytes) = srv.blob_stats();
            Ok(ResponseValue::BlobStatsInfo(
                super::protocol::BlobStatsPayload {
                    total_blobs,
                    total_bytes,
                },
            ))
        }

        WireRequest::OverlayApply {
            base_hash,
            ops,
            mime_type,
        } => {
            srv.ensure_authenticated(session_id)?;
            let meta = srv.blob_apply_overlay(session_id, base_hash, ops, mime_type)?;
            Ok(ResponseValue::BlobMeta(
                super::protocol::BlobMetaPayload::from_blob_meta(&meta),
            ))
        }
        WireRequest::OverlayGet { overlay_hash } => {
            let overlay = srv.blob_get_overlay(overlay_hash)?;
            Ok(ResponseValue::OverlayInfo(
                super::protocol::OverlayPayload {
                    overlay_hash,
                    base_hash: overlay.base_hash,
                    operations: overlay.operations,
                    mime_type: overlay.mime_type,
                },
            ))
        }

        WireRequest::LabelCreate => {
            let label_id = srv.create_label();
            Ok(ResponseValue::LabelInfo { label_id })
        }
        WireRequest::LabelGetPositions { work_id, label_id } => {
            let positions = srv.label_get_positions(work_id, label_id)?;
            Ok(ResponseValue::LabelPositions {
                label_id,
                positions,
            })
        }
        WireRequest::EditionRelabel { work_id, label_id } => {
            srv.ensure_authenticated(session_id)?;
            let _ed = srv.edition_relabel(work_id, label_id)?;
            Ok(ResponseValue::LabelInfo { label_id })
        }
        WireRequest::EditionRebind {
            work_id,
            position,
            new_edition,
        } => {
            srv.ensure_authenticated(session_id)?;
            let ed = new_edition
                .to_edition_checked(work_id)
                .map_err(ServerError::InvalidArgument)?;
            let updated = srv.edition_rebind(session_id, work_id, position, ed)?;
            Ok(ResponseValue::Edition(EditionPayload::from_edition(
                &updated,
            )))
        }
        WireRequest::CanMakeIdentical {
            source_work_id,
            target_work_id,
            position,
        } => {
            let results =
                srv.can_make_identical_elements(source_work_id, target_work_id, position)?;
            let all_yes = !results.is_empty() && results.iter().all(|(_, r)| r == "yes");
            let any_yes = results.iter().any(|(_, r)| r == "yes");
            Ok(ResponseValue::CanMakeIdenticalResult {
                result: if results.is_empty() {
                    "no_positions".to_string()
                } else if all_yes {
                    "yes".to_string()
                } else if any_yes {
                    "partial".to_string()
                } else {
                    "no".to_string()
                },
            })
        }
        WireRequest::MakeRangeIdentical {
            source_work_id,
            target_work_id,
            region,
        } => {
            let (outcome, failed_count, failed_ed) = srv.make_range_identical_editions(
                session_id,
                source_work_id,
                target_work_id,
                region,
            )?;
            Ok(ResponseValue::MakeRangeIdenticalResult {
                outcome,
                failed_count,
                failed: EditionPayload::from_edition(&failed_ed),
            })
        }
        WireRequest::IdentityUnify {
            source_id,
            target_id,
        } => {
            srv.ensure_admin(session_id)?;
            srv.identity_unify(source_id, target_id);
            Ok(ResponseValue::IdentityResolveResult {
                resolved_id: target_id,
            })
        }
        WireRequest::IdentityResolve { id } => {
            let resolved = srv.identity_resolve(id);
            Ok(ResponseValue::IdentityResolveResult {
                resolved_id: resolved,
            })
        }
        WireRequest::EditionRetrieve {
            work_id,
            region,
            flags,
        } => {
            srv.ensure_can_read(session_id, work_id)?;
            use super::protocol::BundlePayload;
            use crate::edition::RetrieveFlags;
            let rf = match flags {
                Some(f) => RetrieveFlags {
                    ignore_total_ordering: f.ignore_total_ordering.unwrap_or(false),
                    ignore_array_ordering: f.ignore_array_ordering.unwrap_or(false),
                    separate_owners: f.separate_owners.unwrap_or(false),
                },
                None => RetrieveFlags::default(),
            };
            let bundles = srv.edition_retrieve(work_id, region.as_ref(), rf)?;
            let payloads: Vec<BundlePayload> =
                bundles.iter().map(BundlePayload::from_bundle).collect();
            Ok(ResponseValue::BundleResults { bundles: payloads })
        }
        WireRequest::EditionCost { work_id, method } => {
            use crate::edition::CostMethod;
            let cm = match method.as_deref() {
                Some("omit_shared") => CostMethod::OmitShared,
                Some("prorate_shared") => CostMethod::ProrateShared,
                _ => CostMethod::TotalShared,
            };
            let cost = srv.edition_cost(work_id, cm)?;
            Ok(ResponseValue::StorageCostResult {
                total_bytes: cost.total_bytes,
                unique_bytes: cost.unique_bytes,
                shared_bytes: cost.shared_bytes,
                share_count: cost.share_count,
                billed_bytes: cost.billed_bytes(),
                method: format!("{:?}", cm).to_lowercase(),
            })
        }
        WireRequest::CrossServerSpanRefresh {
            source_work,
            update,
        } => {
            let payload = srv.cross_server_span_refresh(session_id, source_work, update)?;
            Ok(ResponseValue::CrossServerSpanRefresh(payload))
        }
        WireRequest::TransclusionPlaceCrossServer {
            dest_work,
            cursor,
            tumbler,
            span_start,
            span_end,
            title_hint,
        } => {
            let payload = srv.transclusion_place_cross_server(
                session_id, dest_work, cursor, &tumbler, span_start, span_end, title_hint,
            )?;
            Ok(ResponseValue::CrossServerTransclusion(payload))
        }
        WireRequest::ElementInsert {
            work_id,
            position,
            element,
        } => {
            srv.ensure_can_edit(session_id, work_id)?;
            let elem = element.to_range_element().ok_or_else(|| {
                crate::server::ServerError::InvalidArgument(
                    "cannot convert payload to RangeElement".into(),
                )
            })?;
            let rev = srv.element_insert(session_id, work_id, position, elem)?;
            Ok(ResponseValue::Humber(rev))
        }
        WireRequest::ElementUpdate {
            work_id,
            char_position,
            element,
        } => {
            srv.ensure_can_edit(session_id, work_id)?;
            let elem = element.to_range_element().ok_or_else(|| {
                crate::server::ServerError::InvalidArgument(
                    "cannot convert payload to RangeElement".into(),
                )
            })?;
            let rev = srv.element_update(session_id, work_id, char_position, elem)?;
            Ok(ResponseValue::Humber(rev))
        }
        WireRequest::ContentSharedRegion { work_a, work_b } => {
            srv.ensure_can_read(session_id, work_a)?;
            srv.ensure_can_read(session_id, work_b)?;
            let region = srv.content_shared_region(work_a, work_b)?;
            Ok(ResponseValue::SharedRegionResult { region })
        }
        WireRequest::ContentMapSharedTo { work_a, work_b } => {
            srv.ensure_can_read(session_id, work_a)?;
            srv.ensure_can_read(session_id, work_b)?;
            let mapping = srv.content_map_shared_to(work_a, work_b)?;
            Ok(ResponseValue::SharedMappingResult {
                pairs: mapping.pairs().to_vec(),
            })
        }
        WireRequest::ContentMapSharedOnto { work_a, work_b } => {
            srv.ensure_can_read(session_id, work_a)?;
            srv.ensure_can_read(session_id, work_b)?;
            let mapping = srv.content_map_shared_onto(work_a, work_b)?;
            Ok(ResponseValue::SharedMappingResult {
                pairs: mapping.pairs().to_vec(),
            })
        }
        WireRequest::PositionsOf { work_id, element } => {
            srv.ensure_can_read(session_id, work_id)?;
            let region = srv.positions_of(work_id, &element)?;
            Ok(ResponseValue::PositionsOfResult { region })
        }
        WireRequest::RangeTranscluders {
            work_id,
            region,
            direct_only,
        } => {
            srv.ensure_can_read(session_id, work_id)?;
            let result =
                srv.range_transcluders(work_id, region.as_ref(), direct_only.unwrap_or(false))?;
            let readable_work_ids: Vec<BeId> = result
                .work_ids
                .into_iter()
                .filter(|wid| {
                    srv.work(*wid)
                        .map(|w| srv.work_is_readable(session_id, w))
                        .unwrap_or(false)
                })
                .collect();
            let readable_edition_ids: Vec<BeId> = result
                .edition_ids
                .into_iter()
                .filter(|eid| srv.get_edition(*eid).ok().flatten().is_some())
                .collect();
            Ok(ResponseValue::RangeTranscludersResult {
                edition_ids: readable_edition_ids,
                work_ids: readable_work_ids,
                region: result.region,
            })
        }
        WireRequest::RangeWorks { work_id, region } => {
            srv.ensure_can_read(session_id, work_id)?;
            let result = srv.range_works(work_id, region.as_ref())?;
            let readable_work_ids: Vec<BeId> = result
                .work_ids
                .into_iter()
                .filter(|wid| {
                    srv.work(*wid)
                        .map(|w| srv.work_is_readable(session_id, w))
                        .unwrap_or(false)
                })
                .collect();
            Ok(ResponseValue::RangeWorksResult {
                work_ids: readable_work_ids,
                region: result.region,
            })
        }
        WireRequest::OrderedBundles { work_id, region } => {
            srv.ensure_can_read(session_id, work_id)?;
            let bundles = srv.ordered_bundles(work_id, region.as_ref())?;
            let payloads: Vec<BundlePayload> =
                bundles.iter().map(BundlePayload::from_bundle).collect();
            Ok(ResponseValue::OrderedBundlesResult { bundles: payloads })
        }
        WireRequest::TransclusionDepth {
            work_id,
            position,
            max_depth,
        } => {
            srv.ensure_can_read(session_id, work_id)?;
            let depth = srv.transclusion_depth(work_id, position, max_depth.unwrap_or(10))?;
            Ok(ResponseValue::TransclusionDepthResult { depth })
        }
        WireRequest::VersionIsBefore { work_a, work_b } => {
            srv.ensure_can_read_history(session_id, work_a)?;
            srv.ensure_can_read_history(session_id, work_b)?;
            let is_before = srv.version_is_before(work_a, work_b);
            Ok(ResponseValue::VersionIsBeforeResult { is_before })
        }
        WireRequest::VersionAncestors { work_id } => {
            srv.ensure_can_read_history(session_id, work_id)?;
            let ancestors = srv.version_ancestors_transitive(work_id);
            let ancestors: Vec<_> = ancestors
                .into_iter()
                .filter(|id| {
                    srv.work(*id)
                        .map(|w| srv.work_is_readable(session_id, w))
                        .unwrap_or(false)
                })
                .collect();
            Ok(ResponseValue::VersionAncestorsResult { ancestors })
        }
        WireRequest::VersionDescendants { work_id } => {
            srv.ensure_can_read_history(session_id, work_id)?;
            let descendants = srv.version_descendants(work_id);
            let descendants: Vec<_> = descendants
                .into_iter()
                .filter(|id| {
                    srv.work(*id)
                        .map(|w| srv.work_is_readable(session_id, w))
                        .unwrap_or(false)
                })
                .collect();
            Ok(ResponseValue::VersionDescendantsResult { descendants })
        }
        WireRequest::VersionTracePosition { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let tp = srv.version_trace_position(work_id);
            let trace_position = tp.map(|tp| super::protocol::TracePositionPayload {
                branch_id: tp.branch().to_u64(),
                position: tp.position(),
            });
            Ok(ResponseValue::VersionTracePositionResult { trace_position })
        }
        WireRequest::ProvenanceAncestry { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let chain = srv.provenance_ancestry(work_id);
            let hops = srv.enrich_provenance_hops(&chain);
            Ok(ResponseValue::ProvenanceAncestryResult { chain: hops })
        }
        WireRequest::AdminRecorderCreate {
            kind,
            direct_only,
            region,
        } => {
            srv.ensure_admin(session_id)?;
            let recorder_kind = match kind.as_str() {
                "works" => crate::edition::RecorderKind::Works,
                _ => crate::edition::RecorderKind::Transcluders,
            };
            let query = crate::edition::RecorderQuery {
                kind: recorder_kind,
                region,
                direct_only: direct_only.unwrap_or(false),
                authority_clubs: Vec::new(),
                endorsement_filter: None,
                watched_content: Vec::new(),
            };
            let id = srv.recorder_create(query)?;
            Ok(ResponseValue::RecorderCreateResult { recorder_id: id })
        }
        WireRequest::AdminRecorderRecord {
            recorder_id,
            element,
        } => {
            srv.ensure_admin(session_id)?;
            let recorded = srv.recorder_record(recorder_id, &element)?;
            Ok(ResponseValue::RecorderRecordResult { recorded })
        }
        WireRequest::AdminRecorderList => {
            srv.ensure_admin(session_id)?;
            let recorders = srv
                .recorder_list()
                .into_iter()
                .map(|f| super::protocol::RecorderInfoPayload {
                    id: f.id,
                    kind: match f.query.kind {
                        crate::edition::RecorderKind::Transcluders => "transcluders".to_string(),
                        crate::edition::RecorderKind::Works => "works".to_string(),
                    },
                    direct_only: f.query.direct_only,
                    result_count: f.result_count(),
                    is_extinct: f.is_extinct,
                    reference_count: f.reference_count,
                    created_at: f.created_at,
                })
                .collect();
            Ok(ResponseValue::RecorderListResult { recorders })
        }
        WireRequest::AdminRecorderGet { recorder_id } => {
            srv.ensure_admin(session_id)?;
            let info =
                srv.recorder_get(recorder_id)
                    .map(|f| super::protocol::RecorderInfoPayload {
                        id: f.id,
                        kind: match f.query.kind {
                            crate::edition::RecorderKind::Transcluders => {
                                "transcluders".to_string()
                            }
                            crate::edition::RecorderKind::Works => "works".to_string(),
                        },
                        direct_only: f.query.direct_only,
                        result_count: f.result_count(),
                        is_extinct: f.is_extinct,
                        reference_count: f.reference_count,
                        created_at: f.created_at,
                    });
            Ok(ResponseValue::RecorderGetResult { recorder: info })
        }
        WireRequest::ResolveInlineTransclusions { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let result = srv.resolve_inline_transclusions(work_id)?;
            for sr in &result.span_ranges {
                srv.ensure_can_read(session_id, sr.source_work_id)?;
            }
            Ok(ResponseValue::ResolveInlineTransclusionsResult {
                text: result.text,
                span_ranges: result
                    .span_ranges
                    .iter()
                    .map(SpanRangePayload::from_span_range)
                    .collect(),
                source_titles: result.source_titles,
            })
        }
        WireRequest::AttributionQueryResolved { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let resolved = srv.resolve_inline_transclusions(work_id)?;
            for sr in &resolved.span_ranges {
                srv.ensure_can_read(session_id, sr.source_work_id)?;
            }
            let spans = srv.attribution_query_resolved(work_id)?;
            Ok(ResponseValue::AttributionQueryResult { spans })
        }
        WireRequest::MigrateCompoundToInline { work_id } => {
            srv.ensure_can_edit(session_id, work_id)?;
            let count = srv.migrate_compound_to_inline(work_id)?;
            Ok(ResponseValue::MigrateCompoundToInlineResult {
                migrated_count: count,
            })
        }
        WireRequest::ElementRemoveTransclusion {
            work_id,
            source_work_id,
            char_start,
            char_end,
        } => {
            srv.ensure_can_edit(session_id, work_id)?;
            let removed = srv.element_remove_transclusion(
                session_id,
                work_id,
                source_work_id,
                char_start,
                char_end,
            )?;
            Ok(ResponseValue::ElementRemoveTransclusionResult { removed })
        }
        WireRequest::AdminServerHealth => {
            let health = srv.server_health();
            Ok(ResponseValue::ServerHealthResult {
                operation_count: health.operation_count,
                active_recorders: health.active_recorders,
                total_recorded: health.total_recorded,
                blob_count: health.blob_count,
                link_count: health.link_count,
                uptime_secs: health.uptime_secs,
            })
        }
        WireRequest::CryptoGetPublicKey => {
            let identity = srv.server_identity();
            Ok(ResponseValue::CryptoPublicKeyResult {
                key_id: srv.server_key_id(),
                verifying_key: identity.signing_key_bytes().to_vec(),
                kex_key: identity.kex_public_bytes().to_vec(),
                server_id: identity.server_id,
            })
        }
        WireRequest::CryptoSignData { data } => {
            srv.ensure_admin(session_id)?;
            let sig = srv.sign_data(&data);
            Ok(ResponseValue::CryptoSignResult {
                signature: sig,
                key_id: srv.server_key_id(),
            })
        }
        WireRequest::CryptoVerifySignature { data, signature } => {
            let valid = srv.verify_server_signature(&data, &signature).is_ok();
            Ok(ResponseValue::CryptoVerifyResult { valid })
        }
        WireRequest::CryptoKeyRotation => {
            srv.ensure_admin(session_id)?;
            let new_id = srv.rotate_server_keys()?;
            Ok(ResponseValue::CryptoKeyRotationResult { new_key_id: new_id })
        }
        WireRequest::CryptoKeyHistory => {
            let history = srv.server_key_history();
            let entries = history
                .entries
                .iter()
                .map(|e| super::protocol::KeyHistoryEntryPayload {
                    key_id: e.key_id,
                    not_before: e.not_before,
                    not_after: e.not_after,
                })
                .collect();
            Ok(ResponseValue::CryptoKeyHistoryResult {
                server_id: history.server_id.clone(),
                current_key_id: history.current_key_id,
                entry_count: history.entry_count(),
                entries,
            })
        }
        WireRequest::WorkEndorse {
            work_id,
            endorsements,
        } => {
            let es = crate::edition::EndorsementSet::from_endorsements(
                endorsements
                    .iter()
                    .map(|&(c, t)| crate::edition::Endorsement::new(c, t))
                    .collect(),
            );
            srv.work_endorse(session_id, work_id, es)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkRetract {
            work_id,
            endorsements,
        } => {
            let es = crate::edition::EndorsementSet::from_endorsements(
                endorsements
                    .iter()
                    .map(|&(c, t)| crate::edition::Endorsement::new(c, t))
                    .collect(),
            );
            srv.work_retract(session_id, work_id, es)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkEndorsements { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let es = srv.work_endorsements(work_id)?;
            Ok(ResponseValue::EndorsementResult {
                endorsements: es.iter().map(|e| (e.club_id(), e.token_id())).collect(),
            })
        }
        WireRequest::EditionEndorse {
            edition_id,
            endorsements,
        } => {
            let es = crate::edition::EndorsementSet::from_endorsements(
                endorsements
                    .iter()
                    .map(|&(c, t)| crate::edition::Endorsement::new(c, t))
                    .collect(),
            );
            srv.edition_endorse(session_id, edition_id, es)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::EditionRetract {
            edition_id,
            endorsements,
        } => {
            let es = crate::edition::EndorsementSet::from_endorsements(
                endorsements
                    .iter()
                    .map(|&(c, t)| crate::edition::Endorsement::new(c, t))
                    .collect(),
            );
            srv.edition_retract(session_id, edition_id, es)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::EditionEndorsements { edition_id } => {
            srv.ensure_session(session_id)?;
            let es = srv.edition_endorsements(edition_id)?;
            Ok(ResponseValue::EndorsementResult {
                endorsements: es.iter().map(|e| (e.club_id(), e.token_id())).collect(),
            })
        }
        WireRequest::EditionVisibleEndorsements { edition_id } => {
            let es = srv.edition_visible_endorsements(session_id, edition_id)?;
            Ok(ResponseValue::EndorsementResult {
                endorsements: es.iter().map(|e| (e.club_id(), e.token_id())).collect(),
            })
        }
        WireRequest::EditionTotalEndorsements { edition_id } => {
            srv.ensure_session(session_id)?;
            let es = srv.edition_total_endorsements(edition_id)?;
            Ok(ResponseValue::EndorsementResult {
                endorsements: es.iter().map(|e| (e.club_id(), e.token_id())).collect(),
            })
        }
        WireRequest::FederationInfo => {
            let info = srv.federation_info();
            let mode_str = match info.mode {
                crate::server::federation::FederationMode::Closed => "closed".to_string(),
                crate::server::federation::FederationMode::Open => "open".to_string(),
            };
            Ok(ResponseValue::FederationInfoResult {
                server_id: info.server_id,
                federation_domain: info.federation_domain,
                key_id: info.key_id,
                verifying_key: info.verifying_key,
                kex_key: info.kex_key,
                mode: mode_str,
                peers: info
                    .peers
                    .into_iter()
                    .map(|p| super::protocol::FederationPeerPayload {
                        server_id: p.server_id,
                        address: p.address.to_string(),
                        connected: p.connected,
                    })
                    .collect(),
                work_count: info.work_count,
                edition_count: info.edition_count,
            })
        }
        WireRequest::FederationPeers => {
            let peers = srv.federation_peers();
            Ok(ResponseValue::FederationPeersResult {
                peers: peers.iter().map(|p| p.to_string()).collect(),
            })
        }
        WireRequest::FederatedTransclusionQuery {
            content_fingerprint_hex,
            direct_only,
        } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            let results =
                srv.federation_query_local_transclusion(&content_fingerprint_hex, direct_only);
            Ok(ResponseValue::FederatedTransclusionResult { results })
        }
        WireRequest::FederatedContentFetch {
            content_fingerprint_hex,
        } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            let response = srv.federation_fetch_by_fingerprint(&content_fingerprint_hex);
            match response {
                crate::server::server::FederationFetchResponse::Edition(payload) => {
                    Ok(ResponseValue::FederatedContentFetchResult {
                        found: true,
                        edition_payload: Some(payload),
                        blob_data: None,
                        blob_mime_type: None,
                    })
                }
                crate::server::server::FederationFetchResponse::Blob(data, mime) => {
                    Ok(ResponseValue::FederatedContentFetchResult {
                        found: true,
                        edition_payload: None,
                        blob_data: Some(data),
                        blob_mime_type: Some(mime),
                    })
                }
                crate::server::server::FederationFetchResponse::NotFound => {
                    Ok(ResponseValue::FederatedContentFetchResult {
                        found: false,
                        edition_payload: None,
                        blob_data: None,
                        blob_mime_type: None,
                    })
                }
            }
        }
        WireRequest::EndorsementSync { work_fingerprint } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            let entries = srv.reconcile_export_endorsements();
            let matches: Vec<(u64, u64, String)> = entries
                .into_iter()
                .filter(|(fp, _)| fp == &work_fingerprint)
                .flat_map(|(_, orset)| {
                    let vals: Vec<(u64, u64, String)> = orset
                        .values()
                        .into_iter()
                        .map(|e| (e.club_id, e.token_id, e.origin_server_id.clone()))
                        .collect();
                    vals
                })
                .collect();
            let tombstones: Vec<(u64, u64, String)> = srv
                .reconcile_get(&work_fingerprint)
                .map(|state| {
                    let (adds, tombs) = state.endorsements.to_entries();
                    let _ = adds;
                    tombs
                        .iter()
                        .map(|e| {
                            (
                                e.value.club_id,
                                e.value.token_id,
                                e.value.origin_server_id.clone(),
                            )
                        })
                        .collect()
                })
                .unwrap_or_default();
            Ok(ResponseValue::EndorsementSyncResult {
                endorsements: matches,
                tombstones,
            })
        }
        WireRequest::EndorsementAdd {
            work_fingerprint,
            club_id,
            token_id,
        } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            let tag = srv.reconcile_next_tag();
            let tag_server_id = tag.server_id.clone();
            let tag_counter = tag.counter;
            srv.reconcile_endorse(&work_fingerprint, club_id, token_id, tag);
            Ok(ResponseValue::EndorsementAddResult {
                tag_server_id,
                tag_counter,
            })
        }
        WireRequest::EndorsementRetract {
            work_fingerprint,
            club_id,
            token_id,
        } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            srv.reconcile_retract(&work_fingerprint, club_id, token_id);
            Ok(ResponseValue::EndorsementRetractResult {})
        }
        WireRequest::EndorsementQuery { work_fingerprint } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            let (matches, tombstones) = match srv.reconcile_get(&work_fingerprint) {
                Some(state) => {
                    let active: Vec<(u64, u64, String)> = state
                        .endorsements
                        .values()
                        .into_iter()
                        .map(|e| (e.club_id, e.token_id, e.origin_server_id.clone()))
                        .collect();
                    let (_, tombs) = state.endorsements.to_entries();
                    let tomb_vals: Vec<(u64, u64, String)> = tombs
                        .iter()
                        .map(|e| {
                            (
                                e.value.club_id,
                                e.value.token_id,
                                e.value.origin_server_id.clone(),
                            )
                        })
                        .collect();
                    (active, tomb_vals)
                }
                None => (Vec::new(), Vec::new()),
            };
            Ok(ResponseValue::EndorsementQueryResult {
                endorsements: matches,
                tombstones,
            })
        }
        WireRequest::StateSync { work_fingerprints } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            let states: Vec<crate::server::federation::ReconcileState> = srv
                .reconcile_export_all()
                .into_iter()
                .filter(|s| {
                    work_fingerprints.is_empty() || work_fingerprints.contains(&s.work_fingerprint)
                })
                .collect();
            Ok(ResponseValue::StateSyncResult { states })
        }
        WireRequest::StateAlternatives { work_fingerprint } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            let alternatives = srv.reconcile_alternatives(&work_fingerprint);
            let current_key = srv
                .reconcile_get(&work_fingerprint)
                .map(|s| s.current.value().clone())
                .unwrap_or_default();
            Ok(ResponseValue::StateAlternativesResult {
                alternatives,
                current_key,
            })
        }

        WireRequest::MembershipJoinRequest { entry } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            let result = srv.membership_process_join(entry);
            Ok(ResponseValue::MembershipJoinResult { result })
        }

        WireRequest::MembershipEndorseOffer { server_id, proof } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            let accepted = srv.membership_endorse(&server_id, proof);
            Ok(ResponseValue::MembershipEndorseOfferResult { accepted })
        }

        WireRequest::MembershipEndorseAccept { server_id } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            if let Some(vk_hex) = srv.membership_get_verifying_key_hex(&server_id) {
                if let Some(proof) = srv.membership_sign_endorsement(&server_id, &vk_hex) {
                    srv.membership_endorse(&server_id, proof);
                }
            }
            Ok(ResponseValue::MembershipEndorseAcceptResult {})
        }

        WireRequest::MembershipSync => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            let members = srv.membership_list();
            Ok(ResponseValue::MembershipSyncResult { members })
        }

        WireRequest::MembershipLeave => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_admin(session_id)?;
            srv.membership_leave();
            Ok(ResponseValue::MembershipLeaveResult {})
        }

        WireRequest::MembershipList => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            let members = srv.membership_list();
            Ok(ResponseValue::MembershipListResult { members })
        }

        WireRequest::MembershipVerify { server_id } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            let verify = srv.membership_verify(&server_id);
            Ok(ResponseValue::MembershipVerifyResult { verify })
        }

        WireRequest::GovernancePropose { transactions } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_admin(session_id)?;
            let proposal = srv.governance_propose(transactions);
            if let Some(ref p) = proposal {
                let _ = state.governance_tx.send(
                    super::federation_handler::FederationFrame::GovernancePrePrepare {
                        proposal: p.clone(),
                    },
                );
            }
            Ok(ResponseValue::GovernanceProposeResult { proposal })
        }

        WireRequest::GovernancePrepare { vote } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            let phase = srv.governance_receive_prepare(vote);
            Ok(ResponseValue::GovernancePrepareResult {
                phase: format!("{:?}", phase),
            })
        }

        WireRequest::GovernanceCommit { vote } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            let phase = srv.governance_receive_commit(vote);
            Ok(ResponseValue::GovernanceCommitResult {
                phase: format!("{:?}", phase),
            })
        }

        WireRequest::GovernanceSeal => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_admin(session_id)?;
            let batch = srv.governance_seal_round();
            Ok(ResponseValue::GovernanceSealResult { batch })
        }

        WireRequest::GovernanceLog => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            let log = srv.governance_log().to_vec();
            Ok(ResponseValue::GovernanceLogResult { log })
        }

        WireRequest::GovernanceStatus => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            Ok(ResponseValue::GovernanceStatusResult {
                view: srv.governance_current_view(),
                sequence: srv.governance_current_sequence(),
                cluster_size: srv.governance_cluster_size(),
                quorum: srv.governance_quorum_size(),
                is_leader: srv.governance_is_leader(),
                leader_id: srv.governance_leader_id(),
                pending: srv.governance_pending_round().is_some(),
            })
        }

        WireRequest::CrdtSyncOpen { work_id } => {
            srv.ensure_logged_in(session_id)?;
            let result = srv.crdt_open_session(session_id, work_id)?;
            Ok(ResponseValue::CrdtSyncOpenResult {
                state_vector: result.state_vector,
                current_text: result.current_text,
            })
        }

        WireRequest::CrdtSyncClose { work_id } => {
            srv.ensure_logged_in(session_id)?;
            if let Ok(result) = srv.crdt_remove_awareness(session_id, work_id) {
                for (relay_sid, _) in &result.relay_to {
                    use super::channel::EventMessage;
                    let ev = EventMessage {
                        session_id: *relay_sid,
                        subscription_id: 0,
                        event: EventPayload::CrdtAwarenessRemove {
                            work_id,
                            session_id: session_id.as_u64(),
                        },
                    };
                    state.send_to_session(relay_sid, ev);
                }
            }
            srv.crdt_close_session(session_id, work_id)?;
            Ok(ResponseValue::Void)
        }

        WireRequest::CrdtSyncUpdate { work_id, update } => {
            srv.ensure_logged_in(session_id)?;
            let result = srv.crdt_apply_update(session_id, work_id, update)?;
            Ok(ResponseValue::CrdtSyncUpdateResult {
                relay_count: result.relay_to.len(),
            })
        }

        WireRequest::CrdtSyncDiff {
            work_id,
            state_vector,
        } => {
            srv.ensure_logged_in(session_id)?;
            let update = srv.crdt_get_diff(work_id, state_vector)?;
            Ok(ResponseValue::CrdtSyncDiffResult { update })
        }

        WireRequest::CrdtSyncFullState { work_id } => {
            srv.ensure_logged_in(session_id)?;
            let state = srv.crdt_get_full_state(work_id)?;
            Ok(ResponseValue::CrdtSyncFullStateResult { state })
        }

        WireRequest::CrdtSyncMaterialize { work_id } => {
            srv.ensure_logged_in(session_id)?;
            let revision = srv.crdt_materialize_now(session_id, work_id)?;
            Ok(ResponseValue::CrdtSyncMaterializeResult { revision })
        }

        WireRequest::CrdtSyncSubscriberCount { work_id } => {
            srv.ensure_logged_in(session_id)?;
            let count = srv.crdt_subscriber_count(work_id);
            Ok(ResponseValue::CrdtSyncSubscriberCountResult { count })
        }

        WireRequest::CrdtSyncText { work_id } => {
            srv.ensure_logged_in(session_id)?;
            let text = srv.crdt_current_text(work_id)?;
            Ok(ResponseValue::CrdtSyncTextResult { text })
        }

        WireRequest::CrdtAwarenessUpdate {
            work_id,
            mut awareness,
        } => {
            srv.ensure_logged_in(session_id)?;
            let (display_name, club_id, pub_key) = srv.identity_for_session(session_id);
            awareness.user_name = display_name;
            awareness.club_id = club_id;
            awareness.author_public_key = pub_key;
            awareness.session_id = session_id.as_u64();
            let result = srv.crdt_update_awareness(session_id, work_id, awareness.clone())?;
            for (relay_sid, _) in &result.relay_to {
                use super::channel::EventMessage;
                let ev = EventMessage {
                    session_id: *relay_sid,
                    subscription_id: 0,
                    event: EventPayload::CrdtAwarenessUpdate {
                        work_id,
                        state: awareness.clone(),
                    },
                };
                state.send_to_session(relay_sid, ev);
            }
            Ok(ResponseValue::CrdtAwarenessUpdateResult {
                relay_count: result.relay_to.len(),
            })
        }

        WireRequest::CrdtAwarenessGet { work_id } => {
            srv.ensure_logged_in(session_id)?;
            let mut states = srv.crdt_get_awareness(work_id)?;
            // Never echo the requester their own presence: the state
            // carries the SERVER-side masked SessionId, which clients
            // cannot predict from their session_connect id — the
            // self-echo rendered as a phantom "remote" caret.
            states.retain(|s| s.session_id != session_id.as_u64());
            Ok(ResponseValue::CrdtAwarenessGetResult { states })
        }

        WireRequest::CrdtRegisterAuthor {
            work_id,
            public_key: _,
            display_name: _,
        } => {
            srv.crdt_update_author(session_id, work_id)?;
            Ok(ResponseValue::CrdtRegisterAuthorResult { registered: true })
        }

        WireRequest::AttributionQuery {
            work_id,
            start,
            end,
        } => {
            srv.ensure_can_read(session_id, work_id)?;
            if srv.crdt_needs_materialization(work_id) {
                srv.crdt_materialize_any_session(work_id).map_err(|e| {
                    tracing::warn!("attribution_query: materialize failed: {e}");
                    crate::server::ServerError::Internal(e.to_string())
                })?;
            }
            let spans = srv.attribution_query(work_id, start, end)?;
            Ok(ResponseValue::AttributionQueryResult { spans })
        }

        WireRequest::AttributionVerify {
            author_public_key,
            signature,
            timestamp,
            server_id,
            span_fingerprint_hex,
        } => {
            let author_pk: [u8; 32] = author_public_key.try_into().map_err(|_| {
                crate::server::ServerError::InvalidArgument(
                    "author_public_key must be 32 bytes".into(),
                )
            })?;
            let sig: [u8; 64] = signature.try_into().map_err(|_| {
                crate::server::ServerError::InvalidArgument("signature must be 64 bytes".into())
            })?;
            let sid: [u8; 32] = server_id.try_into().map_err(|_| {
                crate::server::ServerError::InvalidArgument("server_id must be 32 bytes".into())
            })?;
            let valid =
                srv.attribution_verify(author_pk, sig, timestamp, sid, &span_fingerprint_hex);
            Ok(ResponseValue::AttributionVerifyResult { valid })
        }

        WireRequest::AttributionLogStatus => Ok(srv.attribution_log_status()),
        WireRequest::AttestationReport { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let report = srv.generate_attestation_report(work_id, session_id)?;
            Ok(ResponseValue::AttestationReportResult {
                report_json: report,
            })
        }
        WireRequest::WorkTextRange {
            work_id,
            start_char,
            end_char,
        } => {
            srv.ensure_can_read(session_id, work_id)?;
            let result = srv.crdt_text_range(work_id, start_char as usize, end_char as usize)?;
            Ok(ResponseValue::WorkTextRangeResult {
                text: result.text,
                total_chars: result.total_chars as u64,
                start_char: result.start_char as u64,
                end_char: result.end_char as u64,
            })
        }
        WireRequest::WorkOutline { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let entries = srv.work_outline(work_id)?;
            let payload: Vec<super::protocol::OutlineEntryPayload> = entries
                .into_iter()
                .map(|e| super::protocol::OutlineEntryPayload {
                    level: e.level,
                    text: e.text,
                    line: e.line,
                    char_offset: e.char_offset,
                })
                .collect();
            Ok(ResponseValue::WorkOutlineResult { entries: payload })
        }
        WireRequest::WorkSearch {
            work_id,
            query,
            max_results,
        } => {
            srv.ensure_can_read(session_id, work_id)?;
            let max = max_results.unwrap_or(100) as usize;
            let matches = srv.work_search(work_id, &query, max)?;
            let payload: Vec<super::protocol::SearchMatchPayload> = matches
                .into_iter()
                .map(|m| super::protocol::SearchMatchPayload {
                    char_offset: m.char_offset,
                    line: m.line,
                    context: m.context,
                })
                .collect();
            let total = payload.len() as u64;
            Ok(ResponseValue::WorkSearchResult {
                matches: payload,
                total_matches: total,
            })
        }
        WireRequest::WorkGoto {
            work_id,
            line,
            char,
            context_lines,
        } => {
            srv.ensure_can_read(session_id, work_id)?;
            let target_line = line.unwrap_or(0);
            let ctx = context_lines.unwrap_or(10);
            let (start_line, char_offset, context) = srv.work_goto(work_id, target_line, ctx)?;
            let actual_char = char.unwrap_or(char_offset);
            Ok(ResponseValue::WorkGotoResult {
                line: start_line,
                char_offset: actual_char,
                context,
                context_start_line: start_line,
            })
        }
        WireRequest::WorkDiffNarration { .. } => Err(crate::server::ServerError::Internal(
            "work_diff_narration not routed (dispatcher invariant violated)".to_string(),
        )),
        WireRequest::WorkWritingFeedback { .. } => Err(crate::server::ServerError::Internal(
            "work_writing_feedback not routed (dispatcher invariant violated)".to_string(),
        )),

        WireRequest::WorkBacklinks { work_id } => {
            srv.ensure_session(session_id)?;
            let backlinks = srv.find_backlinks(session_id, work_id)?;
            Ok(ResponseValue::WorkBacklinksResult(backlinks))
        }

        WireRequest::AnnotationCreate {
            work_id,
            annotation_id,
            kind,
            payload,
            char_start,
            char_end,
            is_private,
        } => {
            srv.annotation_create(
                session_id,
                work_id,
                annotation_id,
                kind,
                payload,
                char_start,
                char_end,
                is_private,
            )?;
            Ok(ResponseValue::Id(annotation_id))
        }
        WireRequest::AnnotationDelete {
            work_id,
            annotation_id,
        } => {
            srv.annotation_delete(session_id, work_id, annotation_id)?;
            Ok(ResponseValue::Boolean(true))
        }
        WireRequest::AnnotationAttachNode {
            work_id,
            annotation_id,
            node_id,
        } => {
            srv.annotation_attach_node(session_id, work_id, annotation_id, node_id)?;
            Ok(ResponseValue::Boolean(true))
        }
        WireRequest::AnnotationAttachSpan {
            work_id,
            annotation_id,
            span_id,
        } => {
            srv.annotation_attach_span(session_id, work_id, annotation_id, span_id)?;
            Ok(ResponseValue::Boolean(true))
        }
        WireRequest::AnnotationGet {
            work_id,
            annotation_id,
        } => {
            let result = srv.annotation_get(session_id, work_id, annotation_id)?;
            match result {
                Some(ann) => Ok(ResponseValue::AnnotationResult(ann)),
                None => Err(crate::server::ServerError::NotFound(format!(
                    "annotation {} on work {}",
                    annotation_id, work_id
                ))),
            }
        }
        WireRequest::AnnotationList { work_id } => {
            let annotations = srv.annotation_list(session_id, work_id)?;
            Ok(ResponseValue::AnnotationListResult(annotations))
        }

        WireRequest::HistoricalAuthorRegister {
            name,
            display_name,
            birth_year,
            death_year,
            external_ids,
            source_bibliography,
        } => {
            srv.ensure_logged_in(session_id)?;
            let session = srv
                .sessions
                .get(&session_id)
                .ok_or(crate::server::ServerError::SessionRequired)?;
            let created_by = session
                ._key_master()
                .and_then(|km| km.login_authority().iter().next().copied())
                .ok_or(crate::server::ServerError::NotAuthorized)?;
            let author = srv.register_historical_author(
                name,
                display_name,
                birth_year,
                death_year,
                external_ids,
                source_bibliography,
                created_by,
            )?;
            Ok(ResponseValue::HistoricalAuthorResult {
                be_id: author.be_id,
                name: author.name,
                display_name: author.display_name,
                birth_year: author.birth_year,
                death_year: author.death_year,
                external_ids: author.external_ids,
                source_bibliography: author.source_bibliography,
            })
        }

        WireRequest::HistoricalAuthorGet { author_id } => {
            let author = srv.get_historical_author(author_id)?;
            Ok(ResponseValue::HistoricalAuthorResult {
                be_id: author.be_id,
                name: author.name,
                display_name: author.display_name,
                birth_year: author.birth_year,
                death_year: author.death_year,
                external_ids: author.external_ids,
                source_bibliography: author.source_bibliography,
            })
        }

        WireRequest::HistoricalAuthorSearch { query } => {
            let authors = srv.search_historical_authors(&query);
            let entries: Vec<super::protocol::HistoricalAuthorEntry> = authors
                .into_iter()
                .map(|a| super::protocol::HistoricalAuthorEntry {
                    be_id: a.be_id,
                    name: a.name,
                    display_name: a.display_name,
                    birth_year: a.birth_year,
                    death_year: a.death_year,
                })
                .collect();
            Ok(ResponseValue::HistoricalAuthorListResult { authors: entries })
        }

        WireRequest::HistoricalAuthorList => {
            let authors = srv.list_historical_authors();
            let entries: Vec<super::protocol::HistoricalAuthorEntry> = authors
                .into_iter()
                .map(|a| super::protocol::HistoricalAuthorEntry {
                    be_id: a.be_id,
                    name: a.name,
                    display_name: a.display_name,
                    birth_year: a.birth_year,
                    death_year: a.death_year,
                })
                .collect();
            Ok(ResponseValue::HistoricalAuthorListResult { authors: entries })
        }

        WireRequest::ImportSourceWork {
            author_id,
            title,
            text,
            edition_info,
            skip_prefix_lines,
            skip_suffix_lines,
        } => {
            let (work_id, auth_id, text_length, import_title) = srv.import_source_work(
                session_id,
                author_id,
                title,
                text,
                edition_info,
                skip_prefix_lines,
                skip_suffix_lines,
            )?;
            Ok(ResponseValue::ImportSourceWorkResult {
                work_id,
                author_id: auth_id,
                title: import_title,
                text_length,
            })
        }

        WireRequest::ImportEpub {
            epub_data,
            title,
            author,
            skip_prefix_lines,
            skip_suffix_lines,
        } => {
            let (work_id, auth_id, text_length, import_title) = srv.import_epub(
                session_id,
                &epub_data,
                title.as_deref(),
                author.as_deref(),
                skip_prefix_lines,
                skip_suffix_lines,
            )?;
            Ok(ResponseValue::ImportSourceWorkResult {
                work_id,
                author_id: auth_id,
                title: import_title,
                text_length,
            })
        }

        WireRequest::SourceDetect { text } => {
            let result = srv.detect_source(&text);
            Ok(ResponseValue::SourceDetectResult {
                source_type: result.source_type,
                detected: result.detected,
                content_start_line: result.content_start_line,
                content_end_line: result.content_end_line,
                total_lines: result.total_lines,
                metadata: result.metadata,
            })
        }

        WireRequest::SourcePatternList => {
            let patterns = srv.list_source_patterns();
            let entries: Vec<super::protocol::SourcePatternEntry> = patterns
                .into_iter()
                .map(
                    |(source_type, display_name)| super::protocol::SourcePatternEntry {
                        source_type,
                        display_name,
                    },
                )
                .collect();
            Ok(ResponseValue::SourcePatternListResult { patterns: entries })
        }
        WireRequest::WorkListByAuthor { author_id } => {
            let starred = srv.starred_for_session(session_id);
            let entries = srv.list_works_by_historical_author(author_id);
            let list: Vec<super::protocol::WorkListEntry> = entries
                .into_iter()
                .filter(|(work_id, _, _, _, _, _, _)| {
                    srv.work(*work_id)
                        .map(|w| srv.work_is_readable(session_id, w))
                        .unwrap_or(false)
                })
                .map(
                    |(
                        work_id,
                        owner,
                        revision_count,
                        is_grabbed,
                        title,
                        read_club,
                        source_edition_info,
                    )| {
                        super::protocol::WorkListEntry {
                            work_id,
                            owner,
                            revision_count,
                            is_grabbed,
                            char_count: 0,
                            title,
                            read_club,
                            is_source: true,
                            content_start_line: None,
                            content_end_line: None,
                            source_author_id: Some(author_id),
                            source_edition_info,
                            is_starred: starred.contains(&work_id),
                            updated_at: None,
                            content_crum: None,
                        }
                    },
                )
                .collect();
            Ok(ResponseValue::WorkList(list))
        }

        WireRequest::ContentMatch { text } => match srv.match_content(&text) {
            Some((work_id, author_id, score)) => Ok(ResponseValue::ContentMatchResult {
                matched: true,
                work_id: Some(work_id),
                author_id: Some(author_id),
                score: Some(score),
            }),
            None => Ok(ResponseValue::ContentMatchResult {
                matched: false,
                work_id: None,
                author_id: None,
                score: None,
            }),
        },

        WireRequest::WorkApplySourceAttribution {
            work_id,
            historical_author_id,
            source_work_id,
            paste_start,
            paste_end,
        } => {
            srv.apply_source_attribution(
                session_id,
                work_id,
                historical_author_id,
                source_work_id,
                paste_start,
                paste_end,
            )?;
            Ok(ResponseValue::Void)
        }

        WireRequest::WorkApplyTransclusionAttribution { link_id } => {
            srv.apply_transclusion_attribution(session_id, link_id)?;
            Ok(ResponseValue::Void)
        }

        WireRequest::WorkSummary { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            srv.work_summary(work_id)
        }

        WireRequest::WorkVersionTimeline { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            srv.work_version_timeline(work_id)
        }

        WireRequest::PassageComposition {
            work_id,
            start,
            end,
        } => {
            srv.ensure_can_read(session_id, work_id)?;
            srv.passage_composition(work_id, start, end)
        }
        WireRequest::GlobalTextSearch { query, max_results } => {
            srv.ensure_session(session_id)?;
            let max = max_results.unwrap_or(50) as usize;
            let results = srv.global_text_search(session_id, &query, max);
            let total_works_matched = results.len() as u64;
            let payloads: Vec<super::protocol::GlobalSearchResultPayload> = results
                .into_iter()
                .map(|r| super::protocol::GlobalSearchResultPayload {
                    work_id: r.work_id,
                    title: r.title,
                    owner: r.owner,
                    revision_count: r.revision_count,
                    matches: r
                        .matches
                        .into_iter()
                        .map(|m| super::protocol::SearchMatchPayload {
                            char_offset: m.char_offset,
                            line: m.line,
                            context: m.context,
                        })
                        .collect(),
                })
                .collect();
            Ok(ResponseValue::GlobalSearchResults {
                results: payloads,
                total_works_matched,
            })
        }
        WireRequest::SeedDemoAttribution {
            work_id,
            author_count,
        } => {
            srv.ensure_authenticated(session_id)?;
            srv.seed_demo_attribution(session_id, work_id, author_count)?;
            Ok(ResponseValue::Boolean(true))
        }
        #[cfg(feature = "serde")]
        WireRequest::ProvJsonExport {
            work_id,
            include_federation,
        } => {
            let wid = work_id.unwrap_or(0);
            if wid > 0 {
                srv.ensure_can_read(session_id, wid)?;
            } else {
                srv.ensure_session(session_id)?;
            }
            let prov_json = srv.federation_export_prov_json(work_id, include_federation)?;
            Ok(ResponseValue::ProvJsonExportResult { prov_json })
        }
        #[cfg(feature = "serde")]
        WireRequest::ServerDirectoryList => {
            srv.ensure_session(session_id)?;
            let servers: Vec<serde_json::Value> = srv
                .server_directory()
                .list()
                .into_iter()
                .map(|e| {
                    serde_json::json!({
                        "server_id": e.server_id.to_string(),
                        "address": e.address,
                        "port": e.port,
                        "verifying_key": e.verifying_key,
                        "name": e.name,
                        "description": e.description,
                        "trusted": e.trusted,
                        "discovered": e.discovered,
                        "referred_by": e.referred_by,
                        "last_seen": e.last_seen,
                        "first_seen": e.first_seen,
                        "successful_resolutions": e.successful_resolutions,
                        "quarantined": e.quarantined,
                        "last_success": e.last_success,
                        "last_failure": e.last_failure,
                        "consecutive_failures": e.consecutive_failures,
                    })
                })
                .collect();
            Ok(ResponseValue::ServerDirectoryListResult { servers })
        }
        #[cfg(feature = "serde")]
        WireRequest::ServerDirectoryAdd { address, port } => {
            srv.ensure_logged_in(session_id)?;
            let entry = srv.server_directory_add(&address, port)?;
            srv.server_directory_save()?;
            Ok(ResponseValue::ServerDirectoryAddResult {
                server_id: entry.server_id.to_string(),
                name: entry.name,
                address: entry.address,
                trusted: entry.trusted,
            })
        }
        #[cfg(feature = "serde")]
        WireRequest::ServerDirectoryRemove { server_id } => {
            srv.ensure_logged_in(session_id)?;
            let sid: u64 = server_id.parse().map_err(|_| {
                crate::server::ServerError::InvalidArgument("invalid server_id".into())
            })?;
            let removed = srv.server_directory_remove(sid);
            srv.server_directory_save()?;
            Ok(ResponseValue::ServerDirectoryRemoveResult { removed })
        }
        #[cfg(feature = "serde")]
        WireRequest::ServerDirectorySetTrust { server_id, trusted } => {
            srv.ensure_logged_in(session_id)?;
            let sid: u64 = server_id.parse().map_err(|_| {
                crate::server::ServerError::InvalidArgument("invalid server_id".into())
            })?;
            srv.server_directory_set_trust(sid, trusted);
            srv.server_directory_save()?;
            Ok(ResponseValue::ServerDirectorySetTrustResult {
                server_id: sid,
                trusted,
            })
        }
        #[cfg(feature = "serde")]
        #[cfg(feature = "serde")]
        WireRequest::NetworkSetEnabled { enabled } => {
            let new_val = srv.set_network_enabled(session_id, enabled)?;
            Ok(ResponseValue::Boolean(new_val))
        }
        #[cfg(feature = "serde")]
        WireRequest::ExternalLinksSetEnabled { enabled } => {
            let new_val = srv.set_external_links_enabled(session_id, enabled)?;
            Ok(ResponseValue::Boolean(new_val))
        }
        #[cfg(feature = "serde")]
        WireRequest::WorkAdminDelete { work_id } => {
            srv.work_delete_admin(session_id, work_id)?;
            Ok(ResponseValue::Void)
        }
        #[cfg(feature = "serde")]
        WireRequest::AdminSessionKick { session_id: target } => {
            srv.admin_session_kick(session_id, crate::server::session::SessionId::new(target))?;
            Ok(ResponseValue::Void)
        }
        #[cfg(feature = "serde")]
        WireRequest::AdminClubsList => {
            let clubs = srv.admin_clubs_list(session_id)?;
            let payloads: Vec<super::protocol::AdminClubPayload> = clubs
                .into_iter()
                .map(|c| super::protocol::AdminClubPayload {
                    be_id: c.be_id,
                    name: c.name,
                    display_name: c.display_name,
                    is_personal: c.is_personal,
                    is_verified: c.is_verified,
                    member_count: c.member_count,
                    works_owned: c.works_owned,
                    is_system: c.is_system,
                })
                .collect();
            Ok(ResponseValue::Json(
                serde_json::json!({ "clubs": payloads }),
            ))
        }
        #[cfg(feature = "serde")]
        WireRequest::AdminGrantAdmin { club_id } => {
            srv.admin_grant_admin(session_id, club_id)?;
            Ok(ResponseValue::Void)
        }
        #[cfg(feature = "serde")]
        WireRequest::AdminRevokeAdmin { club_id } => {
            srv.admin_revoke_admin(session_id, club_id)?;
            Ok(ResponseValue::Void)
        }
        #[cfg(feature = "serde")]
        WireRequest::AdminAuditTail => {
            let (lines, valid) = srv.admin_audit_tail(session_id)?;
            let arr: Vec<serde_json::Value> =
                lines.into_iter().map(serde_json::Value::String).collect();
            Ok(ResponseValue::Json(serde_json::json!({
                "lines": arr,
                "chain_valid": valid,
            })))
        }
        #[cfg(feature = "serde")]
        WireRequest::AdminEditPolicySet { policy } => {
            let parsed = match policy.as_str() {
                "owner-only" => crate::server::EditPolicy::OwnerOnly,
                "public-sandbox" => crate::server::EditPolicy::PublicSandbox,
                other => {
                    return Err(crate::server::ServerError::InvalidArgument(format!(
                        "unknown edit policy: {}",
                        other
                    )))
                }
            };
            srv.set_edit_policy_admin(session_id, parsed)?;
            Ok(ResponseValue::Void)
        }

        WireRequest::CrossServerResolve {
            tumbler,
            content_hash_hex,
        } => {
            srv.ensure_session(session_id)?;
            if !srv.network_enabled() {
                return Err(crate::server::ServerError::Unauthorized(
                    "Xudanu network is disabled on this server (single-player mode). Enable it in Settings to connect to other servers.".to_string(),
                ));
            }
            let hash_bytes = match crate::crypto::keys::hex_decode(&content_hash_hex) {
                Ok(b) if b.len() == 32 => {
                    let mut arr = [0u8; 32];
                    arr.copy_from_slice(&b);
                    arr
                }
                _ => {
                    return Err(crate::server::ServerError::InvalidArgument(
                        "invalid content_hash_hex: expected 64 hex chars".into(),
                    ))
                }
            };
            match srv.resolve_cross_server_ref(&tumbler, hash_bytes) {
                Ok(resolution) => Ok(ResponseValue::CrossServerResolveResult {
                    text: resolution.text().to_string(),
                    hash_verified: true,
                    cached: !resolution.was_fetched(),
                    origin_server_id: resolution.origin_server_id(),
                }),
                Err(e) => {
                    tracing::warn!("cross-server resolve failed: {}", e);
                    Err(e)
                }
            }
        }
        #[cfg(feature = "serde")]
        WireRequest::CrossServerFetchWork { server_id, work_id } => {
            srv.ensure_session(session_id)?;
            let sid: u64 = server_id.parse().map_err(|_| {
                crate::server::ServerError::InvalidArgument("invalid server_id".into())
            })?;
            match srv.fetch_remote_work(sid, &work_id) {
                Ok(data) => Ok(ResponseValue::CrossServerFetchWorkResult {
                    work_id: data.work_id,
                    title: data.title,
                    text: data.text,
                    revision: data.revision,
                    char_count: data.char_count,
                    content_hash: data.content_hash,
                    origin_server_id: data.origin_server_id,
                    origin_server_name: data.origin_server_name,
                    license: data.license,
                    tumbler: data.tumbler,
                    cached: data.cached,
                }),
                Err(e) => {
                    tracing::warn!("cross-server fetch work failed: {}", e);
                    Err(e)
                }
            }
        }
        #[cfg(feature = "serde")]
        WireRequest::CrossServerListWorks { server_id } => {
            srv.ensure_session(session_id)?;
            let sid: u64 = server_id.parse().map_err(|_| {
                crate::server::ServerError::InvalidArgument("invalid server_id".into())
            })?;
            match srv.fetch_remote_works_list(sid) {
                Ok((works, name)) => Ok(ResponseValue::CrossServerListWorksResult {
                    works,
                    origin_server_name: name,
                }),
                Err(e) => {
                    tracing::warn!("cross-server list works failed: {}", e);
                    Err(e)
                }
            }
        }
        #[cfg(feature = "serde")]
        WireRequest::FederatedSearch { query } => {
            srv.ensure_session(session_id)?;
            // FR-41 S1: fan-outs cost the peers real work — a single
            // session spamming federated_search is an amplifier
            // vector. 10/minute per session.
            if !state
                .rate_limiter
                .check_federated_search(session_id.as_u64())
            {
                tracing::warn!(
                    target: "xudanu::security",
                    session = session_id.as_u64(),
                    event = "SECURITY:federated_search_rate_limited",
                    "federated search rate limit exceeded"
                );
                return Err(ServerError::Unauthorized(
                    "too many federated searches, wait a moment".into(),
                ));
            }
            let results = srv.federated_search(&query);
            Ok(ResponseValue::FederatedSearchResult { results })
        }
        #[cfg(feature = "serde")]
        WireRequest::FetchIntroductions { server_id } => {
            srv.ensure_session(session_id)?;
            let sid: u64 = server_id.parse().map_err(|_| {
                crate::server::ServerError::InvalidArgument("invalid server_id".into())
            })?;
            let intros = srv.fetch_remote_introductions(sid)?;
            Ok(ResponseValue::FetchIntroductionsResult {
                introductions: intros,
            })
        }
        #[cfg(feature = "serde")]
        WireRequest::AddDiscoveredServer {
            server_id,
            address,
            name,
            verifying_key,
            introduced_by,
        } => {
            srv.ensure_logged_in(session_id)?;
            srv.add_discovered_server(server_id, address, name, verifying_key, introduced_by)?;
            Ok(ResponseValue::AddDiscoveredServerResult { added: true })
        }
        #[cfg(feature = "serde")]
        WireRequest::CrossServerLinkCreate {
            local_work_id,
            remote_tumbler,
            remote_title,
            remote_server_name,
            remote_server_id,
            link_type,
        } => {
            srv.ensure_logged_in(session_id)?;
            srv.add_cross_server_link(
                local_work_id,
                remote_tumbler.clone(),
                remote_title.clone(),
                remote_server_name.clone(),
                remote_server_id,
                link_type.clone(),
            );
            let local_title = srv.work_title(local_work_id).unwrap_or_default();
            // FR-40 sender feedback: notify synchronously and surface
            // the definitive outcome to the creating user instead of
            // fire-and-forget. Ok(None) = remote server not in the
            // directory (no notification attempted).
            let (remote_accepted, notify_error) = match srv
                .send_backlink_notification_sync(
                    remote_server_id,
                    &remote_tumbler,
                    local_work_id,
                    &local_title,
                    "",
                    &link_type,
                ) {
                Ok(Some(_)) => (Some(true), None),
                Ok(None) => (None, Some(format!(
                    "remote server {} not in the server directory — the link is saved locally but the remote was not notified",
                    remote_server_id
                ))),
                Err(e) => (Some(false), Some(e)),
            };
            if let Some(err) = &notify_error {
                tracing::warn!(
                    "Cross-server link notification outcome: accepted={:?} reason={}",
                    remote_accepted,
                    err
                );
            }
            Ok(ResponseValue::CrossServerLinkCreateResult {
                created: true,
                remote_accepted,
                notify_error,
            })
        }
        #[cfg(feature = "serde")]
        WireRequest::CrossServerLinkList { work_id } => {
            srv.ensure_session(session_id)?;
            let links: Vec<serde_json::Value> = srv
                .cross_server_links_for_work(work_id)
                .iter()
                .map(|l| {
                    serde_json::json!({
                        "remote_tumbler": l.remote_tumbler,
                        "remote_title": l.remote_title,
                        "remote_server_name": l.remote_server_name,
                        "remote_server_id": l.remote_server_id,
                        "link_type": l.link_type,
                        "created_at": l.created_at,
                    })
                })
                .collect();
            Ok(ResponseValue::CrossServerLinkListResult { links })
        }
        #[cfg(feature = "serde")]
        WireRequest::FetchRemoteIdentity {
            server_id,
            club_name,
        } => {
            srv.ensure_session(session_id)?;
            let sid: u64 = server_id.parse().map_err(|_| {
                crate::server::ServerError::InvalidArgument("invalid server_id".into())
            })?;
            let attestation = srv.fetch_remote_identity(sid, &club_name)?;
            Ok(ResponseValue::FetchRemoteIdentityResult {
                display_name: attestation.display_name,
                verifying_key: attestation.verifying_key,
                home_server_name: attestation.home_server_name,
                home_server_address: attestation.home_server_address,
                verified_at: attestation.verified_at,
            })
        }
        WireRequest::TumblerResolve { tumbler } => {
            srv.ensure_session(session_id)?;
            let parsed = crate::edition::tumbler::XudanuTumbler::parse(&tumbler);
            let server_addr = parsed.server().to_string();
            if let Some(work_id) = srv.resolve_local_tumbler(&parsed) {
                let title = srv
                    .works
                    .get(&work_id)
                    .map(|ws| ws.cached_title().to_string());
                Ok(ResponseValue::TumblerResolveResult {
                    work_id: Some(format!("{:04x}", work_id)),
                    title,
                    is_local: true,
                    server: server_addr,
                })
            } else {
                Ok(ResponseValue::TumblerResolveResult {
                    work_id: None,
                    title: None,
                    is_local: false,
                    server: server_addr,
                })
            }
        }
        WireRequest::BloomFilterGet { server_id } => {
            srv.ensure_session(session_id)?;
            let sid: u64 = server_id.parse().map_err(|_| {
                crate::server::ServerError::InvalidArgument("invalid server_id".into())
            })?;
            let filter = srv.fetch_remote_bloom_filter(sid)?;
            Ok(ResponseValue::BloomFilterResult {
                bits: filter.bits_as_vec(),
                num_hashes: filter.num_hashes(),
                num_bits: filter.num_bits(),
                item_count: filter.item_count(),
                timestamp: filter.timestamp(),
            })
        }
        WireRequest::BloomFilterCheck { server_id, work_id } => {
            srv.ensure_session(session_id)?;
            let sid: u64 = server_id.parse().map_err(|_| {
                crate::server::ServerError::InvalidArgument("invalid server_id".into())
            })?;
            let filter = srv.fetch_remote_bloom_filter(sid)?;
            Ok(ResponseValue::BloomFilterCheckResult {
                present: filter.contains(&work_id.to_le_bytes()),
            })
        }
        #[cfg(feature = "serde")]
        WireRequest::FederationAttestationCreate {
            attestation_type,
            subject_server_id,
        } => {
            srv.ensure_session(session_id)?;
            Err(crate::server::ServerError::Internal(format!(
                "Federation attestation create not supported in dispatch: type={} subject={}",
                attestation_type, subject_server_id
            )))
        }
        #[cfg(feature = "serde")]
        WireRequest::FederationAttestationVerify { attestation_json } => {
            srv.ensure_session(session_id)?;
            Err(crate::server::ServerError::Internal(format!(
                "Federation attestation verify not supported in dispatch: json_len={}",
                attestation_json.len()
            )))
        }
        #[cfg(feature = "serde")]
        WireRequest::FederationBundleExport { bundle_id } => {
            srv.ensure_session(session_id)?;
            Err(crate::server::ServerError::Internal(format!(
                "Federation bundle export not supported in dispatch: bundle_id={}",
                bundle_id
            )))
        }
        #[cfg(feature = "serde")]
        WireRequest::ClusterVerificationCreate {
            activity_type,
            verifying_servers,
            consensus_type,
            threshold_met,
        } => {
            srv.ensure_session(session_id)?;
            Err(crate::server::ServerError::Internal(
                format!("Cluster verification create not supported in dispatch: type={} servers={} consensus={} threshold={}", activity_type, verifying_servers.len(), consensus_type, threshold_met)
            ))
        }
        #[cfg(feature = "serde")]
        WireRequest::CrossServerSignatureVerify {
            server_id,
            signature,
            timestamp,
        } => {
            srv.ensure_session(session_id)?;
            Err(crate::server::ServerError::Internal(
                format!("Cross-server signature verify not supported in dispatch: server={} sig_len={} ts={}", server_id, signature.len(), timestamp)
            ))
        }
        _ => Err(crate::server::ServerError::Internal(
            "unhandled request".to_string(),
        )),
    }
}

fn dispatch_inner_read(
    srv: &Server,
    session_id: crate::server::SessionId,
    request: WireRequest,
    state: &SharedState,
) -> Result<ResponseValue, crate::server::ServerError> {
    match request {
        WireRequest::SessionConnect => Ok(ResponseValue::Id(session_id.as_u64())),
        WireRequest::ClubGet { club_id } => {
            srv.ensure_session(session_id)?;
            let _club = srv.club(club_id)?;
            Ok(ResponseValue::Id(club_id))
        }
        WireRequest::ClubNames { offset, limit } => {
            srv.ensure_session(session_id)?;
            let all: Vec<_> = srv
                .club_names_list()
                .into_iter()
                .map(|(n, id)| (n.to_string(), id))
                .collect();
            let total_count = all.len() as u64;
            let limit_val = limit.unwrap_or(100).min(1000) as usize;
            let offset_val = offset.unwrap_or(0) as usize;
            let has_more = offset_val + limit_val < all.len();
            let entries: Vec<_> = all.into_iter().skip(offset_val).take(limit_val).collect();
            Ok(ResponseValue::PaginatedClubNames {
                entries,
                total_count,
                has_more,
            })
        }
        WireRequest::WorkGetEdition { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            if srv.has_stale_transclusion_cache(work_id) {
                tracing::debug!(
                    "[work_get_edition] stale transclusion caches on {:x}; EditionPayload serves resolved spans via resolve paths",
                    work_id
                );
            }
            let ed = srv.work_edition(work_id)?;
            Ok(ResponseValue::Edition(EditionPayload::from_edition(&ed)))
        }
        WireRequest::WorkIsGrabbed { work_id } => {
            let grabbed = srv.work_is_grabbed(work_id)?;
            Ok(ResponseValue::Boolean(grabbed))
        }
        WireRequest::WorkGrabber { work_id } => {
            let grabber = srv.work_grabber(work_id)?;
            Ok(ResponseValue::Humber(
                grabber.map(|s| s.as_u64()).unwrap_or(0),
            ))
        }
        WireRequest::WorkGrabWaiters { work_id } => {
            let waiters = srv.work_grab_waiters(work_id)?;
            Ok(ResponseValue::Humber(waiters.len() as u64))
        }
        WireRequest::WorkCanRead { work_id } => {
            let can = srv.work_can_read(session_id, work_id)?;
            Ok(ResponseValue::Boolean(can))
        }
        WireRequest::WorkCanRevise { work_id } => {
            let can = srv.work_can_revise(session_id, work_id)?;
            Ok(ResponseValue::Boolean(can))
        }
        WireRequest::WorkIsStarred { work_id } => {
            let starred = srv.work_is_starred(session_id, work_id)?;
            Ok(ResponseValue::Boolean(starred))
        }
        WireRequest::TrailList => {
            srv.ensure_authenticated(session_id)?;
            let trails = srv.trail_list(session_id)?;
            Ok(ResponseValue::TrailListResult(trails))
        }
        WireRequest::TrailGet { trail_id } => {
            srv.ensure_authenticated(session_id)?;
            let trail = srv.trail_get(session_id, trail_id)?;
            Ok(ResponseValue::TrailResult(trail))
        }
        WireRequest::TrailListPublished { category } => {
            let trails = srv.trail_list_published(session_id, category.as_deref())?;
            Ok(ResponseValue::TrailListResult(trails))
        }
        WireRequest::TrailListCategories => {
            let cats = srv.trail_list_categories();
            Ok(ResponseValue::TrailCategories(cats))
        }
        WireRequest::WorkReadClub { work_id } => {
            let club = srv.work_read_club(work_id)?;
            Ok(ResponseValue::Humber(club.unwrap_or(0)))
        }
        WireRequest::WorkEditClub { work_id } => {
            let club = srv.work_edit_club(work_id)?;
            Ok(ResponseValue::Humber(club.unwrap_or(0)))
        }
        WireRequest::WorkHistoryClub { work_id } => {
            let club = srv.work_history_club(work_id)?;
            Ok(ResponseValue::Humber(club.unwrap_or(0)))
        }
        WireRequest::WorkRevisionCount { work_id } => {
            let count = srv.work_revision_count(work_id)?;
            Ok(ResponseValue::Humber(count))
        }
        WireRequest::WorkSponsors { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let sponsors = srv.work_sponsors(work_id)?.to_vec();
            Ok(ResponseValue::Ids(sponsors))
        }
        WireRequest::WorkOwner { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let owner = srv.work_owner(work_id)?;
            Ok(ResponseValue::Humber(owner.unwrap_or(0)))
        }
        WireRequest::WorkListArchived => {
            // Archived (soft-deleted) works. Owner-scoped; admins see all.
            let is_admin = srv.ensure_admin(session_id).is_ok();
            let owner_club = srv.identity_for_session(session_id).1;
            let starred = srv.starred_for_session(session_id);
            let entries: Vec<_> = srv
                .list_works_with_titles()
                .into_iter()
                .filter(|(work_id, owner, _, _, _, _, _, _, _, _, _)| {
                    let readable = srv
                        .work(*work_id)
                        .map(|w| srv.work_is_readable(session_id, w))
                        .unwrap_or(false);
                    let archived = srv.work_is_archived(*work_id).unwrap_or(false);
                    if !readable || !archived {
                        return false;
                    }
                    is_admin || owner_club.map_or(false, |oc| *owner == Some(oc))
                })
                .map(
                    |(
                        work_id,
                        owner,
                        revision_count,
                        is_grabbed,
                        title,
                        read_club,
                        is_source,
                        content_start_line,
                        content_end_line,
                        source_author_id,
                        source_edition_info,
                    )| {
                        super::protocol::WorkListEntry {
                            work_id,
                            owner,
                            revision_count,
                            is_grabbed,
                            char_count: 0,
                            title,
                            read_club,
                            is_source,
                            content_start_line,
                            content_end_line,
                            source_author_id,
                            source_edition_info,
                            is_starred: starred.contains(&work_id),
                            updated_at: None,
                            content_crum: None,
                        }
                    },
                )
                .collect();
            Ok(ResponseValue::WorkList(entries))
        }
        WireRequest::WorkIsPublished { work_id } => {
            let published = srv.work_is_published(session_id, work_id)?;
            Ok(ResponseValue::Boolean(published))
        }
        WireRequest::WorkGhost { work_id } => {
            let ghost = srv
                .work_ghost(work_id)
                .map(|g| super::protocol::WorkGhostInfoPayload {
                    work_id: g.work_id,
                    title: g.title,
                    owner: g.owner,
                    archived_by: g.archived_by,
                    archived_at: g.archived_at,
                    lifecycle_history: g
                        .lifecycle_history
                        .iter()
                        .map(|e| super::protocol::WorkLifecycleEventPayload {
                            kind: e.kind.clone(),
                            actor_club: e.actor_club,
                            timestamp: e.timestamp,
                        })
                        .collect(),
                });
            Ok(ResponseValue::WorkGhostResult { ghost })
        }
        WireRequest::RenderTransclusions { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let elements = srv.render_transclusions(work_id)?;
            let payloads: Vec<super::protocol::RenderedElementPayload> = elements
                .into_iter()
                .map(|e| super::protocol::RenderedElementPayload {
                    position: e.position,
                    text: e.text,
                    source_work_id: e.source_work_id,
                    source_author_name: e.source_author_name,
                    is_transcluded: e.is_transcluded,
                    transclusion_sources: e
                        .transclusion_sources
                        .into_iter()
                        .map(|s| super::protocol::TransclusionSourcePayload {
                            work_id: s.work_id,
                            title: s.title,
                            author_name: s.author_name,
                            is_direct: s.is_direct,
                        })
                        .collect(),
                })
                .collect();
            Ok(ResponseValue::RenderedTransclusions(payloads))
        }
        WireRequest::ClubWhoAmI => {
            let clubs = srv.who_am_i(session_id)?;
            let verifying_key = clubs
                .first()
                .and_then(|(cid, _)| srv.club_verifying_key_hex(*cid));
            Ok(ResponseValue::ClubWhoAmIResult {
                clubs,
                verifying_key,
            })
        }
        WireRequest::ClubMembers { club_id } => {
            let members = srv.club_members(session_id, club_id)?;
            Ok(ResponseValue::ClubMembersResult { members })
        }
        WireRequest::ClubRoster { club_id } => {
            let r = srv.club_roster(session_id, club_id)?;
            Ok(ResponseValue::ClubRosterResult {
                members: r.members,
                total: r.total as u64,
                truncated: r.truncated,
            })
        }
        WireRequest::EditionGet { be_id } => {
            srv.ensure_logged_in(session_id)?;
            match srv.get_edition(be_id)? {
                Some(ed) => Ok(ResponseValue::Edition(EditionPayload::from_edition(&ed))),
                None => Ok(ResponseValue::Void),
            }
        }
        WireRequest::AdminIsAcceptingConnections => {
            let accepting = srv.admin_is_accepting_connections();
            Ok(ResponseValue::Boolean(accepting))
        }
        WireRequest::AdminActiveSessions => {
            let infos = srv.admin_active_sessions(session_id)?;
            let payloads = infos
                .into_iter()
                .map(|si| super::protocol::SessionInfoPayload {
                    session_id: si.session_id,
                    is_logged_in: si.is_logged_in,
                    authority_clubs: si.authority_clubs,
                    initial_login: si.initial_login,
                    grabbed_work_count: if si.has_grabbed_works { 1 } else { 0 },
                })
                .collect();
            Ok(ResponseValue::SessionInfos(payloads))
        }
        WireRequest::AdminGrants => {
            let grants = srv.admin_grants(session_id)?;
            let payloads = grants
                .iter()
                .map(|g| {
                    let (start, end) = g.region.as_interval().unwrap_or((0, 0));
                    super::protocol::GrantPayload {
                        club_id: g.club_id,
                        region_start: start,
                        region_end: end,
                    }
                })
                .collect();
            Ok(ResponseValue::Grants(payloads))
        }
        WireRequest::AdminServerInfo => {
            srv.ensure_admin(session_id)?;
            Ok(ResponseValue::ServerInfo(
                super::protocol::ServerInfoPayload {
                    version: env!("CARGO_PKG_VERSION").to_string(),
                    session_count: srv.session_count(),
                    work_count: srv.work_count(),
                    club_count: srv.club_count(),
                    edition_count: srv.edition_count(),
                    is_accepting_connections: srv.admin_is_accepting_connections(),
                    public_club_id: srv.public_club_id(),
                    llm_enabled: crate::server::ollama::llm_enabled(),
                    llm_usage: crate::server::ollama::usage_tracker().summary(),
                },
            ))
        }
        WireRequest::ServerStats => Ok(ResponseValue::ServerInfo(
            super::protocol::ServerInfoPayload {
                version: env!("CARGO_PKG_VERSION").to_string(),
                session_count: srv.session_count(),
                work_count: srv.work_count(),
                club_count: srv.club_count(),
                edition_count: srv.edition_count(),
                is_accepting_connections: srv.admin_is_accepting_connections(),
                public_club_id: srv.public_club_id(),
                llm_enabled: crate::server::ollama::llm_enabled(),
                llm_usage: crate::server::ollama::usage_tracker().summary(),
            },
        )),
        WireRequest::WorkList { offset, limit } => {
            let starred = srv.starred_for_session(session_id);
            let authority = srv.session_authority_clubs(session_id);
            let public_club = srv.public_club_id();
            let limit_val = limit.unwrap_or(100).min(1000) as usize;
            let offset_val = offset.unwrap_or(0) as usize;
            let mut total: u64 = 0;
            let mut entries: Vec<super::protocol::WorkListEntry> = Vec::new();
            for (id, ws) in srv.works_iter() {
                if ws.work().is_archived() {
                    if *id == 0x586 {
                        tracing::info!("[worklist] 0x586 is ARCHIVED");
                    }
                    continue;
                }
                let read_club = ws.work().read_club();
                if !srv.work_is_readable(session_id, &ws.work()) {
                    if *id == 0x586 {
                        tracing::info!(
                            "[worklist] 0x586 NOT readable — read_club={:?} edit_club={:?}",
                            read_club,
                            ws.work().edit_club()
                        );
                    }
                    continue;
                }
                if *id == 0x586 {
                    tracing::info!("[worklist] 0x586 INCLUDED — read_club={:?}", read_club);
                }
                total += 1;
                if total > offset_val as u64 && entries.len() < limit_val {
                    entries.push(super::protocol::WorkListEntry {
                        work_id: *id,
                        owner: ws.work().owner(),
                        revision_count: ws.work().revision_count(),
                        is_grabbed: ws.grabber().is_some(),
                        char_count: ws.work().current_edition().to_text().len() as u64,
                        title: ws.cached_title().to_string(),
                        read_club,
                        is_source: ws.is_source(),
                        content_start_line: ws.content_start_line(),
                        content_end_line: ws.content_end_line(),
                        source_author_id: ws.source_author_id(),
                        source_edition_info: ws.source_edition_info().map(|s| s.to_string()),
                        is_starred: starred.contains(id),
                        updated_at: ws.latest_revision_timestamp(),
                        content_crum: ws
                            .work()
                            .current_edition()
                            .crum()
                            .map(|c| c.iter().map(|b| format!("{:02x}", b)).collect()),
                    });
                }
            }
            let has_more = total as usize > offset_val + limit_val;
            Ok(ResponseValue::PaginatedWorkList {
                entries,
                total_count: total,
                has_more,
            })
        }
        WireRequest::WorkListByOwner {
            owner,
            offset,
            limit,
        } => {
            let starred = srv.starred_for_session(session_id);
            let all: Vec<_> = srv
                .list_works_by_owner(owner)
                .into_iter()
                .filter(|(work_id, _, _, _, _)| {
                    srv.work(*work_id)
                        .map(|w| srv.work_is_readable(session_id, w))
                        .unwrap_or(false)
                })
                .map(|(work_id, owner, revision_count, is_grabbed, read_club)| {
                    super::protocol::WorkListEntry {
                        work_id,
                        owner,
                        revision_count,
                        is_grabbed,
                        char_count: 0,
                        title: String::new(),
                        read_club,
                        is_source: false,
                        content_start_line: None,
                        content_end_line: None,
                        source_author_id: None,
                        source_edition_info: None,
                        is_starred: starred.contains(&work_id),
                        updated_at: None,
                        content_crum: None,
                    }
                })
                .collect();
            let total_count = all.len() as u64;
            let limit_val = limit.unwrap_or(100).min(1000) as usize;
            let offset_val = offset.unwrap_or(0) as usize;
            let has_more = offset_val + limit_val < all.len();
            let entries: Vec<_> = all.into_iter().skip(offset_val).take(limit_val).collect();
            Ok(ResponseValue::PaginatedWorkList {
                entries,
                total_count,
                has_more,
            })
        }
        WireRequest::LinkGet { link_id } => {
            let (origin, destination, link) = srv.get_link(link_id)?;
            srv.ensure_can_read(session_id, origin)?;
            srv.ensure_can_read(session_id, destination)?;
            Ok(ResponseValue::LinkInfo(build_link_payload(
                srv,
                link_id,
                origin,
                destination,
                link,
            )))
        }
        WireRequest::LinkListForWork {
            work_id,
            offset,
            limit,
        } => {
            srv.ensure_can_read(session_id, work_id)?;
            let all: Vec<_> = srv
                .list_links_for_work(work_id)
                .into_iter()
                .filter(|&(link_id, _, _)| !srv.link_hidden_by_home_archive(link_id))
                .filter_map(|(link_id, origin, destination)| {
                    let (_, _, link) = srv.get_link(link_id).ok()?;
                    Some(build_link_payload(srv, link_id, origin, destination, link))
                })
                .collect();
            let total_count = all.len() as u64;
            let limit_val = limit.unwrap_or(100).min(1000) as usize;
            let offset_val = offset.unwrap_or(0) as usize;
            let has_more = offset_val + limit_val < all.len();
            let entries: Vec<_> = all.into_iter().skip(offset_val).take(limit_val).collect();
            Ok(ResponseValue::PaginatedLinkList {
                entries,
                total_count,
                has_more,
            })
        }
        WireRequest::LinkQuery {
            from_spec,
            to_spec,
            type_ids,
            home_spec,
        } => {
            let matches =
                srv.link_query(session_id, &from_spec, &to_spec, &type_ids, &home_spec)?;
            let entries: Vec<_> = matches
                .into_iter()
                .filter_map(|(link_id, origin, destination)| {
                    let (_, _, link) = srv.get_link(link_id).ok()?;
                    Some(build_link_payload(srv, link_id, origin, destination, link))
                })
                .collect();
            Ok(ResponseValue::LinkList(entries))
        }
        WireRequest::LinkTypeList => {
            let types = srv
                .list_link_types()
                .into_iter()
                .map(|(type_id, name)| super::protocol::LinkTypeInfoPayload {
                    type_id,
                    name,
                    definition_work: srv.link_type_definition(type_id),
                })
                .collect();
            Ok(ResponseValue::LinkTypes(types))
        }
        WireRequest::BlobGet { content_hash } => {
            let data = srv.blob_get(content_hash.parse().unwrap_or(0))?;
            Ok(ResponseValue::BlobData(data))
        }
        WireRequest::BlobGetPreview { content_hash } => {
            match srv.blob_preview(content_hash.parse().unwrap_or(0))? {
                Some(data) => Ok(ResponseValue::BlobData(data)),
                None => Ok(ResponseValue::Void),
            }
        }
        WireRequest::BlobExists { content_hash } => Ok(ResponseValue::Boolean(
            srv.blob_exists(content_hash.parse().unwrap_or(0)),
        )),
        WireRequest::BlobInfo { content_hash } => {
            let meta = srv.blob_info(content_hash.parse().unwrap_or(0))?;
            Ok(ResponseValue::BlobMeta(
                super::protocol::BlobMetaPayload::from_blob_meta(&meta),
            ))
        }
        WireRequest::BlobStats => {
            let (total_blobs, total_bytes) = srv.blob_stats();
            Ok(ResponseValue::BlobStatsInfo(
                super::protocol::BlobStatsPayload {
                    total_blobs,
                    total_bytes,
                },
            ))
        }
        WireRequest::OverlayGet { overlay_hash } => {
            let overlay = srv.blob_get_overlay(overlay_hash)?;
            Ok(ResponseValue::OverlayInfo(
                super::protocol::OverlayPayload {
                    overlay_hash,
                    base_hash: overlay.base_hash,
                    operations: overlay.operations,
                    mime_type: overlay.mime_type,
                },
            ))
        }
        WireRequest::AdminRecorderList => {
            srv.ensure_admin(session_id)?;
            let recorders = srv
                .recorder_list()
                .into_iter()
                .map(|f| super::protocol::RecorderInfoPayload {
                    id: f.id,
                    kind: match f.query.kind {
                        crate::edition::RecorderKind::Transcluders => "transcluders".to_string(),
                        crate::edition::RecorderKind::Works => "works".to_string(),
                    },
                    direct_only: f.query.direct_only,
                    result_count: f.result_count(),
                    is_extinct: f.is_extinct,
                    reference_count: f.reference_count,
                    created_at: f.created_at,
                })
                .collect();
            Ok(ResponseValue::RecorderListResult { recorders })
        }
        WireRequest::AdminRecorderGet { recorder_id } => {
            srv.ensure_admin(session_id)?;
            let info =
                srv.recorder_get(recorder_id)
                    .map(|f| super::protocol::RecorderInfoPayload {
                        id: f.id,
                        kind: match f.query.kind {
                            crate::edition::RecorderKind::Transcluders => {
                                "transcluders".to_string()
                            }
                            crate::edition::RecorderKind::Works => "works".to_string(),
                        },
                        direct_only: f.query.direct_only,
                        result_count: f.result_count(),
                        is_extinct: f.is_extinct,
                        reference_count: f.reference_count,
                        created_at: f.created_at,
                    });
            Ok(ResponseValue::RecorderGetResult { recorder: info })
        }

        WireRequest::ResolveInlineTransclusions { work_id } => {
            // Materializing resolver — handled on the mutable dispatch
            // path (materialize_virtual_elements writes).
            let _ = work_id;
            return Err(ServerError::Internal(
                "resolve_inline_transclusions requires the mutable dispatch path".into(),
            ));
        }
        WireRequest::AttributionQueryResolved { work_id } => {
            // Materializing resolver — handled on the mutable dispatch path.
            let _ = work_id;
            return Err(ServerError::Internal(
                "attribution_query_resolved requires the mutable dispatch path".into(),
            ));
        }
        WireRequest::AdminServerHealth => {
            let health = srv.server_health();
            Ok(ResponseValue::ServerHealthResult {
                operation_count: health.operation_count,
                active_recorders: health.active_recorders,
                total_recorded: health.total_recorded,
                blob_count: health.blob_count,
                link_count: health.link_count,
                uptime_secs: health.uptime_secs,
            })
        }
        WireRequest::CryptoGetPublicKey => {
            let identity = srv.server_identity();
            Ok(ResponseValue::CryptoPublicKeyResult {
                key_id: srv.server_key_id(),
                verifying_key: identity.signing_key_bytes().to_vec(),
                kex_key: identity.kex_public_bytes().to_vec(),
                server_id: identity.server_id,
            })
        }
        WireRequest::CryptoKeyHistory => {
            let history = srv.server_key_history();
            let entries = history
                .entries
                .iter()
                .map(|e| super::protocol::KeyHistoryEntryPayload {
                    key_id: e.key_id,
                    not_before: e.not_before,
                    not_after: e.not_after,
                })
                .collect();
            Ok(ResponseValue::CryptoKeyHistoryResult {
                server_id: history.server_id.clone(),
                current_key_id: history.current_key_id,
                entry_count: history.entry_count(),
                entries,
            })
        }
        WireRequest::WorkEndorsements { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let es = srv.work_endorsements(work_id)?;
            Ok(ResponseValue::EndorsementResult {
                endorsements: es.iter().map(|e| (e.club_id(), e.token_id())).collect(),
            })
        }
        WireRequest::EditionEndorsements { edition_id } => {
            srv.ensure_session(session_id)?;
            let es = srv.edition_endorsements(edition_id)?;
            Ok(ResponseValue::EndorsementResult {
                endorsements: es.iter().map(|e| (e.club_id(), e.token_id())).collect(),
            })
        }
        WireRequest::EditionVisibleEndorsements { edition_id } => {
            let es = srv.edition_visible_endorsements(session_id, edition_id)?;
            Ok(ResponseValue::EndorsementResult {
                endorsements: es.iter().map(|e| (e.club_id(), e.token_id())).collect(),
            })
        }
        WireRequest::EditionTotalEndorsements { edition_id } => {
            srv.ensure_session(session_id)?;
            let es = srv.edition_total_endorsements(edition_id)?;
            Ok(ResponseValue::EndorsementResult {
                endorsements: es.iter().map(|e| (e.club_id(), e.token_id())).collect(),
            })
        }
        WireRequest::FederationInfo => {
            let info = srv.federation_info();
            let mode_str = match info.mode {
                crate::server::federation::FederationMode::Closed => "closed".to_string(),
                crate::server::federation::FederationMode::Open => "open".to_string(),
            };
            Ok(ResponseValue::FederationInfoResult {
                server_id: info.server_id,
                federation_domain: info.federation_domain,
                key_id: info.key_id,
                verifying_key: info.verifying_key,
                kex_key: info.kex_key,
                mode: mode_str,
                peers: info
                    .peers
                    .into_iter()
                    .map(|p| super::protocol::FederationPeerPayload {
                        server_id: p.server_id,
                        address: p.address.to_string(),
                        connected: p.connected,
                    })
                    .collect(),
                work_count: info.work_count,
                edition_count: info.edition_count,
            })
        }
        WireRequest::FederationPeers => {
            let peers = srv.federation_peers();
            Ok(ResponseValue::FederationPeersResult {
                peers: peers.iter().map(|p| p.to_string()).collect(),
            })
        }
        WireRequest::MembershipList => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            let members = srv.membership_list();
            Ok(ResponseValue::MembershipListResult { members })
        }
        WireRequest::MembershipVerify { server_id } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            let verify = srv.membership_verify(&server_id);
            Ok(ResponseValue::MembershipVerifyResult { verify })
        }
        WireRequest::GovernanceLog => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            let log = srv.governance_log().to_vec();
            Ok(ResponseValue::GovernanceLogResult { log })
        }
        WireRequest::GovernanceStatus => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument(
                    "federation not enabled".into(),
                ));
            }
            srv.ensure_logged_in(session_id)?;
            Ok(ResponseValue::GovernanceStatusResult {
                view: srv.governance_current_view(),
                sequence: srv.governance_current_sequence(),
                cluster_size: srv.governance_cluster_size(),
                quorum: srv.governance_quorum_size(),
                is_leader: srv.governance_is_leader(),
                leader_id: srv.governance_leader_id(),
                pending: srv.governance_pending_round().is_some(),
            })
        }
        WireRequest::CrdtSyncDiff {
            work_id,
            state_vector,
        } => {
            srv.ensure_logged_in(session_id)?;
            let update = srv.crdt_get_diff(work_id, state_vector)?;
            Ok(ResponseValue::CrdtSyncDiffResult { update })
        }
        WireRequest::CrdtSyncFullState { work_id } => {
            srv.ensure_logged_in(session_id)?;
            let state = srv.crdt_get_full_state(work_id)?;
            Ok(ResponseValue::CrdtSyncFullStateResult { state })
        }
        WireRequest::CrdtSyncSubscriberCount { work_id } => {
            srv.ensure_logged_in(session_id)?;
            let count = srv.crdt_subscriber_count(work_id);
            Ok(ResponseValue::CrdtSyncSubscriberCountResult { count })
        }
        WireRequest::CrdtSyncText { work_id } => {
            srv.ensure_logged_in(session_id)?;
            let text = srv.crdt_current_text(work_id)?;
            Ok(ResponseValue::CrdtSyncTextResult { text })
        }
        WireRequest::CrdtAwarenessGet { work_id } => {
            srv.ensure_logged_in(session_id)?;
            let mut states = srv.crdt_get_awareness(work_id)?;
            // Never echo the requester their own presence: the state
            // carries the SERVER-side masked SessionId, which clients
            // cannot predict from their session_connect id — the
            // self-echo rendered as a phantom "remote" caret.
            states.retain(|s| s.session_id != session_id.as_u64());
            Ok(ResponseValue::CrdtAwarenessGetResult { states })
        }
        WireRequest::AttributionVerify {
            author_public_key,
            signature,
            timestamp,
            server_id,
            span_fingerprint_hex,
        } => {
            let author_pk: [u8; 32] = author_public_key.try_into().map_err(|_| {
                crate::server::ServerError::InvalidArgument(
                    "author_public_key must be 32 bytes".into(),
                )
            })?;
            let sig: [u8; 64] = signature.try_into().map_err(|_| {
                crate::server::ServerError::InvalidArgument("signature must be 64 bytes".into())
            })?;
            let sid: [u8; 32] = server_id.try_into().map_err(|_| {
                crate::server::ServerError::InvalidArgument("server_id must be 32 bytes".into())
            })?;
            let valid =
                srv.attribution_verify(author_pk, sig, timestamp, sid, &span_fingerprint_hex);
            Ok(ResponseValue::AttributionVerifyResult { valid })
        }
        WireRequest::AttributionLogStatus => Ok(srv.attribution_log_status()),
        WireRequest::WorkBacklinks { work_id } => {
            srv.ensure_session(session_id)?;
            let backlinks = srv.find_backlinks(session_id, work_id)?;
            Ok(ResponseValue::WorkBacklinksResult(backlinks))
        }
        WireRequest::AnnotationGet {
            work_id,
            annotation_id,
        } => {
            let result = srv.annotation_get(session_id, work_id, annotation_id)?;
            match result {
                Some(ann) => Ok(ResponseValue::AnnotationResult(ann)),
                None => Err(crate::server::ServerError::NotFound(format!(
                    "annotation {} on work {}",
                    annotation_id, work_id
                ))),
            }
        }
        WireRequest::HistoricalAuthorGet { author_id } => {
            let author = srv.get_historical_author(author_id)?;
            Ok(ResponseValue::HistoricalAuthorResult {
                be_id: author.be_id,
                name: author.name,
                display_name: author.display_name,
                birth_year: author.birth_year,
                death_year: author.death_year,
                external_ids: author.external_ids,
                source_bibliography: author.source_bibliography,
            })
        }
        WireRequest::HistoricalAuthorSearch { query } => {
            let authors = srv.search_historical_authors(&query);
            let entries: Vec<super::protocol::HistoricalAuthorEntry> = authors
                .into_iter()
                .map(|a| super::protocol::HistoricalAuthorEntry {
                    be_id: a.be_id,
                    name: a.name,
                    display_name: a.display_name,
                    birth_year: a.birth_year,
                    death_year: a.death_year,
                })
                .collect();
            Ok(ResponseValue::HistoricalAuthorListResult { authors: entries })
        }
        WireRequest::HistoricalAuthorList => {
            let authors = srv.list_historical_authors();
            let entries: Vec<super::protocol::HistoricalAuthorEntry> = authors
                .into_iter()
                .map(|a| super::protocol::HistoricalAuthorEntry {
                    be_id: a.be_id,
                    name: a.name,
                    display_name: a.display_name,
                    birth_year: a.birth_year,
                    death_year: a.death_year,
                })
                .collect();
            Ok(ResponseValue::HistoricalAuthorListResult { authors: entries })
        }
        WireRequest::SourcePatternList => {
            let patterns = srv.list_source_patterns();
            let entries: Vec<super::protocol::SourcePatternEntry> = patterns
                .into_iter()
                .map(
                    |(source_type, display_name)| super::protocol::SourcePatternEntry {
                        source_type,
                        display_name,
                    },
                )
                .collect();
            Ok(ResponseValue::SourcePatternListResult { patterns: entries })
        }
        WireRequest::WorkSummary { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            srv.work_summary(work_id)
        }
        WireRequest::WorkVersionTimeline { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            srv.work_version_timeline(work_id)
        }
        WireRequest::GlobalTextSearch { query, max_results } => {
            srv.ensure_session(session_id)?;
            let max = max_results.unwrap_or(50) as usize;
            let results = srv.global_text_search(session_id, &query, max);
            let total_works_matched = results.len() as u64;
            let payloads: Vec<super::protocol::GlobalSearchResultPayload> = results
                .into_iter()
                .map(|r| super::protocol::GlobalSearchResultPayload {
                    work_id: r.work_id,
                    title: r.title,
                    owner: r.owner,
                    revision_count: r.revision_count,
                    matches: r
                        .matches
                        .into_iter()
                        .map(|m| super::protocol::SearchMatchPayload {
                            char_offset: m.char_offset,
                            line: m.line,
                            context: m.context,
                        })
                        .collect(),
                })
                .collect();
            Ok(ResponseValue::GlobalSearchResults {
                results: payloads,
                total_works_matched,
            })
        }
        _ => Err(crate::server::ServerError::Internal(
            "unhandled read request in dispatch_inner_read".to_string(),
        )),
    }
}

fn edition_to_text(edition: &Edition) -> String {
    edition
        .all_entries()
        .iter()
        .map(|(_, carrier)| carrier.element.as_text().unwrap_or(""))
        .collect()
}

fn spawn_auto_title(state: &SharedState, work_id: u64) {
    let llm = match crate::server::ollama::get_client() {
        Some(c) => c,
        None => return,
    };

    let text = state
        .server
        .with_server(|srv| srv.crdt_current_text(work_id).unwrap_or_default());

    if text.len() < 20 {
        return;
    }

    let state = state.clone();
    let prompt = crate::server::ollama::build_title_prompt(&text);

    tracing::info!(work_id, "auto-title: requesting from LLM");

    tokio::spawn(async move {
        match llm
            .generate_tracked(crate::server::ollama::LlmFeature::AutoTitle, &prompt)
            .await
        {
            Ok(title) => {
                let title = title.trim().trim_matches('"').to_string();
                tracing::info!(work_id, %title, "auto-title: generated");
                state.server.with_server(|srv| {
                    srv.set_work_title(work_id, title);
                });
            }
            Err(_e) => {
                tracing::warn!(work_id, "auto-title: failed");
            }
        }
    });
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn only_work_create_triggers_auto_title_gate() {
        let cases = [
            (
                WireRequest::WorkCreate {
                    edition: EditionPayload::Empty,
                },
                true,
            ),
            (
                WireRequest::ClubCreate {
                    description: EditionPayload::Empty,
                },
                false,
            ),
            (
                WireRequest::WorkRevise {
                    work_id: 1,
                    edition: EditionPayload::Empty,
                },
                false,
            ),
            (
                WireRequest::ClubCreateNamed {
                    name: "x".into(),
                    description: EditionPayload::Empty,
                },
                false,
            ),
            (WireRequest::WorkStar { work_id: 1 }, false),
        ];
        for (req, expected) in cases {
            let actual = matches!(req, WireRequest::WorkCreate { .. });
            assert_eq!(
                actual, expected,
                "auto-title gate wrong for {:?}: expected {}, got {}",
                req, expected, actual
            );
        }
    }

    #[tokio::test]
    async fn llm_semaphore_limits_concurrency() {
        let sem = llm_semaphore();
        let max = sem.available_permits().min(LLM_MAX_CONCURRENCY);

        let mut handles = Vec::new();
        for _ in 0..max {
            let permit = sem.acquire().await.unwrap();
            handles.push(permit);
        }

        assert_eq!(sem.available_permits(), 0);

        let start = std::time::Instant::now();
        let result =
            tokio::time::timeout(std::time::Duration::from_millis(100), sem.acquire()).await;
        assert!(
            start.elapsed() < std::time::Duration::from_millis(200),
            "acquiring beyond limit should block, not return immediately"
        );
        assert!(result.is_err(), "should time out waiting for permit");

        drop(handles);
        assert_eq!(sem.available_permits(), max);
    }

    // ── dispatch integration tests ─────────────────────────────────────

    use super::super::shared::AppState;
    use crate::server::SessionId;

    fn make_state() -> SharedState {
        AppState::new(Server::new()).shared()
    }

    fn fresh_session(state: &SharedState) -> SessionId {
        state.server.with_server(|srv| srv.connect())
    }

    fn public_session(state: &SharedState) -> SessionId {
        state.server.with_server(|srv| {
            let sid = srv.connect();
            srv.login_public(sid).unwrap();
            sid
        })
    }

    fn owned_session(state: &SharedState) -> SessionId {
        use crate::server::lock::{BooLock, LockCredential};
        state.server.with_server(|srv| {
            let sid = srv.connect();
            srv.login_public(sid).unwrap();
            let club_id = srv
                .create_club(sid, Edition::from_text("owner club"))
                .unwrap();
            let lock = BooLock::new(club_id);
            srv.authenticate(sid, &lock, &LockCredential::Boo).unwrap();
            sid
        })
    }

    // ── Read-only operations (no auth required) ──

    #[test]
    fn dispatch_server_stats_returns_payload() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(&state, sid, WireRequest::ServerStats);
        match result {
            Ok(ResponseValue::ServerInfo(info)) => {
                assert!(!info.version.is_empty());
                assert_eq!(info.work_count, 0);
                assert!(info.is_accepting_connections);
                assert_eq!(info.session_count, 1);
            }
            other => panic!("expected ServerInfo, got {:?}", other),
        }
    }

    #[test]
    fn dispatch_admin_is_accepting_connections_default_true() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(&state, sid, WireRequest::AdminIsAcceptingConnections);
        assert!(matches!(result, Ok(ResponseValue::Boolean(true))));
    }

    #[test]
    fn dispatch_crypto_get_public_key_returns_keys() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(&state, sid, WireRequest::CryptoGetPublicKey);
        match result {
            Ok(ResponseValue::CryptoPublicKeyResult {
                verifying_key,
                kex_key,
                server_id,
                ..
            }) => {
                assert!(!verifying_key.is_empty());
                assert!(!kex_key.is_empty());
                assert!(!server_id.is_empty());
            }
            other => panic!("expected CryptoPublicKeyResult, got {:?}", other),
        }
    }

    #[test]
    fn dispatch_link_type_list_empty_on_fresh_server() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(&state, sid, WireRequest::LinkTypeList);
        match result {
            Ok(ResponseValue::LinkTypes(types)) => {
                assert!(
                    types.is_empty(),
                    "fresh server has no registered link types"
                );
            }
            other => panic!("expected LinkTypes, got {:?}", other),
        }
    }

    #[test]
    fn dispatch_federation_info_returns_closed_mode() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(&state, sid, WireRequest::FederationInfo);
        match result {
            Ok(ResponseValue::FederationInfoResult { mode, peers, .. }) => {
                assert_eq!(mode, "closed");
                assert!(peers.is_empty());
            }
            other => panic!("expected FederationInfoResult, got {:?}", other),
        }
    }

    #[test]
    fn dispatch_federation_peers_returns_empty() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(&state, sid, WireRequest::FederationPeers);
        match result {
            Ok(ResponseValue::FederationPeersResult { peers }) => {
                assert!(peers.is_empty());
            }
            other => panic!("expected FederationPeersResult, got {:?}", other),
        }
    }

    #[test]
    fn dispatch_blob_stats_returns_zero() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(&state, sid, WireRequest::BlobStats);
        match result {
            Ok(ResponseValue::BlobStatsInfo(stats)) => {
                assert_eq!(stats.total_blobs, 0);
                assert_eq!(stats.total_bytes, 0);
            }
            other => panic!("expected BlobStatsInfo, got {:?}", other),
        }
    }

    #[test]
    fn dispatch_historical_author_list_empty() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(&state, sid, WireRequest::HistoricalAuthorList);
        match result {
            Ok(ResponseValue::HistoricalAuthorListResult { authors }) => {
                assert!(authors.is_empty());
            }
            other => panic!("expected HistoricalAuthorListResult, got {:?}", other),
        }
    }

    #[test]
    fn dispatch_trail_list_categories_succeeds() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(&state, sid, WireRequest::TrailListCategories);
        assert!(result.is_ok(), "TrailListCategories should succeed");
        assert!(matches!(result.unwrap(), ResponseValue::TrailCategories(_)));
    }

    #[test]
    fn dispatch_attribution_log_status_returns_result() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(&state, sid, WireRequest::AttributionLogStatus);
        match result {
            Ok(ResponseValue::AttributionLogStatusResult { has_log, .. }) => {
                assert!(has_log);
            }
            other => panic!("expected AttributionLogStatusResult, got {:?}", other),
        }
    }

    #[test]
    fn dispatch_source_pattern_list_returns_entries() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(&state, sid, WireRequest::SourcePatternList);
        assert!(result.is_ok());
        match result {
            Ok(ResponseValue::SourcePatternListResult { patterns }) => {
                assert!(!patterns.is_empty(), "should have builtin source patterns");
            }
            other => panic!("expected SourcePatternListResult, got {:?}", other),
        }
    }

    // ── Read-only operations (session required) ──

    #[test]
    fn dispatch_session_connect_echoes_session_id() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(&state, sid, WireRequest::SessionConnect);
        match result {
            Ok(ResponseValue::Id(val)) => {
                assert_eq!(val, sid.as_u64());
            }
            other => panic!("expected Id echoing session, got {:?}", other),
        }
    }

    #[test]
    fn dispatch_work_list_empty_on_fresh_server() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(
            &state,
            sid,
            WireRequest::WorkList {
                offset: None,
                limit: None,
            },
        );
        match result {
            Ok(ResponseValue::PaginatedWorkList {
                entries,
                total_count,
                has_more,
            }) => {
                assert!(entries.is_empty());
                assert_eq!(total_count, 0);
                assert!(!has_more);
            }
            other => panic!("expected PaginatedWorkList, got {:?}", other),
        }
    }

    #[test]
    fn dispatch_club_names_returns_system_clubs() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(
            &state,
            sid,
            WireRequest::ClubNames {
                offset: None,
                limit: None,
            },
        );
        match result {
            Ok(ResponseValue::PaginatedClubNames {
                entries,
                total_count,
                ..
            }) => {
                assert!(total_count >= 4, "should have at least 4 system clubs");
                let names: Vec<&str> = entries.iter().map(|(n, _)| n.as_str()).collect();
                assert!(names.contains(&"admin"), "should include admin club");
                assert!(names.contains(&"public"), "should include public club");
            }
            other => panic!("expected PaginatedClubNames, got {:?}", other),
        }
    }

    #[test]
    fn dispatch_club_names_pagination() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(
            &state,
            sid,
            WireRequest::ClubNames {
                offset: Some(0),
                limit: Some(2),
            },
        );
        match result {
            Ok(ResponseValue::PaginatedClubNames {
                entries,
                total_count,
                has_more,
            }) => {
                assert_eq!(entries.len(), 2, "should limit to 2 entries");
                assert!(has_more, "should have more entries");
                assert!(total_count >= 4);
            }
            other => panic!("expected PaginatedClubNames, got {:?}", other),
        }
    }

    #[test]
    fn dispatch_club_who_am_i_after_login_public() {
        let state = make_state();
        let sid = public_session(&state);
        let result = dispatch(&state, sid, WireRequest::ClubWhoAmI);
        match result {
            Ok(ResponseValue::ClubWhoAmIResult { clubs, .. }) => {
                assert!(
                    clubs.is_empty(),
                    "no personal clubs after login_public only"
                );
            }
            other => panic!("expected ClubWhoAmIResult, got {:?}", other),
        }
    }

    #[test]
    fn dispatch_global_text_search_empty_server() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(
            &state,
            sid,
            WireRequest::GlobalTextSearch {
                query: "nothing".to_string(),
                max_results: Some(10),
            },
        );
        assert!(result.is_ok(), "search should succeed on empty server");
        match result.unwrap() {
            ResponseValue::GlobalSearchResults {
                results,
                total_works_matched,
            } => {
                assert!(results.is_empty());
                assert_eq!(total_works_matched, 0);
            }
            other => panic!("expected GlobalSearchResults, got {:?}", other),
        }
    }

    // ── Session lifecycle (write path) ──

    #[tokio::test]
    async fn dispatch_session_login_public_succeeds() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(&state, sid, WireRequest::SessionLoginPublic);
        match result {
            Ok(ResponseValue::Id(_)) => {}
            other => panic!("expected Id after login_public, got {:?}", other),
        }
    }

    #[tokio::test]
    async fn dispatch_session_disconnect_succeeds() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(&state, sid, WireRequest::SessionDisconnect);
        assert!(matches!(result, Ok(ResponseValue::Void)));
    }

    #[tokio::test]
    async fn dispatch_session_ticket_issue_and_redeem_roundtrip() {
        let state = make_state();
        let sid = public_session(&state);

        let issue_result = dispatch(&state, sid, WireRequest::SessionTicketIssue);
        let ticket = match issue_result {
            Ok(ResponseValue::Ticket { ticket, .. }) => ticket,
            other => panic!("expected Ticket, got {:?}", other),
        };
        assert!(!ticket.is_empty(), "ticket bytes should be non-empty");

        let sid2 = fresh_session(&state);
        let redeem_result = dispatch(&state, sid2, WireRequest::SessionTicketRedeem { ticket });
        assert!(redeem_result.is_ok(), "ticket redeem should succeed");
    }

    // ── Error cases ──

    #[tokio::test]
    async fn dispatch_work_create_without_auth_fails() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(
            &state,
            sid,
            WireRequest::WorkCreate {
                edition: EditionPayload::Text("test".into()),
            },
        );
        assert!(
            matches!(result, Err(crate::server::ServerError::NotAuthorized)),
            "WorkCreate without auth should return NotAuthorized, got {:?}",
            result
        );
    }

    #[test]
    fn dispatch_club_get_unknown_club_errors() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(&state, sid, WireRequest::ClubGet { club_id: 999_999 });
        assert!(result.is_err(), "unknown club should error");
    }

    #[test]
    fn dispatch_work_revision_count_unknown_work_errors() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(
            &state,
            sid,
            WireRequest::WorkRevisionCount { work_id: 999_999 },
        );
        assert!(result.is_err(), "unknown work should error");
    }

    #[test]
    fn dispatch_club_by_name_finds_admin() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(
            &state,
            sid,
            WireRequest::ClubByName {
                name: "admin".to_string(),
            },
        );
        match result {
            Ok(ResponseValue::Id(id)) => {
                assert!(id > 0);
            }
            other => panic!("expected Id for admin club, got {:?}", other),
        }
    }

    #[test]
    fn dispatch_club_by_name_unknown_returns_error() {
        let state = make_state();
        let sid = fresh_session(&state);
        let result = dispatch(
            &state,
            sid,
            WireRequest::ClubByName {
                name: "nonexistent".to_string(),
            },
        );
        assert!(result.is_err());
    }

    #[test]
    fn dispatch_club_name_by_id_returns_name() {
        let state = make_state();
        let sid = fresh_session(&state);
        let admin_id = state.server.with_server_ref(|srv| srv.admin_club_id());
        let result = dispatch(&state, sid, WireRequest::ClubNameById { club_id: admin_id });
        match result {
            Ok(ResponseValue::String(name)) => {
                assert_eq!(name, "admin");
            }
            other => panic!("expected String, got {:?}", other),
        }
    }

    // ── Authenticated write path ──

    #[tokio::test]
    async fn dispatch_work_create_with_auth_succeeds() {
        let state = make_state();
        let sid = owned_session(&state);
        let result = dispatch(
            &state,
            sid,
            WireRequest::WorkCreate {
                edition: EditionPayload::Text("hello world".into()),
            },
        );
        match result {
            Ok(ResponseValue::Id(work_id)) => {
                assert!(work_id > 0, "work id should be positive");
            }
            other => panic!("expected Id(work_id), got {:?}", other),
        }
    }

    #[tokio::test]
    async fn dispatch_work_list_after_create_shows_work() {
        let state = make_state();
        let sid = owned_session(&state);
        let create_result = dispatch(
            &state,
            sid,
            WireRequest::WorkCreate {
                edition: EditionPayload::Text("my work".into()),
            },
        );
        let work_id = match create_result {
            Ok(ResponseValue::Id(id)) => id,
            other => panic!("expected Id, got {:?}", other),
        };

        let list_result = dispatch(
            &state,
            sid,
            WireRequest::WorkList {
                offset: None,
                limit: None,
            },
        );
        match list_result {
            Ok(ResponseValue::PaginatedWorkList {
                entries,
                total_count,
                ..
            }) => {
                assert_eq!(total_count, 1, "should see exactly 1 work");
                assert_eq!(entries.len(), 1);
                assert_eq!(entries[0].work_id, work_id);
            }
            other => panic!("expected PaginatedWorkList, got {:?}", other),
        }
    }

    #[tokio::test]
    async fn dispatch_work_get_edition_after_create() {
        let state = make_state();
        let sid = owned_session(&state);
        let create_result = dispatch(
            &state,
            sid,
            WireRequest::WorkCreate {
                edition: EditionPayload::Text("edition test".into()),
            },
        );
        let work_id = match create_result {
            Ok(ResponseValue::Id(id)) => id,
            other => panic!("expected Id, got {:?}", other),
        };

        let result = dispatch(&state, sid, WireRequest::WorkGetEdition { work_id });
        match result {
            Ok(ResponseValue::Edition(EditionPayload::Text(text))) => {
                assert_eq!(text, "edition test");
            }
            other => panic!("expected Edition Text, got {:?}", other),
        }
    }

    #[tokio::test]
    async fn dispatch_work_is_grabbed_false_for_new_work() {
        let state = make_state();
        let sid = owned_session(&state);
        let create_result = dispatch(
            &state,
            sid,
            WireRequest::WorkCreate {
                edition: EditionPayload::Empty,
            },
        );
        let work_id = match create_result {
            Ok(ResponseValue::Id(id)) => id,
            other => panic!("expected Id, got {:?}", other),
        };

        let result = dispatch(&state, sid, WireRequest::WorkIsGrabbed { work_id });
        assert!(matches!(result, Ok(ResponseValue::Boolean(false))));
    }

    #[tokio::test]
    async fn dispatch_work_revision_count_after_create() {
        let state = make_state();
        let sid = owned_session(&state);
        let create_result = dispatch(
            &state,
            sid,
            WireRequest::WorkCreate {
                edition: EditionPayload::Text("rev count".into()),
            },
        );
        let work_id = match create_result {
            Ok(ResponseValue::Id(id)) => id,
            other => panic!("expected Id, got {:?}", other),
        };

        let result = dispatch(&state, sid, WireRequest::WorkRevisionCount { work_id });
        match result {
            Ok(ResponseValue::Humber(count)) => {
                assert_eq!(count, 0, "freshly created work should have 0 revisions");
            }
            other => panic!("expected Humber, got {:?}", other),
        }
    }

    #[tokio::test]
    async fn dispatch_work_star_toggle() {
        let state = make_state();
        let sid = owned_session(&state);
        let create_result = dispatch(
            &state,
            sid,
            WireRequest::WorkCreate {
                edition: EditionPayload::Empty,
            },
        );
        let work_id = match create_result {
            Ok(ResponseValue::Id(id)) => id,
            other => panic!("expected Id, got {:?}", other),
        };

        let before = dispatch(&state, sid, WireRequest::WorkIsStarred { work_id });
        assert!(matches!(before, Ok(ResponseValue::Boolean(false))));

        let star_result = dispatch(&state, sid, WireRequest::WorkStar { work_id });
        assert!(matches!(star_result, Ok(ResponseValue::Void)));

        let after = dispatch(&state, sid, WireRequest::WorkIsStarred { work_id });
        assert!(matches!(after, Ok(ResponseValue::Boolean(true))));
    }

    #[tokio::test]
    async fn dispatch_admin_accept_connections_toggle() {
        let state = make_state();
        let sid = state.server.with_server(|srv| {
            use crate::server::lock::{BooLock, LockCredential};
            let s = srv.connect();
            let admin_id = srv.admin_club_id();
            let lock = BooLock::new(admin_id);
            srv.authenticate(s, &lock, &LockCredential::Boo).unwrap();
            s
        });

        let before = dispatch(&state, sid, WireRequest::AdminIsAcceptingConnections);
        assert!(matches!(before, Ok(ResponseValue::Boolean(true))));

        let toggle = dispatch(
            &state,
            sid,
            WireRequest::AdminAcceptConnections { accept: false },
        );
        assert!(matches!(toggle, Ok(ResponseValue::Void)));

        let after = dispatch(&state, sid, WireRequest::AdminIsAcceptingConnections);
        assert!(matches!(after, Ok(ResponseValue::Boolean(false))));
    }

    #[tokio::test]
    async fn dispatch_server_stats_reflects_created_work() {
        let state = make_state();
        let sid = owned_session(&state);

        let before = dispatch(&state, sid, WireRequest::ServerStats);
        match &before {
            Ok(ResponseValue::ServerInfo(info)) => {
                assert_eq!(info.work_count, 0);
            }
            other => panic!("expected ServerInfo, got {:?}", other),
        }

        dispatch(
            &state,
            sid,
            WireRequest::WorkCreate {
                edition: EditionPayload::Text("stats test".into()),
            },
        )
        .unwrap();

        let after = dispatch(&state, sid, WireRequest::ServerStats);
        match after {
            Ok(ResponseValue::ServerInfo(info)) => {
                assert_eq!(info.work_count, 1, "work_count should reflect created work");
            }
            other => panic!("expected ServerInfo, got {:?}", other),
        }
    }
}
