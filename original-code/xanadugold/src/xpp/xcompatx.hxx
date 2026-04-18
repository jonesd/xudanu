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


/* It is intended for this file to provide portable functionality */
/*  to needed non-portable constructs.  Mostly this file provides */
/* portability between various C++ compilers */
/* This file should be acceptable to various C++s */
/*
 * CONST now always const.  Formic has been upgraded with "const:", so
 * stubble can do the right thing.
 *	- michael Nov 14 1990
 *
 * CONST now always '', because making it const breaks backend diskfulness.
 *	- michael Dec  3 1990
 *
 * Shut up xlint "hard cast" complaints at uint1() and character()
 *	- michael Apr 21 1991
  *
  * - Added PURE_VIRTUAL_BUG definition to move compatibility switching from
  *   tofu to here.  Initially defined for sgi only.
 */

#ifndef XCOMPATX_HXX
#define XCOMPATX_HXX

#ifdef sgi
#define PURE_VIRTUAL_BUG
#endif /* sgi */

#ifndef STUBBLE
#	define C_DECL_BEGIN extern "C" {
#	define C_DECL_END };
#else
#	define C_DECL_BEGIN
#	define C_DECL_END
#endif /* STUBBLE */

C_DECL_BEGIN
#	include "ccompatc.h"
C_DECL_END

VERSION_ID(xcompatx_hxx,
	   "$Id: xcompatx.hxx,v 2.7 1993/01/05 17:29:58 ravi Exp $")

#define STR_CAT(x,y) STR(x) STR(y)

class ostream;
class istream;

#ifdef XLINT
#define STUBBLE
#else
#define REQUIRE(numErrs,errNameOrAll)
#define PERMIT(nunErrsOrN,errNameOrAll)
#endif /* XLINT */

/*   fake conversion functions so that we can treat UInt8 and char as different
     types.
*/
REQUIRE(2,"hard cast")
inline UInt8 uint8(char ch) { return((UInt8) ch); }
inline char character(UInt8 ui) { return((char) ui); }
PERMIT(0,"hard cast")

#ifdef STUBBLE
#	define CONST
#else
#	define CONST /*const  confused and broken */
#endif

#ifdef PARAMETERIZED_TYPES
#	define TEMPLATE	template
#	define OF(T)		<T>
#	define OF1(T)		<T>
#	define OF2(T1,T2)	<T1,T2>
#	define OF3(T1,T2,T3)	<T1,T2,T3>
#	define OF4(T1,T2,T3,T4)	<T1,T2,T3,T4>
#	define AS(C,T)		T
#else
#	define TEMPLATE
#	define OF(T)
#	define OF1(T)
#	define OF2(T1,T2)
#	define OF3(T1,T2,T3)
#	define OF4(T1,T2,T3,T4)
#	define AS(C,T)		C
#endif

/*********
The interpretation of the above is NOT a claim that all will compile
as is in a C++ with parameterized types by just turning the flag on;
rather it is simply a structured comment that makes a claim about what
the run time types of various data must be.  It does also give us a
leg up on coverting to parameterized types, but this is besides the
point.  
*******/


/* The following turns off multiple inheritance when possible */

#ifndef STUBBLE
#	ifdef macintosh
#		define ROOTCLASS	: public SingleObject
#	else
#		define ROOTCLASS
#	endif
#else
#	define ROOTCLASS
#endif


/* Inline switches */

#define USE_INLINE

#ifdef STUBBLE
#	undef USE_INLINE
#define INLINE inline
#endif

#ifdef USE_INLINE
#	define INLINE inline
#else
#ifndef INLINE
#	define INLINE
#endif
#endif /* USE_INLINE */



#ifndef XLINT

#define LEAF virtual

/* Once we have an xlint++ to check that LEAF member functions in fact */
/*  aren't redefined in any subclass, then we can safely turn the above */
/*  into: */
/*    #define LEAF */
/*  to make production code faster & smaller.  This will also reduce the */
/*  effectiveness of tombstone checking. */

#endif /* XLINT */

#ifdef HIGHC
extern "C" {
	int xumain (int, char **);
};
#define XU_MAIN xumain
#else
#define XU_MAIN main
#endif

#endif /* XCOMPATX_HXX */
