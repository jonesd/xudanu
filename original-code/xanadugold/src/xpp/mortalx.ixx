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
//	Spun off mortalx.ixx during change to ORDER/BUILD_BOMB_BEGIN/END form.
//		- michael Mar 11 1992

#ifndef MORTALX_IXX
#define MORTALX_IXX

static char mortalx_ixx_rcsid[] = "$Id: mortalx.ixx,v 1.3 1992/08/14 22:09:12 shap Exp $";

BUILD_BOMB_BEGIN(mortalDelete, Heaper*) {
	CHARGE->destroy();
} BUILD_BOMB_END(mortalDelete);

#endif /* MORTALX_IXX */

