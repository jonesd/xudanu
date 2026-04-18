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
//	Eliminated StrongPtrVar::inspectFuse() overriding.  (Unnecessary.)
//	 - michael May  3 1991
//
//	Moved remaining inline code to opaquex.ixx, and split off opaque2x.ixx
//	(containing only those routines that need to call routines in Heaper.)
//	The routines that need to call heaper inline routines will not be
//	inlined for those pointer classes that must be defined before Tofu
//	and Heaper.  (Currently, that's destroyIt() in pointers to Heaper,
//	Xmtr, and Rcvr.)
//		- michael Oct 10 1991

/* $Id: opaquex.cxx,v 2.5 1992/11/25 23:26:37 eric Exp $ */

#include "tofux.hxx"
#include "opaquex.ixx"
#include "opaque2x.ixx"



/* ----------------------- CheckedPtrVar non-inline stuff ------------------ */


PERMIT(4,"reference")

void CheckedPtrVar::printOn(ostream& oo) {
  oo << value;
}

void CheckedPtrVar::nullPointer () {
    BLAST(NULL_CHKPTR);
}

ostream& operator<<  (ostream& oo, CheckedPtrVar& ptrVar) {
  ptrVar.printOn (oo);
  return oo;
}


/* ----------------- GlobalStrongPtrVar non-inline stuff ---------------------*/


void GlobalStrongPtrVar::badSequenceNumber () CONST
{
#ifdef SEQUENCE_NUMBER_DANGLE_CHECK
    cerr << "mine = " << this->sequenceNumber
      << ", from p = " << ::sequenceNumber(this->value) 
      << ", p = " << ((void*)this->value) << "\n";
    BLAST(BAD_SEQUENCE_NUMBER);
#endif SEQUENCE_NUMBER_DANGLE_CHECK
}

void * GlobalStrongPtrVar::gCHook ()
{
    return this->value;
}

void GlobalStrongPtrVar::gCHook (void * value)
{
    this->value = (Heaper*) value;
}

void GlobalStrongPtrVar::nullPointer () {
    BLAST(NULL_GPTR);
}

REQUIRE(4, "reference")

void GlobalStrongPtrVar::printOn(ostream& oo) {
  oo << value;
}

ostream& operator<<  (ostream& oo, GlobalStrongPtrVar& ptrVar) {
  ptrVar.printOn (oo);
  return oo;
}

PERMIT(0, "reference")
