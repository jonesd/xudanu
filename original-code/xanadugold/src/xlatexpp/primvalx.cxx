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

#ifndef PRIMVALX_CXX
#define PRIMVALX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef PRIMVALX_HXX
#include "primvalx.hxx"
#endif /* PRIMVALX_HXX */

#ifndef PRIMVALX_IXX
#include "primvalx.ixx"
#endif /* PRIMVALX_IXX */


#ifndef FHASHX_HXX
#include "fhashx.hxx"
#endif /* FHASHX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */




/* ************************************************************************ *
 * 
 *                    Class PrimSpec 
 *
 * ************************************************************************ */



/* Initializers for PrimSpec */

GPTR(PrimIntegerSpec) PrimSpec::TheUInt8Spec = NULL;
GPTR(PrimIntegerSpec) PrimSpec::TheUInt32Spec = NULL;
GPTR(PrimIntegerSpec) PrimSpec::TheInt32Spec = NULL;
GPTR(PrimIntegerSpec) PrimSpec::TheIntegerVarSpec = NULL;
GPTR(PrimFloatSpec) PrimSpec::TheIEEE32Spec = NULL;
GPTR(PrimFloatSpec) PrimSpec::TheIEEE64Spec = NULL;
GPTR(PrimPointerSpec) PrimSpec::ThePtrSpec = NULL;
GPTR(PrimPointerSpec) PrimSpec::TheSharedPtrSpec = NULL;



BEGIN_INIT_TIME(PrimSpec,initTimeNonInherited) {
	PrimSpec::initSpecs();
} END_INIT_TIME(PrimSpec,initTimeNonInherited);



/* Initializers for PrimSpec */






/* private: init */


void PrimSpec::initSpecs (){
	/* moved from initTime because MS C++/NT does not like large 
	initTimes */
	
	CONSTRUCT(PrimSpec::TheUInt8Spec,PrimIntegerSpec,(cat_UInt8Array, 8, FALSE));
	CONSTRUCT(PrimSpec::TheUInt32Spec,PrimIntegerSpec,(cat_UInt32Array, 32, FALSE));
	CONSTRUCT(PrimSpec::TheInt32Spec,PrimIntegerSpec,(cat_Int32Array, 32, TRUE));
	CONSTRUCT(PrimSpec::TheIntegerVarSpec,PrimIntegerSpec,(cat_IntegerVarArray, -1, TRUE));
	CONSTRUCT(PrimSpec::TheIEEE32Spec,PrimFloatSpec,(cat_IEEE32Array, 32));
	CONSTRUCT(PrimSpec::TheIEEE64Spec,PrimFloatSpec,(cat_IEEE64Array, 64));
	CONSTRUCT(PrimSpec::ThePtrSpec,PrimPointerSpec,(cat_PtrArray, tcsj));
	CONSTRUCT(PrimSpec::TheSharedPtrSpec,PrimPointerSpec,(cat_SharedPtrArray, tcsj));
}
/* pseudo constructors */


RPTR(PrimFloatSpec) PrimSpec::iEEE (Int32 precision){
	if (precision == 32) {
		WPTR(PrimFloatSpec) 	returnValue;
		returnValue = PrimSpec::TheIEEE32Spec;
		return returnValue;
	}
	if (precision == 64) {
		WPTR(PrimFloatSpec) 	returnValue;
		returnValue = PrimSpec::TheIEEE64Spec;
		return returnValue;
	}
	BLAST(NOT_YET_IMPLEMENTED);
	return NULL;
}


RPTR(PrimIntegerSpec) PrimSpec::signedInteger (Int32 bitCount){
	if (bitCount == 32) {
		WPTR(PrimIntegerSpec) 	returnValue;
		returnValue = PrimSpec::TheInt32Spec;
		return returnValue;
	}
	BLAST(NOT_YET_IMPLEMENTED);
	return NULL;
}


