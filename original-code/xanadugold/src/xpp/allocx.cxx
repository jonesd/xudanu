/*
      (C) Copyright 1988, 89 by Xanadu Operating Company, All Rights Reserved.

******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
**************************************************************************** */


/*===========================================================================
  |
  |  Main Memory Heap Manager
  |  Adapted from XU 88.1 using a variant of John Walker's queue package.'
  |  The allocator here, falloc() returns a pointer to the header for a
  |  new block of memory, and therefore must be under another layer of
  |  memory function before the pointer is passed to clients of new.
  |  The header is made available for use in a so-called smart memory manager.
  |   
  ===========================================================================*/

/* $Id: allocx.cxx,v 2.8 1993/03/16 22:29:40 eric Exp $ */

#include "xcompatx.hxx"
#include "tofux.hxx"
#include "initx.hxx"
#include "allocp.hxx"
#include "tombx.hxx"
PERMIT(N,"ALL")
#include <fstream.h>
#include <assert.h>
#include <stdlib.h>
#include <string.h>
#include <stream.h>
#ifdef unix
#ifndef GNU
#include <osfcn.h>
#endif GNU
#endif
PERMIT(0,"ALL")

#define ALLOCSIZE 0x1000  // Bibop''s default page granularity

#if defined(SEQUENCE_NUMBER_DANGLE_CHECK) || defined(ALLOC_REGRESSION_HOOKS)
static UInt4 serialCounter; /* = 0; */
 
UInt4 extraSequenceNumber() {
      return ++serialCounter;
}
#endif	/* SEQUENCE_NUMBER_DANGLE_CHECK || ALLOC_REGRESSION_HOOKS */

UInt4 sequenceNumber (void * addr)
{
#if defined(SEQUENCE_NUMBER_DANGLE_CHECK) || defined(ALLOC_REGRESSION_HOOKS)
    if (*((UInt4*)addr-1) == 0) {
	/* Adjust for non-heaper case */
	addr = (UInt4*) addr - 1;
    }
    return HEADER(addr)->sequenceNumber;
#else
    return 0;
#endif /* SEQUENCE_NUMBER_DANGLE_CHECK || ALLOC_REGRESSION_HOOKS */
}


static Queue freeHeapQueue;

static ABufHead * ourMoreCore (UInt4 bytesNeeded);

#define MAXALLOCQUEUEARRAY 10

/*
   We maintain lists of small unallocated objects.
   Each list contains objects of the same size.
*/
static Queue allocQueueArray[MAXALLOCQUEUEARRAY];
static Queue urdiBufferQueue;
#define URDI_BUFFER_ALLOC_SIZE 2050

/*============================================================================
  |
  |  initAllocQueues - Initialize the size sorted heaps.  This is called by
  |                    falloc on its first call.
  |   
  ===========================================================================*/

static void initAllocQueues () {
    for (int i = 0; i < MAXALLOCQUEUEARRAY; i++) {
	allocQueueArray[i].init();
    }
    urdiBufferQueue.init();
}


/*============================================================================
  |
  |  allocFromQueue - attempt to return a free object of the given size
  |   
  |  freeToQueue - place a newly free small object with others of the same
  |                size.
  |
  ===========================================================================*/

static inline ABufHead * allocFromQueue (UInt4 nUnits) {
    return (ABufHead*) allocQueueArray[nUnits].wipe();
}

static inline void freeToQueue (ABufHead * ptr) {
    allocQueueArray[ptr->numUnits].insert(&ptr->allocClass);
}


/*===========================================================================
  |
  |  falloc - return pointer to a header followed by at least nBytes of
  |           available memory.  If the request is small, first look in
  |           the size sorted structures to avoid fragmentation.  Otherwise
  |           pull it off of the freeHeapQueue queue.
  |   
  ===========================================================================*/

