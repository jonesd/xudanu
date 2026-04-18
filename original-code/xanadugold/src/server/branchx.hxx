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

#ifndef BRANCHX_HXX
#define BRANCHX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef BRANCHX_OXX
#include "branchx.oxx"
#endif /* BRANCHX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */


#ifndef DAGWOODX_OXX
#include "dagwoodx.oxx"
#endif /* DAGWOODX_OXX */

#ifndef PRIMTABX_OXX
#include "primtabx.oxx"
#endif /* PRIMTABX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef TRACEPX_OXX
#include "tracepx.oxx"
#endif /* TRACEPX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class BranchDescription 
 *
 * ************************************************************************ */




	/* Instances of subclasses describe the different kinds of 
	paths in a traceDag.  The 
	three kinds are root (no parent), tree (one parent) and dag 
	(two parent) branches.  
	The dag caching routine chases up the dag finding the max of 
	all paths.  The special 
	case of chasing up the hierarchy is probably not worth the code.
	
	At the moment, these never go away!!! */

class BranchDescription : public Abraham {

/* Attributes for class BranchDescription */
	DEFERRED(BranchDescription)
	SHEPHERD_PATRIARCH(BranchDescription,Abraham)
	COPY(BranchDescription,DiskCuisine)
	DEFERRED_LOCKED(BranchDescription)
	AUTO_GC(BranchDescription)
  public: /* instance creation */

	
	static RPTR(BranchDescription) make (APTR(DagWood) ARG(xfulltrace));
	
	
	static RPTR(BranchDescription) make (APTR(DagWood) ARG(xfulltrace), APTR(TracePosition) ARG(parent));
	
	
	static RPTR(BranchDescription) make (
			APTR(DagWood) ARG(xfulltrace), 
			APTR(TracePosition) ARG(parent1), 
			APTR(TracePosition) ARG(parent2))
	;
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
	
	virtual BooleanVar doesInclude (UInt32 ARG(position), APTR(TracePosition) ARG(tracePos));
	
  public: /* deferred accessing */

	/* recur toward the root filling in the cache. */
	
	virtual void cacheRecur (APTR(PrimIndexTable) ARG(navCache)) DEFERRED_SUBR;
	
  public: /* accessing */

	/* Add the first useable positions for all successor branches 
	to the set. */
	
	virtual void addSuccessorsTo (APTR(MuSet) ARG(set));
	
	
	virtual RPTR(ImmuSet) successorsOf (APTR(BoundedTrace) ARG(trace));
	
  public: /* position making */

	/* Return a new successor to the receiver. The first 
	successor is on the 
		same branch with a higher position. Further successors are allocated 
		in a binary-tree fashion along a new branch. */
	
	virtual RPTR(TracePosition) createAfter (APTR(BoundedTrace) ARG(trace));
	
	/* Install branch as a descendant branch of myself. Walk down 
	the binary tree of 
		branches to find a place to lodge it. This gets called if 
	there was already a 
		branch existing off my root. */
	
	virtual void installBranch (APTR(BranchDescription) ARG(branch));
	void BranchDescription::walkBranch ();

	
	virtual void installBranchAfter (APTR(BranchDescription) ARG(branch), APTR(TracePosition) ARG(trace));
	
	/* Create a dag branch that succeeds both trace1 and trace2. */
	
	virtual RPTR(BranchDescription) makeBranch (APTR(TracePosition) ARG(trace1), APTR(TracePosition) ARG(trace2));
	
	/* Return the first available tracePosition on this branch. */
	
	virtual RPTR(TracePosition) nextPosition ();
	
  protected: /* protected: protected create */

	
	BranchDescription (APTR(DagWood) ARG(ft), TCSJ);
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
  private:
	UInt32 lastPosition;
	CHKPTR(BranchDescription) myLeft;
	CHKPTR(BranchDescription) myRight;
	CHKPTR(DagWood) fulltrace;
};  /* end class BranchDescription */



/* ************************************************************************ *
 * 
 *                    Class   DagBranch 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class DagBranch : public BranchDescription {

/* Attributes for class DagBranch */
	CONCRETE(DagBranch)
	SHEPHERD_ANCESTOR(DagBranch,BranchDescription)
	COPY(DagBranch,DiskCuisine)
	LOCKED(DagBranch)
	NOT_A_TYPE(DagBranch)
	AUTO_GC(DagBranch)
  public: /* caching */

	
	virtual void cacheRecur (APTR(PrimIndexTable) ARG(navCache));
	
  public: /* create */

	
	DagBranch (
			APTR(DagWood) ARG(ft), 
			APTR(TracePosition) ARG(p1), 
			APTR(TracePosition) ARG(p2))
	;
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	CHKPTR(TracePosition) parent1;
	CHKPTR(TracePosition) parent2;
	friend class BranchDescription;
};  /* end class DagBranch */



/* ************************************************************************ *
 * 
 *                    Class   RootBranch 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class RootBranch : public BranchDescription {

/* Attributes for class RootBranch */
	CONCRETE(RootBranch)
	SHEPHERD_ANCESTOR(RootBranch,BranchDescription)
	COPY(RootBranch,DiskCuisine)
	LOCKED(RootBranch)
	NOT_A_TYPE(RootBranch)
	NO_GC(RootBranch)
  public: /* caching */

	/* The recursion ends here. */
	
	virtual NOLOCK void cacheRecur (APTR(PrimIndexTable) ARG(navCache));
	
  public: /* create */

	
	RootBranch (APTR(DagWood) ARG(ft), TCSJ);
	

	friend class BranchDescription;
};  /* end class RootBranch */



/* ************************************************************************ *
 * 
 *                    Class   TreeBranch 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class TreeBranch : public BranchDescription {

/* Attributes for class TreeBranch */
	CONCRETE(TreeBranch)
	SHEPHERD_ANCESTOR(TreeBranch,BranchDescription)
	COPY(TreeBranch,DiskCuisine)
	LOCKED(TreeBranch)
	NOT_A_TYPE(TreeBranch)
	AUTO_GC(TreeBranch)
  public: /* caching */

	
	virtual void cacheRecur (APTR(PrimIndexTable) ARG(navCache));
	
  public: /* create */

	
	TreeBranch (APTR(DagWood) ARG(ft), APTR(TracePosition) ARG(p));
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	CHKPTR(TracePosition) parent;
	friend class BranchDescription;
};  /* end class TreeBranch */



#endif /* BRANCHX_HXX */

