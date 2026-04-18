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

#ifndef TCLUDEX_CXX
#define TCLUDEX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef TCLUDEX_HXX
#include "tcludex.hxx"
#endif /* TCLUDEX_HXX */

#ifndef TCLUDEX_IXX
#include "tcludex.ixx"
#endif /* TCLUDEX_IXX */

#ifndef TCLUDEP_HXX
#include "tcludep.hxx"
#endif /* TCLUDEP_HXX */

#ifndef TCLUDEP_IXX
#include "tcludep.ixx"
#endif /* TCLUDEP_IXX */


#ifndef BRANGE2X_HXX
#include "brange2x.hxx"
#endif /* BRANGE2X_HXX */

#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef FLKINFOX_HXX
#include "flkinfox.hxx"
#endif /* FLKINFOX_HXX */

#ifndef GRANMAPX_HXX
#include "granmapx.hxx"
#endif /* GRANMAPX_HXX */

#ifndef HTREEX_HXX
#include "htreex.hxx"
#endif /* HTREEX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef PROPSP_HXX
#include "propsp.hxx"
#endif /* PROPSP_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */




/* ************************************************************************ *
 * 
 *                    Class HashSetCache 
 *
 * ************************************************************************ */


/* pseudo-constructors */


RPTR(HashSetCache) HashSetCache::make (){
	RETURN_CONSTRUCT(HashSetCache,(10, tcsj));
}


RPTR(HashSetCache) HashSetCache::make (UInt32 size){
	RETURN_CONSTRUCT(HashSetCache,(size, tcsj));
}
/* accessing */


BooleanVar HashSetCache::hasMember (APTR(Heaper) aHeaper){
	register UInt32 index;
	SPTR(Heaper) OR(NULL) val;
	
	index = aHeaper->hashForEqual() % mySize;
	{	BooleanVar crutch_Flag;
		/* index < UInt32Zero || index >= mySize */
		
		crutch_Flag = index < UInt32Zero;
		if(!crutch_Flag) {
			crutch_Flag = index >= mySize;
		}
		if (crutch_Flag) {
			BLAST(ModuloFailed);
		}
	}
	val = myElements->fetch(index);
	{	BooleanVar crutch_Flag;
		/* val != NULL && aHeaper->isEqual(val) */
		
		crutch_Flag = val != NULL;
		if(crutch_Flag) {
			crutch_Flag = aHeaper->isEqual(val);
		}
		return crutch_Flag;
	}
}


void HashSetCache::store (APTR(Heaper) aHeaper){
	register UInt32 index;
	
	index = aHeaper->hashForEqual() % mySize;
	{	BooleanVar crutch_Flag;
		/* index < UInt32Zero || index >= mySize */
		
		crutch_Flag = index < UInt32Zero;
		if(!crutch_Flag) {
			crutch_Flag = index >= mySize;
		}
		if (crutch_Flag) {
			BLAST(ModuloFailed);
		}
	}
	myElements->store(index, aHeaper);
}


void HashSetCache::wipe (APTR(Heaper) aHeaper){
	register UInt32 index;
	SPTR(Heaper) OR(NULL) val;
	
	index = aHeaper->hashForEqual() % mySize;
	{	BooleanVar crutch_Flag;
		/* index < UInt32Zero || index >= mySize */
		
		crutch_Flag = index < UInt32Zero;
		if(!crutch_Flag) {
			crutch_Flag = index >= mySize;
		}
		if (crutch_Flag) {
			BLAST(ModuloFailed);
		}
	}
	val = myElements->fetch(index);
	{	BooleanVar crutch_Flag;
		/* val != NULL && aHeaper->isEqual(val) */
		
		crutch_Flag = val != NULL;
		if(crutch_Flag) {
			crutch_Flag = aHeaper->isEqual(val);
		}
		if (crutch_Flag) {
			myElements->store(index, NULL);
		}
	}
}
/* create/delete */


HashSetCache::HashSetCache (UInt32 size, TCSJ) {
	mySize = size;
	myElements = PtrArray::nulls(mySize);
}
/* protected: creation */


void HashSetCache::destruct (){
	myElements = NULL;
	mySize = UInt32Zero;
	this->Heaper::destruct();
}



/* ************************************************************************ *
 * 
 *                    Class Matcher 
 *
 * ************************************************************************ */


/* creation */


RPTR(Matcher) Matcher::make (
		APTR(OrglRoot) oroot, 
		APTR(PropFinder) finder, 
		APTR(RecorderFossil) fossil)
{
	BEGIN_CONSISTENT(2) {
		RETURN_CONSTRUCT(Matcher,(oroot, finder, fossil));
	} END_CONSISTENT;
}
/* This is a one-shot agenda item.

When doing a delayed backFollow, after the future is taken care of 
(by posting recorders in the Sensor Canopy), the past needs to be 
checked (by walking the HTree northwards filtered by the Bert 
Canopy).  This AgendaItem is a one-shot used to remember to 
backFollow thru the past.  (myOrglRoot == NULL when the shot has been done.) */


/* accessing */


BooleanVar Matcher::step (){
	/* If myStamp is NULL
			We've already shot once.  Do nothing.
		walk the HTree northwards filtered by the Bert Canopy, 
	scheduling RecorderTriggers to record already-existing 
	matching stamps.  ('past' part of backfollow)
			Remember that we're done. */
	if (myOrglRoot == NULL) {
		return FALSE;
	}
	BEGIN_REANIMATE(myFossil,ResultRecorder,recorder) {
		myOrglRoot->delayedFindMatching(myFinder, myFossil, recorder);
	} END_REANIMATE;
	BEGIN_CONSISTENT(1) {
		myOrglRoot = NULL;
		/* Thing to do !!!! */
		
		/* stop making sure the stamp sticks around */
		this->diskUpdate();
		return FALSE;
	} END_CONSISTENT;
}
/* creation */


