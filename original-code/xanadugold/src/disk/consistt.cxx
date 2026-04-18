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

#ifndef CONSISTT_CXX
#define CONSISTT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef CONSISTT_HXX
#include "consistt.hxx"
#endif /* CONSISTT_HXX */

#ifndef CONSISTT_IXX
#include "consistt.ixx"
#endif /* CONSISTT_IXX */


#ifndef COOKBKX_HXX
#include "cookbkx.hxx"
#endif /* COOKBKX_HXX */

#ifndef FLKINFOX_HXX
#include "flkinfox.hxx"
#endif /* FLKINFOX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef LOGGERX_HXX
#include "loggerx.hxx"
#endif /* LOGGERX_HXX */

#ifndef PACKERX_HXX
#include "packerx.hxx"
#endif /* PACKERX_HXX */

#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */

#ifndef STRINGX_HXX
#include "stringx.hxx"
#endif /* STRINGX_HXX */

#ifndef TURTLEX_HXX
#include "turtlex.hxx"
#endif /* TURTLEX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */




/* ************************************************************************ *
 * 
 *                    Class CBlockTracker 
 *
 * ************************************************************************ */



/* Initializers for CBlockTracker */

GPTR(CBlockTracker) OR(NULL) CBlockTracker::TheTrackerList = NULL;


/* Initializers for CBlockTracker */



/* creation */


RPTR(CBlockTracker) CBlockTracker::make (IntegerVar dirty, APTR(CBlockTracker) OR(NULL) outer){
	RETURN_CONSTRUCT(CBlockTracker,(dirty, outer));
}
/* printing */


void CBlockTracker::printTrackersOn (ostream& oo){
	/* CBlockTracker printTrackersOn: cerr. cerr endEntry */
	
	oo << "\n\nConsistent-Block Behavior\n\n";
	if (CBlockTracker::TheTrackerList != NULL) {
		CBlockTracker::TheTrackerList->printAllOn(oo);
	}
	oo << "\n";
}
/* creation */


CBlockTracker::CBlockTracker (IntegerVar dirty, APTR(CBlockTracker) OR(NULL) outer) {
	if (dirty == -1) {
		myMaxDirty = 1000;
	} else {
		myMaxDirty = dirty;
	}
	myOuterTracker = outer;
	myFileName = NULL;
	myLineNo = Int32Zero;
	myDirtySoFar = Int32Zero;
	myTrulyDirtySoFar = Int32Zero;
	myDirtyInfos = MuSet::make ();
	myDirtyInfosCount = Int32Zero;
	myOccurencesCount = 1;
	if (outer == NULL) {
		myLimit = myMaxDirty;
	} else {
		myLimit = min(outer->slack(), myMaxDirty);
	}
}
/* accessing */


void CBlockTracker::dirty (APTR(FlockInfo) OR(NULL) info){
	myDirtySoFar += 1;
	myTrulyDirtySoFar += 1;
	if ( ! (info != NULL) ) {
		BLAST(Assertion_failed);
	}
	myDirtyInfos->store(IntegerPos::make (info->getShepherd()->hashForEqual()));
	myDirtyInfosCount = myDirtyInfos->count();
	this->reportProblems();
}


RPTR(CBlockTracker) OR(NULL) CBlockTracker::fetchUnwrapped (){
	SPTR(CBlockTracker) OR(NULL) result;
	SPTR(CBlockTracker) OR(NULL) stored;
	
	result = myOuterTracker;
	if (result != NULL) {
		result->innerDirtied(myMaxDirty);
		result->innerTrulyDirtied(myTrulyDirtySoFar);
		result->innerDirtyInfos(myDirtyInfos);
		result->reportProblems();
	}
	if (myFileName != NULL) {
		{	BooleanVar crutch_Flag;
			/* CBlockTracker::TheTrackerList == NULL || (stored = CBlockTracker::TheTrackerList->fetchMatch(this)) == NULL */
			
			crutch_Flag = CBlockTracker::TheTrackerList == NULL;
			if(!crutch_Flag) {
				crutch_Flag = (stored = CBlockTracker::TheTrackerList->fetchMatch(this)) == NULL;
			}
			if (crutch_Flag) {
				myOuterTracker = CBlockTracker::TheTrackerList;
				myDirtyInfos = MuSet::make ();
				CBlockTracker::TheTrackerList = this;
			} else {
				stored->updateFrom(this);
			}
		}
	}
	WPTR(CBlockTracker) OR(NULL) 	returnValue;
	returnValue = result;
	return returnValue;
}


