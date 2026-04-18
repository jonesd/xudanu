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

#ifndef INTTABX_CXX
#define INTTABX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef INTTABX_HXX
#include "inttabx.hxx"
#endif /* INTTABX_HXX */

#ifndef INTTABX_IXX
#include "inttabx.ixx"
#endif /* INTTABX_IXX */

#ifndef INTTABR_HXX
#include "inttabr.hxx"
#endif /* INTTABR_HXX */

#ifndef INTTABR_IXX
#include "inttabr.ixx"
#endif /* INTTABR_IXX */

#ifndef INTTABP_HXX
#include "inttabp.hxx"
#endif /* INTTABP_HXX */

#ifndef INTTABP_IXX
#include "inttabp.ixx"
#endif /* INTTABP_IXX */


#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */




/* ************************************************************************ *
 * 
 *                    Class IntegerTable 
 *
 * ************************************************************************ */


/* pseudoConstructors */


RPTR(IntegerTable) IntegerTable::make (){
	/* A new empty IntegerTable */
	
	RETURN_CONSTRUCT(ActualIntegerTable,());
}


RPTR(IntegerTable) IntegerTable::make (IntegerVar someSize){
	/* A new empty IntegerTable. 'someSize' is a hint about how 
	big the table is likely 
		to need to be ('highestIndex - lowestIndex + 1', not 'count'). */
	
	RETURN_CONSTRUCT(ActualIntegerTable,(someSize, tcsj));
}


RPTR(IntegerTable) IntegerTable::make (IntegerVar fromIdx, IntegerVar toIdx){
	/* Hint that the domain's lowerBound (inclusive) will 
	eventually be 'fromIdx', and 
		the domain's upperBound (exclusive) will eventually be 'toIdx'. */
	
	RETURN_CONSTRUCT(ActualIntegerTable,(fromIdx, toIdx));
}


RPTR(IntegerTable) IntegerTable::make (APTR(IntegerRegion) reg){
	/* Hint that the domain of the new table will eventually be 
	(or at least resemble) 
		'reg'. */
	
	RETURN_CONSTRUCT(ActualIntegerTable,(reg->start(), reg->stop()));
}
/* The IntegerTable class is used for tables that have arbitrary 
XuInteger keys in their domain.  Since ScruTable & MuTable already 
provide all the unboxed versions of the table protocol, there is 
little need for this class to be a type.  However, this class does 
provide a bit of extra protocol convenience: highestIndex & 
lowestIndex. Unless these are retired, we cannot retire this class 
from type status.
	
	Note that there may be tables with XuInteger keys (i.e., 
IntegerSpace domains) which are not kinds of IntegerTables.  In 
particular it is perfectly sensible to create a HashTable with 
XuInteger keys when the domain region is likely to be sparse. */


/* accessing */


void IntegerTable::atIntIntroduce (IntegerVar key, APTR(Heaper) value){
	SPTR(Heaper) old;
	
	if ((old = this->atIntStore(key, value)) != NULL) {
		this->atIntStore(key, old);
		/* restore prior condition */
		BLAST(AlreadyInTable);
	}
}


void IntegerTable::atIntReplace (IntegerVar key, APTR(Heaper) value){
	if (this->atIntStore(key, value) == NULL) {
		this->intWipe(key);
		/* restore prior condition */
		BLAST(NotInTable);
	}
}


RPTR(CoordinateSpace) IntegerTable::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = IntegerSpace::make ();
	return returnValue;
}


void IntegerTable::intRemove (IntegerVar anIdx){
	if (!this->intWipe(anIdx)) {
		BLAST(NotInTable);
	}
}
/* accessing overloads */


void IntegerTable::introduce (APTR(Position) key, APTR(Heaper) value){
	this->atIntIntroduce(CAST(IntegerPos,key)->asIntegerVar(), value);
}


void IntegerTable::replace (APTR(Position) key, APTR(Heaper) value){
	this->atIntReplace(CAST(IntegerPos,key)->asIntegerVar(), value);
}


RPTR(Heaper) IntegerTable::store (APTR(Position) key, APTR(Heaper) value){
	WPTR(Heaper) 	returnValue;
	returnValue = this->atIntStore(CAST(IntegerPos,key)->asIntegerVar(), value);
	return returnValue;
}


RPTR(Heaper) IntegerTable::fetch (APTR(Position) key){
	WPTR(Heaper) 	returnValue;
	returnValue = this->intFetch(CAST(IntegerPos,key)->asIntegerVar());
	return returnValue;
}


BooleanVar IntegerTable::includesKey (APTR(Position) aKey){
	return this->includesIntKey(CAST(IntegerPos,aKey)->asIntegerVar());
}


void IntegerTable::remove (APTR(Position) aPos){
	this->intRemove(CAST(IntegerPos,aPos)->asIntegerVar());
}


RPTR(XnRegion) IntegerTable::runAt (APTR(Position) key){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->runAtInt(CAST(IntegerPos,key)->asIntegerVar());
	return returnValue;
}


BooleanVar IntegerTable::wipe (APTR(Position) anIdx){
	return this->intWipe(CAST(IntegerPos,anIdx)->asIntegerVar());
}
/* testing */
/* enumerating */
/* runs */
/* creation */


IntegerTable::IntegerTable () {
	/* Create a new table with an unspecified number of initial 
	domain positions. */
	
	
}



/* ************************************************************************ *
 * 
 *                    Class IntegerTableStepper 
 *
 * ************************************************************************ */


/* pseudoConstructors */


