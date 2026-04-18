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

#ifndef PROPSX_HXX
#define PROPSX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PROPSX_OXX
#include "propsx.oxx"
#endif /* PROPSX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef BRANGE1X_OXX
#include "brange1x.oxx"
#endif /* BRANGE1X_OXX */

#ifndef BRANGE3X_OXX
#include "brange3x.oxx"
#endif /* BRANGE3X_OXX */

#ifndef CANOPYX_OXX
#include "canopyx.oxx"
#endif /* CANOPYX_OXX */

#ifndef CROSSX_OXX
#include "crossx.oxx"
#endif /* CROSSX_OXX */

#ifndef FILTERX_OXX
#include "filterx.oxx"
#endif /* FILTERX_OXX */

#ifndef IDX_OXX
#include "idx.oxx"
#endif /* IDX_OXX */

#ifndef PROPSP_OXX
#include "propsp.oxx"
#endif /* PROPSP_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class Prop 
 *
 * ************************************************************************ */




	/* A collection of properties which are to be found by 
	navigating a Canopy.  PropJoints are the union/intersection 
	style abstraction of the properties which provide for such 
	navigation. */

class Prop : public Heaper {

/* Attributes for class Prop */
	DEFERRED(Prop)
	NO_GC(Prop)
  public: /* accessing */

	/* The flags used in the Canopy to tag this prop */
	
	virtual UInt32 flags () DEFERRED_FUNC;
	
	
	virtual RPTR(Prop) with (APTR(Prop) ARG(other)) DEFERRED_FUNC;
	
  public: /* tesing */

	
	virtual UInt32 actualHashForEqual ();
	

	/* automatic 0-argument constructor */
  public:
	Prop();

};  /* end class Prop */



/* ************************************************************************ *
 * 
 *                    Class   BertProp 
 *
 * ************************************************************************ */



/* Initializers for BertProp */




	/* The properties which are nevigable towards using the Bert 
	Canopy.  All of these are properties of the Stamps at the 
	leaves of the Bert Canopy. */

class BertProp : public Prop {

/* Attributes for class BertProp */
	CONCRETE(BertProp)
	COPY(BertProp,DiskCuisine)
	AUTO_GC(BertProp)

/* Initializers for BertProp */


  public: /* creation */

	
	static RPTR(BertProp) cannotPartializeProp ();
	
	
	static RPTR(BertProp) detectorWaitingProp ();
	
	
	static RPTR(BertProp) endorsementsProp (APTR(XnRegion) ARG(endorsements));
	
	
	static RPTR(BertProp) make ();
	
	
	static RPTR(BertProp) make (
			APTR(XnRegion) OF1(ID) ARG(permissions), 
			APTR(XnRegion) ARG(endorsements), 
			BooleanVar ARG(isSensorWaiting), 
			BooleanVar ARG(isNotPartializable))
	;
	
	
	static RPTR(BertProp) permissionsProp (APTR(XnRegion) OF1(ID) ARG(iDs));
	
  public: /* accessing */

	
	virtual RPTR(CrossRegion) endorsements ();
	
	
	virtual UInt32 flags ();
	
	
	virtual BooleanVar isNotPartializable ();
	
	
	virtual BooleanVar isSensorWaiting ();
	
	
	virtual RPTR(XnRegion) OF1(ID) permissions ();
	
	
	virtual RPTR(Prop) with (APTR(Prop) ARG(other));
	
  public: /* creation */

	
	BertProp (
			APTR(XnRegion) OF1(ID) ARG(permissions), 
			APTR(XnRegion) OF1(ID) ARG(endorsements), 
			BooleanVar ARG(isSensorWaiting), 
			BooleanVar ARG(isNotPartializable))
	;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	/* Does this do the right thing. */
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	CHKPTR(XnRegion) OF1(ID) myPermissions;
	CHKPTR(XnRegion) OF1(ID) myEndorsements;
	BooleanVar mySensorWaitingFlag;
	BooleanVar myCannotPartializeFlag;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(BertProp) TheIdentityBertProp;
};  /* end class BertProp */



