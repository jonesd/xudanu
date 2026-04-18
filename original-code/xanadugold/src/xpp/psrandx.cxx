/* Copyright Xanadu Operating Company.  All Rights Reserved.
	19 January 1991 at 2:23:34 pm
	From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 */


/* $Id: psrandx.cxx,v 2.10 1993/02/24 23:40:13 mark Exp $ */

#include "psrandx.hxx"

#include "parrayx.hxx"
#if defined(HIGHC) || defined(_MSC_VER)
#include <limits.h>
#else
#include <values.h>
#endif

#include "psrandx.sxx"

/* ************************************************************************ *
 * 
 *                    Class RandomStepper 

  This is a Fibonacci style pseudo random number generator.
Once initialized, values are produced by adding elements from
an array of numbers.  The array has a length N, and two
indices P and Q, which are separated by some distance D.
This array is filled initially with N numbers produces by a
congruential pseudo-random number generator from a given seed.
The contents of this array should not all be even.
The two indices are initially P==0 and Q==D.  Each value
is then
	(seed[P] + seed[Q]) mod UInt32Max.
When the next value is needed, seed[P] receives the above
value, and P and Q are incremented modulo N.  The effect
with a word size S, is that a seed with S*N bits where groups
of S bits separated by S*D bits are mixed together with each step.
If N and D are mutually prime, all bits will eventually influence all
other bits yielding cycles with lengths greatly exceeding the number
range.  One pair of N and D, 11 and 5, respectively, seem to work
quite well, while only needing a small seed array.  Empirically,
this seems to generate uniformly distributed values.  According
to my source for this algorithm (Van Nostrand Encyclopedia of
Computer Science, "random numbers"), this passes most randomness tests.
(Actually, I picked this up from one of the Ann Arbor hackers ages ago,
who in turn read about it in an article by Guy Steele.  The encyclopedia
also happens to mention it.)
Since RandomStepper is used by fastHash() which is used in tofux.cxx,
I've chosen to take the non-purist route of not making this class
a subclass of Stepper, even though it has the same interface.
Besides, you wouldn't want to use one of these in a forEach loop anyway.

 * ************************************************************************ */



/* pseudoconstructor */

RPTR(RandomStepper)  RandomStepper::make (UInt32 seed){
	RETURN_CONSTRUCT(RandomStepper,(seed, 11, 5));
}

RPTR(RandomStepper)  RandomStepper::make (UInt32 seed, UInt32 nSeeds, UInt32 sep){
	RETURN_CONSTRUCT(RandomStepper,(seed, nSeeds, sep));
}

/* private create */

RandomStepper::RandomStepper (UInt32 seed, UInt32 numSeeds, UInt32 sep) {
	/* This constructor produces a new sequence */
	
	UInt32 gen;
	
	seeds = UInt32Array::make (numSeeds);
	nSeeds = numSeeds;
	p = UInt32Zero;
	q = p + sep;

	/* This loop uses a standard congruential pseudorandom number generator to
	   produce the seed data for the Fibonacci generator.
	   The intermediate value in the expression producing 'gen,' below, is not
	   to exceed 2^32. */
	gen = seed;
	for (UInt32 i = UInt32Zero; i < nSeeds; i += 1) {
		seeds->storeUInt(i, gen);
		gen = gen * 65497 + 379 & UInt32Max;
	}

	/* We need to be sure that there are odd numbers in the seed array
	   or else the array will eventually be all zero. */
	BooleanVar foundOdd = FALSE;
	for (UInt32 j = UInt32Zero; j < nSeeds; j += 1) {
	  foundOdd |= (seeds->uIntAt(p) & 1) == 1;
	}
	if (!foundOdd) {
	  /* Just make sure some are odd */
	  for (UInt32 i = UInt32Zero; i < nSeeds; i += 4) {
	    seeds->storeUInt(i, seeds->uIntAt(i)+1);
	  }
	}

	currVal = seeds->uIntAt(p) + seeds->uIntAt(q) & UInt32Max;
	idx = UInt32Zero;
}

RandomStepper::RandomStepper (
		UInt32Array * origSeeds, 
		UInt32 numSeeds, 
		UInt32 initP, 
		UInt32 initQ, 
		UInt32 index) 
{
	/* This constructor is used by copy to clone an existing sequence */
	
	seeds = UInt32Array::make (numSeeds);
	nSeeds = numSeeds;
	p = initP;
	q = initQ;
	for (UInt32 i = UInt32Zero; i < nSeeds; i += 1) {
		seeds->storeUInt(i, origSeeds->uIntAt(i));
	}
	currVal = seeds->uIntAt(p) + seeds->uIntAt(q) & UInt32Max;
	idx = index;
}

void RandomStepper::destruct (){
	{seeds->destroy();  seeds = NULL /* don't want stale (S/CHK)PTRs */;}
	this->Heaper::destruct();
}


/* operations */

BooleanVar RandomStepper::hasValue (){
	return TRUE;
}

void RandomStepper::step (){
	seeds->storeUInt(p, currVal);
	p = (p + 1) % nSeeds;
	q = (q + 1) % nSeeds;
	currVal = seeds->uIntAt(p) + seeds->uIntAt(q) & UInt32Max;
	idx += 1;
}


/* create */

RPTR(RandomStepper) RandomStepper::copy (){
	RETURN_CONSTRUCT(RandomStepper,(seeds, nSeeds, p, q, idx));
}


/* special */

IntegerVar RandomStepper::index (){
	/* This indicates how many steps the sequence has taken; its utility
	   is questionable. */
	
	return idx;
}

UInt32 RandomStepper::value (){
	return currVal;
}


