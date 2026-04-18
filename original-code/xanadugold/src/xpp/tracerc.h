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
  |	tracer - collect histogram data based on return address stack	   |
  |                                                                        |
  |          Written by Eric C. Hill                                       |
  |          Copyright (C) 1991, Xanadu Operating Company, Inc.            |
  |                                                                        |
  ==========================================================================*/


#ifndef TRACERC_H
#define TRACERC_H

/* $Id: tracerc.h,v 2.3 1992/11/25 23:27:15 eric Exp $ */

extern void initTracerBuffers ();
extern void recordStackTrace ();
extern void dumpTracerBuffers ();

#endif /* TRACERC_H */