/* ************************************************************************ *
 * 
 *                    Class   SensorProp 
 *
 * ************************************************************************ */



/* Initializers for SensorProp */




	/* The properties which are nevigable towards using the 
	Sensor Canopy.  The permissions and endorsements are those 
	whose changes may affect the triggering of the recorders that 
	decorate the canopy.  myPartialFlag is a property of the 
	o-leaf-stuff which are at the leaves of the Sensor Canopy. */

class SensorProp : public Prop {

/* Attributes for class SensorProp */
	CONCRETE(SensorProp)
	COPY(SensorProp,DiskCuisine)
	AUTO_GC(SensorProp)

/* Initializers for SensorProp */


  public: /* creation */

	/* returns an empty SensorProp */
	
	static RPTR(SensorProp) make ();
	
	
	static RPTR(SensorProp) make (
			APTR(IDRegion) ARG(relevantPermissions), 
			APTR(CrossRegion) ARG(relevantEndorsements), 
			BooleanVar ARG(isPartial))
	;
	
	/* returns an empty SensorProp with the partial flag on */
	
	static RPTR(SensorProp) partial ();
	
  public: /* creation */

	
	SensorProp (
			APTR(IDRegion) ARG(relevantPermissions), 
			APTR(CrossRegion) OF2(IDRegion,IDRegion) ARG(relevantEndorsements), 
			BooleanVar ARG(isPartial))
	;
	
  public: /* accessing */

	
	virtual UInt32 flags ();
	
	
	virtual BooleanVar isPartial ();
	
	
	virtual RPTR(CrossRegion) relevantEndorsements ();
	
	
	virtual RPTR(IDRegion) relevantPermissions ();
	
	
	virtual RPTR(Prop) with (APTR(Prop) ARG(other));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(heaper));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	CHKPTR(IDRegion) myRelevantPermissions;
	CHKPTR(CrossRegion) OF2(IDRegion,IDRegion) myRelevantEndorsements;
	BooleanVar myPartialFlag;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(SensorProp) TheIdentitySensorProp;
	static GPTR(SensorProp) ThePartialSensorProp;
};  /* end class SensorProp */



/* ************************************************************************ *
 * 
 *                    Class PropChange 
 *
 * ************************************************************************ */



/* Initializers for PropChange */







	/* Each concrete class has just one canonical instance and no 
	state.  A PropChange is used to represent which property 
	aspect changed (such as permission vs endorsement vs both). */

class PropChange : public Heaper {

/* Attributes for class PropChange */
	DEFERRED(PropChange)
	NO_GC(PropChange)

/* Initializers for PropChange */



friend class INIT_TIME_NAME(PropChange,initTimeNonInherited);

  public: /* pseudo constructors */

	
	static RPTR(PropChange) bertPropChange ();
	
	
	static RPTR(PropChange) cannotPartializeChange ();
	
	
	static RPTR(PropChange) detectorWaitingChange ();
	
	
	static RPTR(PropChange) endorsementsChange ();
	
	
	static RPTR(PropChange) permissionsChange ();
	
	/* Returns the canonical PropChange object for propagating 
	the properties that result from installing a recorder 
	(permissions and endorsement filters).  A better name would 
	be recorderPropChange */
	
	static RPTR(PropChange) sensorPropChange ();
	
  public: /* accessing */

	/* compare the changed parts of two Props */
	
	virtual BooleanVar areEqualProps (APTR(Prop) ARG(a), APTR(Prop) ARG(b)) DEFERRED_FUNC;
	
	/* Return a Prop which is the same as 'old' for aspects which 
	I don't represent as changing, and 'a' for aspects that I do 
	represent as changing.
		
		 This is used to replace Props with minimum effort, given 
	that the 'a' parameter has only new props which are of the 
	aspect this change replaces, while the 'old' parameter starts 
	as the original set of Props, perhaps including other aspects.
		 
		 See also: with:with:, which unions rather than replacing. */
	
	virtual RPTR(Prop) changed (APTR(Prop) ARG(old), APTR(Prop) ARG(a)) DEFERRED_FUNC;
	
