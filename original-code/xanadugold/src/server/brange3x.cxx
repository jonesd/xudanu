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

#ifndef BRANGE3X_CXX
#define BRANGE3X_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef BRANGE3X_HXX
#include "brange3x.hxx"
#endif /* BRANGE3X_HXX */

#ifndef BRANGE3X_IXX
#include "brange3x.ixx"
#endif /* BRANGE3X_IXX */

#ifndef BRANGE3P_HXX
#include "brange3p.hxx"
#endif /* BRANGE3P_HXX */

#ifndef BRANGE3P_IXX
#include "brange3p.ixx"
#endif /* BRANGE3P_IXX */


#ifndef BRANGE2X_HXX
#include "brange2x.hxx"
#endif /* BRANGE2X_HXX */

#ifndef CANOPYX_HXX
#include "canopyx.hxx"
#endif /* CANOPYX_HXX */

#ifndef CROSSX_HXX
#include "crossx.hxx"
#endif /* CROSSX_HXX */

#ifndef DETECTX_HXX
#include "detectx.hxx"
#endif /* DETECTX_HXX */

#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef ENTX_HXX
#include "entx.hxx"
#endif /* ENTX_HXX */

#ifndef FILTERX_HXX
#include "filterx.hxx"
#endif /* FILTERX_HXX */

#ifndef GRANMAPX_HXX
#include "granmapx.hxx"
#endif /* GRANMAPX_HXX */

#ifndef GRANTABX_HXX
#include "grantabx.hxx"
#endif /* GRANTABX_HXX */

#ifndef HTREEX_HXX
#include "htreex.hxx"
#endif /* HTREEX_HXX */

#ifndef IDX_HXX
#include "idx.hxx"
#endif /* IDX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef LOAVESX_HXX
#include "loavesx.hxx"
#endif /* LOAVESX_HXX */

#ifndef NKERNELX_HXX
#include "nkernelx.hxx"
#endif /* NKERNELX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */

#ifndef TABLESX_HXX
#include "tablesx.hxx"
#endif /* TABLESX_HXX */

#ifndef TCLUDEX_HXX
#include "tcludex.hxx"
#endif /* TCLUDEX_HXX */

#ifndef TRACEPX_HXX
#include "tracepx.hxx"
#endif /* TRACEPX_HXX */

#ifndef TURTLEX_HXX
#include "turtlex.hxx"
#endif /* TURTLEX_HXX */




/* ************************************************************************ *
 * 
 *                    Class BeEdition 
 *
 * ************************************************************************ */


/* creation */


RPTR(BeEdition) BeEdition::make (APTR(OrglRoot) oroot){
	BEGIN_CONSISTENT(5) {
		RETURN_CONSTRUCT(BeEdition,(oroot, tcsj));
	} END_CONSISTENT;
}
/* operations */


RPTR(BeEdition) BeEdition::combine (APTR(BeEdition) other){
	/* An Edition with the contents of both Editions; where they 
	share keys, they must have the same RangeElement. */
	
	if (other->isEmpty()) {
		return this;
	}
	if (this->isEmpty()) {
		WPTR(BeEdition) 	returnValue;
		returnValue = other;
		return returnValue;
	}
	/* Eventually trace coordinates should be delayed. */
	
	
	
	{	FLUID_BIND(CurrentTrace,this->hCrum()->hCut()->newSuccessorAfter(other->hCrum()->hCut())) {
			{	FLUID_BIND(CurrentBertCrum,BertCrum::make ()) {
					WPTR(BeEdition) 	returnValue;
					returnValue = BeEdition::make (myOrglRoot->combine(other->orglRoot()));
					return returnValue;
				}
			}
		}
	}
}


RPTR(BeEdition) BeEdition::copy (APTR(XnRegion) keys){
	/* A new Edition with the domain restricted to the given set 
	of keys. */
	
	{	FLUID_BIND(CurrentTrace,this->hCrum()->hCut()->newSuccessor()) {
			{	FLUID_BIND(CurrentBertCrum,BertCrum::make ()) {
					WPTR(BeEdition) 	returnValue;
					returnValue = BeEdition::make (myOrglRoot->copy(keys));
					return returnValue;
				}
			}
		}
	}
}


RPTR(BeEdition) BeEdition::replace (APTR(BeEdition) other){
	/* An Edition with the contents of both Editions; where they 
	share keys, use the contents of the other Edition. Equivalent to
			this->copy (other->domain ()->complement ())->combine (other) */
	
	/* Thing to do !!!! */
	
	/* This should be implemented directly. */
	WPTR(BeEdition) 	returnValue;
	returnValue = this->copy(other->domain()->complement())->combine(other);
	return returnValue;
}


