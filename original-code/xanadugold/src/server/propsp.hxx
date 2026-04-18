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

#ifndef PROPSP_HXX
#define PROPSP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PROPSX_HXX
#include "propsx.hxx"
#endif /* PROPSX_HXX */

#ifndef PROPSP_OXX
#include "propsp.oxx"
#endif /* PROPSP_OXX */


#ifndef BRANGE1X_OXX
#include "brange1x.oxx"
#endif /* BRANGE1X_OXX */

#ifndef BRANGE2X_OXX
#include "brange2x.oxx"
#endif /* BRANGE2X_OXX */

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

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */

#ifndef TCLUDEX_OXX
#include "tcludex.oxx"
#endif /* TCLUDEX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class BertPropFinder 
 *
 * ************************************************************************ */




	/* Used to filter by the bert canopy */

class BertPropFinder : public PropFinder {

/* Attributes for class BertPropFinder */
	DEFERRED(BertPropFinder)
	NOT_A_TYPE(BertPropFinder)
	NO_GC(BertPropFinder)
  public: /* create */

	
	BertPropFinder ();
	
	
	BertPropFinder (UInt32 ARG(flags), TCSJ);
	
  public: /* accessing */

	
	virtual RPTR(PropFinder) findPast (APTR(BeEdition) ARG(edition)) DEFERRED_FUNC;
	
	/* tell whether a prop matches this filter */
	
	virtual BooleanVar match (APTR(Prop) ARG(prop)) DEFERRED_FUNC;
	

	friend class PropFinder;
};  /* end class BertPropFinder */



/* ************************************************************************ *
 * 
 *                    Class   BackfollowFinder 
 *
 * ************************************************************************ */




	/* Finder used to filter the htree walk by the bert canopy 
	when doing a backFollow which uses both permissions and 
	endorsement filters */

class BackfollowFinder : public BertPropFinder {

/* Attributes for class BackfollowFinder */
	CONCRETE(BackfollowFinder)
	COPY(BackfollowFinder,DiskCuisine)
	NOT_A_TYPE(BackfollowFinder)
	AUTO_GC(BackfollowFinder)
  public: /* creation */

	
	BackfollowFinder (
			UInt32 ARG(flags), 
			APTR(Filter) OF1(XnRegion OF1(ID)) ARG(permissionsFilter), 
			APTR(Filter) OF1(CrossRegion OF1(ID)) ARG(endorsementsFilter))
	;
	
  public: /* accessing */

	
	virtual RPTR(Filter) OF1(XnRegion OF1(ID)) endorsementsFilter ();
	
	
	virtual RPTR(PropFinder) findPast (APTR(BeEdition) ARG(edition));
	
	/* tell whether a prop matches this filter */
	
	virtual BooleanVar match (APTR(Prop) ARG(prop));
	
	
	virtual RPTR(Filter) OF1(XnRegion OF1(ID)) permissionsFilter ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  private:
	CHKPTR(Filter) OF1(XnRegion OF1(ID)) myPermissionsFilter;
	CHKPTR(Filter) OF1(XnRegion OF1(ID)) myEndorsementsFilter;
	friend class PropFinder;
};  /* end class BackfollowFinder */



/* ************************************************************************ *
 * 
 *                    Class   BackfollowPFinder 
 *
 * ************************************************************************ */




	/* Finder used to filter the htree walk by the bert canopy 
	when doing a backFollow which uses just permissions filters */

class BackfollowPFinder : public BertPropFinder {

/* Attributes for class BackfollowPFinder */
	CONCRETE(BackfollowPFinder)
	COPY(BackfollowPFinder,DiskCuisine)
	NOT_A_TYPE(BackfollowPFinder)
	AUTO_GC(BackfollowPFinder)
  public: /* creation */

	
	BackfollowPFinder (UInt32 ARG(flags), APTR(Filter) OF1(XnRegion OF1(ID)) ARG(permissionsFilter));
	
  public: /* accessing */

	
	virtual RPTR(PropFinder) findPast (APTR(BeEdition) ARG(edition));
	
	/* tell whether a prop matches this filter */
	
	virtual BooleanVar match (APTR(Prop) ARG(prop));
	
	
	virtual RPTR(Filter) OF1(XnRegion OF1(ID)) permissionsFilter ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  private:
	CHKPTR(Filter) OF1(XnRegion OF1(ID)) myPermissionsFilter;
	friend class PropFinder;
};  /* end class BackfollowPFinder */



/* ************************************************************************ *
 * 
 *                    Class   CannotPartializeFinder 
 *
 * ************************************************************************ */




	/* Used to figure out which Stamps have Orgls on them so that 
	the archiver can knw that they cannot be partialized.  Will 
	go away because the state described is session level state 
	and therefore should be store in NOCOPY variables instead of 
	in the Canopy's Props. */

