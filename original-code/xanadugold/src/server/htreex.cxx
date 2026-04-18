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

#ifndef HTREEX_CXX
#define HTREEX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef HTREEX_HXX
#include "htreex.hxx"
#endif /* HTREEX_HXX */

#ifndef HTREEX_IXX
#include "htreex.ixx"
#endif /* HTREEX_IXX */


#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef ENTX_HXX
#include "entx.hxx"
#endif /* ENTX_HXX */

#ifndef NKERNELX_HXX
#include "nkernelx.hxx"
#endif /* NKERNELX_HXX */

#ifndef OROOTX_HXX
#include "orootx.hxx"
#endif /* OROOTX_HXX */

#ifndef PROPSX_HXX
#include "propsx.hxx"
#endif /* PROPSX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */

#ifndef TCLUDEX_HXX
#include "tcludex.hxx"
#endif /* TCLUDEX_HXX */




/* ************************************************************************ *
 * 
 *                    Class HistoryCrum 
 *
 * ************************************************************************ */



/* Initializers for HistoryCrum */

UInt32 HistoryCrum::SequenceNumber = UInt32Zero;


/* Initializers for HistoryCrum */



/* accessing */


UInt32 HistoryCrum::nextHistoryCrumSequenceNumber (){
	/* Shepherds use a sequence number for their hash.  Return the next one
		 and increment.  This should actually do spread the hashes. */
	/* This actually needs to roll over the UInt32 limit. */
	
	/* 2^27-1 */
	HistoryCrum::SequenceNumber = HistoryCrum::SequenceNumber + 1 & 134217727;
	return HistoryCrum::SequenceNumber;
}
/* invariant:  the parent's trace >= the child's trace

The subclasses should differentiate between the number 
of children:  0, 1, or more.  ORoots have 0 children and 
always have a canopyCrum.  HCrums for OCrums in the 
body of the ent have one child if they are at the top 
of an unshared subtreee, and more if they are at the top 
of a shared subtree.  HCrums with more than one child 
almost always have a canopyCrum to represent the join 
between the canopies of their multiple hchildren.

The change would make the updateH method return a 
new crum, which the oCrums would install.

They don't do so now because I'm not sure if a crum with 
no parents can appear in the middle of the ent.  If so, then 
the version compare operations would gag.  Hmmm.  The 
change doesn't make any difference for that.... */


/* deferred filtering */
/* filtering */


void HistoryCrum::delayedStoreBackfollow (
		APTR(PropFinder) finder, 
		APTR(RecorderFossil) fossil, 
		APTR(ResultRecorder) recorder, 
		APTR(HashSetCache) OF1(HistoryCrum) hCrumCache)
{
	/* Do the northward H-tree walk for the 'now' part of a backfollow. */
	
	/* Check cache, call polymorphic actualDelayedStoreBackfollow 
	if miss. */
	if (!hCrumCache->hasMember(this)) {
		hCrumCache->store(this);
		this->actualDelayedStoreBackfollow(finder, fossil, recorder, hCrumCache);
	}
}
/* testing */


UInt32 HistoryCrum::actualHashForEqual (){
	return myHash;
}


BooleanVar HistoryCrum::isEqual (APTR(Heaper) other){
	return this == other;
}
/* create */


HistoryCrum::HistoryCrum () {
	myHash = HistoryCrum::nextHistoryCrumSequenceNumber();
}
/* deferred testing */
/* deferred accessing */
/* deferred updating */



/* ************************************************************************ *
 * 
 *                    Class   HUpperCrum 
 *
 * ************************************************************************ */


/* instance creation */


RPTR(HUpperCrum) HUpperCrum::make (){
	
	BEGIN_CONSISTENT(-1) {
		RETURN_CONSTRUCT(HUpperCrum,(CurrentTrace.fluidGet(), CurrentBertCrum.fluidGet()));
	} END_CONSISTENT;
	/* Compiler fodder */
	return NULL;
}


RPTR(HUpperCrum) HUpperCrum::make (APTR(BertCrum) bertCrum){
	RETURN_CONSTRUCT(HUpperCrum,(CurrentTrace.fluidGet(), bertCrum));
}


RPTR(HUpperCrum) HUpperCrum::make (APTR(HUpperCrum) hcrum){
	RETURN_CONSTRUCT(HUpperCrum,(hcrum->hCut(), hcrum->bertCrum()));
}
/* testing */


BooleanVar HUpperCrum::inTrace (APTR(TracePosition) trace){
	/* Return true if the receiver can backfollow to trace. */
	/* This chase up the htree could terminate early if the trace equalled 
		the trace in the receiver. This would be correct except that 
		oplanes can be created with a particular trace, only part of which 
		actually get included in the real orgl with that trace. */
	
	if (hcut->isLE(trace)) {
		BEGIN_FOR_EACH(OPart,oc,(hcrums->stepper())) {
			if (oc->hCrum()->inTrace(trace)) {
				return TRUE;
			}
		} END_FOR_EACH;
	}
	return FALSE;
}