RPTR(BeEdition) BeEdition::transformedBy (APTR(Mapping) mapping){
	/* An Edition with the keys transformed according to the 
	given Mapping. Where the Mapping takes several keys in the 
	domain to a single key in the range, this Edition must have 
	the same RangeElement at all the domain keys. */
	
	SPTR(OrglRoot) resultRoot;
	SPTR(XnRegion) domain;
	
	/* The rest of the method */
	BEGIN_CHOOSE(mapping) {
		BEGIN_KIND(Dsp,dsp) {
			if (dsp->isIdentity()) {
				return this;
			}
			{	FLUID_BIND(CurrentTrace,this->hCrum()->hCut()->newSuccessor()) {
					{	FLUID_BIND(CurrentBertCrum,BertCrum::make ()) {
							WPTR(BeEdition) 	returnValue;
							returnValue = BeEdition::make (myOrglRoot->transformedBy(dsp));
							return returnValue;
						}
					}
				}
			}
		} END_KIND;
		BEGIN_OTHERS {
			
		} END_OTHERS;
	} END_CHOOSE;
	{	FLUID_BIND(CurrentTrace,this->hCrum()->hCut()->newSuccessor()) {
			{	FLUID_BIND(CurrentBertCrum,BertCrum::make ()) {
					domain = myOrglRoot->simpleDomain();
					resultRoot = OrglRoot::make (mapping->rangeSpace());
					BEGIN_FOR_EACH(Mapping,simple,(mapping->simpleMappings()->stepper())) {
						SPTR(XnRegion) common;
						
						common = domain->intersect(simple->domain());
						if (!common->isEmpty()) {
							SPTR(Dsp) dsp;
							
							if ((dsp = simple->fetchDsp()) != NULL) {
								resultRoot = resultRoot->combine(myOrglRoot->copy(common)->transformedBy(dsp));
							} else {
								BLAST(NOT_YET_IMPLEMENTED);
							}
						}
					} END_FOR_EACH;
					WPTR(BeEdition) 	returnValue;
					returnValue = BeEdition::make (resultRoot);
					return returnValue;
				}
			}
		}
	}
}


RPTR(BeEdition) BeEdition::with (APTR(Position) key, APTR(BeCarrier) value){
	/* A new Edition with a RangeElement at a specified key. The 
	old value, if there is one, is superceded. Equivalent to
			this->replace (theServer ()->makeEditionWith (key, value)) */
	
	WPTR(BeEdition) 	returnValue;
	returnValue = this->replace(CurrentGrandMap.fluidGet()->newEditionWith(key, value));
	return returnValue;
}


RPTR(BeEdition) BeEdition::withAll (APTR(XnRegion) keys, APTR(BeCarrier) value){
	/* A new Edition with a RangeElement at a specified set of 
	keys. The old values, if there are any, are superceded. Equivalent to
			this->replace (theServer ()->makeEditionWithAll (keys, value)) */
	
	WPTR(BeEdition) 	returnValue;
	returnValue = this->replace(CurrentGrandMap.fluidGet()->newEditionWithAll(keys, value));
	return returnValue;
}


RPTR(BeEdition) BeEdition::without (APTR(Position) key){
	/* A new Edition without any RangeElement at a specified key. 
	The old value, if there is one, is removed. Equivalent to
			this->copy (key->asRegion ()->complement ()) */
	
	WPTR(BeEdition) 	returnValue;
	returnValue = this->copy(key->asRegion()->complement());
	return returnValue;
}


RPTR(BeEdition) BeEdition::withoutAll (APTR(XnRegion) keys){
	/* A new Edition without any RangeElements at the specified 
	keys. The old values, if there are any, are removed. Equivalent to
			this->copy (keys->complement ()) */
	
	WPTR(BeEdition) 	returnValue;
	returnValue = this->copy(keys->complement());
	return returnValue;
}
/* accessing */


RPTR(CoordinateSpace) BeEdition::coordinateSpace (){
	/* The space from which the keys of this Edition are taken. 
	Equivalent to
			this->domain ()->coordinateSpace () */
	
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = myOrglRoot->coordinateSpace();
	return returnValue;
}


IntegerVar BeEdition::count (){
	/* The number of keys in this Edition. Blasts if infinite. 
	Equivalent to
			this->domain ()->count () */
	
	return myOrglRoot->count();
}


RPTR(XnRegion) BeEdition::domain (){
	/* All the keys in this Edition. May be infinite, or empty. */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = myOrglRoot->domain();
	return returnValue;
}


RPTR(FeRangeElement) OR(NULL) BeEdition::fetch (APTR(Position) key){
	/* Create a front end representation for what is at the given key. */
	
	WPTR(FeRangeElement) OR(NULL) 	returnValue;
	returnValue = myOrglRoot->fetch(key, this);
	return returnValue;
}


RPTR(FeRangeElement) BeEdition::get (APTR(Position) key){
	/* The value at the given key, or blast if there is no such 
	key (i.e. if ! this->domain ()->hasMember (key)). */
	
	SPTR(FeRangeElement) OR(NULL) result;
	
	result = this->fetch(key);
	if (result == NULL) {
		BLAST(NotInTable);
	}
	WPTR(FeRangeElement) 	returnValue;
	returnValue = result;
	return returnValue;
}


BooleanVar BeEdition::includesKey (APTR(Position) key){
	/* Whether the given key is in the Edition. Equivalent to
			this->domain ()->hasMember (key) */
	
	return myOrglRoot->fetch(key, this) != NULL;
}


BooleanVar BeEdition::isEmpty (){
	/* Whether there are any keys in this Edition. Equivalent to
			this->domain ()->isEmpty () */
	
	return myOrglRoot->isEmpty();
}


