// ==========================================================================
//
//	Copyright (c) 1989 by Xanadu Operating Company
//
// ==========================================================================
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

#ifndef GARBAGEX_IXX
#define GARBAGEX_IXX

/* $Id: garbagex.ixx,v 2.7 1992/11/25 23:26:28 eric Exp $ */

INLINE Int32 Heap::gCNumber ()
{
    return TheGCIDNumber;
}

INLINE BooleanVar Heap::isCollecting () {
    return myCollecting;
}

INLINE void Heap::exists () {
    if (TheHeap == NULL) {
	Heap::createHeap ();
    }
}

INLINE Heap * Heap::current () {
    return TheHeap;
}

INLINE BooleanVar Heap::gCEnabled () {
    return TheHeap && TheHeap->myEnabled && maxInterval > 0;
}

INLINE void Heap::enableGC () {
    Heap::exists ();
    TheHeap->myEnabled = TRUE;
}

INLINE void Heap::disableGC () {
    if (TheHeap != NULL) {
	TheHeap->myEnabled = FALSE;
    }
}

INLINE BooleanVar inGC ()
{
  return Heap::current() != NULL && Heap::current()->isCollecting();
}

#endif /* GARBAGEX_IXX */
