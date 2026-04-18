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

#ifndef HASHTABX_CXX
#define HASHTABX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef HASHTABX_HXX
#include "hashtabx.hxx"
#endif /* HASHTABX_HXX */

#ifndef HASHTABX_IXX
#include "hashtabx.ixx"
#endif /* HASHTABX_IXX */

#ifndef HASHTABP_HXX
#include "hashtabp.hxx"
#endif /* HASHTABP_HXX */

#ifndef HASHTABP_IXX
#include "hashtabp.ixx"
#endif /* HASHTABP_IXX */


#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */

#ifndef TABENTX_HXX
#include "tabentx.hxx"
#endif /* TABENTX_HXX */

#ifndef TABTOOLX_HXX
#include "tabtoolx.hxx"
#endif /* TABTOOLX_HXX */




/* ************************************************************************ *
 * 
 *                    Class HashTable 
 *
 * ************************************************************************ */



/* Initializers for HashTable */


BEGIN_INIT_TIME(HashTable,initTimeNonInherited) {
	REQUIRES (ImmuSet);
	/* for the empty set domain */
	REQUIRES (LPPrimeSizeProvider);
} END_INIT_TIME(HashTable,initTimeNonInherited);



/* Initializers for HashTable */



/* pseudo constructors */


RPTR(HashTable) HashTable::make (APTR(CoordinateSpace) cs, IntegerVar size){
	WPTR(HashTable) 	returnValue;
	returnValue = ActualHashTable::make (cs, size.asLong() | 1);
	return returnValue;
}
/* accessing */
/* testing */
/* enumerating */
/* runs */
/* creation */
/* protected: create */


HashTable::HashTable () {
	
}



/* ************************************************************************ *
 * 
 *                    Class ActualHashTable 
 *
 * ************************************************************************ */


/* creation */


RPTR(HashTable) ActualHashTable::make (APTR(CoordinateSpace) cs){
	RETURN_CONSTRUCT(ActualHashTable,(SharedPtrArray::make (7), Int32Zero, cs));
}


RPTR(HashTable) ActualHashTable::make (APTR(CoordinateSpace) cs, IntegerVar size){
	RETURN_CONSTRUCT(ActualHashTable,(SharedPtrArray::make (LPPrimeSizeProvider::make ()->uInt32PrimeAfter(size.asLong())), Int32Zero, cs));
}
/* The HashTable is an implementation class that is intended to 
provide the weakest Position->Object mapping.  It can map from 
arbitrary Position classes (such as HeaperAsPosition or 
TreePosition).  HashTable can also be used for very sparse integer domains.
	
	HashTable, and the entire hashtab module, is private implementation. 
 Not to be included by clients. */


/* accessing */


RPTR(Heaper) OR(NULL) ActualHashTable::store (APTR(Position) key, APTR(Heaper) aHeaper){
	Int32 offset;
	SPTR(TableEntry) OR(NULL) entry;
	SPTR(TableEntry) OR(NULL) prev;
	
	if (aHeaper == NULL) {
		BLAST(NullInsertion);
	}
	this->aboutToWrite();
	this->checkSize();
	offset = key->hashForEqual() % myHashEntries->count();
	entry = CAST(TableEntry,myHashEntries->fetch(offset));
	prev = NULL;
	while (entry != NULL) {
		if (entry->match(key)) {
			SPTR(Heaper) result;
			
			result = entry->value();
			/* Replace the whole entry object if it 
				cannot be side-effected in place. */
			if (!entry->replaceValue(aHeaper)) {
				SPTR(TableEntry) newEntry;
				
				newEntry = TableEntry::make (key, aHeaper);
				newEntry->setNext(entry->fetchNext());
				if (prev == NULL) {
					myHashEntries->store(offset, newEntry);
				} else {
					prev->setNext(newEntry);
				}
				{entry->destroy();  entry = NULL /* don't want stale (S/CHK)PTRs */;}
			}
			WPTR(Heaper) OR(NULL) 	returnValue;
			returnValue = result;
			return returnValue;
		}
		prev = entry;
		entry = entry->fetchNext();
	}
	entry = TableEntry::make (key, aHeaper);
	entry->setNext(CAST(TableEntry,myHashEntries->fetch(offset)));
	myHashEntries->store(offset, entry);
	myTally += 1;
	return NULL;
}


