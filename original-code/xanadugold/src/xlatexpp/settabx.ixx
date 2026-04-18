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

#ifndef SETTABX_IXX
#define SETTABX_IXX


#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */






/* ************************************************************************ *
 * 
 *                    Class SetTable 
 *
 * ************************************************************************ */


/* creation */


INLINE RPTR(SetTable) SetTable::make (APTR(CoordinateSpace) cs){
	WPTR(SetTable) 	returnValue;
	returnValue = SetTable::make (cs, 7);
	return returnValue;
}
/* accessing */


INLINE RPTR(CoordinateSpace) SetTable::coordinateSpace (){
	return (CoordinateSpace*) myCoordinateSpace;
}


INLINE IntegerVar SetTable::count (){
	return IntegerVar(myTally);
}
/* printing */
/* runLength */
/* enumerating */
/* creation */


INLINE RPTR(SetTable) SetTable::emptySize (IntegerVar size){
	/* return an empty table just like the current one */
	
	WPTR(SetTable) 	returnValue;
	returnValue = SetTable::make (myCoordinateSpace, size);
	return returnValue;
}
/* testing */
/* private: resize */


#endif /* SETTABX_IXX */

