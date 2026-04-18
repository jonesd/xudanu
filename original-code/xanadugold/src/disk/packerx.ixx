/* Copyright Xanadu Operating Company.  All Rights Reserved. */

/******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
***************************************************************************
Output from Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989
*/

#ifndef PACKERX_IXX
#define PACKERX_IXX


#ifndef ARRAYX_HXX
#include "arrayx.hxx"
#endif /* ARRAYX_HXX */

#ifndef COOKBKX_HXX
#include "cookbkx.hxx"
#endif /* COOKBKX_HXX */

#ifndef COUNTERX_HXX
#include "counterx.hxx"
#endif /* COUNTERX_HXX */

#ifndef GCHOOKSX_HXX
#include "gchooksx.hxx"
#endif /* GCHOOKSX_HXX */

#ifndef INTTABX_HXX
#include "inttabx.hxx"
#endif /* INTTABX_HXX */

#ifndef PURGINGX_HXX
#include "purgingx.hxx"
#endif /* PURGINGX_HXX */

#ifndef SETTABX_HXX
#include "settabx.hxx"
#endif /* SETTABX_HXX */

#ifndef SNFINFOX_HXX
#include "snfinfox.hxx"
#endif /* SNFINFOX_HXX */

#ifndef TABLESX_HXX
#include "tablesx.hxx"
#endif /* TABLESX_HXX */

#ifndef TURTLEX_HXX
#include "turtlex.hxx"
#endif /* TURTLEX_HXX */

#ifndef URDIX_HXX
#include "urdix.hxx"
#endif /* URDIX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */






/* ************************************************************************ *
 * 
 *                    Class SnarfPacker 
 *
 * ************************************************************************ */


/* exceptions: private: */

BUILD_BOMB_BEGIN(ResetCommit, SPTR(SnarfPacker) ) {
	CHARGE->commitState(FALSE);
} BUILD_BOMB_END(ResetCommit);


/* creation */
/* shepherds */
/* stubs */
/* internals */
/* transactions */
/* protected: destruction */
/* private: */
/* protected: creation */
/* testing */


#endif /* PACKERX_IXX */

