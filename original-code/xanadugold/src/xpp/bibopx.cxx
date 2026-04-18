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


/* ========================================================================== */
//
//				bibopx.cxx
//
//	Executables and globals for the objects supporting Bibop (BIg Bag Of Pages).
//
//		By Chris Hibbert  August 1992  
//          based on a sketch by Mark Miller and Michael McClary
//
/* ========================================================================== */

#include "bibopp.hxx"
#include "bibopx.hxx"
#include "bibopx.sxx"
#include "bibopp.sxx"
#include "bibopx.ixx"
#include "bibopp.ixx"

#include <new.h>
#include <libc.h>	/* for memset() */
#include <stdlib.h>	/* for getenv() */
#include <osfcn.h>	/* for sbrk() */

VERSION_ID(bibopx_cxx,
	   "$Id: bibopx.cxx,v 3.13 1993/03/19 23:24:48 eric Exp $");

/* ************************************************************************ *
 * 
 *                    Class     UnallocatedHeaper
 *
 * ************************************************************************ */

void UnallocatedHeaper::markInstances (Heaplet * /* target */) CONST {
    // should not point at these
    BLAST(MEM_ALLOC_ERROR);
}

void UnallocatedHeaper::destroy() {
    BLAST(MEM_ALLOC_ERROR);
}

void UnallocatedHeaper::destruct() {
    BLAST(MEM_ALLOC_ERROR);
}


/* ************************************************************************ *
 * 
 *                    Class     BibopPage
 *
 * ************************************************************************ */

 
char * OR(NULL) BibopPage::TheLowestAllocatedMemory = NULL;
char * OR(NULL) BibopPage::TheHighestAllocatedMemory = NULL;
BibopPage * OR(NULL) BibopPage::ThePagePool = NULL;
UInt8 * OR(NULL) BibopPage::ThePageMap = NULL;

Int32 BibopPage::BibopLogPageSize = 0;
Int32 BibopPage::BibopPageSizeMask = 0;
Int32 BibopPage::BibopPageSize = 0;
Int32 BibopPage::BibopMaxMemory = 0;
Int32 BibopPage::BibopAllocIncrement = 0;

/* If there's space for another Heaper in this page, return a
pointer to the space for it, and bump the high water mark.  Doesn't
affect the free list.  */

void * OR(NULL) BibopPage::fetchAlloc ()
{
    void * result = myNextRaw;
    if (result <= myLastPossibleHeaper) {
        myNextRaw += myChunkSize;
#ifdef BIBOP_VERBOSE_LOGGING
        BibopLogger << "*" << myOffset;
#endif /* BIBOP_VERBOSE_LOGGING */
        return result;
    } else {
        return NULL;
    }
}

/* assumes a range check has already been done to ensure the address is within the page. */
Heaper * OR(NULL) BibopPage::fetchContainer (void * possiblePtr)
{
    if (myChunkSize == 0 
        || possiblePtr >= myNextRaw
        || possiblePtr < (char *)this + sizeof(BibopPage)) {
        return NULL;
    }

    Heaper * result;
    /* truncate possiblePtr to a multiple of myChunkSize offset from myNextRaw.
       Use myNextRaw, since it's aligned with the objects; myLastPossibleHeaper
       isn't.  */
    result = (Heaper *) ((char *)possiblePtr -
                         (((char *)possiblePtr - ((char *)this + sizeof(BibopPage)))
                             % myChunkSize));

    if (result->gCSweep()) {
        return result;
    } else {
        return NULL;
    }
}

BibopPage::BibopPage()
{
    if (BibopPage::BibopPageSize == 0) {
	/* Bibop not initialized */
        BLAST(MEM_ALLOC_ERROR);
    }
    myChunkSize = 0;
    myNextPage = ThePagePool;
    ThePagePool = this;
    myHeap = NULL;
    myNextRaw = (char *)this + sizeof(BibopPage);
    myLastPossibleHeaper = (char *)this;    /* can't allocate w'out init */
}

Heaper * OR(NULL) BibopPage::fetchFirstLiveHeaper()
{
    if (myChunkSize == 0
        || myNextRaw <= (char *)this + sizeof(BibopPage)) {
        return NULL;
    }
    Heaper *firstHeaper = (Heaper *)((char *)this + sizeof(BibopPage));
    if (firstHeaper->gCSweep()) {
        return firstHeaper;
    } else {
        return this->fetchNextLiveHeaper(firstHeaper);
    }
}

