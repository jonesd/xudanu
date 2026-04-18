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

#ifndef BRANGE2X_HXX
#define BRANGE2X_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef BRANGE2X_OXX
#include "brange2x.oxx"
#endif /* BRANGE2X_OXX */


#ifndef BRANGE1X_HXX
#include "brange1x.hxx"
#endif /* BRANGE1X_HXX */

#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef BRANGE3X_OXX
#include "brange3x.oxx"
#endif /* BRANGE3X_OXX */

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

#ifndef NKERNELX_OXX
#include "nkernelx.oxx"
#endif /* NKERNELX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef PRIMTABX_OXX
#include "primtabx.oxx"
#endif /* PRIMTABX_OXX */

#ifndef PROPSX_OXX
#include "propsx.oxx"
#endif /* PROPSX_OXX */

#ifndef SCHUNKX_OXX
#include "schunkx.oxx"
#endif /* SCHUNKX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef WPARRAYX_OXX
#include "wparrayx.oxx"
#endif /* WPARRAYX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class BeWork 
 *
 * ************************************************************************ */




	/* This is the actual representation on disk; the Fe versions 
	of these classes hide the actual representation.ó */

class BeWork : public BeRangeElement {

/* Attributes for class BeWork */
	CONCRETE(BeWork)
	SHEPHERD_PATRIARCH(BeWork,BeRangeElement)
	LOCKED(BeWork)
	COPY(BeWork,DiskCuisine)
	AUTO_GC(BeWork)
  public: /* creation */

	
	static RPTR(BeWork) make (APTR(FeEdition) ARG(edition));
	
  public: /* locking */

	/* Answer whether the KeyMaster has the authority to edit this work. */
	
	virtual BooleanVar canBeEditedBy (APTR(FeKeyMaster) ARG(km));
	
	/* Return true if the KeyMaster has the authority to read this Work. */
	
	virtual BooleanVar canBeReadBy (APTR(FeKeyMaster) ARG(km));
	
	/* The Work which has this locked, or NULL if noone does. */
	
	INLINE RPTR(FeWork) OR(NULL) fetchLockingWork ();
	
	/* Make a frontend Work on me and lock it if possible. */
	
	virtual RPTR(FeWork) makeLockedFeWork ();
	
	/* Try to lock with the give FE Work. Return TRUE if successful */
	
	virtual BooleanVar tryLock (APTR(FeWork) ARG(work));
	
	/* If the given FE Work is locking, then unlock and return 
	TRUE; else return FALSE with no change in lock state */
	
	virtual BooleanVar tryUnlock (APTR(FeWork) ARG(work));
	
  public: /* contents */

	/* Tell the FE Work whenever this Work is revised */
	
	virtual void addRevisionWatcher (APTR(FeWork) ARG(work));
	
	/* The current Edition.
		Note: If this is an unsponsored Work, the Edition might have 
	been discarded, and this operation will blast. */
	
	virtual RPTR(FeEdition) edition ();
	
	/* The Club who made the last revision */
	
	virtual NOLOCK RPTR(ID) lastRevisionAuthor ();
	
	/* The sequence number of the last revision of this Work. */
	
	virtual NOLOCK IntegerVar lastRevisionNumber ();
	
	/* The time of the last revision of this Work. */
	
	virtual NOLOCK IntegerVar lastRevisionTime ();
	
	/* Change the current edition and notify anyone who cares 
	about the revision */
	
	virtual void recordHistory ();
	
	/* Inform the work that its last revision watcher is gone. */
	
	virtual NOLOCK void removeLastRevisionWatcher ();
	
	/* Remove a previously added RevisionWatcher */
	
	virtual void removeRevisionWatcher (APTR(FeWork) ARG(work));
	
	/* Change the current edition and notify anyone who cares 
	about the revision */
	
	virtual void revise (APTR(FeEdition) ARG(edition));
	
	/* If there isn't already a shared Trail on this Work, create 
	a new one. Return it */
	
	virtual RPTR(BeEdition) revisions ();
	
  public: /* permissions */

	/* The edit Club, or NULL if there is none */
	
	virtual NOLOCK RPTR(ID) OR(NULL) fetchEditClub ();
	
	/* The history Club, or NULL if there is none */
	
