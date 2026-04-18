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

#ifndef LOAVESX_CXX
#define LOAVESX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef LOAVESX_HXX
#include "loavesx.hxx"
#endif /* LOAVESX_HXX */

#ifndef LOAVESX_IXX
#include "loavesx.ixx"
#endif /* LOAVESX_IXX */

#ifndef LOAVESR_HXX
#include "loavesr.hxx"
#endif /* LOAVESR_HXX */

#ifndef LOAVESR_IXX
#include "loavesr.ixx"
#endif /* LOAVESR_IXX */

#ifndef LOAVESP_HXX
#include "loavesp.hxx"
#endif /* LOAVESP_HXX */

#ifndef LOAVESP_IXX
#include "loavesp.ixx"
#endif /* LOAVESP_IXX */


#ifndef BRANGE3X_HXX
#include "brange3x.hxx"
#endif /* BRANGE3X_HXX */

#ifndef CANOPYX_HXX
#include "canopyx.hxx"
#endif /* CANOPYX_HXX */

#ifndef DETECTX_HXX
#include "detectx.hxx"
#endif /* DETECTX_HXX */

#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef ENTX_HXX
#include "entx.hxx"
#endif /* ENTX_HXX */

#ifndef FLKINFOX_HXX
#include "flkinfox.hxx"
#endif /* FLKINFOX_HXX */

#ifndef PRIMVALX_HXX
#include "primvalx.hxx"
#endif /* PRIMVALX_HXX */

#ifndef PROPSX_HXX
#include "propsx.hxx"
#endif /* PROPSX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef TABLESX_HXX
#include "tablesx.hxx"
#endif /* TABLESX_HXX */

#ifndef TRACEPX_HXX
#include "tracepx.hxx"
#endif /* TRACEPX_HXX */

#ifndef TURTLEX_HXX
#include "turtlex.hxx"
#endif /* TURTLEX_HXX */




/* ************************************************************************ *
 * 
 *                    Class Loaf 
 *
 * ************************************************************************ */


/* create */


RPTR(Loaf) Loaf::make (APTR(XnRegion) region, APTR(BeCarrier) element){
	BEGIN_CONSISTENT(7) {
		RETURN_CONSTRUCT(RegionLoaf,(region, element->fetchLabel(), element->rangeElement(), NULL));
	} END_CONSISTENT;
}


RPTR(Loaf) Loaf::make (APTR(XnRegion) region){
	BEGIN_CONSISTENT(3) {
		RETURN_CONSTRUCT(OPartialLoaf,(region, NULL, SensorCrum::partial()));
	} END_CONSISTENT;
}


RPTR(Loaf) Loaf::make (APTR(PrimDataArray) values, APTR(Arrangement) arrangement){
	BEGIN_CONSISTENT(4) {
		SPTR(SharedData) tmp;
		
		CONSTRUCT(tmp,SharedData,(values, arrangement));
		RETURN_CONSTRUCT(OVirtualLoaf,(arrangement->region(), tmp));
	} END_CONSISTENT;
}
/* accessing */
/* operations */


RPTR(Loaf) Loaf::transformedBy (APTR(Dsp) externalDsp){
	/* Return a copy with externalDsp added to the receiver's dsp. */
	
	if (externalDsp->isIdentity()) {
		return this;
	} else {
		WPTR(Loaf) 	returnValue;
		returnValue = InnerLoaf::make (this, externalDsp);
		return returnValue;
	}
}


RPTR(Loaf) Loaf::unTransformedBy (APTR(Dsp) globalDsp){
	/* Return a copy with globalDsp removed from the receiver's dsp. */
	
	if (globalDsp->isIdentity()) {
		return this;
	} else {
		WPTR(Loaf) 	returnValue;
		returnValue = InnerLoaf::make (this, CAST(Dsp,globalDsp->inverse()));
		return returnValue;
	}
}
/* splay */


UInt8 Loaf::splay (APTR(XnRegion) region, APTR(XnRegion) limitRegion){
	/* Make each child completely contained or completely outside 
		the region. Return the number of children completely in the region. 
		Full containment cases can be handled generically. */
	
	if (limitRegion->isSubsetOf(region)) {
		return 2;
	} else {
		if (limitRegion->intersects(region)) {
			return this->actualSplay(region, limitRegion);
		} else {
			return Int0;
		}
	}
}
/* protected: splay */
/* backfollow */


void Loaf::addOParent (APTR(OPart) oParent){
	/* This should probably take a bertCanopyCrum argument, as well. */
	/* add oParent to the set of upward pointers. */
	
	myHCrum->addOParent(oParent);
	this->remember();
	this->diskUpdate();
}


void Loaf::checkRecorders (APTR(PropFinder) finder, APTR(SensorCrum) OR(NULL) scrum){
	/* check any recorders that might be triggered by a change in 
	the edition.
		 Walk leafward on O-plane, filtered by sensor canopy, 
	ringing recorders.
		 
		 Not in a consistent block:  It spawns unbounded work.  */
	
	SPTR(PropFinder) newFinder;
	
	/* Shrink finder to just what may be on this branch of O-tree.
		 If there might be something on this branch
		 	Check the children using the simplified finder. */
	newFinder = this->sensorCrum()->checkRecorders(finder, scrum);
	if (!newFinder->isEmpty()) {
		this->checkChildRecorders(newFinder);
	}
}


RPTR(HistoryCrum) Loaf::hCrum (){
	return (HUpperCrum*) myHCrum;
}


void Loaf::removeOParent (APTR(OPart) oparent){
	/* remove oparent from the set of upward pointers. */
	
	myHCrum->removeOParent(oparent);
	/* Now we get into the risky part of deletion.  There are
					 no more upward pointers, so destroy the receiver. */
	if (myHCrum->isEmpty()) {
		{this->destroy();}
	} else {
		this->diskUpdate();
	}
}


BooleanVar Loaf::updateBCrumTo (APTR(BertCrum) newBCrum){
	/* Ensure the my bertCrum is not be leafward of newBCrum. */
	
	if (myHCrum->propagateBCrum(newBCrum)) {
		this->diskUpdate();
		return TRUE;
	}
	return FALSE;
}
/* protected: */


RPTR(FeEdition) Loaf::asFeEdition (){
	/* Make a FeEdition out of myself. Used for triggering Detectors */
	
	{	FLUID_BIND(CurrentTrace,this->hCrum()->hCut()) {
			{	FLUID_BIND(CurrentBertCrum,this->hCrum()->bertCrum()) {
					WPTR(FeEdition) 	returnValue;
					returnValue = FeEdition::on(BeEdition::make (ActualOrglRoot::make (this, this->domain())));
					return returnValue;
				}
			}
		}
	}
}


void Loaf::dismantle (){
	BEGIN_INSISTENT(2) {
		this->OPart::dismantle();
		myHCrum = NULL;
	} END_INSISTENT;
}
/* create */


Loaf::Loaf (APTR(HUpperCrum) OR(NULL) hcrum, APTR(SensorCrum) OR(NULL) scrum) 
	: OPart(scrum, tcsj) {
	if (hcrum == NULL) {
		myHCrum = HUpperCrum::make ();
	} else {
		myHCrum = hcrum;
	}
}


Loaf::Loaf (
		UInt32 hash, 
		APTR(HUpperCrum) OR(NULL) hcrum, 
		APTR(SensorCrum) OR(NULL) scrum) 

	: OPart(hash, scrum) {
	if (hcrum == NULL) {
		myHCrum = HUpperCrum::make ();
	} else {
		myHCrum = hcrum;
	}
}
/* testing */


UInt32 Loaf::contentsHash (){
	return this->OPart::contentsHash() ^ myHCrum->hashForEqual();
}



/* ************************************************************************ *
 * 
 *                    Class   InnerLoaf 
 *
 * ************************************************************************ */


/* create */


RPTR(InnerLoaf) InnerLoaf::make (APTR(Loaf) newO, APTR(Dsp) dsp){
	/* Make a loaf that transforms the contents of newO. */
	
	BEGIN_CONSISTENT(11) {
		RETURN_CONSTRUCT(DspLoaf,(newO, dsp));
	} END_CONSISTENT;
}


RPTR(InnerLoaf) InnerLoaf::make (
		APTR(XnRegion) newSplit, 
		APTR(Loaf) newIn, 
		APTR(Loaf) newOut)
{
	/* The contents of newIn must be completely contained in newSplit. 
		 newOut must be completely outside newSplit.  Should this just 
		 forward to make:with:with:with:?  This should extract shared dsp 
		 from newIn and newOut. */
	
	BEGIN_CONSISTENT(-1) {
		RETURN_CONSTRUCT(SplitLoaf,(newSplit, newIn, newOut));
	} END_CONSISTENT;
}


RPTR(InnerLoaf) InnerLoaf::make (
		APTR(XnRegion) newSplit, 
		APTR(Loaf) newIn, 
		APTR(Loaf) newOut, 
		APTR(HUpperCrum) hcrum)
{
	/* The contents of newIn must be completely contained in newSplit. 
		 newOut must be completely outside newSplit */
	
	BEGIN_CONSISTENT(6) {
		RETURN_CONSTRUCT(SplitLoaf,(newSplit, newIn, newOut, hcrum));
	} END_CONSISTENT;
}
/* create */


InnerLoaf::InnerLoaf (APTR(HUpperCrum) hcrum, APTR(SensorCrum) scrum) 
	: Loaf(hcrum, scrum) {
	
}


InnerLoaf::InnerLoaf (
		UInt32 hash, 
		APTR(HUpperCrum) hcrum, 
		APTR(SensorCrum) scrum) 

	: Loaf(hash
		, hcrum
		, scrum) 
{
	
}
/* protected: splay */
/* accessing */
/* backfollow */
/* operations */



/* ************************************************************************ *
 * 
 *                    Class   OExpandingLoaf 
 *
 * ************************************************************************ */


/*  NOT.A.TYPE */


/* operations */


RPTR(OrglRoot) OExpandingLoaf::combine (
		APTR(ActualOrglRoot) another, 
		APTR(XnRegion) /* limitRegion */, 
		APTR(Dsp) globalDsp)
{
	/* Accumulate dsp downward. */
	
	SPTR(XnRegion) myGlobalRegion;
	SPTR(ActualOrglRoot) result;
	SPTR(OrglRoot) him;
	
	myGlobalRegion = globalDsp->ofAll(myRegion);
	if (!another->copy(myGlobalRegion)->isEmpty()) {
		BLAST(IntersectingCombine);
	}
	result = ActualOrglRoot::make (this->transformedBy(globalDsp), myGlobalRegion);
	him = another;
	
	BEGIN_FOR_EACH(XnRegion,split,(myGlobalRegion->distinctions()->stepper())) {
		SPTR(OrglRoot) hisOut;
		
		hisOut = him->copy(split->complement());
		if (!hisOut->isEmpty()) {
			result = 
					result->makeNew(split, result, CAST(ActualOrglRoot,hisOut));
			him = another->copy(split);
		}
	} END_FOR_EACH;
	if (!him->isEmpty()) {
		BLAST(CombineLoopFailed);
	}
	WPTR(OrglRoot) 	returnValue;
	returnValue = result;
	return returnValue;
}


