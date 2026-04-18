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

#ifndef BRANGE2P_HXX
#define BRANGE2P_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef BRANGE2X_HXX
#include "brange2x.hxx"
#endif /* BRANGE2X_HXX */

#ifndef BRANGE2P_OXX
#include "brange2p.oxx"
#endif /* BRANGE2P_OXX */


#ifndef TURTLEX_HXX
#include "turtlex.hxx"
#endif /* TURTLEX_HXX */

#ifndef WPARRAYX_HXX
#include "wparrayx.hxx"
#endif /* WPARRAYX_HXX */


#ifndef GRANMAPX_OXX
#include "granmapx.oxx"
#endif /* GRANMAPX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class BeWorkLockExecutor 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class BeWorkLockExecutor : public XnExecutor {

/* Attributes for class BeWorkLockExecutor */
	CONCRETE(BeWorkLockExecutor)
	AUTO_GC(BeWorkLockExecutor)
  public: /* pseudoconstructors */

	
	static RPTR(BeWorkLockExecutor) make (APTR(BeWork) ARG(work));
	
  public: /* invoking */

	/* The work's locking pointer will already be NULL, so we 
	only have to update */
	
	virtual void execute (Int32 ARG(estateIndex));
	
  public: /* create */

	
	BeWorkLockExecutor (APTR(BeWork) ARG(work), TCSJ);
	
  private:
	CHKPTR(BeWork) myWork;
};  /* end class BeWorkLockExecutor */



/* ************************************************************************ *
 * 
 *                    Class RevisionWatcherExecutor 
 *
 * ************************************************************************ */




	/* This executor tells its BeWork when the last of its 
	revision watchers have gone away. */

class RevisionWatcherExecutor : public XnExecutor {

/* Attributes for class RevisionWatcherExecutor */
	CONCRETE(RevisionWatcherExecutor)
	NOT_A_TYPE(RevisionWatcherExecutor)
	AUTO_GC(RevisionWatcherExecutor)
  public: /* create */

	
	static RPTR(XnExecutor) make (APTR(BeWork) ARG(work));
	
  protected: /* protected: create */

	
	RevisionWatcherExecutor (APTR(BeWork) ARG(work), TCSJ);
	
  public: /* execute */

	
	virtual void execute (Int32 ARG(arg));
	
  private:
	CHKPTR(BeWork) myWork;
};  /* end class RevisionWatcherExecutor */



/* ************************************************************************ *
 * 
 *                    Class UpdateTransitiveMemberIDs 
 *
 * ************************************************************************ */




	/* This carries on the updating of transitive member IDs for 
	the given club. */

class UpdateTransitiveMemberIDs : public AgendaItem {

/* Attributes for class UpdateTransitiveMemberIDs */
	CONCRETE(UpdateTransitiveMemberIDs)
	SHEPHERD_PATRIARCH(UpdateTransitiveMemberIDs,AgendaItem)
	LOCKED(UpdateTransitiveMemberIDs)
	COPY(UpdateTransitiveMemberIDs,DiskCuisine)
	AUTO_GC(UpdateTransitiveMemberIDs)
  public: /* creation */

	
	static RPTR(UpdateTransitiveMemberIDs) make (APTR(MuSet) OF1(BeClub) ARG(clubs));
	
  public: /* accessing */

	
	virtual BooleanVar step ();
	
  protected: /* protected: creation */

	
	UpdateTransitiveMemberIDs (APTR(MuSet) OF1(BeClub) ARG(clubs), TCSJ);
	
  private:
	CHKPTR(MuSet) OF1(BeClub) myClubs;
};  /* end class UpdateTransitiveMemberIDs */



/* ************************************************************************ *
 * 
 *                    Class UpdateTransitiveSuperClubIDs 
 *
 * ************************************************************************ */




	/* This carries on the updating of transitive superclass IDs 
	for the given club. */

class UpdateTransitiveSuperClubIDs : public AgendaItem {

/* Attributes for class UpdateTransitiveSuperClubIDs */
	CONCRETE(UpdateTransitiveSuperClubIDs)
	SHEPHERD_PATRIARCH(UpdateTransitiveSuperClubIDs,AgendaItem)
	LOCKED(UpdateTransitiveSuperClubIDs)
	COPY(UpdateTransitiveSuperClubIDs,DiskCuisine)
	AUTO_GC(UpdateTransitiveSuperClubIDs)
  public: /* creation */

	
	static RPTR(UpdateTransitiveSuperClubIDs) make (APTR(MuSet) OF1(BeClub) ARG(clubs), APTR(BeGrandMap) ARG(grandMap));
	
  public: /* accessing */

	
	virtual BooleanVar step ();
	
  protected: /* protected: creation */

	
	UpdateTransitiveSuperClubIDs (APTR(MuSet) OF1(BeClub) ARG(clubs), APTR(BeGrandMap) ARG(grandMap));
	
  private:
	CHKPTR(MuSet) OF1(BeClub OR(NULL)) myClubs;
	CHKPTR(BeGrandMap) myGrandMap;
};  /* end class UpdateTransitiveSuperClubIDs */



#endif /* BRANGE2P_HXX */

