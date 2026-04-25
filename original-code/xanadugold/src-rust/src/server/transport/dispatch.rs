use crate::edition::BeId;
use crate::server::Server;
use crate::server::lock::LockCredential;
use crate::server::lock::{BooLock, ChallengeLock, MatchLock};
use super::protocol::*;
use super::shared::ServerHandle;

pub fn dispatch(
    handle: &ServerHandle,
    session_id: crate::server::SessionId,
    request: WireRequest,
) -> Result<ResponseValue, crate::server::ServerError> {
    handle.with_server(|srv| {
        srv.bump_operation();
        dispatch_inner(srv, session_id, request)
    })
}

fn dispatch_inner(
    srv: &mut Server,
    session_id: crate::server::SessionId,
    request: WireRequest,
) -> Result<ResponseValue, crate::server::ServerError> {
    match request {
        WireRequest::SessionConnect => {
            Ok(ResponseValue::Id(session_id.as_u64()))
        }
        WireRequest::SessionDisconnect => {
            srv.disconnect(session_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::SessionLogin { club_id } => {
            let _lock = srv.login(session_id, club_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::SessionLoginByName { club_name } => {
            let _lock = srv.login_by_name(session_id, &club_name)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::SessionAuthenticate { club_id, credential } => {
            let lock = match &credential {
                LockCredential::Boo => {
                    Box::new(BooLock::new(club_id)) as Box<dyn crate::server::Lock>
                }
                LockCredential::ChallengeResponse(resp) => {
                    Box::new(ChallengeLock::new(club_id, vec![], resp.clone()))
                }
                LockCredential::Password(pw) => {
                    Box::new(MatchLock::new(club_id, pw.clone()))
                }
                LockCredential::Named { .. } => {
                    return Err(crate::server::ServerError::InvalidArgument(
                        "multi-lock not supported via authenticate; use named locks directly".into(),
                    ));
                }
            };
            let km = srv.authenticate(session_id, lock.as_ref(), &credential)?;
            let clubs: Vec<BeId> = km.actual_authority().into_iter().collect();
            Ok(ResponseValue::Ids(clubs))
        }
        WireRequest::SessionLoginPublic => {
            let km = srv.login_public(session_id)?;
            Ok(ResponseValue::Id(km.login_authority().iter().next().copied().unwrap_or(0)))
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
            let _club = srv.club(club_id)?;
            Ok(ResponseValue::Id(club_id))
        }
        WireRequest::ClubByName { name } | WireRequest::ClubIdByName { name } => {
            match srv.club_id_by_name(&name) {
                Some(id) => Ok(ResponseValue::Id(id)),
                None => Err(crate::server::ServerError::NotFound(format!("club '{}'", name))),
            }
        }
        WireRequest::ClubNameById { club_id } => {
            let name = srv.club_name_by_id(club_id)
                .map(|s| s.to_string())
                .ok_or_else(|| crate::server::ServerError::ClubNotFound(club_id))?;
            Ok(ResponseValue::String(name))
        }
        WireRequest::ClubNames => {
            let names = srv.club_names_list()
                .into_iter()
                .map(|(n, id)| (n.to_string(), id))
                .collect();
            Ok(ResponseValue::ClubNames(names))
        }

        WireRequest::WorkCreate { edition } => {
            let ed = edition.to_edition();
            let id = srv.create_work(session_id, ed)?;
            Ok(ResponseValue::Id(id))
        }
        WireRequest::WorkGetEdition { work_id } => {
            let ed = srv.work_edition(work_id)?;
            Ok(ResponseValue::Edition(EditionPayload::from_edition(&ed)))
        }
        WireRequest::WorkRevise { work_id, edition } => {
            let ed = edition.to_edition();
            let rev = srv.work_revise(session_id, work_id, ed)?;
            Ok(ResponseValue::Humber(rev))
        }
        WireRequest::WorkGrab { work_id } => {
            srv.work_grab(session_id, work_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkRelease { work_id } => {
            srv.work_release(session_id, work_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkIsGrabbed { work_id } => {
            let grabbed = srv.work_is_grabbed(work_id)?;
            Ok(ResponseValue::Boolean(grabbed))
        }
        WireRequest::WorkGrabber { work_id } => {
            let grabber = srv.work_grabber(work_id)?;
            Ok(ResponseValue::Humber(grabber.map(|s| s.as_u64()).unwrap_or(0)))
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
            srv.work_set_read_club(session_id, work_id, club_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkSetEditClub { work_id, club_id } => {
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
            match srv.work_fetch_revision(work_id, number)? {
                Some(ed) => Ok(ResponseValue::Edition(EditionPayload::from_edition(&ed))),
                None => Ok(ResponseValue::Void),
            }
        }
        WireRequest::WorkSponsor { work_id, club_id } => {
            srv.work_sponsor(work_id, club_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkUnsponsor { work_id, club_id } => {
            srv.work_unsponsor(work_id, club_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkSponsors { work_id } => {
            let sponsors = srv.work_sponsors(work_id)?.to_vec();
            Ok(ResponseValue::Ids(sponsors))
        }
        WireRequest::WorkOwner { work_id } => {
            let owner = srv.work_owner(work_id)?;
            Ok(ResponseValue::Humber(owner.unwrap_or(0)))
        }

        WireRequest::EditionStore { edition } => {
            let ed = edition.to_edition();
            let id = srv.store_edition(session_id, ed)?;
            Ok(ResponseValue::Id(id))
        }
        WireRequest::EditionGet { be_id } => {
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
            let payloads = infos.into_iter().map(|si| {
                super::protocol::SessionInfoPayload {
                    session_id: si.session_id,
                    is_logged_in: si.is_logged_in,
                    authority_clubs: si.authority_clubs,
                    initial_login: si.initial_login,
                    grabbed_work_count: if si.has_grabbed_works { 1 } else { 0 },
                }
            }).collect();
            Ok(ResponseValue::SessionInfos(payloads))
        }
        WireRequest::AdminShutdown => {
            srv.admin_shutdown(session_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::AdminGrant { club_id, region_start, region_end } => {
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
            let payloads = grants.iter().map(|g| {
                let (start, end) = g.region.as_interval().unwrap_or((0, 0));
                super::protocol::GrantPayload {
                    club_id: g.club_id,
                    region_start: start,
                    region_end: end,
                }
            }).collect();
            Ok(ResponseValue::Grants(payloads))
        }
        WireRequest::AdminServerInfo => {
            Ok(ResponseValue::ServerInfo(super::protocol::ServerInfoPayload {
                version: env!("CARGO_PKG_VERSION").to_string(),
                session_count: srv.session_count(),
                work_count: srv.work_count(),
                club_count: srv.club_count(),
                edition_count: srv.edition_count(),
                is_accepting_connections: srv.admin_is_accepting_connections(),
            }))
        }

        WireRequest::ServerStats => {
            Ok(ResponseValue::ServerInfo(super::protocol::ServerInfoPayload {
                version: env!("CARGO_PKG_VERSION").to_string(),
                session_count: srv.session_count(),
                work_count: srv.work_count(),
                club_count: srv.club_count(),
                edition_count: srv.edition_count(),
                is_accepting_connections: srv.admin_is_accepting_connections(),
            }))
        }

        WireRequest::WorkList => {
            let entries = srv.list_works().into_iter().map(|(work_id, owner, revision_count, is_grabbed)| {
                super::protocol::WorkListEntry { work_id, owner, revision_count, is_grabbed }
            }).collect();
            Ok(ResponseValue::WorkList(entries))
        }
        WireRequest::WorkListByOwner { owner } => {
            let entries = srv.list_works_by_owner(owner).into_iter().map(|(work_id, owner, revision_count, is_grabbed)| {
                super::protocol::WorkListEntry { work_id, owner, revision_count, is_grabbed }
            }).collect();
            Ok(ResponseValue::WorkList(entries))
        }

        WireRequest::LinkCreate { origin, destination, origin_ref, destination_ref } => {
            let o_ref = origin_ref.map(|hr| {
                crate::edition::links::HyperRef::single(None, hr.work_context, hr.original_context, None)
            });
            let d_ref = destination_ref.map(|hr| {
                crate::edition::links::HyperRef::single(None, hr.work_context, hr.original_context, None)
            });
            let link_id = srv.create_link(session_id, origin, destination, o_ref, d_ref)?;
            Ok(ResponseValue::Id(link_id))
        }
        WireRequest::LinkGet { link_id } => {
            let (origin, destination, link) = srv.get_link(link_id)?;
            let o_ref = link.end_at("LeftEnd").map(super::protocol::HyperRefPayload::from_hyper_ref);
            let d_ref = link.end_at("RightEnd").map(super::protocol::HyperRefPayload::from_hyper_ref);
            Ok(ResponseValue::LinkInfo(super::protocol::LinkPayload {
                link_id, origin, destination, origin_ref: o_ref, destination_ref: d_ref,
            }))
        }
        WireRequest::LinkUpdate { link_id, origin_ref, destination_ref } => {
            let o_ref = origin_ref.map(|hr| {
                crate::edition::links::HyperRef::single(None, hr.work_context, hr.original_context, None)
            });
            let d_ref = destination_ref.map(|hr| {
                crate::edition::links::HyperRef::single(None, hr.work_context, hr.original_context, None)
            });
            srv.update_link(session_id, link_id, o_ref, d_ref)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::LinkDelete { link_id } => {
            srv.delete_link(session_id, link_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::LinkListForWork { work_id } => {
            let links = srv.list_links_for_work(work_id).into_iter().map(|(link_id, origin, destination)| {
                super::protocol::LinkPayload {
                    link_id, origin, destination,
                    origin_ref: None,
                    destination_ref: None,
                }
            }).collect();
            Ok(ResponseValue::LinkList(links))
        }

        WireRequest::FindTranscluders { content_be_id } => {
            let results = srv.find_transcluders(content_be_id).into_iter().map(|(element_type, element_id, is_direct)| {
                super::protocol::TransclusionResultPayload { element_type, element_id, is_direct }
            }).collect();
            Ok(ResponseValue::TransclusionResults(results))
        }
        WireRequest::FindWorksForContent { content_be_id } => {
            let work_ids = srv.find_works_for_content(content_be_id);
            Ok(ResponseValue::WorkIds(work_ids))
        }
    }
}
