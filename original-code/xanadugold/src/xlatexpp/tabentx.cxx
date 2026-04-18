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

#ifndef TABENTX_CXX
#define TABENTX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef TABENTX_HXX
#include "tabentx.hxx"
#endif /* TABENTX_HXX */

#ifndef TABENTX_IXX
#include "tabentx.ixx"
#endif /* TABENTX_IXX */

#ifndef TABENTP_HXX
#include "tabentp.hxx"
#endif /* TABENTP_HXX */

#ifndef TABENTP_IXX
#include "tabentp.ixx"
#endif /* TABENTP_IXX */


#ifndef HSPACEX_HXX
#include "hspacex.hxx"
#endif /* HSPACEX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */




/* ************************************************************************ *
 * 
 *                    Class TableEntry 
 *
 * ************************************************************************ */


/* creation */


RPTR(TableEntry) TableEntry::make (IntegerVar index, APTR(Heaper) value){
	if (index == value->hashForEqual()) {
		RETURN_CONSTRUCT(HashIndexEntry,(value, tcsj));
	} else {
		RETURN_CONSTRUCT(IndexEntry,(index, value));
	}
}


RPTR(TableEntry) TableEntry::make (APTR(Position) key, APTR(Heaper) value){
	BEGIN_CHOOSE(key) {
		BEGIN_KIND(IntegerPos,xuint) {
			WPTR(TableEntry) 	returnValue;
			returnValue = TableEntry::make (xuint->asIntegerVar(), value);
			return returnValue;
		} END_KIND;
		BEGIN_KIND(HeaperAsPosition,hap) {
			if (key->isEqual(HeaperAsPosition::make (value))) {
				RETURN_CONSTRUCT(HeaperAsEntry,(value, tcsj));
			} else {
				RETURN_CONSTRUCT(PositionEntry,(key, value));
			}
		} END_KIND;
		BEGIN_OTHERS {
			RETURN_CONSTRUCT(PositionEntry,(key, value));
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return NULL;
}
/* accessing */


IntegerVar TableEntry::index (){
	return CAST(IntegerPos,this->position())->asIntegerVar();
}


BooleanVar TableEntry::matchInt (IntegerVar index){
	/* Return true if my key matches the position associated with index. */
	
	return this->match(IntegerPos::make (index));
}


BooleanVar TableEntry::matchValue (APTR(Heaper) value){
	/* Return true if my value matches value.  Note that this 
	*must* test EQ first in
		 case the value is no longer a heaper.  Otherwise we could 
	never remove a 
		 destructed object. */
	
	{	BooleanVar crutch_Flag;
		/* value == (Heaper * ) myValue || value->isEqual(myValue) */
		
		crutch_Flag = value == (Heaper * ) myValue;
		if(!crutch_Flag) {
			crutch_Flag = value->isEqual(myValue);
		}
		return crutch_Flag;
	}
}


BooleanVar TableEntry::replaceValue (APTR(Heaper) newValue){
	/* Return true if my value can be replaced in place, and 
	false if the entire entry must be replaced. */
	/* The default implementation. */
	
	myValue = newValue;
	return TRUE;
}
/* protected: creation */


TableEntry::TableEntry (APTR(Heaper) value, TCSJ) {
	myNext = NULL;
	myValue = value;
}


TableEntry::TableEntry (APTR(TableEntry) next, APTR(Heaper) value) {
	myNext = next;
	myValue = value;
}
/* printing */


void TableEntry::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << this->position() << " -> " << this->value() << ")";
}
/* destroy */


void TableEntry::destroy (){
	/* temporarily don't destroy. */
	
	
}



/* ************************************************************************ *
 * 
 *                    Class BucketArrayStepper 
 *
 * ************************************************************************ */



/* Initializers for BucketArrayStepper */

GPTR(InstanceCache) BucketArrayStepper::SomeSteppers = NULL;



BEGIN_INIT_TIME(BucketArrayStepper,initTimeNonInherited) {
	BucketArrayStepper::SomeSteppers = InstanceCache::make (8);
} END_INIT_TIME(BucketArrayStepper,initTimeNonInherited);



/* Initializers for BucketArrayStepper */






/* creation */


RPTR(TableStepper) BucketArrayStepper::make (APTR(SharedPtrArray) entries){
	SPTR(Heaper) result;
	
	result = BucketArrayStepper::SomeSteppers->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(BucketArrayStepper,(entries, NULL, Int32Zero));
	} else {
		WPTR(TableStepper) 	returnValue;
		returnValue = new (result) BucketArrayStepper(entries, NULL, Int32Zero);
		return returnValue;
	}
}
/* operations */