RPTR(Heaper) OR(NULL) ActualHashTable::atIntStore (IntegerVar key, APTR(Heaper) aHeaper){
	Int32 offset;
	SPTR(TableEntry) OR(NULL) entry;
	SPTR(TableEntry) OR(NULL) prev;
	
	if (aHeaper == NULL) {
		BLAST(NullInsertion);
	}
	this->aboutToWrite();
	this->checkSize();
	offset = IntegerPos::integerHash(key) % myHashEntries->count();
	entry = CAST(TableEntry,myHashEntries->fetch(offset));
	prev = NULL;
	while (entry != NULL) {
		if (entry->matchInt(key)) {
			SPTR(Heaper) result;
			
			result = entry->value();
			/* Replace the whole entry object if it 
				cannot be side-effected in place. */
			if (!entry->replaceValue(aHeaper)) {
				SPTR(TableEntry) newEntry;
				
				newEntry = TableEntry::make (key, aHeaper);
				newEntry->setNext(entry->fetchNext());
				if (prev == NULL) {
					myHashEntries->store(offset, newEntry);
				} else {
					prev->setNext(newEntry);
				}
				{entry->destroy();  entry = NULL /* don't want stale (S/CHK)PTRs */;}
			}
			WPTR(Heaper) OR(NULL) 	returnValue;
			returnValue = result;
			return returnValue;
		}
		prev = entry;
		entry = entry->fetchNext();
	}
	entry = TableEntry::make (key, aHeaper);
	entry->setNext(CAST(TableEntry,myHashEntries->fetch(offset)));
	myHashEntries->store(offset, entry);
	myTally += 1;
	return NULL;
}


RPTR(CoordinateSpace) ActualHashTable::coordinateSpace (){
	return (CoordinateSpace*) myCoordinateSpace;
}


IntegerVar ActualHashTable::count (){
	return IntegerVar(myTally);
}


RPTR(XnRegion) ActualHashTable::domain (){
	SPTR(TableStepper) keys;
	
	keys = this->stepper();
	if (this->coordinateSpace() == IntegerSpace::make ()) {
		SPTR(IntegerRegion) result;
		
		result = IntegerRegion::make ();
		while (keys->hasValue()) {
			result = CAST(IntegerRegion,result->withInt(keys->index()));
			/* This is stupid, I should not need a cast here */
			keys->step();
		}
		{keys->destroy();  keys = NULL /* don't want stale (S/CHK)PTRs */;}
		WPTR(XnRegion) 	returnValue;
		returnValue = result;
		return returnValue;
	} else {
		SPTR(XnRegion) result;
		
		result = this->coordinateSpace()->emptyRegion();
		while (keys->hasValue()) {
			result = result->with(keys->position());
			keys->step();
		}
		{keys->destroy();  keys = NULL /* don't want stale (S/CHK)PTRs */;}
		WPTR(XnRegion) 	returnValue;
		returnValue = result;
		return returnValue;
	}
}


RPTR(Heaper) OR(NULL) ActualHashTable::fetch (APTR(Position) key){
	Int32 offset;
	WPTR(TableEntry) entry;
	
	offset = key->hashForEqual() % myHashEntries->count();
	entry = CAST(TableEntry,myHashEntries->fetch(offset));
	while (entry != NULL) {
		if (entry->match(key)) {
			WPTR(Heaper) OR(NULL) 	returnValue;
			returnValue = entry->value();
			return returnValue;
		}
		entry = entry->fetchNext();
	}
	return NULL;
}


RPTR(Heaper) OR(NULL) ActualHashTable::intFetch (IntegerVar key){
	Int32 offset;
	WPTR(TableEntry) entry;
	
	offset = IntegerPos::integerHash(key) % myHashEntries->count();
	entry = CAST(TableEntry,myHashEntries->fetch(offset));
	while (entry != NULL) {
		if (entry->matchInt(key)) {
			WPTR(Heaper) OR(NULL) 	returnValue;
			returnValue = entry->value();
			return returnValue;
		}
		entry = entry->fetchNext();
	}
	return NULL;
}


RPTR(ScruTable) ActualHashTable::subTable (APTR(XnRegion) region){
	SPTR(HashTable) newTable;
	SPTR(TableStepper) elements;
	
	newTable = HashTable::make (myCoordinateSpace, region->count());
	elements = this->stepper();
	BEGIN_FOR_EACH(Heaper,elemValue,(elements)) {
		if (region->hasMember(elements->position())) {
			newTable->store(elements->position(), elemValue);
		}
	} END_FOR_EACH;
	WPTR(ScruTable) 	returnValue;
	returnValue = newTable;
	return returnValue;
}


