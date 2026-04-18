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

#ifndef OROOTX_CXX
#define OROOTX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef OROOTX_HXX
#include "orootx.hxx"
#endif /* OROOTX_HXX */

#ifndef OROOTX_IXX
#include "orootx.ixx"
#endif /* OROOTX_IXX */

#ifndef OROOTP_HXX
#include "orootp.hxx"
#endif /* OROOTP_HXX */

#ifndef OROOTP_IXX
#include "orootp.ixx"
#endif /* OROOTP_IXX */


#ifndef BRANGE1X_HXX
#include "brange1x.hxx"
#endif /* BRANGE1X_HXX */

#ifndef BRANGE3X_HXX
#include "brange3x.hxx"
#endif /* BRANGE3X_HXX */

#ifndef DETECTX_HXX
#include "detectx.hxx"
#endif /* DETECTX_HXX */

#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef ENTX_HXX
#include "entx.hxx"
#endif /* ENTX_HXX */

#ifndef IDX_HXX
#include "idx.hxx"
#endif /* IDX_HXX */

#ifndef NKERNELX_HXX
#include "nkernelx.hxx"
#endif /* NKERNELX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef PRIMVALX_HXX
#include "primvalx.hxx"
#endif /* PRIMVALX_HXX */

#ifndef PROPSX_HXX
#include "propsx.hxx"
#endif /* PROPSX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */

#ifndef TABLESX_HXX
#include "tablesx.hxx"
#endif /* TABLESX_HXX */

#ifndef TCLUDEX_HXX
#include "tcludex.hxx"
#endif /* TCLUDEX_HXX */

#ifndef TURTLEX_HXX
#include "turtlex.hxx"
#endif /* TURTLEX_HXX */




/* ************************************************************************ *
 * 
 *                    Class OPart 
 *
 * ************************************************************************ */


/* backfollow */
/* accessing */


RPTR(Mapping) OPart::mappingTo (APTR(TracePosition) trace, APTR(Mapping) initial){
	/* return the mapping into the domain space of the given trace */
	
	WPTR(Mapping) 	returnValue;
	returnValue = this->hCrum()->mappingTo(trace, initial);
	return returnValue;
}


RPTR(SensorCrum) OPart::sensorCrum (){
	return (SensorCrum*) mySensorCrum;
}
/* protected: delete */


void OPart::dismantle (){
	BEGIN_INSISTENT(2) {
		if (::isConstructed(mySensorCrum)) {
			mySensorCrum->removePointer(this);
		}
		{	BooleanVar crutch_Flag;
			/* ::isConstructed(this->hCrum()) && ::isConstructed(this->hCrum()->bertCrum()) */
			
			crutch_Flag = ::isConstructed(this->hCrum());
			if(crutch_Flag) {
				crutch_Flag = ::isConstructed(this->hCrum()->bertCrum());
			}
			if (crutch_Flag) {
				this->hCrum()->bertCrum()->removePointer(this->hCrum());
			}
		}
		this->Abraham::dismantle();
	} END_INSISTENT;
}
/* protected: create */


OPart::OPart (APTR(SensorCrum) OR(NULL) scrum, TCSJ) {
	if (scrum == NULL) {
		mySensorCrum = SensorCrum::make ();
	} else {
		mySensorCrum = scrum;
	}
	mySensorCrum->addPointer(this);
}


OPart::OPart (UInt32 hash, APTR(SensorCrum) OR(NULL) scrum) 
	: Abraham(hash, tcsj) {
	if (scrum == NULL) {
		mySensorCrum = SensorCrum::make ();
	} else {
		mySensorCrum = scrum;
	}
	mySensorCrum->addPointer(this);
}
/* testing */


UInt32 OPart::contentsHash (){
	return this->Abraham::contentsHash() ^ mySensorCrum->hashForEqual();
}



/* ************************************************************************ *
 * 
 *                    Class   OrglRoot 
 *
 * ************************************************************************ */


/* creation */


RPTR(OrglRoot) OrglRoot::make (APTR(CoordinateSpace) cs){
	/* create a new orgl root */
	/* This should definitely be cached!  We make them all the 
	time probably. */
	
	/* Thing to do !!!! */
	
	BEGIN_CONSISTENT(4) {
		RETURN_CONSTRUCT(EmptyOrglRoot,(cs, tcsj));
	} END_CONSISTENT;
}


