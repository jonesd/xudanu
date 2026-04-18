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

#ifndef BRANGE1X_CXX
#define BRANGE1X_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef BRANGE1X_HXX
#include "brange1x.hxx"
#endif /* BRANGE1X_HXX */

#ifndef BRANGE1X_IXX
#include "brange1x.ixx"
#endif /* BRANGE1X_IXX */

#ifndef BRANGE1P_HXX
#include "brange1p.hxx"
#endif /* BRANGE1P_HXX */

#ifndef BRANGE1P_IXX
#include "brange1p.ixx"
#endif /* BRANGE1P_IXX */


#ifndef BRANGE3X_HXX
#include "brange3x.hxx"
#endif /* BRANGE3X_HXX */

#ifndef DETECTX_HXX
#include "detectx.hxx"
#endif /* DETECTX_HXX */

#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef FILTERX_HXX
#include "filterx.hxx"
#endif /* FILTERX_HXX */

#ifndef GRANMAPX_HXX
#include "granmapx.hxx"
#endif /* GRANMAPX_HXX */

#ifndef LOAVESP_HXX
#include "loavesp.hxx"
#endif /* LOAVESP_HXX */

#ifndef LOAVESX_HXX
#include "loavesx.hxx"
#endif /* LOAVESX_HXX */

#ifndef NKERNELP_HXX
#include "nkernelp.hxx"
#endif /* NKERNELP_HXX */

#ifndef NKERNELX_HXX
#include "nkernelx.hxx"
#endif /* NKERNELX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef OROOTX_HXX
#include "orootx.hxx"
#endif /* OROOTX_HXX */

#ifndef PROPSX_HXX
#include "propsx.hxx"
#endif /* PROPSX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */

#ifndef TRACEPX_HXX
#include "tracepx.hxx"
#endif /* TRACEPX_HXX */




/* ************************************************************************ *
 * 
 *                    Class BeCarrier 
 *
 * ************************************************************************ */


/* creation */


RPTR(BeCarrier) BeCarrier::label (APTR(BeRangeElement) element){
	/* For non-Editions only. */
	
	
	RETURN_CONSTRUCT(BeCarrier,(CurrentGrandMap.fluidGet()->newLabel(), element));
}


RPTR(BeCarrier) BeCarrier::make (APTR(BeRangeElement) element){
	/* For non-Editions only. */
	
	RETURN_CONSTRUCT(BeCarrier,(NULL, element));
}


RPTR(BeCarrier) BeCarrier::make (APTR(BeLabel) OR(NULL) label, APTR(BeRangeElement) element){
	/* For editions only. */
	
	RETURN_CONSTRUCT(BeCarrier,(label, element));
}
/* These are used to carry a combination of a rangeElement and a 
label.  Using FeRangeElements would be a hack that drags in 
permissions checking, etc. */


/* accessing */


RPTR(BeLabel) OR(NULL) BeCarrier::fetchLabel (){
	return (BeLabel*) myLabel;
}


RPTR(BeLabel) BeCarrier::getLabel (){
	if (myLabel == NULL) {
		BLAST(NoLabel);
	}
	return (BeLabel*) myLabel;
}


RPTR(FeRangeElement) BeCarrier::makeFe (){
	if (myLabel == NULL) {
		WPTR(FeRangeElement) 	returnValue;
		returnValue = myRangeElement->makeFe(myLabel);
		return returnValue;
	} else {
		WPTR(FeRangeElement) 	returnValue;
		returnValue = myRangeElement->makeFe(myLabel);
		return returnValue;
	}
}


RPTR(BeRangeElement) BeCarrier::rangeElement (){
	return (BeRangeElement*) myRangeElement;
}
/* creation */


BeCarrier::BeCarrier (APTR(BeLabel) OR(NULL) label, APTR(BeRangeElement) element) {
	myLabel = label;
	myRangeElement = element;
	if (!(myLabel != NULL == myRangeElement->isKindOf(cat_BeEdition))) {
		BLAST(IncorrectLabel);
	}
}
/* testing */


UInt32 BeCarrier::actualHashForEqual (){
	return Heaper::takeOop();
}



/* ************************************************************************ *
 * 
 *                    Class BeRangeElement 
 *
 * ************************************************************************ */


/* This is the actual representation on disk; the Fe versions of 
these classes hide the actual representation.ó */


/* accessing */


void BeRangeElement::addFeRangeElement (APTR(FeRangeElement) element){
	/* Add a new session level pointer */
	
	if (myFeRangeElements == NULL) {
		myFeRangeElements = PrimSet::weak();
	}
	myFeRangeElements->introduce(element);
}


