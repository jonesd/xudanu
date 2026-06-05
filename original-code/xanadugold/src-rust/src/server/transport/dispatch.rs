use super::protocol::*;
use super::shared::{AppState, ServerHandle, SharedState};
use crate::edition::{BeId, Edition};
use crate::server::lock::LockCredential;
use crate::server::Server;

pub fn dispatch(
    state: &SharedState,
    session_id: crate::server::SessionId,
    request: WireRequest,
) -> Result<ResponseValue, crate::server::ServerError> {
    let op_name = format!("{:?}", request);
    let op_name = op_name.split_whitespace().next().unwrap_or("?");
    let span = tracing::info_span!("dispatch", op = op_name, session = session_id.as_u64());
    let _enter = span.enter();

    if matches!(request, WireRequest::WorkDiffNarration { .. }) {
        return dispatch_narration(state, session_id, request);
    }

    if matches!(request, WireRequest::WorkWritingFeedback { .. }) {
        return dispatch_writing_feedback(state, session_id, request);
    }

    let result = {
        let guard_result = std::panic::catch_unwind(std::panic::AssertUnwindSafe(|| {
            state.server.with_server(|srv| {
                srv.bump_operation();
                dispatch_inner(srv, session_id, request, state)
            })
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

    if let Ok(ResponseValue::Id(work_id)) = &result {
        spawn_auto_title(state, *work_id);
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
        srv.bump_operation();
        srv.ensure_can_read(session_id, work_id)?;

        let new_text = if srv.crdt_is_active(work_id) {
            srv.crdt_current_text(work_id).unwrap_or_default()
        } else {
            String::new()
        };

        let base_text = if srv.crdt_is_active(work_id) {
            if srv.use_otree_crdt {
                srv.otree_crdt
                    .narration_snapshot(work_id)
                    .map_err(|e| crate::server::ServerError::Internal(e.to_string()))?
                    .unwrap_or_default()
            } else {
                let edition = srv.work_edition(work_id)?;
                edition_to_text(&edition)
            }
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

    let narration = match tokio::task::block_in_place(|| {
        tokio::runtime::Handle::current()
            .block_on(llm.generate_tracked(crate::server::ollama::LlmFeature::Narration, &prompt))
    }) {
        Ok(text) => text,
        Err(e) => format!("(LLM unavailable: {})", e),
    };

    let llm_model = format!("{}/{}", llm.backend_label(), llm.model_name());

    let insert_text = format!(
        "\n\n---\n**Change Summary**\n{}\n— via {}",
        narration, llm_model
    );

    state.server.with_server(|srv| {
        if srv.crdt_is_active(work_id) && srv.use_otree_crdt {
            let _ = srv.otree_crdt.set_narration_snapshot(work_id);
            let triggerer_club = srv
                .otree_crdt
                .get_author(work_id, session_id)
                .ok()
                .flatten()
                .map(|a| a.club_be_id)
                .unwrap_or(0);
            let _ =
                srv.otree_crdt
                    .append_llm_text(work_id, &insert_text, &llm_model, triggerer_club);
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
        srv.bump_operation();
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
        tokio::runtime::Handle::current().block_on(
            llm.generate_tracked(crate::server::ollama::LlmFeature::WritingFeedback, &prompt),
        )
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

fn dispatch_inner(
    srv: &mut Server,
    session_id: crate::server::SessionId,
    request: WireRequest,
    state: &SharedState,
) -> Result<ResponseValue, crate::server::ServerError> {
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
            let ed = edition.to_edition();
            let id = srv.create_work(session_id, ed)?;
            Ok(ResponseValue::Id(id))
        }
        WireRequest::WorkGetEdition { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
            let ed = srv.work_edition(work_id)?;
            Ok(ResponseValue::Edition(EditionPayload::from_edition(&ed)))
        }
        WireRequest::WorkRevise { work_id, edition } => {
            srv.ensure_authenticated(session_id)?;
            let ed = edition.to_edition();
            let rev = srv.work_revise(session_id, work_id, ed)?;
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
                use super::protocol::apply_text_delta;
                let current_ed = srv.work_edition(work_id)?;
                let current_rev = srv.work_revision_count(work_id)?;
                if current_rev != base_revision {
                    return Ok(ResponseValue::Edition(EditionPayload::from_edition(
                        &current_ed,
                    )));
                }
                let current_text = edition_to_text(&current_ed);
                let new_text = apply_text_delta(&current_text, &ops);
                let new_ed = Edition::from_text_batched(&new_text);
                let rev = srv.work_revise(session_id, work_id, new_ed)?;
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
            let ed = edition.to_edition();
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
        WireRequest::WorkReadClub { work_id } => {
            let club = srv.work_read_club(work_id)?;
            Ok(ResponseValue::Humber(club.unwrap_or(0)))
        }
        WireRequest::WorkEditClub { work_id } => {
            let club = srv.work_edit_club(work_id)?;
            Ok(ResponseValue::Humber(club.unwrap_or(0)))
        }
        WireRequest::WorkRevisionCount { work_id } => {
            let count = srv.work_revision_count(work_id)?;
            Ok(ResponseValue::Humber(count))
        }
        WireRequest::WorkFetchRevision { work_id, number } => {
            srv.ensure_can_read(session_id, work_id)?;
            match srv.work_fetch_revision(work_id, number)? {
                Some(ed) => Ok(ResponseValue::Edition(EditionPayload::from_edition(&ed))),
                None => Ok(ResponseValue::Void),
            }
        }
        WireRequest::WorkFetchRevisionRange { work_id, from, to } => {
            srv.ensure_can_read(session_id, work_id)?;
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
        WireRequest::WorkIsPublished { work_id } => {
            let published = srv.work_is_published(session_id, work_id)?;
            Ok(ResponseValue::Boolean(published))
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
            let (credential, raw_password) = match password {
                Some(pw) => {
                    let phc_hash = crate::crypto::password::hash_password(&pw).map_err(|e| {
                        crate::server::ServerError::Internal(format!("password hash failed: {}", e))
                    })?;
                    (Some(Credential::Password { phc_hash }), Some(pw))
                }
                None => (None, None),
            };
            let id =
                srv.create_personal_club(session_id, display_name, credential, raw_password)?;
            Ok(ResponseValue::Id(id))
        }
        WireRequest::ClubWhoAmI => {
            let clubs = srv.who_am_i(session_id)?;
            Ok(ResponseValue::ClubWhoAmIResult { clubs })
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

        WireRequest::EditionStore { edition } => {
            srv.ensure_authenticated(session_id)?;
            let ed = edition.to_edition();
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
            let all: Vec<_> = srv
                .list_works_with_titles()
                .into_iter()
                .filter(|(work_id, _, _, _, _, _, _, _, _, _, _)| {
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
                            title,
                            read_club,
                            is_source,
                            content_start_line,
                            content_end_line,
                            source_author_id,
                            source_edition_info,
                        }
                    },
                )
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
        WireRequest::WorkListByOwner {
            owner,
            offset,
            limit,
        } => {
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
                        title: String::new(),
                        read_club,
                        is_source: false,
                        content_start_line: None,
                        content_end_line: None,
                        source_author_id: None,
                        source_edition_info: None,
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
        } => {
            srv.ensure_authenticated(session_id)?;
            srv.ensure_can_read(session_id, origin)?;
            srv.ensure_can_read(session_id, destination)?;
            let o_ref = origin_ref.map(|hr| {
                let excerpt = hr
                    .excerpt
                    .as_deref()
                    .map(|t| crate::edition::Edition::from_text(t));
                let path = hr.path_context.map(|labels| {
                    crate::edition::links::Path::new(
                        labels
                            .iter()
                            .filter_map(|l| l.to_range_element())
                            .collect(),
                    )
                });
                crate::edition::links::HyperRef::single(
                    excerpt,
                    hr.work_context,
                    hr.original_context,
                    path,
                )
            });
            let d_ref = destination_ref.map(|hr| {
                let excerpt = hr
                    .excerpt
                    .as_deref()
                    .map(|t| crate::edition::Edition::from_text(t));
                let path = hr.path_context.map(|labels| {
                    crate::edition::links::Path::new(
                        labels
                            .iter()
                            .filter_map(|l| l.to_range_element())
                            .collect(),
                    )
                });
                crate::edition::links::HyperRef::single(
                    excerpt,
                    hr.work_context,
                    hr.original_context,
                    path,
                )
            });
            let link_id = srv.create_link(session_id, origin, destination, o_ref, d_ref)?;
            Ok(ResponseValue::Id(link_id))
        }
        WireRequest::LinkGet { link_id } => {
            let (origin, destination, link) = srv.get_link(link_id)?;
            srv.ensure_can_read(session_id, origin)?;
            srv.ensure_can_read(session_id, destination)?;
            let o_ref = link
                .end_at("LeftEnd")
                .map(super::protocol::HyperRefPayload::from_hyper_ref);
            let d_ref = link
                .end_at("RightEnd")
                .map(super::protocol::HyperRefPayload::from_hyper_ref);
            Ok(ResponseValue::LinkInfo(super::protocol::LinkPayload {
                link_id,
                origin,
                destination,
                origin_ref: o_ref,
                destination_ref: d_ref,
            }))
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
                .with_provenance_chain(chain)
            });
            let d_ref = destination_ref.map(|hr| {
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
                .filter_map(|(link_id, origin, destination)| {
                    let (_, _, link) = srv.get_link(link_id).ok()?;
                    let o_ref = link
                        .end_at("LeftEnd")
                        .map(super::protocol::HyperRefPayload::from_hyper_ref);
                    let d_ref = link
                        .end_at("RightEnd")
                        .map(super::protocol::HyperRefPayload::from_hyper_ref);
                    Some(super::protocol::LinkPayload {
                        link_id,
                        origin,
                        destination,
                        origin_ref: o_ref,
                        destination_ref: d_ref,
                    })
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
                .find_transcluders(content_be_id)
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
            let data = srv.blob_get(content_hash)?;
            Ok(ResponseValue::BlobData(data))
        }
        WireRequest::BlobGetPreview { content_hash } => match srv.blob_preview(content_hash)? {
            Some(data) => Ok(ResponseValue::BlobData(data)),
            None => Ok(ResponseValue::Void),
        },
        WireRequest::BlobExists { content_hash } => {
            Ok(ResponseValue::Boolean(srv.blob_exists(content_hash)))
        }
        WireRequest::BlobInfo { content_hash } => {
            let meta = srv.blob_info(content_hash)?;
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
            let ed = new_edition.to_edition();
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
            use super::protocol::{BundlePayload, RetrieveFlagsPayload};
            use crate::edition::{Bundle, RetrieveFlags};
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
            srv.ensure_can_read(session_id, work_a)?;
            srv.ensure_can_read(session_id, work_b)?;
            let is_before = srv.version_is_before(work_a, work_b);
            Ok(ResponseValue::VersionIsBeforeResult { is_before })
        }
        WireRequest::VersionAncestors { work_id } => {
            srv.ensure_can_read(session_id, work_id)?;
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
            srv.ensure_can_read(session_id, work_id)?;
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
            let hops = chain
                .into_iter()
                .map(|hop| super::protocol::ProvenanceHopPayload {
                    source_work_id: hop.source_work_id(),
                    link_id: hop.link_id(),
                })
                .collect();
            Ok(ResponseValue::ProvenanceAncestryResult { chain: hops })
        }
        WireRequest::CompoundResolve { compound } => {
            let edition = compound.to_compound();
            for work_id in edition.referenced_works() {
                srv.ensure_can_read(session_id, work_id)?;
            }
            let text = srv.resolve_compound_edition(&edition)?;
            Ok(ResponseValue::CompoundResolveResult { text })
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

        WireRequest::CrdtAwarenessUpdate { work_id, mut awareness } => {
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
            let states = srv.crdt_get_awareness(work_id)?;
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
        WireRequest::WorkDiffNarration { .. } => unreachable!("handled in dispatch_narration"),
        WireRequest::WorkWritingFeedback { .. } => {
            unreachable!("handled in dispatch_writing_feedback")
        }

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
        } => {
            srv.annotation_create(session_id, work_id, annotation_id, kind, payload)?;
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
                            title,
                            read_club,
                            is_source: true,
                            content_start_line: None,
                            content_end_line: None,
                            source_author_id: Some(author_id),
                            source_edition_info,
                        }
                    },
                )
                .collect();
            Ok(ResponseValue::WorkList(list))
        }

        WireRequest::ContentMatch { text } => {
            match srv.match_content(&text) {
                Some((work_id, author_id, score)) => {
                    Ok(ResponseValue::ContentMatchResult {
                        matched: true,
                        work_id: Some(work_id),
                        author_id: Some(author_id),
                        score: Some(score),
                    })
                }
                None => Ok(ResponseValue::ContentMatchResult {
                    matched: false,
                    work_id: None,
                    author_id: None,
                    score: None,
                }),
            }
        }

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
            Err(e) => {
                tracing::warn!(work_id, "auto-title: failed: {}", e);
            }
        }
    });
}
