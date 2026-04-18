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

#ifndef DETECTX_IXX
#define DETECTX_IXX






/* ************************************************************************ *
 * 
 *                    Class FeDetector 
 *
 * ************************************************************************ */





/* ************************************************************************ *
 * 
 *                    Class   FeFillDetector 
 *
 * ************************************************************************ */


/* triggering */



/* ************************************************************************ *
 * 
 *                    Class   FeFillRangeDetector 
 *
 * ************************************************************************ */


/* triggering */



/* ************************************************************************ *
 * 
 *                    Class   FeRevisionDetector 
 *
 * ************************************************************************ */


/* triggering */



/* ************************************************************************ *
 * 
 *                    Class   FeStatusDetector 
 *
 * ************************************************************************ */


/* constants */


INLINE Int32 FeStatusDetector::EDIT_PERMISSION_CHANGED (){
	/* The reason for the change was a change in the permissions 
	required to edit the Work */
	
	return 4;
}


INLINE Int32 FeStatusDetector::KEYMASTER_CHANGED (){
	/* The reason for the change was a change in authority of the 
	KeyMaster in the Work */
	
	return 2;
}


INLINE Int32 FeStatusDetector::SIGNATURE_AUTHORITY (){
	/* The reason for the change was a change in signature 
	authority of the CurrentAuthor */
	
	return 1;
}
/* triggering */



/* ************************************************************************ *
 * 
 *                    Class   FeWaitDetector 
 *
 * ************************************************************************ */


/* triggering */


#endif /* DETECTX_IXX */

