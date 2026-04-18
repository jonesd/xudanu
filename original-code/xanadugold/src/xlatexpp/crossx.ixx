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

#ifndef CROSSX_IXX
#define CROSSX_IXX


#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */






/* ************************************************************************ *
 * 
 *                    Class CrossMapping 
 *
 * ************************************************************************ */


/* pseudoconstructors */
/* transforming */
/* combining */
/* accessing */



/* ************************************************************************ *
 * 
 *                    Class CrossOrderSpec 
 *
 * ************************************************************************ */


/* pseudoconstructors */
/* private: pseudo constructors */
/* private: creation */
/* accessing */


INLINE RPTR(CoordinateSpace) CrossOrderSpec::coordinateSpace (){
	return (CrossSpace*) mySpace;
}
/* testing */



/* ************************************************************************ *
 * 
 *                    Class CrossRegion 
 *
 * ************************************************************************ */


/* testing */
/* enumerating */
/* operations */
/* accessing */
/* protected: enumerating */



/* ************************************************************************ *
 * 
 *                    Class CrossSpace 
 *
 * ************************************************************************ */


/* creation */
/* accessing */


INLINE Int32 CrossSpace::axisCount (){
	/* The number of dimensions in this space */
	
	return mySubSpaces->count();
}
/* testing */
/* making */
/* protected: accessing */


INLINE RPTR(PtrArray) OF1(CoordinateSpace) CrossSpace::secretSubSpaces (){
	/* The actual array of sub spaces. DO NOT MODIFY */
	
	return (PtrArray*) mySubSpaces;
}
/* protected: creation */



/* ************************************************************************ *
 * 
 *                    Class Tuple 
 *
 * ************************************************************************ */


/* pseudoconstructors */
/* printing */
/* accessing */
/* testing */


#endif /* CROSSX_IXX */

