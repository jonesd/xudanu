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

#ifndef PRIMTABX_CXX
#define PRIMTABX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef PRIMTABX_HXX
#include "primtabx.hxx"
#endif /* PRIMTABX_HXX */

#ifndef PRIMTABX_IXX
#include "primtabx.ixx"
#endif /* PRIMTABX_IXX */

#ifndef PRIMTABP_HXX
#include "primtabp.hxx"
#endif /* PRIMTABP_HXX */

#ifndef PRIMTABP_IXX
#include "primtabp.ixx"
#endif /* PRIMTABP_IXX */


#ifndef FHASHX_HXX
#include "fhashx.hxx"
#endif /* FHASHX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */




/* ************************************************************************ *
 * 
 *                    Class PrimIndexTable 
 *
 * ************************************************************************ */


/* create */


RPTR(PrimIndexTable) PrimIndexTable::make (Int32 size){
	RETURN_CONSTRUCT(PrimIndexTable,(size, FALSE));
}


RPTR(PrimIndexTable) PrimIndexTable::wimpyIndexTable (Int32 size){
	RETURN_CONSTRUCT(PrimIndexTable,(size, TRUE));
}
/* Map possibly wimpy pointers to integers.  Common usage almost never does a
remove on this class, therefore we rehash in order to save time on 
other ops. */


/* accessing */


void PrimIndexTable::introduce (APTR(Heaper) ptr, IntegerVar index){
	Int32 loc;
	
	/* redundant code for sake of speed */
	loc = this->hashFind(ptr);
	if (myPtrs->fetch(loc) == NULL) {
		myIndices->storeIntegerVar(loc, index);
		myPtrs->store(loc, ptr);
	} else {
		BLAST(AlreadyInTable);
	}
	myTally += 1;
	if (myTally > myPtrs->count() >> 1) {
		this->grow();
	}
}


void PrimIndexTable::store (APTR(Heaper) ptr, IntegerVar index){
	Int32 loc;
	
	loc = this->hashFind(ptr);
	if (!(myPtrs->fetch(loc) != NULL)) {
		myTally += 1;
	}
	myIndices->storeIntegerVar(loc, index);
	myPtrs->store(loc, ptr);
	if (myTally > myPtrs->count() >> 1) {
		this->grow();
	}
}


void PrimIndexTable::clearAll (){
	/* Clear all entries from the table. I know this looks like a 
	hack, but the 
		alternative is to throw away the table and build a new one: 
	an expensive 
		prospect for comm. */
	
	if (myPtrs->count() > myOriginalSize) {
		{myPtrs->destroy();  myPtrs = NULL /* don't want stale (S/CHK)PTRs */;}
		if (amWimpy) {
			myPtrs = WeakPtrArray::make (XnExecutor::noopExecutor(), myOriginalSize);
		} else {
			myPtrs = PtrArray::nulls(myOriginalSize);
		}
	} else {
		myPtrs->storeAll();
	}
	myTally = Int32Zero;
}


IntegerVar PrimIndexTable::fetch (APTR(Heaper) ptr){
	/* return -1 on not found. */
	
	Int32 loc;
	
	loc = this->hashFindFetch(ptr);
	if (loc == -1) {
		return -1;
	}
	return myIndices->integerVarAt(loc);
}


IntegerVar PrimIndexTable::get (APTR(Heaper) ptr){
	Int32 loc;
	
	loc = this->hashFind(ptr);
	if (myPtrs->fetch(loc) == NULL) {
		BLAST(NotInTable);
	}
	return myIndices->integerVarAt(loc);
}


void PrimIndexTable::remove (APTR(Heaper) ptr){
	Int32 loc;
	
	loc = this->hashFind(ptr);
	if (myPtrs->fetch(loc) == NULL) {
		BLAST(NotInTable);
	}
	myPtrs->store(loc, NULL);
	myTally -= 1;
	this->rehash(myPtrs, myIndices, myPtrs->count());
}
/* protected: */


PrimIndexTable::PrimIndexTable (Int32 size, BooleanVar wimpy) {
	amWimpy = wimpy;
	if (amWimpy) {
		myPtrs = WeakPtrArray::make (XnExecutor::noopExecutor(), size);
	} else {
		myPtrs = PtrArray::nulls(size);
	}
	myIndices = IntegerVarArray::zeros(size);
	myTally = Int32Zero;
	myOriginalSize = size;
}


void PrimIndexTable::destruct (){
	{myPtrs->destroy();  myPtrs = NULL /* don't want stale (S/CHK)PTRs */;}
	{myIndices->destroy();  myIndices = NULL /* don't want stale (S/CHK)PTRs */;}
	this->Heaper::destruct();
}
/* private: */


void PrimIndexTable::grow (){
	this->rehash(myPtrs, myIndices, 5 * myPtrs->count() / 3);
}


Int32 PrimIndexTable::hashFind (APTR(Heaper) value){
	Int32 loc;
	Int32 start;
	Int32 top;
	WPTR(Heaper) tmp;
	
	loc = value->hashForEqual();
	top = myPtrs->count();
	loc = ::fastHash(loc) % top;
	start = loc;
	while ((tmp = myPtrs->fetch(loc)) != NULL) {
		if (tmp == value) {
			return loc;
		}
		loc += 1;
		if (loc == start) {
			BLAST(SanityViolation);
		}
		if (loc >= top) {
			loc = Int32Zero;
		}
	}
	return loc;
}