Heaper * OR(NULL) BibopPage::fetchNextLiveHeaper(Heaper * previous)
{
    Int32 chunkSize = myChunkSize; // these two make the sun optimizer
    char * nextRaw = myNextRaw;    // use the result register for nextHeaper
    for (Heaper * nextHeaper = (Heaper *)((char *)previous + chunkSize)
             ; (char *) nextHeaper < nextRaw
             ; nextHeaper = (Heaper *)((char *)nextHeaper + chunkSize)) {
        if (nextHeaper->gCSweep()) {
            return nextHeaper;
        }
    }
    return NULL;
}

BibopPage * OR(NULL) BibopPage::fetchNewPage(BibopHeap * aHeap, Int32 chunkSize, Int32 increment)
{
    if (ThePagePool == NULL) {
        return NULL;
    }
    BibopPage *result = ThePagePool;
    ThePagePool = result->fetchNextPage();
    result->setNextPage(NULL);
    result->initializePage(aHeap, chunkSize, increment);
    return result;
}

void BibopPage::resetHighWaterMark()
{
    myChunkSize = 0;
    myHeap = NULL;
    myNextRaw = (char *)this + sizeof(BibopPage);
    myLastPossibleHeaper = (char *)this;    /* can't allocate w'out init */
    BibopPage::clearPageMapBit(this);
}

void BibopPage::returnPagesToPool(BibopPage * pageThread)
{
    BibopPage * pageToReset;

    /* reset the HighWater mark for all the pages in this thread.  */
    for (pageToReset = pageThread;
         pageToReset->fetchNextPage() != NULL ;
         pageToReset = pageToReset->fetchNextPage())
    {
        pageToReset->resetHighWaterMark();
    }
    /* we stopped before the end so we can splice next.  Need to catch the
        last page here.  */
    pageToReset->resetHighWaterMark();

    /*  splice the entire thread to the front of ThePagePool */
    pageToReset->setNextPage(ThePagePool);
    ThePagePool = pageThread;
}

void BibopPage::addPagesToPagePool()
{
    int extentToAskFor;          /* ALLOC_INCREMENT minus any fractional page */
    Int32 actualExtent;   /* extentToAskFor minus PAGE_SIZE if sbrk screws us */
    char * space;                               /* where the pages will start */
    char * chunk;              /* pointer to each page as it gets constructed */
    Int32 pageSize = BibopPage::BibopPageSize;
    Int32 allocIncrement = BibopPage::BibopAllocIncrement;

    assert(ThePagePool == NULL);

    extentToAskFor = (int)(allocIncrement - (allocIncrement & BibopPage::BibopPageSizeMask));
    space = SBRK(extentToAskFor);
    if (space == SBRK_FAILED) {
        BLAST(MEM_ALLOC_ERROR);
    }

    /* make sure the space ends on an even PAGE_SIZE boundary, so we can
           allocate full pages up to the end */
    if ((int)space & BibopPage::BibopPageSizeMask) {

                /* size of fractional page at low end of space */
        int fragmentSize = (int)(pageSize - ((int)space & BibopPage::BibopPageSizeMask));

                /* fill out the fractional page at the end */
        char * fragment = SBRK(fragmentSize);
        if (fragment == SBRK_FAILED) {
            BLAST(MEM_ALLOC_ERROR);
        }
        if (fragment == space + extentToAskFor) {  /* sbrk returned a contiguous piece */
                    /* throw away the fractional page at the low end */
            space += fragmentSize;
            actualExtent = extentToAskFor;
            BibopLogger << "\nsbrk returned unaligned memory: " << fragmentSize << "\n";
        } else {
                    /* throw away the fractional pages at the low and high ends */
            space += fragmentSize;
            actualExtent = extentToAskFor - pageSize;
            BibopLogger << "\nsbrk returned unaligned non-contiguous memory: " 
                << actualExtent << "\n";
        }
    } else {
        BibopLogger << "\nsbrk returned aligned memory: " << extentToAskFor << "\n";
        actualExtent = extentToAskFor;
    }

    BibopPage::addRegionToPageMap(space, actualExtent);

    /* split the initial allocation into empty pages */
    for (chunk = space ; chunk + pageSize < space + actualExtent ; chunk += pageSize)
    {
        new (chunk) BibopPage();
    }
}

