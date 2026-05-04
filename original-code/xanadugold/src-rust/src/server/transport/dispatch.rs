use crate::edition::{BeId, Edition};
use crate::server::Server;
use crate::server::lock::LockCredential;
use crate::server::lock::{BooLock, ChallengeLock, MatchLockSmith, LockSmith};
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
                    let smith = MatchLockSmith::from_password(pw)
                        .map_err(|e| crate::server::ServerError::Internal(e.to_string()))?;
                    smith.create_lock(Some(club_id))
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
        WireRequest::WorkReviseDelta { work_id, base_revision, ops } => {
            use super::protocol::apply_text_delta;
            let current_ed = srv.work_edition(work_id)?;
            let current_rev = srv.work_revision_count(work_id)?;
            if current_rev != base_revision {
                return Ok(ResponseValue::Edition(EditionPayload::from_edition(&current_ed)));
            }
            let current_text = edition_to_text(&current_ed);
            let new_text = apply_text_delta(&current_text, &ops);
            let new_ed = Edition::from_text(&new_text);
            let rev = srv.work_revise(session_id, work_id, new_ed)?;
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
            srv.ensure_logged_in(session_id)?;
            srv.work_sponsor(work_id, club_id)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkUnsponsor { work_id, club_id } => {
            srv.ensure_logged_in(session_id)?;
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
            srv.ensure_admin(session_id)?;
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
            srv.ensure_logged_in(session_id)?;
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
            let entries = srv.list_works_with_titles().into_iter().map(|(work_id, owner, revision_count, is_grabbed, title)| {
                super::protocol::WorkListEntry { work_id, owner, revision_count, is_grabbed, title }
            }).collect();
            Ok(ResponseValue::WorkList(entries))
        }
        WireRequest::WorkListByOwner { owner } => {
            let entries = srv.list_works_by_owner(owner).into_iter().map(|(work_id, owner, revision_count, is_grabbed)| {
                super::protocol::WorkListEntry { work_id, owner, revision_count, is_grabbed, title: String::new() }
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
        WireRequest::FindTextTranscluders { text } => {
            let results = srv.find_text_transcluders(&text);
            let payloads = results.into_iter().map(|(work_id, owner, revision_count, matches)| {
                super::protocol::TextTransclusionResultPayload {
                    work_id,
                    owner,
                    revision_count,
                    matches: matches.into_iter().map(|(start, end)| {
                        super::protocol::TextMatchPayload { start, end }
                    }).collect(),
                }
            }).collect();
            Ok(ResponseValue::TextTransclusionResults(payloads))
        }
        WireRequest::FindSharedRegions { work_a, work_b, filter_text } => {
            let results = srv.find_shared_regions(work_a, work_b);
            let filtered: Vec<_> = match &filter_text {
                Some(ft) => results.into_iter().filter(|(_, _, _, _, text)| text.contains(ft.as_str())).collect(),
                None => results,
            };
            let payloads = filtered.into_iter().map(|(start_a, end_a, start_b, end_b, text)| {
                super::protocol::SharedRegionPayload { work_id: work_b, start_a, end_a, start_b, end_b, text }
            }).collect();
            Ok(ResponseValue::SharedRegions(payloads))
        }

        WireRequest::BlobUpload { data, mime_type } => {
            let raw_data = crate::edition::base64_decode(&data)
                .ok_or_else(|| crate::server::ServerError::InvalidArgument("invalid base64 data".to_string()))?;
            let meta = srv.blob_upload(session_id, raw_data, mime_type)?;
            Ok(ResponseValue::BlobMeta(super::protocol::BlobMetaPayload::from_blob_meta(&meta)))
        }
        WireRequest::BlobGet { content_hash } => {
            let data = srv.blob_get(content_hash)?;
            Ok(ResponseValue::BlobData(data))
        }
        WireRequest::BlobGetPreview { content_hash } => {
            match srv.blob_preview(content_hash)? {
                Some(data) => Ok(ResponseValue::BlobData(data)),
                None => Ok(ResponseValue::Void),
            }
        }
        WireRequest::BlobExists { content_hash } => {
            Ok(ResponseValue::Boolean(srv.blob_exists(content_hash)))
        }
        WireRequest::BlobInfo { content_hash } => {
            let meta = srv.blob_info(content_hash)?;
            Ok(ResponseValue::BlobMeta(super::protocol::BlobMetaPayload::from_blob_meta(&meta)))
        }
        WireRequest::BlobStats => {
            let (total_blobs, total_bytes) = srv.blob_stats();
            Ok(ResponseValue::BlobStatsInfo(super::protocol::BlobStatsPayload {
                total_blobs,
                total_bytes,
            }))
        }

        WireRequest::OverlayApply { base_hash, ops, mime_type } => {
            let meta = srv.blob_apply_overlay(session_id, base_hash, ops, mime_type)?;
            Ok(ResponseValue::BlobMeta(super::protocol::BlobMetaPayload::from_blob_meta(&meta)))
        }
        WireRequest::OverlayGet { overlay_hash } => {
            let overlay = srv.blob_get_overlay(overlay_hash)?;
            Ok(ResponseValue::OverlayInfo(super::protocol::OverlayPayload {
                overlay_hash,
                base_hash: overlay.base_hash,
                operations: overlay.operations,
                mime_type: overlay.mime_type,
            }))
        }

        WireRequest::LabelCreate => {
            let label_id = srv.create_label();
            Ok(ResponseValue::LabelInfo { label_id })
        }
        WireRequest::LabelGetPositions { work_id, label_id } => {
            let positions = srv.label_get_positions(work_id, label_id)?;
            Ok(ResponseValue::LabelPositions { label_id, positions })
        }
        WireRequest::EditionRelabel { work_id, label_id } => {
            let _ed = srv.edition_relabel(work_id, label_id)?;
            Ok(ResponseValue::LabelInfo { label_id })
        }
        WireRequest::EditionRebind { work_id, position, new_edition } => {
            let ed = new_edition.to_edition();
            let updated = srv.edition_rebind(session_id, work_id, position, ed)?;
            Ok(ResponseValue::Edition(EditionPayload::from_edition(&updated)))
        }
        WireRequest::CanMakeIdentical { source_work_id, target_work_id, position } => {
            let results = srv.can_make_identical_elements(source_work_id, target_work_id, position)?;
            let all_yes = !results.is_empty() && results.iter().all(|(_, r)| r == "yes");
            let any_yes = results.iter().any(|(_, r)| r == "yes");
            Ok(ResponseValue::CanMakeIdenticalResult {
                result: if results.is_empty() { "no_positions".to_string() }
                        else if all_yes { "yes".to_string() }
                        else if any_yes { "partial".to_string() }
                        else { "no".to_string() },
            })
        }
        WireRequest::MakeRangeIdentical { source_work_id, target_work_id, region } => {
            let (outcome, failed_count, failed_ed) = srv.make_range_identical_editions(session_id, source_work_id, target_work_id, region)?;
            Ok(ResponseValue::MakeRangeIdenticalResult {
                outcome,
                failed_count,
                failed: EditionPayload::from_edition(&failed_ed),
            })
        }
        WireRequest::IdentityUnify { source_id, target_id } => {
            srv.ensure_admin(session_id)?;
            srv.identity_unify(source_id, target_id);
            Ok(ResponseValue::IdentityResolveResult { resolved_id: target_id })
        }
        WireRequest::IdentityResolve { id } => {
            let resolved = srv.identity_resolve(id);
            Ok(ResponseValue::IdentityResolveResult { resolved_id: resolved })
        }
        WireRequest::EditionRetrieve { work_id, region, flags } => {
            use crate::edition::{RetrieveFlags, Bundle};
            use super::protocol::{BundlePayload, RetrieveFlagsPayload};
            let rf = match flags {
                Some(f) => RetrieveFlags {
                    ignore_total_ordering: f.ignore_total_ordering.unwrap_or(false),
                    ignore_array_ordering: f.ignore_array_ordering.unwrap_or(false),
                    separate_owners: f.separate_owners.unwrap_or(false),
                },
                None => RetrieveFlags::default(),
            };
            let bundles = srv.edition_retrieve(work_id, region.as_ref(), rf)?;
            let payloads: Vec<BundlePayload> = bundles.iter()
                .map(BundlePayload::from_bundle)
                .collect();
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
            let region = srv.content_shared_region(work_a, work_b)?;
            Ok(ResponseValue::SharedRegionResult { region })
        }
        WireRequest::ContentMapSharedTo { work_a, work_b } => {
            let mapping = srv.content_map_shared_to(work_a, work_b)?;
            Ok(ResponseValue::SharedMappingResult { pairs: mapping.pairs().to_vec() })
        }
        WireRequest::ContentMapSharedOnto { work_a, work_b } => {
            let mapping = srv.content_map_shared_onto(work_a, work_b)?;
            Ok(ResponseValue::SharedMappingResult { pairs: mapping.pairs().to_vec() })
        }
        WireRequest::PositionsOf { work_id, element } => {
            let region = srv.positions_of(work_id, &element)?;
            Ok(ResponseValue::PositionsOfResult { region })
        }
        WireRequest::RangeTranscluders { work_id, region, direct_only } => {
            let result = srv.range_transcluders(work_id, region.as_ref(), direct_only.unwrap_or(false))?;
            Ok(ResponseValue::RangeTranscludersResult {
                edition_ids: result.edition_ids,
                work_ids: result.work_ids,
                region: result.region,
            })
        }
        WireRequest::RangeWorks { work_id, region } => {
            let result = srv.range_works(work_id, region.as_ref())?;
            Ok(ResponseValue::RangeWorksResult {
                work_ids: result.work_ids,
                region: result.region,
            })
        }
        WireRequest::OrderedBundles { work_id, region } => {
            let bundles = srv.ordered_bundles(work_id, region.as_ref())?;
            let payloads: Vec<BundlePayload> = bundles.iter()
                .map(BundlePayload::from_bundle)
                .collect();
            Ok(ResponseValue::OrderedBundlesResult { bundles: payloads })
        }
        WireRequest::TransclusionDepth { work_id, position, max_depth } => {
            let depth = srv.transclusion_depth(work_id, position, max_depth.unwrap_or(10))?;
            Ok(ResponseValue::TransclusionDepthResult { depth })
        }
        WireRequest::AdminRecorderCreate { kind, direct_only, region } => {
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
            };
            let id = srv.recorder_create(query)?;
            Ok(ResponseValue::RecorderCreateResult { recorder_id: id })
        }
        WireRequest::AdminRecorderRecord { recorder_id, element } => {
            srv.ensure_admin(session_id)?;
            let recorded = srv.recorder_record(recorder_id, &element)?;
            Ok(ResponseValue::RecorderRecordResult { recorded })
        }
        WireRequest::AdminRecorderList => {
            srv.ensure_admin(session_id)?;
            let recorders = srv.recorder_list().into_iter().map(|f| {
                super::protocol::RecorderInfoPayload {
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
                }
            }).collect();
            Ok(ResponseValue::RecorderListResult { recorders })
        }
        WireRequest::AdminRecorderGet { recorder_id } => {
            srv.ensure_admin(session_id)?;
            let info = srv.recorder_get(recorder_id).map(|f| {
                super::protocol::RecorderInfoPayload {
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
                }
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
            let entries = history.entries.iter().map(|e| {
                super::protocol::KeyHistoryEntryPayload {
                    key_id: e.key_id,
                    not_before: e.not_before,
                    not_after: e.not_after,
                }
            }).collect();
            Ok(ResponseValue::CryptoKeyHistoryResult {
                server_id: history.server_id.clone(),
                current_key_id: history.current_key_id,
                entry_count: history.entry_count(),
                entries,
            })
        }
        WireRequest::WorkEndorse { work_id, endorsements } => {
            let es = crate::edition::EndorsementSet::from_endorsements(
                endorsements.iter().map(|&(c, t)| crate::edition::Endorsement::new(c, t)).collect()
            );
            srv.work_endorse(session_id, work_id, es)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkRetract { work_id, endorsements } => {
            let es = crate::edition::EndorsementSet::from_endorsements(
                endorsements.iter().map(|&(c, t)| crate::edition::Endorsement::new(c, t)).collect()
            );
            srv.work_retract(session_id, work_id, es)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::WorkEndorsements { work_id } => {
            let es = srv.work_endorsements(work_id)?;
            Ok(ResponseValue::EndorsementResult {
                endorsements: es.iter().map(|e| (e.club_id(), e.token_id())).collect(),
            })
        }
        WireRequest::EditionEndorse { edition_id, endorsements } => {
            let es = crate::edition::EndorsementSet::from_endorsements(
                endorsements.iter().map(|&(c, t)| crate::edition::Endorsement::new(c, t)).collect()
            );
            srv.edition_endorse(session_id, edition_id, es)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::EditionRetract { edition_id, endorsements } => {
            let es = crate::edition::EndorsementSet::from_endorsements(
                endorsements.iter().map(|&(c, t)| crate::edition::Endorsement::new(c, t)).collect()
            );
            srv.edition_retract(session_id, edition_id, es)?;
            Ok(ResponseValue::Void)
        }
        WireRequest::EditionEndorsements { edition_id } => {
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
                peers: info.peers.into_iter().map(|p| {
                    super::protocol::FederationPeerPayload {
                        server_id: p.server_id,
                        address: p.address.to_string(),
                        connected: p.connected,
                    }
                }).collect(),
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
        WireRequest::FederatedTransclusionQuery { content_fingerprint_hex, direct_only } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
            }
            let results = srv.federation_query_local_transclusion(&content_fingerprint_hex, direct_only);
            Ok(ResponseValue::FederatedTransclusionResult {
                results,
            })
        }
        WireRequest::FederatedContentFetch { content_fingerprint_hex } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
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
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
            }
            srv.ensure_logged_in(session_id)?;
            let entries = srv.reconcile_export_endorsements();
            let matches: Vec<(u64, u64, String)> = entries
                .into_iter()
                .filter(|(fp, _)| fp == &work_fingerprint)
                .flat_map(|(_, orset)| {
                    let vals: Vec<(u64, u64, String)> = orset.values()
                        .into_iter()
                        .map(|e| (e.club_id, e.token_id, e.origin_server_id.clone()))
                        .collect();
                    vals
                })
                .collect();
            let tombstones: Vec<(u64, u64, String)> = srv.reconcile_get(&work_fingerprint)
                .map(|state| {
                    let (adds, tombs) = state.endorsements.to_entries();
                    let _ = adds;
                    tombs.iter()
                        .map(|e| (e.value.club_id, e.value.token_id, e.value.origin_server_id.clone()))
                        .collect()
                })
                .unwrap_or_default();
            Ok(ResponseValue::EndorsementSyncResult { endorsements: matches, tombstones })
        }
        WireRequest::EndorsementAdd { work_fingerprint, club_id, token_id } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
            }
            srv.ensure_logged_in(session_id)?;
            let tag = srv.reconcile_next_tag();
            let tag_server_id = tag.server_id.clone();
            let tag_counter = tag.counter;
            srv.reconcile_endorse(&work_fingerprint, club_id, token_id, tag);
            Ok(ResponseValue::EndorsementAddResult { tag_server_id, tag_counter })
        }
        WireRequest::EndorsementRetract { work_fingerprint, club_id, token_id } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
            }
            srv.ensure_logged_in(session_id)?;
            srv.reconcile_retract(&work_fingerprint, club_id, token_id);
            Ok(ResponseValue::EndorsementRetractResult {})
        }
        WireRequest::EndorsementQuery { work_fingerprint } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
            }
            srv.ensure_logged_in(session_id)?;
            let (matches, tombstones) = match srv.reconcile_get(&work_fingerprint) {
                Some(state) => {
                    let active: Vec<(u64, u64, String)> = state.endorsements.values()
                        .into_iter()
                        .map(|e| (e.club_id, e.token_id, e.origin_server_id.clone()))
                        .collect();
                    let (_, tombs) = state.endorsements.to_entries();
                    let tomb_vals: Vec<(u64, u64, String)> = tombs.iter()
                        .map(|e| (e.value.club_id, e.value.token_id, e.value.origin_server_id.clone()))
                        .collect();
                    (active, tomb_vals)
                }
                None => (Vec::new(), Vec::new()),
            };
            Ok(ResponseValue::EndorsementQueryResult { endorsements: matches, tombstones })
        }
        WireRequest::StateSync { work_fingerprints } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
            }
            srv.ensure_logged_in(session_id)?;
            let states: Vec<crate::server::federation::ReconcileState> = srv.reconcile_export_all()
                .into_iter()
                .filter(|s| work_fingerprints.is_empty() || work_fingerprints.contains(&s.work_fingerprint))
                .collect();
            Ok(ResponseValue::StateSyncResult { states })
        }
        WireRequest::StateAlternatives { work_fingerprint } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
            }
            srv.ensure_logged_in(session_id)?;
            let alternatives = srv.reconcile_alternatives(&work_fingerprint);
            let current_key = srv.reconcile_get(&work_fingerprint)
                .map(|s| s.current.value().clone())
                .unwrap_or_default();
            Ok(ResponseValue::StateAlternativesResult { alternatives, current_key })
        }

        WireRequest::MembershipJoinRequest { entry } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
            }
            srv.ensure_logged_in(session_id)?;
            let result = srv.membership_process_join(entry);
            Ok(ResponseValue::MembershipJoinResult { result })
        }

        WireRequest::MembershipEndorseOffer { server_id, proof } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
            }
            srv.ensure_logged_in(session_id)?;
            let accepted = srv.membership_endorse(&server_id, proof);
            Ok(ResponseValue::MembershipEndorseOfferResult { accepted })
        }

        WireRequest::MembershipEndorseAccept { server_id } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
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
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
            }
            srv.ensure_logged_in(session_id)?;
            let members = srv.membership_list();
            Ok(ResponseValue::MembershipSyncResult { members })
        }

        WireRequest::MembershipLeave => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
            }
            srv.ensure_admin(session_id)?;
            srv.membership_leave();
            Ok(ResponseValue::MembershipLeaveResult {})
        }

        WireRequest::MembershipList => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
            }
            srv.ensure_logged_in(session_id)?;
            let members = srv.membership_list();
            Ok(ResponseValue::MembershipListResult { members })
        }

        WireRequest::MembershipVerify { server_id } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
            }
            srv.ensure_logged_in(session_id)?;
            let verify = srv.membership_verify(&server_id);
            Ok(ResponseValue::MembershipVerifyResult { verify })
        }

        WireRequest::GovernancePropose { transactions } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
            }
            srv.ensure_admin(session_id)?;
            let proposal = srv.governance_propose(transactions);
            Ok(ResponseValue::GovernanceProposeResult { proposal })
        }

        WireRequest::GovernancePrepare { vote } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
            }
            srv.ensure_logged_in(session_id)?;
            let phase = srv.governance_receive_prepare(vote);
            Ok(ResponseValue::GovernancePrepareResult { phase: format!("{:?}", phase) })
        }

        WireRequest::GovernanceCommit { vote } => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
            }
            srv.ensure_logged_in(session_id)?;
            let phase = srv.governance_receive_commit(vote);
            Ok(ResponseValue::GovernanceCommitResult { phase: format!("{:?}", phase) })
        }

        WireRequest::GovernanceSeal => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
            }
            srv.ensure_admin(session_id)?;
            let batch = srv.governance_seal_round();
            Ok(ResponseValue::GovernanceSealResult { batch })
        }

        WireRequest::GovernanceLog => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
            }
            srv.ensure_logged_in(session_id)?;
            let log = srv.governance_log().to_vec();
            Ok(ResponseValue::GovernanceLogResult { log })
        }

        WireRequest::GovernanceStatus => {
            if !srv.federation_is_enabled() {
                return Err(crate::server::ServerError::InvalidArgument("federation not enabled".into()));
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
    }
}

fn edition_to_text(edition: &Edition) -> String {
    edition
        .all_entries()
        .iter()
        .map(|(_, carrier)| carrier.element.as_text().unwrap_or(""))
        .collect()
}
