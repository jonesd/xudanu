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
//	Spun from sema4x.hxx while going to ORDER/BUILD_BOMB.
//		- michael Mar 11 1992

#ifndef SEMA4X_IXX
#define SEMA4X_IXX

/* $Id: sema4x.ixx,v 1.3 1992/11/25 23:26:52 eric Exp $ */

BUILD_BOMB_BEGIN(mutex, Sema4 *) {
	CHARGE->v();
} BUILD_BOMB_END(mutex);

#endif /* SEMA4X_IXX */
