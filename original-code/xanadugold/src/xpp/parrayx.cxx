 /*Copyright Xanadu Operating Company.  All Rights Reserved. */

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

/* $Id: parrayx.cxx,v 3.25 1993/04/10 00:53:51 eric Exp $ */

#ifndef PARRAYX_CXX
#define PARRAYX_CXX

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef PARRAYX_IXX
#include "parrayx.ixx"
#endif /* PARRAYX_IXX */

#ifndef PARRAYP_HXX
#include "parrayp.hxx"
#endif /* PARRAYP_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef PRIMVALX_HXX
#include "primvalx.hxx"
#endif /* PRIMVALX_HXX */

#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef FHASHX_HXX
#include "fhashx.hxx"
#endif /* FHASHX_HXX */

#include "scavx.hxx"

#include <stdlib.h>
#include <assert.h>

/* ************************************************************************ *
 * 
 *                    Class PrimArray 
 *
 * ************************************************************************ */


/* Array objects in smalltalk vary in size, while in x++ they 
allocate separate storage for the varying part.  Thus they require 
very different Recipes.

Recipes are normally registered by the class' associated Recipe class 
at its own initialization time.  In smalltalk, the Array classes 
share a common Recipe class, (STArrayRecipe), which registers an 
instance of itself for each appropriate concrete subclass of PrimArray.X.

(WeakPtrArrays are not in the browser because they currently have no 
clients and may disappear.) */

Int32 PrimArray::OurGutsCount = 0;

/* accessing */

RPTR(Heaper) PrimArray::getValue (Int32 index) {
    SPTR(Heaper) result;

    result = this->fetchValue (index);
    if (result == NULL) {
	BLAST(NotInTable);
    }
    return result;
}

/* testing */

UInt32 PrimArray::contentsHash (){
    /* A hash of the entire contents of the array. If two arrays 
    are contentsEqual, they will have the same contentsHash. */

    return this->elementsHash();
}

/* bulk accessing */

void PrimArray::storeMany (Int32 to,
			   APTR(PrimArray) source,
			   Int32 count/* = -1*/,
			   Int32 from/* = Int32Zero*/)
{
    /* Copy n elements from the other array into this one. The 
    other array must be of a compatible type. */

    Int32 n;

    if (count < 0) {
	n = source->count() - from;
    } else {
	n = count;
    }
    if (to + n > this->count() || from + n > source->count()) {
	BLAST(IndexOutOfBounds);
    }
    this->copyElements (to, source, from, n);
}

RPTR(PrimArray) PrimArray::copy (Int32 count /*= -1*/,
				 Int32 start /*= Int32Zero*/,
				 Int32 before /*= Int32Zero*/,
				 Int32 after /*= Int32Zero*/)
{

    Int32 copyCount;

    if (count < 0) {
	copyCount = this->count() - start;
    } else {
	copyCount = count;
	if (start + copyCount > this->count()) {
	    BLAST(IndexOutOfBounds);
	}
    }
    return this->makeNew (copyCount+before+after, this, start, copyCount, before);
}

RPTR(PrimArray) PrimArray::copyGrow (Int32 after) {
    return this->copy(this->count(), 0, 0, after);
}

Int32 PrimArray::indexOfElements (APTR(PrimArray) source, 
				  Int32 valueCount/* = -1*/, 
				  Int32 valueStart/* = Int32Zero*/, 
				  Int32 start/* = Int32Zero*/, 
				  Int32 nth/* = 1*/)
{
    /* The index of the nth occurrence of the given sequence of 
    values at or after (before if n is negative) the given 
    starting index, or -1 if there is none. Negative numbers for 
    start are relative to the end of the array. */

    Int32 valueN;
    Int32 result;
    Int32 n;
    BooleanVar forward;

    if (this->count() == 0 || nth == 0) {
	return -1;
    }
    if (valueCount < 0) {
	valueN = source->count();
    } else {
	if (valueCount > source->count()) {
	    BLAST(IndexOutOfBounds);
	}
	valueN = valueCount;
    }
    if (start >= 0) {
	result = start;
    } else {
	result = this->count() + start;
    }
    n = nth < 0 ? -nth : nth;
    forward = nth > 0;
    for ( ; ; ) {
	{
	    if (forward ? (result > this->count()) - valueN : result < 0) {
		return -1;
	    }
	    if (this->elementsEqual(result, source, valueStart, valueN)) {
		n -= 1;
		if (n == 0) {
		    return result;
		}
	    }
	    if (forward) {
		result += 1;
	    } else {
		result -= 1;
	    }
	}
    }
}

Int32 PrimArray::indexPast (APTR(Heaper) value,
			    Int32 start/* = Int32Zero*/,
			    Int32 n/* = 1*/)
{
    /* The index of the nth occurrence of anything but the given 
    value at or after (before if n is negative) the given index, 
    or -1 if there is none. */
Int32 i;
Int32 idx;
    for (idx = start, i = 0; i < n && idx < this->count(); idx++) {
	WPTR(Heaper) ptr = this->fetchValue(idx);
	if (ptr != NULL && ! ptr->isEqual(value)) {
	    i++;
	}
    }
    return i > 0 ? idx : -1;
}

/* printing */

void PrimArray::printOn (ostream& oo){
    char * before;

    before = "[";
    if (this->count() == 0) {
	oo << "[empty";
    } else {
	for (Int32 i = 0; i < this->count(); i += 1) {
	    oo << before;
	    this->printElementOn (i, oo);
	    before = " ";
	}
    }
    oo << "]";
}

/* create */

/* we get the datum size all the way up here so that the caller does not
   have to repeat whatever calculation went into newCount */
PrimArray::PrimArray (Int32 newCount, Int32 datumSize) {
    //assert(PrimArray::OurGutsCount == 0);// zzz reg for allowing the debugger to do guts of
    myCount = newCount;
    if (myCount) {
	mySize  = alignUp (newCount * datumSize) / sizeof(Int32);
	myStorage = PrimArrayHeap::getStorage (mySize, this);
    } else {
	mySize = 0;
	myStorage = NULL;
    }
}

/* destruction */

PrimArray::~PrimArray () {
    /* PrimArray internal storage is not recovered at GC.  It is recovered at
        compact time.  Note that a SanitationEngineer to recover space at GC
        time will not work, since SEs run before the GC, and we get back more
        space compacting after a GC. */
    /* These two lines assures that access to destructed PrimArrays will crash */
    mySize = -1;
    myStorage = NULL;
}

/* hooks */

void PrimArray::receivePrimArray (APTR(Rcvr)) {
    //assert(PrimArray::OurGutsCount == 0);// zzz reg for allowing the debugger to do guts of
    if (myCount) {
	myStorage = PrimArrayHeap::getStorage (mySize, this);
    } else {
	myStorage = NULL;
    }
}

/* helper functions */

void PrimArray::zeroElements (Int32 from, Int32 count)
{
    Int32 n = count;

    if (n < 0) {
	n = this->count();
    }
    if (n+from > this->count()) {
	BLAST(TOO_MANY_ZEROS);
    }
    if (from < 0) {
	BLAST(BogusStartIndex);
    }
    memset (myStorage + from, 0, (int) n * sizeof(Int32));
}

void PrimArray::copyElements (Int32 to, 
			      APTR(PrimArray) source,
			      Int32 from,
			      Int32 count)
{
    Int32 n = count;
    if (n == -1) {
	n = source->count() - from;
    }
    if (n < 0 || to < 0 || from < 0 || from+n > source->count() || to+n > this->count()) {
	BLAST(CopyOutOfBounds);
    }
    if (this->getCategory() == source->getCategory()) {
	/* we can hold the source storage pointer since this is atomic */
	Int32 * sourceBits = ((Int32*)source->storage()) + from;
	Int32 * destBits = myStorage + to;
	MEMMOVE (destBits, sourceBits, (int) (n * sizeof(Int32)));
    } else {
	/* since the types aren''t the same, we have to do it the hard way */
	for (Int32 i = 0; i < n; i += 1) {
	    this->storeValue (to + i, source->fetchValue(from + i));
	}
    }
}

/* private error */

void PrimArray::outOfBounds () {
    BLAST(IndexOutOfBounds);
}

/* used in compaction */
static debugingPrintChar = 'a';
void PrimArray::moveTo (Int32 * newLoc) {
    MEMMOVE (newLoc, myStorage, (int) (mySize * sizeof(Int32)));
memset((char *) myStorage,debugingPrintChar,(int) (mySize * sizeof(Int32)));
debugingPrintChar +=1;
if(debugingPrintChar <0 || debugingPrintChar >127){
debugingPrintChar = 'a';
}
    myStorage = newLoc;
}

/* used by GC */

void PrimArray::cleanup () {
    PrimArrayHeap::cleanup ();
}


/* ************************************************************************ *
 * 
 *                    Class   PrimDataArray 
 *
 * ************************************************************************ */


/* A common superclass for primitive arrays of basic data types (i.e. 
   bits of some kind) */

/* testing */

BooleanVar PrimDataArray::contentsEqual (PrimArray * other){
    if (this->count() != other->count()) {
	return FALSE;
    }
    return this->compareData (0, CAST(PrimDataArray,other),
			      0, this->count())
    		== 0;
}

/* bulk accessing */

void PrimDataArray::addElements (Int32 to,
				 APTR(PrimDataArray) other,
				 Int32 count/* = -1*/,
				 Int32 from/* = Int32Zero*/)
{
    Int32 n;

    n = min(other->count() - from, this->count() - to);
    if (count > n) {
	BLAST(IndexOutOfBounds);
    }
    if (count >= 0) {
	n = count;
    }
    this->addData (to, other, from, n);
}


void PrimDataArray::subtractElements (Int32 to,
					APTR(PrimDataArray) other,
					Int32 count/* = -1*/,
					Int32 from/* = Int32Zero*/)
{
    Int32 n;

    n = min(other->count() - from, this->count() - to);
    if (count > n) {
	BLAST(IndexOutOfBounds);
    }
    if (count >= 0) {
	n = count;
    }
    this->subtractData (to, other, from, n);
}

/* bulk testing */

Int32 PrimDataArray::compare (APTR(PrimDataArray) other,
			      Int32 count/* = -1*/,
			      UInt32 here/* = Int32Zero*/,
			      Int32 there/* = Int32Zero*/)
{
    /* Return -1, 0, or +1 according to whether the elements in 
    the specified span of this array are lexically less than, 
    equal to, or greater than the specified span of the other. 
    The other array must be of a compatible type. If the count is 
    negative or goes beyond the end of either array, then the 
    shorter array is considered to be extended with zeros.
    NOTE: Because of zero extension, this is not the same as 
    elementsEqual; it is possible that a->compare (b) == 0 even 
    though ! a->contentsEqual (b) */

    Int32 n;
    SPTR(PrimDataArray) longer;
    Int32 index;
    Int32 cmp;

    n = min(other->count() - there, this->count() - here);
    if (count >= 0 && count < n) {
	n = count;
    }
    cmp = this->compareData (here, other, there, n);
    if (cmp != 0) {
	return cmp < 0 ? -1 : 1;
    }

    /* past the end. check if a count was specified or if they 
    are the same length */
    if (count == n || (other->count() - there) == (this->count() -(Int32) here)) {
	return 0;
    }
    /* figure out which is longer and look for a nonzero element */
    if (n == other->count() - there) {
	longer = this;
	index = here + n;
    } else {
	longer = other;
	index = there + n;
    }
    if (count >= 0) {
	n = min(count - n + index, longer->count());
    } else {
	n = longer->count();
    }
    Int32 sign = longer->signOfNonZeroAfter (index);
    return longer == this ? sign : -sign;
}