RPTR(OrglRoot) OrglRoot::make (APTR(XnRegion) region){
	if (region->isEmpty()) {
		WPTR(OrglRoot) 	returnValue;
		returnValue = OrglRoot::make (region->coordinateSpace());
		return returnValue;
	}
	WPTR(OrglRoot) 	returnValue;
	returnValue = ActualOrglRoot::make (Loaf::make (region), region);
	return returnValue;
}


RPTR(OrglRoot) OrglRoot::make (
		APTR(XnRegion) keys, 
		APTR(OrderSpec) ordering, 
		APTR(PtrArray) OF1(FeRangeElement) values)
{
	SPTR(Stepper) stepper;
	SPTR(OrglRoot) result;
	Int32 i;
	
	result = OrglRoot::make (ordering->coordinateSpace());
	/* Hack !!!! */
	
	/* This should make a balanced tree directly. */
	i = Int32Zero;
	stepper = keys->stepper(ordering);
	BEGIN_FOR_EACH(Position,key,(stepper)) {
		SPTR(BeCarrier) element;
		SPTR(XnRegion) region;
		
		BEGIN_CHOOSE(values->fetch(i)){
			BEGIN_KIND(FeRangeElement,fe){
				element = fe->carrier();
			} END_KIND;
			BEGIN_ISNULL {
				{
					BLAST(MustNotHaveNullElements);
				}
			}END_ISNULL
			
		} END_CHOOSE;
		region = key->asRegion();
		result = result->combine(ActualOrglRoot::make (Loaf::make (region, element), region));
		i += 1;
	} END_FOR_EACH;
	WPTR(OrglRoot) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(OrglRoot) OrglRoot::makeData (APTR(PrimDataArray) values, APTR(Arrangement) arrangement){
	/* Make an Orgl from a bunch of Data. The data is 
		guaranteed to be of a reasonable size. */
	
	WPTR(OrglRoot) 	returnValue;
	returnValue = ActualOrglRoot::make (Loaf::make (values, arrangement), arrangement->region());
	return returnValue;
}


RPTR(OrglRoot) OrglRoot::makeData (
		APTR(XnRegion) keys, 
		APTR(OrderSpec) ordering, 
		APTR(PrimDataArray) values)
{
	/* Make an Orgl from a bunch of Data. The data is 
		guaranteed to be of a reasonable size. */
	
	WPTR(OrglRoot) 	returnValue;
	returnValue = ActualOrglRoot::make (Loaf::make (values, ordering->arrange(keys)), keys);
	return returnValue;
}
/* backfollow */


RPTR(AgendaItem) OrglRoot::propChanger (APTR(PropChange) change){
	/* NOTE: The AgendaItem returned is not yet scheduled.  Doing 
	so is up to my caller. */
	
	WPTR(AgendaItem) 	returnValue;
	returnValue = myHCrum->propChanger(change);
	return returnValue;
}


BooleanVar OrglRoot::updateBCrumTo (APTR(BertCrum) newBCrum){
	/* Ensure the my bertCrum is not be leafward of newBCrum. */
	
	if (myHCrum->propagateBCrum(newBCrum)) {
		this->diskUpdate();
		return TRUE;
	}
	return FALSE;
}
/* accessing */


RPTR(HistoryCrum) OrglRoot::hCrum (){
	return (HBottomCrum*) myHCrum;
}


RPTR(TracePosition) OrglRoot::hCut (){
	/* This is primarily for the example routines. */
	
	WPTR(TracePosition) 	returnValue;
	returnValue = myHCrum->hCut();
	return returnValue;
}


void OrglRoot::introduceEdition (APTR(BeEdition) edition){
	myHCrum->introduceEdition(edition);
	this->remember();
	this->diskUpdate();
}


void OrglRoot::removeEdition (APTR(BeEdition) stamp){
	myHCrum->removeEdition(stamp);
	/* Now we get into the risky part of deletion.  Only Editions 
		can keep OrglRoots around, so destroy the receiver. */
	if (myHCrum->isEmpty()) {
		{this->destroy();}
	} else {
		this->diskUpdate();
	}
}
/* operations */
/* protected: */


void OrglRoot::dismantle (){
	BEGIN_CONSISTENT(3) {
		this->OPart::dismantle();
		myHCrum = NULL;
	} END_CONSISTENT;
}
/* create */


OrglRoot::OrglRoot (APTR(SensorCrum) OR(NULL) scrum, TCSJ) 
	: OPart(scrum, tcsj) {
	myHCrum = HBottomCrum::make ();
}
/* testing */


UInt32 OrglRoot::contentsHash (){
	return this->OPart::contentsHash() ^ myHCrum->hashForEqual();
}



/* ************************************************************************ *
 * 
 *                    Class     ActualOrglRoot 
 *
 * ************************************************************************ */


/* creation */


RPTR(ActualOrglRoot) ActualOrglRoot::make (APTR(Loaf) loaf, APTR(XnRegion) region){
	/* create a new orgl root */
	
	if ( region->isEmpty() ) {
		BLAST(Attempt_to_make_an_empty_ActualOrglRoot);
	}
	BEGIN_CONSISTENT(13) {
		RETURN_CONSTRUCT(ActualOrglRoot,(loaf, region));
	} END_CONSISTENT;
}
/* backfollow */


RPTR(XnRegion) ActualOrglRoot::attachTrailBlazer (APTR(TrailBlazer) blazer){
	WPTR(XnRegion) 	returnValue;
	returnValue = myO->attachTrailBlazer(blazer);
	return returnValue;
}


void ActualOrglRoot::checkRecorders (APTR(PropFinder) finder, APTR(SensorCrum) OR(NULL) scrum){
	myO->checkRecorders(finder, scrum);
}


void ActualOrglRoot::checkTrailBlazer (APTR(TrailBlazer) blazer){
	myO->checkTrailBlazer(blazer);
}


void ActualOrglRoot::delayedFindMatching (
		APTR(PropFinder) finder, 
		APTR(RecorderFossil) fossil, 
		APTR(ResultRecorder) recorder)
{
	SPTR(HashSetCache) OF1(HistoryCrum) hCrumCache;
	
	/* Cache for optimization: Frequently, in going northwards on 
	the h-tree, one will encounter an h-crum already encountered 
	during this very delayedFindMatching: operation.  In this 
	case, the cache helps us avoid *much* redundant work.  We can 
	get away with a bounded size cache because redundant work is 
	still correct. */
	hCrumCache = HashSetCache::make (100);
	/* Tell my O crum to do its flavor of the work.  It will tell 
		its children recursively. */
	myO->delayedStoreMatching(finder, fossil, recorder, hCrumCache);
	{hCrumCache->destroy();  hCrumCache = NULL /* don't want stale (S/CHK)PTRs */;}
}


RPTR(TrailBlazer) OR(NULL) ActualOrglRoot::fetchTrailBlazer (){
	WPTR(TrailBlazer) OR(NULL) 	returnValue;
	returnValue = myO->fetchTrailBlazer();
	return returnValue;
}


void ActualOrglRoot::storeRecordingAgents (APTR(RecorderFossil) recorder, APTR(Agenda) agenda){
	myO->storeRecordingAgents(recorder, agenda);
}


void ActualOrglRoot::triggerDetector (APTR(FeFillRangeDetector) detect){
	myO->triggerDetector(detect);
}


BooleanVar ActualOrglRoot::updateBCrumTo (APTR(BertCrum) newBCrum){
	/* My bertCrum must not be leafward of newBCrum. 
		Thus it must be LE to newCrum. Otherwise correct it and recur. */
	
	if (this->OrglRoot::updateBCrumTo(newBCrum)) {
		myO->updateBCrumTo(newBCrum);
		return TRUE;
	}
	return FALSE;
}
/* accessing */


RPTR(CoordinateSpace) ActualOrglRoot::coordinateSpace (){
	/* the kind of domain elements allowed */
	
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = myRegion->coordinateSpace();
	return returnValue;
}


IntegerVar ActualOrglRoot::count (){
	return myO->count();
}


RPTR(XnRegion) ActualOrglRoot::domain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myO->domain();
	return returnValue;
}