class CannotPartializeFinder : public BertPropFinder {

/* Attributes for class CannotPartializeFinder */
	CONCRETE(CannotPartializeFinder)
	COPY(CannotPartializeFinder,DiskCuisine)
	NOT_A_TYPE(CannotPartializeFinder)
	NO_GC(CannotPartializeFinder)
  public: /* create */

	
	CannotPartializeFinder ();
	
  public: /* accessing */

	
	virtual RPTR(PropFinder) findPast (APTR(BeEdition) ARG(edition));
	
	/* tell whether a prop matches this filter */
	
	virtual BooleanVar match (APTR(Prop) ARG(prop));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	

	friend class PropFinder;
};  /* end class CannotPartializeFinder */



/* ************************************************************************ *
 * 
 *                    Class   SensorFinder 
 *
 * ************************************************************************ */




	/* Currently unused but will be re-instated.  Used to find 
	which containing Editions have WaitForCompletionDetectors 
	installed on them so that they can be rung when placegholders 
	get filled in. */

class SensorFinder : public BertPropFinder {

/* Attributes for class SensorFinder */
	CONCRETE(SensorFinder)
	COPY(SensorFinder,DiskCuisine)
	NOT_A_TYPE(SensorFinder)
	NO_GC(SensorFinder)
  public: /* create */

	
	SensorFinder ();
	
  public: /* accessing */

	
	virtual RPTR(PropFinder) findPast (APTR(BeEdition) ARG(edition));
	
	/* tell whether a prop matches this filter */
	
	virtual BooleanVar match (APTR(Prop) ARG(prop));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	

	friend class PropFinder;
};  /* end class SensorFinder */



/* ************************************************************************ *
 * 
 *                    Class CannotPartializeChange 
 *
 * ************************************************************************ */




	/* The "Cannot Partialize" property is a Bert Canopy property 
	to remember that a Stamp is actively being viewed (by a 
	session level Orgl) and therefore cannot be poured-out (made 
	more partial).  Should probably not be a Prop(erty), by 
	rather a NOCOPY session level bit in the BertCrums. */

class CannotPartializeChange : public PropChange {

/* Attributes for class CannotPartializeChange */
	CONCRETE(CannotPartializeChange)
	COPY(CannotPartializeChange,DiskCuisine)
	NOT_A_TYPE(CannotPartializeChange)
	NO_GC(CannotPartializeChange)
  public: /* accessing */

	/* compare the changed parts of two Props */
	
	virtual BooleanVar areEqualProps (APTR(Prop) ARG(a), APTR(Prop) ARG(b));
	
	
	virtual RPTR(Prop) changed (APTR(Prop) ARG(old), APTR(Prop) ARG(a));
	
	
	virtual RPTR(PropFinder) OR(NULL) fetchFinder (
			APTR(Prop) ARG(before), 
			APTR(Prop) ARG(after), 
			APTR(BeRangeElement) ARG(element), 
			APTR(PropFinder) OR(NULL) ARG(oldFinder))
	;
	
	/* whether this is a complete change of props */
	
	virtual BooleanVar isFull ();
	
	
	virtual RPTR(Prop) with (APTR(Prop) ARG(old), APTR(Prop) ARG(a));
	

	/* automatic 0-argument constructor */
  public:
	CannotPartializeChange();

};  /* end class CannotPartializeChange */



/* ************************************************************************ *
 * 
 *                    Class ClosedPropFinder 
 *
 * ************************************************************************ */




	/* The finder which matches nothing.  Used to indicate that 
	this subtree is known to be useless (no matches possible 
	below here). */

class ClosedPropFinder : public PropFinder {

/* Attributes for class ClosedPropFinder */
	CONCRETE(ClosedPropFinder)
	COPY(ClosedPropFinder,DiskCuisine)
	NOT_A_TYPE(ClosedPropFinder)
	NO_GC(ClosedPropFinder)
  public: /* accessing */

	
	virtual RPTR(PropFinder) findPast (APTR(BeEdition) ARG(stamp));
	
	/* Overridden only here */
	
	virtual BooleanVar isEmpty ();
	
	/* tell whether a prop matches this filter */
	
	virtual BooleanVar match (APTR(Prop) ARG(prop));
	
	
	virtual RPTR(PropFinder) pass (APTR(CanopyCrum) ARG(crum));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* create */

	
	ClosedPropFinder ();
	

	friend class PropFinder;
};  /* end class ClosedPropFinder */



