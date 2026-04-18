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

#ifndef PROPSX_CXX
#define PROPSX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef PROPSX_HXX
#include "propsx.hxx"
#endif /* PROPSX_HXX */

#ifndef PROPSX_IXX
#include "propsx.ixx"
#endif /* PROPSX_IXX */

#ifndef PROPSP_HXX
#include "propsp.hxx"
#endif /* PROPSP_HXX */

#ifndef PROPSP_IXX
#include "propsp.ixx"
#endif /* PROPSP_IXX */


#ifndef BRANGE2X_HXX
#include "brange2x.hxx"
#endif /* BRANGE2X_HXX */

#ifndef BRANGE3X_HXX
#include "brange3x.hxx"
#endif /* BRANGE3X_HXX */

#ifndef CANOPYX_HXX
#include "canopyx.hxx"
#endif /* CANOPYX_HXX */

#ifndef GRANMAPX_HXX
#include "granmapx.hxx"
#endif /* GRANMAPX_HXX */

#ifndef NKERNELX_HXX
#include "nkernelx.hxx"
#endif /* NKERNELX_HXX */

#ifndef TCLUDEX_HXX
#include "tcludex.hxx"
#endif /* TCLUDEX_HXX */




/* ************************************************************************ *
 * 
 *                    Class Prop 
 *
 * ************************************************************************ */


/* A collection of properties which are to be found by navigating a 
Canopy.  PropJoints are the union/intersection style abstraction of 
the properties which provide for such navigation. */


/* accessing */
/* tesing */


UInt32 Prop::actualHashForEqual (){
	return Heaper::takeOop();
}

	/* automatic 0-argument constructor */
Prop::Prop() {}



/* ************************************************************************ *
 * 
 *                    Class   BertProp 
 *
 * ************************************************************************ */



/* Initializers for BertProp */

GPTR(BertProp) BertProp::TheIdentityBertProp = NULL;


/* Initializers for BertProp */



/* creation */


RPTR(BertProp) BertProp::cannotPartializeProp (){
	
	WPTR(BertProp) 	returnValue;
	returnValue = BertProp::make (IDSpace::global()->emptyRegion(), CurrentGrandMap.fluidGet()->endorsementSpace()->emptyRegion(), FALSE, TRUE);
	return returnValue;
}


RPTR(BertProp) BertProp::detectorWaitingProp (){
	WPTR(BertProp) 	returnValue;
	returnValue = BertProp::make (CurrentGrandMap.fluidGet()->globalIDSpace()->emptyRegion(), CurrentGrandMap.fluidGet()->endorsementSpace()->emptyRegion(), TRUE, FALSE);
	return returnValue;
}


RPTR(BertProp) BertProp::endorsementsProp (APTR(XnRegion) endorsements){
	WPTR(BertProp) 	returnValue;
	returnValue = BertProp::make (IDSpace::global()->emptyRegion(), endorsements, FALSE, FALSE);
	return returnValue;
}


RPTR(BertProp) BertProp::make (){
	if (BertProp::TheIdentityBertProp == NULL) {
		BertProp::TheIdentityBertProp = 
				BertProp::make (IDSpace::global()->emptyRegion(), CurrentGrandMap.fluidGet()->endorsementSpace()->emptyRegion(), FALSE, FALSE);
	}
	WPTR(BertProp) 	returnValue;
	returnValue = BertProp::TheIdentityBertProp;
	return returnValue;
}


RPTR(BertProp) BertProp::make (
		APTR(XnRegion) OF1(ID) permissions, 
		APTR(XnRegion) endorsements, 
		BooleanVar isSensorWaiting, 
		BooleanVar isNotPartializable)
{
	RETURN_CONSTRUCT(BertProp,(permissions, endorsements, isSensorWaiting, isNotPartializable));
}


RPTR(BertProp) BertProp::permissionsProp (APTR(XnRegion) OF1(ID) iDs){
	WPTR(BertProp) 	returnValue;
	returnValue = BertProp::make (iDs, CurrentGrandMap.fluidGet()->endorsementSpace()->emptyRegion(), FALSE, FALSE);
	return returnValue;
}
/* The properties which are nevigable towards using the Bert Canopy.  
All of these are properties of the Stamps at the leaves of the Bert Canopy. */


/* accessing */


RPTR(CrossRegion) BertProp::endorsements (){
	return CAST(CrossRegion,myEndorsements);
}


UInt32 BertProp::flags (){
	return BertCrum::flagsFor(CAST(IDRegion,myPermissions), CAST(CrossRegion,myEndorsements), myCannotPartializeFlag, mySensorWaitingFlag);
}


BooleanVar BertProp::isNotPartializable (){
	return myCannotPartializeFlag;
}


BooleanVar BertProp::isSensorWaiting (){
	return mySensorWaitingFlag;
}


RPTR(XnRegion) OF1(ID) BertProp::permissions (){
	return (XnRegion*) myPermissions;
}


RPTR(Prop) BertProp::with (APTR(Prop) other){
	SPTR(BertProp) o;
	
	o = CAST(BertProp,other);
	WPTR(Prop) 	returnValue;
	returnValue = BertProp::make (myPermissions->unionWith(o->permissions()), myEndorsements->unionWith(o->endorsements()), mySensorWaitingFlag || o->isSensorWaiting(), myCannotPartializeFlag || o->isNotPartializable());
	return returnValue;
}
/* creation */


BertProp::BertProp (
		APTR(XnRegion) OF1(ID) permissions, 
		APTR(XnRegion) OF1(ID) endorsements, 
		BooleanVar isSensorWaiting, 
		BooleanVar isNotPartializable) 
{
	myPermissions = permissions;
	myEndorsements = endorsements;
	mySensorWaitingFlag = isSensorWaiting;
	myCannotPartializeFlag = isNotPartializable;
}
/* testing */


UInt32 BertProp::actualHashForEqual (){
	return myPermissions->hashForEqual() ^ myEndorsements->hashForEqual();
}


BooleanVar BertProp::isEmpty (){
	/* Does this do the right thing. */
	
	/* Known bug !!!! */
	
	{	BooleanVar crutch_Flag;
		/* myEndorsements->isEmpty() && myPermissions->isEmpty() */
		
		crutch_Flag = myEndorsements->isEmpty();
		if(crutch_Flag) {
			crutch_Flag = myPermissions->isEmpty();
		}
		return crutch_Flag;
	}
}


