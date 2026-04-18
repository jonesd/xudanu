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

#ifndef BIN2COMP_IXX
#define BIN2COMP_IXX


#ifndef CACHEX_HXX
#include "cachex.hxx"
#endif /* CACHEX_HXX */

#ifndef NSCOTTYX_HXX
#include "nscottyx.hxx"
#endif /* NSCOTTYX_HXX */






/* ************************************************************************ *
 * 
 *                    Class Binary2Rcvr 
 *
 * ************************************************************************ */


/* creation */
/* receiving */
/* protected: specialist */
/* private: */
/* creation */
/* printing */
/* protected: accessing */


INLINE RPTR(XnReadStream) Binary2Rcvr::stream (){
	return (XnReadStream*) myStream;
}



/* ************************************************************************ *
 * 
 *                    Class Binary2Xmtr 
 *
 * ************************************************************************ */


/* creation */
/* sending */
/* printing */
/* protected: sending */


INLINE RPTR(XnWriteStream) Binary2Xmtr::stream (){
	return (XnWriteStream*) myStream;
}
/* creation */
/* specialist sending */


#endif /* BIN2COMP_IXX */