/* ************************************************************************ *
 * 
 *                    Class DetectorWaitingChange 
 *
 * ************************************************************************ */




	/* The "Detector Waiting" property is a Bert Canopy property 
	to remember that an Edition has a Detector waiting for 
	PlaceHolders to be filled in. */

class DetectorWaitingChange : public PropChange {

/* Attributes for class DetectorWaitingChange */
	CONCRETE(DetectorWaitingChange)
	COPY(DetectorWaitingChange,DiskCuisine)
	NOT_A_TYPE(DetectorWaitingChange)
	NO_GC(DetectorWaitingChange)
  public: /* accessing */

	/* compare the changed parts of two Props */
	
	virtual BooleanVar areEqualProps (APTR(Prop) ARG(a), APTR(Prop) ARG(b));
	
	
	virtual RPTR(Prop) changed (APTR(Prop) ARG(old), APTR(Prop) ARG(a));
	
	
	virtual RPTR(PropFinder) OR(NULL) fetchFinder (
			APTR(Prop) ARG(before), 
			APTR(Prop) ARG(after), 
			APTR(BeRangeElement) ARG(element), 
			APTR(PropFinder) OR(NULL) ARG(oldFinder))
	;
	
	
	virtual BooleanVar isFull ();
	
	
	virtual RPTR(Prop) with (APTR(Prop) ARG(old), APTR(Prop) ARG(a));
	

	/* automatic 0-argument constructor */
  public:
	DetectorWaitingChange();

};  /* end class DetectorWaitingChange */



/* ************************************************************************ *
 * 
 *                    Class EndorsementsChange 
 *
 * ************************************************************************ */




	/* Used when the Endorsement part of a BertProp changed */

class EndorsementsChange : public PropChange {

/* Attributes for class EndorsementsChange */
	CONCRETE(EndorsementsChange)
	COPY(EndorsementsChange,DiskCuisine)
	NOT_A_TYPE(EndorsementsChange)
	NO_GC(EndorsementsChange)
  public: /* accessing */

	/* compare the changed parts of two Props */
	
	virtual BooleanVar areEqualProps (APTR(Prop) ARG(a), APTR(Prop) ARG(b));
	
	
	virtual RPTR(Prop) changed (APTR(Prop) ARG(old), APTR(Prop) ARG(a));
	
	
	virtual RPTR(PropFinder) OR(NULL) fetchFinder (
			APTR(Prop) ARG(before), 
			APTR(Prop) ARG(after), 
			APTR(BeRangeElement) ARG(element), 
			APTR(PropFinder) OR(NULL) ARG(oldFinder))
	;
	
	/* whether this is a complete change of props */
	
	virtual BooleanVar isFull ();
	
	
	virtual RPTR(Prop) with (APTR(Prop) ARG(old), APTR(Prop) ARG(a));
	

	/* automatic 0-argument constructor */
  public:
	EndorsementsChange();

};  /* end class EndorsementsChange */



/* ************************************************************************ *
 * 
 *                    Class FullPropChange 
 *
 * ************************************************************************ */




	/* Use this to indicate that all aspects of the Prop may have 
	changed. */

class FullPropChange : public PropChange {

/* Attributes for class FullPropChange */
	DEFERRED(FullPropChange)
	NOT_A_TYPE(FullPropChange)
	NO_GC(FullPropChange)
  public: /* accessing */

	/* compare the changed parts of two Props */
	
	virtual BooleanVar areEqualProps (APTR(Prop) ARG(a), APTR(Prop) ARG(b));
	
	
	virtual RPTR(Prop) changed (APTR(Prop) ARG(old), APTR(Prop) ARG(a));
	
	
	virtual RPTR(PropFinder) OR(NULL) fetchFinder (
			APTR(Prop) ARG(before), 
			APTR(Prop) ARG(after), 
			APTR(BeRangeElement) ARG(element), 
			APTR(PropFinder) OR(NULL) ARG(oldFinder))
	 DEFERRED_FUNC;
	
	/* whether this is a complete change of props */
	
	virtual BooleanVar isFull ();
	
	
	virtual RPTR(Prop) with (APTR(Prop) ARG(old), APTR(Prop) ARG(a));
	

	/* automatic 0-argument constructor */
  public:
	FullPropChange();

};  /* end class FullPropChange */



/* ************************************************************************ *
 * 
 *                    Class   BertPropChange 
 *
 * ************************************************************************ */




	/* Use when it is fine to consider that all aspects of the 
	BertProp may have changed */

class BertPropChange : public FullPropChange {

/* Attributes for class BertPropChange */
	CONCRETE(BertPropChange)
	COPY(BertPropChange,DiskCuisine)
	NOT_A_TYPE(BertPropChange)
	NO_GC(BertPropChange)
  public: /* accessing */

	
	virtual RPTR(PropFinder) OR(NULL) fetchFinder (
			APTR(Prop) ARG(before), 
			APTR(Prop) ARG(after), 
			APTR(BeRangeElement) ARG(element), 
			APTR(PropFinder) OR(NULL) ARG(oldFinder))
	;
	