Int32 PrimIndexTable::hashFindFetch (APTR(Heaper) value){
	Int32 hashLoc;
	Int32 loc;
	Int32 top;
	WPTR(Heaper) tmp;
	
	if (value == NULL) {

		return -1;
	}
	hashLoc = value->hashForEqual();
	top = myPtrs->count();
	hashLoc = ::fastHash(hashLoc) % top;
	loc = hashLoc;
	while ((tmp = myPtrs->fetch(loc)) != NULL) {
		if (tmp == value) {
			return loc;
		}
		loc += 1;
		if (loc == hashLoc) {
			return -1;
		}
		if (loc >= top) {
			loc = Int32Zero;
		}
	}
	return -1;
}


void PrimIndexTable::rehash (
		APTR(PtrArray) oldPtrs, 
		APTR(IntegerVarArray) oldIndices, 
		Int32 newSize)
{
	if (amWimpy) {
		myPtrs = WeakPtrArray::make (XnExecutor::noopExecutor(), newSize);
	} else {
		myPtrs = PtrArray::nulls(newSize);
	}
	myIndices = IntegerVarArray::zeros(newSize);
	{
		Int32 LoopFinal = oldPtrs->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				Int32 loc;
				
				if (oldPtrs->fetch(i) != NULL) {
					loc = this->hashFind(oldPtrs->fetch(i));
					myIndices->storeIntegerVar(loc, oldIndices->integerVarAt(i));
					myPtrs->store(loc, oldPtrs->fetch(i));
				}
			}
			i += 1;
		}
	}
	{oldPtrs->destroy();  oldPtrs = NULL /* don't want stale (S/CHK)PTRs */;}
	{oldIndices->destroy();  oldIndices = NULL /* don't want stale (S/CHK)PTRs */;}
}
/* testing */


UInt32 PrimIndexTable::actualHashForEqual (){
	return myTally ^ myPtrs->count();
}
/* enumerating */


RPTR(PrimIndexTableStepper) PrimIndexTable::stepper (){
	RETURN_CONSTRUCT(PrimIndexTableStepper,(myPtrs, myIndices, Int32Zero));
}



/* ************************************************************************ *
 * 
 *                    Class PrimIndexTableStepper 
 *
 * ************************************************************************ */


/* Stepper over map from pointers to integers */


/* accessing */


WPTR(Heaper) PrimIndexTableStepper::fetch (){
	if (myIndex < myPtrs->count()) {
		WPTR(Heaper) 	returnValue;
		returnValue = IntegerPos::make (myIndices->integerVarAt(myIndex));
		return returnValue;
	} else {
		return NULL;
	}
}


BooleanVar PrimIndexTableStepper::hasValue (){
	return myIndex < myPtrs->count();
}


RPTR(Heaper) PrimIndexTableStepper::key (){
	/* This does not necessarily return a Position */
	
	if (myIndex < myIndices->count()) {
		WPTR(Heaper) 	returnValue;
		returnValue = myPtrs->fetch(myIndex);
		return returnValue;
	}
	BLAST(EmptyStepper);
	/* Hush up the compiler */
	return NULL;
}


void PrimIndexTableStepper::step (){
	WPTR(Heaper) tmp;
	
	myIndex += 1;
	for (;;) {	BooleanVar crutch_Flag;
		/* myIndex < myPtrs->count() && ((tmp = myPtrs->fetch(myIndex)) == NULL || tmp == PrimRemovedObject::make ()) */
		
		crutch_Flag = myIndex < myPtrs->count();
		if(crutch_Flag) {
			crutch_Flag = (tmp = myPtrs->fetch(myIndex)) == NULL;
			if(!crutch_Flag) {
				crutch_Flag = tmp == PrimRemovedObject::make ();
			}
		}
		if (crutch_Flag) {
			myIndex += 1;
		} else {
			break;
		}
	}
}


IntegerVar PrimIndexTableStepper::value (){
	if (myIndex < myPtrs->count()) {
		return myIndices->integerVarAt(myIndex);
	} else {
		BLAST(EmptyStepper);
		return NULL;
	}
}
/* protected: create */


PrimIndexTableStepper::PrimIndexTableStepper (
		APTR(PtrArray) from, 
		APTR(IntegerVarArray) to, 
		Int32 index) 
{
	WPTR(Heaper) tmp;
	
	myPtrs = from;
	myIndices = to;
	myIndex = index;
	for (;;) {	BooleanVar crutch_Flag;
		/* myIndex < myPtrs->count() && ((tmp = myPtrs->fetch(myIndex)) == NULL || tmp == PrimRemovedObject::make ()) */
		
		crutch_Flag = myIndex < myPtrs->count();
		if(crutch_Flag) {
			crutch_Flag = (tmp = myPtrs->fetch(myIndex)) == NULL;
			if(!crutch_Flag) {
				crutch_Flag = tmp == PrimRemovedObject::make ();
			}
		}
		if (crutch_Flag) {
			myIndex += 1;
		} else {
			break;
		}
	}
}
/* create */


RPTR(Stepper) PrimIndexTableStepper::copy (){
	RETURN_CONSTRUCT(PrimIndexTableStepper,(myPtrs, myIndices, myIndex));
}



/* ************************************************************************ *
 * 
 *                    Class PrimPtr2PtrTable 
 *
 * ************************************************************************ */


/* create */


RPTR(PrimPtr2PtrTable) PrimPtr2PtrTable::make (Int32 size){
	RETURN_CONSTRUCT(PrimPtr2PtrTable,(size, tcsj));
}
/* Map wimpy pointers to strong ptrs */


/* enumerating */


RPTR(PrimPtr2PtrTableStepper) PrimPtr2PtrTable::stepper (){
	RETURN_CONSTRUCT(PrimPtr2PtrTableStepper,(myFromPtrs, myToPtrs, Int32Zero));
}
/* accessing */


