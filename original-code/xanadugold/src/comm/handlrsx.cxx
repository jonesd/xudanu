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

#ifndef HANDLRSX_CXX
#define HANDLRSX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef HANDLRSX_HXX
#include "handlrsx.hxx"
#endif /* HANDLRSX_HXX */

#ifndef HANDLRSX_IXX
#include "handlrsx.ixx"
#endif /* HANDLRSX_IXX */


#ifndef CROSSX_HXX
#include "crossx.hxx"
#endif /* CROSSX_HXX */

#ifndef FILTERX_HXX
#include "filterx.hxx"
#endif /* FILTERX_HXX */

#ifndef IDX_HXX
#include "idx.hxx"
#endif /* IDX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef NADMINX_HXX
#include "nadminx.hxx"
#endif /* NADMINX_HXX */

#ifndef NKERNELX_HXX
#include "nkernelx.hxx"
#endif /* NKERNELX_HXX */

#ifndef NLINKSX_HXX
#include "nlinksx.hxx"
#endif /* NLINKSX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef PRIMVALX_HXX
#include "primvalx.hxx"
#endif /* PRIMVALX_HXX */

#ifndef PROMANX_HXX
#include "promanx.hxx"
#endif /* PROMANX_HXX */

#ifndef REALX_HXX
#include "realx.hxx"
#endif /* REALX_HXX */

#ifndef SEQUENCX_HXX
#include "sequencx.hxx"
#endif /* SEQUENCX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */

#ifndef SYSADMX_HXX
#include "sysadmx.hxx"
#endif /* SYSADMX_HXX */

#ifndef WRAPPERX_HXX
#include "wrapperx.hxx"
#endif /* WRAPPERX_HXX */




/* ************************************************************************ *
 * 
 *                    Class RequestHandler 
 *
 * ************************************************************************ */


/* translate: generated */


void RequestHandler::Adminer_acceptConnections_N2 (APTR(FeAdminer) receiver, BooleanVar arg1){
	receiver->acceptConnections(arg1);
}


RPTR(Stepper) RequestHandler::Adminer_activeSessions_N1 (APTR(FeAdminer) receiver){
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->activeSessions();
	return returnValue;
}


void RequestHandler::Adminer_execute_N2 (APTR(FeAdminer) receiver, APTR(PrimIntArray) arg1){
	receiver->execute(arg1);
}


RPTR(FeLockSmith) RequestHandler::Adminer_gateLockSmith_N1 (APTR(FeAdminer) receiver){
	WPTR(FeLockSmith) 	returnValue;
	returnValue = receiver->gateLockSmith();
	return returnValue;
}


void RequestHandler::Adminer_grant_N3 (
		APTR(FeAdminer) receiver, 
		APTR(ID) arg1, 
		APTR(IDRegion) arg2)
{
	receiver->grant(arg1, arg2);
}


RPTR(TableStepper) RequestHandler::Adminer_grants_N1 (APTR(FeAdminer) receiver){
	WPTR(TableStepper) 	returnValue;
	returnValue = receiver->grants();
	return returnValue;
}


RPTR(TableStepper) RequestHandler::Adminer_grants_N2 (APTR(FeAdminer) receiver, APTR(IDRegion) arg1){
	WPTR(TableStepper) 	returnValue;
	returnValue = receiver->grants(arg1);
	return returnValue;
}


RPTR(TableStepper) RequestHandler::Adminer_grants_N3 (
		APTR(FeAdminer) receiver, 
		APTR(IDRegion) arg1, 
		APTR(IDRegion) arg2)
{
	WPTR(TableStepper) 	returnValue;
	returnValue = receiver->grants(arg1, arg2);
	return returnValue;
}


BooleanVar RequestHandler::Adminer_isAcceptingConnections_N1 (APTR(FeAdminer) receiver){
	return receiver->isAcceptingConnections();
}


RPTR(FeAdminer) RequestHandler::Adminer_make_N0 (){
	WPTR(FeAdminer) 	returnValue;
	returnValue = FeAdminer::make ();
	return returnValue;
}


void RequestHandler::Adminer_setGateLockSmith_N2 (APTR(FeAdminer) receiver, APTR(FeLockSmith) arg1){
	receiver->setGateLockSmith(arg1);
}


RPTR(FeEdition) RequestHandler::Archiver_archive_N3 (
		APTR(FeArchiver) receiver, 
		APTR(FeEdition) arg1, 
		APTR(FeEdition) arg2)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->archive(arg1, arg2);
	return returnValue;
}


RPTR(FeArchiver) RequestHandler::Archiver_make_N0 (){
	WPTR(FeArchiver) 	returnValue;
	returnValue = FeArchiver::make ();
	return returnValue;
}


void RequestHandler::Archiver_markArchived_N2 (APTR(FeArchiver) receiver, APTR(FeEdition) arg1){
	receiver->markArchived(arg1);
}


RPTR(FeEdition) RequestHandler::Archiver_restore_N3 (
		APTR(FeArchiver) receiver, 
		APTR(FeEdition) arg1, 
		APTR(FeEdition) arg2)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->restore(arg1, arg2);
	return returnValue;
}


RPTR(PrimArray) RequestHandler::Array_copy_N1 (APTR(PrimArray) receiver){
	WPTR(PrimArray) 	returnValue;
	returnValue = receiver->copy();
	return returnValue;
}


RPTR(PrimArray) RequestHandler::Array_copy_N2 (APTR(PrimArray) receiver, APTR(PrimIntValue) arg1){
	WPTR(PrimArray) 	returnValue;
	returnValue = receiver->copy(arg1->asInt32());
	return returnValue;
}


RPTR(PrimArray) RequestHandler::Array_copy_N3 (
		APTR(PrimArray) receiver, 
		APTR(PrimIntValue) arg1, 
		APTR(PrimIntValue) arg2)
{
	WPTR(PrimArray) 	returnValue;
	returnValue = receiver->copy(arg1->asInt32(), arg2->asInt32());
	return returnValue;
}


RPTR(PrimArray) RequestHandler::Array_copy_N4 (
		APTR(PrimArray) receiver, 
		APTR(PrimIntValue) arg1, 
		APTR(PrimIntValue) arg2, 
		APTR(PrimIntValue) arg3)
{
	WPTR(PrimArray) 	returnValue;
	returnValue = receiver->copy(arg1->asInt32(), arg2->asInt32(), arg3->asInt32());
	return returnValue;
}


RPTR(PrimArray) RequestHandler::Array_copy_N5 (
		APTR(PrimArray) receiver, 
		APTR(PrimIntValue) arg1, 
		APTR(PrimIntValue) arg2, 
		APTR(PrimIntValue) arg3, 
		APTR(PrimIntValue) arg4)
{
	WPTR(PrimArray) 	returnValue;
	returnValue = receiver->copy(arg1->asInt32(), arg2->asInt32(), arg3->asInt32(), arg4->asInt32());
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::Array_count_N1 (APTR(PrimArray) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->count());
	return returnValue;
}


RPTR(Heaper) RequestHandler::Array_get_N2 (APTR(PrimArray) receiver, APTR(PrimIntValue) arg1){
	WPTR(Heaper) 	returnValue;
	returnValue = receiver->getValue(arg1->asInt32());
	return returnValue;
}


void RequestHandler::Array_store_N3 (
		APTR(PrimArray) receiver, 
		APTR(PrimIntValue) arg1, 
		APTR(Heaper) arg2)
{
	receiver->storeValue(arg1->asInt32(), arg2);
}


void RequestHandler::Array_storeAll_N1 (APTR(PrimArray) receiver){
	receiver->storeAll();
}


void RequestHandler::Array_storeAll_N2 (APTR(PrimArray) receiver, APTR(Heaper) arg1){
	receiver->storeAll(arg1);
}


void RequestHandler::Array_storeAll_N3 (
		APTR(PrimArray) receiver, 
		APTR(Heaper) arg1, 
		APTR(PrimIntValue) arg2)
{
	receiver->storeAll(arg1, arg2->asInt32());
}


void RequestHandler::Array_storeAll_N4 (
		APTR(PrimArray) receiver, 
		APTR(Heaper) arg1, 
		APTR(PrimIntValue) arg2, 
		APTR(PrimIntValue) arg3)
{
	receiver->storeAll(arg1, arg2->asInt32(), arg3->asInt32());
}


void RequestHandler::Array_storeMany_N3 (
		APTR(PrimArray) receiver, 
		APTR(PrimIntValue) arg1, 
		APTR(PrimArray) arg2)
{
	receiver->storeMany(arg1->asInt32(), arg2);
}


void RequestHandler::Array_storeMany_N4 (
		APTR(PrimArray) receiver, 
		APTR(PrimIntValue) arg1, 
		APTR(PrimArray) arg2, 
		APTR(PrimIntValue) arg3)
{
	receiver->storeMany(arg1->asInt32(), arg2, arg3->asInt32());
}


void RequestHandler::Array_storeMany_N5 (
		APTR(PrimArray) receiver, 
		APTR(PrimIntValue) arg1, 
		APTR(PrimArray) arg2, 
		APTR(PrimIntValue) arg3, 
		APTR(PrimIntValue) arg4)
{
	receiver->storeMany(arg1->asInt32(), arg2, arg3->asInt32(), arg4->asInt32());
}


RPTR(PrimArray) RequestHandler::ArrayBundle_array_N1 (APTR(FeArrayBundle) receiver){
	WPTR(PrimArray) 	returnValue;
	returnValue = receiver->array();
	return returnValue;
}


RPTR(OrderSpec) RequestHandler::ArrayBundle_ordering_N1 (APTR(FeArrayBundle) receiver){
	WPTR(OrderSpec) 	returnValue;
	returnValue = receiver->ordering();
	return returnValue;
}


RPTR(FeKeyMaster) RequestHandler::BooLock_boo_N1 (APTR(BooLock) receiver){
	WPTR(FeKeyMaster) 	returnValue;
	returnValue = receiver->boo();
	return returnValue;
}