	/* automatic 0-argument constructor */
  public:
	BertPropChange();

};  /* end class BertPropChange */



/* ************************************************************************ *
 * 
 *                    Class   SensorPropChange 
 *
 * ************************************************************************ */




	/* Use when it is fine to consider that all aspects of the 
	SensorProp may have changed */

class SensorPropChange : public FullPropChange {

/* Attributes for class SensorPropChange */
	CONCRETE(SensorPropChange)
	COPY(SensorPropChange,DiskCuisine)
	NOT_A_TYPE(SensorPropChange)
	NO_GC(SensorPropChange)
  public: /* accessing */

	
	virtual RPTR(PropFinder) OR(NULL) fetchFinder (
			APTR(Prop) ARG(before), 
			APTR(Prop) ARG(after), 
			APTR(BeRangeElement) ARG(element), 
			APTR(PropFinder) OR(NULL) ARG(oldFinder))
	;
	

	/* automatic 0-argument constructor */
  public:
	SensorPropChange();

};  /* end class SensorPropChange */



/* ************************************************************************ *
 * 
 *                    Class OpenPropFinder 
 *
 * ************************************************************************ */




	/* The finder which matches everything.  Used to indicate 
	that everything below here necessarily matches. */

class OpenPropFinder : public PropFinder {

/* Attributes for class OpenPropFinder */
	CONCRETE(OpenPropFinder)
	COPY(OpenPropFinder,DiskCuisine)
	NOT_A_TYPE(OpenPropFinder)
	NO_GC(OpenPropFinder)
  public: /* accessing */

	
	virtual RPTR(PropFinder) findPast (APTR(BeEdition) ARG(stamp));
	
	
	virtual BooleanVar isFull ();
	
	/* tell whether a prop matches this filter */
	
	virtual BooleanVar match (APTR(Prop) ARG(prop));
	
	
	virtual RPTR(PropFinder) pass (APTR(CanopyCrum) ARG(crum));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* create */

	
	OpenPropFinder ();
	

	friend class PropFinder;
};  /* end class OpenPropFinder */



/* ************************************************************************ *
 * 
 *                    Class PermissionsChange 
 *
 * ************************************************************************ */




	/* Used when the Permissions part of a BertProp changed */

class PermissionsChange : public PropChange {

/* Attributes for class PermissionsChange */
	CONCRETE(PermissionsChange)
	COPY(PermissionsChange,DiskCuisine)
	NOT_A_TYPE(PermissionsChange)
	NO_GC(PermissionsChange)
  public: /* accessing */

	/* compare the changed parts of two Props */
	
	virtual BooleanVar areEqualProps (APTR(Prop) ARG(a), APTR(Prop) ARG(b));
	
	
	virtual RPTR(Prop) changed (APTR(Prop) ARG(old), APTR(Prop) ARG(a));
	
	
	virtual RPTR(PropFinder) OR(NULL) fetchFinder (
			APTR(Prop) ARG(before), 
			APTR(Prop) ARG(after), 
			APTR(BeRangeElement) ARG(element), 
			APTR(PropFinder) OR(NULL) ARG(oldFinder))
	;
	
	/* whether this is a complete change of props */
	
	virtual BooleanVar isFull ();
	
	
	virtual RPTR(Prop) with (APTR(Prop) ARG(old), APTR(Prop) ARG(a));
	

	/* automatic 0-argument constructor */
  public:
	PermissionsChange();

};  /* end class PermissionsChange */



/* ************************************************************************ *
 * 
 *                    Class SensorPropFinder 
 *
 * ************************************************************************ */




	/* Used to filter by the sensor canopy */

class SensorPropFinder : public PropFinder {

/* Attributes for class SensorPropFinder */
	DEFERRED(SensorPropFinder)
	NOT_A_TYPE(SensorPropFinder)
	NO_GC(SensorPropFinder)
  public: /* create */

	
	SensorPropFinder ();
	
	
	SensorPropFinder (UInt32 ARG(flags), TCSJ);
	
  public: /* accessing */

	
	virtual RPTR(PropFinder) findPast (APTR(BeEdition) ARG(stamp)) DEFERRED_FUNC;
	
	/* tell whether a prop matches this filter */
	
	virtual BooleanVar match (APTR(Prop) ARG(prop)) DEFERRED_FUNC;
	

	friend class PropFinder;
};  /* end class SensorPropFinder */



