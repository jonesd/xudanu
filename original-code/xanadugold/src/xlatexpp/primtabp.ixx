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

#ifndef PRIMTABP_IXX
#define PRIMTABP_IXX


#ifndef CACHEX_HXX
#include "cachex.hxx"
#endif /* CACHEX_HXX */






/* ************************************************************************ *
 * 
 *                    Class PrimPtrTableExecutor 
 *
 * ************************************************************************ */


/* create */
/* invoking */
/* protected: create */



/* ************************************************************************ *
 * 
 *                    Class PrimRemovedObject 
 *
 * ************************************************************************ */


/* accessing */


INLINE WPTR(Heaper) PrimRemovedObject::make (){
	WPTR(Heaper) 	returnValue;
	returnValue = PrimRemovedObject::TheRemovedObject;
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class PrimSetExecutor 
 *
 * ************************************************************************ */


/* pseudoconstructor */
/* protected: create */
/* execution */



/* ************************************************************************ *
 * 
 *                    Class PrimSetStepper 
 *
 * ************************************************************************ */


/* create */
/* create */
/* accessing */
/* printint */


#endif /* PRIMTABP_IXX */