RPTR(FeRangeElement) OR(NULL) ActualOrglRoot::fetch (APTR(Position) key, APTR(BeEdition) edition){
	/* get an individual element */
	
	WPTR(FeRangeElement) OR(NULL) 	returnValue;
	returnValue = myO->fetch(key, edition, key);
	return returnValue;
}


RPTR(Loaf) ActualOrglRoot::fullcrum (){
	return (Loaf*) myO;
}


RPTR(BeRangeElement) ActualOrglRoot::getBe (APTR(Position) key){
	/* Get or Make the BeRangeElement at the location. */
	/* Separate the position from the rest of the oplane with 
	copy.  Then instantiate it. */
	
	{	FLUID_BIND(CurrentTrace,this->hCrum()->hCut()) {
			{	FLUID_BIND(CurrentBertCrum,this->hCrum()->bertCrum()) {
					WPTR(BeRangeElement) 	returnValue;
					returnValue = CAST(ActualOrglRoot,this->copy(key->asRegion()))->fullcrum()->getBe(key);
					return returnValue;
				}
			}
		}
	}
}


BooleanVar ActualOrglRoot::isEmpty (){
	/* ActualOrglRoots believe they have stuff beneath them. */
	
	return FALSE;
}


RPTR(XnRegion) ActualOrglRoot::keysLabelled (APTR(BeLabel) label){
	/* Just search for now. */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = myO->keysLabelled(label);
	return returnValue;
}


