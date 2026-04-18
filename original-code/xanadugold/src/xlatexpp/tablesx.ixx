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

#ifndef TABLESX_IXX
#define TABLESX_IXX






/* ************************************************************************ *
 * 
 *                    Class Pair 
 *
 * ************************************************************************ */


/* instance creation */
/* obsolete: creation */
/* testing */
/* accessing */


INLINE RPTR(Pair) Pair::reversed (){
	/* Returns a new pair which is the left-right reversal of me.
		pair(a,b)->reversed() is the same as pair(b,a).
		
		Only works on non-obsolete Pairs--those whose parts are non-NULL */
	
	WPTR(Pair) 	returnValue;
	returnValue = Pair::make (rightPart, leftPart);
	return returnValue;
}
/* instance creation */
/* printing */
/* obsolete: access */


INLINE RPTR(Heaper) OR(NULL) Pair::fetchLeft (){
	/* Returns the left part which obsoletely may be NULL */
	
	return (Heaper*) leftPart;
}


INLINE RPTR(Heaper) OR(NULL) Pair::fetchRight (){
	/* Returns the right part which obsoletely may be NULL */
	
	return (Heaper*) rightPart;
}



/* ************************************************************************ *
 * 
 *                    Class ScruTable 
 *
 * ************************************************************************ */


/* exceptions: exceptions */
/* accessing */
/* testing */
/* enumerating */
/* conversion */
/* printing */
/* runs */
/* creation */
/* protected: creation */
/* overloads */



/* ************************************************************************ *
 * 
 *                    Class   ImmuTable 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* accessing */
/* creation */
/* SEF manipulation */
/* testing */
/* enumerating */
/* conversion */



/* ************************************************************************ *
 * 
 *                    Class   MuTable 
 *
 * ************************************************************************ */


/* exceptions: */
/* pseudo constructors */
/* accessing */
/* bulk operations */
/* testing */
/* enumerating */
/* conversion */
/* runs */
/* creation */
/* protected: creation */
/* overloads */



/* ************************************************************************ *
 * 
 *                    Class TableAccumulator 
 *
 * ************************************************************************ */


/* pseudoConstructors */
/* deferred operations */
/* deferred create */
/* printing */


#endif /* TABLESX_IXX */

