/*
      (C) Copyright 1988, 89 by Xanadu Operating Company, All Rights Reserved.

******************************************************************************
*									     *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
**************************************************************************** */


/* It is intended for this file to provide portable functionality */
/*  to needed non-portable constructs. */
/* This file should be acceptable to both C & C++ */
/****
 *
 *	Added CAT3 (Hopefully compatible with WJR's, which I was surprised not
 *	 to find in the file)  
 *		-- MarkM 8/10/90
 *
 *	Made BooleanVar into a nice transmittable UInt1
 *	Added ALERT_CHAR
 *	Added VOLATILE
 *		-- MarkM 8/22/1990
 *
 *	Made BooleanVar into an 'int', exactly the type returned by
 *	operators ||, &&, ==, !=, etc.
 *	Made possible by elimination of overloading in comm stuff.
 *	Also, any sane binary comm code should not use more than
 *	one byte to send the values 0 and 1.
 *		-- ECH 5/15/91
 *    - Moved macro overrides for bcopy and memmove from scattered places
 *	to here, now that both macintosh and sgi need them.
 *    - Added #deinfe of STD_CPP if sgi is defined.
 *    - Added definition of _environ, which is missing from sgi's libc.h
 *     (Check that this is still needed!!!!)
 *	      - michael Aug 29/Sep 5 1991 (Merged Mar 24 1992)
 *
 ****/


#ifndef CCOMPATC_H
#define CCOMPATC_H

#ifndef STD_CPP
#	ifdef __STDC__
#		define STD_CPP
#	endif /* __STDC__ */

#	ifdef __sgi
#       ifndef STUBBLE
#    		define STD_CPP
#       endif
#	endif 

#	ifdef applec
#		define STD_CPP
#	endif /* applec */

#endif /* STD_CPP */

/* CAT must be up here for the VERSION_ID macros */

/* CAT concatenates its arguments so they can form a single token */
#if defined(STD_CPP) || defined(HIGHC) /* ANSI Standard way: */
/*
 * ANSI C preprocessors will not expand the arguments to a macro;
 * so we need to add a level of indirection to allow macro expansion of
 * arguments.  (Reiser preprocessors allowed the first arg to be expanded;
 * this method will allow both to be expanded, which is better than none.)
 */
/*
 * I don't believe the above statement is correct wrt the ANSI spec.
 * However, I'm sure it's true of some claimed-to-be-ANSI preprocessors,
 * so the code below is proper.
 *   -- MarkM
 */
 
#	define CAT(x,y) CAT_AUX(x,y)
#	define CAT_AUX(x,y) x ## y
#	define CAT3(x,y,z) CAT3_AUX(x,y,z)
#	define CAT3_AUX(x,y,z) x ## y ## z
#else
#	ifdef BSD /* non-standard BSD way: */
#		define CAT(x,y) x\
y
#		define CAT3(x,y,z) x\
y\
z
#	else /* non-standard System V way: */
#		define CAT(x,y) x/**/y
#		define CAT3(x,y,z) x/**/y/**/z
#	endif /* BSD */
#endif /* __STDC__ */

#define VERSION_ID_STRING(file)	CAT(file,_rcsId)
#define VERSION_ID_FUNC(file)	CAT(file,_idString)

#define VERSION_ID(file,string)
/*			\
static char VERSION_ID_STRING(file)[] = string;	\
static char *VERSION_ID_FUNC(file)() {		\
	return VERSION_ID_STRING(file);		\
    }
*/
VERSION_ID(ccompatc_h,
	   "$Id: ccompatc.h,v 2.15 1993/02/24 23:40:03 mark Exp $")

#define Int0	((int)0)
#define UInt0	((unsigned int)0)

typedef long /* int */		Int4;
#define Int40   ((Int4) 0)
#define Int4Min ((Int4) 0x80000000L)
#define Int4Max ((Int4) 0x7fffffffL)
typedef unsigned long /* int */	UInt4;
#define UInt40  ((UInt4)0)
typedef char			Int1;
#define Int10   ((Int1)0)
typedef unsigned char		UInt1;
#define UInt10  ((UInt1)0)

