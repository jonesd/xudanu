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

#ifndef EDGER_HXX
#define EDGER_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef EDGER_OXX
#include "edger.oxx"
#endif /* EDGER_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef EDGEP_OXX
#include "edgep.oxx"
#endif /* EDGEP_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class EdgeManager 
 *
 * ************************************************************************ */




	/* Manages the common code for regions which are represented 
	as a sequence of EdgeTransitions. Each coordinate space 
	should define a subclass which implements the appropriate 
	methods, and then use it to do the various region operations. 
	Clients of the region do not need to see any of these classes. */

class EdgeManager : public Heaper {

/* Attributes for class EdgeManager */
	DEFERRED(EdgeManager)
	EQ(EdgeManager)
	NO_GC(EdgeManager)
  private: /* private: */

	/* Create an accumulator which takes edges and creates a region */
	
	virtual RPTR(EdgeAccumulator) edgeAccumulator (BooleanVar ARG(startsInside));
	
	/* Create a stepper for iterating through the edges of the region */
	
	virtual RPTR(EdgeStepper) edgeStepper (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(TransitionEdge) lowerEdge (APTR(XnRegion) ARG(region));
	
	/* Create a stepper for iterating through the edges of the region */
	
	virtual RPTR(EdgeStepper) singleEdgeStepper (APTR(Position) ARG(pos));
	
	
	virtual RPTR(TransitionEdge) upperEdge (APTR(XnRegion) ARG(region));
	
  public: /* testing */

	
	virtual BooleanVar hasMember (APTR(XnRegion) ARG(region), APTR(Position) ARG(pos));
	
	/* Same meaning as IntegerRegion::isBoundedLeft */
	
	virtual BooleanVar isBoundedLeft (APTR(XnRegion) ARG(region));
	
	/* Same meaning as IntegerRegion::isBoundedRight */
	
	virtual BooleanVar isBoundedRight (APTR(XnRegion) ARG(region));
	
	
	virtual BooleanVar isEmpty (APTR(XnRegion) ARG(region));
	
	/* Here is one place where the *infinite* of the infinite 
	divisibility assumed by OrderedRegion about the full ordering 
	comes in (see class comment).  
		An interval whose left edge is not the same as the right 
	edge is assumed to contain an infinite number of positions */
	
	virtual BooleanVar isFinite (APTR(XnRegion) ARG(region));
	
	
	virtual BooleanVar isFull (APTR(XnRegion) ARG(region));
	
	
	virtual BooleanVar isSimple (APTR(XnRegion) ARG(region));
	
	
	virtual BooleanVar isSubsetOf (APTR(XnRegion) ARG(me), APTR(XnRegion) ARG(other));
	
  public: /* enumerating */

	/* Because Edge Regions should only be used on infinitely 
	divisible spaces (like rationals), if it's finite then it is 
	bounded on both sides, and all the internal intervals are singletons */
	
	virtual IntegerVar count (APTR(XnRegion) ARG(region));
	
  public: /* accessing */

	
	virtual RPTR(XnRegion) asSimpleRegion (APTR(XnRegion) ARG(region));
	
	/* The largest position such that no other positions in the 
	region are any less than it. In other words, this is the 
	lower bounding element. We choose to avoid the terms 
	'lowerBound' and 'upperBound' as their meanings in 
	IntegerRegion are significantly different. Here, both 'all 
	numbers >= 3' and 'all numbers > 3' have a 
	'greatestLowerBound' of 3 even though the latter doesn't 
	include 3. To tell whether a bound is included, good old 
	'hasMember' should do a fine job. */
	
	virtual RPTR(Position) greatestLowerBound (APTR(XnRegion) ARG(region));
	
	/* The smallest position such that no other positions in the 
	region are 
		any greater than it. In other words, this is the upper 
	bounding element. 
		We choose to avoid the terms 'lowerBound' and 'upperBound' as 
		their meanings in IntegerRegion are significantly different. 
	Here, both 
		'all numbers <= 3' and 'all numbers < 3' have a 'leastUpperBound' 
		of 3 even though the latter doesn't include 3. To tell whether a 
		bound is included, good old 'hasMember' should do a fine job. */
	
	virtual RPTR(Position) leastUpperBound (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(XnRegion) simpleUnion (APTR(XnRegion) ARG(me), APTR(XnRegion) ARG(other));
	
  public: /* printing */

	
	virtual void printRegionOn (APTR(XnRegion) ARG(region), ostream& ARG(oo));
	
  public: /* operations */

	
	virtual RPTR(XnRegion) complement (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(ScruSet) OF1(XnRegion) distinctions (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(XnRegion) intersect (APTR(XnRegion) ARG(meRegion), APTR(XnRegion) ARG(otherRegion));
	
	
	virtual RPTR(Stepper) simpleRegions (APTR(XnRegion) ARG(region), APTR(OrderSpec) ARG(order) = NULL);
	
	
	virtual RPTR(XnRegion) unionWith (APTR(XnRegion) ARG(meRegion), APTR(XnRegion) ARG(otherRegion));
	
	
	virtual RPTR(XnRegion) with (APTR(XnRegion) ARG(meRegion), APTR(Position) ARG(newPos));
	
  protected: /* protected: */

	/* The position associated with the given edge. Blast if 
	there is none */
	
	virtual RPTR(Position) edgePosition (APTR(TransitionEdge) ARG(edge)) DEFERRED_FUNC;
	
	/* Make a new region of the right type */
	
	virtual RPTR(XnRegion) makeNew (BooleanVar ARG(startsInside), APTR(PtrArray) OF1(TransitionEdge) ARG(transitions)) DEFERRED_FUNC;
	
	/* Make a new region of the right type */
	
	virtual RPTR(XnRegion) makeNew (
			BooleanVar ARG(startsInside), 
			APTR(PtrArray) OF1(TransitionEdge) ARG(transitions), 
			Int32 ARG(count))
	 DEFERRED_FUNC;
	
	
	virtual RPTR(PtrArray) OF1(TransitionEdge) posTransitions (APTR(Position) ARG(pos)) DEFERRED_FUNC;
	
	
	virtual BooleanVar startsInside (APTR(XnRegion) ARG(region)) DEFERRED_FUNC;
	
	
	virtual RPTR(PtrArray) OF1(TransitionEdge) transitions (APTR(XnRegion) ARG(region)) DEFERRED_FUNC;
	
	
	virtual Int32 transitionsCount (APTR(XnRegion) ARG(region)) DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	EdgeManager();

/* Friends for class EdgeManager */
friend class EdgeSimpleRegionStepper;
friend class EdgeAccumulator;



};  /* end class EdgeManager */



/* ************************************************************************ *
 * 
 *                    Class TransitionEdge 
 *
 * ************************************************************************ */




	/* Clients of EdgeManager define concrete subclasses of this, 
	which are then used by the EdgeManager code */

class TransitionEdge : public Heaper {

/* Attributes for class TransitionEdge */
	DEFERRED(TransitionEdge)
	COPY(TransitionEdge,XppCuisine)
	NO_GC(TransitionEdge)
  public: /* accessing */

	
	virtual RPTR(TransitionEdge) ceiling (APTR(TransitionEdge) ARG(other));
	
	
	virtual RPTR(TransitionEdge) floor (APTR(TransitionEdge) ARG(other));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	/* Whether the position is strictly less than this edge */
	
	virtual BooleanVar follows (APTR(Position) ARG(pos)) DEFERRED_FUNC;
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other)) DEFERRED_FUNC;
	
	/* Whether there is precisely one position between this edge 
	and the next one */
	
	virtual BooleanVar isFollowedBy (APTR(TransitionEdge) ARG(next)) DEFERRED_FUNC;
	
	/* Defines a full ordering among all edges in a given 
	CoordinateSpace */
	
	virtual BooleanVar isGE (APTR(TransitionEdge) ARG(other)) DEFERRED_FUNC;
	
	/* Whether this edge touches the same position the other does */
	
	virtual BooleanVar touches (APTR(TransitionEdge) ARG(other)) DEFERRED_FUNC;
	
  public: /* printing */

	/* Print a description of this transition */
	
	virtual void printTransitionOn (
			ostream& ARG(oo), 
			BooleanVar ARG(entering), 
			BooleanVar ARG(touchesPrevious))
	 DEFERRED_SUBR;
	

	/* automatic 0-argument constructor */
  public:
	TransitionEdge();

};  /* end class TransitionEdge */



#endif /* EDGER_HXX */