void OExpandingLoaf::informTo (APTR(OrglRoot) /* orgl */){
	BLAST(NOT_YET_IMPLEMENTED);
}


BooleanVar OExpandingLoaf::isPartial (){
	return FALSE;
}


UInt8 OExpandingLoaf::splay (APTR(XnRegion) region, APTR(XnRegion) limitRegion){
	/* Make each child completely contained or completely outside 
		the region. Return the number of children completely in the region. 
		Handle the containment cases using myRegion. */
	
	if (myRegion->isSubsetOf(region)) {
		return 2;
	} else {
		if (myRegion->intersects(region)) {
			return this->actualSplay(region, limitRegion);
		} else {
			return Int0;
		}
	}
}
/* backfollow */


void OExpandingLoaf::checkChildRecorders (APTR(PropFinder) finder){
	/* send checkRecorders to all children */
	
	
}


void OExpandingLoaf::delayedStoreMatching (
		APTR(PropFinder) finder, 
		APTR(RecorderFossil) fossil, 
		APTR(ResultRecorder) recorder, 
		APTR(HashSetCache) OF1(HistoryCrum) hCrumCache)
{
	/* Default south-to-north turnaround point during 'now' part 
	of backfollow (which is leafward, then rootward, in the 
	H-tree, filtered by the Bert canopy).  (Sometimes overridden).
		(OExpandingLoaf is the supercalss of all O-tree leaf types.) */
	
	this->hCrum()->delayedStoreBackfollow(finder, fossil, recorder, hCrumCache);
}


void OExpandingLoaf::storeRecordingAgents (APTR(RecorderFossil) recorder, APTR(Agenda) agenda){
	agenda->registerItem(this->sensorCrum()->recordingAgent(recorder));
}
/* accessing */


RPTR(Mapping) OExpandingLoaf::compare (APTR(TracePosition) trace, APTR(XnRegion) region){
	/* return a mapping from my data to corresponding stuff in 
	the given trace */
	
	WPTR(Mapping) 	returnValue;
	returnValue = this->hCrum()->mappingTo(trace, region->coordinateSpace()->identityDsp()->restrict(region));
	return returnValue;
}


IntegerVar OExpandingLoaf::count (){
	return myRegion->count();
}


RPTR(XnRegion) OExpandingLoaf::domain (){
	return (XnRegion*) myRegion;
}


RPTR(OExpandingLoaf) OExpandingLoaf::fetchBottomAt (APTR(Position) key){
	/* I'm at the bottom. */
	
	return this;
}


RPTR(XnRegion) OExpandingLoaf::keysLabelled (APTR(BeLabel) label){
	/* This gets overridden by RegionLoaf. */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = this->domain()->coordinateSpace()->emptyRegion();
	return returnValue;
}


RPTR(XnRegion) OExpandingLoaf::rangeOwners (APTR(XnRegion) OR(NULL) positions){
	{	BooleanVar crutch_Flag;
		/* positions == NULL || myRegion->intersects(positions) */
		
		crutch_Flag = positions == NULL;
		if(!crutch_Flag) {
			crutch_Flag = myRegion->intersects(positions);
		}
		if (crutch_Flag) {
			WPTR(XnRegion) 	returnValue;
			returnValue = this->owner()->asRegion();
			return returnValue;
		} else {
			WPTR(XnRegion) 	returnValue;
			returnValue = this->owner()->coordinateSpace()->emptyRegion();
			return returnValue;
		}
	}
}


RPTR(XnRegion) OExpandingLoaf::sharedRegion (APTR(TracePosition) trace, APTR(XnRegion) /* limitRegion */){
	/* Return a region describing the stuff that can backfollow 
	to trace. */
	
	if (this->hCrum()->inTrace(trace)) {
		return (XnRegion*) myRegion;
	} else {
		WPTR(XnRegion) 	returnValue;
		returnValue = myRegion->coordinateSpace()->emptyRegion();
		return returnValue;
	}
}
/* printing */


void OExpandingLoaf::printOn (ostream& aStream){
	aStream << this->getCategory()->name() << "(" << myRegion << ")";
}
/* protected: splay */
/* create */


OExpandingLoaf::OExpandingLoaf (APTR(XnRegion) region, TCSJ) 
	: Loaf(NULL, NULL) {
	if ( region->isEmpty() ) {
		BLAST(Assertion_failed);
	}
	myRegion = region;
}


OExpandingLoaf::OExpandingLoaf (
		APTR(XnRegion) region, 
		APTR(HUpperCrum) OR(NULL) hcrum, 
		APTR(SensorCrum) sensor) 

	: Loaf(hcrum, sensor) {
	if ( region->isEmpty() ) {
		BLAST(Assertion_failed);
	}
	myRegion = region;
}


OExpandingLoaf::OExpandingLoaf (
		UInt32 hash, 
		APTR(XnRegion) region, 
		APTR(HUpperCrum) hcrum, 
		APTR(SensorCrum) sensor) 

	: Loaf(hash
		, hcrum
		, sensor) 
{
	if ( region->isEmpty() ) {
		BLAST(Assertion_failed);
	}
	myRegion = region;
}
/* testing */


UInt32 OExpandingLoaf::contentsHash (){
	return this->Loaf::contentsHash() ^ myRegion->hashForEqual();
}



/* ************************************************************************ *
 * 
 *                    Class MergeBundlesStepper 
 *
 * ************************************************************************ */


/* creation */


RPTR(Stepper) MergeBundlesStepper::make (
		APTR(Stepper) OF1(FeBundle) a, 
		APTR(Stepper) OF1(FeBundle) b, 
		APTR(OrderSpec) order)
{
	if (!a->hasValue()) {
		WPTR(Stepper) 	returnValue;
		returnValue = b;
		return returnValue;
	}
	if (!b->hasValue()) {
		WPTR(Stepper) 	returnValue;
		returnValue = a;
		return returnValue;
	}
	RETURN_CONSTRUCT(MergeBundlesStepper,(a, b, order, NULL));
}
/* A Stepper for doing a merge-sort like ordered interleaving of two 
other steppers.  It is assumed that the other two steppers are 
constructed so that their values are also produced in order according 
to the same OrderSpec.  A tree of these operates much like a heap as 
found in heapsort. */


/* operations */


RPTR(Stepper) MergeBundlesStepper::copy (){
	if (myValue == NULL) {
		WPTR(Stepper) 	returnValue;
		returnValue = Stepper::emptyStepper();
		return returnValue;
	}
	RETURN_CONSTRUCT(MergeBundlesStepper,(myA->copy(), myB->copy(), myOrder, myValue));
}


WPTR(Heaper) MergeBundlesStepper::fetch (){
	return (FeBundle*) myValue;
}


BooleanVar MergeBundlesStepper::hasValue (){
	return myValue != NULL;
}


void MergeBundlesStepper::step (){
	SPTR(FeBundle) a;
	SPTR(FeBundle) b;
	
	a = CAST(FeBundle,myA->fetch());
	b = CAST(FeBundle,myB->fetch());
	if (a == NULL) {
		myValue = b;
		if (b != NULL) {
			myB->step();
		}
		return;
		
	}
	if (b == NULL) {
		myValue = a;
		myA->step();
		return;
		
	}
	if (myOrder->preceeds(a->region(), b->region())) {
		myValue = a;
		myA->step();
	} else {
		myValue = b;
		myB->step();
	}
}
/* private: creation */


MergeBundlesStepper::MergeBundlesStepper (
		APTR(Stepper) OF1(Position) a, 
		APTR(Stepper) OF1(Position) b, 
		APTR(OrderSpec) order, 
		APTR(FeBundle) OR(NULL) value) 
{
	myA = a;
	myB = b;
	myOrder = order;
	myValue = value;
	if (value == NULL) {
		this->step();
	}
}



/* ************************************************************************ *
 * 
 *                    Class DspLoaf 
 *
 * ************************************************************************ */


/* accessing */


RPTR(Mapping) DspLoaf::compare (APTR(TracePosition) trace, APTR(XnRegion) region){
	/* return a mapping from my data to corresponding stuff in 
	the given trace */
	
	WPTR(Mapping) 	returnValue;
	returnValue = myO->compare(trace, myDsp->inverseOfAll(region))->transformedBy(CAST(Dsp,myDsp->inverse()));
	return returnValue;
}


IntegerVar DspLoaf::count (){
	return myO->count();
}


RPTR(XnRegion) DspLoaf::domain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myDsp->ofAll(myO->domain());
	return returnValue;
}


RPTR(FeRangeElement) OR(NULL) DspLoaf::fetch (
		APTR(Position) key, 
		APTR(BeEdition) edition, 
		APTR(Position) globalKey)
{
	/* Look up the range element for the key.  If it is embedded 
	within a virtual
		 structure, then make a virtual range element using the 
	edition and globalKey. */
	
	WPTR(FeRangeElement) OR(NULL) 	returnValue;
	returnValue = myO->fetch(myDsp->inverseOf(key), edition, globalKey);
	return returnValue;
}


RPTR(OExpandingLoaf) DspLoaf::fetchBottomAt (APTR(Position) key){
	/* Return the bottom-most Loaf.  Used to get the owner and 
	such of a position. */
	
	WPTR(OExpandingLoaf) 	returnValue;
	returnValue = myO->fetchBottomAt(myDsp->inverseOf(key));
	return returnValue;
}


void DspLoaf::fill (
		APTR(XnRegion) keys, 
		APTR(Arrangement) toArrange, 
		APTR(PrimArray) toArray, 
		APTR(Dsp) globalDsp, 
		APTR(BeEdition) edition)
{
	/* Make an FeRangeElement for each position. */
	
	if (!keys->isEmpty()) {
		myO->fill(myDsp->inverseOfAll(keys), toArrange, toArray, globalDsp->compose(myDsp), edition);
	}
}


RPTR(BeRangeElement) DspLoaf::getBe (APTR(Position) key){
	/* Get or Make the BeRangeElement at the location. */
	
	WPTR(BeRangeElement) 	returnValue;
	returnValue = myO->getBe(myDsp->inverseOf(key));
	return returnValue;
}


RPTR(Loaf) DspLoaf::inPart (){
	/* This is used by the splay algorithms. */
	
	WPTR(Loaf) 	returnValue;
	returnValue = CAST(InnerLoaf,myO)->inPart()->transformedBy(myDsp);
	return returnValue;
}