	/* return a finder looking for this change from before to 
	after, in addition to whatever oldFinder is looking for 
	(assumes this changes is a subset of oldFinder's change) */
	
	virtual RPTR(PropFinder) OR(NULL) fetchFinder (
			APTR(Prop) ARG(before), 
			APTR(Prop) ARG(after), 
			APTR(BeRangeElement) ARG(element), 
			APTR(PropFinder) OR(NULL) ARG(oldFinder))
	 DEFERRED_FUNC;
	
	/* whether this is a complete change of props */
	
	virtual BooleanVar isFull () DEFERRED_FUNC;
	
	/* Return a Prop which is the same as 'old' for aspects which 
	I don't represent as changing, and the union of 'old' and 'a' 
	for aspects that I do represent as changing.
		
		 This is used to accumulate changes to Props with minimum 
	effort, given that the 'a' parameter has only new props which 
	are of the aspect this change changes, while the 'old' 
	parameter starts as the original set of Props, perhaps 
	including other aspects.
		 
		 See also changed:with:, which replaces rather than unioning. */
	
	virtual RPTR(Prop) with (APTR(Prop) ARG(old), APTR(Prop) ARG(a)) DEFERRED_FUNC;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	

	/* automatic 0-argument constructor */
  public:
	PropChange();


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(PropChange) TheBertPropChange;
	static GPTR(PropChange) TheCannotPartializeChange;
	static GPTR(PropChange) TheDetectorWaitingChange;
	static GPTR(PropChange) TheEndorsementsChange;
	static GPTR(PropChange) ThePermissionsChange;
	static GPTR(PropChange) TheSensorPropChange;
};  /* end class PropChange */



/* ************************************************************************ *
 * 
 *                    Class PropFinder 
 *
 * ************************************************************************ */




	/* For filtering by canopies.  Matches against Props and 
	CanopyCrum flags */

class PropFinder : public Heaper {

/* Attributes for class PropFinder */
	DEFERRED(PropFinder)
	NO_GC(PropFinder)
  public: /* creation */

	
	static RPTR(PropFinder) backfollowFinder (APTR(Filter) OF1(XnRegion OF1(ID)) ARG(permissionsFilter));
	
	
	static RPTR(PropFinder) backfollowFinder (APTR(Filter) OF1(XnRegion OF1(ID)) ARG(permissionsFilter), APTR(Filter) OF1(XnRegion OF1(ID)) ARG(endorsementsFilter));
	
	
	static RPTR(PropFinder) cannotPartializeFinder ();
	
	
	static RPTR(PropFinder) closedPropFinder ();
	
	
	static RPTR(PropFinder) openPropFinder ();
	
	
	static RPTR(PropFinder) sensorFinder ();
	
  public: /* create */

	
	PropFinder ();
	
	
	PropFinder (UInt32 ARG(flags), TCSJ);
	
  public: /* accessing */

	/* return whether the propJoint passes the finder */
	
	virtual BooleanVar doesPass (APTR(CanopyCrum) ARG(parent));
	
	/* During a southwards walk of a multi-Edition (aka 
	multi-Stamp), normally we simplify the finder by using 
	PropFinder>>pass:.  However, when we cross an internal 
	Edition boundary and are about to walk into the O-plane of 
	that contained edition we call this method (findPast:) to get 
	the new PropFinder. */
	
	virtual RPTR(PropFinder) findPast (APTR(BeEdition) ARG(stamp)) DEFERRED_FUNC;
	
	
	virtual UInt32 flags ();
	
	/* Overridden only in ClosedPropFinder */
	
	virtual BooleanVar isEmpty ();
	
	/* Overridden only in OpenPropFinder */
	
	virtual BooleanVar isFull ();
	
	/* tell whether a prop matches this filter */
	
	virtual BooleanVar match (APTR(Prop) ARG(prop)) DEFERRED_FUNC;
	
	/* return a simple enough finder for looking at the children */
	
	virtual RPTR(PropFinder) pass (APTR(CanopyCrum) ARG(parent));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  private:
	UInt32 myFlags;
};  /* end class PropFinder */



#endif /* PROPSX_HXX */

