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

#ifndef DISKMANX_IXX
#define DISKMANX_IXX


#ifndef FLUIDX_HXX
#include "fluidx.hxx"
#endif /* FLUIDX_HXX */

#ifndef PRIMTABX_HXX
#include "primtabx.hxx"
#endif /* PRIMTABX_HXX */

#ifndef WPARRAYX_HXX
#include "wparrayx.hxx"
#endif /* WPARRAYX_HXX */


#include "allocx.hxx"



/* ************************************************************************ *
 * 
 *                    Class DiskManager 
 *
 * ************************************************************************ */


/* exceptions: exceptions */

BUILD_BOMB_BEGIN(ConsistentBlock, IntegerVar ) {
	CurrentPacker.fluidGet()->endConsistent(CHARGE);
} BUILD_BOMB_END(ConsistentBlock);


/* creation */
/* emulsion accessing */
/* shepherds */
/* stubs */
/* transactions */
/* testing */
/* protected: accessing */


INLINE void DiskManager::flockInfoTable (APTR(PrimPtrTable) table){
	myFlockInfoTable = table;
}


INLINE void DiskManager::flockTable (APTR(WeakPtrArray) table){
	myFlockTable = table;
}
/* accessing */


INLINE RPTR(PrimPtrTable) DiskManager::flockInfoTable (){
	return (PrimPtrTable*) myFlockInfoTable;
}


INLINE RPTR(WeakPtrArray) DiskManager::flockTable (){
	return (WeakPtrArray*) myFlockTable;
}
/* protected: creation */
/* emulsion accessing */



/* ************************************************************************ *
 * 
 *                    Class ShepherdBootMaker 
 *
 * ************************************************************************ */


/* creation */
/* accessing */
/* protected: */


#endif /* DISKMANX_IXX */