RPTR(IntegerTableStepper) IntegerTableStepper::make (APTR(IntegerTable) aTable, APTR(OrderSpec) anOrder/* = NULL*/){
	/* Do not consider public.  Only for use by the modules 
	inttab, array, and awarray. */
	
	BEGIN_CHOOSE(aTable) {
		BEGIN_KIND(ActualIntegerTable,tab) {
			if (anOrder->followsInt(1, IntegerVar0)) {
				RETURN_CONSTRUCT(ITAscendingStepper,(tab, tcsj));
			} else {
				RETURN_CONSTRUCT(ITDescendingStepper,(tab, tcsj));
			}
		} END_KIND;
		BEGIN_OTHERS {
			if (anOrder == NULL) {
				RETURN_CONSTRUCT(ITGenericStepper,(aTable, tcsj));
			} else {
				RETURN_CONSTRUCT(ITGenericStepper,(aTable, anOrder));
			}
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return NULL;
}


RPTR(IntegerTableStepper) IntegerTableStepper::make (
		APTR(IntegerTable) aTable, 
		IntegerVar start, 
		IntegerVar stop)
{
	/* Do not consider public.  Only for use by the modules 
	inttab, array, and awarray. */
	
	BEGIN_CHOOSE(aTable) {
		BEGIN_KIND(ActualIntegerTable,tab) {
			RETURN_CONSTRUCT(ITAscendingStepper,(tab, start, stop));
		} END_KIND;
		BEGIN_OTHERS {
			RETURN_CONSTRUCT(ITGenericStepper,(aTable, start, stop, 1));
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return NULL;
}
/* Consider this a protected class.  It is public only for use by the 
"array" module. */


/* operations */


WPTR(Heaper) IntegerTableStepper::get (){
	WPTR(Heaper) res;
	
	res = this->fetch();
	if (res == NULL) {
		BLAST(EmptyStepper);
	}
	WPTR(Heaper) 	returnValue;
	returnValue = res;
	return returnValue;
}
/* special */
/* create */

	/* automatic 0-argument constructor */
IntegerTableStepper::IntegerTableStepper() {}



/* ************************************************************************ *
 * 
 *                    Class ITAscendingStepper 
 *
 * ************************************************************************ */


/* operations */


WPTR(Heaper) ITAscendingStepper::fetch (){
	if (indexInternal <= lastValueInternal) {
		WPTR(Heaper) 	returnValue;
		returnValue = arrayInternal->elementsArray()->fetch(indexInternal);
		return returnValue;
	} else {
		return NULL;
	}
}


BooleanVar ITAscendingStepper::hasValue (){
	return indexInternal <= lastValueInternal;
}


void ITAscendingStepper::step (){
	indexInternal += 1;
	for (;;) {	BooleanVar crutch_Flag;
		/* indexInternal <= lastValueInternal && arrayInternal->elementsArray()->fetch(indexInternal) == NULL */
		
		crutch_Flag = indexInternal <= lastValueInternal;
		if(crutch_Flag) {
			crutch_Flag = arrayInternal->elementsArray()->fetch(indexInternal) == NULL;
		}
		if (crutch_Flag) {
			indexInternal += 1;
		} else {
			break;
		}
	}
}
/* create */


RPTR(Stepper) ITAscendingStepper::copy (){
	RETURN_CONSTRUCT(ITAscendingStepper,(CAST(OberIntegerTable,arrayInternal->copy()), this->index(), arrayInternal->startIndex() + lastValueInternal));
}


ITAscendingStepper::ITAscendingStepper (APTR(OberIntegerTable) array, TCSJ) {
	arrayInternal = CAST(OberIntegerTable,array->copy());
	indexInternal = arrayInternal->startOffset();
	lastValueInternal = arrayInternal->endOffset();
	this->verifyEntry();
}


ITAscendingStepper::ITAscendingStepper (APTR(OberIntegerTable) array, IntegerVar index) {
	arrayInternal = CAST(OberIntegerTable,array->copy());
	indexInternal = (index - arrayInternal->startIndex()).asLong();
	lastValueInternal = arrayInternal->endOffset();
	this->verifyEntry();
}


ITAscendingStepper::ITAscendingStepper (
		APTR(OberIntegerTable) array, 
		IntegerVar start, 
		IntegerVar stop) 
{
	/* n.b. !!!! This constructor DOES NOT COPY the table because this 
		constructor is used by the table copy (which creates a stepper). 
		The copy is done in the table->stepper(NULL) routine before calling 
		this constructor. */
	
	arrayInternal = array;
	indexInternal = (start - arrayInternal->startIndex()).asLong();
	lastValueInternal = (stop - arrayInternal->startIndex()).asLong();
	this->verifyEntry();
}
/* special */


IntegerVar ITAscendingStepper::index (){
	return arrayInternal->startIndex() + indexInternal;
}


RPTR(Position) ITAscendingStepper::position (){
	WPTR(Position) 	returnValue;
	returnValue = IntegerPos::make (this->index());
	return returnValue;
}
/* private: private */


void ITAscendingStepper::verifyEntry (){
	for (;;) {	BooleanVar crutch_Flag;
		/* indexInternal <= lastValueInternal && arrayInternal->elementsArray()->fetch(indexInternal) == NULL */
		
		crutch_Flag = indexInternal <= lastValueInternal;
		if(crutch_Flag) {
			crutch_Flag = arrayInternal->elementsArray()->fetch(indexInternal) == NULL;
		}
		if (crutch_Flag) {
			indexInternal += 1;
		} else {
			break;
		}
	}
}



/* ************************************************************************ *
 * 
 *                    Class ITDescendingStepper 
 *
 * ************************************************************************ */


/* create */


RPTR(Stepper) ITDescendingStepper::copy (){
	RETURN_CONSTRUCT(ITDescendingStepper,(CAST(ActualIntegerTable,arrayInternal->copy()), this->index(), arrayInternal->startIndex() + lastValueInternal));
}


ITDescendingStepper::ITDescendingStepper (APTR(OberIntegerTable) array, TCSJ) {
	arrayInternal = CAST(OberIntegerTable,array->copy());
	indexInternal = arrayInternal->endOffset();
	lastValueInternal = arrayInternal->startOffset();
	this->verifyEntry();
}


ITDescendingStepper::ITDescendingStepper (APTR(OberIntegerTable) array, IntegerVar index) {
	arrayInternal = CAST(OberIntegerTable,array->copy());
	indexInternal = (index - arrayInternal->startIndex()).asLong();
	lastValueInternal = arrayInternal->startOffset();
	this->verifyEntry();
}


ITDescendingStepper::ITDescendingStepper (
		APTR(OberIntegerTable) array, 
		IntegerVar start, 
		IntegerVar stop) 
{
	arrayInternal = CAST(OberIntegerTable,array->copy());
	indexInternal = (start - arrayInternal->startIndex()).asLong();
	lastValueInternal = (stop - arrayInternal->startIndex()).asLong();
	this->verifyEntry();
}
/* operations */


WPTR(Heaper) ITDescendingStepper::fetch (){
	if (indexInternal >= lastValueInternal) {
		WPTR(Heaper) 	returnValue;
		returnValue = arrayInternal->elementsArray()->fetch(indexInternal);
		return returnValue;
	} else {
		return NULL;
	}
}


BooleanVar ITDescendingStepper::hasValue (){
	return indexInternal >= lastValueInternal;
}


void ITDescendingStepper::step (){
	indexInternal -= 1;
	this->verifyEntry();
}
/* special */


IntegerVar ITDescendingStepper::index (){
	return arrayInternal->startIndex() + indexInternal;
}


RPTR(Position) ITDescendingStepper::position (){
	WPTR(Position) 	returnValue;
	returnValue = IntegerPos::make (this->index());
	return returnValue;
}
/* private: private */


void ITDescendingStepper::verifyEntry (){
	for (;;) {	BooleanVar crutch_Flag;
		/* indexInternal >= lastValueInternal && arrayInternal->elementsArray()->fetch(indexInternal) == NULL */
		
		crutch_Flag = indexInternal >= lastValueInternal;
		if(crutch_Flag) {
			crutch_Flag = arrayInternal->elementsArray()->fetch(indexInternal) == NULL;
		}
		if (crutch_Flag) {
			indexInternal -= 1;
		} else {
			break;
		}
	}
}



/* ************************************************************************ *
 * 
 *                    Class ITGenericStepper 
 *
 * ************************************************************************ */


/* operations */


WPTR(Heaper) ITGenericStepper::fetch (){
	if (this->hasValue()) {
		WPTR(Heaper) 	returnValue;
		returnValue = arrayInternal->intFetch(indexInternal);
		return returnValue;
	} else {
		return NULL;
	}
}


BooleanVar ITGenericStepper::hasValue (){
	{	BooleanVar crutch_Flag;
		/* incrementInternal > Int32Zero && indexInternal <= lastValueInternal || incrementInternal < Int32Zero && indexInternal >= lastValueInternal */
		
		crutch_Flag = incrementInternal > Int32Zero;
		if(crutch_Flag) {
			crutch_Flag = indexInternal <= lastValueInternal;
		}
		if(!crutch_Flag) {
			crutch_Flag = incrementInternal < Int32Zero;
			if(crutch_Flag) {
				crutch_Flag = indexInternal >= lastValueInternal;
			}
		}
		return crutch_Flag;
	}
}


void ITGenericStepper::step (){
	indexInternal += incrementInternal;
	this->verifyEntry();
}
/* special */


IntegerVar ITGenericStepper::index (){
	return indexInternal;
}


RPTR(Position) ITGenericStepper::position (){
	WPTR(Position) 	returnValue;
	returnValue = IntegerPos::make (indexInternal);
	return returnValue;
}
/* create */


RPTR(Stepper) ITGenericStepper::copy (){
	RETURN_CONSTRUCT(ITGenericStepper,(arrayInternal, indexInternal, lastValueInternal, incrementInternal));
}


ITGenericStepper::ITGenericStepper (APTR(IntegerTable) array, TCSJ) {
	arrayInternal = CAST(IntegerTable,array->copy());
	indexInternal = IntegerVar0;
	lastValueInternal = arrayInternal->highestIndex();
	incrementInternal = 1;
}


ITGenericStepper::ITGenericStepper (APTR(IntegerTable) onTable, APTR(OrderSpec) anOrder) {
	/* order is ascending */
		/* order is descending */
	if (anOrder->followsInt(1, IntegerVar0)) {
		arrayInternal = CAST(IntegerTable,onTable->copy());
		indexInternal = onTable->lowestIndex();
		lastValueInternal = onTable->highestIndex();
		incrementInternal = 1;
	} else {
		arrayInternal = CAST(IntegerTable,onTable->copy());
		indexInternal = onTable->highestIndex();
		lastValueInternal = onTable->lowestIndex();
		incrementInternal = -1;
	}
}


ITGenericStepper::ITGenericStepper (APTR(IntegerTable) array, IntegerVar index) {
	arrayInternal = CAST(IntegerTable,array->copy());
	indexInternal = index;
	lastValueInternal = arrayInternal->highestIndex();
	incrementInternal = 1;
}


ITGenericStepper::ITGenericStepper (
		APTR(IntegerTable) array, 
		IntegerVar start, 
		IntegerVar stop) 
{
	arrayInternal = CAST(IntegerTable,array->copy());
	indexInternal = start;
	lastValueInternal = stop;
	incrementInternal = 1;
}


ITGenericStepper::ITGenericStepper (
		APTR(IntegerTable) array, 
		IntegerVar start, 
		IntegerVar stop, 
		IntegerVar direction) 
{
	arrayInternal = CAST(IntegerTable,array->copy());
	indexInternal = start;
	lastValueInternal = stop;
	incrementInternal = direction.asLong();
}
/* private: private */


void ITGenericStepper::verifyEntry (){
	BooleanVar notDone;
	
	notDone = TRUE;
	while (notDone) {
		{	BooleanVar crutch_Flag;
			/* incrementInternal > Int32Zero && indexInternal < lastValueInternal || incrementInternal < Int32Zero && indexInternal >= lastValueInternal */
			
			crutch_Flag = incrementInternal > Int32Zero;
			if(crutch_Flag) {
				crutch_Flag = indexInternal < lastValueInternal;
			}
			if(!crutch_Flag) {
				crutch_Flag = incrementInternal < Int32Zero;
				if(crutch_Flag) {
					crutch_Flag = indexInternal >= lastValueInternal;
				}
			}
			if (crutch_Flag) {
				if (arrayInternal->intFetch(indexInternal) == NULL) {
					indexInternal += incrementInternal;
				} else {
					notDone = FALSE;
				}
			} else {
				notDone = FALSE;
			}
		}
	}
}



/* ************************************************************************ *
 * 
 *                    Class OberIntegerTable 
 *
 * ************************************************************************ */


/* accessing */


RPTR(CoordinateSpace) OberIntegerTable::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = IntegerSpace::make ();
	return returnValue;
}
/* creation */
/* runs */
/* testing */
/* enumerating */
/* private: */
/* protected: create */


OberIntegerTable::OberIntegerTable () {
	myNextCOW = NULL;
}
/* vulnerable: COW stuff */


void OberIntegerTable::aboutToWrite (){
	WPTR(COWIntegerTable) nextCOW;
	
	/* make a copy of myself for all outstanding CopyOnWrites on me.
		pass that copy to each of the CopyOnWrite objects.
		One of the COWs gets to become my clone, and the rest point at it. */
	nextCOW = this->getNextCOW();
	if (nextCOW != NULL) {
		WPTR(COWIntegerTable) cowP;
		
		this->becomeCloneOnWrite(nextCOW);
		cowP = nextCOW->getNextCOW();
		while (cowP != NULL) {
			cowP->setMuTable(nextCOW);
			cowP = cowP->getNextCOW();
		}
		this->setNextCOW(NULL);
	}
}


WPTR(COWIntegerTable) OberIntegerTable::getNextCOW (){
	return (COWIntegerTable*) myNextCOW;
}


void OberIntegerTable::setNextCOW (APTR(COWIntegerTable) table){
	myNextCOW = table;
}
/* overload junk */


RPTR(Heaper) OberIntegerTable::store (APTR(Position) key, APTR(Heaper) value){
	WPTR(Heaper) 	returnValue;
	returnValue = this->atIntStore(CAST(IntegerPos,key)->asIntegerVar(), value);
	return returnValue;
}


RPTR(Heaper) OberIntegerTable::fetch (APTR(Position) key){
	WPTR(Heaper) 	returnValue;
	returnValue = this->intFetch(CAST(IntegerPos,key)->asIntegerVar());
	return returnValue;
}


BooleanVar OberIntegerTable::includesKey (APTR(Position) aKey){
	return this->includesIntKey(CAST(IntegerPos,aKey)->asIntegerVar());
}


RPTR(XnRegion) OberIntegerTable::runAt (APTR(Position) key){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->runAtInt(CAST(IntegerPos,key)->asIntegerVar());
	return returnValue;
}


BooleanVar OberIntegerTable::wipe (APTR(Position) key){
	return this->intWipe(CAST(IntegerPos,key)->asIntegerVar());
}



/* ************************************************************************ *
 * 
 *                    Class   ActualIntegerTable 
 *
 * ************************************************************************ */


/* The IntegerTable class is intended to provide an integer indexed
table which is not constrained to be zero based. */


/* testing */


UInt32 ActualIntegerTable::fastHash (){
	return (start.asLong() ^ firstElem ^ tally ^ lastElem) + cat_ActualIntegerTable->hashForEqual();
}


BooleanVar ActualIntegerTable::includesIntKey (IntegerVar aKey){
	{	BooleanVar crutch_Flag;
		/* aKey < this->lowestIndex() || aKey > this->highestIndex() */
		
		crutch_Flag = aKey < this->lowestIndex();
		if(!crutch_Flag) {
			crutch_Flag = aKey > this->highestIndex();
		}
		if (crutch_Flag) {
			return FALSE;
		} else {
			if (domainIsSimple) {
				return TRUE;
			} else {
				return elements->fetch(aKey.asLong() - start.asLong()) != NULL;
			}
		}
	}
}


BooleanVar ActualIntegerTable::isEmpty (){
	return tally == UInt32Zero;
}
/* accessing */


RPTR(Heaper) ActualIntegerTable::atIntStore (IntegerVar index, APTR(Heaper) value){
	Int32 reali;
	SPTR(Heaper) old;
	
	if (value == NULL) {
		BLAST(NullInsertion);
	}
	if (tally == UInt32Zero) {
		start = index;
	}
	if (index - start >= elemCount) {
		this->enlargeAfter(index);
	} else {
		if (index < start) {
			this->enlargeBefore(index);
		}
	}
	reali = (index - start).asLong();
	if ((old = elements->fetch(reali)) == NULL) {
		tally += 1;
	}
	if (reali < firstElem) {
		if (firstElem - reali > 1) {
			domainIsSimple = FALSE;
		}
		firstElem = reali;
	}
	if (reali > lastElem) {
		if (reali - lastElem > 1) {
			domainIsSimple = FALSE;
		}
		lastElem = reali;
	}
	elements->store(reali, value);
	WPTR(Heaper) 	returnValue;
	returnValue = old;
	return returnValue;
}


RPTR(CoordinateSpace) ActualIntegerTable::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = IntegerSpace::make ();
	return returnValue;
}


IntegerVar ActualIntegerTable::count (){
	return tally;
}


RPTR(XnRegion) ActualIntegerTable::domain (){
	/*  */
	/* The domainIsSimple flag is used as an optimization in this 
	method.  When it is True, I 
		stop looking after the first simple domain I find.  
	Therefore, when True, it MUST BE 
		CORRECT.  When it is False, I do a complete search, and set 
	the flag if the domain
		turns out to be simple. */
	
	SPTR(XnRegion) newReg;
	
	if (this->isEmpty()) {
		WPTR(XnRegion) 	returnValue;
		returnValue = IntegerRegion::make ();
		return returnValue;
	} else {
		if (domainIsSimple) {
			WPTR(XnRegion) 	returnValue;
			returnValue = IntegerRegion::make (this->lowestIndex(), this->highestIndex() + 1);
			return returnValue;
		} else {
			newReg = this->generateDomain();
			if (newReg->isSimple()) {
				domainIsSimple = TRUE;
			}
			WPTR(XnRegion) 	returnValue;
			returnValue = newReg;
			return returnValue;
		}
	}
}


IntegerVar ActualIntegerTable::highestIndex (){
	if (tally == UInt32Zero) {
		return start;
	}
	return start + lastElem;
}


RPTR(Heaper) ActualIntegerTable::intFetch (IntegerVar index){
	UInt32 idx;
	
	{	BooleanVar crutch_Flag;
		/* (idx = (index - start).asLong()) >= elemCount || index < start */
		
		crutch_Flag = (idx = (index - start).asLong()) >= elemCount;
		if(!crutch_Flag) {
			crutch_Flag = index < start;
		}
		if (crutch_Flag) {
			return NULL;
		} else {
			WPTR(Heaper) 	returnValue;
			returnValue = elements->fetch(idx);
			return returnValue;
		}
	}
}


BooleanVar ActualIntegerTable::intWipe (IntegerVar index){
	UInt32 reali;
	BooleanVar wiped;
	
	wiped = FALSE;
	reali = (index - start).asLong();
	{	BooleanVar crutch_Flag;
		/* reali > lastElem || reali < firstElem */
		
		crutch_Flag = reali > lastElem;
		if(!crutch_Flag) {
			crutch_Flag = reali < firstElem;
		}
		if (!crutch_Flag) {
			if (elements->fetch(reali) != NULL) {
				tally -= 1;
				wiped = TRUE;
			}
			elements->store(reali, NULL);
			if (reali == firstElem) {
				firstElem = this->firstElemAfter(reali);
			} else {
				if (reali == lastElem) {
					lastElem = this->lastElemBefore(reali);
				} else {
					domainIsSimple = FALSE;
				}
			}
		}
	}
	return wiped;
}


IntegerVar ActualIntegerTable::lowestIndex (){
	if (tally == UInt32Zero) {
		return start;
	}
	return start + firstElem;
}
/* creation */


RPTR(ScruTable) ActualIntegerTable::copy (){
	RETURN_CONSTRUCT(ActualIntegerTable,(CAST(PtrArray,elements->copy()), start, elemCount, firstElem, lastElem, tally, domainIsSimple));
}


ActualIntegerTable::ActualIntegerTable () {
	/* The optional argument just hints at the number of elements
		 to eventually be added.  It makes no difference semantically. */
	
	elements = PtrArray::nulls(8);
	start = IntegerVar0;
	firstElem = 7;
	lastElem = UInt32Zero;
	elemCount = 8;
	tally = UInt32Zero;
	domainIsSimple = TRUE;
}


ActualIntegerTable::ActualIntegerTable (IntegerVar size, TCSJ) {
	/* The optional argument just hints at the number of elements
		 to eventually be added.  It makes no difference semantically. */
	
	if (size > IntegerVar0) {
		elemCount = size.asLong();
	} else {
		elemCount = 4;
	}
	elements = PtrArray::nulls(elemCount);
	start = IntegerVar0;
	tally = UInt32Zero;
	firstElem = elemCount - 1;
	lastElem = UInt32Zero;
	domainIsSimple = TRUE;
}


ActualIntegerTable::ActualIntegerTable (IntegerVar begin, IntegerVar end) {
	/* Hint at the domain to be accessed (inclusive, exclusive). */
	
	start = begin;
	elemCount = (end - start).asLong();
	if (elemCount < 4) {
		elemCount = 4;
	}
	elements = PtrArray::nulls(elemCount);
	firstElem = elemCount - 1;
	lastElem = UInt32Zero;
	tally = UInt32Zero;
	domainIsSimple = TRUE;
}


ActualIntegerTable::ActualIntegerTable (
		APTR(PtrArray) array, 
		IntegerVar begin, 
		UInt32 count, 
		UInt32 first, 
		UInt32 last, 
		UInt32 aTally, 
		BooleanVar simple) 
{
	elements = array;
	start = begin;
	elemCount = count;
	firstElem = first;
	lastElem = last;
	tally = aTally;
	domainIsSimple = simple;
}


void ActualIntegerTable::destroy (){
	if (this->getNextCOW() == NULL) {
		this->OberIntegerTable::destroy();
	}
}


RPTR(ScruTable) ActualIntegerTable::emptySize (IntegerVar /* size */){
	WPTR(ScruTable) 	returnValue;
	returnValue = IntegerTable::make (this->lowestIndex(), this->highestIndex() + 1);
	return returnValue;
}


RPTR(ScruTable) ActualIntegerTable::offsetSubTableBetween (
		IntegerVar startIndex, 
		IntegerVar stopIndex, 
		IntegerVar firstIndex)
{
	/* Copy the given range into a new IntegerTable. 
		The range is startIndex (inclusive) to stopIndex (exclusive)
		The first element in the sub table will be at firstIndex */
	
	SPTR(IntegerTable) table;
	IntegerVar theEnd;
	
	theEnd = firstIndex + stopIndex - startIndex - 1;
	table = IntegerTable::make (firstIndex, theEnd);
	{
		IntegerVar LoopFinal = theEnd;
		IntegerVar i = firstIndex;
		for (;;) {
			if (i > LoopFinal){
				break;
			}
			{
				WPTR(Heaper) val;
				
				val = this->intFetch(i + startIndex - firstIndex);
				if (!(val == NULL)) {
					table->atIntIntroduce(i, val);
				}
			}
			i += 1;
		}
	}
	WPTR(ScruTable) 	returnValue;
	returnValue = table;
	return returnValue;
}


RPTR(ScruTable) ActualIntegerTable::subTable (APTR(XnRegion) reg){
	SPTR(IntegerRegion) subRegion;
	
	subRegion = CAST(IntegerRegion,reg->intersect(this->domain()->asSimpleRegion()));
	if (subRegion->isEmpty()) {
		WPTR(ScruTable) 	returnValue;
		returnValue = this->emptySize(max(this->count(), 1));
		return returnValue;
	}
	WPTR(ScruTable) 	returnValue;
	returnValue = this->subTableBetween(subRegion->start(), subRegion->stop());
	return returnValue;
}


RPTR(ScruTable) ActualIntegerTable::subTableBetween (IntegerVar startIndex, IntegerVar stopIndex){
	/* Hack for C++ overloading problem */
	
	WPTR(ScruTable) 	returnValue;
	returnValue = this->offsetSubTableBetween(startIndex, stopIndex, startIndex);
	return returnValue;
}
/* runs */


RPTR(XnRegion) ActualIntegerTable::runAtInt (IntegerVar anIdx){
	UInt32 idx;
	SPTR(Heaper) lastObj;
	BooleanVar notDone;
	
	idx = (anIdx - start).asLong();
	if (tally == UInt32Zero) {
		WPTR(XnRegion) 	returnValue;
		returnValue = IntegerRegion::make ();
		return returnValue;
	}
	{	BooleanVar crutch_Flag;
		/* idx < firstElem || idx > lastElem */
		
		crutch_Flag = idx < firstElem;
		if(!crutch_Flag) {
			crutch_Flag = idx > lastElem;
		}
		if (crutch_Flag) {
			WPTR(XnRegion) 	returnValue;
			returnValue = IntegerRegion::make (anIdx, anIdx);
			return returnValue;
		}
	}
	notDone = TRUE;
	if ((lastObj = elements->fetch(idx)) == NULL) {
		for (;;) {	BooleanVar crutch_Flag;
			/* idx <= lastElem && notDone */
			
			crutch_Flag = idx <= lastElem;
			if(crutch_Flag) {
				crutch_Flag = notDone;
			}
			if (crutch_Flag) {
				if (elements->fetch(idx) == NULL) {
					idx += 1;
				} else {
					notDone = FALSE;
				}
			} else {
				break;
			}
		}
	} else {
		for (;;) {	BooleanVar crutch_Flag;
			/* idx <= lastElem && notDone */
			
			crutch_Flag = idx <= lastElem;
			if(crutch_Flag) {
				crutch_Flag = notDone;
			}
			if (crutch_Flag) {
				if (elements->fetch(idx) != NULL) {
					if (elements->fetch(idx)->isEqual(lastObj)) {
						idx += 1;
					} else {
						notDone = FALSE;
					}
				} else {
					notDone = FALSE;
				}
			} else {
				break;
			}
		}
	}
	WPTR(XnRegion) 	returnValue;
	returnValue = IntegerRegion::make (anIdx, start + idx);
	return returnValue;
}
/* printing */


void ActualIntegerTable::printOn (ostream& aStream){
	aStream << this->getCategory()->name();
	this->printOnWithSimpleSyntax(aStream, "[", ",", "]");
}
/* enumerating */


RPTR(TableStepper) ActualIntegerTable::stepper (APTR(OrderSpec) order/* = NULL*/){
	/* ignore order spec for now */
	/* Note that this method depends on the ITAscendingStepper 
	NOT copying the table. */
	
	if (order == NULL) {
		if (tally == UInt32Zero) {
			WPTR(TableStepper) 	returnValue;
			returnValue = IntegerTableStepper::make (this, start, start);
			return returnValue;
		} else {
			/* self lowestIndex */
			/* self highestIndex */
			RETURN_CONSTRUCT(ITAscendingStepper,(CAST(OberIntegerTable,this->copy()), start + firstElem, start + lastElem));
		}
	} else {
		WPTR(TableStepper) 	returnValue;
		returnValue = IntegerTableStepper::make (this, order);
		return returnValue;
	}
}


RPTR(Heaper) ActualIntegerTable::theOne (){
	if (this->count() != 1) {
		BLAST(NotOneElement);
	}
	WPTR(Heaper) 	returnValue;
	returnValue = this->intFetch(this->lowestIndex());
	return returnValue;
}
/* private: */


RPTR(IntegerRegion) ActualIntegerTable::contigDomainStarting (UInt32 anIdx){
	UInt32 begin;
	UInt32 tIdx;
	
	tIdx = begin = anIdx;
	for (;;) {	BooleanVar crutch_Flag;
		/* tIdx <= lastElem && elements->fetch(tIdx) != NULL */
		
		crutch_Flag = tIdx <= lastElem;
		if(crutch_Flag) {
			crutch_Flag = elements->fetch(tIdx) != NULL;
		}
		if (crutch_Flag) {
			tIdx += 1;
		} else {
			break;
		}
	}
	if (tIdx > begin) {
		WPTR(IntegerRegion) 	returnValue;
		returnValue = IntegerRegion::make (start + begin, start + tIdx);
		return returnValue;
	} else {
		WPTR(IntegerRegion) 	returnValue;
		returnValue = IntegerRegion::make (anIdx, anIdx);
		return returnValue;
	}
}


RPTR(PtrArray) ActualIntegerTable::elementsArray (){
	/* return the elements array for rapid processing */
	
	return (PtrArray*) elements;
}


UInt32 ActualIntegerTable::endOffset (){
	/* return the size of the elements array for rapid processing */
	
	return lastElem;
}


void ActualIntegerTable::enlargeAfter (IntegerVar toMinimum){
	/* Enlarge the receiver to contain more slots filled with nil. */
	
	SPTR(PtrArray) newElements;
	WPTR(PtrArray) oldElements;
	UInt32 tmp;
	UInt32 newSize;
	
	newSize = elemCount * 2;
	if (newSize < 4) {
		newSize = 4;
	}
	if (newSize < (tmp = (toMinimum - start).asLong() + 1)) {
		newSize = tmp;
	}
	newElements = PtrArray::nulls(newSize);
	{
		UInt32 LoopFinal = elemCount;
		UInt32 i = UInt32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				newElements->store(i, elements->fetch(i));
			}
			i += 1;
		}
	}
	/* Just for the hell of it, I make this robust for 
		asynchronous readers... */
	oldElements = elements;
	elements = newElements;
	{oldElements->destroy();  oldElements = NULL /* don't want stale (S/CHK)PTRs */;}
	elemCount = newSize;
	if (tally == UInt32Zero) {
		firstElem = elements->count() - 1;
	}
}