BooleanVar ActualHashTable::wipe (APTR(Position) aKey){
	UInt32 offset;
	WPTR(TableEntry) OR(NULL) prev;
	WPTR(TableEntry) OR(NULL) entry;
	
	offset = aKey->hashForEqual() % myHashEntries->count();
	entry = CAST(TableEntry,myHashEntries->fetch(offset));
	prev = NULL;
	while (entry != NULL) {
		if (entry->match(aKey)) {
			this->aboutToWrite();
			if (prev == NULL) {
				myHashEntries->store(offset, entry->fetchNext());
			} else {
				prev->setNext(entry->fetchNext());
			}
			{entry->destroy();  entry = NULL /* don't want stale (S/CHK)PTRs */;}
			myTally -= 1;
			return TRUE;
		}
		prev = entry;
		entry = entry->fetchNext();
	}
	return FALSE;
}
/* testing */


UInt32 ActualHashTable::fastHash (){
	register UInt32 result;
	WPTR(TableEntry) entry;
	
	result = this->getCategory()->hashForEqual() + myTally;
	{
		Int32 LoopFinal = myHashEntries->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				entry = CAST(TableEntry,myHashEntries->fetch(i));
				while (entry != NULL) {
					result += entry->hashForEqual();
					entry = entry->fetchNext();
				}
			}
			i += 1;
		}
	}
	return result;
}


BooleanVar ActualHashTable::includesKey (APTR(Position) aKey){
	return this->fetch(aKey) != NULL;
}


BooleanVar ActualHashTable::isEmpty (){
	return myTally == Int32Zero;
}
/* creation */


RPTR(ScruTable) ActualHashTable::copy (){
	RETURN_CONSTRUCT(ActualHashTable,(myHashEntries, this->count().asLong(), this->coordinateSpace()));
}


RPTR(ScruTable) ActualHashTable::emptySize (IntegerVar size){
	WPTR(ScruTable) 	returnValue;
	returnValue = ActualHashTable::make (myCoordinateSpace, size);
	return returnValue;
}
/* printing */


void ActualHashTable::printOn (ostream& oo){
	oo << this->getCategory()->name();
	this->printOnWithSimpleSyntax(oo, "[", ", ", "]");
}
/* runLength */


RPTR(XnRegion) ActualHashTable::runAt (APTR(Position) index){
	if (this->includesKey(index)) {
		WPTR(XnRegion) 	returnValue;
		returnValue = index->asRegion();
		return returnValue;
	} else {
		WPTR(XnRegion) 	returnValue;
		returnValue = myCoordinateSpace->emptyRegion();
		return returnValue;
	}
}
/* enumerating */


RPTR(TableStepper) ActualHashTable::stepper (APTR(OrderSpec) order/* = NULL*/){
	/* ignore order spec for now */
	
	if (order == NULL) {
		WPTR(TableStepper) 	returnValue;
		returnValue = TableEntry::bucketStepper(myHashEntries);
		return returnValue;
	} else {
		BLAST(NOT_YET_IMPLEMENTED);
	}
	/* fodder */
	return NULL;
}


RPTR(Heaper) ActualHashTable::theOne (){
	WPTR(TableEntry) entry;
	
	if (myTally != 1) {
		BLAST(NotOneElement);
	}
	{
		Int32 LoopFinal = myHashEntries->count();
		Int32 index = Int32Zero;
		for (;;) {
			if (index >= LoopFinal){
				break;
			}
			{
				if ((entry = CAST(TableEntry,myHashEntries->fetch(index))) != NULL) {
					WPTR(Heaper) 	returnValue;
					returnValue = entry->value();
					return returnValue;
				}
			}
			index += 1;
		}
	}
	return NULL;
}
/* hooks: */


void ActualHashTable::receiveHashTable (APTR(Rcvr) rcvr){
	/* This currently doesn't take advantage of the optimizations 
	in TableEntries.  It should. */
	
	myHashEntries = SharedPtrArray::make (myTally / 2 + 1);
	myHashEntries->shareMore();
	if (myCoordinateSpace->isEqual(IntegerSpace::make ())) {
		{
			for (Int32 T_LoopVar = myTally; T_LoopVar > 0; T_LoopVar -= 1) {
				IntegerVar index;
				
				index = rcvr->receiveIntegerVar();
				this->storeEntry(TableEntry::make (index, rcvr->receiveHeaper()));
			}
		}
	} else {
		{
			for (Int32 T_LoopVar = myTally; T_LoopVar > 0; T_LoopVar -= 1) {
				SPTR(Position) key;
				
				key = CAST(Position,rcvr->receiveHeaper());
				this->storeEntry(TableEntry::make (key, rcvr->receiveHeaper()));
			}
		}
	}
}