typedef long		Int32;
#define Int32Zero   	((Int32) 0)
#define Int32Min 	((Int32) 0x80000000L)
#define Int32Max 	((Int32) 0x7fffffffL)

typedef unsigned long	UInt32;
#define UInt32Zero  	((UInt32) 0)
#define UInt32Min	UInt32Zero
#define UInt32Max	((UInt32) 0xffffffffL)

typedef char		Int8;
#define Int8Zero   	((Int8) 0)
#define Int8Min		((Int8) 0x80)
#define Int8Max		((Int8) 0x7f)

typedef unsigned char	UInt8;
#define UInt8Zero  	((UInt8) 0)
#define UInt8Min	UInt8Zero
#define UInt8Max	((UInt8) 0xff)

/* typedef enum {FALSE = 0, TRUE = 1} BooleanVar; */

typedef int BooleanVar; 

#ifndef FALSE
#	define FALSE 0
#endif
#ifndef TRUE
#	define TRUE 1
#endif

#ifdef HIGHC
#ifdef NULL
#undef NULL
#endif
#endif

#ifndef NULL
#	define NULL 0
/* const void * NULL = 0; */
#endif /* NULL */

typedef double IEEEDoubleVar; /* IEEE format double precision variable */
typedef struct { unsigned char bytes [8]; } IEEE128;
typedef double IEEE64;
typedef float  IEEE32;
typedef struct {
	unsigned int sign :	 1 ;
	unsigned int exponent :  8 ;
	unsigned int mantissa : 23 ;
} IEEE32_fields;

typedef struct {
	unsigned int sign :	  1 ;
	unsigned int exponent :  11 ;
	unsigned int mantissaH : 20 ;
	unsigned int mantissaL : 32 ;
} IEEE64_fields;

#ifdef __STDC__
#	define PROTOTYPES_UNDERSTOOD 1
#elif defined(__cplusplus)
#	define PROTOTYPES_UNDERSTOOD 1
#endif


#ifdef PROTOTYPES_UNDERSTOOD
#	define PROTO_ARGS(args) args
#else
#	define PROTO_ARGS(args) ()
#endif

/* C Preprocessor macros */

/* STR stringifies its argument */
#if defined(STD_CPP) || defined( __sgi )  /* ANSI Standard way: */
#	define STR(x) #x
#else
#if _MSC_VER >= 700
#	define STR(x) #x
#else /* old non-standard way: */
#	define STR(x) "x"
#endif
#endif




/* OUT is included in a parameter list to separate input from output */
/*  parameters */
#ifndef STUBBLE
#	define OUT /* empty */
#endif


