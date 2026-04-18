/* ========================================================================== */
//
//	Copyright (c) 1988, 1989, 1991 by Xanadu Operating Company, All
//	Rights Reserved.
//
/* ========================================================================== */
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
/* ========================================================================== */
//
//				opaque2x.ixx
//
//	This module allows the declaration of the inheritance relationship
//	of classes, and the definition of pointers-with-lots-of-behavior-to
//	instances of those classes, without exposing the implementation
//	of the classes to which the pointers point.
//
//	It is called "opaque" because such declarations-without-exposure
//	are said to be opaque (though some have suggested it's really
//	because this module is excessively complex and confusing).
//
/* ========================================================================== */
//
//	Added destroyIt() methods
//		- michael Jul 15 1991 (Touched merging Jul 22 1991)
//
//	Split off opaque2x.ixx
//	(containing only those routines that need to call routines in Heaper.)
//	The routines that need to call heaper inline routines will not be
//	inlined for those pointer classes that must be defined before Tofu
//	and Heaper.  (Currently, that's destroyIt() in pointers to Heaper,
//	Xmtr, and Rcvr.)
//		- michael Oct 10 1991

#ifndef OPAQUE2X_IXX
#define OPAQUE2X_IXX

/* $Id: opaque2x.ixx,v 2.4 1992/11/25 23:26:33 eric Exp $ */

// ======================================================================== */
/* ----------------------- CheckedPtrVar inline stuff ---------------------- */
// ==========================================================================

/* ============================================================== */
//  Next couldn't be in the hxx because Heaper was still opaque.
// !!!! Not checked with both settings of inline switching.
/* ============================================================== */

INLINE void CheckedPtrVar::destroyIt() {
	Heaper *	tValue;
	tValue = this->get();
	this->store(NULL);
	tValue->destroy();
}

// ======================================================================== */
/* ----------------------------- GlobalStrongPtrVar inline stuff -------------------*/
// ==========================================================================

/* ============================================================== */
//  Next couldn't be in the hxx because Heaper was still opaque.
// !!!! Not checked with both settings of inline switching.
/* ============================================================== */

INLINE void GlobalStrongPtrVar::destroyIt() {
	Heaper *	tValue;
	tValue = this->get();
	this->store(NULL);
	tValue->destroy();
}

#endif /* OPAQUE2X_IXX */
