/*==========================================================================
  |                                                                        |
  |          Written by Eric C. Hill                                       |
  |          Copyright (C) 1991, Xanadu Operating Company, Inc.            |
  |                                                                        |
  ==========================================================================*/

/*

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

static char tracerc_c_rcsid[] = "$Id: tracerc.c,v 2.2 1992/08/14 22:12:07 shap Exp $";

#include "tracerc.h"
#include <stdio.h>
#include <machine/frame.h>
extern int etext;

static int          * pcTraceBuffer;

static struct frame * frameP;
static void  	    * stackP;

void recordStackTrace () {
    struct frame * fr;
    int lastReturn = 0;
    asm ("	t	0x03");	/* Flush windows */
    asm ("	nop");
    asm ("	sethi	%hi(_frameP),%o1");
    asm ("	st	%fp,[%o1+%lo(_frameP)]");
    asm ("	sethi	%hi(_stackP),%o1");
    asm ("	st	%sp,[%o1+%lo(_stackP)]");

    for (
	 fr = frameP->fr_savfp;	/* get previous frame */
	 fr >= stackP && fr->fr_savpc;
	 fr = fr->fr_savfp) {

	/* if (fr->fr_savpc != lastReturn) { */

	    pcTraceBuffer[fr->fr_savpc / 4] ++;

	    /*    lastReturn = fr->fr_savpc;
		  } */
    }
}

void initTracerBuffers () {
    int bufSize = (int) &etext;
    pcTraceBuffer = (int*) malloc(bufSize);
    memset (pcTraceBuffer, 0, bufSize);
}

void dumpTracerBuffers () {
    /* tracer.out has entries of 2 words  index,count */
    int numEntries = ((int)&etext) / 4;
    int i;
    FILE * outFd = fopen ("tracer.out", "w");
    for (i = 0; i < numEntries; i++) {
	if (pcTraceBuffer[i]) {
	    putw (i * 4, outFd);
	    putw (pcTraceBuffer[i], outFd);
	}
    }
    fclose (outFd);
}