BooleanVar BeEdition::isFinite (){
	/* Whether there is a finite number of keys in this Edition. 
	Equivalent to
			this->domain ()->isFinite () */
	
	{	BooleanVar crutch_Flag;
		/* myOrglRoot->simpleDomain()->isFinite() || myOrglRoot->domain()->isFinite() */
		
		crutch_Flag = myOrglRoot->simpleDomain()->isFinite();
		if(!crutch_Flag) {
			crutch_Flag = myOrglRoot->domain()->isFinite();
		}
		return crutch_Flag;
	}
}


BooleanVar BeEdition::isPurgeable (){
	{	BooleanVar crutch_Flag;
		/* this->BeRangeElement::isPurgeable() && myDetectors == NULL */
		
		crutch_Flag = this->BeRangeElement::isPurgeable();
		if(crutch_Flag) {
			crutch_Flag = myDetectors == NULL;
		}
		return crutch_Flag;
	}
}


RPTR(FeRangeElement) BeEdition::makeFe (APTR(BeLabel) OR(NULL) label){
	WPTR(FeRangeElement) 	returnValue;
	returnValue = FeEdition::on(this, FeLabel::on(label));
	return returnValue;
}


RPTR(IDRegion) BeEdition::rangeOwners (APTR(XnRegion) positions/* = NULL*/){
	/* The owners of all the RangeElements in the given Region, 
	or in the entire 
		Edition if no Region is specified. */
	
	return CAST(IDRegion,myOrglRoot->rangeOwners(positions));
}


RPTR(Stepper) OF1(Bundle) BeEdition::retrieve (
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
		If no Region is given, then reads out the whole thing. */
	
	SPTR(XnRegion) theRegion;
	SPTR(OrderSpec) theOrder;
	SPTR(Accumulator) result;
	
	/* Thing to do !!!! */
	
	/* The above comment is horribly insufficient. */
	/* Thing to do !!!! */
	
	/* This desperately needs to splay the region. */
	if (region == NULL) {
		theRegion = myOrglRoot->simpleDomain();
	} else {
		theRegion = region;
	}
	if (theRegion->isEmpty()) {
		WPTR(Stepper) OF1(Bundle) 	returnValue;
		returnValue = Stepper::emptyStepper();
		return returnValue;
	}
	if (order == NULL) {
		theOrder = theRegion->coordinateSpace()->getAscending();
	} else {
		theOrder = order;
	}
	/* generate everything at once to avoid problems with the 
		data structures changing as the client steps */
	result = Accumulator::ptrArray();
	BEGIN_FOR_EACH(Heaper,bundle,(myOrglRoot->bundleStepper(theRegion, theOrder))) {
		result->step(bundle);
	} END_FOR_EACH;
	WPTR(Stepper) OF1(Bundle) 	returnValue;
	returnValue = TableStepper::ascending(CAST(PtrArray,result->value()));
	return returnValue;
}


RPTR(FeRangeElement) BeEdition::theOne (){
	/* If this Edition has a single key, then the value at that 
	key; if not, blasts. Equivalent to
			this->get (this->domain ()->theOne ()) */
	
	WPTR(FeRangeElement) 	returnValue;
	returnValue = this->get(this->domain()->theOne());
	return returnValue;
}


RPTR(CrossRegion) BeEdition::visibleEndorsements (){
	/* All of the endorsements on this Edition and all Works 
	which the CurrentKeyMaster can read. */
	
	SPTR(XnRegion) result;
	
	result = myOwnProp->endorsements();
	BEGIN_FOR_EACH(BeWork,work,(myWorks->stepper())) {
		if (work->canBeReadBy(CurrentKeyMaster.fluidGet())) {
			result = result->unionWith(work->endorsements());
		}
	} END_FOR_EACH;
	return CAST(CrossRegion,result);
}
/* props */


void BeEdition::endorse (APTR(CrossRegion) endorsements){
	/* Adds to the endorsements on this Edition. The set of 
	endorsements must be a finite number of (club ID, token ID) pairs. */
	
	if (endorsements->isEmpty()) {
		return;
		
	}
	BEGIN_CONSISTENT(8) {
		this->propChange(PropChange::endorsementsChange(), BertProp::endorsementsProp(endorsements->unionWith(myProp->endorsements())));
	} END_CONSISTENT;
}


RPTR(CrossRegion) BeEdition::endorsements (){
	/* All of the endorsements on this Edition. */
	
	return CAST(CrossRegion,myOwnProp->endorsements());
}


RPTR(BertProp) BeEdition::prop (){
	return (BertProp*) myProp;
}


void BeEdition::propChange (APTR(PropChange) change, APTR(Prop) nw){
	SPTR(Prop) old;
	
	old = myOwnProp;
	if (!change->areEqualProps(old, nw)) {
		BEGIN_CONSISTENT(6) {
			myOwnProp = CAST(BertProp,change->changed(old, nw));
			this->diskUpdate();
			this->propChanged(change, old, nw);
		} END_CONSISTENT;
	}
}