RPTR(Mapping) ActualOrglRoot::mapSharedTo (APTR(TracePosition) trace){
	/* return a mapping from my data to corresponding stuff in 
	the given trace */
	
	WPTR(Mapping) 	returnValue;
	returnValue = myO->compare(trace, myRegion);
	return returnValue;
}


RPTR(ID) ActualOrglRoot::ownerAt (APTR(Position) key){
	/* Return the owner for the given position in the receiver. */
	
	SPTR(OExpandingLoaf) loaf;
	
	loaf = myO->fetchBottomAt(key);
	if (loaf == NULL) {
		BLAST(NotInTable);
	}
	WPTR(ID) 	returnValue;
	returnValue = loaf->owner();
	return returnValue;
}


RPTR(XnRegion) ActualOrglRoot::rangeOwners (APTR(XnRegion) OR(NULL) positions){
	WPTR(XnRegion) 	returnValue;
	returnValue = myO->rangeOwners(positions);
	return returnValue;
}


RPTR(OrglRoot) ActualOrglRoot::setAllOwners (APTR(ID) owner){
	/* Recur assigning owners.  Return the portion of the receiver that
		 couldn't be assigned. */
	
	WPTR(OrglRoot) 	returnValue;
	returnValue = myO->setAllOwners(owner);
	return returnValue;
}


RPTR(XnRegion) ActualOrglRoot::sharedRegion (APTR(TracePosition) trace){
	/* Return a region for all the stuff in this orgl that can 
	backfollow to trace. */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = myO->sharedRegion(trace, myRegion);
	return returnValue;
}


RPTR(XnRegion) ActualOrglRoot::simpleDomain (){
	return (XnRegion*) myRegion;
}


RPTR(PrimSpec) ActualOrglRoot::specAt (APTR(Position) key){
	/* Return the owner for the given position in the receiver. */
	
	SPTR(OExpandingLoaf) loaf;
	
	loaf = myO->fetchBottomAt(key);
	if (loaf == NULL) {
		BLAST(NotInTable);
	}
	WPTR(PrimSpec) 	returnValue;
	returnValue = loaf->spec();
	return returnValue;
}