void CBlockTracker::track (char * fileName, Int32 lineNo){
	myFileName = fileName;
	myLineNo = lineNo;
}
/* printing */


void CBlockTracker::printAllOn (ostream& oo){
	oo << this << "\n";
	if (myOuterTracker != NULL) {
		myOuterTracker->printAllOn(oo);
	}
}


void CBlockTracker::printOn (ostream& oo){
	oo << "\"" << myFileName << "\"" << ", line " << myLineNo << ": " << this->getCategory()->name() << "(";
	oo << myMaxDirty << ",\t" << myLimit << ",\t" << myDirtySoFar << ",\t" << myTrulyDirtySoFar << ", " << myDirtyInfosCount << ", " << myOccurencesCount << ")";
}
/* private: accessing */


IntegerVar CBlockTracker::dirtyInfosCount (){
	return myDirtyInfosCount;
}


IntegerVar CBlockTracker::dirtySoFar (){
	return myDirtySoFar;
}


RPTR(CBlockTracker) OR(NULL) CBlockTracker::fetchMatch (APTR(CBlockTracker) other){
	{	BooleanVar crutch_Flag;
		/* myFileName != NULL && other->fileName() != NULL && ::strcmp(myFileName, other->fileName()) == Int32Zero && myLineNo == other->lineNo() */
		
		crutch_Flag = myFileName != NULL;
		if(crutch_Flag) {
			crutch_Flag = other->fileName() != NULL;
			if(crutch_Flag) {
				crutch_Flag = ::strcmp(myFileName, other->fileName()) == Int32Zero;
				if(crutch_Flag) {
					crutch_Flag = myLineNo == other->lineNo();
				}
			}
		}
		if (crutch_Flag) {
			return this;
		} else {
			if (myOuterTracker == NULL) {
				return NULL;
			} else {
				WPTR(CBlockTracker) OR(NULL) 	returnValue;
				returnValue = myOuterTracker->fetchMatch(other);
				return returnValue;
			}
		}
	}
}


char OR(NULL) * CBlockTracker::fileName (){
	return (char*) myFileName;
}


void CBlockTracker::innerDirtied (IntegerVar dirty){
	myDirtySoFar += dirty;
}


void CBlockTracker::innerDirtyInfos (APTR(MuSet) OF1(IntegerPos) dirties){
	myDirtyInfos->storeAll(dirties);
	myDirtyInfosCount = myDirtyInfos->count();
}


void CBlockTracker::innerTrulyDirtied (IntegerVar dirty){
	myTrulyDirtySoFar += dirty;
}


IntegerVar CBlockTracker::limit (){
	return myLimit;
}


Int32 CBlockTracker::lineNo (){
	return myLineNo;
}


IntegerVar CBlockTracker::maxDirty (){
	return myMaxDirty;
}


IntegerVar CBlockTracker::occurencesCount (){
	return myOccurencesCount;
}


void CBlockTracker::reportProblems (){
	/* (myLimit < 1000 
		 and: [myDirtyInfosCount > myMaxDirty 
		 		"((myDirtySoFar max: myTrulyDirtySoFar) max: 
	myDirtyInfosCount) > myLimit"])
			ifTrue: 
				[cerr << '
	Limit exceeded [
	'.
				self printAllOn: cerr.
				[cerr endEntry.
				"myDirtyInfosCount > myMaxDirty
					ifTrue: [self halt]"] smalltalkOnly] */
	return;
	
}