BooleanVar PrimDataArray::elementsEqual (Int32 here,
					 APTR(PrimArray) other,
					 Int32 there/* = Int32Zero*/,
					 Int32 count/* = -1*/)
{
    Int32 n;

    n = min(other->count() - there, this->count() - here);
    if (count > n) {
	BLAST(IndexOutOfBounds);
    }
    if (count >= 0) {
	n = count;
    }
    return this->compareData (here, CAST(PrimDataArray,other),
			      there, n) == 0;
}

/* create -- just to pass up to PrimArray */

PrimDataArray::PrimDataArray (Int32 count, Int32 datumSize)
    : PrimArray (count, datumSize)
{}

/* helper functions */

Int32 PrimDataArray::compareData (Int32 /*start*/, 
				  APTR(PrimDataArray) /*other*/,
				  Int32 /*otherStart*/,
				  Int32 /*count*/)
{
    BLAST(NOT_YET_IMPLEMENTED); /* not yet well defined here */
    return 0;
}

void PrimDataArray::addData (Int32 /*start*/,
			     APTR(PrimDataArray) /*other*/,
			     Int32 /*otherStart*/,
			     Int32 /*count*/)
{
    BLAST(NOT_YET_IMPLEMENTED); /* not yet well defined here */
}

void PrimDataArray::subtractData (Int32 /*start*/,
				  APTR(PrimDataArray) /*other*/,
				  Int32 /*otherStart*/,
				  Int32 /*count*/)
{
    BLAST(NOT_YET_IMPLEMENTED); /* not yet well defined here */
}


/* ************************************************************************ *
 * 
 *                    Class     PrimFloatArray 
 *
 * ************************************************************************ */

RPTR(PrimFloatArray) PrimFloatArray::zeros (Int32 bitCount, Int32 count)
{
    if (bitCount == 64) {
	return IEEE64Array::make (count);
    }
    if (bitCount == 32) {
	return IEEE32Array::make (count);
    }
    BLAST(UnimplementedPrecision);
    return NULL;
}



/* testing */

UInt32 PrimFloatArray::elementsHash (Int32 count/* = -1*/,
				     Int32 /*start*//* = Int32Zero*/)
{
    /* make this actually do something !!!! */
    return this->getCategory()->hashForEqual() ^ ::fastHash(count);
}

/* bulk accessing */
Int32 PrimFloatArray::indexOf (APTR(Heaper) value, 
			       Int32 start/* = Int32Zero*/,
			       Int32 nth/* = 1*/)
{
    if (this->count() == 0 || nth == 0) {
	return -1;
    }
    if (start < 0) {
	start = this->count () + start;
    }
    if (start < 0 || start >= this->count ()) {
	BLAST(IndexOutOfBounds);
    }

    IEEE64 x = CAST(PrimFloatValue,value)->asIEEE64();

    if (nth >= 0) {
	for (Int32 idx = start; idx < this->count(); idx++) {
	    if (this->floatAt(idx) == x) {
		nth--;
		if (nth == 0) {
		    return idx;
		}
	    }
	}
    } else {
	for (Int32 idx = start; idx >= 0; idx--) {
	    if (this->floatAt(idx) == x) {
		nth++;
		if (nth == 0) {
		    return idx;
		}
	    }
	}
    }
    return -1;
}

Int32 PrimFloatArray::indexPast (APTR(Heaper) value, 
				 Int32 start/* = Int32Zero*/,
				 Int32 nth/* = 1*/)
{
    if (this->count() == 0 || nth == 0) {
	return -1;
    }
    if (start < 0) {
	start = this->count () + start;
    }
    if (start < 0 || start >= this->count ()) {
	BLAST(IndexOutOfBounds);
    }

    IEEE64 x = CAST(PrimFloatValue,value)->asIEEE64();

    if (nth >= 0) {
	for (Int32 idx = start; idx < this->count(); idx++) {
	    if (this->floatAt(idx) != x) {
		nth--;
		if (nth == 0) {
		    return idx;
		}
	    }
	}
    } else {
	for (Int32 idx = start; idx >= 0; idx--) {
	    if (this->floatAt(idx) != x) {
		nth++;
		if (nth == 0) {
		    return idx;
		}
	    }
	}
    }
    return -1;
}


/* create -- just to pass up to PrimArray */

PrimFloatArray::PrimFloatArray (Int32 count, Int32 datumSize)
    : PrimDataArray (count, datumSize)
{}

/* helper functions */

Int32 PrimFloatArray::compareData (Int32 start, 
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(PrimFloatArray,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		IEEE64 cmp;
		cmp = this->floatAt(i + start) - o->floatAt(i + otherStart);
		if (cmp != 0.0) {
		    return ((Int32) cmp) < 0 ? -1 : 1;
		}
	    }
	    return 0;
	} END_KIND;
	BEGIN_OTHERS {
	    return this->PrimDataArray::compareData (start, other, otherStart,
						     count);
	} END_OTHERS;
    } END_CHOOSE;
    return 0;
}

void PrimFloatArray::addData (Int32 start, 
			      APTR(PrimDataArray) other,
			      Int32 otherStart,
			      Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(PrimFloatArray,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		this->storeFloat (i + start,
				  this->floatAt(i + start) 
				   + o->floatAt(i + otherStart));
	    }
	} END_KIND;
	BEGIN_OTHERS {
	    this->PrimDataArray::addData (start, other, otherStart, count);
	} END_OTHERS;
    } END_CHOOSE;
}

void PrimFloatArray::subtractData (Int32 start, 
				   APTR(PrimDataArray) other,
				   Int32 otherStart,
				   Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(PrimFloatArray,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		this->storeFloat (i + start,
				  this->floatAt(i + start) 
				  - o->floatAt(i + otherStart));
	    }
	} END_KIND;
	BEGIN_OTHERS {
	    this->PrimDataArray::subtractData (start, other, otherStart,
					       count);
	} END_OTHERS;
    } END_CHOOSE;
}


/* ************************************************************************ *
 * 
 *                    Class       IEEE32Array 
 *
 * ************************************************************************ */


/* pseudo constructors */

RPTR(IEEE32Array) IEEE32Array::make (Int32 count) {
    RETURN_CONSTRUCT(IEEE32Array,(count,tcsj));
}

RPTR(IEEE32Array) IEEE32Array::make (Int32 size,
				     APTR(PrimArray) from, 
				     Int32 sourceOffset, 
				     Int32 count, 
				     Int32 destOffset)
{
    RETURN_CONSTRUCT(IEEE32Array,(size, from, sourceOffset, count, destOffset));
}

RPTR(IEEE32Array) IEEE32Array::make (Int32 count, void * buffer) {
    RETURN_CONSTRUCT(IEEE32Array,(count,buffer));
}

/* accessing */

Int32 IEEE32Array::bitCount () {
    /* Return the maximum bits/entry that can be stored in this array */

    return 32;
}

void IEEE32Array::storeFloat (Int32 index, IEEE64 value){
    /* Store a floating point value */

    this->storeIEEE32(index, value);
}

IEEE64 IEEE32Array::floatAt (Int32 index){
    /* Get an actual floating point number */

    return (IEEE64) this->iEEE32At(index);
}

void IEEE32Array::storeValue (Int32 index, APTR(Heaper) OR(NULL) value){
    if (value == NULL) {
	BLAST(NULL_VALUE);
    }
    this->storeIEEE32(index, CAST(PrimFloatValue,value)->asIEEE32());
}

RPTR(Heaper) OR(NULL) IEEE32Array::fetchValue (Int32 index) {
    return PrimIEEE32::make(this->iEEE32At(index));
}

RPTR(PrimSpec) IEEE32Array::spec (){
	return PrimSpec::iEEE32();
}

/* bulk accessing */

void IEEE32Array::storeAll (APTR(Heaper) value/* = NULL*/, 
			    Int32 count/* = -1*/,
			    Int32 start/* = Int32Zero*/)
{
    IEEE64 f;
    Int32 n;

    n = this->count() - start;
    if (count > n) {
	BLAST(IndexOutOfBounds);
    }
    if (count >= 0) {
	n = count;
    }
    if (value == NULL) {
	f = 0.0;
    } else {
	f = CAST(PrimFloatValue,value)->asIEEE32();
    }
    for (Int32 i = 0; i < n; i += 1) {
	this->storeIEEE32(start + i, f);
    }
}

void IEEE32Array::copyToBuffer (void * buffer,
				Int32 size,
				Int32 count /*= -1*/,
				Int32 start /* = Int32Zero*/)
{
    Int32 bufSize;
    Int32 n;

    bufSize = size / sizeof(IEEE32);
    if (count >= 0) {
	n = count;
    } else {
	n = this->count() - start;
    }
    if (n > bufSize) {
	n = bufSize;
    }
    MEMMOVE (buffer, (IEEE32*)this->storage() + start,
	     (int)(n * sizeof(IEEE32)));
}

/* create */

IEEE32Array::IEEE32Array (Int32 count, TCSJ)
    : PrimFloatArray (count, sizeof(IEEE32))
{
    this->zeroElements (0, count);
}

IEEE32Array::IEEE32Array (Int32 size, 
			  APTR(PrimArray) from, 
			  Int32 sourceOffset, 
			  Int32 count, 
			  Int32 destOffset) 
    : PrimFloatArray (size, sizeof(IEEE32))
{
    if (count == -1) {
	count = from->count() - sourceOffset;
    }
    this->zeroElements (0, destOffset);
    this->copyElements (destOffset, from, sourceOffset, count);
    this->zeroElements (destOffset + count, size - destOffset - count);
}

IEEE32Array::IEEE32Array (Int32 count, void * buffer)
    : PrimFloatArray (count, sizeof(IEEE32))
{
    MEMMOVE (this->storage(), buffer, (int) (count * sizeof(IEEE32)));
}

/* helper functions */

Int32 IEEE32Array::compareData (Int32 start, 
				APTR(PrimDataArray) other,
				Int32 otherStart,
				Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(IEEE32Array, o) {
	    for (Int32 i = 0; i < count; i += 1) {
		IEEE32 cmp;
		cmp = this->iEEE32At(i + start) - o->iEEE32At(i + otherStart);
		if (cmp != 0.0) {
		    return ((Int32) cmp) < 0 ? -1 : 1;
		}
	    }
	    return 0;
	} END_KIND;
	BEGIN_OTHERS {
	    return this->PrimFloatArray::compareData (start, other,
						      otherStart, count);
	} END_OTHERS;
    } END_CHOOSE;
    return 0;
}

Int32 IEEE32Array::signOfNonZeroAfter (Int32 index) {
    for (Int32 i = index; i < this->count(); i += 1) {
	IEEE32 val;
	
	if ((val = this->iEEE32At(i)) < 0.0) {
	    return -1;
	}
	if (val > 0.0) {
	    return +1;
	}
    }
    return 0;
}

