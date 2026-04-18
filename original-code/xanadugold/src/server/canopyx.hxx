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

#ifndef CANOPYX_HXX
#define CANOPYX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef CANOPYX_OXX
#include "canopyx.oxx"
#endif /* CANOPYX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */


#ifndef CANOPYP_OXX
#include "canopyp.oxx"
#endif /* CANOPYP_OXX */

#ifndef CROSSX_OXX
#include "crossx.oxx"
#endif /* CROSSX_OXX */

#ifndef DISKMANX_OXX
#include "diskmanx.oxx"
#endif /* DISKMANX_OXX */

#ifndef FLUIDX_OXX
#include "fluidx.oxx"
#endif /* FLUIDX_OXX */

#ifndef IDX_OXX
#include "idx.oxx"
#endif /* IDX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef PROPSX_OXX
#include "propsx.oxx"
#endif /* PROPSX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */

#ifndef TABLESX_OXX
#include "tablesx.oxx"
#endif /* TABLESX_OXX */

#ifndef TCLUDEX_OXX
#include "tcludex.oxx"
#endif /* TCLUDEX_OXX */

#ifndef TURTLEX_OXX
#include "turtlex.oxx"
#endif /* TURTLEX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class CanopyCrum 
 *
 * ************************************************************************ */



/* Initializers for CanopyCrum */







	/* CanopyCrums form binary trees that acrete in a balanced 
	fashion.  No rebalancing ever happens.  Things are simply 
	added to the tree up to the point thta the tree is balanced, 
	then the height of the tree gets extended at the root.
	
	Essentially, when the join of two trees is asked for, if the 
	two trees aren't already parts of a larger tree, the 
	algorithm attempts to find a place in one tree into which the 
	other tree could completely fit without violating the depth 
	constraint on the tree.  It then returns the nearest root 
	that contains both trees.  If it can't put one tree into the 
	other, then it makes a new node that joins the two trees 
	(probably with room to add other stuff deeper down).
	
	myRefCount is only the count of Loafs or HCrums that point at 
	the CanopyCrum.  It doesn't include other CanopyCrums.
	
	12/2/92 Ravi
	PropJoints have been suspended, and their function has been 
	replaced by flag words in the CanopyCrum. Any interesting 
	Club or endorsement gets a bit, and there is a bit for "any 
	other Club" and "any other endorsement". Any criteria not 
	given a bit of their own require an exhaustive search. These 
	flags are widded by ORing up the canopy. When we start using 
	more sophisticated hashing strategies, we will probably need 
	to reanimate PropJoints. */

class CanopyCrum : public Abraham {

/* Attributes for class CanopyCrum */
	DEFERRED(CanopyCrum)
	SHEPHERD_PATRIARCH(CanopyCrum,Abraham)
	COPY(CanopyCrum,DiskCuisine)
	DEFERRED_LOCKED(CanopyCrum)
	AUTO_GC(CanopyCrum)

/* Initializers for CanopyCrum */



friend class INIT_TIME_NAME(CanopyCrum,initTimeNonInherited);

  protected: /* protected: flags */

	/* Flag bits corresponding to endorsements */
	
	static UInt32 endorsementsFlags (APTR(CrossRegion) ARG(endorsements));
	
	/* Flag bits corresponding to permissions */
	
	static UInt32 permissionsFlags (APTR(IDRegion) ARG(permissions));
	
  private: /* private: flags */

	/* Max number of special endorsement flags */
	
	static Int32 endorsementFlagLimit ();
	
	/* Rightmost flag for interesting endorsements */
	
	static UInt32 firstEndorsementsFlag ();
	
	/* The flag for any other Clubs */
	
	static UInt32 otherClubsFlag ();
	
	/* Flag for all uninteresting endorsements */
	
	static UInt32 otherEndorsementsFlag ();
	
	/* The flag for the Universal Public Club */
	
	static UInt32 publicClubFlag ();
	
  public: /* flag setup */

	/* Use a special flag to look for any of the these endorsements */
	
	static void useEndorsementFlags (APTR(PtrArray) OF1(Position OR(XnRegion)) ARG(endorsements));
	
  public: /* canopy operations */

