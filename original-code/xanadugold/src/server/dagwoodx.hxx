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

#ifndef DAGWOODX_HXX
#define DAGWOODX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef DAGWOODX_OXX
#include "dagwoodx.oxx"
#endif /* DAGWOODX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */


#ifndef BRANCHX_OXX
#include "branchx.oxx"
#endif /* BRANCHX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef PRIMTABX_OXX
#include "primtabx.oxx"
#endif /* PRIMTABX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef TABLESX_OXX
#include "tablesx.oxx"
#endif /* TABLESX_OXX */

#ifndef TRACEPX_OXX
#include "tracepx.oxx"
#endif /* TRACEPX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class DagWood 
 *
 * ************************************************************************ */




	/* Each dagwood defines a partial ordering of TracePositions. 
	 Several implementation variables use longs because they 
	represent the size of an in-core array (which can't get that 
	large).  The variable 'myRoot' is just for debugging for the moment. */

class DagWood : public Abraham {

/* Attributes for class DagWood */
	CONCRETE(DagWood)
	SHEPHERD_PATRIARCH(DagWood,Abraham)
	LOCKED(DagWood)
	COPY(DagWood,DiskCuisine)
	AUTO_GC(DagWood)
  public: /* accessing */

	
	virtual NOLOCK RPTR(TracePosition) root ();
	
	/* Return all the successors of the receiver in the trace tree. */
	
	virtual RPTR(BranchDescription) successorBranchOfPosition (APTR(BranchDescription) ARG(branch), UInt32 ARG(position));
	
	/* Return the first used positions on all the successors of trace. */
	
	virtual RPTR(MuSet) successorsOf (APTR(TracePosition) ARG(trace));
	
  public: /* branches */

	/* Lookup the anchorTrace to find the branch hanging off it. 
	If there isn't one, 
		then install branch as that branch. Otherwise walk a 
	balanced walk down the 
		binary tree of branches to find a place to hang the new branch. */
	
	virtual void installBranchAfter (APTR(BranchDescription) ARG(branch), APTR(TracePosition) ARG(anchorTrace));
	
	/* This should really create a new root, but that's harder to draw!. */
	
	virtual RPTR(TracePosition) newPosition ();
	
  public: /* caching */

	/* Install the supplied branch and position as the navCache 
	and return it.  */
	
	virtual RPTR(PrimIndexTable) cacheTracePos (APTR(TracePosition) ARG(tracePos));
	
  public: /* create */

	
	DagWood ();
	
  public: /* hooks: */

	/* re-initialize the non-persistent part */
	
	virtual RECEIVE_HOOK void restartDagWood (APTR(Rcvr) ARG(trans) = NULL);
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	CHKPTR(TracePosition) myRoot;
	CHKPTR(MuTable) OF2(TracePosition,BranchDescription) myTrunk;
	NOCOPY CHKPTR(TracePosition) myCachedPosition;
	NOCOPY CHKPTR(PrimIndexTable) myNavCache;
};  /* end class DagWood */



#endif /* DAGWOODX_HXX */