void IEEE32Array::addData (Int32 start, 
			   APTR(PrimDataArray) other,
			   Int32 otherStart,
			   Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(IEEE32Array,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		this->storeIEEE32 (i + start,
				   this->iEEE32At(i + start) 
				   + o->iEEE32At(i + otherStart));
	    }
	} END_KIND;
	BEGIN_OTHERS {
	    this->PrimFloatArray::addData (start, other, otherStart, count);
	} END_OTHERS;
    } END_CHOOSE;
}

void IEEE32Array::subtractData (Int32 start, 
				APTR(PrimDataArray) other,
				Int32 otherStart,
				Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(IEEE32Array,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		this->storeIEEE32 (i + start,
				   this->iEEE32At(i + start) 
				   - o->iEEE32At(i + otherStart));
	    }
	} END_KIND;
	BEGIN_OTHERS {
	    this->PrimFloatArray::subtractData (start, other, otherStart,
						count);
	} END_OTHERS;
    } END_CHOOSE;
}

void IEEE32Array::printElementOn (Int32 index, ostream& oo)
{
    oo << this->iEEE32At (index);
}

RPTR(PrimArray) IEEE32Array::makeNew (Int32 size,
				      APTR(PrimArray) source,
				      Int32 sourceOffset,
				      Int32 count,
				      Int32 destOffset)
{
    return IEEE32Array::make (size, CAST(PrimFloatArray,source),
			      sourceOffset, count, destOffset);
}


/* ************************************************************************ *
 * 
 *                    Class       IEEE64Array 
 *
 * ************************************************************************ */


/* pseudo constructors */

RPTR(IEEE64Array) IEEE64Array::make (Int32 count) {
    RETURN_CONSTRUCT(IEEE64Array,(count,tcsj));
}

RPTR(IEEE64Array) IEEE64Array::make (Int32 size,
				     APTR(PrimArray) from, 
				     Int32 sourceOffset, 
				     Int32 count, 
				     Int32 destOffset)
{
    RETURN_CONSTRUCT(IEEE64Array,(size, from, sourceOffset, count, destOffset));
}

RPTR(IEEE64Array) IEEE64Array::make (Int32 count, void * buffer) {
    RETURN_CONSTRUCT(IEEE64Array,(count,buffer));
}

/* accessing */

Int32 IEEE64Array::bitCount () {
    /* Return the maximum bits/entry that can be stored in this array */

    return 64;
}

void IEEE64Array::storeFloat (Int32 index, IEEE64 value){
    /* Store a floating point value */

    this->storeIEEE64(index, value);
}

IEEE64 IEEE64Array::floatAt (Int32 index){
    /* Get an actual floating point number */

    return this->iEEE64At(index);
}

void IEEE64Array::storeValue (Int32 index, APTR(Heaper) OR(NULL) value){
    if (value == NULL) {
	BLAST(NULL_VALUE);
    }
    this->storeIEEE64(index, CAST(PrimFloatValue,value)->asIEEE64());
}

RPTR(Heaper) OR(NULL) IEEE64Array::fetchValue (Int32 index) {
    return PrimIEEE64::make(this->iEEE64At(index));
}

RPTR(PrimSpec) IEEE64Array::spec (){
    return PrimSpec::iEEE64();
}

/* bulk accessing */

void IEEE64Array::storeAll (APTR(Heaper) value/* = NULL*/,
			    Int32 count/* = -1*/,
			    Int32 start/* = Int32Zero*/)
{
    IEEE64 f;
    Int32 n;

    n = this->count() - start;
    if (count > n) {
	BLAST(IndexOutOfBounds);
    }
    if (count >= 0) {
	n = count;
    }
    if (value == NULL) {
	f = 0.0;
    } else {
	f = CAST(PrimFloatValue,value)->asIEEE64();
    }
    for (Int32 i = 0; i < n; i += 1) {
	this->storeIEEE64(start + i, f);
    }
}

void IEEE64Array::copyToBuffer (void * buffer,
				Int32 size,
				Int32 count /*= -1*/,
				Int32 start /* = Int32Zero*/)
{
    Int32 bufSize;
    Int32 n;

    bufSize = size / sizeof(IEEE64);
    if (count >= 0) {
	n = count;
    } else {
	n = this->count() - start;
    }
    if (n > bufSize) {
	n = bufSize;
    }
    MEMMOVE (buffer, (IEEE64*)this->storage() + start,
	     (int)(n * sizeof(IEEE64)));
}

/* create */

IEEE64Array::IEEE64Array (Int32 count, TCSJ)
    : PrimFloatArray (count, sizeof(IEEE64))
{
    this->zeroElements (0, count);
}


IEEE64Array::IEEE64Array (Int32 size, 
			  APTR(PrimArray) from, 
			  Int32 sourceOffset, 
			  Int32 count, 
			  Int32 destOffset)
    : PrimFloatArray (size, sizeof(IEEE64))
{
    if (count == -1) {
	count = from->count() - sourceOffset;
    }
    this->zeroElements (0, destOffset);
    this->copyElements (destOffset, from, sourceOffset, count);
    this->zeroElements (destOffset + count, size - destOffset - count);
}

IEEE64Array::IEEE64Array (Int32 count, void * buffer)
    : PrimFloatArray (count, sizeof(IEEE64))
{
    MEMMOVE (this->storage(), buffer, (int)(count * sizeof(IEEE64)));
}

/* helper functions */

Int32 IEEE64Array::compareData (Int32 start, 
				APTR(PrimDataArray) other,
				Int32 otherStart,
				Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(IEEE64Array,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		IEEE64 cmp;
		cmp = this->iEEE64At(i + start) - o->iEEE64At(i + otherStart);
		if (cmp != 0.0) {
		    return ((Int32) cmp) < 0 ? -1 : 1;
		}
	    }
	    return 0;
	} END_KIND;
	BEGIN_OTHERS {
	    return this->PrimFloatArray::compareData (start, other,
						      otherStart, count);
	} END_OTHERS;
    } END_CHOOSE;
    return 0;
}

Int32 IEEE64Array::signOfNonZeroAfter (Int32 index) {
    for (Int32 i = index; i < this->count(); i += 1) {
	IEEE64 val;
	
	if ((val = this->iEEE64At(i)) < 0.0) {
	    return -1;
	}
	if (val > 0.0) {
	    return +1;
	}
    }
    return 0;
}

void IEEE64Array::addData (Int32 start, 
			   APTR(PrimDataArray) other,
			   Int32 otherStart,
			   Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(IEEE64Array,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		this->storeIEEE64 (i + start,
				   this->iEEE64At(i + start) 
				   + o->iEEE64At(i + otherStart));
	    }
	} END_KIND;
	BEGIN_OTHERS {
	    this->PrimFloatArray::addData (start, other, otherStart, count);
	} END_OTHERS;
    } END_CHOOSE;
}

void IEEE64Array::subtractData (Int32 start, 
				APTR(PrimDataArray) other,
				Int32 otherStart,
				Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(IEEE64Array,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		this->storeIEEE64 (i + start,
				   this->iEEE64At(i + start) 
				   - o->iEEE64At(i + otherStart));
	    }
	} END_KIND;
	BEGIN_OTHERS {
	    this->PrimFloatArray::subtractData (start, other, otherStart,
						count);
	} END_OTHERS;
    } END_CHOOSE;
}

void IEEE64Array::printElementOn (Int32 index, ostream& oo)
{
    oo << this->iEEE64At (index);
}

void IEEE64Array::zeroElements (Int32 from, Int32 count)
{
    Int32 n = count;
    if (n < 0) {
	n = this->count();
    }
    if (n+from > this->count()) {
	BLAST(TOO_MANY_ZEROS);
    }
    if (from < 0) {
	BLAST(BogusStartIndex);
    }
    memset ((IEEE64*)this->storage()+from, 0, (int)(n * sizeof(IEEE64)));
}

void IEEE64Array::copyElements (Int32 to, 
				APTR(PrimArray) source,
				Int32 from,
				Int32 count)
{
    Int32 n = count;
    if (n == -1) {
	n = source->count() - from;
    }
    /* we can hold the source storage pointer since this is atomic */
    IEEE64 * sourceBits = ((IEEE64*)CAST(IEEE64Array,source)->storage()) +from;
    IEEE64 * destBits = ((IEEE64*)this->storage()) + to;
    MEMMOVE (destBits, sourceBits, (int) (n * sizeof(IEEE64)));
}

RPTR(PrimArray) IEEE64Array::makeNew (Int32 size,
				      APTR(PrimArray) source,
				      Int32 sourceOffset,
				      Int32 count,
				      Int32 destOffset)
{
    return IEEE64Array::make (size, CAST(PrimFloatArray,source),
			      sourceOffset, count, destOffset);
}


/* ************************************************************************ *
 * 
 *                    Class     PrimIntegerArray 
 *
 * ************************************************************************ */


/* A common superclass for primitive arrays of integer types; this is 
the point to add bulk operations for Boolean operations, etc if we 
ever want them */

/* accessing */

RPTR(PrimIntegerArray) PrimIntegerArray::hold (Int32 index,
					       IntegerVar value,
					       BooleanVar canModify/* = FALSE*/)
{
    /* Store a new value into the array at the given index. If 
    the value does not fit into the range that can be stored 
    here, return an array of a kind that will accept it. If the 
    index is past the end, return a larger array.
    If canModify, then returns a newly created array only if the 
    value will not fit into this one, otherwise will always 
    return a new array. */

    SPTR(PrimArray) result;

    if (index < 0) {
	BLAST(IndexOutOfBounds);
    }
    if (index >= this->count()) {
	if (CAST(PrimIntegerSpec,this->spec())->canHold(value)) {
	    result = this->spec()->copyGrow(this, index + 1 - this->count());
	} else {
	    result = PrimSpec::toHold(value)->copyGrow(this, index + 1 - this->count());
	}
    } else {
	if (CAST(PrimIntegerSpec,this->spec())->canHold(value)) {
	    if (canModify) {
		result = this;
	    } else {
		result = this->copy();
	    }
	} else {
	    result = PrimSpec::toHold(value)->copy(this);
	}
    }
    CAST(PrimIntegerArray,result)->storeInteger(index, value);
    return CAST(PrimIntegerArray,result);
}

/* testing */

UInt32 PrimIntegerArray::elementsHash (Int32 count/* = -1*/,
				       Int32 start/* = Int32Zero*/)
{
    Int32 n;

    n = this->count() - start;
    if (count > n) {
	BLAST(IndexOutOfBounds);
    }
    if (count >= 0) {
	n = count;
    }
    if (n == 0) {
	return ::fastHash(17);
    } else {
	if (n == 1) {
	    return ::fastHash(this->integerAt(0).asLong());
	} else {
	    /* I keep the &65565s here for compatibility with Smalltalk */
	    return
	      ::fastHash(n) 
	      ^ ::fastHash(this->integerAt(start).asLong() & 65535)
	      ^ ::fastHash(this->integerAt(start + n - 1).asLong() & 65535);
	}
    }
}

/* bulk accessing */

Int32 PrimIntegerArray::indexOf (APTR(Heaper) value,
				 Int32 start/* = Int32Zero*/,
				 Int32 n/* = 1*/)
{
    return this->indexOfInteger (CAST(PrimIntValue,value)->asIntegerVar(),
				 start, n);
}

