/* ===========================================================================
//
//      Bibop (BIg Bag Of Pages) Allocator
//
// ===========================================================================
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

#ifndef BIBOPX_HXX
#define BIBOPX_HXX

#include "tofux.hxx"

#include <stddef.h>
#include <assert.h>

#include "bibopx.oxx"
#include "bibopp.oxx"

#include "loggerx.hxx"

class ExhaustionHook ROOTCLASS {
 public:
    virtual void bibopExhaustionEvent() = 0;
};

class BibopHeap ROOTCLASS {

  public:
/* PUBLIC INTERFACE */
    /* Return a pointer to the allocated storage, or BLASTs */
    void * alloc (size_t nBytes);

    /* Deallocate storage previously allocated from this heap */
    void free (void * chunk);

    /* This is faster when we already have the page */
    void freeFromPage (void * chunk, BibopPage * page);

    /* If 'possiblePtr' is indeed a pointer to an allocated chunk on this heap, 
       or a pointer within such an chunk, then return a pointer to the chunk
       itself.  Otherwise return NULL (or BLAST for 'getContainer'). */
    Heaper * OR(NULL) fetchContainer (void * possiblePtr);
    Heaper * getContainer (void * possiblePtr);

    /* Returns whether 'possiblePtr' is indeed a pointer to an allocated chunk
       on this heap.  Returns FALSE if 'possiblePtr' is either outside this
       heap, or into the middle of an allocated chunk.  Note that in the case of
       multiple inheritance, a pointer "to the object itself" may well be
       interpreted by this routine as a pointer into the middle of the chunk
       (and so return FALSE.)  When we start handling contained objects, the
       calculation will have to take pointers which appear to point into the
       middle of an object and ask the object if it really is a contained
       object. */
    BooleanVar isAValidHeaper (void * possiblePtr);

    void registerPage(BibopPage * aPage);

    BibopHeap (Int32 maxSize, Int32 increment);
    ~BibopHeap ();

    LiveHeaperStepper * stepper ();

    void setExhaustionHook(ExhaustionHook * aHook);

    /* return a BibopHeap constructed from the defaults or environment
        variables.  This method may be called to construct the first
        Heap.  All others must be created using the constructor. */
    static BibopHeap * defaultInitialHeap();

 private:
/* PRIVATE (helper functions) */

    /*  allocate pages from the PagePool.  Assumes the pool is non-empty.  */
    BibopPage * fetchPageFromPool(Int32 pageIndex);

    /* Destroying this heap also deallocates all chunks allocated on
       this heap and returns the pages to the page pool. */ 
    void destroy();

    UnallocatedHeaper * OR(NULL) fetchSimpleAlloc(Int32 pageIndex);

  private:

    Int32 myMaxSize;
    Int32 myIncrement;

    /* all the pages in this heap.  (They all have something in them, or they
       would be in PagePool instead.) */
    BibopPage * OR(NULL) myPages;

    /* Array (by size) of Pages with room above their high-water mark */
    BibopPage * OR(NULL) * myNextPageArray;

    /* Array (by size) of the head of a list of UnallocatedHeapers
       residing below high-water marks */
    UnallocatedHeaper * OR(NULL) * myFreeListArray;

    ExhaustionHook * myExhaustionHook;
};


class LiveHeaperStepper ROOTCLASS {
    /* LiveHeaperStepper is not a Heaper to since it is less to allocate
       and delete non-Heapers as temporaries during GC */

  public: /* operations */
    INLINE WPTR(Heaper) fetch ();
    WPTR(Heaper) get ();

    INLINE BooleanVar hasValue ();
    BooleanVar atEnd ();

    void step ();

  public: /* special */
    LiveHeaperStepper(BibopPage * aPage, TCSJ);

    INLINE BibopPage * page (); // an efficiency hook

  private: /* private helper method */
    void findNextPageWithLiveHeapers();

  private:
    BibopPage * myPage;
    Heaper * myHeaper;
};

/* These are the default values if the corresponding environment
variables aren't set.  

These variables must be set before any allocation is done.  They
    constrain the space taken up by all pages in all heaps.

    PageSize is the size of the pages assigned for each size of allocated
        object.  A small amount of space is taken out of this space for
        the page's header.  LogPageSize and PageSizeMask allow faster
	calculations.  PageSize must be a power of 2.
    MaxMemory is the maximum space that will be taken up by memory used by
        Bibop.  If there are multiple heaps, they share the limit.
    AllocIncrement is the incremental memory that will be requested from
        sbrk() when more pages are needed.

These two variables are constant for any heap, but can vary from heap
    to heap.

    Heap_Max_Size is the maximum size of an object within a particular
        heap.
    Heap_Increment is the step in object sizes that are alloted to the
        same pages.  When Heap_Increment is 1, there will be separate
        heaps for every size of object.  When the number is larger,
        more different sized objects will appear on the same pages
 */

#define DEFAULT_BIBOP_LOG_PAGE_SIZE     12  // page size on sun4c is 4K
#define DEFAULT_BIBOP_MAX_MEMORY        (512 * 1024 * 1024)
#define DEFAULT_BIBOP_ALLOC_INCREMENT   (1024 * 1024)
#define DEFAULT_BIBOP_HEAP_MAX_SIZE     128
#define DEFAULT_BIBOP_HEAP_INCREMENT    12  // sizeof (UnallocatedHeaper)

#define BIBOP_LOG_PAGE_SIZE_STRING      "BIBOP_LOG_PAGE_SIZE"
#define BIBOP_MAX_MEMORY_STRING         "BIBOP_MAX_MEMORY"
#define BIBOP_ALLOC_INCREMENT_STRING    "BIBOP_ALLOC_INCREMENT"
#define BIBOP_HEAP_MAX_SIZE_STRING      "BIBOP_HEAP_MAX_SIZE"
#define BIBOP_HEAP_INCREMENT_STRING     "BIBOP_HEAP_INCREMENT"

LOGGER(BibopLogger);

#ifdef USE_INLINE
#include "bibopx.ixx"
#endif /* USE_INLINE */

#endif /* BIBOPX_HXX */
