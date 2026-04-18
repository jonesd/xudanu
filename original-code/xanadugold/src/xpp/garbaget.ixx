/* ========================================================================== */
//
//	Copyright (c) 1992 by Xanadu Operating Company
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
// ==========================================================================
//
//			garbaget.ixx
//
//	Inline code for garbage collector tests.
//
/* ========================================================================== */

#ifndef GARBAGET_IXX
#define GARBAGET_IXX

/* $Id: garbaget.ixx,v 1.3 1992/11/25 23:26:24 eric Exp $ */

/* ========================================================================== */
//
//	ConsCell test class
//
/* ========================================================================== */

INLINE ConsCell::
ConsCell(
   APTR(Heaper)		aCar
 , APTR(ConsCell)	aCdr
) {
	myCar = aCar;
	myCdr = aCdr;
}

INLINE RPTR(Heaper) ConsCell::
fetchCar() {
	return (Heaper *) myCar;
}

INLINE RPTR(ConsCell) ConsCell::
fetchCdr() {
	return (ConsCell *) myCdr;
}

INLINE void ConsCell::
setCar(APTR(Heaper) aHeaper) {
	myCar = aHeaper;
}

INLINE void ConsCell::
setCdr(APTR(ConsCell) aConsCell) {
	myCdr = aConsCell;
}

/* ========================================================================== */
//
//	gc bomb:  Force a GC to check that strong pointers aren't missed.
//
/* ========================================================================== */

BUILD_BOMB_BEGIN(gc,int) {
	cerr << "Blasting garbage.\n";
	gcOpportunity(CHARGE);
} BUILD_BOMB_END(gc);

#endif /* GARBAGET_IXX */