	/* Find a canopyCrum that is an anscestor to 
		 both the receiver and otherBCrum. otherBCrum 
		 is added to the canopy in a pseudo-balanced fashion. 
		 This demonstrates the beauty and power of caching
		 in object-oriented systems. */
	
	virtual RPTR(CanopyCrum) computeJoin (APTR(CanopyCrum) ARG(otherBCrum));
	
	/* split into two if possible, return the two leaves */
	
	virtual RPTR(Pair) OF1(CanopyCrum) expand ();
	
	/* Install otherCanopy at or below the receiver. If the 
	otherCanopy fits in a lower branch, put it there. Otherwise, 
	replace the shortest child with a new child that contains the 
	shortest child and otherCanopy. */
	/* This should be a friend or private function or something. */
	
	virtual void includeCanopy (APTR(CanopyCrum) ARG(otherCanopy));
	
	/* Return true if other is equal to the receiver
		 or an anscestor (through the parent links). 
		 Use caches for efficiency. */
	
	virtual BooleanVar isLE (APTR(CanopyCrum) ARG(other));
	
  public: /* canopy accessing */

	/* Keep a refcount of diskful pointers to myself for disk 
	space management.  (Maybe backpointers later.) */
	
	virtual void addPointer (APTR(Heaper) ARG(ignored));
	
	
	virtual NOLOCK RPTR(CanopyCrum) fetchParent ();
	
	
	virtual NOLOCK UInt32 flags ();
	
	
	virtual IntegerVar heightDiff ();
	
	
	virtual BooleanVar isLeaf ();
	
	
	virtual NOLOCK IntegerVar maxHeight ();
	
	
	virtual NOLOCK IntegerVar minHeight ();
	
	/* Keep a refcount of diskful pointers to myself for disk 
	space management.  (Maybe backpointers later.)
		 Forget the object if it goes to zero. */
	
	virtual void removePointer (APTR(Heaper) ARG(ignored));
	
	
	virtual void setParent (APTR(CanopyCrum) OR(NULL) ARG(p));
	
  protected: /* protected: */

	
	virtual WPTR(CanopyCache) canopyCache () DEFERRED_FUNC;
	
	
	virtual void dismantle ();
	
	
	virtual NOLOCK RPTR(CanopyCrum) fetchChild1 ();
	
	
	virtual NOLOCK RPTR(CanopyCrum) fetchChild2 ();
	
	
	virtual RPTR(CanopyCrum) makeNew () DEFERRED_FUNC;
	
	
	virtual NOLOCK UInt32 ownFlags ();
	
	
	virtual NOLOCK void setOwnFlags (UInt32 ARG(newFlags));
	
  public: /* create */

	/* Make a canopyCrum for a root:  it has no children. */
	
	CanopyCrum (UInt32 ARG(flags), TCSJ);
	
	/* prop must be empty */
	
	CanopyCrum (
			UInt32 ARG(flags), 
			APTR(CanopyCrum) ARG(first), 
			APTR(CanopyCrum) ARG(second))
	;
	
  public: /* props */

	/* Return an AgendaItem to propagate properties.
		
		NOTE: The AgendaItem returned is not yet scheduled.  Doing 
	so is up to my caller. */
	
	virtual RPTR(AgendaItem) propChanger (APTR(PropChange) ARG(change), APTR(Prop) ARG(prop));
	
  public: /* testing */

	/* This is only used by the TestPacker, so it includes all 
	persistent state whether or not
		 it is semantically interesting--myRefCount is not 
	semantically interesting. */
	
	virtual UInt32 contentsHash ();
	
  public: /* protected */

	/* Figure out new props, etc. Return true if any changes may 
	require further propagation */
	/* At least one subclass adds behavior here by overriding and 
	calling 'super changeCanopy:' */
	
	virtual BooleanVar changeCanopy ();
	
	/* Figure out new height. Return true if changes may require 
	further propagation */
	
	virtual BooleanVar changeHeight ();
	
	/* Make a new crum that contains both first and second.
		This method just makes a new parent whose properties are 
	empty. My client must bring my properties up to date */
	
	virtual RPTR(CanopyCrum) makeNewParent (APTR(CanopyCrum) ARG(first), APTR(CanopyCrum) ARG(second)) DEFERRED_FUNC;
	
  public: /* private */

