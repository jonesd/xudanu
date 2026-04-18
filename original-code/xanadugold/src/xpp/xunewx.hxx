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
//	Added count of Lions/Tigers/Bears vs Christians
//		- michael Aug  5 1991
//
//	Piled lions on top of tigers and finally removed extinct bears
//	Note that all christians caused by bears are also gone.
//		- ech Mar 11 1992



/* =========================================================================
   |			    new & delete		                   |
   ========================================================================= */

#ifndef XUNEW_HXX
#define XUNEW_HXX

#include "xcompatx.hxx"

VERSION_ID(xunewx_hxx,
	   "$Id: xunewx.hxx,v 2.7 1992/08/14 22:13:00 shap Exp $")

PERMIT(N,"ALL")
#include <stddef.h>  /* For size_t */
PERMIT(0,"ALL")

enum AllocType { PERSISTENT = 0,
		 OTHER = 1,
		 YOUR_CHOICE = 2 /* To be determined according to fluid
		                     allocationType. */
		 };

UInt32	tigers();
UInt32	christians();

#endif /* XUNEW_HXX */
