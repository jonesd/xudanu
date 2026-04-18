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

#ifndef NKERNELX_CXX
#define NKERNELX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef NKERNELX_HXX
#include "nkernelx.hxx"
#endif /* NKERNELX_HXX */

#ifndef NKERNELX_IXX
#include "nkernelx.ixx"
#endif /* NKERNELX_IXX */

#ifndef NKERNELP_HXX
#include "nkernelp.hxx"
#endif /* NKERNELP_HXX */

#ifndef NKERNELP_IXX
#include "nkernelp.ixx"
#endif /* NKERNELP_IXX */


#ifndef CROSSX_HXX
#include "crossx.hxx"
#endif /* CROSSX_HXX */

#ifndef DETECTX_HXX
#include "detectx.hxx"
#endif /* DETECTX_HXX */

#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef FILTERX_HXX
#include "filterx.hxx"
#endif /* FILTERX_HXX */

#ifndef FLUIDX_HXX
#include "fluidx.hxx"
#endif /* FLUIDX_HXX */

#ifndef GRANMAPX_HXX
#include "granmapx.hxx"
#endif /* GRANMAPX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef NADMINX_HXX
#include "nadminx.hxx"
#endif /* NADMINX_HXX */

#ifndef RECIPEX_HXX
#include "recipex.hxx"
#endif /* RECIPEX_HXX */

#ifndef SCHUNKX_HXX
#include "schunkx.hxx"
#endif /* SCHUNKX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef TABLESX_HXX
#include "tablesx.hxx"
#endif /* TABLESX_HXX */

#ifndef WRAPPERX_HXX
#include "wrapperx.hxx"
#endif /* WRAPPERX_HXX */




/* ************************************************************************ *
 * 
 *                    Class FeBundle 
 *
 * ************************************************************************ */


/* Describes a single chunk of information from an Edition */


/* protected: create */


FeBundle::FeBundle (APTR(XnRegion) region, TCSJ) {
	myRegion = region;
}
/* accessing */


RPTR(XnRegion) FeBundle::region (){
	/* Essential. The positions in the Edition for which I 
	describe the contents */
	
	return (XnRegion*) myRegion;
}
/* testing */


UInt32 FeBundle::actualHashForEqual (){
	return Heaper::takeOop();
}



/* ************************************************************************ *
 * 
 *                    Class   FeArrayBundle 
 *
 * ************************************************************************ */


/* create */


RPTR(FeArrayBundle) FeArrayBundle::make (
		APTR(XnRegion) region, 
		APTR(PrimArray) array, 
		APTR(OrderSpec) order)
{
	RETURN_CONSTRUCT(FeArrayBundle,(region, array, order));
}
/* Describes a chunk of information represented as an array. The 
number of elements in the array are the same as my region, and they 
are ordered according to OrderSpec given to the retrieve operation 
which produced me. */


/* accessing */


RPTR(PrimArray) FeArrayBundle::array (){
	/* Essential. The array of elements in this bundle */
	
	WPTR(PrimArray) 	returnValue;
	returnValue = myArray->copy();
	return returnValue;
}


RPTR(OrderSpec) FeArrayBundle::ordering (){
	/* Essential. The order relating the elements in the array to 
	the positions in the region. */
	
	return (OrderSpec*) myOrder;
}
/* private: create */


FeArrayBundle::FeArrayBundle (
		APTR(XnRegion) region, 
		APTR(PrimArray) array, 
		APTR(OrderSpec) order) 

	: FeBundle(region, tcsj) {
	myArray = array;
	myOrder = order;
}



/* ************************************************************************ *
 * 
 *                    Class   FeElementBundle 
 *
 * ************************************************************************ */


/* create */


RPTR(FeElementBundle) FeElementBundle::make (APTR(XnRegion) region, APTR(FeRangeElement) element){
	RETURN_CONSTRUCT(FeElementBundle,(region, element));
}
/* Describes a region of an Edition in which all indices in my region 
hold the same RangeElement. */


/* accessing */


RPTR(FeRangeElement) FeElementBundle::element (){
	/* Essential. The RangeElement which is at every position in 
	my region */
	
	return (FeRangeElement*) myElement;
}
/* private: create */


FeElementBundle::FeElementBundle (APTR(XnRegion) region, APTR(FeRangeElement) element) 
	: FeBundle(region, tcsj) {
	myElement = element;
}



/* ************************************************************************ *
 * 
 *                    Class   FePlaceHolderBundle 
 *
 * ************************************************************************ */


/* create */


RPTR(FePlaceHolderBundle) FePlaceHolderBundle::make (APTR(XnRegion) region){
	RETURN_CONSTRUCT(FePlaceHolderBundle,(region, tcsj));
}
/* Describes a region of an Edition in which all indices in my region 
have a distinct PlaceHolder. */


/* private: create */


FePlaceHolderBundle::FePlaceHolderBundle (APTR(XnRegion) region, TCSJ) 
	: FeBundle(region, tcsj) {
	
}



/* ************************************************************************ *
 * 
 *                    Class FeKeyMaster 
 *
 * ************************************************************************ */


/* creation */


RPTR(FeKeyMaster) FeKeyMaster::make (APTR(ID) clubID){
	/* Make a KeyMaster initially logged in to the given Club */
	
	/* login authority */
	WPTR(FeKeyMaster) 	returnValue;
	returnValue = FeKeyMaster::make (CAST(IDRegion,clubID->asRegion()), CurrentGrandMap.fluidGet()->getClub(clubID)->transitiveSuperClubIDs());
	return returnValue;
}


RPTR(FeKeyMaster) FeKeyMaster::makeAll (APTR(IDRegion) clubIDs){
	/* Make a KeyMaster initially logged in to the given Clubs */
	
	SPTR(IDRegion) actuals;
	SPTR(BeGrandMap) gm;
	
	gm = CurrentGrandMap.fluidGet();
	actuals = CAST(IDRegion,gm->globalIDSpace()->emptyRegion());
	BEGIN_FOR_EACH(ID,iD,(clubIDs->stepper())) {
		actuals = CAST(IDRegion,actuals->unionWith(gm->getClub(iD)->transitiveSuperClubIDs()));
	} END_FOR_EACH;
	WPTR(FeKeyMaster) 	returnValue;
	returnValue = FeKeyMaster::make (clubIDs, actuals);
	return returnValue;
}


RPTR(FeKeyMaster) FeKeyMaster::makePublic (){
	/* Make a KeyMaster logged in to the Universal Public Club. */
	
	WPTR(FeKeyMaster) 	returnValue;
	returnValue = FeKeyMaster::make (FeServer::publicClubID());
	return returnValue;
}
/* private: pseudo constructors */


