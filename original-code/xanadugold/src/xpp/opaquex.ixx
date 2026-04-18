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
//				opaquex.ixx
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
//	Turned on ~StrongPtrVar()'s guts.
//	 - michael May  3 1991
//
//	Added destroyIt() methods
//		- michael Jul 15 1991 (Touched merging Jul 22 1991)
//
//	- Prettified the code (my style) and fixed the xlint hooks in
//	  preparation for surgery during a fix of MB30 (failed inlining
//	  of some SPTR() constructors and destructors.)
//	- Removed some leftover commented-out incorrect dangleCheck code.
//	- Removed ditto "DONT_INLINE_FETCH" junk.
//	- Changed deep-stack code from commented out to ifdefed out.
//	- Removed commented-out get() routines (redundant with differing
//	  always-inline definitions in the .hxx.)
//		- michael Oct  4 1991
//
//	Split off opaque2x.ixx
//	(containing only those routines that need to call routines in Heaper.)
//	The routines that need to call heaper inline routines will not be
//	inlined for those pointer classes that must be defined before Tofu
//	and Heaper.  (Currently, that's destroyIt() in pointers to Heaper,
//	Xmtr, and Rcvr.)
//		- michael Oct 10 1991

#ifndef OPAQUEX_IXX
#define OPAQUEX_IXX
VERSION_ID(opaquex_ixx,
	   "$Id: opaquex.ixx,v 2.5 1992/11/25 23:26:39 eric Exp $")
#include "bombx.hxx"
#include "scavx.hxx"

#include <stream.h>
#include <string.h>

#ifndef NDEBUG
#ifdef	CATCH_DEEP_STACKS
extern char * stackTop;
#endif	/* CATCH_DEEP_STACKS */
#endif /* NDEBUG */

// ======================================================================== */
/* --------------------- GlobalStrongPtrVar inline stuff -------------------*/
// ==========================================================================

// ======================================
//  Constructors:
//   - No argument:  Point at null
//   - One argument: Point at something.
// ======================================

INLINE GlobalStrongPtrVar::GlobalStrongPtrVar() {
#ifndef NDEBUG
#ifdef	CATCH_DEEP_STACKS
	char		aChar;
	if (stackTop == NULL) {
		stackTop = &aChar;
	}
	if ((stackTop - &aChar) > 80000) {
		BLAST(STACK_TOO_DEEP);
	}
#endif	/* CATCH_DEEP_STACKS */
#endif /* NDEBUG */
	this->value = NULL;
#ifdef SEQUENCE_NUMBER_DANGLE_CHECK
	this->sequenceNumber = 0;
#endif /* SEQUENCE_NUMBER_DANGLE_CHECK */
	this->armBomb();
}

INLINE GlobalStrongPtrVar::GlobalStrongPtrVar(Heaper * p) {
	value = NULL;
	if (p) {
	    Heaplet::checkedStore (&this->value, p, this);
	}
	this->armBomb();
}

//======
// Destructor: remove from bomb string and straighten out remember sets
//======

INLINE GlobalStrongPtrVar::~GlobalStrongPtrVar () {
	Heaplet::forgetPointer (&this->value, this);
	this->disarmBomb();
}

//========
// Deref
//========

INLINE GlobalStrongPtrVar::operator Heaper* () {
	return this->value;
}

//===================
// Accessing
//===================

inline Heaper * GlobalStrongPtrVar::fetch() CONST {
	return value;
}

inline Heaper *	GlobalStrongPtrVar::get() CONST {
#ifndef NO_NULL_PTR_CHECK
	if (value == NULL) {
	    GlobalStrongPtrVar::nullPointer ();
	}
#endif /* NO_NULL_PTR_CHECK */
	return value;
}

inline void GlobalStrongPtrVar::store(Heaper * p) {
	Heaplet::checkedStore (&this->value, p, this);
}

// ======================================================================== */
/* ---------------------- CheckedPtrVar inline stuff ---------------------- */
// ======================================================================== */

// ======================================
//  Constructors:
//   - No argument:  Point at null
//   - One argument: Point at something.
// ======================================

INLINE CheckedPtrVar::CheckedPtrVar() {
	value = NULL;
#ifdef SEQUENCE_NUMBER_DANGLE_CHECK
	sequenceNumber = 0;
#endif /* SEQUENCE_NUMBER_DANGLE_CHECK */
}

INLINE CheckedPtrVar::CheckedPtrVar(Heaper * p) {
	value = NULL;   
	Heaplet::checkedStore (&this->value, p, this);
}

/* straighten out remember sets */

INLINE CheckedPtrVar::~CheckedPtrVar () {
	Heaplet::forgetPointer (&this->value, this);
}


//========
// Deref
//========

INLINE CheckedPtrVar::operator Heaper*() {
	return this->value;
}

//===================
// Accessing
//===================

inline Heaper * CheckedPtrVar::fetch() CONST {
	return value;
}

inline Heaper * CheckedPtrVar::get() CONST {
#ifndef NO_NULL_PTR_CHECK
	if (value == NULL) {
	    CheckedPtrVar::nullPointer();
	}
#endif /* NO_NULL_PTR_CHECK */
	return value;
}

inline void   CheckedPtrVar::store(Heaper * p) {
	Heaplet::checkedStore (&this->value, p, this);
}

inline void   CheckedPtrVar::forwardTo(Heaper * p) {
	this->value = p;
}

#endif /* OPAQUEX_IXX */