ABufHead * falloc (size_t nBytes) { /* I think 2.0 let this be unsigned */

    /* sizeof(ABufHead) is memory quantum, and extra unit is for header */
    UInt4 nUnits = (nBytes + sizeof(ABufHead)/* - 1*/) / sizeof(ABufHead) + 1;

    static BooleanVar haveToInitFreeHeap = TRUE;
    if (haveToInitFreeHeap) {

UInt4 testbytesToGet = NULL;
void * p1 = NULL;
 
// Note--you cannot put a print to cerr here because Iostream gets
// constructed by the first call, and a msg sent to cerr before cerr
// is constructed results in a seg fault.  It may also be worth
// noting that if memory allocation goes sour on startup you may
// not get the msg "out of memory!!" below.  hkh


	freeHeapQueue.init();
	initAllocQueues();
ourMoreCore(1024*1024);
	haveToInitFreeHeap = FALSE;
    }

    if (nUnits == URDI_BUFFER_ALLOC_SIZE) {
	ABufHead * p = (ABufHead*) urdiBufferQueue.wipe();
	if (p) {
	    return p;
	}
    } else if (nUnits < MAXALLOCQUEUEARRAY) {
	ABufHead * p = allocFromQueue (nUnits);
	if (p) {
#if defined(SEQUENCE_NUMBER_DANGLE_CHECK) || defined(ALLOC_REGRESSION_HOOKS)
	    p->sequenceNumber = 0; //++serialCounter;
#endif /* SEQUENCE_NUMBER_DANGLE_CHECK || ALLOC_REGRESSION_HOOKS */
	    return p;
	}
    }

    ABufHead * p = (ABufHead*) freeHeapQueue.next(&freeHeapQueue);
    /* Derived from K&R alloc */
    for (; /* getting fresh buffers from ourMoreCore */ ;) {

	if (p == NULL) {

	    if (ourMoreCore (nUnits * sizeof(ABufHead)) == NULL) {
		/* out of memory -- do not expect to buffer message */
#ifndef GNU
		write(((ofstream&)cerr).rdbuf()->fd(),
		      "\n*** Engine out of memory!! ***\n", 32);
#endif
		BLAST(MEM_ALLOC_ERROR);
	    }
	    
	    if (nUnits == URDI_BUFFER_ALLOC_SIZE) {
		ABufHead * p = (ABufHead*) urdiBufferQueue.wipe();
		if (p) {
		    return p;
		}
	    } else if (nUnits < MAXALLOCQUEUEARRAY) {
		ABufHead * p = allocFromQueue (nUnits);
		if (p) {
#if defined(SEQUENCE_NUMBER_DANGLE_CHECK) || defined(ALLOC_REGRESSION_HOOKS)
		    p->sequenceNumber = 0; //++serialCounter;
#endif /* SEQUENCE_NUMBER_DANGLE_CHECK || ALLOC_REGRESSION_HOOKS */
		    return p;
		}
	    }

	    /* Find resulting block.  We start at the beginning of the
	        free list since the result of ourMoreCore may have been
	        fused with another block */
	    for (p = (ABufHead*) freeHeapQueue.next (&freeHeapQueue);
		 p && p->numUnits < nUnits;
		 p = (ABufHead*) freeHeapQueue.next (&p->allocClass)) ;

	    if (p == NULL) {
		/* list corrupted */
		BLAST(MEM_ALLOC_ERROR);
	    }
	}

	UInt4 pnu = p->numUnits;

	if (pnu >= nUnits) {
	    if (pnu < nUnits+2) {
		p->allocClass.dechain();
	    } else {
		p += (p->numUnits -= nUnits);
		p->numUnits = nUnits;
		p->allocClass.init();
	    }

#if defined(SEQUENCE_NUMBER_DANGLE_CHECK) || defined(ALLOC_REGRESSION_HOOKS)
	    p->sequenceNumber = 0; //++serialCounter;
#endif /* SEQUENCE_NUMBER_DANGLE_CHECK || ALLOC_REGRESSION_HOOKS */

	    return p;
	}
	p = (ABufHead*) freeHeapQueue.next (&p->allocClass);
    }
}


/*============================================================================
  |
  |  ourMoreCore - get more memory from the system and free it onto our heap.
  |
  ===========================================================================*/

int globalsbrkcount = 0;
int allocsbrkcount = 0;
static ABufHead * ourMoreCore (UInt4 bytesNeeded) {
    /* derived from K&R */

    static BooleanVar prevFailFlag = FALSE;

    if (prevFailFlag) {
	/* Give up if we have already failed */
	return NULL;
    }

    UInt4 bytesToGet = bytesNeeded > ALLOCSIZE ? bytesNeeded : ALLOCSIZE;

    void * p = SBRK((int)bytesToGet);
globalsbrkcount += bytesToGet;
allocsbrkcount += bytesToGet;

    if (p == SBRK_FAILED) {
	prevFailFlag = TRUE;
	return NULL;
    }

    ABufHead * bp = (ABufHead*) p;

    bp->numUnits = ((UInt4)bytesToGet) / sizeof (ABufHead);
    bp->allocClass.init();

    ffree (bp);

    return (bp);
}


/*============================================================================
  |
  |  ffree - release memory to a heap.  If the piece is small, give it to
  |          the size sorted allocator, otherwise place it onto a position
  |          sorted queue with neighbor merging.
  |
  ===========================================================================*/

void ffree (ABufHead * p) {

#if defined(SEQUENCE_NUMBER_DANGLE_CHECK) || defined(ALLOC_REGRESSION_HOOKS)
/*    p->sequenceNumber = 0;*/
#endif /* SEQUENCE_NUMBER_DANGLE_CHECK || ALLOC_REGRESSION_HOOKS */

    if (p->numUnits == URDI_BUFFER_ALLOC_SIZE) {
	urdiBufferQueue.insert (&p->allocClass);
	return;
    } else if (p->numUnits < MAXALLOCQUEUEARRAY) {
	freeToQueue (p);
	return;
    }

    /* derived from K&R */
    ABufHead * afterPPtr = p + p->numUnits;
    for (Queue * q = freeHeapQueue.next (&freeHeapQueue); q; ) {
	ABufHead * qbh = (ABufHead*) q;
	if (qbh + qbh->numUnits == p) {
	    qbh->numUnits += p->numUnits;
	    return;
	} else if (afterPPtr == qbh) {
	    p->numUnits += qbh->numUnits;
	    q->replaceWith (&p->allocClass);
	    return;
	}
	if (p < qbh) {
	    q->insert (&p->allocClass);
	    return;
	}
	Queue * next = freeHeapQueue.next (q);
	if (p > qbh && (next == NULL || p < (ABufHead*)next)) {
	    q->push (&p->allocClass);
      return;
	}
	q = next;
    }
    freeHeapQueue.insert(&p->allocClass);
}

/* fcalloc imitate calloc from the library*/
//#include <memory.h> // not needed for GNU anyway!! reg june 29 1995

char * fcalloc(unsigned nelm, unsigned elsize){
	return (char *)memset( (char *) falloc(nelm*elsize),0,nelm*elsize);
}
