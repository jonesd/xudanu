
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


/*===========================================================================
  |
  | Derived from John Walker's smart allocation stuff and xu 88.1'
  |  (and gawd knows where else).
  |
  ===========================================================================*/

#ifndef ALLOCX_IXX
#define ALLOCX_IXX

static char allocx_ixx_rcsid[] = "$Id: allocx.ixx,v 2.3 1992/08/14 22:06:35 shap Exp $";

#if defined(SEQUENCE_NUMBER_DANGLE_CHECK) || defined(ALLOC_REGRESSION_HOOKS)
#include "allocx.hxx"
#endif


#if defined(SEQUENCE_NUMBER_DANGLE_CHECK) || defined(ALLOC_REGRESSION_HOOKS)
INLINE UInt4 sequenceNumber (void * addr)
{
    if (*((UInt4*)addr-1) == 0) {
	/* Adjust for non-heaper case */
	addr = (UInt4*) addr - 1;
    }
    return inOurHeap(addr) ? HEADER(addr)->sequenceNumber : 0;
}
#endif /* SEQUENCE_NUMBER_DANGLE_CHECK || ALLOC_REGRESSION_HOOKS */


#endif /* ALLOCX_IXX */