Int32 PrimIntegerArray::indexOfInteger (IntegerVar value, 
					Int32 start/* = Int32Zero*/,
					Int32 nth/* = 1*/)
{
    if (this->count() == 0 || nth == 0) {
	return -1;
    }
    if (start < 0) {
	start = this->count () + start;
    }
    if (start < 0 || start >= this->count ()) {
	BLAST(IndexOutOfBounds);
    }

    if (nth >= 0) {
	for (Int32 idx = start; idx < this->count(); idx++) {
	    if (this->integerAt(idx) == value) {
		nth--;
		if (nth == 0) {
		    return idx;
		}
	    }
	}
    } else {
	for (Int32 idx = start; idx >= 0; idx--) {
	    if (this->integerAt(idx) == value) {
		nth++;
		if (nth == 0) {
		    return idx;
		}
	    }
	}
    }
    return -1;
}




Int32 PrimIntegerArray::indexPast (APTR(Heaper) value,
				   Int32 start/* = Int32Zero*/,
				   Int32 n/* = 1*/)
{
    return this->indexPastInteger (CAST(PrimIntValue,value)->asIntegerVar(),
				   start, n);
}


Int32 PrimIntegerArray::indexPastInteger (IntegerVar value, 
			       Int32 start/* = Int32Zero*/,
			       Int32 nth/* = 1*/)
{
    Int32 result;
    Int32 n;

    if (this->count() == 0 || nth == 0) {
	return -1;
    }
    if (start < 0) {
	result = this->count () + start;
    } else {
	result = start;
    }
    if (result < 0 || result >= this->count ()) {
	BLAST(IndexOutOfBounds);
    }

    if (nth >= 0) {
	n = nth;
	do {
	    if (value != this->integerAt(result)) {
		n = n - 1;
		if (n == 0) {
		    return result;
		}
	    }
	    result = result + 1;
	} while (result < this->count());
	return -1;
    } else {
	n = nth;
	do {
	    if (value != this->integerAt(result)) {
		n = n + 1;
		if (n == 0) {
		    return result;
		}
	    }
	    result = result - 1;
	} while (result > 0);
	return -1;
    }
}

void PrimIntegerArray::storeAll (APTR(Heaper) value/* = NULL*/, 
				 Int32 count/* = -1*/,
				 Int32 start/* = Int32Zero*/)
{
    IntegerVar k;
    Int32 n;

    n = this->count() - start;
    if (count > n) {
	BLAST(IndexOutOfBounds);
    }
    if (count >= 0) {
	n = count;
    }
    if (value == NULL) {
	k = 0;
    } else {
	k = CAST(PrimIntValue,value)->asIntegerVar();
    }
    for (Int32 i = 0; i < n; i += 1) {
	this->storeInteger(start + i, k);
    }
}

/* create -- just to pass up to PrimArray */

PrimIntegerArray::PrimIntegerArray (Int32 count, Int32 datumSize)
    : PrimDataArray (count, datumSize)
{}

/* helper functions */

Int32 PrimIntegerArray::compareData (Int32 here, 
				     APTR(PrimDataArray) other,
				     Int32 there,
				     Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(PrimIntegerArray,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		IntegerVar a, b;
		a = this->integerAt(here + i);
		b = o->integerAt(there + i);
		if (a < b) {
		    return -1;
		}
		if (a > b) {
		    return 1;
		}
	    }
	    return 0;
	} END_KIND;
	BEGIN_OTHERS {
	    return this->PrimDataArray::compareData (here, other, there,
						     count);
	} END_OTHERS;
    } END_CHOOSE;
    return 0;
}

void PrimIntegerArray::addData (Int32 start, 
				APTR(PrimDataArray) other,
				Int32 otherStart,
				Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(PrimIntegerArray,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		IntegerVar sum;
		sum = this->integerAt(i + start)
		      + o->integerAt(i + otherStart);
		this->storeInteger (i + start, sum);
	    }
	} END_KIND;
	BEGIN_OTHERS {
	    this->PrimDataArray::addData (start, other, otherStart, count);
	} END_OTHERS;
    } END_CHOOSE;
}

void PrimIntegerArray::subtractData (Int32 start, 
				     APTR(PrimDataArray) other,
				     Int32 otherStart,
				     Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(PrimIntegerArray,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		IntegerVar sum;
		sum = this->integerAt(i + start)
		      - o->integerAt(i + otherStart);
		this->storeInteger (i + start, sum);
	    }
	} END_KIND;
	BEGIN_OTHERS {
	    this->PrimDataArray::subtractData (start, other, otherStart,
					       count);
	} END_OTHERS;
    } END_CHOOSE;
}


/* ************************************************************************ *
 * 
 *                    Class       PrimIntArray 
 *
 * ************************************************************************ */


/* pseudo constructors */

RPTR(PrimIntArray) PrimIntArray::zeros (IntegerVar numBits,
					IntegerVar count)
{
    /* Make an array initialized to zero values. The values are
       signed if numBits is negative. */

    if (numBits == 8) {
	return UInt8Array::make (count.asInt32());
    }
    if (numBits == 32) {
	return UInt32Array::make (count.asInt32());
    }
    if (numBits == -32) {
	return Int32Array::make (count.asInt32());
    }
    BLAST(UnimplementedPrecision);
    /* compiler fodder */
    return NULL;
}
 
/* create -- just to pass up to PrimIntegerArray */
 
PrimIntArray::PrimIntArray (Int32 count, Int32 datumSize)
    : PrimIntegerArray (count, datumSize)
{}


/* ************************************************************************ *
 * 
 *                    Class       Int32Array 
 *
 * ************************************************************************ */


/* pseudo constructors */

RPTR(Int32Array) Int32Array::make (Int32 count) {
    RETURN_CONSTRUCT(Int32Array,(count,tcsj));
}

RPTR(Int32Array) Int32Array::make (Int32 size,
				   APTR(PrimArray) from, 
				   Int32 sourceOffset, 
				   Int32 count, 
				   Int32 destOffset)
{
    RETURN_CONSTRUCT(Int32Array,(size, from, sourceOffset, count, destOffset));
}

RPTR(Int32Array) Int32Array::make (Int32 count, void * buffer) {
    RETURN_CONSTRUCT(Int32Array,(count,buffer));
}

/* accessing */

void Int32Array::storeInteger (Int32 index, IntegerVar value){
    /* Store an integer value */

    if (!CAST(PrimIntegerSpec,this->spec())->canHold (value)) {
	BLAST(ValueOutOfRange);
    }
    this->storeInt(index, value.asLong());
}

IntegerVar Int32Array::integerAt (Int32 index){
    /* Get an actual integer value */
    IntegerVar rv = this->intAt(index);
    return rv;
}

void Int32Array::storeValue (Int32 index, APTR(Heaper) OR(NULL) value){
    if (value == NULL) {
	BLAST(NULL_VALUE);
    }
    this->storeInt(index, CAST(PrimIntValue,value)->asIntegerVar().asInt32());
}

RPTR(Heaper) OR(NULL) Int32Array::fetchValue (Int32 index) {
    return PrimIntValue::make(this->intAt(index));
}

RPTR(PrimSpec) Int32Array::spec (){
    return PrimSpec::int32();
}

Int32 Int32Array::bitCount () {
    /* Return the maximum bit/entry that can be stored in this array.
       The number will be negative for signed arrays. */

    return -32;
}

/* bulk accessing */

void Int32Array::copyToBuffer (void * buffer,
			       Int32 size,
			       Int32 count /*= -1*/,
			       Int32 start /* = Int32Zero*/)
{
    Int32 bufSize;
    Int32 n;

    bufSize = size / sizeof(Int32);
    if (count >= 0) {
	n = count;
    } else {
	n = this->count() - start;
    }
    if (n > bufSize) {
	n = bufSize;
    }
    MEMMOVE (buffer, (Int32*)this->storage() + start,
	     (int)(n * sizeof(Int32)));
}

/* create */

Int32Array::Int32Array (Int32 count, TCSJ) 
    : PrimIntArray (count, sizeof (Int32))
{
    this->zeroElements (0, count);
}


Int32Array::Int32Array (Int32 size, 
			APTR(PrimArray) from, 
			Int32 sourceOffset, 
			Int32 count, 
			Int32 destOffset) 
    : PrimIntArray (size, sizeof (Int32))
{
    if (count == -1) {
	count = from->count() - sourceOffset;
    }
    this->zeroElements (0, destOffset);
    this->copyElements (destOffset, from, sourceOffset, count);
    this->zeroElements (destOffset + count, size - destOffset - count);
}

Int32Array::Int32Array (Int32 count, void * buffer)
    : PrimIntArray (count, sizeof(Int32))
{
    MEMMOVE (this->storage(), buffer, (int)(count * sizeof(Int32)));
}

/* comm hooks */

void Int32Array::receiveInt32Array (APTR(Rcvr) rcvr){
    for (Int32 i = 0; i <= this->count() - 1; i += 1) {
	this->storeInt(i, rcvr->receiveInt32());
    }
}

void Int32Array::sendInt32Array (APTR(Xmtr) xmtr){
    for (Int32 i = 0; i < this->count(); i += 1) {
	xmtr->sendInt32(this->intAt(i));
    }
}

/* helper functions */

Int32 Int32Array::compareData (Int32 start, 
			       APTR(PrimDataArray) other,
			       Int32 otherStart,
			       Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(Int32Array,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		Int32 cmp;
		cmp = this->intAt(i + start) - o->intAt(i + otherStart);
		if (cmp != 0) {
		    return cmp < 0 ? -1 : 1;
		}
	    }
	    return 0;
	} END_KIND;
	BEGIN_OTHERS {
	    return this->PrimIntegerArray::compareData (start, other, 
							otherStart, count);
	} END_OTHERS;
    } END_CHOOSE;
    return 0;
}

Int32 Int32Array::signOfNonZeroAfter (Int32 index) {
    for (Int32 i = index; i < this->count(); i += 1) {
	Int32 val;
	
	if ((val = this->intAt(i)) < 0) {
	    return -1;
	}
	if (val > 0) {
	    return +1;
	}
    }
    return 0;
}

void Int32Array::addData (Int32 start, 
			  APTR(PrimDataArray) other,
			  Int32 otherStart,
			  Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(Int32Array,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		this->storeInt (i + start,
				this->intAt(i + start) 
				+ o->intAt(i + otherStart));
	    }
	} END_KIND;
	BEGIN_OTHERS {
	    this->PrimIntegerArray::addData (start, other, otherStart, count);
	} END_OTHERS;
    } END_CHOOSE;
}

void Int32Array::subtractData (Int32 start, 
				APTR(PrimDataArray) other,
				Int32 otherStart,
				Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(Int32Array,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		this->storeInt (i + start,
				this->intAt(i + start) 
				- o->intAt(i + otherStart));
	    }
	} END_KIND;
	BEGIN_OTHERS {
	    this->PrimIntegerArray::subtractData (start, other, otherStart,
						  count);
	} END_OTHERS;
    } END_CHOOSE;
}

void Int32Array::printElementOn (Int32 index, ostream& oo)
{
    oo << this->intAt (index);
}

RPTR(PrimArray) Int32Array::makeNew (Int32 size,
				     APTR(PrimArray) source,
				     Int32 sourceOffset,
				     Int32 count,
				     Int32 destOffset)
{
    return Int32Array::make (size, CAST(PrimIntegerArray,source),
			     sourceOffset, count, destOffset);
}