/* ************************************************************************ *
 * 
 *                    Class   AbstractRecorderFinder 
 *
 * ************************************************************************ */




	/* The finders used to find recorders in the sensor canopy in 
	response to some change in props of a Stamp. */

class AbstractRecorderFinder : public SensorPropFinder {

/* Attributes for class AbstractRecorderFinder */
	DEFERRED(AbstractRecorderFinder)
	NO_GC(AbstractRecorderFinder)
  public: /* create */

	
	AbstractRecorderFinder ();
	
	
	AbstractRecorderFinder (UInt32 ARG(flags), TCSJ);
	
  public: /* accessing */

	
	virtual RPTR(PropFinder) findPast (APTR(BeEdition) ARG(stamp)) DEFERRED_FUNC;
	
	/* tell whether a prop matches this filter */
	
	virtual BooleanVar match (APTR(Prop) ARG(prop)) DEFERRED_FUNC;
	
  public: /* recording */

	/* While doing one step of a southward walk in the O-tree,
		 filtered by the sensor canopy,
		 looking for recorders that represent queries that are newly 
	passed by the change of properties,
		 where the object that changed properties and the change 
	itself are represented by my state,
		 record my object into the recorder if it newly passes the 
	recorder's filtering criteria.
		 
		 See class comments of the various subclasses for details on 
	the purpose of each kindOf AbstractRecorderFinder. */
	
	virtual void checkRecorder (APTR(ResultRecorder) ARG(recorder), APTR(RecorderFossil) ARG(fossil)) DEFERRED_SUBR;
	

	friend class PropFinder;
};  /* end class AbstractRecorderFinder */



/* ************************************************************************ *
 * 
 *                    Class     AnyRecorderFinder 
 *
 * ************************************************************************ */




	/* NOT.A.TYPE A general superclass for finders that looks for 
	all recorders, and all elements they might find, resulting 
	from a given change. */

class AnyRecorderFinder : public AbstractRecorderFinder {

/* Attributes for class AnyRecorderFinder */
	DEFERRED(AnyRecorderFinder)
	NO_GC(AnyRecorderFinder)
  public: /* create */

	
	AnyRecorderFinder ();
	
	
	AnyRecorderFinder (UInt32 ARG(flags), TCSJ);
	
  public: /* recording */

	/* do nothing */
	
	virtual void checkRecorder (APTR(ResultRecorder) ARG(recorder), APTR(RecorderFossil) ARG(fossil));
	
  public: /* accessing */

	
	virtual RPTR(PropFinder) findPast (APTR(BeEdition) ARG(stamp));
	
	
	virtual BooleanVar match (APTR(Prop) ARG(prop)) DEFERRED_FUNC;
	
	/* An additional finder to use below the given Edition */
	
	virtual RPTR(PropFinder) nextFinder (APTR(BeEdition) ARG(edition)) DEFERRED_FUNC;
	

	friend class PropFinder;
};  /* end class AnyRecorderFinder */



/* ************************************************************************ *
 * 
 *                    Class       AnyRecorderEFinder 
 *
 * ************************************************************************ */




	/* Generates finders for recorders triggered by an increase 
	in endorsements. Also remembers the (approximate) permissions 
	on the object whose endorsements changed */

class AnyRecorderEFinder : public AnyRecorderFinder {

/* Attributes for class AnyRecorderEFinder */
	CONCRETE(AnyRecorderEFinder)
	COPY(AnyRecorderEFinder,DiskCuisine)
	NOT_A_TYPE(AnyRecorderEFinder)
	AUTO_GC(AnyRecorderEFinder)
  public: /* create */

	
	static RPTR(PropFinder) make (APTR(IDRegion) ARG(permissions), APTR(RegionDelta) OF1(CrossRegion) ARG(endorsementsDelta));
	
	
	static RPTR(PropFinder) make (
			APTR(IDRegion) ARG(permissions), 
			APTR(RegionDelta) OF1(CrossRegion) ARG(endorsementsDelta), 
			APTR(CrossRegion) ARG(newEndorsements))
	;
	
  public: /* accessing */

	
	virtual RPTR(RegionDelta) OF1(CrossRegion) endorsementsDelta ();
	
	
	virtual BooleanVar match (APTR(Prop) ARG(prop));
	
	
	virtual RPTR(CrossRegion) newEndorsements ();
	
	
	virtual RPTR(PropFinder) nextFinder (APTR(BeEdition) ARG(edition));
	
	
	virtual RPTR(IDRegion) permissions ();
	