Matcher::Matcher (
		APTR(OrglRoot) oroot, 
		APTR(PropFinder) finder, 
		APTR(RecorderFossil) fossil) 
{
	myOrglRoot = oroot;
	/* Thing to do !!!! */
	
	/* make sure the stamp sticks around.  Do something like 
		what's being done with myFossil>>addItem */
	myFinder = finder;
	myFossil = fossil;
	myFossil->addItem(this);
	this->newShepherd();
}


void Matcher::dismantle (){
	BEGIN_CONSISTENT(3) {
		myFossil->removeItem(this);
		/* Unbump refcount on myFossil. */
		/* Thing to do !!!! */
		
		/* stop making sure the OrglRoot sticks around.  
			AgendaItems may be aborted by the enclosing 
			algorithm, so can't assume I dropped my 
			reference by stepping. */
		this->AgendaItem::dismantle();
	} END_CONSISTENT;
}



/* ************************************************************************ *
 * 
 *                    Class NorthRecorderChecker 
 *
 * ************************************************************************ */


/* create */


RPTR(AgendaItem) NorthRecorderChecker::make (APTR(BeEdition) edition, APTR(PropFinder) finder){
	RETURN_CONSTRUCT(NorthRecorderChecker,(edition, finder));
}
/* This is a one-shot agenda item.

See comment in SouthRecorderChecker for constraints and relationships 
to other pieces of the algorithm.

Looks for and triggers WorkRecorders lying northward of this Edition 
up to the next Edition. The Finder should only be carrying around Works. */


/* accessing */


BooleanVar NorthRecorderChecker::step (){
	/* Known bug !!!! */
	
	/* if my WorkRecorders have been hoisted they will not be 
		found; there needs to be a way to walk north in the 
		sensor canopy until we pass an edition boundary */
	if (!(myEdition == NULL)) {
		/* Ravi -- Thing to do !!!! */
		
		/* Make this work */
			/* myEdition sensorCrum fetchNextAfterTriggeri
			ngRecorders: myFinder with: NULL. */
		BEGIN_CONSISTENT(1) {
			myEdition = NULL;
			/* Thing to do !!!! */
			
			/* stop making sure the edition sticks around */
			this->diskUpdate();
		} END_CONSISTENT;
	}
	return FALSE;
}
/* create */


NorthRecorderChecker::NorthRecorderChecker (APTR(BeEdition) edition, APTR(PropFinder) finder) {
	myEdition = edition;
	myFinder = finder;
	this->newShepherd();
}



/* ************************************************************************ *
 * 
 *                    Class RecorderFossil 
 *
 * ************************************************************************ */


/* exceptions: exceptions */
/* create */


RPTR(RecorderFossil) RecorderFossil::transcluders (
		BooleanVar isDirectOnly, 
		APTR(IDRegion) loginAuthority, 
		APTR(Filter) OF1(Tuple OF2(ID,ID)) directFilter, 
		APTR(Filter) OF1(Tuple OF2(ID,ID)) indirectFilter, 
		APTR(TrailBlazer) trailBlazer)
{
	BEGIN_CONSISTENT(2) {
		if (isDirectOnly) {
			RETURN_CONSTRUCT(DirectEditionRecorderFossil,(loginAuthority, directFilter, indirectFilter, trailBlazer));
		} else {
			RETURN_CONSTRUCT(IndirectEditionRecorderFossil,(loginAuthority, directFilter, indirectFilter, trailBlazer));
		}
	} END_CONSISTENT;
}


RPTR(RecorderFossil) RecorderFossil::works (
		BooleanVar isDirectOnly, 
		APTR(IDRegion) loginAuthority, 
		APTR(Filter) OF1(Tuple OF2(ID,ID)) endorsementsFilter, 
		APTR(TrailBlazer) trailBlazer)
{
	BEGIN_CONSISTENT(2) {
		if (isDirectOnly) {
			RETURN_CONSTRUCT(DirectWorkRecorderFossil,(loginAuthority, endorsementsFilter, trailBlazer));
		} else {
			RETURN_CONSTRUCT(IndirectWorkRecorderFossil,(loginAuthority, endorsementsFilter, trailBlazer));
		}
	} END_CONSISTENT;
}
/* A Fossil for a ResultRecorder, which also stores its permissions, 
filters, and a cache of the results which have already been recorded. */


/* accessing */


void RecorderFossil::addItem (APTR(AgendaItem) /* item */){
	BEGIN_INSISTENT(1) {
		myAgendaCount += 1;
		this->diskUpdate();
		this->memoryCheck();
	} END_INSISTENT;
}


void RecorderFossil::extinguish (APTR(TrailBlazer) trailBlazer){
	/* Should only be called from BeEdition::fossilRelease().  
	Results in my becoming extinct. */
	
	if (myTrailBlazer == NULL) {
		BLAST(AlreadyExtinct);
	}
	if (!myTrailBlazer->isEqual(trailBlazer)) {
		BLAST(WhoSays);
	}
	if (myRecorderCount != Int32Zero) {
		BLAST(RecordersStillOutstanding);
	}
	if (myRecorder != NULL) {
		{myRecorder->destroy();  myRecorder = NULL /* don't want stale (S/CHK)PTRs */;}
		myRecorder = NULL;
	}
	BEGIN_INSISTENT(1) {
		myTrailBlazer = NULL;
		this->diskUpdate();
		this->memoryCheck();
	} END_INSISTENT;
}


void RecorderFossil::releaseRecorder (){
	/* As a premature optimization, we don't destroy the waldo 
	when the count goes to zero, but rather when we consider 
	purging while the count is zero. */
	
	if ( ! (myRecorderCount >= 1) ) {
		BLAST(Assertion_failed);
	}
	myRecorderCount -= 1;
}


void RecorderFossil::removeItem (APTR(AgendaItem) /* item */){
	if ( ! (myAgendaCount >= 1) ) {
		BLAST(Assertion_failed);
	}
	BEGIN_INSISTENT(1) {
		myAgendaCount -= 1;
		this->diskUpdate();
		this->memoryCheck();
	} END_INSISTENT;
}