void ActualIntegerTable::enlargeBefore (IntegerVar toMinimum){
	/* Enlarge the receiver to contain more slots filled with nil. */
	
	UInt32 newSize;
	SPTR(PtrArray) newElements;
	WPTR(PtrArray) oldElements;
	UInt32 offset;
	UInt32 tmp;
	IntegerVar stop;
	
	stop = start + elemCount;
	newSize = elemCount * 2;
	if (newSize < 4) {
		newSize = 4;
	}
	if (newSize < (tmp = (stop - toMinimum).asLong() + 1)) {
		newSize = tmp;
	}
	newElements = PtrArray::nulls(newSize);
	offset = newSize - elemCount;
	{
		UInt32 LoopFinal = elemCount;
		UInt32 i = UInt32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				newElements->store(i + offset, elements->fetch(i));
			}
			i += 1;
		}
	}
	oldElements = elements;
	elements = newElements;
	{oldElements->destroy();  oldElements = NULL /* don't want stale (S/CHK)PTRs */;}
	start = stop - newSize;
	firstElem += offset;
	lastElem += offset;
	elemCount = newSize;
}


UInt32 ActualIntegerTable::firstElemAfter (UInt32 index){
	/* This method returns the first table entry that is not NULL 
	after index. */
	
	UInt32 idx;
	
	if (tally == UInt32Zero) {
		return elemCount;
	}
	idx = index + 1;
	for (;;) {	BooleanVar crutch_Flag;
		/* idx < lastElem && elements->fetch(idx) == NULL */
		
		crutch_Flag = idx < lastElem;
		if(crutch_Flag) {
			crutch_Flag = elements->fetch(idx) == NULL;
		}
		if (crutch_Flag) {
			idx += 1;
		} else {
			break;
		}
	}
	return idx;
}