BibopPage * OR(NULL) BibopPage::fetchPageForPointer(void * pointer)
{
    /* first test: does the (candidate) pointer point into the area of
        memory containing heapers? */
    if (pointer < TheLowestAllocatedMemory || pointer > TheHighestAllocatedMemory) {
	return NULL;
    }

    /* second test: It is in the space represented by the bitmap; is
       the bit representing the page containing this ptr on? */
    if (testPageMapBit((BibopPage *)pointer)) {
	return (BibopPage *)((char *)pointer -
			     ((Int32)pointer & BibopPage::BibopPageSizeMask));
    } else {
	return NULL;
    }
}

void BibopPage::addRegionToPageMap(char * start, Int32 extent)
{
    if (TheLowestAllocatedMemory == NULL) {
        assert(((Int32)start & BibopPage::BibopPageSizeMask) == 0);

        TheLowestAllocatedMemory = start;
        TheHighestAllocatedMemory = start + extent - 1;
    } else if (TheHighestAllocatedMemory < start) {
        TheHighestAllocatedMemory = start + extent - 1;
        if (TheHighestAllocatedMemory > TheLowestAllocatedMemory + BibopPage::BibopMaxMemory) {
            BLAST(BIBOP_ALLOC_MORE_THAN_MAX);
        }
    } else {        /*  We got lower memory */
	/* Unimplemented need to move page map */
        BLAST(MEM_ALLOC_ERROR);
        assert(((Int32)TheLowestAllocatedMemory & BibopPage::BibopPageSizeMask)== 0);
    }
}

void BibopPage::initializeBibop()
{
    char * envValue;

    if (BibopPage::ThePageMap != NULL) {
	/* Bibop heap initialized twice */
        BLAST(MEM_ALLOC_ERROR);
    }

    envValue = getenv(BIBOP_LOG_PAGE_SIZE_STRING);
    if (envValue != NULL) {
        BibopPage::BibopLogPageSize = strtol(envValue, (char **)NULL, 0);
    }
    if (BibopPage::BibopLogPageSize == 0) {
        BibopPage::BibopLogPageSize = DEFAULT_BIBOP_LOG_PAGE_SIZE;
    }

    BibopPage::BibopPageSize = 1 << BibopPage::BibopLogPageSize;
    BibopPage::BibopPageSizeMask = BibopPage::BibopPageSize - 1;

    envValue = getenv(BIBOP_MAX_MEMORY_STRING);
    if (envValue != NULL) {
        BibopPage::BibopMaxMemory = strtol(envValue, (char **)NULL, 0);
    }
    if (BibopPage::BibopMaxMemory == 0) {
        BibopPage::BibopMaxMemory = DEFAULT_BIBOP_MAX_MEMORY;
    } 

    envValue = getenv(BIBOP_ALLOC_INCREMENT_STRING);
    if (envValue != NULL) {
        BibopPage::BibopAllocIncrement = strtol(envValue, (char **)NULL, 0);
    }
    if (BibopPage::BibopAllocIncrement == NULL) {
        BibopPage::BibopAllocIncrement = DEFAULT_BIBOP_ALLOC_INCREMENT;
    }

    BibopPage::ThePageMap = (UInt8 *)SBRK((int)
                 ((BibopPage::BibopMaxMemory >> BibopPage::BibopLogPageSize) / 8) + 1);
    if (BibopPage::ThePageMap == SBRK_FAILED) {
        BLAST(MEM_ALLOC_ERROR);
    }
}

void BibopPage::initializePage(BibopHeap * aHeap, Int32 chunkSize, Int32 increment)
{
    myHeap = aHeap;
    myChunkSize = chunkSize;
    myOffset = (chunkSize - 1) / increment;
    myLastPossibleHeaper = (char *)this + BibopPage::BibopPageSize - chunkSize;
    BibopPage::setPageMapBit(this);
    myHeap->registerPage(this);
}

/* ************************************************************************ *
 * 
 *                    Class     BibopHeap
 *
 * ************************************************************************ */