RPTR(ResultRecorder) RecorderFossil::secretRecorder (){
	/* The Recorder of which this Fossil is the imprint. If 
	necessary, reconstruct it using the information stored in the imprint.
		Should only be called if I am not extinct
		Should only be called from the reanimate macro. */
	
	/* If I'm extinct, somebody goofed.
			Blow 'em up.
		If we haven't already reanimated a recorder (because this is 
	the outermost reanimate for this fossil)
			bind a new current KeyMaster (recovering the fossilized permissions)
						make a recorder implicitly using the fossilized permissions
							and explicitly using the fossilized endorsements
							and trail.
		bump the refcount on myRecorder
		return myRecorder */
	if (this->isExtinct()) {
		BLAST(FossilExtinct);
	}
	if (myRecorder == NULL) {
		{	FLUID_BIND(CurrentKeyMaster,FeKeyMaster::makeAll(myLoginAuthority)) {
				myRecorder = this->actualRecorder();
			}
		}
	}
	myRecorderCount += 1;
	return (ResultRecorder*) myRecorder;
}
/* testing */


BooleanVar RecorderFossil::isExtinct (){
	/* A Fossil (unlike a Grabber or an Orgl) does not prevent 
	the grabbed IObject from being dismantled.  Instead, if the 
	IObject does get dismantled, then the Fossil is considered 
	extinct.  A waldo may not be gotten from an extinct fossil 
	(if the species is really extinct, then it cannot be revived 
	from its remaining fossils). */
	
	return myTrailBlazer == NULL;
}


BooleanVar RecorderFossil::isPurgeable (){
	/* I can`t go to disk while someone has my WaldoSocket and 
	might be doing 
		something with the Waldo in it. */
	
	{	BooleanVar crutch_Flag;
		/* this->Abraham::isPurgeable() && myRecorderCount == Int32Zero */
		
		crutch_Flag = this->Abraham::isPurgeable();
		if(crutch_Flag) {
			crutch_Flag = myRecorderCount == Int32Zero;
		}
		if (crutch_Flag) {
			if (myRecorder != NULL) {
				{myRecorder->destroy();  myRecorder = NULL /* don't want stale (S/CHK)PTRs */;}
				myRecorder = NULL;
			}
			return TRUE;
		} else {
			return FALSE;
		}
	}
}
/* hooks: */


void RecorderFossil::restartRecorderFossil (APTR(Rcvr) /* rcvr *//* = NULL*/){
	myRecorder = NULL;
	myRecorderCount = Int32Zero;
}
/* protected: destruction */


void RecorderFossil::dismantle (){
	if ( ! (myRecorderCount == Int32Zero) ) {
		BLAST(Assertion_failed);
	}
	/* (myAgendaCount = Int32Zero) assert. */
	if (myRecorder != NULL) {
		{myRecorder->destroy();  myRecorder = NULL /* don't want stale (S/CHK)PTRs */;}
		myRecorder = NULL;
	}
	BEGIN_CONSISTENT(2) {
		if (::isConstructed(myTrailBlazer)) {
			myTrailBlazer->removeReference(this);
		}
		myTrailBlazer = NULL;
		this->Abraham::dismantle();
	} END_CONSISTENT;
}
/* protected: accessing */


void RecorderFossil::memoryCheck (){
	/* and: [myAgendaCount = Int32Zero] */
	if (myTrailBlazer == NULL) {
		this->forget();
	} else {
		this->remember();
	}
}


RPTR(TrailBlazer) RecorderFossil::trailBlazer (){
	if (myTrailBlazer == NULL) {
		BLAST(FatalError);
	}
	/* should have already been checked */
	return (TrailBlazer*) myTrailBlazer;
}
/* create */


RecorderFossil::RecorderFossil (APTR(IDRegion) loginAuthority, APTR(TrailBlazer) trailBlazer) {
	myLoginAuthority = loginAuthority;
	myTrailBlazer = trailBlazer;
	myTrailBlazer->addReference(this);
	myAgendaCount = Int32Zero;
	this->restartRecorderFossil(NULL);
}
/* backfollow */


void RecorderFossil::storeDataRecordingAgents (APTR(SensorCrum) sensorCrum, APTR(Agenda) agenda){
	/* Store recording agents into a SensorCrum on data in the 
	original Edition that was a source of the query */
	
	/* default behaviour */
	agenda->registerItem(sensorCrum->recordingAgent(this));
}


void RecorderFossil::storePartialityRecordingAgents (APTR(SensorCrum) sensorCrum, APTR(Agenda) agenda){
	/* Store recording agents into a SensorCrum on partiality in 
	the original Edition that was a source of the query */
	
	/* default behaviour */
	agenda->registerItem(sensorCrum->recordingAgent(this));
}


void RecorderFossil::storeRangeElementRecordingAgents (
		APTR(BeRangeElement) /* rangeElement */, 
		APTR(SensorCrum) sensorCrum, 
		APTR(Agenda) agenda)
{
	/* Store recording agents into a SensorCrum on a RangeElement 
	in the original Edition that was a source of the query */
	
	/* default behaviour */
	agenda->registerItem(sensorCrum->recordingAgent(this));
}



/* ************************************************************************ *
 * 
 *                    Class RecorderHoister 
 *
 * ************************************************************************ */


/* creation */


RPTR(AgendaItem) RecorderHoister::make (APTR(CanopyCrum) crum, APTR(ScruSet) OF1(RecorderFossil) aSetOfRecorders){
	/* Create a RecorderHoister. */
	
	if (aSetOfRecorders->isEmpty()) {
		WPTR(AgendaItem) 	returnValue;
		returnValue = Agenda::make ();
		return returnValue;
	}
	BEGIN_CONSISTENT(1) {
		RETURN_CONSTRUCT(RecorderHoister,(crum, aSetOfRecorders->asMuSet()));
	} END_CONSISTENT;
}
/*  NOT.A.TYPE I exist to hoist myCargo (a set of recorder fossils) 
up the Sensor canopy as far as it needs to go, as well as to 
propogate the props resulting from the planting of these recorders.  
When I no longer have any cargo to hoist, I devolve into an ActualPropChanger

I assume that RecorderCheckers do their southward walk in a single 
step, so I can hoist recorders by an algorithm that would 
occasionally cause a recorder to be missed if RecorderCheckers were 
incremental. */


