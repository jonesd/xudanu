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

#ifndef GCHOOKSX_IXX
#define GCHOOKSX_IXX


#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef PRIMTABX_HXX
#include "primtabx.hxx"
#endif /* PRIMTABX_HXX */

#ifndef GNUSUN
#include <osfcn.h>
#include <stdlib.h>
#else
/*extern "C"{
#include <stdlib.h>
}*/
#endif



/* ************************************************************************ *
 * 
 *                    Class CloseExecutor 
 *
 * ************************************************************************ */


/* accessing */
/* protected: create */
/* invoking */



/* ************************************************************************ *
 * 
 *                    Class DeleteExecutor 
 *
 * ************************************************************************ */


/* accessing */
/* invoking */
/* protected: create */



/* ************************************************************************ *
 * 
 *                    Class RepairEngineer 
 *
 * ************************************************************************ */


/* repairing */
/* protected: create */
/* invoking */
/* private: accessing */


INLINE RPTR(RepairEngineer) RepairEngineer::next (){
	return (RepairEngineer*) myNext;
}


INLINE void RepairEngineer::setNext (APTR(RepairEngineer) n){
	myNext = n;
}


INLINE void RepairEngineer::setPrev (APTR(RepairEngineer) n){
	myPrev = n;
}



/* ************************************************************************ *
 * 
 *                    Class SanitationEngineer 
 *
 * ************************************************************************ */


/* sanitizing */
/* invoking */
/* protected: create */
/* private: accessing */


INLINE RPTR(SanitationEngineer) SanitationEngineer::next (){
	return (SanitationEngineer*) myNext;
}


INLINE void SanitationEngineer::setNext (APTR(SanitationEngineer) n){
	myNext = n;
}


INLINE void SanitationEngineer::setPrev (APTR(SanitationEngineer) p){
	myPrev = p;
}



/* ************************************************************************ *
 * 
 *                    Class StackExaminer 
 *
 * ************************************************************************ */


/* accessing */


INLINE Int32 * StackExaminer::stackEnd (){
	Int32 * 	returnValue;
	returnValue = StackExaminer::StackEnd;
	return returnValue;
}
/* testing */


#endif /* GCHOOKSX_IXX */