void PrimPtr2PtrTable::introduce (APTR(Heaper) key, APTR(Heaper) value){
	Int32 loc;
	WPTR(Heaper) tmp;
	
	loc = this->hashFind(key);
	{	BooleanVar crutch_Flag;
		/* (tmp = myToPtrs->fetch(loc)) != NULL && tmp != PrimRemovedObject::make () */
		
		crutch_Flag = (tmp = myToPtrs->fetch(loc)) != NULL;
		if(crutch_Flag) {
			crutch_Flag = tmp != PrimRemovedObject::make ();
		}
		if (crutch_Flag) {
			BLAST(AlreadyInTable);
		}
	}
	myToPtrs->store(loc, value);
	myFromPtrs->store(loc, key);
	myTally += 1;
	if (myTally > 2 * myFromPtrs->count() / 3) {
		this->grow();
	}
}


void PrimPtr2PtrTable::store (APTR(Heaper) key, APTR(Heaper) value){
	Int32 loc;
	
	loc = this->hashFind(key);
	if (myToPtrs->fetch(loc) == NULL) {
		myTally += 1;
	}
	myToPtrs->store(loc, value);
	myFromPtrs->store(loc, key);
	if (myTally > 2 * myFromPtrs->count() / 3) {
		this->grow();
	}
}


RPTR(Heaper) PrimPtr2PtrTable::fetch (APTR(Heaper) key){
	WPTR(Heaper) tmp;
	
	tmp = myToPtrs->fetch(this->hashFind(key));
	if (tmp == PrimRemovedObject::make ()) {
		return NULL;
	} else {
		WPTR(Heaper) 	returnValue;
		returnValue = tmp;
		return returnValue;
	}
}


RPTR(Heaper) PrimPtr2PtrTable::get (APTR(Heaper) ptr){
	SPTR(Heaper) result;
	
	{	BooleanVar crutch_Flag;
		/* (result = myToPtrs->fetch(this->hashFind(ptr))) == NULL || (Heaper * ) result == (Heaper * ) PrimRemovedObject::make () */
		
		crutch_Flag = (result = myToPtrs->fetch(this->hashFind(ptr))) == NULL;
		if(!crutch_Flag) {
			crutch_Flag = (Heaper * ) result == (Heaper * ) PrimRemovedObject::make ();
		}
		if (crutch_Flag) {
			BLAST(NotInTable);
		}
	}
	WPTR(Heaper) 	returnValue;
	returnValue = result;
	return returnValue;
}


void PrimPtr2PtrTable::remove (APTR(Heaper) key){
	Int32 loc;
	
	loc = this->hashFind(key);
	if (myToPtrs->fetch(loc) == NULL) {
		BLAST(NotInTable);
	}
	myToPtrs->store(loc, PrimRemovedObject::make ());
	myTally -= 1;
}
/* protected: destruct */


void PrimPtr2PtrTable::destruct (){
	{myFromPtrs->destroy();  myFromPtrs = NULL /* don't want stale (S/CHK)PTRs */;}
	{myToPtrs->destroy();  myToPtrs = NULL /* don't want stale (S/CHK)PTRs */;}
	this->Heaper::destruct();
}
/* protected: create */


PrimPtr2PtrTable::PrimPtr2PtrTable (Int32 size, TCSJ) {
	myFromPtrs = WeakPtrArray::make (XnExecutor::noopExecutor(), size);
	myToPtrs = PtrArray::nulls(size);
	myTally = Int32Zero;
}
/* private: */


void PrimPtr2PtrTable::grow (){
	SPTR(PtrArray) oldFromPtrs;
	SPTR(PtrArray) oldToPtrs;
	WPTR(Heaper) tmp;
	WPTR(Heaper) removed;
	
	oldFromPtrs = myFromPtrs;
	oldToPtrs = myToPtrs;
	myFromPtrs = WeakPtrArray::make (XnExecutor::noopExecutor(), 5 * myFromPtrs->count() / 3);
	myToPtrs = PtrArray::nulls(myFromPtrs->count());
	removed = PrimRemovedObject::make ();
	{
		Int32 LoopFinal = oldFromPtrs->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				Int32 loc;
				
				{	BooleanVar crutch_Flag;
					/* (tmp = oldToPtrs->fetch(i)) != NULL && tmp != removed */
					
					crutch_Flag = (tmp = oldToPtrs->fetch(i)) != NULL;
					if(crutch_Flag) {
						crutch_Flag = tmp != removed;
					}
					if (crutch_Flag) {
						loc = this->hashFind(oldFromPtrs->fetch(i));
						myFromPtrs->store(loc, oldFromPtrs->fetch(i));
						myToPtrs->store(loc, oldToPtrs->fetch(i));
					}
				}
			}
			i += 1;
		}
	}
	{oldFromPtrs->destroy();  oldFromPtrs = NULL /* don't want stale (S/CHK)PTRs */;}
	{oldToPtrs->destroy();  oldToPtrs = NULL /* don't want stale (S/CHK)PTRs */;}
}


Int32 PrimPtr2PtrTable::hashFind (APTR(Heaper) key){
	Int32 loc;
	Int32 firstRemoved;
	WPTR(Heaper) tmp;
	WPTR(Heaper) removed;
	BooleanVar looped;
	
	firstRemoved = -1;
	loc = key->hashForEqual();
	loc = ::fastHash(loc) % myFromPtrs->count();
	removed = PrimRemovedObject::make ();
	looped = FALSE;
	while ((tmp = myToPtrs->fetch(loc)) != NULL) {
		if ((Heaper * ) myFromPtrs->fetch(loc) == key) {
			return loc;
		}
		if (tmp == removed) {
			if (firstRemoved == -1) {
				firstRemoved = loc;
			}
		}
		loc += 1;
		if (loc >= myFromPtrs->count()) {
			if (looped) {
				return firstRemoved;
			} else {
				looped = TRUE;
			}
			loc = Int32Zero;
		}
	}
	if (firstRemoved != -1) {
		return firstRemoved;
	} else {
		return loc;
	}
}
/* testing */