/* creation */


RecorderHoister::RecorderHoister (APTR(CanopyCrum) crum, APTR(MuSet) OF1(RecorderFossil) aSetOfRecorders) 
	: PropChanger(crum, tcsj) {
	myCargo = aSetOfRecorders;
	this->newShepherd();
}
/* accessing */


BooleanVar RecorderHoister::step (){
	/* See class comment for a constraint I impose on another class.
		
		If I'm done
			Stop me before I step again!.
		atomically
			Do one step of property changing (and/or height 
	recalculation until that's moved to HeightChanger). 
				If more needs to be done, step rootward.  (myCrum is set 
	to NULL if I am the root.)
				else I'm done.  Remember it by setting myCrum to NULL
		return a flag saying whether I'm done */
	/* Thing to do !!!! */
	
	/* update comment after we move height calculation to 
		HeightChanger>>step */
	if (this->fetchCrum() == NULL) {
		return FALSE;
	}
	BEGIN_CONSISTENT(3) {
		SPTR(CanopyCrum) OR(NULL) crum;
		BooleanVar propsChangedFlag;
		
		crum = this->fetchCrum()->fetchParent();
		propsChangedFlag = this->fetchCrum()->changeCanopy();
		/* All the updating of myPropJoint that's needed even 
			though I hoist recorders into my parent 
			below, since hoisting cannot change what 
			myPropJoint needs to be. */
		this->setCrum(crum);
		if (crum == NULL) {
			return FALSE;
		}
		/* CASCADE */
		myCargo->restrictTo(CAST(SensorCrum,crum->fetchChild1())->recorders());
		myCargo->restrictTo(CAST(SensorCrum,crum->fetchChild2())->recorders());
		this->diskUpdate();
		if (myCargo->isEmpty()) {
			UInt32 hash;
			SPTR(FlockInfo) info;
			
			if (!propsChangedFlag) {
				this->setCrum(NULL);
				return FALSE;
			}
			{myCargo->destroy();  myCargo = NULL /* don't want stale (S/CHK)PTRs */;}
			/* Normally done by destruct, but here we do 
				it directly because we're about to 
				become something */
			hash = this->hashForEqual();
			info = this->fetchInfo();
			new (this) ActualPropChanger(crum, hash, info);
			/* the special purpose constructor will not 
			do a 'crum->addPointer(this)' so we don't 
			have to undo it */
			return TRUE;
		}
		/* If we reach this point, we have cargo to hoist. */
		CAST(SensorCrum,crum->fetchChild1())->removeRecorders(myCargo->asImmuSet());
		CAST(SensorCrum,crum->fetchChild2())->removeRecorders(myCargo->asImmuSet());
		myCargo->wipeAll(CAST(SensorCrum,crum)->recorders());
		if (myCargo->isEmpty()) {
			if (!propsChangedFlag) {
				this->setCrum(NULL);
			}
			return propsChangedFlag;
		} else {
			CAST(SensorCrum,crum)->installRecorders(myCargo->asImmuSet());
			crum->diskUpdate();
		}
	} END_CONSISTENT;
	return TRUE;
}



/* ************************************************************************ *
 * 
 *                    Class RecorderTrigger 
 *
 * ************************************************************************ */


/* creation */


RPTR(RecorderTrigger) RecorderTrigger::make (APTR(RecorderFossil) fossil, APTR(BeRangeElement) element){
	BEGIN_CONSISTENT(2) {
		RETURN_CONSTRUCT(RecorderTrigger,(fossil, element));
	} END_CONSISTENT;
}
/* This is a one-shot agenda item.

Asks myFossil to record myElement.

When an answer to a delayed backFollow is found, whether thru a 
northwards h-walk (filtered by the Bert Canopy) of a southwards 
o-walk (filtered by the Sensor Canopy), instead of actually recording 
the answer into the backFollow trail immediately, we shedule a 
RecorderTrigger to do the job. */


/* accessing */


BooleanVar RecorderTrigger::step (){
	/* If null pointer to myFossil
			We've already shot once.  Do nothing.
		If myFossil is still in suspension
			Inform myFossil with myElement
		Atomically
			Remove refcount from ourself on myFossil.
			Remember that we're done. */
	if (myFossil == NULL) {
		return FALSE;
	}
	if (!myFossil->isExtinct()) {
		BEGIN_REANIMATE(myFossil,ResultRecorder,recorder) {
			recorder->record(myElement);
		} END_REANIMATE;
	}
	BEGIN_CONSISTENT(2) {
		myFossil->removeItem(this);
		myFossil = NULL;
		/* Thing to do !!!! */
		
		/* stop making sure the Edition doesn't go away; it 
			needs a refcount or something like it. */
		this->diskUpdate();
		return FALSE;
	} END_CONSISTENT;
}
/* creation */


RecorderTrigger::RecorderTrigger (APTR(RecorderFossil) fossil, APTR(BeRangeElement) element) {
	myFossil = fossil;
	myFossil->addItem(this);
	myElement = element;
	/* Thing to do !!!! */
	
	this->newShepherd();
}


void RecorderTrigger::dismantle (){
	BEGIN_CONSISTENT(2) {
		if (myFossil != NULL) {
			myFossil->removeItem(this);
			myFossil = NULL;
		}
		/* Thing to do !!!! */
		
		/* stop making sure the stamp doesn't go away */
		this->AgendaItem::dismantle();
	} END_CONSISTENT;
}



/* ************************************************************************ *
 * 
 *                    Class ResultRecorder 
 *
 * ************************************************************************ */


/* Represents the persistent embodiment of a query operation. Can be 
stored on disk in the form of a RecorderFossil. The abstract protocol 
deals with:
	- caching previous results to avoid duplication
	- storing results in a trail at unique positions
	- managing persistent permissions
	- looking for immediate results
	- checking whether a good candidate (identified by the canopy props) 
should really go into the trail */


/* accessing */


RPTR(IDRegion) ResultRecorder::actualAuthority (){
	WPTR(IDRegion) 	returnValue;
	returnValue = myKeyMaster->actualAuthority();
	return returnValue;
}