RPTR(Mapping) DspLoaf::mappingTo (APTR(TracePosition) trace, APTR(Mapping) initial){
	/* return the mapping into the domain space of the given trace */
	
	WPTR(Mapping) 	returnValue;
	returnValue = this->hCrum()->mappingTo(trace, initial->preCompose(myDsp));
	return returnValue;
}


RPTR(Loaf) DspLoaf::outPart (){
	/* This is used by the splay algorithms. */
	
	WPTR(Loaf) 	returnValue;
	returnValue = CAST(InnerLoaf,myO)->outPart()->transformedBy(myDsp);
	return returnValue;
}


RPTR(XnRegion) DspLoaf::rangeOwners (APTR(XnRegion) OR(NULL) positions){
	if (positions == NULL) {
		WPTR(XnRegion) 	returnValue;
		returnValue = myO->rangeOwners(NULL);
		return returnValue;
	}
	if (positions->isEmpty()) {
		WPTR(XnRegion) 	returnValue;
		returnValue = IDSpace::global()->emptyRegion();
		return returnValue;
	} else {
		WPTR(XnRegion) 	returnValue;
		returnValue = myO->rangeOwners(myDsp->inverseOfAll(positions));
		return returnValue;
	}
}


RPTR(OrglRoot) DspLoaf::setAllOwners (APTR(ID) owner){
	/* Recur assigning owners.  Return the portion of the o-tree 
	that couldn't be assigned. */
	
	WPTR(OrglRoot) 	returnValue;
	returnValue = myO->setAllOwners(owner)->transformedBy(myDsp);
	return returnValue;
}


RPTR(XnRegion) DspLoaf::usedDomain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myDsp->ofAll(myO->usedDomain());
	return returnValue;
}
/* protected: splay */


Int8 DspLoaf::actualSplay (APTR(XnRegion) region, APTR(XnRegion) limitRegion){
	/* Make each child completely contained or completely outside
		 the region.  Return the number of children completely in 
	the region. */
	
	SPTR(Dsp) dsp;
	
	dsp = myDsp;
	return myO->splay(dsp->inverseOfAll(region), dsp->inverseOfAll(limitRegion));
}
/* operations */


RPTR(Stepper) DspLoaf::bundleStepper (
		APTR(XnRegion) region, 
		APTR(OrderSpec) order, 
		APTR(Dsp) globalDsp)
{
	/* Return a stepper of bundles according to the order. */
	
	WPTR(Stepper) 	returnValue;
	returnValue = myO->bundleStepper(region, order, globalDsp->compose(myDsp));
	return returnValue;
}


RPTR(OrglRoot) DspLoaf::combine (
		APTR(ActualOrglRoot) another, 
		APTR(XnRegion) limitRegion, 
		APTR(Dsp) globalDsp)
{
	/* Accumulate dsp downward. */
	
	WPTR(OrglRoot) 	returnValue;
	returnValue = myO->combine(another, limitRegion, globalDsp->compose(myDsp));
	return returnValue;
}


RPTR(XnRegion) DspLoaf::keysLabelled (APTR(BeLabel) label){
	/* Just search for now. */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = myDsp->ofAll(myO->keysLabelled(label));
	return returnValue;
}


RPTR(XnRegion) DspLoaf::sharedRegion (APTR(TracePosition) trace, APTR(XnRegion) limitRegion){
	/* Return a region describing the stuff that can backfollow 
	to trace. */
	
	if (this->hCrum()->inTrace(trace)) {
		WPTR(XnRegion) 	returnValue;
		returnValue = this->domain();
		return returnValue;
	} else {
		WPTR(XnRegion) 	returnValue;
		returnValue = myDsp->ofAll(myO->sharedRegion(trace, myDsp->inverseOfAll(limitRegion)));
		return returnValue;
	}
}


RPTR(Loaf) DspLoaf::transformedBy (APTR(Dsp) externalDsp){
	/* Return a copy with externalDsp added to the receiver's dsp. */
	
	if (externalDsp->isIdentity()) {
		return this;
	} else {
		WPTR(Loaf) 	returnValue;
		returnValue = myO->transformedBy(externalDsp->compose(myDsp));
		return returnValue;
	}
}


RPTR(Loaf) DspLoaf::unTransformedBy (APTR(Dsp) externalDsp){
	/* Return a copy with externalDsp removed from the receiver's dsp. */
	
	if (externalDsp->isIdentity()) {
		return this;
	} else {
		WPTR(Loaf) 	returnValue;
		returnValue = myO->unTransformedBy(myDsp->minus(externalDsp));
		return returnValue;
	}
}
/* printing */


void DspLoaf::printOn (ostream& aStream){
	aStream << "(" << myDsp << ")";
}
/* backfollow */


void DspLoaf::addOParent (APTR(OPart) oparent){
	/* add oparent to the set of upward pointers and update the 
	bertCrums my child. */
	
	SPTR(BertCrum) bCrum;
	SPTR(BertCrum) newBCrum;
	
	bCrum = this->hCrum()->bertCrum();
	this->InnerLoaf::addOParent(oparent);
	newBCrum = this->hCrum()->bertCrum();
	if (!bCrum->isLE(newBCrum)) {
		myO->updateBCrumTo(newBCrum);
	}
}


RPTR(XnRegion) DspLoaf::attachTrailBlazer (APTR(TrailBlazer) blazer){
	WPTR(XnRegion) 	returnValue;
	returnValue = myDsp->ofAll(myO->attachTrailBlazer(blazer));
	return returnValue;
}


void DspLoaf::checkChildRecorders (APTR(PropFinder) finder){
	/* send checkRecorders to all children */
	
	myO->checkRecorders(finder, this->sensorCrum());
}


void DspLoaf::checkTrailBlazer (APTR(TrailBlazer) blazer){
	myO->checkTrailBlazer(blazer);
}


void DspLoaf::delayedStoreMatching (
		APTR(PropFinder) finder, 
		APTR(RecorderFossil) fossil, 
		APTR(ResultRecorder) recorder, 
		APTR(HashSetCache) OF1(HistoryCrum) hCrumCache)
{
	myO->delayedStoreMatching(finder, fossil, recorder, hCrumCache);
}


RPTR(TrailBlazer) OR(NULL) DspLoaf::fetchTrailBlazer (){
	WPTR(TrailBlazer) OR(NULL) 	returnValue;
	returnValue = myO->fetchTrailBlazer();
	return returnValue;
}


void DspLoaf::storeRecordingAgents (APTR(RecorderFossil) recorder, APTR(Agenda) agenda){
	myO->storeRecordingAgents(recorder, agenda);
}


void DspLoaf::triggerDetector (APTR(FeFillRangeDetector) detect){
	if (this->sensorCrum()->isPartial()) {
		myO->triggerDetector(detect);
	} else {
		detect->rangeFilled(this->asFeEdition());
	}
}


BooleanVar DspLoaf::updateBCrumTo (APTR(BertCrum) newBCrum){
	/* My bertCrum must not be leafward of newBCrum. 
		Thus it must be LE to newCrum. Otherwise correct it and recur. */
	
	if (this->InnerLoaf::updateBCrumTo(newBCrum)) {
		myO->updateBCrumTo(newBCrum);
		return TRUE;
	}
	return FALSE;
}
/* create */


DspLoaf::DspLoaf (APTR(Loaf) loaf, APTR(Dsp) dsp) 
	: InnerLoaf(NULL, loaf->sensorCrum()) {
	myO = loaf;
	myDsp = dsp;
	/* Connect the HTrees. */
	this->newShepherd();
	myO->addOParent(this);
}
/* protected: delete */


void DspLoaf::dismantle (){
	BEGIN_CONSISTENT(3) {
		if (::isConstructed(myO)) {
			myO->removeOParent(this);
		}
		this->InnerLoaf::dismantle();
	} END_CONSISTENT;
}
/* testing */


UInt32 DspLoaf::contentsHash (){
	return this->InnerLoaf::contentsHash() ^ myDsp->hashForEqual() ^ myO->hashForEqual();
}



/* ************************************************************************ *
 * 
 *                    Class OPartialLoaf 
 *
 * ************************************************************************ */


/* accessing */


RPTR(FeRangeElement) OR(NULL) OPartialLoaf::fetch (
		APTR(Position) key, 
		APTR(BeEdition) edition, 
		APTR(Position) globalKey)
{
	/* Make a virtual PlaceHolder. */
	
	if (this->domain()->hasMember(key)) {
		WPTR(FeRangeElement) OR(NULL) 	returnValue;
		returnValue = FePlaceHolder::fake(edition, globalKey);
		return returnValue;
	} else {
		return NULL;
	}
}


RPTR(BeRangeElement) OPartialLoaf::getBe (APTR(Position) key){
	/* Get or make the BeRangeElement at the location. */
	/* My region had better be just onto the key.
		 become a RegionLoaf onto a new BePlaceHolder */
	
	SPTR(BeRangeElement) element;
	SPTR(XnRegion) domain;
	SPTR(HUpperCrum) hcrum;
	UInt32 hash;
	SPTR(FlockInfo) info;
	
	domain = key->asRegion();
	if (!this->domain()->isEqual(domain)) {
		BLAST(NotInTable);
	}
	hcrum = CAST(HUpperCrum,this->hCrum());
	hash = this->hashForEqual();
	info = this->fetchInfo();
	BEGIN_CONSISTENT(-1) {
		this->sensorCrum()->removePointer(this);
		{	FLUID_BIND(InitialOwner,this->owner()) {
				
				{	FLUID_BIND(CurrentTrace,this->hCrum()->hCut()) {
						{	FLUID_BIND(CurrentBertCrum,BertCrum::make ()) {
								CONSTRUCT(element,BePlaceHolder,(myTrailBlazer, tcsj));
								if (myTrailBlazer != NULL) {
									myTrailBlazer->removeReference(this);
									myTrailBlazer = NULL;
								}
							}
						}
					}
				}
			}
		}
		new (this) RegionLoaf(domain, element, hcrum, hash, info);
	} END_CONSISTENT;
	WPTR(BeRangeElement) 	returnValue;
	returnValue = element;
	return returnValue;
}


RPTR(ID) OPartialLoaf::owner (){
	/* Return the owner of the atoms represented by the receiver. */
	
	return (ID*) myOwner;
}


