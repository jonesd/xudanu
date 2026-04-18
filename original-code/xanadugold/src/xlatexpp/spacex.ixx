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

#ifndef SPACEX_IXX
#define SPACEX_IXX


#ifndef SPACEP_HXX
#include "spacep.hxx"
#endif /* SPACEP_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */






/* ************************************************************************ *
 * 
 *                    Class Arrangement 
 *
 * ************************************************************************ */


/* accessing */
/* testing */



/* ************************************************************************ *
 * 
 *                    Class CoordinateSpace 
 *
 * ************************************************************************ */


/* accessing */


INLINE RPTR(OrderSpec) CoordinateSpace::ascending (){
	/* Essential.  The natural full-ordering of the coordinate space. */
	
	WPTR(OrderSpec) 	returnValue;
	returnValue = this->getAscending();
	return returnValue;
}


INLINE RPTR(Mapping) CoordinateSpace::completeMapping (APTR(XnRegion) range){
	/* Essential. A Mapping which maps each position in this 
	space to every position in the range region. The region can 
	be from any CoordinateSpace. */
	
	WPTR(Mapping) 	returnValue;
	returnValue = Mapping::make (this, range);
	return returnValue;
}


INLINE RPTR(OrderSpec) CoordinateSpace::descending (){
	/* The mirror image of the partial order returned by 
	'CoordinateSpace::ascending'. */
	
	WPTR(OrderSpec) 	returnValue;
	returnValue = this->getDescending();
	return returnValue;
}


INLINE RPTR(XnRegion) CoordinateSpace::emptyRegion (){
	/* Essential.  An empty region in this coordinate space */
	
	return (XnRegion*) myEmptyRegion;
}


INLINE RPTR(OrderSpec) OR(NULL) CoordinateSpace::fetchAscending (){
	/* The natural full-ordering of the coordinate space. */
	
	return (OrderSpec*) myAscending;
}


INLINE RPTR(OrderSpec) OR(NULL) CoordinateSpace::fetchDescending (){
	/* The mirror image of the partial order returned by 
		'CoordinateSpace::fetchAscending'. */
	
	return (OrderSpec*) myDescending;
}


INLINE RPTR(XnRegion) CoordinateSpace::fullRegion (){
	/* A full region in this coordinate space */
	
	return (XnRegion*) myFullRegion;
}


INLINE RPTR(Dsp) CoordinateSpace::identityDsp (){
	/* A Dsp which maps all positions in the coordinate space 
	onto themselves */
	
	return (Dsp*) myIdentityDsp;
}


INLINE RPTR(Mapping) CoordinateSpace::identityMapping (){
	/* Essential.  A Mapping which maps all positions in the 
	coordinate space onto themselves */
	
	WPTR(Mapping) 	returnValue;
	returnValue = this->identityDsp();
	return returnValue;
}
/* protected: create followup */
/* create */



/* ************************************************************************ *
 * 
 *                    Class Mapping 
 *
 * ************************************************************************ */


/* pseudo constructors */


INLINE RPTR(Mapping) Mapping::make (APTR(CoordinateSpace) cs, APTR(CoordinateSpace) rs){
	/* Make an empty mapping from cs to rs. The domain will consist of an 
		empty region in cs, and the range will consist of an empty 
	region in rs */
	
	WPTR(Mapping) 	returnValue;
	returnValue = EmptyMapping::make (cs, rs);
	return returnValue;
}
/* accessing */


INLINE RPTR(CoordinateSpace) Mapping::domainSpace (){
	/* The coordinate space of the domain of the Mapping */
	
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = this->coordinateSpace();
	return returnValue;
}
/* mapping */
/* operations */
/* vulnerable: accessing */
/* testing */



/* ************************************************************************ *
 * 
 *                    Class   Dsp 
 *
 * ************************************************************************ */


/* accessing */


INLINE RPTR(Mapping) Dsp::appliedAfter (APTR(Dsp) dsp){
	/* For Dsp's, it is identical to compose. */
	
	WPTR(Mapping) 	returnValue;
	returnValue = this->compose(dsp);
	return returnValue;
}


INLINE RPTR(Dsp) OR(NULL) Dsp::fetchDsp (){
	return this;
}


INLINE BooleanVar Dsp::isComplete (){
	return FALSE;
}


INLINE RPTR(CoordinateSpace) Dsp::rangeSpace (){
	/* Same as the domain space */
	
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = this->coordinateSpace();
	return returnValue;
}


INLINE RPTR(Mapping) Dsp::transformedBy (APTR(Dsp) dsp){
	/* For Dsp's, it is identical to preCompose. */
	
	WPTR(Mapping) 	returnValue;
	returnValue = dsp->compose(this);
	return returnValue;
}
/* combining */
/* transforming */
/* operations */


INLINE RPTR(Mapping) Dsp::restrict (APTR(XnRegion) region){
	WPTR(Mapping) 	returnValue;
	returnValue = SimpleMapping::restrictTo(region, this);
	return returnValue;
}
/* protected: */
/* deferred transforming */
/* deferred combining */



/* ************************************************************************ *
 * 
 *                    Class OrderSpec 
 *
 * ************************************************************************ */


/* testing */
/* accessing */



/* ************************************************************************ *
 * 
 *                    Class Position 
 *
 * ************************************************************************ */


/* testing */
/* accessing */



/* ************************************************************************ *
 * 
 *                    Class XnRegion 
 *
 * ************************************************************************ */


/* pseudo constructors */
/* accessing */
/* operations */
/* testing */
/* enumerating */


INLINE RPTR(Stepper) OF1(XnRegion) XnRegion::disjointSimpleRegions (APTR(OrderSpec) order/* = NULL*/){
	/* break it up into a set of non-empty simple regions which don't 
		overlap. This message satisfies all the specs of 'simpleRegions', and 
		in addition provides for lack of overlap. It may be 
	significantly more 
		expensive than 'simpleRegions' which is why they both exist. */
	
	WPTR(Stepper) OF1(XnRegion) 	returnValue;
	returnValue = DisjointRegionStepper::make (this, order);
	return returnValue;
}
/* protected: enumerating */


#endif /* SPACEX_IXX */

