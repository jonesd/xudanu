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
#ifndef ALLOCX_HXX
#define ALLOCX_HXX

/* $Id: allocx.hxx,v 2.6 1993/03/16 22:29:42 eric Exp $ */

#include "xcompatx.hxx"

#include "queuesx.hxx"
#include <stddef.h>

#ifndef NDEBUG
/*#define TOMBSTONES 1*/
/*#define SMARTALLOC 1*/
/*#define SEQUENCE_NUMBER_DANGLE_CHECK 1*/
#define ALLOC_REGRESSION_HOOKS 1
#endif /* NDEBUG */

#if defined(SEQUENCE_NUMBER_DANGLE_CHECK) || defined(ALLOC_REGRESSION_HOOKS)
UInt4 extraSequenceNumber();
#endif /* SEQUENCE_NUMBER_DANGLE_CHECK || ALLOC_REGRESSION_HOOKS */

extern UInt4 sequenceNumber (void * addr);

extern struct ABufHead * falloc (size_t nBytes);

extern char * fcalloc(unsigned nelm, unsigned elsize);

extern void ffree (struct ABufHead * head);

REQUIRE(2,"struct")
PERMIT(N,"public data")

struct ABufHead {

  Queue  allocClass;        /* Links with similarly allocated objects */
  UInt4  numUnits;	    /* Buffer length in sizeof(ABufHead) units */

#ifdef SMARTALLOC
  Queue          abq;	    /* Links on allocated queue */
  size_t         numBytes;  /* Buffer length in bytes */
#endif /* SMARTALLOC */

#if defined(SEQUENCE_NUMBER_DANGLE_CHECK) || defined(ALLOC_REGRESSION_HOOKS)
  UInt4 sequenceNumber;
#endif /* SEQUENCE_NUMBER_DANGLE_CHECK || ALLOC_REGRESSION_HOOKS */

};

PERMIT(0,"struct")
PERMIT(0,"public data")

#define HEADER(obj) ((ABufHead*)obj - 1)

#endif /* ALLOCX_HXX */