RPTR(PrimSpec) OPartialLoaf::spec (){
	/* Return the PrimSpec that describes the representation of 
	the data. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	WPTR(PrimSpec) 	returnValue;
	returnValue = PrimSpec::pointer();
	return returnValue;
}


RPTR(XnRegion) OPartialLoaf::usedDomain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->domain()->coordinateSpace()->emptyRegion();
	return returnValue;
}
/* operations */


RPTR(Stepper) OPartialLoaf::bundleStepper (
		APTR(XnRegion) region, 
		APTR(OrderSpec) order, 
		APTR(Dsp) globalDsp)
{
	/* Return a stepper of bundles according to the order. */
	
	SPTR(XnRegion) bundleRegion;
	
	bundleRegion = region->intersect(globalDsp->ofAll(this->domain()));
	if (bundleRegion->isEmpty()) {
		WPTR(Stepper) 	returnValue;
		returnValue = Stepper::emptyStepper();
		return returnValue;
	}
	WPTR(Stepper) 	returnValue;
	returnValue = Stepper::itemStepper(FePlaceHolderBundle::make (bundleRegion));
	return returnValue;
}


void OPartialLoaf::fill (
		APTR(XnRegion) keys, 
		APTR(Arrangement) toArrange, 
		APTR(PrimArray) toArray, 
		APTR(Dsp) dsp, 
		APTR(BeEdition) edition)
{
	/* Make an FeRangeElement for each position. */
	
	BEGIN_FOR_EACH(Position,key,(keys->intersect(this->domain())->stepper())) {
		SPTR(Position) globalKey;
		
		globalKey = dsp->of(key);
		toArray->storeValue(toArrange->indexOf(globalKey).asLong(), FePlaceHolder::fake(edition, globalKey));
	} END_FOR_EACH;
}


void OPartialLoaf::informTo (APTR(OrglRoot) /* orgl */){
	BLAST(NOT_YET_IMPLEMENTED);
}


BooleanVar OPartialLoaf::isPartial (){
	/* Partial crums are always partial. */
	
	return TRUE;
}


RPTR(OrglRoot) OPartialLoaf::setAllOwners (APTR(ID) owner){
	/* If the CurrentKeyMaster includes the owner of this loaf
			then change the owner and return NULL
			else just return self. */
	
	if (CurrentKeyMaster.fluidGet()->hasAuthority(myOwner)) {
		myOwner = owner;
		WPTR(OrglRoot) 	returnValue;
		returnValue = OrglRoot::make (this->domain()->coordinateSpace());
		return returnValue;
	} else {
		WPTR(OrglRoot) 	returnValue;
		returnValue = ActualOrglRoot::make (this, this->domain());
		return returnValue;
	}
}
/* protected: splay */


Int8 OPartialLoaf::actualSoftSplay (APTR(XnRegion) region, APTR(XnRegion) /* limitRegion */){
	/* Don't expand me in place.  Just move it closer to the top. */
	
	return 2;
}


Int8 OPartialLoaf::actualSplay (APTR(XnRegion) region, APTR(XnRegion) /* limitRegion */){
	/* Expand my partial tree in place. The area in the region must go 
		into the leftCrum of my substitute, or the splay algorithm 
	will fail! */
	
	SPTR(Pair) OF1(SensorCrum) crums;
	SPTR(Loaf) tmp1;
	SPTR(Loaf) tmp2;
	
	crums = this->sensorCrum()->expand();
	BEGIN_CONSISTENT(3) {
		CONSTRUCT(tmp1,OPartialLoaf,(this->domain()->intersect(region), HUpperCrum::make (CAST(HUpperCrum,this->hCrum())), CAST(SensorCrum,crums->left()), myOwner, myTrailBlazer));
	} END_CONSISTENT;
	BEGIN_CONSISTENT(3) {
		CONSTRUCT(tmp2,OPartialLoaf,(this->domain()->intersect(region->complement()), HUpperCrum::make (CAST(HUpperCrum,this->hCrum())), CAST(SensorCrum,crums->right()), myOwner, myTrailBlazer));
	} END_CONSISTENT;
	if (myTrailBlazer != NULL) {
		BEGIN_CONSISTENT(1) {
			myTrailBlazer->addReference(tmp1);
			myTrailBlazer->addReference(tmp2);
			myTrailBlazer->removeReference(this);
		} END_CONSISTENT;
	}
	BEGIN_CONSISTENT(5) {
		SPTR(HUpperCrum) hcrum;
		UInt32 hash;
		SPTR(FlockInfo) info;
		SPTR(CanopyCrum) oldSensorCrum;
		
		hcrum = CAST(HUpperCrum,this->hCrum());
		hash = this->hashForEqual();
		oldSensorCrum = this->sensorCrum();
		info = this->fetchInfo();
		new (this) SplitLoaf(region, tmp1, tmp2, hcrum, hash, info);
		/* The new SplitLoaf will add itself. */
		oldSensorCrum->removePointer(this);
	} END_CONSISTENT;
	return 1;
}
/* create */


OPartialLoaf::OPartialLoaf (APTR(XnRegion) region, TCSJ) 
	: OExpandingLoaf(region, tcsj) {
	myOwner = InitialOwner.fluidFetch();
	myTrailBlazer = NULL;
	this->newShepherd();
}


OPartialLoaf::OPartialLoaf (
		APTR(XnRegion) region, 
		APTR(HUpperCrum) hcrum, 
		APTR(SensorCrum) scrum) 

	: OExpandingLoaf(region
		, hcrum
		, scrum) 
{
	myOwner = InitialOwner.fluidFetch();
	myTrailBlazer = NULL;
	this->newShepherd();
}


OPartialLoaf::OPartialLoaf (
		APTR(XnRegion) region, 
		APTR(HUpperCrum) hcrum, 
		APTR(SensorCrum) scrum, 
		APTR(ID) owner, 
		APTR(TrailBlazer) OR(NULL) blazer) 

	: OExpandingLoaf(region
		, hcrum
		, scrum) 
{
	myOwner = owner;
	myTrailBlazer = blazer;
	this->newShepherd();
}
/* protected: delete */


void OPartialLoaf::dismantle (){
	BEGIN_CONSISTENT(4) {
		if (::isConstructed(myTrailBlazer)) {
			myTrailBlazer->removeReference(this);
		}
		this->OExpandingLoaf::dismantle();
	} END_CONSISTENT;
}
/* backfollow */


RPTR(XnRegion) OPartialLoaf::attachTrailBlazer (APTR(TrailBlazer) blazer){
	BEGIN_CONSISTENT(2) {
		if (myTrailBlazer != NULL) {
			if (myTrailBlazer->isAlive()) {
				BLAST(FatalError);
			} else {
				myTrailBlazer->removeReference(this);
			}
		}
		myTrailBlazer = blazer;
		blazer->addReference(this);
		this->diskUpdate();
	} END_CONSISTENT;
	WPTR(XnRegion) 	returnValue;
	returnValue = this->domain();
	return returnValue;
}


void OPartialLoaf::checkTrailBlazer (APTR(TrailBlazer) blazer){
	{	BooleanVar crutch_Flag;
		/* myTrailBlazer != NULL && myTrailBlazer->isEqual(blazer) */
		
		crutch_Flag = myTrailBlazer != NULL;
		if(crutch_Flag) {
			crutch_Flag = myTrailBlazer->isEqual(blazer);
		}
		if (!crutch_Flag) {
			BLAST(InvalidTrail);
		}
	}
}


RPTR(TrailBlazer) OR(NULL) OPartialLoaf::fetchTrailBlazer (){
	{	BooleanVar crutch_Flag;
		/* myTrailBlazer == NULL || myTrailBlazer->isAlive() */
		
		crutch_Flag = myTrailBlazer == NULL;
		if(!crutch_Flag) {
			crutch_Flag = myTrailBlazer->isAlive();
		}
		if (crutch_Flag) {
			return (TrailBlazer*) myTrailBlazer;
		}
	}
	/* it was not successfully attached, so clean it up */
	BEGIN_CONSISTENT(2) {
		myTrailBlazer->removeReference(this);
		myTrailBlazer = NULL;
		this->diskUpdate();
		return NULL;
	} END_CONSISTENT;
}


void OPartialLoaf::triggerDetector (APTR(FeFillRangeDetector) detect){
	/* do nothing */
	
	
}



/* ************************************************************************ *
 * 
 *                    Class OVirtualLoaf 
 *
 * ************************************************************************ */


/* accessing */


RPTR(FeRangeElement) OR(NULL) OVirtualLoaf::fetch (
		APTR(Position) key, 
		APTR(BeEdition) edition, 
		APTR(Position) globalKey)
{
	/* Make a virtual DataHolder. */
	
	if (this->domain()->hasMember(key)) {
		WPTR(FeRangeElement) OR(NULL) 	returnValue;
		returnValue = FeDataHolder::fake(CAST(PrimValue,myData->fetch(key)), globalKey, edition);
		return returnValue;
	} else {
		return NULL;
	}
}


RPTR(BeRangeElement) OVirtualLoaf::getBe (APTR(Position) key){
	/* Get or make the BeRangeElement at the location. */
	/* My region had better be just onto the key.
		 become a RegionLoaf onto a new BeDataHolder containing the 
		 data extracted from my SharedData object. */
	
	SPTR(BeRangeElement) element;
	SPTR(XnRegion) domain;
	SPTR(HUpperCrum) hcrum;
	UInt32 hash;
	SPTR(FlockInfo) info;
	
	domain = key->asRegion();
	if (!this->domain()->isEqual(domain)) {
		BLAST(NotInTable);
	}
	hcrum = CAST(HUpperCrum,this->hCrum());
	hash = this->hashForEqual();
	info = this->fetchInfo();
	BEGIN_CONSISTENT(-1) {
		SPTR(CanopyCrum) oldSensorCrum;
		
		oldSensorCrum = this->sensorCrum();
		
		{	FLUID_BIND(InitialOwner,this->owner()) {
				{	FLUID_BIND(CurrentTrace,this->hCrum()->hCut()) {
						{	FLUID_BIND(CurrentBertCrum,BertCrum::make ()) {
								CONSTRUCT(element,BeDataHolder,(CAST(PrimValue,myData->fetch(key)), tcsj));
							}
						}
					}
				}
			}
		}
		new (this) RegionLoaf(domain, element, hcrum, hash, info);
		oldSensorCrum->removePointer(this);
	} END_CONSISTENT;
	WPTR(BeRangeElement) 	returnValue;
	returnValue = element;
	return returnValue;
}


RPTR(ID) OVirtualLoaf::owner (){
	/* Return the owner of the atoms represented by the receiver. */
	
	return (ID*) myOwner;
}


RPTR(PrimSpec) OVirtualLoaf::spec (){
	/* Return the primSpec for my data. */
	
	WPTR(PrimSpec) 	returnValue;
	returnValue = myData->spec();
	return returnValue;
}


RPTR(XnRegion) OVirtualLoaf::usedDomain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->domain();
	return returnValue;
}
/* operations */