RPTR(IntegerRegion) ActualIntegerTable::generateDomain (){
	UInt32 begin;
	SPTR(IntegerRegion) resReg;
	SPTR(IntegerRegion) nextReg;
	
	resReg = IntegerRegion::make ();
	if (tally == UInt32Zero) {
		WPTR(IntegerRegion) 	returnValue;
		returnValue = resReg;
		return returnValue;
	}
	begin = firstElem;
	while (begin <= lastElem) {
		nextReg = this->contigDomainStarting(begin);
		if (nextReg->isEmpty()) {
			nextReg = this->nullDomainStarting(begin);
		} else {
			resReg = CAST(IntegerRegion,resReg->unionWith(nextReg));
		}
		begin = (nextReg->stop() - start).asLong();
	}
	WPTR(IntegerRegion) 	returnValue;
	returnValue = resReg;
	return returnValue;
}


UInt32 ActualIntegerTable::lastElemBefore (UInt32 index){
	/* This method returns the first table entry that is not NULL 
	after index. */
	
	UInt32 idx;
	
	if (tally == UInt32Zero) {
		return UInt32Zero;
	}
	idx = index - 1;
	for (;;) {	BooleanVar crutch_Flag;
		/* idx > firstElem && elements->fetch(idx) == NULL */
		
		crutch_Flag = idx > firstElem;
		if(crutch_Flag) {
			crutch_Flag = elements->fetch(idx) == NULL;
		}
		if (crutch_Flag) {
			idx -= 1;
		} else {
			break;
		}
	}
	return idx;
}