BooleanVar HUpperCrum::isEmpty (){
	/* Return true if their are no upward pointers.  This is used
		 by OParts to determine if they can be forgotten. */
	
	return hcrums->isEmpty();
}


BooleanVar HUpperCrum::propagateBCrum (APTR(BertCrum) newBCrum){
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


RPTR(BertCrum) HUpperCrum::bertCrum (){
	/* find the canopyCrum that goes with this hCrum. */
	
	return (BertCrum*) myBertCrum;
}


RPTR(TracePosition) HUpperCrum::hCut (){
	return (TracePosition*) hcut;
}


RPTR(Mapping) HUpperCrum::mappingTo (APTR(TracePosition) trace, APTR(Mapping) initial){
	/* return the mapping into the domain space of the given trace */
	
	SPTR(Mapping) result;
	
	result = Mapping::make (initial->coordinateSpace(), initial->rangeSpace());
	if (this->inTrace(trace)) {
		BEGIN_FOR_EACH(OPart,each,(hcrums->stepper())) {
			result = result->combine(each->mappingTo(trace, initial));
		} END_FOR_EACH;
	}
	WPTR(Mapping) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(ImmuSet) OF1(OPart) HUpperCrum::oParents (){
	WPTR(ImmuSet) OF1(OPart) 	returnValue;
	returnValue = hcrums->asImmuSet();
	return returnValue;
}
/* updating */


void HUpperCrum::addOParent (APTR(OPart) newCrum){
	/* If this hcrum represents a fork, then it must get its own 
	canopy crum. */
	/* This routine could be drastically improved for orgl creation. */
	
	/* Hack !!!! */
	
	
	this->updateBertCanopy(newCrum->hCrum()->bertCrum());
	hcrums->store(newCrum);
}


void HUpperCrum::removeOParent (APTR(OPart) newCrum){
	/* Make a history crum with no upward pointers. */
	
	hcrums->remove(newCrum);
}
/* filtering */


void HUpperCrum::actualDelayedStoreBackfollow (
		APTR(PropFinder) finder, 
		APTR(RecorderFossil) fossil, 
		APTR(ResultRecorder) recorder, 
		APTR(HashSetCache) OF1(HistoryCrum) hCrumCache)
{
	/* Apply filter on canopy */
	
	SPTR(PropFinder) newFinder;
	
	/* Simplify finder (to cut out no longer reachable tests). */
	newFinder = finder->pass(myBertCrum);
	/* If things are still findable, recur on each child. */
	if (!newFinder->isEmpty()) {
		BEGIN_FOR_EACH(OPart,loaf,(hcrums->stepper())) {
			loaf->hCrum()->delayedStoreBackfollow(newFinder, fossil, recorder, hCrumCache);
		} END_FOR_EACH;
	}
}


BooleanVar HUpperCrum::anyPasses (APTR(PropFinder) finder){
	if (finder->doesPass(myBertCrum)) {
		BEGIN_FOR_EACH(OPart,loaf,(hcrums->stepper())) {
			if (loaf->hCrum()->anyPasses(finder)) {
				return TRUE;
			}
		} END_FOR_EACH;
	}
	return FALSE;
}


void HUpperCrum::ringDetectors (APTR(FeEdition) edition){
	if (this->bertCrum()->isSensorWaiting()) {
		BEGIN_FOR_EACH(OPart,o,(this->oParents()->stepper())) {
			o->hCrum()->ringDetectors(edition);
		} END_FOR_EACH;
	}
}
/* private: */


void HUpperCrum::updateBertCanopy (APTR(BertCrum) bCrum){
	/* Make my bertCrum the join of its current value and bCrum. */
	
	if (!myBertCrum->isLE(bCrum)) {
		SPTR(BertCrum) oldBCrum;
		
		oldBCrum = myBertCrum;
		myBertCrum = CAST(BertCrum,myBertCrum->computeJoin(bCrum));
		if ((BertCrum * ) myBertCrum != (BertCrum * ) oldBCrum) {
			myBertCrum->addPointer(this);
			oldBCrum->removePointer(this);
		}
	}
}
/* create */


HUpperCrum::HUpperCrum (APTR(TracePosition) trace, APTR(BertCrum) canopy) {
	hcut = trace;
	myBertCrum = canopy;
	myBertCrum->addPointer(this);
	hcrums = MuSet::make ();
}


HUpperCrum::HUpperCrum (
		APTR(OPart) first, 
		APTR(OPart) second, 
		APTR(TracePosition) trace) 
{
	SPTR(MuSet) set;
	
	hcut = trace;
	/* self halt. */
	set = MuSet::make (2);
	set->introduce(first);
	set->introduce(second);
	hcrums = set;
	myBertCrum = first->hCrum()->bertCrum();
	this->updateBertCanopy(second->hCrum()->bertCrum());
	myBertCrum->addPointer(this);
}

#ifndef HTREEX_SXX
#include "htreex.sxx"
#endif /* HTREEX_SXX */



#endif /* HTREEX_CXX */