  public: /* create */

	
	AnyRecorderEFinder (
			UInt32 ARG(flags), 
			APTR(IDRegion) ARG(permissions), 
			APTR(RegionDelta) OF1(CrossRegion) ARG(endorsementsDelta), 
			APTR(CrossRegion) ARG(newEndorsements))
	;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(heaper));
	
  private:
	CHKPTR(IDRegion) myPermissions;
	CHKPTR(RegionDelta) OF1(CrossRegion) myEndorsementsDelta;
	CHKPTR(CrossRegion) myNewEndorsements;
};  /* end class AnyRecorderEFinder */



/* ************************************************************************ *
 * 
 *                    Class       AnyRecorderPFinder 
 *
 * ************************************************************************ */




	/* Generates finders for recorders triggered by an increase 
	in permissions */

class AnyRecorderPFinder : public AnyRecorderFinder {

/* Attributes for class AnyRecorderPFinder */
	CONCRETE(AnyRecorderPFinder)
	COPY(AnyRecorderPFinder,DiskCuisine)
	NOT_A_TYPE(AnyRecorderPFinder)
	AUTO_GC(AnyRecorderPFinder)
  public: /* create */

	
	static RPTR(PropFinder) make (APTR(RegionDelta) OF1(IDRegion) ARG(permissionsDelta));
	
	
	static RPTR(PropFinder) make (APTR(RegionDelta) OF1(IDRegion) ARG(permissionsDelta), APTR(IDRegion) ARG(newPermissions));
	
  public: /* accessing */

	
	virtual BooleanVar match (APTR(Prop) ARG(prop));
	
	
	virtual RPTR(PropFinder) nextFinder (APTR(BeEdition) ARG(edition));
	
	
	virtual RPTR(IDRegion) permissions ();
	
	
	virtual RPTR(RegionDelta) OF1(IDRegion) permissionsDelta ();
	
  public: /* create */

	
	AnyRecorderPFinder (
			UInt32 ARG(flags), 
			APTR(RegionDelta) OF1(IDRegion) ARG(permissionsDelta), 
			APTR(IDRegion) ARG(permissions))
	;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(heaper));
	
  private:
	CHKPTR(RegionDelta) OF1(IDRegion) myPermissionsDelta;
	CHKPTR(IDRegion) myPermissions;
	friend class PropFinder;
};  /* end class AnyRecorderPFinder */



/* ************************************************************************ *
 * 
 *                    Class     CumulativeRecorderFinder 
 *
 * ************************************************************************ */




	/* Propagates a change to all recorders which might be 
	interested in it, and picking up all elements which might 
	newly be made visible by it. The generators make new finders 
	as we pass by additional Edition boundaries. Also holds onto 
	a collection of simple finders looking for recorders 
	triggered by specific Works or Editions. The current set 
	contains those which might record the current edition, and 
	are passed to all Recorders. The others are only passed to 
	Recorders with the directContainersOnly flag off. */

class CumulativeRecorderFinder : public AbstractRecorderFinder {

/* Attributes for class CumulativeRecorderFinder */
	CONCRETE(CumulativeRecorderFinder)
	COPY(CumulativeRecorderFinder,DiskCuisine)
	NOT_A_TYPE(CumulativeRecorderFinder)
	AUTO_GC(CumulativeRecorderFinder)
  public: /* create */

	
	static RPTR(PropFinder) make (
			APTR(ImmuSet) OF1(SimpleRecorderFinder) ARG(generators), 
			APTR(ImmuSet) OF1(SimpleRecorderFinder) ARG(current), 
			APTR(ImmuSet) OF1(SimpleRecorderFinder) ARG(others))
	;
	
  public: /* recording */

	
	virtual void checkRecorder (APTR(ResultRecorder) ARG(recorder), APTR(RecorderFossil) ARG(fossil));
	
  public: /* create */

	
	CumulativeRecorderFinder (
			UInt32 ARG(flags), 
			APTR(ImmuSet) OF1(AnyRecorderFinder) ARG(generators), 
			APTR(ImmuSet) OF1(SimpleRecorderFinder) ARG(current), 
			APTR(ImmuSet) OF1(SimpleRecorderFinder OR(AnyRecorderFinder)) ARG(others))
	;
	
  public: /* accessing */

	
	virtual RPTR(ImmuSet) OF1(AnyRecorderFinder) current ();
	
	
	virtual RPTR(PropFinder) findPast (APTR(BeEdition) ARG(edition));
	
	
	virtual RPTR(ImmuSet) OF1(AnyRecorderFinder) generators ();
	
	
	virtual BooleanVar match (APTR(Prop) ARG(prop));
	
	
	virtual RPTR(ImmuSet) OF1(SimpleRecorderFinder OR(AnyRecorderFinder)) others ();
	
	
	virtual RPTR(PropFinder) pass (APTR(CanopyCrum) ARG(parent));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(heaper));
	
  private:
	CHKPTR(ImmuSet) OF1(AnyRecorderFinder) myGenerators;
	CHKPTR(ImmuSet) OF1(SimpleRecorderFinder) myCurrent;
	CHKPTR(ImmuSet) OF1(SimpleRecorderFinder OR(AnyRecorderFinder)) myOthers;
};  /* end class CumulativeRecorderFinder */



