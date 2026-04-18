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

#ifndef REALP_IXX
#define REALP_IXX






/* ************************************************************************ *
 * 
 *                    Class IEEE32Pos 
 *
 * ************************************************************************ */


/* creation */
/* obsolete: */
/* printing */
/* accessing */



/* ************************************************************************ *
 * 
 *                    Class IEEE64Pos 
 *
 * ************************************************************************ */


/* creation */
/* obsolete: */
/* printing */
/* accessing */



/* ************************************************************************ *
 * 
 *                    Class IEEE8Pos 
 *
 * ************************************************************************ */


/* creation */
/* obsolete: */
/* accessing */



/* ************************************************************************ *
 * 
 *                    Class RealDsp 
 *
 * ************************************************************************ */


/* creation */
/* deferred accessing */



/* ************************************************************************ *
 * 
 *                    Class RealEdge 
 *
 * ************************************************************************ */


/* accessing */
/* testing */
/* printing */
/* creation */



/* ************************************************************************ *
 * 
 *                    Class   AfterReal 
 *
 * ************************************************************************ */


/* create */
/* comparing */
/* printing */
/* creation */



/* ************************************************************************ *
 * 
 *                    Class   BeforeReal 
 *
 * ************************************************************************ */


/* create */
/* printing */
/* comparing */
/* creation */



/* ************************************************************************ *
 * 
 *                    Class RealManager 
 *
 * ************************************************************************ */


/* protected: */


INLINE Int32 RealManager::transitionsCount (APTR(XnRegion) region){
	return CAST(RealRegion,region)->secretTransitions()->count();
}



/* ************************************************************************ *
 * 
 *                    Class RealStepper 
 *
 * ************************************************************************ */


/* operations */
/* create */



/* ************************************************************************ *
 * 
 *                    Class RealUpOrder 
 *
 * ************************************************************************ */


/* creation */
/* accessing */
/* testing */


#endif /* REALP_IXX */

