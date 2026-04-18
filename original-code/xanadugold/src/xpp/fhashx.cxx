/*
      (C) Copyright 1988, 89 by Xanadu Operating Company, All Rights Reserved.

******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
******************************************************************************/

#include "fhashx.hxx"

VERSION_ID(fhashx_cxx,
	   "$Id: fhashx.cxx,v 2.14 1993/03/01 21:35:15 eric Exp $")

#include "hsboxx.hxx"
#ifdef GNUSUN
/*extern "C"{
#include <math.h>
}
*/
#else
#include <math.h>
#endif

/* Adapted from 
	"Fast Hashing of Variable-Length Text Strings"
	Peter K. Pearson
	Communications of the ACM
	June 1990
	Volume 33, Number 6, pp 677-680

	The original generates an 8-bit value using the iterand
		result = hashSBox [ string[i] ^ result ]

	Changed to cheaper but still effective hash function
		- ech Fed 25, 1993
*/

//
//	Added fastHash(UInt8[], count)
//		- michael Jul  5 1991 (Touched merging Jul 22 1991)

UInt32 fastHash (char * string) {
    UInt32 result = 0;
    for (Int32 i = 0; *string; i++) {
	result = hashSBoxes[i & 7][*string++] ^ result;
    }
    return result;
}

UInt32 fastHash (UInt8 * vector, int count) {
    UInt32 result = 0;
    for (Int32 i = 0; i < count; i++) {
	result = hashSBoxes[i & 7][*vector++] ^ result;
    }
    return result;
}


/* Multiply the argument integer by a couple of enormous primes to smear it.
   Only 29 bits are returned for compatibility with Smalltalk. */

UInt32 fastHash (UInt32 value) {
    /* 325221869 = 94349 * 88801 & 29 bits */
    return (value * 325221869) & 536870911;
}

/*  No implementation of ilogb available on SGI.

UInt32 fastFloatHash (IEEE64 value) {
#if defined(_MSC_VER) || defined(HIGHC) || defined(__sgi) || defined(GNUSUN)
    return 0;
#else
    if (value == 0.0 || isnan(value)) {
	return 0;
    }
    Int32 exp = ilogb(value);
    return exp ^ (UInt32) (value / (1 << (exp - 16)));
#endif
}
*/
