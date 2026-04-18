/* Copyright (c) 1993, Memex, Inc., All Rights Reserved. */

/*
		Generation Scavenging Garbage Collector
*/

/* $Id$ */

#ifndef SCAVX_HXX
#define SCAVX_HXX

#include "xcompatx.hxx"
#ifdef GNUSUN
#include <stdtypes.h>
#endif
class Heaper;

class PtrArray;
//#include "wparrayx.oxx"--introduces an inclusion loop
class WeakPtrArray;

#include "scavx.oxx"
#include "scavp.oxx"

struct ObjHead;

class PointerReferenceSet;
class ArrayReferenceSet;
class OutPointerSet;
class PtrArraySet;


/*
	Class Heaplet

	To allow cheap PrimArrayHeap compaction, the remember set
	for each page is in two parts: random pointers and pointers
	inside PtrArrays.  The first are recorded by address, while
	the later is recorded by array and index.
*/

class Heaplet ROOTCLASS {

 public: /* class stuff */

    /* Acquire storage for a new Heaper in new space. */
    static void * allocate (size_t nBytes);

    /* Acquire storage for a new Heaper in new space. */
    static ObjHead * allocateWords (Int32 nInt32s);

    /* Acquire storage for a Heaper migrating to old space. */
    static ObjHead * allocateOldWords (Int32 nInt32s);

    /* Perform a scavenge over Current */
    static void garbageCollect ();

    /* Return part of address that specifies page.  Does not check
       if pointer is actually in a page. */
    INLINE static Heaplet * pageOf (void * ptr);

    /* Return TRUE if ptr is in a scavengeable page */
    static BooleanVar isScavengeable (void * ptr);

    /* Make sure the world is set up for allocation. */
    INLINE static void initialize ();

    /* Change the tenuring age.  Return old tenuring age. */
    static Int32 setTenureAge (Int32 age);

    /* Force all objects to be tenured */
    static void tenureAll ();

    /* Updates the remembered sets (in-ptrs) for the pages referenced
       by both the old and new value of the pointer being assigned.
       The container argument is a pointer within the page holding
       the object responsible for holding the pointer.  This is
       necessary as the PrimArray classes keep their storage outside
       of the Heaplets.
       */
    /*INLINE*/ static void checkedStore (Heaper** ptr, 
				     Heaper* newValue,
				     void* container);

    /* Updates the array reference set */
    /*INLINE*/ static void checkedArrayStore (PtrArray* array,
					      Heaper** ptr,
					      Heaper* newValue,
					      Int32 index);

    /* Updates the remembered sets (in-ptrs) for the pages referenced
       by both the old and new value of the pointer being assigned
       to a WeakPtrArray. */
    /*INLINE*/ static void checkedWeakStore (WeakPtrArray* array,
					     Heaper** ptr, 
					     Heaper* newValue,
					     Int32 index);

    /* Removes the pointer from the remembered set of the page it
       references.
       The container argument is a pointer within the page holding
       the object responsible for holding the pointer.  This is
       necessary as the PrimArray classes keep their storage outside
       of the Heaplets.
       */
    static void forgetPointer (Heaper** ptr, void* container);

    /* Move the object to a new page if it''s still here.
       Returns the new address. */
    static Heaper * forward (Heaper* obj);

    /* Return NULL if obj is in CurrentDrainSet and not forwarded,
       otherwise return the new location. */
    static Heaper * forwardOrNULL (Heaper * obj);

    static void forwardToOld (Heaper ** oldPtr, Heaper ** newPtr);

 private: /* class stuff */

    /* The out-of-line work function for initialization */
    static void actualInitialize ();

    static void actualCheckedStore  (Heaper** ptr, 
				     Heaper* newValue,
				     void* container);

    static void actualCheckedArrayStore (PtrArray* array,
					 Heaper** ptr,
					 Heaper* newValue,
					 Int32 index);

    static void actualCheckedWeakStore (WeakPtrArray* array,
					Heaper** ptr, 
					Heaper* newValue,
					Int32 index);

public: /* instance stuff */

    /* Attempt to allocate storage in this page. */
    ObjHead * fetchAlloc (Int32 nInt32s);