RPTR(PropFinder) ResultRecorder::bertPropFinder (){
	/* Something to find potential candidates given a source for 
	the query */
	
	WPTR(PropFinder) 	returnValue;
	returnValue = PropFinder::backfollowFinder(this->permissionsFilter(), this->endorsementsFilter());
	return returnValue;
}


RPTR(Filter) ResultRecorder::endorsementsFilter (){
	/* The endorsements I am looking for */
	
	return (Filter*) myEndorsementsFilter;
}


RPTR(FeKeyMaster) ResultRecorder::keyMaster (){
	return (FeKeyMaster*) myKeyMaster;
}


RPTR(Filter) OF1(ID) ResultRecorder::permissionsFilter (){
	/* The permissions I am looking for */
	
	return (Filter*) myPermissionsFilter;
}


RPTR(SensorProp) ResultRecorder::sensorProp (){
	/* A SensorProp which corresponds to what I am looking for */
	
	WPTR(SensorProp) 	returnValue;
	returnValue = SensorProp::make (CAST(IDRegion,this->permissionsFilter()->relevantRegion()), myRelevantEndorsements, FALSE);
	return returnValue;
}
/* recording */


void ResultRecorder::record (APTR(BeRangeElement) answer){
	/* tell my TrailBlazer to recorder it */
	
	myTrailBlazer->record(answer);
}


void ResultRecorder::triggerIfMatching (APTR(PropFinder) finder, APTR(RecorderFossil) fossil){
	/* Trigger myself if I match the finder's profile */
	
	BEGIN_CHOOSE(finder) {
		BEGIN_KIND(AbstractRecorderFinder,arf) {
			arf->checkRecorder(this, fossil);
		} END_KIND;
	} END_CHOOSE;
}
/* create */


ResultRecorder::ResultRecorder (
		APTR(Filter) endorsementsFilter, 
		APTR(CrossRegion) relevantEndorsements, 
		APTR(TrailBlazer) trailBlazer) 
{
	/* Ravi -- Thing to do !!!! */
	
	/* decide whether this should have a filter or just the 
		relevant regions */
	myEndorsementsFilter = endorsementsFilter;
	myRelevantEndorsements = relevantEndorsements;
	myKeyMaster = CurrentKeyMaster.fluidGet();
	
	myPermissionsFilter = CurrentGrandMap.fluidGet()->globalIDFilterSpace()->anyFilter(myKeyMaster->actualAuthority());
	myTrailBlazer = trailBlazer;
}
/* backfollow */


void ResultRecorder::delayedStoreMatching (
		APTR(BeRangeElement) element, 
		APTR(PropFinder) finder, 
		APTR(RecorderFossil) fossil, 
		APTR(HashSetCache) OF1(HistoryCrum) hCrumCache)
{
	/* The immediate part of the backfollow has reached an 
	RangeElement of the original Edition. I now get to decide 
	what to do next to continue the operation */
	
	/* this is a default implementation, which subclasses may 
		override or modify */
	element->delayedStoreBackfollow(finder, fossil, this, hCrumCache);
}



/* ************************************************************************ *
 * 
 *                    Class   EditionRecorder 
 *
 * ************************************************************************ */


/* Represents the a persistent transcluders or rangeTranscluders query */


/* accessing */


BooleanVar EditionRecorder::accepts (APTR(BeRangeElement) element){
	return element->isKindOf(cat_BeEdition);
}


RPTR(Filter) EditionRecorder::directFilter (){
	return (Filter*) myDirectFilter;
}


RPTR(Filter) EditionRecorder::indirectFilter (){
	return (Filter*) myIndirectFilter;
}
/* create */


EditionRecorder::EditionRecorder (
		APTR(Filter) directFilter, 
		APTR(Filter) indirectFilter, 
		APTR(TrailBlazer) trailBlazer) 

	: ResultRecorder(CAST(Filter,directFilter->unionWith(indirectFilter))
		, CAST(CrossRegion,directFilter->relevantRegion()->unionWith(indirectFilter->relevantRegion()))
		, trailBlazer) 
{
	myDirectFilter = directFilter;
	myIndirectFilter = indirectFilter;
}
/* backfollow */


void EditionRecorder::delayedStoreBackfollow (
		APTR(BeEdition) edition, 
		APTR(PropFinder) /* finder */, 
		APTR(RecorderFossil) fossil, 
		APTR(HashSetCache) OF1(HistoryCrum) hCrumCache)
{
	{	FLUID_BIND(CurrentKeyMaster,this->keyMaster()) {
			{	BooleanVar crutch_Flag;
				/* myDirectFilter->match(edition->visibleEndorsements()) && edition->anyPasses(PropFinder::backfollowFinder(this->permissionsFilter(), myIndirectFilter)) */
				
				crutch_Flag = myDirectFilter->match(edition->visibleEndorsements());
				if(crutch_Flag) {
					crutch_Flag = edition->anyPasses(PropFinder::backfollowFinder(this->permissionsFilter(), myIndirectFilter));
				}
				if (crutch_Flag) {
					RecorderTrigger::make (fossil, edition)->schedule();
				}
			}
		}
	}
}



/* ************************************************************************ *
 * 
 *                    Class   WorkRecorder 
 *
 * ************************************************************************ */


/* Represents the a persistent works or rangeWorks query */


/* create */


WorkRecorder::WorkRecorder (APTR(Filter) endorsementsFilter, APTR(TrailBlazer) trailBlazer) 
	: ResultRecorder(endorsementsFilter
		, CAST(CrossRegion,endorsementsFilter->relevantRegion())
		, trailBlazer) 
{
	
}
/* accessing */


BooleanVar WorkRecorder::accepts (APTR(BeRangeElement) element){
	return element->isKindOf(cat_BeWork);
}
/* backfollow */


