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

#ifndef PARRAYX_IXX
#define PARRAYX_IXX

/* $Id: parrayx.ixx,v 3.12 1993/04/10 00:53:59 eric Exp $ */


/* ************************************************************************ *
 * 
 *                    Class PrimArray 
 *
 * ************************************************************************ */


/* accessing */

INLINE Int32 PrimArray::count () {
    return myCount;
}

/* protected bounds checking */

INLINE Int32 PrimArray::rangeCheck (Int32 index) {
#if ! (defined(NO_PRIMARRAY_RANGE_CHECK) || defined(PRODUCT))
    if (index < 0 || index >= this->count()) {
	this->outOfBounds();
    }
#endif /* NO_PRIMARRAY_RANGE_CHECK */
    return index;
}

/* protected heap access */

INLINE void * PrimArray::storage () {
    return myStorage;
}

/* private heap management */

INLINE Int32 PrimArray::size () {
    return mySize;
}


/* ************************************************************************ *
 * 
 *                    Class   PrimDataArray 
 *
 * ************************************************************************ */


/* bulk testing */
/* testing */
/* bulk accessing */


/* ************************************************************************ *
 * 
 *                    Class     PrimFloatArray 
 *
 * ************************************************************************ */


/* accessing */
/* testing */
/* bulk accessing */


/* ************************************************************************ *
 * 
 *                    Class       IEEE32Array 
 *
 * ************************************************************************ */


/* accessing */

INLINE void IEEE32Array::storeIEEE32 (Int32 index, IEEE32 value){
    /* Store a floating point value */
    
    ((IEEE32*)this->storage())[this->rangeCheck (index)] = value;
}

INLINE IEEE32 IEEE32Array::iEEE32At (Int32 index){
    /* Get an actual floating point number */

    return ((IEEE32*)this->storage())[this->rangeCheck (index)];
}


/* ************************************************************************ *
 * 
 *                    Class       IEEE64Array 
 *
 * ************************************************************************ */


/* accessing */

INLINE void IEEE64Array::storeIEEE64 (Int32 index, IEEE64 value){
    /* Store a floating point value */
    ((IEEE64*)this->storage())[this->rangeCheck (index)] = value;
}

INLINE IEEE64 IEEE64Array::iEEE64At (Int32 index){
    /* Get an actual floating point number */
    return ((IEEE64*)this->storage())[this->rangeCheck (index)];
}


/* ************************************************************************ *
 * 
 *                    Class     PrimIntegerArray 
 *
 * ************************************************************************ */


/* accessing */
/* testing */
/* bulk accessing */
/* create */


/* ************************************************************************ *
 * 
 *                    Class       Int32Array 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* accessing */

INLINE void Int32Array::storeInt (Int32 index, Int32 value){
    /* Store a 32 bit signed integer value */
    ((Int32*)this->storage())[this->rangeCheck (index)] = value;
}

INLINE Int32 Int32Array::intAt (Int32 index){
    /* Get a 32 bit signed actual integer value */
    return ((Int32*)this->storage())[this->rangeCheck (index)];
}



/* ************************************************************************ *
 * 
 *                    Class       IntegerVarArray 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* accessing */

INLINE void IntegerVarArray::storeIntegerVar (Int32 index, IntegerVar value){
    /* Store an integer value */
    ((IntegerVar*)this->storage())[this->rangeCheck (index)] = value;
}

INLINE IntegerVar IntegerVarArray::integerVarAt (Int32 index){
    /* Get an actual integer value */
    return ((IntegerVar*)this->storage())[this->rangeCheck (index)];
}


/* ************************************************************************ *
 * 
 *                    Class       UInt32Array 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* accessing */

INLINE void UInt32Array::storeUInt (Int32 index, UInt32 value){
    /* Store a 32 bit signed integer value */
    ((UInt32*)this->storage())[this->rangeCheck (index)] = value;
}

INLINE UInt32 UInt32Array::uIntAt (Int32 index){
    /* Get a 32 bit signed actual integer value */
    return ((UInt32*)this->storage())[this->rangeCheck (index)];
}

/* testing */


/* ************************************************************************ *
 * 
 *                    Class       UInt8Array 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* accessing */

INLINE void UInt8Array::storeUInt (Int32 index, UInt32 value){
    /* Store an 8 bit unsigned integer value */
    ((UInt8*)this->storage())[this->rangeCheck (index)] = (UInt8)value;
}

INLINE UInt32 UInt8Array::uIntAt (Int32 index){
    /* Get an 8 bit unsigned actual integer value */
    return ((UInt8*)this->storage())[this->rangeCheck (index)];
}

/* printing */
/* testing */
/* private: accessing */
/* create */


/* ************************************************************************ *
 * 
 *                    Class   PtrArray 
 *
 * ************************************************************************ */


/* accessing */

INLINE RPTR(Heaper) OR(NULL) PtrArray::fetch (Int32 index){
    return ((Heaper**)this->storage())[this->rangeCheck (index)];
}

INLINE RPTR(Heaper) PtrArray::get (Int32 index) {
    WPTR(Heaper) result = this->fetch(index);
    if (result == NULL) {
	PtrArray::nullEntry();
    }
    return result;
}

/* pseudo constructors */
/* bulk testing */
/* testing */
/* create */
/* bulk accessing */
/* accessing */

/* garbage collection and other close friends */

INLINE void PtrArray::unsafeStore (Int32 index, APTR(Heaper) ptr) {
    ((Heaper**)this->storage())[index] = ptr;
}

INLINE RPTR(Heaper) OR(NULL) PtrArray::unsafeFetch (Int32 index){
    return ((Heaper**)this->storage())[index];
}



/* ************************************************************************ *
 * 
 *                    Class     SharedPtrArray 
 *
 * ************************************************************************ */


/* accessing */

INLINE Int4 SharedPtrArray::shareCount () {
	return myShareCount;
}

#endif /* PARRAYX_IXX */
