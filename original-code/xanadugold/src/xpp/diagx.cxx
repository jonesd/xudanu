/* ========================================================================== */
//
//   Copyright (c) 1989, 90 by Xanadu Operating Company, All Rights Reserved.
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

/* $Id: diagx.cxx,v 2.6 1992/12/19 00:53:07 ravi Exp $ */

#include "diagx.hxx"
#include "initx.hxx"

#include "diagx.sxx"

DEFINE_PRIM_FLUID(long,debugIndentCount,globalEmulsion());
DEFINE_PRIM_FLUID(BooleanVar,inPrintOn,globalEmulsion());
void debugIndent (ostream& oo)
{
  for (long i = 0; i < debugIndentCount.fluidFetch(); i++) {
    oo << " ";
  }
}


void printHeaper (Heaper * obj)
{
  cerr << obj;
}

void printCHKPTR (CheckedPtrVar var)
{
  cerr << (Heaper*) var;
}

void printGPTR (GlobalStrongPtrVar var)
{
  cerr << var.fetch();
}