UInt32 ActualIntegerTable::maxElements (){
	/* return the size of the elements array for rapid processing */
	
	return elemCount;
}


RPTR(IntegerRegion) ActualIntegerTable::nullDomainStarting (UInt32 anIdx){
	UInt32 begin;
	UInt32 tIdx;
	
	tIdx = begin = anIdx;
	for (;;) {	BooleanVar crutch_Flag;
		/* tIdx <= lastElem && elements->fetch(tIdx) == NULL */
		
		crutch_Flag = tIdx <= lastElem;
		if(crutch_Flag) {
			crutch_Flag = elements->fetch(tIdx) == NULL;
		}
		if (crutch_Flag) {
			tIdx += 1;
		} else {
			break;
		}
	}
	if (tIdx > begin) {
		WPTR(IntegerRegion) 	returnValue;
		returnValue = IntegerRegion::make (start + begin, start + tIdx);
		return returnValue;
	} else {
		WPTR(IntegerRegion) 	returnValue;
		returnValue = IntegerRegion::make (anIdx, anIdx);
		return returnValue;
	}
}


IntegerVar ActualIntegerTable::startIndex (){
	/* return the size of the elements array for rapid processing */
	
	return start;
}


UInt32 ActualIntegerTable::startOffset (){
	/* return the size of the elements array for rapid processing */
	
	return firstElem;
}
/* protected: destruct */