/* Return a pointer to the allocated storage, or BLASTs */
void * BibopHeap::alloc (size_t nBytes)
{
    void * result;
    if (nBytes > myMaxSize) {
        BLAST(MEM_ALLOC_ERROR);
    }

    if (nBytes < sizeof(UnallocatedHeaper)) {
        nBytes = sizeof(UnallocatedHeaper);
    }

    Int32 pageIndex = (nBytes - 1) / myIncrement;

    /*  Plan of attack:

        1  try a simple alloc which is:
            a  Try the free list.
            b  Try above the high-water mark
        2  try to get a new page from the page pool.
        3  Declare an exhaustion event and see if space was
            released (ie try simple again) !!!! do this sooner???
        4  Try to get more space from sbrk()

      Before we go to conservative GC, this is the right order.  Once we 
      have a generational scheme, it will make more sense to swap (a) and (b).
    */

    if ((result = fetchSimpleAlloc(pageIndex)) != NULL) {
        return result;
    }

    BibopPage * OR(NULL) page = fetchPageFromPool(pageIndex);

    if (page == NULL && myExhaustionHook != NULL) {
#ifdef BIBOP_VERBOSE_LOGGING
            BibopLogger << "\nExhaustion!\n";
#endif /* BIBOP_VERBOSE_LOGGING */
        myExhaustionHook->bibopExhaustionEvent();
        if ((result = fetchSimpleAlloc(pageIndex)) != NULL) {
            return result;
        }

        /*  The following only helps if we're using a generational
            scheme, but it doesn't hurt much before that.  */
        page = fetchPageFromPool(pageIndex);
    }

    if (page == NULL) {
        /* get more space and try to get a new page again. */
        BibopPage::addPagesToPagePool();
        page = fetchPageFromPool(pageIndex);
    }

    if (page == NULL) {
	/* Unable to allocate new bibop page */
        BLAST(MEM_ALLOC_ERROR);
    }

    result = page->fetchAlloc();
    if (result == NULL) {
	/* Unable to allocate from new page */
        BLAST(MEM_ALLOC_ERROR);
    }

    return result;
}

UnallocatedHeaper * OR(NULL) BibopHeap::fetchSimpleAlloc(Int32 pageIndex)
{
    /* first look in appropriate free list */

    UnallocatedHeaper * result = myFreeListArray[pageIndex];

    if (result != NULL) {
#ifdef BIBOP_VERBOSE_LOGGING
        BibopLogger << "+" << pageIndex;
#endif /* BIBOP_VERBOSE_LOGGING */
        myFreeListArray[pageIndex] = result->fetchNextFree();
	return result;
    }

    /*  look above the high-water mark in the current next page */

    BibopPage *page = myNextPageArray[pageIndex];

    if (page != NULL) {
        result = (UnallocatedHeaper *)(page->fetchAlloc());
    }
    return result;
}

/* Deallocate storage previously allocated from this heap */
void BibopHeap::free (void * chunk)
{
    BibopPage * page = BibopPage::fetchPageForPointer(chunk);
    if (page == NULL) {
	/* Attempt to free object not in heap */
        BLAST(MEM_ALLOC_ERROR);
    }
    assert(page->fetchHeap() == this);
    if (!page->isValid(chunk)) {
        BLAST(MEM_ALLOC_ERROR);
    }
    Int32 offset = page->offset();
    UnallocatedHeaper * unalloc = new (chunk) UnallocatedHeaper(myFreeListArray[offset], tcsj);
#ifdef BIBOP_VERBOSE_LOGGING
    BibopLogger << "(" << offset << ")";
#endif /* BIBOP_VERBOSE_LOGGING */
    myFreeListArray[offset] = unalloc;
}

/* Deallocate storage previously allocated from this heap from a known page*/
void BibopHeap::freeFromPage (void * chunk, BibopPage * page)
{
    Int32 offset = page->offset();
    UnallocatedHeaper * unalloc = new (chunk) UnallocatedHeaper(myFreeListArray[offset], tcsj);
    myFreeListArray[offset] = unalloc;
}

/* If 'possiblePtr' is indeed a pointer to an allocated chunk on this heap,
   or a pointer within such an chunk, then return a pointer to the Heaper.
   Otherwise return NULL (or BLAST for 'getContainer'). */
Heaper * OR(NULL) BibopHeap::fetchContainer (void * possiblePtr)
{
    BibopPage * page = BibopPage::fetchPageForPointer(possiblePtr);
    if (page != NULL && page->fetchHeap() == this) {
        return(page->fetchContainer(possiblePtr));
    } else {
        return NULL;
    }
}

Heaper * BibopHeap::getContainer (void * possiblePtr)
{
    BibopPage * page = BibopPage::fetchPageForPointer(possiblePtr);
    if (page != NULL && page->fetchHeap() == this) {
        Heaper * obj = page->fetchContainer(possiblePtr);
        if (obj != NULL) {
            return obj;
        }
    }
    /* Pointer not to live heaper */
    BLAST(MEM_ALLOC_ERROR);
    return NULL; // hush up compiler
}

BooleanVar BibopHeap::isAValidHeaper (void * possiblePtr)
{
    BibopPage * page = BibopPage::fetchPageForPointer(possiblePtr);
    if (page != NULL && page->fetchHeap() == this) {
        return(page->isValid(possiblePtr));
    } else {
        return FALSE;
    }
}

