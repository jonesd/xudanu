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

#ifndef COUNTERX_CXX
#define COUNTERX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef COUNTERX_HXX
#include "counterx.hxx"
#endif /* COUNTERX_HXX */

#ifndef COUNTERX_IXX
#include "counterx.ixx"
#endif /* COUNTERX_IXX */

#ifndef COUNTERP_HXX
#include "counterp.hxx"
#endif /* COUNTERP_HXX */

#ifndef COUNTERP_IXX
#include "counterp.ixx"
#endif /* COUNTERP_IXX */


#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */




/* ************************************************************************ *
 * 
 *                    Class Counter 
 *
 * ************************************************************************ */


/* pseudo-constructors */


RPTR(Counter) Counter::fakeCounter (
		IntegerVar count, 
		IntegerVar batchCount, 
		UInt32 hash)
{
	WPTR(Counter) 	returnValue;
	returnValue = BatchCounter::makeFakeCounter(count, batchCount, hash);
	return returnValue;
}


RPTR(Counter) Counter::make (){
	RETURN_CONSTRUCT(SingleCounter,());
}


RPTR(Counter) Counter::make (IntegerVar count){
	RETURN_CONSTRUCT(SingleCounter,(count, tcsj));
}


RPTR(Counter) Counter::make (IntegerVar count, IntegerVar batchCount){
	WPTR(Counter) 	returnValue;
	returnValue = BatchCounter::make (count, batchCount);
	return returnValue;
}
/* accessing */
/* printing */


void Counter::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << this->count() << ")";
}
/* protected: creation */


Counter::Counter () {
	
}


Counter::Counter (UInt32 hash, TCSJ) 
	: Abraham(hash, tcsj) {
	
}



/* ************************************************************************ *
 * 
 *                    Class BatchCounter 
 *
 * ************************************************************************ */


/* pseudo-constructors */


RPTR(Counter) BatchCounter::make (IntegerVar count, IntegerVar batchCount){
	RETURN_CONSTRUCT(BatchCounter,(count, batchCount));
}


RPTR(Counter) BatchCounter::makeFakeCounter (
		IntegerVar count, 
		IntegerVar batchCount, 
		UInt32 hash)
{
	RETURN_CONSTRUCT(BatchCounter,(count, batchCount, hash));
}
/* Instances preallocate a bunch of numbers and record the 
preallocations to disk.  It then increments purely in memory until 
the preallocated counts are used up.  It then preallocates another 
bunch of numbers.  If the system crashes, all numbers between the 
in-memory count and the on-disk count simply never get used.  This 
reduces the access to disk for shepherd hashes and GrandMap IDs. */


/* accessing */


IntegerVar BatchCounter::count (){
	return myCount;
}


IntegerVar BatchCounter::decrement (){
	BEGIN_CRITICAL_BLOCK(myMutex) {
		BEGIN_CONSISTENT(1) {
			myCount -= 1;
			this->diskUpdate();
		} END_CONSISTENT;
	} END_CRITICAL_BLOCK;
	return myCount;
}


IntegerVar BatchCounter::decrementBy (IntegerVar count){
	if (!(count >= IntegerVarZero)) {
		BLAST(InvalidRequest);
	}
	BEGIN_CRITICAL_BLOCK(myMutex) {
		BEGIN_CONSISTENT(1) {
			myCount -= count;
			this->diskUpdate();
		} END_CONSISTENT;
	} END_CRITICAL_BLOCK;
	return myCount;
}


IntegerVar BatchCounter::increment (){
	BEGIN_CRITICAL_BLOCK(myMutex) {
		myCount += 1;
		if (myCount > myPersistentCount) {
			BEGIN_CONSISTENT(1) {
				myPersistentCount = myCount + myBatchCount;
				this->diskUpdate();
			} END_CONSISTENT;
		}
	} END_CRITICAL_BLOCK;
	return myCount;
}


IntegerVar BatchCounter::incrementBy (IntegerVar count){
	if (!(count >= IntegerVarZero)) {
		BLAST(InvalidRequest);
	}
	BEGIN_CRITICAL_BLOCK(myMutex) {
		myCount += count;
		if (myCount > myPersistentCount) {
			BEGIN_CONSISTENT(1) {
				myPersistentCount = myCount + myBatchCount;
				this->diskUpdate();
			} END_CONSISTENT;
		}
	} END_CRITICAL_BLOCK;
	return myCount;
}


void BatchCounter::setCount (IntegerVar count){
	BEGIN_CRITICAL_BLOCK(myMutex) {
		BEGIN_CONSISTENT(1) {
			myCount = count;
			this->diskUpdate();
		} END_CONSISTENT;
	} END_CRITICAL_BLOCK;
}
/* receiver: stubble */