UInt32 PrimPtr2PtrTable::actualHashForEqual (){
	return Heaper::takeOop();
}



/* ************************************************************************ *
 * 
 *                    Class PrimPtr2PtrTableStepper 
 *
 * ************************************************************************ */


/* create */


RPTR(Stepper) PrimPtr2PtrTableStepper::copy (){
	RETURN_CONSTRUCT(PrimPtr2PtrTableStepper,(myFromPtrs, myToPtrs, myIndex));
}
/* accessing */


WPTR(Heaper) PrimPtr2PtrTableStepper::fetch (){
	if (myIndex < myToPtrs->count()) {
		WPTR(Heaper) 	returnValue;
		returnValue = myToPtrs->fetch(myIndex);
		return returnValue;
	} else {
		return NULL;
	}
}


BooleanVar PrimPtr2PtrTableStepper::hasValue (){
	return myIndex < myToPtrs->count();
}


RPTR(Heaper) PrimPtr2PtrTableStepper::heaperKey (){
	if (myIndex < myFromPtrs->count()) {
		WPTR(Heaper) 	returnValue;
		returnValue = myFromPtrs->fetch(myIndex);
		return returnValue;
	} else {
		return NULL;
	}
}


void PrimPtr2PtrTableStepper::step (){
	WPTR(Heaper) tmp;
	
	myIndex += 1;
	for (;;) {	BooleanVar crutch_Flag;
		/* myIndex < myToPtrs->count() && ((tmp = myToPtrs->fetch(myIndex)) == NULL || tmp == PrimRemovedObject::make ()) */
		
		crutch_Flag = myIndex < myToPtrs->count();
		if(crutch_Flag) {
			crutch_Flag = (tmp = myToPtrs->fetch(myIndex)) == NULL;
			if(!crutch_Flag) {
				crutch_Flag = tmp == PrimRemovedObject::make ();
			}
		}
		if (crutch_Flag) {
			myIndex += 1;
		} else {
			break;
		}
	}
}
/* protected: create */


PrimPtr2PtrTableStepper::PrimPtr2PtrTableStepper (
		APTR(PtrArray) from, 
		APTR(PtrArray) to, 
		Int32 index) 
{
	WPTR(Heaper) tmp;
	
	myFromPtrs = from;
	myToPtrs = to;
	myIndex = index;
	for (;;) {	BooleanVar crutch_Flag;
		/* myIndex < myToPtrs->count() && ((tmp = myToPtrs->fetch(myIndex)) == NULL || tmp == PrimRemovedObject::make ()) */
		
		crutch_Flag = myIndex < myToPtrs->count();
		if(crutch_Flag) {
			crutch_Flag = (tmp = myToPtrs->fetch(myIndex)) == NULL;
			if(!crutch_Flag) {
				crutch_Flag = tmp == PrimRemovedObject::make ();
			}
		}
		if (crutch_Flag) {
			myIndex += 1;
		} else {
			break;
		}
	}
}



/* ************************************************************************ *
 * 
 *                    Class PrimPtrTable 
 *
 * ************************************************************************ */


/* create */


RPTR(PrimPtrTable) PrimPtrTable::make (Int32 size){
	RETURN_CONSTRUCT(PrimPtrTable,(size, tcsj));
}


RPTR(PrimPtrTable) PrimPtrTable::weak (Int32 size, APTR(XnExecutor) executor/* = NULL*/){
	RETURN_CONSTRUCT(PrimPtrTable,(size, executor));
}
/* Map integers to strong or weak pointers */


/* accessing */


void PrimPtrTable::introduce (IntegerVar index, APTR(Heaper) ptr){
	Int32 loc;
	WPTR(Heaper) tmp;
	
	loc = this->hashFind(index);
	{	BooleanVar crutch_Flag;
		/* (tmp = myPtrs->fetch(loc)) != NULL && tmp != PrimRemovedObject::make () */
		
		crutch_Flag = (tmp = myPtrs->fetch(loc)) != NULL;
		if(crutch_Flag) {
			crutch_Flag = tmp != PrimRemovedObject::make ();
		}
		if (crutch_Flag) {
			BLAST(AlreadyInTable);
		}
	}
	myIndices->storeIntegerVar(loc, index);
	myPtrs->store(loc, ptr);
	myTally += 1;
	if (myTally > 2 * myPtrs->count() / 3) {
		this->grow();
	}
}


void PrimPtrTable::store (IntegerVar index, APTR(Heaper) ptr){
	Int32 loc;
	WPTR(Heaper) tmp;
	
	loc = this->hashFind(index);
	{	BooleanVar crutch_Flag;
		/* (tmp = myPtrs->fetch(loc)) != NULL && tmp != PrimRemovedObject::make () */
		
		crutch_Flag = (tmp = myPtrs->fetch(loc)) != NULL;
		if(crutch_Flag) {
			crutch_Flag = tmp != PrimRemovedObject::make ();
		}
		if (!crutch_Flag) {
			myTally += 1;
		}
	}
	myIndices->storeIntegerVar(loc, index);
	myPtrs->store(loc, ptr);
	if (myTally > 2 * myPtrs->count() / 3) {
		this->grow();
	}
}


void PrimPtrTable::clearAll (){
	/* Clear all entries from the table. I know this looks like a 
	hack, but the 
		alternative is to throw away the table and build a new one: 
	an expensive 
		prospect for comm. */
	
	myPtrs->storeAll();
	myTally = Int32Zero;
}


