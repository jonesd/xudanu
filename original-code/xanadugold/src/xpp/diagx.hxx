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
//	Changed comments during change to ORDER/BUILD_BOMB_BEGIN/END form.
//	Additional changes will be needed if the bomb is ever turned back on.
//		- michael Mar 11 1992

#ifndef DIAGX_HXX
#define DIAGX_HXX

/* $Id: diagx.hxx,v 2.8 1992/12/12 00:05:05 eric Exp $ */

#include "tofux.hxx"
#include "fluidx.hxx"
#include <stdio.h>

DESIGN_PRIM_FLUID (long,debugIndentCount);
DESIGN_PRIM_FLUID (BooleanVar,inPrintOn);

extern void debugIndent(ostream& oo);

/*

ORDER_BOMB (printHeaperResult, SPTR(Heaper)*);

  and create a diagx.ixx, placing in it:

BUILD_BOMB_BEGIN (printHeaperResult, SPTR(Heaper)*) {
	debugIndent(cerr);cerr << "result = " << *(CHARGE) << "\n";
} BUILD_BOMB_END(printHeaperResult);

*/

extern void dumpAllocIntervalsOn (FILE * fd);  // Can't be iostream in alloc

extern "C" {
  void printHeaper (Heaper  *  object);
  void printCHKPTR (CheckedPtrVar var);
  void printGPTR   (GlobalStrongPtrVar var);
};


/* This macro's purpose is to cause a coredump on any bad non-NULL pointer */
#define ISVALIDPTR(p)			       	\
{						\
	if (p != NULL) {			\
		if (!p->isKindOf(cat_Heaper)) { \
			BLAST(UGH);		\
		}				\
        }					\
}


#endif /* DIAGX_HXX */
