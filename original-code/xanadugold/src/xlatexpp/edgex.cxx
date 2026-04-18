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

#ifndef EDGEX_CXX
#define EDGEX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef EDGER_HXX
#include "edger.hxx"
#endif /* EDGER_HXX */

#ifndef EDGER_IXX
#include "edger.ixx"
#endif /* EDGER_IXX */

#ifndef EDGEP_HXX
#include "edgep.hxx"
#endif /* EDGEP_HXX */

#ifndef EDGEP_IXX
#include "edgep.ixx"
#endif /* EDGEP_IXX */


#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef PRIMVALX_HXX
#include "primvalx.hxx"
#endif /* PRIMVALX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */




/* ************************************************************************ *
 * 
 *                    Class EdgeManager 
 *
 * ************************************************************************ */


/* Manages the common code for regions which are represented as a 
sequence of EdgeTransitions. Each coordinate space should define a 
subclass which implements the appropriate methods, and then use it to 
do the various region operations. Clients of the region do not need 
to see any of these classes. */


/* private: */


RPTR(EdgeAccumulator) EdgeManager::edgeAccumulator (BooleanVar startsInside){
	/* Create an accumulator which takes edges and creates a region */
	
	WPTR(EdgeAccumulator) 	returnValue;
	returnValue = EdgeAccumulator::make (this, startsInside);
	return returnValue;
}


RPTR(EdgeStepper) EdgeManager::edgeStepper (APTR(XnRegion) region){
	/* Create a stepper for iterating through the edges of the region */
	
	WPTR(EdgeStepper) 	returnValue;
	returnValue = EdgeStepper::make (!this->startsInside(region), this->transitions(region), this->transitionsCount(region));
	return returnValue;
}


RPTR(TransitionEdge) EdgeManager::lowerEdge (APTR(XnRegion) region){
	SPTR(PtrArray) OF1(TransitionEdge) transitions;
	
	transitions = this->transitions(region);
	{	BooleanVar crutch_Flag;
		/* this->startsInside(region) || this->transitionsCount(region) == Int32Zero */
		
		crutch_Flag = this->startsInside(region);
		if(!crutch_Flag) {
			crutch_Flag = this->transitionsCount(region) == Int32Zero;
		}
		if (crutch_Flag) {
			BLAST(InvalidRequest);
		}
	}
	return CAST(TransitionEdge,transitions->fetch(Int32Zero));
}


RPTR(EdgeStepper) EdgeManager::singleEdgeStepper (APTR(Position) pos){
	/* Create a stepper for iterating through the edges of the region */
	
	WPTR(EdgeStepper) 	returnValue;
	returnValue = EdgeStepper::make (!FALSE, this->posTransitions(pos));
	return returnValue;
}


RPTR(TransitionEdge) EdgeManager::upperEdge (APTR(XnRegion) region){
	SPTR(PtrArray) OF1(TransitionEdge) transitions;
	Int32 transitionsCount;
	
	transitions = this->transitions(region);
	transitionsCount = this->transitionsCount(region);
	{	BooleanVar crutch_Flag;
		/* !this->isBoundedRight(region) || transitionsCount == Int32Zero */
		
		crutch_Flag = !this->isBoundedRight(region);
		if(!crutch_Flag) {
			crutch_Flag = transitionsCount == Int32Zero;
		}
		if (crutch_Flag) {
			BLAST(InvalidRequest);
		}
	}
	return CAST(TransitionEdge,transitions->fetch(transitionsCount - 1));
}
/* testing */


BooleanVar EdgeManager::hasMember (APTR(XnRegion) region, APTR(Position) pos){
	SPTR(EdgeStepper) edges;
	SPTR(TransitionEdge) edge;
	BooleanVar result;
	
	edges = this->edgeStepper(region);
	while ((edge = CAST(TransitionEdge,edges->fetch())) != NULL) {
		if (edge->follows(pos)) {
			result = !edges->isEntering();
			{edges->destroy();  edges = NULL /* don't want stale (S/CHK)PTRs */;}
			return result;
		}
		edges->step();
	}
	result = !edges->isEntering();
	{edges->destroy();  edges = NULL /* don't want stale (S/CHK)PTRs */;}
	return result;
}


BooleanVar EdgeManager::isBoundedLeft (APTR(XnRegion) region){
	/* Same meaning as IntegerRegion::isBoundedLeft */
	
	return !this->startsInside(region);
}


BooleanVar EdgeManager::isBoundedRight (APTR(XnRegion) region){
	/* Same meaning as IntegerRegion::isBoundedRight */
	
	return (this->transitionsCount(region) & 1) == Int32Zero != this->startsInside(region);
}