/* ************************************************************************ *
 * 
 *                    Class       IntegerVarArray 
 *
 * ************************************************************************ */


/* pseudo constructors */

RPTR(IntegerVarArray) IntegerVarArray::zeros (Int32 count) {
    RETURN_CONSTRUCT(IntegerVarArray,(count,tcsj));
}

RPTR(IntegerVarArray) IntegerVarArray::make (Int32 size,
					     APTR(PrimArray) from, 
					     Int32 sourceOffset, 
					     Int32 count, 
					     Int32 destOffset)
{
    RETURN_CONSTRUCT(IntegerVarArray,(size, from, sourceOffset, count, destOffset));
}

RPTR(IntegerVarArray) IntegerVarArray::make (Int32 count, void * buffer) {
    RETURN_CONSTRUCT(IntegerVarArray,(count,buffer));
}

/* accessing */

void IntegerVarArray::storeInteger (Int32 index, IntegerVar value){
    /* Store an integer value */

    this->storeIntegerVar(index, value);
}

IntegerVar IntegerVarArray::integerAt (Int32 index){
    /* Get an actual integer value */

    return this->integerVarAt(index);
}

void IntegerVarArray::storeValue (Int32 index, APTR(Heaper) OR(NULL) value){
    if (value == NULL) {
	BLAST(NULL_VALUE);
    }
    this->storeIntegerVar(index, CAST(PrimIntValue,value)->asIntegerVar());
}

RPTR(Heaper) OR(NULL) IntegerVarArray::fetchValue (Int32 index) {
    return PrimIntValue::make(this->integerVarAt(index));
}

RPTR(PrimSpec) IntegerVarArray::spec (){
    return PrimSpec::integerVar();
}

/* bulk accessing */

void IntegerVarArray::copyToBuffer (void * buffer,
				    Int32 size,
				    Int32 count /*= -1*/,
				    Int32 start /* = Int32Zero*/)
{
    Int32 bufSize;
    Int32 n;

    bufSize = size / sizeof(IntegerVar);
    if (count >= 0) {
	n = count;
    } else {
	n = this->count() - start;
    }
    if (n > bufSize) {
	n = bufSize;
    }
    IntegerVar * source = (IntegerVar*)this->storage();
    for (Int32 i = 0; i < n; i += 1) {
	((IntegerVar*)buffer)[i] = source[i + start];
    }
}

/* create */

IntegerVarArray::IntegerVarArray (Int32 count, TCSJ) 
    : PrimIntegerArray (count, sizeof(IntegerVar))
{
    this->unsafeZeroElements (0, count);
}


IntegerVarArray::IntegerVarArray (Int32 size, 
				  APTR(PrimArray) from, 
				  Int32 sourceOffset, 
				  Int32 count, 
				  Int32 destOffset) 
    : PrimIntegerArray (size, sizeof(IntegerVar))
{
    if (count == -1) {
	count = from->count() - sourceOffset;
    }
    this->unsafeZeroElements (0, destOffset);
    this->copyElements (destOffset, from, sourceOffset, count);
    this->unsafeZeroElements (destOffset + count, size - destOffset - count);
}

IntegerVarArray::IntegerVarArray (Int32 count, void * buffer)
    : PrimIntegerArray (count, sizeof(IntegerVar))
{
    IntegerVar * source = (IntegerVar*) buffer;
    IntegerVar * dest = (IntegerVar*) this->storage();
    for (Int32 i = 0 ; i < count; i++) {
	dest[i] = source[i];
    }
}

/* comm hooks */

void IntegerVarArray::receiveIVArray (APTR(Rcvr) rcvr){
    for (Int32 i = 0; i < this->count(); i += 1) {
	this->storeIntegerVar(i, rcvr->receiveIntegerVar());
    }
}

void IntegerVarArray::sendIVArray (APTR(Xmtr) xmtr){
    for (Int32 i = 0; i < this->count(); i += 1) {
	xmtr->sendIntegerVar(this->integerVarAt(i));
    }
}

/* helper functions */

Int32 IntegerVarArray::compareData (Int32 start, 
				    APTR(PrimDataArray) other,
				    Int32 otherStart,
				    Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(IntegerVarArray,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		IntegerVar a = this->integerVarAt(start + i);
		IntegerVar b = o->integerVarAt(otherStart + i);
		if (a < b) {
		    return -1;
		}
		if (a > b) {
		    return 1;
		}
	    }
	    return 0;
	} END_KIND;
	BEGIN_OTHERS {
	    return this->PrimIntegerArray::compareData (start, other,
							otherStart, count);
	} END_OTHERS;
    } END_CHOOSE;
    return 0;
}

Int32 IntegerVarArray::signOfNonZeroAfter (Int32 index) {
    for (Int32 i = index; i < this->count(); i += 1) {
	IntegerVar val = this->integerVarAt(i);
	if (val < IntegerVarZero) {
	    return -1;
	}
	if (val > IntegerVarZero) {
	    return +1;
	}
    }
    return 0;
}

void IntegerVarArray::addData (Int32 start, 
			       APTR(PrimDataArray) other,
			       Int32 otherStart,
			       Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(IntegerVarArray,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		this->storeIntegerVar (i + start,
				       this->integerVarAt(i + start) 
				       + o->integerVarAt(i + otherStart));
	    }
	} END_KIND;
	BEGIN_OTHERS {
	    this->PrimIntegerArray::addData (start, other, otherStart, count);
	} END_OTHERS;
    } END_CHOOSE;
}

void IntegerVarArray::subtractData (Int32 start, 
				    APTR(PrimDataArray) other,
				    Int32 otherStart,
				    Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(IntegerVarArray,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		this->storeIntegerVar (i + start,
				       this->integerVarAt(i + start) 
				       - o->integerVarAt(i + otherStart));
	    }
	} END_KIND;
	BEGIN_OTHERS {
	    this->PrimIntegerArray::subtractData (start, other, otherStart,
						  count);
	} END_OTHERS;
    } END_CHOOSE;
}

void IntegerVarArray::printElementOn (Int32 index, ostream& oo)
{
    oo << this->integerVarAt (index);
}

void IntegerVarArray::zeroElements (Int32 from, Int32 count)
{
    Int32 n = count;
    if (n < 0) {
	n = this->count();
    }
    if (n+from > this->count()) {
	BLAST(TOO_MANY_ZEROS);
    }
    if (from < 0) {
	BLAST(BogusStartIndex);
    }
    for (Int32 i = 0; i < n; i += 1) {
	this->storeIntegerVar (from + i, IntegerVarZero);
    }
}

void IntegerVarArray::unsafeZeroElements (Int32 from, Int32 count)
{
    memset (((IntegerVar*)this->storage()) + from, 0,
	    (int) count * sizeof(IntegerVar));
}

void IntegerVarArray::copyElements (Int32 to, 
				    APTR(PrimArray) source,
				    Int32 from,
				    Int32 count)
{
    Int32 n = count;
    if (n == -1) {
	n = source->count() - from;
    }
    SPTR(PrimIntegerArray) s = CAST(PrimIntegerArray,source);
    for (Int32 i = 0; i < n; i += 1) {
	this->storeIntegerVar (to + i, s->integerAt (from + i));
    }
}

RPTR(PrimArray) IntegerVarArray::makeNew (Int32 size,
					  APTR(PrimArray) source,
					  Int32 sourceOffset,
					  Int32 count,
					  Int32 destOffset)
{
    return IntegerVarArray::make (size, CAST(PrimIntegerArray,source),
				  sourceOffset, count, destOffset);
}


/* ************************************************************************ *
 * 
 *                    Class       UInt32Array 
 *
 * ************************************************************************ */


/* pseudo constructors */

RPTR(UInt32Array) UInt32Array::make (Int32 count) {
    RETURN_CONSTRUCT(UInt32Array,(count,tcsj));
}

RPTR(UInt32Array) UInt32Array::make (Int32 size,
				     APTR(PrimArray) from, 
				     Int32 sourceOffset, 
				     Int32 count, 
				     Int32 destOffset)
{
    RETURN_CONSTRUCT(UInt32Array,(size, from, sourceOffset, count, destOffset));
}

RPTR(UInt32Array) UInt32Array::make (Int32 count, void * buffer) {
    RETURN_CONSTRUCT(UInt32Array,(count,buffer));
}

/* accessing */

void UInt32Array::storeInteger (Int32 index, IntegerVar value){
    /* Store an integer value */

    if (!CAST(PrimIntegerSpec,this->spec())->canHold (value)) {
	BLAST(ValueOutOfRange);
    }
    this->storeUInt(index, value.asLong());
}

IntegerVar UInt32Array::integerAt (Int32 index){
    /* Get an actual integer value */

    return this->uIntAt(index);
}

void UInt32Array::storeValue (Int32 index, APTR(Heaper) OR(NULL) value){
    if (value == NULL) {
	BLAST(NULL_VALUE);
    }
    this->storeUInt(index, CAST(PrimIntValue,value)->asIntegerVar().asUInt32());
}

RPTR(Heaper) OR(NULL) UInt32Array::fetchValue (Int32 index) {
    return PrimIntValue::make(this->uIntAt(index));
}

RPTR(PrimSpec) UInt32Array::spec (){
    return PrimSpec::uInt32();
}

Int32 UInt32Array::bitCount () {
    /* Return the maximum bits/entry that can be stored in this array.
       The number will be negative for signed arrays. */

    return 32;
}

/* bulk accessing */

void UInt32Array::copyToBuffer (void * buffer,
				Int32 size,
				Int32 count /*= -1*/,
				Int32 start /* = Int32Zero*/)
{
    Int32 bufSize;
    Int32 n;

    bufSize = size / sizeof(UInt32);
    if (count >= 0) {
	n = count;
    } else {
	n = this->count() - start;
    }
    if (n > bufSize) {
	n = bufSize;
    }
    MEMMOVE (buffer, (UInt32*)this->storage() + start,
	     (int)(n * sizeof(UInt32)));
}

/* create */

UInt32Array::UInt32Array (Int32 count, TCSJ) 
    : PrimIntArray (count, sizeof (UInt32))
{
    this->zeroElements (0, count);
}


UInt32Array::UInt32Array (Int32 size, 
			  APTR(PrimArray) from, 
			  Int32 sourceOffset, 
			  Int32 count, 
			  Int32 destOffset) 
    : PrimIntArray (size, sizeof (UInt32))
{
    if (count == -1) {
	count = from->count() - sourceOffset;
    }
    this->zeroElements (0, destOffset);
    this->copyElements (destOffset, from, sourceOffset, count);
    this->zeroElements (destOffset + count, size - destOffset - count);
}

UInt32Array::UInt32Array (Int32 count, void * buffer)
    : PrimIntArray (count, sizeof(UInt32))
{
    MEMMOVE (this->storage(), buffer, (int)(count * sizeof(UInt32)));
}

/* comm hooks */

void UInt32Array::receiveInt32Array (APTR(Rcvr) rcvr){
    for (Int32 i = 0; i <= this->count() - 1; i += 1) {
	this->storeUInt(i, rcvr->receiveUInt32());
    }
}