RPTR(Pair) OF1(OrglRoot) ActualOrglRoot::tryAllBecome (APTR(OrglRoot) other){
	/* Change the identities of the RangeElements of this Edition 
	to those at the same key in the other Edition. The left piece 
	of the result contains those object which are know to not be 
	able to become, because of
			- lack of ownership authority
			- different contents
			- incompatible types
			- no corresponding new identity
		The right piece of the result is NULL if there is nothing 
	more that might be done, or else the remainder of the 
	receiver on which we might be able to proceed. This material 
	might fail at a later time because of any of the reasons 
	above; or it might succeed , even though it failed this time because of
			- synchronization problem
			- just didn't feel like it
		This is always required to make progress if it can, although 
	it isn't required to make all the progress that it might. 
	Returns right=NULL when it can't make further progress. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}


RPTR(XnRegion) ActualOrglRoot::usedDomain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myO->usedDomain();
	return returnValue;
}
/* operations */


RPTR(Stepper) ActualOrglRoot::bundleStepper (APTR(XnRegion) region, APTR(OrderSpec) order){
	/* Return a stepper of bundles according to the order. */
	
	WPTR(Stepper) 	returnValue;
	returnValue = myO->bundleStepper(region, order, region->coordinateSpace()->identityDsp());
	return returnValue;
}


RPTR(OrglRoot) ActualOrglRoot::combine (APTR(OrglRoot) another){
	SPTR(ActualOrglRoot) him;
	SPTR(OrglRoot) result;
	
	if (another->isEmpty()) {
		return this;
	}
	him = CAST(ActualOrglRoot,another);
	result = this->fetchEasyCombine(him);
	if (result != NULL) {
		WPTR(OrglRoot) 	returnValue;
		returnValue = result;
		return returnValue;
	}
	result = him->fetchEasyCombine(this);
	if (result != NULL) {
		WPTR(OrglRoot) 	returnValue;
		returnValue = result;
		return returnValue;
	}
	/* both Ins are non-empty & both Outs are empty */
	WPTR(OrglRoot) 	returnValue;
	returnValue = myO->combine(him, myRegion, this->coordinateSpace()->identityDsp());
	return returnValue;
}


RPTR(OrglRoot) ActualOrglRoot::copy (APTR(XnRegion) region){
	/* Copy out each simple region and then combine them. */
	
	if (region->isSimple()) {
		WPTR(OrglRoot) 	returnValue;
		returnValue = this->copySimple(region);
		return returnValue;
	} else {
		SPTR(OrglRoot) result;
		
		result = OrglRoot::make (this->coordinateSpace());
		BEGIN_FOR_EACH(XnRegion,simple,(region->disjointSimpleRegions())) {
			result = result->combine(this->copySimple(simple));
		} END_FOR_EACH;
		WPTR(OrglRoot) 	returnValue;
		returnValue = result;
		return returnValue;
	}
}


RPTR(OrglRoot) ActualOrglRoot::copyDistinction (APTR(XnRegion) region){
	/* region must be a valid thing to store as a split. */
	
	UInt8 cnt;
	
	cnt = this->splay(region);
	if (Int0 == cnt) {
		WPTR(OrglRoot) 	returnValue;
		returnValue = OrglRoot::make (this->coordinateSpace());
		return returnValue;
	} else {
		if (2 == cnt) {
			return this;
		} else {
			WPTR(OrglRoot) 	returnValue;
			returnValue = ActualOrglRoot::make (CAST(InnerLoaf,myO)->inPart(), myRegion->intersect(region));
			return returnValue;
		}
	}
}


RPTR(OrglRoot) ActualOrglRoot::copySimple (APTR(XnRegion) simpleRegion){
	/* simpleRegion must be simple!  Copy out each distinction. */
	
	SPTR(OrglRoot) result;
	
	
	result = this;
	if ( ! (simpleRegion->isSimple()) ) {
		BLAST(This_must_be_a_simple_region_);
	}
	BEGIN_FOR_EACH(XnRegion,distinct,(simpleRegion->distinctions()->stepper())) {
		if (result->isEmpty()) {
			WPTR(OrglRoot) 	returnValue;
			returnValue = result;
			return returnValue;
		}
		result = CAST(ActualOrglRoot,result)->copyDistinction(distinct);
	} END_FOR_EACH;
	WPTR(OrglRoot) 	returnValue;
	returnValue = result;
	return returnValue;
}


void ActualOrglRoot::fill (
		APTR(XnRegion) keys, 
		APTR(Arrangement) toArrange, 
		APTR(PrimDataArray) toArray, 
		APTR(Dsp) dsp, 
		APTR(BeEdition) edition)
{
	myO->fill(keys, toArrange, toArray, dsp, edition);
}


RPTR(ActualOrglRoot) ActualOrglRoot::makeNew (
		APTR(XnRegion) newSplit, 
		APTR(ActualOrglRoot) newIn, 
		APTR(ActualOrglRoot) newOut)
{
	WPTR(ActualOrglRoot) 	returnValue;
	returnValue = ActualOrglRoot::make (
		InnerLoaf::make (newSplit, newIn->fullcrum(), newOut->fullcrum()), newIn->simpleDomain()->simpleUnion(newOut->simpleDomain()));
	return returnValue;
}


RPTR(OrglRoot) ActualOrglRoot::transformedBy (APTR(Dsp) externalDsp){
	/* Return a copy with externalDsp added to the receiver's dsp. */
	
	if (externalDsp->isIdentity()) {
		return this;
	}
	WPTR(OrglRoot) 	returnValue;
	returnValue = ActualOrglRoot::make (myO->transformedBy(externalDsp), externalDsp->ofAll(myRegion));
	return returnValue;
}


RPTR(OrglRoot) ActualOrglRoot::unTransformedBy (APTR(Dsp) externalDsp){
	/* Return a copy with externalDsp removed from the receiver's dsp. */
	
	if (externalDsp->isIdentity()) {
		return this;
	}
	WPTR(OrglRoot) 	returnValue;
	returnValue = ActualOrglRoot::make (myO->unTransformedBy(externalDsp), externalDsp->inverseOfAll(myRegion));
	return returnValue;
}
/* create */


ActualOrglRoot::ActualOrglRoot (APTR(Loaf) fullcrum, APTR(XnRegion) region) 
	: OrglRoot(fullcrum->sensorCrum(), tcsj) {
	myO = fullcrum;
	myRegion = region;
	myO->addOParent(this);
	this->newShepherd();
}
/* printing */


void ActualOrglRoot::printOn (ostream& aStream){
	aStream << this->getCategory()->name() << "(" << myRegion << ", " << myO << ")";
}
/* private: */


RPTR(ActualOrglRoot) OR(NULL) ActualOrglRoot::fetchEasyCombine (APTR(ActualOrglRoot) another){
	BEGIN_FOR_EACH(XnRegion,bound,(another->simpleDomain()->distinctions()->stepper())) {
		SPTR(OrglRoot) myIn;
		SPTR(OrglRoot) myOut;
		
		myIn = this->copy(bound);
		myOut = this->copy(bound->complement());
		if (myIn->isEmpty()) {
			WPTR(ActualOrglRoot) OR(NULL) 	returnValue;
			returnValue = this->makeNew(bound, another, CAST(ActualOrglRoot,myOut));
			return returnValue;
		}
		if (!myOut->isEmpty()) {
			WPTR(ActualOrglRoot) OR(NULL) 	returnValue;
			returnValue = this->makeNew(bound, CAST(ActualOrglRoot,another->combine(myIn)), CAST(ActualOrglRoot,myOut));
			return returnValue;
		}
	} END_FOR_EACH;
	return NULL;
}


UInt8 ActualOrglRoot::splay (APTR(XnRegion) region){
	/* Splay a region into its own subtree as close as possible 
	to the root */
	
	return myO->splay(region, myRegion);
}
/* protected: delete */


void ActualOrglRoot::dismantle (){
	BEGIN_CONSISTENT(4) {
		if (::isConstructed(myO)) {
			myO->removeOParent(this);
		}
		this->OrglRoot::dismantle();
	} END_CONSISTENT;
}
/* testing */


UInt32 ActualOrglRoot::contentsHash (){
	return this->OrglRoot::contentsHash() ^ myO->hashForEqual() ^ myRegion->hashForEqual();
}



/* ************************************************************************ *
 * 
 *                    Class     EmptyOrglRoot 
 *
 * ************************************************************************ */


/* backfollow */


RPTR(XnRegion) EmptyOrglRoot::attachTrailBlazer (APTR(TrailBlazer) blazer){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->domain();
	return returnValue;
}


void EmptyOrglRoot::checkRecorders (APTR(PropFinder) finder, APTR(SensorCrum) OR(NULL) scrum){
	
}


void EmptyOrglRoot::checkTrailBlazer (APTR(TrailBlazer) /* blazer */){
	BLAST(EmptyTrail);
}


void EmptyOrglRoot::delayedFindMatching (
		APTR(PropFinder) finder, 
		APTR(RecorderFossil) fossil, 
		APTR(ResultRecorder) recorder)
{
	
}


RPTR(TrailBlazer) OR(NULL) EmptyOrglRoot::fetchTrailBlazer (){
	return NULL;
}


void EmptyOrglRoot::storeRecordingAgents (APTR(RecorderFossil) recorder, APTR(Agenda) agenda){
	
}


void EmptyOrglRoot::triggerDetector (APTR(FeFillRangeDetector) detect){
	
}
/* accessing */


RPTR(CoordinateSpace) EmptyOrglRoot::coordinateSpace (){
	/* the kind of domain elements allowed */
	
	return (CoordinateSpace*) myCS;
}


IntegerVar EmptyOrglRoot::count (){
	return IntegerVar0;
}


RPTR(XnRegion) EmptyOrglRoot::domain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myCS->emptyRegion();
	return returnValue;
}


