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

#ifndef FILTERX_IXX
#define FILTERX_IXX


#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */






/* ************************************************************************ *
 * 
 *                    Class Filter 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* private: functions */
/* operations */


INLINE RPTR(XnRegion) Filter::simpleUnion (APTR(XnRegion) other){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->unionWith(other);
	return returnValue;
}
/* testing */


INLINE BooleanVar Filter::isFinite (){
	return FALSE;
}


INLINE BooleanVar Filter::isSimple (){
	return TRUE;
}
/* enumerating */
/* accessing */


INLINE RPTR(XnRegion) Filter::asSimpleRegion (){
	return this;
}


INLINE RPTR(CoordinateSpace) Filter::coordinateSpace (){
	return (FilterSpace*) myCS;
}
/* filtering */
/* creation */
/* components */
/* vulnerable: internal */
/* protected: enumerating */
/* protected: */


INLINE RPTR(FilterSpace) Filter::filterSpace (){
	return (FilterSpace*) myCS;
}



/* ************************************************************************ *
 * 
 *                    Class FilterPosition 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* testing */
/* accessing */


INLINE RPTR(XnRegion) FilterPosition::baseRegion (){
	/* Essential. The region in the base space which I represent. */
	
	return (XnRegion*) myRegion;
}
/* instance creation */



/* ************************************************************************ *
 * 
 *                    Class FilterSpace 
 *
 * ************************************************************************ */


/* creation */
/* rcvr pseudo constructors */
/* creation */
/* testing */
/* accessing */


INLINE RPTR(CoordinateSpace) FilterSpace::baseSpace (){
	/* Essential.  The CoordinateSpace of the Regions that are 
	the input to Filters in this FilterSpace. */
	
	return (CoordinateSpace*) myBaseSpace;
}
/* printing */
/* making */


INLINE RPTR(Filter) FilterSpace::allFilter (APTR(XnRegion) region){
	/* Essential. A region that matches any region that contains 
	all the Positions in, i.e. is a superset of, the given region. */
	
	WPTR(Filter) 	returnValue;
	returnValue = Filter::supersetFilter(this, region);
	return returnValue;
}


INLINE RPTR(Filter) FilterSpace::anyFilter (APTR(XnRegion) baseRegion){
	/* Essential. A filter that matches any region that 
	intersects the given region. */
	
	WPTR(Filter) 	returnValue;
	returnValue = Filter::intersectionFilter(this, baseRegion);
	return returnValue;
}


INLINE RPTR(Filter) FilterSpace::intersectionFilter (APTR(XnRegion) region){
	/* Essential. A filter that matches any region that 
	intersects the given region. */
	
	WPTR(Filter) 	returnValue;
	returnValue = Filter::intersectionFilter(this, region);
	return returnValue;
}


INLINE RPTR(Filter) FilterSpace::notSubsetFilter (APTR(XnRegion) region){
	/* A filter matching any regions that is not a subset of the 
	given region. */
	
	WPTR(Filter) 	returnValue;
	returnValue = Filter::notSubsetFilter(this, region);
	return returnValue;
}


INLINE RPTR(Filter) FilterSpace::notSupersetFilter (APTR(XnRegion) region){
	/* A filter that matches any region that is not a superset of 
	the given region. */
	
	WPTR(Filter) 	returnValue;
	returnValue = Filter::notSupersetFilter(this, region);
	return returnValue;
}


INLINE RPTR(Filter) FilterSpace::orFilter (APTR(ScruSet) OF1(Filter) subs){
	/* A filter that matches any region that any of the filters 
	in the set would have matched. */
	
	WPTR(Filter) 	returnValue;
	returnValue = Filter::orFilter(this, subs);
	return returnValue;
}


INLINE RPTR(FilterPosition) FilterSpace::position (APTR(XnRegion) baseRegion){
	/* Essential. Given a Region in the baseSpace, make a 
	Position which corresponds to it, so that
			filter->hasMember (this->position (baseRegion)) iff 
	filter->match (baseRegion) */
	
	WPTR(FilterPosition) 	returnValue;
	returnValue = FilterPosition::make (baseRegion);
	return returnValue;
}


INLINE RPTR(Filter) FilterSpace::subsetFilter (APTR(XnRegion) region){
	/* A filter that matches any region that is a subset of the 
	given region. */
	
	WPTR(Filter) 	returnValue;
	returnValue = Filter::subsetFilter(this, region);
	return returnValue;
}


INLINE RPTR(Filter) FilterSpace::supersetFilter (APTR(XnRegion) region){
	/* Essential. A region that matches any region that is a 
	superset of the given region. */
	
	WPTR(Filter) 	returnValue;
	returnValue = Filter::supersetFilter(this, region);
	return returnValue;
}
/* hooks: */



/* ************************************************************************ *
 * 
 *                    Class Joint 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* creation */
/* printing */
/* accessing */


INLINE RPTR(XnRegion) Joint::intersected (){
	/* The intersection of the regions at all child nodes in the tree. */
	
	return (XnRegion*) myIntersected;
}


INLINE RPTR(Joint) Joint::join (APTR(Joint) other){
	/* A Joint that is a parent of this Joint and the given one. */
	
	WPTR(Joint) 	returnValue;
	returnValue = Joint::make (this, other);
	return returnValue;
}


INLINE RPTR(XnRegion) Joint::unioned (){
	/* The union of the regions at all child nodes in the tree. */
	
	return (XnRegion*) myUnioned;
}
/* testing */



/* ************************************************************************ *
 * 
 *                    Class RegionDelta 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* creation */
/* testing */


INLINE BooleanVar RegionDelta::isSame (){
	/* if the before and after are the same */
	
	return myBefore->isEqual(myAfter);
}
/* accessing */


INLINE RPTR(XnRegion) RegionDelta::after (){
	/* The region after the change. */
	
	return (XnRegion*) myAfter;
}


INLINE RPTR(XnRegion) RegionDelta::before (){
	/* The region before the change. */
	
	return (XnRegion*) myBefore;
}


#endif /* FILTERX_IXX */