void WorkRecorder::recordImmediateWorks (APTR(BeRangeElement) element, APTR(RecorderFossil) fossil){
	/* If there are any Works directly on the RangeElement which 
	pass the filters, record them */
	
	BEGIN_CHOOSE(element) {
		BEGIN_KIND(BeEdition,edition) {
			BEGIN_FOR_EACH(BeWork,work,(edition->currentWorks()->stepper())) {
				{	BooleanVar crutch_Flag;
					/* work->canBeReadBy(this->keyMaster()) && this->endorsementsFilter()->match(work->endorsements()) */
					
					crutch_Flag = work->canBeReadBy(this->keyMaster());
					if(crutch_Flag) {
						crutch_Flag = this->endorsementsFilter()->match(work->endorsements());
					}
					if (crutch_Flag) {
						RecorderTrigger::make (fossil, work)->schedule();
					}
				}
			} END_FOR_EACH;
		} END_KIND;
		BEGIN_OTHERS {
			
		} END_OTHERS;
	} END_CHOOSE;
}



/* ************************************************************************ *
 * 
 *                    Class SouthRecorderChecker 
 *
 * ************************************************************************ */


/* creation */


RPTR(SouthRecorderChecker) SouthRecorderChecker::make (
		APTR(OrglRoot) oroot, 
		APTR(PropFinder) finder, 
		APTR(SensorCrum) OR(NULL) scrum)
{
	BEGIN_CONSISTENT(2) {
		RETURN_CONSTRUCT(SouthRecorderChecker,(oroot, finder, scrum));
	} END_CONSISTENT;
}
/* This is a one-shot agenda item.

When changing the prop(ertie)s of a Stamp, we need to first take care 
of the future backFollow requests (by updating the Bert Canopy so the 
filtered HTree walk will find this Stamp) before taking care of the 
past (the Recorders that were looking for this Stamp in their 
future).  This AgendaItem is to remember to take care of the past (by 
doing a southwards o-walk filtered by the Sensor Canopy) after the 
future is properly dealt with.

The RecorderHoister assumes that this southward walk is done in a 
single-step, so it is free to make changes in a way that, if it were 
interleaved with an incremental southward walk by a RecorderChecker 
looking for the recorder(s) being hoisted, might cause the hoisted 
recorder to be missed.

This is also used recursively by this very o-walk to schedule a 
further o-walk on appropriate sub-Stamps.

Keeping track of whether persistent objects are garbage-on-disk 
during AgendaItem processing only remains open for Stamps, except 
here where it also arises for an OrglRoot.  The OrglRoot is itself 
held by a persistent Stamp, from which it can be easily obtained, so 
we should probably just hold onto two Stamps instead of a Stamp and 
an OrglRoot (so I only have to solve the "how to keep it around" 
problem for Stamps). */


/* creation */


SouthRecorderChecker::SouthRecorderChecker (
		APTR(OrglRoot) oroot, 
		APTR(PropFinder) finder, 
		APTR(SensorCrum) OR(NULL) scrum) 
{
	myORoot = oroot;
	myFinder = finder;
	/* Known bug !!!! */
	
	/* make sure these objects stick around.  mySCrum has 
		add/removePointer already.  myStamp and myORoot need 
		something similar.  myFinder is one of my sheep and 
		is already OK. */
	mySCrum = scrum;
	if (mySCrum != NULL) {
		mySCrum->addPointer(this);
	}
	this->newShepherd();
}


void SouthRecorderChecker::dismantle (){
	BEGIN_CONSISTENT(3) {
		if (mySCrum != NULL) {
			mySCrum->removePointer(this);
			mySCrum = NULL;
		}
		/* Thing to do !!!! */
		
		/* stop making sure these objects stick around */
		this->AgendaItem::dismantle();
	} END_CONSISTENT;
}
/* accessing */


BooleanVar SouthRecorderChecker::step (){
	/* See class comment for a constraint on this method.
		
		If empty ORoot
			We've already shot once.  Do nothing.
		Check for any recorders in the sensor canopy that need to be rung.
			Remember that we're done. */
	if (myORoot == NULL) {
		return FALSE;
	}
	myORoot->checkRecorders(myFinder, mySCrum);
	BEGIN_CONSISTENT(1) {
		myORoot = NULL;
		/* Thing to do !!!! */
		
		/* stop making sure these objects stick around */
		this->diskUpdate();
		return FALSE;
	} END_CONSISTENT;
}



/* ************************************************************************ *
 * 
 *                    Class TrailBlazer 
 *
 * ************************************************************************ */


/* exceptions: */


/* create */