RPTR(FeRangeElement) OR(NULL) EmptyOrglRoot::fetch (APTR(Position) key, APTR(BeEdition) edition){
	return NULL;
}


RPTR(BeRangeElement) EmptyOrglRoot::getBe (APTR(Position) key){
	/* Get or Make the BeRangeElement at the location. */
	
	BLAST(NotInTable);
	return NULL;
}


BooleanVar EmptyOrglRoot::isEmpty (){
	return TRUE;
}


RPTR(XnRegion) EmptyOrglRoot::keysLabelled (APTR(BeLabel) label){
	/* Just search for now. */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = myCS->emptyRegion();
	return returnValue;
}


RPTR(Mapping) EmptyOrglRoot::mapSharedTo (APTR(TracePosition) /* trace */){
	/* return a mapping from my data to corresponding stuff in 
	the given trace */
	
	WPTR(Mapping) 	returnValue;
	returnValue = this->coordinateSpace()->identityDsp();
	return returnValue;
}


RPTR(ID) EmptyOrglRoot::ownerAt (APTR(Position) key){
	/* Return the owner for the given position in the receiver. */
	
	BLAST(NotInTable);
	return NULL;
}


RPTR(XnRegion) EmptyOrglRoot::rangeOwners (APTR(XnRegion) OR(NULL) positions){
	WPTR(XnRegion) 	returnValue;
	returnValue = IDSpace::global()->emptyRegion();
	return returnValue;
}