void BeEdition::propChanged (
		APTR(PropChange) change, 
		APTR(Prop) old, 
		APTR(Prop) nw, 
		APTR(PropFinder) oldFinder/* = NULL*/)
{
	/* update props */
	
	SPTR(Prop) newProp;
	
	/* Attempt to apply the change directly to the current set of 
	properties.
		 If that removes some property
		 			look at all the berts to see if we get it from somewhere 
	else.  (BIG and not currently log.)
		 If the new properties are different than the old ones we 
	must change, so
		 		remember the current props
		 		In a consistent block
		 			change the props on the stamp
		 			change leaf of bert canopy and create an AgendaItem to 
	propagate the chage through bert canopy
		 			fetch a finder to look for recorders rung by this change in props
		 			See if permissions decrease:
		 				If so, recorders can't be rung.  Don't bother with 
	sensor canopy, just schedule bert canopy propagation.
		 				If not
		 					make an AgendaItem to check for recorders in the sensor canopy
		 					make and schedule a Sequencer to do the bert then the 
	sensor canopy AgendaItems. */
	newProp = change->changed(myProp, myOwnProp);
	newProp = change->with(newProp, nw);
	if (!change->areEqualProps(newProp, change->with(newProp, old))) {
		BEGIN_FOR_EACH(BeWork,work,(myWorks->stepper())) {
			/* Thing to do !!!! */
			
			/* Make it log. */
			newProp = change->with(newProp, work->localProp());
		} END_FOR_EACH;
	}
	if (!change->areEqualProps(myProp, newProp)) {
		SPTR(BertProp) before;
		SPTR(PropFinder) finder;
		SPTR(AgendaItem) changer;
		SPTR(AgendaItem) checker;
		
		before = myProp;
		BEGIN_CONSISTENT(9) {
			myProp = CAST(BertProp,newProp);
			this->diskUpdate();
			changer = myOrglRoot->propChanger(change);
			finder = 
					change->fetchFinder(before, myProp, this, oldFinder);
			if (finder == NULL) {
				changer->schedule();
			} else {
				checker = 
						SouthRecorderChecker::make (myOrglRoot, finder, CAST(SensorCrum,myOrglRoot->sensorCrum()->fetchParent()));
				if (oldFinder == NULL) {
					Sequencer::make (changer, checker)->schedule();
				} else {
					SPTR(AgendaItem) workChecker;
					
					workChecker = NorthRecorderChecker::make (this, finder);
					/* the sequence of 
						workChecker vs checker 
						doesn't matter */
					Sequencer::make (changer, Sequencer::make (workChecker, checker))->schedule();
				}
			}
		} END_CONSISTENT;
	}
}


void BeEdition::retract (APTR(CrossRegion) endorsements){
	/* Removes endorsements from this Edition. Ignores all 
	endorsements which you could have removed, but which don't 
	happen to be there right now. */
	
	if (endorsements->isEmpty()) {
		return;
		
	}
	BEGIN_CONSISTENT(4) {
		this->propChange(PropChange::endorsementsChange(), BertProp::endorsementsProp(myOwnProp->endorsements()->minus(endorsements)));
	} END_CONSISTENT;
}


RPTR(CrossRegion) BeEdition::totalEndorsements (){
	/* All of the endorsements on this Edition and all Works 
	directly on it */
	
	SPTR(XnRegion) result;
	
	result = myOwnProp->endorsements();
	BEGIN_FOR_EACH(BeWork,work,(myWorks->stepper())) {
		result = result->unionWith(work->endorsements());
	} END_FOR_EACH;
	return CAST(CrossRegion,result);
}
/* becoming */


void BeEdition::addDetector (APTR(FeFillRangeDetector) detect){
	/* Add a detector which will be triggered with a FeEdition 
	when a PlaceHolder becomes a non-PlaceHolder */
	
	if (myDetectors == NULL) {
		myDetectors = PrimSet::weak(7, BeEditionDetectorExecutor::make (this));
		this->propChange(PropChange::detectorWaitingChange(), BertProp::detectorWaitingProp());
	}
	myDetectors->introduce(detect);
	myOrglRoot->triggerDetector(detect);
}


RPTR(ID) BeEdition::ownerAt (APTR(Position) key){
	/* Return the owner for the given position in the receiver. */
	
	WPTR(ID) 	returnValue;
	returnValue = myOrglRoot->ownerAt(key);
	return returnValue;
}


void BeEdition::removeDetector (APTR(FeFillRangeDetector) detect){
	/* Remove a previously added detector */
	
	if (::isDestructed(myDetectors)) {
		return;
		
	}
	if (myDetectors == NULL) {
		BLAST(NeverAddedDetector);
	}
	/* Known bug !!!! */
	
	/* if we're in GC, we may be dealing with a partially 
		unconstructed web of objects */
	myDetectors->remove(detect);
	if (myDetectors->isEmpty()) {
		myDetectors = NULL;
		this->propChange(PropChange::detectorWaitingChange(), BertProp::make ());
	}
}


void BeEdition::removeLastDetector (){
	/* Notify the edition that there are no remaining detectors on it. */
	
	myDetectors = NULL;
	this->propChange(PropChange::detectorWaitingChange(), BertProp::make ());
}


void BeEdition::ringDetectors (APTR(FeEdition) newIdentities){
	/* Ring all my detectors with the given Edition as an argument */
	
	if (myDetectors != NULL) {
		BEGIN_FOR_EACH(FeFillRangeDetector,det,(myDetectors->stepper())) {
			det->rangeFilled(newIdentities);
		} END_FOR_EACH;
	}
}