IntegerVar CBlockTracker::slack (){
	return myLimit - myDirtySoFar;
}


IntegerVar CBlockTracker::trulyDirtySoFar (){
	return myTrulyDirtySoFar;
}


void CBlockTracker::updateFrom (APTR(CBlockTracker) other){
	myMaxDirty = max(myMaxDirty, other->maxDirty());
	myLimit = min(myLimit, other->limit());
	myDirtySoFar = max(myDirtySoFar, other->dirtySoFar());
	myTrulyDirtySoFar = max(myTrulyDirtySoFar, other->trulyDirtySoFar());
	myDirtyInfosCount = max(myDirtyInfosCount, other->dirtyInfosCount());
	myOccurencesCount += other->occurencesCount();
}
/* testing */


UInt32 CBlockTracker::actualHashForEqual (){
	return Heaper::takeOop();
}



/* ************************************************************************ *
 * 
 *                    Class CBlockTrackingPacker 
 *
 * ************************************************************************ */


/* creation */


RPTR(DiskManager) CBlockTrackingPacker::make (APTR(DiskManager) subPacker){
	RETURN_CONSTRUCT(CBlockTrackingPacker,(subPacker, tcsj));
}
/* transactions */


void CBlockTrackingPacker::beginConsistent (IntegerVar dirty){
	myTracker = CBlockTracker::make (dirty, myTracker);
	myPacker->beginConsistent(dirty);
}


void CBlockTrackingPacker::consistentBlockAt (char * fileName, Int32 lineNo){
	if (this->checkTracker()) {
		myTracker->track(fileName, lineNo);
		myPacker->consistentBlockAt(fileName, lineNo);
	}
}


void CBlockTrackingPacker::endConsistent (IntegerVar dirty){
	if (this->checkTracker()) {
		myTracker = myTracker->fetchUnwrapped();
		myPacker->endConsistent(dirty);
	}
}


BooleanVar CBlockTrackingPacker::insideCommit (){
	return myPacker->insideCommit();
}


void CBlockTrackingPacker::purge (){
	myPacker->purge();
}


void CBlockTrackingPacker::purgeClean (BooleanVar noneLocked/* = FALSE*/){
	myPacker->purgeClean(noneLocked);
}
/* shepherds */


void CBlockTrackingPacker::destroyFlock (APTR(FlockInfo) info){
	/* Queue destroy of the given flock.  The destroy will 
	probably happen later. */
	
	myPacker->destroyFlock(info);
}


void CBlockTrackingPacker::diskUpdate (APTR(FlockInfo) OR(NULL) info){
	if (this->checkTracker()) {
		myTracker->dirty(info);
		myPacker->diskUpdate(info);
	}
}


void CBlockTrackingPacker::dismantleFlock (APTR(FlockInfo) info){
	/* The flock designated by info has completed all dismantling 
	actions; throw it off the disk. */
	
	myPacker->dismantleFlock(info);
}


void CBlockTrackingPacker::dropFlock (Int32 token){
	myPacker->dropFlock(token);
}


void CBlockTrackingPacker::forgetFlock (APTR(FlockInfo) info){
	if (this->checkTracker()) {
		myTracker->dirty(info);
		myPacker->forgetFlock(info);
	}
}


RPTR(Turtle) CBlockTrackingPacker::getInitialFlock (){
	WPTR(Turtle) 	returnValue;
	returnValue = myPacker->getInitialFlock();
	return returnValue;
}


UInt32 CBlockTrackingPacker::nextHashForEqual (){
	return myPacker->nextHashForEqual();
}


void CBlockTrackingPacker::rememberFlock (APTR(FlockInfo) info){
	if (this->checkTracker()) {
		myTracker->dirty(info);
		myPacker->rememberFlock(info);
	}
}