	/* Install otherCanopy as a subtree in the canopy containing 
	the receiver. Look below 
		the receiver and then in successively higher branches for a 
	branch that has 
		enough height difference to contain otherCanopy. */
	
	virtual RPTR(CanopyCrum) makeJoin (APTR(CanopyCrum) ARG(otherCanopy));
	
  private:
	CHKPTR(CanopyCrum) OR(NULL) child1;
	CHKPTR(CanopyCrum) OR(NULL) child2;
	CHKPTR(CanopyCrum) OR(NULL) parent;
	IntegerVar minH;
	IntegerVar maxH;
	UInt32 myOwnFlags;
	UInt32 myFlags;
	IntegerVar myRefCount;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(PtrArray) OF1(Position OR(XnRegion)) FlagEndorsements;
	static GPTR(IDRegion) OtherClubs;
	static GPTR(CrossRegion) OtherEndorsements;
	static GPTR(Heaper2UInt32Cache) TheEFlagsCache;
	static GPTR(Heaper2UInt32Cache) ThePFlagsCache;
/* Friends for class CanopyCrum */
friend class RecorderHoister;




};  /* end class CanopyCrum */



/* ************************************************************************ *
 * 
 *                    Class   BertCrum 
 *
 * ************************************************************************ */



/* Initializers for BertCrum */
DESIGN_FLUID(CanopyCache,CurrentBertCanopyCache);	/* in BertCrum */




	/* This implementation tracks the endorsement information with 
	a strictly binary tree.  The tree gets heuristically balanced 
	upon insertion of new elements in such a way that the ocrums 
	pointing at a particular canopyCrum need not be updated.  
	Therefore we should not bother storing backpointers.  I'm 
	doing so currently in case we change algorithms.
	
	Deletion may require backpointers to eliminate joins 
	with the deleted crums. */

class BertCrum : public CanopyCrum {

/* Attributes for class BertCrum */
	CONCRETE(BertCrum)
	SHEPHERD_PATRIARCH(BertCrum,CanopyCrum)
	LOCKED(BertCrum)
	COPY(BertCrum,DiskCuisine)
	NO_GC(BertCrum)

/* Initializers for BertCrum */


  public: /* instance creation */

	
	static RPTR(BertCrum) make ();
	
  public: /* flags */

	/* The flag word corresponding to the given props */
	
	static UInt32 flagsFor (
			APTR(IDRegion) OR(NULL) ARG(permissions), 
			APTR(CrossRegion) OR(NULL) ARG(endorsements), 
			BooleanVar ARG(isNotPartializable), 
			BooleanVar ARG(isSensorWaiting))
	;
	
	/* Flag bit for active Editions */
	
	static UInt32 isNotPartializableFlag () CONST;
	
	/* Flag bit for active Editions */
	
	static UInt32 isSensorWaitingFlag () CONST;
	
  private: /* private: creation */

	/* Make a canopyCrum for a root:  it has no children. */
	
	BertCrum ();
	
  protected: /* protected: */

	/* should have one per Ent */
	
	virtual WPTR(CanopyCache) canopyCache ();
	
	
	virtual RPTR(CanopyCrum) makeNew ();
	
  public: /* protected */

	
	virtual RPTR(CanopyCrum) makeNewParent (APTR(CanopyCrum) ARG(first), APTR(CanopyCrum) ARG(second));
	
  public: /* instance creation */

	/* Create a new parent for two BertCrums.
		My client must bring my properties up to date.  This 
	constructor just makes a new parent whose properties are empty */
	
	BertCrum (APTR(BertCrum) ARG(first), APTR(BertCrum) ARG(second));
	
  public: /* accessing */

	
	virtual BooleanVar isNotPartializable ();
	
	
	virtual BooleanVar isSensorWaiting ();
	

};  /* end class BertCrum */



/* ************************************************************************ *
 * 
 *                    Class   SensorCrum 
 *
 * ************************************************************************ */



/* Initializers for SensorCrum */
DESIGN_FLUID(CanopyCache,CurrentSensorCanopyCache);	/* in SensorCrum */




	/* This implementation is the same as BertCrums.  This will require 
	pointers into the ent to implement delete (for archiving).  Canopy 
	reorganization could be achieved by removing several orgls, then 
	re-adding them (archive then restore). */

