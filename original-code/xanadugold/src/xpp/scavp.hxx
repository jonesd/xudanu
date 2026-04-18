/* Copyright (C) 1993, Memex, Inc., All rights reserved */

/* $Id$ */

#ifndef SCAVP_HXX
#define SCAVP_HXX

/* The word at the start of each object */
#define EXTENDED_HEADER 
struct ObjHead {
    int age : 16;
    int size : 16;
#ifdef EXTENDED_HEADER
    void *  objHeadPtr;
#endif
};

#define FORWARDER_FLAG (0x7DF1)	// magic value for age
#define OLD_AGE (0x701D) // another enough different that it can't increment to OLD_AGE reg sept 22 1994

/*
	Class HeapletManager

	Manages the pool of empty pages.
*/

class HeapletManager ROOTCLASS {

 public: /* class stuff */

    static HeapletManager * make ();

 private: /* class stuff */

    /* disable access to pages memory */
    static void protect (Heaplet * page);

    /* enable access to pages memory */
    static void unprotect (Heaplet * page);

    friend class ScavengerTester;  // wants to examine freshly freed pages

 public: /* instance stuff */

    /* Return TRUE if pointer is into this pool. */
    BooleanVar contains (void * ptr);

    /* Take a page from the free page pool.  Fails if none available. */
    Heaplet * take ();

    /* Release a page to the free page pool.  This is responsible for
       releasing overflow pages as well.  This is done here for
       debugability. */
    void release (Heaplet * page);

    ~HeapletManager ();

 protected:

    HeapletManager ();

 private: /* instance stuff */

    void moreStorage ();

    HeapletSet * myEmptyPagePool;

    HeapletSet * myPagePool;	// all pages, empty or used
};

/*
	Class HeapletSetStepper
*/

class HeapletSetStepper ROOTCLASS {

 public: /* stepper protocol */

    INLINE Heaplet * fetch ();

    void step ();

    HeapletSetStepper (HeapletSet * set);

 private:

    UInt32 myWord;
    Int32 myWordIndex;
    Int32 myBitIndex;
    HeapletSet * mySet;
};

/*
	Class HeapletSet
*/

class HeapletSet ROOTCLASS {

 public: /* class stuff */

    /* Return an empty set that can store size pages */
    static HeapletSet * make (Int32 size);

 public: /* instance stuff */

    /* hack test for debugging */
    static int  heapletIntersect (HeapletSet * a, HeapletSet * b);

    /* Inclusion test */
    INLINE BooleanVar contains (void * ptr);

    /* Take a page from the set.  Return NULL if set is empty */
    Heaplet * OR(NULL) take ();

    /* Remove a particular page from the set. */
    void remove (Heaplet * page);

    /* Add a page to the set */
    void introduce (Heaplet * page);

    /* Add a page to the set */
    void store (Heaplet * page);

    /* Add a range of pages to the set */
    void introduceMany (Heaplet * lowPage, Heaplet * highPage);

    /* Returns number of pages in set */

    Int32 count ();

    /* Returns a stepper to enumerate the set */
    HeapletSetStepper * stepper ();

    ~ HeapletSet ();

 protected:

    HeapletSet (Int32 size);

 private: /* instance stuff */

    friend class HeapletSetStepper;

    INLINE UInt32 wordAt (Int32 index);
    INLINE Int32  wordCount ();
    INLINE Int32  lowestIndex ();
    INLINE Int32  highestIndex ();

    Int32 mySize;  /* is only used for sanity checks at sept 14 1994 reg */
    Int32 myLowest;
    Int32 myHighest;
    Int32 myTally;

    UInt32 * myBitMap;
};


/*
	Class PointerReferenceSet
*/

#define POINTER_SET_SIZE (64)

class PointerReferenceSet ROOTCLASS {
 public:
    static PointerReferenceSet * make (Heaplet * page);
 public:
    void remember (Heaper ** refPtr);
    void change   (Heaper ** oldRefPtr, Heaper ** newRefPtr);
    void forget   (Heaper ** refPtr);
    void forgetFromPage (Heaplet * page);
    void scavengeNew (HeapletSet * drainSet);
 protected:
    PointerReferenceSet (Heaplet * page);
    Heaplet *  isOnOneOfMyPages(Heaplet * ptr);
 private:
    PointerReferenceSet * myNext;
    Heaplet * myPage;
    Int32 myCount;
    Heaper ** myRefs[POINTER_SET_SIZE];
    friend class ScavengerTester;
};

/*
	Class ArrayReferenceSet
*/

#define ARRAY_SET_SIZE (64)

class ArrayReferenceSet ROOTCLASS {
 public:
    static ArrayReferenceSet * make (Heaplet * page);
 public:
    void remember (PtrArray * array, Int32 index, PtrArray * oldArray);
    void change   (PtrArray * oldArray, PtrArray * newArray);
    void forget   (PtrArray * array, Int32 index);
    void forgetFromPage (Heaplet * page);
    void scavengeNew (HeapletSet * drainSet);
    void executeWeakly ();
 protected:
    ArrayReferenceSet (Heaplet * page);
    Heaplet *  isOnOneOfMyPages(Heaplet * ptr);
/* private:*/ public:
    ArrayReferenceSet * myNext;
    Heaplet * myPage;
    Int32 myCount;
    PtrArray * myArrays[ARRAY_SET_SIZE];
    Int32 myIndices[ARRAY_SET_SIZE];
    friend class ScavengerTester;
};


/*
	Class OutPointerSet
*/

#define OUT_POINTER_SET_SIZE (16)

class OutPointerSet ROOTCLASS {
 public:
    static OutPointerSet * make (Heaplet * page);
 public:
    void reference (Heaplet * page);
    void unreference (Heaplet * page,
		      HeapletSet * dropSet = NULL);
    /* Puts remaining old referenced pages into set */
    void dropInto (HeapletSet * oldSet,
		   HeapletSet * dropSet,
		   HeapletSet * exceptSet);
 protected:
    OutPointerSet (Heaplet * page);
 private:
    OutPointerSet * myNext;
    Heaplet * myPage;
    Int32 myCount;
    Heaplet * myRefPages[OUT_POINTER_SET_SIZE];
    Int32 myRefCounts[OUT_POINTER_SET_SIZE];
    friend class ScavengerTester;
};


/*
	Class PtrArraySet
*/

#define PTRARRAY_SET_SIZE (64)

class PtrArraySet ROOTCLASS {
 public:
    static PtrArraySet * make (Heaplet * page);
 public:
    void registerPtrArray (PtrArray * array);
    void unregisterPtrArray (PtrArray * array);
    /* Remove all arrays from target reference sets. */
    void cleanup ();
 protected:
    Heaplet *  isOnOneOfMyPages(Heaplet * ptr);
    PtrArraySet (Heaplet * page);
 private:
    PtrArraySet * myNext;
    Heaplet * myPage;
    Int32 myCount;
    PtrArray * myArrays[PTRARRAY_SET_SIZE];
    friend class ScavengerTester;
};

#ifdef USE_INLINE
#include "scavp.ixx"
#endif /* USE_INLINE */

  void checkStack(void *);
  void  checkStackInit(void *);
 ObjHead *objHeader (Heaper *);
 int objAge (Heaper *);
 Int32 objIsForwarded (Heaper *);
 Int32 objIsOld (Heaper *);
 Heaper* heaperForwardedTo (Heaper *);
 Heaper* heaperForwardedToOrHeaper (Heaper *);
 void assignForwardedTo(Heaper *, Heaper *);
#endif /* SCAVP_HXX */
