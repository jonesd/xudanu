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

#ifndef REALX_IXX
#define REALX_IXX


#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef REALP_HXX
#include "realp.hxx"
#endif /* REALP_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */






/* ************************************************************************ *
 * 
 *                    Class RealPos 
 *
 * ************************************************************************ */


/* creation */


INLINE RPTR(RealPos) RealPos::make (IEEE64 value){
	/* make an XuReal given an IEEE floating point number of 
	whatever precision on this platform is able to hold all the 
	real numbers currently representable by an XuReal.  Currently 
	this is IEEE64 (double precision), but may be redeclared as a 
	larger IEEE precision in the future.  See comment in 
	XuReal::makeIEEE64 */
	
	WPTR(RealPos) 	returnValue;
	returnValue = RealPos::makeIEEE64(value);
	return returnValue;
}
/* accessing */


INLINE RPTR(CoordinateSpace) RealPos::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = RealSpace::make ();
	return returnValue;
}
/* testing */
/* obsolete: */



/* ************************************************************************ *
 * 
 *                    Class RealRegion 
 *
 * ************************************************************************ */


/* creation */
/* enumerating */


INLINE IntegerVar RealRegion::count (){
	return RealRegion::TheManager->count(this);
}


INLINE RPTR(ScruSet) OF1(XnRegion) RealRegion::distinctions (){
	WPTR(ScruSet) OF1(XnRegion) 	returnValue;
	returnValue = RealRegion::TheManager->distinctions(this);
	return returnValue;
}


INLINE RPTR(Stepper) OF1(RealRegion) RealRegion::intervals (APTR(OrderSpec) order/* = NULL*/){
	/* Essential. Break this up into disjoint intervals */
	
	WPTR(Stepper) OF1(RealRegion) 	returnValue;
	returnValue = this->simpleRegions(order);
	return returnValue;
}


INLINE BooleanVar RealRegion::isInterval (){
	/* Whether this Region is a non-empty interval, i.e. if A, B 
	in the Region and A <= C <= B then C is in the Region. This 
	includes inequalities (e.g. {x | x > 5}) and the fullRegion 
	in addition to ordinary two-ended intervals. */
	
	return this->isSimple();
}
/* protected: enumerating */
/* testing */


INLINE BooleanVar RealRegion::hasMember (APTR(Position) position){
	return RealRegion::TheManager->hasMember(this, position);
}


INLINE BooleanVar RealRegion::isBoundedAbove (){
	/* Same meaning as IntegerRegion::isBoundedAbove */
	
	return RealRegion::TheManager->isBoundedRight(this);
}


INLINE BooleanVar RealRegion::isBoundedBelow (){
	/* Same meaning as IntegerRegion::isBoundedBelow */
	
	return RealRegion::TheManager->isBoundedLeft(this);
}


INLINE BooleanVar RealRegion::isEmpty (){
	return RealRegion::TheManager->isEmpty(this);
}


INLINE BooleanVar RealRegion::isEnumerable (APTR(OrderSpec) order/* = NULL*/){
	/* Any representable infinite set of real numbers is also not 
	enumerable */
	
	return this->isFinite();
}
/* operations */


INLINE RPTR(XnRegion) RealRegion::complement (){
	WPTR(XnRegion) 	returnValue;
	returnValue = RealRegion::TheManager->complement(this);
	return returnValue;
}


INLINE RPTR(XnRegion) RealRegion::intersect (APTR(XnRegion) other){
	WPTR(XnRegion) 	returnValue;
	returnValue = RealRegion::TheManager->intersect(this, other);
	return returnValue;
}
/* secret */


INLINE BooleanVar RealRegion::startsInside (){
	return myStartsInside;
}
/* printing */
/* accessing */


INLINE RPTR(XnRegion) RealRegion::asSimpleRegion (){
	WPTR(XnRegion) 	returnValue;
	returnValue = RealRegion::TheManager->asSimpleRegion(this);
	return returnValue;
}


INLINE RPTR(CoordinateSpace) RealRegion::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = RealSpace::make ();
	return returnValue;
}
/* creation */



/* ************************************************************************ *
 * 
 *                    Class RealSpace 
 *
 * ************************************************************************ */


/* creation */


INLINE RPTR(RealSpace) RealSpace::make (){
	WPTR(RealSpace) 	returnValue;
	returnValue = RealSpace::TheRealSpace;
	return returnValue;
}
/* rcvr pseudo constructors */
/* create */
/* making */


INLINE RPTR(RealPos) RealSpace::position (IEEE64 val){
	/* The XuReal representing the same real number as that 
	exactly represented by 'val'.  If 'val' doesn't represent a 
	real number (i.e., it is an infinity or a NAN), then this 
	message BLASTs.  If 'val' is a negative zero, it is silently 
	converted to a positive zero */
	
	WPTR(RealPos) 	returnValue;
	returnValue = RealPos::make (val);
	return returnValue;
}
/* obsolete: */
/* testing */


#endif /* REALX_IXX */

