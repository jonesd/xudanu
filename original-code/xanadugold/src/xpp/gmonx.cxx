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

/*
Include this file in your link in order to get around the bug that Sun C++ 
programs don't write out the gmon.out (or whatever) file when doing profiling.
*/

/*
#include "mon.h"
Commented out because the documented call to monitor in the manual, which 
appears below isn't consistent with the header file
*/

/* $Id: gmonx.cxx,v 2.9 1993/04/10 00:53:43 eric Exp $ */

#include "xcompatx.hxx"

typedef int (*PF) ();

#ifdef unix
C_DECL_BEGIN
/*#include "../tracer2.h"*/
    extern void monitor (PF /*, PF, WORD*, int, int */ );
    extern void moncontrol ( int );
C_DECL_END
#endif /* unix */

class MonitorClass {
  public:
    MonitorClass ()
      /* To suppress a silly compiler warning message */
      {
#ifdef unix
	moncontrol (1);
#endif
/*	  startStatisticalTracing();*/
      }
    ~MonitorClass ()
      {
#ifdef unix
	  monitor (0);
#endif
/*	  dumpTracerBuffers();*/
      }
};

static MonitorClass terminateMonitor;
