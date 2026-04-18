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

#ifndef TABENTX_IXX
#define TABENTX_IXX


#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */

#ifndef TABENTP_HXX
#include "tabentp.hxx"
#endif /* TABENTP_HXX */






/* ************************************************************************ *
 * 
 *                    Class TableEntry 
 *
 * ************************************************************************ */


/* creation */


INLINE RPTR(TableStepper) TableEntry::bucketStepper (APTR(SharedPtrArray) array){
	WPTR(TableStepper) 	returnValue;
	returnValue = BucketArrayStepper::make (array);
	return returnValue;
}
/* accessing */


INLINE RPTR(TableEntry) OR(NULL) TableEntry::fetchNext (){
	return (TableEntry*) myNext;
}


INLINE void TableEntry::setNext (APTR(TableEntry) OR(NULL) next){
	/* Change my pointer to the rest of the chain in this bucket. */
	
	myNext = next;
}


INLINE RPTR(Heaper) TableEntry::value (){
	return (Heaper*) myValue;
}
/* protected: creation */
/* printing */
/* destroy */


#endif /* TABENTX_IXX */