RPTR(Stepper) OVirtualLoaf::bundleStepper (
		APTR(XnRegion) region, 
		APTR(OrderSpec) order, 
		APTR(Dsp) globalDsp)
{
	/* Return a stepper of bundles according to the order. */
	
	SPTR(XnRegion) bundleRegion;
	SPTR(PrimArray) array;
	
	bundleRegion = region->intersect(globalDsp->ofAll(this->domain()));
	if (bundleRegion->isEmpty()) {
		WPTR(Stepper) 	returnValue;
		returnValue = Stepper::emptyStepper();
		return returnValue;
	}
	array = myData->spec()->array(bundleRegion->count().asLong());
	myData->fill(bundleRegion, order->arrange(bundleRegion), array, globalDsp);
	WPTR(Stepper) 	returnValue;
	returnValue = Stepper::itemStepper(
			FeArrayBundle::make (bundleRegion, array, order));
	return returnValue;
}


void OVirtualLoaf::fill (
		APTR(XnRegion) keys, 
		APTR(Arrangement) toArrange, 
		APTR(PrimArray) toArray, 
		APTR(Dsp) dsp, 
		APTR(BeEdition) edition)
{
	myData->fill(keys->intersect(this->domain()), toArrange, toArray, dsp);
}


void OVirtualLoaf::informTo (APTR(OrglRoot) /* orgl */){
	BLAST(NOT_YET_IMPLEMENTED);
}


RPTR(OrglRoot) OVirtualLoaf::setAllOwners (APTR(ID) owner){
	/* If the CurrentKeyMaster includes the owner of this loaf
			then change the owner and return NULL
			else just return self. */
	
	if (CurrentKeyMaster.fluidGet()->hasAuthority(myOwner)) {
		myOwner = owner;
		WPTR(OrglRoot) 	returnValue;
		returnValue = OrglRoot::make (this->domain()->coordinateSpace());
		return returnValue;
	} else {
		WPTR(OrglRoot) 	returnValue;
		returnValue = ActualOrglRoot::make (this, this->domain());
		return returnValue;
	}
}
/* printing */


void OVirtualLoaf::printOn (ostream& aStream){
	/* (myData table subTable: self domain) << */
	aStream << this->getCategory()->name() << "(" << ", " << this->hCrum()->hCut() << ")";
}
/* protected: splay */


Int8 OVirtualLoaf::actualSoftSplay (APTR(XnRegion) region, APTR(XnRegion) /* limitRegion */){
	/* Don't expand my virtual tree in place.  Just move it 
	closer to the top. */
	
	return 2;
}


Int8 OVirtualLoaf::actualSplay (APTR(XnRegion) region, APTR(XnRegion) /* limitRegion */){
	/* Expand my partial tree in place. The area in the region must go 
		into the leftCrum of my substitute, or the splay algorithm 
	will fail! */
	
	SPTR(Pair) OF1(SensorCrum) crums;
	SPTR(Loaf) tmp1;
	SPTR(Loaf) tmp2;
	
	crums = this->sensorCrum()->expand();
	{	FLUID_BIND(InitialOwner,this->owner()) {
			BEGIN_CONSISTENT(3) {
				CONSTRUCT(tmp1,OVirtualLoaf,(this->domain()->intersect(region), myData, HUpperCrum::make (CAST(HUpperCrum,this->hCrum())), CAST(SensorCrum,crums->left())));
			} END_CONSISTENT;
			BEGIN_CONSISTENT(3) {
				CONSTRUCT(tmp2,OVirtualLoaf,(this->domain()->intersect(region->complement()), myData, HUpperCrum::make (CAST(HUpperCrum,this->hCrum())), CAST(SensorCrum,crums->right())));
			} END_CONSISTENT;
			BEGIN_CONSISTENT(5) {
				SPTR(HUpperCrum) hcrum;
				UInt32 hash;
				SPTR(FlockInfo) info;
				SPTR(CanopyCrum) oldSensorCrum;
				
				hcrum = CAST(HUpperCrum,this->hCrum());
				hash = this->hashForEqual();
				oldSensorCrum = this->sensorCrum();
				info = this->fetchInfo();
				new (this) SplitLoaf(region, tmp1, tmp2, hcrum, hash, info);
				/* The new SplitLoaf will add itself. */
				oldSensorCrum->removePointer(this);
			} END_CONSISTENT;
		}
	}
	return 1;
}
/* create */


OVirtualLoaf::OVirtualLoaf (APTR(XnRegion) region, APTR(SharedData) data) 
	: OExpandingLoaf(region, tcsj) {
	myData = data;
	myOwner = InitialOwner.fluidFetch();
	this->newShepherd();
}


OVirtualLoaf::OVirtualLoaf (
		APTR(XnRegion) region, 
		APTR(SharedData) data, 
		APTR(HUpperCrum) hcrum, 
		APTR(SensorCrum) scrum) 

	: OExpandingLoaf(region
		, hcrum
		, scrum) 
{
	myData = data;
	myOwner = InitialOwner.fluidFetch();
	this->newShepherd();
}
/* testing */


UInt32 OVirtualLoaf::contentsHash (){
	return this->OExpandingLoaf::contentsHash() ^ myData->contentsHash();
}
/* backfollow */


RPTR(XnRegion) OVirtualLoaf::attachTrailBlazer (APTR(TrailBlazer) blazer){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->domain()->coordinateSpace()->emptyRegion();
	return returnValue;
}


void OVirtualLoaf::checkTrailBlazer (APTR(TrailBlazer) blazer){
	/* it's OK */
	
	
}


RPTR(TrailBlazer) OR(NULL) OVirtualLoaf::fetchTrailBlazer (){
	return NULL;
}


void OVirtualLoaf::triggerDetector (APTR(FeFillRangeDetector) detect){
	detect->rangeFilled(this->asFeEdition());
}



/* ************************************************************************ *
 * 
 *                    Class RegionLoaf 
 *
 * ************************************************************************ */


/* accessing */


RPTR(Mapping) RegionLoaf::compare (APTR(TracePosition) trace, APTR(XnRegion) region){
	/* return a mapping from my data to corresponding stuff in 
	the given trace */
	
	WPTR(Mapping) 	returnValue;
	returnValue = myRangeElement->mappingTo(trace, region->coordinateSpace()->identityDsp()->restrict(region));
	return returnValue;
}


RPTR(FeRangeElement) OR(NULL) RegionLoaf::fetch (
		APTR(Position) key, 
		APTR(BeEdition) edition, 
		APTR(Position) globalKey)
{
	/* Make a virtual DataHolder. */
	
	if (this->domain()->hasMember(key)) {
		WPTR(FeRangeElement) OR(NULL) 	returnValue;
		returnValue = myRangeElement->makeFe(myLabel);
		return returnValue;
	} else {
		return NULL;
	}
}


void RegionLoaf::fill (
		APTR(XnRegion) keys, 
		APTR(Arrangement) toArrange, 
		APTR(PrimArray) toArray, 
		APTR(Dsp) dsp, 
		APTR(BeEdition) edition)
{
	/* Make an FeRangeElement for each position. */
	
	BEGIN_FOR_EACH(Position,key,(keys->intersect(this->domain())->stepper())) {
		SPTR(Position) globalKey;
		SPTR(FeRangeElement) fe;
		
		globalKey = dsp->of(key);
		fe = myRangeElement->makeFe(myLabel);
		toArray->storeValue(toArrange->indexOf(globalKey).asLong(), fe);
	} END_FOR_EACH;
}


void RegionLoaf::forwardTo (APTR(BeRangeElement) rangeElement){
	BEGIN_CONSISTENT(-1) {
		rangeElement->addOParent(this);
		myRangeElement->removeOParent(this);
		myRangeElement = rangeElement;
		this->diskUpdate();
	} END_CONSISTENT;
	/* Ravi -- Thing to do !!!! */
	
	/* Is there a lazier way to make the FeEdition? */
	if (this->hCrum()->bertCrum()->isSensorWaiting()) {
		this->hCrum()->ringDetectors(this->asFeEdition());
	}
}


RPTR(BeRangeElement) RegionLoaf::getBe (APTR(Position) key){
	/* If I'm here it must be non-virtual. */
	
	if (this->domain()->hasMember(key)) {
		return (BeRangeElement*) myRangeElement;
	} else {
		BLAST(NotInTable);
		return NULL;
	}
}


RPTR(XnRegion) RegionLoaf::keysLabelled (APTR(BeLabel) label){
	/* The keys in this Edition at which there are Editions with 
	the given label. */
	
	{	BooleanVar crutch_Flag;
		/* myLabel != NULL && myLabel->isEqual(label) */
		
		crutch_Flag = myLabel != NULL;
		if(crutch_Flag) {
			crutch_Flag = myLabel->isEqual(label);
		}
		if (crutch_Flag) {
			WPTR(XnRegion) 	returnValue;
			returnValue = this->domain();
			return returnValue;
		} else {
			WPTR(XnRegion) 	returnValue;
			returnValue = this->domain()->coordinateSpace()->emptyRegion();
			return returnValue;
		}
	}
}


RPTR(Mapping) RegionLoaf::mappingTo (APTR(TracePosition) trace, APTR(Mapping) initial){
	/* return the mapping into the domain space of the given trace */
	
	WPTR(Mapping) 	returnValue;
	returnValue = this->hCrum()->mappingTo(trace, Mapping::make (initial->coordinateSpace(), this->domain())->restrict(initial->domain()));
	return returnValue;
}


RPTR(ID) RegionLoaf::owner (){
	/* Return the owner of the atoms represented by the receiver. */
	
	WPTR(ID) 	returnValue;
	returnValue = myRangeElement->owner();
	return returnValue;
}


RPTR(XnRegion) RegionLoaf::sharedRegion (APTR(TracePosition) trace, APTR(XnRegion) /* limitRegion */){
	/* Return a region describing the stuff that can backfollow 
	to trace.  Redefine this to pass down to my hRoot. */
	
	if (myRangeElement->inTrace(trace)) {
		WPTR(XnRegion) 	returnValue;
		returnValue = this->domain();
		return returnValue;
	} else {
		WPTR(XnRegion) 	returnValue;
		returnValue = this->domain()->coordinateSpace()->emptyRegion();
		return returnValue;
	}
}


