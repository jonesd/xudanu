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

#ifndef PACKERT_IXX
#define PACKERT_IXX


#ifndef COOKBKX_HXX
#include "cookbkx.hxx"
#endif /* COOKBKX_HXX */

#ifndef GRANMAPX_HXX
#include "granmapx.hxx"
#endif /* GRANMAPX_HXX */

#ifndef INTTABX_HXX
#include "inttabx.hxx"
#endif /* INTTABX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */






/* ************************************************************************ *
 * 
 *                    Class DoublingFlock 
 *
 * ************************************************************************ */


/* creation */
/* accessing */
/* hooks: */
/* printing */
/* creation */
/* testing */



/* ************************************************************************ *
 * 
 *                    Class HashStream 
 *
 * ************************************************************************ */


/* creation */
/* create */
/* accessing */



/* ************************************************************************ *
 * 
 *                    Class HonestAbeIniter 
 *
 * ************************************************************************ */


/* accessing */
/* running */



/* ************************************************************************ *
 * 
 *                    Class HonestAbePlan 
 *
 * ************************************************************************ */


/* accessing */



/* ************************************************************************ *
 * 
 *                    Class Honestly 
 *
 * ************************************************************************ */


/* running */



/* ************************************************************************ *
 * 
 *                    Class PairFlock 
 *
 * ************************************************************************ */


/* creation */
/* accessing */
/* creation */
/* testing */



/* ************************************************************************ *
 * 
 *                    Class TestFlockInfo 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* create */
/* accessing */



/* ************************************************************************ *
 * 
 *                    Class TestPacker 
 *
 * ************************************************************************ */


/* exceptions: private: */

BUILD_BOMB_BEGIN(EndCommit, TestPacker * ) {
	CHARGE->committing(FALSE);
} BUILD_BOMB_END(EndCommit);


/* pseudo constructors */
/* shepherds */
/* private: testing */
/* stubs */
/* private: streams */
/* private: disk */
/* create */
/* internals */
/* transactions */
/* testing */


#endif /* PACKERT_IXX */

