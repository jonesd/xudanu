/* Copyright Xanadu Operating Company.  All Rights Reserved. */

/******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
***************************************************************************
Output from Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989
*/

#ifndef HANDLRSX_HXX
#define HANDLRSX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef HANDLRSX_OXX
#include "handlrsx.oxx"
#endif /* HANDLRSX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef CROSSX_OXX
#include "crossx.oxx"
#endif /* CROSSX_OXX */

#ifndef FILTERX_OXX
#include "filterx.oxx"
#endif /* FILTERX_OXX */

#ifndef IDX_OXX
#include "idx.oxx"
#endif /* IDX_OXX */

#ifndef INTEGERX_OXX
#include "integerx.oxx"
#endif /* INTEGERX_OXX */

#ifndef NADMINX_OXX
#include "nadminx.oxx"
#endif /* NADMINX_OXX */

#ifndef NKERNELX_OXX
#include "nkernelx.oxx"
#endif /* NKERNELX_OXX */

#ifndef NLINKSX_OXX
#include "nlinksx.oxx"
#endif /* NLINKSX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef PRIMVALX_OXX
#include "primvalx.oxx"
#endif /* PRIMVALX_OXX */

#ifndef PROMANX_OXX
#include "promanx.oxx"
#endif /* PROMANX_OXX */

#ifndef REALX_OXX
#include "realx.oxx"
#endif /* REALX_OXX */

#ifndef SEQUENCX_OXX
#include "sequencx.oxx"
#endif /* SEQUENCX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */

#ifndef SYSADMX_OXX
#include "sysadmx.oxx"
#endif /* SYSADMX_OXX */

#ifndef WRAPPERX_OXX
#include "wrapperx.oxx"
#endif /* WRAPPERX_OXX */