RPTR(Heaper) OR(NULL) PrimPtrTable::fetch (IntegerVar index){
	Int32 loc;
	WPTR(Heaper) tmp;
	
	loc = this->hashFind(index);
	tmp = myPtrs->fetch(loc);
	{	BooleanVar crutch_Flag;
		/* tmp == NULL || tmp == PrimRemovedObject::make () */
		
		crutch_Flag = tmp == NULL;
		if(!crutch_Flag) {
			crutch_Flag = tmp == PrimRemovedObject::make ();
		}
		if (crutch_Flag) {
			return NULL;
		}
	}
	WPTR(Heaper) OR(NULL) 	returnValue;
	returnValue = tmp;
	return returnValue;
}


RPTR(Heaper) PrimPtrTable::get (IntegerVar index){
	Int32 loc;
	WPTR(Heaper) tmp;
	
	loc = this->hashFind(index);
	tmp = myPtrs->fetch(loc);
	{	BooleanVar crutch_Flag;
		/* tmp == NULL || tmp == PrimRemovedObject::make () */
		
		crutch_Flag = tmp == NULL;
		if(!crutch_Flag) {
			crutch_Flag = tmp == PrimRemovedObject::make ();
		}
		if (crutch_Flag) {
			BLAST(NotInTable);
		}
	}
	WPTR(Heaper) 	returnValue;
	returnValue = tmp;
	return returnValue;
}


void PrimPtrTable::remove (IntegerVar index){
	Int32 loc;
	
	loc = this->hashFind(index);
	{	BooleanVar crutch_Flag;
		/* myPtrs->fetch(loc) == NULL || myPtrs->fetch(loc) == PrimRemovedObject::make () */
		
		crutch_Flag = myPtrs->fetch(loc) == NULL;
		if(!crutch_Flag) {
			crutch_Flag = myPtrs->fetch(loc) == PrimRemovedObject::make ();
		}
		if (crutch_Flag) {
			BLAST(NotInTable);
		}
	}
	myPtrs->store(loc, PrimRemovedObject::make ());
	myTally -= 1;
}


void PrimPtrTable::wipe (IntegerVar index){
	Int32 loc;
	
	loc = this->hashFind(index);
	{	BooleanVar crutch_Flag;
		/* myPtrs->fetch(loc) == NULL || myPtrs->fetch(loc) == PrimRemovedObject::make () */
		
		crutch_Flag = myPtrs->fetch(loc) == NULL;
		if(!crutch_Flag) {
			crutch_Flag = myPtrs->fetch(loc) == PrimRemovedObject::make ();
		}
		if (crutch_Flag) {
			return;
			
		}
	}
	myPtrs->store(loc, PrimRemovedObject::make ());
	myTally -= 1;
}
/* protected: destruct */


void PrimPtrTable::destruct (){
	{myPtrs->destroy();  myPtrs = NULL /* don't want stale (S/CHK)PTRs */;}
	{myIndices->destroy();  myIndices = NULL /* don't want stale (S/CHK)PTRs */;}
	this->Heaper::destruct();
}
/* private: */


void PrimPtrTable::grow (){
	SPTR(PtrArray) oldPtrs;
	SPTR(IntegerVarArray) oldIndices;
	SPTR(IntegerVarArray) newIndices;
	WPTR(Heaper) tmp;
	WPTR(Heaper) removed;
	
	oldPtrs = myPtrs;
	oldIndices = myIndices;
	/* To be GC safe, instance variables are not modified until 
		all allocations are complete. */
	newIndices = IntegerVarArray::zeros(5 * myPtrs->count() / 3);
	if (myExecutor == NULL) {
		myPtrs = PtrArray::nulls(newIndices->count());
	} else {
		myPtrs = WeakPtrArray::make (myExecutor, newIndices->count());
	}
	myIndices = newIndices;
	removed = PrimRemovedObject::make ();
	{
		UInt32 LoopFinal = oldPtrs->count();
		UInt32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				Int32 loc;
				
				{	BooleanVar crutch_Flag;
					/* (tmp = oldPtrs->fetch(i)) != NULL && tmp != removed */
					
					crutch_Flag = (tmp = oldPtrs->fetch(i)) != NULL;
					if(crutch_Flag) {
						crutch_Flag = tmp != removed;
					}
					if (crutch_Flag) {
						loc = this->hashFind(oldIndices->integerVarAt(i));
						myIndices->storeIntegerVar(loc, oldIndices->integerVarAt(i));
						myPtrs->store(loc, oldPtrs->fetch(i));
					}
				}
			}
			i += 1;
		}
	}
	{oldPtrs->destroy();  oldPtrs = NULL /* don't want stale (S/CHK)PTRs */;}
	{oldIndices->destroy();  oldIndices = NULL /* don't want stale (S/CHK)PTRs */;}
}


Int32 PrimPtrTable::hashFind (IntegerVar value){
	Int32 loc = 0;
	Int32 firstRemoved;
	WPTR(Heaper) tmp;
	WPTR(Heaper) removed;
	BooleanVar looped;
	
	firstRemoved = -1;
	if (TRUE ||!(value == NULL)) {//zzz roger  1995
		loc = ::fastHash(value.asLong()) % myPtrs->count();
		removed = PrimRemovedObject::make ();
	}
	looped = FALSE;
	while ((tmp = myPtrs->fetch(loc)) != NULL) {
		if (myIndices->integerVarAt(loc) == value) {
			return loc;
		}
		if (tmp == removed) {
			if (firstRemoved == -1) {
				firstRemoved = loc;
			}
		}
		loc += 1;
		if (loc >= myPtrs->count()) {
			if (looped) {
				return firstRemoved;
			} else {
				looped = TRUE;
			}
			loc = Int32Zero;
		}
	}
	if (firstRemoved != -1) {
		return firstRemoved;
	} else {
		return loc;
	}
}
/* protected: create */