/* ************************************************************************ *
 * 
 *                    Class     SimpleRecorderFinder 
 *
 * ************************************************************************ */




	/* A finder which holds onto a RangeElement and looks for 
	ResultRecorders which might want to record it NOT.A.TYPE  */

class SimpleRecorderFinder : public AbstractRecorderFinder {

/* Attributes for class SimpleRecorderFinder */
	DEFERRED(SimpleRecorderFinder)
	COPY(SimpleRecorderFinder,DiskCuisine)
	AUTO_GC(SimpleRecorderFinder)
  public: /* accessing */

	
	virtual RPTR(PropFinder) findPast (APTR(BeEdition) ARG(edition));
	
	
	virtual BooleanVar match (APTR(Prop) ARG(prop)) DEFERRED_FUNC;
	
  public: /* recording */

	
	virtual void checkRecorder (APTR(ResultRecorder) ARG(recorder), APTR(RecorderFossil) ARG(fossil));
	
	/* Whether the recorder should be triggered with my RangeElement */
	
	virtual BooleanVar shouldTrigger (APTR(ResultRecorder) ARG(recorder), APTR(RecorderFossil) ARG(fossil)) DEFERRED_FUNC;
	
  public: /* create */

	
	SimpleRecorderFinder ();
	
	
	SimpleRecorderFinder (UInt32 ARG(flags), APTR(BeRangeElement) ARG(element));
	
  protected: /* protected: */

	
	virtual RPTR(BeEdition) edition ();
	
	
	virtual RPTR(BeRangeElement) rangeElement ();
	
	
	virtual RPTR(BeWork) work ();
	
  private:
	CHKPTR(BeRangeElement) myRangeElement;
	friend class PropFinder;
	friend class PropFinder;
};  /* end class SimpleRecorderFinder */



/* ************************************************************************ *
 * 
 *                    Class       ContainedEditionRecorderEFinder 
 *
 * ************************************************************************ */




	/* Looks for recorders which might be triggered by an 
	increase in endorsements in something containing my edition. 
	Keep the total endorsements on my edition for quick reject? */

class ContainedEditionRecorderEFinder : public SimpleRecorderFinder {

/* Attributes for class ContainedEditionRecorderEFinder */
	CONCRETE(ContainedEditionRecorderEFinder)
	COPY(ContainedEditionRecorderEFinder,DiskCuisine)
	NOT_A_TYPE(ContainedEditionRecorderEFinder)
	AUTO_GC(ContainedEditionRecorderEFinder)
  public: /* create */

	
	static RPTR(PropFinder) make (
			APTR(BeRangeElement) ARG(element), 
			APTR(IDRegion) ARG(permissions), 
			APTR(RegionDelta) OF1(CrossRegion) ARG(endorsementsDelta))
	;
	
	
	static RPTR(PropFinder) make (
			APTR(BeRangeElement) ARG(element), 
			APTR(IDRegion) ARG(permissions), 
			APTR(RegionDelta) OF1(CrossRegion) ARG(endorsementsDelta), 
			APTR(CrossRegion) ARG(newEndorsements))
	;
	
  public: /* recording */

	
	virtual BooleanVar shouldTrigger (APTR(ResultRecorder) ARG(recorder), APTR(RecorderFossil) ARG(fossil));
	
  public: /* accessing */

	
	virtual RPTR(RegionDelta) OF1(CrossRegion) endorsementsDelta ();
	
	
	virtual BooleanVar match (APTR(Prop) ARG(prop));
	
	
	virtual RPTR(CrossRegion) newEndorsements ();
	
	
	virtual RPTR(IDRegion) permissions ();
	
  public: /* create */

	
	ContainedEditionRecorderEFinder (
			UInt32 ARG(flags), 
			APTR(BeRangeElement) ARG(element), 
			APTR(IDRegion) ARG(permissions), 
			APTR(RegionDelta) OF1(CrossRegion) ARG(endorsementsDelta), 
			APTR(CrossRegion) ARG(newEndorsements))
	;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(heaper));
	
  private:
	CHKPTR(IDRegion) myPermissions;
	CHKPTR(RegionDelta) OF1(CrossRegion) myEndorsementsDelta;
	CHKPTR(CrossRegion) myNewEndorsements;
};  /* end class ContainedEditionRecorderEFinder */