void BibopHeap::registerPage (BibopPage * aPage)
{
    aPage->setNextPage(myPages);
    myPages = aPage;
}

BibopHeap::BibopHeap (Int32 maxSize, Int32 increment)
{
    myMaxSize = maxSize;
    myIncrement = increment;
    int arraySize = (int)((maxSize - 1) / myIncrement);
    myNextPageArray = new BibopPage * [arraySize];
    myFreeListArray = new UnallocatedHeaper * [arraySize];
    myPages = NULL;
    myExhaustionHook = NULL;

    memset(myNextPageArray, 0, arraySize * (sizeof(BibopPage *)));
    memset(myFreeListArray, 0, arraySize * (sizeof(UnallocatedHeaper *)));
}

BibopHeap::~BibopHeap ()
{
    /* We don't need to touch the Pages in myNextPageArray separately,
       since they're all threaded in myPages. */
    BibopPage::returnPagesToPool(myPages);
    myPages = NULL;

    /* reset the FreeList of UnallocatedHeapers and the Pages with room.
       No need to do anything to the UnallocatedHeapers individually,
       since their respective HighWater marks have all been reset. */
    delete(myNextPageArray);
    delete(myFreeListArray);
}

BibopHeap * BibopHeap::defaultInitialHeap()
{
    char * envValue;
    Int32 maxSize;
    Int32 increment;

    BibopPage::initializeBibop();

    envValue = getenv(BIBOP_HEAP_MAX_SIZE_STRING);
    if (envValue == NULL) {
        maxSize = DEFAULT_BIBOP_HEAP_MAX_SIZE;
    } else {
        maxSize = strtol(envValue, (char **)NULL, 0);
    }

    envValue = getenv(BIBOP_HEAP_INCREMENT_STRING);
    if (envValue == NULL) {
        increment = DEFAULT_BIBOP_HEAP_INCREMENT;
    } else {
        increment = strtol(envValue, (char **)NULL, 0);
    }

    return new BibopHeap(maxSize, increment);
}

void BibopHeap::setExhaustionHook (ExhaustionHook * aHook) {
    myExhaustionHook = aHook;
}

LiveHeaperStepper * BibopHeap::stepper ()
{
    return new LiveHeaperStepper (myPages, tcsj);
}

BibopPage * BibopHeap::fetchPageFromPool(Int32 pageIndex)
{
    BibopPage * result = BibopPage::fetchNewPage(this, (pageIndex + 1) * myIncrement, myIncrement);

    if (result == NULL) {
        return NULL;
    }
    myNextPageArray[pageIndex] = result;
    return result;
}

/* Destroying this heap also deallocates all chunks allocated on
   this heap and returns the page to the page pool. */ 
void BibopHeap::destroy()
{
    delete this;
}

/* ************************************************************************ *
 * 
 *                    Class     LiveHeaperStepper
 *
 * ************************************************************************ */

Heaper * OR(NULL) LiveHeaperStepper::get()
{
    if (myHeaper == NULL) {
	/* Empty stepper */
        BLAST(MEM_ALLOC_ERROR);
    } else {
        return myHeaper;
    }
}

BooleanVar LiveHeaperStepper::atEnd()
{
    return myHeaper == NULL;
}

void LiveHeaperStepper::step()
{
/*    if (myHeaper == NULL) {
		BLAST(MEM_ALLOC_ERROR);
    }
*/
    /* step to the next live heaper in this page */

    if ((myHeaper = myPage->fetchNextLiveHeaper(myHeaper)) == NULL) {

	this->findNextPageWithLiveHeapers();

    }
}

LiveHeaperStepper::LiveHeaperStepper(BibopPage * aPage, TCSJ)
{
    myPage = aPage;
    if (myPage == NULL) {
        myHeaper = NULL;
    } else {
        myHeaper = myPage->fetchFirstLiveHeaper();
        if (myHeaper == NULL) {
	    this->findNextPageWithLiveHeapers();
        }
    }
}

void LiveHeaperStepper::findNextPageWithLiveHeapers()
{
    for (myPage = myPage->fetchNextPage()
         ; myPage != NULL &&
           (myHeaper = myPage->fetchFirstLiveHeaper()) == NULL
         ; myPage = myPage->fetchNextPage()) {
             /*  empty loop */
         }
    if (myPage == NULL) {
	myHeaper = NULL;
    }
    return;
}

DEFINE_LOGGER(BibopLogger,NULL);