	virtual NOLOCK RPTR(ID) OR(NULL) fetchHistoryClub ();
	
	/* The read Club, or NULL if there is none */
	
	virtual NOLOCK RPTR(ID) OR(NULL) fetchReadClub ();
	
	/* Change the edit Club (or remove it if NULL). */
	
	virtual void setEditClub (APTR(ID) OR(NULL) ARG(club));
	
	/* Change the history Club (or remove it if NULL). */
	
	virtual void setHistoryClub (APTR(ID) OR(NULL) ARG(club));
	
	/* Change the read Club (or remove it if NULL). */
	
	virtual void setReadClub (APTR(ID) OR(NULL) ARG(club));
	
  public: /* props */

	/* Adds to the endorsements on this Work. The set of 
	endorsements must be a finite number of (club ID, token ID) 
	pairs. This requires the authority of all of the Clubs used 
	to endorse. The token IDs must not be named IDs. */
	
	virtual void endorse (APTR(CrossRegion) ARG(endorsements));
	
	/* All endorsements which have been placed on this Work. The 
	Edition::transclusions () operation will be able to find the 
	current Edition of this Work by filtering for these 
	endorsements; they are also used to filter various other 
	operations which directly return sets of Works. */
	
	virtual RPTR(CrossRegion) endorsements ();
	
	
	virtual NOLOCK RPTR(BertProp) localProp ();
	
	
	virtual NOLOCK RPTR(BertProp) prop ();
	
	
	virtual void propChange (APTR(PropChange) ARG(change), APTR(Prop) ARG(nw));
	
	/* Removes endorsements from this Work. This requires the 
	authority of all of the Clubs whose endorsements are in the 
	list. Ignores all endorsements which you could have removed, 
	but which don't happen to be there right now. */
	
	virtual void retract (APTR(CrossRegion) ARG(endorsements));
	
  public: /* accessing */

	
	virtual BooleanVar isPurgeable ();
	
	
	virtual RPTR(FeRangeElement) makeFe (APTR(BeLabel) OR(NULL) ARG(label));
	
	/* Add new sponsors to the Work, and notify the Clubs */
	
	virtual void sponsor (APTR(IDRegion) ARG(clubs));
	
	
	virtual NOLOCK RPTR(IDRegion) sponsors ();
	
	/* Remove sponsors from the Work, and notify the Clubs */
	
	virtual void unsponsor (APTR(IDRegion) ARG(clubs));
	
  private: /* private: */

	/* Tell all the FeWorks on this one to update their status */
	
	virtual void updateFeStatus ();
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK void restartWork (APTR(Rcvr) ARG(rcvr));
	
  public: /* creation */

	
	BeWork (APTR(FeEdition) ARG(contents), BooleanVar ARG(isClub));
	
	/* Gets called once the object is created, to finish up */
	
	virtual void finishCreation ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	CHKPTR(BeEdition) myEdition;
	CHKPTR(BeLabel) myEditionLabel;
	CHKPTR(ID) OR(NULL) myReadClub;
	CHKPTR(ID) OR(NULL) myEditClub;
	CHKPTR(BertProp) myOwnProp;
	CHKPTR(BeEdition) OR(NULL) myHistory;
	CHKPTR(ID) OR(NULL) myHistoryClub;
	IntegerVar myRevisionCount;
	IntegerVar myRevisionTime;
	CHKPTR(ID) myReviser;
	CHKPTR(IDRegion) mySponsors;
	NOCOPY CHKPTR(WeakPtrArray) OF1(FeWork) myLockingWork;
	NOCOPY CHKPTR(PrimSet) OF1(FeWork) OR(NULL) myRevisionWatchers;
/* Friends for class BeWork */
/* friends for class BeWork */
friend class BeWorkLockExecutor;


};  /* end class BeWork */



/* ************************************************************************ *
 * 
 *                    Class   BeClub 
 *
 * ************************************************************************ */



/* Initializers for BeClub */
DESIGN_FLUID(BeClub,CurrentOwner);	/* in BeClub */
DESIGN_FLUID(MuSet,ActiveClubs);	/* in BeClub */




	/* NO CLASS COMMENT */

