/*
      (C) Copyright 1988, 89 by Xanadu Operating Company, All Rights Reserved.

******************************************************************************
*
* The information contained herein is confidential, proprietary to Xanadu
* Operating Company, and considered a trade secret as defined in section
* 499C of the penal code of the State of California.  Use of this information
* by anyone other than authorized employees of Xanadu is granted
* only under a  written non-disclosure agreement, expressly prescribing
* the scope and  manner of such use.
*
**************************************************************************** */
//
//	Added count of Lions/Tigers/Bears vs Christians
//		- michael Aug  5 1991
//
//	Piled lions on top of tigers and finally removed extinct bears
//	Note that all christians caused by bears are also gone.
//		- ech Mar 11 1992

/* =========================================================================
   |			    new & delete
   ========================================================================= */

/* $Id: xunewx.cxx,v 2.12 1993/03/16 22:30:16 eric Exp $ */

#include "allocx.hxx"
#include "bombx.hxx"

static UInt32	Tigers = 0;
static UInt32	Christians = 0;

UInt32 tigers() {
	return Tigers;
}

UInt32 christians() {
	return Christians;
}


void * operator new(size_t s)
{
    if (s <= 0) {
	BLAST(MEM_ALLOC_ERROR);
    }

    Tigers++;

    return falloc (s + sizeof(ABufHead)) + 1;	/* Will not return NULL */
}


void operator delete(void * p)
{
  if (p == 0) {
    BLAST(MEM_ALLOC_ERROR);
  }
  ffree(HEADER(p));
  Christians++;
}