BooleanVar EdgeManager::isEmpty (APTR(XnRegion) region){
	{	BooleanVar crutch_Flag;
		/* !this->startsInside(region) && this->transitionsCount(region) == Int32Zero */
		
		crutch_Flag = !this->startsInside(region);
		if(crutch_Flag) {
			crutch_Flag = this->transitionsCount(region) == Int32Zero;
		}
		return crutch_Flag;
	}
}


BooleanVar EdgeManager::isFinite (APTR(XnRegion) region){
	/* Here is one place where the *infinite* of the infinite 
	divisibility assumed by OrderedRegion about the full ordering 
	comes in (see class comment).  
		An interval whose left edge is not the same as the right 
	edge is assumed to contain an infinite number of positions */
	
	SPTR(PtrArray) OF1(TransitionEdge) transitions;
	Int32 transitionsCount;
	
	transitions = this->transitions(region);
	transitionsCount = this->transitionsCount(region);
	{	BooleanVar crutch_Flag;
		/* this->startsInside(region) || (transitionsCount & 1) != Int32Zero */
		
		crutch_Flag = this->startsInside(region);
		if(!crutch_Flag) {
			crutch_Flag = (transitionsCount & 1) != Int32Zero;
		}
		if (crutch_Flag) {
			return FALSE;
		}
	}
	{
		Int32 LoopFinal = transitionsCount;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (!CAST(TransitionEdge,transitions->fetch(i))->isFollowedBy(CAST(TransitionEdge,transitions->fetch(i + 1)))) {
					return FALSE;
				}
			}
			i += 2;
		}
	}
	return TRUE;
}


BooleanVar EdgeManager::isFull (APTR(XnRegion) region){
	{	BooleanVar crutch_Flag;
		/* this->startsInside(region) && this->transitionsCount(region) == Int32Zero */
		
		crutch_Flag = this->startsInside(region);
		if(crutch_Flag) {
			crutch_Flag = this->transitionsCount(region) == Int32Zero;
		}
		return crutch_Flag;
	}
}


BooleanVar EdgeManager::isSimple (APTR(XnRegion) region){
	Int32 testVal;
	
	if (this->startsInside(region)) {
		testVal = 1;
	} else {
		testVal = 2;
	}
	return this->transitionsCount(region) <= testVal;
}


