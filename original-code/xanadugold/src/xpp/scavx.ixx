#ifndef SCAVX_IXX
#define SCAVX_IXX

#define PAGEADDRBITS (14)
#define MAXPAGES (1<<(32-PAGEADDRBITS))
#define PAGESIZE (1<<(PAGEADDRBITS))
#define PAGEMASK (((UInt32)-1)<<(PAGEADDRBITS))
#define ALLOCINCR (1024*1024*1)

/* Return part of address that specifies page.  Does not check
    if pointer is actually in a page.  Simple enough, just clip
    the last 14 address bits off hkh */
INLINE Heaplet * Heaplet::pageOf (void * ptr) {
    return (Heaplet*) ((Int32) ptr & PAGEMASK);
}

/* Make sure the world is set up for allocation */

/* The reason for the very odd placement of an *INLINE* initiallizer
is because this is getting called every! time a constructor is
called in tofu.  There might be another way to do this . . . but this is 
fairly inexpensive. */

INLINE void Heaplet::initialize () {
    if (!NewPage) {
	Heaplet::actualInitialize ();
    }
}

/* Returns TRUE if this page contains ptr.  Reads ptr ge myHeap and
ptr < myHWM hkh */

INLINE BooleanVar Heaplet::contains (void * ptr) {
    return ptr >= myHeap && ptr < myHighWaterMark;
}

/* Returns overflow page; used by release to free group of pages */
INLINE Heaplet * Heaplet::overflow () {
    return myOverflow;
}

#endif /* SCAVX_IXX */