BooleanVar BertProp::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(BertProp,b) {
			{	BooleanVar crutch_Flag;
				/* b->endorsements()->isEqual(myEndorsements) && b->permissions()->isEqual(myPermissions) && b->isSensorWaiting() == mySensorWaitingFlag && b->isNotPartializable() == myCannotPartializeFlag */
				
				crutch_Flag = b->endorsements()->isEqual(myEndorsements);
				if(crutch_Flag) {
					crutch_Flag = b->permissions()->isEqual(myPermissions);
					if(crutch_Flag) {
						crutch_Flag = b->isSensorWaiting() == mySensorWaitingFlag;
						if(crutch_Flag) {
							crutch_Flag = b->isNotPartializable() == myCannotPartializeFlag;
						}
					}
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}
/* printing */


void BertProp::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(P: " << myPermissions << "; E: " << myEndorsements;
	if (mySensorWaitingFlag) {
		oo << "; sensor";
	}
	if (myCannotPartializeFlag) {
		oo << "; cannot partialize";
	}
	oo << ")";
}



/* ************************************************************************ *
 * 
 *                    Class   SensorProp 
 *
 * ************************************************************************ */



/* Initializers for SensorProp */

GPTR(SensorProp) SensorProp::TheIdentitySensorProp = NULL;
GPTR(SensorProp) SensorProp::ThePartialSensorProp = NULL;


/* Initializers for SensorProp */



/* creation */


RPTR(SensorProp) SensorProp::make (){
	/* returns an empty SensorProp */
	
	if (SensorProp::TheIdentitySensorProp == NULL) {
		CONSTRUCT(SensorProp::TheIdentitySensorProp,SensorProp,(CAST(IDRegion,CurrentGrandMap.fluidGet()->globalIDSpace()->emptyRegion()), CAST(CrossRegion,CurrentGrandMap.fluidGet()->endorsementSpace()->emptyRegion()), FALSE));
	}
	WPTR(SensorProp) 	returnValue;
	returnValue = SensorProp::TheIdentitySensorProp;
	return returnValue;
}


RPTR(SensorProp) SensorProp::make (
		APTR(IDRegion) relevantPermissions, 
		APTR(CrossRegion) relevantEndorsements, 
		BooleanVar isPartial)
{
	RETURN_CONSTRUCT(SensorProp,(relevantPermissions, relevantEndorsements, isPartial));
}


RPTR(SensorProp) SensorProp::partial (){
	/* returns an empty SensorProp with the partial flag on */
	
	if (SensorProp::ThePartialSensorProp == NULL) {
		CONSTRUCT(SensorProp::ThePartialSensorProp,SensorProp,(CAST(IDRegion,CurrentGrandMap.fluidGet()->globalIDSpace()->emptyRegion()), CAST(CrossRegion,CurrentGrandMap.fluidGet()->endorsementSpace()->emptyRegion()), TRUE));
	}
	WPTR(SensorProp) 	returnValue;
	returnValue = SensorProp::ThePartialSensorProp;
	return returnValue;
}
/* The properties which are nevigable towards using the Sensor 
Canopy.  The permissions and endorsements are those whose changes may 
affect the triggering of the recorders that decorate the canopy.  
myPartialFlag is a property of the o-leaf-stuff which are at the 
leaves of the Sensor Canopy. */


/* creation */


SensorProp::SensorProp (
		APTR(IDRegion) relevantPermissions, 
		APTR(CrossRegion) OF2(IDRegion,IDRegion) relevantEndorsements, 
		BooleanVar isPartial) 
{
	myRelevantPermissions = relevantPermissions;
	myRelevantEndorsements = relevantEndorsements;
	myPartialFlag = isPartial;
}
/* accessing */


UInt32 SensorProp::flags (){
	return SensorCrum::flagsFor(myRelevantPermissions, myRelevantEndorsements, myPartialFlag);
}


BooleanVar SensorProp::isPartial (){
	return myPartialFlag;
}


RPTR(CrossRegion) SensorProp::relevantEndorsements (){
	return (CrossRegion*) myRelevantEndorsements;
}


RPTR(IDRegion) SensorProp::relevantPermissions (){
	return (IDRegion*) myRelevantPermissions;
}


RPTR(Prop) SensorProp::with (APTR(Prop) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(SensorProp,o) {
			WPTR(Prop) 	returnValue;
			returnValue = SensorProp::make (CAST(IDRegion,myRelevantPermissions->unionWith(o->relevantPermissions())), CAST(CrossRegion,myRelevantEndorsements->unionWith(o->relevantEndorsements())), myPartialFlag || o->isPartial());
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* compiler fodder */
	return NULL;
}
/* testing */


UInt32 SensorProp::actualHashForEqual (){
	return myRelevantPermissions->hashForEqual() ^ myRelevantEndorsements->hashForEqual();
}


BooleanVar SensorProp::isEqual (APTR(Heaper) heaper){
	BEGIN_CHOOSE(heaper) {
		BEGIN_KIND(SensorProp,prop) {
			{	BooleanVar crutch_Flag;
				/* myRelevantEndorsements->isEqual(prop->relevantEndorsements()) && myRelevantPermissions->isEqual(prop->relevantPermissions()) && myPartialFlag == prop->isPartial() */
				
				crutch_Flag = myRelevantEndorsements->isEqual(prop->relevantEndorsements());
				if(crutch_Flag) {
					crutch_Flag = myRelevantPermissions->isEqual(prop->relevantPermissions());
					if(crutch_Flag) {
						crutch_Flag = myPartialFlag == prop->isPartial();
					}
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}
/* printing */


void SensorProp::printOn (ostream& oo){
	oo << "SensorProp(P: " << myRelevantPermissions << "; E: " << myRelevantEndorsements;
	if (myPartialFlag) {
		oo << "; partial";
	}
	oo << ")";
}



/* ************************************************************************ *
 * 
 *                    Class PropChange 
 *
 * ************************************************************************ */



/* Initializers for PropChange */

GPTR(PropChange) PropChange::TheCannotPartializeChange = NULL;
GPTR(PropChange) PropChange::TheDetectorWaitingChange = NULL;
GPTR(PropChange) PropChange::TheEndorsementsChange = NULL;
GPTR(PropChange) PropChange::TheBertPropChange = NULL;
GPTR(PropChange) PropChange::TheSensorPropChange = NULL;
GPTR(PropChange) PropChange::ThePermissionsChange = NULL;



BEGIN_INIT_TIME(PropChange,initTimeNonInherited) {
	CONSTRUCT(PropChange::TheCannotPartializeChange,CannotPartializeChange,());
	CONSTRUCT(PropChange::TheDetectorWaitingChange,DetectorWaitingChange,());
	CONSTRUCT(PropChange::TheEndorsementsChange,EndorsementsChange,());
	CONSTRUCT(PropChange::TheBertPropChange,BertPropChange,());
	CONSTRUCT(PropChange::TheSensorPropChange,SensorPropChange,());
	CONSTRUCT(PropChange::ThePermissionsChange,PermissionsChange,());
} END_INIT_TIME(PropChange,initTimeNonInherited);



/* Initializers for PropChange */






/* pseudo constructors */


RPTR(PropChange) PropChange::bertPropChange (){
	WPTR(PropChange) 	returnValue;
	returnValue = PropChange::TheBertPropChange;
	return returnValue;
}


RPTR(PropChange) PropChange::cannotPartializeChange (){
	WPTR(PropChange) 	returnValue;
	returnValue = PropChange::TheCannotPartializeChange;
	return returnValue;
}


RPTR(PropChange) PropChange::detectorWaitingChange (){
	WPTR(PropChange) 	returnValue;
	returnValue = PropChange::TheDetectorWaitingChange;
	return returnValue;
}


RPTR(PropChange) PropChange::endorsementsChange (){
	WPTR(PropChange) 	returnValue;
	returnValue = PropChange::TheEndorsementsChange;
	return returnValue;
}


RPTR(PropChange) PropChange::permissionsChange (){
	WPTR(PropChange) 	returnValue;
	returnValue = PropChange::ThePermissionsChange;
	return returnValue;
}


RPTR(PropChange) PropChange::sensorPropChange (){
	/* Returns the canonical PropChange object for propagating 
	the properties that result from installing a recorder 
	(permissions and endorsement filters).  A better name would 
	be recorderPropChange */
	
	WPTR(PropChange) 	returnValue;
	returnValue = PropChange::TheSensorPropChange;
	return returnValue;
}
/* Each concrete class has just one canonical instance and no state.  
A PropChange is used to represent which property aspect changed (such 
as permission vs endorsement vs both). */


/* accessing */
/* testing */


UInt32 PropChange::actualHashForEqual (){
	return this->takeOop();
}


BooleanVar PropChange::isEqual (APTR(Heaper) other){
	return this == other;
}

	/* automatic 0-argument constructor */
PropChange::PropChange() {}



/* ************************************************************************ *
 * 
 *                    Class PropFinder 
 *
 * ************************************************************************ */


/* creation */


RPTR(PropFinder) PropFinder::backfollowFinder (APTR(Filter) OF1(XnRegion OF1(ID)) permissionsFilter){
	if (permissionsFilter->isEmpty()) {
		WPTR(PropFinder) 	returnValue;
		returnValue = PropFinder::closedPropFinder();
		return returnValue;
	} else {
		RETURN_CONSTRUCT(BackfollowPFinder,(
			BertCrum::flagsFor(CAST(IDRegion,permissionsFilter->relevantRegion()), NULL, FALSE, FALSE), permissionsFilter));
	}
}


RPTR(PropFinder) PropFinder::backfollowFinder (APTR(Filter) OF1(XnRegion OF1(ID)) permissionsFilter, APTR(Filter) OF1(XnRegion OF1(ID)) endorsementsFilter){
	{	BooleanVar crutch_Flag;
		/* permissionsFilter->isEmpty() || endorsementsFilter->isEmpty() */
		
		crutch_Flag = permissionsFilter->isEmpty();
		if(!crutch_Flag) {
			crutch_Flag = endorsementsFilter->isEmpty();
		}
		if (crutch_Flag) {
			WPTR(PropFinder) 	returnValue;
			returnValue = PropFinder::closedPropFinder();
			return returnValue;
		}
	}
	if (endorsementsFilter->isFull()) {
		RETURN_CONSTRUCT(BackfollowPFinder,(
			BertCrum::flagsFor(CAST(IDRegion,permissionsFilter->relevantRegion()), NULL, FALSE, FALSE), permissionsFilter));
	}
	RETURN_CONSTRUCT(BackfollowFinder,(
		BertCrum::flagsFor(CAST(IDRegion,permissionsFilter->relevantRegion()), CAST(CrossRegion,endorsementsFilter->relevantRegion()), FALSE, FALSE), permissionsFilter, endorsementsFilter));
}


RPTR(PropFinder) PropFinder::cannotPartializeFinder (){
	RETURN_CONSTRUCT(CannotPartializeFinder,());
}


RPTR(PropFinder) PropFinder::closedPropFinder (){
	RETURN_CONSTRUCT(ClosedPropFinder,());
}


RPTR(PropFinder) PropFinder::openPropFinder (){
	RETURN_CONSTRUCT(OpenPropFinder,());
}


RPTR(PropFinder) PropFinder::sensorFinder (){
	RETURN_CONSTRUCT(SensorFinder,());
}
/* For filtering by canopies.  Matches against Props and CanopyCrum flags */


/* create */


PropFinder::PropFinder () {
	
}


PropFinder::PropFinder (UInt32 flags, TCSJ) {
	myFlags = flags;
}
/* accessing */


BooleanVar PropFinder::doesPass (APTR(CanopyCrum) parent){
	/* return whether the propJoint passes the finder */
	
	return (myFlags | parent->flags()) != UInt32Zero;
}


UInt32 PropFinder::flags (){
	return myFlags;
}


BooleanVar PropFinder::isEmpty (){
	/* Overridden only in ClosedPropFinder */
	
	return FALSE;
}


BooleanVar PropFinder::isFull (){
	/* Overridden only in OpenPropFinder */
	
	return FALSE;
}


RPTR(PropFinder) PropFinder::pass (APTR(CanopyCrum) parent){
	/* return a simple enough finder for looking at the children */
	
	if (this->doesPass(parent)) {
		return this;
	} else {
		WPTR(PropFinder) 	returnValue;
		returnValue = PropFinder::closedPropFinder();
		return returnValue;
	}
}
/* testing */


UInt32 PropFinder::actualHashForEqual (){
	return Heaper::takeOop();
}



/* ************************************************************************ *
 * 
 *                    Class BertPropFinder 
 *
 * ************************************************************************ */


/* Used to filter by the bert canopy */


/* create */


BertPropFinder::BertPropFinder () {
	
}


BertPropFinder::BertPropFinder (UInt32 flags, TCSJ) 
	: PropFinder(flags, tcsj) {
	
}
/* accessing */



/* ************************************************************************ *
 * 
 *                    Class   BackfollowFinder 
 *
 * ************************************************************************ */


/* Finder used to filter the htree walk by the bert canopy when doing 
a backFollow which uses both permissions and endorsement filters */


/* creation */


BackfollowFinder::BackfollowFinder (
		UInt32 flags, 
		APTR(Filter) OF1(XnRegion OF1(ID)) permissionsFilter, 
		APTR(Filter) OF1(CrossRegion OF1(ID)) endorsementsFilter) 

	: BertPropFinder(flags, tcsj) {
	myPermissionsFilter = permissionsFilter;
	myEndorsementsFilter = endorsementsFilter;
}
/* accessing */


RPTR(Filter) OF1(XnRegion OF1(ID)) BackfollowFinder::endorsementsFilter (){
	return (Filter*) myEndorsementsFilter;
}


RPTR(PropFinder) BackfollowFinder::findPast (APTR(BeEdition) edition){
	BooleanVar canSee;
	SPTR(XnRegion) endorsements;
	
	/* Ravi -- Thing to do !!!! */
	
	/* use regions in finder so that we don't need to create 
		intermediate objects */
	canSee = FALSE;
	endorsements = edition->endorsements();
	BEGIN_FOR_EACH(BeWork,work,(edition->currentWorks()->stepper())) {
		{	BooleanVar crutch_Flag;
			/* work->fetchReadClub() != NULL && myPermissionsFilter->match(work->fetchReadClub()->asRegion()) || work->fetchEditClub() != NULL && myPermissionsFilter->match(work->fetchEditClub()->asRegion()) */
			
			crutch_Flag = work->fetchReadClub() != NULL;
			if(crutch_Flag) {
				crutch_Flag = myPermissionsFilter->match(work->fetchReadClub()->asRegion());
			}
			if(!crutch_Flag) {
				crutch_Flag = work->fetchEditClub() != NULL;
				if(crutch_Flag) {
					crutch_Flag = myPermissionsFilter->match(work->fetchEditClub()->asRegion());
				}
			}
			if (crutch_Flag) {
				canSee = TRUE;
				endorsements = endorsements->unionWith(work->endorsements());
			}
		}
	} END_FOR_EACH;
	if (myEndorsementsFilter->match(endorsements)) {
		if (canSee) {
			WPTR(PropFinder) 	returnValue;
			returnValue = PropFinder::openPropFinder();
			return returnValue;
		} else {
			WPTR(PropFinder) 	returnValue;
			returnValue = PropFinder::backfollowFinder(myPermissionsFilter);
			return returnValue;
		}
	}
	return this;
}


BooleanVar BackfollowFinder::match (APTR(Prop) prop){
	/* tell whether a prop matches this filter */
	
	WPTR(BertProp) p;
	
	p = CAST(BertProp,prop);
	{	BooleanVar crutch_Flag;
		/* myPermissionsFilter->match(p->permissions()) && myEndorsementsFilter->match(p->endorsements()) */
		
		crutch_Flag = myPermissionsFilter->match(p->permissions());
		if(crutch_Flag) {
			crutch_Flag = myEndorsementsFilter->match(p->endorsements());
		}
		return crutch_Flag;
	}
}


RPTR(Filter) OF1(XnRegion OF1(ID)) BackfollowFinder::permissionsFilter (){
	return (Filter*) myPermissionsFilter;
}
/* testing */


UInt32 BackfollowFinder::actualHashForEqual (){
	return this->getCategory()->hashForEqual() ^ myPermissionsFilter->hashForEqual() ^ myEndorsementsFilter->hashForEqual();
}


BooleanVar BackfollowFinder::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(BackfollowFinder,o) {
			{	BooleanVar crutch_Flag;
				/* myPermissionsFilter->isEqual(o->permissionsFilter()) && myEndorsementsFilter->isEqual(o->endorsementsFilter()) */
				
				crutch_Flag = myPermissionsFilter->isEqual(o->permissionsFilter());
				if(crutch_Flag) {
					crutch_Flag = myEndorsementsFilter->isEqual(o->endorsementsFilter());
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}



/* ************************************************************************ *
 * 
 *                    Class   BackfollowPFinder 
 *
 * ************************************************************************ */


/* Finder used to filter the htree walk by the bert canopy when doing 
a backFollow which uses just permissions filters */


/* creation */


BackfollowPFinder::BackfollowPFinder (UInt32 flags, APTR(Filter) OF1(XnRegion OF1(ID)) permissionsFilter) 
	: BertPropFinder(flags, tcsj) {
	myPermissionsFilter = permissionsFilter;
}
/* accessing */


RPTR(PropFinder) BackfollowPFinder::findPast (APTR(BeEdition) edition){
	/* Ravi -- Thing to do !!!! */
	
	/* use regions in finder so that we don't need to create 
		intermediate objects */
	BEGIN_FOR_EACH(BeWork,work,(edition->currentWorks()->stepper())) {
		{	BooleanVar crutch_Flag;
			/* work->fetchReadClub() != NULL && myPermissionsFilter->match(work->fetchReadClub()->asRegion()) || work->fetchEditClub() != NULL && myPermissionsFilter->match(work->fetchEditClub()->asRegion()) */
			
			crutch_Flag = work->fetchReadClub() != NULL;
			if(crutch_Flag) {
				crutch_Flag = myPermissionsFilter->match(work->fetchReadClub()->asRegion());
			}
			if(!crutch_Flag) {
				crutch_Flag = work->fetchEditClub() != NULL;
				if(crutch_Flag) {
					crutch_Flag = myPermissionsFilter->match(work->fetchEditClub()->asRegion());
				}
			}
			if (crutch_Flag) {
				WPTR(PropFinder) 	returnValue;
				returnValue = PropFinder::openPropFinder();
				return returnValue;
			}
		}
	} END_FOR_EACH;
	return this;
}


BooleanVar BackfollowPFinder::match (APTR(Prop) prop){
	/* tell whether a prop matches this filter */
	
	return myPermissionsFilter->match(CAST(BertProp,prop)->permissions());
}


RPTR(Filter) OF1(XnRegion OF1(ID)) BackfollowPFinder::permissionsFilter (){
	return (Filter*) myPermissionsFilter;
}
/* testing */


UInt32 BackfollowPFinder::actualHashForEqual (){
	return this->getCategory()->hashForEqual() ^ myPermissionsFilter->hashForEqual();
}


BooleanVar BackfollowPFinder::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(BackfollowPFinder,o) {
			return myPermissionsFilter->isEqual(o->permissionsFilter());
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}



/* ************************************************************************ *
 * 
 *                    Class   CannotPartializeFinder 
 *
 * ************************************************************************ */


/* Used to figure out which Stamps have Orgls on them so that the 
archiver can knw that they cannot be partialized.  Will go away 
because the state described is session level state and therefore 
should be store in NOCOPY variables instead of in the Canopy's Props. */


/* create */


CannotPartializeFinder::CannotPartializeFinder () 
	: BertPropFinder(BertCrum::isNotPartializableFlag(), tcsj) {
	
}
/* accessing */


RPTR(PropFinder) CannotPartializeFinder::findPast (APTR(BeEdition) /* edition */){
	/* inability to partialize is transitive */
	return this;
}


BooleanVar CannotPartializeFinder::match (APTR(Prop) prop){
	/* tell whether a prop matches this filter */
	
	return CAST(BertProp,prop)->isNotPartializable();
}
/* testing */


UInt32 CannotPartializeFinder::actualHashForEqual (){
	return this->getCategory()->hashForEqual();
}


BooleanVar CannotPartializeFinder::isEqual (APTR(Heaper) other){
	return other->isKindOf(cat_CannotPartializeFinder);
}



/* ************************************************************************ *
 * 
 *                    Class   SensorFinder 
 *
 * ************************************************************************ */


/* Currently unused but will be re-instated.  Used to find which 
containing Editions have WaitForCompletionDetectors installed on them 
so that they can be rung when placegholders get filled in. */


/* create */


SensorFinder::SensorFinder () 
	: BertPropFinder(BertCrum::isSensorWaitingFlag(), tcsj) {
	
}
/* accessing */


RPTR(PropFinder) SensorFinder::findPast (APTR(BeEdition) /* edition */){
	/* Dont look for Detectors past an Edition boundary */
	WPTR(PropFinder) 	returnValue;
	returnValue = PropFinder::closedPropFinder();
	return returnValue;
}


BooleanVar SensorFinder::match (APTR(Prop) prop){
	/* tell whether a prop matches this filter */
	
	return CAST(BertProp,prop)->isSensorWaiting();
}
/* testing */


UInt32 SensorFinder::actualHashForEqual (){
	return this->getCategory()->hashForEqual();
}


BooleanVar SensorFinder::isEqual (APTR(Heaper) other){
	return other->isKindOf(cat_SensorFinder);
}



/* ************************************************************************ *
 * 
 *                    Class CannotPartializeChange 
 *
 * ************************************************************************ */


/* The "Cannot Partialize" property is a Bert Canopy property to 
remember that a Stamp is actively being viewed (by a session level 
Orgl) and therefore cannot be poured-out (made more partial).  Should 
probably not be a Prop(erty), by rather a NOCOPY session level bit in 
the BertCrums. */


/* accessing */


BooleanVar CannotPartializeChange::areEqualProps (APTR(Prop) a, APTR(Prop) b){
	/* compare the changed parts of two Props */
	
	return CAST(BertProp,a)->isNotPartializable() == CAST(BertProp,b)->isNotPartializable();
}


RPTR(Prop) CannotPartializeChange::changed (APTR(Prop) old, APTR(Prop) a){
	WPTR(BertProp) bp;
	WPTR(BertProp) abp;
	
	bp = CAST(BertProp,old);
	abp = CAST(BertProp,a);
	if (bp->isNotPartializable() == abp->isNotPartializable()) {
		WPTR(Prop) 	returnValue;
		returnValue = old;
		return returnValue;
	}
	WPTR(Prop) 	returnValue;
	returnValue = BertProp::make (bp->permissions(), bp->endorsements(), bp->isSensorWaiting(), abp->isNotPartializable());
	return returnValue;
}


RPTR(PropFinder) OR(NULL) CannotPartializeChange::fetchFinder (
		APTR(Prop) /* before */, 
		APTR(Prop) /* after */, 
		APTR(BeRangeElement) /* element */, 
		APTR(PropFinder) OR(NULL) /* oldFinder */)
{
	return NULL;
}


BooleanVar CannotPartializeChange::isFull (){
	/* whether this is a complete change of props */
	
	return FALSE;
}


RPTR(Prop) CannotPartializeChange::with (APTR(Prop) old, APTR(Prop) a){
	WPTR(BertProp) bp;
	WPTR(BertProp) abp;
	
	bp = CAST(BertProp,old);
	abp = CAST(BertProp,a);
	{	BooleanVar crutch_Flag;
		/* bp->isNotPartializable() || !abp->isNotPartializable() */
		
		crutch_Flag = bp->isNotPartializable();
		if(!crutch_Flag) {
			crutch_Flag = !abp->isNotPartializable();
		}
		if (crutch_Flag) {
			WPTR(Prop) 	returnValue;
			returnValue = old;
			return returnValue;
		} else {
			WPTR(Prop) 	returnValue;
			returnValue = BertProp::make (bp->permissions(), bp->endorsements(), bp->isSensorWaiting(), abp->isNotPartializable());
			return returnValue;
		}
	}
}

	/* automatic 0-argument constructor */
CannotPartializeChange::CannotPartializeChange() {}



/* ************************************************************************ *
 * 
 *                    Class ClosedPropFinder 
 *
 * ************************************************************************ */


/* The finder which matches nothing.  Used to indicate that this 
subtree is known to be useless (no matches possible below here). */


/* accessing */


RPTR(PropFinder) ClosedPropFinder::findPast (APTR(BeEdition) /* stamp */){
	return this;
}


BooleanVar ClosedPropFinder::isEmpty (){
	/* Overridden only here */
	
	return TRUE;
}


BooleanVar ClosedPropFinder::match (APTR(Prop) /* prop */){
	/* tell whether a prop matches this filter */
	
	return FALSE;
}


RPTR(PropFinder) ClosedPropFinder::pass (APTR(CanopyCrum) /* crum */){
	return this;
}
/* testing */


UInt32 ClosedPropFinder::actualHashForEqual (){
	return this->getCategory()->hashForEqual();
}


BooleanVar ClosedPropFinder::isEqual (APTR(Heaper) other){
	return other->isKindOf(cat_ClosedPropFinder);
}
/* create */


ClosedPropFinder::ClosedPropFinder () 
	: PropFinder(UInt32Zero, tcsj) {
	
}



/* ************************************************************************ *
 * 
 *                    Class DetectorWaitingChange 
 *
 * ************************************************************************ */


/* The "Detector Waiting" property is a Bert Canopy property to 
remember that an Edition has a Detector waiting for PlaceHolders to 
be filled in. */


/* accessing */


BooleanVar DetectorWaitingChange::areEqualProps (APTR(Prop) a, APTR(Prop) b){
	/* compare the changed parts of two Props */
	
	return CAST(BertProp,a)->isSensorWaiting() == CAST(BertProp,b)->isSensorWaiting();
}


RPTR(Prop) DetectorWaitingChange::changed (APTR(Prop) old, APTR(Prop) a){
	WPTR(BertProp) bp;
	WPTR(BertProp) abp;
	
	bp = CAST(BertProp,old);
	abp = CAST(BertProp,a);
	if (bp->isSensorWaiting() == abp->isSensorWaiting()) {
		WPTR(Prop) 	returnValue;
		returnValue = old;
		return returnValue;
	}
	WPTR(Prop) 	returnValue;
	returnValue = BertProp::make (bp->permissions(), bp->endorsements(), abp->isSensorWaiting(), bp->isNotPartializable());
	return returnValue;
}


RPTR(PropFinder) OR(NULL) DetectorWaitingChange::fetchFinder (
		APTR(Prop) /* before */, 
		APTR(Prop) /* after */, 
		APTR(BeRangeElement) /* element */, 
		APTR(PropFinder) OR(NULL) /* oldFinder */)
{
	return NULL;
}


BooleanVar DetectorWaitingChange::isFull (){
	return FALSE;
}


RPTR(Prop) DetectorWaitingChange::with (APTR(Prop) old, APTR(Prop) a){
	WPTR(BertProp) bp;
	WPTR(BertProp) abp;
	
	bp = CAST(BertProp,old);
	abp = CAST(BertProp,a);
	{	BooleanVar crutch_Flag;
		/* bp->isSensorWaiting() || !abp->isSensorWaiting() */
		
		crutch_Flag = bp->isSensorWaiting();
		if(!crutch_Flag) {
			crutch_Flag = !abp->isSensorWaiting();
		}
		if (crutch_Flag) {
			WPTR(Prop) 	returnValue;
			returnValue = old;
			return returnValue;
		} else {
			WPTR(Prop) 	returnValue;
			returnValue = BertProp::make (bp->permissions(), bp->endorsements(), abp->isSensorWaiting(), bp->isNotPartializable());
			return returnValue;
		}
	}
}

	/* automatic 0-argument constructor */
DetectorWaitingChange::DetectorWaitingChange() {}



/* ************************************************************************ *
 * 
 *                    Class EndorsementsChange 
 *
 * ************************************************************************ */


/* Used when the Endorsement part of a BertProp changed */


/* accessing */


BooleanVar EndorsementsChange::areEqualProps (APTR(Prop) a, APTR(Prop) b){
	/* compare the changed parts of two Props */
	
	return CAST(BertProp,a)->endorsements()->isEqual(CAST(BertProp,b)->endorsements());
}


RPTR(Prop) EndorsementsChange::changed (APTR(Prop) old, APTR(Prop) a){
	WPTR(BertProp) bp;
	
	bp = CAST(BertProp,old);
	WPTR(Prop) 	returnValue;
	returnValue = BertProp::make (bp->permissions(), CAST(BertProp,a)->endorsements(), bp->isSensorWaiting(), bp->isNotPartializable());
	return returnValue;
}


RPTR(PropFinder) OR(NULL) EndorsementsChange::fetchFinder (
		APTR(Prop) before, 
		APTR(Prop) after, 
		APTR(BeRangeElement) element, 
		APTR(PropFinder) OR(NULL) oldFinder)
{
	BEGIN_CHOOSE(before) {
		BEGIN_KIND(BertProp,b) {
			BEGIN_CHOOSE(after) {
				BEGIN_KIND(BertProp,a) {
					SPTR(PropFinder) result;
					SPTR(RegionDelta) delta;
					SPTR(PropFinder) any;
					SPTR(ImmuSet) anys;
					SPTR(PropFinder) simple;
					SPTR(ImmuSet) simples;
					
					delta = RegionDelta::make (b->endorsements(), a->endorsements());
					if (delta->isSame()) {
						return NULL;
					}
					any = AnyRecorderEFinder::make (CAST(IDRegion,a->permissions()), delta);
					if (any->isEmpty()) {
						anys = ImmuSet::make ();
					} else {
						anys = ImmuSet::newWith(any);
					}
					simple = 
							OriginalResultRecorderEFinder::make (element, CAST(IDRegion,a->permissions()), delta);
					if (simple->isEmpty()) {
						simples = ImmuSet::make ();
					} else {
						simples = ImmuSet::newWith(simple);
					}
					if (oldFinder == NULL) {
						result = 
								CumulativeRecorderFinder::make (anys, simples, ImmuSet::make ());
					} else {
						BEGIN_CHOOSE(oldFinder) {
							BEGIN_KIND(CumulativeRecorderFinder,crf) {
								result = 
										CumulativeRecorderFinder::make (anys, simples, crf->current()->unionWith(crf->others()));
							} END_KIND;
						} END_CHOOSE;
					}
					if (result->isEmpty()) {
						return NULL;
					} else {
						WPTR(PropFinder) OR(NULL) 	returnValue;
						returnValue = result;
						return returnValue;
					}
				} END_KIND;
			} END_CHOOSE;
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return NULL;
}


BooleanVar EndorsementsChange::isFull (){
	/* whether this is a complete change of props */
	
	return FALSE;
}


RPTR(Prop) EndorsementsChange::with (APTR(Prop) old, APTR(Prop) a){
	WPTR(BertProp) bp;
	
	bp = CAST(BertProp,old);
	WPTR(Prop) 	returnValue;
	returnValue = BertProp::make (bp->permissions(), CAST(BertProp,a)->endorsements()->unionWith(bp->endorsements()), bp->isSensorWaiting(), bp->isNotPartializable());
	return returnValue;
}

	/* automatic 0-argument constructor */
EndorsementsChange::EndorsementsChange() {}



/* ************************************************************************ *
 * 
 *                    Class FullPropChange 
 *
 * ************************************************************************ */


/* Use this to indicate that all aspects of the Prop may have changed. */


/* accessing */


BooleanVar FullPropChange::areEqualProps (APTR(Prop) a, APTR(Prop) b){
	/* compare the changed parts of two Props */
	
	return a->isEqual(b);
}


RPTR(Prop) FullPropChange::changed (APTR(Prop) /* old */, APTR(Prop) a){
	WPTR(Prop) 	returnValue;
	returnValue = a;
	return returnValue;
}


BooleanVar FullPropChange::isFull (){
	/* whether this is a complete change of props */
	
	return TRUE;
}


RPTR(Prop) FullPropChange::with (APTR(Prop) old, APTR(Prop) a){
	WPTR(Prop) 	returnValue;
	returnValue = old->with(a);
	return returnValue;
}

	/* automatic 0-argument constructor */
FullPropChange::FullPropChange() {}



/* ************************************************************************ *
 * 
 *                    Class   BertPropChange 
 *
 * ************************************************************************ */


/* Use when it is fine to consider that all aspects of the BertProp 
may have changed */


/* accessing */


RPTR(PropFinder) OR(NULL) BertPropChange::fetchFinder (
		APTR(Prop) before, 
		APTR(Prop) after, 
		APTR(BeRangeElement) element, 
		APTR(PropFinder) OR(NULL) oldFinder)
{
	SPTR(PropFinder) p;
	SPTR(PropFinder) e;
	
	p = 
			PropChange::permissionsChange()->fetchFinder(before, after, element, oldFinder);
	e = 
			PropChange::endorsementsChange()->fetchFinder(before, after, element, oldFinder);
	if (p == NULL) {
		WPTR(PropFinder) OR(NULL) 	returnValue;
		returnValue = e;
		return returnValue;
	}
	if (e == NULL) {
		WPTR(PropFinder) OR(NULL) 	returnValue;
		returnValue = p;
		return returnValue;
	}
	BEGIN_CHOOSE(p) {
		BEGIN_KIND(CumulativeRecorderFinder,pcrf) {
			BEGIN_CHOOSE(e) {
				BEGIN_KIND(CumulativeRecorderFinder,ecrf) {
					WPTR(PropFinder) OR(NULL) 	returnValue;
					returnValue = CumulativeRecorderFinder::make (pcrf->generators()->unionWith(ecrf->generators()), pcrf->current()->unionWith(ecrf->current()), pcrf->others()->unionWith(ecrf->others()));
					return returnValue;
				} END_KIND;
			} END_CHOOSE;
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return NULL;
}

	/* automatic 0-argument constructor */
BertPropChange::BertPropChange() {}



/* ************************************************************************ *
 * 
 *                    Class   SensorPropChange 
 *
 * ************************************************************************ */


/* Use when it is fine to consider that all aspects of the SensorProp 
may have changed */


/* accessing */


RPTR(PropFinder) OR(NULL) SensorPropChange::fetchFinder (
		APTR(Prop) /* before */, 
		APTR(Prop) /* after */, 
		APTR(BeRangeElement) /* element */, 
		APTR(PropFinder) OR(NULL) /* oldFinder */)
{
	return NULL;
}

	/* automatic 0-argument constructor */
SensorPropChange::SensorPropChange() {}



/* ************************************************************************ *
 * 
 *                    Class OpenPropFinder 
 *
 * ************************************************************************ */


/* The finder which matches everything.  Used to indicate that 
everything below here necessarily matches. */


/* accessing */


RPTR(PropFinder) OpenPropFinder::findPast (APTR(BeEdition) /* stamp */){
	return this;
}


BooleanVar OpenPropFinder::isFull (){
	return TRUE;
}


BooleanVar OpenPropFinder::match (APTR(Prop) /* prop */){
	/* tell whether a prop matches this filter */
	
	return TRUE;
}


RPTR(PropFinder) OpenPropFinder::pass (APTR(CanopyCrum) /* crum */){
	return this;
}
/* testing */


UInt32 OpenPropFinder::actualHashForEqual (){
	return this->getCategory()->hashForEqual();
}


BooleanVar OpenPropFinder::isEqual (APTR(Heaper) other){
	return other->isKindOf(cat_OpenPropFinder);
}
/* create */


OpenPropFinder::OpenPropFinder () 
	: PropFinder(~UInt32Zero, tcsj) {
	
}



/* ************************************************************************ *
 * 
 *                    Class PermissionsChange 
 *
 * ************************************************************************ */


/* Used when the Permissions part of a BertProp changed */


/* accessing */


BooleanVar PermissionsChange::areEqualProps (APTR(Prop) a, APTR(Prop) b){
	/* compare the changed parts of two Props */
	
	return CAST(BertProp,a)->permissions()->isEqual(CAST(BertProp,b)->permissions());
}


RPTR(Prop) PermissionsChange::changed (APTR(Prop) old, APTR(Prop) a){
	WPTR(BertProp) bp;
	
	bp = CAST(BertProp,old);
	WPTR(Prop) 	returnValue;
	returnValue = BertProp::make (CAST(BertProp,a)->permissions(), bp->endorsements(), bp->isSensorWaiting(), bp->isNotPartializable());
	return returnValue;
}


RPTR(PropFinder) OR(NULL) PermissionsChange::fetchFinder (
		APTR(Prop) before, 
		APTR(Prop) after, 
		APTR(BeRangeElement) element, 
		APTR(PropFinder) OR(NULL) oldFinder)
{
	BEGIN_CHOOSE(before) {
		BEGIN_KIND(BertProp,b) {
			BEGIN_CHOOSE(after) {
				BEGIN_KIND(BertProp,a) {
					SPTR(PropFinder) result;
					SPTR(RegionDelta) delta;
					SPTR(PropFinder) any;
					SPTR(ImmuSet) anys;
					SPTR(PropFinder) simple;
					SPTR(ImmuSet) simples;
					
					delta = RegionDelta::make (b->permissions(), a->permissions());
					if (delta->isSame()) {
						return NULL;
					}
					any = AnyRecorderPFinder::make (delta);
					if (any->isEmpty()) {
						anys = ImmuSet::make ();
					} else {
						anys = ImmuSet::newWith(any);
					}
					simple = 
							ResultRecorderPFinder::make (element, delta, a->endorsements());
					if (simple->isEmpty()) {
						simples = ImmuSet::make ();
					} else {
						simples = ImmuSet::newWith(simple);
					}
					if (oldFinder == NULL) {
						result = 
								CumulativeRecorderFinder::make (anys, simples, ImmuSet::make ());
					} else {
						BEGIN_CHOOSE(oldFinder) {
							BEGIN_KIND(CumulativeRecorderFinder,crf) {
								result = 
										CumulativeRecorderFinder::make (anys, simples, crf->current()->unionWith(crf->others()));
							} END_KIND;
						} END_CHOOSE;
					}
					if (result->isEmpty()) {
						return NULL;
					} else {
						WPTR(PropFinder) OR(NULL) 	returnValue;
						returnValue = result;
						return returnValue;
					}
				} END_KIND;
			} END_CHOOSE;
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return NULL;
}


BooleanVar PermissionsChange::isFull (){
	/* whether this is a complete change of props */
	
	return FALSE;
}


RPTR(Prop) PermissionsChange::with (APTR(Prop) old, APTR(Prop) a){
	WPTR(BertProp) bp;
	
	bp = CAST(BertProp,old);
	WPTR(Prop) 	returnValue;
	returnValue = BertProp::make (CAST(BertProp,a)->permissions()->unionWith(bp->permissions()), bp->endorsements(), bp->isSensorWaiting(), bp->isNotPartializable());
	return returnValue;
}

	/* automatic 0-argument constructor */
PermissionsChange::PermissionsChange() {}



/* ************************************************************************ *
 * 
 *                    Class SensorPropFinder 
 *
 * ************************************************************************ */


/* Used to filter by the sensor canopy */


/* create */


SensorPropFinder::SensorPropFinder () {
	
}


SensorPropFinder::SensorPropFinder (UInt32 flags, TCSJ) 
	: PropFinder(flags, tcsj) {
	
}
/* accessing */



/* ************************************************************************ *
 * 
 *                    Class   AbstractRecorderFinder 
 *
 * ************************************************************************ */


/* The finders used to find recorders in the sensor canopy in 
response to some change in props of a Stamp. */


/* create */


AbstractRecorderFinder::AbstractRecorderFinder () {
	
}


AbstractRecorderFinder::AbstractRecorderFinder (UInt32 flags, TCSJ) 
	: SensorPropFinder(flags, tcsj) {
	
}
/* accessing */
/* recording */



/* ************************************************************************ *
 * 
 *                    Class     AnyRecorderFinder 
 *
 * ************************************************************************ */


/* NOT.A.TYPE A general superclass for finders that looks for all 
recorders, and all elements they might find, resulting from a given change. */


/* create */


AnyRecorderFinder::AnyRecorderFinder () {
	
}


AnyRecorderFinder::AnyRecorderFinder (UInt32 flags, TCSJ) 
	: AbstractRecorderFinder(flags, tcsj) {
	
}
/* recording */


void AnyRecorderFinder::checkRecorder (APTR(ResultRecorder) recorder, APTR(RecorderFossil) fossil){
	/* do nothing */
	
	
}
/* accessing */


RPTR(PropFinder) AnyRecorderFinder::findPast (APTR(BeEdition) /* stamp */){
	return this;
}



/* ************************************************************************ *
 * 
 *                    Class       AnyRecorderEFinder 
 *
 * ************************************************************************ */


/* create */


RPTR(PropFinder) AnyRecorderEFinder::make (APTR(IDRegion) permissions, APTR(RegionDelta) OF1(CrossRegion) endorsementsDelta){
	WPTR(PropFinder) 	returnValue;
	returnValue = AnyRecorderEFinder::make (permissions, endorsementsDelta, CAST(CrossRegion,endorsementsDelta->after()->minus(endorsementsDelta->before())));
	return returnValue;
}


RPTR(PropFinder) AnyRecorderEFinder::make (
		APTR(IDRegion) permissions, 
		APTR(RegionDelta) OF1(CrossRegion) endorsementsDelta, 
		APTR(CrossRegion) newEndorsements)
{
	{	BooleanVar crutch_Flag;
		/* permissions->isEmpty() || newEndorsements->isEmpty() */
		
		crutch_Flag = permissions->isEmpty();
		if(!crutch_Flag) {
			crutch_Flag = newEndorsements->isEmpty();
		}
		if (crutch_Flag) {
			WPTR(PropFinder) 	returnValue;
			returnValue = PropFinder::closedPropFinder();
			return returnValue;
		}
	}
	RETURN_CONSTRUCT(AnyRecorderEFinder,(
		SensorCrum::flagsFor(permissions, newEndorsements, FALSE), permissions, endorsementsDelta, newEndorsements));
}
/* Generates finders for recorders triggered by an increase in 
endorsements. Also remembers the (approximate) permissions on the 
object whose endorsements changed */


/* accessing */


RPTR(RegionDelta) OF1(CrossRegion) AnyRecorderEFinder::endorsementsDelta (){
	return (RegionDelta*) myEndorsementsDelta;
}


BooleanVar AnyRecorderEFinder::match (APTR(Prop) prop){
	BEGIN_CHOOSE(prop) {
		BEGIN_KIND(SensorProp,p) {
			{	BooleanVar crutch_Flag;
				/* p->relevantPermissions()->intersects(myPermissions) && p->relevantEndorsements()->intersects(myNewEndorsements) */
				
				crutch_Flag = p->relevantPermissions()->intersects(myPermissions);
				if(crutch_Flag) {
					crutch_Flag = p->relevantEndorsements()->intersects(myNewEndorsements);
				}
				return crutch_Flag;
			}
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


RPTR(CrossRegion) AnyRecorderEFinder::newEndorsements (){
	return (CrossRegion*) myNewEndorsements;
}


RPTR(PropFinder) AnyRecorderEFinder::nextFinder (APTR(BeEdition) edition){
	WPTR(PropFinder) 	returnValue;
	returnValue = ContainedEditionRecorderEFinder::make (edition, myPermissions, myEndorsementsDelta, myNewEndorsements);
	return returnValue;
}


RPTR(IDRegion) AnyRecorderEFinder::permissions (){
	return (IDRegion*) myPermissions;
}
/* create */


AnyRecorderEFinder::AnyRecorderEFinder (
		UInt32 flags, 
		APTR(IDRegion) permissions, 
		APTR(RegionDelta) OF1(CrossRegion) endorsementsDelta, 
		APTR(CrossRegion) newEndorsements) 

	: AnyRecorderFinder(flags, tcsj) {
	myPermissions = permissions;
	myEndorsementsDelta = endorsementsDelta;
	myNewEndorsements = newEndorsements;
}
/* testing */


UInt32 AnyRecorderEFinder::actualHashForEqual (){
	return myPermissions->hashForEqual() ^ myEndorsementsDelta->hashForEqual() ^ myNewEndorsements->hashForEqual();
}


BooleanVar AnyRecorderEFinder::isEqual (APTR(Heaper) heaper){
	BEGIN_CHOOSE(heaper) {
		BEGIN_KIND(AnyRecorderEFinder,other) {
			{	BooleanVar crutch_Flag;
				/* myPermissions->isEqual(other->permissions()) && myEndorsementsDelta->isEqual(other->endorsementsDelta()) && myNewEndorsements->isEqual(other->newEndorsements()) */
				
				crutch_Flag = myPermissions->isEqual(other->permissions());
				if(crutch_Flag) {
					crutch_Flag = myEndorsementsDelta->isEqual(other->endorsementsDelta());
					if(crutch_Flag) {
						crutch_Flag = myNewEndorsements->isEqual(other->newEndorsements());
					}
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}



/* ************************************************************************ *
 * 
 *                    Class       AnyRecorderPFinder 
 *
 * ************************************************************************ */


/* create */


RPTR(PropFinder) AnyRecorderPFinder::make (APTR(RegionDelta) OF1(IDRegion) permissionsDelta){
	WPTR(PropFinder) 	returnValue;
	returnValue = AnyRecorderPFinder::make (permissionsDelta, CAST(IDRegion,permissionsDelta->after()->minus(permissionsDelta->before())));
	return returnValue;
}


RPTR(PropFinder) AnyRecorderPFinder::make (APTR(RegionDelta) OF1(IDRegion) permissionsDelta, APTR(IDRegion) newPermissions){
	if (newPermissions->isEmpty()) {
		WPTR(PropFinder) 	returnValue;
		returnValue = PropFinder::closedPropFinder();
		return returnValue;
	}
	RETURN_CONSTRUCT(AnyRecorderPFinder,(
		SensorCrum::flagsFor(newPermissions, NULL, FALSE), permissionsDelta, newPermissions));
}
/* Generates finders for recorders triggered by an increase in permissions */


/* accessing */


BooleanVar AnyRecorderPFinder::match (APTR(Prop) prop){
	BEGIN_CHOOSE(prop) {
		BEGIN_KIND(SensorProp,p) {
			return p->relevantPermissions()->intersects(myPermissions);
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


RPTR(PropFinder) AnyRecorderPFinder::nextFinder (APTR(BeEdition) edition){
	WPTR(PropFinder) 	returnValue;
	returnValue = ResultRecorderPFinder::make (edition, myPermissionsDelta, myPermissions, edition->totalEndorsements());
	return returnValue;
}


RPTR(IDRegion) AnyRecorderPFinder::permissions (){
	return (IDRegion*) myPermissions;
}


RPTR(RegionDelta) OF1(IDRegion) AnyRecorderPFinder::permissionsDelta (){
	return (RegionDelta*) myPermissionsDelta;
}
/* create */


AnyRecorderPFinder::AnyRecorderPFinder (
		UInt32 flags, 
		APTR(RegionDelta) OF1(IDRegion) permissionsDelta, 
		APTR(IDRegion) permissions) 

	: AnyRecorderFinder(flags, tcsj) {
	myPermissionsDelta = permissionsDelta;
	myPermissions = permissions;
}
/* testing */


UInt32 AnyRecorderPFinder::actualHashForEqual (){
	return myPermissionsDelta->hashForEqual() ^ myPermissions->hashForEqual();
}


BooleanVar AnyRecorderPFinder::isEqual (APTR(Heaper) heaper){
	BEGIN_CHOOSE(heaper) {
		BEGIN_KIND(AnyRecorderPFinder,other) {
			{	BooleanVar crutch_Flag;
				/* myPermissionsDelta->isEqual(other->permissionsDelta()) && myPermissions->isEqual(other->permissions()) */
				
				crutch_Flag = myPermissionsDelta->isEqual(other->permissionsDelta());
				if(crutch_Flag) {
					crutch_Flag = myPermissions->isEqual(other->permissions());
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}



/* ************************************************************************ *
 * 
 *                    Class     CumulativeRecorderFinder 
 *
 * ************************************************************************ */


/* create */


RPTR(PropFinder) CumulativeRecorderFinder::make (
		APTR(ImmuSet) OF1(SimpleRecorderFinder) generators, 
		APTR(ImmuSet) OF1(SimpleRecorderFinder) current, 
		APTR(ImmuSet) OF1(SimpleRecorderFinder) others)
{
	UInt32 f;
	
	if (generators->isEmpty()) {
		WPTR(PropFinder) 	returnValue;
		returnValue = PropFinder::closedPropFinder();
		return returnValue;
	}
	/* Ravi -- Thing to do !!!! */
	
	/* since current & generators can have at most two elements, 
		represent them explicitly as two OR(NULL) pointers? 
		or make special SmallImmuSet class? */
	f = UInt32Zero;
	BEGIN_FOR_EACH(AnyRecorderFinder,g,(generators->stepper())) {
		f |= g->flags();
	} END_FOR_EACH;
	BEGIN_FOR_EACH(SimpleRecorderFinder,c,(current->stepper())) {
		f |= c->flags();
	} END_FOR_EACH;
	BEGIN_FOR_EACH(AbstractRecorderFinder,o,(others->stepper())) {
		f |= o->flags();
	} END_FOR_EACH;
	RETURN_CONSTRUCT(CumulativeRecorderFinder,(f, generators, current, others));
}
/* Propagates a change to all recorders which might be interested in 
it, and picking up all elements which might newly be made visible by 
it. The generators make new finders as we pass by additional Edition 
boundaries. Also holds onto a collection of simple finders looking 
for recorders triggered by specific Works or Editions. The current 
set contains those which might record the current edition, and are 
passed to all Recorders. The others are only passed to Recorders with 
the directContainersOnly flag off. */


/* recording */


void CumulativeRecorderFinder::checkRecorder (APTR(ResultRecorder) recorder, APTR(RecorderFossil) fossil){
	BEGIN_FOR_EACH(SimpleRecorderFinder,current,(myCurrent->stepper())) {
		current->checkRecorder(recorder, fossil);
	} END_FOR_EACH;
	if (!recorder->isDirectOnly()) {
		BEGIN_FOR_EACH(SimpleRecorderFinder,other,(myOthers->stepper())) {
			other->checkRecorder(recorder, fossil);
		} END_FOR_EACH;
	}
}
/* create */


CumulativeRecorderFinder::CumulativeRecorderFinder (
		UInt32 flags, 
		APTR(ImmuSet) OF1(AnyRecorderFinder) generators, 
		APTR(ImmuSet) OF1(SimpleRecorderFinder) current, 
		APTR(ImmuSet) OF1(SimpleRecorderFinder OR(AnyRecorderFinder)) others) 

	: AbstractRecorderFinder(flags, tcsj) {
	myGenerators = generators;
	myCurrent = current;
	myOthers = others;
}
/* accessing */


RPTR(ImmuSet) OF1(AnyRecorderFinder) CumulativeRecorderFinder::current (){
	return (ImmuSet*) myCurrent;
}


RPTR(PropFinder) CumulativeRecorderFinder::findPast (APTR(BeEdition) edition){
	SPTR(SetAccumulator) newCurrent;
	
	newCurrent = SetAccumulator::make ();
	BEGIN_FOR_EACH(AnyRecorderFinder,gen,(myGenerators->stepper())) {
		SPTR(PropFinder) next;
		
		next = gen->nextFinder(edition);
		if (!next->isEmpty()) {
			/* cast will catch algorithm bugs in a place 
				from which they are easier to fix */
			newCurrent->step(CAST(SimpleRecorderFinder,next));
		}
	} END_FOR_EACH;
	WPTR(PropFinder) 	returnValue;
	returnValue = CumulativeRecorderFinder::make (myGenerators, CAST(ImmuSet,newCurrent->value()), myOthers->unionWith(myCurrent));
	return returnValue;
}


RPTR(ImmuSet) OF1(AnyRecorderFinder) CumulativeRecorderFinder::generators (){
	return (ImmuSet*) myGenerators;
}


BooleanVar CumulativeRecorderFinder::match (APTR(Prop) prop){
	BEGIN_FOR_EACH(PropFinder,gen,(myGenerators->stepper())) {
		if (gen->match(prop)) {
			return TRUE;
		}
	} END_FOR_EACH;
	return FALSE;
}


RPTR(ImmuSet) OF1(SimpleRecorderFinder OR(AnyRecorderFinder)) CumulativeRecorderFinder::others (){
	return (ImmuSet*) myOthers;
}


RPTR(PropFinder) CumulativeRecorderFinder::pass (APTR(CanopyCrum) parent){
	BEGIN_CHOOSE(parent) {
		BEGIN_KIND(SensorCrum,p) {
			SPTR(SetAccumulator) newGenerators;
			SPTR(SetAccumulator) newCurrent;
			SPTR(SetAccumulator) newOthers;
			SPTR(PropFinder) past;
			
			newGenerators = SetAccumulator::make ();
			BEGIN_FOR_EACH(PropFinder,gen,(myGenerators->stepper())) {
				past = gen->pass(p);
				if (!past->isEmpty()) {
					newGenerators->step(past);
				}
			} END_FOR_EACH;
			if (CAST(ImmuSet,newGenerators->value())->isEmpty()) {
				WPTR(PropFinder) 	returnValue;
				returnValue = PropFinder::closedPropFinder();
				return returnValue;
			}
			newCurrent = SetAccumulator::make ();
			BEGIN_FOR_EACH(PropFinder,current,(myCurrent->stepper())) {
				past = current->pass(p);
				if (!past->isEmpty()) {
					newCurrent->step(past);
				}
			} END_FOR_EACH;
			newOthers = SetAccumulator::make ();
			BEGIN_FOR_EACH(PropFinder,other,(myOthers->stepper())) {
				past = other->pass(p);
				if (!past->isEmpty()) {
					newOthers->step(past);
				}
			} END_FOR_EACH;
			WPTR(PropFinder) 	returnValue;
			returnValue = CumulativeRecorderFinder::make (CAST(ImmuSet,newGenerators->value()), CAST(ImmuSet,newCurrent->value()), CAST(ImmuSet,newOthers->value()));
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return NULL;
}
/* testing */


UInt32 CumulativeRecorderFinder::actualHashForEqual (){
	return myGenerators->hashForEqual() ^ myCurrent->hashForEqual() ^ myOthers->hashForEqual();
}


BooleanVar CumulativeRecorderFinder::isEqual (APTR(Heaper) heaper){
	BEGIN_CHOOSE(heaper) {
		BEGIN_KIND(CumulativeRecorderFinder,other) {
			{	BooleanVar crutch_Flag;
				/* myGenerators->isEqual(other->generators()) && myCurrent->isEqual(other->current()) && myOthers->isEqual(other->others()) */
				
				crutch_Flag = myGenerators->isEqual(other->generators());
				if(crutch_Flag) {
					crutch_Flag = myCurrent->isEqual(other->current());
					if(crutch_Flag) {
						crutch_Flag = myOthers->isEqual(other->others());
					}
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}



/* ************************************************************************ *
 * 
 *                    Class     SimpleRecorderFinder 
 *
 * ************************************************************************ */


/* A finder which holds onto a RangeElement and looks for 
ResultRecorders which might want to record it NOT.A.TYPE  */


/* accessing */


RPTR(PropFinder) SimpleRecorderFinder::findPast (APTR(BeEdition) /* edition */){
	return this;
}
/* recording */


void SimpleRecorderFinder::checkRecorder (APTR(ResultRecorder) recorder, APTR(RecorderFossil) fossil){
	{	BooleanVar crutch_Flag;
		/* recorder->accepts(this->rangeElement()) && this->shouldTrigger(recorder, fossil) */
		
		crutch_Flag = recorder->accepts(this->rangeElement());
		if(crutch_Flag) {
			crutch_Flag = this->shouldTrigger(recorder, fossil);
		}
		if (crutch_Flag) {
			RecorderTrigger::make (fossil, myRangeElement)->schedule();
		}
	}
}
/* create */


SimpleRecorderFinder::SimpleRecorderFinder () {
	
}


SimpleRecorderFinder::SimpleRecorderFinder (UInt32 flags, APTR(BeRangeElement) element) 
	: AbstractRecorderFinder(flags, tcsj) {
	myRangeElement = element;
}
/* protected: */


RPTR(BeEdition) SimpleRecorderFinder::edition (){
	return CAST(BeEdition,myRangeElement);
}


RPTR(BeRangeElement) SimpleRecorderFinder::rangeElement (){
	return (BeRangeElement*) myRangeElement;
}


RPTR(BeWork) SimpleRecorderFinder::work (){
	return CAST(BeWork,myRangeElement);
}



/* ************************************************************************ *
 * 
 *                    Class       ContainedEditionRecorderEFinder 
 *
 * ************************************************************************ */


/* create */


RPTR(PropFinder) ContainedEditionRecorderEFinder::make (
		APTR(BeRangeElement) element, 
		APTR(IDRegion) permissions, 
		APTR(RegionDelta) OF1(CrossRegion) endorsementsDelta)
{
	/* Ravi -- Thing to do !!!! */
	
	/* Separate out relevant endorsements from new endorsements; 
	relevant is those on contained edition - so you can exclude 
	paths which would never care to record that Edition. At the 
	moment all spawned Contained...Finders will vanish at the 
	same time, i.e. when noone cares about the new endorsements 
	any more. Putting in the relevant endorsements as well allows 
	them to vanish earlier. This could also be done by testing 
	self edition totalEndorsements in match and pass. */
	WPTR(PropFinder) 	returnValue;
	returnValue = ContainedEditionRecorderEFinder::make (element, permissions, endorsementsDelta, CAST(CrossRegion,endorsementsDelta->after()->minus(endorsementsDelta->before())));
	return returnValue;
}


RPTR(PropFinder) ContainedEditionRecorderEFinder::make (
		APTR(BeRangeElement) element, 
		APTR(IDRegion) permissions, 
		APTR(RegionDelta) OF1(CrossRegion) endorsementsDelta, 
		APTR(CrossRegion) newEndorsements)
{
	{	BooleanVar crutch_Flag;
		/* permissions->isEmpty() || newEndorsements->isEmpty() */
		
		crutch_Flag = permissions->isEmpty();
		if(!crutch_Flag) {
			crutch_Flag = newEndorsements->isEmpty();
		}
		if (crutch_Flag) {
			WPTR(PropFinder) 	returnValue;
			returnValue = PropFinder::closedPropFinder();
			return returnValue;
		}
	}
	RETURN_CONSTRUCT(ContainedEditionRecorderEFinder,(
		SensorCrum::flagsFor(permissions, newEndorsements, FALSE), element, permissions, endorsementsDelta, newEndorsements));
}
/* Looks for recorders which might be triggered by an increase in 
endorsements in something containing my edition. Keep the total 
endorsements on my edition for quick reject? */


/* recording */


BooleanVar ContainedEditionRecorderEFinder::shouldTrigger (APTR(ResultRecorder) recorder, APTR(RecorderFossil) fossil){
	BEGIN_CHOOSE(recorder) {
		BEGIN_KIND(EditionRecorder,er) {
			
			{	FLUID_BIND(CurrentKeyMaster,er->keyMaster()) {
					{	BooleanVar crutch_Flag;
						/* er->indirectFilter()->isSwitchedOnBy(myEndorsementsDelta) && er->directFilter()->match(this->edition()->visibleEndorsements()) && this->edition()->anyPasses(PropFinder::backfollowFinder(er->permissionsFilter())) */
						
						crutch_Flag = er->indirectFilter()->isSwitchedOnBy(myEndorsementsDelta);
						if(crutch_Flag) {
							crutch_Flag = er->directFilter()->match(this->edition()->visibleEndorsements());
							if(crutch_Flag) {
								crutch_Flag = this->edition()->anyPasses(PropFinder::backfollowFinder(er->permissionsFilter()));
							}
						}
						return crutch_Flag;
					}
				}
			}
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}
/* accessing */


RPTR(RegionDelta) OF1(CrossRegion) ContainedEditionRecorderEFinder::endorsementsDelta (){
	return (RegionDelta*) myEndorsementsDelta;
}


BooleanVar ContainedEditionRecorderEFinder::match (APTR(Prop) prop){
	BEGIN_CHOOSE(prop) {
		BEGIN_KIND(SensorProp,p) {
			{	BooleanVar crutch_Flag;
				/* p->relevantPermissions()->intersects(myPermissions) && p->relevantEndorsements()->intersects(myNewEndorsements) */
				
				crutch_Flag = p->relevantPermissions()->intersects(myPermissions);
				if(crutch_Flag) {
					crutch_Flag = p->relevantEndorsements()->intersects(myNewEndorsements);
				}
				return crutch_Flag;
			}
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


RPTR(CrossRegion) ContainedEditionRecorderEFinder::newEndorsements (){
	return (CrossRegion*) myNewEndorsements;
}


RPTR(IDRegion) ContainedEditionRecorderEFinder::permissions (){
	return (IDRegion*) myPermissions;
}
/* create */


ContainedEditionRecorderEFinder::ContainedEditionRecorderEFinder (
		UInt32 flags, 
		APTR(BeRangeElement) element, 
		APTR(IDRegion) permissions, 
		APTR(RegionDelta) OF1(CrossRegion) endorsementsDelta, 
		APTR(CrossRegion) newEndorsements) 

	: SimpleRecorderFinder(flags, element) {
	myPermissions = permissions;
	myEndorsementsDelta = endorsementsDelta;
	myNewEndorsements = newEndorsements;
}
/* testing */


UInt32 ContainedEditionRecorderEFinder::actualHashForEqual (){
	return this->rangeElement()->hashForEqual() ^ myPermissions->hashForEqual() ^ myEndorsementsDelta->hashForEqual() ^ myNewEndorsements->hashForEqual();
}


BooleanVar ContainedEditionRecorderEFinder::isEqual (APTR(Heaper) heaper){
	BEGIN_CHOOSE(heaper) {
		BEGIN_KIND(ContainedEditionRecorderEFinder,other) {
			{	BooleanVar crutch_Flag;
				/* this->rangeElement()->isEqual(other->rangeElement()) && myPermissions->isEqual(other->permissions()) && myEndorsementsDelta->isEqual(other->endorsementsDelta()) && myNewEndorsements->isEqual(other->newEndorsements()) */
				
				crutch_Flag = this->rangeElement()->isEqual(other->rangeElement());
				if(crutch_Flag) {
					crutch_Flag = myPermissions->isEqual(other->permissions());
					if(crutch_Flag) {
						crutch_Flag = myEndorsementsDelta->isEqual(other->endorsementsDelta());
						if(crutch_Flag) {
							crutch_Flag = myNewEndorsements->isEqual(other->newEndorsements());
						}
					}
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}



/* ************************************************************************ *
 * 
 *                    Class       OriginalResultRecorderEFinder 
 *
 * ************************************************************************ */


/* create */


RPTR(PropFinder) OriginalResultRecorderEFinder::make (
		APTR(BeRangeElement) element, 
		APTR(IDRegion) permissions, 
		APTR(RegionDelta) OF1(CrossRegion) endorsementsDelta)
{
	WPTR(PropFinder) 	returnValue;
	returnValue = OriginalResultRecorderEFinder::make (element, permissions, endorsementsDelta, CAST(CrossRegion,endorsementsDelta->after()->minus(endorsementsDelta->before())));
	return returnValue;
}


RPTR(PropFinder) OriginalResultRecorderEFinder::make (
		APTR(BeRangeElement) element, 
		APTR(IDRegion) permissions, 
		APTR(RegionDelta) OF1(CrossRegion) endorsementsDelta, 
		APTR(CrossRegion) newEndorsements)
{
	{	BooleanVar crutch_Flag;
		/* permissions->isEmpty() || newEndorsements->isEmpty() */
		
		crutch_Flag = permissions->isEmpty();
		if(!crutch_Flag) {
			crutch_Flag = newEndorsements->isEmpty();
		}
		if (crutch_Flag) {
			WPTR(PropFinder) 	returnValue;
			returnValue = PropFinder::closedPropFinder();
			return returnValue;
		}
	}
	RETURN_CONSTRUCT(OriginalResultRecorderEFinder,(
		SensorCrum::flagsFor(permissions, newEndorsements, FALSE), element, permissions, endorsementsDelta, newEndorsements));
}
/* Looks for recorders which might be triggered by an increase in 
endorsements on my RangeElement itself */


/* recording */


BooleanVar OriginalResultRecorderEFinder::shouldTrigger (APTR(ResultRecorder) recorder, APTR(RecorderFossil) fossil){
	BEGIN_CHOOSE(recorder) {
		BEGIN_KIND(EditionRecorder,er) {
			{	BooleanVar crutch_Flag;
				/* er->directFilter()->isSwitchedOnBy(myEndorsementsDelta) && this->edition()->anyPasses(PropFinder::backfollowFinder(er->permissionsFilter(), er->indirectFilter())) */
				
				crutch_Flag = er->directFilter()->isSwitchedOnBy(myEndorsementsDelta);
				if(crutch_Flag) {
					crutch_Flag = this->edition()->anyPasses(PropFinder::backfollowFinder(er->permissionsFilter(), er->indirectFilter()));
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_KIND(WorkRecorder,wr) {
			{	BooleanVar crutch_Flag;
				/* wr->endorsementsFilter()->isSwitchedOnBy(myEndorsementsDelta) && this->work()->canBeReadBy(wr->keyMaster()) */
				
				crutch_Flag = wr->endorsementsFilter()->isSwitchedOnBy(myEndorsementsDelta);
				if(crutch_Flag) {
					crutch_Flag = this->work()->canBeReadBy(wr->keyMaster());
				}
				return crutch_Flag;
			}
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}
/* accessing */


RPTR(RegionDelta) OF1(CrossRegion) OriginalResultRecorderEFinder::endorsementsDelta (){
	return (RegionDelta*) myEndorsementsDelta;
}


BooleanVar OriginalResultRecorderEFinder::match (APTR(Prop) prop){
	BEGIN_CHOOSE(prop) {
		BEGIN_KIND(SensorProp,p) {
			{	BooleanVar crutch_Flag;
				/* p->relevantEndorsements()->intersects(myNewEndorsements) && p->relevantPermissions()->intersects(myPermissions) */
				
				crutch_Flag = p->relevantEndorsements()->intersects(myNewEndorsements);
				if(crutch_Flag) {
					crutch_Flag = p->relevantPermissions()->intersects(myPermissions);
				}
				return crutch_Flag;
			}
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


RPTR(CrossRegion) OriginalResultRecorderEFinder::newEndorsements (){
	return (CrossRegion*) myNewEndorsements;
}


RPTR(IDRegion) OriginalResultRecorderEFinder::permissions (){
	return (IDRegion*) myPermissions;
}
/* create */


OriginalResultRecorderEFinder::OriginalResultRecorderEFinder (
		UInt32 flags, 
		APTR(BeRangeElement) element, 
		APTR(IDRegion) permissions, 
		APTR(RegionDelta) OF1(CrossRegion) endorsementsDelta, 
		APTR(CrossRegion) newEndorsements) 

	: SimpleRecorderFinder(flags, element) {
	myPermissions = permissions;
	myEndorsementsDelta = endorsementsDelta;
	myNewEndorsements = newEndorsements;
}
/* testing */


UInt32 OriginalResultRecorderEFinder::actualHashForEqual (){
	return this->rangeElement()->hashForEqual() ^ myPermissions->hashForEqual() ^ myEndorsementsDelta->hashForEqual() ^ myNewEndorsements->hashForEqual();
}


BooleanVar OriginalResultRecorderEFinder::isEqual (APTR(Heaper) heaper){
	BEGIN_CHOOSE(heaper) {
		BEGIN_KIND(OriginalResultRecorderEFinder,other) {
			{	BooleanVar crutch_Flag;
				/* this->rangeElement()->isEqual(other->rangeElement()) && myPermissions->isEqual(other->permissions()) && myEndorsementsDelta->isEqual(other->endorsementsDelta()) && myNewEndorsements->isEqual(other->newEndorsements()) */
				
				crutch_Flag = this->rangeElement()->isEqual(other->rangeElement());
				if(crutch_Flag) {
					crutch_Flag = myPermissions->isEqual(other->permissions());
					if(crutch_Flag) {
						crutch_Flag = myEndorsementsDelta->isEqual(other->endorsementsDelta());
						if(crutch_Flag) {
							crutch_Flag = myNewEndorsements->isEqual(other->newEndorsements());
						}
					}
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}



/* ************************************************************************ *
 * 
 *                    Class       ResultRecorderPFinder 
 *
 * ************************************************************************ */


/* create */


RPTR(PropFinder) ResultRecorderPFinder::make (
		APTR(BeRangeElement) element, 
		APTR(RegionDelta) permissionsDelta, 
		APTR(CrossRegion) endorsements)
{
	WPTR(PropFinder) 	returnValue;
	returnValue = ResultRecorderPFinder::make (element, permissionsDelta, CAST(IDRegion,permissionsDelta->after()->minus(permissionsDelta->before())), endorsements);
	return returnValue;
}


RPTR(PropFinder) ResultRecorderPFinder::make (
		APTR(BeRangeElement) element, 
		APTR(RegionDelta) permissionsDelta, 
		APTR(IDRegion) newPermissions, 
		APTR(CrossRegion) endorsements)
{
	{	BooleanVar crutch_Flag;
		/* newPermissions->isEmpty() || endorsements->isEmpty() */
		
		crutch_Flag = newPermissions->isEmpty();
		if(!crutch_Flag) {
			crutch_Flag = endorsements->isEmpty();
		}
		if (crutch_Flag) {
			WPTR(PropFinder) 	returnValue;
			returnValue = PropFinder::closedPropFinder();
			return returnValue;
		}
	}
	RETURN_CONSTRUCT(ResultRecorderPFinder,(
		SensorCrum::flagsFor(newPermissions, endorsements, FALSE), element, permissionsDelta, newPermissions, endorsements));
}
/* Looks for records which might be triggered by in increase in 
visibility of my RangeElement */


/* create */


ResultRecorderPFinder::ResultRecorderPFinder (
		UInt32 flags, 
		APTR(BeRangeElement) element, 
		APTR(RegionDelta) permissionsDelta, 
		APTR(IDRegion) newPermissions, 
		APTR(CrossRegion) endorsements) 

	: SimpleRecorderFinder(flags, element) {
	myPermissionsDelta = permissionsDelta;
	myNewPermissions = newPermissions;
	myEndorsements = endorsements;
}
/* accessing */


RPTR(CrossRegion) ResultRecorderPFinder::endorsements (){
	return (CrossRegion*) myEndorsements;
}


BooleanVar ResultRecorderPFinder::match (APTR(Prop) prop){
	BEGIN_CHOOSE(prop) {
		BEGIN_KIND(SensorProp,p) {
			{	BooleanVar crutch_Flag;
				/* p->relevantPermissions()->intersects(myPermissionsDelta->after()) && p->relevantEndorsements()->intersects(myEndorsements) */
				
				crutch_Flag = p->relevantPermissions()->intersects(myPermissionsDelta->after());
				if(crutch_Flag) {
					crutch_Flag = p->relevantEndorsements()->intersects(myEndorsements);
				}
				return crutch_Flag;
			}
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


RPTR(IDRegion) ResultRecorderPFinder::newPermissions (){
	return (IDRegion*) myNewPermissions;
}


RPTR(RegionDelta) OF1(IDRegion) ResultRecorderPFinder::permissionsDelta (){
	return (RegionDelta*) myPermissionsDelta;
}
/* recording */


BooleanVar ResultRecorderPFinder::shouldTrigger (APTR(ResultRecorder) recorder, APTR(RecorderFossil) fossil){
	if (recorder->permissionsFilter()->isSwitchedOnBy(myPermissionsDelta)) {
		BEGIN_CHOOSE(recorder) {
			BEGIN_KIND(EditionRecorder,er) {
				{	FLUID_BIND(CurrentKeyMaster,er->keyMaster()) {
						return er->directFilter()->match(this->edition()->visibleEndorsements());
					}
				}
			} END_KIND;
			BEGIN_KIND(WorkRecorder,wr) {
				return wr->endorsementsFilter()->match(this->work()->endorsements());
			} END_KIND;
		} END_CHOOSE;
	} else {
		return FALSE;
	}
	/* fodder */
	return FALSE;
}
/* testing */


UInt32 ResultRecorderPFinder::actualHashForEqual (){
	return myPermissionsDelta->hashForEqual() ^ myNewPermissions->hashForEqual() ^ myEndorsements->hashForEqual();
}


BooleanVar ResultRecorderPFinder::isEqual (APTR(Heaper) heaper){
	BEGIN_CHOOSE(heaper) {
		BEGIN_KIND(ResultRecorderPFinder,other) {
			{	BooleanVar crutch_Flag;
				/* myPermissionsDelta->isEqual(other->permissionsDelta()) && myNewPermissions->isEqual(other->newPermissions()) && myEndorsements->isEqual(other->endorsements()) */
				
				crutch_Flag = myPermissionsDelta->isEqual(other->permissionsDelta());
				if(crutch_Flag) {
					crutch_Flag = myNewPermissions->isEqual(other->newPermissions());
					if(crutch_Flag) {
						crutch_Flag = myEndorsements->isEqual(other->endorsements());
					}
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}

#ifndef PROPSX_SXX
#include "propsx.sxx"
#endif /* PROPSX_SXX */


#ifndef PROPSP_SXX
#include "propsp.sxx"
#endif /* PROPSP_SXX */



#endif /* PROPSX_CXX */