PrimPtrTable::PrimPtrTable (Int32 size, TCSJ) {
	myPtrs = PtrArray::nulls(size);
	myIndices = IntegerVarArray::zeros(size);
	myTally = Int32Zero;
	myExecutor = NULL;
}


PrimPtrTable::PrimPtrTable (Int32 size, APTR(XnExecutor) OR(NULL) executor) {
	/* Create weak array last to be GC safe */
	myIndices = IntegerVarArray::zeros(size);
	myTally = Int32Zero;
	myExecutor = PrimPtrTableExecutor::make (this, executor);
	myPtrs = WeakPtrArray::make (myExecutor, size);
}
/* enumerating */


RPTR(PrimPtrTableStepper) PrimPtrTable::stepper (){
	RETURN_CONSTRUCT(PrimPtrTableStepper,(myIndices, myPtrs, Int32Zero));
}
/* private: weakness */


void PrimPtrTable::weakRemove (Int32 index, APTR(XnExecutor) OR(NULL) follower){
	/* By way of a weird kluge, this passes the index that the 
	item was stored at in this table
		to the follow up executor */
	
	Int32 virtualIndex;
	
	myPtrs->store(index, PrimRemovedObject::make ());
	virtualIndex = myIndices->integerAt(index).asLong();
	myTally -= 1;
	if (follower != NULL) {
		follower->execute(virtualIndex);
	}
}
/* testing */


UInt32 PrimPtrTable::actualHashForEqual (){
	return Heaper::takeOop();
}



/* ************************************************************************ *
 * 
 *                    Class PrimPtrTableStepper 
 *
 * ************************************************************************ */


/* Stepper over map from integers to strong or wimpy pointers */


/* protected: create */


PrimPtrTableStepper::PrimPtrTableStepper (
		APTR(IntegerVarArray) from, 
		APTR(PtrArray) to, 
		Int32 index) 
{
	WPTR(Heaper) tmp;
	
	myIndices = from;
	myPtrs = to;
	myIndex = index;
	for (;;) {	BooleanVar crutch_Flag;
		/* myIndex < myPtrs->count() && ((tmp = myPtrs->fetch(myIndex)) == NULL || tmp == PrimRemovedObject::make ()) */
		
		crutch_Flag = myIndex < myPtrs->count();
		if(crutch_Flag) {
			crutch_Flag = (tmp = myPtrs->fetch(myIndex)) == NULL;
			if(!crutch_Flag) {
				crutch_Flag = tmp == PrimRemovedObject::make ();
			}
		}
		if (crutch_Flag) {
			myIndex += 1;
		} else {
			break;
		}
	}
}
/* accessing */


WPTR(Heaper) PrimPtrTableStepper::fetch (){
	if (myIndex < myPtrs->count()) {
		WPTR(Heaper) 	returnValue;
		returnValue = myPtrs->fetch(myIndex);
		return returnValue;
	} else {
		return NULL;
	}
}


BooleanVar PrimPtrTableStepper::hasValue (){
	return myIndex < myPtrs->count();
}


IntegerVar PrimPtrTableStepper::index (){
	if (myIndex < myIndices->count()) {
		return myIndices->integerVarAt(myIndex);
	}
	BLAST(EmptyStepper);
	/* Hush up the compiler */
	return NULL;
}


void PrimPtrTableStepper::step (){
	WPTR(Heaper) tmp;
	
	myIndex += 1;
	for (;;) {	BooleanVar crutch_Flag;
		/* myIndex < myPtrs->count() && ((tmp = myPtrs->fetch(myIndex)) == NULL || tmp == PrimRemovedObject::make ()) */
		
		crutch_Flag = myIndex < myPtrs->count();
		if(crutch_Flag) {
			crutch_Flag = (tmp = myPtrs->fetch(myIndex)) == NULL;
			if(!crutch_Flag) {
				crutch_Flag = tmp == PrimRemovedObject::make ();
			}
		}
		if (crutch_Flag) {
			myIndex += 1;
		} else {
			break;
		}
	}
}
/* create */


RPTR(Stepper) PrimPtrTableStepper::copy (){
	RETURN_CONSTRUCT(PrimPtrTableStepper,(myIndices, myPtrs, myIndex));
}



/* ************************************************************************ *
 * 
 *                    Class PrimSet 
 *
 * ************************************************************************ */


/* create */


RPTR(PrimSet) PrimSet::make (){
	RETURN_CONSTRUCT(PrimSet,(7, FALSE));
}


RPTR(PrimSet) PrimSet::make (Int32 size){
	RETURN_CONSTRUCT(PrimSet,(size, FALSE));
}


RPTR(PrimSet) PrimSet::weak (){
	RETURN_CONSTRUCT(PrimSet,(7, TRUE));
}


RPTR(PrimSet) PrimSet::weak (Int32 size){
	RETURN_CONSTRUCT(PrimSet,(size, TRUE));
}


RPTR(PrimSet) PrimSet::weak (Int32 size, APTR(XnExecutor) exec){
	RETURN_CONSTRUCT(PrimSet,(size, exec));
}
/* A set of pointers.  May be strong or weak.  If we have a separate 
executor, it is called with the remaining size after removal. */


/* enumerating */


RPTR(Stepper) PrimSet::stepper (){
	WPTR(Stepper) 	returnValue;
	returnValue = PrimSetStepper::make (myPtrs);
	return returnValue;
}
/* adding-removing */


