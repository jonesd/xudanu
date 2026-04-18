#ifndef SCAVP_IXX
#define SCAVP_IXX

#include "bombx.hxx"

/*
	Class HeapletSetStepper
*/

INLINE Heaplet * HeapletSetStepper::fetch () {
    return
    	myBitIndex >= 0
	? (Heaplet*) ((myWordIndex * 32 + myBitIndex) * PAGESIZE)
	: NULL;
}


/*
	Class HeapletSet
*/

/* Inclusion test */

//"contains" returns true if the pointer is in one of the 5 heaplet
//mappings.  The first test is bogus at the current setting because
//mySize is as big as 32 bits of address/16k can get.  hkh sept 14 1994
//the "else" part ands the bit in myBitMap with the derived
//location of the bit from the passed in ptr and heaplet
//set.  Returning true indicates the ptr is within an    
//active (in use) page of whatever set was [set]->contains

INLINE BooleanVar HeapletSet::contains (void * ptr) {
    Int32 index = ((UInt32)ptr) / PAGESIZE;
    if (index > mySize) {
	return FALSE;
    } else {
	return myBitMap[index / 32] & (1 << (index % 32));
    }
}

INLINE UInt32 HeapletSet::wordAt (Int32 index) {
    if (index*32 > mySize) {
	BLAST(SanityViolation);
    }
    return myBitMap[index];
}

INLINE Int32 HeapletSet::wordCount () {
    return mySize / 32;
}

INLINE Int32 HeapletSet::lowestIndex () {
    return myLowest;
}

INLINE Int32 HeapletSet::highestIndex () {
    return myHighest;
}

#endif /* SCAVP_IXX */