RPTR(OrglRoot) EmptyOrglRoot::setAllOwners (APTR(ID) owner){
	/* There aren't any contents, so just return self. */
	
	return this;
}


RPTR(XnRegion) EmptyOrglRoot::sharedRegion (APTR(TracePosition) /* trace */){
	/* I have no contents, so I can't shared anything. */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = myCS->emptyRegion();
	return returnValue;
}


RPTR(XnRegion) EmptyOrglRoot::simpleDomain (){
	/* Return a simple region that encloses the domain of the receiver. */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = myCS->emptyRegion();
	return returnValue;
}


RPTR(PrimSpec) EmptyOrglRoot::specAt (APTR(Position) key){
	/* Return the owner for the given position in the receiver. */
	
	BLAST(NotInTable);
	/* fodder */
	return NULL;
}


RPTR(XnRegion) EmptyOrglRoot::usedDomain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myCS->emptyRegion();
	return returnValue;
}
/* operations */


RPTR(Stepper) EmptyOrglRoot::bundleStepper (APTR(XnRegion) region, APTR(OrderSpec) order){
	/* Return a stepper of bundles according to the order. */
	
	WPTR(Stepper) 	returnValue;
	returnValue = Stepper::emptyStepper();
	return returnValue;
}


RPTR(OrglRoot) EmptyOrglRoot::combine (APTR(OrglRoot) orgl){
	WPTR(OrglRoot) 	returnValue;
	returnValue = orgl;
	return returnValue;
}


RPTR(OrglRoot) EmptyOrglRoot::copy (APTR(XnRegion) /* externalRegion */){
	return this;
}


RPTR(OrglRoot) EmptyOrglRoot::transformedBy (APTR(Dsp) /* externalDsp */){
	/* Return a copy with externalDsp added to the receiver's dsp. */
	
	return this;
}


RPTR(OrglRoot) EmptyOrglRoot::unTransformedBy (APTR(Dsp) /* externalDsp */){
	/* Return a copy with externalDsp removed from the receiver's dsp. */
	
	return this;
}
/* create */


EmptyOrglRoot::EmptyOrglRoot (APTR(CoordinateSpace) cs, TCSJ) 
	: OrglRoot((SensorCrum * ) NULL, tcsj) {
	myCS = cs;
	this->newShepherd();
}
/* testing */


UInt32 EmptyOrglRoot::contentsHash (){
	return this->OrglRoot::contentsHash() ^ myCS->hashForEqual();
}



/* ************************************************************************ *
 * 
 *                    Class HBottomCrum 
 *
 * ************************************************************************ */


/* instance creation */


RPTR(HBottomCrum) HBottomCrum::make (){
	
	RETURN_CONSTRUCT(HBottomCrum,(CurrentTrace.fluidGet(), CurrentBertCrum.fluidGet()));
}
/* testing */


BooleanVar HBottomCrum::hasRefs (){
	/* Return true if there are stamps that
		 point at this orgl. */
	
	return !myEditions->isEmpty();
}


BooleanVar HBottomCrum::inTrace (APTR(TracePosition) trace){
	/* Return true if the receiver can backfollow to trace. */
	
	/* Hack !!!! */
	
	/* The following grotesque hack (myEdition isEmpty not) is so 
	that intermediate orglRoots generated by copy and combine are 
	not considered for version comparison.  The proper thing to 
	do is make those operations destroy their intermediate results. */
	{	BooleanVar crutch_Flag;
		/* (Heaper * ) myTrace == trace && !myEditions->isEmpty() */
		
		crutch_Flag = (Heaper * ) myTrace == trace;
		if(crutch_Flag) {
			crutch_Flag = !myEditions->isEmpty();
		}
		return crutch_Flag;
	}
}


BooleanVar HBottomCrum::isEmpty (){
	/* Return true if their are no upward pointers.  This is used
		 by OParts to determine if they can be forgotten. */
	
	return myEditions->isEmpty();
}


BooleanVar HBottomCrum::propagateBCrum (APTR(BertCrum) newBCrum){
	/* If bertCrum is leafward of newBCrum then change it and return true, 
		otherwise return false. */
	
	if (myBertCrum->isLE(newBCrum)) {
		return FALSE;
	} else {
		myBertCrum = newBCrum;
		return TRUE;
	}
}
/* accessing */