RPTR(TrailBlazer) TrailBlazer::make (APTR(BeEdition) trail){
	/* should only be called from Edition::getOrMakeTrailBlazer */
	
	SPTR(TrailBlazer) result;
	SPTR(XnRegion) partial;
	SPTR(BeEdition) sub;
	
	BEGIN_CONSISTENT(1) {
		CONSTRUCT(result,TrailBlazer,());
	} END_CONSISTENT;
	partial = trail->attachTrailBlazer(result);
	sub = trail->copy(partial);
	BEGIN_CONSISTENT(1) {
		result->setEdition(sub);
	} END_CONSISTENT;
	/* this makes the blazer be alive, once attached */
	WPTR(TrailBlazer) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* The object responsible for recording results into a trail.  */


/* create */


TrailBlazer::TrailBlazer () {
	myTrail = NULL;
	myRecorded = HashSetCache::make ();
	myRefCount = IntegerVarZero;
	this->newShepherd();
}
/* private: */


void TrailBlazer::setEdition (APTR(BeEdition) trail){
	myTrail = trail;
	this->diskUpdate();
}
/* accessing */


BooleanVar TrailBlazer::isAlive (){
	/* Whether this TrailBlazer was in fact successfully attached */
	
	return myTrail != NULL;
}


void TrailBlazer::record (APTR(BeRangeElement) answer){
	/* record the answer into my Edition, and keep only the partial part.
	
		Should usually suppress redundant records of the same 
	object.  (These are typically generated by a race between the 
	now and future parts of a backfollow, which are guaranteed to 
	err by overlapping rather than gapping.  They may also be 
	generated by a crash/reboot during AgendaItem processing.) */
	
	if (!myRecorded->hasMember(answer)) {
		SPTR(ID) iD;
		SPTR(BeEdition) newTrail;
		
		iD = CAST(IDSpace,myTrail->coordinateSpace())->newID();
		{
			INSTALL_SHIELD(ex);
			SHIELD_UP_BEGIN(ex, RecordFailureFilter) {
				return;
				
			} SHIELD_UP_END(ex);
			myTrail->get(iD)->makeIdentical(answer->makeFe(NULL));
		}
		myRecorded->store(answer);
		/* Ravi -- Thing to do !!!! */
		
		/* This should not be an edit operation (?) */
		newTrail = myTrail->without(iD);
		/* Ravi -- Thing to do !!!! */
		
		/* decrease refcount on old trail, increase on new one */
		BEGIN_CONSISTENT(1) {
			myTrail = newTrail;
			this->diskUpdate();
		} END_CONSISTENT;
	}
}
/* storage */


void TrailBlazer::addReference (APTR(Abraham) /* object */){
	/* Increment the reference count */
	
	BEGIN_CONSISTENT(1) {
		myRefCount += 1;
		if (myRefCount == 1) {
			this->remember();
		}
		this->diskUpdate();
	} END_CONSISTENT;
}


void TrailBlazer::removeReference (APTR(Abraham) /* object */){
	/* Decrement the reference count */
	
	BEGIN_CONSISTENT(1) {
		myRefCount -= 1;
		if (myRefCount == IntegerVarZero) {
			this->forget();
		}
		this->diskUpdate();
	} END_CONSISTENT;
}



/* ************************************************************************ *
 * 
 *                    Class DirectEditionRecorder 
 *
 * ************************************************************************ */


/* Represents the a persistent transcluders or rangeTranscluders 
query with directContainersOnly flag on */


/* accessing */


BooleanVar DirectEditionRecorder::isDirectOnly (){
	return TRUE;
}
/* create */


DirectEditionRecorder::DirectEditionRecorder (
		APTR(Filter) directFilter, 
		APTR(Filter) indirectFilter, 
		APTR(TrailBlazer) trailBlazer) 

	: EditionRecorder(directFilter
		, indirectFilter
		, trailBlazer) 
{
	
}



/* ************************************************************************ *
 * 
 *                    Class DirectWorkRecorder 
 *
 * ************************************************************************ */


/* Represents the a persistent works or rangeWorks query with the 
directContainersOnly flag on */


/* create */


DirectWorkRecorder::DirectWorkRecorder (APTR(Filter) endorsementsFilter, APTR(TrailBlazer) trailBlazer) 
	: WorkRecorder(endorsementsFilter, trailBlazer) {
	
}
/* accessing */


BooleanVar DirectWorkRecorder::isDirectOnly (){
	return TRUE;
}
/* backfollow */


void DirectWorkRecorder::delayedStoreBackfollow (
		APTR(BeEdition) /* edition */, 
		APTR(PropFinder) /* finder */, 
		APTR(RecorderFossil) /* fossil */, 
		APTR(HashSetCache) OF1(HistoryCrum) /* hCrumCache */)
{
	/* This algorithm should never reach here */
	BLAST(FatalError);
}


void DirectWorkRecorder::delayedStoreMatching (
		APTR(BeRangeElement) element, 
		APTR(PropFinder) /* finder */, 
		APTR(RecorderFossil) fossil, 
		APTR(HashSetCache) OF1(HistoryCrum) /* hCrumCache */)
{
	/* and nothing else */
	this->recordImmediateWorks(element, fossil);
}



/* ************************************************************************ *
 * 
 *                    Class EditionRecorderFossil 
 *
 * ************************************************************************ */


/* A Fossil for an EditionRecorder. */


/* protected: accessing */


RPTR(Filter) EditionRecorderFossil::directFilter (){
	return (Filter*) myDirectFilter;
}


RPTR(Filter) EditionRecorderFossil::indirectFilter (){
	return (Filter*) myIndirectFilter;
}
/* create */


EditionRecorderFossil::EditionRecorderFossil (
		APTR(IDRegion) loginAuthority, 
		APTR(Filter) directFilter, 
		APTR(Filter) indirectFilter, 
		APTR(TrailBlazer) trailBlazer) 

	: RecorderFossil(loginAuthority, trailBlazer) {
	myDirectFilter = directFilter;
	myIndirectFilter = indirectFilter;
}



/* ************************************************************************ *
 * 
 *                    Class   DirectEditionRecorderFossil 
 *
 * ************************************************************************ */


/* A Fossil for an EditionRecorder with the directOnly flag set. */


/* protected: accessing */


RPTR(ResultRecorder) DirectEditionRecorderFossil::actualRecorder (){
	RETURN_CONSTRUCT(DirectEditionRecorder,(this->directFilter(), this->indirectFilter(), this->trailBlazer()));
}
/* create */


DirectEditionRecorderFossil::DirectEditionRecorderFossil (
		APTR(IDRegion) loginAuthority, 
		APTR(Filter) directFilter, 
		APTR(Filter) indirectFilter, 
		APTR(TrailBlazer) trailBlazer) 

	: EditionRecorderFossil(loginAuthority
		, directFilter
		, indirectFilter
		, trailBlazer) 
{
	this->newShepherd();
	this->remember();
}



/* ************************************************************************ *
 * 
 *                    Class   IndirectEditionRecorderFossil 
 *
 * ************************************************************************ */


/* A Fossil for an EditionRecorder with the directOnly flag off. */


/* protected: accessing */


RPTR(ResultRecorder) IndirectEditionRecorderFossil::actualRecorder (){
	RETURN_CONSTRUCT(IndirectEditionRecorder,(this->directFilter(), this->indirectFilter(), this->trailBlazer()));
}
/* create */


IndirectEditionRecorderFossil::IndirectEditionRecorderFossil (
		APTR(IDRegion) loginAuthority, 
		APTR(Filter) directFilter, 
		APTR(Filter) indirectFilter, 
		APTR(TrailBlazer) trailBlazer) 

	: EditionRecorderFossil(loginAuthority
		, directFilter
		, indirectFilter
		, trailBlazer) 
{
	this->newShepherd();
	this->remember();
}



/* ************************************************************************ *
 * 
 *                    Class IndirectEditionRecorder 
 *
 * ************************************************************************ */


/* Represents the a persistent transcluders or rangeTranscluders 
query with directContainersOnly flag off */


/* accessing */


BooleanVar IndirectEditionRecorder::isDirectOnly (){
	return FALSE;
}
/* create */


IndirectEditionRecorder::IndirectEditionRecorder (
		APTR(Filter) directFilter, 
		APTR(Filter) indirectFilter, 
		APTR(TrailBlazer) trailBlazer) 

	: EditionRecorder(directFilter
		, indirectFilter
		, trailBlazer) 
{
	
}
/* backfollow */


void IndirectEditionRecorder::delayedStoreBackfollow (
		APTR(BeEdition) edition, 
		APTR(PropFinder) finder, 
		APTR(RecorderFossil) fossil, 
		APTR(HashSetCache) OF1(HistoryCrum) hCrumCache)
{
	this->EditionRecorder::delayedStoreBackfollow(edition, finder, fossil, hCrumCache);
	edition->delayedStoreBackfollow(finder, fossil, this, hCrumCache);
}



/* ************************************************************************ *
 * 
 *                    Class IndirectWorkRecorder 
 *
 * ************************************************************************ */


/* Represents the a persistent works or rangeWorks query with the 
directContainersOnly flag off */


/* create */


IndirectWorkRecorder::IndirectWorkRecorder (APTR(Filter) endorsementsFilter, APTR(TrailBlazer) trailBlazer) 
	: WorkRecorder(endorsementsFilter, trailBlazer) {
	
}
/* accessing */


BooleanVar IndirectWorkRecorder::isDirectOnly (){
	return FALSE;
}
/* backfollow */


void IndirectWorkRecorder::delayedStoreBackfollow (
		APTR(BeEdition) edition, 
		APTR(PropFinder) finder, 
		APTR(RecorderFossil) fossil, 
		APTR(HashSetCache) OF1(HistoryCrum) hCrumCache)
{
	this->recordImmediateWorks(edition, fossil);
	edition->delayedStoreBackfollow(finder, fossil, this, hCrumCache);
}


void IndirectWorkRecorder::delayedStoreMatching (
		APTR(BeRangeElement) element, 
		APTR(PropFinder) finder, 
		APTR(RecorderFossil) fossil, 
		APTR(HashSetCache) OF1(HistoryCrum) hCrumCache)
{
	this->recordImmediateWorks(element, fossil);
	this->WorkRecorder::delayedStoreMatching(element, finder, fossil, hCrumCache);
}



/* ************************************************************************ *
 * 
 *                    Class WorkRecorderFossil 
 *
 * ************************************************************************ */


/* A Fossil for a WorkRecorder. */


/* protected: accessing */


RPTR(Filter) WorkRecorderFossil::endorsementsFilter (){
	return (Filter*) myEndorsementsFilter;
}
/* create */


WorkRecorderFossil::WorkRecorderFossil (
		APTR(IDRegion) loginAuthority, 
		APTR(Filter) endorsementsFilter, 
		APTR(TrailBlazer) trailBlazer) 

	: RecorderFossil(loginAuthority, trailBlazer) {
	myEndorsementsFilter = endorsementsFilter;
}



/* ************************************************************************ *
 * 
 *                    Class   DirectWorkRecorderFossil 
 *
 * ************************************************************************ */


/* A Fossil for a DirectWorkRecorder. */


/* protected: accessing */


RPTR(ResultRecorder) DirectWorkRecorderFossil::actualRecorder (){
	RETURN_CONSTRUCT(DirectWorkRecorder,(this->endorsementsFilter(), this->trailBlazer()));
}
/* create */


DirectWorkRecorderFossil::DirectWorkRecorderFossil (
		APTR(IDRegion) loginAuthority, 
		APTR(Filter) endorsementsFilter, 
		APTR(TrailBlazer) trailBlazer) 

	: WorkRecorderFossil(loginAuthority
		, endorsementsFilter
		, trailBlazer) 
{
	this->newShepherd();
	this->remember();
}
/* backfollow */


void DirectWorkRecorderFossil::storeDataRecordingAgents (APTR(SensorCrum) sensorCrum, APTR(Agenda) agenda){
	/* do nothing */
	
	
}


void DirectWorkRecorderFossil::storeRangeElementRecordingAgents (
		APTR(BeRangeElement) rangeElement, 
		APTR(SensorCrum) sensorCrum, 
		APTR(Agenda) agenda)
{
	{	BooleanVar crutch_Flag;
		/* rangeElement->isKindOf(cat_BeEdition) || rangeElement->isKindOf(cat_BePlaceHolder) */
		
		crutch_Flag = rangeElement->isKindOf(cat_BeEdition);
		if(!crutch_Flag) {
			crutch_Flag = rangeElement->isKindOf(cat_BePlaceHolder);
		}
		if (crutch_Flag) {
			this->WorkRecorderFossil::storeRangeElementRecordingAgents(rangeElement, sensorCrum, agenda);
		}
	}
}



/* ************************************************************************ *
 * 
 *                    Class   IndirectWorkRecorderFossil 
 *
 * ************************************************************************ */


/* A Fossil for a IndirectWorkRecorder. */


/* protected: accessing */


RPTR(ResultRecorder) IndirectWorkRecorderFossil::actualRecorder (){
	RETURN_CONSTRUCT(IndirectWorkRecorder,(this->endorsementsFilter(), this->trailBlazer()));
}
/* create */


IndirectWorkRecorderFossil::IndirectWorkRecorderFossil (
		APTR(IDRegion) loginAuthority, 
		APTR(Filter) endorsementsFilter, 
		APTR(TrailBlazer) trailBlazer) 

	: WorkRecorderFossil(loginAuthority
		, endorsementsFilter
		, trailBlazer) 
{
	this->newShepherd();
	this->remember();
}

#ifndef TCLUDEX_SXX
#include "tcludex.sxx"
#endif /* TCLUDEX_SXX */


#ifndef TCLUDEP_SXX
#include "tcludep.sxx"
#endif /* TCLUDEP_SXX */



#endif /* TCLUDEX_CXX */

