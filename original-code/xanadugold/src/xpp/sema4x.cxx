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
//
//	Fixed to use SPTR macro on return.
//		- michael Jun 29 1991 (Touched merging Jul 22)

/* $Id: sema4x.cxx,v 2.4 1992/11/25 23:26:50 eric Exp $ */

#include <stream.h>
#include "tofux.hxx"
#include "sema4x.hxx"

#include "sema4x.sxx"

/* Obviously dummy definitions for now */

RPTR(Sema4) Sema4::make (IntegerVar initialCount) {
    RETURN_CONSTRUCT(Sema4,(initialCount, tcsj));
}

void Sema4::v ()
{
    count += 1;
}

void Sema4::p ()
{
    count -= 1;
}

IntegerVar Sema4::t ()
{
    IntegerVar result = count;

    if (count > 0) {
	count -= 1;
    }
    return result;
}

Sema4::Sema4 (IntegerVar initialCount, TCSJ)
{
    count = initialCount;
}