void UInt32Array::sendInt32Array (APTR(Xmtr) xmtr){
    for (Int32 i = 0; i < this->count(); i += 1) {
	xmtr->sendUInt32(this->uIntAt(i));
    }
}

/* helper functions */

Int32 UInt32Array::compareData (Int32 start, 
				APTR(PrimDataArray) other,
				Int32 otherStart,
				Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(UInt32Array,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		/* With unsigneds, we can''t use subtraction to do this */
		UInt32 a, b;
		a = this->uIntAt(i + start);
		b = o->uIntAt(i + otherStart);
		if (a < b) {
		    return -1;
		}
		if (a > b) {
		    return 1;
		}
	    }
	    return 0;
	} END_KIND;
	BEGIN_OTHERS {
	    return this->PrimIntegerArray::compareData (start, other,
							otherStart, count);
	} END_OTHERS;
    } END_CHOOSE;
    return 0;
}

Int32 UInt32Array::signOfNonZeroAfter (Int32 index) {
    for (Int32 i = index; i < this->count(); i += 1) {
	UInt32 val;
	
	if ((val = this->uIntAt(i)) > 0) {
	    return +1;
	}
    }
    return 0;
}

void UInt32Array::addData (Int32 start, 
			   APTR(PrimDataArray) other,
			   Int32 otherStart,
			   Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(UInt32Array,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		this->storeUInt (i + start,
				 this->uIntAt(i + start) 
				 + o->uIntAt(i + otherStart));
	    }
	} END_KIND;
	BEGIN_OTHERS {
	    this->PrimIntegerArray::addData (start, other, otherStart, count);
	} END_OTHERS;
    } END_CHOOSE;
}

void UInt32Array::subtractData (Int32 start, 
				APTR(PrimDataArray) other,
				Int32 otherStart,
				Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(UInt32Array,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		this->storeUInt (i + start,
				 this->uIntAt(i + start) 
				 - o->uIntAt(i + otherStart));
	    }
	} END_KIND;
	BEGIN_OTHERS {
	    this->PrimIntegerArray::subtractData (start, other, otherStart,
						  count);
	} END_OTHERS;
    } END_CHOOSE;
}

void UInt32Array::printElementOn (Int32 index, ostream& oo)
{
    oo << this->uIntAt (index);
}

RPTR(PrimArray) UInt32Array::makeNew (Int32 size,
				      APTR(PrimArray) source,
				      Int32 sourceOffset,
				      Int32 count,
				      Int32 destOffset)
{
    return UInt32Array::make (size, CAST(PrimIntegerArray,source),
			      sourceOffset, count, destOffset);
}


/* ************************************************************************ *
 * 
 *                    Class       UInt8Array 
 *
 * ************************************************************************ */


/* pseudo constructors */

RPTR(UInt8Array) UInt8Array::make (Int32 count) {
    RETURN_CONSTRUCT(UInt8Array,(count,tcsj));
}

RPTR(UInt8Array) UInt8Array::make (Int32 size,
				   APTR(PrimArray) from, 
				   Int32 sourceOffset, 
				   Int32 count, 
				   Int32 destOffset)
{
    RETURN_CONSTRUCT(UInt8Array,(size, from, sourceOffset, count, destOffset));
}

RPTR(UInt8Array) UInt8Array::make (Int32 count, void * buffer) {
    RETURN_CONSTRUCT(UInt8Array,(count,buffer));
}

RPTR(UInt8Array) UInt8Array::string (char * string){
    return UInt8Array::make (strlen(string), (UInt8*) string);
}

/* accessing */

void UInt8Array::storeInteger (Int32 index, IntegerVar value){
    /* Store an integer value */

    if (!CAST(PrimIntegerSpec,this->spec())->canHold (value)) {
	BLAST(ValueOutOfRange);
    }
    this->storeUInt(index, value.asLong());
}

IntegerVar UInt8Array::integerAt (Int32 index){
    /* Get an actual integer value */

    return this->uIntAt(index);
}

void UInt8Array::storeValue (Int32 index, APTR(Heaper) OR(NULL) value){
    if (value == NULL) {
	BLAST(NULL_VALUE);
    }
    this->storeUInt(index, CAST(PrimIntValue,value)->asIntegerVar().asUInt32());
}

RPTR(Heaper) OR(NULL) UInt8Array::fetchValue (Int32 index) {
    return PrimIntValue::make(this->uIntAt(index));
}

RPTR(PrimSpec) UInt8Array::spec (){
    return PrimSpec::uInt8();
}

Int32 UInt8Array::bitCount () {
    /* Return the maximum bits/entry that can be stored in this array.
       The number will be negative for signed arrays. */

    return 8;
}

/* bulk accessing */

void UInt8Array::storeMany (Int32 to, 
			    APTR(PrimArray) other,
			    Int32 count/* = -1*/,
			    Int32 from/* = Int32Zero*/)
{
    /* Copy count elements from the other array into this one.
       The other array must be of a compatible type. */

    Int32 n = count;
    if (n < 0) {
	n = min(this->count() - to, other->count() - from);
    }
    this->copyElements (to, other, from, n);
}

/* printing */

void UInt8Array::printOn (ostream& oo){
    for (Int32 i = 0; i < this->count(); i += 1) {
	oo << (char) this->uIntAt(i);
    }
}

/* bulk accessing */

void UInt8Array::copyToBuffer (void * buffer,
			       Int32 size,
			       Int32 count /*= -1*/,
			       Int32 start /* = Int32Zero*/)
{
    Int32 bufSize;
    Int32 n;

    bufSize = size / sizeof(UInt8);
    if (count >= 0) {
	n = count;
    } else {
	n = this->count() - start;
    }
    if (n > bufSize) {
	n = bufSize;
    }
    MEMMOVE (buffer, (UInt8*)this->storage() + start,
	     (int)(n * sizeof(UInt8)));
}

/* private: accessing */

char * UInt8Array::gutsOf (){
    PrimArray::OurGutsCount++;
    return (char*) this->storage();
}

void UInt8Array::noMoreGuts ()
{
    assert(PrimArray::OurGutsCount > 0);
    PrimArray::OurGutsCount--;
}

/* create */

UInt8Array::UInt8Array (Int32 count, TCSJ) 
    : PrimIntArray (count, sizeof (UInt8))
{
    this->zeroElements (0, count);
}


UInt8Array::UInt8Array (Int32 size, 
			APTR(PrimArray) from, 
			Int32 sourceOffset, 
			Int32 count, 
			Int32 destOffset) 
    : PrimIntArray (size, sizeof (UInt8))
{
    if (count == -1) {
	count = from->count() - sourceOffset;
    }
    this->zeroElements (0, destOffset);
    this->copyElements (destOffset, from, sourceOffset, count);
    this->zeroElements (destOffset + count, size - destOffset - count);
}

UInt8Array::UInt8Array (Int32 count, void * buffer)
    : PrimIntArray (count, sizeof(UInt8))
{
    MEMMOVE (this->storage(), buffer, (int)(count * sizeof(UInt8)));
}

/* comm hooks */

void UInt8Array::receiveUInt8Array (APTR(Rcvr) rcvr){
    rcvr->receiveData(this);
}

void UInt8Array::sendUInt8Array (APTR(Xmtr) xmtr){
    xmtr->sendUInt8Data(this);
}

/* helper functions */

Int32 UInt8Array::compareData (Int32 start, 
			       APTR(PrimDataArray) other,
			       Int32 otherStart,
			       Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(UInt8Array,o) {
	    UInt8 * ap = (UInt8*) this->storage() + start;
	    UInt8 * bp = (UInt8*) o->storage() + otherStart;
	    for (Int32 i = 0; i < count; i += 1) {
		/* With unsigneds, we can''t use subtraction to do this.
		   Also, ANSI doesn''t say anything about strcmp and memcmp
		   being signed or unsigned. */
		UInt32 a, b;
		a = *ap++;
		b = *bp++;
		if (a < b) {
		    return -1;
		}
		if (a > b) {
		    return 1;
		}
	    }
	    return 0;
	} END_KIND;
	BEGIN_OTHERS {
	    return this->PrimIntegerArray::compareData (start, other,
							otherStart, count);
	} END_OTHERS;
    } END_CHOOSE;
    return 0;
}

Int32 UInt8Array::signOfNonZeroAfter (Int32 index) {
    for (Int32 i = index; i < this->count(); i += 1) {
	UInt32 val;
	
	if ((val = this->uIntAt(i)) > 0) {
	    return +1;
	}
    }
    return 0;
}

void UInt8Array::addData (Int32 start, 
			  APTR(PrimDataArray) other,
			  Int32 otherStart,
			  Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(UInt8Array,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		this->storeUInt (i + start,
				 this->uIntAt(i + start) 
				 + o->uIntAt(i + otherStart));
	    }
	} END_KIND;
	BEGIN_OTHERS {
	    this->PrimIntegerArray::addData (start, other, otherStart, count);
	} END_OTHERS;
    } END_CHOOSE;
}

void UInt8Array::subtractData (Int32 start, 
			      APTR(PrimDataArray) other,
			      Int32 otherStart,
			      Int32 count)
{
    BEGIN_CHOOSE(other) {
	BEGIN_KIND(UInt8Array,o) {
	    for (Int32 i = 0; i < count; i += 1) {
		this->storeUInt (i + start,
				 this->uIntAt(i + start) 
				 - o->uIntAt(i + otherStart));
	    }
	} END_KIND;
	BEGIN_OTHERS {
	    this->PrimIntegerArray::subtractData (start, other, otherStart,
						  count);
	} END_OTHERS;
    } END_CHOOSE;
}

void UInt8Array::printElementOn (Int32 index, ostream& oo)
{
    oo << this->uIntAt (index);
}


void UInt8Array::zeroElements (Int32 from, Int32 count)
{
    Int32 n = count;
    if (n < 0) {
	n = this->count();
    }
    if (n+from > this->count()) {
	BLAST(TOO_MANY_ZEROS);
    }
    if (from < 0) {
	BLAST(BogusStartIndex);
    }
    memset (((UInt8*)this->storage()) + from, 0, (int) n * sizeof(UInt8));
}


void UInt8Array::copyElements (Int32 to, 
			       APTR(PrimArray) source,
			       Int32 from,
			       Int32 count)
{
    Int32 n = count;
    if (n == -1) {
	n = source->count() - from;
    }
    /* we can hold the source storage pointer since this is atomic */
    UInt8 * sourceBits = ((UInt8*)CAST(UInt8Array,source)->storage()) + from;
    UInt8 * destBits = ((UInt8*)this->storage()) + to;
    MEMMOVE (destBits, sourceBits, (int) (n * sizeof(UInt8)));
}


RPTR(PrimArray) UInt8Array::makeNew (Int32 size,
				     APTR(PrimArray) source,
				     Int32 sourceOffset,
				     Int32 count,
				     Int32 destOffset)
{
    return UInt8Array::make (size, CAST(PrimIntegerArray,source),
			     sourceOffset, count, destOffset);
}



/* ************************************************************************ *
 * 
 *                    Class   PtrArray 
 *
 * ************************************************************************ */


/* pseudo constructors */

static void emptyMake() {
    /* for profiling */
}