WPTR(Heaper) BucketArrayStepper::fetch (){
	if (myEntry == NULL) {
		return NULL;
	} else {
		WPTR(Heaper) 	returnValue;
		returnValue = myEntry->value();
		return returnValue;
	}
}


BooleanVar BucketArrayStepper::hasValue (){
	return myEntry != NULL;
}


void BucketArrayStepper::step (){
	if (myEntry != NULL) {
		myEntry = myEntry->fetchNext();
		this->verifyEntry();
	}
}
/* private: */


void BucketArrayStepper::verifyEntry (){
	/* Step through the bucket till we find something with a 
	matching key. */
	
	Int32 bucket;
	
	/* use a local index to avoid pointer refs in loop */
	if (myEntry != NULL) {
		return;
		
	}
	bucket = myNextBucket;
	while (bucket < myEntries->count()) {
		WPTR(Heaper) nextEntry;
		
		nextEntry = myEntries->fetch(bucket);
		bucket += 1;
		if (nextEntry != NULL) {
			myEntry = CAST(TableEntry,nextEntry);
			myNextBucket = bucket;
			return;
			
		}
	}
	myEntries = NULL;
}
/* special */


IntegerVar BucketArrayStepper::index (){
	if ( ! (myEntry != NULL) ) {
		BLAST(Illegal_access);
	}
	return myEntry->index();
}


RPTR(Position) BucketArrayStepper::position (){
	if ( ! (myEntry != NULL) ) {
		BLAST(Illegal_access);
	}
	WPTR(Position) 	returnValue;
	returnValue = myEntry->position();
	return returnValue;
}
/* protected: create */


BucketArrayStepper::BucketArrayStepper (
		APTR(SharedPtrArray) entries, 
		APTR(TableEntry) OR(NULL) entry, 
		Int32 nextBucket) 
{
	myEntry = entry;
	myEntries = entries;
	myNextBucket = nextBucket;
	myEntries->shareMore();
	this->verifyEntry();
}


void BucketArrayStepper::destruct (){
	if (myEntries != NULL) {
		myEntries->shareLess();
	}
	this->TableStepper::destruct();
}
/* create */


RPTR(Stepper) BucketArrayStepper::copy (){
	SPTR(Heaper) result;
	
	result = BucketArrayStepper::SomeSteppers->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(BucketArrayStepper,(myEntries, myEntry, myNextBucket));
	} else {
		WPTR(Stepper) 	returnValue;
		returnValue = new (result) BucketArrayStepper(myEntries, myEntry, myNextBucket);
		return returnValue;
	}
}


void BucketArrayStepper::destroy (){
	if (!BucketArrayStepper::SomeSteppers->store(this)) {
		this->TableStepper::destroy();
	}
}



/* ************************************************************************ *
 * 
 *                    Class HashIndexEntry 
 *
 * ************************************************************************ */


/* accessing */


