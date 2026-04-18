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

#ifndef HSPACEX_IXX
#define HSPACEX_IXX


#ifndef HSPACEP_HXX
#include "hspacep.hxx"
#endif /* HSPACEP_HXX */






/* ************************************************************************ *
 * 
 *                    Class HeaperSpace 
 *
 * ************************************************************************ */


/* pseudo constructors */


INLINE RPTR(HeaperSpace) HeaperSpace::make (){
	/* Return the one instance of HeaperSpace */
	
	WPTR(HeaperSpace) 	returnValue;
	returnValue = HeaperSpace::TheHeaperSpace;
	return returnValue;
}
/* rcvr pseudo constructor */
/* creation */
/* testing */



/* ************************************************************************ *
 * 
 *                    Class UnOrdered 
 *
 * ************************************************************************ */


/* accessing */
/* testing */



/* ************************************************************************ *
 * 
 *                    Class   HeaperAsPosition 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* testing */
/* accessing */


INLINE RPTR(XnRegion) HeaperAsPosition::asRegion (){
	WPTR(XnRegion) 	returnValue;
	returnValue = HeaperRegion::make (this);
	return returnValue;
}


#endif /* HSPACEX_IXX */

