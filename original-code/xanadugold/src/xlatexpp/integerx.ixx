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

#ifndef INTEGERX_IXX
#define INTEGERX_IXX


#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */






/* ************************************************************************ *
 * 
 *                    Class IntegerMapping 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* private: for create */
/* unprotected for init creation */
/* printing */
/* transforming */
/* accessing */


INLINE RPTR(CoordinateSpace) IntegerMapping::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = IntegerSpace::make ();
	return returnValue;
}


INLINE BooleanVar IntegerMapping::isIdentity (){
	return myTranslation == IntegerVar0;
}


INLINE IntegerVar IntegerMapping::translation (){
	/* The offset which I add to a position.  
		If my translation is 7, then this->of(4) is 11. */
	
	return myTranslation;
}
/* testing */
/* combining */
/* sender */



/* ************************************************************************ *
 * 
 *                    Class IntegerPos 
 *
 * ************************************************************************ */


/* pseudo constructors */


INLINE RPTR(IntegerPos) IntegerPos::make (IntegerVar newValue){
	/* Box an integer. See XuInteger class comment. you can also create an 
		integer in smalltalk by sending the integer message to a 
	Smalltalk integer */
	
	RETURN_CONSTRUCT(IntegerPos,(newValue, tcsj));
}


INLINE RPTR(IntegerPos) IntegerPos::zero (){
	/* Box an integer. See XuInteger class comment. you can also create an 
		integer in smalltalk by sending the integer message to a 
	Smalltalk integer.
		This should return the canonical zero eventually. */
	
	WPTR(IntegerPos) 	returnValue;
	returnValue = IntegerPos::make (IntegerVarZero);
	return returnValue;
}
/* hash computing */


INLINE UInt32 IntegerPos::integerHash (IntegerVar value){
	/* NOTE:  Do NOT change this without also changing the 
	implementation of hashForEqual in XuInteger!!!. */
	
	
	/* bitShiftRight: 6 */
	return (value * 99991).asLong() & 16777215 ^ 98953;
	
}
/* testing */
/* accessing */


INLINE Int32 IntegerPos::asInt32 (){
	/* Unboxed version as an integer.  See class comment */
	
	return myValue.asLong();
}


INLINE IntegerVar IntegerPos::asIntegerVar (){
	/* Essential.  Unboxed version.  See class comment */
	
	return myValue;
}


INLINE RPTR(CoordinateSpace) IntegerPos::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = IntegerSpace::make ();
	return returnValue;
}


INLINE IntegerVar IntegerPos::value (){
	/* Essential.  Unboxed version.  See class comment */
	
	return myValue;
}
/* printing */
/* protected: creation */



/* ************************************************************************ *
 * 
 *                    Class IntegerRegion 
 *
 * ************************************************************************ */


/* pseudo constructors */


INLINE RPTR(IntegerRegion) IntegerRegion::allIntegers (){
	/* The full region of this space */
	
	WPTR(IntegerRegion) 	returnValue;
	returnValue = IntegerRegion::AllIntegers;
	return returnValue;
}


INLINE RPTR(IntegerRegion) IntegerRegion::make (){
	/* No integers, the empty region */
	
	WPTR(IntegerRegion) 	returnValue;
	returnValue = IntegerRegion::EmptyIntegerRegion;
	return returnValue;
}
/* privacy violator */


INLINE RPTR(IntegerVarArray) IntegerRegion::badlyViolatePrivacyOfIntegerRegionTransitions (APTR(IntegerRegion) reg){
	/* used for an efficiency hack in PointRegion.  Don't use. */
	
	WPTR(IntegerVarArray) 	returnValue;
	returnValue = reg->secretTransitions();
	return returnValue;
}
/* private: pseudo constructors */
/* accessing */


INLINE RPTR(CoordinateSpace) IntegerRegion::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = IntegerSpace::make ();
	return returnValue;
}
/* unprotected creation */
/* destroy */
/* printing */
/* testing */


INLINE BooleanVar IntegerRegion::isBoundedBelow (){
	/* Either I extend indefinitely to minus infinity, or I am 
	bounded below, not both. 
		The empty region is bounded below despite the fact that it 
	has no lower bound. */
	
	return !myStartsInside;
}
/* operations */
/* enumerating */


INLINE RPTR(Stepper) OF1(IntegerRegion) IntegerRegion::intervals (APTR(OrderSpec) /* order *//* = NULL*/){
	/* Essential. Break this into an ascending sequence of 
	disjoint intervals (which may be unbounded). */
	
	WPTR(Stepper) OF1(IntegerRegion) 	returnValue;
	returnValue = this->simpleRegions();
	return returnValue;
}


INLINE BooleanVar IntegerRegion::isInterval (){
	/* Whether this Region is a non-empty interval, i.e. if A, B 
	in the Region and A <= C <= B then C is in the Region. This 
	includes inequalities (e.g. {x | x > 5}) and the fullRegion 
	in addition to ordinary two-ended intervals. */
	
	return this->isSimple();
}
/* breaking up */
/* private: */


INLINE RPTR(IntegerVarArray) IntegerRegion::secretTransitions (){
	/* The actuall array. DO NOT MODIFY */
	
	return (IntegerVarArray*) myTransitions;
}
/* private: has friends */


INLINE UInt32 IntegerRegion::transitionCount (){
	/* Do not send from outside the module. This should not be exported 
		outside the module, but to not export it in this case is 
	some trouble. 
		It is used for an efficiency hack in PointRegion. */
	
	return myTransitionCount;
}
/* protected: enumerating */



/* ************************************************************************ *
 * 
 *                    Class IntegerSpace 
 *
 * ************************************************************************ */


/* creation */


INLINE RPTR(IntegerSpace) IntegerSpace::implicitReceiver (){
	/* Get the receievr for wire requests. */
	
	WPTR(IntegerSpace) 	returnValue;
	returnValue = IntegerSpace::TheIntegerSpace;
	return returnValue;
}


INLINE RPTR(IntegerSpace) IntegerSpace::make (){
	/* return the one integer space */
	
	WPTR(IntegerSpace) 	returnValue;
	returnValue = IntegerSpace::TheIntegerSpace;
	return returnValue;
}
/* rcvr pseudo constructor */
/* creation */
/* making */


INLINE RPTR(IntegerPos) IntegerSpace::position (IntegerVar value){
	/* Essential. Make an integer Position object */
	
	WPTR(IntegerPos) 	returnValue;
	returnValue = IntegerPos::make (value);
	return returnValue;
}
/* testing */


#endif /* INTEGERX_IXX */

