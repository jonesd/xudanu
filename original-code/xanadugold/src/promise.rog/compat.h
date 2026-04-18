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
/*  to needed non-portable constructs. */
/* This file should be acceptable to both C & C++ */

#ifndef XU_COMPAT_H
#define XU_COMPAT_H


typedef unsigned char XuByteVar;
typedef int XuBooleanVar;
typedef long XuIntVar; /* must be at least 32 bits */
typedef unsigned long XuUIntVar;
typedef const char * XuStringVar;
typedef void * XuBufferVar;

#ifndef NULL
#	define NULL 0
#endif

#ifndef FALSE
#	define FALSE 0
#endif
#ifndef TRUE
#	define TRUE 1
#endif

#define XU_OR_NULL

#ifdef __STDC__
#	define XU_PROTOTYPES_UNDERSTOOD 1
#elif defined(__cplusplus)
#	define XU_PROTOTYPES_UNDERSTOOD 1
#endif


#ifdef XU_PROTOTYPES_UNDERSTOOD
#	define XU_ARGS(args) args
#else
#	define XU_ARGS(args) ()
#endif


#ifndef DOTDOTDOT
#	define DOTDOTDOT
#endif /* DOTDOTDOT */


/* C Preprocessor macros */

#ifndef STD_CPP
#	ifdef __STDC__
#		define STD_CPP
#	endif /* __STDC__ */

#	ifdef sgi
#		define STD_CPP
#	endif /* sgi */

#	ifdef applec
#		define STD_CPP
#	endif /* applec */

#endif /* STD_CPP */

/* XU_STR stringifies its argument */
#ifdef STD_CPP /* ANSI Standard way: */
#	define XU_STR(x) #x
#else /* old non-standard way: */
#	define XU_STR(x) "x"
#endif

/* XU_CAT concatenates its arguments so they can form a single token */
#ifdef STD_CPP /* ANSI Standard way: */
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
 
#	define XU_CAT(x,y) XU_CAT_AUX(x,y)
#	define XU_CAT_AUX(x,y) x ## y
#	define XU_CAT3(x,y,z) XU_CAT3_AUX(x,y,z)
#	define XU_CAT3_AUX(x,y,z) x ## y ## z
#else
#	ifdef BSD /* non-standard BSD way: */
#		define XU_CAT(x,y) x\
y
#		define XU_CAT3(x,y,z) x\
y\
z
#	else /* non-standard System V way: */
#		define XU_CAT(x,y) x/**/y
#		define XU_CAT3(x,y,z) x/**/y/* */z
#	endif /* BSD */
#endif /* __STDC__ */

/* thingToDo: XU_ or omit each of the things below */

/* memmove is the ANSI memory copying operation--sun doesn''t have it */
#ifdef macintosh
/* Include memory.h for Macintosh style memory allocations */
#	include <memory.h>
#	define SBRK(x)	NewPtr(x)
#	define SBRK_FAILED ((void*)0)
#	define MEMMOVE(dest,source,count) memmove((dest),(source),(count))
#	define _NEW(x) NewPtr(x)
#	define FREE(x) DisposPtr(x)
#       define HOSTID(name) StrToIP(name)
#else
# ifndef sgi
/*	extern char * sbrk XU_ARGS((unsigned incr)); */
#	define SBRK(x) sbrk(x)
#	define SBRK_FAILED ((void*)-1)
#	define MEMMOVE(dest,source,count) bcopy((source),(dest),(count))
#	define _NEW(x) (::operator new (x))
#	define FREE(x) free(x)
#       define HOSTID(name) gethostbyname(name)
# else /* sgi */
/*	extern char * sbrk XU_ARGS((unsigned incr)); */
#	define SBRK(x) sbrk(x)
#	define SBRK_FAILED ((void*)-1)
#	define MEMMOVE(dest,source,count) memmove((dest),(source),(count))
#	define _NEW(x) (::operator new (x))
#	define FREE(x) free(x)
#       define HOSTID(name) gethostbyname(name)
# endif
#endif

#ifdef sgi
extern char** _environ;		/* missing from libc.h */
#endif /* sgi */

/* SGI won''t give us sigvec unless we want BSD_SIGNALS or BSD_COMPAT */
#ifdef sgi
#  define _BSD_COMPAT
#endif /* sgi */

extern unsigned long alignUp XU_ARGS((unsigned long offset));
  /* round up offset to the next worst case alignment boundary */
  /*  of the current machine. */

#define DOES_MOD_OK
/* DOES_MOD_OK should be defined if the underlying C compiler's modulus */
/* operator does the right thing. The right thing is defined as */
/* satisfying the equation: a % b == a-(a/b)*b. regardless of the sign of */
/* the operands. This can also be stated as "The sign of the result is the */
/* same as the left operand".  */


#endif /* XU_COMPAT_H */