RPTR(TracePosition) HBottomCrum::hCut (){
	return (TracePosition*) myTrace;
}


RPTR(Mapping) HBottomCrum::mappingTo (APTR(TracePosition) trace, APTR(Mapping) initial){
	/* return the mapping into the domain space of the given trace */
	
	if (this->inTrace(trace)) {
		WPTR(Mapping) 	returnValue;
		returnValue = initial;
		return returnValue;
	} else {
		WPTR(Mapping) 	returnValue;
		returnValue = Mapping::make (initial->coordinateSpace(), initial->rangeSpace());
		return returnValue;
	}
}


RPTR(ImmuSet) OF1(OPart) HBottomCrum::oParents (){
	WPTR(ImmuSet) OF1(OPart) 	returnValue;
	returnValue = ImmuSet::make ();
	return returnValue;
}
/* filtering */


void HBottomCrum::actualDelayedStoreBackfollow (
		APTR(PropFinder) finder, 
		APTR(RecorderFossil) fossil, 
		APTR(ResultRecorder) recorder, 
		APTR(HashSetCache) OF1(HistoryCrum) hCrumCache)
{
	{	BooleanVar crutch_Flag;
		/* !myEditions->isEmpty() && finder->doesPass(myBertCrum) */
		
		crutch_Flag = !myEditions->isEmpty();
		if(crutch_Flag) {
			crutch_Flag = finder->doesPass(myBertCrum);
		}
		if (crutch_Flag) {
			BEGIN_FOR_EACH(BeEdition,edition,(myEditions->stepper())) {
				recorder->delayedStoreBackfollow(edition, finder, fossil, hCrumCache);
			} END_FOR_EACH;
		}
	}
}


BooleanVar HBottomCrum::anyPasses (APTR(PropFinder) finder){
	if (finder->doesPass(myBertCrum)) {
		BEGIN_FOR_EACH(BeEdition,edition,(myEditions->stepper())) {
			if (edition->anyPasses(finder)) {
				return TRUE;
			}
		} END_FOR_EACH;
	}
	return FALSE;
}


RPTR(BertCrum) HBottomCrum::bertCrum (){
	return (BertCrum*) myBertCrum;
}


void HBottomCrum::introduceEdition (APTR(BeEdition) edition){
	myEditions->introduce(edition);
	this->propChanger(PropChange::bertPropChange())->schedule();
}


RPTR(AgendaItem) HBottomCrum::propChanger (APTR(PropChange) change){
	/* NOTE: The AgendaItem returned is not yet scheduled.  Doing 
	so is up to my caller. */
	
	SPTR(Prop) newProp;
	
	newProp = BertProp::make ();
	BEGIN_FOR_EACH(BeEdition,edition,(myEditions->stepper())) {
		newProp = change->with(newProp, edition->prop());
	} END_FOR_EACH;
	WPTR(AgendaItem) 	returnValue;
	returnValue = myBertCrum->propChanger(change, newProp);
	return returnValue;
}


void HBottomCrum::removeEdition (APTR(BeEdition) edition){
	myEditions->remove(edition);
	this->propChanger(PropChange::bertPropChange())->schedule();
}


void HBottomCrum::ringDetectors (APTR(FeEdition) edition){
	if (this->bertCrum()->isSensorWaiting()) {
		BEGIN_FOR_EACH(BeEdition,ed,(myEditions->stepper())) {
			ed->ringDetectors(edition);
		} END_FOR_EACH;
	}
}
/* create */


HBottomCrum::HBottomCrum (APTR(TracePosition) trace, APTR(BertCrum) canopy) {
	myTrace = trace;
	myBertCrum = canopy;
	myBertCrum->addPointer(this);
	myEditions = MuSet::make ();
}
/* deferred accessing */


RPTR(XnRegion) HBottomCrum::fetchRegionIn (
		APTR(BeEdition) stamp, 
		APTR(TracePosition) hCut, 
		APTR(XnRegion) region)
{
	BLAST(NOT_YET_IMPLEMENTED);
	/* or else remove it again and get rid of polymorphs */
	/* fodder */
	return NULL;
}

#ifndef OROOTX_SXX
#include "orootx.sxx"
#endif /* OROOTX_SXX */


#ifndef OROOTP_SXX
#include "orootp.sxx"
#endif /* OROOTP_SXX */



#endif /* OROOTX_CXX */