class BeClub : public BeWork {

/* Attributes for class BeClub */
	CONCRETE(BeClub)
	SHEPHERD_PATRIARCH(BeClub,BeWork)
	LOCKED(BeClub)
	COPY(BeClub,DiskCuisine)
	AUTO_GC(BeClub)

/* Initializers for BeClub */


  public: /* creation */

	
	static RPTR(BeClub) make (APTR(FeEdition) ARG(contents));
	
  public: /* dependents */

	/* Notify the KeyMaster when the transitive super Clubs of 
	this Club change */
	
	virtual void registerKeyMaster (APTR(FeKeyMaster) ARG(km));
	
	/* Unregister a previously registered KeyMaster */
	
	virtual void unregisterKeyMaster (APTR(FeKeyMaster) ARG(km));
	
  public: /* accessing */

	/* Add a sponsored Work (sent from the Work) */
	
	virtual void addSponsored (APTR(BeWork) ARG(work));
	
	/* The Club who can endorse and sponsor with this Club */
	
	virtual NOLOCK RPTR(ID) OR(NULL) fetchSignatureClub ();
	
	
	virtual BooleanVar isPurgeable ();
	
	
	virtual RPTR(FeRangeElement) makeFe (APTR(BeLabel) OR(NULL) ARG(label));
	
	/* Whether the direct membership includes the given Club */
	
	virtual BooleanVar membershipIncludes (APTR(BeClub) ARG(club));
	
	/* Add a sponsored Work (sent from the Work) */
	
	virtual void removeSponsored (APTR(BeWork) ARG(work));
	
	/* Change the Club who can endorse and sponsor with this Club */
	
	virtual NOLOCK void setSignatureClub (APTR(ID) OR(NULL) ARG(clubID));
	
	
	virtual RPTR(ImmuSet) OF1(BeWork) sponsored ();
	
	
	virtual NOLOCK RPTR(IDRegion) transitiveMemberIDs ();
	
	
	virtual NOLOCK RPTR(IDRegion) transitiveSuperClubIDs ();
	
  private: /* private: propagating */

	
	virtual void updateKeyMasters ();
	
  private: /* private: accessing */

	
	virtual NOLOCK RPTR(MuSet) OF1(BeClub) immediateSuperClubs ();
	
	
	virtual NOLOCK RPTR(MuSet) OF1(BeClub) members ();
	
  public: /* contents */

	/* Update cached information */
	
	virtual void revise (APTR(FeEdition) ARG(contents));
	
  public: /* propagating */

	/* Add an immediate super Club and update my cached 
	information, and those of my members */
	
	virtual void addImmediateSuperClub (APTR(BeClub) ARG(parent));
	
	/* Add an immediate super Club and update my cached 
	information, and those of my members */
	
	virtual void removeImmediateSuperClub (APTR(BeClub) ARG(parent));
	
	/* Figure out result of changes in membership, then propagate 
	upwards */
	
	virtual void updateTransitiveMemberIDs ();
	
	/* Figure out result of changes in membership, then propagate 
	upwards */
	
	virtual void updateTransitiveSuperClubIDs ();
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK NOLOCK void restartClub (APTR(Rcvr) ARG(rcvr));
	
  public: /* creation */

	
	BeClub (APTR(FeEdition) ARG(contents), TCSJ);
	
  private:
	CHKPTR(ID) OR(NULL) mySignatureClub;
	CHKPTR(MuSet) OF1(BeClub) myMembers;
	CHKPTR(MuSet) OF1(BeClub) myImmediateSuperClubs;
	CHKPTR(MuSet) OF1(BeWork) mySponsored;
	BooleanVar myWallFlag;
	CHKPTR(IDRegion) myTransitiveSuperClubIDs;
	CHKPTR(IDRegion) myTransitiveMemberIDs;
	NOCOPY CHKPTR(MuSet) OF1(NuKeyMaster) OR(NULL) myKeyMasters;
/* Friends for class BeClub */
/* friends for class BeClub */
friend class UpdateTransitiveMemberIDs;
friend class UpdateTransitiveSuperClubIDs;
friend class UpdateClubKeyMasterAuthorities;



};  /* end class BeClub */


#ifdef USE_INLINE
#ifndef BRANGE2X_IXX
#include "brange2x.ixx"
#endif /* BRANGE2X_IXX */


#endif /* USE_INLINE */


#endif /* BRANGE2X_HXX */