BooleanVar EdgeManager::isSubsetOf (APTR(XnRegion) me, APTR(XnRegion) other){
	SPTR(EdgeStepper) mine;
	SPTR(EdgeStepper) others;
	BooleanVar result;
	
	if (this->isEmpty(other)) {
		return this->isEmpty(me);
	}
	mine = this->edgeStepper(me);
	others = this->edgeStepper(other);
	{	BooleanVar crutch_Flag;
		/* mine->hasValue() || others->hasValue() */
		
		crutch_Flag = mine->hasValue();
		if(!crutch_Flag) {
			crutch_Flag = others->hasValue();
		}
		if (!crutch_Flag) {
			result = mine->isEntering() || !others->isEntering();
			{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
			{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
			return result;
		}
	}
	{	BooleanVar crutch_Flag;
		/* !mine->isEntering() && others->isEntering() */
		
		crutch_Flag = !mine->isEntering();
		if(crutch_Flag) {
			crutch_Flag = others->isEntering();
		}
		if (crutch_Flag) {
			{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
			{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
			return FALSE;
		}
	}
	for (;;) {	BooleanVar crutch_Flag;
		/* mine->hasValue() && others->hasValue() */
		
		crutch_Flag = mine->hasValue();
		if(crutch_Flag) {
			crutch_Flag = others->hasValue();
		}
		if (crutch_Flag) {
			if (!others->getEdge()->isGE(mine->getEdge())) {
				{	BooleanVar crutch_Flag;
					/* !others->isEntering() && !mine->isEntering() */
					
					crutch_Flag = !others->isEntering();
					if(crutch_Flag) {
						crutch_Flag = !mine->isEntering();
					}
					if (crutch_Flag) {
						{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
						{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
						return FALSE;
					}
				}
				others->step();
			} else {
				if (!mine->getEdge()->isGE(others->getEdge())) {
					{	BooleanVar crutch_Flag;
						/* others->isEntering() && mine->isEntering() */
						
						crutch_Flag = others->isEntering();
						if(crutch_Flag) {
							crutch_Flag = mine->isEntering();
						}
						if (crutch_Flag) {
							{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
							{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
							return FALSE;
						}
					}
					mine->step();
				} else {
					if (others->isEntering() != mine->isEntering()) {
						{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
						{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
						return FALSE;
					}
					others->step();
					mine->step();
				}
			}
		} else {
			break;
		}
	}
	result = !(mine->hasValue() && others->isEntering() || others->hasValue() && !mine->isEntering());
	{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
	{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
	return result;
}
/* enumerating */


IntegerVar EdgeManager::count (APTR(XnRegion) region){
	/* Because Edge Regions should only be used on infinitely 
	divisible spaces (like rationals), if it's finite then it is 
	bounded on both sides, and all the internal intervals are singletons */
	
	if (!this->isFinite(region)) {
		BLAST(MustBeFinite);
	}
	return this->transitionsCount(region) / 2;
}
/* accessing */


RPTR(XnRegion) EdgeManager::asSimpleRegion (APTR(XnRegion) region){
	if (this->isSimple(region)) {
		WPTR(XnRegion) 	returnValue;
		returnValue = region;
		return returnValue;
	}
	if (this->isBoundedLeft(region)) {
		if (this->isBoundedRight(region)) {
			WPTR(XnRegion) 	returnValue;
			returnValue = this->makeNew(FALSE, CAST(PtrArray,PrimSpec::pointer()->arrayWithTwo(this->lowerEdge(region), this->upperEdge(region))));
			return returnValue;
		} else {
			WPTR(XnRegion) 	returnValue;
			returnValue = this->makeNew(FALSE, CAST(PtrArray,PrimSpec::pointer()->arrayWith(this->lowerEdge(region))));
			return returnValue;
		}
	} else {
		if (this->isBoundedRight(region)) {
			WPTR(XnRegion) 	returnValue;
			returnValue = this->makeNew(TRUE, CAST(PtrArray,PrimSpec::pointer()->arrayWith(this->upperEdge(region))));
			return returnValue;
		} else {
			WPTR(XnRegion) 	returnValue;
			returnValue = this->makeNew(TRUE, PtrArray::empty());
			return returnValue;
		}
	}
}


RPTR(Position) EdgeManager::greatestLowerBound (APTR(XnRegion) region){
	/* The largest position such that no other positions in the 
	region are any less than it. In other words, this is the 
	lower bounding element. We choose to avoid the terms 
	'lowerBound' and 'upperBound' as their meanings in 
	IntegerRegion are significantly different. Here, both 'all 
	numbers >= 3' and 'all numbers > 3' have a 
	'greatestLowerBound' of 3 even though the latter doesn't 
	include 3. To tell whether a bound is included, good old 
	'hasMember' should do a fine job. */
	
	WPTR(Position) 	returnValue;
	returnValue = this->edgePosition(this->lowerEdge(region));
	return returnValue;
}


RPTR(Position) EdgeManager::leastUpperBound (APTR(XnRegion) region){
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
	
	WPTR(Position) 	returnValue;
	returnValue = this->edgePosition(this->upperEdge(region));
	return returnValue;
}


RPTR(XnRegion) EdgeManager::simpleUnion (APTR(XnRegion) me, APTR(XnRegion) other){
	if (this->isEmpty(me)) {
		WPTR(XnRegion) 	returnValue;
		returnValue = this->asSimpleRegion(other);
		return returnValue;
	}
	if (this->isEmpty(other)) {
		WPTR(XnRegion) 	returnValue;
		returnValue = this->asSimpleRegion(me);
		return returnValue;
	}
	{	BooleanVar crutch_Flag;
		/* this->isBoundedLeft(me) && this->isBoundedLeft(other) */
		
		crutch_Flag = this->isBoundedLeft(me);
		if(crutch_Flag) {
			crutch_Flag = this->isBoundedLeft(other);
		}
		if (crutch_Flag) {
			{	BooleanVar crutch_Flag;
				/* this->isBoundedRight(me) && this->isBoundedRight(other) */
				
				crutch_Flag = this->isBoundedRight(me);
				if(crutch_Flag) {
					crutch_Flag = this->isBoundedRight(other);
				}
				if (crutch_Flag) {
					WPTR(XnRegion) 	returnValue;
					returnValue = this->makeNew(FALSE, CAST(PtrArray,PrimSpec::pointer()->arrayWithTwo(this->lowerEdge(me)->floor(this->lowerEdge(other)), this->upperEdge(me)->ceiling(this->upperEdge(other)))));
					return returnValue;
				} else {
					WPTR(XnRegion) 	returnValue;
					returnValue = this->makeNew(FALSE, CAST(PtrArray,PrimSpec::pointer()->arrayWith(this->lowerEdge(me)->floor(this->lowerEdge(other)))));
					return returnValue;
				}
			}
		} else {
			{	BooleanVar crutch_Flag;
				/* this->isBoundedRight(me) && this->isBoundedRight(other) */
				
				crutch_Flag = this->isBoundedRight(me);
				if(crutch_Flag) {
					crutch_Flag = this->isBoundedRight(other);
				}
				if (crutch_Flag) {
					WPTR(XnRegion) 	returnValue;
					returnValue = this->makeNew(TRUE, CAST(PtrArray,PrimSpec::pointer()->arrayWith(this->upperEdge(me)->ceiling(this->upperEdge(other)))));
					return returnValue;
				} else {
					WPTR(XnRegion) 	returnValue;
					returnValue = this->makeNew(TRUE, PtrArray::empty());
					return returnValue;
				}
			}
		}
	}
}
/* printing */


void EdgeManager::printRegionOn (APTR(XnRegion) region, ostream& oo){
	if (this->isEmpty(region)) {
		oo << "{}";
	} else {
		SPTR(EdgeStepper) edges;
		SPTR(TransitionEdge) previous;
		
		edges = this->edgeStepper(region);
		if (!this->isSimple(region)) {
			oo << "{";
		}
		if (!edges->isEntering()) {
			oo << "(-inf";
		}
		previous = NULL;
		BEGIN_FOR_EACH(TransitionEdge,edge,(edges)) {
			edge->printTransitionOn(oo, edges->isEntering(), previous != NULL && previous->touches(edge));
			previous = edge;
		} END_FOR_EACH;
		if (!this->isBoundedRight(region)) {
			oo << " +inf)";
		}
		if (!this->isSimple(region)) {
			oo << "}";
		}
	}
}
/* operations */


RPTR(XnRegion) EdgeManager::complement (APTR(XnRegion) region){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->makeNew(!this->startsInside(region), this->transitions(region), this->transitionsCount(region));
	return returnValue;
}


RPTR(ScruSet) OF1(XnRegion) EdgeManager::distinctions (APTR(XnRegion) region){
	SPTR(MuSet) result;
	
	if (!this->isSimple(region)) {
		BLAST(InvalidRequest);
	}
	if (this->isEmpty(region)) {
		WPTR(ScruSet) OF1(XnRegion) 	returnValue;
		returnValue = ImmuSet::make ()->with(region);
		return returnValue;
	}
	if (this->isFull(region)) {
		WPTR(ScruSet) OF1(XnRegion) 	returnValue;
		returnValue = ImmuSet::make ();
		return returnValue;
	}
	if (this->transitionsCount(region) == 1) {
		WPTR(ScruSet) OF1(XnRegion) 	returnValue;
		returnValue = ImmuSet::make ()->with(region);
		return returnValue;
	}
	result = MuSet::make ();
	result->store(this->makeNew(FALSE, CAST(PtrArray,PrimSpec::pointer()->arrayWith(this->lowerEdge(region)))));
	result->store(this->makeNew(TRUE, CAST(PtrArray,PrimSpec::pointer()->arrayWith(this->upperEdge(region)))));
	WPTR(ScruSet) OF1(XnRegion) 	returnValue;
	returnValue = result->asImmuSet();
	return returnValue;
}


RPTR(XnRegion) EdgeManager::intersect (APTR(XnRegion) meRegion, APTR(XnRegion) otherRegion){
	SPTR(EdgeStepper) mine;
	SPTR(EdgeStepper) others;
	SPTR(EdgeAccumulator) result;
	SPTR(XnRegion) resultReg;
	
	if (this->isEmpty(otherRegion)) {
		WPTR(XnRegion) 	returnValue;
		returnValue = otherRegion;
		return returnValue;
	}
	mine = this->edgeStepper(meRegion);
	others = this->edgeStepper(otherRegion);
	result = this->edgeAccumulator(this->startsInside(meRegion) && this->startsInside(otherRegion));
	for (;;) {	BooleanVar crutch_Flag;
		/* mine->hasValue() && others->hasValue() */
		
		crutch_Flag = mine->hasValue();
		if(crutch_Flag) {
			crutch_Flag = others->hasValue();
		}
		if (crutch_Flag) {
			SPTR(TransitionEdge) me;
			SPTR(TransitionEdge) other;
			
			me = mine->getEdge();
			other = others->getEdge();
			if (!me->isGE(other)) {
				if (!others->isEntering()) {
					result->edge(me);
				}
				mine->step();
			} else {
				if (!mine->isEntering()) {
					result->edge(other);
				}
				others->step();
			}
		} else {
			break;
		}
	}
	{	BooleanVar crutch_Flag;
		/* mine->hasValue() && !others->isEntering() */
		
		crutch_Flag = mine->hasValue();
		if(crutch_Flag) {
			crutch_Flag = !others->isEntering();
		}
		if (crutch_Flag) {
			result->edges(mine);
		}
	}
	{	BooleanVar crutch_Flag;
		/* others->hasValue() && !mine->isEntering() */
		
		crutch_Flag = others->hasValue();
		if(crutch_Flag) {
			crutch_Flag = !mine->isEntering();
		}
		if (crutch_Flag) {
			result->edges(others);
		}
	}
	{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
	{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
	resultReg = result->region();
	{result->destroy();  result = NULL /* don't want stale (S/CHK)PTRs */;}
	WPTR(XnRegion) 	returnValue;
	returnValue = resultReg;
	return returnValue;
}


RPTR(Stepper) EdgeManager::simpleRegions (APTR(XnRegion) region, APTR(OrderSpec) order/* = NULL*/){
	if (order != NULL) {
		BLAST(NOT_YET_IMPLEMENTED);
	}
	WPTR(Stepper) 	returnValue;
	returnValue = EdgeSimpleRegionStepper::make (this, this->edgeStepper(region));
	return returnValue;
}


RPTR(XnRegion) EdgeManager::unionWith (APTR(XnRegion) meRegion, APTR(XnRegion) otherRegion){
	SPTR(EdgeStepper) mine;
	SPTR(EdgeStepper) others;
	SPTR(EdgeAccumulator) result;
	SPTR(XnRegion) resultReg;
	
	if (this->isEmpty(otherRegion)) {
		WPTR(XnRegion) 	returnValue;
		returnValue = meRegion;
		return returnValue;
	}
	mine = this->edgeStepper(meRegion);
	others = this->edgeStepper(otherRegion);
	result = this->edgeAccumulator(this->startsInside(meRegion) || this->startsInside(otherRegion));
	for (;;) {	BooleanVar crutch_Flag;
		/* mine->hasValue() && others->hasValue() */
		
		crutch_Flag = mine->hasValue();
		if(crutch_Flag) {
			crutch_Flag = others->hasValue();
		}
		if (crutch_Flag) {
			SPTR(TransitionEdge) me;
			SPTR(TransitionEdge) other;
			
			me = mine->getEdge();
			other = others->getEdge();
			if (!me->isGE(other)) {
				if (others->isEntering()) {
					result->edge(me);
				}
				mine->step();
			} else {
				if (mine->isEntering()) {
					result->edge(other);
				}
				others->step();
			}
		} else {
			break;
		}
	}
	{	BooleanVar crutch_Flag;
		/* mine->hasValue() && others->isEntering() */
		
		crutch_Flag = mine->hasValue();
		if(crutch_Flag) {
			crutch_Flag = others->isEntering();
		}
		if (crutch_Flag) {
			result->edges(mine);
		}
	}
	{	BooleanVar crutch_Flag;
		/* others->hasValue() && mine->isEntering() */
		
		crutch_Flag = others->hasValue();
		if(crutch_Flag) {
			crutch_Flag = mine->isEntering();
		}
		if (crutch_Flag) {
			result->edges(others);
		}
	}
	{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
	{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
	resultReg = result->region();
	{result->destroy();  result = NULL /* don't want stale (S/CHK)PTRs */;}
	WPTR(XnRegion) 	returnValue;
	returnValue = resultReg;
	return returnValue;
}


RPTR(XnRegion) EdgeManager::with (APTR(XnRegion) meRegion, APTR(Position) newPos){
	SPTR(EdgeStepper) mine;
	SPTR(EdgeStepper) others;
	SPTR(EdgeAccumulator) result;
	SPTR(XnRegion) resultReg;
	
	mine = this->edgeStepper(meRegion);
	others = this->singleEdgeStepper(newPos);
	result = this->edgeAccumulator(this->startsInside(meRegion));
	for (;;) {	BooleanVar crutch_Flag;
		/* mine->hasValue() && others->hasValue() */
		
		crutch_Flag = mine->hasValue();
		if(crutch_Flag) {
			crutch_Flag = others->hasValue();
		}
		if (crutch_Flag) {
			SPTR(TransitionEdge) me;
			SPTR(TransitionEdge) other;
			
			me = mine->getEdge();
			other = others->getEdge();
			if (!me->isGE(other)) {
				if (others->isEntering()) {
					result->edge(me);
				}
				mine->step();
			} else {
				if (mine->isEntering()) {
					result->edge(other);
				}
				others->step();
			}
		} else {
			break;
		}
	}
	{	BooleanVar crutch_Flag;
		/* mine->hasValue() && others->isEntering() */
		
		crutch_Flag = mine->hasValue();
		if(crutch_Flag) {
			crutch_Flag = others->isEntering();
		}
		if (crutch_Flag) {
			result->edges(mine);
		}
	}
	{	BooleanVar crutch_Flag;
		/* others->hasValue() && mine->isEntering() */
		
		crutch_Flag = others->hasValue();
		if(crutch_Flag) {
			crutch_Flag = mine->isEntering();
		}
		if (crutch_Flag) {
			result->edges(others);
		}
	}
	{mine->destroy();  mine = NULL /* don't want stale (S/CHK)PTRs */;}
	{others->destroy();  others = NULL /* don't want stale (S/CHK)PTRs */;}
	resultReg = result->region();
	{result->destroy();  result = NULL /* don't want stale (S/CHK)PTRs */;}
	WPTR(XnRegion) 	returnValue;
	returnValue = resultReg;
	return returnValue;
}
/* protected: */

	/* automatic 0-argument constructor */
EdgeManager::EdgeManager() {}



/* ************************************************************************ *
 * 
 *                    Class TransitionEdge 
 *
 * ************************************************************************ */


/* Clients of EdgeManager define concrete subclasses of this, which 
are then used by the EdgeManager code */


/* accessing */


RPTR(TransitionEdge) TransitionEdge::ceiling (APTR(TransitionEdge) other){
	if (other->isGE(this)) {
		WPTR(TransitionEdge) 	returnValue;
		returnValue = other;
		return returnValue;
	} else {
		return this;
	}
}


RPTR(TransitionEdge) TransitionEdge::floor (APTR(TransitionEdge) other){
	if (this->isGE(other)) {
		WPTR(TransitionEdge) 	returnValue;
		returnValue = other;
		return returnValue;
	} else {
		return this;
	}
}
/* testing */


UInt32 TransitionEdge::actualHashForEqual (){
	return Heaper::takeOop();
}
/* printing */

	/* automatic 0-argument constructor */
TransitionEdge::TransitionEdge() {}



/* ************************************************************************ *
 * 
 *                    Class EdgeAccumulator 
 *
 * ************************************************************************ */



/* Initializers for EdgeAccumulator */

GPTR(InstanceCache) EdgeAccumulator::SomeAccumulators = NULL;



BEGIN_INIT_TIME(EdgeAccumulator,initTimeNonInherited) {
	EdgeAccumulator::SomeAccumulators = InstanceCache::make (8);
} END_INIT_TIME(EdgeAccumulator,initTimeNonInherited);



/* Initializers for EdgeAccumulator */






/* create */


RPTR(EdgeAccumulator) EdgeAccumulator::make (APTR(EdgeManager) manager, BooleanVar startsInside){
	SPTR(Heaper) result;
	
	result = EdgeAccumulator::SomeAccumulators->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(EdgeAccumulator,(manager, startsInside));
	} else {
		WPTR(EdgeAccumulator) 	returnValue;
		returnValue = new (result) EdgeAccumulator(manager, startsInside);
		return returnValue;
	}
}
/* protected: create */


EdgeAccumulator::EdgeAccumulator (APTR(EdgeManager) manager, BooleanVar startsInside) {
	myManager = manager;
	myStartsInside = startsInside;
	myEdges = PtrArray::nulls(4);
	myIndex = -1;
	myPending = NULL;
	myResultGiven = FALSE;
}


EdgeAccumulator::EdgeAccumulator (
		APTR(EdgeManager) manager, 
		BooleanVar startsInside, 
		APTR(PtrArray) OF1(TransitionEdge) edges, 
		Int32 index, 
		APTR(TransitionEdge) pending) 
{
	myManager = manager;
	myStartsInside = startsInside;
	myEdges = edges;
	myIndex = index;
	myPending = pending;
	myResultGiven = FALSE;
}
/* creation */


RPTR(Accumulator) EdgeAccumulator::copy (){
	SPTR(Heaper) result;
	
	result = EdgeAccumulator::SomeAccumulators->fetch();
	myResultGiven = TRUE;
	if (result == NULL) {
		RETURN_CONSTRUCT(EdgeAccumulator,(myManager, myStartsInside, myEdges, myIndex, myPending));
	} else {
		WPTR(Accumulator) 	returnValue;
		returnValue = new (result) EdgeAccumulator(myManager, myStartsInside, myEdges, myIndex, myPending);
		return returnValue;
	}
}


void EdgeAccumulator::destroy (){
	if (!EdgeAccumulator::SomeAccumulators->store(this)) {
		this->Accumulator::destroy();
	}
}
/* operations */


void EdgeAccumulator::step (APTR(Heaper) someObj){
	this->edge(CAST(TransitionEdge,someObj));
}


RPTR(Heaper) EdgeAccumulator::value (){
	WPTR(Heaper) 	returnValue;
	returnValue = this->region();
	return returnValue;
}
/* edge operations */


void EdgeAccumulator::edge (APTR(TransitionEdge) x){
	/* add a transition at the given position. doing it again cancels it */
	
	if (myPending == NULL) {
		myPending = x;
	} else {
		if (myPending->isEqual(x)) {
			myPending = NULL;
		} else {
			this->storeStep(myPending);
			myPending = x;
		}
	}
}


void EdgeAccumulator::edges (APTR(EdgeStepper) stepper){
	/* add a whole bunch of edges at once, assuming that they are 
	sorted and there are no duplicates */
	/* do the first step manually in case it is the same as the 
	current edge
		then do all the rest without checking for repeats */
	
	if (stepper->hasValue()) {
		SPTR(TransitionEdge) edge;
		
		this->edge(stepper->fetchEdge());
		stepper->step();
		while ((edge = CAST(TransitionEdge,stepper->fetch())) != NULL) {
			if (myPending != NULL) {
				this->storeStep(myPending);
			}
			myPending = edge;
			stepper->step();
		}
	}
}


RPTR(XnRegion) EdgeAccumulator::region (){
	/* make a region out of the accumulated edges */
	
	if (myPending != NULL) {
		this->storeStep(myPending);
		myPending = NULL;
	}
	myResultGiven = TRUE;
	WPTR(XnRegion) 	returnValue;
	returnValue = myManager->makeNew(myStartsInside, myEdges, myIndex + 1);
	return returnValue;
}
/* private: */


void EdgeAccumulator::storeStep (APTR(TransitionEdge) edge){
	/* Just store an edge into the array and increment the count */
	
	myIndex += 1;
	if (myIndex == myEdges->count()) {
		myEdges = CAST(PtrArray,myEdges->copyGrow(myEdges->count()));
		myResultGiven = FALSE;
	} else {
		if (myResultGiven) {
			myEdges = CAST(PtrArray,myEdges->copy());
			myResultGiven = FALSE;
		}
	}
	myEdges->store(myIndex, edge);
}
/* hooks: */


void EdgeAccumulator::restartEdgeAccumulator (APTR(Rcvr) /* rcvr */){
	myResultGiven = FALSE;
}



/* ************************************************************************ *
 * 
 *                    Class EdgeSimpleRegionStepper 
 *
 * ************************************************************************ */


/* create */


RPTR(EdgeSimpleRegionStepper) EdgeSimpleRegionStepper::make (APTR(EdgeManager) manager, APTR(EdgeStepper) edges){
	RETURN_CONSTRUCT(EdgeSimpleRegionStepper,(manager, edges));
}
/* Consider this a "protected" class.  See class comment in EdgeAccumulator */


/* accessing */


WPTR(Heaper) EdgeSimpleRegionStepper::fetch (){
	return (XnRegion*) mySimple;
}


BooleanVar EdgeSimpleRegionStepper::hasValue (){
	return mySimple != NULL;
}


void EdgeSimpleRegionStepper::step (){
	BooleanVar startsInside;
	SPTR(TransitionEdge) one;
	SPTR(TransitionEdge) two;
	
	/* if there are no more edges
			then the stepper is empty
			
		remember whether we're entering or leaving the region
		fetch the first edge
		if there is no first edge
			then remember the edges are gone
			if we were already in the region
				then there is the full region
				else we're empty
		else there is a first edge, so
			if we start outside and there is another edge
				then get it and make a two-sided region
				else make a one-side region */
	if (myEdges == NULL) {
		mySimple = NULL;
		return;
		
	}
	startsInside = !myEdges->isEntering();
	one = myEdges->fetchEdge();
	if (one == NULL) {
		myEdges = NULL;
		{	BooleanVar crutch_Flag;
			/* startsInside && mySimple == NULL */
			
			crutch_Flag = startsInside;
			if(crutch_Flag) {
				crutch_Flag = mySimple == NULL;
			}
			if (crutch_Flag) {
				mySimple = myManager->makeNew(TRUE, PtrArray::empty());
			} else {
				mySimple = NULL;
			}
		}
	} else {
		myEdges->step();
		{	BooleanVar crutch_Flag;
			/* !startsInside && myEdges->hasValue() */
			
			crutch_Flag = !startsInside;
			if(crutch_Flag) {
				crutch_Flag = myEdges->hasValue();
			}
			if (crutch_Flag) {
				two = myEdges->fetchEdge();
				myEdges->step();
				mySimple = myManager->makeNew(startsInside, CAST(PtrArray,PrimSpec::pointer()->arrayWithTwo(one, two)));
			} else {
				mySimple = myManager->makeNew(startsInside, CAST(PtrArray,PrimSpec::pointer()->arrayWith(one)));
			}
		}
	}
}
/* create */


RPTR(Stepper) EdgeSimpleRegionStepper::copy (){
	SPTR(EdgeStepper) step;
	
	/* can't to ?: with SPTRs */
	step = myEdges;
	if (step != NULL) {
		step = CAST(EdgeStepper,myEdges->copy());
	}
	RETURN_CONSTRUCT(EdgeSimpleRegionStepper,(myManager, step, mySimple));
}
/* protected: create */


EdgeSimpleRegionStepper::EdgeSimpleRegionStepper (APTR(EdgeManager) manager, APTR(EdgeStepper) edges) {
	myManager = manager;
	myEdges = edges;
	mySimple = NULL;
	this->step();
}


EdgeSimpleRegionStepper::EdgeSimpleRegionStepper (
		APTR(EdgeManager) manager, 
		APTR(EdgeStepper) OR(NULL) edges, 
		APTR(XnRegion) OR(NULL) simple) 
{
	myManager = manager;
	myEdges = edges;
	mySimple = simple;
}



/* ************************************************************************ *
 * 
 *                    Class EdgeStepper 
 *
 * ************************************************************************ */



/* Initializers for EdgeStepper */

GPTR(InstanceCache) EdgeStepper::SomeEdgeSteppers = NULL;



BEGIN_INIT_TIME(EdgeStepper,initTimeNonInherited) {
	EdgeStepper::SomeEdgeSteppers = InstanceCache::make (16);
} END_INIT_TIME(EdgeStepper,initTimeNonInherited);



/* Initializers for EdgeStepper */






/* create */


RPTR(EdgeStepper) EdgeStepper::make (BooleanVar entering, APTR(PtrArray) OF1(TransitionEdge) edges){
	SPTR(Heaper) result;
	
	result = EdgeStepper::SomeEdgeSteppers->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(EdgeStepper,(entering, edges, edges->count()));
	} else {
		WPTR(EdgeStepper) 	returnValue;
		returnValue = new (result) EdgeStepper(entering, edges, edges->count());
		return returnValue;
	}
}


RPTR(EdgeStepper) EdgeStepper::make (
		BooleanVar entering, 
		APTR(PtrArray) OF1(TransitionEdge) edges, 
		Int32 count)
{
	SPTR(Heaper) result;
	
	result = EdgeStepper::SomeEdgeSteppers->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(EdgeStepper,(entering, edges, count));
	} else {
		WPTR(EdgeStepper) 	returnValue;
		returnValue = new (result) EdgeStepper(entering, edges, count);
		return returnValue;
	}
}
/* A single instance of this class is cached.  To take advantage of 
this, a method
that uses EdgeSteppers should explicitly destroy at least one of them.
Consider this a "protected" class.  See class comment in EdgeAccumulator. */


/* accessing */


WPTR(Heaper) EdgeStepper::fetch (){
	if (myIndex < myEdgesCount) {
		WPTR(Heaper) 	returnValue;
		returnValue = myEdges->fetch(myIndex);
		return returnValue;
	} else {
		return NULL;
	}
}


BooleanVar EdgeStepper::hasValue (){
	return myIndex < myEdgesCount;
}


void EdgeStepper::step (){
	if (this->hasValue()) {
		myEntering = !myEntering;
		myIndex += 1;
	}
}
/* edge accessing */


RPTR(TransitionEdge) OR(NULL) EdgeStepper::fetchEdge (){
	if (myIndex < myEdgesCount) {
		return CAST(TransitionEdge,myEdges->fetch(myIndex));
	} else {
		return NULL;
	}
}


RPTR(TransitionEdge) EdgeStepper::getEdge (){
	if (myIndex < myEdgesCount) {
		return CAST(TransitionEdge,myEdges->fetch(myIndex));
	} else {
		BLAST(EmptyStepper);
	}
	/* fodder */
	return NULL;
}


BooleanVar EdgeStepper::isEntering (){
	/* whether the current transition is entering or leaving the set */
	
	return myEntering;
}
/* protected: create */


EdgeStepper::EdgeStepper (
		BooleanVar entering, 
		APTR(PtrArray) OF1(TransitionEdge) edges, 
		Int32 count) 
{
	myEntering = entering;
	myEdges = edges;
	myEdgesCount = count;
	myIndex = Int32Zero;
}


EdgeStepper::EdgeStepper (
		BooleanVar entering, 
		APTR(PtrArray) OF1(TransitionEdge) edges, 
		Int32 count, 
		Int32 index) 
{
	myEntering = entering;
	myEdges = edges;
	myEdgesCount = count;
	myIndex = index;
}
/* create */


RPTR(Stepper) EdgeStepper::copy (){
	RETURN_CONSTRUCT(EdgeStepper,(myEntering, myEdges, myEdgesCount, myIndex));
}
/* destroy */


void EdgeStepper::destroy (){
	if (!EdgeStepper::SomeEdgeSteppers->store(this)) {
		this->Stepper::destroy();
	}
}

#ifndef EDGER_SXX
#include "edger.sxx"
#endif /* EDGER_SXX */


#ifndef EDGEP_SXX
#include "edgep.sxx"
#endif /* EDGEP_SXX */



#endif /* EDGEX_CXX */

