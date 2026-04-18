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

#ifndef GARBAGEQ_IXX
#define GARBAGEQ_IXX

static char garbageq_ixx_rcsid[] = "$Id: garbager.ixx,v 1.5 1992/08/14 22:08:13 shap Exp $";

#include "allocx.hxx"

INLINE Heap * ownerOf (void * p) {
  return (HEADER(p)->hasHeapObject) ? Heap::current() : NULL;
}

#endif /* GARBAGEQ_IXX */
