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

#ifndef HSPACEP_IXX
#define HSPACEP_IXX


#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */


#include "choosex.hxx"



/* ************************************************************************ *
 * 
 *                    Class HeaperDsp 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* accessing */
/* creation */



/* ************************************************************************ *
 * 
 *                    Class SetRegion 
 *
 * ************************************************************************ */


/* accessing */


INLINE BooleanVar SetRegion::isComplement (){
	/* FALSE means that I'm a 'positive' region (see class comment).  
		TRUE means I'm a negative region. */
	
	return myIsComplement;
}


INLINE WPTR(ImmuSet) OF1(Position) SetRegion::positions (){
	/* If I'm a positive region (see class comment and isComplement), then 
		this is a list of those positions I contain. If I'm 
	negative, then it's 
		those positions I don't contain. */
	
	return (ImmuSet*) myPositions;
}
/* enumerating */
/* operations */
/* testing */
/* protected: creation */
/* printing */
/* protected: protected deferred */
/* deferred accessing */
/* protected: enumerating */



/* ************************************************************************ *
 * 
 *                    Class   HeaperRegion 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* accessing */
/* protected: protected */
/* testing */
/* creation */



/* ************************************************************************ *
 * 
 *                    Class StrongAsPosition 
 *
 * ************************************************************************ */


/* testing */
/* accessing */
/* printing */
/* instance creation */


#endif /* HSPACEP_IXX */