RPTR(PrimIntegerSpec) PrimSpec::toHold (IntegerVar value){
	/* The least demanding spec that will hold the given value */
	
	if (value < IntegerVar0) {
		if (value < Int32Min) {
			WPTR(PrimIntegerSpec) 	returnValue;
			returnValue = PrimSpec::integerVar();
			return returnValue;
		} else {
			WPTR(PrimIntegerSpec) 	returnValue;
			returnValue = PrimSpec::int32();
			return returnValue;
		}
	} else {
		if (value <= Int32Max) {
			if (value <= UInt8Max) {
				WPTR(PrimIntegerSpec) 	returnValue;
				returnValue = PrimSpec::uInt8();
				return returnValue;
			} else {
				WPTR(PrimIntegerSpec) 	returnValue;
				returnValue = PrimSpec::int32();
				return returnValue;
			}
		} else {
			if (value <= UInt32Max) {
				WPTR(PrimIntegerSpec) 	returnValue;
				returnValue = PrimSpec::uInt32();
				return returnValue;
			} else {
				WPTR(PrimIntegerSpec) 	returnValue;
				returnValue = PrimSpec::integerVar();
				return returnValue;
			}
		}
	}
}


RPTR(PrimIntegerSpec) PrimSpec::unsignedInteger (Int32 bitCount){
	if (bitCount == 32) {
		WPTR(PrimIntegerSpec) 	returnValue;
		returnValue = PrimSpec::TheUInt32Spec;
		return returnValue;
	}
	if (bitCount == 8) {
		WPTR(PrimIntegerSpec) 	returnValue;
		returnValue = PrimSpec::TheUInt8Spec;
		return returnValue;
	}
	BLAST(NOT_YET_IMPLEMENTED);
	return NULL;
}
/* A specification of a kind of primitive data type which can be 
stored in PrimArrays. It gives you protocol for creating and copying 
PrimArrays. The class and characteristics of this object determine 
what kind of things are stored there, and how much precision they have. */


/* private: making */
/* protected: */
/* protected: create */


PrimSpec::PrimSpec (APTR(Category) primClass, TCSJ) {
	myClass = primClass;
}
/* making */


