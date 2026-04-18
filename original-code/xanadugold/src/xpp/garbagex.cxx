/* ===========================================================================
//
//	garbagex.cxx
//
//      Mark-and-Sweep Garbage Collector
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
// ========================================================================== */
//
// - Changed to use BombStringDetonator::currentP and fetchFirstP()
//   Rather than friendship and retired bombString global variable.
//
// - Added additional loop in Heap::collect(), so all strong pointers
//   will be seen if the GC runs during exception handling.
//	- michael Mar ...6 1992

/* $Id: garbagex.cxx,v 2.24 1993/04/10 00:53:42 eric Exp $ */

#include "garbagep.hxx"

#include "tofux.hxx"
#include "bibopx.hxx"

#include "gchooksx.hxx"
#include "tombx.hxx"
#include "parrayx.hxx"
#include "wparrayx.hxx"
#include "diagx.hxx"

PERMIT(N,"ALL")
#include <stdio.h>
#include <stdlib.h>
PERMIT(0,"ALL")

extern "C" {
#include "tracerc.h"
};

#include "garbagex.ixx"

#include "garbagep.sxx"

#define GCSWEEP_LIMIT 32

void GCMaxInterval::execute () {
    Heap::maxInterval = interval;
}

void GCMinInterval::execute () {
    Heap::minInterval = interval;
}


/* ==========================================================================
//
//	class Heap -- Give and take storage as a garbage collector
//
// ========================================================================== */

Heap * Heap::TheHeap = NULL;
Int32 Heap::TheGCIDNumber = 1;  // Never ever ever == 0

Int32 Heap::maxInterval = 20000;
Int32 Heap::minInterval = 10000;

void * Heap::allocate (size_t size)
{
    if (myCollecting) {
	myCollecting = myCollecting; // for a breakpoint
    }

    /*    recordStackTrace ();*/

    if (--myAllocCounter <= 0) {
	this->collect (FALSE, FALSE);
    }
    void * result = myAllocator->alloc (size);
    return result;
}

void Heap::free (void * /* storage */)
{
    // we do not release storage unless garbage collecting.
}

BooleanVar DoNotCollect = FALSE;

extern "C" {
    void moncontrol(int);
};

void Heap::collect (BooleanVar ignoreStack, BooleanVar hitWall)
{
    BombStringDetonator * bsd;
    WeakPtrArray * wpa;

    if (DoNotCollect) {
	return;
    }

    if (myCollecting) {
	return;  /* don''t recursively collect */
    }

    /* If we are called by the allocator, do nothing except flag for later and return */
    if (!ignoreStack) {
	    myRepairer->mustRepair();
	    return;
    }

    myCollecting = TRUE;
    myAllocCounter = -1;	// For test in allocate

    SanitationEngineer::garbageDay (hitWall);	// implementors should not allocate if hitWall

    if ((++TheGCIDNumber & (GCSWEEP_LIMIT-1)) == 0) {
	TheGCIDNumber = 1;  /* Never 0 */
    }

    /* First separate the seed */

    /* This loop takes care of globals and fluids */
    for (bsd = BombStringDetonator::currentP;
	 bsd;
	 bsd = bsd->fetchPreviousDetonatorP()) {
	for (BombSuperclass * bp = bsd->firstP; bp; bp = bp->nextP) {
	    Heaper * obj = (Heaper*) bp->gCHook ();
	    if (obj && obj->testAndSetMarked (TheGCIDNumber)) {
		obj->markInstances (TheGCIDNumber);
	    }
	}
    }

    /* Remove unreffed WeakPtrArrays */

    WeakPtrArray::unchainGarbage (TheGCIDNumber);

    /* Then check surviving WeakPtrArrays */

    EstateRecorder::reset();
    for (wpa = WeakPtrArray::list (); wpa; wpa = wpa->next()) {
	wpa->checkInstances (TheGCIDNumber);
    }

    /* Now throw out the chaff */
    {
	/* We put the DOOMSDAY_BOMB up here so the freeAllUnmarked
	   can be control flow optimized */
	PLANT_DOOMSDAY_BOMB ();
	ARM_DOOMSDAY_BOMB ();

	PrimArray::cleanup ();	// PrimArray finalization before storage release

	this->freeAllUnmarked ();

	EstateRecorder::handleAllEstates();  // also fatal if we crash here

    }

    myAllocCounter = maxInterval; // Reset interval until next collection.
    myCollecting = FALSE;

}

/* private */

void Heap::freeAllUnmarked ()
{
    Int32 localGCID = TheGCIDNumber;	/* reduce memory hits in loop */

    LiveHeaperStepper * life = myAllocator->stepper ();

    while (life->hasValue ()) {
	Heaper * obj = life->fetch ();
	if (obj->gCSweep() != localGCID) {
	    myAllocator->free (obj);
	}
	life->step ();
    }
    delete life;
}

Int32 Heap::allocCounter () {
    return myAllocCounter;
}


BooleanVar Heap::owns (void * ptr) {
    return myAllocator->isAValidHeaper (ptr);
}


/* instanciation and deinstanciation */

Heap::Heap (BibopHeap * allocator) {
    myCollecting = FALSE;
    myAllocCounter = -1;
    myEnabled = FALSE;
    myAllocator = allocator;
    myAllocator->setExhaustionHook (new GCOpportunity ());
    myRepairer = NULL;  // cannot create yet since it is a Heaper
}

Heap::~Heap () {
  delete myAllocator;
  delete myRepairer;
  if (TheHeap == this) {
      TheHeap = NULL;
  }
}

void Heap::createHeap() {
    TheHeap = new Heap (BibopHeap::defaultInitialHeap ());
    CONSTRUCT_ON(PERSISTENT,TheHeap->myRepairer,GCNecessity,());
}


/* ===========================================================================
//
//	GCNecessity
//
// ===========================================================================*/

void GCNecessity::repair () {
    if (hasToRepair) {
	Heap::current()->collect(TRUE, FALSE);	// ignore stack variables
	hasToRepair = FALSE;
    }
}

void GCNecessity::mustRepair () {
    hasToRepair = TRUE;
}

GCNecessity::GCNecessity () {
    hasToRepair = FALSE;
}


/* ===========================================================================
//
//	global name space slimer
//
// ===========================================================================*/

void gcOpportunity (Int32 hint)
{
    if (Heap::gCEnabled()) {
	Int32 allocCount = Heap::maxInterval - Heap::current()->allocCounter();

	if (allocCount > Heap::minInterval
	    || hint == -1
	    || (hint > 0 && allocCount > hint)) {
		Heap::current()->collect (FALSE, hint == -1);
	    }
    }
}