void ActualIntegerTable::destruct (){
	{elements->destroy();  elements = NULL /* don't want stale (S/CHK)PTRs */;}
	elements = NULL;
	this->OberIntegerTable::destruct();
}
/* protected: COW stuff */


void ActualIntegerTable::becomeCloneOnWrite (APTR(Heaper) where){
	SPTR(IntegerTable) tmp;
	SPTR(TableStepper) source;
	
	tmp = new (where) ActualIntegerTable(start, start + lastElem);
	if (tally == UInt32Zero) {
		return;
		
	}
	CONSTRUCT(source,ITAscendingStepper,(this, start + firstElem, start + lastElem));
	BEGIN_FOR_EACH(Heaper,tableElem,(source)) {
		tmp->store(source->position(), tableElem);
	} END_FOR_EACH;
}
/* overload junk */


RPTR(Heaper) ActualIntegerTable::store (APTR(Position) key, APTR(Heaper) value){
	WPTR(Heaper) 	returnValue;
	returnValue = this->atIntStore(CAST(IntegerPos,key)->asIntegerVar(), value);
	return returnValue;
}


RPTR(Heaper) ActualIntegerTable::fetch (APTR(Position) key){
	WPTR(Heaper) 	returnValue;
	returnValue = this->intFetch(CAST(IntegerPos,key)->asIntegerVar());
	return returnValue;
}