/*  */
/*  */
typedef void (*VHHFn) (APTR(Heaper), APTR(Heaper));
typedef void (*VHHHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef void (*VHFn) (APTR(Heaper));
typedef void (*VHHHHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef void (*VHHHHHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef void (*VHBFn) (APTR(Heaper), BooleanVar);
typedef SPTR(Heaper) (*HFn) ();
typedef SPTR(Heaper) (*HHFn) (APTR(Heaper));
typedef SPTR(Heaper) (*HHHFn) (APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HHHHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HHHHHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HHHHHHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HHHHHHHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef BooleanVar (*BHHFn) (APTR(Heaper), APTR(Heaper));
typedef BooleanVar (*BHFn) (APTR(Heaper));
typedef SPTR(Heaper) (*HHBFn) (APTR(Heaper), BooleanVar);
typedef SPTR(Heaper) (*HHHBFn) (APTR(Heaper), APTR(Heaper), BooleanVar);
typedef BooleanVar (*BHHHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper));




/* ************************************************************************ *
 * 
 *                    Class RequestHandler 
 *
 * ************************************************************************ */




	/* A class for each abstract signature.  Each instance will 
	wrap a pointer to a static member function. */

class RequestHandler : public Heaper {

/* Attributes for class RequestHandler */
	DEFERRED(RequestHandler)
	NO_GC(RequestHandler)
  public: /* translate: generated */

	
	static void Adminer_acceptConnections_N2 (APTR(FeAdminer) ARG(receiver), BooleanVar ARG(arg1));
	
	
	static RPTR(Stepper) Adminer_activeSessions_N1 (APTR(FeAdminer) ARG(receiver));
	
	
	static void Adminer_execute_N2 (APTR(FeAdminer) ARG(receiver), APTR(PrimIntArray) ARG(arg1));
	
	
	static RPTR(FeLockSmith) Adminer_gateLockSmith_N1 (APTR(FeAdminer) ARG(receiver));
	
	
	static void Adminer_grant_N3 (
			APTR(FeAdminer) ARG(receiver), 
			APTR(ID) ARG(arg1), 
			APTR(IDRegion) ARG(arg2))
	;
	
	
	static RPTR(TableStepper) Adminer_grants_N1 (APTR(FeAdminer) ARG(receiver));
	
	
	static RPTR(TableStepper) Adminer_grants_N2 (APTR(FeAdminer) ARG(receiver), APTR(IDRegion) ARG(arg1));
	
	
	static RPTR(TableStepper) Adminer_grants_N3 (
			APTR(FeAdminer) ARG(receiver), 
			APTR(IDRegion) ARG(arg1), 
			APTR(IDRegion) ARG(arg2))
	;
	
	
	static BooleanVar Adminer_isAcceptingConnections_N1 (APTR(FeAdminer) ARG(receiver));
	
	
	static RPTR(FeAdminer) Adminer_make_N0 ();
	
	
	static void Adminer_setGateLockSmith_N2 (APTR(FeAdminer) ARG(receiver), APTR(FeLockSmith) ARG(arg1));
	
	
	static RPTR(FeEdition) Archiver_archive_N3 (
			APTR(FeArchiver) ARG(receiver), 
			APTR(FeEdition) ARG(arg1), 
			APTR(FeEdition) ARG(arg2))
	;
	
	
	static RPTR(FeArchiver) Archiver_make_N0 ();
	
	
	static void Archiver_markArchived_N2 (APTR(FeArchiver) ARG(receiver), APTR(FeEdition) ARG(arg1));
	
	
	static RPTR(FeEdition) Archiver_restore_N3 (
			APTR(FeArchiver) ARG(receiver), 
			APTR(FeEdition) ARG(arg1), 
			APTR(FeEdition) ARG(arg2))
	;
	
	
	static RPTR(PrimArray) Array_copy_N1 (APTR(PrimArray) ARG(receiver));
	
	
	static RPTR(PrimArray) Array_copy_N2 (APTR(PrimArray) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PrimArray) Array_copy_N3 (
			APTR(PrimArray) ARG(receiver), 
			APTR(PrimIntValue) ARG(arg1), 
			APTR(PrimIntValue) ARG(arg2))
	;
	
	
	static RPTR(PrimArray) Array_copy_N4 (
			APTR(PrimArray) ARG(receiver), 
			APTR(PrimIntValue) ARG(arg1), 
			APTR(PrimIntValue) ARG(arg2), 
			APTR(PrimIntValue) ARG(arg3))
	;
	
	
	static RPTR(PrimArray) Array_copy_N5 (
			APTR(PrimArray) ARG(receiver), 
			APTR(PrimIntValue) ARG(arg1), 
			APTR(PrimIntValue) ARG(arg2), 
			APTR(PrimIntValue) ARG(arg3), 
			APTR(PrimIntValue) ARG(arg4))
	;
	
	
	static RPTR(PrimIntValue) Array_count_N1 (APTR(PrimArray) ARG(receiver));
	
	
	static RPTR(Heaper) Array_get_N2 (APTR(PrimArray) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static void Array_store_N3 (
			APTR(PrimArray) ARG(receiver), 
			APTR(PrimIntValue) ARG(arg1), 
			APTR(Heaper) ARG(arg2))
	;
	
	
	static void Array_storeAll_N1 (APTR(PrimArray) ARG(receiver));
	
	
	static void Array_storeAll_N2 (APTR(PrimArray) ARG(receiver), APTR(Heaper) ARG(arg1));
	
	
	static void Array_storeAll_N3 (
			APTR(PrimArray) ARG(receiver), 
			APTR(Heaper) ARG(arg1), 
			APTR(PrimIntValue) ARG(arg2))
	;
	
	
	static void Array_storeAll_N4 (
			APTR(PrimArray) ARG(receiver), 
			APTR(Heaper) ARG(arg1), 
			APTR(PrimIntValue) ARG(arg2), 
			APTR(PrimIntValue) ARG(arg3))
	;
	
	
	static void Array_storeMany_N3 (
			APTR(PrimArray) ARG(receiver), 
			APTR(PrimIntValue) ARG(arg1), 
			APTR(PrimArray) ARG(arg2))
	;
	
	
	static void Array_storeMany_N4 (
			APTR(PrimArray) ARG(receiver), 
			APTR(PrimIntValue) ARG(arg1), 
			APTR(PrimArray) ARG(arg2), 
			APTR(PrimIntValue) ARG(arg3))
	;
	
	
	static void Array_storeMany_N5 (
			APTR(PrimArray) ARG(receiver), 
			APTR(PrimIntValue) ARG(arg1), 
			APTR(PrimArray) ARG(arg2), 
			APTR(PrimIntValue) ARG(arg3), 
			APTR(PrimIntValue) ARG(arg4))
	;
	
	
	static RPTR(PrimArray) ArrayBundle_array_N1 (APTR(FeArrayBundle) ARG(receiver));
	
	
	static RPTR(OrderSpec) ArrayBundle_ordering_N1 (APTR(FeArrayBundle) ARG(receiver));
	
	
	static RPTR(FeKeyMaster) BooLock_boo_N1 (APTR(BooLock) ARG(receiver));
	
	
	static RPTR(FeBooLockSmith) BooLockSmith_make_N0 ();
	
	
	static RPTR(XnRegion) Bundle_region_N1 (APTR(FeBundle) ARG(receiver));
	
	
	static RPTR(PrimIntArray) ChallengeLock_challenge_N1 (APTR(ChallengeLock) ARG(receiver));
	
	
	static RPTR(FeKeyMaster) ChallengeLock_response_N2 (APTR(ChallengeLock) ARG(receiver), APTR(PrimIntArray) ARG(arg1));
	
	
	static RPTR(PrimIntArray) ChallengeLockSmith_encrypterName_N1 (APTR(FeChallengeLockSmith) ARG(receiver));
	
	
	static RPTR(FeChallengeLockSmith) ChallengeLockSmith_make_N2 (APTR(PrimIntArray) ARG(arg1), APTR(Sequence) ARG(arg2));
	
	
	static RPTR(PrimIntArray) ChallengeLockSmith_publicKey_N1 (APTR(FeChallengeLockSmith) ARG(receiver));
	
	
	static RPTR(FeClub) Club_make_N1 (APTR(FeEdition) ARG(arg1));
	
	
	static void Club_removeSignatureClub_N1 (APTR(FeClub) ARG(receiver));
	
	
	static void Club_setSignatureClub_N2 (APTR(FeClub) ARG(receiver), APTR(ID) ARG(arg1));
	
	
	static RPTR(ID) Club_signatureClub_N1 (APTR(FeClub) ARG(receiver));
	
	
	static RPTR(FeEdition) Club_sponsoredWorks_N1 (APTR(FeClub) ARG(receiver));
	
	
	static RPTR(FeEdition) Club_sponsoredWorks_N2 (APTR(FeClub) ARG(receiver), APTR(Filter) ARG(arg1));
	
	
	static RPTR(FeLockSmith) ClubDescription_lockSmith_N1 (APTR(FeClubDescription) ARG(receiver));
	
	
	static RPTR(FeClubDescription) ClubDescription_make_N2 (APTR(FeSet) ARG(arg1), APTR(FeLockSmith) ARG(arg2));
	
	
	static RPTR(FeSet) ClubDescription_membership_N1 (APTR(FeClubDescription) ARG(receiver));
	
	
	static RPTR(FeClubDescription) ClubDescription_withLockSmith_N2 (APTR(FeClubDescription) ARG(receiver), APTR(FeLockSmith) ARG(arg1));
	
	
	static RPTR(FeClubDescription) ClubDescription_withMembership_N2 (APTR(FeClubDescription) ARG(receiver), APTR(FeSet) ARG(arg1));
	
	
	static RPTR(OrderSpec) CoordinateSpace_ascending_N1 (APTR(CoordinateSpace) ARG(receiver));
	
	
	static RPTR(Mapping) CoordinateSpace_completeMapping_N2 (APTR(CoordinateSpace) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static RPTR(OrderSpec) CoordinateSpace_descending_N1 (APTR(CoordinateSpace) ARG(receiver));
	
	
	static RPTR(XnRegion) CoordinateSpace_emptyRegion_N1 (APTR(CoordinateSpace) ARG(receiver));
	
	
	static RPTR(XnRegion) CoordinateSpace_fullRegion_N1 (APTR(CoordinateSpace) ARG(receiver));
	
	
	static RPTR(Mapping) CoordinateSpace_identityMapping_N1 (APTR(CoordinateSpace) ARG(receiver));
	
	
	static RPTR(Mapping) CrossMapping_subMapping_N2 (APTR(CrossMapping) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PtrArray) CrossMapping_subMappings_N1 (APTR(CrossMapping) ARG(receiver));
	
	
	static RPTR(PrimIntArray) CrossOrderSpec_lexOrder_N1 (APTR(CrossOrderSpec) ARG(receiver));
	
	
	static RPTR(OrderSpec) CrossOrderSpec_subOrder_N2 (APTR(CrossOrderSpec) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PtrArray) CrossOrderSpec_subOrders_N1 (APTR(CrossOrderSpec) ARG(receiver));
	
	
	static RPTR(Stepper) CrossRegion_boxes_N1 (APTR(CrossRegion) ARG(receiver));
	
	
	static BooleanVar CrossRegion_isBox_N1 (APTR(CrossRegion) ARG(receiver));
	
	
	static RPTR(XnRegion) CrossRegion_projection_N2 (APTR(CrossRegion) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PtrArray) CrossRegion_projections_N1 (APTR(CrossRegion) ARG(receiver));
	
	
	static RPTR(PtrArray) CrossSpace_axes_N1 (APTR(CrossSpace) ARG(receiver));
	
	
	static RPTR(CoordinateSpace) CrossSpace_axis_N2 (APTR(CrossSpace) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PrimIntValue) CrossSpace_axisCount_N1 (APTR(CrossSpace) ARG(receiver));
	
	
	static RPTR(Mapping) CrossSpace_crossOfMappings_N1 (APTR(CrossSpace) ARG(receiver));
	
	
	static RPTR(Mapping) CrossSpace_crossOfMappings_N2 (APTR(CrossSpace) ARG(receiver), APTR(PtrArray) ARG(arg1));
	
	
	static RPTR(CrossOrderSpec) CrossSpace_crossOfOrderSpecs_N1 (APTR(CrossSpace) ARG(receiver));
	
	
	static RPTR(CrossOrderSpec) CrossSpace_crossOfOrderSpecs_N2 (APTR(CrossSpace) ARG(receiver), APTR(PtrArray) ARG(arg1));
	
	
	static RPTR(CrossOrderSpec) CrossSpace_crossOfOrderSpecs_N3 (
			APTR(CrossSpace) ARG(receiver), 
			APTR(PtrArray) ARG(arg1), 
			APTR(PrimIntArray) ARG(arg2))
	;
	
	
	static RPTR(Tuple) CrossSpace_crossOfPositions_N2 (APTR(CrossSpace) ARG(receiver), APTR(PtrArray) ARG(arg1));
	
	
	static RPTR(CrossRegion) CrossSpace_crossOfRegions_N2 (APTR(CrossSpace) ARG(receiver), APTR(PtrArray) ARG(arg1));
	
	
	static RPTR(CrossRegion) CrossSpace_extrusion_N3 (
			APTR(CrossSpace) ARG(receiver), 
			APTR(PrimIntValue) ARG(arg1), 
			APTR(XnRegion) ARG(arg2))
	;
	
	
	static RPTR(CrossSpace) CrossSpace_make_N1 (APTR(PtrArray) ARG(arg1));
	
	
	static RPTR(FeDataHolder) DataHolder_make_N1 (APTR(PrimValue) ARG(arg1));
	
	
	static RPTR(PrimValue) DataHolder_value_N1 (APTR(FeDataHolder) ARG(receiver));
	
	
	static RPTR(XnRegion) Edition_canMakeRangeIdentical_N2 (APTR(FeEdition) ARG(receiver), APTR(FeEdition) ARG(arg1));
	
	
	static RPTR(XnRegion) Edition_canMakeRangeIdentical_N3 (
			APTR(FeEdition) ARG(receiver), 
			APTR(FeEdition) ARG(arg1), 
			APTR(XnRegion) ARG(arg2))
	;
	
	
	static RPTR(FeEdition) Edition_combine_N2 (APTR(FeEdition) ARG(receiver), APTR(FeEdition) ARG(arg1));
	
	
	static RPTR(CoordinateSpace) Edition_coordinateSpace_N1 (APTR(FeEdition) ARG(receiver));
	
	
	static RPTR(FeEdition) Edition_copy_N2 (APTR(FeEdition) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static RPTR(PrimIntValue) Edition_cost_N2 (APTR(FeEdition) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PrimIntValue) Edition_count_N1 (APTR(FeEdition) ARG(receiver));
	
	
	static RPTR(XnRegion) Edition_domain_N1 (APTR(FeEdition) ARG(receiver));
	
	
	static RPTR(FeEdition) Edition_empty_N1 (APTR(CoordinateSpace) ARG(arg1));
	
	
	static void Edition_endorse_N2 (APTR(FeEdition) ARG(receiver), APTR(CrossRegion) ARG(arg1));
	
	
	static RPTR(CrossRegion) Edition_endorsements_N1 (APTR(FeEdition) ARG(receiver));
	
	
	static RPTR(FeEdition) Edition_fromAll_N2 (APTR(XnRegion) ARG(arg1), APTR(FeRangeElement) ARG(arg2));
	
	
	static RPTR(FeEdition) Edition_fromArray_N1 (APTR(PrimArray) ARG(arg1));
	
	
	static RPTR(FeEdition) Edition_fromArray_N2 (APTR(PrimArray) ARG(arg1), APTR(XnRegion) ARG(arg2));
	
	
	static RPTR(FeEdition) Edition_fromArray_N3 (
			APTR(PrimArray) ARG(arg1), 
			APTR(XnRegion) ARG(arg2), 
			APTR(OrderSpec) ARG(arg3))
	;
	
	
	static RPTR(FeEdition) Edition_fromOne_N2 (APTR(Position) ARG(arg1), APTR(FeRangeElement) ARG(arg2));
	
	
	static RPTR(FeRangeElement) Edition_get_N2 (APTR(FeEdition) ARG(receiver), APTR(Position) ARG(arg1));
	
	
	static BooleanVar Edition_hasPosition_N2 (APTR(FeEdition) ARG(receiver), APTR(Position) ARG(arg1));
	
	
	static BooleanVar Edition_isEmpty_N1 (APTR(FeEdition) ARG(receiver));
	
	
	static BooleanVar Edition_isFinite_N1 (APTR(FeEdition) ARG(receiver));
	
	
	static BooleanVar Edition_isRangeIdentical_N2 (APTR(FeEdition) ARG(receiver), APTR(FeEdition) ARG(arg1));
	
	
	static RPTR(FeEdition) Edition_makeRangeIdentical_N2 (APTR(FeEdition) ARG(receiver), APTR(FeEdition) ARG(arg1));
	
	
	static RPTR(FeEdition) Edition_makeRangeIdentical_N3 (
			APTR(FeEdition) ARG(receiver), 
			APTR(FeEdition) ARG(arg1), 
			APTR(XnRegion) ARG(arg2))
	;
	
	
	static RPTR(Mapping) Edition_mapSharedOnto_N2 (APTR(FeEdition) ARG(receiver), APTR(FeEdition) ARG(arg1));
	
	
	static RPTR(Mapping) Edition_mapSharedTo_N2 (APTR(FeEdition) ARG(receiver), APTR(FeEdition) ARG(arg1));
	
	
	static RPTR(FeEdition) Edition_notSharedWith_N2 (APTR(FeEdition) ARG(receiver), APTR(FeEdition) ARG(arg1));
	
	
	static RPTR(FeEdition) Edition_notSharedWith_N3 (
			APTR(FeEdition) ARG(receiver), 
			APTR(FeEdition) ARG(arg1), 
			APTR(PrimIntValue) ARG(arg2))
	;
	
	
	static RPTR(FeEdition) Edition_placeHolders_N1 (APTR(XnRegion) ARG(arg1));
	
	
	static RPTR(XnRegion) Edition_positionsLabelled_N2 (APTR(FeEdition) ARG(receiver), APTR(FeLabel) ARG(arg1));
	
	
	static RPTR(XnRegion) Edition_positionsOf_N2 (APTR(FeEdition) ARG(receiver), APTR(FeRangeElement) ARG(arg1));
	
	
	static RPTR(IDRegion) Edition_rangeOwners_N2 (APTR(FeEdition) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static RPTR(FeEdition) Edition_rangeTranscluders_N1 (APTR(FeEdition) ARG(receiver));
	
	
	static RPTR(FeEdition) Edition_rangeTranscluders_N2 (APTR(FeEdition) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static RPTR(FeEdition) Edition_rangeTranscluders_N3 (
			APTR(FeEdition) ARG(receiver), 
			APTR(XnRegion) ARG(arg1), 
			APTR(Filter) ARG(arg2))
	;
	
	
	static RPTR(FeEdition) Edition_rangeTranscluders_N4 (
			APTR(FeEdition) ARG(receiver), 
			APTR(XnRegion) ARG(arg1), 
			APTR(Filter) ARG(arg2), 
			APTR(Filter) ARG(arg3))
	;
	
	
	static RPTR(FeEdition) Edition_rangeTranscluders_N5 (
			APTR(FeEdition) ARG(receiver), 
			APTR(XnRegion) ARG(arg1), 
			APTR(Filter) ARG(arg2), 
			APTR(Filter) ARG(arg3), 
			APTR(PrimIntValue) ARG(arg4))
	;
	
	
	static RPTR(FeEdition) Edition_rangeTranscluders_N6 (
			APTR(FeEdition) ARG(receiver), 
			APTR(XnRegion) ARG(arg1), 
			APTR(Filter) ARG(arg2), 
			APTR(Filter) ARG(arg3), 
			APTR(PrimIntValue) ARG(arg4), 
			APTR(FeEdition) ARG(arg5))
	;
	
	
	static RPTR(FeEdition) Edition_rangeWorks_N1 (APTR(FeEdition) ARG(receiver));
	
	
	static RPTR(FeEdition) Edition_rangeWorks_N2 (APTR(FeEdition) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static RPTR(FeEdition) Edition_rangeWorks_N3 (
			APTR(FeEdition) ARG(receiver), 
			APTR(XnRegion) ARG(arg1), 
			APTR(Filter) ARG(arg2))
	;
	
	
	static RPTR(FeEdition) Edition_rangeWorks_N4 (
			APTR(FeEdition) ARG(receiver), 
			APTR(XnRegion) ARG(arg1), 
			APTR(Filter) ARG(arg2), 
			APTR(PrimIntValue) ARG(arg3))
	;
	
	
	static RPTR(FeEdition) Edition_rangeWorks_N5 (
			APTR(FeEdition) ARG(receiver), 
			APTR(XnRegion) ARG(arg1), 
			APTR(Filter) ARG(arg2), 
			APTR(PrimIntValue) ARG(arg3), 
			APTR(FeEdition) ARG(arg4))
	;
	
	
	static RPTR(FeEdition) Edition_rebind_N3 (
			APTR(FeEdition) ARG(receiver), 
			APTR(Position) ARG(arg1), 
			APTR(FeEdition) ARG(arg2))
	;
	
	
	static RPTR(FeEdition) Edition_replace_N2 (APTR(FeEdition) ARG(receiver), APTR(FeEdition) ARG(arg1));
	
	
	static void Edition_retract_N2 (APTR(FeEdition) ARG(receiver), APTR(CrossRegion) ARG(arg1));
	
	
	static RPTR(Stepper) Edition_retrieve_N1 (APTR(FeEdition) ARG(receiver));
	
	
	static RPTR(Stepper) Edition_retrieve_N2 (APTR(FeEdition) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static RPTR(Stepper) Edition_retrieve_N3 (
			APTR(FeEdition) ARG(receiver), 
			APTR(XnRegion) ARG(arg1), 
			APTR(OrderSpec) ARG(arg2))
	;
	
	
	static RPTR(Stepper) Edition_retrieve_N4 (
			APTR(FeEdition) ARG(receiver), 
			APTR(XnRegion) ARG(arg1), 
			APTR(OrderSpec) ARG(arg2), 
			APTR(PrimIntValue) ARG(arg3))
	;
	
	
	static RPTR(FeEdition) Edition_setRangeOwners_N2 (APTR(FeEdition) ARG(receiver), APTR(ID) ARG(arg1));
	
	
	static RPTR(FeEdition) Edition_setRangeOwners_N3 (
			APTR(FeEdition) ARG(receiver), 
			APTR(ID) ARG(arg1), 
			APTR(XnRegion) ARG(arg2))
	;
	
	
	static RPTR(XnRegion) Edition_sharedRegion_N2 (APTR(FeEdition) ARG(receiver), APTR(FeEdition) ARG(arg1));
	
	
	static RPTR(XnRegion) Edition_sharedRegion_N3 (
			APTR(FeEdition) ARG(receiver), 
			APTR(FeEdition) ARG(arg1), 
			APTR(PrimIntValue) ARG(arg2))
	;
	
	
	static RPTR(FeEdition) Edition_sharedWith_N2 (APTR(FeEdition) ARG(receiver), APTR(FeEdition) ARG(arg1));
	
	
	static RPTR(FeEdition) Edition_sharedWith_N3 (
			APTR(FeEdition) ARG(receiver), 
			APTR(FeEdition) ARG(arg1), 
			APTR(PrimIntValue) ARG(arg2))
	;
	
	
	static RPTR(TableStepper) Edition_stepper_N1 (APTR(FeEdition) ARG(receiver));
	
	
	static RPTR(TableStepper) Edition_stepper_N2 (APTR(FeEdition) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static RPTR(TableStepper) Edition_stepper_N3 (
			APTR(FeEdition) ARG(receiver), 
			APTR(XnRegion) ARG(arg1), 
			APTR(OrderSpec) ARG(arg2))
	;
	
	
	static RPTR(FeRangeElement) Edition_theOne_N1 (APTR(FeEdition) ARG(receiver));
	
	
	static RPTR(FeEdition) Edition_transformedBy_N2 (APTR(FeEdition) ARG(receiver), APTR(Mapping) ARG(arg1));
	
	
	static RPTR(CrossRegion) Edition_visibleEndorsements_N1 (APTR(FeEdition) ARG(receiver));
	
	
	static RPTR(FeEdition) Edition_with_N3 (
			APTR(FeEdition) ARG(receiver), 
			APTR(Position) ARG(arg1), 
			APTR(FeRangeElement) ARG(arg2))
	;
	
	
	static RPTR(FeEdition) Edition_withAll_N3 (
			APTR(FeEdition) ARG(receiver), 
			APTR(XnRegion) ARG(arg1), 
			APTR(FeRangeElement) ARG(arg2))
	;
	
	
	static RPTR(FeEdition) Edition_without_N2 (APTR(FeEdition) ARG(receiver), APTR(Position) ARG(arg1));
	
	
	static RPTR(FeEdition) Edition_withoutAll_N2 (APTR(FeEdition) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static RPTR(FeRangeElement) ElementBundle_element_N1 (APTR(FeElementBundle) ARG(receiver));
	
	
	static RPTR(XnRegion) Filter_baseRegion_N1 (APTR(Filter) ARG(receiver));
	
	
	static RPTR(Stepper) Filter_intersectedFilters_N1 (APTR(Filter) ARG(receiver));
	
	
	static BooleanVar Filter_isAllFilter_N1 (APTR(Filter) ARG(receiver));
	
	
	static BooleanVar Filter_isAnyFilter_N1 (APTR(Filter) ARG(receiver));
	
	
	static BooleanVar Filter_match_N2 (APTR(Filter) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static RPTR(Stepper) Filter_unionedFilters_N1 (APTR(Filter) ARG(receiver));
	
	
	static RPTR(XnRegion) FilterPosition_baseRegion_N1 (APTR(FilterPosition) ARG(receiver));
	
	
	static RPTR(Filter) FilterSpace_allFilter_N2 (APTR(FilterSpace) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static RPTR(Filter) FilterSpace_anyFilter_N2 (APTR(FilterSpace) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static RPTR(CoordinateSpace) FilterSpace_baseSpace_N1 (APTR(FilterSpace) ARG(receiver));
	
	
	static RPTR(FilterSpace) FilterSpace_make_N1 (APTR(CoordinateSpace) ARG(arg1));
	
	
	static RPTR(FilterPosition) FilterSpace_position_N2 (APTR(FilterSpace) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static RPTR(PrimIntValue) FloatArray_bitCount_N1 (APTR(PrimFloatArray) ARG(receiver));
	
	
	static RPTR(PrimFloatArray) FloatArray_zeros_N2 (APTR(PrimIntValue) ARG(arg1), APTR(PrimIntValue) ARG(arg2));
	
	
	static RPTR(PrimIntValue) FloatValue_bitCount_N1 (APTR(PrimFloatValue) ARG(receiver));
	
	
	static RPTR(IntegerVarArray) HumberArray_zeros_N1 (APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(FeHyperRef) HyperLink_endAt_N2 (APTR(FeHyperLink) ARG(receiver), APTR(Sequence) ARG(arg1));
	
	
	static RPTR(SequenceRegion) HyperLink_endNames_N1 (APTR(FeHyperLink) ARG(receiver));
	
	
	static RPTR(FeSet) HyperLink_linkTypes_N1 (APTR(FeHyperLink) ARG(receiver));
	
	
	static RPTR(FeHyperLink) HyperLink_make_N3 (
			APTR(FeSet) ARG(arg1), 
			APTR(FeHyperRef) ARG(arg2), 
			APTR(FeHyperRef) ARG(arg3))
	;
	
	
	static RPTR(FeHyperLink) HyperLink_withEnd_N3 (
			APTR(FeHyperLink) ARG(receiver), 
			APTR(Sequence) ARG(arg1), 
			APTR(FeHyperRef) ARG(arg2))
	;
	
	
	static RPTR(FeHyperLink) HyperLink_withLinkTypes_N2 (APTR(FeHyperLink) ARG(receiver), APTR(FeSet) ARG(arg1));
	
	
	static RPTR(FeHyperLink) HyperLink_withoutEnd_N2 (APTR(FeHyperLink) ARG(receiver), APTR(Sequence) ARG(arg1));
	
	
	static RPTR(FeWork) HyperRef_originalContext_N1 (APTR(FeHyperRef) ARG(receiver));
	
	
	static RPTR(FePath) HyperRef_pathContext_N1 (APTR(FeHyperRef) ARG(receiver));
	
	
	static RPTR(FeHyperRef) HyperRef_withOriginalContext_N2 (APTR(FeHyperRef) ARG(receiver), APTR(FeWork) ARG(arg1));
	
	
	static RPTR(FeHyperRef) HyperRef_withPathContext_N2 (APTR(FeHyperRef) ARG(receiver), APTR(FePath) ARG(arg1));
	
	
	static RPTR(FeHyperRef) HyperRef_withWorkContext_N2 (APTR(FeHyperRef) ARG(receiver), APTR(FeWork) ARG(arg1));
	
	
	static RPTR(FeWork) HyperRef_workContext_N1 (APTR(FeHyperRef) ARG(receiver));
	
	
	static RPTR(PrimIntArray) ID_export_N1 (APTR(ID) ARG(receiver));
	
	
	static RPTR(ID) ID_import_N1 (APTR(PrimIntArray) ARG(arg1));
	
	
	static RPTR(ID) IDHolder_iD_N1 (APTR(FeIDHolder) ARG(receiver));
	
	
	static RPTR(FeIDHolder) IDHolder_make_N1 (APTR(ID) ARG(arg1));
	
	
	static RPTR(PrimIntArray) IDRegion_export_N1 (APTR(IDRegion) ARG(receiver));
	
	
	static RPTR(IDRegion) IDRegion_import_N1 (APTR(PrimIntArray) ARG(arg1));
	
	
	static RPTR(PrimIntArray) IDSpace_export_N1 (APTR(IDSpace) ARG(receiver));
	
	
	static RPTR(IDSpace) IDSpace_global_N0 ();
	
	
	static RPTR(IDRegion) IDSpace_iDsFromServer_N2 (APTR(IDSpace) ARG(receiver), APTR(Sequence) ARG(arg1));
	
	
	static RPTR(IDSpace) IDSpace_import_N1 (APTR(PrimIntArray) ARG(arg1));
	
	
	static RPTR(ID) IDSpace_newID_N1 (APTR(IDSpace) ARG(receiver));
	
	
	static RPTR(IDRegion) IDSpace_newIDs_N2 (APTR(IDSpace) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(IDSpace) IDSpace_unique_N0 ();
	
	
	static RPTR(PrimIntValue) IntArray_bitCount_N1 (APTR(PrimIntArray) ARG(receiver));
	
	
	static RPTR(PrimIntArray) IntArray_zeros_N2 (APTR(PrimIntValue) ARG(arg1), APTR(PrimIntValue) ARG(arg2));
	
	
	static RPTR(PrimIntValue) Integer_value_N1 (APTR(IntegerPos) ARG(receiver));
	
	
	static RPTR(PrimIntValue) IntegerMapping_translation_N1 (APTR(IntegerMapping) ARG(receiver));
	
	
	static RPTR(Stepper) IntegerRegion_intervals_N1 (APTR(IntegerRegion) ARG(receiver));
	
	
	static RPTR(Stepper) IntegerRegion_intervals_N2 (APTR(IntegerRegion) ARG(receiver), APTR(OrderSpec) ARG(arg1));
	
	
	static BooleanVar IntegerRegion_isBoundedAbove_N1 (APTR(IntegerRegion) ARG(receiver));
	
	
	static BooleanVar IntegerRegion_isBoundedBelow_N1 (APTR(IntegerRegion) ARG(receiver));
	
	
	static BooleanVar IntegerRegion_isInterval_N1 (APTR(IntegerRegion) ARG(receiver));
	
	
	static RPTR(PrimIntValue) IntegerRegion_start_N1 (APTR(IntegerRegion) ARG(receiver));
	
	
	static RPTR(PrimIntValue) IntegerRegion_stop_N1 (APTR(IntegerRegion) ARG(receiver));
	
	
	static RPTR(IntegerRegion) IntegerSpace_above_N2 (APTR(IntegerPos) ARG(arg1), BooleanVar ARG(arg2));
	
	
	static RPTR(IntegerRegion) IntegerSpace_below_N2 (APTR(IntegerPos) ARG(arg1), BooleanVar ARG(arg2));
	
	
	static RPTR(IntegerRegion) IntegerSpace_interval_N2 (APTR(IntegerPos) ARG(arg1), APTR(IntegerPos) ARG(arg2));
	
	
	static RPTR(IntegerSpace) IntegerSpace_make_N0 ();
	
	
	static RPTR(IntegerPos) IntegerSpace_position_N1 (APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(IntegerMapping) IntegerSpace_translation_N1 (APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PrimIntValue) IntValue_bitCount_N1 (APTR(PrimIntValue) ARG(receiver));
	
	
	static RPTR(PrimIntValue) IntValue_bitwiseAnd_N2 (APTR(PrimIntValue) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PrimIntValue) IntValue_bitwiseOr_N2 (APTR(PrimIntValue) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PrimIntValue) IntValue_bitwiseXor_N2 (APTR(PrimIntValue) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PrimIntValue) IntValue_dividedBy_N2 (APTR(PrimIntValue) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static BooleanVar IntValue_isGE_N2 (APTR(PrimIntValue) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PrimIntValue) IntValue_leftShift_N2 (APTR(PrimIntValue) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PrimIntValue) IntValue_maximum_N2 (APTR(PrimIntValue) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PrimIntValue) IntValue_minimum_N2 (APTR(PrimIntValue) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PrimIntValue) IntValue_minus_N2 (APTR(PrimIntValue) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PrimIntValue) IntValue_mod_N2 (APTR(PrimIntValue) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PrimIntValue) IntValue_plus_N2 (APTR(PrimIntValue) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PrimIntValue) IntValue_times_N2 (APTR(PrimIntValue) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(IDRegion) KeyMaster_actualAuthority_N1 (APTR(FeKeyMaster) ARG(receiver));
	
	
	static RPTR(FeKeyMaster) KeyMaster_copy_N1 (APTR(FeKeyMaster) ARG(receiver));
	
	
	static BooleanVar KeyMaster_hasAuthority_N2 (APTR(FeKeyMaster) ARG(receiver), APTR(ID) ARG(arg1));
	
	
	static void KeyMaster_incorporate_N2 (APTR(FeKeyMaster) ARG(receiver), APTR(FeKeyMaster) ARG(arg1));
	
	
	static RPTR(IDRegion) KeyMaster_loginAuthority_N1 (APTR(FeKeyMaster) ARG(receiver));
	
	
	static void KeyMaster_removeLogins_N2 (APTR(FeKeyMaster) ARG(receiver), APTR(IDRegion) ARG(arg1));
	
	
	static RPTR(FeLabel) Label_make_N0 ();
	
	
	static RPTR(Mapping) Mapping_combine_N2 (APTR(Mapping) ARG(receiver), APTR(Mapping) ARG(arg1));
	
	
	static RPTR(XnRegion) Mapping_domain_N1 (APTR(Mapping) ARG(receiver));
	
	
	static RPTR(CoordinateSpace) Mapping_domainSpace_N1 (APTR(Mapping) ARG(receiver));
	
	
	static RPTR(Mapping) Mapping_inverse_N1 (APTR(Mapping) ARG(receiver));
	
	
	static BooleanVar Mapping_isComplete_N1 (APTR(Mapping) ARG(receiver));
	
	
	static BooleanVar Mapping_isIdentity_N1 (APTR(Mapping) ARG(receiver));
	
	
	static RPTR(Position) Mapping_of_N2 (APTR(Mapping) ARG(receiver), APTR(Position) ARG(arg1));
	
	
	static RPTR(XnRegion) Mapping_ofAll_N2 (APTR(Mapping) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static RPTR(XnRegion) Mapping_range_N1 (APTR(Mapping) ARG(receiver));
	
	
	static RPTR(CoordinateSpace) Mapping_rangeSpace_N1 (APTR(Mapping) ARG(receiver));
	
	
	static RPTR(Mapping) Mapping_restrict_N2 (APTR(Mapping) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static RPTR(Stepper) Mapping_simplerMappings_N1 (APTR(Mapping) ARG(receiver));
	
	
	static RPTR(Mapping) Mapping_unrestricted_N1 (APTR(Mapping) ARG(receiver));
	
	
	static RPTR(FeKeyMaster) MatchLock_encryptedPassword_N2 (APTR(MatchLock) ARG(receiver), APTR(PrimIntArray) ARG(arg1));
	
	
	static RPTR(FeMatchLockSmith) MatchLockSmith_make_N2 (APTR(PrimIntArray) ARG(arg1), APTR(Sequence) ARG(arg2));
	
	
	static RPTR(PrimIntArray) MatchLockSmith_scrambledPassword_N1 (APTR(FeMatchLockSmith) ARG(receiver));
	
	
	static RPTR(PrimIntArray) MatchLockSmith_scramblerName_N1 (APTR(FeMatchLockSmith) ARG(receiver));
	
	
	static RPTR(Lock) MultiLock_lock_N2 (APTR(MultiLock) ARG(receiver), APTR(Sequence) ARG(arg1));
	
	
	static RPTR(SequenceRegion) MultiLock_lockNames_N1 (APTR(MultiLock) ARG(receiver));
	
	
	static RPTR(FeLockSmith) MultiLockSmith_lockSmith_N2 (APTR(FeMultiLockSmith) ARG(receiver), APTR(Sequence) ARG(arg1));
	
	
	static RPTR(SequenceRegion) MultiLockSmith_lockSmithNames_N1 (APTR(FeMultiLockSmith) ARG(receiver));
	
	
	static RPTR(FeMultiLockSmith) MultiLockSmith_make_N0 ();
	
	
	static RPTR(FeMultiLockSmith) MultiLockSmith_with_N3 (
			APTR(FeMultiLockSmith) ARG(receiver), 
			APTR(Sequence) ARG(arg1), 
			APTR(FeLockSmith) ARG(arg2))
	;
	
	
	static RPTR(FeMultiLockSmith) MultiLockSmith_without_N2 (APTR(FeMultiLockSmith) ARG(receiver), APTR(Sequence) ARG(arg1));
	
	
	static RPTR(FeMultiRef) MultiRef_intersect_N2 (APTR(FeMultiRef) ARG(receiver), APTR(FeMultiRef) ARG(arg1));
	
	
	static RPTR(FeMultiRef) MultiRef_make_N1 (APTR(PtrArray) ARG(arg1));
	
	
	static RPTR(FeMultiRef) MultiRef_make_N2 (APTR(PtrArray) ARG(arg1), APTR(FeWork) ARG(arg2));
	
	
	static RPTR(FeMultiRef) MultiRef_make_N3 (
			APTR(PtrArray) ARG(arg1), 
			APTR(FeWork) ARG(arg2), 
			APTR(FeWork) ARG(arg3))
	;
	
	
	static RPTR(FeMultiRef) MultiRef_make_N4 (
			APTR(PtrArray) ARG(arg1), 
			APTR(FeWork) ARG(arg2), 
			APTR(FeWork) ARG(arg3), 
			APTR(FePath) ARG(arg4))
	;
	
	
	static RPTR(FeMultiRef) MultiRef_minus_N2 (APTR(FeMultiRef) ARG(receiver), APTR(FeMultiRef) ARG(arg1));
	
	
	static RPTR(Stepper) MultiRef_refs_N1 (APTR(FeMultiRef) ARG(receiver));
	
	
	static RPTR(FeMultiRef) MultiRef_unionWith_N2 (APTR(FeMultiRef) ARG(receiver), APTR(FeMultiRef) ARG(arg1));
	
	
	static RPTR(FeMultiRef) MultiRef_with_N2 (APTR(FeMultiRef) ARG(receiver), APTR(FeHyperRef) ARG(arg1));
	
	
	static RPTR(FeMultiRef) MultiRef_without_N2 (APTR(FeMultiRef) ARG(receiver), APTR(FeHyperRef) ARG(arg1));
	
	
	static RPTR(CoordinateSpace) OrderSpec_coordinateSpace_N1 (APTR(OrderSpec) ARG(receiver));
	
	
	static BooleanVar OrderSpec_follows_N3 (
			APTR(OrderSpec) ARG(receiver), 
			APTR(Position) ARG(arg1), 
			APTR(Position) ARG(arg2))
	;
	
	
	static RPTR(OrderSpec) OrderSpec_reversed_N1 (APTR(OrderSpec) ARG(receiver));
	
	
	static RPTR(FeRangeElement) Path_follow_N2 (APTR(FePath) ARG(receiver), APTR(FeEdition) ARG(arg1));
	
	
	static RPTR(FePath) Path_make_N1 (APTR(PtrArray) ARG(arg1));
	
	
	static RPTR(XnRegion) Position_asRegion_N1 (APTR(Position) ARG(receiver));
	
	
	static RPTR(CoordinateSpace) Position_coordinateSpace_N1 (APTR(Position) ARG(receiver));
	
	
	static RPTR(PtrArray) PtrArray_nulls_N1 (APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(FeRangeElement) RangeElement_again_N1 (APTR(FeRangeElement) ARG(receiver));
	
	
	static BooleanVar RangeElement_canMakeIdentical_N2 (APTR(FeRangeElement) ARG(receiver), APTR(FeRangeElement) ARG(arg1));
	
	
	static BooleanVar RangeElement_isIdentical_N2 (APTR(FeRangeElement) ARG(receiver), APTR(FeRangeElement) ARG(arg1));
	
	
	static RPTR(FeLabel) RangeElement_label_N1 (APTR(FeRangeElement) ARG(receiver));
	
	
	static void RangeElement_makeIdentical_N2 (APTR(FeRangeElement) ARG(receiver), APTR(FeRangeElement) ARG(arg1));
	
	
	static RPTR(ID) RangeElement_owner_N1 (APTR(FeRangeElement) ARG(receiver));
	
	
	static RPTR(FeRangeElement) RangeElement_placeHolder_N0 ();
	
	
	static RPTR(FeRangeElement) RangeElement_relabelled_N2 (APTR(FeRangeElement) ARG(receiver), APTR(FeLabel) ARG(arg1));
	
	
	static void RangeElement_setOwner_N2 (APTR(FeRangeElement) ARG(receiver), APTR(ID) ARG(arg1));
	
	
	static RPTR(FeEdition) RangeElement_transcluders_N1 (APTR(FeRangeElement) ARG(receiver));
	
	
	static RPTR(FeEdition) RangeElement_transcluders_N2 (APTR(FeRangeElement) ARG(receiver), APTR(Filter) ARG(arg1));
	
	
	static RPTR(FeEdition) RangeElement_transcluders_N3 (
			APTR(FeRangeElement) ARG(receiver), 
			APTR(Filter) ARG(arg1), 
			APTR(Filter) ARG(arg2))
	;
	
	
	static RPTR(FeEdition) RangeElement_transcluders_N4 (
			APTR(FeRangeElement) ARG(receiver), 
			APTR(Filter) ARG(arg1), 
			APTR(Filter) ARG(arg2), 
			APTR(PrimIntValue) ARG(arg3))
	;
	
	
	static RPTR(FeEdition) RangeElement_transcluders_N5 (
			APTR(FeRangeElement) ARG(receiver), 
			APTR(Filter) ARG(arg1), 
			APTR(Filter) ARG(arg2), 
			APTR(PrimIntValue) ARG(arg3), 
			APTR(FeEdition) ARG(arg4))
	;
	
	
	static RPTR(FeEdition) RangeElement_works_N1 (APTR(FeRangeElement) ARG(receiver));
	
	
	static RPTR(FeEdition) RangeElement_works_N2 (APTR(FeRangeElement) ARG(receiver), APTR(Filter) ARG(arg1));
	
	
	static RPTR(FeEdition) RangeElement_works_N3 (
			APTR(FeRangeElement) ARG(receiver), 
			APTR(Filter) ARG(arg1), 
			APTR(PrimIntValue) ARG(arg2))
	;
	
	
	static RPTR(FeEdition) RangeElement_works_N4 (
			APTR(FeRangeElement) ARG(receiver), 
			APTR(Filter) ARG(arg1), 
			APTR(PrimIntValue) ARG(arg2), 
			APTR(FeEdition) ARG(arg3))
	;
	
	
	static RPTR(PrimFloatValue) Real_value_N1 (APTR(RealPos) ARG(receiver));
	
	
	static RPTR(Stepper) RealRegion_intervals_N1 (APTR(RealRegion) ARG(receiver));
	
	
	static RPTR(Stepper) RealRegion_intervals_N2 (APTR(RealRegion) ARG(receiver), APTR(OrderSpec) ARG(arg1));
	
	
	static BooleanVar RealRegion_isBoundedAbove_N1 (APTR(RealRegion) ARG(receiver));
	
	
	static BooleanVar RealRegion_isBoundedBelow_N1 (APTR(RealRegion) ARG(receiver));
	
	
	static BooleanVar RealRegion_isInterval_N1 (APTR(RealRegion) ARG(receiver));
	
	
	static RPTR(RealPos) RealRegion_lowerBound_N1 (APTR(RealRegion) ARG(receiver));
	
	
	static RPTR(RealPos) RealRegion_upperBound_N1 (APTR(RealRegion) ARG(receiver));
	
	
	static RPTR(RealRegion) RealSpace_above_N3 (
			APTR(RealSpace) ARG(receiver), 
			APTR(RealPos) ARG(arg1), 
			BooleanVar ARG(arg2))
	;
	
	
	static RPTR(RealRegion) RealSpace_below_N3 (
			APTR(RealSpace) ARG(receiver), 
			APTR(RealPos) ARG(arg1), 
			BooleanVar ARG(arg2))
	;
	
	
	static RPTR(RealRegion) RealSpace_interval_N3 (
			APTR(RealSpace) ARG(receiver), 
			APTR(RealPos) ARG(arg1), 
			APTR(RealPos) ARG(arg2))
	;
	
	
	static RPTR(RealSpace) RealSpace_make_N0 ();
	
	
	static RPTR(RealPos) RealSpace_position_N2 (APTR(RealSpace) ARG(receiver), APTR(PrimFloatValue) ARG(arg1));
	
	
	static RPTR(XnRegion) Region_chooseMany_N2 (APTR(XnRegion) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(XnRegion) Region_chooseMany_N3 (
			APTR(XnRegion) ARG(receiver), 
			APTR(PrimIntValue) ARG(arg1), 
			APTR(OrderSpec) ARG(arg2))
	;
	
	
	static RPTR(Position) Region_chooseOne_N1 (APTR(XnRegion) ARG(receiver));
	
	
	static RPTR(Position) Region_chooseOne_N2 (APTR(XnRegion) ARG(receiver), APTR(OrderSpec) ARG(arg1));
	
	
	static RPTR(XnRegion) Region_complement_N1 (APTR(XnRegion) ARG(receiver));
	
	
	static RPTR(CoordinateSpace) Region_coordinateSpace_N1 (APTR(XnRegion) ARG(receiver));
	
	
	static RPTR(PrimIntValue) Region_count_N1 (APTR(XnRegion) ARG(receiver));
	
	
	static BooleanVar Region_hasMember_N2 (APTR(XnRegion) ARG(receiver), APTR(Position) ARG(arg1));
	
	
	static RPTR(XnRegion) Region_intersect_N2 (APTR(XnRegion) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static BooleanVar Region_intersects_N2 (APTR(XnRegion) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static BooleanVar Region_isEmpty_N1 (APTR(XnRegion) ARG(receiver));
	
	
	static BooleanVar Region_isFinite_N1 (APTR(XnRegion) ARG(receiver));
	
	
	static BooleanVar Region_isFull_N1 (APTR(XnRegion) ARG(receiver));
	
	
	static BooleanVar Region_isSubsetOf_N2 (APTR(XnRegion) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static RPTR(XnRegion) Region_minus_N2 (APTR(XnRegion) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static RPTR(Stepper) Region_stepper_N1 (APTR(XnRegion) ARG(receiver));
	
	
	static RPTR(Stepper) Region_stepper_N2 (APTR(XnRegion) ARG(receiver), APTR(OrderSpec) ARG(arg1));
	
	
	static RPTR(Position) Region_theOne_N1 (APTR(XnRegion) ARG(receiver));
	
	
	static RPTR(XnRegion) Region_unionWith_N2 (APTR(XnRegion) ARG(receiver), APTR(XnRegion) ARG(arg1));
	
	
	static RPTR(XnRegion) Region_with_N2 (APTR(XnRegion) ARG(receiver), APTR(Position) ARG(arg1));
	
	
	static RPTR(XnRegion) Region_without_N2 (APTR(XnRegion) ARG(receiver), APTR(Position) ARG(arg1));
	
	
	static RPTR(PrimIntValue) Sequence_firstIndex_N1 (APTR(Sequence) ARG(receiver));
	
	
	static RPTR(PrimIntValue) Sequence_integerAt_N2 (APTR(Sequence) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PrimArray) Sequence_integers_N1 (APTR(Sequence) ARG(receiver));
	
	
	static BooleanVar Sequence_isZero_N1 (APTR(Sequence) ARG(receiver));
	
	
	static RPTR(PrimIntValue) Sequence_lastIndex_N1 (APTR(Sequence) ARG(receiver));
	
	
	static RPTR(Sequence) Sequence_with_N3 (
			APTR(Sequence) ARG(receiver), 
			APTR(PrimIntValue) ARG(arg1), 
			APTR(PrimIntValue) ARG(arg2))
	;
	
	
	static RPTR(PrimIntValue) SequenceMapping_shift_N1 (APTR(SequenceMapping) ARG(receiver));
	
	
	static RPTR(Sequence) SequenceMapping_translation_N1 (APTR(SequenceMapping) ARG(receiver));
	
	
	static RPTR(Stepper) SequenceRegion_intervals_N1 (APTR(SequenceRegion) ARG(receiver));
	
	
	static RPTR(Stepper) SequenceRegion_intervals_N2 (APTR(SequenceRegion) ARG(receiver), APTR(OrderSpec) ARG(arg1));
	
	
	static BooleanVar SequenceRegion_isBoundedAbove_N1 (APTR(SequenceRegion) ARG(receiver));
	
	
	static BooleanVar SequenceRegion_isBoundedBelow_N1 (APTR(SequenceRegion) ARG(receiver));
	
	
	static BooleanVar SequenceRegion_isInterval_N1 (APTR(SequenceRegion) ARG(receiver));
	
	
	static RPTR(Sequence) SequenceRegion_lowerEdge_N1 (APTR(SequenceRegion) ARG(receiver));
	
	
	static RPTR(PrimIntValue) SequenceRegion_lowerEdgePrefixLimit_N1 (APTR(SequenceRegion) ARG(receiver));
	
	
	static RPTR(PrimIntValue) SequenceRegion_lowerEdgeType_N1 (APTR(SequenceRegion) ARG(receiver));
	
	
	static RPTR(Sequence) SequenceRegion_upperEdge_N1 (APTR(SequenceRegion) ARG(receiver));
	
	
	static RPTR(PrimIntValue) SequenceRegion_upperEdgePrefixLimit_N1 (APTR(SequenceRegion) ARG(receiver));
	
	
	static RPTR(PrimIntValue) SequenceRegion_upperEdgeType_N1 (APTR(SequenceRegion) ARG(receiver));
	
	
	static RPTR(SequenceRegion) SequenceSpace_above_N2 (APTR(Sequence) ARG(arg1), BooleanVar ARG(arg2));
	
	
	static RPTR(SequenceRegion) SequenceSpace_below_N2 (APTR(Sequence) ARG(arg1), BooleanVar ARG(arg2));
	
	
	static RPTR(SequenceRegion) SequenceSpace_interval_N2 (APTR(Sequence) ARG(arg1), APTR(Sequence) ARG(arg2));
	
	
	static RPTR(SequenceSpace) SequenceSpace_make_N0 ();
	
	
	static RPTR(SequenceMapping) SequenceSpace_mapping_N1 (APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(SequenceMapping) SequenceSpace_mapping_N2 (APTR(PrimIntValue) ARG(arg1), APTR(Sequence) ARG(arg2));
	
	
	static RPTR(Sequence) SequenceSpace_position_N1 (APTR(PrimArray) ARG(arg1));
	
	
	static RPTR(Sequence) SequenceSpace_position_N2 (APTR(PrimArray) ARG(arg1), APTR(PrimIntValue) ARG(arg2));
	
	
	static RPTR(SequenceRegion) SequenceSpace_prefixedBy_N2 (APTR(Sequence) ARG(arg1), APTR(PrimIntValue) ARG(arg2));
	
	
	static RPTR(ID) Server_accessClubID_N0 ();
	
	
	static RPTR(ID) Server_adminClubID_N0 ();
	
	
	static RPTR(ID) Server_archiveClubID_N0 ();
	
	
	static RPTR(ID) Server_assignID_N1 (APTR(FeRangeElement) ARG(arg1));
	
	
	static RPTR(ID) Server_assignID_N2 (APTR(FeRangeElement) ARG(arg1), APTR(ID) ARG(arg2));
	
	
	static RPTR(ID) Server_clubDirectoryID_N0 ();
	
	
	static RPTR(PrimIntValue) Server_currentTime_N0 ();
	
	
	static RPTR(ID) Server_emptyClubID_N0 ();
	
	
	static RPTR(Sequence) Server_encrypterName_N0 ();
	
	
	static RPTR(FeRangeElement) Server_get_N1 (APTR(ID) ARG(arg1));
	
	
	static RPTR(Sequence) Server_identifier_N0 ();
	
	
	static RPTR(ID) Server_iDOf_N1 (APTR(FeRangeElement) ARG(arg1));
	
	
	static RPTR(IDRegion) Server_iDsOf_N1 (APTR(FeRangeElement) ARG(arg1));
	
	
	static RPTR(IDRegion) Server_iDsOfRange_N1 (APTR(FeEdition) ARG(arg1));
	
	
	static RPTR(Lock) Server_login_N1 (APTR(ID) ARG(arg1));
	
	
	static RPTR(Lock) Server_loginByName_N1 (APTR(Sequence) ARG(arg1));
	
	
	static RPTR(ID) Server_publicClubID_N0 ();
	
	
	static RPTR(PrimIntArray) Server_publicKey_N0 ();
	
	
	static RPTR(PrimIntValue) Session_connectTime_N1 (APTR(FeSession) ARG(receiver));
	
	
	static RPTR(FeSession) Session_current_N0 ();
	
	
	static void Session_endSession_N1 (APTR(FeSession) ARG(receiver));
	
	
	static void Session_endSession_N2 (APTR(FeSession) ARG(receiver), BooleanVar ARG(arg1));
	
	
	static RPTR(ID) Session_initialLogin_N1 (APTR(FeSession) ARG(receiver));
	
	
	static BooleanVar Session_isConnected_N1 (APTR(FeSession) ARG(receiver));
	
	
	static RPTR(PrimIntArray) Session_port_N1 (APTR(FeSession) ARG(receiver));
	
	
	static RPTR(PrimIntValue) Set_count_N1 (APTR(FeSet) ARG(receiver));
	
	
	static BooleanVar Set_includes_N2 (APTR(FeSet) ARG(receiver), APTR(FeRangeElement) ARG(arg1));
	
	
	static RPTR(FeSet) Set_intersect_N2 (APTR(FeSet) ARG(receiver), APTR(FeSet) ARG(arg1));
	
	
	static RPTR(FeSet) Set_make_N0 ();
	
	
	static RPTR(FeSet) Set_make_N1 (APTR(PtrArray) ARG(arg1));
	
	
	static RPTR(FeSet) Set_minus_N2 (APTR(FeSet) ARG(receiver), APTR(FeSet) ARG(arg1));
	
	
	static RPTR(FeRangeElement) Set_theOne_N1 (APTR(FeSet) ARG(receiver));
	
	
	static RPTR(FeSet) Set_unionWith_N2 (APTR(FeSet) ARG(receiver), APTR(FeSet) ARG(arg1));
	
	
	static RPTR(FeSet) Set_with_N2 (APTR(FeSet) ARG(receiver), APTR(FeRangeElement) ARG(arg1));
	
	
	static RPTR(FeSet) Set_without_N2 (APTR(FeSet) ARG(receiver), APTR(FeRangeElement) ARG(arg1));
	
	
	static RPTR(FeEdition) SingleRef_excerpt_N1 (APTR(FeSingleRef) ARG(receiver));
	
	
	static RPTR(FeSingleRef) SingleRef_make_N1 (APTR(FeEdition) ARG(arg1));
	
	
	static RPTR(FeSingleRef) SingleRef_make_N2 (APTR(FeEdition) ARG(arg1), APTR(FeWork) ARG(arg2));
	
	
	static RPTR(FeSingleRef) SingleRef_make_N3 (
			APTR(FeEdition) ARG(arg1), 
			APTR(FeWork) ARG(arg2), 
			APTR(FeWork) ARG(arg3))
	;
	
	
	static RPTR(FeSingleRef) SingleRef_make_N4 (
			APTR(FeEdition) ARG(arg1), 
			APTR(FeWork) ARG(arg2), 
			APTR(FeWork) ARG(arg3), 
			APTR(FePath) ARG(arg4))
	;
	
	
	static RPTR(FeSingleRef) SingleRef_withExcerpt_N2 (APTR(FeSingleRef) ARG(receiver), APTR(FeEdition) ARG(arg1));
	
	
	static BooleanVar Stepper_atEnd_N1 (APTR(Stepper) ARG(receiver));
	
	
	static RPTR(Stepper) Stepper_copy_N1 (APTR(Stepper) ARG(receiver));
	
	
	static RPTR(Heaper) Stepper_get_N1 (APTR(Stepper) ARG(receiver));
	
	
	static void Stepper_step_N1 (APTR(Stepper) ARG(receiver));
	
	
	static RPTR(PrimArray) Stepper_stepMany_N1 (APTR(Stepper) ARG(receiver));
	
	
	static RPTR(PrimArray) Stepper_stepMany_N2 (APTR(Stepper) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(Heaper) Stepper_theOne_N1 (APTR(Stepper) ARG(receiver));
	
	
	static RPTR(Position) TableStepper_position_N1 (APTR(TableStepper) ARG(receiver));
	
	
	static RPTR(PrimArray) TableStepper_stepManyPairs_N1 (APTR(TableStepper) ARG(receiver));
	
	
	static RPTR(PrimArray) TableStepper_stepManyPairs_N2 (APTR(TableStepper) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(FeEdition) Text_contents_N1 (APTR(FeText) ARG(receiver));
	
	
	static RPTR(PrimIntValue) Text_count_N1 (APTR(FeText) ARG(receiver));
	
	
	static RPTR(FeText) Text_extract_N2 (APTR(FeText) ARG(receiver), APTR(IntegerRegion) ARG(arg1));
	
	
	static RPTR(FeText) Text_insert_N3 (
			APTR(FeText) ARG(receiver), 
			APTR(PrimIntValue) ARG(arg1), 
			APTR(FeText) ARG(arg2))
	;
	
	
	static RPTR(FeText) Text_make_N1 (APTR(PrimArray) ARG(arg1));
	
	
	static RPTR(FeText) Text_move_N3 (
			APTR(FeText) ARG(receiver), 
			APTR(PrimIntValue) ARG(arg1), 
			APTR(IntegerRegion) ARG(arg2))
	;
	
	
	static RPTR(FeText) Text_replace_N3 (
			APTR(FeText) ARG(receiver), 
			APTR(IntegerRegion) ARG(arg1), 
			APTR(FeText) ARG(arg2))
	;
	
	
	static RPTR(Position) Tuple_coordinate_N2 (APTR(Tuple) ARG(receiver), APTR(PrimIntValue) ARG(arg1));
	
	
	static RPTR(PtrArray) Tuple_coordinates_N1 (APTR(Tuple) ARG(receiver));
	
	
	static RPTR(FeWallLockSmith) WallLockSmith_make_N0 ();
	
	
	static BooleanVar Work_canRead_N1 (APTR(FeWork) ARG(receiver));
	
	
	static BooleanVar Work_canRevise_N1 (APTR(FeWork) ARG(receiver));
	
	
	static RPTR(ID) Work_editClub_N1 (APTR(FeWork) ARG(receiver));
	
	
	static RPTR(FeEdition) Work_edition_N1 (APTR(FeWork) ARG(receiver));
	
	
	static void Work_endorse_N2 (APTR(FeWork) ARG(receiver), APTR(CrossRegion) ARG(arg1));
	
	
	static RPTR(CrossRegion) Work_endorsements_N1 (APTR(FeWork) ARG(receiver));
	
	
	static void Work_grab_N1 (APTR(FeWork) ARG(receiver));
	
	
	static RPTR(ID) Work_grabber_N1 (APTR(FeWork) ARG(receiver));
	
	
	static RPTR(ID) Work_historyClub_N1 (APTR(FeWork) ARG(receiver));
	
	
	static RPTR(ID) Work_lastRevisionAuthor_N1 (APTR(FeWork) ARG(receiver));
	
	
	static RPTR(PrimIntValue) Work_lastRevisionNumber_N1 (APTR(FeWork) ARG(receiver));
	
	
	static RPTR(PrimIntValue) Work_lastRevisionTime_N1 (APTR(FeWork) ARG(receiver));
	
	
	static RPTR(FeWork) Work_make_N1 (APTR(FeEdition) ARG(arg1));
	
	
	static RPTR(ID) Work_readClub_N1 (APTR(FeWork) ARG(receiver));
	
	
	static void Work_release_N1 (APTR(FeWork) ARG(receiver));
	
	
	static void Work_removeEditClub_N1 (APTR(FeWork) ARG(receiver));
	
	
	static void Work_removeReadClub_N1 (APTR(FeWork) ARG(receiver));
	
	
	static void Work_requestGrab_N1 (APTR(FeWork) ARG(receiver));
	
	
	static void Work_retract_N2 (APTR(FeWork) ARG(receiver), APTR(CrossRegion) ARG(arg1));
	
	
	static void Work_revise_N2 (APTR(FeWork) ARG(receiver), APTR(FeEdition) ARG(arg1));
	
	
	static RPTR(FeEdition) Work_revisions_N1 (APTR(FeWork) ARG(receiver));
	
	
	static void Work_setEditClub_N2 (APTR(FeWork) ARG(receiver), APTR(ID) ARG(arg1));
	
	
	static void Work_setHistoryClub_N2 (APTR(FeWork) ARG(receiver), APTR(ID) ARG(arg1));
	
	
	static void Work_setReadClub_N2 (APTR(FeWork) ARG(receiver), APTR(ID) ARG(arg1));
	
	
	static void Work_sponsor_N2 (APTR(FeWork) ARG(receiver), APTR(IDRegion) ARG(arg1));
	
	
	static RPTR(IDRegion) Work_sponsors_N1 (APTR(FeWork) ARG(receiver));
	
	
	static void Work_unsponsor_N2 (APTR(FeWork) ARG(receiver), APTR(IDRegion) ARG(arg1));
	
	
	static RPTR(FeEdition) Wrapper_edition_N1 (APTR(FeWrapper) ARG(receiver));
	
	
	static RPTR(FeWrapper) Wrapper_inner_N1 (APTR(FeWrapper) ARG(receiver));
	
	
	static RPTR(Filter) WrapperSpec_filter_N1 (APTR(FeWrapperSpec) ARG(receiver));
	
	
	static RPTR(FeWrapperSpec) WrapperSpec_get_N1 (APTR(Sequence) ARG(arg1));
	
	
	static RPTR(Sequence) WrapperSpec_name_N1 (APTR(FeWrapperSpec) ARG(receiver));
	
	
	static RPTR(FeWrapper) WrapperSpec_wrap_N2 (APTR(FeWrapperSpec) ARG(receiver), APTR(FeEdition) ARG(arg1));
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm)) DEFERRED_SUBR;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	

	/* automatic 0-argument constructor */
  public:
	RequestHandler();

};  /* end class RequestHandler */



/* ************************************************************************ *
 * 
 *                    Class   BHHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class BHHandler : public RequestHandler {

/* Attributes for class BHHandler */
	CONCRETE(BHHandler)
	NOT_A_TYPE(BHHandler)
	AUTO_GC(BHHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (BHFn ARG(fn), APTR(Category) ARG(type1));
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	BHHandler (BHFn ARG(fn), APTR(Category) ARG(type1));
	
  private:
	BHFn myFn;
	CHKPTR(Category) myType1;
};  /* end class BHHandler */



/* ************************************************************************ *
 * 
 *                    Class   BHHHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class BHHHandler : public RequestHandler {

/* Attributes for class BHHHandler */
	CONCRETE(BHHHandler)
	NOT_A_TYPE(BHHHandler)
	AUTO_GC(BHHHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (
			BHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2))
	;
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	BHHHandler (
			BHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2))
	;
	
  private:
	BHHFn myFn;
	CHKPTR(Category) myType1;
	CHKPTR(Category) myType2;
};  /* end class BHHHandler */



/* ************************************************************************ *
 * 
 *                    Class   BHHHHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class BHHHHandler : public RequestHandler {

/* Attributes for class BHHHHandler */
	CONCRETE(BHHHHandler)
	NOT_A_TYPE(BHHHHandler)
	AUTO_GC(BHHHHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (
			BHHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2), 
			APTR(Category) ARG(type3))
	;
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	BHHHHandler (
			BHHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2), 
			APTR(Category) ARG(type3))
	;
	
  private:
	BHHHFn myFn;
	CHKPTR(Category) myType1;
	CHKPTR(Category) myType2;
	CHKPTR(Category) myType3;
};  /* end class BHHHHandler */



/* ************************************************************************ *
 * 
 *                    Class   HHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HHandler : public RequestHandler {

/* Attributes for class HHandler */
	CONCRETE(HHandler)
	NOT_A_TYPE(HHandler)
	NO_GC(HHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (HFn ARG(fn));
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	HHandler (HFn ARG(fn), TCSJ);
	
  private:
	HFn myFn;
};  /* end class HHandler */



/* ************************************************************************ *
 * 
 *                    Class   HHBHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HHBHandler : public RequestHandler {

/* Attributes for class HHBHandler */
	CONCRETE(HHBHandler)
	NOT_A_TYPE(HHBHandler)
	AUTO_GC(HHBHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (HHBFn ARG(fn), APTR(Category) ARG(type1));
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	HHBHandler (HHBFn ARG(fn), APTR(Category) ARG(type1));
	
  private:
	HHBFn myFn;
	CHKPTR(Category) myType1;
};  /* end class HHBHandler */



/* ************************************************************************ *
 * 
 *                    Class   HHHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HHHandler : public RequestHandler {

/* Attributes for class HHHandler */
	CONCRETE(HHHandler)
	NOT_A_TYPE(HHHandler)
	AUTO_GC(HHHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (HHFn ARG(fn), APTR(Category) ARG(type1));
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	HHHandler (HHFn ARG(fn), APTR(Category) ARG(type1));
	
  private:
	HHFn myFn;
	CHKPTR(Category) myType1;
};  /* end class HHHandler */



/* ************************************************************************ *
 * 
 *                    Class   HHHBHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HHHBHandler : public RequestHandler {

/* Attributes for class HHHBHandler */
	CONCRETE(HHHBHandler)
	NOT_A_TYPE(HHHBHandler)
	AUTO_GC(HHHBHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (
			HHHBFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2))
	;
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	HHHBHandler (
			HHHBFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2))
	;
	
  private:
	HHHBFn myFn;
	CHKPTR(Category) myType1;
	CHKPTR(Category) myType2;
};  /* end class HHHBHandler */



/* ************************************************************************ *
 * 
 *                    Class   HHHHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HHHHandler : public RequestHandler {

/* Attributes for class HHHHandler */
	CONCRETE(HHHHandler)
	NOT_A_TYPE(HHHHandler)
	AUTO_GC(HHHHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (
			HHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2))
	;
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	HHHHandler (
			HHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2))
	;
	
  private:
	HHHFn myFn;
	CHKPTR(Category) myType1;
	CHKPTR(Category) myType2;
};  /* end class HHHHandler */



/* ************************************************************************ *
 * 
 *                    Class   HHHHHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HHHHHandler : public RequestHandler {

/* Attributes for class HHHHHandler */
	CONCRETE(HHHHHandler)
	NOT_A_TYPE(HHHHHandler)
	AUTO_GC(HHHHHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (
			HHHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2), 
			APTR(Category) ARG(type3))
	;
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	HHHHHandler (
			HHHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2), 
			APTR(Category) ARG(type3))
	;
	
  private:
	HHHHFn myFn;
	CHKPTR(Category) myType1;
	CHKPTR(Category) myType2;
	CHKPTR(Category) myType3;
};  /* end class HHHHHandler */



/* ************************************************************************ *
 * 
 *                    Class   HHHHHHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HHHHHHandler : public RequestHandler {

/* Attributes for class HHHHHHandler */
	CONCRETE(HHHHHHandler)
	NOT_A_TYPE(HHHHHHandler)
	AUTO_GC(HHHHHHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (
			HHHHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2), 
			APTR(Category) ARG(type3), 
			APTR(Category) ARG(type4))
	;
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	HHHHHHandler (
			HHHHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2), 
			APTR(Category) ARG(type3), 
			APTR(Category) ARG(type4))
	;
	
  private:
	HHHHHFn myFn;
	CHKPTR(Category) myType1;
	CHKPTR(Category) myType2;
	CHKPTR(Category) myType3;
	CHKPTR(Category) myType4;
};  /* end class HHHHHHandler */



/* ************************************************************************ *
 * 
 *                    Class   HHHHHHHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HHHHHHHandler : public RequestHandler {

/* Attributes for class HHHHHHHandler */
	CONCRETE(HHHHHHHandler)
	NOT_A_TYPE(HHHHHHHandler)
	AUTO_GC(HHHHHHHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (
			HHHHHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2), 
			APTR(Category) ARG(type3), 
			APTR(Category) ARG(type4), 
			APTR(Category) ARG(type5))
	;
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	HHHHHHHandler (
			HHHHHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2), 
			APTR(Category) ARG(type3), 
			APTR(Category) ARG(type4), 
			APTR(Category) ARG(type5))
	;
	
  private:
	HHHHHHFn myFn;
	CHKPTR(Category) myType1;
	CHKPTR(Category) myType2;
	CHKPTR(Category) myType3;
	CHKPTR(Category) myType4;
	CHKPTR(Category) myType5;
};  /* end class HHHHHHHandler */



/* ************************************************************************ *
 * 
 *                    Class   HHHHHHHHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HHHHHHHHandler : public RequestHandler {

/* Attributes for class HHHHHHHHandler */
	CONCRETE(HHHHHHHHandler)
	NOT_A_TYPE(HHHHHHHHandler)
	AUTO_GC(HHHHHHHHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (
			HHHHHHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2), 
			APTR(Category) ARG(type3), 
			APTR(Category) ARG(type4), 
			APTR(Category) ARG(type5), 
			APTR(Category) ARG(type6))
	;
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	HHHHHHHHandler (
			HHHHHHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2), 
			APTR(Category) ARG(type3), 
			APTR(Category) ARG(type4), 
			APTR(Category) ARG(type5), 
			APTR(Category) ARG(type6))
	;
	
  private:
	HHHHHHHFn myFn;
	CHKPTR(Category) myType1;
	CHKPTR(Category) myType2;
	CHKPTR(Category) myType3;
	CHKPTR(Category) myType4;
	CHKPTR(Category) myType5;
	CHKPTR(Category) myType6;
};  /* end class HHHHHHHHandler */



/* ************************************************************************ *
 * 
 *                    Class   VHBHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class VHBHandler : public RequestHandler {

/* Attributes for class VHBHandler */
	CONCRETE(VHBHandler)
	NOT_A_TYPE(VHBHandler)
	AUTO_GC(VHBHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (VHBFn ARG(fn), APTR(Category) ARG(type1));
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	VHBHandler (VHBFn ARG(fn), APTR(Category) ARG(type1));
	
  private:
	VHBFn myFn;
	CHKPTR(Category) myType1;
};  /* end class VHBHandler */



/* ************************************************************************ *
 * 
 *                    Class   VHHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class VHHandler : public RequestHandler {

/* Attributes for class VHHandler */
	CONCRETE(VHHandler)
	NOT_A_TYPE(VHHandler)
	AUTO_GC(VHHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (VHFn ARG(fn), APTR(Category) ARG(type1));
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	VHHandler (VHFn ARG(fn), APTR(Category) ARG(type1));
	
  private:
	VHFn myFn;
	CHKPTR(Category) myType1;
};  /* end class VHHandler */



/* ************************************************************************ *
 * 
 *                    Class   VHHHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class VHHHandler : public RequestHandler {

/* Attributes for class VHHHandler */
	CONCRETE(VHHHandler)
	NOT_A_TYPE(VHHHandler)
	AUTO_GC(VHHHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (
			VHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2))
	;
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	VHHHandler (
			VHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2))
	;
	
  private:
	VHHFn myFn;
	CHKPTR(Category) myType1;
	CHKPTR(Category) myType2;
};  /* end class VHHHandler */



/* ************************************************************************ *
 * 
 *                    Class   VHHHHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class VHHHHandler : public RequestHandler {

/* Attributes for class VHHHHandler */
	CONCRETE(VHHHHandler)
	NOT_A_TYPE(VHHHHandler)
	AUTO_GC(VHHHHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (
			VHHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2), 
			APTR(Category) ARG(type3))
	;
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	VHHHHandler (
			VHHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2), 
			APTR(Category) ARG(type3))
	;
	
  private:
	VHHHFn myFn;
	CHKPTR(Category) myType1;
	CHKPTR(Category) myType2;
	CHKPTR(Category) myType3;
};  /* end class VHHHHandler */



/* ************************************************************************ *
 * 
 *                    Class   VHHHHHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class VHHHHHandler : public RequestHandler {

/* Attributes for class VHHHHHandler */
	CONCRETE(VHHHHHandler)
	NOT_A_TYPE(VHHHHHandler)
	AUTO_GC(VHHHHHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (
			VHHHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2), 
			APTR(Category) ARG(type3), 
			APTR(Category) ARG(type4))
	;
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	VHHHHHandler (
			VHHHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2), 
			APTR(Category) ARG(type3), 
			APTR(Category) ARG(type4))
	;
	
  private:
	VHHHHFn myFn;
	CHKPTR(Category) myType1;
	CHKPTR(Category) myType2;
	CHKPTR(Category) myType3;
	CHKPTR(Category) myType4;
};  /* end class VHHHHHandler */



/* ************************************************************************ *
 * 
 *                    Class   VHHHHHHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class VHHHHHHandler : public RequestHandler {

/* Attributes for class VHHHHHHandler */
	CONCRETE(VHHHHHHandler)
	NOT_A_TYPE(VHHHHHHandler)
	AUTO_GC(VHHHHHHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (
			VHHHHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2), 
			APTR(Category) ARG(type3), 
			APTR(Category) ARG(type4), 
			APTR(Category) ARG(type5))
	;
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	VHHHHHHandler (
			VHHHHHFn ARG(fn), 
			APTR(Category) ARG(type1), 
			APTR(Category) ARG(type2), 
			APTR(Category) ARG(type3), 
			APTR(Category) ARG(type4), 
			APTR(Category) ARG(type5))
	;
	
  private:
	VHHHHHFn myFn;
	CHKPTR(Category) myType1;
	CHKPTR(Category) myType2;
	CHKPTR(Category) myType3;
	CHKPTR(Category) myType4;
	CHKPTR(Category) myType5;
};  /* end class VHHHHHHandler */



#endif /* HANDLRSX_HXX */

