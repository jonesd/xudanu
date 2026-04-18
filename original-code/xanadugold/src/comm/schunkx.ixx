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

#ifndef SCHUNKX_IXX
#define SCHUNKX_IXX


#ifndef FLUIDX_HXX
#include "fluidx.hxx"
#endif /* FLUIDX_HXX */


#include <stdlib.h>
#include "allocx.hxx"



/* ************************************************************************ *
 * 
 *                    Class ChunkCleaner 
 *
 * ************************************************************************ */


/* cleanup */
/* private: accessing */
/* invoking */
/* protected: create */



/* ************************************************************************ *
 * 
 *                    Class ServerChunk 
 *
 * ************************************************************************ */


/* accessing */
/* protected: accessing */


INLINE Int32 ServerChunk::aliveFlag (){
	return Int32Zero;
}


INLINE Int32 ServerChunk::destroyReadyFlag (){
	return 3;
}


INLINE Int32 ServerChunk::destroyRequestedFlag (){
	return 2;
}


INLINE Int32 ServerChunk::inRequestFlag (){
	return 1;
}
/* protected: accessing */
/* testing */
/* accessing */
/* protected: destruct */
/* creation */


#endif /* SCHUNKX_IXX */