RPTR(PrimSpec) RegionLoaf::spec (){
	/* Return the PrimSpec that describes the representation of 
	the data. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	WPTR(PrimSpec) 	returnValue;
	returnValue = PrimSpec::pointer();
	return returnValue;
}


RPTR(XnRegion) RegionLoaf::usedDomain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->domain();
	return returnValue;
}
/* operations */


RPTR(Stepper) RegionLoaf::bundleStepper (
		APTR(XnRegion) region, 
		APTR(OrderSpec) order, 
		APTR(Dsp) globalDsp)
{
	/* Return a stepper of bundles according to the order. */
	
	SPTR(XnRegion) bundleRegion;
	
	bundleRegion = region->intersect(globalDsp->ofAll(this->domain()));
	if (bundleRegion->isEmpty()) {
		WPTR(Stepper) 	returnValue;
		returnValue = Stepper::emptyStepper();
		return returnValue;
	}
	WPTR(Stepper) 	returnValue;
	returnValue = Stepper::itemStepper(FeElementBundle::make (bundleRegion, myRangeElement->makeFe(myLabel)));
	return returnValue;
}


void RegionLoaf::informTo (APTR(OrglRoot) /* orgl */){
	BLAST(NOT_YET_IMPLEMENTED);
}


RPTR(OrglRoot) RegionLoaf::setAllOwners (APTR(ID) owner){
	/* If the CurrentKeyMaster includes the owner of this loaf
			then change the owner and return NULL
			else just return self. */
	
	if (CurrentKeyMaster.fluidGet()->hasAuthority(myRangeElement->owner())) {
		myRangeElement->setOwner(owner);
		WPTR(OrglRoot) 	returnValue;
		returnValue = OrglRoot::make (this->domain()->coordinateSpace());
		return returnValue;
	} else {
		WPTR(OrglRoot) 	returnValue;
		returnValue = ActualOrglRoot::make (this, this->domain());
		return returnValue;
	}
}
/* printing */


void RegionLoaf::printOn (ostream& aStream){
	aStream << this->getCategory()->name() << "(" << this->domain() << ", " << myRangeElement << ")";
}
/* protected: splay */


Int8 RegionLoaf::actualSoftSplay (APTR(XnRegion) region, APTR(XnRegion) /* limitRegion */){
	/* Don't expand me in place.  Just move it closer to the top. */
	
	return 2;
}


Int8 RegionLoaf::actualSplay (APTR(XnRegion) region, APTR(XnRegion) /* limitRegion */){
	/* Expand my partial tree in place.  The area in the region must go
		 into the leftCrum of my substitute, or the splay algorithm 
	will fail! */
	
	SPTR(Loaf) tmp1;
	SPTR(Loaf) tmp2;
	
	BEGIN_CONSISTENT(4) {
		CONSTRUCT(tmp1,RegionLoaf,(this->domain()->intersect(region), myLabel, myRangeElement, HUpperCrum::make (CAST(HUpperCrum,this->hCrum()))));
	} END_CONSISTENT;
	BEGIN_CONSISTENT(4) {
		CONSTRUCT(tmp2,RegionLoaf,(this->domain()->intersect(region->complement()), myLabel, myRangeElement, HUpperCrum::make (CAST(HUpperCrum,this->hCrum()))));
	} END_CONSISTENT;
	BEGIN_CONSISTENT(4) {
		SPTR(HUpperCrum) hcrum;
		UInt32 hash;
		SPTR(FlockInfo) info;
		
		hcrum = CAST(HUpperCrum,this->hCrum());
		hash = this->hashForEqual();
		info = this->fetchInfo();
		new (this) SplitLoaf(region, tmp1, tmp2, hcrum, hash, info);
	} END_CONSISTENT;
	return 1;
}
/* create */


RegionLoaf::RegionLoaf (
		APTR(XnRegion) region, 
		APTR(BeLabel) OR(NULL) label, 
		APTR(BeRangeElement) element, 
		APTR(HUpperCrum) OR(NULL) hcrum) 

	: OExpandingLoaf(region
		, hcrum
		, element->sensorCrum()) 
{
	myLabel = label;
	myRangeElement = element;
	this->newShepherd();
	myRangeElement->addOParent(this);
}


RegionLoaf::RegionLoaf (
		APTR(XnRegion) region, 
		APTR(BeRangeElement) element, 
		APTR(HUpperCrum) hcrum, 
		UInt32 hash, 
		APTR(FlockInfo) info) 

	: OExpandingLoaf(hash
		, region
		, hcrum
		, element->sensorCrum()) 
{
	if (element->isKindOf(cat_BeEdition)) {
		BLAST(EditionsRequireLabels);
	}
	myLabel = NULL;
	/* Known bug !!!! */
	
	/* This doesn't deal with labels. */
	this->flockInfo(info);
	myRangeElement = element;
	myRangeElement->addOParent(this);
	this->diskUpdate();
}
/* backfollow */


void RegionLoaf::addOParent (APTR(OPart) oparent){
	/* add oparent to the set of upward pointers and update the 
	bertCrums my child. */
	
	SPTR(BertCrum) bCrum;
	SPTR(BertCrum) newBCrum;
	
	bCrum = this->hCrum()->bertCrum();
	this->OExpandingLoaf::addOParent(oparent);
	newBCrum = this->hCrum()->bertCrum();
	if (!bCrum->isLE(newBCrum)) {
		myRangeElement->updateBCrumTo(newBCrum);
	}
}


RPTR(XnRegion) RegionLoaf::attachTrailBlazer (APTR(TrailBlazer) blazer){
	BEGIN_CHOOSE(myRangeElement) {
		BEGIN_KIND(BePlaceHolder,p) {
			p->attachTrailBlazer(blazer);
			WPTR(XnRegion) 	returnValue;
			returnValue = this->domain();
			return returnValue;
		} END_KIND;
		BEGIN_OTHERS {
			WPTR(XnRegion) 	returnValue;
			returnValue = this->domain()->coordinateSpace()->emptyRegion();
			return returnValue;
		} END_OTHERS;
	} END_CHOOSE;
}


void RegionLoaf::checkChildRecorders (APTR(PropFinder) finder){
	myRangeElement->checkRecorders(finder, this->sensorCrum());
}


void RegionLoaf::checkTrailBlazer (APTR(TrailBlazer) blazer){
	/* OK */
	BEGIN_CHOOSE(myRangeElement) {
		BEGIN_KIND(BePlaceHolder,p) {
			p->checkTrailBlazer(blazer);
		} END_KIND;
		BEGIN_OTHERS {
			
		} END_OTHERS;
	} END_CHOOSE;
}


void RegionLoaf::delayedStoreMatching (
		APTR(PropFinder) finder, 
		APTR(RecorderFossil) fossil, 
		APTR(ResultRecorder) recorder, 
		APTR(HashSetCache) OF1(HistoryCrum) hCrumCache)
{
	/* RegionLoaf is the one kind of o-leaf which actually shares 
	range-element identity with other o-leafs.  The range element 
	identity is in myRangeElement rather than myself, so I 
	override my super's version of this method to forward it 
	south one more step to myRangeElement. */
	
	recorder->delayedStoreMatching(myRangeElement, finder, fossil, hCrumCache);
}


RPTR(TrailBlazer) OR(NULL) RegionLoaf::fetchTrailBlazer (){
	BEGIN_CHOOSE(myRangeElement) {
		BEGIN_KIND(BePlaceHolder,p) {
			WPTR(TrailBlazer) OR(NULL) 	returnValue;
			returnValue = p->fetchTrailBlazer();
			return returnValue;
		} END_KIND;
		BEGIN_OTHERS {
			return NULL;
		} END_OTHERS;
	} END_CHOOSE;
}


void RegionLoaf::storeRecordingAgents (APTR(RecorderFossil) recorder, APTR(Agenda) agenda){
	recorder->storeRangeElementRecordingAgents(myRangeElement, myRangeElement->sensorCrum(), agenda);
}


BooleanVar RegionLoaf::testHChild (APTR(HistoryCrum) child){
	/* Return true if child is a child.  Used for debugging. */
	
	return (Heaper * ) myRangeElement->hCrum() == child;
}


void RegionLoaf::triggerDetector (APTR(FeFillRangeDetector) detect){
	if (!myRangeElement->isKindOf(cat_BePlaceHolder)) {
		detect->rangeFilled(this->asFeEdition());
	}
}


BooleanVar RegionLoaf::updateBCrumTo (APTR(BertCrum) newBCrum){
	/* My bertCrum must not be leafward of newBCrum. 
		Thus it must be LE to newCrum. Otherwise correct it and recur. */
	
	if (this->OExpandingLoaf::updateBCrumTo(newBCrum)) {
		myRangeElement->updateBCrumTo(newBCrum);
		return TRUE;
	}
	return FALSE;
}
/* protected: delete */


void RegionLoaf::dismantle (){
	BEGIN_CONSISTENT(4) {
		if (::isConstructed(myRangeElement)) {
			myRangeElement->removeOParent(this);
		}
		this->OExpandingLoaf::dismantle();
	} END_CONSISTENT;
}
/* testing */


UInt32 RegionLoaf::contentsHash (){
	return this->OExpandingLoaf::contentsHash() ^ myRangeElement->hashForEqual();
}



/* ************************************************************************ *
 * 
 *                    Class SharedData 
 *
 * ************************************************************************ */


/* accessing */


UInt32 SharedData::contentsHash (){
	return this->Abraham::contentsHash() ^ myData->contentsHash();
}


RPTR(Heaper) OR(NULL) SharedData::fetch (APTR(Position) key){
	WPTR(Heaper) OR(NULL) 	returnValue;
	returnValue = myData->fetchValue(myArrangement->indexOf(key).asLong());
	return returnValue;
}


void SharedData::fill (
		APTR(XnRegion) keys, 
		APTR(Arrangement) toArrange, 
		APTR(PrimArray) toArray, 
		APTR(Dsp) dsp)
{
	/* Transfer my data into the toArray mapping through my 
	arrangement and his arrangement. */
	
	if (!keys->isEmpty()) {
		toArrange->copyElements(toArray, dsp, myData, myArrangement, dsp->inverseOfAll(keys));
	}
}


RPTR(PrimSpec) SharedData::spec (){
	/* Return the primSpec for my data. */
	
	WPTR(PrimSpec) 	returnValue;
	returnValue = myData->spec();
	return returnValue;
}
/* creation */


SharedData::SharedData (APTR(PrimDataArray) data, APTR(Arrangement) arrange) {
	myData = data;
	myArrangement = arrange;
	if ( ! (myData->count() == myArrangement->region()->count().asLong()) ) {
		BLAST(Invalid_arrangement);
	}
	this->newShepherd();
	this->remember();
}



/* ************************************************************************ *
 * 
 *                    Class SplitLoaf 
 *
 * ************************************************************************ */


/* accessing */


RPTR(Mapping) SplitLoaf::compare (APTR(TracePosition) trace, APTR(XnRegion) region){
	/* return a mapping from my data to corresponding stuff in 
	the given trace */
	
	WPTR(Mapping) 	returnValue;
	returnValue = myIn->compare(trace, region->intersect(mySplit))->combine(myOut->compare(trace, region->minus(mySplit)));
	return returnValue;
}


IntegerVar SplitLoaf::count (){
	return myIn->count() + myOut->count();
}


RPTR(XnRegion) SplitLoaf::domain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myIn->domain()->unionWith(myOut->domain());
	return returnValue;
}


