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

#ifndef INTEGERP_IXX
#define INTEGERP_IXX


#ifndef CACHEX_HXX
#include "cachex.hxx"
#endif /* CACHEX_HXX */






/* ************************************************************************ *
 * 
 *                    Class AscendingIntegerStepper 
 *
 * ************************************************************************ */


/* creation */
/* protected: creation */
/* creation */
/* accessing */



/* ************************************************************************ *
 * 
 *                    Class DescendingIntegerStepper 
 *
 * ************************************************************************ */


/* creation */
/* protected: create */
/* creation */
/* accessing */



/* ************************************************************************ *
 * 
 *                    Class IntegerArrangement 
 *
 * ************************************************************************ */


/* creation */
/* accessing */
/* printing */
/* protected: creation */
/* testing */



/* ************************************************************************ *
 * 
 *                    Class IntegerEdgeAccumulator 
 *
 * ************************************************************************ */


/* creation */
/* protected: creation */
/* creation */
/* operations */
/* printing */
/* edge operations */



/* ************************************************************************ *
 * 
 *                    Class IntegerEdgeStepper 
 *
 * ************************************************************************ */


/* errors */
/* create */
/* operations */


INLINE BooleanVar IntegerEdgeStepper::hasValue (){
	return myIndex < myCount;
}


INLINE void IntegerEdgeStepper::step (){
	myEntering = !myEntering;
	myIndex += 1;
}
/* edge accessing */


INLINE IntegerVar IntegerEdgeStepper::edge (){
	/* the current transition */
	
	if (myIndex >= myCount) {
		IntegerEdgeStepper::outOfBounds();
	}
	return myEdges->integerVarAt(myIndex);
}


INLINE BooleanVar IntegerEdgeStepper::isEntering (){
	/* whether the current transition is entering or leaving the set */
	
	return myEntering;
}
/* protected: create */
/* destroy */
/* create */
/* printing */



/* ************************************************************************ *
 * 
 *                    Class IntegerSimpleRegionStepper 
 *
 * ************************************************************************ */


/* operations */
/* unprotected create */
/* create */
/* printing */



/* ************************************************************************ *
 * 
 *                    Class IntegerUpOrder 
 *
 * ************************************************************************ */


/* pseudoconstructors */
/* testing */
/* accessing */


#endif /* INTEGERP_IXX */