RPTR(PtrArray) PtrArray::nulls (Int32 count){
    if (count < 0 || count > (Int32)(HeapChunkSize/sizeof(void*))) {
	BLAST(MEM_ALLOC_ERROR);
    }
    if (count == 0) {
	emptyMake();
    }
    RETURN_CONSTRUCT(PtrArray,(count, tcsj));
}

RPTR(PtrArray) PtrArray::make (Int32 size,
			       APTR(PrimArray) from, 
			       Int32 sourceOffset, 
			       Int32 count, 
			       Int32 destOffset)
{
    if (count == 0) {
	emptyMake();
    }
    RETURN_CONSTRUCT(PtrArray,(size, from, sourceOffset, count, destOffset));
}

RPTR(PtrArray) PtrArray::make (Int32 count, void * buffer){
    if (count == 0) {
	emptyMake();
    }
    RETURN_CONSTRUCT(PtrArray,(count, buffer));
}

RPTR(PtrArray) PtrArray::empty (){
    /* Thing to do !!!! */

    emptyMake();
    /* Cache a single array */
    RETURN_CONSTRUCT(PtrArray,(Int32Zero, tcsj));
}

/* accessing */

void PtrArray::store (Int32 index, APTR(Heaper) OR(NULL) pointer){
    Heaplet::checkedArrayStore
    	(this,
	 ((Heaper**)this->storage()) + this->rangeCheck (index),
	 pointer,
	 index);
}

RPTR(PrimSpec) PtrArray::spec (){
    return PrimSpec::pointer();
}

RPTR(Heaper) OR(NULL) PtrArray::fetchValue (Int32 index) {
    return this->fetch(index);
}

void PtrArray::storeValue (Int32 index, APTR(Heaper) OR(NULL) value){
    this->store(index, value);
}

/* bulk testing */

BooleanVar PtrArray::elementsEQ (Int32 here,
				 PrimArray * other,
				 Int32 there/* = Int32Zero*/,
				 Int32 count/* = -1*/)
{
    Int32 n;
    SPTR(PtrArray) o = CAST(PtrArray,other);

    n = min(other->count() - there, this->count() - here);
    if (count > n) {
	BLAST(IndexOutOfBounds);
    }
    if (count >= 0) {
	n = count;
    }
    for (Int32 i = 0; i < n; i += 1) {
	if (this->unsafeFetch(here + i) != o->unsafeFetch(there + i)) {
	    return FALSE;
	}
    }
    return TRUE;
}


BooleanVar PtrArray::elementsEqual (Int32 here,
				    APTR(PrimArray) other,
				    Int32 there/* = Int32Zero*/,
				    Int32 count/* = -1*/)
{
    Int32 n;
    SPTR(PtrArray) o = CAST(PtrArray,other);

    n = min(other->count() - there, this->count() - here);
    if (count > n) {
	BLAST(IndexOutOfBounds);
    }
    if (count >= 0) {
	n = count;
    }
    for (Int32 i = 0; i < n; i += 1) {
	SPTR(Heaper) a;
	SPTR(Heaper) b;

	if (!((a = this->unsafeFetch(here + i)) ==
	      (b = o->unsafeFetch(there + i))
	      || a != NULL && b != NULL && a->isEqual(b))) {
	    return FALSE;
	}
    }
    return TRUE;
}


UInt32 PtrArray::elementsHash(Int32 count/* = -1*/,
			      Int32 start/* = Int32Zero*/)
{
    UInt32 result = 0;
    Int32 n = count == -1 ? this->count() - start : count;
    if (start < 0 || n + start > this->count()) {
        BLAST(IndexOutOfBounds);
    }
    for (Int32 i = 0; i < n; i++) {
	result ^= this->unsafeFetch(i + start)->hashForEqual();
    }
    return result;
}

/* testing */

BooleanVar PtrArray::contentsEQ (APTR(PtrArray) other){
    if (this->count() != other->count()) {
	return FALSE;
    }
    SPTR(PtrArray) o = CAST(PtrArray,other);
    for (Int32 i = 0; i < this->count(); i += 1) {
	if (this->unsafeFetch(i) != o->unsafeFetch(i)) {
	    return FALSE;
	}
    }
    return TRUE;
}


BooleanVar PtrArray::contentsEqual (APTR(PrimArray) other){
    SPTR(PtrArray) o = CAST(PtrArray,other);

    if (this->count() != other->count()) {
	return FALSE;
    }
    for (Int32 i = 0; i < this->count(); i += 1) {
	SPTR(Heaper) a;
	SPTR(Heaper) b;
	
	if (!((a = this->unsafeFetch(i)) == (b = o->unsafeFetch(i))
	      || a != NULL && b != NULL && a->isEqual(b))) {
		  return FALSE;
	}
    }
    return TRUE;
}


UInt32 PtrArray::contentsHash (){
    UInt32 result;

    result = this->count() * 43;
    for (Int32 i = 0; i < this->count(); i += 1) {
	SPTR(Heaper) p;

	if ((p = this->unsafeFetch(i)) != NULL) {
	    result ^= p->hashForEqual();
	}
    }
    return result;
}

/* bulk accessing */

Int32 PtrArray::indexOf (APTR(Heaper) value, 
			 Int32 start/* = Int32Zero*/,
			 Int32 nth/* = 1*/)
{
    if (this->count() == 0 || nth == 0) {
	return -1;
    }
    if (start < 0) {
	start = this->count () + start;
    }
    if (start < 0 || start >= this->count ()) {
	BLAST(IndexOutOfBounds);
    }

    if (value != NULL) {
	if (nth >= 0) {
	    for (Int32 idx = start; idx < this->count(); idx++) {
		WPTR(Heaper) ptr = this->unsafeFetch(idx);
		if (ptr == value || (ptr && value && ptr->isEqual (value))) {
		    nth--;
		    if (nth == 0) {
			return idx;
		    }
		}
	    }
	} else {
	    for (Int32 idx = start; idx >= 0; idx--) {
		WPTR(Heaper) ptr = this->unsafeFetch(idx);
		if (ptr == value || (ptr && value && ptr->isEqual (value))) {
		    nth++;
		    if (nth == 0) {
			return idx;
		    }
		}
	    }
	}
    } else {
	Heaper ** pp = (Heaper**) this->storage() + start;
	if (nth >= 0) {
	    Int32 count = this->count();
	    for (Int32 idx = start; idx < count; idx++) {
		WPTR(Heaper) ptr = *pp++;
		if (ptr == NULL) {
		    nth--;
		    if (nth == 0) {
			return idx;
		    }
		}
	    }
	} else {
	    for (Int32 idx = start; idx >= 0; idx--) {
		WPTR(Heaper) ptr = *pp--;
		if (ptr == NULL) {
		    nth++;
		    if (nth == 0) {
			return idx;
		    }
		}
	    }
	}
    }
    return -1;
}

Int32 PtrArray::indexPast (APTR(Heaper) value, 
			   Int32 start/* = Int32Zero*/,
			   Int32 nth/* = 1*/)
{
    if (this->count() == 0 || nth == 0) {
	return -1;
    }
    if (start < 0) {
	start = this->count () + start;
    }
    if (start < 0 || start >= this->count ()) {
	BLAST(IndexOutOfBounds);
    }

    if (value != NULL) {
	if (nth >= 0) {
	    for (Int32 idx = start; idx < this->count(); idx++) {
		WPTR(Heaper) ptr = this->unsafeFetch(idx);
		if (! (ptr == value || (ptr && ptr->isEqual (value)))) {
		    nth--;
		    if (nth == 0) {
			return idx;
		    }
		}
	    }
	} else {
	    for (Int32 idx = start; idx >= 0; idx--) {
		WPTR(Heaper) ptr = this->unsafeFetch(idx);
		if (! (ptr == value || (ptr && ptr->isEqual (value)))) {
		    nth++;
		    if (nth == 0) {
			return idx;
		    }
		}
	    }
	}
    } else {
	Heaper ** pp = (Heaper**) this->storage() + start;
	if (nth >= 0) {
	    for (Int32 idx = start; idx < this->count(); idx++) {
		WPTR(Heaper) ptr = *pp++;
		if (ptr) {
		    nth--;
		    if (nth == 0) {
			return idx;
		    }
		}
	    }
	} else {
	    for (Int32 idx = start; idx >= 0; idx--) {
		WPTR(Heaper) ptr = *pp--;
		if (ptr) {
		    nth++;
		    if (nth == 0) {
			return idx;
		    }
		}
	    }
	}
    }
    return -1;
}

void PtrArray::storeAll (APTR(Heaper) value/* = NULL*/,
			 Int32 count/* = -1*/,
			 Int32 start/* = Int32Zero*/)
{
    Int32 n;

    n = this->count() - start;
    if (count > n) {
	BLAST(IndexOutOfBounds);
    }
    if (value == NULL && start == Int32Zero) {
	for (Int32 i = 0; i < this->count(); i++) {
	    this->store(i, NULL);
	}
//	this->zeroElements (0, count);
	return;
    }
    if (count >= 0) {
	n = count;
    }
    for (Int32 i = 0; i < n; i += 1) {
	this->store(start + i, value);
    }
}

void PtrArray::copyToBuffer (void * buffer,
			     Int32 size,
			     Int32 count /*= -1*/,
			     Int32 start /* = Int32Zero*/)
{
    Int32 bufSize;
    Int32 n;

    bufSize = size / sizeof(Heaper*);
    if (count >= 0) {
	n = count;
    } else {
	n = this->count() - start;
    }
    if (n > bufSize) {
	n = bufSize;
    }
    MEMMOVE (buffer, (Heaper**)this->storage() + start,
	     (int)(n * sizeof(Heaper*)));
}

/* EQ bulk accessing */

Int32 PtrArray::indexOfEQ (APTR(Heaper) value, 
			   Int32 start/* = Int32Zero*/,
			   Int32 nth/* = 1*/)
{
    if (this->count() == 0 || nth == 0) {
	return -1;
    }
    if (start < 0) {
	start = this->count () + start;
    }
    if (start < 0 || start >= this->count ()) {
	BLAST(IndexOutOfBounds);
    }

    Heaper ** pp = (Heaper**) this->storage() + start;
    if (nth >= 0) {
	for (Int32 idx = start; idx < this->count(); idx++) {
	    WPTR(Heaper) ptr = *pp++;
	    if (ptr == value) {
		nth--;
		if (nth == 0) {
		    return idx;
		}
	    }
	}
    } else {
	for (Int32 idx = start; idx >= 0; idx--) {
	    WPTR(Heaper) ptr = *pp--;
	    if (ptr == value) {
		nth++;
		if (nth == 0) {
		    return idx;
		}
	    }
	}
    }
    return -1;
}

Int32 PtrArray::indexOfEQOrNull (APTR(Heaper) value, 
				 Int32 start/* = Int32Zero*/,
				 Int32 nth/* = 1*/)
{
    if (this->count() == 0 || nth == 0) {
	return -1;
    }
    if (start < 0) {
	start = this->count () + start;
    }
    if (start < 0 || start >= this->count ()) {
	BLAST(IndexOutOfBounds);
    }

    Heaper ** pp = (Heaper**) this->storage() + start;
    if (nth >= 0) {
	for (Int32 idx = start; idx < this->count(); idx++) {
	    WPTR(Heaper) ptr = *pp++;
	    if (ptr == value || ptr == NULL) {
		nth--;
		if (nth == 0) {
		    return idx;
		}
	    }
	}
    } else {
	for (Int32 idx = start; idx >= 0; idx--) {
	    WPTR(Heaper) ptr = *pp--;
	    if (ptr == value || ptr == NULL) {
		nth++;
		if (nth == 0) {
		    return idx;
		}
	    }
	}
    }
    return -1;
}

