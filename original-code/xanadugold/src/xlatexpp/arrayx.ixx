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

#ifndef ARRAYX_IXX
#define ARRAYX_IXX


#include <string.h>
#include <stream.h>




/* ************************************************************************ *
 * 
 *                    Class MuArray 
 *
 * ************************************************************************ */


/* creation */


INLINE RPTR(MuArray) MuArray::array (){
	/* A new empty XnArray */
	
	WPTR(MuArray) 	returnValue;
	returnValue = MuArray::make (1);
	return returnValue;
}
/* accessing */
/* creation */
/* testing */
/* runs */
/* enumerating */
/* bulk operations */
/* overload junk */


#endif /* ARRAYX_IXX */