void PrimSet::introduce (APTR(Heaper) value){
	Int32 loc;
	
	loc = this->hashFind(value);
	if (loc == -1) {
		/* Hack !!!! */
		
		this->grow();
		loc = this->hashFind(value);
	}
	if (myPtrs->fetch(loc) == value) {
		BLAST(AlreadyInSet);
	} else {
		myPtrs->store(loc, value);
		myTally += 1;
		if (myTally > 2 * myPtrs->count() / 3) {
			this->grow();
		}
	}
}


void PrimSet::remove (APTR(Heaper) value){
	Int32 loc;
	
	loc = this->hashFind(value);
	if (myPtrs->fetch(loc) != value) {
		BLAST(NotInSet);
	}
	myPtrs->store(loc, PrimRemovedObject::make ());
	myTally -= 1;
}


void PrimSet::store (APTR(Heaper) value){
	Int32 loc;
	
	loc = this->hashFind(value);
	if (loc == -1) {
		/* Hack !!!! */
		
		this->grow();
		loc = this->hashFind(value);
	}
	if (myPtrs->fetch(loc) != value) {
		myPtrs->store(loc, value);
		myTally += 1;
		if (myTally > 2 * myPtrs->count() / 3) {
			this->grow();
		}
	}
}


void PrimSet::wipe (APTR(Heaper) value){
	Int32 loc;
	
	loc = this->hashFind(value);
	if (myPtrs->fetch(loc) == value) {
		myPtrs->store(loc, PrimRemovedObject::make ());
		myTally -= 1;
	}
}


void PrimSet::wipeAll (){
	myPtrs->storeAll();
	myTally = Int32Zero;
}
/* accessing */


BooleanVar PrimSet::hasMember (APTR(Heaper) element){
	WPTR(Heaper) tmp;
	
	tmp = myPtrs->fetch(this->hashFind(element));
	return tmp == element;
}


BooleanVar PrimSet::isEmpty (){
	return myTally == Int32Zero;
}
/* private: */


void PrimSet::grow (){
	SPTR(PtrArray) oldPtrs;
	WPTR(Heaper) removed;
	
	oldPtrs = myPtrs;
	if (myWeakness) {
		myPtrs = WeakPtrArray::make (PrimSetExecutor::make (this), 5 * oldPtrs->count() / 3);
	} else {
		myPtrs = PtrArray::nulls(5 * oldPtrs->count() / 3);
	}
	removed = PrimRemovedObject::make ();
	{
		Int32 LoopFinal = oldPtrs->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				WPTR(Heaper) tmp;
				
				tmp = oldPtrs->fetch(i);
				{	BooleanVar crutch_Flag;
					/* tmp != NULL && tmp != removed */
					
					crutch_Flag = tmp != NULL;
					if(crutch_Flag) {
						crutch_Flag = tmp != removed;
					}
					if (crutch_Flag) {
						Int32 loc;
						
						loc = this->hashFind(tmp);
						myPtrs->store(loc, tmp);
					}
				}
			}
			i += 1;
		}
	}
	{oldPtrs->destroy();  oldPtrs = NULL /* don't want stale (S/CHK)PTRs */;}
}


Int32 PrimSet::hashFind (APTR(Heaper) value){
	Int32 loc;
	Int32 firstRemoved;
	WPTR(Heaper) tmp;
	WPTR(Heaper) removed;
	BooleanVar looped;
	
	firstRemoved = -1;
	loc = value->hashForEqual();
	loc = ::fastHash(loc) % myPtrs->count();
	removed = PrimRemovedObject::make ();
	looped = FALSE;
	while ((tmp = myPtrs->fetch(loc)) != NULL) {
		if (tmp == value) {
			return loc;
		}
		if (tmp == removed) {
			if (firstRemoved == -1) {
				firstRemoved = loc;
			}
		}
		loc += 1;
		if (loc >= myPtrs->count()) {
			if (looped) {
				return firstRemoved;
			} else {
				looped = TRUE;
			}
			loc = Int32Zero;
		}
	}
	if (firstRemoved != -1) {
		return firstRemoved;
	} else {
		return loc;
	}
}
/* protected: create */


PrimSet::PrimSet (Int32 size, APTR(XnExecutor) exec) {
	myWeakness = TRUE;
	myExecutor = exec;
	myPtrs = WeakPtrArray::make (PrimSetExecutor::make (this), size);
	myTally = Int32Zero;
}


PrimSet::PrimSet (Int32 size, BooleanVar weakness) {
	myWeakness = weakness;
	myExecutor = NULL;
	if (weakness) {
		myPtrs = WeakPtrArray::make (PrimSetExecutor::make (this), size);
	} else {
		myPtrs = PtrArray::nulls(size);
	}
	myTally = Int32Zero;
}
/* private: weakness */


void PrimSet::weakRemove (Int32 index){
	myPtrs->store(index, PrimRemovedObject::make ());
	/* NULL will mess up hashFind */
	myTally -= 1;
	if (myExecutor != NULL) {
		myExecutor->execute(myTally);
	}
}
/* testing */


UInt32 PrimSet::actualHashForEqual (){
	return Heaper::takeOop();
}



/* ************************************************************************ *
 * 
 *                    Class PrimPtrTableExecutor 
 *
 * ************************************************************************ */


/* create */


RPTR(PrimPtrTableExecutor) PrimPtrTableExecutor::make (APTR(PrimPtrTable) table, APTR(XnExecutor) OR(NULL) follower){
	RETURN_CONSTRUCT(PrimPtrTableExecutor,(table, follower));
}
/* invoking */


void PrimPtrTableExecutor::execute (Int32 estateIndex){
	myTable->weakRemove(estateIndex, myFollower);
}
/* protected: create */


PrimPtrTableExecutor::PrimPtrTableExecutor (APTR(PrimPtrTable) table, APTR(XnExecutor) OR(NULL) follower) {
	myTable = table;
	myFollower = follower;
}