BooleanVar BeRangeElement::isPurgeable (){
	{	BooleanVar crutch_Flag;
		/* myFeRangeElements == NULL || myFeRangeElements->isEmpty() */
		
		crutch_Flag = myFeRangeElements == NULL;
		if(!crutch_Flag) {
			crutch_Flag = myFeRangeElements->isEmpty();
		}
		return crutch_Flag;
	}
}


BooleanVar BeRangeElement::makeIdentical (APTR(BeRangeElement) /* other */){
	/* Change the identity of this object to that of the other.
		 Only placeHolders implement it at the moment, so the 
		 default is to reject the operation (return false). */
	
	return FALSE;
}


RPTR(ID) BeRangeElement::owner (){
	/* The Club who has ownership */
	
	return (ID*) myOwner;
}


void BeRangeElement::removeFeRangeElement (APTR(FeRangeElement) element){
	/* Remove a session level pointer */
	
	{	BooleanVar crutch_Flag;
		/* myFeRangeElements == NULL || !myFeRangeElements->hasMember(element) */
		
		crutch_Flag = myFeRangeElements == NULL;
		if(!crutch_Flag) {
			crutch_Flag = !myFeRangeElements->hasMember(element);
		}
		if (crutch_Flag) {
			BLAST(NeverAddedFeRangeElement);
		}
	}
	myFeRangeElements->wipe(element);
	if (myFeRangeElements->isEmpty()) {
		{myFeRangeElements->destroy();  myFeRangeElements = NULL /* don't want stale (S/CHK)PTRs */;}
		myFeRangeElements = NULL;
	}
}


void BeRangeElement::setOwner (APTR(ID) club){
	/* Change the Club who has ownership */
	
	BEGIN_CONSISTENT(1) {
		myOwner = club;
		this->diskUpdate();
	} END_CONSISTENT;
}
/* be accessing */


void BeRangeElement::addOParent (APTR(Loaf) oparent){
	/* add oparent to the set of upward pointers.  Editions may
		 also have to propagate BertCrum change downward. */
	
	BEGIN_INSISTENT(5) {
		if (myHCrum->isEmpty()) {
			this->remember();
		}
		myHCrum->addOParent(oparent);
		this->diskUpdate();
	} END_INSISTENT;
}


BooleanVar BeRangeElement::anyPasses (APTR(PropFinder) finder){
	return myHCrum->anyPasses(finder);
}


RPTR(BertCrum) BeRangeElement::bertCrum (){
	WPTR(BertCrum) 	returnValue;
	returnValue = myHCrum->bertCrum();
	return returnValue;
}


void BeRangeElement::checkRecorders (APTR(PropFinder) finder, APTR(SensorCrum) OR(NULL) scrum){
	/* does nothing.  Overrides do something. */
	
	
}


UInt32 BeRangeElement::contentsHash (){
	return this->Abraham::contentsHash() ^ myHCrum->hashForEqual() ^ mySensorCrum->hashForEqual() ^ myOwner->hashForEqual();
}


void BeRangeElement::delayedStoreBackfollow (
		APTR(PropFinder) finder, 
		APTR(RecorderFossil) fossil, 
		APTR(ResultRecorder) recorder, 
		APTR(HashSetCache) OF1(HistoryCrum) hCrumCache)
{
	myHCrum->delayedStoreBackfollow(finder, fossil, recorder, hCrumCache);
}


RPTR(PrimSet) OF1(FeRangeElement) BeRangeElement::feRangeElements (){
	if (myFeRangeElements == NULL) {
		WPTR(PrimSet) OF1(FeRangeElement) 	returnValue;
		returnValue = PrimSet::make ();
		return returnValue;
	} else {
		return (PrimSet*) myFeRangeElements;
	}
}


RPTR(HistoryCrum) BeRangeElement::hCrum (){
	return (HUpperCrum*) myHCrum;
}


BooleanVar BeRangeElement::inTrace (APTR(TracePosition) trace){
	/* Return true if the receiver can backfollow to trace. */
	
	return myHCrum->inTrace(trace);
}


RPTR(Mapping) BeRangeElement::mappingTo (APTR(TracePosition) trace, APTR(Mapping) mapping){
	/* return a mapping from my data to corresponding stuff in 
	the given trace */
	
	WPTR(Mapping) 	returnValue;
	returnValue = myHCrum->mappingTo(trace, mapping);
	return returnValue;
}


void BeRangeElement::removeOParent (APTR(OPart) oparent){
	/* remove oparent from the set of upward pointers. */
	
	myHCrum->removeOParent(oparent);
	/* myHCrum isEmpty 
				ifTrue: 
					["Now we get into the risky part of deletion.  myHCrum
					 canForget iff all the downward pointers to it are gone."
					self destroy] */
	this->diskUpdate();
}


RPTR(SensorCrum) BeRangeElement::sensorCrum (){
	return (SensorCrum*) mySensorCrum;
}


