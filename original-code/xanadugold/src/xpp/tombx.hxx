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


/*==========================================================================
  |                                                                        |
  |          tombstone.h - entomb objects to catch dangling references     |
  |                                                                        |
  |          Written by Eric C. Hill                                       |
  |          Copyright (C) 1989, Xanadu Operating Company, Inc.            |
  |                                                                        |
  ==========================================================================*/


#ifndef TOMBSTONE_HXX
#define TOMBSTONE_HXX

/* $Id: tombx.hxx,v 2.3 1992/11/25 23:27:13 eric Exp $ */

#include "xcompatx.hxx"

#define MAX_STACK_DEPTH 32
extern size_t recordStack (int saveArea[], size_t maxTraceback);
extern size_t recordStack (void *** saveAreaP);
class ostream;
PERMIT(1,"reference")
extern void   recordStack (ostream& oo);

PERMIT(1,"struct")
struct TombClass;

extern void entomb(void * object);
extern void consecrateGraveyard();

#endif /* TOMBSTONE_HXX */