class SensorCrum : public CanopyCrum {

/* Attributes for class SensorCrum */
	CONCRETE(SensorCrum)
	SHEPHERD_PATRIARCH(SensorCrum,CanopyCrum)
	LOCKED(SensorCrum)
	COPY(SensorCrum,DiskCuisine)
	AUTO_GC(SensorCrum)

/* Initializers for SensorCrum */


  public: /* pseudo constructors */

	
	static RPTR(SensorCrum) make ();
	
	
	static RPTR(SensorCrum) partial ();
	
  public: /* flags */

	/* The flag word corresponding to the given props */
	
	static UInt32 flagsFor (
			APTR(IDRegion) OR(NULL) ARG(permissions), 
			APTR(CrossRegion) OR(NULL) ARG(endorsements), 
			BooleanVar ARG(isPartial))
	;
	
	/* Flag bit for existence of partiality */
	
	static UInt32 isPartialFlag () CONST;
	
  private: /* private: creation */

	/* Make a canopyCrum for a root:  it has no children. */
	
	SensorCrum ();
	
	/* Make a canopyCrum for a root:  it has no children. */
	
	SensorCrum (UInt32 ARG(flags), TCSJ);
	
  protected: /* protected: */

	/* should have one per Ent */
	
	virtual WPTR(CanopyCache) canopyCache ();
	
	
	virtual RPTR(CanopyCrum) makeNew ();
	
  public: /* accessing */

	/* Set off all recorders that respond to the change either in 
	me or in any of my ancestors up to but not including sCrum
		(If I am the same as sCrum, skip me as well.)
		(If sCrum is null, search through all my ancestors to a root 
	of the sensor canopy.)
		return simplest finder for looking at children */
	
	virtual RPTR(PropFinder) checkRecorders (APTR(PropFinder) ARG(finder), APTR(SensorCrum) OR(NULL) ARG(scrum));
	
	/* Set off all recorders in me that respond to the change, if 
	appropriate
		(If I am the same as sCrum, skip me.)
		If sCrum is null or not me, return my parent so caller can 
	iterate through my ancestors to sCrum or a root. */
	
	virtual RPTR(SensorCrum) OR(NULL) fetchNextAfterTriggeringRecorders (APTR(PropFinder) ARG(finder), APTR(SensorCrum) OR(NULL) ARG(sCrum));
	
	
	virtual BooleanVar isPartial ();
	
	
	virtual NOLOCK RPTR(ImmuSet) OF1(RecorderFossil) recorders ();
	
	/* NOTE: The AgendaItem returned is not yet scheduled.  Doing 
	so is up to my caller. */
	
	virtual RPTR(AgendaItem) recordingAgent (APTR(RecorderFossil) ARG(recorder));
	
	/* Remove recorders because they have migrated rootward.
		Recalculate myOwnFlags and myFlags. */
	
	virtual void removeRecorders (APTR(ImmuSet) OF1(RecorderFossil) ARG(recorders));
	
  private: /* private: */

	/* Installs the recorders in my set and updates myOwnProp accordingly.
		The caller has already checked that none of these recorders 
	are already installed here.
		The caller also handles updating myFlags.
		The caller also handles all issues of rootward propagation 
	of these changes.
		The caller also does the 'diskUpdate'.
		
		This is a separate method because it's called once by the 
	code that installs a new recorder, and again by the code that 
	recursively hoists recurders up the canopy.
		
		add the new recorders to my set
		for each new recorder
			if it hasn't gone extinct
				extract its properties
				union them into my own */
	
	virtual void installRecorders (APTR(ImmuSet) OF1(RecorderFossil) ARG(recorders));
	
  public: /* protected */

	
	virtual RPTR(CanopyCrum) makeNewParent (APTR(CanopyCrum) ARG(first), APTR(CanopyCrum) ARG(second));
	
  public: /* instance creation */

	/* Create a new parent for two SensorCrums.
		This constructor just makes a new parent whose properties 
	are empty. My client must bring my properties up to date. */
	
	SensorCrum (APTR(SensorCrum) ARG(first), APTR(SensorCrum) ARG(second));
	
  private:
	CHKPTR(ImmuSet) OF1(RecorderFossil) myBackfollowRecorders;
/* Friends for class SensorCrum */
friend class RecorderHoister;



};  /* end class SensorCrum */



#endif /* CANOPYX_HXX */