void CBlockTrackingPacker::storeAlmostNewShepherd (APTR(Abraham) shep){
	myPacker->storeAlmostNewShepherd(shep);
}


void CBlockTrackingPacker::storeInitialFlock (
		APTR(Abraham) turtle, 
		APTR(XcvrMaker) protocol, 
		APTR(Cookbook) cookbook)
{
	myPacker->storeInitialFlock(turtle, protocol, cookbook);
}


void CBlockTrackingPacker::storeNewFlock (APTR(Abraham) shep){
	if (this->checkTracker()) {
		myPacker->storeNewFlock(shep);
		myTracker->dirty(shep->getInfo());
	}
}
/* stubs */


RPTR(Abraham) CBlockTrackingPacker::fetchCanonical (
		UInt32 hash, 
		Int32 snarfID, 
		Int32 index)
{
	WPTR(Abraham) 	returnValue;
	returnValue = myPacker->fetchCanonical(hash, snarfID, index);
	return returnValue;
}


void CBlockTrackingPacker::makeReal (APTR(FlockInfo) info){
	myPacker->makeReal(info);
}


void CBlockTrackingPacker::registerStub (
		APTR(Abraham) shep, 
		Int32 snarfID, 
		Int32 index)
{
	myPacker->registerStub(shep, snarfID, index);
}
/* create */


CBlockTrackingPacker::CBlockTrackingPacker (APTR(DiskManager) subPacker, TCSJ) {
	myPacker = subPacker;
	myTracker = NULL;
	this->flockTable(myPacker->flockTable());
	this->flockInfoTable(myPacker->flockInfoTable());
}
/* protected: destruction */


void CBlockTrackingPacker::destruct (){
	if ( ! (myTracker == NULL) ) {
		BLAST(Assertion_failed);
	}
	{myPacker->destroy();  myPacker = NULL /* don't want stale (S/CHK)PTRs */;}
	this->DiskManager::destruct();
}
/* testing */


BooleanVar CBlockTrackingPacker::isFake (){
	return myPacker->isFake();
}
/* private: */


BooleanVar CBlockTrackingPacker::checkTracker (){
	if (myTracker != NULL) {
		return TRUE;
	}
	
	ErrorLog << "Must be inside consistent block\n";
}


void CBlockTrackingPacker::commitState (BooleanVar flag){
	/* Used by ResetCommit bomb */
	
	CAST(SnarfPacker,myPacker)->commitState(flag);
}



/* ************************************************************************ *
 * 
 *                    Class PrintCBlocksTracks 
 *
 * ************************************************************************ */


/* operate */


void PrintCBlocksTracks::execute (){
	/*  */
	/* PrintCBlocksTracks create execute */
	
	CBlockTracker::printTrackersOn(cerr);
	
}

	/* automatic 0-argument constructor */
PrintCBlocksTracks::PrintCBlocksTracks() {}



/* ************************************************************************ *
 * 
 *                    Class TrackCBlocks 
 *
 * ************************************************************************ */


/* accessing */


RPTR(Category) TrackCBlocks::bootCategory (){
	WPTR(Category) 	returnValue;
	returnValue = myBootPlan->bootCategory();
	return returnValue;
}


RPTR(Connection) TrackCBlocks::connection (){
	/* Return the object representing the connection. This gives 
	the client a handle by 
		which to terminate the connection. */
	
	SPTR(Connection) result;
	
	result = myBootPlan->connection();
	CurrentPacker.fluidSet(CBlockTrackingPacker::make (CurrentPacker.fluidGet()));
	WPTR(Connection) 	returnValue;
	returnValue = result;
	return returnValue;
}

	/* automatic 0-argument constructor */
TrackCBlocks::TrackCBlocks() {}

#ifndef CONSISTT_SXX
#include "consistt.sxx"
#endif /* CONSISTT_SXX */



#endif /* CONSISTT_CXX */