void BatchCounter::restartBatchCounter (APTR(Rcvr) /* trans *//* = NULL*/){
	/* re-initialize the non-persistent part */
	
	myCount = myPersistentCount;
	myMutex = Sema4::make (1);
}
/* protected: create */


BatchCounter::BatchCounter (IntegerVar count, IntegerVar batchCount) {
	BEGIN_CONSISTENT(1) {
		myPersistentCount = myCount = count;
		myBatchCount = batchCount;
		this->restartBatchCounter(NULL);
		this->newShepherd();
		this->remember();
	} END_CONSISTENT;
}


BatchCounter::BatchCounter (
		IntegerVar count, 
		IntegerVar batchCount, 
		UInt32 hash) 

	: Counter(hash, tcsj) {
	myPersistentCount = myCount = count;
	myBatchCount = batchCount;
	this->restartBatchCounter(NULL);
}
/* testing */


UInt32 BatchCounter::contentsHash (){
	return this->Counter::contentsHash() ^ IntegerPos::integerHash(myPersistentCount);
}



/* ************************************************************************ *
 * 
 *                    Class SingleCounter 
 *
 * ************************************************************************ */


/* pseudo-constructors */


RPTR(Counter) SingleCounter::make (){
	RETURN_CONSTRUCT(SingleCounter,());
}


RPTR(Counter) SingleCounter::make (IntegerVar count){
	RETURN_CONSTRUCT(SingleCounter,(count, tcsj));
}
/* This counter separates a very simple state change into another 
flock so that big objects like GrandMaps and GrandHashTables don't 
ned to flush their entirety to disk.  It localizes the state change 
of a counter. */


/* accessing */


IntegerVar SingleCounter::count (){
	return myCount;
}


IntegerVar SingleCounter::decrement (){
	BEGIN_CRITICAL_BLOCK(myMutex) {
		BEGIN_CONSISTENT(1) {
			myCount -= 1;
			this->diskUpdate();
		} END_CONSISTENT;
	} END_CRITICAL_BLOCK;
	return myCount;
}


IntegerVar SingleCounter::decrementBy (IntegerVar count){
	if (!(count >= IntegerVarZero)) {
		BLAST(InvalidRequest);
	}
	BEGIN_CRITICAL_BLOCK(myMutex) {
		BEGIN_CONSISTENT(1) {
			myCount -= count;
			this->diskUpdate();
		} END_CONSISTENT;
	} END_CRITICAL_BLOCK;
	return myCount;
}


IntegerVar SingleCounter::increment (){
	BEGIN_CRITICAL_BLOCK(myMutex) {
		BEGIN_CONSISTENT(1) {
			myCount += 1;
			this->diskUpdate();
		} END_CONSISTENT;
	} END_CRITICAL_BLOCK;
	return myCount;
}


IntegerVar SingleCounter::incrementBy (IntegerVar count){
	if (!(count >= IntegerVarZero)) {
		BLAST(InvalidRequest);
	}
	BEGIN_CRITICAL_BLOCK(myMutex) {
		BEGIN_CONSISTENT(1) {
			myCount += count;
			this->diskUpdate();
		} END_CONSISTENT;
	} END_CRITICAL_BLOCK;
	return myCount;
}


void SingleCounter::setCount (IntegerVar count){
	BEGIN_CRITICAL_BLOCK(myMutex) {
		BEGIN_CONSISTENT(1) {
			myCount = count;
			this->diskUpdate();
		} END_CONSISTENT;
	} END_CRITICAL_BLOCK;
}
/* receiver: restart */


void SingleCounter::restartSingleCounter (APTR(Rcvr) /* trans *//* = NULL*/){
	/* re-initialize the non-persistent part */
	
	myMutex = Sema4::make (1);
}
/* protected: create */


SingleCounter::SingleCounter () {
	myCount = IntegerVar0;
	this->restartSingleCounter(NULL);
	this->newShepherd();
	this->remember();
}


SingleCounter::SingleCounter (IntegerVar count, TCSJ) {
	myCount = count;
	this->restartSingleCounter(NULL);
	this->newShepherd();
	this->remember();
}
/* testing */


UInt32 SingleCounter::contentsHash (){
	return this->Counter::contentsHash() ^ IntegerPos::integerHash(myCount);
}

#ifndef COUNTERX_SXX
#include "counterx.sxx"
#endif /* COUNTERX_SXX */


#ifndef COUNTERP_SXX
#include "counterp.sxx"
#endif /* COUNTERP_SXX */



#endif /* COUNTERX_CXX */