Int32 PtrArray::indexPastEQ (APTR(Heaper) value, 
			     Int32 start/* = Int32Zero*/,
			     Int32 nth/* = 1*/)
{
    if (this->count() == 0 || nth == 0) {
	return -1;
    }
    if (start < 0) {
	start = this->count () + start;
    }
    if (start < 0 || start >= this->count ()) {
	BLAST(IndexOutOfBounds);
    }

    Heaper ** pp = (Heaper**) this->storage() + start;
    if (nth >= 0) {
	for (Int32 idx = start; idx < this->count(); idx++) {
	    WPTR(Heaper) ptr = *pp++;
	    if (ptr == value) {
		nth--;
		if (nth == 0) {
		    return idx;
		}
	    }
	}
    } else {
	for (Int32 idx = start; idx >= 0; idx--) {
	    WPTR(Heaper) ptr = *pp--;
	    if (ptr == value) {
		nth++;
		if (nth == 0) {
		    return idx;
		}
	    }
	}
    }
    return -1;
}


/* create */

PtrArray::PtrArray (Int32 count, TCSJ) 
    : PrimArray (count, sizeof(Heaper*))
{
    this->zeroElements (0, count);
    Heaplet::pageOf(this)->registerPtrArray (this);
}

PtrArray::PtrArray (Int32 size, 
		    APTR(PrimArray) from, 
		    Int32 sourceOffset, 
		    Int32 count, 
		    Int32 destOffset)
    : PrimArray (size, sizeof(Heaper*))
{
    if (from != NULL) {
	SPTR(PtrArray) other = CAST(PtrArray, from);
	if (count == -1) {
	    count = from->count() - sourceOffset;
	}
	this->zeroElements (0, destOffset);
	this->copyElements (destOffset, from, sourceOffset, count);
	this->zeroElements (destOffset + count, size - destOffset - count);
    } else {
	this->zeroElements (0, size);
    }
    Heaplet::pageOf(this)->registerPtrArray (this);
}

PtrArray::PtrArray (Int32 count, void * buffer)
    : PrimArray (count, sizeof(Heaper*))
{
    MEMMOVE (this->storage(), buffer, (int)(count * sizeof(Heaper*)));
    Heaplet::pageOf(this)->registerPtrArray (this);
}

/* destruction */

PtrArray::~PtrArray () {
    for (Int32 i = 0; i < this->count(); i++) {
	this->store(i, NULL);
    }
    Heaplet::pageOf(this)->unregisterPtrArray ((PtrArray*)this);
}

/* comm hooks */

void PtrArray::receivePtrArray (APTR(Rcvr) rcvr){
    /* must zero elements first in case GC happens while receiving */
    Heaplet::pageOf(this)->registerPtrArray (this);
    this->zeroElements (0, this->count());
    for (Int32 i = 0; i <= this->count() - 1; i += 1) {
	this->store(i, rcvr->receiveHeaper());
    }
}

void PtrArray::sendPtrArray (APTR(Xmtr) xmtr){
    for (Int32 i = 0; i < this->count(); i += 1) {
	xmtr->sendHeaper(this->unsafeFetch(i));
    }
}

/* helper functions */

void PtrArray::printElementOn (Int32 index, ostream& oo)
{
    oo << this->fetch(index);
}

RPTR(PrimArray) PtrArray::makeNew (Int32 size,
				   APTR(PrimArray) source,
				   Int32 sourceOffset,
				   Int32 count,
				   Int32 destOffset)
{
    return PtrArray::make (size, CAST(PtrArray,source), sourceOffset, count,
			   destOffset);
}

void PtrArray::migrate (void * origin,
			BooleanVar destinationIsOld)
{
    Heaper *p, *n;

    Heaplet::pageOf(origin)->unregisterPtrArray ((PtrArray*)origin);
    Heaplet::pageOf(this)->registerPtrArray (this);

    Int32 localCount = this->count();  // saves a memory hit in the loop

    if (destinationIsOld) {
	for (Int32 i = 0; i < localCount; i++) {
	    Heaper ** pp = &((Heaper**) this->storage())[i];
	    p = *pp;
	    if (Heaplet::isScavengeable (p)) {
		if (p) {
		    n = Heaplet::forward (p);
		}
		if (p == n) {
		    Heaplet::pageOf (n)->changeArray((PtrArray*)origin, this);
		} else {
		    ((Heaper**) this->storage())[i] = n;
		    Heaplet::pageOf (p)->forgetArray((PtrArray*)origin, i);
		    Heaplet::pageOf (n)->rememberArray(this, i, NULL);
		}
	    }
	}
    } else {
	for (Int32 i = 0; i < localCount; i++) {
	    p = ((Heaper**) this->storage())[i];
	    if (Heaplet::isScavengeable (p)) {
		if (p) {
		    n = Heaplet::forward (p);
		    if (p == n) {
			Heaplet::pageOf (n)->changeArray((PtrArray*)origin,
							 this);
		    }
		    ((Heaper**) this->storage())[i] = n;
		}
	    }
	}
    }
}

/* errors */

void PtrArray::nullEntry () {
    BLAST(NullEntry);
}


/* ************************************************************************ *
 * 
 *                    Class     SharedPtrArray 
 *
 * ************************************************************************ */


/* pseudo constructors */

RPTR(SharedPtrArray) SharedPtrArray::make (Int32 count){
    RETURN_CONSTRUCT(SharedPtrArray,(count, tcsj));
}

RPTR(SharedPtrArray) SharedPtrArray::make (Int32 size,
					   APTR(PrimArray) from, 
					   Int32 sourceOffset, 
					   Int32 count, 
					   Int32 destOffset)
{
    RETURN_CONSTRUCT(SharedPtrArray,(size, from, sourceOffset, count, destOffset));
}

RPTR(SharedPtrArray) SharedPtrArray::make (Int32 count, void * buffer){
    RETURN_CONSTRUCT(SharedPtrArray,(count, buffer));
}

/* accessing */

RPTR(PrimSpec) SharedPtrArray::spec (){
    return PrimSpec::sharedPointer();
}

void SharedPtrArray::shareLess () {
	myShareCount -= 1;
}


void SharedPtrArray::shareMore () {
	myShareCount += 1;
}


/* creation */

SharedPtrArray::SharedPtrArray (Int32 count, TCSJ) 
    : PtrArray(count, tcsj)
{
    myShareCount = 0;
}

SharedPtrArray::SharedPtrArray (Int32 size, 
				APTR(PrimArray) from, 
				Int32 sourceOffset, 
				Int32 count, 
				Int32 destOffset) 
    : PtrArray(size, from, sourceOffset, count, destOffset) 
{
    myShareCount = 0;
}

SharedPtrArray::SharedPtrArray (Int32 count, void * buffer) 
    : PtrArray(count, buffer)
{
    myShareCount = 0;
}

/* helper functions */

RPTR(PrimArray) SharedPtrArray::makeNew (Int32 size,
					 APTR(PrimArray) source,
					 Int32 sourceOffset,
					 Int32 count,
					 Int32 destOffset)
{
    return SharedPtrArray::make (size, CAST(PtrArray,source),
				 sourceOffset, count, destOffset);
}


/* ************************************************************************ *
*
*		      Class PrimArrayHeap
*
 * ************************************************************************ */


Int32 HeapChunkSize = 0x100000 / sizeof(Int32); /* default 1MB for heap */

/* "class" instances and methods */

PrimArrayHeap * PrimArrayHeap::FirstHeap = NULL;

Int32 * PrimArrayHeap::getStorage (Int32 nWords, APTR(PrimArray) pa) {

    if (nWords > HeapChunkSize) {
	/* If someone wants a giant PrimArray, we better allocate it. */
	PrimArrayHeap * newHeap = new PrimArrayHeap (nWords);
	return newHeap->allocate (nWords, pa);
    }




    for (PrimArrayHeap * paha = FirstHeap; paha; paha = paha->myNextHeap) {
	Int32 * result;
	if ((result = paha->allocate (nWords, pa))) {
	    return result;
	}
    }
#ifdef ENABLECOMPACTION
   for (PrimArrayHeap * pah = FirstHeap; pah; pah = pah->myNextHeap) {//zzz zzzz klugh roger kluge ZZZ june 1995 reg
	pah->compact ();
	Int32 * result;
	if (result = pah->allocate (nWords, pa)) {
	    return result;
	}
    }
#endif
/* reg zzz nov 2 1994 look here "still failing  compact  gc ZZZZ !!!!!!!!!!!!!!!!!!!!!*/
    /* With the above still failing, we need a new heap */
    PrimArrayHeap * newHeap = new PrimArrayHeap (HeapChunkSize);

    return newHeap->allocate (nWords, pa);
}

void PrimArrayHeap::cleanup () {
    for (PrimArrayHeap * pah = FirstHeap; pah; pah = pah->myNextHeap) {
	pah->removeDestructedArrays();
    }
}

/* "instance" methods */

Int32 * PrimArrayHeap::allocate (Int32 nWords, APTR(PrimArray) pa) {
    Int32 * result = myEndSpace;
    Int32 * newEnd = result + nWords;
    if (newEnd >= (Int32*)(myPrimArrayTable - 1)) {
	return NULL;
    }
    myEndSpace = newEnd;
    *myPrimArrayTable-- = pa;
    return result;
}

void PrimArrayHeap::compact () {
    Int32 * nextSpace = myHeapStore;

    for (PrimArray ** ppa = (PrimArray**)myLastWord; ppa > myPrimArrayTable; ppa--) {
	PrimArray * pa = *ppa;
	if (pa->isKindOf(cat_PrimArray)) {
	    /* fixes a bug, used to break compaction during receive */
	    if (pa->storage() != NULL) {
		if (pa->storage() < nextSpace) {
		    BLAST(MESSUP_IN_PRIMARRAY_COMPACT);
		}
		
		if (pa->storage() > nextSpace) {
		    pa->moveTo (nextSpace);
		}
		nextSpace += pa->size();
	    }
	}
    }
    myEndSpace = nextSpace;
}

void PrimArrayHeap::removeDestructedArrays () {
#if 0
    PrimArray ** from = (PrimArray**)myLastWord;
    PrimArray ** to = from;
    Int32 gcn = Heap::gCNumber();
    while (from > myPrimArrayTable) {
	while (from > myPrimArrayTable && (*from)->gCSweep() != gcn) {
	    from--;
	}
	if (from > myPrimArrayTable) {
	    *to-- = *from--;
	}
    }
    myPrimArrayTable = to;
#endif
}

PrimArrayHeap::PrimArrayHeap (Int32 size) {
    myNextHeap = FirstHeap;
    FirstHeap = this;
    myEndSpace = myHeapStore = new Int32[size];
    myLastWord = myHeapStore + size - 1;
    myPrimArrayTable = (PrimArray**) myLastWord;
}

#ifndef PARRAYX_SXX
#include "parrayx.sxx"
#endif /* PARRAYX_SXX */

#endif /* PARRAYX_CXX */