BooleanVar BeRangeElement::updateBCrumTo (APTR(BertCrum) newBCrum){
	/* Ensure the my bertCrum is not be leafward of newBCrum. */
	
	if (myHCrum->propagateBCrum(newBCrum)) {
		this->diskUpdate();
		return TRUE;
	}
	return FALSE;
}
/* protected: */


BeRangeElement::BeRangeElement () {
	myOwner = InitialOwner.fluidGet();
	myHCrum = HUpperCrum::make ();
	mySensorCrum = SensorCrum::make ();
	myFeRangeElements = NULL;
}


BeRangeElement::BeRangeElement (APTR(SensorCrum) sensorCrum, TCSJ) {
	myOwner = InitialOwner.fluidGet();
	myHCrum = HUpperCrum::make ();
	mySensorCrum = sensorCrum;
	myFeRangeElements = NULL;
}


void BeRangeElement::dismantle (){
	BEGIN_CONSISTENT(2) {
		if (::isConstructed(mySensorCrum)) {
			mySensorCrum->removePointer(this);
		}
		{	BooleanVar crutch_Flag;
			/* ::isConstructed(myHCrum) && ::isConstructed(myHCrum->bertCrum()) */
			
			crutch_Flag = ::isConstructed(myHCrum);
			if(crutch_Flag) {
				crutch_Flag = ::isConstructed(myHCrum->bertCrum());
			}
			if (crutch_Flag) {
				myHCrum->bertCrum()->removePointer(myHCrum);
			}
		}
		myHCrum = NULL;
		this->Abraham::dismantle();
	} END_CONSISTENT;
}
/* hooks: */


void BeRangeElement::restartRE (APTR(Rcvr) /* rcvr */){
	myFeRangeElements = NULL;
}
/* comparing */


RPTR(BeEdition) BeRangeElement::works (
		APTR(IDRegion) permissions, 
		APTR(Filter) endorsementsFilter, 
		Int32 flags)
{
	/* See comment in FeRangeElement */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}



/* ************************************************************************ *
 * 
 *                    Class   BeDataHolder 
 *
 * ************************************************************************ */


/* accessing */


RPTR(FeRangeElement) BeDataHolder::makeFe (APTR(BeLabel) OR(NULL) label){
	/* Return me wrapped with a session level DataHolder. */
	
	WPTR(FeRangeElement) 	returnValue;
	returnValue = FeDataHolder::on(this);
	return returnValue;
}


RPTR(PrimValue) BeDataHolder::value (){
	return (PrimValue*) myValue;
}
/* create */


BeDataHolder::BeDataHolder (APTR(PrimValue) value, TCSJ) {
	myValue = value;
	this->newShepherd();
}



/* ************************************************************************ *
 * 
 *                    Class   BeIDHolder 
 *
 * ************************************************************************ */


/* creation */


RPTR(BeIDHolder) BeIDHolder::make (APTR(ID) iD){
	RETURN_CONSTRUCT(BeIDHolder,(iD, tcsj));
}
/* accessing */


RPTR(ID) BeIDHolder::iD (){
	return (ID*) myID;
}


RPTR(FeRangeElement) BeIDHolder::makeFe (APTR(BeLabel) OR(NULL) label){
	WPTR(FeRangeElement) 	returnValue;
	returnValue = FeIDHolder::on(this);
	return returnValue;
}
/* protected: dismantle */


void BeIDHolder::dismantle (){
	/* Does this need to clear the GrandMap table? */
	
	BLAST(NOT_YET_IMPLEMENTED);
}
/* protected: creation */


BeIDHolder::BeIDHolder (APTR(ID) iD, TCSJ) {
	myID = iD;
	this->newShepherd();
}



/* ************************************************************************ *
 * 
 *                    Class   BeLabel 
 *
 * ************************************************************************ */


/* accessing */


RPTR(FeRangeElement) BeLabel::makeFe (APTR(BeLabel) OR(NULL) label){
	WPTR(FeRangeElement) 	returnValue;
	returnValue = FeLabel::on(this);
	return returnValue;
}
/* creation */


BeLabel::BeLabel () {
	this->newShepherd();
	/* Hack !!!! */
	
	/* Labels don't know when they're pointed to as labels 
		instead of range elements, so just remember them. */
	this->remember();
}



/* ************************************************************************ *
 * 
 *                    Class   BePlaceHolder 
 *
 * ************************************************************************ */


/* accessing */


void BePlaceHolder::addDetector (APTR(FeFillDetector) detector){
	if (myDetectors == NULL) {
		myDetectors = PrimSet::weak(7, FillDetectorExecutor::make (this));
	}
	myDetectors->store(detector);
}