BooleanVar HashIndexEntry::match (APTR(Position) key){
	/* Return true if my key matches key. */
	
	BEGIN_CHOOSE(key) {
		BEGIN_KIND(IntegerPos,pos) {
			return pos->asIntegerVar() == this->value()->hashForEqual();
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}


BooleanVar HashIndexEntry::matchInt (IntegerVar index){
	/* Return true if my key matches the position associated with index. */
	
	return index == this->value()->hashForEqual();
}


RPTR(Position) HashIndexEntry::position (){
	WPTR(Position) 	returnValue;
	returnValue = IntegerPos::make (this->value()->hashForEqual());
	return returnValue;
}


BooleanVar HashIndexEntry::replaceValue (APTR(Heaper) newValue){
	/* Return true if my value can be replaced in place, and 
	false if the entire entry must be replaced. */
	
	{	BooleanVar crutch_Flag;
		/* newValue->hashForEqual() == this->value()->hashForEqual() && this->TableEntry::replaceValue(newValue) */
		
		crutch_Flag = newValue->hashForEqual() == this->value()->hashForEqual();
		if(crutch_Flag) {
			crutch_Flag = this->TableEntry::replaceValue(newValue);
		}
		return crutch_Flag;
	}
}
/* creation */


RPTR(TableEntry) HashIndexEntry::copy (){
	RETURN_CONSTRUCT(HashIndexEntry,(this->value(), tcsj));
}


HashIndexEntry::HashIndexEntry (APTR(Heaper) value, TCSJ) 
	: TableEntry(value, tcsj) {
	
}


HashIndexEntry::HashIndexEntry (APTR(TableEntry) next, APTR(Heaper) value) 
	: TableEntry(next, value) {
	
}



/* ************************************************************************ *
 * 
 *                    Class HeaperAsEntry 
 *
 * ************************************************************************ */


/* accessing */


BooleanVar HeaperAsEntry::match (APTR(Position) position){
	/* Return true if my position matches position. */
	
	return this->position()->isEqual(position);
}


RPTR(Position) HeaperAsEntry::position (){
	WPTR(Position) 	returnValue;
	returnValue = HeaperAsPosition::make (this->value());
	return returnValue;
}


BooleanVar HeaperAsEntry::replaceValue (APTR(Heaper) newValue){
	/* Return true if my value can be replaced in place, and 
	false if the entire entry must be replaced. */
	
	{	BooleanVar crutch_Flag;
		/* newValue->hashForEqual() == this->value()->hashForEqual() && this->TableEntry::replaceValue(newValue) */
		
		crutch_Flag = newValue->hashForEqual() == this->value()->hashForEqual();
		if(crutch_Flag) {
			crutch_Flag = this->TableEntry::replaceValue(newValue);
		}
		return crutch_Flag;
	}
}
/* creation */


RPTR(TableEntry) HeaperAsEntry::copy (){
	RETURN_CONSTRUCT(HeaperAsEntry,(this->value(), tcsj));
}


HeaperAsEntry::HeaperAsEntry (APTR(Heaper) value, TCSJ) 
	: TableEntry(value, tcsj) {
	
}


HeaperAsEntry::HeaperAsEntry (APTR(TableEntry) next, APTR(Heaper) value) 
	: TableEntry(next, value) {
	
}



/* ************************************************************************ *
 * 
 *                    Class IndexEntry 
 *
 * ************************************************************************ */


/* accessing */


IntegerVar IndexEntry::index (){
	return myIndex;
}


BooleanVar IndexEntry::match (APTR(Position) key){
	/* Return true if my key matches key. */
	
	BEGIN_CHOOSE(key) {
		BEGIN_KIND(IntegerPos,pos) {
			return pos->asIntegerVar() == myIndex;
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}


BooleanVar IndexEntry::matchInt (IntegerVar index){
	/* Return true if my key matches the position associated with index. */
	
	return index == myIndex;
}


RPTR(Position) IndexEntry::position (){
	WPTR(Position) 	returnValue;
	returnValue = IntegerPos::make (myIndex);
	return returnValue;
}
/* creation */


RPTR(TableEntry) IndexEntry::copy (){
	RETURN_CONSTRUCT(IndexEntry,(myIndex, this->value()));
}


IndexEntry::IndexEntry (IntegerVar index, APTR(Heaper) value) 
	: TableEntry(value, tcsj) {
	myIndex = index;
}


IndexEntry::IndexEntry (
		APTR(TableEntry) next, 
		APTR(Heaper) value, 
		IntegerVar index) 

	: TableEntry(next, value) {
	myIndex = index;
}
/* printing */


void IndexEntry::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << IntegerPos::make (myIndex) << " -> " << this->value() << ")";
}



/* ************************************************************************ *
 * 
 *                    Class PositionEntry 
 *
 * ************************************************************************ */


/* accessing */


BooleanVar PositionEntry::match (APTR(Position) key){
	/* Return true if my key matches key. */
	
	return key->isEqual(myKey);
}


RPTR(Position) PositionEntry::position (){
	return (Position*) myKey;
}
/* creation */


RPTR(TableEntry) PositionEntry::copy (){
	RETURN_CONSTRUCT(PositionEntry,(myKey, this->value()));
}


PositionEntry::PositionEntry (APTR(Position) key, APTR(Heaper) value) 
	: TableEntry(value, tcsj) {
	myKey = key;
}


PositionEntry::PositionEntry (
		APTR(TableEntry) next, 
		APTR(Heaper) value, 
		APTR(Position) key) 

	: TableEntry(next, value) {
	myKey = key;
}

#ifndef TABENTX_SXX
#include "tabentx.sxx"
#endif /* TABENTX_SXX */


#ifndef TABENTP_SXX
#include "tabentp.sxx"
#endif /* TABENTP_SXX */



#endif /* TABENTX_CXX */