/* ************************************************************************ *
 * 
 *                    Class       OriginalResultRecorderEFinder 
 *
 * ************************************************************************ */




	/* Looks for recorders which might be triggered by an 
	increase in endorsements on my RangeElement itself */

class OriginalResultRecorderEFinder : public SimpleRecorderFinder {

/* Attributes for class OriginalResultRecorderEFinder */
	CONCRETE(OriginalResultRecorderEFinder)
	COPY(OriginalResultRecorderEFinder,DiskCuisine)
	NOT_A_TYPE(OriginalResultRecorderEFinder)
	AUTO_GC(OriginalResultRecorderEFinder)
  public: /* create */

	
	static RPTR(PropFinder) make (
			APTR(BeRangeElement) ARG(element), 
			APTR(IDRegion) ARG(permissions), 
			APTR(RegionDelta) OF1(CrossRegion) ARG(endorsementsDelta))
	;
	
	
	static RPTR(PropFinder) make (
			APTR(BeRangeElement) ARG(element), 
			APTR(IDRegion) ARG(permissions), 
			APTR(RegionDelta) OF1(CrossRegion) ARG(endorsementsDelta), 
			APTR(CrossRegion) ARG(newEndorsements))
	;
	
  public: /* recording */

	
	virtual BooleanVar shouldTrigger (APTR(ResultRecorder) ARG(recorder), APTR(RecorderFossil) ARG(fossil));
	
  public: /* accessing */

	
	virtual RPTR(RegionDelta) OF1(CrossRegion) endorsementsDelta ();
	
	
	virtual BooleanVar match (APTR(Prop) ARG(prop));
	
	
	virtual RPTR(CrossRegion) newEndorsements ();
	
	
	virtual RPTR(IDRegion) permissions ();
	
  public: /* create */

	
	OriginalResultRecorderEFinder (
			UInt32 ARG(flags), 
			APTR(BeRangeElement) ARG(element), 
			APTR(IDRegion) ARG(permissions), 
			APTR(RegionDelta) OF1(CrossRegion) ARG(endorsementsDelta), 
			APTR(CrossRegion) ARG(newEndorsements))
	;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(heaper));
	
  private:
	CHKPTR(IDRegion) myPermissions;
	CHKPTR(RegionDelta) OF1(CrossRegion) myEndorsementsDelta;
	CHKPTR(CrossRegion) myNewEndorsements;
};  /* end class OriginalResultRecorderEFinder */



/* ************************************************************************ *
 * 
 *                    Class       ResultRecorderPFinder 
 *
 * ************************************************************************ */




	/* Looks for records which might be triggered by in increase 
	in visibility of my RangeElement */

class ResultRecorderPFinder : public SimpleRecorderFinder {

/* Attributes for class ResultRecorderPFinder */
	CONCRETE(ResultRecorderPFinder)
	COPY(ResultRecorderPFinder,DiskCuisine)
	NOT_A_TYPE(ResultRecorderPFinder)
	AUTO_GC(ResultRecorderPFinder)
  public: /* create */

	
	static RPTR(PropFinder) make (
			APTR(BeRangeElement) ARG(element), 
			APTR(RegionDelta) ARG(permissionsDelta), 
			APTR(CrossRegion) ARG(endorsements))
	;
	
	
	static RPTR(PropFinder) make (
			APTR(BeRangeElement) ARG(element), 
			APTR(RegionDelta) ARG(permissionsDelta), 
			APTR(IDRegion) ARG(newPermissions), 
			APTR(CrossRegion) ARG(endorsements))
	;
	
  public: /* create */

	
	ResultRecorderPFinder (
			UInt32 ARG(flags), 
			APTR(BeRangeElement) ARG(element), 
			APTR(RegionDelta) ARG(permissionsDelta), 
			APTR(IDRegion) ARG(newPermissions), 
			APTR(CrossRegion) ARG(endorsements))
	;
	
  public: /* accessing */

	
	virtual RPTR(CrossRegion) endorsements ();
	
	
	virtual BooleanVar match (APTR(Prop) ARG(prop));
	
	
	virtual RPTR(IDRegion) newPermissions ();
	
	
	virtual RPTR(RegionDelta) OF1(IDRegion) permissionsDelta ();
	
  public: /* recording */

	
	virtual BooleanVar shouldTrigger (APTR(ResultRecorder) ARG(recorder), APTR(RecorderFossil) ARG(fossil));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(heaper));
	
  private:
	CHKPTR(RegionDelta) myPermissionsDelta;
	CHKPTR(IDRegion) myNewPermissions;
	CHKPTR(CrossRegion) myEndorsements;
};  /* end class ResultRecorderPFinder */



#endif /* PROPSP_HXX */