BooleanVar ActualIntegerTable::includesKey (APTR(Position) aKey){
	return this->includesIntKey(CAST(IntegerPos,aKey)->asIntegerVar());
}


RPTR(XnRegion) ActualIntegerTable::runAt (APTR(Position) anIdx){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->runAtInt(CAST(IntegerPos,anIdx)->asIntegerVar());
	return returnValue;
}


BooleanVar ActualIntegerTable::wipe (APTR(Position) key){
	return this->intWipe(CAST(IntegerPos,key)->asIntegerVar());
}



/* ************************************************************************ *
 * 
 *                    Class   COWIntegerTable 
 *
 * ************************************************************************ */


/* accessing */


RPTR(Heaper) COWIntegerTable::atIntStore (IntegerVar aKey, APTR(Heaper) anObject){
	this->aboutToWrite();
	WPTR(Heaper) 	returnValue;
	returnValue = this->atIntStore(aKey, anObject);
	return returnValue;
}


RPTR(CoordinateSpace) COWIntegerTable::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = myTable->coordinateSpace();
	return returnValue;
}


IntegerVar COWIntegerTable::count (){
	return myTable->count();
}


RPTR(XnRegion) COWIntegerTable::domain (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myTable->domain();
	return returnValue;
}


IntegerVar COWIntegerTable::highestIndex (){
	return myTable->highestIndex();
}