RPTR(BeEdition) BeEdition::setRangeOwners (APTR(ID) newOwner, APTR(XnRegion) region){
	/* Changes the owner of all RangeElements; requires the 
	authority of the current owner.
		Returns the subset of this Edition whose owners did not get 
	changed because of lack of authority. */
	
	/* Known bug !!!! */
	
	/* Must be a loop in ServerLoop. */
	/* Thing to do !!!! */
	
	/* propagate region down through the algorithm? */
	{	FLUID_BIND(CurrentTrace,this->hCrum()->hCut()->newSuccessor()) {
			{	FLUID_BIND(CurrentBertCrum,BertCrum::make ()) {
					WPTR(BeEdition) 	returnValue;
					returnValue = BeEdition::make (myOrglRoot->copy(region)->setAllOwners(newOwner));
					return returnValue;
				}
			}
		}
	}
}


RPTR(Pair) OF1(BeEdition) BeEdition::tryAllBecome (APTR(BeEdition) newIdentities){
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
/* labelling */


RPTR(XnRegion) BeEdition::keysLabelled (APTR(BeLabel) label){
	/* The keys in this Edition at which there are Editions with 
	the given label. */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = myOrglRoot->keysLabelled(label);
	return returnValue;
}


RPTR(BeEdition) BeEdition::rebind (APTR(Position) key, APTR(BeEdition) edition){
	/* Replace the Edition at the given key, leaving the Label 
	the same. Equivalent to
			this->store (key, edition->labelled (CAST(FeEdition,this->ge
	t (key))->label ())) */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}
/* hooks: */


void BeEdition::restartE (APTR(Rcvr) /* rcvr */){
	myDetectors = NULL;
}
/* protected: */


RPTR(OrglRoot) BeEdition::orglRoot (){
	return (OrglRoot*) myOrglRoot;
}
/* be accessing */


void BeEdition::addOParent (APTR(Loaf) oparent){
	/* add oparent to the set of upward pointers.  Editions may
		 also have to propagate BertCrum change downward. */
	
	SPTR(BertCrum) bCrum;
	SPTR(BertCrum) newBCrum;
	
	
	bCrum = this->hCrum()->bertCrum();
	this->BeRangeElement::addOParent(oparent);
	newBCrum = this->hCrum()->bertCrum();
	if (!bCrum->isLE(newBCrum)) {
		myOrglRoot->updateBCrumTo(newBCrum);
	}
}


BooleanVar BeEdition::anyPasses (APTR(PropFinder) finder){
	SPTR(PropFinder) next;
	
	next = finder->findPast(this);
	{	BooleanVar crutch_Flag;
		/* next->isFull() || this->BeRangeElement::anyPasses(next) */
		
		crutch_Flag = next->isFull();
		if(!crutch_Flag) {
			crutch_Flag = this->BeRangeElement::anyPasses(next);
		}
		return crutch_Flag;
	}
}


void BeEdition::checkRecorders (APTR(PropFinder) finder, APTR(SensorCrum) OR(NULL) scrum){
	SPTR(PropFinder) newFinder;
	
	/* Get a new finder which remembers to check if recorders 
	will newly find me */
	newFinder = finder->findPast(this);
	/* replace endorsements with those in the prop */
		/* keep looking down, with my stamp as the new 
		reference point */
	if (!newFinder->isEmpty()) {
		/* Thing to do !!!! */
		
		/* Use the new finder to check all recorders beneath 
			me, checking whether they record all stamps 
			from me all the way up to the stamp passed in 
			as an argument */
		/* Known bug !!!! */
		
		/* using scrum's parent records things twice */
		SouthRecorderChecker::make (myOrglRoot, newFinder, CAST(SensorCrum,scrum->fetchParent()))->schedule();
	}
}


RPTR(ImmuSet) OF1(BeWork) BeEdition::currentWorks (){
	/* The Works currently on this Edition */
	
	WPTR(ImmuSet) OF1(BeWork) 	returnValue;
	returnValue = myWorks->asImmuSet();
	return returnValue;
}


RPTR(BeRangeElement) BeEdition::getOrMakeBe (APTR(Position) key){
	/* An actual, non-virtual FE range element at that key. Used 
	by become operation to get something to pass into 
	BeRangeElement::become () */
	
	WPTR(BeRangeElement) 	returnValue;
	returnValue = myOrglRoot->getBe(key);
	return returnValue;
}


void BeEdition::introduceWork (APTR(BeWork) work){
	/* A Work has been newly revised to point at me. */
	
	BEGIN_CONSISTENT(-1) {
		myWorks->introduce(work);
		this->diskUpdate();
		this->propChanged(PropChange::bertPropChange(), BertProp::make (), work->prop(), 
				PropChange::bertPropChange()->fetchFinder(BertProp::make (), work->prop(), work, NULL));
	} END_CONSISTENT;
	{	BooleanVar crutch_Flag;
		/* myWorks->count() >= 100 && !myWorks->isKindOf(cat_GrandHashSet) */
		
		crutch_Flag = myWorks->count() >= 100;
		if(crutch_Flag) {
			crutch_Flag = !myWorks->isKindOf(cat_GrandHashSet);
		}
		if (crutch_Flag) {
			SPTR(MuSet) newWorks;
			
			newWorks = GrandHashSet::make ();
			BEGIN_FOR_EACH(BeWork,b,(myWorks->stepper())) {
				newWorks->store(b);
			} END_FOR_EACH;
			BEGIN_CONSISTENT(1) {
				myWorks = newWorks;
				this->diskUpdate();
			} END_CONSISTENT;
		}
	}
}


void BeEdition::removeWork (APTR(BeWork) work){
	/* The Work is no longer onto this Edition.  Remove the backpointer. */
	
	BEGIN_CONSISTENT(-1) {
		myWorks->remove(work);
		this->diskUpdate();
		this->propChanged(PropChange::bertPropChange(), work->prop(), BertProp::make ());
	} END_CONSISTENT;
}


BooleanVar BeEdition::updateBCrumTo (APTR(BertCrum) newBCrum){
	/* My bertCrum must not be leafward of newBCrum. 
		Thus it must be LE to newCrum. Otherwise correct it and recur. */
	
	if (this->BeRangeElement::updateBCrumTo(newBCrum)) {
		myOrglRoot->updateBCrumTo(newBCrum);
		return TRUE;
	}
	return FALSE;
}
/* comparing */


RPTR(XnRegion) BeEdition::keysOf (APTR(FeRangeElement) value){
	/* All of the keys in this Edition at which the given 
	RangeElement can be found. Equivalent to
			this->sharedRegion (theServer ()->makeEditionWith (some 
	position, value)) */
	
	
	WPTR(XnRegion) 	returnValue;
	returnValue = this->sharedRegion(CurrentGrandMap.fluidGet()->newEditionWith(IntegerPos::zero(), value->carrier()));
	return returnValue;
}


RPTR(Mapping) BeEdition::mapSharedTo (APTR(BeEdition) other){
	/* A Mapping from each of the keys in this Edition to all of 
	the keys in the other Edition which have the same RangeElement. */
	
	WPTR(Mapping) 	returnValue;
	returnValue = myOrglRoot->mapSharedTo(other->hCrum()->hCut());
	return returnValue;
}


RPTR(BeEdition) BeEdition::notSharedWith (APTR(BeEdition) other, Int32 flags/* = Int32Zero*/){
	/* The subset of this Edition whose RangeElements are not in 
	the other Edition. Equivalent to
			this->copy (this->sharedRegion (other, flags)->complement ()) */
	
	WPTR(BeEdition) 	returnValue;
	returnValue = this->copy(this->sharedRegion(other, flags)->complement());
	return returnValue;
}


RPTR(XnRegion) BeEdition::sharedRegion (APTR(BeEdition) other, Int32 flags/* = Int32Zero*/){
	/* The subset of the keys of this Edition which  have 
	RangeElements that are in the other Edition. If both flags 
	are false, then equivalent to
			this->mapSharedTo (other)->domain ()
		If nestThis, then returns not only keys of RangeElements 
	which are in the other, but also keys of Editions which lead 
	to RangeElements which are in the other.
		If nestOther, then looks not only for RangeElements which 
	are values of the other Edition, but also those which are 
	values of sub-Editions of the other Edition. (This option 
	will probably not be supported in version 1.0) */
	
	if (flags != Int32Zero) {
		BLAST(NOT_YET_IMPLEMENTED);
	}
	WPTR(XnRegion) 	returnValue;
	returnValue = myOrglRoot->sharedRegion(other->hCrum()->hCut());
	return returnValue;
}


RPTR(BeEdition) BeEdition::sharedWith (APTR(BeEdition) other, Int32 flags/* = Int32Zero*/){
	/* The subset of this Edition whose RangeElements are in the 
	other Edition. If the same RangeElement is in this Edition at 
	several different keys, all keys will be in the result 
	(provided the RangeElement is also in the other Edition). Equivalent to
			this->copy (this->sharedRegion (other, flags)) */
	
	WPTR(BeEdition) 	returnValue;
	returnValue = this->copy(this->sharedRegion(other, flags));
	return returnValue;
}


RPTR(BeEdition) BeEdition::works (
		APTR(IDRegion) permissions, 
		APTR(Filter) endorsementsFilter, 
		Int32 flags)
{
	SPTR(Accumulator) result;
	SPTR(IDSpace) iDSpace;
	SPTR(XnRegion) region;
	
	if (!(flags == (FeEdition::LOCAL_PRESENT_ONLY() | FeEdition::DIRECT_CONTAINERS_ONLY()))) {
		WPTR(BeEdition) 	returnValue;
		returnValue = this->BeRangeElement::works(permissions, endorsementsFilter, flags);
		return returnValue;
	}
	result = Accumulator::ptrArray();
	BEGIN_FOR_EACH(BeWork,work,(myWorks->stepper())) {
		if (endorsementsFilter->match(work->endorsements())) {
			result->step(work->makeFe(NULL));
		}
	} END_FOR_EACH;
	iDSpace = CurrentGrandMap.fluidGet()->newIDSpace();
	region = iDSpace->newIDs(CAST(PtrArray,result->value())->count());
	WPTR(BeEdition) 	returnValue;
	returnValue = CurrentGrandMap.fluidGet()->newPlaceHolders(region->complement())->combine(
			CurrentGrandMap.fluidGet()->newValueEdition(CAST(PtrArray,result->value()), region, iDSpace->ascending()));
	return returnValue;
}
/* creation */


BeEdition::BeEdition (APTR(OrglRoot) root, TCSJ) 
	: BeRangeElement(root->sensorCrum(), tcsj) {
	/* Known bug !!!! */
	
	/* this should not have the same SensorCrum as my OrglRoot */
	myOrglRoot = root;
	myWorks = MuSet::make ();
	/* This should maybe just start out NULL. */
	myOwnProp = myProp = BertProp::make ();
	myDetectors = NULL;
	BEGIN_CONSISTENT(5) {
		myOrglRoot->introduceEdition(this);
		this->newShepherd();
	} END_CONSISTENT;
}


void BeEdition::dismantle (){
	/* 2 with: (need to recalculate for adding propChange) */
	BEGIN_CONSISTENT(-1) {
		this->propChange(PropChange::bertPropChange(), BertProp::make ());
		if (::isConstructed(myOrglRoot)) {
			myOrglRoot->removeEdition(this);
		}
		myOrglRoot = NULL;
		this->BeRangeElement::dismantle();
	} END_CONSISTENT;
}
/* printing */


void BeEdition::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myOrglRoot << ")";
}
/* transclusions */