/* memmove is the ANSI memory copying operation--sun doesn''t have it */
#ifdef macintosh
/* Include memory.h for Macintosh style memory allocations */
#	include <memory.h>
#	define SBRK(x)	NewPtr(x)
#	define BRK(x)	DisposPtr(x)
#	define SBRK_FAILED ((void*)0)
#	define MEMMOVE(dest,source,count) memmove((dest),(source),(count))
#	define _NEW(x) NewPtr(x)
#	define FREE(x) DisposPtr(x)
#       define HOSTID(name) StrToIP(name)
#else
#ifdef WIN32
#		include <string.h>
#	define SBRK(x) VirtualAlloc(NULL,(x),MEM_COMMIT,PAGE_READWRITE)
#	define BRK(x) VirtualFree(x)
#	define SBRK_FAILED NULL
#	define MEMMOVE(dest,source,count) memmove((dest),(source),(count))
#	define _NEW(x) (::operator new (x))
#	define FREE(x) free(x)
#	define HOSTID(name) gethostbyname(name)
#else /* WIN32 */
# ifdef HIGHC
#		include <string.h>
#	define SBRK(x) malloc(x)
#	define BRK(x) free(x)
#	define SBRK_FAILED NULL
#	define MEMMOVE(dest,source,count) memmove((dest),(source),(count))
#	define _NEW(x) (::operator new (x))
#	define FREE(x) free(x)
#	define HOSTID(name) gethostbyname(name)
# else
# ifndef __sgi
#ifndef GNUSUN
#		include <string.h>
#endif
/*	extern char * sbrk PROTO_ARGS((unsigned incr)); */
#	define SBRK(x) sbrk(x)
#	define BRK(x) brk(x)
#	define SBRK_FAILED ((void*)-1)
#	define MEMMOVE(dest,source,count) bcopy((source),(dest),(count))
#	define _NEW(x) (::operator new (x))
#	define FREE(x) free(x)
#       define HOSTID(name) gethostbyname(name)
# else /* sgi */
/*	extern char * sbrk PROTO_ARGS((unsigned incr)); */
#	define SBRK(x) sbrk(x)
#	define BRK(x) brk(x)
#	define SBRK_FAILED ((void*)-1)
#	define MEMMOVE(dest,source,count) memmove((dest),(source),(count))
#	define _NEW(x) (::operator new (x))
#	define FREE(x) free(x)
#       define HOSTID(name) gethostbyname(name)
# endif
# endif
#endif
#endif

#ifdef __sgi
extern char** _environ;		/* missing from libc.h */
#endif /* sgi */

/* SGI won''t give us sigvec unless we want BSD_SIGNALS or BSD_COMPAT */
#ifdef __sgi
#  define _BSD_COMPAT
#endif /* sgi */

extern unsigned long alignUp PROTO_ARGS((unsigned long offset));
  /* round up offset to the next worst case alignment boundary */
  /*  of the current machine. */

#define DOES_MOD_OK
/* DOES_MOD_OK should be defined if the underlying C compiler's modulus */
/* operator doews the right thing. The right thing is defined as */
/* satisfying the equation: a % b == a-(a/b)*b. regardless of the sign of */
/* the operands. This can also be stated as "The sign of the result is the */
/* same as the left operand". This is used by IntegerVars. */


#ifdef __STDC__
#	define ALERT_CHAR '\a'
#else
#	define ALERT_CHAR '\a'
#endif


/************************ VOLATILE ***********************

The ANSI C spec says for "longjmp":

"All accessible objects have values as of the time longjmp was called,
except that objects of automatic storage duration that are local to
the function containing the invocation of the corresponding setjmp
macro that do not have volatile-qualified type and have been changed
between the setjmp invocation and longjmp call are indeterminate."

"setjmp"s are necessarily present in X++ in the expansion of a
SHIELD_UP.  Unfortunately, some compilers (such as the Mac) do not
recognize the setjmp keyword, so we need to provide some other way to
force the storage for the variable onto the stack (as opposed to being
in a register).  If the Mac case below isn't sufficient, more extreme
measures should be taken.  

Note:  It is unspecified whether 

	VOLATILE(Foo,foo,expr);

means

	volatile Foo foo = (expr);

or

	volatile Foo foo;
	foo = (expr);

These mean different things in C++ (constructor vs operator= invocation).


***********/

extern void doNothingWith PROTO_ARGS((void * ptr));


#ifdef macintosh
#	define VOLATILE(TYPE,VAR,INITEXPR) 			\
		TYPE VAR; 					\
		*&VAR = (INITEXPR)
#elif defined(__STDC__)
#	define VOLATILE(TYPE,VAR,INITEXPR) 			\
		volatile TYPE VAR = (INITEXPR)
#else
#	define VOLATILE(TYPE,VAR,INITEXPR) 			\
		TYPE VAR = (INITEXPR); 				\
		doNothingWith (&VAR)
#endif


/* as in Foo* OR(NULL).  This may need to be changed to less common name */
#define OR(val)

#endif /* CCOMPATC_H */