RPTR(FeRangeElement) OR(NULL) SplitLoaf::fetch (
		APTR(Position) key, 
		APTR(BeEdition) edition, 
		APTR(Position) globalKey)
{
	/* Look up the range element for the key.  If it is embedded 
	within a virtual
		 structure, then make a virtual range element using the 
	edition and globalKey. */
	
	if (mySplit->hasMember(key)) {
		WPTR(FeRangeElement) OR(NULL) 	returnValue;
		returnValue = myIn->fetch(key, edition, globalKey);
		return returnValue;
	} else {
		WPTR(FeRangeElement) OR(NULL) 	returnValue;
		returnValue = myOut->fetch(key, edition, globalKey);
		return returnValue;
	}
}


RPTR(OExpandingLoaf) SplitLoaf::fetchBottomAt (APTR(Position) key){
	/* Return the bottom-most Loaf.  Used to get the owner and 
	such of a position. */
	
	/* Thing to do !!!! */
	
	/* This should be splaying! */
	if (mySplit->hasMember(key)) {
		WPTR(OExpandingLoaf) 	returnValue;
		returnValue = myIn->fetchBottomAt(key);
		return returnValue;
	} else {
		WPTR(OExpandingLoaf) 	returnValue;
		returnValue = myOut->fetchBottomAt(key);
		return returnValue;
	}
}


RPTR(BeRangeElement) SplitLoaf::getBe (APTR(Position) key){
	/* Get or Make the BeRangeElement at the location. */
	
	/* Thing to do !!!! */
	
	/* This should be splaying! */
	if (mySplit->hasMember(key)) {
		WPTR(BeRangeElement) 	returnValue;
		returnValue = myIn->getBe(key);
		return returnValue;
	} else {
		WPTR(BeRangeElement) 	returnValue;
		returnValue = myOut->getBe(key);
		return returnValue;
	}
}


RPTR(Loaf) SplitLoaf::inPart (){
	/* This effectively copies the region represented by my distinction. */
	
	return (Loaf*) myIn;
}


BooleanVar SplitLoaf::isLeaf (){
	return FALSE;
}


RPTR(Loaf) SplitLoaf::outPart (){
	/* This is used by the splay algorithms. */
	
	return (Loaf*) myOut;
}


RPTR(XnRegion) SplitLoaf::rangeOwners (APTR(XnRegion) OR(NULL) positions){
	SPTR(XnRegion) result;
	
	if (positions == NULL) {
		WPTR(XnRegion) 	returnValue;
		returnValue = myIn->rangeOwners(NULL)->unionWith(myIn->rangeOwners(NULL));
		return returnValue;
	}
	result = IDSpace::global()->emptyRegion();
	if (mySplit->intersects(positions)) {
		result = myIn->rangeOwners(positions);
	}
	if (mySplit->complement()->intersects(positions)) {
		result = myIn->rangeOwners(positions)->unionWith(result);
	}
	WPTR(XnRegion) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(OrglRoot) SplitLoaf::setAllOwners (APTR(ID) owner){
	/* Recur assigning owners.  Return the portion of the o-tree 
	that couldn't be assigned. */
	
	SPTR(OrglRoot) in;
	SPTR(OrglRoot) out;
	
	in = myIn->setAllOwners(owner);
	out = myOut->setAllOwners(owner);
	if (in->isEmpty()) {
		WPTR(OrglRoot) 	returnValue;
		returnValue = out;
		return returnValue;
	}
	if (out->isEmpty()) {
		WPTR(OrglRoot) 	returnValue;
		returnValue = in;
		return returnValue;
	}
	{	BooleanVar crutch_Flag;
		/* CAST(ActualOrglRoot,in)->fullcrum() == myIn && CAST(ActualOrglRoot,out)->fullcrum() == myOut */
		
		crutch_Flag = CAST(ActualOrglRoot,in)->fullcrum() == myIn;
		if(crutch_Flag) {
			crutch_Flag = CAST(ActualOrglRoot,out)->fullcrum() == myOut;
		}
		if (crutch_Flag) {
			WPTR(OrglRoot) 	returnValue;
			returnValue = ActualOrglRoot::make (this, in->simpleDomain()->simpleUnion(out->simpleDomain()));
			return returnValue;
		}
	}
	WPTR(OrglRoot) 	returnValue;
	returnValue = CAST(ActualOrglRoot,in)->makeNew(mySplit, CAST(ActualOrglRoot,in), CAST(ActualOrglRoot,out));
	return returnValue;
}


RPTR(XnRegion) SplitLoaf::usedDomain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myIn->usedDomain()->unionWith(myOut->usedDomain());
	return returnValue;
}
/* operations */


RPTR(Stepper) SplitLoaf::bundleStepper (
		APTR(XnRegion) region, 
		APTR(OrderSpec) order, 
		APTR(Dsp) globalDsp)
{
	/* Return a stepper of bundles according to the order. */
	
	SPTR(XnRegion) local;
	SPTR(Stepper) in;
	SPTR(Stepper) out;
	
	local = globalDsp->inverseOfAll(region);
	in = out = NULL;
	if (mySplit->intersects(local)) {
		in = 
				myIn->bundleStepper(region, order, globalDsp);
	}
	if (mySplit->complement()->intersects(local)) {
		out = 
				myOut->bundleStepper(region, order, globalDsp);
	}
	if (in == NULL) {
		if (out == NULL) {
			WPTR(Stepper) 	returnValue;
			returnValue = Stepper::emptyStepper();
			return returnValue;
		} else {
			WPTR(Stepper) 	returnValue;
			returnValue = out;
			return returnValue;
		}
	} else {
		if (out == NULL) {
			WPTR(Stepper) 	returnValue;
			returnValue = in;
			return returnValue;
		} else {
			WPTR(Stepper) 	returnValue;
			returnValue = MergeBundlesStepper::make (in, out, order);
			return returnValue;
		}
	}
}


RPTR(OrglRoot) SplitLoaf::combine (
		APTR(ActualOrglRoot) another, 
		APTR(XnRegion) limitRegion, 
		APTR(Dsp) globalDsp)
{
	/* Break another into pieces according to mySplit, and combine
		 the corresponding pieces with my children transformed to global 
		 coordinates.  Combine the two non-overlapping results. */
	
	SPTR(ActualOrglRoot) newIn;
	SPTR(ActualOrglRoot) newOut;
	SPTR(OrglRoot) hisIn;
	SPTR(OrglRoot) hisOut;
	SPTR(XnRegion) globalIn;
	SPTR(XnRegion) globalOut;
	
	globalIn = globalDsp->ofAll(mySplit);
	globalOut = globalIn->complement();
	newIn = ActualOrglRoot::make (myIn->transformedBy(globalDsp), limitRegion->intersect(globalIn));
	newOut = ActualOrglRoot::make (myOut->transformedBy(globalDsp), limitRegion->intersect(globalOut));
	hisIn = another->copy(globalIn);
	hisOut = another->copy(globalOut);
	/* Can this assume that the results don't overlap? */
	WPTR(OrglRoot) 	returnValue;
	returnValue = newIn->makeNew(globalIn, CAST(ActualOrglRoot,newIn->combine(hisIn)), CAST(ActualOrglRoot,newOut->combine(hisOut)));
	return returnValue;
}


void SplitLoaf::fill (
		APTR(XnRegion) keys, 
		APTR(Arrangement) toArrange, 
		APTR(PrimArray) toArray, 
		APTR(Dsp) globalDsp, 
		APTR(BeEdition) edition)
{
	/* Make an FeRangeElement for each position. */
	
	myIn->fill(keys->intersect(mySplit), toArrange, toArray, globalDsp, edition);
	myOut->fill(keys->intersect(mySplit->complement()), toArrange, toArray, globalDsp, edition);
}


void SplitLoaf::informTo (APTR(OrglRoot) /* orgl */){
	/* Copy the enclosure in orgl appropriate for this crum, then 
	hand it down to the 
		subCrums. */
	
	/* orgl isKnownEmpty ifFalse:
				[myLeft informTo: ((orgl copy: leftWisp 
		externalRegion) unTransformedBy: leftWisp dsp).
				myRight informTo: ((orgl copy: rightWisp 
		externalRegion) unTransformedBy: rightWisp dsp)] */
	BLAST(NOT_YET_IMPLEMENTED);
}


RPTR(XnRegion) SplitLoaf::keysLabelled (APTR(BeLabel) label){
	/* Just search for now. */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = myIn->keysLabelled(label)->unionWith(myOut->keysLabelled(label));
	return returnValue;
}


RPTR(XnRegion) SplitLoaf::sharedRegion (APTR(TracePosition) trace, APTR(XnRegion) limitRegion){
	/* Return a region describing the stuff I share with the orgl 
	under trace. */
	
	if (this->hCrum()->inTrace(trace)) {
		WPTR(XnRegion) 	returnValue;
		returnValue = this->domain();
		return returnValue;
	} else {
		WPTR(XnRegion) 	returnValue;
		returnValue = myIn->sharedRegion(trace, limitRegion->intersect(mySplit))->unionWith(myOut->sharedRegion(trace, limitRegion->intersect(mySplit->complement())));
		return returnValue;
	}
}
/* printing */


void SplitLoaf::printOn (ostream& aStream){
	
	aStream << "(" << mySplit << ", " << myIn << ", " << myOut << ")";
}
/* create */


SplitLoaf::SplitLoaf (
		APTR(XnRegion) split, 
		APTR(Loaf) inLoaf, 
		APTR(Loaf) outLoaf) 

	: InnerLoaf(NULL, CAST(SensorCrum,inLoaf->sensorCrum()->computeJoin(outLoaf->sensorCrum()))) {
	myIn = inLoaf;
	myOut = outLoaf;
	mySplit = split;
	/* Connect the HTrees. */
	this->newShepherd();
	myIn->addOParent(this);
	myOut->addOParent(this);
}


SplitLoaf::SplitLoaf (
		APTR(XnRegion) split, 
		APTR(Loaf) inLoaf, 
		APTR(Loaf) outLoaf, 
		APTR(HUpperCrum) hcrum) 

	: InnerLoaf(hcrum, CAST(SensorCrum,inLoaf->sensorCrum()->computeJoin(outLoaf->sensorCrum()))) {
	myIn = inLoaf;
	myOut = outLoaf;
	mySplit = split;
	/* Connect the HTrees. */
	this->newShepherd();
	myIn->addOParent(this);
	myOut->addOParent(this);
}


