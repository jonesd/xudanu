/* Copyright Xanadu Operating Company.  All Rights Reserved.
	19 January 1991 at 2:23:34 pm
	From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 */

#ifndef PSRANDX_HXX
#define PSRANDX_HXX
/* This file group has no comment
 */

/* $Id: psrandx.hxx,v 2.6 1992/11/25 23:26:49 eric Exp $ */

#include "tofux.hxx"
#include "intvarx.hxx"

#include "parrayx.oxx"
#include "psrandx.oxx"


/* pseudoconstructor */


class RandomStepper : public Heaper {
	/* This is a Fibonacci style pseudo random number generator.
Once initialized, values are produced by adding elements from
an array of numbers.  The array has a length N, and two
indices P and Q, which are separated by some distance D.
This array is filled initially with N numbers produces by a
congruential pseudo-random number generator from a given seed.
The contents of this array should not all be even.
The two indices are initially P==0 and Q==D.  Each value
is then
	(seed[P] + seed[Q]) mod MAXINT.
When the next value is needed, seed[P] receives the above
value, and P and Q are incremented modulo N.  The effect
with a word size S, is that a seed with S*N bits where groups
of S bits separated by S*D bits are mixed together with each step.
If N and D are mutually prime, all bits will eventually influence all
other bits yielding cycles with lengths greatly exceeding the number
range.  One pair of N and D, 11 and 5, respectively, seem to work
work quite well, while only needing a small seed array.
Empirically, this seems to generate uniformly distributed values.
According to my source for this algorithm (Van Nostrand Encyclopedia
of Computer Science, "random numbers"), this passes most
randomness tests.  (Actually, I picked this up from one of the
Ann Arbor hackers ages ago, who in turn read about it in an
article by Guy Steele.  The encyclopedia also happens to mention
it.)
Since RandomStepper is used by fastHash() which is used in tofux.cxx,
I've chosen to take the non-purist route of not making this class
a subclass of Stepper, even though it has the same interface.
Besides, you wouldn't want to use one of these in a forEach loop anyway.
 */

/* Attributes for class RandomStepper */
    CONCRETE(RandomStepper)
    AUTO_GC(RandomStepper)

 public:
    static RPTR(RandomStepper)  make (UInt32 seed);

    static RPTR(RandomStepper)  make (UInt32 seed, UInt32 nSeeds, UInt32 sep);

 private: /* private create */

    /* This constructor produces a new sequence */

    RandomStepper (UInt32 seed, UInt32 numSeeds, UInt32 sep);

    /* This constructor is used by copy to clone an existing sequence */

    RandomStepper (
		   UInt32Array * origSeeds, 
		   UInt32 numSeeds, 
		   UInt32 initP, 
		   UInt32 initQ, 
		   UInt32 index)
    ;


 protected: /* destruction */

    virtual /*LEAF?*/ void destruct ();

 public: /* operations */

    virtual /*LEAF?*/ UInt32 value ();

    virtual /*LEAF?*/ BooleanVar hasValue ();

    virtual /*LEAF?*/ void step ();

    /* This indicates how many steps the sequence has taken; its utility is
       questionable. */
    
    virtual /*LEAF?*/ IntegerVar index ();

 public: /* create */

    virtual /*LEAF?*/ RPTR(RandomStepper) copy ();


 private:
    UInt32 nSeeds;
    UInt32 p;
    UInt32 q;
    CHKPTR(UInt32Array) seeds;
    UInt32 currVal;
    UInt32 idx;
};

#endif /* PSRANDX_HXX */
