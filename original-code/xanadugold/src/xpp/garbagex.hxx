/* ===========================================================================
//
//      Garbage Collector
//
// ===========================================================================
//
//	Copyright (c) 1989 by Xanadu Operating Company
//
// ===========================================================================
//
// The information contained herein is confidential, proprietary to Xanadu
// Operating Company, and considered a trade secret as defined in section
// 499C of the penal code of the State of California.
//
// Use of this information by anyone other than authorized employees of
// Xanadu is granted only under a written nondisclosure agreement,
// expressly prescribing the scope and manner of such use.
//
// The above copyright notice is not to be construed as evidence of
// publication or the intent to publish.
//
// =========================================================================== */


#ifndef GARBAGEX_HXX
#define GARBAGEX_HXX

/* $Id: garbagex.hxx,v 2.9 1993/02/24 01:50:10 eric Exp $ */

#include "xcompatx.hxx"

#include "bibopx.oxx"

#include <stddef.h>

/* ===========================================================================
//
//	class Heap -- Give and take storage as a garbage collector
//
// =========================================================================== */

class GCNecessity;

class Heap ROOTCLASS {
 public:

    INLINE static void exists ();
    INLINE static Heap * current ();

    INLINE static BooleanVar gCEnabled ();
    INLINE static void enableGC ();
    INLINE static void disableGC ();

    INLINE static Int32 gCNumber ();

 public:
    void * allocate (size_t size);
    void free (void * storage);

    INLINE BooleanVar isCollecting ();

    BooleanVar owns (void * ptr);

    Heap (BibopHeap * allocator);
    ~Heap ();

    /* For the non-conservative GC that sometimes occurs at the top to
       the world, all pointers on the stack are to be ignored
       */
    virtual void collect (BooleanVar ignoreStack, BooleanVar hitWall);

    static void createHeap ();

 private:
    friend void collectEarly(void*);
    friend void collectLate(void*);
    friend void gcOpportunity(Int32);

 private:
    void freeAllUnmarked ();
    Int32 allocCounter ();

    BooleanVar myCollecting;
    Int32 myAllocCounter;
    BooleanVar myEnabled;

    BibopHeap * myAllocator;
    GCNecessity * myRepairer;

    static Heap * TheHeap;
    static Int32 TheGCIDNumber;  // must be instance if multi-heap

    static Int32 maxInterval;
    static Int32 minInterval;
    friend class GCMaxInterval;
    friend class GCMinInterval;
    friend void gcOpportunity (Int32 hint);  /* change to member sometime */

};

/* =========================================================================
//
//	garbageHeap -- create a heap that collects garbage when limit bytes
//		        have been used up.  Much of this will change for
//			incremental GC.
//
// ========================================================================= */

/* Default is up to receiver;
   for now, -1 means do it now, n > 0 means on n-th alloc */
extern void gcOpportunity (Int32 hint = 0);

INLINE Heap * ownerOf (void * ptr);  /* Gets proper receiver, if any, of */
				     /*  Heap::free() */


INLINE BooleanVar inGC();  /* Return TRUE if garbage collection in progress. */
			   /* This is for use by destructors that must alter */
			   /* their behavior during garbage collection. */

#ifdef USE_INLINE
#include "garbagex.ixx"
#endif /* USE_INLINE */

#endif /* GARBAGEX_HXX */
