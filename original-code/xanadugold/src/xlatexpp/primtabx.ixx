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

#ifndef PRIMTABX_IXX
#define PRIMTABX_IXX


#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef WPARRAYX_HXX
#include "wparrayx.hxx"
#endif /* WPARRAYX_HXX */


#include "fhashx.hxx"



/* ************************************************************************ *
 * 
 *                    Class PrimIndexTable 
 *
 * ************************************************************************ */


/* create */
/* accessing */


INLINE Int32 PrimIndexTable::count (){
	return myTally;
}
/* protected: */
/* private: */
/* testing */
/* enumerating */



/* ************************************************************************ *
 * 
 *                    Class PrimIndexTableStepper 
 *
 * ************************************************************************ */


/* accessing */
/* protected: create */
/* create */



/* ************************************************************************ *
 * 
 *                    Class PrimPtr2PtrTable 
 *
 * ************************************************************************ */


/* create */
/* enumerating */
/* accessing */


INLINE Int32 PrimPtr2PtrTable::count (){
	return myTally;
}
/* protected: destruct */
/* protected: create */
/* private: */
/* testing */



/* ************************************************************************ *
 * 
 *                    Class PrimPtr2PtrTableStepper 
 *
 * ************************************************************************ */


/* create */
/* accessing */
/* protected: create */



/* ************************************************************************ *
 * 
 *                    Class PrimPtrTable 
 *
 * ************************************************************************ */


/* create */
/* accessing */


INLINE Int32 PrimPtrTable::count (){
	return myTally;
}
/* protected: destruct */
/* private: */
/* protected: create */
/* enumerating */
/* private: weakness */
/* testing */



/* ************************************************************************ *
 * 
 *                    Class PrimPtrTableStepper 
 *
 * ************************************************************************ */


/* protected: create */
/* accessing */
/* create */



/* ************************************************************************ *
 * 
 *                    Class PrimSet 
 *
 * ************************************************************************ */


/* create */
/* enumerating */
/* adding-removing */
/* accessing */


INLINE Int32 PrimSet::count (){
	return myTally;
}
/* private: */
/* protected: create */
/* private: weakness */
/* testing */


#endif /* PRIMTABX_IXX */