RPTR(XnRegion) BeEdition::attachTrailBlazer (APTR(TrailBlazer) blazer){
	/* Attach the TrailBlazer to this Edition, and return the 
	region of partiality it is attached to */
	
	WPTR(XnRegion) 	returnValue;
	returnValue = myOrglRoot->attachTrailBlazer(blazer);
	return returnValue;
}


void BeEdition::fossilRelease (APTR(RecorderFossil) oldGrabber){
	/* myGrabbersFossil == NULL ifTrue:
				[Heaper BLAST: #NotGrabbed]
			ifFalse: [myGrabbersFossil ~~ oldGrabber ifTrue:
				[Heaper BLAST: #WhoIsReleasingMe]
			ifFalse:
				[DiskManager consistent: 2 with:
					[myGrabbersFossil := NULL.
					oldGrabber extinguish: self.
					self diskUpdate]]] */
	/* MarkM -- Thing to do !!!! */
	
}


RPTR(TrailBlazer) BeEdition::getOrMakeTrailBlazer (){
	/* Get or make a TrailBlazer for recording results into this 
	Edition. Blast if there is already more than one */
	
	SPTR(TrailBlazer) result;
	
	result = myOrglRoot->fetchTrailBlazer();
	if (result == NULL) {
		WPTR(TrailBlazer) 	returnValue;
		returnValue = TrailBlazer::make (this);
		return returnValue;
	}
	myOrglRoot->checkTrailBlazer(result);
	WPTR(TrailBlazer) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(BeEdition) BeEdition::rangeTranscluders (
		APTR(XnRegion) OR(NULL) region, 
		APTR(Filter) directFilter, 
		APTR(Filter) indirectFilter, 
		Int32 flags, 
		APTR(BeEdition) OR(NULL) otherTrail)
{
	/* See FeEdition */
	
	SPTR(RecorderFossil) fossil;
	SPTR(BeEdition) result;
	
	/* Reject all the unimplemented cases.
		
		if a trail isn't given
			make a new one
		else
			use it as the result.
			
		Make a fossilized recorder 
			snapshotting the current login authority
			filtered by the endorsementsFilter
			for recording into the trail
		Set the transclusions request in motion
		Return the trail */
	if ((flags & ~(FeEdition::DIRECT_CONTAINERS_ONLY() | FeEdition::LOCAL_PRESENT_ONLY())) != Int32Zero) {
		BLAST(NOT_YET_IMPLEMENTED);
	}
	if (otherTrail == NULL) {
		result = CurrentGrandMap.fluidGet()->newPlaceHolders(CurrentGrandMap.fluidGet()->newIDSpace()->fullRegion());
	} else {
		result = otherTrail;
	}
	fossil = 
			RecorderFossil::transcluders((flags & FeEdition::DIRECT_CONTAINERS_ONLY()) != Int32Zero, CurrentKeyMaster.fluidFetch()->loginAuthority(), directFilter, indirectFilter, result->getOrMakeTrailBlazer());
	if ((flags & FeEdition::LOCAL_PRESENT_ONLY()) != Int32Zero) {
		this->scheduleImmediateBackfollow(fossil, region);
	} else {
		if ((flags & FeEdition::DIRECT_CONTAINERS_ONLY()) != Int32Zero) {
			BLAST(NOT_YET_IMPLEMENTED);
		}
		this->scheduleDelayedBackfollow(fossil, region);
	}
	WPTR(BeEdition) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(BeEdition) BeEdition::rangeWorks (
		APTR(XnRegion) OR(NULL) region, 
		APTR(Filter) filter, 
		Int32 flags, 
		APTR(BeEdition) OR(NULL) otherTrail)
{
	/* See FeEdition */
	
	SPTR(RecorderFossil) fossil;
	SPTR(BeEdition) result;
	
	/* Reject all the unimplemented cases.
		
		if a trail isn't given
			make a new one
		else
			use it as the result.
			
		Make a fossilized recorder 
			snapshotting the current login authority
			filtered by the endorsementsFilter
			for recording into the trail
		Set the transclusions request in motion
		Return the trail */
	if ((flags & ~(FeEdition::DIRECT_CONTAINERS_ONLY() | FeEdition::LOCAL_PRESENT_ONLY())) != Int32Zero) {
		BLAST(NOT_YET_IMPLEMENTED);
	}
	if (otherTrail == NULL) {
		result = CurrentGrandMap.fluidGet()->newPlaceHolders(CurrentGrandMap.fluidGet()->newIDSpace()->fullRegion());
	} else {
		result = otherTrail;
	}
	fossil = 
			RecorderFossil::works((flags & FeEdition::DIRECT_CONTAINERS_ONLY()) != Int32Zero, CurrentKeyMaster.fluidGet()->loginAuthority(), filter, result->getOrMakeTrailBlazer());
	if ((flags & FeEdition::LOCAL_PRESENT_ONLY()) != Int32Zero) {
		this->scheduleImmediateBackfollow(fossil, region);
	} else {
		if ((flags & FeEdition::DIRECT_CONTAINERS_ONLY()) != Int32Zero) {
			BLAST(NOT_YET_IMPLEMENTED);
		}
		this->scheduleDelayedBackfollow(fossil, region);
	}
	WPTR(BeEdition) 	returnValue;
	returnValue = result;
	return returnValue;
}


void BeEdition::scheduleDelayedBackfollow (APTR(RecorderFossil) fossil, APTR(XnRegion) OR(NULL) region){
	/* Walk down orgl's O-tree (onto range elements of interest) 
	planting pointers to a Fossil of BackfollowRecorder in the 
	sensor canopy and collecting agenda items to propagate their 
	endorsement and permission filtering info rootward in the 
	sensor canopy.
		Create and schedule a structure of AgendaItems to:
			- First:  Do the filtering info propagation.
			- Second: Find and record any currently matching stamps.
		
		This is done in this order so collection of the future part 
	of recorder information is completed before the present part 
	is extracted, keeping significant information from falling 
	through the crack. */
	
	SPTR(Agenda) rAgents;
	SPTR(AgendaItem) matcher;
	SPTR(OrglRoot) oroot;
	
	/* Create an empty Agenda.
		Do the walk and collect PropChangers in the new Agenda.
		Reanimate the Fossil long enough to
			make a Matcher AgendaItem
				from the filtering information extracted from the Fossil
		Make and schedule a Sequencer that first runs the Agenda 
	that propagates filtering info, then runs the Matcher. */
	if (fossil->isExtinct()) {
		return;
		
	}
	rAgents = Agenda::make ();
	if (region == NULL) {
		oroot = myOrglRoot;
	} else {
		{	FLUID_BIND(CurrentTrace,this->hCrum()->hCut()->newSuccessor()) {
				{	FLUID_BIND(CurrentBertCrum,BertCrum::make ()) {
						oroot = myOrglRoot->copy(region);
					}
				}
			}
		}
	}
	oroot->storeRecordingAgents(fossil, rAgents);
	BEGIN_REANIMATE(fossil,ResultRecorder,recorder) {
		matcher = 
				Matcher::make (oroot, recorder->bertPropFinder(), fossil);
	} END_REANIMATE;
	Sequencer::make (rAgents, matcher)->schedule();
}


void BeEdition::scheduleImmediateBackfollow (APTR(RecorderFossil) fossil, APTR(XnRegion) OR(NULL) region){
	/* Find and record any currently matching Editions. */
	
	SPTR(OrglRoot) oroot;
	
	/* MarkM -- Thing to do !!!! */
	
	/* When we are actually leaving AgendaItems on the queue, 
		make sure that all necessary canopy propagation is 
		done before the Matcher excutes */
	if (region == NULL) {
		oroot = myOrglRoot;
	} else {
		{	FLUID_BIND(CurrentTrace,this->hCrum()->hCut()->newSuccessor()) {
				{	FLUID_BIND(CurrentBertCrum,BertCrum::make ()) {
						oroot = myOrglRoot->copy(region);
					}
				}
			}
		}
	}
	BEGIN_REANIMATE(fossil,ResultRecorder,recorder) {
		Matcher::make (oroot, recorder->bertPropFinder(), fossil)->schedule();
	} END_REANIMATE;
}



/* ************************************************************************ *
 * 
 *                    Class BeEditionDetectorExecutor 
 *
 * ************************************************************************ */


/* creation */


RPTR(XnExecutor) BeEditionDetectorExecutor::make (APTR(BeEdition) edition){
	RETURN_CONSTRUCT(BeEditionDetectorExecutor,(edition, tcsj));
}
/* This class notifies its edition when its last detector has gone. */


/* protected: create */


BeEditionDetectorExecutor::BeEditionDetectorExecutor (APTR(BeEdition) edition, TCSJ) {
	myEdition = edition;
}
/* execute */


void BeEditionDetectorExecutor::execute (Int32 arg){
	if (arg == Int32Zero) {
		myEdition->removeLastDetector();
	}
}

#ifndef BRANGE3X_SXX
#include "brange3x.sxx"
#endif /* BRANGE3X_SXX */


#ifndef BRANGE3P_SXX
#include "brange3p.sxx"
#endif /* BRANGE3P_SXX */



#endif /* BRANGE3X_CXX */

