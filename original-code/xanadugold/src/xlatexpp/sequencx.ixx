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

#ifndef SEQUENCX_IXX
#define SEQUENCX_IXX


#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef SEQUENCP_HXX
#include "sequencp.hxx"
#endif /* SEQUENCP_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */


#include <sys/types.h>
#ifndef WIN32
#	include <sys/time.h>
#else
#	include <sys/timeb.h>
#endif /* WIN32 */




/* ************************************************************************ *
 * 
 *                    Class Sequence 
 *
 * ************************************************************************ */


/* pseudo constructors */


INLINE RPTR(Sequence) Sequence::zero (){
	WPTR(Sequence) 	returnValue;
	returnValue = Sequence::TheZero;
	return returnValue;
}
/* private: */
/* accessing */


INLINE RPTR(CoordinateSpace) Sequence::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = SequenceSpace::make ();
	return returnValue;
}


INLINE IntegerVar Sequence::count (){
	/* How many numbers in the sequence, not counting leading or 
	trailing zeros */
	
	return myNumbers->count();
}


INLINE IntegerVar Sequence::shift (){
	/* The amount by which the numbers are shifted. Positive 
	means less significant, negative means more significant. This 
	is contrary to the usual arithmetic notions, but it is the 
	right thing for arrays. */
	
	return myShift;
}
/* private: comparing */
/* testing */
/* private: */


INLINE RPTR(PrimIntegerArray) Sequence::secretNumbers (){
	/* The array itself, for internal use */
	
	return (PrimIntegerArray*) myNumbers;
}
/* printing */
/* create */
/* operations */



/* ************************************************************************ *
 * 
 *                    Class SequenceMapping 
 *
 * ************************************************************************ */


/* private: pseudo constructors */
/* accessing */


INLINE RPTR(CoordinateSpace) SequenceMapping::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = SequenceSpace::make ();
	return returnValue;
}


INLINE IntegerVar SequenceMapping::shift (){
	/* The amount by which it shifts a sequence */
	
	return myShift;
}


INLINE RPTR(Sequence) SequenceMapping::translation (){
	/* What it adds to a sequence after shifting it */
	
	return (Sequence*) myTranslation;
}
/* transforming */
/* combining */
/* private: create */



/* ************************************************************************ *
 * 
 *                    Class SequenceRegion 
 *
 * ************************************************************************ */


/* pseudo constructors */


INLINE RPTR(SequenceRegion) SequenceRegion::empty (){
	WPTR(SequenceRegion) 	returnValue;
	returnValue = SequenceRegion::TheEmptySequenceRegion;
	return returnValue;
}


INLINE RPTR(SequenceRegion) SequenceRegion::full (){
	WPTR(SequenceRegion) 	returnValue;
	returnValue = SequenceRegion::TheFullSequenceRegion;
	return returnValue;
}
/* private: */
/* constants */


INLINE Int32 SequenceRegion::EXCLUSIVE () CONST{
	return 2;
}


INLINE Int32 SequenceRegion::INCLUSIVE () CONST{
	return 1;
}


INLINE Int32 SequenceRegion::PREFIX () CONST{
	return 3;
}
/* create */
/* accessing */
/* testing */


INLINE BooleanVar SequenceRegion::isBoundedAbove (){
	/* Same meaning as IntegerRegion::isBoundedAbove */
	
	return SequenceRegion::TheManager->isBoundedRight(this);
}


INLINE BooleanVar SequenceRegion::isBoundedBelow (){
	/* Same meaning as IntegerRegion::isBoundedBelow */
	
	return SequenceRegion::TheManager->isBoundedLeft(this);
}
/* protected: enumerating */
/* enumerating */


INLINE RPTR(Stepper) OF1(SequenceRegion) SequenceRegion::intervals (APTR(OrderSpec) order/* = NULL*/){
	/* Essential. Break this up into disjoint intervals */
	
	WPTR(Stepper) OF1(SequenceRegion) 	returnValue;
	returnValue = this->simpleRegions(order);
	return returnValue;
}


INLINE BooleanVar SequenceRegion::isInterval (){
	/* Whether this Region is a non-empty interval, i.e. if A, B 
	in the Region and A <= C <= B then C is in the Region. This 
	includes inequalities (e.g. {x | x > 5.3}) and the fullRegion 
	in addition to ordinary two-ended intervals. */
	
	return this->isSimple();
}
/* operations */
/* printing */
/* secret */


INLINE RPTR(PtrArray) OF1(SequenceEdge) SequenceRegion::secretTransitions (){
	return (PtrArray*) myTransitions;
}


INLINE Int32 SequenceRegion::secretTransitionsCount (){
	return myTransitionsCount;
}


INLINE BooleanVar SequenceRegion::startsInside (){
	return myStartsInside;
}
/* hooks: */



/* ************************************************************************ *
 * 
 *                    Class SequenceSpace 
 *
 * ************************************************************************ */


/* rcvr creation */
/* creation */


INLINE RPTR(SequenceSpace) SequenceSpace::implicitReceiver (){
	/* Get the receiver for wire requests. */
	
	WPTR(SequenceSpace) 	returnValue;
	returnValue = SequenceSpace::TheSequenceSpace;
	return returnValue;
}


INLINE RPTR(SequenceSpace) SequenceSpace::make (){
	WPTR(SequenceSpace) 	returnValue;
	returnValue = SequenceSpace::TheSequenceSpace;
	return returnValue;
}
/* create */
/* temporary */


INLINE RPTR(Sequence) SequenceSpace::position (APTR(PrimArray) numbers){
	WPTR(Sequence) 	returnValue;
	returnValue = this->position(numbers, IntegerVarZero);
	return returnValue;
}
/* making */
/* testing */


#endif /* SEQUENCX_IXX */