/* ************************************************************************ *
 * 
 *                    Class PrimRemovedObject 
 *
 * ************************************************************************ */



/* Initializers for PrimRemovedObject */

GPTR(Heaper) PrimRemovedObject::TheRemovedObject = NULL;



BEGIN_INIT_TIME(PrimRemovedObject,initTimeNonInherited) {
	CONSTRUCT(PrimRemovedObject::TheRemovedObject,PrimRemovedObject,());
} END_INIT_TIME(PrimRemovedObject,initTimeNonInherited);



/* Initializers for PrimRemovedObject */






/* accessing */
/* A single instance of this exists as a marker for slots in 
PrimTables where entries have been removed.
This object lives on the GC heap to keep weak arrays happy */



	/* automatic 0-argument constructor */
PrimRemovedObject::PrimRemovedObject() {}



/* ************************************************************************ *
 * 
 *                    Class PrimSetExecutor 
 *
 * ************************************************************************ */


/* pseudoconstructor */


RPTR(PrimSetExecutor) PrimSetExecutor::make (APTR(PrimSet) set){
	RETURN_CONSTRUCT(PrimSetExecutor,(set, tcsj));
}
/* protected: create */


PrimSetExecutor::PrimSetExecutor (APTR(PrimSet) set, TCSJ) {
	mySet = set;
}
/* execution */


void PrimSetExecutor::execute (Int32 estateIndex){
	mySet->weakRemove(estateIndex);
}



/* ************************************************************************ *
 * 
 *                    Class PrimSetStepper 
 *
 * ************************************************************************ */



/* Initializers for PrimSetStepper */

GPTR(InstanceCache) PrimSetStepper::SomeSteppers = NULL;



BEGIN_INIT_TIME(PrimSetStepper,initTimeNonInherited) {
	PrimSetStepper::SomeSteppers = InstanceCache::make (8);
} END_INIT_TIME(PrimSetStepper,initTimeNonInherited);



/* Initializers for PrimSetStepper */






/* create */


RPTR(Stepper) PrimSetStepper::make (APTR(PtrArray) ptrs){
	SPTR(Heaper) result;
	
	result = PrimSetStepper::SomeSteppers->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(PrimSetStepper,(ptrs, Int32Zero));
	} else {
		WPTR(Stepper) 	returnValue;
		returnValue = new (result) PrimSetStepper(ptrs, Int32Zero);
		return returnValue;
	}
}
/* create */


RPTR(Stepper) PrimSetStepper::copy (){
	SPTR(Heaper) result;
	
	result = PrimSetStepper::SomeSteppers->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(PrimSetStepper,(myPtrs, Int32Zero));
	} else {
		WPTR(Stepper) 	returnValue;
		returnValue = new (result) PrimSetStepper(myPtrs, Int32Zero);
		return returnValue;
	}
}


PrimSetStepper::PrimSetStepper (APTR(PtrArray) array, Int32 index) {
	WPTR(Heaper) tmp;
	
	myPtrs = array;
	myIndex = index;
	for (;;) {	BooleanVar crutch_Flag;
		/* myIndex < myPtrs->count() && ((tmp = myPtrs->fetch(myIndex)) == NULL || tmp == PrimRemovedObject::make ()) */
		
		crutch_Flag = myIndex < myPtrs->count();
		if(crutch_Flag) {
			crutch_Flag = (tmp = myPtrs->fetch(myIndex)) == NULL;
			if(!crutch_Flag) {
				crutch_Flag = tmp == PrimRemovedObject::make ();
			}
		}
		if (crutch_Flag) {
			myIndex += 1;
		} else {
			break;
		}
	}
}


void PrimSetStepper::destroy (){
	if (!PrimSetStepper::SomeSteppers->store(this)) {
		this->Stepper::destroy();
	}
}
/* accessing */


WPTR(Heaper) PrimSetStepper::fetch (){
	if (myIndex < myPtrs->count()) {
		WPTR(Heaper) 	returnValue;
		returnValue = myPtrs->fetch(myIndex);
		return returnValue;
	} else {
		return NULL;
	}
}


BooleanVar PrimSetStepper::hasValue (){
	return myIndex < myPtrs->count();
}


void PrimSetStepper::step (){
	WPTR(Heaper) tmp;
	
	myIndex += 1;
	for (;;) {	BooleanVar crutch_Flag;
		/* myIndex < myPtrs->count() && ((tmp = myPtrs->fetch(myIndex)) == NULL || tmp == PrimRemovedObject::make ()) */
		
		crutch_Flag = myIndex < myPtrs->count();
		if(crutch_Flag) {
			crutch_Flag = (tmp = myPtrs->fetch(myIndex)) == NULL;
			if(!crutch_Flag) {
				crutch_Flag = tmp == PrimRemovedObject::make ();
			}
		}
		if (crutch_Flag) {
			myIndex += 1;
		} else {
			break;
		}
	}
}
/* printint */


void PrimSetStepper::printOn (ostream& oo){
	BooleanVar printedElem;
	
	oo << "PrimSetStepper on {";
	printedElem = FALSE;
	{
		Int32 LoopFinal = myPtrs->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (myPtrs->fetch(i) != NULL) {
					if (printedElem) {
						oo << ", ";
					}
					oo << myPtrs->fetch(i);
					printedElem = TRUE;
				}
			}
			i += 1;
		}
	}
	oo << "}";
}

#ifndef PRIMTABX_SXX
#include "primtabx.sxx"
#endif /* PRIMTABX_SXX */


#ifndef PRIMTABP_SXX
#include "primtabp.sxx"
#endif /* PRIMTABP_SXX */



#endif /* PRIMTABX_CXX */