    /* Allocate storage associated with this page, going into
       overflow if necessary.  This is used for interpage
       reference recording that must not fail. */
    ObjHead * getWords (Int32 nInt32s);

    /* Allocate storage associated with this page, going into
       overflow if necessary.  This is used for interpage
       reference recording that must not fail. */
    ObjHead * getBytes (Int32 nBytes);

    /* Do a scavenge of this page in new space */
 /*   void scavengeNew ();*/
 void scavengeNewRememberSet();
 void scavengeNewArrayRememberSet();
 void scavengeNewWeakReferenceSet();
 void scavengeNewPtrArraySet();
 void scavengeNewOutPointerSet();


    /* Add a pointer to the remember set */
    void remember (Heaper** ptr);

    /* Remove a pointer from the remember set */
    void forget (Heaper** ptr);

    /* Change a pointer in the remember set.  Useful for migration */
    void changeRemembered (Heaper** oldPtr, Heaper** newPtr);

    /* Add a pointer to the array remember set */
    void rememberArray (PtrArray* array, Int32 index,
			PtrArray* oldArray = NULL);

    /* Remove a pointer from the array remember set */
    void forgetArray (PtrArray* array, Int32 index);

    /* Change an entry in the array reference set */
    void changeArray (PtrArray* oldArray, PtrArray* newArray);

    /* Add a pointer to the weak reference set */
    void rememberWeak (WeakPtrArray* array, Int32 index,
		       WeakPtrArray* oldArray = NULL);

    /* Remove a pointer from the weak reference set */
    void forgetWeak (WeakPtrArray* array, Int32 index);

    /* Change an entry in the weak reference set */
    void changeWeak (WeakPtrArray* oldArray, WeakPtrArray* newArray);

    /* Remove all references from page from remember, array, and
       weak reference sets.  In the weak case this is to prevent
       bogus finalization if an object is collected after its
       referencing weak arrays go away. */
    void forgetFromPage (Heaplet * page);

    /* Add an outward pointer. */
    void addOutPointer (Heaplet* other);

    /* Remove an outward pointer. */
    void removeOutPointer (Heaplet* other);

    /* Record that a PtrArray resides in this page. */
    void registerPtrArray (PtrArray* array);

    /* Remove a PtrArray from this page. */
    void unregisterPtrArray (PtrArray* array);

    /* Returns TRUE if this page contains ptr. */
    INLINE BooleanVar contains (void * ptr);

    /* Returns overflow page; used by release to free group of pages */
    INLINE Heaplet * overflow ();

    Heaplet ();

 public: /* class stuff */

    /* The manager for the resevoir of free pages */
    static HeapletManager * PagePool;

    /* Pages of tenured objects believed not to be garbage */
    static HeapletSet * Old;

 public: /* fluid-like class variables */

    /* The page currently providing new storage.  This is only NULL prior
       to initialization of the heap. */
    static Heaplet * NewPage;

    /* The page current allocating space for Old objects during a migration. */
    static Heaplet * AltNewPage;

    /* Pages containing new objects to be scrutinized during next scavenge */
    static HeapletSet * Current;

    /* Pages containing new or old objects survived by current scavenge */
    static HeapletSet * NextCurrent;

    /* The set from which things are being scavenged */
    static HeapletSet * CurrentDrainSet;

    /* The age of an object moving to Old space */
    static Int32 TenureAge;

    static Int32 NumberOfPagesSinceLastCollect;

 private: /* instance stuff */

    /* Head of Heaplet */

    Int32		* myHighWaterMark;
    Int32		* myLastWord;
    Heaplet		* myOverflow;
    PointerReferenceSet * myRememberSet;
    ArrayReferenceSet   * myArrayRememberSet;
    ArrayReferenceSet   * myWeakReferenceSet;
    OutPointerSet	* myOutPointerSet;
    PtrArraySet		* myPtrArraySet;
    Int32		myHeap[1];

    friend class ScavengerTester;
};


#ifdef USE_INLINE
#include "scavx.ixx"
#endif /* USE_INLINE */

#endif /* SCAVX_HXX */