SplitLoaf::SplitLoaf (
		APTR(XnRegion) split, 
		APTR(Loaf) inLoaf, 
		APTR(Loaf) outLoaf, 
		APTR(HUpperCrum) hcrum, 
		UInt32 hash) 

	: InnerLoaf(hash
		, hcrum
		, CAST(SensorCrum,inLoaf->sensorCrum()->computeJoin(outLoaf->sensorCrum()))) 
{
	myIn = inLoaf;
	myOut = outLoaf;
	mySplit = split;
	/* Connect the HTrees. */
	this->newShepherd();
	myIn->addOParent(this);
	myOut->addOParent(this);
}


SplitLoaf::SplitLoaf (
		APTR(XnRegion) split, 
		APTR(Loaf) inLoaf, 
		APTR(Loaf) outLoaf, 
		APTR(HUpperCrum) hcrum, 
		UInt32 hash, 
		APTR(FlockInfo) info) 

	: InnerLoaf(hash
		, hcrum
		, CAST(SensorCrum,inLoaf->sensorCrum()->computeJoin(outLoaf->sensorCrum()))) 
{
	/* Special constructor for becoming this class */
	
	myIn = inLoaf;
	myOut = outLoaf;
	mySplit = split;
	/* Connect the HTrees. */
	this->flockInfo(info);
	myIn->addOParent(this);
	myOut->addOParent(this);
	this->diskUpdate();
}
/* backfollow */


void SplitLoaf::addOParent (APTR(OPart) oparent){
	/* add oparent to the set of upward pointers and update the 
	bertCrums in 
		southern children. */
	
	SPTR(BertCrum) bCrum;
	SPTR(BertCrum) newBCrum;
	
	bCrum = this->hCrum()->bertCrum();
	this->InnerLoaf::addOParent(oparent);
	/* My bertCrum may have been changed by the last operation. */
	newBCrum = this->hCrum()->bertCrum();
	if (!bCrum->isLE(newBCrum)) {
		myIn->updateBCrumTo(newBCrum);
		myOut->updateBCrumTo(newBCrum);
	} else {
		if ( ! (newBCrum->isLE(bCrum)) ) {
			BLAST(unrelated_bertCrums___Call_dean_);
		}
	}
}


RPTR(XnRegion) SplitLoaf::attachTrailBlazer (APTR(TrailBlazer) blazer){
	WPTR(XnRegion) 	returnValue;
	returnValue = myIn->attachTrailBlazer(blazer)->unionWith(myOut->attachTrailBlazer(blazer));
	return returnValue;
}


void SplitLoaf::checkChildRecorders (APTR(PropFinder) finder){
	myIn->checkRecorders(finder, this->sensorCrum());
	myOut->checkRecorders(finder, this->sensorCrum());
}


void SplitLoaf::checkTrailBlazer (APTR(TrailBlazer) blazer){
	myIn->checkTrailBlazer(blazer);
	myOut->checkTrailBlazer(blazer);
}


void SplitLoaf::delayedStoreMatching (
		APTR(PropFinder) finder, 
		APTR(RecorderFossil) fossil, 
		APTR(ResultRecorder) recorder, 
		APTR(HashSetCache) OF1(HistoryCrum) hCrumCache)
{
	myIn->delayedStoreMatching(finder, fossil, recorder, hCrumCache);
	myOut->delayedStoreMatching(finder, fossil, recorder, hCrumCache);
}


RPTR(TrailBlazer) OR(NULL) SplitLoaf::fetchTrailBlazer (){
	SPTR(TrailBlazer) OR(NULL) result;
	
	result = myIn->fetchTrailBlazer();
	if (result != NULL) {
		WPTR(TrailBlazer) OR(NULL) 	returnValue;
		returnValue = result;
		return returnValue;
	} else {
		WPTR(TrailBlazer) OR(NULL) 	returnValue;
		returnValue = myOut->fetchTrailBlazer();
		return returnValue;
	}
}


void SplitLoaf::storeRecordingAgents (APTR(RecorderFossil) recorder, APTR(Agenda) agenda){
	myIn->storeRecordingAgents(recorder, agenda);
	myOut->storeRecordingAgents(recorder, agenda);
}


void SplitLoaf::triggerDetector (APTR(FeFillRangeDetector) detect){
	/* there is no partiality below me so I can just trigger it 
		with everything */
	if (this->sensorCrum()->isPartial()) {
		myIn->triggerDetector(detect);
		myOut->triggerDetector(detect);
	} else {
		detect->rangeFilled(this->asFeEdition());
	}
}


BooleanVar SplitLoaf::updateBCrumTo (APTR(BertCrum) newBCrum){
	/* My bertCrum must not be leafward of newBCrum. 
		Thus it must be LE to newCrum. Otherwise correct it and recur. */
	
	if (this->InnerLoaf::updateBCrumTo(newBCrum)) {
		myIn->updateBCrumTo(newBCrum);
		myOut->updateBCrumTo(newBCrum);
		return TRUE;
	}
	return FALSE;
}
/* protected: splay */


Int8 SplitLoaf::actualSplay (APTR(XnRegion) region, APTR(XnRegion) limitRegion){
	/* Make each child completely contained or completely outside
		 the region.  Return the number of children completely in the region. 
		 The transformation table follows:
	 #   in 	    out 	  return 	operation		rearrange
	1|	 0		0		0		none			none
	2|	 0		1		1		swap #4		(A (B* C)) -> (B* (A C))
	3|	 0		2		1		swap #7		(A B*) -> (B* A)
	4|	 1		0		1		rotateRight		((A* B) C) -> (A* (B C))
	5|	 1		1		1		interleave		((A* B) (C* D)) -> ((A* C*) (B D))
	6|	 1		2		1		swap #8		((A* B) C*) -> ((A* C*) B)
	7|	 2		0		1		none			none
	8|	 2		1		1		rotateLeft		(A* (B* C)) -> ((A* B*) C)
	9|	 2		2		2		none			none */
	
	UInt8 in;
	UInt8 out;
	
	/* For each child, compute the number of grandchildren 
	completely contained in region. */
	in = myIn->splay(region, mySplit->intersect(limitRegion));
	out = myOut->splay(region, mySplit->complement()->intersect(limitRegion));
	/* Swap the out and in sides if necessary to reduce the 
		number of cases. */
	BEGIN_CONSISTENT(19) {
		if (out > in) {
			UInt8 cnt;
			
			cnt = out;
			out = in;
			in = cnt;
			this->swapChildren();
		}
		/* The hard cases are when a child is partially 
			contained (in or out = 1).  For those
					 cases, construct the two new children, 
			then install them. */
			/* The non-rotating cases:
								^in==0 ifTrue: [0] ifFalse: [ out==0 
			ifTrue: [1] ifFalse: [2] ] */
			/* The 1 case here should change mySplit to 
			the incoming one. */
		{	BooleanVar crutch_Flag;
			/* in == 1 || out == 1 */
			
			crutch_Flag = in == 1;
			if(!crutch_Flag) {
				crutch_Flag = out == 1;
			}
			if (crutch_Flag) {
				SPTR(Loaf) newIn;
				SPTR(Loaf) newOut;
				
				if (out == Int0) {
					newIn = CAST(InnerLoaf,myIn)->inPart();
					newOut = this->makeNew(CAST(InnerLoaf,myIn)->outPart(), myOut);
				} else {
					if (in == 2) {
						newIn = this->makeNew(myIn, CAST(InnerLoaf,myOut)->inPart());
						newOut = CAST(InnerLoaf,myOut)->outPart();
					} else {
						newIn = this->makeNew(CAST(InnerLoaf,myIn)->inPart(), CAST(InnerLoaf,myOut)->inPart());
						newOut = this->makeNew(CAST(InnerLoaf,myIn)->outPart(), CAST(InnerLoaf,myOut)->outPart());
					}
				}
				/* The splayed region represents the 
					newDistinction for me in the 
					split cases. */
				this->install(newIn, newOut, region);
				return 1;
			} else {
				return (in + out) / 2;
			}
		}
	} END_CONSISTENT;
}
/* private: splay */


void SplitLoaf::install (
		APTR(Loaf) newIn, 
		APTR(Loaf) newOut, 
		APTR(XnRegion) newSplit)
{
	/* Install new in and out children at the same 
		 time. This will need to be in a critical section.  Add me as
		 parent to the new loaves first in case the only ent reference
		 to the new loaf is through one of my children (which might 
		 delete it if I'm *their* last reference). */
	
	newIn->addOParent(this);
	newOut->addOParent(this);
	myIn->removeOParent(this);
	myIn = newIn;
	myOut->removeOParent(this);
	myOut = newOut;
	mySplit = newSplit;
	/* Thing to do !!!! */
	
	/* This shouldn't update the disk if the swapChildren already did. */
	this->diskUpdate();
}


RPTR(Loaf) SplitLoaf::makeNew (APTR(Loaf) newIn, APTR(Loaf) newOut){
	/* Make a new crum to replace some existing crums during a splay 
		operation. The new crum must have the same trace as me to 
		guarantee the hTree property. Optimization: look at parents of the 
		new loaves to find a pre-existing parent with the same trace and 
		wisps. This will coalesce the shearing that splaying causes. */
	/* The new loaf is made from pieces of me, so they are 
	distinguished by my split. */
	
	WPTR(Loaf) 	returnValue;
	returnValue = InnerLoaf::make (mySplit, newIn, newOut, HUpperCrum::make (CAST(HUpperCrum,this->hCrum())));
	return returnValue;
}


void SplitLoaf::swapChildren (){
	/* This is a support for the splay routine. Swapping the children 
		reduces the number of cases. This way, if this crum is partially 
		in a region being splayed, the part contained in the region 
		resides in the left slot. */
	
	SPTR(Loaf) loaf;
	
	mySplit = mySplit->complement();
	loaf = myIn;
	myIn = myOut;
	myOut = loaf;
	/* Thing to do !!!! */
	
	/* Swapping may be expensive if it's
					unnecessary.  Check more cases in the splay routine. */
	this->diskUpdate();
}
/* protected: delete */


void SplitLoaf::dismantle (){
	BEGIN_CONSISTENT(4) {
		if (::isConstructed(myIn)) {
			myIn->removeOParent(this);
		}
		if (::isConstructed(myOut)) {
			myOut->removeOParent(this);
		}
		this->InnerLoaf::dismantle();
	} END_CONSISTENT;
}
/* testing */


UInt32 SplitLoaf::contentsHash (){
	return this->InnerLoaf::contentsHash() ^ mySplit->hashForEqual() ^ myIn->hashForEqual() ^ myOut->hashForEqual();
}

#ifndef LOAVESX_SXX
#include "loavesx.sxx"
#endif /* LOAVESX_SXX */


#ifndef LOAVESR_SXX
#include "loavesr.sxx"
#endif /* LOAVESR_SXX */


#ifndef LOAVESP_SXX
#include "loavesp.sxx"
#endif /* LOAVESP_SXX */



#endif /* LOAVESX_CXX */