void ActualHashTable::sendHashTable (APTR(Xmtr) xmtr){
	/* This currently doesn't take advantage of the optimizations 
	in TableEntries.  It should. */
	
	if (myCoordinateSpace->isEqual(IntegerSpace::make ())) {
		BEGIN_FOR_INDICES(index,Heaper,value,(this->stepper())) {
			xmtr->sendIntegerVar(index);
			xmtr->sendHeaper(value);
		} END_FOR_INDICES;
	} else {
		BEGIN_FOR_POSITIONS(Position,p,Heaper,v,(this->stepper())) {
			xmtr->sendHeaper(p);
			xmtr->sendHeaper(v);
		} END_FOR_POSITIONS;
	}
}
/* protected: */


ActualHashTable::ActualHashTable (
		APTR(SharedPtrArray) OF1(TableEntry) entries, 
		Int32 tally, 
		APTR(CoordinateSpace) cs) 
{
	myHashEntries = entries;
	myTally = tally;
	myCoordinateSpace = cs;
	myHashEntries->shareMore();
}


void ActualHashTable::destruct (){
	myHashEntries->shareLess();
	this->HashTable::destruct();
}
/* private: */


void ActualHashTable::aboutToWrite (){
	/* If my contents are shared, and I'm about to change them, 
	make a copy of them. */
	
	if (myHashEntries->shareCount() > 1) {
		SPTR(SharedPtrArray) OF1(TableEntry) newEntries;
		Int32 entryCount;
		
		entryCount = myHashEntries->count();
		newEntries = SharedPtrArray::make (entryCount);
		{
			Int32 LoopFinal = entryCount;
			Int32 index = Int32Zero;
			for (;;) {
				if (index >= LoopFinal){
					break;
				}
				{
					WPTR(TableEntry) entry;
					
					if ((entry = CAST(TableEntry,myHashEntries->fetch(index))) != NULL) {
						SPTR(TableEntry) newEntry;
						
						newEntry = entry->copy();
						newEntries->store(index, newEntry);
						entry = entry->fetchNext();
						while (entry != NULL) {
							newEntry->setNext(entry->copy());
							newEntry = newEntry->fetchNext();
							entry = entry->fetchNext();
						}
					}
				}
				index += 1;
			}
		}
		myHashEntries->shareLess();
		myHashEntries = newEntries;
		myHashEntries->shareMore();
	}
}


void ActualHashTable::checkSize (){
	SPTR(SharedPtrArray) oldEntries;
	Int32 oldSize;
	Int32 newSize;
	
	if (myTally > myHashEntries->count() * 2) {
		oldSize = myHashEntries->count();
		newSize = LPPrimeSizeProvider::make ()->uInt32PrimeAfter(oldSize * 4);
		myHashEntries->shareLess();
		oldEntries = myHashEntries;
		myHashEntries = SharedPtrArray::make (newSize);
		myHashEntries->shareMore();
		{
			Int32 LoopFinal = oldSize;
			Int32 j = Int32Zero;
			for (;;) {
				if (j >= LoopFinal){
					break;
				}
				{
					SPTR(TableEntry) cur;
					SPTR(TableEntry) next;
					
					cur = CAST(TableEntry,oldEntries->fetch(j));
					while (cur != NULL) {
						next = cur->fetchNext();
						this->storeEntry(cur);
						cur = next;
					}
				}
				j += 1;
			}
		}
		{oldEntries->destroy();  oldEntries = NULL /* don't want stale (S/CHK)PTRs */;}
	}
}


void ActualHashTable::storeEntry (APTR(TableEntry) anEntry){
	/* Store the tableentry into the entry table */
	
	UInt32 index;
	
	index = anEntry->position()->hashForEqual() % myHashEntries->count();
	anEntry->setNext(CAST(TableEntry,myHashEntries->fetch(index)));
	myHashEntries->store(index, anEntry);
}

#ifndef HASHTABX_SXX
#include "hashtabx.sxx"
#endif /* HASHTABX_SXX */


#ifndef HASHTABP_SXX
#include "hashtabp.sxx"
#endif /* HASHTABP_SXX */



#endif /* HASHTABX_CXX */