RPTR(PrimArray) PrimSpec::arrayWith (APTR(Heaper) value){
	/* Make a single element array containing the given value */
	
	SPTR(PrimArray) result;
	
	result = this->array(1);
	result->storeValue(Int32Zero, value);
	WPTR(PrimArray) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(PrimArray) PrimSpec::arrayWithThree (
		APTR(Heaper) value, 
		APTR(Heaper) other, 
		APTR(Heaper) another)
{
	/* Make a two element array containing the given values */
	
	SPTR(PrimArray) result;
	
	result = this->array(3);
	result->storeValue(Int32Zero, value);
	result->storeValue(1, other);
	result->storeValue(2, another);
	WPTR(PrimArray) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(PrimArray) PrimSpec::arrayWithTwo (APTR(Heaper) value, APTR(Heaper) other){
	/* Make a two element array containing the given values */
	
	SPTR(PrimArray) result;
	
	result = this->array(2);
	result->storeValue(Int32Zero, value);
	result->storeValue(1, other);
	WPTR(PrimArray) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(PrimArray) PrimSpec::copy (
		APTR(PrimArray) array, 
		Int32 count/* = -1*/, 
		Int32 start/* = Int32Zero*/, 
		Int32 before/* = Int32Zero*/, 
		Int32 after/* = Int32Zero*/)
{
	/* Make a copy of an array with a different representation 
	size. The arguments are the same as in PrimArray::copy. */
	
	Int32 copyCount;
	
	if (count < Int32Zero) {
		copyCount = array->count() - start;
	} else {
		copyCount = count;
		if (start + copyCount > array->count()) {
			BLAST(IndexOutOfBounds);
		}
	}
	WPTR(PrimArray) 	returnValue;
	returnValue = this->privateCopy(array, copyCount + before + after, start, copyCount, before);
	return returnValue;
}


RPTR(PrimArray) PrimSpec::copyGrow (APTR(PrimArray) array, Int32 after){
	/* Make a copy of the array into a larger array.  The array 
	has 'after' slots after the copied elements. */
	
	WPTR(PrimArray) 	returnValue;
	returnValue = this->copy(array, -1, Int32Zero, Int32Zero, after);
	return returnValue;
}
/* accessing */


Int32 PrimSpec::sizeofElement (){
	/* Essential. The size of a single element of the array, to 
	be used to allocated space for copyTo/FromBuffer. In the same 
	units as C sizeof (). */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return Int32Zero;
}
/* testing */


UInt32 PrimSpec::actualHashForEqual (){
	return Heaper::takeOop();
}



/* ************************************************************************ *
 * 
 *                    Class   PrimFloatSpec 
 *
 * ************************************************************************ */


/* Specifies different precisions and representations of floating 
point numbers. */


/* accessing */
/* create */


PrimFloatSpec::PrimFloatSpec (APTR(Category) primClass, Int32 bitCount) 
	: PrimSpec(primClass, tcsj) {
	myBitCount = bitCount;
}
/* testing */


UInt32 PrimFloatSpec::actualHashForEqual (){
	return this->getCategory()->hashForEqual() ^ ::fastHash(myBitCount);
}


BooleanVar PrimFloatSpec::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(PrimFloatSpec,spec) {
			return myBitCount == spec->bitCount();
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}
/* private: making */


RPTR(PrimArray) PrimFloatSpec::privateCopy (
		APTR(PrimArray) array, 
		Int32 size/* = -1*/, 
		Int32 start/* = Int32Zero*/, 
		Int32 count/* = -1*/, 
		Int32 offset/* = Int32Zero*/)
{
	/* Make a copy of an array with a different representation 
	size. The arguments are the same as in PrimArray::copy. */
	
	/* Eric -- Thing to do !!!! */
	
	if (this == (Heaper * ) PrimSpec::iEEE64()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = IEEE64Array::make (size, array, start, count, offset);
		return returnValue;
	}
	if (this == (Heaper * ) PrimSpec::iEEE32()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = IEEE32Array::make (size, array, start, count, offset);
		return returnValue;
	}
	BLAST(BadPrimSpec);
	
	
	/* compiler fodder */
	return NULL;
}
/* making */


RPTR(PrimArray) PrimFloatSpec::array (Int32 count/* = Int32Zero*/){
	/* Make an array initialized to zero values */
	
	/* Eric -- Thing to do !!!! */
	
	if (this == (Heaper * ) PrimSpec::iEEE64()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = IEEE64Array::make (count);
		return returnValue;
	}
	if (this == (Heaper * ) PrimSpec::iEEE32()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = IEEE32Array::make (count);
		return returnValue;
	}
	BLAST(BadPrimSpec);
	
	
	/* compiler fodder */
	return NULL;
}


RPTR(PrimArray) PrimFloatSpec::arrayFromBuffer (Int32 count, void * buffer){
	/* Make an array with the values at the given address */
	
	/* Generic case of unspecified size can't be handled here. */
	if (this == (Heaper * ) PrimSpec::iEEE64()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = IEEE64Array::make (count, buffer);
		return returnValue;
	}
	if (this == (Heaper * ) PrimSpec::iEEE32()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = IEEE32Array::make (count, buffer);
		return returnValue;
	}
	BLAST(BadPrimSpec);
	
	
	/* compiler fodder */
	return NULL;
}


RPTR(PrimFloatValue) PrimFloatSpec::preciseValue (IEEE128 number){
	/* A boxed floating point value from a large precision number */
	/* myBitCount = 32 ifTrue: [^PrimIEEE32 make: self with: number].
		myBitCount = 64 ifTrue: [^PrimIEEE64 make: self with: number] */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}


RPTR(PrimFloatValue) PrimFloatSpec::value (IEEE64 number){
	/* A boxed floating point value */
	
	if (myBitCount == 32) {
		WPTR(PrimFloatValue) 	returnValue;
		returnValue = PrimIEEE32::make (number);
		return returnValue;
	}
	if (myBitCount == 64) {
		WPTR(PrimFloatValue) 	returnValue;
		returnValue = PrimIEEE64::make (number);
		return returnValue;
	}
	/* fodder */
	return NULL;
}



/* ************************************************************************ *
 * 
 *                    Class   PrimIntegerSpec 
 *
 * ************************************************************************ */


/* accessing */


RPTR(PrimIntegerSpec) PrimIntegerSpec::combine (APTR(PrimIntegerSpec) other){
	/* A spec whose range of values contains both ranges */
	
	if (this == other) {
		return this;
	}
	if (myBitCount == Int32Zero) {
		return this;
	}
	if (other->bitCount() == Int32Zero) {
		WPTR(PrimIntegerSpec) 	returnValue;
		returnValue = other;
		return returnValue;
	}
	if (myBitCount < other->bitCount()) {
		WPTR(PrimIntegerSpec) 	returnValue;
		returnValue = other;
		return returnValue;
	}
	if (myBitCount > other->bitCount()) {
		return this;
	}
	if (amSigned == other->isSigned()) {
		return this;
	}
	/* here we get ad hoc since we need to expand to the next 
		larger size */
	if (myBitCount == 8) {
		WPTR(PrimIntegerSpec) 	returnValue;
		returnValue = PrimSpec::int32();
		return returnValue;
	}
	WPTR(PrimIntegerSpec) 	returnValue;
	returnValue = PrimSpec::integerVar();
	return returnValue;
}
/* create */


PrimIntegerSpec::PrimIntegerSpec (
		APTR(Category) primClass, 
		Int32 bitCount, 
		BooleanVar isSigned) 

	: PrimSpec(primClass, tcsj) {
	myBitCount = bitCount;
	amSigned = isSigned;
	if (myBitCount != -1) {
		if (amSigned) {
			
			myMin = 1 << (myBitCount - 1);
			myMax = ~myMin;
			
		} else {
			
			myMin = Int32Zero;
			/* the shift is done in two steps to avoid five-bit truncation on SPARCs */
			myMax = ~(((~Int32Zero) << (myBitCount - 1)) << 1);
			
		}
	}
}
/* testing */


UInt32 PrimIntegerSpec::actualHashForEqual (){
	UInt32 signPart;
	
	if (amSigned) {
		signPart = 255;
	} else {
		signPart = UInt32Zero;
	}
	return this->getCategory()->hashForEqual() ^ ::fastHash(myBitCount) ^ signPart;
}


BooleanVar PrimIntegerSpec::canHold (IntegerVar value){
	/* Whether this spec can hold the given value */
	
	
	if (myBitCount = -1) {
		return TRUE;
	} else if (amSigned) {
		return value >= myMin && value <= myMax;
	} else {
		return (unsigned) value.asLong () >= (unsigned) myMin
			&& (unsigned) value.asLong () <= (unsigned) myMax;
	}
	
}


BooleanVar PrimIntegerSpec::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(PrimIntegerSpec,spec) {
			{	BooleanVar crutch_Flag;
				/* myBitCount == spec->bitCount() && amSigned == spec->isSigned() */
				
				crutch_Flag = myBitCount == spec->bitCount();
				if(crutch_Flag) {
					crutch_Flag = amSigned == spec->isSigned();
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* compiler fodder */
	return FALSE;
}
/* making */


RPTR(PrimArray) PrimIntegerSpec::array (Int32 count/* = Int32Zero*/){
	/* Make an array initialized to zero values */
	
	if (this == (Heaper * ) PrimSpec::uInt32()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = UInt32Array::make (count);
		return returnValue;
	}
	if (this == (Heaper * ) PrimSpec::uInt8()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = UInt8Array::make (count);
		return returnValue;
	}
	if (this == (Heaper * ) PrimSpec::int32()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = Int32Array::make (count);
		return returnValue;
	}
	if (this == (Heaper * ) PrimSpec::integerVar()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = IntegerVarArray::zeros(count);
		return returnValue;
	}
	BLAST(BadPrimSpec);
	
	
	/* compiler fodder */
	return NULL;
}


RPTR(PrimArray) PrimIntegerSpec::arrayFromBuffer (Int32 count, void * buffer){
	/* Make an array with the values at the given address */
	
	if (this == (Heaper * ) PrimSpec::uInt32()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = UInt32Array::make (count, buffer);
		return returnValue;
	}
	if (this == (Heaper * ) PrimSpec::uInt8()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = UInt8Array::make (count, buffer);
		return returnValue;
	}
	if (this == (Heaper * ) PrimSpec::int32()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = Int32Array::make (count, buffer);
		return returnValue;
	}
	if (this == (Heaper * ) PrimSpec::integerVar()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = IntegerVarArray::make (count, buffer);
		return returnValue;
	}
	BLAST(BadPrimSpec);
	
	
	/* compiler fodder */
	return NULL;
}


RPTR(PrimIntegerArray) PrimIntegerSpec::string (char * string){
	/* Make an array the contents of the string */
	
	if (this == (Heaper * ) PrimSpec::uInt8()) {
		WPTR(PrimIntegerArray) 	returnValue;
		returnValue = UInt8Array::string(string);
		return returnValue;
	}
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}
/* private: making */


RPTR(PrimArray) PrimIntegerSpec::privateCopy (
		APTR(PrimArray) array, 
		Int32 size/* = -1*/, 
		Int32 start/* = Int32Zero*/, 
		Int32 count/* = -1*/, 
		Int32 offset/* = Int32Zero*/)
{
	/* Make a copy of an array with a different representation 
	size. The arguments are the same as in PrimArray::copy. */
	
	if (this == (Heaper * ) PrimSpec::uInt32()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = UInt32Array::make (size, array, start, count, offset);
		return returnValue;
	}
	if (this == (Heaper * ) PrimSpec::uInt8()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = UInt8Array::make (size, array, start, count, offset);
		return returnValue;
	}
	if (this == (Heaper * ) PrimSpec::int32()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = Int32Array::make (size, array, start, count, offset);
		return returnValue;
	}
	if (this == (Heaper * ) PrimSpec::integerVar()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = IntegerVarArray::make (size, array, start, count, offset);
		return returnValue;
	}
	BLAST(BadPrimSpec);
	
	
	/* compiler fodder */
	return NULL;
}



/* ************************************************************************ *
 * 
 *                    Class   PrimPointerSpec 
 *
 * ************************************************************************ */


/* Describes a kind of primitive pointer array */


/* testing */


UInt32 PrimPointerSpec::actualHashForEqual (){
	return this->getCategory()->hashForEqual() ^ this->arrayClass()->hashForEqual();
}


BooleanVar PrimPointerSpec::isEqual (APTR(Heaper) other){
	{	BooleanVar crutch_Flag;
		/* other->isKindOf(cat_PrimPointerSpec) && this->arrayClass() == CAST(PrimPointerSpec,other)->arrayClass() */
		
		crutch_Flag = other->isKindOf(cat_PrimPointerSpec);
		if(crutch_Flag) {
			crutch_Flag = this->arrayClass() == CAST(PrimPointerSpec,other)->arrayClass();
		}
		return crutch_Flag;
	}
}
/* private: making */


RPTR(PrimArray) PrimPointerSpec::privateCopy (
		APTR(PrimArray) array, 
		Int32 size/* = -1*/, 
		Int32 start/* = Int32Zero*/, 
		Int32 count/* = -1*/, 
		Int32 offset/* = Int32Zero*/)
{
	/* Make a copy of an array with a different representation 
	size. The arguments are the same as in PrimArray::copy. */
	
	if (this == (Heaper * ) PrimSpec::pointer()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = PtrArray::make (size, array, start, count, offset);
		return returnValue;
	}
	if (this == (Heaper * ) PrimSpec::sharedPointer()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = SharedPtrArray::make (size, array, start, count, offset);
		return returnValue;
	}
	BLAST(BadPrimSpec);
	
	
	/* compiler fodder */
	return NULL;
}
/* create */


PrimPointerSpec::PrimPointerSpec (APTR(Category) primClass, TCSJ) 
	: PrimSpec(primClass, tcsj) {
	
}
/* making */


RPTR(PrimArray) PrimPointerSpec::array (Int32 count/* = Int32Zero*/){
	/* Make an array initialized to null values */
	
	if (this == (Heaper * ) PrimSpec::pointer()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = PtrArray::nulls(count);
		return returnValue;
	}
	if (this == (Heaper * ) PrimSpec::sharedPointer()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = SharedPtrArray::make (count);
		return returnValue;
	}
	BLAST(BadPrimSpec);
	
	
	/* compiler fodder */
	return NULL;
}


RPTR(PrimArray) PrimPointerSpec::arrayFromBuffer (Int32 count, void * buffer){
	/* Make an array with the values at the given address */
	
	if (this == (Heaper * ) PrimSpec::pointer()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = PtrArray::make (count, buffer);
		return returnValue;
	}
	if (this == (Heaper * ) PrimSpec::sharedPointer()) {
		WPTR(PrimArray) 	returnValue;
		returnValue = SharedPtrArray::make (count, buffer);
		return returnValue;
	}
	BLAST(BadPrimSpec);
	
	
	/* compiler fodder */
	return NULL;
}



/* ************************************************************************ *
 * 
 *                    Class PrimValue 
 *
 * ************************************************************************ */


/* A boxed representation of a primitive data type */



	/* automatic 0-argument constructor */
PrimValue::PrimValue() {}



/* ************************************************************************ *
 * 
 *                    Class   PrimFloatValue 
 *
 * ************************************************************************ */


/* A boxed representation of a floating point value */


/* accessing */

	/* automatic 0-argument constructor */
PrimFloatValue::PrimFloatValue() {}



/* ************************************************************************ *
 * 
 *                    Class     PrimIEEE32 
 *
 * ************************************************************************ */


/* create */


RPTR(PrimIEEE32) PrimIEEE32::make (IEEE32 value){
	RETURN_CONSTRUCT(PrimIEEE32,(value, tcsj));
}
/* A boxed representation of an IEEE 32-bit floating point value */


/* testing */


UInt32 PrimIEEE32::actualHashForEqual (){
	/* Eric -- Thing to do !!!! */
	
	/* Figure out a hash for floats */
#if !defined(GNUSUN)	
	BLAST(NOT_YET_IMPLEMENTED);
#endif
	return this->bitCount();
	
}


BooleanVar PrimIEEE32::isEqual (APTR(Heaper) other){
	if (!other->isKindOf(cat_PrimIEEE32)) {
		BLAST(IncomparableType);
	}
	return myValue == CAST(PrimIEEE32,other)->asIEEE32();
}
/* accessing */


IEEE32 PrimIEEE32::asIEEE32 (){
	/* The value as an IEEE 32-bit floating point number */
	
	return myValue;
}


IEEE64 PrimIEEE32::asIEEE64 (){
	/* The value as an IEEE 64-bit floating point number */
	
	return (IEEE64 ) myValue;
	
	
}


Int32 PrimIEEE32::bitCount (){
	return 32;
}


IntegerVar PrimIEEE32::exponent (){
	/* If this is a number, return the exponent */
	
	if (!this->isANumber()) {
		BLAST(NotANumber);
	}
	
	
#if defined(_MSC_VER) || defined(HIGHC) || defined(__sgi) ||  defined (XGNUSUN)
	BLAST(NOT_YET_IMPLEMENTED);
	return IntegerVarZero; /* fodder */
#else
	return myValue == 0 ? 0 : ilogb(myValue);
#endif /* WIN32 */

	
}


BooleanVar PrimIEEE32::isANumber (){
	
	
#if defined(_MSC_VER) || defined(HIGHC) || defined(__sgi)||  defined (XGNUSUN)
	BLAST(NOT_YET_IMPLEMENTED);
	return FALSE; /* fodder */
#else
	return finite(myValue);
#endif /* WIN32 */

	
}


IntegerVar PrimIEEE32::mantissa (){
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return IntegerVarZero;
}
/* protected: create */


PrimIEEE32::PrimIEEE32 (IEEE32 value, TCSJ) {
	myValue = value;
}



/* ************************************************************************ *
 * 
 *                    Class     PrimIEEE64 
 *
 * ************************************************************************ */


/* create */


RPTR(PrimIEEE64) PrimIEEE64::make (IEEE64 value){
	RETURN_CONSTRUCT(PrimIEEE64,(value, tcsj));
}
/* A boxed representation of an IEEE 64-bit floating point value */


/* testing */


UInt32 PrimIEEE64::actualHashForEqual (){
	/* Eric -- Thing to do !!!! */
	
	/* Figure out a hash for floats */
	
	/*BLAST(NOT_YET_IMPLEMENTED);*/ // zzz reg 
	return this->bitCount();
	
}


BooleanVar PrimIEEE64::isEqual (APTR(Heaper) other){
	if (!other->isKindOf(cat_PrimIEEE64)) {
		BLAST(IncomparableType);
	}
	return myValue == CAST(PrimIEEE64,other)->asIEEE64();
}
/* accessing */


IEEE32 PrimIEEE64::asIEEE32 (){
	/* The value as an IEEE 32-bit floating point number */
	
	return (IEEE32 ) myValue;
	
	
}


IEEE64 PrimIEEE64::asIEEE64 (){
	/* The value as an IEEE 64-bit floating point number */
	
	return myValue;
}


Int32 PrimIEEE64::bitCount (){
	return 64;
}


IntegerVar PrimIEEE64::exponent (){
	/* If this is a number, return the exponent */
	
	if (!this->isANumber()) {
		BLAST(NotANumber);
	}
	
	
#if defined(_MSC_VER) || defined(HIGHC) || defined(__sgi) ||  defined (XGNUSUN)
	BLAST(NOT_YET_IMPLEMENTED);
	return IntegerVarZero; /* fodder */
#else
	return myValue == 0 ? 0 : ilogb(myValue);
#endif /* WIN32 */

	
}


BooleanVar PrimIEEE64::isANumber (){
	
	
#if defined(_MSC_VER) || defined(HIGHC) || defined(__sgi) ||  defined (XGNUSUN)
	BLAST(NOT_YET_IMPLEMENTED);
	return FALSE; /* fodder */
#else
	return finite(myValue);
#endif /* WIN32 */

	
}


IntegerVar PrimIEEE64::mantissa (){
#if defined(GNUSUN)
	BLAST(NOT_YET_IMPLEMENTED);
#endif
	/* fodder */
	return IntegerVarZero;
}
/* protected: create */


PrimIEEE64::PrimIEEE64 (IEEE64 value, TCSJ) {
	myValue = value;
}



/* ************************************************************************ *
 * 
 *                    Class   PrimIntValue 
 *
 * ************************************************************************ */


/* create */


RPTR(PrimIntValue) PrimIntValue::make (IntegerVar value){
	RETURN_CONSTRUCT(PrimIntValue,(value, tcsj));
}
/* operations */


IntegerVar PrimIntValue::bitwiseAnd (APTR(PrimIntValue) another){
	/* Return the the first number bitwise and'd with the second. */
	
	return myValue & another->asIntegerVar();
}


IntegerVar PrimIntValue::bitwiseOr (APTR(PrimIntValue) another){
	/* Return the the first number bitwise or'd with the second. */
	
	return myValue | another->asIntegerVar();
}


IntegerVar PrimIntValue::bitwiseXor (APTR(PrimIntValue) another){
	/* Return the the first number bitwise xor'd with the second. */
	
	return myValue ^ another->asIntegerVar();
}


IntegerVar PrimIntValue::dividedBy (APTR(PrimIntValue) another){
	/* Integer divide the two numbers and return the result.  
	This truncates. */
	
	return myValue / another->asIntegerVar();
}


BooleanVar PrimIntValue::isGE (APTR(PrimIntValue) another){
	/* Return true if the first number is greater than or euqla 
	to the second number. */
	
	return myValue >= another->asIntegerVar();
}


IntegerVar PrimIntValue::leftShift (APTR(PrimIntValue) another){
	/* Return the the first number shifted to the left by the 
	second amount. */
	
	return myValue << another->asIntegerVar();
}


IntegerVar PrimIntValue::maximum (APTR(PrimIntValue) another){
	/* Return the largest of the two numbers. */
	
	return max(myValue, another->asIntegerVar());
}


IntegerVar PrimIntValue::minimum (APTR(PrimIntValue) another){
	/* Return the smallest of the two numbers. */
	
	return min(myValue, another->asIntegerVar());
}


IntegerVar PrimIntValue::minus (APTR(PrimIntValue) another){
	/* Return the difference two numbers. */
	
	return myValue - another->asIntegerVar();
}


IntegerVar PrimIntValue::mod (APTR(PrimIntValue) another){
	/* Return the the first number modulo the second. */
	
	return myValue % another->asIntegerVar();
}


IntegerVar PrimIntValue::plus (APTR(PrimIntValue) another){
	/* Return the sum of two numbers. */
	
	return myValue + another->asIntegerVar();
}


IntegerVar PrimIntValue::times (APTR(PrimIntValue) another){
	/* Multiply the two numbers and return the result. */
	
	return myValue * another->asIntegerVar();
}
/* accessing */


Int32 PrimIntValue::bitCount (){
	/* What precision is it, in terms of the number of bits used 
	to represent it.  In the interests of efficiency, this may 
	return a number larger than that *needed* to represent it.  
	However, the precision reported must be at least that needed 
	to represent this number.
		The fact that this message is allowed to overestimate 
	precision doesn't interfere with equality: a->isEqual(b) 
	exactly when they represent that same real number, even if 
	one of them happens to overestimate precision more that the other. */
	
	Int32 precision;
	
	precision = PrimSpec::toHold(myValue)->bitCount();
	if (precision == Int32Zero) {
		BLAST(NoBitCountLimit);
	}
	return precision;
}
/* testing */


UInt32 PrimIntValue::actualHashForEqual (){
	return ::fastHash(myValue.asLong());
}


BooleanVar PrimIntValue::isEqual (APTR(Heaper) other){
	{	BooleanVar crutch_Flag;
		/* other->isKindOf(cat_PrimIntValue) && CAST(PrimIntValue,other)->asIntegerVar() == myValue */
		
		crutch_Flag = other->isKindOf(cat_PrimIntValue);
		if(crutch_Flag) {
			crutch_Flag = CAST(PrimIntValue,other)->asIntegerVar() == myValue;
		}
		return crutch_Flag;
	}
}
/* protected: create */


PrimIntValue::PrimIntValue (IntegerVar value, TCSJ) {
	myValue = value;
}
/* printing */


void PrimIntValue::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myValue << ")";
}

#ifndef PRIMVALX_SXX
#include "primvalx.sxx"
#endif /* PRIMVALX_SXX */



#endif /* PRIMVALX_CXX */