RPTR(FeKeyMaster) FeKeyMaster::make (APTR(IDRegion) loginAuthority, APTR(IDRegion) actualAuthority){
	SPTR(FeKeyMaster) result;
	
	CONSTRUCT(result,FeKeyMaster,(loginAuthority, actualAuthority));
	/* Register with all the login Clubs to find out when their 
		permissions change */
	BEGIN_FOR_EACH(ID,loginClubID,(loginAuthority->stepper())) {
		CAST(BeClub,CurrentGrandMap.fluidGet()->get(loginClubID))->registerKeyMaster(result);
	} END_FOR_EACH;
	WPTR(FeKeyMaster) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* assertions */


void FeKeyMaster::assertAdminAuthority (){
	/* Blast if the CurrentKeyMaster doesn't have Admin authority. */
	
	if (!CurrentKeyMaster.fluidGet()->hasAuthority(CurrentGrandMap.fluidGet()->adminClubID())) {
		BLAST(MustHaveAdminAuthority);
	}
}


void FeKeyMaster::assertSignatureAuthority (){
	/* Blast if the CurrentKeyMaster doesn't have signature 
	authority for the CurrentAuthor. */
	
	if (!CurrentKeyMaster.fluidGet()->hasSignatureAuthority(CurrentAuthor.fluidGet())) {
		BLAST(MustHaveAuthorSignatureAuthority);
	}
}


void FeKeyMaster::assertSponsorship (){
	/* If there is a currentSponsor, then the CurrentKeyMaster 
	must have authority for it. */
	
	SPTR(FeKeyMaster) ckm;
	SPTR(BeGrandMap) cgm;
	
	ckm = CurrentKeyMaster.fluidGet();
	cgm = CurrentGrandMap.fluidGet();
	{	BooleanVar crutch_Flag;
		/* InitialSponsor.fluidGet() == cgm->emptyClubID() || ckm->hasAuthority(InitialSponsor.fluidFetch()) */
		
		crutch_Flag = InitialSponsor.fluidGet() == cgm->emptyClubID();
		if(!crutch_Flag) {
			crutch_Flag = ckm->hasAuthority(InitialSponsor.fluidFetch());
		}
		if (!crutch_Flag) {
			BLAST(MustHaveSponsorAuthority);
		}
	}
}
/* A KeyMaster provides the authority, or "holds the keys", for a 
client`s activities on the BackEnd. A client can have any number of 
different KeyMasters, each with different authority. FeServer_login 
(if successful) gives you back a KeyMaster with the authority of a 
single Club (along with all the Clubs of which it is a member, 
directly or indirectly). This will give you appropriate authority to 
do anything permitted to that Club. You can incorporate the authority 
of other KeyMasters into it, so that it will additionally enable you 
to do anything the other KeyMasters would have enabled. */


/* authority */


RPTR(IDRegion) FeKeyMaster::actualAuthority (){
	/* Essential.  The Clubs whose authority is actually being 
	held right now. This may change asynchronously when you or 
	others change the membership lists of clubs.  It is my 
	loginAuthority plus all clubs that list any of these clubs as 
	members, transitively. */
	
	return (IDRegion*) myActualAuthority;
}


RPTR(FeKeyMaster) FeKeyMaster::copy (){
	/* Essential.  A different KeyMaster with the same login and 
	actual authority as this one. */
	
	WPTR(FeKeyMaster) 	returnValue;
	returnValue = FeKeyMaster::make (myLoginAuthority, myActualAuthority);
	return returnValue;
}


BooleanVar FeKeyMaster::hasAuthority (APTR(ID) clubID){
	/* Whether this KeyMaster is currently holding the authority 
	of the given Club. Equivalent to
			this->actualAuthority ()->hasMember (clubID) */
	
	return myActualAuthority->hasMember(clubID);
}


void FeKeyMaster::incorporate (APTR(FeKeyMaster) other){
	/* Essential.  Add the other KeyMaster's login and actual 
	authorities to my own respective authorities. */
	
	SPTR(XnRegion) newLogins;
	
	newLogins = other->loginAuthority()->minus(myLoginAuthority);
	myLoginAuthority = CAST(IDRegion,myLoginAuthority->unionWith(other->loginAuthority()));
	myActualAuthority = CAST(IDRegion,myActualAuthority->unionWith(other->actualAuthority()));
	/* Tell all my Works */
	this->authorityChanged();
	/* Register with the new login Clubs to find out when their 
		super clubs change */
	BEGIN_FOR_EACH(ID,login,(newLogins->stepper())) {
		CAST(BeClub,CurrentGrandMap.fluidGet()->get(login))->registerKeyMaster(this);
	} END_FOR_EACH;
}


RPTR(IDRegion) FeKeyMaster::loginAuthority (){
	/* Essential.  The Clubs whose authority was obtained 
	directly, by logging in to them. They are the ones from which 
	all other authority is derived. */
	
	return (IDRegion*) myLoginAuthority;
}


void FeKeyMaster::removeLogins (APTR(IDRegion) oldLogins){
	/* Essential.  Remove the listed IDs from the set of Clubs 
	whose login authority I exercise.  All authority derived from 
	them that cannot be derived from the remaining login 
	authority will also disappear.  Listed Clubs for which I do 
	not hold login authority will be silently ignored. */
	
	SPTR(IDRegion) removed;
	
	removed = CAST(IDRegion,oldLogins->intersect(myLoginAuthority));
	myLoginAuthority = CAST(IDRegion,myLoginAuthority->minus(removed));
	/* Figure out the new transitive authority */
	this->updateAuthority();
	/* Unregister with the new IDs */
	BEGIN_FOR_EACH(ID,login,(removed->stepper())) {
		CAST(BeClub,CurrentGrandMap.fluidGet()->get(login))->unregisterKeyMaster(this);
	} END_FOR_EACH;
}
/* private: create */


FeKeyMaster::FeKeyMaster (APTR(IDRegion) loginAuthority, APTR(IDRegion) actualAuthority) {
	myLoginAuthority = loginAuthority;
	myActualAuthority = actualAuthority;
	myRegisteredWorks = NULL;
}
/* server accessing */


BooleanVar FeKeyMaster::hasSignatureAuthority (APTR(ID) club){
	/* Whether this KeyMaster has signature authority for the given Club */
	
	SPTR(ID) sig;
	SPTR(BeGrandMap) cgm;
	
	cgm = CurrentGrandMap.fluidGet();
	{	BooleanVar crutch_Flag;
		/* (sig = cgm->getClub(club)->fetchSignatureClub()) != NULL && this->hasAuthority(sig) */
		
		crutch_Flag = (sig = cgm->getClub(club)->fetchSignatureClub()) != NULL;
		if(crutch_Flag) {
			crutch_Flag = this->hasAuthority(sig);
		}
		return crutch_Flag;
	}
}


void FeKeyMaster::registerWork (APTR(FeWork) work){
	/* Notify the Work whenever my authority changes */
	
	if (myRegisteredWorks == NULL) {
		myRegisteredWorks = PrimSet::weak();
	}
	myRegisteredWorks->introduce(work);
}


void FeKeyMaster::unregisterWork (APTR(FeWork) work){
	/* Notify the Work whenever my authority changes */
	
	{	BooleanVar crutch_Flag;
		/* myRegisteredWorks == NULL || myRegisteredWorks->isEmpty() */
		
		crutch_Flag = myRegisteredWorks == NULL;
		if(!crutch_Flag) {
			crutch_Flag = myRegisteredWorks->isEmpty();
		}
		if (crutch_Flag) {
			BLAST(NeverAddedWatcher);
		}
	}
	myRegisteredWorks->remove(work);
	if (myRegisteredWorks->isEmpty()) {
		myRegisteredWorks = NULL;
	}
}


void FeKeyMaster::updateAuthority (){
	/* Recompute the actual authority of this KeyMaster based on 
	the set of login Clubs */
	
	myActualAuthority = CAST(IDRegion,IDSpace::global()->emptyRegion());
	BEGIN_FOR_EACH(ID,login,(myLoginAuthority->stepper())) {
		myActualAuthority = CAST(IDRegion,myActualAuthority->unionWith(CAST(BeClub,CurrentGrandMap.fluidGet()->get(login))->transitiveSuperClubIDs()));
	} END_FOR_EACH;
	this->authorityChanged();
}
/* private: */


void FeKeyMaster::authorityChanged (){
	/* Notify all my dependents of a change in authority */
	
	if (myRegisteredWorks != NULL) {
		BEGIN_FOR_EACH(FeWork,work,(myRegisteredWorks->stepper())) {
			work->updateStatus();
		} END_FOR_EACH;
	}
}
/* printing */


void FeKeyMaster::printOn (ostream& oo){
	oo << "KeyMaster(" << this->loginAuthority() << ")";
}
/* obsolete: */


RPTR(Filter) FeKeyMaster::permissionsFilter (){
	/* A filter for things which can be read by this KeyMaster */
	
	/* Thing to do !!!! */
	
	/* have all callers use 'actualAuthority' instead */
	WPTR(Filter) 	returnValue;
	returnValue = CurrentGrandMap.fluidGet()->globalIDFilterSpace()->anyFilter(myActualAuthority);
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class FeRangeElement 
 *
 * ************************************************************************ */


/* protected: */


void FeRangeElement::validateEndorsement (APTR(CrossRegion) endorsements, APTR(FeKeyMaster) km){
	/* Check whether the endorsements are valid and authorized.
		 Blast appropriately if not. */
	
	if (!endorsements->isFinite()) {
		BLAST(EndorsementMustBeFinite);
	}
	FeRangeElement::validateSignature(CAST(IDRegion,endorsements->projection(Int32Zero)), km);
}


void FeRangeElement::validateSignature (APTR(IDRegion) clubs, APTR(FeKeyMaster) km){
	/* Check whether the signatures are valid and authorized.
		 Blast appropriately if not. */
	
	if (!clubs->isFinite()) {
		BLAST(MustHaveSignatureAuthority);
	}
	BEGIN_FOR_EACH(ID,clubID,(clubs->stepper())) {
		if (!km->hasSignatureAuthority(clubID)) {
			BLAST(MustHaveSignatureAuthority);
		}
	} END_FOR_EACH;
}
/* creation */


RPTR(FeRangeElement) FeRangeElement::placeHolder (){
	/* Make a single PlaceHolder. */
	
	WPTR(FeRangeElement) 	returnValue;
	returnValue = FePlaceHolder::on(CurrentGrandMap.fluidGet()->newPlaceHolder());
	return returnValue;
}
/* The kinds of objects which can be in the range of Editions. */


/* accessing */


void FeRangeElement::addFillDetector (APTR(FeFillDetector) detector){
	/* Essential.  When this PlaceHolder becomes any other kind 
	of RangeElement, then the Detector will be triggered with the 
	new RangeElement. If this is already not a PlaceHolder, then 
	the Detector is triggered immediately with this RangeElement.
		See FillRangeDetector::filled (RangeElement * newIdentity). */
	
	/* default will be overridden in FePlaceHolder */
	detector->filled(this);
}


BooleanVar FeRangeElement::canMakeIdentical (APTR(FeRangeElement) newIdentity){
	/* Essential.  Whether the identity of this object could be 
	changed to the other.
		Does not check whether the CurrentKeyMaster has authority to do it.
		The restrictions on this operation depend on which subclass 
	this is, but in general (except for PlaceHolders) an object 
	can only become another of the same type with the same content. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return FALSE;
}


RPTR(FeFillDetector) FeRangeElement::fillDetector (){
	/* Essential.  Return a FillDetector that will be triggered 
	when this RangeElement becomes something other than a 
	PlaceHolder, or immeditely if this RangeElement is not 
	currently a PlaceHolder.
		See FillRangeDetector::filled (RangeElement * newIdentity). */
	
	BLAST(NOT_YET_IMPLEMENTED);
	this->addFillDetector(NULL);
	/* fodder */
	return NULL;
}


BooleanVar FeRangeElement::isIdentical (APTR(FeRangeElement) other){
	/* Essential.  Return whether two objects have the same 
	identity on the Server.  Note that this can change over time, 
	if makeIdentical is used.  However, for a given pair of 
	FeRangeElements, it can only change from not being the same 
	to being the same while you are holding onto them. */
	
	/* This should be OK, since virtual subclasses override this anyway */
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(FeVirtualDataHolder,vd) {
			return vd->isIdentical(this);
		} END_KIND;
		BEGIN_KIND(FeVirtualPlaceHolder,vp) {
			return vp->isIdentical(this);
		} END_KIND;
		BEGIN_OTHERS {
			return this->getOrMakeBe()->isEqual(other->getOrMakeBe());
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


RPTR(ID) FeRangeElement::owner (){
	/* Essential.  The Club which owns this RangeElement, and has 
	the authority to make it become something else, and to 
	transfer ownership to someone else. */
	
	/* virtuals should override */
	WPTR(ID) 	returnValue;
	returnValue = this->getOrMakeBe()->owner();
	return returnValue;
}


void FeRangeElement::removeFillDetector (APTR(FeFillDetector) detector){
	/* Essential.  Remove a Detector which had been added to this 
	RangeElement. You should remove every Detector you add, 
	although they will go away automatically when a client 
	session terminates. */
	
	
}


void FeRangeElement::setOwner (APTR(ID) clubID){
	/* Essential.  Change the owner; must have the authority of 
	the current owner. */
	
	if (!CurrentKeyMaster.fluidGet()->hasAuthority(this->owner())) {
		BLAST(MustBeOwner);
	}
	/* Need to make it into a reified range element in order to 
		have distinct ownership */
	CurrentGrandMap.fluidGet()->getClub(clubID);
	/* Checks that it is a club. */
	this->getOrMakeBe()->setOwner(clubID);
}


RPTR(FeEdition) FeRangeElement::transcluders (
		APTR(Filter) directFilter/* = NULL*/, 
		APTR(Filter) indirectFilter/* = NULL*/, 
		Int32 flags/* = Int32Zero*/, 
		APTR(FeEdition) otherTranscluders/* = NULL*/)
{
	/* All Editions which the CurrentKeyMaster can see, which 
	transclude this RangeElement.
		If a directFilter is given, then the visibleEndorsements on 
	a Edition must match the filter.
		If an indirectFilter is given, then a resulting Edition must 
	be contained in some readable Edition whose 
	visibleEndorsements match the filter.
		If the directContainersOnly flag is set, then a resulting 
	Edition must contain this directly as a RangeElement; 
	otherwise, indirect containment through Editions is allowed.
		If the localPresentOnly flag is set, then only Editions 
	currently known to this Server are guaranteed to end up in 
	the result; otherwise, Editions which come to satisfy the 
	conditions in the future, and those on other Servers, may 
	also be found.
		Equivalent to
			FeServer::current ()->newEditionWith (<any position>, this)
				->rangeTranscluders (NULL, directFilter, indirectFilter, 
	flags, otherTranscluders). */
	
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::fromOne(IntegerPos::make (IntegerVarZero), this)->rangeTranscluders(NULL, directFilter, indirectFilter, flags, otherTranscluders);
	return returnValue;
}


RPTR(FeEdition) FeRangeElement::works (
		APTR(Filter) filter/* = NULL*/, 
		Int32 flags/* = Int32Zero*/, 
		APTR(FeEdition) otherTranscluders/* = NULL*/)
{
	/* Essential.  Works which contain this RangeElement and can 
	be read by the CurrentKeyMaster. Returns an IDSpace Edition 
	full of PlaceHolders, which will be filled with Works as 
	results come in.
		If a filter is given, then only Works whose endorsements 
	pass the Filter are returned.
		If localPresentOnly flag is set, then only Works currently 
	known to this Server are returned; otherwise, as new Works 
	come to be known to the Server, they are filled into the 
	resulting Edition.
		If directContainersOnly is set, and this is an Edition, then 
	only Works which are directly on this Edition are returned 
	(and not Works which are on Editions which have this one as 
	sub-Editions).
		{ <k,l,w> | w's contains self, w passes filter} */
	
	SPTR(Filter) theFilter;
	
	if (filter == NULL) {
		theFilter = CAST(Filter,CurrentGrandMap.fluidGet()->endorsementFilterSpace()->fullRegion());
	} else {
		theFilter = filter;
	}
	/* Dean -- Thing to do !!!! */
	
	/* avoid reifying */
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(
			this->getOrMakeBe()->works(CurrentKeyMaster.fluidGet()->actualAuthority(), theFilter, flags));
	return returnValue;
}
/* server accessing */


RPTR(BeCarrier) FeRangeElement::carrier (){
	/* Return an object that wraps up any run-time state that 
	might be needed inside the Be system.  Right now that means labels. */
	
	WPTR(BeCarrier) 	returnValue;
	returnValue = BeCarrier::make (this->getOrMakeBe());
	return returnValue;
}
/* labelling */


RPTR(FeLabel) FeRangeElement::label (){
	/* Essential. Return the label attached to this 
	FeRangeElement. (An FeRangeElement holds a BeRangeElement and 
	a label.)  All FeRangeElements have a label attached to them 
	when they are created (in the various Server::newRangeElement 
	operations).  Derived Editions have the same the label as the 
	Edition they were derived from (e.g. the receiver of copy, 
	combine, replace, transformedBy, etc.)  Labels may be 
	available only on Editions in 1.0.  (While this is in force, 
	label() will blast if sent to other kinds of FeEditions.) */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* default */
	return NULL;
}


RPTR(FeRangeElement) FeRangeElement::relabelled (APTR(FeLabel) label){
	/* Essential. Return a new FeRangeElement with the same 
	identity and contents (i.e. holding the same BeRangeElement), 
	but with a different label.  (Get new labels from 
	FeServer::newLabel()) */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* default */
	return NULL;
}

	/* automatic 0-argument constructor */
FeRangeElement::FeRangeElement() {}



/* ************************************************************************ *
 * 
 *                    Class   FeDataHolder 
 *
 * ************************************************************************ */


/* creation */


RPTR(FeDataHolder) FeDataHolder::fake (
		APTR(PrimValue) value, 
		APTR(Position) key, 
		APTR(BeEdition) edition)
{
	RETURN_CONSTRUCT(FeVirtualDataHolder,(value, key, edition));
}


RPTR(FeDataHolder) FeDataHolder::make (APTR(PrimValue) value){
	/* Make a single DataHolder with the given value */
	
	WPTR(FeDataHolder) 	returnValue;
	returnValue = FeDataHolder::on(CurrentGrandMap.fluidGet()->newDataHolder(value));
	return returnValue;
}


RPTR(FeDataHolder) FeDataHolder::on (APTR(BeDataHolder) be){
	SPTR(FeDataHolder) result;
	
	CONSTRUCT(result,FeActualDataHolder,(be, tcsj));
	be->addFeRangeElement(result);
	WPTR(FeDataHolder) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* The kind of FeRangeElement that represents a piece of data in the 
Server, along with its identity. */


/* client accessing */


BooleanVar FeDataHolder::canMakeIdentical (APTR(FeRangeElement) newIdentity){
	/* Check that it is data with the same value,
			and check permissions,
			and forward the operation after coercing the newIdentity to 
	a persistent RangeElement. */
	
	{	BooleanVar crutch_Flag;
		/* newIdentity->isKindOf(cat_FeDataHolder) && CAST(FeDataHolder,newIdentity)->value()->isEqual(this->value()) */
		
		crutch_Flag = newIdentity->isKindOf(cat_FeDataHolder);
		if(crutch_Flag) {
			crutch_Flag = CAST(FeDataHolder,newIdentity)->value()->isEqual(this->value());
		}
		return crutch_Flag;
	}
}


void FeDataHolder::makeIdentical (APTR(FeRangeElement) newIdentity){
	/* Allow consolidation of data in 1st product. */
	
	SPTR(FeKeyMaster) ckm;
	
	/* Check that it is data with the same value,
			and check permissions,
			and forward the operation after coercing the newIdentity to 
	a persistent RangeElement. */
	/* Thing to do !!!! */
	
	/* better blast */
	ckm = CurrentKeyMaster.fluidGet();
	{	BooleanVar crutch_Flag;
		/* newIdentity->isKindOf(cat_FeDataHolder) && CAST(FeDataHolder,newIdentity)->value()->isEqual(this->value()) && ckm->hasAuthority(this->owner()) */
		
		crutch_Flag = newIdentity->isKindOf(cat_FeDataHolder);
		if(crutch_Flag) {
			crutch_Flag = CAST(FeDataHolder,newIdentity)->value()->isEqual(this->value());
			if(crutch_Flag) {
				crutch_Flag = ckm->hasAuthority(this->owner());
			}
		}
		if (crutch_Flag) {
			BLAST(CantMakeIdentical);
		}
	}
	this->getOrMakeBe()->makeIdentical(newIdentity->getOrMakeBe());
}
/* server accessing */
/* printing */


void FeDataHolder::printOn (ostream& oo){
	oo << "DataHolder(" << this->value() << ")";
}

	/* automatic 0-argument constructor */
FeDataHolder::FeDataHolder() {}



/* ************************************************************************ *
 * 
 *                    Class   FeEdition 
 *
 * ************************************************************************ */


/* creation */


RPTR(FeEdition) FeEdition::empty (APTR(CoordinateSpace) keySpace){
	/* An empty Edition, with the given CoordinateSpace but no contents. */
	
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(CurrentGrandMap.fluidGet()->newEmptyEdition(keySpace));
	return returnValue;
}


RPTR(FeEdition) FeEdition::fromAll (APTR(XnRegion) keys, APTR(FeRangeElement) value){
	/* Essential.  A singleton Edition mapping from a Region of 
	keys (potentially infinite) to a single value. */
	
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(CurrentGrandMap.fluidGet()->newEditionWithAll(keys, value->carrier()));
	return returnValue;
}


RPTR(FeEdition) FeEdition::fromArray (
		APTR(PrimArray) OF1(FeRangeElement) values, 
		APTR(XnRegion) keys/* = NULL*/, 
		APTR(OrderSpec) ordering/* = NULL*/)
{
	/* Essential.  Creates an Edition mapping from a Region of 
	keys to the values in an array. The ordering specifies the 
	correspondance between  the keys and the indices in the array.
		If a Region is given, then it must have the same count as 
	the array.  If no Region is given, then it is taken to be the 
	IntegerRegion from 0  to the size of the array. If no 
	OrderSpec is given, then it is the default ascending full 
	ordering for that CoordinateSpace. */
	
	SPTR(XnRegion) theKeys;
	SPTR(OrderSpec) theOrdering;
	
	if (keys == NULL) {
		theKeys = IntegerRegion::make (IntegerVar0, values->count());
	} else {
		theKeys = keys;
	}
	if (ordering == NULL) {
		theOrdering = theKeys->coordinateSpace()->getAscending();
	} else {
		theOrdering = ordering;
	}
	BEGIN_CHOOSE(values) {
		BEGIN_KIND(PrimDataArray,data) {
			WPTR(FeEdition) 	returnValue;
			returnValue = FeEdition::on(
					CurrentGrandMap.fluidGet()->newDataEdition(data, theKeys, theOrdering));
			return returnValue;
		} END_KIND;
		BEGIN_KIND(PtrArray,ptr) {
			WPTR(FeEdition) 	returnValue;
			returnValue = FeEdition::on(
					CurrentGrandMap.fluidGet()->newValueEdition(ptr, theKeys, theOrdering));
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return NULL;
}


RPTR(FeEdition) FeEdition::fromOne (APTR(Position) key, APTR(FeRangeElement) value){
	/* A singleton Edition mapping from a single key to a single value. */
	
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(CurrentGrandMap.fluidGet()->newEditionWith(key, value->carrier()));
	return returnValue;
}


RPTR(FeEdition) FeEdition::on (APTR(BeEdition) be){
	SPTR(FeEdition) result;
	
	CONSTRUCT(result,FeEdition,(be, FeLabel::fake()));
	be->addFeRangeElement(result);
	WPTR(FeEdition) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(FeEdition) FeEdition::on (APTR(BeEdition) be, APTR(FeLabel) label){
	SPTR(FeEdition) result;
	
	CONSTRUCT(result,FeEdition,(be, label));
	be->addFeRangeElement(result);
	WPTR(FeEdition) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(FeEdition) FeEdition::placeHolders (APTR(XnRegion) keys){
	/* Essential.  Create a new Edition mapping from each key in 
	the Region to a new, unique PlaceHolder. The owner will have 
	the capability to make them become something else. */
	
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(CurrentGrandMap.fluidGet()->newPlaceHolders(keys));
	return returnValue;
}
/* constants */
/* The kind of FeRangeElement that consists of an immutable 
organization of RangeElements, indexed by Positions in some CoordinateSpace.
 R1 prohibits cyclic containment.

Set notation is used in the comments documenting some of the methods 
of this class.  In each case the cleartext explanation stands alone, 
and the set notation is a separate, more formal, expression of the 
actions of the method, in terms of key(position)/label/value triples 
("<k,l,v>"). */


/* operations */


RPTR(FeEdition) FeEdition::combine (APTR(FeEdition) other){
	/* Essential.  Return a new FeEdition containing the contents 
	of boththe receiver and the argument Editions, and with the 
	label of the receiving edition; where they share positions, 
	they must have the same RangeElement.  Currently the two may 
	not share positions.  It is unclear whether to elevate this 
	from an implementation restriction to a specification.  The 
	advantage of so specifying is that 'combine' becomes timing 
	independent, i.e. a failing combine could otherwise succeed 
	after the differing range elements were unified (by 
	FeRangeElement::makeIdentical()).  See FeEdition::mapSharedOnt
	o and FeEdition::transformedBy.
		
		{ <k,l,v> | <k,l,v> in self or <k,l,v> in other }
		requires:
			currently: { k | <k,la,v1> in self and <k,lb,v2> in other } is empty
			eventually maybe: { k | v1 not same as v2 
										and <k,la,v1> in self and <k,lb,v2> in other } is empty */
	
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(myBeEdition->combine(other->beEdition()), myLabel);
	return returnValue;
}


RPTR(FeEdition) FeEdition::copy (APTR(XnRegion) positions){
	/* Return a new FeEdition which is the subset of this Edition 
	with the domain restricted to the given set of positions  The 
	new edition has the same label as this edition.
		
		{ <k,l,v> | k in positions and <k,l,v> in self } */
	
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(myBeEdition->copy(positions), myLabel);
	return returnValue;
}


RPTR(FeEdition) FeEdition::replace (APTR(FeEdition) other){
	/* Return a new FeEdition with the label of the current 
	Edition and the contents of both Editions; where they share 
	positions, use the contents and labels of the other Edition. 
	Equivalent to
			this->copy (other->domain ()->complement ())->combine (other).
			
		{ <k,l,v> | <k,l,v> in other or (<k,l,v> in self and 
	<k,l2,v2> not in other } */
	
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(myBeEdition->replace(other->beEdition()), myLabel);
	return returnValue;
}


RPTR(FeEdition) FeEdition::transformedBy (APTR(Mapping) mapping){
	/* Essential.  Return a new FeEdition containing the contents 
	and label of the current Edition with the positions 
	transformed according to the given Mapping. Where the Mapping 
	takes several positions in the domain to a single position in 
	the range, this Edition must have the same RangeElement and 
	label at all the domain positions.  Currently the mapping 
	must be 'onto', i.e., no more that one domain position may 
	map onto any given range position.  It is unclear whether to 
	elevate this from an implementation restriction to a 
	specification.  See FeEdition::mapSharedOnto and FeEdition::combine.
		
		{ <k2,l1,v1> | <k1,l1,v1> in self and <k1,k2> in mapping }
		requires:
			Currently: not exists k1a, k1b : k1a != k1b and <k1a,k2> in 
	mapping and <k1b,k2> in mapping.
			Maybe eventually: for all v1, v2 : <k,l1,v1> in result and 
	<k,l2,v2> in result, v1 is same as v2 */
	
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(myBeEdition->transformedBy(mapping), myLabel);
	return returnValue;
}


RPTR(FeEdition) FeEdition::with (APTR(Position) position, APTR(FeRangeElement) value){
	/* Return a new FeEditionwith the same contents and label as 
	this Edition, except for the addition or substitution of a 
	RangeElement at a specified position.
		(The difference between with() and rebind() is exactly that 
	rebind() preserves the old label at position, while with() 
	installs the label attached to the value argument.)
		Equivalent to:
			this->replace (FeServer::current ()->makeEditionWith 
	(position, value)) */
	
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(myBeEdition->with(position, value->carrier()), myLabel);
	return returnValue;
}


RPTR(FeEdition) FeEdition::withAll (APTR(XnRegion) positions, APTR(FeRangeElement) value){
	/* Return a new FeEdition with the same contents and label as 
	this Edition, except at a specified set of positions, where 
	the old values and labels, if there are any, are superceded 
	by the value argument.
		Equivalent to:
			this->replace (FeServer::current ()->makeEditionWithAll 
	(positions, value)) */
	
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(myBeEdition->withAll(positions, value->carrier()), myLabel);
	return returnValue;
}


RPTR(FeEdition) FeEdition::without (APTR(Position) position){
	/* Return a new FeEdition with the same contents and label as 
	this Edition, except at a specified position, where the old 
	value and label, if there is one, is removed.
		Equivalent to:
			this->copy (position->asRegion ()->complement ()) */
	
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(myBeEdition->without(position), myLabel);
	return returnValue;
}


RPTR(FeEdition) FeEdition::withoutAll (APTR(XnRegion) positions){
	/* Return a new FeEdition with the same contents and label as 
	this Edition, except at a specified set of positions, where 
	the old values and labels, if there are any, are removed.
		Equivalent to
			this->copy (positions->complement ()) */
	
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(myBeEdition->withoutAll(positions), myLabel);
	return returnValue;
}
/* accessing */


RPTR(CoordinateSpace) FeEdition::coordinateSpace (){
	/* Return the space in which the positions of this Edition 
	are positions. Equivalent to
			this->domain ()->coordinateSpace () */
	
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = myBeEdition->coordinateSpace();
	return returnValue;
}


IntegerVar FeEdition::cost (Int32 method){
	/* Essential. Retiurn how much space this Edition is taking 
	up on the disk, in bytes (but the precision may exceed the 
	accuracy; it's simply a well-known unit). The method 
	determines how material shared with other Editions is 
	treated: if omitShared, it is not counted at all; if 
	prorateShared, then it is divided evenly among the Editions 
	sharing it; if totalShared, its entire cost is counted. This 
	figure is only approximate, and may vary with time.
		(No permissions are required to obtain this informiation, 
	even though it exposes sharing by Editions you can't read to 
	traffic analysis.) */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return IntegerVarZero;
}


IntegerVar FeEdition::count (){
	/* Return the number of positions in this Edition. Blasts if 
	infinite. Equivalent to
			this->domain ()->count () */
	
	return myBeEdition->count();
}


RPTR(XnRegion) FeEdition::domain (){
	/* Essential.  Return the region consisting of all the 
	positions in this Edition. May be infinite, or empty.
		
		{ k | <k,l,v> in self } */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = myBeEdition->domain();
	return returnValue;
}


RPTR(FeRangeElement) FeEdition::get (APTR(Position) position){
	/* Return the value at the given position, or blast if there 
	is no such position (i.e. if ! this->domain ()->hasMember (position)).
		
		v : <position,l,v> in self
		requires: <position,l,v> in self */
	
	WPTR(FeRangeElement) 	returnValue;
	returnValue = myBeEdition->get(position);
	return returnValue;
}


BooleanVar FeEdition::hasPosition (APTR(Position) position){
	/* Return whether the given position is in the Edition. Equivalent to
			this->domain ()->hasMember (position) */
	
	/* Thing to do !!!! */
	
	/* rename Be protocol */
	return myBeEdition->includesKey(position);
}


BooleanVar FeEdition::isEmpty (){
	/* Return whether there are any positions in this Edition. 
	Equivalent to
			this->domain ()->isEmpty () */
	
	return myBeEdition->isEmpty();
}


BooleanVar FeEdition::isFinite (){
	/* Return whether there are a finite number of positions in 
	this Edition. Equivalent to
			this->domain ()->isFinite () */
	
	return myBeEdition->isFinite();
}


RPTR(Stepper) OF1(Bundle) FeEdition::retrieve (
		APTR(XnRegion) region/* = NULL*/, 
		APTR(OrderSpec) order/* = NULL*/, 
		Int32 flags/* = Int32Zero*/)
{
	/* Essential.  This is the fundamental retrieval operation.  
	Return a stepper of bundles.  Each bundle is an association 
	between a region in the domain and the range elements 
	associated with that region.  Where the region is associated 
	with data, for instance, the bundle contains a PrimArray of 
	the data elements.
		If a region is given, only that subset of the Edition's 
	contents will be returned.  If it is not given, the entire 
	content of the Edition will be returned.
		if the ignoreTotalOrdering flag is set, then the operation 
	can group non-contiguous regions, and can supply the bundles 
	in any order.
		if the ignoreArrayOrdering flag is set, then ArrayBundles 
	returned by the operation can be ordered differently from the 
	supplied order.
		If an OrderSpec is not supplied, then the ordering will be 
	the default order for the coordinate space, if one exists, 
	and if none exists the returned data will be completely 
	unordered and the Ordering flags will be ignored. */
	
	/* Thing to do !!!! */
	
	/* The above comment is still horribly insufficient. */
	WPTR(Stepper) OF1(Bundle) 	returnValue;
	returnValue = myBeEdition->retrieve(region, order, flags);
	return returnValue;
}


RPTR(TableStepper) OF1(FeRangeElement) FeEdition::stepper (APTR(XnRegion) region/* = NULL*/, APTR(OrderSpec) ordering/* = NULL*/){
	/* Return a stepper for iterating over the positions and 
	RangeElements of this Edition. If a region is specified, then 
	it only iterates over the domain positions which are in the 
	given region. If no ordering is specified, then the default 
	ascending full ordering of the CoordinateSpace is used, or a 
	random order chosen if there is no default. */
	
	SPTR(XnRegion) theRegion;
	
	theRegion = this->domain();
	if (region != NULL) {
		theRegion = theRegion->intersect(region);
	}
	RETURN_CONSTRUCT(EditionStepper,(theRegion->stepper(ordering), this));
}


RPTR(FeRangeElement) FeEdition::theOne (){
	/* If this Edition has a single position, then return the 
	RangeElement at that position; if not, blasts. Equivalent to
			this->get (this->domain ()->theOne ()) */
	
	WPTR(FeRangeElement) 	returnValue;
	returnValue = myBeEdition->theOne();
	return returnValue;
}
/* comparing */


BooleanVar FeEdition::isRangeIdentical (APTR(FeEdition) other, APTR(XnRegion) region/* = NULL*/){
	/* Whether the two Editions have the same domains, and each 
	RangeElement isIdentical to the corresponding RangeElement in 
	the other Edition. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return FALSE;
}


RPTR(Mapping) FeEdition::mapSharedOnto (APTR(FeEdition) other){
	/* Return a mapping such that for each range element that 
	appears in both editions, the mapping maps each of its 
	appearances in the argument edition to some appearance in 
	this one.  (Some of the appearances in this edition may be 
	unmapped or mapped to multiple appearances in the argument 
	edition.)  Like 'mapSharedTo' except that the resulting 
	mapping is 'onto'.  This means that each range position of 
	the resulting mapping inverse maps to at most one domain 
	position.  Such a mapping is suitable as an argument to 
	'transformedBy', and represents the minimal transformation 
	needed to make the shared part of 'other' from self.  Note 
	that there is no unique answer.
		
		result = { <k1,k2> | <k1,l1,v1> in self and <k2,l2,v2> in 
	other and v1 is same as v2
								and not exists k11 : k11 != k1 and <k11,k2> in result }
		
	Note that this is useful for optimization of FeBe 
	communication and Frontend display updating. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}


RPTR(Mapping) FeEdition::mapSharedTo (APTR(FeEdition) other){
	/* Essential.  Return a Mapping from each of the positions in 
	this Edition to all of the positions in the other Edition 
	which have the same RangeElement.
		
		{ <k1,k2> | <k1,l1,v1> in self and <k2,l2,v2> in other and 
	v1 is same as v2 } */
	
	WPTR(Mapping) 	returnValue;
	returnValue = myBeEdition->mapSharedTo(other->beEdition());
	return returnValue;
}


RPTR(FeEdition) FeEdition::notSharedWith (APTR(FeEdition) other, Int32 flags/* = Int32Zero*/){
	/* Return a new FeEdition containing exactly the subset of 
	this Edition whose RangeElements are not in the other Edition.
		Equivalent to:
			this->copy (this->sharedRegion (other)->complement ()).
			
		{ <k1,l1,v1> | <k1,l1,v1> in self and <k2,l2,v2> in other 
	and v1 is same as v2 }
		
	Note that this is useful for optimization of FeBe 
	communication and Frontend display updating. */
	
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(myBeEdition->notSharedWith(other->beEdition(), flags), myLabel);
	return returnValue;
}


RPTR(XnRegion) FeEdition::positionsOf (APTR(FeRangeElement) value){
	/* Return the region consisting of all the positions in this 
	Edition at which the given RangeElement can be found.
		Equivalent to:
			this->sharedRegion (theServer ()->makeEditionWith (some 
	position, value)).
			
		{ k | <k,l,v> in self and v is same as value } */
	
	/* Thing to do !!!! */
	
	/* rename Be protocol */
	WPTR(XnRegion) 	returnValue;
	returnValue = myBeEdition->keysOf(value);
	return returnValue;
}


RPTR(FeEdition) FeEdition::rangeTranscluders (
		APTR(XnRegion) positions/* = NULL*/, 
		APTR(Filter) directFilter/* = NULL*/, 
		APTR(Filter) indirectFilter/* = NULL*/, 
		Int32 flags/* = Int32Zero*/, 
		APTR(FeEdition) otherTranscluders/* = NULL*/)
{
	/* Essential.  Return a new FeEdition containing all Editions 
	which can be read with the authority of the CurrentKeyMaster, 
	and which transclude RangeElements in this Edition. 
	Immediately returns with an Edition full of PlaceHolders, 
	which will be filled in as results appear; the lookup 
	proceeds asynchronously.
		The Server will attempt to avoid placing duplicate copies in 
	the result, but it may still happen.
		If a Region is given, then the request only considers the 
	subset at those positions (i.e. equivalent to this->copy 
	(positions)->rangeTransclusions (...))
		If a directFilter is given, then the endorsements on the 
	resulting Editions, unioned with the endorsements on any 
	Works directly on those Editions to which the 
	CurrentKeyMaster has read permission, must pass the filter.
		If an indirectFilter is given, then the resulting Editions 
	must be contained, directly or indirectly, by an Edition 
	whose endorsements (unioned with its readable Works 
	endorsements) pass the filter. (Giving a non-NULL 
	indirectFilter will probably not be supported in version 1.0.)
		If the directContainersOnly flag is set, then the result 
	only includes Editions which have the material as 
	RangeElements; otherwise, the result includes Editions which 
	indirectly contain the material through other Editions. 
	(Setting this flag will probably not be supported in version 1.0.)
		If the fromTransitiveContents flag is set, then the result 
	includes transclusions of RangeElements of sub-Editions of 
	this one, in addition to the RangeElements in this Edition. 
	(Setting ths flag will probably not be supported in version 1.0.)
		If localPresentOnly flag is clear, a persistent request will 
	be created, and the new FeEdition will continue to be filled 
	in in the future.  If it is set, only those Editions which 
	are currently known to transclude by this Backend are sure to 
	be recorded into the Trail.  (Some, but not all, Editions 
	which come to transclude while this request is being 
	processed may be recorded.  If the request is followed by a 
	FeServer::waitForConsequences(), no Editions which come to 
	transclude after the wait completes will be recorded.)
		If otherTranscluders is given, then the results will be 
	recorded into it. (This may increase the chance of the same 
	Edition being recorded twice.)
		(For convenience, you can attach a TransclusionDetector to 
	the result Edition.  See FeEdition::addFillRangeDetector()  
	See also FeServer::waitForConsequences().) */
	
	SPTR(BeEdition) theOther;
	SPTR(Filter) theDirectFilter;
	SPTR(Filter) theIndirectFilter;
	
	if (otherTranscluders == NULL) {
		theOther = NULL;
	} else {
		theOther = otherTranscluders->beEdition();
	}
	if (directFilter == NULL) {
		theDirectFilter = CAST(Filter,FeServer::endorsementFilterSpace()->fullRegion());
	} else {
		theDirectFilter = directFilter;
	}
	if (indirectFilter == NULL) {
		theIndirectFilter = CAST(Filter,FeServer::endorsementFilterSpace()->fullRegion());
	} else {
		theIndirectFilter = indirectFilter;
	}
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(
			myBeEdition->rangeTranscluders(positions, theDirectFilter, theIndirectFilter, flags, theOther));
	return returnValue;
}


RPTR(FeEdition) FeEdition::rangeWorks (
		APTR(XnRegion) positions/* = NULL*/, 
		APTR(Filter) filter/* = NULL*/, 
		Int32 flags/* = Int32Zero*/, 
		APTR(FeEdition) otherTranscluders/* = NULL*/)
{
	/* Essential.  Return a new FeEdition containing all Works 
	which contain RangeElements of this Edition and can be read 
	by the CurrentKeyMaster. Returns an IDSpace Edition full of 
	PlaceHolders, which will be filled with Works as results come in.
		If a filter is given, then only Works whose endorsements 
	pass the Filter are returned.
		If the localPresentOnly flag is clear, a persistent request 
	will be created, and as new Works come to be known to the 
	Server, they will be filled into the resulting Edition.  If 
	it is set, only Works currently known to this Server are sure 
	to be recorded into the Trail.  (Some, but not all, Works 
	which become known while this request is being processed may 
	be recorded.  If the request is followed by a 
	FeServer::waitForConsequences(), no Works which become known 
	after the wait completes will be recorded.)
		If the fromTransitiveContents flag is set, then the result 
	includes Works which contain RangeElements transitively 
	contained in this Edition. (This may not be supported in 1.0)
		If directContainersOnly is set, then only Works which are 
	directly on Editions which are RangeElements of this Edition 
	are returned (and not Works which are on Editions which have 
	them as sub-Editions).
		If otherTranscluders is given, this records works into that trail.
		(For convenience, you can attach a TransclusionDetector to 
	the result Edition.  See FeEdition::addFillRangeDetector()  
	See also FeServer::waitForConsequences().)
		
		{ <k,l,w> | w's contains self, w passes filter} */
	
	SPTR(BeEdition) theOther;
	SPTR(Filter) theFilter;
	
	if (otherTranscluders == NULL) {
		theOther = NULL;
	} else {
		theOther = otherTranscluders->beEdition();
	}
	if (filter == NULL) {
		theFilter = CAST(Filter,FeServer::endorsementFilterSpace()->fullRegion());
	} else {
		theFilter = filter;
	}
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(
			myBeEdition->rangeWorks(positions, theFilter, flags, theOther));
	return returnValue;
}


RPTR(XnRegion) FeEdition::sharedRegion (APTR(FeEdition) other, Int32 flags/* = Int32Zero*/){
	/* Return the subset of the positions of this Edition which  
	have RangeElements that are in the other Edition.
		If nestThis flag is set, then returns not only positions of 
	RangeElements which are in the other, but also positions of 
	Editions which have RangeElements which are in the other, or 
	which have other such Editions, recursively.  (This searches 
	down to, but not across, work boundaries.)
		If nestOther flag is set, then looks not only for 
	RangeElements which are values of the other Edition, but also 
	those which are values of sub-Editions of the other Edition. 
	(This option will probably not be supported in version 1.0).
		If both flags are false, then equivalent to:
			this->mapSharedTo (other)->domain ()
		
		{ k1 | <k1,l1,v1> in self and <k2,l2,v2> in other and v1 is 
	same as v2 } */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = myBeEdition->sharedRegion(other->beEdition(), flags);
	return returnValue;
}


RPTR(FeEdition) FeEdition::sharedWith (APTR(FeEdition) other, Int32 flags/* = Int32Zero*/){
	/* Essential.  Return a new FeEdition consisting of the 
	subset of this Edition whose RangeElements are in the other 
	Edition. If the same RangeElement is in this Edition at 
	several different positions, all positions will be in the 
	result (provided the RangeElement is also in the other Edition).
		Equivalent to:
			this->copy (this->sharedRegion (other, flags)).
			
		{ <k1,l1,v1> | <k1,l1,v1> in self and <k2,l2,v2> in other 
	and v1 is same as v2 } */
	
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(myBeEdition->sharedWith(other->beEdition(), flags), myLabel);
	return returnValue;
}
/* endorsing */


void FeEdition::endorse (APTR(CrossRegion) additionalEndorsements){
	/* Essential.  Adds to the endorsements on this Edition.  The 
	region of additionalEndorsements must consist of a finite 
	number of (club ID, token ID) pairs.  CurrentKeyMaster must 
	hold the signature authority of all the Clubs used to 
	endorse; the request will blast and do nothing if any of the 
	required authority is lacking.  (Redoing an endorse() undoes 
	a retract()) */
	
	FeRangeElement::validateEndorsement(additionalEndorsements, CurrentKeyMaster.fluidGet());
	myBeEdition->endorse(additionalEndorsements);
}


RPTR(CrossRegion) FeEdition::endorsements (){
	/* Essential.  Return all of the endorsements which have been 
	placed on this Edition and not retracted. */
	
	WPTR(CrossRegion) 	returnValue;
	returnValue = myBeEdition->endorsements();
	return returnValue;
}


void FeEdition::retract (APTR(CrossRegion) endorsements){
	/* Essential.  Removes endorsements from this Edition.  This 
	requires that the CurrentKeyMaster hold signature authority 
	for all of the Clubs whose endorsements are in the list; will 
	blast and do nothing if any of the required authority is 
	lacking, even if the endorsements weren't there to be 
	retracted.  Ignores all endorsements which you could have 
	removed, but which don't happen to be there right now.
		
		In the current release removed endorsements aren't 
	preserved, so they vanish forever.  Beginning in some future 
	release removed endorsements will become inactive, but it 
	will be possible to detect that they once had been present.  
	The intent is for a removed endorsement to be analogous to a 
	signature that has been struck out.  You can express that you 
	changed your mind, but you can't undo the past. */
	
	FeRangeElement::validateEndorsement(endorsements, CurrentKeyMaster.fluidGet());
	myBeEdition->retract(endorsements);
}


RPTR(CrossRegion) FeEdition::visibleEndorsements (){
	/* Essential.  Return all the unretracted endorsements on 
	this Edition along with those on any Works directly on it 
	which the CurrentKeyMaster has permission to read. */
	
	WPTR(CrossRegion) 	returnValue;
	returnValue = myBeEdition->visibleEndorsements();
	return returnValue;
}
/* becoming */


void FeEdition::addFillRangeDetector (APTR(FeFillRangeDetector) detector){
	/* Essential.  Connect a FillRangeDetector to the underlying 
	BeEdition so that when any of the PlaceHolders in that 
	Edition become any other kind of RangeElement, then the 
	Detector will be triggered with an Edition containing the new 
	RangeElements (but not necessarily at the same positions, or 
	even in the same CoordinateSpace). If there already are 
	non-PlaceHolders, then the Detector is triggered immediately 
	with those RangeElements.
		See FillRangeDetector::allFilled (Edition * newIdentities). */
	
	myBeEdition->addDetector(detector);
}


RPTR(XnRegion) FeEdition::canMakeRangeIdentical (APTR(FeEdition) newIdentities, APTR(XnRegion) positions/* = NULL*/){
	/* Essential.  Return the region consisting of all locations 
	at which my RangeElements can NOT be made identical to the 
	corresponding RangeElements in the other Edition. (This seems 
	like the opposite of what you want, but in fact it makes it 
	easy to check for success.)
		Does not check whether you have permissions to do so, just 
	whether it could be done by someone with the appropriate 
	permissions. See rangeOwners. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}


RPTR(FeFillRangeDetector) FeEdition::fillRangeDetector (){
	/* Essential.  Return a FillRangeDetector so that when any of 
	the PlaceHolders in this Edition become any other kind of 
	RangeElement, then the Detector will be triggered with an 
	Edition containing the new RangeElements (but not necessarily 
	at the same positions, or even in the same CoordinateSpace). 
	If there already are non-PlaceHolders, then the Detector is 
	triggered immediately with those RangeElements.
		See FillRangeDetector::allFilled (Edition * newIdentities). */
	
	BLAST(NOT_YET_IMPLEMENTED);
	this->addFillRangeDetector(NULL);
	/* fodder */
	return NULL;
}


RPTR(FeEdition) FeEdition::makeRangeIdentical (APTR(FeEdition) newIdentities, APTR(XnRegion) positions/* = NULL*/){
	/* Essential.  Try to change the identity of each 
	RangeElements of this Edition which are in the Region (or all 
	if no Region supplied) to that of the RangeElement at the 
	same position in the other Edition. Returns the subset of 
	this Edition which did not end up with the new identities, because of
			- lack of ownership authority
			- different contents
			- contents of other edition unreadable
			- incompatible types
			- no corresponding new identity
			
	Note that the labels on the RangeElements need not match and 
	will NOT be changed. */
	
	SPTR(BeEdition) never;
	SPTR(BeEdition) maybe;
	SPTR(BeEdition) trial;
	SPTR(Pair) OF1(BeEdition) result;
	SPTR(XnRegion) theRegion;
	
	/* Keep trying the primitive routine until it says it can't 
	do any more */
	/* Known bug !!!! */
	
	/* put loop into server loop */
	if (!this->coordinateSpace()->isEqual(newIdentities->coordinateSpace())) {
		return this;
	}
	never = CurrentGrandMap.fluidGet()->newEmptyEdition(this->coordinateSpace());
	maybe = myBeEdition;
	theRegion = maybe->domain();
	if (positions != NULL) {
		theRegion = theRegion->intersect(positions);
	}
	trial = newIdentities->beEdition()->copy(theRegion);
	while ((result = maybe->tryAllBecome(trial))->fetchRight() != NULL) {
		never = never->combine(CAST(BeEdition,result->left()));
		maybe = CAST(BeEdition,result->right());
		trial = trial->copy(maybe->domain());
	}
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(never, myLabel);
	return returnValue;
}


RPTR(IDRegion) FeEdition::rangeOwners (APTR(XnRegion) positions/* = NULL*/){
	/* The owners of all the RangeElements in the given Region, 
	or in the entire 
		Edition if no Region is specified. */
	
	WPTR(IDRegion) 	returnValue;
	returnValue = myBeEdition->rangeOwners(positions);
	return returnValue;
}


void FeEdition::removeFillRangeDetector (APTR(FeFillRangeDetector) detector){
	/* Essential.  Remove a Detector which had been added to this 
	Edition. You should remove every Detector you add, although 
	they will go away automatically when a client session terminates. */
	
	if (!::isDestructed(myBeEdition)) {
		myBeEdition->removeDetector(detector);
	}
}


RPTR(FeEdition) FeEdition::setRangeOwners (APTR(ID) newOwner, APTR(XnRegion) region/* = NULL*/){
	/* Changes the owner of all RangeElements in the Edition (but 
	not the Edition itself!); requires the authority of the 
	current owner of each range element. If a Region is supplied, 
	then only sets those in the region.
		Returns the subset of this Edition which is in the Region 
	whose owners did not end up being the new Owner because of 
	lack of authority. */
	
	SPTR(XnRegion) theRegion;
	
	if (region == NULL) {
		theRegion = this->domain();
	} else {
		theRegion = region;
	}
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(myBeEdition->setRangeOwners(newOwner, theRegion), myLabel);
	return returnValue;
}
/* labelling */


RPTR(FeLabel) FeEdition::label (){
	return (FeLabel*) myLabel;
}


RPTR(XnRegion) FeEdition::positionsLabelled (APTR(FeLabel) label){
	/* Return a region consisting of exactly the positions in 
	this Edition which are associated with the given label.
		
		{ k | <k,label,v> in self } */
	
	/* Thing to do !!!! */
	
	/* rename Be protocol */
	WPTR(XnRegion) 	returnValue;
	returnValue = myBeEdition->keysLabelled(CAST(BeLabel,label->fetchBe()));
	return returnValue;
}


RPTR(FeEdition) FeEdition::rebind (APTR(Position) position, APTR(FeEdition) edition){
	/* Return a new FeEdition which is a copy of this Edition 
	with the contained Edition at the given position replaced by 
	the given Edition, but with the Label at that position 
	unchanged.  Equivalent to
			this->with (position, edition->relabelled (this->get 
	(position)->label ())).
	
		Note that rebind() is useless (and blasts) when a 
	non-edition RangeElement is at the given position.
			
		{ <k,l,v> | ((k isEqual: position) and (v is same as edition)) 
					or (<k,l,v> in self and k != position) } */
	
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::fromOne(position, edition->relabelled(CAST(FeEdition,this->get(position))->label()));
	return returnValue;
}


RPTR(FeRangeElement) FeEdition::relabelled (APTR(FeLabel) label){
	WPTR(FeRangeElement) 	returnValue;
	returnValue = FeEdition::on(myBeEdition, label);
	return returnValue;
}
/* server accessing */


RPTR(BeEdition) FeEdition::beEdition (){
	return (BeEdition*) myBeEdition;
}


RPTR(BeCarrier) FeEdition::carrier (){
	/* Return an object that wraps up any run-time state that 
	might be needed inside the Be system.  Right now that means labels. */
	
	WPTR(BeCarrier) 	returnValue;
	returnValue = BeCarrier::make (CAST(BeLabel,myLabel->getOrMakeBe()), myBeEdition);
	return returnValue;
}


RPTR(FeRangeElement) FeEdition::fetch (APTR(Position) position){
	/* The value at the position, or NULL if there is none */
	
	WPTR(FeRangeElement) 	returnValue;
	returnValue = myBeEdition->fetch(position);
	return returnValue;
}


RPTR(BeRangeElement) OR(NULL) FeEdition::fetchBe (){
	return (BeEdition*) myBeEdition;
}


RPTR(BeRangeElement) FeEdition::getOrMakeBe (){
	return (BeEdition*) myBeEdition;
}
/* client implementation */


RPTR(FeRangeElement) FeEdition::again (){
	/* These don't change as long as someone has a handle on them. */
	
	return this;
}


BooleanVar FeEdition::canMakeIdentical (APTR(FeRangeElement) newIdentity){
	if (!this->isIdentical(newIdentity)) {
		BLAST(NOT_YET_IMPLEMENTED);
	}
	return TRUE;
}


void FeEdition::makeIdentical (APTR(FeRangeElement) newIdentity){
	if (!this->isIdentical(newIdentity)) {
		BLAST(NOT_YET_IMPLEMENTED);
	}
}
/* private: create */


FeEdition::FeEdition (APTR(BeEdition) beEdition, APTR(FeLabel) label) {
	myBeEdition = beEdition;
	myLabel = label;
}
/* printing */


void FeEdition::printOn (ostream& oo){
	char * before;
	
	if (this->isEmpty()) {
		oo << "Edition()";
		return;
		
	}
	before = "Edition(";
	BEGIN_FOR_EACH(FeBundle,bundle,(this->retrieve(NULL, NULL, FeEdition::IGNORE_TOTAL_ORDERING()))) {
		oo << before << bundle->region() << " -> ";
		BEGIN_CHOOSE(bundle) {
			BEGIN_KIND(FeArrayBundle,array) {
				oo << array->array();
			} END_KIND;
			BEGIN_KIND(FeElementBundle,range) {
				oo << range->element();
			} END_KIND;
			BEGIN_KIND(FePlaceHolderBundle,place) {
				oo << "{...}";
			} END_KIND;
		} END_CHOOSE;
		before = ", ";
	} END_FOR_EACH;
	oo << ")";
}
/* obsolete: */


BooleanVar FeEdition::includesKey (APTR(Position) position){
	/* Whether the given position is in the Edition. Equivalent to
			this->domain ()->hasMember (position) */
	
	return myBeEdition->includesKey(position);
}


RPTR(XnRegion) FeEdition::keysOf (APTR(FeRangeElement) value){
	/* All of the keys in this Edition at which the given 
	RangeElement can be found. Equivalent to
			this->sharedRegion (theServer ()->makeEditionWith (some 
	position, value)).
			
		{ k | <k,l,v> in self and v is same as value } */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = myBeEdition->keysOf(value);
	return returnValue;
}
/* destruct */


void FeEdition::destruct (){
	myBeEdition->removeFeRangeElement(this);
	this->FeRangeElement::destruct();
}



/* ************************************************************************ *
 * 
 *                    Class   FeIDHolder 
 *
 * ************************************************************************ */


/* creation */


RPTR(FeIDHolder) FeIDHolder::make (APTR(ID) iD){
	/* Essential. Make a single IDHolder with the given ID. 
	Tentative feature. */
	
	WPTR(FeIDHolder) 	returnValue;
	returnValue = FeIDHolder::on(CurrentGrandMap.fluidGet()->newIDHolder(iD));
	return returnValue;
}


RPTR(FeIDHolder) FeIDHolder::on (APTR(BeIDHolder) be){
	SPTR(FeIDHolder) result;
	
	CONSTRUCT(result,FeIDHolder,(be, tcsj));
	be->addFeRangeElement(result);
	WPTR(FeIDHolder) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* An object for having an ID in the range of an Edition. Tentative feature. */


/* accessing */


RPTR(FeRangeElement) FeIDHolder::again (){
	return this;
}


BooleanVar FeIDHolder::canMakeIdentical (APTR(FeRangeElement) newIdentity){
	if (!this->isIdentical(newIdentity)) {
		BLAST(NOT_YET_IMPLEMENTED);
	}
	return TRUE;
}


RPTR(ID) FeIDHolder::iD (){
	/* Essential.  The ID in this holder. */
	
	WPTR(ID) 	returnValue;
	returnValue = myBeIDHolder->iD();
	return returnValue;
}


void FeIDHolder::makeIdentical (APTR(FeRangeElement) newIdentity){
	if (!this->isIdentical(newIdentity)) {
		BLAST(NOT_YET_IMPLEMENTED);
	}
}
/* server accessing */


RPTR(BeRangeElement) OR(NULL) FeIDHolder::fetchBe (){
	return (BeIDHolder*) myBeIDHolder;
}


RPTR(BeRangeElement) FeIDHolder::getOrMakeBe (){
	return (BeIDHolder*) myBeIDHolder;
}
/* private: create */


FeIDHolder::FeIDHolder (APTR(BeIDHolder) be, TCSJ) {
	myBeIDHolder = be;
}
/* printing */


void FeIDHolder::printOn (ostream& oo){
	oo << "IDHolder(" << this->iD() << ")";
}
/* destruct */


void FeIDHolder::destruct (){
	myBeIDHolder->removeFeRangeElement(this);
	this->FeRangeElement::destruct();
}



/* ************************************************************************ *
 * 
 *                    Class   FeLabel 
 *
 * ************************************************************************ */


/* creation */


RPTR(FeLabel) FeLabel::fake (){
	/* The label will be made on demand. */
	
	WPTR(FeLabel) 	returnValue;
	returnValue = FeLabel::on(NULL);
	return returnValue;
}


RPTR(FeLabel) FeLabel::make (){
	/* Essential. Create a new unique Label */
	
	WPTR(FeLabel) 	returnValue;
	returnValue = FeLabel::fake();
	return returnValue;
}


RPTR(FeLabel) FeLabel::on (APTR(BeLabel) OR(NULL) label){
	SPTR(FeLabel) result;
	
	CONSTRUCT(result,FeLabel,(label, tcsj));
	if (label != NULL) {
		label->addFeRangeElement(result);
	}
	WPTR(FeLabel) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* An identity attached to a RangeElement within an Edition. */


/* server accessing */


RPTR(BeRangeElement) OR(NULL) FeLabel::fetchBe (){
	return (BeLabel*) myBeLabel;
}


RPTR(BeRangeElement) FeLabel::getOrMakeBe (){
	if (myBeLabel == NULL) {
		myBeLabel = CurrentGrandMap.fluidGet()->newLabel();
		myBeLabel->addFeRangeElement(this);
	}
	return (BeLabel*) myBeLabel;
}
/* client accessing */


RPTR(FeRangeElement) FeLabel::again (){
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}


BooleanVar FeLabel::canMakeIdentical (APTR(FeRangeElement) newIdentity){
	if (!this->isIdentical(newIdentity)) {
		BLAST(NOT_YET_IMPLEMENTED);
	}
	return TRUE;
}


void FeLabel::makeIdentical (APTR(FeRangeElement) newIdentity){
	BLAST(NOT_YET_IMPLEMENTED);
}
/* destruct */


void FeLabel::destruct (){
	if (!(myBeLabel == NULL)) {
		myBeLabel->removeFeRangeElement(this);
	}
	this->FeRangeElement::destruct();
}
/* creation */


FeLabel::FeLabel (APTR(BeLabel) OR(NULL) label, TCSJ) {
	myBeLabel = label;
}
/* printing */


void FeLabel::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << this->getOrMakeBe()->hashForEqual() << ")";
}



/* ************************************************************************ *
 * 
 *                    Class   FePlaceHolder 
 *
 * ************************************************************************ */


/* creation */


RPTR(FePlaceHolder) FePlaceHolder::fake (APTR(BeEdition) edition, APTR(Position) key){
	RETURN_CONSTRUCT(FeVirtualPlaceHolder,(edition, key));
}


RPTR(FePlaceHolder) FePlaceHolder::on (APTR(BeRangeElement) be){
	SPTR(FeRangeElement) result;
	
	CONSTRUCT(result,FeActualPlaceHolder,(be, tcsj));
	be->addFeRangeElement(result);
	return CAST(FePlaceHolder,result);
}
/* Represents a piece of pure identity in the Server. */


/* accessing */


void FePlaceHolder::addFillDetector (APTR(FeFillDetector) detector){
	/* in case it changed behind our backs */
	BEGIN_CHOOSE(this->getOrMakeBe()) {
		BEGIN_KIND(BePlaceHolder,p) {
			p->addDetector(detector);
		} END_KIND;
		BEGIN_OTHERS {
			detector->filled(this->again());
		} END_OTHERS;
	} END_CHOOSE;
}
/* server accessing */

	/* automatic 0-argument constructor */
FePlaceHolder::FePlaceHolder() {}



/* ************************************************************************ *
 * 
 *                    Class   FeWork 
 *
 * ************************************************************************ */


/* exceptions: exceptions */
/* creation */


RPTR(FeWork) FeWork::make (APTR(FeEdition) contents){
	/* Essential.  Create a new Work whose initial contents are 
	the given Edition. The reader, editor, owner, sponsor, and 
	KeyMaster come from the fluid environment. If the KeyMaster 
	has edit permission, then the Work is initially grabbed by it.
		Note: This does not assign it a global ID; that must be done 
	separately (see Server::assignID). */
	
	FeKeyMaster::assertSponsorship();
	FeKeyMaster::assertSignatureAuthority();
	WPTR(FeWork) 	returnValue;
	returnValue = CurrentGrandMap.fluidGet()->newWork(contents)->makeLockedFeWork();
	return returnValue;
}


RPTR(FeWork) FeWork::on (APTR(BeWork) be){
	SPTR(FeWork) result;
	
	CONSTRUCT(result,FeWork,(be, tcsj));
	be->addFeRangeElement(result);
	WPTR(FeWork) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* A persistent identity for a changeable object. */


/* grab status */


void FeWork::addStatusDetector (APTR(FeStatusDetector) detector){
	/* Essential.  Add a detector which will be notified whenever 
	the locking status of this Work object changes.
		See FeStatusDetector::grabbed (Work *, ID *) / released (Work *). */
	
	if (myStatusDetectors == NULL) {
		myStatusDetectors = PrimSet::weak(7, StatusDetectorExecutor::make (this));
	}
	myStatusDetectors->introduce(detector);
}


BooleanVar FeWork::canRead (){
	/* Return whether you have read permission.  If grabbed, 
	returns TRUE (because a grabber can always read); if 
	released, then returns whether the CurrentKeyMaster has 
	sufficient permission to read the work.  (Read or Edit 
	permission is required.)  Does not check any other KeyMasters 
	you may be holding.
		Note: Be careful of synchronization problems, since the 
	permissions may change between when you ask this question and 
	when you try to actually read the Work. */
	
	SPTR(FeKeyMaster) ckm;
	
	ckm = CurrentKeyMaster.fluidFetch();
	{	BooleanVar crutch_Flag;
		/* this->canRevise() || ckm != NULL && myBeWork->canBeReadBy(ckm) */
		
		crutch_Flag = this->canRevise();
		if(!crutch_Flag) {
			crutch_Flag = ckm != NULL;
			if(crutch_Flag) {
				crutch_Flag = myBeWork->canBeReadBy(ckm);
			}
		}
		return crutch_Flag;
	}
}


BooleanVar FeWork::canRevise (){
	/* Return whether the BeWork is grabbed by you through this FeWork.
		Note: Be careful of synchronization problems, since the 
	permissions may change before you try to actually revise it, 
	causing you to lose your grab. */
	
	return (Heaper * ) myBeWork->fetchLockingWork() == this;
}


void FeWork::grab (){
	/* Essential.  Grab the Work to prevent other clients from 
	revising it.  Requires edit permission. Snapshots the 
	CurrentKeyMaster and CurrentAuthor (to be used to maintain 
	the grab and report what was done with it). Fails if
			- someone else has it grabbed
			- the CurrentKeyMaster does not have edit permission
			- the CurrentKeyMaster does not have signature authority of 
	the CurrentAuthor
		If this Work was already grabbed by you, then it updates the 
	KeyMaster and Author it holds. (If the regrab fails, the old 
	grab will remain in effect.)
		The grab will be released
			- upon a release request
			- if the KeyMaster loses authority to edit
			- if the KeyMaster loses the signature authority of the Author
			- at the end of the session
			- when the FeWork object is deallocated (if an FeWork was 
	dropped while grabbed, {by destroying the promise for it, or 
	by loss of connection} it will be deallocated 'eventually') */
	
	SPTR(ID) oldAuthor;
	
	/* Check that I have edit permissions */
	if (!myBeWork->canBeEditedBy(CurrentKeyMaster.fluidGet())) {
		BLAST(MustHaveEditPermission);
	}
	if (!CurrentKeyMaster.fluidGet()->hasSignatureAuthority(CurrentAuthor.fluidGet())) {
		BLAST(MustHaveAuthorSignatureAuthority);
	}
	oldAuthor = myAuthor;
	myAuthor = CurrentAuthor.fluidFetch();
	if (myKeyMaster != NULL) {
		myKeyMaster->unregisterWork(this);
	}
	myKeyMaster = CurrentKeyMaster.fluidFetch();
	myKeyMaster->registerWork(this);
	/* Try to gain mutual exclusion */
	if (!myBeWork->tryLock(this)) {
		myAuthor = NULL;
		myKeyMaster = NULL;
		BLAST(WorkIsLockedBySomeoneElse);
	}
	/* code has been changed in such a way as to allow a race condition */
	if (amWaiting) {
		BLAST(FatalError);
	}
	/* Ravi -- Thing to do !!!! */
	
	{	BooleanVar crutch_Flag;
		/* myStatusDetectors != NULL && (oldAuthor == NULL || !oldAuthor->isEqual(myAuthor)) */
		
		crutch_Flag = myStatusDetectors != NULL;
		if(crutch_Flag) {
			crutch_Flag = oldAuthor == NULL;
			if(!crutch_Flag) {
				crutch_Flag = !oldAuthor->isEqual(myAuthor);
			}
		}
		if (crutch_Flag) {
			BEGIN_FOR_EACH(FeStatusDetector,stat,(myStatusDetectors->stepper())) {
				/* Thing to do !!!! */
				
				/* reasons */
				stat->grabbed(this, myAuthor, IntegerVarZero);
			} END_FOR_EACH;
		}
	}
}


RPTR(ID) FeWork::grabber (){
	/* Essential.  If you have edit authority, and someone has 
	the BeWork grabbed, then return the Club ID that was the 
	value of his CurrentAuthor when he grabbed it; otherwise blast.
		Requiring edit authority is appropriate here, because it is 
	exactly editors who are affected by competing grabs, and need 
	to know who has the grab.  Once the BeWork is revised, anyone 
	who can read the current trail can see the revision, but the 
	grab state doesn't necessarily imply that the BeWork will be 
	revised soon, or ever. */
	
	SPTR(FeWork) grabber;
	SPTR(FeKeyMaster) ckm;
	
	if (this->canRevise()) {
		return (ID*) myAuthor;
	}
	ckm = CurrentKeyMaster.fluidGet();
	{	BooleanVar crutch_Flag;
		/* myBeWork->fetchEditClub() != NULL && ckm->hasAuthority(myBeWork->fetchEditClub()) */
		
		crutch_Flag = myBeWork->fetchEditClub() != NULL;
		if(crutch_Flag) {
			crutch_Flag = ckm->hasAuthority(myBeWork->fetchEditClub());
		}
		if (!crutch_Flag) {
			BLAST(MustHaveEditAuthority);
		}
	}
	grabber = myBeWork->fetchLockingWork();
	if (grabber == NULL) {
		BLAST(NotGrabbed);
	}
	WPTR(ID) 	returnValue;
	returnValue = grabber->getAuthor();
	return returnValue;
}


void FeWork::release (){
	/* Essential.  Release the grab on this Work; if a 
	requestGrab had been pending, remove it. Does nothing if it 
	is already unlocked. */
	
	BooleanVar becameUnlocked;
	
	{	BooleanVar crutch_Flag;
		/* amWaiting || this->canRevise() */
		
		crutch_Flag = amWaiting;
		if(!crutch_Flag) {
			crutch_Flag = this->canRevise();
		}
		if (!crutch_Flag) {
			return;
			
		}
	}
	becameUnlocked = myBeWork->tryUnlock(this);
	myKeyMaster->unregisterWork(this);
	amWaiting = FALSE;
	myKeyMaster = NULL;
	myAuthor = NULL;
	if (becameUnlocked) {
		if (myStatusDetectors != NULL) {
			BEGIN_FOR_EACH(FeStatusDetector,stat,(myStatusDetectors->stepper())) {
				stat->released(this, IntegerVarZero);
			} END_FOR_EACH;
		}
	}
}


void FeWork::removeLastStatusDetector (){
	/* Essential.  Last detector has gone away */
	
	myStatusDetectors = NULL;
}


void FeWork::requestGrab (){
	/* Essential.  Registers a request so that the next time this 
	Work would have been released and no other grab requests are 
	outstanding the CurrentKeyMaster (as of making the request) 
	has edit permission, and has signature authority of the 
	CurrentAuthor (as of making the request), it will be grabbed 
	by this FeWork.  If this FeWork already has the Work grabbed, 
	then the request has no effect.  To find out when the grab 
	succeeds, place Status Detectors on the Work.  (If there are 
	competing requestGrabs for a BeWork, the queueing of the 
	requests may not be FIFO, but is starvation-free.)  Note that 
	if you have a requestGrab outstanding on a BeWork through one 
	FeWork, and release a grab you have through another, your 
	requestGrab has no special priority over those of other users. */
	
	if (this->canRevise()) {
		if (!myBeWork->canBeEditedBy(CurrentKeyMaster.fluidGet())) {
			BLAST(MustHaveEditPermission);
		}
		if (!CurrentKeyMaster.fluidGet()->hasSignatureAuthority(CurrentAuthor.fluidGet())) {
			BLAST(MustHaveAuthorSignatureAuthority);
		}
		myAuthor = CurrentAuthor.fluidFetch();
		myKeyMaster->unregisterWork(this);
		myKeyMaster = CurrentKeyMaster.fluidFetch();
		myKeyMaster->registerWork(this);
		return;
		
	}
	if (amWaiting) {
		myKeyMaster->unregisterWork(this);
	}
	amWaiting = TRUE;
	myKeyMaster = CurrentKeyMaster.fluidGet();
	myAuthor = CurrentAuthor.fluidGet();
	this->updateStatus();
	myKeyMaster->registerWork(this);
}


RPTR(FeStatusDetector) FeWork::statusDetector (){
	/* Essential.  Return a detector which will be notified 
	whenever the locking status of this Work changes.
		See FeStatusDetector::grabbed (Work *, ID *) / released (Work *). */
	
	BLAST(NOT_YET_IMPLEMENTED);
	this->addStatusDetector(NULL);
	/* fodder */
	return NULL;
}
/* contents */


RPTR(FeEdition) FeWork::edition (){
	/* Essential.  Return the current Edition.  Succeeds if the 
	Work is already grabbed, or if the CurrentKeyMaster has 
	either Read or Edit permission.
		Note: If this is an unsponsored Work, the Edition might have 
	been discarded, in which case this operation will blast. */
	
	if (!this->canRead()) {
		BLAST(MustHaveReadPermission);
	}
	WPTR(FeEdition) 	returnValue;
	returnValue = myBeWork->edition();
	return returnValue;
}


void FeWork::revise (APTR(FeEdition) newEdition){
	/* Essential.  Change the current Edition of this work to 
	newEdition. The Work must be grabbed  The grabber is recorded 
	as the author who made the revision.
		 (This is the fundamental write operation.) */
	
	if (!this->canRevise()) {
		BLAST(WorkMustBeGrabbed);
	}
	{	FLUID_BIND(CurrentKeyMaster,myKeyMaster) {
			{	FLUID_BIND(CurrentAuthor,myAuthor) {
					myBeWork->revise(newEdition);
				}
			}
		}
	}
}
/* permissions */


RPTR(ID) FeWork::editClub (){
	/* Essential.  Return the club which has permission to revise 
	this Work.  Blasts if noone can (i.e. editor has been removed). */
	
	if (myBeWork->fetchEditClub() == NULL) {
		BLAST(EditorRemoved);
	}
	WPTR(ID) 	returnValue;
	returnValue = myBeWork->fetchEditClub();
	return returnValue;
}


RPTR(ID) FeWork::historyClub (){
	/* Essential. Return the club which will be recorded as the 
	initial club for frozen Works in the history trail.  Blasts 
	if there is no trail being generated. */
	
	SPTR(ID) result;
	
	result = myBeWork->fetchHistoryClub();
	if (result == NULL) {
		BLAST(NoHistoryClub);
	}
	WPTR(ID) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(ID) FeWork::readClub (){
	/* Essential.  Return the club which has permission to read 
	this Work.  Blasts if the read Club has been removed (in that 
	case, only those who have edit permission can read the Work). */
	
	if (myBeWork->fetchReadClub() == NULL) {
		BLAST(ReadClubRemoved);
	}
	WPTR(ID) 	returnValue;
	returnValue = myBeWork->fetchReadClub();
	return returnValue;
}


void FeWork::removeEditClub (){
	/* Essential.  Irrevocably remove edit permission. Requires 
	ownership authority. */
	
	if (!CurrentKeyMaster.fluidGet()->hasAuthority(this->owner())) {
		BLAST(MustBeOwner);
	}
	myBeWork->setEditClub(NULL);
}


void FeWork::removeReadClub (){
	/* Essential.  Irrevocably remove read permission (although 
	you should note that editors are still able to read, if there 
	are any). Requires ownership authority. */
	
	if (!CurrentKeyMaster.fluidGet()->hasAuthority(this->owner())) {
		BLAST(MustBeOwner);
	}
	myBeWork->setReadClub(NULL);
}


void FeWork::setEditClub (APTR(ID) OR(NULL) club){
	/* Essential.  Change who has edit permission. Requires 
	ownership authority.
		 Aborts if the Work doesn't have an edit Club. */
	
	if (!CurrentKeyMaster.fluidGet()->hasAuthority(this->owner())) {
		BLAST(MustBeOwner);
	}
	if (myBeWork->fetchEditClub() == NULL) {
		BLAST(EditClubIrrevocablyRemoved);
	}
	myBeWork->setEditClub(club);
}


void FeWork::setHistoryClub (APTR(ID) OR(NULL) club){
	/* Essential.  Change the initial read Club for frozen Works 
	in the trail. Requires ownership authority. Setting it to 
	NULL turns off the recording of history. */
	
	if (!CurrentKeyMaster.fluidGet()->hasAuthority(this->owner())) {
		BLAST(MustBeOwner);
	}
	myBeWork->setHistoryClub(club);
}


void FeWork::setReadClub (APTR(ID) OR(NULL) club){
	/* Essential.  Change who has read permission. Requires 
	ownership authority.
		 Aborts if the works doesn't have a read Club. */
	
	if (!CurrentKeyMaster.fluidGet()->hasAuthority(this->owner())) {
		BLAST(MustBeOwner);
	}
	if (myBeWork->fetchReadClub() == NULL) {
		BLAST(ReadClubIrrevocablyRemoved);
	}
	myBeWork->setReadClub(club);
}
/* endorsing */


void FeWork::endorse (APTR(CrossRegion) additionalEndorsements){
	/* Essential.  Adds to the endorsements on this Work. The set 
	of endorsements must be a finite number of (club ID, token 
	ID) pairs. This requires the signature authority of all of 
	the Clubs used to endorse; will blast and do nothing if any 
	of the required authority is lacking. The token IDs must not 
	be named IDs. */
	
	FeRangeElement::validateEndorsement(additionalEndorsements, CurrentKeyMaster.fluidGet());
	myBeWork->endorse(additionalEndorsements);
}


RPTR(CrossRegion) FeWork::endorsements (){
	/* Essential.  Return all of the endorsements which have been 
	placed on this Work and are not currently retracted.
		(Endorsements are used to filter various operations which 
	return sets of Works.  See FeEdition::rangeTranscluders() for 
	one way to find this work by filtering for its endorsements.) */
	
	WPTR(CrossRegion) 	returnValue;
	returnValue = myBeWork->endorsements();
	return returnValue;
}


void FeWork::retract (APTR(CrossRegion) removedEndorsements){
	/* Essential.  Removes endorsements from this Work. This 
	requires the signature authority of all of the Clubs whose 
	endorsements are in the list; will blast and do nothing if 
	any of the required authority is lacking. Ignores all 
	endorsements which you could have removed, but which don't 
	happen to be there right now. */
	
	FeRangeElement::validateEndorsement(removedEndorsements, CurrentKeyMaster.fluidGet());
	myBeWork->retract(removedEndorsements);
}
/* sponsoring */


void FeWork::sponsor (APTR(IDRegion) clubs){
	/* Essential.  Add to the list of sponsors of this Work. 
	Requires signature authority of all of the Clubs in the set. */
	
	FeRangeElement::validateSignature(clubs, CurrentKeyMaster.fluidGet());
	myBeWork->sponsor(clubs);
}


RPTR(IDRegion) FeWork::sponsors (){
	/* Essential.  All of the Clubs which are sponsoring this 
	Work to keep it from being discarded.
		What sort of permissions does this require? */
	
	WPTR(IDRegion) 	returnValue;
	returnValue = myBeWork->sponsors();
	return returnValue;
}


void FeWork::unsponsor (APTR(IDRegion) clubs){
	/* Essential.  End sponsorship of this Work by all of the 
	listed Clubs. Requires signature authority of all of the 
	Clubs in the set, even if they are not currently sponsors.
		Should this use the CurrentKeyMaster? Or the internal 
	KeyMaster if it is grabbed? */
	
	FeRangeElement::validateSignature(clubs, CurrentKeyMaster.fluidGet());
	myBeWork->unsponsor(clubs);
}
/* server grab status */


void FeWork::updateStatus (){
	/* The authority of my KeyMaster has changed and I need to 
	update my status */
	/* If I was grabbing and lost permission to edit, or 
	signature authority for the author,
			evict myself
		else if I was waiting for a grab and gained permission to do so
			and the Work is ungrabbed
				grab it */
	
	/* Known bug !!!! */
	
	/* Add mechanism to notify when signature Club of Author is changed */
	if (this->canRevise()) {
		{	BooleanVar crutch_Flag;
			/* myBeWork->canBeEditedBy(myKeyMaster) && myKeyMaster->hasSignatureAuthority(myAuthor) */
			
			crutch_Flag = myBeWork->canBeEditedBy(myKeyMaster);
			if(crutch_Flag) {
				crutch_Flag = myKeyMaster->hasSignatureAuthority(myAuthor);
			}
			if (!crutch_Flag) {
				this->release();
			}
		}
	} else {
		{	BooleanVar crutch_Flag;
			/* amWaiting && myKeyMaster != NULL && myBeWork->canBeEditedBy(myKeyMaster) && myKeyMaster->hasSignatureAuthority(myAuthor) */
			
			crutch_Flag = amWaiting;
			if(crutch_Flag) {
				crutch_Flag = myKeyMaster != NULL;
				if(crutch_Flag) {
					crutch_Flag = myBeWork->canBeEditedBy(myKeyMaster);
					if(crutch_Flag) {
						crutch_Flag = myKeyMaster->hasSignatureAuthority(myAuthor);
					}
				}
			}
			if (crutch_Flag) {
				if (myBeWork->tryLock(this)) {
					amWaiting = FALSE;
					if (myStatusDetectors != NULL) {
						BEGIN_FOR_EACH(FeStatusDetector,stat,(myStatusDetectors->stepper())) {
							/* Thing to do !!!! */
							
							/* reasons */
							stat->grabbed(this, myAuthor, IntegerVarZero);
						} END_FOR_EACH;
					}
				}
			}
		}
	}
}
/* server contents */


void FeWork::triggerRevisionDetectors (
		APTR(FeEdition) contents, 
		APTR(ID) author, 
		IntegerVar time, 
		IntegerVar sequence)
{
	/* Trigger all my immediate RevisionDetectors who can read the Work */
	
	BEGIN_FOR_EACH(Pair OF2(FeKeyMaster,FeRevisionDetector),pair,(myRevisionDetectors->stepper())) {
		if (myBeWork->canBeReadBy(CAST(FeKeyMaster,pair->left()))) {
			CAST(FeRevisionDetector,pair->right())->revised(this, contents, author, time, sequence);
		}
	} END_FOR_EACH;
}
/* server accessing */


RPTR(ID) OR(NULL) FeWork::fetchAuthor (){
	return (ID*) myAuthor;
}


RPTR(BeRangeElement) OR(NULL) FeWork::fetchBe (){
	return (BeWork*) myBeWork;
}


RPTR(ID) FeWork::getAuthor (){
	if (myAuthor == NULL) {
		BLAST(NoAuthor);
	}
	return (ID*) myAuthor;
}


RPTR(BeRangeElement) FeWork::getOrMakeBe (){
	return (BeWork*) myBeWork;
}
/* protected: create */


FeWork::FeWork (APTR(BeWork) be, TCSJ) {
	myBeWork = be;
	myKeyMaster = NULL;
	myAuthor = NULL;
	amWaiting = FALSE;
	myStatusDetectors = NULL;
	myRevisionDetectors = NULL;
	myKeyMaster = NULL;
}
/* destruct */


void FeWork::destruct (){
	myBeWork->removeFeRangeElement(this);
	myBeWork->tryUnlock(this);
	if (myKeyMaster != NULL) {
		myKeyMaster->unregisterWork(this);
	}
	this->FeRangeElement::destruct();
}
/* printing */


void FeWork::printOn (ostream& oo){
	oo << "Work(" << "ids: " << FeServer::iDsOf(this);
	if (this->canRead()) {
		oo << " contents: " << this->edition();
	}
	if (this->canRevise()) {
		oo << " (grabbed)";
	}
	oo << ")";
}
/* accessing */


RPTR(FeRangeElement) FeWork::again (){
	/* Thing to do !!!! */
	
	/* deal with work consolidation */
	return this;
}


BooleanVar FeWork::canMakeIdentical (APTR(FeRangeElement) newIdentity){
	if (!this->isIdentical(newIdentity)) {
		BLAST(NOT_YET_IMPLEMENTED);
	}
	return TRUE;
}


void FeWork::makeIdentical (APTR(FeRangeElement) newIdentity){
	/* deal with work consolidation */
	BLAST(NOT_YET_IMPLEMENTED);
}
/* history */


void FeWork::addRevisionDetector (APTR(FeRevisionDetector) detector){
	/* Essential. Trigger a Detector whenever there is a revision 
	to the Work which the CurrentKeyMaster can see. If this 
	detector has already been added, then the old KeyMaster 
	associated with it is replaced with the CurrentKeyMaster.
		See RevisionDetector::revised (Edition * contents,
			ID * author,
			IntegerVar sequence,
			IntegerVar time). */
	
	if (myRevisionDetectors == NULL) {
		myRevisionDetectors = PrimSet::weak(7, RevisionDetectorExecutor::make (this));
		myBeWork->addRevisionWatcher(this);
	} else {
		BEGIN_FOR_EACH(Pair,pair,(myRevisionDetectors->stepper())) {
			if (detector->isEqual(pair->right())) {
				myRevisionDetectors->remove(pair);
			}
		} END_FOR_EACH;
	}
	myRevisionDetectors->introduce(Pair::make (CurrentKeyMaster.fluidGet(), detector));
}


RPTR(ID) FeWork::lastRevisionAuthor (){
	/* The ID of the author of the last revision of this Work to 
	its current Edition, or its creation if it hasn't been 
	revised since. The Work must be grabbed, or the 
	CurrentKeyMaster must be able to exercise the authority of 
	the Read, Edit, or History Club. */
	
	if (!this->canReadHistory()) {
		BLAST(MustHaveReadPermission);
	}
	WPTR(ID) 	returnValue;
	returnValue = myBeWork->lastRevisionAuthor();
	return returnValue;
}


IntegerVar FeWork::lastRevisionNumber (){
	/* The sequence number of the last revision of this Work to 
	its current Edition, or its creation if it hasn't been 
	revised since. The Work must be grabbed, or the 
	CurrentKeyMaster must be able to exercise the authority of 
	the Read, Edit, or History Club. */
	
	if (!this->canReadHistory()) {
		BLAST(MustHaveReadPermission);
	}
	return myBeWork->lastRevisionNumber();
}


IntegerVar FeWork::lastRevisionTime (){
	/* The time of the last revision of this Work to its current 
	Edition, or its creation if it hasn't been revised since. The 
	Work must be grabbed, or the CurrentKeyMaster must be able to 
	exercise the authority of the Read, Edit, or History Club. */
	
	if (!this->canReadHistory()) {
		BLAST(MustHaveReadPermission);
	}
	return myBeWork->lastRevisionTime();
}


void FeWork::removeLastRevisionDetector (){
	/* Essential. Inform the work that its last revision detector 
	has gone away. */
	
	myRevisionDetectors = NULL;
	myBeWork->removeRevisionWatcher(this);
}


RPTR(FeRevisionDetector) FeWork::revisionDetector (){
	/* Essential. Return a detector tht will trigger whenever 
	there is a revision to the Work which the CurrentKeyMaster can see.
		See RevisionDetector::revised (Edition * contents,
			ID * author,
			IntegerVar sequence,
			IntegerVar time). */
	
	BLAST(NOT_YET_IMPLEMENTED);
	this->addRevisionDetector(NULL);
	/* fodder */
	return NULL;
}


RPTR(FeEdition) FeWork::revisions (){
	/* Return the revision trail of the receiver.  The trail will 
	be empty if no revisions have been recorded. The trail is 
	updated immediately when the Work is revised.
		In order to get the trail, either the Work must be grabbed, 
	or you must be a member of the Read, Edit, or History Clubs. */
	
	/* Known bug !!!! */
	
	/* This needs a label. */
	if (!this->canReadHistory()) {
		BLAST(MustHaveReadPermission);
	}
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(myBeWork->revisions());
	return returnValue;
}
/* private: */


BooleanVar FeWork::canReadHistory (){
	/* self canRead or CurrentKeyMaster has authority of the historyClub */
	
	SPTR(FeKeyMaster) ckm;
	
	ckm = CurrentKeyMaster.fluidFetch();
	{	BooleanVar crutch_Flag;
		/* this->canRead() || ckm != NULL && myBeWork->fetchHistoryClub() != NULL && ckm->hasAuthority(myBeWork->fetchHistoryClub()) */
		
		crutch_Flag = this->canRead();
		if(!crutch_Flag) {
			crutch_Flag = ckm != NULL;
			if(crutch_Flag) {
				crutch_Flag = myBeWork->fetchHistoryClub() != NULL;
				if(crutch_Flag) {
					crutch_Flag = ckm->hasAuthority(myBeWork->fetchHistoryClub());
				}
			}
		}
		return crutch_Flag;
	}
}



/* ************************************************************************ *
 * 
 *                    Class     FeClub 
 *
 * ************************************************************************ */


/* creation */


RPTR(FeClub) FeClub::make (APTR(FeEdition) status){
	/* Essential.  Create a new Club whose initial status is 
	described in the given ClubDescription Edition. The reader, 
	editor and owner are taken from the current settings. If the 
	KeyMaster has edit permission, then the Club Work is 
	initially grabbed by it. The Club Work is initially sponsored 
	by the CurrentSponsor.
		Note: Unlike ordinary Works, a newly created Club is 
	assigned a global ID. */
	
	FeKeyMaster::assertSponsorship();
	FeKeyMaster::assertSignatureAuthority();
	return CAST(FeClub,CurrentGrandMap.fluidGet()->newClub(status)->makeLockedFeWork());
}


RPTR(FeClub) FeClub::on (APTR(BeClub) be){
	SPTR(FeClub) result;
	
	CONSTRUCT(result,FeClub,(be, tcsj));
	be->addFeRangeElement(result);
	WPTR(FeClub) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* A persistent Club on the Server. */


/* signing */


void FeClub::removeSignatureClub (){
	/* Essential.  Irrevocably remove signature authority for 
	this Club. Requires ownership authority. */
	
	if (!CurrentKeyMaster.fluidGet()->hasAuthority(this->owner())) {
		BLAST(MustBeOwner);
	}
	this->beClub()->setSignatureClub(NULL);
}


void FeClub::setSignatureClub (APTR(ID) OR(NULL) club){
	/* Essential.  Change who has signature authority for this 
	Club. Requires ownership authority.
		 Aborts if the Work doesn't have a signature Club. */
	
	/* Known bug !!!! */
	
	/* need to updateStatus on Works which are designating me as Author */
	if (club == NULL) {
		BLAST(MustNotBeNull);
	}
	if (!CurrentKeyMaster.fluidGet()->hasAuthority(this->owner())) {
		BLAST(MustBeOwner);
	}
	if (this->beClub()->fetchSignatureClub() == NULL) {
		BLAST(SignatureClubIrrevocablyRemoved);
	}
	this->beClub()->setSignatureClub(club);
}


RPTR(ID) FeClub::signatureClub (){
	/* Essential. The Club which has 'signature authority' for 
	this Club. Members of this Club are allowed to endorse with 
	the ID of this Club, and are allowed to use it to sponsor 
	resources. BLASTs if it has been removed */
	
	SPTR(ID) result;
	
	result = this->beClub()->fetchSignatureClub();
	if (result == NULL) {
		BLAST(SignatureClubIrrevocablyRemoved);
	}
	WPTR(ID) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* server */


RPTR(BeClub) FeClub::beClub (){
	return CAST(BeClub,this->fetchBe());
}
/* managing storage */


RPTR(FeEdition) FeClub::sponsoredWorks (APTR(Filter) filter/* = NULL*/){
	/* Essential.  All of the Works sponsored by this Club. If a 
	Filter is given, then restricts the result to Works which 
	pass the filter. The result can be wrapped with a Set. This 
	does not require any permissions. */
	
	SPTR(IDSpace) iDSpace;
	SPTR(PtrArray) OF1(FeWork) array;
	Int32 index;
	
	
	array = PtrArray::nulls(this->beClub()->sponsored()->count().asLong());
	index = Int32Zero;
	BEGIN_FOR_EACH(BeWork,be,(this->beClub()->sponsored()->stepper())) {
		{	BooleanVar crutch_Flag;
			/* filter == NULL || filter->match(be->endorsements()) */
			
			crutch_Flag = filter == NULL;
			if(!crutch_Flag) {
				crutch_Flag = filter->match(be->endorsements());
			}
			if (crutch_Flag) {
				array->store(index, FeWork::on(be));
				index += 1;
			}
		}
	} END_FOR_EACH;
	iDSpace = IDSpace::unique();
	if (index < array->count()) {
		array = CAST(PtrArray,array->copy(index));
	}
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(
			CurrentGrandMap.fluidGet()->newValueEdition(array, iDSpace->newIDs(array->count()), iDSpace->getAscending()));
	return returnValue;
}
/* private: create */


FeClub::FeClub (APTR(BeClub) be, TCSJ) 
	: FeWork(be, tcsj) {
	
}



/* ************************************************************************ *
 * 
 *                    Class FeServer 
 *
 * ************************************************************************ */



/* Initializers for FeServer */

Recipe * FebeCuisine = NULL;	/* in FeServer */


BUILD_FLUID(FeServer,CurrentServer, NULL, ServerChunk::emulsion());	/* in FeServer */
BUILD_FLUID(FeKeyMaster,CurrentKeyMaster, NULL, ServerChunk::emulsion());	/* in FeServer */
BUILD_FLUID(ID,CurrentAuthor, NULL, ServerChunk::emulsion());	/* in FeServer */
BUILD_FLUID(ID,InitialReadClub, NULL, ServerChunk::emulsion());	/* in FeServer */
BUILD_FLUID(ID,InitialEditClub, NULL, ServerChunk::emulsion());	/* in FeServer */
BUILD_FLUID(ID,InitialOwner, NULL, ServerChunk::emulsion());	/* in FeServer */
BUILD_FLUID(ID,InitialSponsor, NULL, ServerChunk::emulsion());	/* in FeServer */


/* Initializers for FeServer */






/* server library */


RPTR(ID) FeServer::clubID (APTR(Sequence) clubName){
	/* Looks up the ID of a named Club in the directory 
	maintained by the System Admin Club. Requires read permission 
	on the directory. Blasts if there is no Club with that name. */
	
	WPTR(ID) 	returnValue;
	returnValue = FeServer::iDOf(CAST(FeWork,FeServer::get(FeServer::clubDirectoryID()))->edition()->get(clubName));
	return returnValue;
}


RPTR(Sequence) FeServer::clubName (APTR(ID) iD){
	/* Finds the name of a Club in the global directory 
	maintained by the System Admin Club. Blasts if there is no 
	name for that Club, or if there is more than one. Requires 
	read permission on the clubDirectory Work */
	
	SPTR(FeWork) club;
	
	club = CAST(FeClub,FeServer::get(iD));
	return CAST(Sequence,CAST(FeWork,FeServer::get(FeServer::clubDirectoryID()))->edition()->keysOf(club)->theOne());
}


RPTR(SequenceRegion) FeServer::clubNames (){
	/* The names of all global Clubs. Requires read permission on 
	the clubDirectory Work */
	
	return CAST(SequenceRegion,CAST(FeWork,FeServer::get(FeServer::clubDirectoryID()))->edition()->domain());
}


void FeServer::disableAccess (APTR(ID) clubID){
	/* Disable login access to a Club, by revoking its direct 
	membership of the System Access Club */
	
	SPTR(FeClub) club;
	SPTR(FeClubDescription) desc;
	
	/* Ravi -- Thing to do !!!! */
	
	/* kill outstanding KeyMasters */
	club = CAST(FeClub,FeServer::get(FeServer::accessClubID()));
	desc = CAST(FeClubDescription,FeClubDescription::spec()->wrap(club->edition()));
	club->grab();
	club->revise(desc->withMembership(desc->membership()->without(CAST(FeClub,FeServer::get(clubID))))->edition());
	club->release();
}


void FeServer::enableAccess (APTR(ID) clubID){
	/* Enable login access to a Club, by listing it as a direct 
	member of the System Access Club */
	
	SPTR(FeClub) club;
	SPTR(FeClubDescription) desc;
	
	club = CAST(FeClub,FeServer::get(FeServer::accessClubID()));
	desc = CAST(FeClubDescription,FeClubDescription::spec()->wrap(club->edition()));
	club->grab();
	club->revise(desc->withMembership(desc->membership()->with(CAST(FeClub,FeServer::get(clubID))))->edition());
	club->release();
}


RPTR(FilterSpace) FeServer::endorsementFilterSpace (){
	/* The CoordinateSpace used for filtering endorsements on 
	this Server. Equivalent to
			this->filterSpace (this->endorsementSpace ()) */
	
	/* Thing to do !!!! */
	
	/* This should go in CrossSpace */
	WPTR(FilterSpace) 	returnValue;
	returnValue = CurrentGrandMap.fluidGet()->endorsementFilterSpace();
	return returnValue;
}


RPTR(CrossRegion) OF2(IDRegion,IDRegion) FeServer::endorsementRegion (APTR(IDRegion) OR(NULL) clubs, APTR(IDRegion) OR(NULL) tokens){
	/* A set of endorsements for each Club endorsing with each token */
	
	/* Thing to do !!!! */
	
	/* This should go in CrossSpace */
	WPTR(CrossRegion) OF2(IDRegion,IDRegion) 	returnValue;
	returnValue = FeServer::endorsementSpace()->crossOfRegions(CAST(PtrArray,PrimSpec::pointer()->arrayWithTwo(clubs, tokens)));
	return returnValue;
}


RPTR(CrossSpace) OF2(IDSpace,IDSpace) FeServer::endorsementSpace (){
	/* A set of endorsements for each Club endorsing with each token */
	
	/* Thing to do !!!! */
	
	/* This should go in CrossSpace */
	WPTR(CrossSpace) OF2(IDSpace,IDSpace) 	returnValue;
	returnValue = CurrentGrandMap.fluidGet()->endorsementSpace();
	return returnValue;
}


RPTR(FeWork) FeServer::globalClubs (){
	/* The Work mapping names to global Club Works */
	
	return CAST(FeWork,FeServer::get(FeServer::clubDirectoryID()));
}


BooleanVar FeServer::isAdmitted (){
	/* Return true if the current session has successfully logged 
	into the Server yet. */
	
	/* Dean -- Thing to do !!!! */
	
	
	return TRUE;
}


void FeServer::nameClub (APTR(Sequence) clubName, APTR(ID) clubID){
	/* Add a Club to the global list of club names. Blasts if 
	there is already a Club by that name. */
	
	SPTR(FeWork) clubNames;
	SPTR(FeWork) club;
	
	clubNames = FeServer::globalClubs();
	clubNames->grab();
	{
		PLANT_BOMB(ReleaseWork,Boom);
		ARM_BOMB(Boom,(clubNames))
		{
			if (clubNames->edition()->includesKey(clubName)) {
				BLAST(ClubNameInUse);
			}
			club = CAST(FeClub,FeServer::get(clubID));
			if (!clubNames->edition()->keysOf(club)->isEmpty()) {
				BLAST(ClubAlreadyNamed);
			}
			clubNames->revise(clubNames->edition()->with(clubName, club));
		}
	}
}


void FeServer::renameClub (APTR(Sequence) oldName, APTR(Sequence) newName){
	/* Changes the name of an existing Club. Blasts if there is 
	no Club with the old name, or there already is a Club with 
	the new name. */
	
	SPTR(FeWork) names;
	
	names = FeServer::globalClubs();
	names->grab();
	{
		PLANT_BOMB(ReleaseWork,Boom);
		ARM_BOMB(Boom,(names))
		{
			if (!names->edition()->includesKey(oldName)) {
				BLAST(NoSuchClub);
			}
			if (names->edition()->includesKey(newName)) {
				BLAST(ClubNameInUse);
			}
			names->revise(names->edition()->without(oldName)->with(newName, names->edition()->get(oldName)));
		}
	}
}


void FeServer::unnameClub (APTR(Sequence) clubName){
	/* Removes a naming for a Club. Blasts if there is no Club by 
	that clubName. */
	
	SPTR(FeWork) clubNames;
	
	clubNames = FeServer::globalClubs();
	clubNames->grab();
	{
		PLANT_BOMB(ReleaseWork,Boom);
		ARM_BOMB(Boom,(clubNames))
		{
			if (clubNames->edition()->includesKey(clubName)) {
				BLAST(NoSuchClub);
			}
			clubNames->revise(clubNames->edition()->without(clubName));
		}
	}
}
/* create */


RPTR(FeServer) FeServer::implicitReceiver (){
	/* Get the receiver for wire requests. */
	
	WPTR(FeServer) 	returnValue;
	returnValue = CurrentServer.fluidGet();
	return returnValue;
}


RPTR(FeServer) FeServer::make (){
	SPTR(Encrypter) encrypter;
	SPTR(FeServer) result;
	
	/* Ravi -- Thing to do !!!! */
	
	/* use a real Encrypter */
	/* Hack !!!! */
	
	/* to force wrappers to be initialized */
	FeWrapperSpec::get(Sequence::string("Wrapper"));
	encrypter = Encrypter::make (Sequence::string("NoEncrypter"));
	encrypter->randomizeKeys(UInt8Array::string("hello"));
	CONSTRUCT(result,FeServer,(Sequence::string("NoEncrypter"), encrypter));
	CurrentServer.fluidSet(result);
	WPTR(FeServer) 	returnValue;
	returnValue = CurrentServer.fluidGet();
	return returnValue;
}
/* managing clubs */


RPTR(ID) FeServer::accessClubID (){
	/* Essential.  The ID of the System Access Club. */
	
	WPTR(ID) 	returnValue;
	returnValue = CurrentGrandMap.fluidGet()->accessClubID();
	return returnValue;
}


RPTR(ID) FeServer::adminClubID (){
	/* Essential.  The ID of the System Admin Club. */
	
	WPTR(ID) 	returnValue;
	returnValue = CurrentGrandMap.fluidGet()->adminClubID();
	return returnValue;
}


RPTR(ID) FeServer::archiveClubID (){
	/* Essential.  The ID of the System Archive Club. */
	
	/* Known bug !!!! */
	
	/* logging into this Club does not actually give you full 
	read/edit authority */
	WPTR(ID) 	returnValue;
	returnValue = CurrentGrandMap.fluidGet()->archiveClubID();
	return returnValue;
}


RPTR(ID) FeServer::emptyClubID (){
	/* Essential.  The ID of the Universal Empty Club. */
	
	WPTR(ID) 	returnValue;
	returnValue = CurrentGrandMap.fluidGet()->emptyClubID();
	return returnValue;
}


RPTR(Sequence) FeServer::encrypterName (){
	/* Essential. The encryption scheme to be used for sending 
	sensitive parameters to the Server. (e.g. 
	MatchLock::encryptedPassword ()) */
	
	WPTR(Sequence) 	returnValue;
	returnValue = CurrentServer.fluidGet()->getEncrypterName();
	return returnValue;
}


RPTR(Lock) FeServer::login (APTR(ID) clubID){
	/* Essential.  Return a lock which, if satisfied, will give a 
	KeyMaster logged in to that Club. It will be able to exercise 
	the authority of all of its superClubs.
		 The club must be in the System Access Club or another club 
	must have been logged in during this session.
		 If that doesn't hold, or there is no such club, returns the 
	gateLockSpec chosen by the Administrator if there is no such Club */
	
	SPTR(BeClub) club;
	SPTR(BeGrandMap) cgm;
	
	/* Ravi -- Thing to do !!!! */
	
	/* Check this please. */
	cgm = CurrentGrandMap.fluidGet();
	club = cgm->fetchClub(clubID);
	{	BooleanVar crutch_Flag;
		/* club != NULL && (FeSession::current()->isLoggedIn() || cgm->getClub(FeServer::accessClubID())->membershipIncludes(club)) */
		
		crutch_Flag = club != NULL;
		if(crutch_Flag) {
			crutch_Flag = FeSession::current()->isLoggedIn();
			if(!crutch_Flag) {
				crutch_Flag = cgm->getClub(FeServer::accessClubID())->membershipIncludes(club);
			}
		}
		if (crutch_Flag) {
			WPTR(Lock) 	returnValue;
			returnValue = CAST(FeClubDescription,FeClubDescription::spec()->wrap(club->edition()))->lockSmith()->newLock(clubID);
			return returnValue;
		} else {
			WPTR(Lock) 	returnValue;
			returnValue = FeServer::gateLockSmith()->newLock(NULL);
			return returnValue;
		}
	}
}


RPTR(Lock) FeServer::loginByName (APTR(Sequence) clubName){
	/* Essential.  Return a lock which, if satisfied, will give a 
	KeyMaster logged in to the named Club. It will be able to 
	exercise the authority of all of its superClubs.
			 The club must be in the System Access Club or another club 
	must have been logged in during this session.
		 If that doesn't hold, or there is no such club, returns the 
	gateLockSpec chosen by the Administrator if there is no such Club */
	
	SPTR(BeClub) club;
	SPTR(BeGrandMap) cgm;
	
	/* Ravi -- Thing to do !!!! */
	
	/* Check this please. */
	cgm = CurrentGrandMap.fluidGet();
	BEGIN_CHOOSE(CAST(BeWork,cgm->get(cgm->clubDirectoryID()))->edition()->fetch(clubName)) {
		BEGIN_KIND(FeClub,feclub) {
			club = feclub->beClub();
		} END_KIND;
		BEGIN_OTHERS {
			club = NULL;
		} END_OTHERS;
	} END_CHOOSE;
	{	BooleanVar crutch_Flag;
		/* club != NULL && (FeSession::current()->isLoggedIn() || cgm->getClub(FeServer::accessClubID())->membershipIncludes(club)) */
		
		crutch_Flag = club != NULL;
		if(crutch_Flag) {
			crutch_Flag = FeSession::current()->isLoggedIn();
			if(!crutch_Flag) {
				crutch_Flag = cgm->getClub(FeServer::accessClubID())->membershipIncludes(club);
			}
		}
		if (crutch_Flag) {
			WPTR(Lock) 	returnValue;
			returnValue = CAST(FeClubDescription,FeClubDescription::spec()->wrap(club->edition()))->lockSmith()->newLock(cgm->iDOf(club));
			return returnValue;
		} else {
			WPTR(Lock) 	returnValue;
			returnValue = FeServer::gateLockSmith()->newLock(NULL);
			return returnValue;
		}
	}
}


RPTR(ID) FeServer::publicClubID (){
	/* Essential.  The ID of the Universal Public Club. */
	
	WPTR(ID) 	returnValue;
	returnValue = CurrentGrandMap.fluidGet()->publicClubID();
	return returnValue;
}


RPTR(UInt8Array) FeServer::publicKey (){
	/* Essential. The public key to be used for sending sensitive 
	parameters to the Server. (e.g. MatchLock::encryptedPassword ()) */
	
	WPTR(UInt8Array) 	returnValue;
	returnValue = CurrentServer.fluidGet()->encrypter()->publicKey();
	return returnValue;
}
/* comm requests */


NOACK FeServer::force (){
	/* Flush the Server's output buffers. */
	
	BLAST(NOT_YET_IMPLEMENTED);
}


NOACK FeServer::setCurrentAuthor (APTR(ID) iD){
	/* Set the Server side fluid for the CurrentAuthor. */
	
	CurrentAuthor.fluidSet(iD);
}


NOACK FeServer::setCurrentKeyMaster (APTR(FeKeyMaster) km){
	/* Set the Server side fluid for the CurrentKeyMaster. */
	
	CurrentKeyMaster.fluidSet(km);
}


NOACK FeServer::setInitialEditClub (APTR(ID) iD){
	/* Set the Server side fluid for the InitialEditClub. */
	
	InitialEditClub.fluidSet(iD);
}


NOACK FeServer::setInitialOwner (APTR(ID) iD){
	/* Set the Server side fluid for the InitialOwner. */
	
	InitialOwner.fluidSet(iD);
}


NOACK FeServer::setInitialReadClub (APTR(ID) iD){
	/* Set the Server side fluid for the InitialReadClub. */
	
	InitialReadClub.fluidSet(iD);
}


NOACK FeServer::setInitialSponsor (APTR(ID) iD){
	/* Set the Server side fluid for the InitialSponsor. */
	
	InitialSponsor.fluidSet(iD);
}
/* global ids */


RPTR(ID) FeServer::assignID (APTR(FeRangeElement) range, APTR(ID) iD/* = NULL*/){
	/* Essential.  Assign a new global ID to a RangeElement. If 
	NULL, then a new unique ID is generated for it, and this 
	requires no permissions. If an ID is supplied, the 
	CurrentKeyMaster must have been granted authority to assign 
	this ID by the Adminer. Returns the newly assigned ID. */
	
	SPTR(BeGrandMap) gm;
	
	gm = CurrentGrandMap.fluidGet();
	if (iD == NULL) {
		WPTR(ID) 	returnValue;
		returnValue = gm->assignID(range->getOrMakeBe());
		return returnValue;
	}
	if (!CurrentKeyMaster.fluidGet()->hasAuthority(gm->grantAt(iD))) {
		BLAST(MustHaveBeenGrantedAuthority);
	}
	if (!gm->tryIntroduce(iD, range->getOrMakeBe())) {
		BLAST(IDAlreadyAssigned);
	}
	WPTR(ID) 	returnValue;
	returnValue = iD;
	return returnValue;
}


RPTR(ID) FeServer::clubDirectoryID (){
	/* The ID of a Work mapping Club names to FeClubs */
	
	WPTR(ID) 	returnValue;
	returnValue = CurrentGrandMap.fluidGet()->clubDirectoryID();
	return returnValue;
}


RPTR(FeRangeElement) FeServer::get (APTR(ID) iD){
	/* Essential.  Get the object associated with the given 
	global ID. Typically, it will be a Work. Blast if there is 
	nothing there */
	
	WPTR(FeRangeElement) 	returnValue;
	returnValue = CurrentGrandMap.fluidGet()->getFe(iD);
	return returnValue;
}


RPTR(ID) FeServer::iDOf (APTR(FeRangeElement) value){
	/* Find the unique global ID on this Server that has been 
	assigned to this RangeElement. Blast if there is none, or 
	more than one.
		Equivalent to
			CAST(ID, this->iDsOf (value)->theOne ()) */
	
	SPTR(BeRangeElement) be;
	
	be = value->fetchBe();
	if (be == NULL) {
		BLAST(DoesNotHaveAnID);
		return NULL;
	} else {
		WPTR(ID) 	returnValue;
		returnValue = CurrentGrandMap.fluidGet()->iDOf(be);
		return returnValue;
	}
}


RPTR(IDRegion) FeServer::iDsOf (APTR(FeRangeElement) value){
	/* Essential.  Find all the global IDs on this Server that 
	have been assigned to this RangeElement */
	
	SPTR(BeRangeElement) be;
	
	be = value->fetchBe();
	if (be == NULL) {
		return CAST(IDRegion,IDSpace::global()->emptyRegion());
	} else {
		WPTR(IDRegion) 	returnValue;
		returnValue = CurrentGrandMap.fluidGet()->iDsOf(be);
		return returnValue;
	}
}


RPTR(IDRegion) FeServer::iDsOfRange (APTR(FeEdition) edition){
	/* Find all the global IDs on this Server that have been 
	assigned to any of the RangeElements in an Edition */
	
	SPTR(XnRegion) result;
	
	/* Thing to do !!!! */
	
	/* fix this grossly inefficient algorithm so that at least it 
		doesn't check every single virtual object in the range */
	if (!edition->isFinite()) {
		BLAST(MustBeFinite);
	}
	result = IDSpace::global()->emptyRegion();
	BEGIN_FOR_EACH(FeRangeElement,value,(edition->stepper())) {
		SPTR(BeRangeElement) be;
		
		be = value->fetchBe();
		if (be != NULL) {
			result = result->unionWith(CurrentGrandMap.fluidGet()->iDsOf(be));
		}
	} END_FOR_EACH;
	return CAST(IDRegion,result);
}
/* accessing */


IntegerVar FeServer::currentTime (){
	/* The current clock time on the Server, in seconds since the 
	'beginning of time' */
	
	return ::xuTime();
}


RPTR(FeLockSmith) FeServer::gateLockSmith (){
	/* The LockSmith which hands out locks when a client tries to 
	login through the GateKeeper with an invalid Club ID or name. */
	
	return CAST(FeLockSmith,FeLockSmith::spec()->wrap(CurrentGrandMap.fluidGet()->gateLockSmithEdition()));
}


RPTR(Sequence) FeServer::identifier (){
	/* Essential. A sequence of numbers uniquely identifying this Server */
	
	WPTR(Sequence) 	returnValue;
	returnValue = CurrentGrandMap.fluidGet()->identifier();
	return returnValue;
}


void FeServer::removeWaitDetector (APTR(FeWaitDetector) detector){
	/* This is currently a no-op. */
	
	
}


RPTR(FeWaitDetector) FeServer::waitForConsequences (){
	/* Essential.  The Detector will be triggered when the 
	consequences of all previous local requests have finished 
	propagating through this Server. (e.g. Edition::transclusions 
	may take a while to collect all of the results.)
		If you want to remove the Detector before it is triggered, destroy it.
		Note that this is NOT a request to speed up the completion 
	of the outstanding requests.
		See WaitDetector::done () */
	
	BLAST(NOT_YET_IMPLEMENTED);
	FeServer::waitForConsequences(NULL);
	/* fodder */
	return NULL;
}


void FeServer::waitForConsequences (APTR(FeWaitDetector) detector){
	/* Essential.  The Detector will be triggered when the 
	consequences of all previous local requests have finished 
	propagating through this Server. (e.g. Edition::transclusions 
	may take a while to collect all of the results.)
		If you want to remove the Detector before it is triggered, destroy it.
		Note that this is NOT a request to speed up the completion 
	of the outstanding requests.
		See WaitDetector::done () */
	
	BLAST(NOT_YET_IMPLEMENTED);
}


RPTR(FeWaitDetector) FeServer::waitForWrite (){
	/* Essential.  The Detector will be triggered when the 
	current state of the Server has been reliably written to disk.
		If you want to remove the Detector before it is triggered, destroy it.
		See WaitDetector::done () */
	
	BLAST(NOT_YET_IMPLEMENTED);
	FeServer::waitForWrite(NULL);
	/* fodder */
	return NULL;
}


void FeServer::waitForWrite (APTR(FeWaitDetector) detector){
	/* Essential.  The Detector will be triggered when the 
	current state of the Server has been reliably written to disk.
		If you want to remove the Detector before it is triggered, destroy it.
		See WaitDetector::done () */
	
	
	CurrentPacker.fluidGet()->purge();
	detector->done();
}
/* The fundamental Server object. Used for managing the global name 
space, creating Works, Editions, and Clubs, and other general server 
management operations.

Many operations in the protocol use fluidly bound parameters. The 
possible parameters are:
	FeServer defineClientFluid: #CurrentServer with: Listener emulsion 
with: [NULL].

CurrentKeyMaster - a KeyMaster for providing authority to read and/or edit
CurrentAuthor - the ID of the Club under whose name Work revisions 
are being done; requires signature authority
InitialReadClub - the ID of the initial read Club of all newly 
created Works and Clubs
InitialEditClub - the ID of the initial edit Club of all newly 
created Works and Clubs
InitialOwner - the ID of the Club which owns newly created RangeElements
InitialSponsor - the ID of the Club which sponsors newly created 
Works and Clubs; requires signature authority */


/* miscellaneous */


RPTR(PrimPointerSpec) FeServer::pointerSpec (){
	/* Essential. A specification for arrays of pointers. */
	
	WPTR(PrimPointerSpec) 	returnValue;
	returnValue = PrimSpec::pointer();
	return returnValue;
}
/* create */


FeServer::FeServer (APTR(Sequence) encrypterName, APTR(Encrypter) encrypter) {
	myEncrypterName = encrypterName;
	myEncrypter = encrypter;
}
/* security */


RPTR(Encrypter) FeServer::encrypter (){
	/* Return the Encrypter used for sending sensitive parameters 
	to the Server. (e.g. MatchLock::encryptedPassword ()) */
	
	return (Encrypter*) myEncrypter;
}


RPTR(Sequence) FeServer::getEncrypterName (){
	/* Essential. The encryption scheme to be used for sending 
	sensitive parameters to the Server. (e.g. 
	MatchLock::encryptedPassword ()) */
	
	return (Sequence*) myEncrypterName;
}



/* ************************************************************************ *
 * 
 *                    Class EditionStepper 
 *
 * ************************************************************************ */


/* create */


RPTR(Stepper) EditionStepper::copy (){
	RETURN_CONSTRUCT(EditionStepper,(myKeys->copy(), myEdition));
}


EditionStepper::EditionStepper (APTR(Stepper) OF1(Position) keys, APTR(FeEdition) edition) {
	myKeys = keys;
	myEdition = edition;
}
/* special */


RPTR(Position) EditionStepper::position (){
	return CAST(Position,myKeys->get());
}
/* operations */


WPTR(Heaper) EditionStepper::fetch (){
	if (myKeys->hasValue()) {
		WPTR(Heaper) 	returnValue;
		returnValue = myEdition->get(CAST(Position,myKeys->fetch()));
		return returnValue;
	} else {
		return NULL;
	}
}


BooleanVar EditionStepper::hasValue (){
	return myKeys->hasValue();
}


void EditionStepper::step (){
	myKeys->step();
}



/* ************************************************************************ *
 * 
 *                    Class FeActualDataHolder 
 *
 * ************************************************************************ */


/* Actually has a persistent individual DataHolder on the Server */


/* client accessing */


RPTR(FeRangeElement) FeActualDataHolder::again (){
	/* I'm completely reified.  Just return me. */
	
	return this;
}


RPTR(PrimValue) FeActualDataHolder::value (){
	/* The actual data value */
	
	WPTR(PrimValue) 	returnValue;
	returnValue = myBeDataHolder->value();
	return returnValue;
}
/* server accessing */


RPTR(BeRangeElement) OR(NULL) FeActualDataHolder::fetchBe (){
	return (BeDataHolder*) myBeDataHolder;
}


RPTR(BeRangeElement) FeActualDataHolder::getOrMakeBe (){
	return (BeDataHolder*) myBeDataHolder;
}
/* private: create */


FeActualDataHolder::FeActualDataHolder (APTR(BeDataHolder) be, TCSJ) {
	myBeDataHolder = be;
}
/* destruct */


void FeActualDataHolder::destruct (){
	myBeDataHolder->removeFeRangeElement(this);
	this->FeDataHolder::destruct();
}



/* ************************************************************************ *
 * 
 *                    Class FeActualPlaceHolder 
 *
 * ************************************************************************ */


/* Actually has a persistent individual PlaceHolder on the Server, or 
used to, and now has a pointer to the rangeElement it became. */


/* client accessing */


RPTR(FeRangeElement) FeActualPlaceHolder::again (){
	BLAST(NOT_YET_IMPLEMENTED);
	/* This must hold onto an FeRangeElement so that the label is 
		properly maintained. */
	BEGIN_CHOOSE(myRangeElement) {
		BEGIN_KIND(BePlaceHolder,pl) {
			/* No change. */
			return this;
		} END_KIND;
		BEGIN_OTHERS {
			WPTR(FeRangeElement) 	returnValue;
			returnValue = myRangeElement->makeFe(NULL);
			return returnValue;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return NULL;
}


BooleanVar FeActualPlaceHolder::canMakeIdentical (APTR(FeRangeElement) newIdentity){
	if (!this->isIdentical(newIdentity)) {
		BLAST(NOT_YET_IMPLEMENTED);
	}
	return TRUE;
}


void FeActualPlaceHolder::makeIdentical (APTR(FeRangeElement) newIdentity){
	/* Consolidate this PlaceHolder to the newIdentity.  Return 
	true if successful. */
	/* Check permissions
			and forward the operation after coercing the newIdentity
			 to a persistent RangeElement. */
	/* myRangeElement will tell me to forward to another RangeElement. */
	
	if (!CurrentKeyMaster.fluidGet()->hasAuthority(this->owner())) {
		BLAST(MustBeOwner);
	}
	myRangeElement->makeIdentical(newIdentity->getOrMakeBe());
}


RPTR(ID) FeActualPlaceHolder::owner (){
	/* MyBeRangeElement will know it. */
	
	WPTR(ID) 	returnValue;
	returnValue = myRangeElement->owner();
	return returnValue;
}


void FeActualPlaceHolder::removeFillDetector (APTR(FeFillDetector) detector){
	if (!::isDestructed(myRangeElement)) {
		BEGIN_CHOOSE(myRangeElement) {
			BEGIN_KIND(BePlaceHolder,p) {
				p->removeDetector(detector);
			} END_KIND;
			BEGIN_OTHERS {
				
			} END_OTHERS;
		} END_CHOOSE;
	}
}
/* server accessing */


RPTR(BeRangeElement) OR(NULL) FeActualPlaceHolder::fetchBe (){
	return (BeRangeElement*) myRangeElement;
}


void FeActualPlaceHolder::forwardTo (APTR(BeRangeElement) element){
	/* myRangeElement has become something else.  Forward to the 
	new thing. */
	
	myRangeElement->removeFeRangeElement(this);
	myRangeElement = element;
	myRangeElement->addFeRangeElement(this);
}


RPTR(BeRangeElement) FeActualPlaceHolder::getOrMakeBe (){
	return (BeRangeElement*) myRangeElement;
}
/* private: create */


FeActualPlaceHolder::FeActualPlaceHolder (APTR(BeRangeElement) be, TCSJ) {
	myRangeElement = be;
}
/* destruct */


void FeActualPlaceHolder::destruct (){
	myRangeElement->removeFeRangeElement(this);
	this->FePlaceHolder::destruct();
}



/* ************************************************************************ *
 * 
 *                    Class FeVirtualDataHolder 
 *
 * ************************************************************************ */


/* Fakes a DataHolder by having an Edition and a key. */


/* accessing */


RPTR(FeRangeElement) FeVirtualDataHolder::again (){
	/* Fetch from my Edition again, just in case I've been consolidated. */
	
	WPTR(FeRangeElement) 	returnValue;
	returnValue = myEdition->fetch(myKey);
	return returnValue;
}


BooleanVar FeVirtualDataHolder::isIdentical (APTR(FeRangeElement) other){
	/* This can do a version comparison (which seems a bit extreme). */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return FALSE;
}


RPTR(ID) FeVirtualDataHolder::owner (){
	WPTR(ID) 	returnValue;
	returnValue = myEdition->ownerAt(myKey);
	return returnValue;
}


RPTR(PrimValue) FeVirtualDataHolder::value (){
	return (PrimValue*) myValue;
}
/* server accessing */


RPTR(BeRangeElement) OR(NULL) FeVirtualDataHolder::fetchBe (){
	return NULL;
}


RPTR(BeRangeElement) FeVirtualDataHolder::getOrMakeBe (){
	/* Force the ent to generate a beRangeElement at myKey. */
	
	WPTR(BeRangeElement) 	returnValue;
	returnValue = myEdition->getOrMakeBe(myKey);
	return returnValue;
}
/* private: create */


FeVirtualDataHolder::FeVirtualDataHolder (
		APTR(PrimValue) value, 
		APTR(Position) key, 
		APTR(BeEdition) edition) 
{
	myValue = value;
	myKey = key;
	myEdition = edition;
}



/* ************************************************************************ *
 * 
 *                    Class FeVirtualPlaceHolder 
 *
 * ************************************************************************ */


/* Fakes a PlaceHolder by having an Edition and a key. */


/* client accessing */


RPTR(FeRangeElement) FeVirtualPlaceHolder::again (){
	WPTR(FeRangeElement) 	returnValue;
	returnValue = myEdition->get(myKey);
	return returnValue;
}


BooleanVar FeVirtualPlaceHolder::canMakeIdentical (APTR(FeRangeElement) newIdentity){
	if (!this->isIdentical(newIdentity)) {
		BLAST(NOT_YET_IMPLEMENTED);
	}
	return TRUE;
}


void FeVirtualPlaceHolder::makeIdentical (APTR(FeRangeElement) newIdentity){
	/* Consolidate this PlaceHolder to the newIdentity.  Return 
	true if successful. */
	/* Check permissions
			and coerce both of us and have the BeRangeElements try. */
	
	/* Thing to do !!!! */
	
	/* This doesn't need to force newIdentity into a BeRangeElement. */
	if (!CurrentKeyMaster.fluidGet()->hasAuthority(this->owner())) {
		BLAST(MustBeOwner);
	}
	this->getOrMakeBe()->makeIdentical(newIdentity->getOrMakeBe());
}


RPTR(ID) FeVirtualPlaceHolder::owner (){
	WPTR(ID) 	returnValue;
	returnValue = myEdition->ownerAt(myKey);
	return returnValue;
}


void FeVirtualPlaceHolder::removeFillDetector (APTR(FeFillDetector) detector){
	BLAST(NotInSet);
}
/* server accessing */


RPTR(BeRangeElement) OR(NULL) FeVirtualPlaceHolder::fetchBe (){
	return NULL;
}


RPTR(BeRangeElement) FeVirtualPlaceHolder::getOrMakeBe (){
	/* Force the ent to generate a beRangeElement at myKey. */
	
	WPTR(BeRangeElement) 	returnValue;
	returnValue = myEdition->getOrMakeBe(myKey);
	return returnValue;
}
/* private: create */


FeVirtualPlaceHolder::FeVirtualPlaceHolder (APTR(BeEdition) edition, APTR(Position) key) {
	myEdition = edition;
	myKey = key;
}



/* ************************************************************************ *
 * 
 *                    Class RevisionDetectorExecutor 
 *
 * ************************************************************************ */


/* create */


RPTR(XnExecutor) RevisionDetectorExecutor::make (APTR(FeWork) work){
	RETURN_CONSTRUCT(RevisionDetectorExecutor,(work, tcsj));
}
/* This class informs its work when its last detector has gone away. */


/* protected: create */


RevisionDetectorExecutor::RevisionDetectorExecutor (APTR(FeWork) work, TCSJ) {
	myWork = work;
}
/* execute */


void RevisionDetectorExecutor::execute (Int32 arg){
	if (arg == Int32Zero) {
		myWork->removeLastRevisionDetector();
	}
}



/* ************************************************************************ *
 * 
 *                    Class StatusDetectorExecutor 
 *
 * ************************************************************************ */


/* create */


RPTR(XnExecutor) StatusDetectorExecutor::make (APTR(FeWork) work){
	RETURN_CONSTRUCT(StatusDetectorExecutor,(work, tcsj));
}
/* This class informs its work when its last status detector has gone away. */


/* executing */


void StatusDetectorExecutor::execute (Int32 arg){
	if (arg == Int32Zero) {
		myWork->removeLastStatusDetector();
	}
}
/* protected: create */


StatusDetectorExecutor::StatusDetectorExecutor (APTR(FeWork) work, TCSJ) {
	myWork = work;
}

#ifndef NKERNELX_SXX
#include "nkernelx.sxx"
#endif /* NKERNELX_SXX */


#ifndef NKERNELP_SXX
#include "nkernelp.sxx"
#endif /* NKERNELP_SXX */



#endif /* NKERNELX_CXX */

