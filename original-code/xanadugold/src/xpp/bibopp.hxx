/* ===========================================================================
//
//	Copyright (c) 1992 by Xanadu Operating Company
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

#ifndef BIBOPP_HXX
#define BIBOPP_HXX

#ifndef XCOMPATX_HXX
#include "xcompatx.hxx"
#endif /* XCOMPATX_HXX */
#include <stddef.h>

#include "bibopx.hxx"
#include "bibopp.oxx"
#include "stepperx.hxx"

class UnallocatedHeaper : public Heaper {
    MANUAL_GC(UnallocatedHeaper)
    CONCRETE(UnallocatedHeaper)
    NOT_A_TYPE(UnallocatedHeaper)

  public:

    INLINE UnallocatedHeaper * OR(NULL) fetchNextFree();

    INLINE UnallocatedHeaper (UnallocatedHeaper * OR(NULL) next, TCSJ tcsj);

    void markInstances (Heaplet * target) CONST;

    void destroy ();

  protected:

    void destruct ();

  private:

	UnallocatedHeaper * OR(NULL) myNextFree;
};

    /* BibopPage represents a page of memory in a Bibop scheme.  Each
        Page holds objects all of the same size (or possibly in a small
        range).  There is a high-water mark, above which the storage is
        unallocated.  Below the high-watermark, the space is evenly
        divided into Heapers.  Some of the Heapers may have been
        allocated and then released, in which case they will be
        represented by UnallocatedHeaper objects.  */

class BibopPage ROOTCLASS {

  public:
/* PUBLIC INTERFACE */

    /* Return a pointer to the next available storage, or NULL */
    void * OR(NULL) fetchAlloc ();

    /* assumes a range check has already been done */
    Heaper * OR(NULL) fetchContainer (void * possiblePtr);

    /* does the pointer point to a live object?  Assumes the pointer
        points into this page. */
    INLINE BooleanVar isValid(void * pointer);

    INLINE Int32 chunkSize();

    /* the offset into various arrays to find a page of mine on a free list */
    INLINE Int32 offset();

    /* return the Page after this in some thread */
    INLINE BibopPage* OR(NULL) fetchNextPage();

    /* set the Page after this in some thread.  */
    INLINE void setNextPage(BibopPage *newNext);

    BibopPage();

    /* return the first live Heaper in the page, or NULL */
    Heaper * OR(NULL) fetchFirstLiveHeaper();

    /* return the next live Heaper after the argument, or NULL */
    Heaper * OR(NULL) fetchNextLiveHeaper(Heaper * OR(NULL) previous);

    /* the heap containing this page */
    INLINE BibopHeap * OR(NULL) fetchHeap();

  private:
/*  INSTANCE VARIABLES */

    /* which BibopHeap owns all allocated chunks within this page */
    BibopHeap * OR(NULL) myHeap;

    /* what is the chunk size within this page. */
    Int32 myChunkSize;

    /* what is the offset into the free list array */
    Int32 myOffset;

    /* points at the next unallocated unformatted chunk for this page.
       If there are no such chunks, then this pointer points past the last
       possible allocatable chunk for this page.  All chunks from myNextRaw
       till the end of the page are unallocated unformatted chunks. */
    char * myNextRaw;

    /* where does the last possible Heaper go?  */
    char * myLastPossibleHeaper;

    /* The Pages containing objects of the same size are threaded
        together.  The empty Pages are threaded onto an empty page list.  */

    BibopPage * myNextPage;

  public:
/* PUBLIC STATIC METHODS for dealing with the Page Pool */

    static BibopPage * OR(NULL) fetchNewPage(BibopHeap * aHeap, Int32 chunkSize, Int32 increment);

    /* return the page containing the pointer or NULL if the pointer
       doesnt point to a valid Heaper */
    static BibopPage * OR(NULL) fetchPageForPointer(void * pointer);

    static void returnPagesToPool(BibopPage * pageThread);

    /*  add pages to the PagePool.  Assumes the pool is currently empty.  */

    static void addPagesToPagePool();

    /* set BibopLogPageSize, BibopPageSizeMask, BibopPageSize, BibopMaxMemory,
       and BibopAllocIncrement from defaults or environment.  Initializes
       ThePageMap from those values.  Must be called exactly once, before the first
       allocation.  Called by BibopHeap::defaultInitialHeap()          */
    static void initializeBibop(); 

  private:
/* PRIVATE STATIC METHODS that deal with the Page Pool */

    INLINE static void clearPageMapBit (BibopPage *aPage);
    INLINE static void setPageMapBit (BibopPage *aPage);
    INLINE static BooleanVar testPageMapBit (void *aPage);

    static void addRegionToPageMap(char * start, Int32 extent);

 private:
/*  STATICS VARIABLES for the Page Pool*/
  
    /* a bitmap showing all the pages being used for Heapers */
    static UInt8 *ThePageMap;

    /* the lowest memory address allocated for heapers.  This is also the
       memory address that the bitmap's zero'th address represents */
    static char * OR(NULL) TheLowestAllocatedMemory;

    /* the highest memory address allocated for heapers. */
    static char * OR(NULL) TheHighestAllocatedMemory;

    /*  Head of the thread of free pages.  When NULL, the PagePool is empty. */
    static BibopPage * OR(NULL) ThePagePool;

    /* how big is a Bibop page */
    static Int32 BibopLogPageSize;

    static Int32 BibopPageSizeMask;

    static Int32 BibopPageSize;

    static Int32 BibopMaxMemory;

    static Int32 BibopAllocIncrement;

 private:
/* PRIVATE helper methods */

    /* reset the page so it knows it is empty.  Assumes there are no
        Heapers needing cleanup */
    void resetHighWaterMark();

    void initializePage(BibopHeap * aHeap, Int32 chunkSize, Int32 increment);

    friend void pointerCheckExerciseOn(ostream& aStream);
};

#ifdef USE_INLINE
#include "bibopp.ixx"
#endif /* USE_INLINE */

#endif /* BIBOPP_HXX */
