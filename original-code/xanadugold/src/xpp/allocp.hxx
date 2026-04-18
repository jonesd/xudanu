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

#ifndef ALLOCP_HXX
#define ALLOCP_HXX

/* $Id: allocp.hxx,v 2.3 1992/11/25 23:25:32 eric Exp $ */
  
#ifndef ALLOCX_IXX  /* disable calling in the .ixx file*/
#define HACK_ALLOCX_IXX
#define ALLOCX_IXX
#endif

#include "allocx.hxx"
#include "tofux.hxx"

#ifdef HACK_ALLOCX_IXX  /* reenable the .ixx file */
#undef HACK_ALLOCX_IXX
#undef ALLOCX_IXX
#endif

#ifdef TOMBSTONES
struct vtbl_entry;
#endif /* TOMBSTONES */


#endif /* ALLOCP_HXX */
