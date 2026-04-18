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

#ifndef PRIMVALX_IXX
#define PRIMVALX_IXX

#ifdef GNUSUN
/*extern "C"{
#include <math.h>
}*/
#else
#include <math.h>
#endif




/* ************************************************************************ *
 * 
 *                    Class PrimSpec 
 *
 * ************************************************************************ */


/* private: init */
/* pseudo constructors */


INLINE RPTR(PrimFloatSpec) PrimSpec::iEEE32 (){
	WPTR(PrimFloatSpec) 	returnValue;
	returnValue = PrimSpec::TheIEEE32Spec;
	return returnValue;
}


INLINE RPTR(PrimFloatSpec) PrimSpec::iEEE64 (){
	WPTR(PrimFloatSpec) 	returnValue;
	returnValue = PrimSpec::TheIEEE64Spec;
	return returnValue;
}


INLINE RPTR(PrimIntegerSpec) PrimSpec::int32 (){
	WPTR(PrimIntegerSpec) 	returnValue;
	returnValue = PrimSpec::TheInt32Spec;
	return returnValue;
}


INLINE RPTR(PrimIntegerSpec) PrimSpec::integerVar (){
	WPTR(PrimIntegerSpec) 	returnValue;
	returnValue = PrimSpec::TheIntegerVarSpec;
	return returnValue;
}


INLINE RPTR(PrimPointerSpec) PrimSpec::pointer (){
	/* A spec for pointers to object */
	
	WPTR(PrimPointerSpec) 	returnValue;
	returnValue = PrimSpec::ThePtrSpec;
	return returnValue;
}


INLINE RPTR(PrimPointerSpec) PrimSpec::sharedPointer (){
	WPTR(PrimPointerSpec) 	returnValue;
	returnValue = PrimSpec::TheSharedPtrSpec;
	return returnValue;
}


INLINE RPTR(PrimIntegerSpec) PrimSpec::uInt32 (){
	WPTR(PrimIntegerSpec) 	returnValue;
	returnValue = PrimSpec::TheUInt32Spec;
	return returnValue;
}


INLINE RPTR(PrimIntegerSpec) PrimSpec::uInt8 (){
	WPTR(PrimIntegerSpec) 	returnValue;
	returnValue = PrimSpec::TheUInt8Spec;
	return returnValue;
}
/* private: making */
/* protected: */


INLINE RPTR(Category) PrimSpec::arrayClass (){
	return (Category*) myClass;
}
/* protected: create */
/* making */
/* accessing */
/* testing */



/* ************************************************************************ *
 * 
 *                    Class   PrimFloatSpec 
 *
 * ************************************************************************ */


/* accessing */


INLINE Int32 PrimFloatSpec::bitCount (){
	/* How many total bits per value */
	
	return myBitCount;
}
/* create */
/* testing */
/* private: making */
/* making */



/* ************************************************************************ *
 * 
 *                    Class   PrimIntegerSpec 
 *
 * ************************************************************************ */


/* accessing */


INLINE Int32 PrimIntegerSpec::bitCount (){
	/* How many bits, or zero if it is unlimited */
	
	return myBitCount;
}


INLINE BooleanVar PrimIntegerSpec::isSigned (){
	/* Whether it allows negative values */
	
	return amSigned;
}
/* create */
/* testing */
/* making */


INLINE RPTR(PrimIntValue) PrimIntegerSpec::value (IntegerVar number){
	/* A boxed integer value */
	
	WPTR(PrimIntValue) 	returnValue;
	returnValue = PrimIntValue::make (number);
	return returnValue;
}
/* private: making */



/* ************************************************************************ *
 * 
 *                    Class   PrimPointerSpec 
 *
 * ************************************************************************ */


/* testing */
/* private: making */
/* create */
/* making */



/* ************************************************************************ *
 * 
 *                    Class PrimValue 
 *
 * ************************************************************************ */





/* ************************************************************************ *
 * 
 *                    Class   PrimFloatValue 
 *
 * ************************************************************************ */


/* accessing */



/* ************************************************************************ *
 * 
 *                    Class     PrimIEEE32 
 *
 * ************************************************************************ */


/* create */
/* testing */
/* accessing */
/* protected: create */



/* ************************************************************************ *
 * 
 *                    Class     PrimIEEE64 
 *
 * ************************************************************************ */


/* create */
/* testing */
/* accessing */
/* protected: create */



/* ************************************************************************ *
 * 
 *                    Class   PrimIntValue 
 *
 * ************************************************************************ */


/* create */
/* operations */
/* accessing */


INLINE BooleanVar PrimIntValue::asBooleanVar (){
	/* The value as a BooleanVar. */
	
	return myValue != IntegerVarZero;
}


INLINE Int32 PrimIntValue::asInt32 (){
	/* The value as a 32 bit signed integer */
	
	return myValue.asInt32();
}


INLINE IntegerVar PrimIntValue::asIntegerVar (){
	/* The value as an indefinite precision integer */
	
	return myValue;
}


INLINE UInt32 PrimIntValue::asUInt32 (){
	/* The value as a 32 bit unsigned integer */
	
	return myValue.asUInt32();
}


INLINE UInt8 PrimIntValue::asUInt8 (){
	/* The value as a 8 bit unsigned integer */
	
	return myValue.asUInt32();
}
/* testing */
/* protected: create */
/* printing */


#endif /* PRIMVALX_IXX */

