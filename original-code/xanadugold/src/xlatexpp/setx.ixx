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

#ifndef SETX_IXX
#define SETX_IXX






/* ************************************************************************ *
 * 
 *                    Class ScruSet 
 *
 * ************************************************************************ */


/* exceptions: exceptions */
/* testing */
/* creation */
/* conversion */
/* printing */
/* enumerating */



/* ************************************************************************ *
 * 
 *                    Class   ImmuSet 
 *
 * ************************************************************************ */


/* protected: pseudo constructors */
/* pseudo constructors */


INLINE RPTR(ImmuSet) ImmuSet::make (){
	WPTR(ImmuSet) 	returnValue;
	returnValue = ImmuSet::EmptySet;
	return returnValue;
}
/* accessing */
/* operations */
/* adding-removing */
/* creation */
/* conversion */
/* enumerating */
/* testing */



/* ************************************************************************ *
 * 
 *                    Class   MuSet 
 *
 * ************************************************************************ */


/* exceptions: exceptions */
/* pseudo constructors */
/* accessing */
/* operations */
/* adding-removing */
/* creation */
/* conversion */
/* enumerating */
/* private: enumerating */



/* ************************************************************************ *
 * 
 *                    Class SetAccumulator 
 *
 * ************************************************************************ */


/* instance creation */
/* accessing */
/* protected: creation */
/* creation */



/* ************************************************************************ *
 * 
 *                    Class UnionRecruiter 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* accessing */
/* protected: creation */
/* creation */


#endif /* SETX_IXX */