BooleanVar BePlaceHolder::isPurgeable (){
	{	BooleanVar crutch_Flag;
		/* this->BeRangeElement::isPurgeable() && myDetectors == NULL */
		
		crutch_Flag = this->BeRangeElement::isPurgeable();
		if(crutch_Flag) {
			crutch_Flag = myDetectors == NULL;
		}
		return crutch_Flag;
	}
}


RPTR(FeRangeElement) BePlaceHolder::makeFe (APTR(BeLabel) OR(NULL) label){
	WPTR(FeRangeElement) 	returnValue;
	returnValue = FePlaceHolder::on(this);
	return returnValue;
}


BooleanVar BePlaceHolder::makeIdentical (APTR(BeRangeElement) other){
	/* Change the identity of this object to that of the other. */
	/* Make all my persistent oParents point at the other guy.
		make all the session level FeRangeElements point at the other guy. */
	
	SPTR(ScruSet) OF1(OPart) oParents;
	
	oParents = this->hCrum()->oParents();
	/* Known bug !!!! */
	
	/* if there are several oParents then a given Detector may be 
		rung more than once */
	BEGIN_CONSISTENT(-1) {
		BEGIN_FOR_EACH(Loaf,loaf,(oParents->stepper())) {
			CAST(RegionLoaf,loaf)->forwardTo(other);
		} END_FOR_EACH;
	} END_CONSISTENT;
	BEGIN_FOR_EACH(FePlaceHolder,elem,(this->feRangeElements()->stepper())) {
		CAST(FeActualPlaceHolder,elem)->forwardTo(other);
	} END_FOR_EACH;
	if (myDetectors != NULL) {
		SPTR(FeRangeElement) fe;
		
		BEGIN_CHOOSE(other) {
			BEGIN_KIND(BeEdition,ed) {
				fe = ed->makeFe(CurrentGrandMap.fluidGet()->newLabel());
			} END_KIND;
			BEGIN_OTHERS {
				fe = other->makeFe(NULL);
			} END_OTHERS;
		} END_CHOOSE;
		BEGIN_FOR_EACH(FeFillDetector,det,(myDetectors->stepper())) {
			det->filled(fe);
		} END_FOR_EACH;
	}
	/* fodder */
	return FALSE;
}


void BePlaceHolder::removeDetector (APTR(FeFillDetector) detector){
	if (::isDestructed(myDetectors)) {
		return;
		
	}
	if (myDetectors == NULL) {
		BLAST(NotInSet);
	}
	myDetectors->remove(detector);
	if (myDetectors->isEmpty()) {
		myDetectors = NULL;
	}
}


void BePlaceHolder::removeLastDetector (){
	myDetectors = NULL;
}
/* creation */


BePlaceHolder::BePlaceHolder () 
	: BeRangeElement(SensorCrum::partial(), tcsj) {
	myTrailBlazer = NULL;
	myDetectors = NULL;
	this->newShepherd();
}


BePlaceHolder::BePlaceHolder (APTR(TrailBlazer) OR(NULL) blazer, TCSJ) 
	: BeRangeElement(SensorCrum::partial(), tcsj) {
	myTrailBlazer = blazer;
	if (blazer != NULL) {
		blazer->addReference(this);
	}
	myDetectors = NULL;
	this->newShepherd();
}
/* backfollow */


void BePlaceHolder::attachTrailBlazer (APTR(TrailBlazer) blazer){
	BEGIN_CONSISTENT(3) {
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
}


void BePlaceHolder::checkTrailBlazer (APTR(TrailBlazer) blazer){
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


RPTR(TrailBlazer) OR(NULL) BePlaceHolder::fetchTrailBlazer (){
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
/* hooks: */


void BePlaceHolder::restartP (APTR(Rcvr) /* rcvr */){
	myDetectors = NULL;
}



/* ************************************************************************ *
 * 
 *                    Class FillDetectorExecutor 
 *
 * ************************************************************************ */


/* create */


RPTR(XnExecutor) FillDetectorExecutor::make (APTR(BePlaceHolder) placeHolder){
	RETURN_CONSTRUCT(FillDetectorExecutor,(placeHolder, tcsj));
}
/* This class notifies its place holder when its last fill detector 
has gone away. */


/* protected: create */


FillDetectorExecutor::FillDetectorExecutor (APTR(BePlaceHolder) placeHolder, TCSJ) {
	myPlaceHolder = placeHolder;
}
/* execute */


void FillDetectorExecutor::execute (Int32 arg){
	if (arg == Int32Zero) {
		myPlaceHolder->removeLastDetector();
	}
}

#ifndef BRANGE1X_SXX
#include "brange1x.sxx"
#endif /* BRANGE1X_SXX */


#ifndef BRANGE1P_SXX
#include "brange1p.sxx"
#endif /* BRANGE1P_SXX */



#endif /* BRANGE1X_CXX */

