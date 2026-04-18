/* Copyright Xanadu Operating Company 1990, All Rights Reserved */

#ifndef PARRAYP_HXX
#define PARRAYP_HXX

/* $Id: parrayp.hxx,v 3.6 1993/04/10 00:53:45 eric Exp $ */

#include "parrayx.hxx"
#include "wparrayx.hxx"
#include "parrayp.oxx"
#include "initx.hxx"

/* ************************************************************************ *
 * 
 *                    Class PrimArrayHeap
 *
 * ************************************************************************ */

class PrimArrayHeap ROOTCLASS {
 public:

    /* allocate from particular heap in sizeof(Int32) units and register array */
    Int32 * allocate (Int32 nWords, APTR(PrimArray) pa);

    /* compacts array table after GC */
    void removeDestructedArrays ();

    PrimArrayHeap (Int32 size);

 private:
    void compact ();

 private:
    PrimArrayHeap * myNextHeap;

    Int32 * myEndSpace;			/* start of contiguous space at end */
    PrimArray ** myPrimArrayTable;	/* table of live PrimArrays on this heap */
    Int32 * myLastWord;			/* Last word in heap */
    PrimArray ** myFirstAfterHole;	/* PrimArray table entry */
    					/*  after first hole in heap or NULL */

    Int32 *myHeapStore;			/* the actual heap storage */

 public:	/* "class" methods */

    /* compacts all array tables after GC */
    static void cleanup ();

    static Int32 * getStorage (Int32 nWords, APTR(PrimArray) pa);  /* from any heap */

 private:	/* "class" instances */

    static PrimArrayHeap * FirstHeap;	/* list of all PrimArrayHeaps in system */

 private:
    friend class PrimArrayTester;
};


extern Int32 HeapChunkSize; /* Hook so tests can detune compactor */

#endif /* PARRAYP_HXX */
