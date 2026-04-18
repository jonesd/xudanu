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

#ifndef DAGWOODX_CXX
#define DAGWOODX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef DAGWOODX_HXX
#include "dagwoodx.hxx"
#endif /* DAGWOODX_HXX */

#ifndef DAGWOODX_IXX
#include "dagwoodx.ixx"
#endif /* DAGWOODX_IXX */


#ifndef BRANCHX_HXX
#include "branchx.hxx"
#endif /* BRANCHX_HXX */

#ifndef GRANTABX_HXX
#include "grantabx.hxx"
#endif /* GRANTABX_HXX */

#ifndef HSPACEX_HXX
#include "hspacex.hxx"
#endif /* HSPACEX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */




/* ************************************************************************ *
 * 
 *                    Class DagWood 
 *
 * ************************************************************************ */


/* Each dagwood defines a partial ordering of TracePositions.  
Several implementation variables use longs because they represent the 
size of an in-core array (which can't get that large).  The variable 
'myRoot' is just for debugging for the moment. */


/* accessing */


RPTR(TracePosition) DagWood::root (){
	return (TracePosition*) myRoot;
}


RPTR(BranchDescription) DagWood::successorBranchOfPosition (APTR(BranchDescription) /* branch */, UInt32 /* position */){
	/* Return all the successors of the receiver in the trace tree. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	return NULL;
}


RPTR(MuSet) DagWood::successorsOf (APTR(TracePosition) trace){
	/* Return the first used positions on all the successors of trace. */
	
	SPTR(BranchDescription) prevBranch;
	SPTR(MuSet) set;
	
	set = MuSet::make ();
	prevBranch = CAST(BranchDescription,myTrunk->fetch(HeaperAsPosition::make (trace)));
	if (prevBranch != NULL) {
		prevBranch->addSuccessorsTo(set);
	}
	WPTR(MuSet) 	returnValue;
	returnValue = set;
	return returnValue;
}
/* branches */


void DagWood::installBranchAfter (APTR(BranchDescription) branch, APTR(TracePosition) anchorTrace){
	/* Lookup the anchorTrace to find the branch hanging off it. 
	If there isn't one, 
		then install branch as that branch. Otherwise walk a 
	balanced walk down the 
		binary tree of branches to find a place to hang the new branch. */
	
	SPTR(BranchDescription) prevBranch;
	SPTR(Position) pos;
	
	prevBranch = CAST(BranchDescription,myTrunk->fetch(pos = HeaperAsPosition::make (anchorTrace)));
	if (prevBranch == NULL) {
		myTrunk->introduce(pos, branch);
	} else {
		prevBranch->installBranch(branch);
	}
}


RPTR(TracePosition) DagWood::newPosition (){
	/* This should really create a new root, but that's harder to draw!. */
	
	WPTR(TracePosition) 	returnValue;
	returnValue = myRoot->newSuccessor();
	return returnValue;
}
/* caching */


RPTR(PrimIndexTable) DagWood::cacheTracePos (APTR(TracePosition) tracePos){
	/* Install the supplied branch and position as the navCache 
	and return it.  */
	
	{	BooleanVar crutch_Flag;
		/* myCachedPosition != NULL && tracePos->isEqual(myCachedPosition) */
		
		crutch_Flag = myCachedPosition != NULL;
		if(crutch_Flag) {
			crutch_Flag = tracePos->isEqual(myCachedPosition);
		}
		if (crutch_Flag) {
			return (PrimIndexTable*) myNavCache;
		}
	}
	myCachedPosition = tracePos;
	myNavCache->clearAll();
	tracePos->cacheIn(myNavCache);
	return (PrimIndexTable*) myNavCache;
}
/* create */


DagWood::DagWood () {
	myCachedPosition = NULL;
	myNavCache = PrimIndexTable::make (128);
	myTrunk = GrandHashTable::make (HeaperSpace::make ());
	myRoot = TracePosition::make (BranchDescription::make (this), 1);
	/* Ensure that no elements get allocated on the root branch. */
	myRoot->newSuccessor();
	this->newShepherd();
	this->remember();
}
/* hooks: */


void DagWood::restartDagWood (APTR(Rcvr) /* trans *//* = NULL*/){
	/* re-initialize the non-persistent part */
	
	myCachedPosition = NULL;
	myNavCache = PrimIndexTable::make (128);
}
/* testing */


UInt32 DagWood::contentsHash (){
	return this->Abraham::contentsHash() ^ myRoot->hashForEqual();
}

#ifndef DAGWOODX_SXX
#include "dagwoodx.sxx"
#endif /* DAGWOODX_SXX */



#endif /* DAGWOODX_CXX */

