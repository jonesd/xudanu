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

#include "hsboxx.hxx"

/* Adapted from 
	"Fast Hashing of Variable-Length Text Strings"
	Peter K. Pearson
	Communications of the ACM
	June 1990
	Volume 33, Number 6, pp 677-680

	The original generates an 8-bit value using the iterand
		result = hashSBox [ string[i] ^ result ]
*/

unsigned long fastHash (char * string) {
  unsigned long result = 0;
  for (int i = 0; *string; i++) {
    result = hashSBoxes[i & 7][(*string++ ^ result) & 255] ^ result;
  }
  return result;
}

unsigned long fastHash (char * vector, int count) {
  unsigned long result = 0;
  for (int i = 0; i < count; i++) {
    result = hashSBoxes[i & 7][(*vector++ ^ result) & 255] ^ result;
  }
  return result;
}


/* Multiply the argument integer by a couple of enormous primes to smear it.
   Only 29 bits are returned for compatibility with Smalltalk. */

unsigned long fastHash (unsigned long value) {
  /* 325221869 = 94349 * 88801 & 29 bits */
  return (value * 325221869) & 536870911;
}
