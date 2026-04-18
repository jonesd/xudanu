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

#ifndef PURGINGX_IXX
#define PURGINGX_IXX


#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef PACKERX_HXX
#include "packerx.hxx"
#endif /* PACKERX_HXX */






/* ************************************************************************ *
 * 
 *                    Class LiberalPurgeror 
 *
 * ************************************************************************ */


/* create */
/* protected: create */
/* accessing */
/* invoking */



/* ************************************************************************ *
 * 
 *                    Class Purgeror 
 *
 * ************************************************************************ */


/* creation */
/* setting */
/* accessing */


INLINE void Purgeror::clearPurgePending (){
	myPurgePending = FALSE;
	myCount = IntegerVar0;
}


INLINE BooleanVar Purgeror::purgePending (){
	return myPurgePending;
}
/* protected: creation */
/* invoking */


#endif /* PURGINGX_IXX */

