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

#ifndef STEPPERX_IXX
#define STEPPERX_IXX


#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef STEPPERP_HXX
#include "stepperp.hxx"
#endif /* STEPPERP_HXX */






/* ************************************************************************ *
 * 
 *                    Class Accumulator 
 *
 * ************************************************************************ */


/* creation */


INLINE RPTR(Accumulator) Accumulator::ptrArray (){
	/* An accumulator that returns a PtrArray of the object put 
	into it, in sequence */
	
	RETURN_CONSTRUCT(PtrArrayAccumulator,());
}
/* deferred operations */
/* deferred creation */



/* ************************************************************************ *
 * 
 *                    Class Stepper 
 *
 * ************************************************************************ */


/* pseudo constructors */


INLINE RPTR(Stepper) Stepper::emptyStepper (){
	/* A Stepper which is born exhausted.  Useful for 
	implementing empty collections */
	
	WPTR(Stepper) 	returnValue;
	returnValue = Stepper::TheEmptyStepper;
	return returnValue;
}
/* create */
/* operations */



/* ************************************************************************ *
 * 
 *                    Class   TableStepper 
 *
 * ************************************************************************ */


/* creation */


INLINE RPTR(TableStepper) TableStepper::ascending (APTR(PtrArray) array){
	/* Note: this being a low level operation, and there being no 
	lightweight form of immutable or lazily copied PtrArray, it 
	is my caller's responsibility to pass me a PtrArray which 
	will in fact not be changed during the life of this stepper.  
	This is an unchecked an uncheckable precondition on my clients. */
	
	WPTR(TableStepper) 	returnValue;
	returnValue = PtrArrayStepper::ascending(array);
	return returnValue;
}


INLINE RPTR(TableStepper) TableStepper::descending (APTR(PtrArray) array){
	/* Note: this being a low level operation, and there being no 
	lightweight form of immutable or lazily copied PtrArray, it 
	is my caller's responsibility to pass me a PtrArray which 
	will in fact not be changed during the life of this stepper.  
	This is an unchecked an uncheckable precondition on my clients. */
	
	WPTR(TableStepper) 	returnValue;
	returnValue = PtrArrayStepper::descending(array);
	return returnValue;
}
/* special */
/* create */
/* operations */


#endif /* STEPPERX_IXX */