RPTR(Heaper) COWIntegerTable::intFetch (IntegerVar key){
	WPTR(Heaper) 	returnValue;
	returnValue = myTable->intFetch(key);
	return returnValue;
}


BooleanVar COWIntegerTable::intWipe (IntegerVar anIdx){
	this->aboutToWrite();
	return this->intWipe(anIdx);
}


IntegerVar COWIntegerTable::lowestIndex (){
	return myTable->lowestIndex();
}


RPTR(ScruTable) COWIntegerTable::subTable (APTR(XnRegion) reg){
	WPTR(ScruTable) 	returnValue;
	returnValue = myTable->subTable(reg);
	return returnValue;
}
/* creation */


RPTR(ScruTable) COWIntegerTable::copy (){
	WPTR(ScruTable) 	returnValue;
	returnValue = myTable->copy();
	return returnValue;
}


COWIntegerTable::COWIntegerTable (APTR(OberIntegerTable) table, TCSJ) {
	myPrev = table;
	this->setNextCOW(table->getNextCOW());
	table->setNextCOW(this);
	myTable = table;
}


void COWIntegerTable::destroy (){
	/* only recover these during GC.  otherwise crashes occur */
	
	
}


RPTR(ScruTable) COWIntegerTable::emptySize (IntegerVar size){
	WPTR(ScruTable) 	returnValue;
	returnValue = myTable->emptySize(size);
	return returnValue;
}


RPTR(ScruTable) COWIntegerTable::offsetSubTableBetween (
		IntegerVar startIndex, 
		IntegerVar stopIndex, 
		IntegerVar firstIndex)
{
	WPTR(ScruTable) 	returnValue;
	returnValue = myTable->offsetSubTableBetween(startIndex, stopIndex, firstIndex);
	return returnValue;
}


RPTR(ScruTable) COWIntegerTable::subTableBetween (IntegerVar startIndex, IntegerVar stopIndex){
	WPTR(ScruTable) 	returnValue;
	returnValue = myTable->subTableBetween(startIndex, stopIndex);
	return returnValue;
}
/* runs */


RPTR(XnRegion) COWIntegerTable::runAtInt (IntegerVar index){
	WPTR(XnRegion) 	returnValue;
	returnValue = myTable->runAtInt(index);
	return returnValue;
}
/* testing */


BooleanVar COWIntegerTable::includesIntKey (IntegerVar aKey){
	return myTable->includesIntKey(aKey);
}


BooleanVar COWIntegerTable::isEmpty (){
	return myTable->isEmpty();
}
/* enumerating */


RPTR(TableStepper) COWIntegerTable::stepper (APTR(OrderSpec) order/* = NULL*/){
	WPTR(TableStepper) 	returnValue;
	returnValue = myTable->stepper(order);
	return returnValue;
}
/* COW stuff */


WPTR(OberIntegerTable) COWIntegerTable::getPrev (){
	if ( ! (myPrev != NULL) ) {
		BLAST(NULL_in_getPrev);
	}
	return (OberIntegerTable*) myPrev;
}


void COWIntegerTable::setMuTable (APTR(OberIntegerTable) table){
	myTable = table;
}


void COWIntegerTable::setPrev (APTR(OberIntegerTable) set){
	myPrev = set;
}
/* private: */


RPTR(PtrArray) COWIntegerTable::elementsArray (){
	/* return the elements array for rapid processing */
	
	WPTR(PtrArray) 	returnValue;
	returnValue = myTable->elementsArray();
	return returnValue;
}


UInt32 COWIntegerTable::endOffset (){
	/* return the size of the elements array for rapid processing */
	
	return myTable->endOffset();
}


IntegerVar COWIntegerTable::startIndex (){
	return myTable->startIndex();
}


UInt32 COWIntegerTable::startOffset (){
	/* return the size of the elements array for rapid processing */
	
	return myTable->startOffset();
}
/* protected: COW stuff */


void COWIntegerTable::aboutToWrite (){
	WPTR(OberIntegerTable) prev;
	WPTR(COWIntegerTable) next;
	
	/* become a copy of myMuTable and remove myself from all 
	CopyOnWrite dependendents lists.
		The caller's self/this pointer will point to the becomed 
	object after this returns.
		This makes all my caller's look like they are recursive, but 
	they aren't. */
	prev = this->getPrev();
	next = this->getNextCOW();
	if (next != NULL) {
		next->setPrev(prev);
	}
	prev->setNextCOW(next);
	myTable->becomeCloneOnWrite(this);
}


void COWIntegerTable::becomeCloneOnWrite (APTR(Heaper) /* where */){
	BLAST(SHOULD_NOT_IMPLEMENT);
}
/* overload junk */


RPTR(Heaper) COWIntegerTable::store (APTR(Position) key, APTR(Heaper) value){
	WPTR(Heaper) 	returnValue;
	returnValue = this->atIntStore(CAST(IntegerPos,key)->asIntegerVar(), value);
	return returnValue;
}


RPTR(Heaper) COWIntegerTable::fetch (APTR(Position) key){
	WPTR(Heaper) 	returnValue;
	returnValue = this->intFetch(CAST(IntegerPos,key)->asIntegerVar());
	return returnValue;
}


BooleanVar COWIntegerTable::includesKey (APTR(Position) aKey){
	return this->includesIntKey(CAST(IntegerPos,aKey)->asIntegerVar());
}


RPTR(XnRegion) COWIntegerTable::runAt (APTR(Position) key){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->runAtInt(CAST(IntegerPos,key)->asIntegerVar());
	return returnValue;
}


BooleanVar COWIntegerTable::wipe (APTR(Position) key){
	return this->intWipe(CAST(IntegerPos,key)->asIntegerVar());
}

#ifndef INTTABX_SXX
#include "inttabx.sxx"
#endif /* INTTABX_SXX */


#ifndef INTTABR_SXX
#include "inttabr.sxx"
#endif /* INTTABR_SXX */


#ifndef INTTABP_SXX
#include "inttabp.sxx"
#endif /* INTTABP_SXX */



#endif /* INTTABX_CXX */