RPTR(FeBooLockSmith) RequestHandler::BooLockSmith_make_N0 (){
	WPTR(FeBooLockSmith) 	returnValue;
	returnValue = FeBooLockSmith::make ();
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Bundle_region_N1 (APTR(FeBundle) receiver){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->region();
	return returnValue;
}


RPTR(PrimIntArray) RequestHandler::ChallengeLock_challenge_N1 (APTR(ChallengeLock) receiver){
	WPTR(PrimIntArray) 	returnValue;
	returnValue = receiver->challenge();
	return returnValue;
}


RPTR(FeKeyMaster) RequestHandler::ChallengeLock_response_N2 (APTR(ChallengeLock) receiver, APTR(PrimIntArray) arg1){
	WPTR(FeKeyMaster) 	returnValue;
	returnValue = receiver->response(arg1);
	return returnValue;
}


RPTR(PrimIntArray) RequestHandler::ChallengeLockSmith_encrypterName_N1 (APTR(FeChallengeLockSmith) receiver){
	WPTR(PrimIntArray) 	returnValue;
	returnValue = receiver->encrypterName();
	return returnValue;
}


RPTR(FeChallengeLockSmith) RequestHandler::ChallengeLockSmith_make_N2 (APTR(PrimIntArray) arg1, APTR(Sequence) arg2){
	WPTR(FeChallengeLockSmith) 	returnValue;
	returnValue = FeChallengeLockSmith::make (arg1, arg2);
	return returnValue;
}


RPTR(PrimIntArray) RequestHandler::ChallengeLockSmith_publicKey_N1 (APTR(FeChallengeLockSmith) receiver){
	WPTR(PrimIntArray) 	returnValue;
	returnValue = receiver->publicKey();
	return returnValue;
}


RPTR(FeClub) RequestHandler::Club_make_N1 (APTR(FeEdition) arg1){
	WPTR(FeClub) 	returnValue;
	returnValue = FeClub::make (arg1);
	return returnValue;
}


void RequestHandler::Club_removeSignatureClub_N1 (APTR(FeClub) receiver){
	receiver->removeSignatureClub();
}


void RequestHandler::Club_setSignatureClub_N2 (APTR(FeClub) receiver, APTR(ID) arg1){
	receiver->setSignatureClub(arg1);
}


RPTR(ID) RequestHandler::Club_signatureClub_N1 (APTR(FeClub) receiver){
	WPTR(ID) 	returnValue;
	returnValue = receiver->signatureClub();
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Club_sponsoredWorks_N1 (APTR(FeClub) receiver){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->sponsoredWorks();
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Club_sponsoredWorks_N2 (APTR(FeClub) receiver, APTR(Filter) arg1){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->sponsoredWorks(arg1);
	return returnValue;
}


RPTR(FeLockSmith) RequestHandler::ClubDescription_lockSmith_N1 (APTR(FeClubDescription) receiver){
	WPTR(FeLockSmith) 	returnValue;
	returnValue = receiver->lockSmith();
	return returnValue;
}


RPTR(FeClubDescription) RequestHandler::ClubDescription_make_N2 (APTR(FeSet) arg1, APTR(FeLockSmith) arg2){
	WPTR(FeClubDescription) 	returnValue;
	returnValue = FeClubDescription::make (arg1, arg2);
	return returnValue;
}


RPTR(FeSet) RequestHandler::ClubDescription_membership_N1 (APTR(FeClubDescription) receiver){
	WPTR(FeSet) 	returnValue;
	returnValue = receiver->membership();
	return returnValue;
}


RPTR(FeClubDescription) RequestHandler::ClubDescription_withLockSmith_N2 (APTR(FeClubDescription) receiver, APTR(FeLockSmith) arg1){
	WPTR(FeClubDescription) 	returnValue;
	returnValue = receiver->withLockSmith(arg1);
	return returnValue;
}


RPTR(FeClubDescription) RequestHandler::ClubDescription_withMembership_N2 (APTR(FeClubDescription) receiver, APTR(FeSet) arg1){
	WPTR(FeClubDescription) 	returnValue;
	returnValue = receiver->withMembership(arg1);
	return returnValue;
}


RPTR(OrderSpec) RequestHandler::CoordinateSpace_ascending_N1 (APTR(CoordinateSpace) receiver){
	WPTR(OrderSpec) 	returnValue;
	returnValue = receiver->ascending();
	return returnValue;
}


RPTR(Mapping) RequestHandler::CoordinateSpace_completeMapping_N2 (APTR(CoordinateSpace) receiver, APTR(XnRegion) arg1){
	WPTR(Mapping) 	returnValue;
	returnValue = receiver->completeMapping(arg1);
	return returnValue;
}


RPTR(OrderSpec) RequestHandler::CoordinateSpace_descending_N1 (APTR(CoordinateSpace) receiver){
	WPTR(OrderSpec) 	returnValue;
	returnValue = receiver->descending();
	return returnValue;
}


RPTR(XnRegion) RequestHandler::CoordinateSpace_emptyRegion_N1 (APTR(CoordinateSpace) receiver){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->emptyRegion();
	return returnValue;
}


RPTR(XnRegion) RequestHandler::CoordinateSpace_fullRegion_N1 (APTR(CoordinateSpace) receiver){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->fullRegion();
	return returnValue;
}


RPTR(Mapping) RequestHandler::CoordinateSpace_identityMapping_N1 (APTR(CoordinateSpace) receiver){
	WPTR(Mapping) 	returnValue;
	returnValue = receiver->identityMapping();
	return returnValue;
}


RPTR(Mapping) RequestHandler::CrossMapping_subMapping_N2 (APTR(CrossMapping) receiver, APTR(PrimIntValue) arg1){
	WPTR(Mapping) 	returnValue;
	returnValue = receiver->subMapping(arg1->asInt32());
	return returnValue;
}


RPTR(PtrArray) RequestHandler::CrossMapping_subMappings_N1 (APTR(CrossMapping) receiver){
	WPTR(PtrArray) 	returnValue;
	returnValue = receiver->subMappings();
	return returnValue;
}


RPTR(PrimIntArray) RequestHandler::CrossOrderSpec_lexOrder_N1 (APTR(CrossOrderSpec) receiver){
	WPTR(PrimIntArray) 	returnValue;
	returnValue = receiver->lexOrder();
	return returnValue;
}


RPTR(OrderSpec) RequestHandler::CrossOrderSpec_subOrder_N2 (APTR(CrossOrderSpec) receiver, APTR(PrimIntValue) arg1){
	WPTR(OrderSpec) 	returnValue;
	returnValue = receiver->subOrder(arg1->asInt32());
	return returnValue;
}


RPTR(PtrArray) RequestHandler::CrossOrderSpec_subOrders_N1 (APTR(CrossOrderSpec) receiver){
	WPTR(PtrArray) 	returnValue;
	returnValue = receiver->subOrders();
	return returnValue;
}


RPTR(Stepper) RequestHandler::CrossRegion_boxes_N1 (APTR(CrossRegion) receiver){
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->boxes();
	return returnValue;
}


BooleanVar RequestHandler::CrossRegion_isBox_N1 (APTR(CrossRegion) receiver){
	return receiver->isBox();
}


RPTR(XnRegion) RequestHandler::CrossRegion_projection_N2 (APTR(CrossRegion) receiver, APTR(PrimIntValue) arg1){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->projection(arg1->asInt32());
	return returnValue;
}


RPTR(PtrArray) RequestHandler::CrossRegion_projections_N1 (APTR(CrossRegion) receiver){
	WPTR(PtrArray) 	returnValue;
	returnValue = receiver->projections();
	return returnValue;
}


RPTR(PtrArray) RequestHandler::CrossSpace_axes_N1 (APTR(CrossSpace) receiver){
	WPTR(PtrArray) 	returnValue;
	returnValue = receiver->axes();
	return returnValue;
}


RPTR(CoordinateSpace) RequestHandler::CrossSpace_axis_N2 (APTR(CrossSpace) receiver, APTR(PrimIntValue) arg1){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = receiver->axis(arg1->asInt32());
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::CrossSpace_axisCount_N1 (APTR(CrossSpace) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->axisCount());
	return returnValue;
}


RPTR(Mapping) RequestHandler::CrossSpace_crossOfMappings_N1 (APTR(CrossSpace) receiver){
	WPTR(Mapping) 	returnValue;
	returnValue = receiver->crossOfMappings();
	return returnValue;
}


RPTR(Mapping) RequestHandler::CrossSpace_crossOfMappings_N2 (APTR(CrossSpace) receiver, APTR(PtrArray) arg1){
	WPTR(Mapping) 	returnValue;
	returnValue = receiver->crossOfMappings(arg1);
	return returnValue;
}


RPTR(CrossOrderSpec) RequestHandler::CrossSpace_crossOfOrderSpecs_N1 (APTR(CrossSpace) receiver){
	WPTR(CrossOrderSpec) 	returnValue;
	returnValue = receiver->crossOfOrderSpecs();
	return returnValue;
}


RPTR(CrossOrderSpec) RequestHandler::CrossSpace_crossOfOrderSpecs_N2 (APTR(CrossSpace) receiver, APTR(PtrArray) arg1){
	WPTR(CrossOrderSpec) 	returnValue;
	returnValue = receiver->crossOfOrderSpecs(arg1);
	return returnValue;
}


RPTR(CrossOrderSpec) RequestHandler::CrossSpace_crossOfOrderSpecs_N3 (
		APTR(CrossSpace) receiver, 
		APTR(PtrArray) arg1, 
		APTR(PrimIntArray) arg2)
{
	WPTR(CrossOrderSpec) 	returnValue;
	returnValue = receiver->crossOfOrderSpecs(arg1, arg2);
	return returnValue;
}


RPTR(Tuple) RequestHandler::CrossSpace_crossOfPositions_N2 (APTR(CrossSpace) receiver, APTR(PtrArray) arg1){
	WPTR(Tuple) 	returnValue;
	returnValue = receiver->crossOfPositions(arg1);
	return returnValue;
}


RPTR(CrossRegion) RequestHandler::CrossSpace_crossOfRegions_N2 (APTR(CrossSpace) receiver, APTR(PtrArray) arg1){
	WPTR(CrossRegion) 	returnValue;
	returnValue = receiver->crossOfRegions(arg1);
	return returnValue;
}


RPTR(CrossRegion) RequestHandler::CrossSpace_extrusion_N3 (
		APTR(CrossSpace) receiver, 
		APTR(PrimIntValue) arg1, 
		APTR(XnRegion) arg2)
{
	WPTR(CrossRegion) 	returnValue;
	returnValue = receiver->extrusion(arg1->asInt32(), arg2);
	return returnValue;
}


RPTR(CrossSpace) RequestHandler::CrossSpace_make_N1 (APTR(PtrArray) arg1){
	WPTR(CrossSpace) 	returnValue;
	returnValue = CrossSpace::make (arg1);
	return returnValue;
}


RPTR(FeDataHolder) RequestHandler::DataHolder_make_N1 (APTR(PrimValue) arg1){
	WPTR(FeDataHolder) 	returnValue;
	returnValue = FeDataHolder::make (arg1);
	return returnValue;
}


RPTR(PrimValue) RequestHandler::DataHolder_value_N1 (APTR(FeDataHolder) receiver){
	WPTR(PrimValue) 	returnValue;
	returnValue = receiver->value();
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Edition_canMakeRangeIdentical_N2 (APTR(FeEdition) receiver, APTR(FeEdition) arg1){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->canMakeRangeIdentical(arg1);
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Edition_canMakeRangeIdentical_N3 (
		APTR(FeEdition) receiver, 
		APTR(FeEdition) arg1, 
		APTR(XnRegion) arg2)
{
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->canMakeRangeIdentical(arg1, arg2);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_combine_N2 (APTR(FeEdition) receiver, APTR(FeEdition) arg1){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->combine(arg1);
	return returnValue;
}


RPTR(CoordinateSpace) RequestHandler::Edition_coordinateSpace_N1 (APTR(FeEdition) receiver){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = receiver->coordinateSpace();
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_copy_N2 (APTR(FeEdition) receiver, APTR(XnRegion) arg1){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->copy(arg1);
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::Edition_cost_N2 (APTR(FeEdition) receiver, APTR(PrimIntValue) arg1){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->cost(arg1->asInt32()));
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::Edition_count_N1 (APTR(FeEdition) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->count());
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Edition_domain_N1 (APTR(FeEdition) receiver){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->domain();
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_empty_N1 (APTR(CoordinateSpace) arg1){
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::empty(arg1);
	return returnValue;
}


void RequestHandler::Edition_endorse_N2 (APTR(FeEdition) receiver, APTR(CrossRegion) arg1){
	receiver->endorse(arg1);
}


RPTR(CrossRegion) RequestHandler::Edition_endorsements_N1 (APTR(FeEdition) receiver){
	WPTR(CrossRegion) 	returnValue;
	returnValue = receiver->endorsements();
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_fromAll_N2 (APTR(XnRegion) arg1, APTR(FeRangeElement) arg2){
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::fromAll(arg1, arg2);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_fromArray_N1 (APTR(PrimArray) arg1){
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::fromArray(arg1);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_fromArray_N2 (APTR(PrimArray) arg1, APTR(XnRegion) arg2){
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::fromArray(arg1, arg2);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_fromArray_N3 (
		APTR(PrimArray) arg1, 
		APTR(XnRegion) arg2, 
		APTR(OrderSpec) arg3)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::fromArray(arg1, arg2, arg3);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_fromOne_N2 (APTR(Position) arg1, APTR(FeRangeElement) arg2){
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::fromOne(arg1, arg2);
	return returnValue;
}


RPTR(FeRangeElement) RequestHandler::Edition_get_N2 (APTR(FeEdition) receiver, APTR(Position) arg1){
	WPTR(FeRangeElement) 	returnValue;
	returnValue = receiver->get(arg1);
	return returnValue;
}


BooleanVar RequestHandler::Edition_hasPosition_N2 (APTR(FeEdition) receiver, APTR(Position) arg1){
	return receiver->hasPosition(arg1);
}


BooleanVar RequestHandler::Edition_isEmpty_N1 (APTR(FeEdition) receiver){
	return receiver->isEmpty();
}


BooleanVar RequestHandler::Edition_isFinite_N1 (APTR(FeEdition) receiver){
	return receiver->isFinite();
}


BooleanVar RequestHandler::Edition_isRangeIdentical_N2 (APTR(FeEdition) receiver, APTR(FeEdition) arg1){
	return receiver->isRangeIdentical(arg1);
}


RPTR(FeEdition) RequestHandler::Edition_makeRangeIdentical_N2 (APTR(FeEdition) receiver, APTR(FeEdition) arg1){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->makeRangeIdentical(arg1);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_makeRangeIdentical_N3 (
		APTR(FeEdition) receiver, 
		APTR(FeEdition) arg1, 
		APTR(XnRegion) arg2)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->makeRangeIdentical(arg1, arg2);
	return returnValue;
}


RPTR(Mapping) RequestHandler::Edition_mapSharedOnto_N2 (APTR(FeEdition) receiver, APTR(FeEdition) arg1){
	WPTR(Mapping) 	returnValue;
	returnValue = receiver->mapSharedOnto(arg1);
	return returnValue;
}


RPTR(Mapping) RequestHandler::Edition_mapSharedTo_N2 (APTR(FeEdition) receiver, APTR(FeEdition) arg1){
	WPTR(Mapping) 	returnValue;
	returnValue = receiver->mapSharedTo(arg1);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_notSharedWith_N2 (APTR(FeEdition) receiver, APTR(FeEdition) arg1){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->notSharedWith(arg1);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_notSharedWith_N3 (
		APTR(FeEdition) receiver, 
		APTR(FeEdition) arg1, 
		APTR(PrimIntValue) arg2)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->notSharedWith(arg1, arg2->asInt32());
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_placeHolders_N1 (APTR(XnRegion) arg1){
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::placeHolders(arg1);
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Edition_positionsLabelled_N2 (APTR(FeEdition) receiver, APTR(FeLabel) arg1){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->positionsLabelled(arg1);
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Edition_positionsOf_N2 (APTR(FeEdition) receiver, APTR(FeRangeElement) arg1){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->positionsOf(arg1);
	return returnValue;
}


RPTR(IDRegion) RequestHandler::Edition_rangeOwners_N2 (APTR(FeEdition) receiver, APTR(XnRegion) arg1){
	WPTR(IDRegion) 	returnValue;
	returnValue = receiver->rangeOwners(arg1);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_rangeTranscluders_N1 (APTR(FeEdition) receiver){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->rangeTranscluders();
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_rangeTranscluders_N2 (APTR(FeEdition) receiver, APTR(XnRegion) arg1){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->rangeTranscluders(arg1);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_rangeTranscluders_N3 (
		APTR(FeEdition) receiver, 
		APTR(XnRegion) arg1, 
		APTR(Filter) arg2)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->rangeTranscluders(arg1, arg2);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_rangeTranscluders_N4 (
		APTR(FeEdition) receiver, 
		APTR(XnRegion) arg1, 
		APTR(Filter) arg2, 
		APTR(Filter) arg3)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->rangeTranscluders(arg1, arg2, arg3);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_rangeTranscluders_N5 (
		APTR(FeEdition) receiver, 
		APTR(XnRegion) arg1, 
		APTR(Filter) arg2, 
		APTR(Filter) arg3, 
		APTR(PrimIntValue) arg4)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->rangeTranscluders(arg1, arg2, arg3, arg4->asInt32());
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_rangeTranscluders_N6 (
		APTR(FeEdition) receiver, 
		APTR(XnRegion) arg1, 
		APTR(Filter) arg2, 
		APTR(Filter) arg3, 
		APTR(PrimIntValue) arg4, 
		APTR(FeEdition) arg5)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->rangeTranscluders(arg1, arg2, arg3, arg4->asInt32(), arg5);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_rangeWorks_N1 (APTR(FeEdition) receiver){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->rangeWorks();
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_rangeWorks_N2 (APTR(FeEdition) receiver, APTR(XnRegion) arg1){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->rangeWorks(arg1);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_rangeWorks_N3 (
		APTR(FeEdition) receiver, 
		APTR(XnRegion) arg1, 
		APTR(Filter) arg2)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->rangeWorks(arg1, arg2);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_rangeWorks_N4 (
		APTR(FeEdition) receiver, 
		APTR(XnRegion) arg1, 
		APTR(Filter) arg2, 
		APTR(PrimIntValue) arg3)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->rangeWorks(arg1, arg2, arg3->asInt32());
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_rangeWorks_N5 (
		APTR(FeEdition) receiver, 
		APTR(XnRegion) arg1, 
		APTR(Filter) arg2, 
		APTR(PrimIntValue) arg3, 
		APTR(FeEdition) arg4)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->rangeWorks(arg1, arg2, arg3->asInt32(), arg4);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_rebind_N3 (
		APTR(FeEdition) receiver, 
		APTR(Position) arg1, 
		APTR(FeEdition) arg2)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->rebind(arg1, arg2);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_replace_N2 (APTR(FeEdition) receiver, APTR(FeEdition) arg1){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->replace(arg1);
	return returnValue;
}


void RequestHandler::Edition_retract_N2 (APTR(FeEdition) receiver, APTR(CrossRegion) arg1){
	receiver->retract(arg1);
}


RPTR(Stepper) RequestHandler::Edition_retrieve_N1 (APTR(FeEdition) receiver){
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->retrieve();
	return returnValue;
}


RPTR(Stepper) RequestHandler::Edition_retrieve_N2 (APTR(FeEdition) receiver, APTR(XnRegion) arg1){
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->retrieve(arg1);
	return returnValue;
}


RPTR(Stepper) RequestHandler::Edition_retrieve_N3 (
		APTR(FeEdition) receiver, 
		APTR(XnRegion) arg1, 
		APTR(OrderSpec) arg2)
{
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->retrieve(arg1, arg2);
	return returnValue;
}


RPTR(Stepper) RequestHandler::Edition_retrieve_N4 (
		APTR(FeEdition) receiver, 
		APTR(XnRegion) arg1, 
		APTR(OrderSpec) arg2, 
		APTR(PrimIntValue) arg3)
{
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->retrieve(arg1, arg2, arg3->asInt32());
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_setRangeOwners_N2 (APTR(FeEdition) receiver, APTR(ID) arg1){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->setRangeOwners(arg1);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_setRangeOwners_N3 (
		APTR(FeEdition) receiver, 
		APTR(ID) arg1, 
		APTR(XnRegion) arg2)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->setRangeOwners(arg1, arg2);
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Edition_sharedRegion_N2 (APTR(FeEdition) receiver, APTR(FeEdition) arg1){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->sharedRegion(arg1);
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Edition_sharedRegion_N3 (
		APTR(FeEdition) receiver, 
		APTR(FeEdition) arg1, 
		APTR(PrimIntValue) arg2)
{
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->sharedRegion(arg1, arg2->asInt32());
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_sharedWith_N2 (APTR(FeEdition) receiver, APTR(FeEdition) arg1){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->sharedWith(arg1);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_sharedWith_N3 (
		APTR(FeEdition) receiver, 
		APTR(FeEdition) arg1, 
		APTR(PrimIntValue) arg2)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->sharedWith(arg1, arg2->asInt32());
	return returnValue;
}


RPTR(TableStepper) RequestHandler::Edition_stepper_N1 (APTR(FeEdition) receiver){
	WPTR(TableStepper) 	returnValue;
	returnValue = receiver->stepper();
	return returnValue;
}


RPTR(TableStepper) RequestHandler::Edition_stepper_N2 (APTR(FeEdition) receiver, APTR(XnRegion) arg1){
	WPTR(TableStepper) 	returnValue;
	returnValue = receiver->stepper(arg1);
	return returnValue;
}


RPTR(TableStepper) RequestHandler::Edition_stepper_N3 (
		APTR(FeEdition) receiver, 
		APTR(XnRegion) arg1, 
		APTR(OrderSpec) arg2)
{
	WPTR(TableStepper) 	returnValue;
	returnValue = receiver->stepper(arg1, arg2);
	return returnValue;
}


RPTR(FeRangeElement) RequestHandler::Edition_theOne_N1 (APTR(FeEdition) receiver){
	WPTR(FeRangeElement) 	returnValue;
	returnValue = receiver->theOne();
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_transformedBy_N2 (APTR(FeEdition) receiver, APTR(Mapping) arg1){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->transformedBy(arg1);
	return returnValue;
}


RPTR(CrossRegion) RequestHandler::Edition_visibleEndorsements_N1 (APTR(FeEdition) receiver){
	WPTR(CrossRegion) 	returnValue;
	returnValue = receiver->visibleEndorsements();
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_with_N3 (
		APTR(FeEdition) receiver, 
		APTR(Position) arg1, 
		APTR(FeRangeElement) arg2)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->with(arg1, arg2);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_withAll_N3 (
		APTR(FeEdition) receiver, 
		APTR(XnRegion) arg1, 
		APTR(FeRangeElement) arg2)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->withAll(arg1, arg2);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_without_N2 (APTR(FeEdition) receiver, APTR(Position) arg1){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->without(arg1);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Edition_withoutAll_N2 (APTR(FeEdition) receiver, APTR(XnRegion) arg1){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->withoutAll(arg1);
	return returnValue;
}


RPTR(FeRangeElement) RequestHandler::ElementBundle_element_N1 (APTR(FeElementBundle) receiver){
	WPTR(FeRangeElement) 	returnValue;
	returnValue = receiver->element();
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Filter_baseRegion_N1 (APTR(Filter) receiver){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->baseRegion();
	return returnValue;
}


RPTR(Stepper) RequestHandler::Filter_intersectedFilters_N1 (APTR(Filter) receiver){
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->intersectedFilters();
	return returnValue;
}


BooleanVar RequestHandler::Filter_isAllFilter_N1 (APTR(Filter) receiver){
	return receiver->isAllFilter();
}


BooleanVar RequestHandler::Filter_isAnyFilter_N1 (APTR(Filter) receiver){
	return receiver->isAnyFilter();
}


BooleanVar RequestHandler::Filter_match_N2 (APTR(Filter) receiver, APTR(XnRegion) arg1){
	return receiver->match(arg1);
}


RPTR(Stepper) RequestHandler::Filter_unionedFilters_N1 (APTR(Filter) receiver){
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->unionedFilters();
	return returnValue;
}


RPTR(XnRegion) RequestHandler::FilterPosition_baseRegion_N1 (APTR(FilterPosition) receiver){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->baseRegion();
	return returnValue;
}


RPTR(Filter) RequestHandler::FilterSpace_allFilter_N2 (APTR(FilterSpace) receiver, APTR(XnRegion) arg1){
	WPTR(Filter) 	returnValue;
	returnValue = receiver->allFilter(arg1);
	return returnValue;
}


RPTR(Filter) RequestHandler::FilterSpace_anyFilter_N2 (APTR(FilterSpace) receiver, APTR(XnRegion) arg1){
	WPTR(Filter) 	returnValue;
	returnValue = receiver->anyFilter(arg1);
	return returnValue;
}


RPTR(CoordinateSpace) RequestHandler::FilterSpace_baseSpace_N1 (APTR(FilterSpace) receiver){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = receiver->baseSpace();
	return returnValue;
}


RPTR(FilterSpace) RequestHandler::FilterSpace_make_N1 (APTR(CoordinateSpace) arg1){
	WPTR(FilterSpace) 	returnValue;
	returnValue = FilterSpace::make (arg1);
	return returnValue;
}


RPTR(FilterPosition) RequestHandler::FilterSpace_position_N2 (APTR(FilterSpace) receiver, APTR(XnRegion) arg1){
	WPTR(FilterPosition) 	returnValue;
	returnValue = receiver->position(arg1);
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::FloatArray_bitCount_N1 (APTR(PrimFloatArray) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->bitCount());
	return returnValue;
}


RPTR(PrimFloatArray) RequestHandler::FloatArray_zeros_N2 (APTR(PrimIntValue) arg1, APTR(PrimIntValue) arg2){
	WPTR(PrimFloatArray) 	returnValue;
	returnValue = PrimFloatArray::zeros(arg1->asInt32(), arg2->asInt32());
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::FloatValue_bitCount_N1 (APTR(PrimFloatValue) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->bitCount());
	return returnValue;
}


RPTR(IntegerVarArray) RequestHandler::HumberArray_zeros_N1 (APTR(PrimIntValue) arg1){
	WPTR(IntegerVarArray) 	returnValue;
	returnValue = IntegerVarArray::zeros(arg1->asInt32());
	return returnValue;
}


RPTR(FeHyperRef) RequestHandler::HyperLink_endAt_N2 (APTR(FeHyperLink) receiver, APTR(Sequence) arg1){
	WPTR(FeHyperRef) 	returnValue;
	returnValue = receiver->endAt(arg1);
	return returnValue;
}


RPTR(SequenceRegion) RequestHandler::HyperLink_endNames_N1 (APTR(FeHyperLink) receiver){
	WPTR(SequenceRegion) 	returnValue;
	returnValue = receiver->endNames();
	return returnValue;
}


RPTR(FeSet) RequestHandler::HyperLink_linkTypes_N1 (APTR(FeHyperLink) receiver){
	WPTR(FeSet) 	returnValue;
	returnValue = receiver->linkTypes();
	return returnValue;
}


RPTR(FeHyperLink) RequestHandler::HyperLink_make_N3 (
		APTR(FeSet) arg1, 
		APTR(FeHyperRef) arg2, 
		APTR(FeHyperRef) arg3)
{
	WPTR(FeHyperLink) 	returnValue;
	returnValue = FeHyperLink::make (arg1, arg2, arg3);
	return returnValue;
}


RPTR(FeHyperLink) RequestHandler::HyperLink_withEnd_N3 (
		APTR(FeHyperLink) receiver, 
		APTR(Sequence) arg1, 
		APTR(FeHyperRef) arg2)
{
	WPTR(FeHyperLink) 	returnValue;
	returnValue = receiver->withEnd(arg1, arg2);
	return returnValue;
}


RPTR(FeHyperLink) RequestHandler::HyperLink_withLinkTypes_N2 (APTR(FeHyperLink) receiver, APTR(FeSet) arg1){
	WPTR(FeHyperLink) 	returnValue;
	returnValue = receiver->withLinkTypes(arg1);
	return returnValue;
}


RPTR(FeHyperLink) RequestHandler::HyperLink_withoutEnd_N2 (APTR(FeHyperLink) receiver, APTR(Sequence) arg1){
	WPTR(FeHyperLink) 	returnValue;
	returnValue = receiver->withoutEnd(arg1);
	return returnValue;
}


RPTR(FeWork) RequestHandler::HyperRef_originalContext_N1 (APTR(FeHyperRef) receiver){
	WPTR(FeWork) 	returnValue;
	returnValue = receiver->originalContext();
	return returnValue;
}


RPTR(FePath) RequestHandler::HyperRef_pathContext_N1 (APTR(FeHyperRef) receiver){
	WPTR(FePath) 	returnValue;
	returnValue = receiver->pathContext();
	return returnValue;
}


RPTR(FeHyperRef) RequestHandler::HyperRef_withOriginalContext_N2 (APTR(FeHyperRef) receiver, APTR(FeWork) arg1){
	WPTR(FeHyperRef) 	returnValue;
	returnValue = receiver->withOriginalContext(arg1);
	return returnValue;
}


RPTR(FeHyperRef) RequestHandler::HyperRef_withPathContext_N2 (APTR(FeHyperRef) receiver, APTR(FePath) arg1){
	WPTR(FeHyperRef) 	returnValue;
	returnValue = receiver->withPathContext(arg1);
	return returnValue;
}


RPTR(FeHyperRef) RequestHandler::HyperRef_withWorkContext_N2 (APTR(FeHyperRef) receiver, APTR(FeWork) arg1){
	WPTR(FeHyperRef) 	returnValue;
	returnValue = receiver->withWorkContext(arg1);
	return returnValue;
}


RPTR(FeWork) RequestHandler::HyperRef_workContext_N1 (APTR(FeHyperRef) receiver){
	WPTR(FeWork) 	returnValue;
	returnValue = receiver->workContext();
	return returnValue;
}


RPTR(PrimIntArray) RequestHandler::ID_export_N1 (APTR(ID) receiver){
	WPTR(PrimIntArray) 	returnValue;
	returnValue = receiver->export();
	return returnValue;
}


RPTR(ID) RequestHandler::ID_import_N1 (APTR(PrimIntArray) arg1){
	WPTR(ID) 	returnValue;
	returnValue = ID::import(arg1);
	return returnValue;
}


RPTR(ID) RequestHandler::IDHolder_iD_N1 (APTR(FeIDHolder) receiver){
	WPTR(ID) 	returnValue;
	returnValue = receiver->iD();
	return returnValue;
}


RPTR(FeIDHolder) RequestHandler::IDHolder_make_N1 (APTR(ID) arg1){
	WPTR(FeIDHolder) 	returnValue;
	returnValue = FeIDHolder::make (arg1);
	return returnValue;
}


RPTR(PrimIntArray) RequestHandler::IDRegion_export_N1 (APTR(IDRegion) receiver){
	WPTR(PrimIntArray) 	returnValue;
	returnValue = receiver->export();
	return returnValue;
}


RPTR(IDRegion) RequestHandler::IDRegion_import_N1 (APTR(PrimIntArray) arg1){
	WPTR(IDRegion) 	returnValue;
	returnValue = IDRegion::import(arg1);
	return returnValue;
}


RPTR(PrimIntArray) RequestHandler::IDSpace_export_N1 (APTR(IDSpace) receiver){
	WPTR(PrimIntArray) 	returnValue;
	returnValue = receiver->export();
	return returnValue;
}


RPTR(IDSpace) RequestHandler::IDSpace_global_N0 (){
	WPTR(IDSpace) 	returnValue;
	returnValue = IDSpace::global();
	return returnValue;
}


RPTR(IDRegion) RequestHandler::IDSpace_iDsFromServer_N2 (APTR(IDSpace) receiver, APTR(Sequence) arg1){
	WPTR(IDRegion) 	returnValue;
	returnValue = receiver->iDsFromServer(arg1);
	return returnValue;
}


RPTR(IDSpace) RequestHandler::IDSpace_import_N1 (APTR(PrimIntArray) arg1){
	WPTR(IDSpace) 	returnValue;
	returnValue = IDSpace::import(arg1);
	return returnValue;
}


RPTR(ID) RequestHandler::IDSpace_newID_N1 (APTR(IDSpace) receiver){
	WPTR(ID) 	returnValue;
	returnValue = receiver->newID();
	return returnValue;
}


RPTR(IDRegion) RequestHandler::IDSpace_newIDs_N2 (APTR(IDSpace) receiver, APTR(PrimIntValue) arg1){
	WPTR(IDRegion) 	returnValue;
	returnValue = receiver->newIDs(arg1->asIntegerVar());
	return returnValue;
}


RPTR(IDSpace) RequestHandler::IDSpace_unique_N0 (){
	WPTR(IDSpace) 	returnValue;
	returnValue = IDSpace::unique();
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::IntArray_bitCount_N1 (APTR(PrimIntArray) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->bitCount());
	return returnValue;
}


RPTR(PrimIntArray) RequestHandler::IntArray_zeros_N2 (APTR(PrimIntValue) arg1, APTR(PrimIntValue) arg2){
	WPTR(PrimIntArray) 	returnValue;
	returnValue = PrimIntArray::zeros(arg1->asInt32(), arg2->asInt32());
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::Integer_value_N1 (APTR(IntegerPos) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->value());
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::IntegerMapping_translation_N1 (APTR(IntegerMapping) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->translation());
	return returnValue;
}


RPTR(Stepper) RequestHandler::IntegerRegion_intervals_N1 (APTR(IntegerRegion) receiver){
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->intervals();
	return returnValue;
}


RPTR(Stepper) RequestHandler::IntegerRegion_intervals_N2 (APTR(IntegerRegion) receiver, APTR(OrderSpec) arg1){
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->intervals(arg1);
	return returnValue;
}


BooleanVar RequestHandler::IntegerRegion_isBoundedAbove_N1 (APTR(IntegerRegion) receiver){
	return receiver->isBoundedAbove();
}


BooleanVar RequestHandler::IntegerRegion_isBoundedBelow_N1 (APTR(IntegerRegion) receiver){
	return receiver->isBoundedBelow();
}


BooleanVar RequestHandler::IntegerRegion_isInterval_N1 (APTR(IntegerRegion) receiver){
	return receiver->isInterval();
}


RPTR(PrimIntValue) RequestHandler::IntegerRegion_start_N1 (APTR(IntegerRegion) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->start());
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::IntegerRegion_stop_N1 (APTR(IntegerRegion) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->stop());
	return returnValue;
}


RPTR(IntegerRegion) RequestHandler::IntegerSpace_above_N2 (APTR(IntegerPos) arg1, BooleanVar arg2){
	WPTR(IntegerRegion) 	returnValue;
	returnValue = IntegerSpace::implicitReceiver()->above(arg1, arg2);
	return returnValue;
}


RPTR(IntegerRegion) RequestHandler::IntegerSpace_below_N2 (APTR(IntegerPos) arg1, BooleanVar arg2){
	WPTR(IntegerRegion) 	returnValue;
	returnValue = IntegerSpace::implicitReceiver()->below(arg1, arg2);
	return returnValue;
}


RPTR(IntegerRegion) RequestHandler::IntegerSpace_interval_N2 (APTR(IntegerPos) arg1, APTR(IntegerPos) arg2){
	WPTR(IntegerRegion) 	returnValue;
	returnValue = IntegerSpace::implicitReceiver()->interval(arg1, arg2);
	return returnValue;
}


RPTR(IntegerSpace) RequestHandler::IntegerSpace_make_N0 (){
	WPTR(IntegerSpace) 	returnValue;
	returnValue = IntegerSpace::make ();
	return returnValue;
}


RPTR(IntegerPos) RequestHandler::IntegerSpace_position_N1 (APTR(PrimIntValue) arg1){
	WPTR(IntegerPos) 	returnValue;
	returnValue = IntegerSpace::implicitReceiver()->position(arg1->asIntegerVar());
	return returnValue;
}


RPTR(IntegerMapping) RequestHandler::IntegerSpace_translation_N1 (APTR(PrimIntValue) arg1){
	WPTR(IntegerMapping) 	returnValue;
	returnValue = IntegerSpace::implicitReceiver()->translation(arg1->asIntegerVar());
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::IntValue_bitCount_N1 (APTR(PrimIntValue) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->bitCount());
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::IntValue_bitwiseAnd_N2 (APTR(PrimIntValue) receiver, APTR(PrimIntValue) arg1){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->bitwiseAnd(arg1));
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::IntValue_bitwiseOr_N2 (APTR(PrimIntValue) receiver, APTR(PrimIntValue) arg1){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->bitwiseOr(arg1));
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::IntValue_bitwiseXor_N2 (APTR(PrimIntValue) receiver, APTR(PrimIntValue) arg1){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->bitwiseXor(arg1));
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::IntValue_dividedBy_N2 (APTR(PrimIntValue) receiver, APTR(PrimIntValue) arg1){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->dividedBy(arg1));
	return returnValue;
}


BooleanVar RequestHandler::IntValue_isGE_N2 (APTR(PrimIntValue) receiver, APTR(PrimIntValue) arg1){
	return receiver->isGE(arg1);
}


RPTR(PrimIntValue) RequestHandler::IntValue_leftShift_N2 (APTR(PrimIntValue) receiver, APTR(PrimIntValue) arg1){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->leftShift(arg1));
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::IntValue_maximum_N2 (APTR(PrimIntValue) receiver, APTR(PrimIntValue) arg1){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->maximum(arg1));
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::IntValue_minimum_N2 (APTR(PrimIntValue) receiver, APTR(PrimIntValue) arg1){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->minimum(arg1));
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::IntValue_minus_N2 (APTR(PrimIntValue) receiver, APTR(PrimIntValue) arg1){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->minus(arg1));
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::IntValue_mod_N2 (APTR(PrimIntValue) receiver, APTR(PrimIntValue) arg1){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->mod(arg1));
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::IntValue_plus_N2 (APTR(PrimIntValue) receiver, APTR(PrimIntValue) arg1){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->plus(arg1));
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::IntValue_times_N2 (APTR(PrimIntValue) receiver, APTR(PrimIntValue) arg1){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->times(arg1));
	return returnValue;
}


RPTR(IDRegion) RequestHandler::KeyMaster_actualAuthority_N1 (APTR(FeKeyMaster) receiver){
	WPTR(IDRegion) 	returnValue;
	returnValue = receiver->actualAuthority();
	return returnValue;
}


RPTR(FeKeyMaster) RequestHandler::KeyMaster_copy_N1 (APTR(FeKeyMaster) receiver){
	WPTR(FeKeyMaster) 	returnValue;
	returnValue = receiver->copy();
	return returnValue;
}


BooleanVar RequestHandler::KeyMaster_hasAuthority_N2 (APTR(FeKeyMaster) receiver, APTR(ID) arg1){
	return receiver->hasAuthority(arg1);
}


void RequestHandler::KeyMaster_incorporate_N2 (APTR(FeKeyMaster) receiver, APTR(FeKeyMaster) arg1){
	receiver->incorporate(arg1);
}


RPTR(IDRegion) RequestHandler::KeyMaster_loginAuthority_N1 (APTR(FeKeyMaster) receiver){
	WPTR(IDRegion) 	returnValue;
	returnValue = receiver->loginAuthority();
	return returnValue;
}


void RequestHandler::KeyMaster_removeLogins_N2 (APTR(FeKeyMaster) receiver, APTR(IDRegion) arg1){
	receiver->removeLogins(arg1);
}


RPTR(FeLabel) RequestHandler::Label_make_N0 (){
	WPTR(FeLabel) 	returnValue;
	returnValue = FeLabel::make ();
	return returnValue;
}


RPTR(Mapping) RequestHandler::Mapping_combine_N2 (APTR(Mapping) receiver, APTR(Mapping) arg1){
	WPTR(Mapping) 	returnValue;
	returnValue = receiver->combine(arg1);
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Mapping_domain_N1 (APTR(Mapping) receiver){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->domain();
	return returnValue;
}


RPTR(CoordinateSpace) RequestHandler::Mapping_domainSpace_N1 (APTR(Mapping) receiver){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = receiver->domainSpace();
	return returnValue;
}


RPTR(Mapping) RequestHandler::Mapping_inverse_N1 (APTR(Mapping) receiver){
	WPTR(Mapping) 	returnValue;
	returnValue = receiver->inverse();
	return returnValue;
}


BooleanVar RequestHandler::Mapping_isComplete_N1 (APTR(Mapping) receiver){
	return receiver->isComplete();
}


BooleanVar RequestHandler::Mapping_isIdentity_N1 (APTR(Mapping) receiver){
	return receiver->isIdentity();
}


RPTR(Position) RequestHandler::Mapping_of_N2 (APTR(Mapping) receiver, APTR(Position) arg1){
	WPTR(Position) 	returnValue;
	returnValue = receiver->of(arg1);
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Mapping_ofAll_N2 (APTR(Mapping) receiver, APTR(XnRegion) arg1){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->ofAll(arg1);
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Mapping_range_N1 (APTR(Mapping) receiver){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->range();
	return returnValue;
}


RPTR(CoordinateSpace) RequestHandler::Mapping_rangeSpace_N1 (APTR(Mapping) receiver){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = receiver->rangeSpace();
	return returnValue;
}


RPTR(Mapping) RequestHandler::Mapping_restrict_N2 (APTR(Mapping) receiver, APTR(XnRegion) arg1){
	WPTR(Mapping) 	returnValue;
	returnValue = receiver->restrict(arg1);
	return returnValue;
}


RPTR(Stepper) RequestHandler::Mapping_simplerMappings_N1 (APTR(Mapping) receiver){
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->simplerMappings();
	return returnValue;
}


RPTR(Mapping) RequestHandler::Mapping_unrestricted_N1 (APTR(Mapping) receiver){
	WPTR(Mapping) 	returnValue;
	returnValue = receiver->unrestricted();
	return returnValue;
}


RPTR(FeKeyMaster) RequestHandler::MatchLock_encryptedPassword_N2 (APTR(MatchLock) receiver, APTR(PrimIntArray) arg1){
	WPTR(FeKeyMaster) 	returnValue;
	returnValue = receiver->encryptedPassword(arg1);
	return returnValue;
}


RPTR(FeMatchLockSmith) RequestHandler::MatchLockSmith_make_N2 (APTR(PrimIntArray) arg1, APTR(Sequence) arg2){
	WPTR(FeMatchLockSmith) 	returnValue;
	returnValue = FeMatchLockSmith::make (arg1, arg2);
	return returnValue;
}


RPTR(PrimIntArray) RequestHandler::MatchLockSmith_scrambledPassword_N1 (APTR(FeMatchLockSmith) receiver){
	WPTR(PrimIntArray) 	returnValue;
	returnValue = receiver->scrambledPassword();
	return returnValue;
}


RPTR(PrimIntArray) RequestHandler::MatchLockSmith_scramblerName_N1 (APTR(FeMatchLockSmith) receiver){
	WPTR(PrimIntArray) 	returnValue;
	returnValue = receiver->scramblerName();
	return returnValue;
}


RPTR(Lock) RequestHandler::MultiLock_lock_N2 (APTR(MultiLock) receiver, APTR(Sequence) arg1){
	WPTR(Lock) 	returnValue;
	returnValue = receiver->lock(arg1);
	return returnValue;
}


RPTR(SequenceRegion) RequestHandler::MultiLock_lockNames_N1 (APTR(MultiLock) receiver){
	WPTR(SequenceRegion) 	returnValue;
	returnValue = receiver->lockNames();
	return returnValue;
}


RPTR(FeLockSmith) RequestHandler::MultiLockSmith_lockSmith_N2 (APTR(FeMultiLockSmith) receiver, APTR(Sequence) arg1){
	WPTR(FeLockSmith) 	returnValue;
	returnValue = receiver->lockSmith(arg1);
	return returnValue;
}


RPTR(SequenceRegion) RequestHandler::MultiLockSmith_lockSmithNames_N1 (APTR(FeMultiLockSmith) receiver){
	WPTR(SequenceRegion) 	returnValue;
	returnValue = receiver->lockSmithNames();
	return returnValue;
}


RPTR(FeMultiLockSmith) RequestHandler::MultiLockSmith_make_N0 (){
	WPTR(FeMultiLockSmith) 	returnValue;
	returnValue = FeMultiLockSmith::make ();
	return returnValue;
}


RPTR(FeMultiLockSmith) RequestHandler::MultiLockSmith_with_N3 (
		APTR(FeMultiLockSmith) receiver, 
		APTR(Sequence) arg1, 
		APTR(FeLockSmith) arg2)
{
	WPTR(FeMultiLockSmith) 	returnValue;
	returnValue = receiver->with(arg1, arg2);
	return returnValue;
}


RPTR(FeMultiLockSmith) RequestHandler::MultiLockSmith_without_N2 (APTR(FeMultiLockSmith) receiver, APTR(Sequence) arg1){
	WPTR(FeMultiLockSmith) 	returnValue;
	returnValue = receiver->without(arg1);
	return returnValue;
}


RPTR(FeMultiRef) RequestHandler::MultiRef_intersect_N2 (APTR(FeMultiRef) receiver, APTR(FeMultiRef) arg1){
	WPTR(FeMultiRef) 	returnValue;
	returnValue = receiver->intersect(arg1);
	return returnValue;
}


RPTR(FeMultiRef) RequestHandler::MultiRef_make_N1 (APTR(PtrArray) arg1){
	WPTR(FeMultiRef) 	returnValue;
	returnValue = FeMultiRef::make (arg1);
	return returnValue;
}


RPTR(FeMultiRef) RequestHandler::MultiRef_make_N2 (APTR(PtrArray) arg1, APTR(FeWork) arg2){
	WPTR(FeMultiRef) 	returnValue;
	returnValue = FeMultiRef::make (arg1, arg2);
	return returnValue;
}


RPTR(FeMultiRef) RequestHandler::MultiRef_make_N3 (
		APTR(PtrArray) arg1, 
		APTR(FeWork) arg2, 
		APTR(FeWork) arg3)
{
	WPTR(FeMultiRef) 	returnValue;
	returnValue = FeMultiRef::make (arg1, arg2, arg3);
	return returnValue;
}


RPTR(FeMultiRef) RequestHandler::MultiRef_make_N4 (
		APTR(PtrArray) arg1, 
		APTR(FeWork) arg2, 
		APTR(FeWork) arg3, 
		APTR(FePath) arg4)
{
	WPTR(FeMultiRef) 	returnValue;
	returnValue = FeMultiRef::make (arg1, arg2, arg3, arg4);
	return returnValue;
}


RPTR(FeMultiRef) RequestHandler::MultiRef_minus_N2 (APTR(FeMultiRef) receiver, APTR(FeMultiRef) arg1){
	WPTR(FeMultiRef) 	returnValue;
	returnValue = receiver->minus(arg1);
	return returnValue;
}


RPTR(Stepper) RequestHandler::MultiRef_refs_N1 (APTR(FeMultiRef) receiver){
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->refs();
	return returnValue;
}


RPTR(FeMultiRef) RequestHandler::MultiRef_unionWith_N2 (APTR(FeMultiRef) receiver, APTR(FeMultiRef) arg1){
	WPTR(FeMultiRef) 	returnValue;
	returnValue = receiver->unionWith(arg1);
	return returnValue;
}


RPTR(FeMultiRef) RequestHandler::MultiRef_with_N2 (APTR(FeMultiRef) receiver, APTR(FeHyperRef) arg1){
	WPTR(FeMultiRef) 	returnValue;
	returnValue = receiver->with(arg1);
	return returnValue;
}


RPTR(FeMultiRef) RequestHandler::MultiRef_without_N2 (APTR(FeMultiRef) receiver, APTR(FeHyperRef) arg1){
	WPTR(FeMultiRef) 	returnValue;
	returnValue = receiver->without(arg1);
	return returnValue;
}


RPTR(CoordinateSpace) RequestHandler::OrderSpec_coordinateSpace_N1 (APTR(OrderSpec) receiver){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = receiver->coordinateSpace();
	return returnValue;
}


BooleanVar RequestHandler::OrderSpec_follows_N3 (
		APTR(OrderSpec) receiver, 
		APTR(Position) arg1, 
		APTR(Position) arg2)
{
	return receiver->follows(arg1, arg2);
}


RPTR(OrderSpec) RequestHandler::OrderSpec_reversed_N1 (APTR(OrderSpec) receiver){
	WPTR(OrderSpec) 	returnValue;
	returnValue = receiver->reversed();
	return returnValue;
}


RPTR(FeRangeElement) RequestHandler::Path_follow_N2 (APTR(FePath) receiver, APTR(FeEdition) arg1){
	WPTR(FeRangeElement) 	returnValue;
	returnValue = receiver->follow(arg1);
	return returnValue;
}


RPTR(FePath) RequestHandler::Path_make_N1 (APTR(PtrArray) arg1){
	WPTR(FePath) 	returnValue;
	returnValue = FePath::make (arg1);
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Position_asRegion_N1 (APTR(Position) receiver){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->asRegion();
	return returnValue;
}


RPTR(CoordinateSpace) RequestHandler::Position_coordinateSpace_N1 (APTR(Position) receiver){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = receiver->coordinateSpace();
	return returnValue;
}


RPTR(PtrArray) RequestHandler::PtrArray_nulls_N1 (APTR(PrimIntValue) arg1){
	WPTR(PtrArray) 	returnValue;
	returnValue = PtrArray::nulls(arg1->asInt32());
	return returnValue;
}


RPTR(FeRangeElement) RequestHandler::RangeElement_again_N1 (APTR(FeRangeElement) receiver){
	WPTR(FeRangeElement) 	returnValue;
	returnValue = receiver->again();
	return returnValue;
}


BooleanVar RequestHandler::RangeElement_canMakeIdentical_N2 (APTR(FeRangeElement) receiver, APTR(FeRangeElement) arg1){
	return receiver->canMakeIdentical(arg1);
}


BooleanVar RequestHandler::RangeElement_isIdentical_N2 (APTR(FeRangeElement) receiver, APTR(FeRangeElement) arg1){
	return receiver->isIdentical(arg1);
}


RPTR(FeLabel) RequestHandler::RangeElement_label_N1 (APTR(FeRangeElement) receiver){
	WPTR(FeLabel) 	returnValue;
	returnValue = receiver->label();
	return returnValue;
}


void RequestHandler::RangeElement_makeIdentical_N2 (APTR(FeRangeElement) receiver, APTR(FeRangeElement) arg1){
	receiver->makeIdentical(arg1);
}


RPTR(ID) RequestHandler::RangeElement_owner_N1 (APTR(FeRangeElement) receiver){
	WPTR(ID) 	returnValue;
	returnValue = receiver->owner();
	return returnValue;
}


RPTR(FeRangeElement) RequestHandler::RangeElement_placeHolder_N0 (){
	WPTR(FeRangeElement) 	returnValue;
	returnValue = FeRangeElement::placeHolder();
	return returnValue;
}


RPTR(FeRangeElement) RequestHandler::RangeElement_relabelled_N2 (APTR(FeRangeElement) receiver, APTR(FeLabel) arg1){
	WPTR(FeRangeElement) 	returnValue;
	returnValue = receiver->relabelled(arg1);
	return returnValue;
}


void RequestHandler::RangeElement_setOwner_N2 (APTR(FeRangeElement) receiver, APTR(ID) arg1){
	receiver->setOwner(arg1);
}


RPTR(FeEdition) RequestHandler::RangeElement_transcluders_N1 (APTR(FeRangeElement) receiver){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->transcluders();
	return returnValue;
}


RPTR(FeEdition) RequestHandler::RangeElement_transcluders_N2 (APTR(FeRangeElement) receiver, APTR(Filter) arg1){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->transcluders(arg1);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::RangeElement_transcluders_N3 (
		APTR(FeRangeElement) receiver, 
		APTR(Filter) arg1, 
		APTR(Filter) arg2)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->transcluders(arg1, arg2);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::RangeElement_transcluders_N4 (
		APTR(FeRangeElement) receiver, 
		APTR(Filter) arg1, 
		APTR(Filter) arg2, 
		APTR(PrimIntValue) arg3)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->transcluders(arg1, arg2, arg3->asInt32());
	return returnValue;
}


RPTR(FeEdition) RequestHandler::RangeElement_transcluders_N5 (
		APTR(FeRangeElement) receiver, 
		APTR(Filter) arg1, 
		APTR(Filter) arg2, 
		APTR(PrimIntValue) arg3, 
		APTR(FeEdition) arg4)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->transcluders(arg1, arg2, arg3->asInt32(), arg4);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::RangeElement_works_N1 (APTR(FeRangeElement) receiver){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->works();
	return returnValue;
}


RPTR(FeEdition) RequestHandler::RangeElement_works_N2 (APTR(FeRangeElement) receiver, APTR(Filter) arg1){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->works(arg1);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::RangeElement_works_N3 (
		APTR(FeRangeElement) receiver, 
		APTR(Filter) arg1, 
		APTR(PrimIntValue) arg2)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->works(arg1, arg2->asInt32());
	return returnValue;
}


RPTR(FeEdition) RequestHandler::RangeElement_works_N4 (
		APTR(FeRangeElement) receiver, 
		APTR(Filter) arg1, 
		APTR(PrimIntValue) arg2, 
		APTR(FeEdition) arg3)
{
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->works(arg1, arg2->asInt32(), arg3);
	return returnValue;
}


RPTR(PrimFloatValue) RequestHandler::Real_value_N1 (APTR(RealPos) receiver){
	WPTR(PrimFloatValue) 	returnValue;
	returnValue = receiver->value();
	return returnValue;
}


RPTR(Stepper) RequestHandler::RealRegion_intervals_N1 (APTR(RealRegion) receiver){
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->intervals();
	return returnValue;
}


RPTR(Stepper) RequestHandler::RealRegion_intervals_N2 (APTR(RealRegion) receiver, APTR(OrderSpec) arg1){
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->intervals(arg1);
	return returnValue;
}


BooleanVar RequestHandler::RealRegion_isBoundedAbove_N1 (APTR(RealRegion) receiver){
	return receiver->isBoundedAbove();
}


BooleanVar RequestHandler::RealRegion_isBoundedBelow_N1 (APTR(RealRegion) receiver){
	return receiver->isBoundedBelow();
}


BooleanVar RequestHandler::RealRegion_isInterval_N1 (APTR(RealRegion) receiver){
	return receiver->isInterval();
}


RPTR(RealPos) RequestHandler::RealRegion_lowerBound_N1 (APTR(RealRegion) receiver){
	WPTR(RealPos) 	returnValue;
	returnValue = receiver->lowerBound();
	return returnValue;
}


RPTR(RealPos) RequestHandler::RealRegion_upperBound_N1 (APTR(RealRegion) receiver){
	WPTR(RealPos) 	returnValue;
	returnValue = receiver->upperBound();
	return returnValue;
}


RPTR(RealRegion) RequestHandler::RealSpace_above_N3 (
		APTR(RealSpace) receiver, 
		APTR(RealPos) arg1, 
		BooleanVar arg2)
{
	WPTR(RealRegion) 	returnValue;
	returnValue = receiver->above(arg1, arg2);
	return returnValue;
}


RPTR(RealRegion) RequestHandler::RealSpace_below_N3 (
		APTR(RealSpace) receiver, 
		APTR(RealPos) arg1, 
		BooleanVar arg2)
{
	WPTR(RealRegion) 	returnValue;
	returnValue = receiver->below(arg1, arg2);
	return returnValue;
}


RPTR(RealRegion) RequestHandler::RealSpace_interval_N3 (
		APTR(RealSpace) receiver, 
		APTR(RealPos) arg1, 
		APTR(RealPos) arg2)
{
	WPTR(RealRegion) 	returnValue;
	returnValue = receiver->interval(arg1, arg2);
	return returnValue;
}


RPTR(RealSpace) RequestHandler::RealSpace_make_N0 (){
	WPTR(RealSpace) 	returnValue;
	returnValue = RealSpace::make ();
	return returnValue;
}


RPTR(RealPos) RequestHandler::RealSpace_position_N2 (APTR(RealSpace) receiver, APTR(PrimFloatValue) arg1){
	WPTR(RealPos) 	returnValue;
	returnValue = receiver->position(arg1->asIEEE64());
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Region_chooseMany_N2 (APTR(XnRegion) receiver, APTR(PrimIntValue) arg1){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->chooseMany(arg1->asIntegerVar());
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Region_chooseMany_N3 (
		APTR(XnRegion) receiver, 
		APTR(PrimIntValue) arg1, 
		APTR(OrderSpec) arg2)
{
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->chooseMany(arg1->asIntegerVar(), arg2);
	return returnValue;
}


RPTR(Position) RequestHandler::Region_chooseOne_N1 (APTR(XnRegion) receiver){
	WPTR(Position) 	returnValue;
	returnValue = receiver->chooseOne();
	return returnValue;
}


RPTR(Position) RequestHandler::Region_chooseOne_N2 (APTR(XnRegion) receiver, APTR(OrderSpec) arg1){
	WPTR(Position) 	returnValue;
	returnValue = receiver->chooseOne(arg1);
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Region_complement_N1 (APTR(XnRegion) receiver){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->complement();
	return returnValue;
}


RPTR(CoordinateSpace) RequestHandler::Region_coordinateSpace_N1 (APTR(XnRegion) receiver){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = receiver->coordinateSpace();
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::Region_count_N1 (APTR(XnRegion) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->count());
	return returnValue;
}


BooleanVar RequestHandler::Region_hasMember_N2 (APTR(XnRegion) receiver, APTR(Position) arg1){
	return receiver->hasMember(arg1);
}


RPTR(XnRegion) RequestHandler::Region_intersect_N2 (APTR(XnRegion) receiver, APTR(XnRegion) arg1){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->intersect(arg1);
	return returnValue;
}


BooleanVar RequestHandler::Region_intersects_N2 (APTR(XnRegion) receiver, APTR(XnRegion) arg1){
	return receiver->intersects(arg1);
}


BooleanVar RequestHandler::Region_isEmpty_N1 (APTR(XnRegion) receiver){
	return receiver->isEmpty();
}


BooleanVar RequestHandler::Region_isFinite_N1 (APTR(XnRegion) receiver){
	return receiver->isFinite();
}


BooleanVar RequestHandler::Region_isFull_N1 (APTR(XnRegion) receiver){
	return receiver->isFull();
}


BooleanVar RequestHandler::Region_isSubsetOf_N2 (APTR(XnRegion) receiver, APTR(XnRegion) arg1){
	return receiver->isSubsetOf(arg1);
}


RPTR(XnRegion) RequestHandler::Region_minus_N2 (APTR(XnRegion) receiver, APTR(XnRegion) arg1){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->minus(arg1);
	return returnValue;
}


RPTR(Stepper) RequestHandler::Region_stepper_N1 (APTR(XnRegion) receiver){
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->stepper();
	return returnValue;
}


RPTR(Stepper) RequestHandler::Region_stepper_N2 (APTR(XnRegion) receiver, APTR(OrderSpec) arg1){
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->stepper(arg1);
	return returnValue;
}


RPTR(Position) RequestHandler::Region_theOne_N1 (APTR(XnRegion) receiver){
	WPTR(Position) 	returnValue;
	returnValue = receiver->theOne();
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Region_unionWith_N2 (APTR(XnRegion) receiver, APTR(XnRegion) arg1){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->unionWith(arg1);
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Region_with_N2 (APTR(XnRegion) receiver, APTR(Position) arg1){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->with(arg1);
	return returnValue;
}


RPTR(XnRegion) RequestHandler::Region_without_N2 (APTR(XnRegion) receiver, APTR(Position) arg1){
	WPTR(XnRegion) 	returnValue;
	returnValue = receiver->without(arg1);
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::Sequence_firstIndex_N1 (APTR(Sequence) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->firstIndex());
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::Sequence_integerAt_N2 (APTR(Sequence) receiver, APTR(PrimIntValue) arg1){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->integerAt(arg1->asIntegerVar()));
	return returnValue;
}


RPTR(PrimArray) RequestHandler::Sequence_integers_N1 (APTR(Sequence) receiver){
	WPTR(PrimArray) 	returnValue;
	returnValue = receiver->integers();
	return returnValue;
}


BooleanVar RequestHandler::Sequence_isZero_N1 (APTR(Sequence) receiver){
	return receiver->isZero();
}


RPTR(PrimIntValue) RequestHandler::Sequence_lastIndex_N1 (APTR(Sequence) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->lastIndex());
	return returnValue;
}


RPTR(Sequence) RequestHandler::Sequence_with_N3 (
		APTR(Sequence) receiver, 
		APTR(PrimIntValue) arg1, 
		APTR(PrimIntValue) arg2)
{
	WPTR(Sequence) 	returnValue;
	returnValue = receiver->with(arg1->asIntegerVar(), arg2->asIntegerVar());
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::SequenceMapping_shift_N1 (APTR(SequenceMapping) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->shift());
	return returnValue;
}


RPTR(Sequence) RequestHandler::SequenceMapping_translation_N1 (APTR(SequenceMapping) receiver){
	WPTR(Sequence) 	returnValue;
	returnValue = receiver->translation();
	return returnValue;
}


RPTR(Stepper) RequestHandler::SequenceRegion_intervals_N1 (APTR(SequenceRegion) receiver){
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->intervals();
	return returnValue;
}


RPTR(Stepper) RequestHandler::SequenceRegion_intervals_N2 (APTR(SequenceRegion) receiver, APTR(OrderSpec) arg1){
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->intervals(arg1);
	return returnValue;
}


BooleanVar RequestHandler::SequenceRegion_isBoundedAbove_N1 (APTR(SequenceRegion) receiver){
	return receiver->isBoundedAbove();
}


BooleanVar RequestHandler::SequenceRegion_isBoundedBelow_N1 (APTR(SequenceRegion) receiver){
	return receiver->isBoundedBelow();
}


BooleanVar RequestHandler::SequenceRegion_isInterval_N1 (APTR(SequenceRegion) receiver){
	return receiver->isInterval();
}


RPTR(Sequence) RequestHandler::SequenceRegion_lowerEdge_N1 (APTR(SequenceRegion) receiver){
	WPTR(Sequence) 	returnValue;
	returnValue = receiver->lowerEdge();
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::SequenceRegion_lowerEdgePrefixLimit_N1 (APTR(SequenceRegion) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->lowerEdgePrefixLimit());
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::SequenceRegion_lowerEdgeType_N1 (APTR(SequenceRegion) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->lowerEdgeType());
	return returnValue;
}


RPTR(Sequence) RequestHandler::SequenceRegion_upperEdge_N1 (APTR(SequenceRegion) receiver){
	WPTR(Sequence) 	returnValue;
	returnValue = receiver->upperEdge();
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::SequenceRegion_upperEdgePrefixLimit_N1 (APTR(SequenceRegion) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->upperEdgePrefixLimit());
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::SequenceRegion_upperEdgeType_N1 (APTR(SequenceRegion) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->upperEdgeType());
	return returnValue;
}


RPTR(SequenceRegion) RequestHandler::SequenceSpace_above_N2 (APTR(Sequence) arg1, BooleanVar arg2){
	WPTR(SequenceRegion) 	returnValue;
	returnValue = SequenceSpace::implicitReceiver()->above(arg1, arg2);
	return returnValue;
}


RPTR(SequenceRegion) RequestHandler::SequenceSpace_below_N2 (APTR(Sequence) arg1, BooleanVar arg2){
	WPTR(SequenceRegion) 	returnValue;
	returnValue = SequenceSpace::implicitReceiver()->below(arg1, arg2);
	return returnValue;
}


RPTR(SequenceRegion) RequestHandler::SequenceSpace_interval_N2 (APTR(Sequence) arg1, APTR(Sequence) arg2){
	WPTR(SequenceRegion) 	returnValue;
	returnValue = SequenceSpace::implicitReceiver()->interval(arg1, arg2);
	return returnValue;
}


RPTR(SequenceSpace) RequestHandler::SequenceSpace_make_N0 (){
	WPTR(SequenceSpace) 	returnValue;
	returnValue = SequenceSpace::make ();
	return returnValue;
}


RPTR(SequenceMapping) RequestHandler::SequenceSpace_mapping_N1 (APTR(PrimIntValue) arg1){
	WPTR(SequenceMapping) 	returnValue;
	returnValue = SequenceSpace::implicitReceiver()->mapping(arg1->asIntegerVar());
	return returnValue;
}


RPTR(SequenceMapping) RequestHandler::SequenceSpace_mapping_N2 (APTR(PrimIntValue) arg1, APTR(Sequence) arg2){
	WPTR(SequenceMapping) 	returnValue;
	returnValue = SequenceSpace::implicitReceiver()->mapping(arg1->asIntegerVar(), arg2);
	return returnValue;
}


RPTR(Sequence) RequestHandler::SequenceSpace_position_N1 (APTR(PrimArray) arg1){
	WPTR(Sequence) 	returnValue;
	returnValue = SequenceSpace::implicitReceiver()->position(arg1);
	return returnValue;
}


RPTR(Sequence) RequestHandler::SequenceSpace_position_N2 (APTR(PrimArray) arg1, APTR(PrimIntValue) arg2){
	WPTR(Sequence) 	returnValue;
	returnValue = SequenceSpace::implicitReceiver()->position(arg1, arg2->asIntegerVar());
	return returnValue;
}


RPTR(SequenceRegion) RequestHandler::SequenceSpace_prefixedBy_N2 (APTR(Sequence) arg1, APTR(PrimIntValue) arg2){
	WPTR(SequenceRegion) 	returnValue;
	returnValue = SequenceSpace::implicitReceiver()->prefixedBy(arg1, arg2->asIntegerVar());
	return returnValue;
}


RPTR(ID) RequestHandler::Server_accessClubID_N0 (){
	WPTR(ID) 	returnValue;
	returnValue = FeServer::accessClubID();
	return returnValue;
}


RPTR(ID) RequestHandler::Server_adminClubID_N0 (){
	WPTR(ID) 	returnValue;
	returnValue = FeServer::adminClubID();
	return returnValue;
}


RPTR(ID) RequestHandler::Server_archiveClubID_N0 (){
	WPTR(ID) 	returnValue;
	returnValue = FeServer::archiveClubID();
	return returnValue;
}


RPTR(ID) RequestHandler::Server_assignID_N1 (APTR(FeRangeElement) arg1){
	WPTR(ID) 	returnValue;
	returnValue = FeServer::assignID(arg1);
	return returnValue;
}


RPTR(ID) RequestHandler::Server_assignID_N2 (APTR(FeRangeElement) arg1, APTR(ID) arg2){
	WPTR(ID) 	returnValue;
	returnValue = FeServer::assignID(arg1, arg2);
	return returnValue;
}


RPTR(ID) RequestHandler::Server_clubDirectoryID_N0 (){
	WPTR(ID) 	returnValue;
	returnValue = FeServer::clubDirectoryID();
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::Server_currentTime_N0 (){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (FeServer::currentTime());
	return returnValue;
}


RPTR(ID) RequestHandler::Server_emptyClubID_N0 (){
	WPTR(ID) 	returnValue;
	returnValue = FeServer::emptyClubID();
	return returnValue;
}


RPTR(Sequence) RequestHandler::Server_encrypterName_N0 (){
	WPTR(Sequence) 	returnValue;
	returnValue = FeServer::encrypterName();
	return returnValue;
}


RPTR(FeRangeElement) RequestHandler::Server_get_N1 (APTR(ID) arg1){
	WPTR(FeRangeElement) 	returnValue;
	returnValue = FeServer::get(arg1);
	return returnValue;
}


RPTR(Sequence) RequestHandler::Server_identifier_N0 (){
	WPTR(Sequence) 	returnValue;
	returnValue = FeServer::identifier();
	return returnValue;
}


RPTR(ID) RequestHandler::Server_iDOf_N1 (APTR(FeRangeElement) arg1){
	WPTR(ID) 	returnValue;
	returnValue = FeServer::iDOf(arg1);
	return returnValue;
}


RPTR(IDRegion) RequestHandler::Server_iDsOf_N1 (APTR(FeRangeElement) arg1){
	WPTR(IDRegion) 	returnValue;
	returnValue = FeServer::iDsOf(arg1);
	return returnValue;
}


RPTR(IDRegion) RequestHandler::Server_iDsOfRange_N1 (APTR(FeEdition) arg1){
	WPTR(IDRegion) 	returnValue;
	returnValue = FeServer::iDsOfRange(arg1);
	return returnValue;
}


RPTR(Lock) RequestHandler::Server_login_N1 (APTR(ID) arg1){
	WPTR(Lock) 	returnValue;
	returnValue = FeServer::login(arg1);
	return returnValue;
}


RPTR(Lock) RequestHandler::Server_loginByName_N1 (APTR(Sequence) arg1){
	WPTR(Lock) 	returnValue;
	returnValue = FeServer::loginByName(arg1);
	return returnValue;
}


RPTR(ID) RequestHandler::Server_publicClubID_N0 (){
	WPTR(ID) 	returnValue;
	returnValue = FeServer::publicClubID();
	return returnValue;
}


RPTR(PrimIntArray) RequestHandler::Server_publicKey_N0 (){
	WPTR(PrimIntArray) 	returnValue;
	returnValue = FeServer::publicKey();
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::Session_connectTime_N1 (APTR(FeSession) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->connectTime());
	return returnValue;
}


RPTR(FeSession) RequestHandler::Session_current_N0 (){
	WPTR(FeSession) 	returnValue;
	returnValue = FeSession::current();
	return returnValue;
}


void RequestHandler::Session_endSession_N1 (APTR(FeSession) receiver){
	receiver->endSession();
}


void RequestHandler::Session_endSession_N2 (APTR(FeSession) receiver, BooleanVar arg1){
	receiver->endSession(arg1);
}


RPTR(ID) RequestHandler::Session_initialLogin_N1 (APTR(FeSession) receiver){
	WPTR(ID) 	returnValue;
	returnValue = receiver->initialLogin();
	return returnValue;
}


BooleanVar RequestHandler::Session_isConnected_N1 (APTR(FeSession) receiver){
	return receiver->isConnected();
}


RPTR(PrimIntArray) RequestHandler::Session_port_N1 (APTR(FeSession) receiver){
	WPTR(PrimIntArray) 	returnValue;
	returnValue = receiver->port();
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::Set_count_N1 (APTR(FeSet) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->count());
	return returnValue;
}


BooleanVar RequestHandler::Set_includes_N2 (APTR(FeSet) receiver, APTR(FeRangeElement) arg1){
	return receiver->includes(arg1);
}


RPTR(FeSet) RequestHandler::Set_intersect_N2 (APTR(FeSet) receiver, APTR(FeSet) arg1){
	WPTR(FeSet) 	returnValue;
	returnValue = receiver->intersect(arg1);
	return returnValue;
}


RPTR(FeSet) RequestHandler::Set_make_N0 (){
	WPTR(FeSet) 	returnValue;
	returnValue = FeSet::make ();
	return returnValue;
}


RPTR(FeSet) RequestHandler::Set_make_N1 (APTR(PtrArray) arg1){
	WPTR(FeSet) 	returnValue;
	returnValue = FeSet::make (arg1);
	return returnValue;
}


RPTR(FeSet) RequestHandler::Set_minus_N2 (APTR(FeSet) receiver, APTR(FeSet) arg1){
	WPTR(FeSet) 	returnValue;
	returnValue = receiver->minus(arg1);
	return returnValue;
}


RPTR(FeRangeElement) RequestHandler::Set_theOne_N1 (APTR(FeSet) receiver){
	WPTR(FeRangeElement) 	returnValue;
	returnValue = receiver->theOne();
	return returnValue;
}


RPTR(FeSet) RequestHandler::Set_unionWith_N2 (APTR(FeSet) receiver, APTR(FeSet) arg1){
	WPTR(FeSet) 	returnValue;
	returnValue = receiver->unionWith(arg1);
	return returnValue;
}


RPTR(FeSet) RequestHandler::Set_with_N2 (APTR(FeSet) receiver, APTR(FeRangeElement) arg1){
	WPTR(FeSet) 	returnValue;
	returnValue = receiver->with(arg1);
	return returnValue;
}


RPTR(FeSet) RequestHandler::Set_without_N2 (APTR(FeSet) receiver, APTR(FeRangeElement) arg1){
	WPTR(FeSet) 	returnValue;
	returnValue = receiver->without(arg1);
	return returnValue;
}


RPTR(FeEdition) RequestHandler::SingleRef_excerpt_N1 (APTR(FeSingleRef) receiver){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->excerpt();
	return returnValue;
}


RPTR(FeSingleRef) RequestHandler::SingleRef_make_N1 (APTR(FeEdition) arg1){
	WPTR(FeSingleRef) 	returnValue;
	returnValue = FeSingleRef::make (arg1);
	return returnValue;
}


RPTR(FeSingleRef) RequestHandler::SingleRef_make_N2 (APTR(FeEdition) arg1, APTR(FeWork) arg2){
	WPTR(FeSingleRef) 	returnValue;
	returnValue = FeSingleRef::make (arg1, arg2);
	return returnValue;
}


RPTR(FeSingleRef) RequestHandler::SingleRef_make_N3 (
		APTR(FeEdition) arg1, 
		APTR(FeWork) arg2, 
		APTR(FeWork) arg3)
{
	WPTR(FeSingleRef) 	returnValue;
	returnValue = FeSingleRef::make (arg1, arg2, arg3);
	return returnValue;
}


RPTR(FeSingleRef) RequestHandler::SingleRef_make_N4 (
		APTR(FeEdition) arg1, 
		APTR(FeWork) arg2, 
		APTR(FeWork) arg3, 
		APTR(FePath) arg4)
{
	WPTR(FeSingleRef) 	returnValue;
	returnValue = FeSingleRef::make (arg1, arg2, arg3, arg4);
	return returnValue;
}


RPTR(FeSingleRef) RequestHandler::SingleRef_withExcerpt_N2 (APTR(FeSingleRef) receiver, APTR(FeEdition) arg1){
	WPTR(FeSingleRef) 	returnValue;
	returnValue = receiver->withExcerpt(arg1);
	return returnValue;
}


BooleanVar RequestHandler::Stepper_atEnd_N1 (APTR(Stepper) receiver){
	return receiver->atEnd();
}


RPTR(Stepper) RequestHandler::Stepper_copy_N1 (APTR(Stepper) receiver){
	WPTR(Stepper) 	returnValue;
	returnValue = receiver->copy();
	return returnValue;
}


RPTR(Heaper) RequestHandler::Stepper_get_N1 (APTR(Stepper) receiver){
	WPTR(Heaper) 	returnValue;
	returnValue = receiver->get();
	return returnValue;
}


void RequestHandler::Stepper_step_N1 (APTR(Stepper) receiver){
	receiver->step();
}


RPTR(PrimArray) RequestHandler::Stepper_stepMany_N1 (APTR(Stepper) receiver){
	WPTR(PrimArray) 	returnValue;
	returnValue = receiver->stepMany();
	return returnValue;
}


RPTR(PrimArray) RequestHandler::Stepper_stepMany_N2 (APTR(Stepper) receiver, APTR(PrimIntValue) arg1){
	WPTR(PrimArray) 	returnValue;
	returnValue = receiver->stepMany(arg1->asInt32());
	return returnValue;
}


RPTR(Heaper) RequestHandler::Stepper_theOne_N1 (APTR(Stepper) receiver){
	WPTR(Heaper) 	returnValue;
	returnValue = receiver->theOne();
	return returnValue;
}


RPTR(Position) RequestHandler::TableStepper_position_N1 (APTR(TableStepper) receiver){
	WPTR(Position) 	returnValue;
	returnValue = receiver->position();
	return returnValue;
}


RPTR(PrimArray) RequestHandler::TableStepper_stepManyPairs_N1 (APTR(TableStepper) receiver){
	WPTR(PrimArray) 	returnValue;
	returnValue = receiver->stepManyPairs();
	return returnValue;
}


RPTR(PrimArray) RequestHandler::TableStepper_stepManyPairs_N2 (APTR(TableStepper) receiver, APTR(PrimIntValue) arg1){
	WPTR(PrimArray) 	returnValue;
	returnValue = receiver->stepManyPairs(arg1->asInt32());
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Text_contents_N1 (APTR(FeText) receiver){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->contents();
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::Text_count_N1 (APTR(FeText) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->count());
	return returnValue;
}


RPTR(FeText) RequestHandler::Text_extract_N2 (APTR(FeText) receiver, APTR(IntegerRegion) arg1){
	WPTR(FeText) 	returnValue;
	returnValue = receiver->extract(arg1);
	return returnValue;
}


RPTR(FeText) RequestHandler::Text_insert_N3 (
		APTR(FeText) receiver, 
		APTR(PrimIntValue) arg1, 
		APTR(FeText) arg2)
{
	WPTR(FeText) 	returnValue;
	returnValue = receiver->insert(arg1->asIntegerVar(), arg2);
	return returnValue;
}


RPTR(FeText) RequestHandler::Text_make_N1 (APTR(PrimArray) arg1){
	WPTR(FeText) 	returnValue;
	returnValue = FeText::make (arg1);
	return returnValue;
}


RPTR(FeText) RequestHandler::Text_move_N3 (
		APTR(FeText) receiver, 
		APTR(PrimIntValue) arg1, 
		APTR(IntegerRegion) arg2)
{
	WPTR(FeText) 	returnValue;
	returnValue = receiver->move(arg1->asIntegerVar(), arg2);
	return returnValue;
}


RPTR(FeText) RequestHandler::Text_replace_N3 (
		APTR(FeText) receiver, 
		APTR(IntegerRegion) arg1, 
		APTR(FeText) arg2)
{
	WPTR(FeText) 	returnValue;
	returnValue = receiver->replace(arg1, arg2);
	return returnValue;
}


RPTR(Position) RequestHandler::Tuple_coordinate_N2 (APTR(Tuple) receiver, APTR(PrimIntValue) arg1){
	WPTR(Position) 	returnValue;
	returnValue = receiver->coordinate(arg1->asInt32());
	return returnValue;
}


RPTR(PtrArray) RequestHandler::Tuple_coordinates_N1 (APTR(Tuple) receiver){
	WPTR(PtrArray) 	returnValue;
	returnValue = receiver->coordinates();
	return returnValue;
}


RPTR(FeWallLockSmith) RequestHandler::WallLockSmith_make_N0 (){
	WPTR(FeWallLockSmith) 	returnValue;
	returnValue = FeWallLockSmith::make ();
	return returnValue;
}


BooleanVar RequestHandler::Work_canRead_N1 (APTR(FeWork) receiver){
	return receiver->canRead();
}


BooleanVar RequestHandler::Work_canRevise_N1 (APTR(FeWork) receiver){
	return receiver->canRevise();
}


RPTR(ID) RequestHandler::Work_editClub_N1 (APTR(FeWork) receiver){
	WPTR(ID) 	returnValue;
	returnValue = receiver->editClub();
	return returnValue;
}


RPTR(FeEdition) RequestHandler::Work_edition_N1 (APTR(FeWork) receiver){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->edition();
	return returnValue;
}


void RequestHandler::Work_endorse_N2 (APTR(FeWork) receiver, APTR(CrossRegion) arg1){
	receiver->endorse(arg1);
}


RPTR(CrossRegion) RequestHandler::Work_endorsements_N1 (APTR(FeWork) receiver){
	WPTR(CrossRegion) 	returnValue;
	returnValue = receiver->endorsements();
	return returnValue;
}


void RequestHandler::Work_grab_N1 (APTR(FeWork) receiver){
	receiver->grab();
}


RPTR(ID) RequestHandler::Work_grabber_N1 (APTR(FeWork) receiver){
	WPTR(ID) 	returnValue;
	returnValue = receiver->grabber();
	return returnValue;
}


RPTR(ID) RequestHandler::Work_historyClub_N1 (APTR(FeWork) receiver){
	WPTR(ID) 	returnValue;
	returnValue = receiver->historyClub();
	return returnValue;
}


RPTR(ID) RequestHandler::Work_lastRevisionAuthor_N1 (APTR(FeWork) receiver){
	WPTR(ID) 	returnValue;
	returnValue = receiver->lastRevisionAuthor();
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::Work_lastRevisionNumber_N1 (APTR(FeWork) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->lastRevisionNumber());
	return returnValue;
}


RPTR(PrimIntValue) RequestHandler::Work_lastRevisionTime_N1 (APTR(FeWork) receiver){
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (receiver->lastRevisionTime());
	return returnValue;
}


RPTR(FeWork) RequestHandler::Work_make_N1 (APTR(FeEdition) arg1){
	WPTR(FeWork) 	returnValue;
	returnValue = FeWork::make (arg1);
	return returnValue;
}


RPTR(ID) RequestHandler::Work_readClub_N1 (APTR(FeWork) receiver){
	WPTR(ID) 	returnValue;
	returnValue = receiver->readClub();
	return returnValue;
}


void RequestHandler::Work_release_N1 (APTR(FeWork) receiver){
	receiver->release();
}


void RequestHandler::Work_removeEditClub_N1 (APTR(FeWork) receiver){
	receiver->removeEditClub();
}


void RequestHandler::Work_removeReadClub_N1 (APTR(FeWork) receiver){
	receiver->removeReadClub();
}


void RequestHandler::Work_requestGrab_N1 (APTR(FeWork) receiver){
	receiver->requestGrab();
}


void RequestHandler::Work_retract_N2 (APTR(FeWork) receiver, APTR(CrossRegion) arg1){
	receiver->retract(arg1);
}


void RequestHandler::Work_revise_N2 (APTR(FeWork) receiver, APTR(FeEdition) arg1){
	receiver->revise(arg1);
}


RPTR(FeEdition) RequestHandler::Work_revisions_N1 (APTR(FeWork) receiver){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->revisions();
	return returnValue;
}


void RequestHandler::Work_setEditClub_N2 (APTR(FeWork) receiver, APTR(ID) arg1){
	receiver->setEditClub(arg1);
}


void RequestHandler::Work_setHistoryClub_N2 (APTR(FeWork) receiver, APTR(ID) arg1){
	receiver->setHistoryClub(arg1);
}


void RequestHandler::Work_setReadClub_N2 (APTR(FeWork) receiver, APTR(ID) arg1){
	receiver->setReadClub(arg1);
}


void RequestHandler::Work_sponsor_N2 (APTR(FeWork) receiver, APTR(IDRegion) arg1){
	receiver->sponsor(arg1);
}


RPTR(IDRegion) RequestHandler::Work_sponsors_N1 (APTR(FeWork) receiver){
	WPTR(IDRegion) 	returnValue;
	returnValue = receiver->sponsors();
	return returnValue;
}


void RequestHandler::Work_unsponsor_N2 (APTR(FeWork) receiver, APTR(IDRegion) arg1){
	receiver->unsponsor(arg1);
}


RPTR(FeEdition) RequestHandler::Wrapper_edition_N1 (APTR(FeWrapper) receiver){
	WPTR(FeEdition) 	returnValue;
	returnValue = receiver->edition();
	return returnValue;
}


RPTR(FeWrapper) RequestHandler::Wrapper_inner_N1 (APTR(FeWrapper) receiver){
	WPTR(FeWrapper) 	returnValue;
	returnValue = receiver->inner();
	return returnValue;
}


RPTR(Filter) RequestHandler::WrapperSpec_filter_N1 (APTR(FeWrapperSpec) receiver){
	WPTR(Filter) 	returnValue;
	returnValue = receiver->filter();
	return returnValue;
}


RPTR(FeWrapperSpec) RequestHandler::WrapperSpec_get_N1 (APTR(Sequence) arg1){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FeWrapperSpec::get(arg1);
	return returnValue;
}


RPTR(Sequence) RequestHandler::WrapperSpec_name_N1 (APTR(FeWrapperSpec) receiver){
	WPTR(Sequence) 	returnValue;
	returnValue = receiver->name();
	return returnValue;
}


RPTR(FeWrapper) RequestHandler::WrapperSpec_wrap_N2 (APTR(FeWrapperSpec) receiver, APTR(FeEdition) arg1){
	WPTR(FeWrapper) 	returnValue;
	returnValue = receiver->wrap(arg1);
	return returnValue;
}
/* A class for each abstract signature.  Each instance will wrap a 
pointer to a static member function. */


/* request handling */
/* testing */


UInt32 RequestHandler::actualHashForEqual (){
	return Heaper::takeOop();
}

	/* automatic 0-argument constructor */
RequestHandler::RequestHandler() {}



/* ************************************************************************ *
 * 
 *                    Class   BHHandler 
 *
 * ************************************************************************ */


/* creation */


RPTR(RequestHandler) BHHandler::make (BHFn fn, APTR(Category) type1){
	RETURN_CONSTRUCT(BHHandler,(fn, type1));
}
/* request handling */


void BHHandler::handleRequest (APTR(PromiseManager) pm){
	SPTR(Heaper) arg1;
	
	arg1 = pm->fetchNonNullHeaper(myType1);
	if (pm->noErrors()) {
		pm->respondBooleanVar((*(myFn)) (arg1));
	}
}
/* creation */


BHHandler::BHHandler (BHFn fn, APTR(Category) type1) {
	myFn = fn;
	myType1 = type1;
}



/* ************************************************************************ *
 * 
 *                    Class   BHHHandler 
 *
 * ************************************************************************ */


/* creation */


RPTR(RequestHandler) BHHHandler::make (
		BHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2)
{
	RETURN_CONSTRUCT(BHHHandler,(fn, type1, type2));
}
/* request handling */


void BHHHandler::handleRequest (APTR(PromiseManager) pm){
	SPTR(Heaper) arg1;
	SPTR(Heaper) arg2;
	
	arg1 = pm->fetchNonNullHeaper(myType1);
	arg2 = pm->fetchNonNullHeaper(myType2);
	if (pm->noErrors()) {
		pm->respondBooleanVar((*(myFn)) (arg1, arg2));
	}
}
/* creation */


BHHHandler::BHHHandler (
		BHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2) 
{
	myFn = fn;
	myType1 = type1;
	myType2 = type2;
}



/* ************************************************************************ *
 * 
 *                    Class   BHHHHandler 
 *
 * ************************************************************************ */


/* creation */


RPTR(RequestHandler) BHHHHandler::make (
		BHHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2, 
		APTR(Category) type3)
{
	RETURN_CONSTRUCT(BHHHHandler,(fn, type1, type2, type3));
}
/* request handling */


void BHHHHandler::handleRequest (APTR(PromiseManager) pm){
	SPTR(Heaper) arg1;
	SPTR(Heaper) arg2;
	SPTR(Heaper) arg3;
	
	arg1 = pm->fetchNonNullHeaper(myType1);
	arg2 = pm->fetchNonNullHeaper(myType2);
	arg3 = pm->fetchNonNullHeaper(myType3);
	if (pm->noErrors()) {
		pm->respondBooleanVar(
				(*(myFn)) (arg1, arg2, arg3));
	}
}
/* creation */


BHHHHandler::BHHHHandler (
		BHHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2, 
		APTR(Category) type3) 
{
	myFn = fn;
	myType1 = type1;
	myType2 = type2;
	myType3 = type3;
}



/* ************************************************************************ *
 * 
 *                    Class   HHandler 
 *
 * ************************************************************************ */


/* creation */


RPTR(RequestHandler) HHandler::make (HFn fn){
	RETURN_CONSTRUCT(HHandler,(fn, tcsj));
}
/* request handling */


void HHandler::handleRequest (APTR(PromiseManager) pm){
	if (pm->noErrors()) {
		pm->respondHeaper((*(myFn)) ());
	}
}
/* creation */


HHandler::HHandler (HFn fn, TCSJ) {
	myFn = fn;
}



/* ************************************************************************ *
 * 
 *                    Class   HHBHandler 
 *
 * ************************************************************************ */


/* creation */


RPTR(RequestHandler) HHBHandler::make (HHBFn fn, APTR(Category) type1){
	RETURN_CONSTRUCT(HHBHandler,(fn, type1));
}
/* request handling */


void HHBHandler::handleRequest (APTR(PromiseManager) pm){
	SPTR(Heaper) arg1;
	BooleanVar arg2;
	
	arg1 = pm->fetchNonNullHeaper(myType1);
	arg2 = pm->fetchBooleanVar();
	if (pm->noErrors()) {
		pm->respondHeaper((*(myFn)) (arg1, arg2));
	}
}
/* creation */


HHBHandler::HHBHandler (HHBFn fn, APTR(Category) type1) {
	myFn = fn;
	myType1 = type1;
}



/* ************************************************************************ *
 * 
 *                    Class   HHHandler 
 *
 * ************************************************************************ */


/* creation */


RPTR(RequestHandler) HHHandler::make (HHFn fn, APTR(Category) type1){
	RETURN_CONSTRUCT(HHHandler,(fn, type1));
}
/* request handling */


void HHHandler::handleRequest (APTR(PromiseManager) pm){
	SPTR(Heaper) arg1;
	
	arg1 = pm->fetchNonNullHeaper(myType1);
	if (pm->noErrors()) {
		pm->respondHeaper((*(myFn)) (arg1));
	}
}
/* creation */


HHHandler::HHHandler (HHFn fn, APTR(Category) type1) {
	myFn = fn;
	myType1 = type1;
}



/* ************************************************************************ *
 * 
 *                    Class   HHHBHandler 
 *
 * ************************************************************************ */


/* creation */


RPTR(RequestHandler) HHHBHandler::make (
		HHHBFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2)
{
	RETURN_CONSTRUCT(HHHBHandler,(fn, type1, type2));
}
/* request handling */


void HHHBHandler::handleRequest (APTR(PromiseManager) pm){
	SPTR(Heaper) arg1;
	SPTR(Heaper) arg2;
	BooleanVar arg3;
	
	arg1 = pm->fetchNonNullHeaper(myType1);
	arg2 = pm->fetchNonNullHeaper(myType2);
	arg3 = pm->fetchBooleanVar();
	if (pm->noErrors()) {
		pm->respondHeaper(
				(*(myFn)) (arg1, arg2, arg3));
	}
}
/* creation */


HHHBHandler::HHHBHandler (
		HHHBFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2) 
{
	myFn = fn;
	myType1 = type1;
	myType2 = type2;
}



/* ************************************************************************ *
 * 
 *                    Class   HHHHandler 
 *
 * ************************************************************************ */


/* creation */


RPTR(RequestHandler) HHHHandler::make (
		HHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2)
{
	RETURN_CONSTRUCT(HHHHandler,(fn, type1, type2));
}
/* request handling */


void HHHHandler::handleRequest (APTR(PromiseManager) pm){
	SPTR(Heaper) arg1;
	SPTR(Heaper) arg2;
	
	arg1 = pm->fetchNonNullHeaper(myType1);
	arg2 = pm->fetchNonNullHeaper(myType2);
	if (pm->noErrors()) {
		pm->respondHeaper((*(myFn)) (arg1, arg2));
	}
}
/* creation */


HHHHandler::HHHHandler (
		HHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2) 
{
	myFn = fn;
	myType1 = type1;
	myType2 = type2;
}



/* ************************************************************************ *
 * 
 *                    Class   HHHHHandler 
 *
 * ************************************************************************ */


/* creation */


RPTR(RequestHandler) HHHHHandler::make (
		HHHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2, 
		APTR(Category) type3)
{
	RETURN_CONSTRUCT(HHHHHandler,(fn, type1, type2, type3));
}
/* request handling */


void HHHHHandler::handleRequest (APTR(PromiseManager) pm){
	SPTR(Heaper) arg1;
	SPTR(Heaper) arg2;
	SPTR(Heaper) arg3;
	
	arg1 = pm->fetchNonNullHeaper(myType1);
	arg2 = pm->fetchNonNullHeaper(myType2);
	arg3 = pm->fetchNonNullHeaper(myType3);
	if (pm->noErrors()) {
		pm->respondHeaper(
				(*(myFn)) (arg1, arg2, arg3));
	}
}
/* creation */


HHHHHandler::HHHHHandler (
		HHHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2, 
		APTR(Category) type3) 
{
	myFn = fn;
	myType1 = type1;
	myType2 = type2;
	myType3 = type3;
}



/* ************************************************************************ *
 * 
 *                    Class   HHHHHHandler 
 *
 * ************************************************************************ */


/* creation */


RPTR(RequestHandler) HHHHHHandler::make (
		HHHHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2, 
		APTR(Category) type3, 
		APTR(Category) type4)
{
	RETURN_CONSTRUCT(HHHHHHandler,(fn, type1, type2, type3, type4));
}
/* request handling */


void HHHHHHandler::handleRequest (APTR(PromiseManager) pm){
	SPTR(Heaper) arg1;
	SPTR(Heaper) arg2;
	SPTR(Heaper) arg3;
	SPTR(Heaper) arg4;
	
	arg1 = pm->fetchNonNullHeaper(myType1);
	arg2 = pm->fetchNonNullHeaper(myType2);
	arg3 = pm->fetchNonNullHeaper(myType3);
	arg4 = pm->fetchNonNullHeaper(myType4);
	if (pm->noErrors()) {
		pm->respondHeaper(
				(*(myFn)) (arg1, arg2, arg3, arg4));
	}
}
/* creation */


HHHHHHandler::HHHHHHandler (
		HHHHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2, 
		APTR(Category) type3, 
		APTR(Category) type4) 
{
	myFn = fn;
	myType1 = type1;
	myType2 = type2;
	myType3 = type3;
	myType4 = type4;
}



/* ************************************************************************ *
 * 
 *                    Class   HHHHHHHandler 
 *
 * ************************************************************************ */


/* creation */


RPTR(RequestHandler) HHHHHHHandler::make (
		HHHHHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2, 
		APTR(Category) type3, 
		APTR(Category) type4, 
		APTR(Category) type5)
{
	RETURN_CONSTRUCT(HHHHHHHandler,(fn, type1, type2, type3, type4, type5));
}
/* request handling */


void HHHHHHHandler::handleRequest (APTR(PromiseManager) pm){
	SPTR(Heaper) arg1;
	SPTR(Heaper) arg2;
	SPTR(Heaper) arg3;
	SPTR(Heaper) arg4;
	SPTR(Heaper) arg5;
	
	arg1 = pm->fetchNonNullHeaper(myType1);
	arg2 = pm->fetchNonNullHeaper(myType2);
	arg3 = pm->fetchNonNullHeaper(myType3);
	arg4 = pm->fetchNonNullHeaper(myType4);
	arg5 = pm->fetchNonNullHeaper(myType5);
	if (pm->noErrors()) {
		pm->respondHeaper(
				(*(myFn)) (arg1, arg2, arg3, arg4, arg5));
	}
}
/* creation */


HHHHHHHandler::HHHHHHHandler (
		HHHHHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2, 
		APTR(Category) type3, 
		APTR(Category) type4, 
		APTR(Category) type5) 
{
	myFn = fn;
	myType1 = type1;
	myType2 = type2;
	myType3 = type3;
	myType4 = type4;
	myType5 = type5;
}



/* ************************************************************************ *
 * 
 *                    Class   HHHHHHHHandler 
 *
 * ************************************************************************ */


/* creation */


RPTR(RequestHandler) HHHHHHHHandler::make (
		HHHHHHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2, 
		APTR(Category) type3, 
		APTR(Category) type4, 
		APTR(Category) type5, 
		APTR(Category) type6)
{
	RETURN_CONSTRUCT(HHHHHHHHandler,(fn, type1, type2, type3, type4, type5, type6));
}
/* request handling */


void HHHHHHHHandler::handleRequest (APTR(PromiseManager) pm){
	SPTR(Heaper) arg1;
	SPTR(Heaper) arg2;
	SPTR(Heaper) arg3;
	SPTR(Heaper) arg4;
	SPTR(Heaper) arg5;
	SPTR(Heaper) arg6;
	
	arg1 = pm->fetchNonNullHeaper(myType1);
	arg2 = pm->fetchNonNullHeaper(myType2);
	arg3 = pm->fetchNonNullHeaper(myType3);
	arg4 = pm->fetchNonNullHeaper(myType4);
	arg5 = pm->fetchNonNullHeaper(myType5);
	arg6 = pm->fetchNonNullHeaper(myType6);
	if (pm->noErrors()) {
		pm->respondHeaper(
				(*(myFn)) (arg1, arg2, arg3, arg4, arg5, arg6));
	}
}
/* creation */


HHHHHHHHandler::HHHHHHHHandler (
		HHHHHHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2, 
		APTR(Category) type3, 
		APTR(Category) type4, 
		APTR(Category) type5, 
		APTR(Category) type6) 
{
	myFn = fn;
	myType1 = type1;
	myType2 = type2;
	myType3 = type3;
	myType4 = type4;
	myType5 = type5;
	myType6 = type6;
}



/* ************************************************************************ *
 * 
 *                    Class   VHBHandler 
 *
 * ************************************************************************ */


/* creation */


RPTR(RequestHandler) VHBHandler::make (VHBFn fn, APTR(Category) type1){
	RETURN_CONSTRUCT(VHBHandler,(fn, type1));
}
/* request handling */


void VHBHandler::handleRequest (APTR(PromiseManager) pm){
	SPTR(Heaper) arg1;
	BooleanVar arg2;
	
	arg1 = pm->fetchNonNullHeaper(myType1);
	arg2 = pm->fetchBooleanVar();
	if (pm->noErrors()) {
		(*(myFn)) (arg1, arg2);
		pm->respondVoid();
	}
}
/* creation */


VHBHandler::VHBHandler (VHBFn fn, APTR(Category) type1) {
	myFn = fn;
	myType1 = type1;
}



/* ************************************************************************ *
 * 
 *                    Class   VHHandler 
 *
 * ************************************************************************ */


/* creation */


RPTR(RequestHandler) VHHandler::make (VHFn fn, APTR(Category) type1){
	RETURN_CONSTRUCT(VHHandler,(fn, type1));
}
/* request handling */


void VHHandler::handleRequest (APTR(PromiseManager) pm){
	SPTR(Heaper) arg1;
	
	arg1 = pm->fetchNonNullHeaper(myType1);
	if (pm->noErrors()) {
		(*(myFn)) (arg1);
		pm->respondVoid();
	}
}
/* creation */


VHHandler::VHHandler (VHFn fn, APTR(Category) type1) {
	myFn = fn;
	myType1 = type1;
}



/* ************************************************************************ *
 * 
 *                    Class   VHHHandler 
 *
 * ************************************************************************ */


/* creation */


RPTR(RequestHandler) VHHHandler::make (
		VHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2)
{
	RETURN_CONSTRUCT(VHHHandler,(fn, type1, type2));
}
/* request handling */


void VHHHandler::handleRequest (APTR(PromiseManager) pm){
	SPTR(Heaper) arg1;
	SPTR(Heaper) arg2;
	
	arg1 = pm->fetchNonNullHeaper(myType1);
	arg2 = pm->fetchNonNullHeaper(myType2);
	if (pm->noErrors()) {
		(*(myFn)) (arg1, arg2);
		pm->respondVoid();
	}
}
/* creation */


VHHHandler::VHHHandler (
		VHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2) 
{
	myFn = fn;
	myType1 = type1;
	myType2 = type2;
}



/* ************************************************************************ *
 * 
 *                    Class   VHHHHandler 
 *
 * ************************************************************************ */


/* creation */


RPTR(RequestHandler) VHHHHandler::make (
		VHHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2, 
		APTR(Category) type3)
{
	RETURN_CONSTRUCT(VHHHHandler,(fn, type1, type2, type3));
}
/* request handling */


void VHHHHandler::handleRequest (APTR(PromiseManager) pm){
	SPTR(Heaper) arg1;
	SPTR(Heaper) arg2;
	SPTR(Heaper) arg3;
	
	arg1 = pm->fetchNonNullHeaper(myType1);
	arg2 = pm->fetchNonNullHeaper(myType2);
	arg3 = pm->fetchNonNullHeaper(myType3);
	if (pm->noErrors()) {
		(*(myFn)) (arg1, arg2, arg3);
		pm->respondVoid();
	}
}
/* creation */


VHHHHandler::VHHHHandler (
		VHHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2, 
		APTR(Category) type3) 
{
	myFn = fn;
	myType1 = type1;
	myType2 = type2;
	myType3 = type3;
}



/* ************************************************************************ *
 * 
 *                    Class   VHHHHHandler 
 *
 * ************************************************************************ */


/* creation */


RPTR(RequestHandler) VHHHHHandler::make (
		VHHHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2, 
		APTR(Category) type3, 
		APTR(Category) type4)
{
	RETURN_CONSTRUCT(VHHHHHandler,(fn, type1, type2, type3, type4));
}
/* request handling */


void VHHHHHandler::handleRequest (APTR(PromiseManager) pm){
	SPTR(Heaper) arg1;
	SPTR(Heaper) arg2;
	SPTR(Heaper) arg3;
	SPTR(Heaper) arg4;
	
	arg1 = pm->fetchNonNullHeaper(myType1);
	arg2 = pm->fetchNonNullHeaper(myType2);
	arg3 = pm->fetchNonNullHeaper(myType3);
	arg4 = pm->fetchNonNullHeaper(myType4);
	if (pm->noErrors()) {
		(*(myFn)) (arg1, arg2, arg3, arg4);
		pm->respondVoid();
	}
}
/* creation */


VHHHHHandler::VHHHHHandler (
		VHHHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2, 
		APTR(Category) type3, 
		APTR(Category) type4) 
{
	myFn = fn;
	myType1 = type1;
	myType2 = type2;
	myType3 = type3;
	myType4 = type4;
}



/* ************************************************************************ *
 * 
 *                    Class   VHHHHHHandler 
 *
 * ************************************************************************ */


/* creation */


RPTR(RequestHandler) VHHHHHHandler::make (
		VHHHHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2, 
		APTR(Category) type3, 
		APTR(Category) type4, 
		APTR(Category) type5)
{
	RETURN_CONSTRUCT(VHHHHHHandler,(fn, type1, type2, type3, type4, type5));
}
/* request handling */


void VHHHHHHandler::handleRequest (APTR(PromiseManager) pm){
	SPTR(Heaper) arg1;
	SPTR(Heaper) arg2;
	SPTR(Heaper) arg3;
	SPTR(Heaper) arg4;
	SPTR(Heaper) arg5;
	
	arg1 = pm->fetchNonNullHeaper(myType1);
	arg2 = pm->fetchNonNullHeaper(myType2);
	arg3 = pm->fetchNonNullHeaper(myType3);
	arg4 = pm->fetchNonNullHeaper(myType4);
	arg5 = pm->fetchNonNullHeaper(myType5);
	if (pm->noErrors()) {
		(*(myFn)) (arg1, arg2, arg3, arg4, arg5);
		pm->respondVoid();
	}
}
/* creation */


VHHHHHHandler::VHHHHHHandler (
		VHHHHHFn fn, 
		APTR(Category) type1, 
		APTR(Category) type2, 
		APTR(Category) type3, 
		APTR(Category) type4, 
		APTR(Category) type5) 
{
	myFn = fn;
	myType1 = type1;
	myType2 = type2;
	myType3 = type3;
	myType4 = type4;
	myType5 = type5;
}

#ifndef HANDLRSX_SXX
#include "handlrsx.sxx"
#endif /* HANDLRSX_SXX */



#endif /* HANDLRSX_CXX */

