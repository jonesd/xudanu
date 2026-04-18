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

#ifndef FILTERX_CXX
#define FILTERX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef FILTERX_HXX
#include "filterx.hxx"
#endif /* FILTERX_HXX */

#ifndef FILTERX_IXX
#include "filterx.ixx"
#endif /* FILTERX_IXX */

#ifndef FILTERP_HXX
#include "filterp.hxx"
#endif /* FILTERP_HXX */

#ifndef FILTERP_IXX
#include "filterp.ixx"
#endif /* FILTERP_IXX */


#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */

#ifndef TABLESX_HXX
#include "tablesx.hxx"
#endif /* TABLESX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */




/* ************************************************************************ *
 * 
 *                    Class Filter 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(Filter) Filter::andFilter (APTR(CoordinateSpace) cs, APTR(ScruSet) OF1(Filter) subs){
	/* A filter that matches only regions that all of the filters 
	in the set would have matched. */
	
	SPTR(ImmuSet) result;
	
	result = ImmuSet::make ();
	BEGIN_FOR_EACH(Filter,sub,(subs->stepper())) {
		BEGIN_CHOOSE(sub) {
			BEGIN_KIND(ClosedFilter,cSub) {
				WPTR(Filter) 	returnValue;
				returnValue = Filter::closedFilter(cs);
				return returnValue;
			} END_KIND;
			BEGIN_KIND(AndFilter,aSub) {
				result = Filter::combineIntersect(result, aSub->subFilters());
			} END_KIND;
			BEGIN_KIND(OpenFilter,oSub) {
				
			} END_KIND;
			BEGIN_OTHERS {
				result = Filter::combineIntersect(result, sub);
			} END_OTHERS;
		} END_CHOOSE;
	} END_FOR_EACH;
	WPTR(Filter) 	returnValue;
	returnValue = Filter::andFilterPrivate(CAST(FilterSpace,cs), result);
	return returnValue;
}


RPTR(Filter) Filter::closedFilter (APTR(CoordinateSpace) cs){
	/* An filter that does match any region. */
	
	RETURN_CONSTRUCT(ClosedFilter,(CAST(FilterSpace,cs), tcsj));
}


RPTR(Filter) Filter::intersectionFilter (APTR(CoordinateSpace) cs, APTR(XnRegion) region){
	/* A filter that matches any region that intersects the given 
	region. */
	
	RETURN_CONSTRUCT(NotSubsetFilter,(CAST(FilterSpace,cs), region->complement()));
}


RPTR(Filter) Filter::notSubsetFilter (APTR(CoordinateSpace) cs, APTR(XnRegion) region){
	/* A filter matching any regions that is not a subset of the 
	given region. */
	
	if (region->isFull()) {
		WPTR(Filter) 	returnValue;
		returnValue = Filter::closedFilter(cs);
		return returnValue;
	}
	RETURN_CONSTRUCT(NotSubsetFilter,(CAST(FilterSpace,cs), region));
}


RPTR(Filter) Filter::notSupersetFilter (APTR(CoordinateSpace) cs, APTR(XnRegion) region){
	/* A filter that matches any region that is not a superset of 
	the given region. */
	
	if (region->isEmpty()) {
		WPTR(Filter) 	returnValue;
		returnValue = Filter::closedFilter(cs);
		return returnValue;
	}
	RETURN_CONSTRUCT(NotSupersetFilter,(CAST(FilterSpace,cs), region));
}


RPTR(Filter) Filter::openFilter (APTR(CoordinateSpace) cs){
	/* A filter that matches any region. */
	
	RETURN_CONSTRUCT(OpenFilter,(CAST(FilterSpace,cs), tcsj));
}


RPTR(Filter) Filter::orFilter (APTR(CoordinateSpace) cs, APTR(ScruSet) OF1(Filter) subs){
	/* A filter that matches any region that any of the filters 
	in the set would have matched. */
	
	SPTR(ImmuSet) OF1(Filter) result;
	
	result = ImmuSet::make ();
	BEGIN_FOR_EACH(Filter,sub,(subs->stepper())) {
		BEGIN_CHOOSE(sub) {
			BEGIN_KIND(OpenFilter,oSub) {
				WPTR(Filter) 	returnValue;
				returnValue = Filter::openFilter(cs);
				return returnValue;
			} END_KIND;
			BEGIN_KIND(OrFilter,orSub) {
				result = Filter::combineUnion(result, orSub->subFilters());
			} END_KIND;
			BEGIN_KIND(ClosedFilter,cSub) {
				
			} END_KIND;
			BEGIN_OTHERS {
				result = Filter::combineUnion(result, sub);
			} END_OTHERS;
		} END_CHOOSE;
	} END_FOR_EACH;
	WPTR(Filter) 	returnValue;
	returnValue = Filter::orFilterPrivate(CAST(FilterSpace,cs), result);
	return returnValue;
}


RPTR(Filter) Filter::subsetFilter (APTR(CoordinateSpace) cs, APTR(XnRegion) region){
	/* A filter that matches any region that is a subset of the 
	given region. */
	
	if (region->isFull()) {
		WPTR(Filter) 	returnValue;
		returnValue = Filter::openFilter(cs);
		return returnValue;
	}
	RETURN_CONSTRUCT(SubsetFilter,(CAST(FilterSpace,cs), region));
}


RPTR(Filter) Filter::supersetFilter (APTR(CoordinateSpace) cs, APTR(XnRegion) region){
	/* A region that matches any region that is a superset of the 
	given region. */
	
	if (region->isEmpty()) {
		WPTR(Filter) 	returnValue;
		returnValue = Filter::openFilter(cs);
		return returnValue;
	}
	RETURN_CONSTRUCT(SupersetFilter,(CAST(FilterSpace,cs), region));
}
/* private: functions */


RPTR(Filter) Filter::andFilterPrivate (APTR(FilterSpace) cs, APTR(ImmuSet) OF1(Filter) subs){
	/* assumes that the interactions between elements have 
	already been removed */
	
	if (subs->isEmpty()) {
		WPTR(Filter) 	returnValue;
		returnValue = Filter::openFilter(cs);
		return returnValue;
	}
	if (subs->count() == 1) {
		return CAST(Filter,subs->theOne());
	}
	RETURN_CONSTRUCT(AndFilter,(cs, subs));
}


RPTR(ImmuSet) OF1(Filter) Filter::combineIntersect (APTR(ImmuSet) OF1(Filter) set, APTR(Filter) filter){
	/* keep going around doing intersections until there are no 
	more special intersects */
	
	SPTR(Stepper) subs;
	SPTR(MuSet) OF1(Filter) nonspecial;
	SPTR(SetAccumulator) result;
	SPTR(Filter) test;
	
	result = SetAccumulator::make ();
	test = filter;
	subs = set->stepper();
	nonspecial = set->asMuSet();
	while (subs->hasValue()) {
		SPTR(Filter) special;
		SPTR(Filter) sub;
		
		sub = CAST(Filter,subs->fetch());
		subs->step();
		special = CAST(Filter,sub->fetchIntersect(test));
		if (special != NULL) {
			test = special;
			result = SetAccumulator::make ();
			nonspecial->remove(sub);
			subs = nonspecial->stepper();
		} else {
			SPTR(Pair) OF1(Filter) canon;
			
			canon = sub->fetchPairIntersect(test);
			if (canon == NULL) {
				result->step(sub);
			} else {
				test = CAST(Filter,canon->right());
				nonspecial->remove(sub);
				result = SetAccumulator::make ();
				nonspecial = Filter::combineIntersect(nonspecial->asImmuSet(), CAST(Filter,canon->left()))->asMuSet();
				subs = nonspecial->stepper();
			}
		}
	}
	WPTR(ImmuSet) OF1(Filter) 	returnValue;
	returnValue = CAST(ImmuSet,result->value())->with(test);
	return returnValue;
}


RPTR(ImmuSet) OF1(Filter) Filter::combineIntersect (APTR(ImmuSet) OF1(Filter) a, APTR(ImmuSet) OF1(Filter) b){
	SPTR(ImmuSet) OF1(Filter) result;
	
	result = a;
	BEGIN_FOR_EACH(Filter,sub,(b->stepper())) {
		result = Filter::combineIntersect(result, sub);
	} END_FOR_EACH;
	WPTR(ImmuSet) OF1(Filter) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(ImmuSet) OF1(Filter) Filter::combineUnion (APTR(ImmuSet) OF1(Filter) set, APTR(Filter) filter){
	/* keep going around doing unions until there are no more 
	special unions */
	
	SPTR(Stepper) subs;
	SPTR(MuSet) OF1(Filter) nonspecial;
	SPTR(SetAccumulator) result;
	SPTR(Filter) test;
	
	result = SetAccumulator::make ();
	test = filter;
	subs = set->stepper();
	nonspecial = set->asMuSet();
	while (subs->hasValue()) {
		SPTR(Filter) special;
		SPTR(Filter) sub;
		
		sub = CAST(Filter,subs->fetch());
		subs->step();
		special = CAST(Filter,sub->fetchUnion(test));
		if (special != NULL) {
			test = special;
			result = SetAccumulator::make ();
			nonspecial->remove(sub);
			subs = nonspecial->stepper();
		} else {
			SPTR(Pair) OF1(Filter) canon;
			
			canon = sub->fetchPairUnion(test);
			if (canon == NULL) {
				result->step(sub);
			} else {
				test = CAST(Filter,canon->right());
				nonspecial->remove(sub);
				result = SetAccumulator::make ();
				nonspecial = Filter::combineUnion(nonspecial->asImmuSet(), CAST(Filter,canon->left()))->asMuSet();
				subs = nonspecial->stepper();
			}
		}
	}
	WPTR(ImmuSet) OF1(Filter) 	returnValue;
	returnValue = CAST(ImmuSet,result->value())->with(test);
	return returnValue;
}


RPTR(ImmuSet) OF1(Filter) Filter::combineUnion (APTR(ImmuSet) OF1(Filter) a, APTR(ImmuSet) OF1(Filter) b){
	SPTR(ImmuSet) OF1(Filter) result;
	
	result = a;
	BEGIN_FOR_EACH(Filter,sub,(b->stepper())) {
		result = Filter::combineUnion(result, sub);
	} END_FOR_EACH;
	WPTR(ImmuSet) OF1(Filter) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(ImmuSet) OF1(Filter) Filter::distributeIntersect (
		APTR(CoordinateSpace) cs, 
		APTR(ImmuSet) OF1(Filter) set, 
		APTR(Filter) filter)
{
	/* distribute the intersection of a filter with the union of 
	a set of filters */
	
	SPTR(Filter) special;
	SPTR(SetAccumulator) OF1(Filter) nonspecial;
	
	special = Filter::closedFilter(cs);
	nonspecial = SetAccumulator::make ();
	BEGIN_FOR_EACH(Filter,sub,(set->stepper())) {
		SPTR(XnRegion) quick;
		
		quick = sub->fetchIntersect(filter);
		if (quick == NULL) {
			nonspecial->step(sub->complexIntersect(filter));
		} else {
			special = CAST(Filter,special->unionWith(quick));
		}
	} END_FOR_EACH;
	if (CAST(ImmuSet,nonspecial->value())->isEmpty()) {
		WPTR(ImmuSet) OF1(Filter) 	returnValue;
		returnValue = ImmuSet::make ()->with(special);
		return returnValue;
	} else {
		WPTR(ImmuSet) OF1(Filter) 	returnValue;
		returnValue = CAST(ImmuSet,nonspecial->value())->with(special);
		return returnValue;
	}
}


RPTR(ImmuSet) OF1(Filter) Filter::distributeIntersect (
		APTR(CoordinateSpace) cs, 
		APTR(ImmuSet) OF1(Filter) a, 
		APTR(ImmuSet) OF1(Filter) b)
{
	/* distribute the intersection of two unions of sets of filters */
	
	SPTR(Filter) special;
	SPTR(ImmuSet) OF1(Filter) nonspecial;
	
	special = Filter::closedFilter(cs);
	nonspecial = ImmuSet::make ();
	BEGIN_FOR_EACH(Filter,other,(a->stepper())) {
		BEGIN_FOR_EACH(Filter,sub,(b->stepper())) {
			SPTR(XnRegion) intersection;
			
			intersection = sub->fetchIntersect(other);
			if (intersection == NULL) {
				nonspecial = Filter::combineUnion(nonspecial, CAST(Filter,sub->complexIntersect(other)));
			} else {
				special = CAST(Filter,special->unionWith(intersection));
			}
		} END_FOR_EACH;
	} END_FOR_EACH;
	WPTR(ImmuSet) OF1(Filter) 	returnValue;
	returnValue = Filter::combineUnion(nonspecial, special);
	return returnValue;
}


RPTR(ImmuSet) OF1(Filter) Filter::distributeUnion (
		APTR(CoordinateSpace) cs, 
		APTR(ImmuSet) OF1(Filter) set, 
		APTR(Filter) filter)
{
	/* distribute the union of a filter with the intersection of 
	a set of filters */
	
	SPTR(Filter) special;
	SPTR(ImmuSet) OF1(Filter) nonspecial;
	
	special = Filter::openFilter(cs);
	nonspecial = ImmuSet::make ();
	BEGIN_FOR_EACH(Filter,sub,(set->stepper())) {
		SPTR(XnRegion) quick;
		
		quick = sub->fetchUnion(filter);
		if (quick == NULL) {
			nonspecial = Filter::combineIntersect(nonspecial, sub);
		} else {
			special = CAST(Filter,special->intersect(quick));
		}
	} END_FOR_EACH;
	if (nonspecial->isEmpty()) {
		WPTR(ImmuSet) OF1(Filter) 	returnValue;
		returnValue = ImmuSet::make ()->with(special);
		return returnValue;
	} else {
		WPTR(ImmuSet) OF1(Filter) 	returnValue;
		returnValue = ImmuSet::make ()->with(Filter::andFilterPrivate(CAST(FilterSpace,cs), Filter::combineIntersect(nonspecial, special)))->with(filter);
		return returnValue;
	}
}


RPTR(ImmuSet) OF1(Filter) Filter::distributeUnion (
		APTR(CoordinateSpace) cs, 
		APTR(ImmuSet) OF1(Filter) anded, 
		APTR(ImmuSet) OF1(Filter) ored)
{
	/* distribute the union of an intersection and a union of 
	sets of filters */
	
	SPTR(Filter) distributed;
	
	distributed = CAST(Filter,ored->theOne());
	WPTR(ImmuSet) OF1(Filter) 	returnValue;
	returnValue = Filter::combineUnion(
			Filter::distributeUnion(cs, anded, distributed), ored->without(distributed));
	return returnValue;
}


RPTR(Filter) Filter::orFilterPrivate (APTR(FilterSpace) cs, APTR(ImmuSet) OF1(Filter) subs){
	/* assumes that the interactions between elements have 
	already been removed */
	
	if (subs->isEmpty()) {
		WPTR(Filter) 	returnValue;
		returnValue = Filter::closedFilter(cs);
		return returnValue;
	}
	if (subs->count() == 1) {
		return CAST(Filter,subs->theOne());
	}
	RETURN_CONSTRUCT(OrFilter,(cs, subs));
}
/* A position in a FilterSpace is a region in the baseSpace, and a 
filter is a set of regions in the baseSpace. It is often more useful 
to think of a Filter as a Boolean function whose input is a region in 
the baseSpace, and of unions, intersections, and complements of 
filters as ORs, ANDs, and NOTs of functions. Not all possible such 
functions can be represented as Filters, since there is an 
uncountable infinity of them for any non-finite CoordinateSpace. 
There are representations for some basic filters, and any filters 
resulting from a finite sequence of unions, intersections, and 
complements among them. The basic filters are:
	subsetFilter(cs,R) -- all subsets of R (i.e. all R1 such that 
R1->isSubsetOf(R))
	supersetFilter(cs,R) -- all supersets of R (i.e. all R1 such that 
R->isSubsetOf(R1))
Mathematically, this is all that is necessary, since other useful 
filters like intersection filters can be generated from these. (e.g. 
intersectionFilter(R) is subsetFilter(R->complement())->complement()).
 However, there are several more pseudo constructors provided as 
shortcuts, including intersectionFilters, closedFilters, 
emptyFilters, and intersections and unions of sets of filters. */


/* operations */


RPTR(XnRegion) Filter::intersect (APTR(XnRegion) other){
	SPTR(XnRegion) result;
	
	result = this->fetchIntersect(other);
	if (result != NULL) {
		WPTR(XnRegion) 	returnValue;
		returnValue = result;
		return returnValue;
	}
	WPTR(XnRegion) 	returnValue;
	returnValue = this->complexIntersect(other);
	return returnValue;
}


RPTR(XnRegion) Filter::unionWith (APTR(XnRegion) other){
	SPTR(XnRegion) result;
	
	result = this->fetchUnion(other);
	if (result != NULL) {
		WPTR(XnRegion) 	returnValue;
		returnValue = result;
		return returnValue;
	}
	WPTR(XnRegion) 	returnValue;
	returnValue = this->complexUnion(other);
	return returnValue;
}
/* testing */


UInt32 Filter::actualHashForEqual (){
	return Heaper::takeOop();
}


BooleanVar Filter::hasMember (APTR(Position) pos){
	return this->match(CAST(FilterPosition,pos)->baseRegion());
}


BooleanVar Filter::isEnumerable (APTR(OrderSpec) order/* = NULL*/){
	/* Known bug !!!! */
	
	/* The singleton region should act enumerably */
	return FALSE;
}


BooleanVar Filter::isSubsetOf (APTR(XnRegion) other){
	SPTR(Filter) o;
	
	o = CAST(Filter,other);
	if (this->fetchSpecialSubset(o) == this) {
		return TRUE;
	}
	if (o->fetchSpecialSubset(this) == this) {
		return TRUE;
	}
	return !this->intersects(o->complement());
}
/* enumerating */


IntegerVar Filter::count (){
	BLAST(NOT_YET_IMPLEMENTED);
	return IntegerVar0;
}
/* accessing */
/* filtering */


BooleanVar Filter::doesPass (APTR(Joint) joint){
	/* Whether there might be anything in the tree beneath the 
	Joint that would pass the filter. */
	
	return !this->pass(joint)->isEmpty();
}


BooleanVar Filter::isSwitchedBy (APTR(RegionDelta) delta){
	/* Whether the change causes a change in the state of the 
	filter. (I.E. Whether the old region was in and the new out, 
	or vice versa.) */
	
	return this->match(delta->before()) != this->match(delta->after());
}


BooleanVar Filter::isSwitchedOffBy (APTR(RegionDelta) delta){
	/* Whether the change switches the state of the filter from 
	on to off. (I.E. Whether the old region was inside the filter 
	and the new region outside.) */
	
	{	BooleanVar crutch_Flag;
		/* this->match(delta->before()) && !this->match(delta->after()) */
		
		crutch_Flag = this->match(delta->before());
		if(crutch_Flag) {
			crutch_Flag = !this->match(delta->after());
		}
		return crutch_Flag;
	}
}


BooleanVar Filter::isSwitchedOnBy (APTR(RegionDelta) delta){
	/* Whether the change switches the state of the filter from 
	off to on. (I.E. Whether the old region was outside the 
	filter and the new region inside.) */
	
	{	BooleanVar crutch_Flag;
		/* !this->match(delta->before()) && this->match(delta->after()) */
		
		crutch_Flag = !this->match(delta->before());
		if(crutch_Flag) {
			crutch_Flag = this->match(delta->after());
		}
		return crutch_Flag;
	}
}
/* creation */


Filter::Filter (APTR(FilterSpace) cs, TCSJ) {
	myCS = cs;
}
/* components */


RPTR(ScruSet) OF1(XnRegion) Filter::distinctions (){
	if (this->isFull()) {
		WPTR(ScruSet) OF1(XnRegion) 	returnValue;
		returnValue = ImmuSet::make ();
		return returnValue;
	} else {
		WPTR(ScruSet) OF1(XnRegion) 	returnValue;
		returnValue = ImmuSet::make ()->with(this);
		return returnValue;
	}
}


RPTR(Stepper) Filter::simpleRegions (APTR(OrderSpec) /* order *//* = NULL*/){
	if (this->isEmpty()) {
		WPTR(Stepper) 	returnValue;
		returnValue = ImmuSet::make ()->stepper();
		return returnValue;
	} else {
		WPTR(Stepper) 	returnValue;
		returnValue = ImmuSet::make ()->with(this)->stepper();
		return returnValue;
	}
}
/* vulnerable: internal */


RPTR(XnRegion) Filter::complexIntersect (APTR(XnRegion) other){
	SPTR(Filter) a;
	SPTR(Filter) b;
	SPTR(Pair) OF1(Filter) canon;
	
	if (this->isKindOf(cat_OrFilter)) {
		a = this;
		b = CAST(Filter,other);
	} else {
		b = this;
		a = CAST(Filter,other);
	}
	if (a->isKindOf(cat_OrFilter)) {
		if (b->isKindOf(cat_OrFilter)) {
			WPTR(XnRegion) 	returnValue;
			returnValue = Filter::orFilterPrivate(myCS, 
					Filter::distributeIntersect(this->coordinateSpace(), CAST(OrFilter,a)->subFilters(), CAST(OrFilter,b)->subFilters()));
			return returnValue;
		} else {
			WPTR(XnRegion) 	returnValue;
			returnValue = Filter::orFilterPrivate(myCS, 
					Filter::distributeIntersect(this->coordinateSpace(), CAST(OrFilter,a)->subFilters(), b));
			return returnValue;
		}
	}
	if (!a->isKindOf(cat_AndFilter)) {
		SPTR(Filter) t;
		
		t = a;
		a = b;
		b = t;
	}
	if (a->isKindOf(cat_AndFilter)) {
		if (b->isKindOf(cat_AndFilter)) {
			WPTR(XnRegion) 	returnValue;
			returnValue = Filter::andFilterPrivate(myCS, Filter::combineIntersect(CAST(AndFilter,a)->subFilters(), CAST(AndFilter,b)->subFilters()));
			return returnValue;
		}
		WPTR(XnRegion) 	returnValue;
		returnValue = Filter::andFilterPrivate(myCS, Filter::combineIntersect(CAST(AndFilter,a)->subFilters(), b));
		return returnValue;
	}
	canon = this->getPairIntersect(CAST(Filter,other));
	WPTR(XnRegion) 	returnValue;
	returnValue = Filter::andFilterPrivate(myCS, ImmuSet::make ()->with(canon->left())->with(canon->right()));
	return returnValue;
}


RPTR(XnRegion) Filter::complexUnion (APTR(XnRegion) other){
	SPTR(Filter) a;
	SPTR(Filter) b;
	SPTR(Pair) OF1(Filter) canon;
	
	if (this->isKindOf(cat_OrFilter)) {
		a = this;
		b = CAST(Filter,other);
	} else {
		b = this;
		a = CAST(Filter,other);
	}
	if (a->isKindOf(cat_OrFilter)) {
		if (b->isKindOf(cat_OrFilter)) {
			WPTR(XnRegion) 	returnValue;
			returnValue = Filter::orFilterPrivate(myCS, Filter::combineUnion(CAST(OrFilter,a)->subFilters(), CAST(OrFilter,b)->subFilters()));
			return returnValue;
		}
		if (b->isKindOf(cat_AndFilter)) {
			WPTR(XnRegion) 	returnValue;
			returnValue = Filter::orFilterPrivate(myCS, 
					Filter::distributeUnion(this->coordinateSpace(), CAST(AndFilter,b)->subFilters(), CAST(OrFilter,a)->subFilters()));
			return returnValue;
		}
		WPTR(XnRegion) 	returnValue;
		returnValue = Filter::orFilterPrivate(myCS, Filter::combineUnion(CAST(OrFilter,a)->subFilters(), b));
		return returnValue;
	}
	if (!a->isKindOf(cat_AndFilter)) {
		SPTR(Filter) t;
		
		t = a;
		a = b;
		b = t;
	}
	if (a->isKindOf(cat_AndFilter)) {
		WPTR(XnRegion) 	returnValue;
		returnValue = Filter::orFilterPrivate(myCS, 
				Filter::distributeUnion(this->coordinateSpace(), CAST(AndFilter,a)->subFilters(), b));
		return returnValue;
	}
	canon = this->getPairUnion(CAST(Filter,other));
	WPTR(XnRegion) 	returnValue;
	returnValue = Filter::orFilterPrivate(myCS, ImmuSet::make ()->with(canon->left())->with(canon->right()));
	return returnValue;
}


RPTR(Pair) OF1(Filter) Filter::fetchCanonicalIntersect (APTR(Filter) /* other */){
	/* return NULL, or the pair of canonical filters (left == 
	new1 | self, right == new2 | other) */
	
	return NULL;
}


RPTR(Pair) OF1(Filter) Filter::fetchCanonicalUnion (APTR(Filter) /* other */){
	/* return NULL, or the pair of canonical filters (left == 
	new1 | self, right == new2 | other) */
	
	return NULL;
}


RPTR(XnRegion) Filter::fetchIntersect (APTR(XnRegion) other){
	SPTR(XnRegion) temp;
	
	temp = this->fetchSpecialSubset(other);
	if (temp == NULL) {
		temp = CAST(Filter,other)->fetchSpecialSubset(this);
	}
	if (temp == this) {
		return this;
	}
	if ((Heaper * ) temp == other) {
		WPTR(XnRegion) 	returnValue;
		returnValue = other;
		return returnValue;
	}
	temp = this->fetchSpecialIntersect(other);
	if (temp != NULL) {
		WPTR(XnRegion) 	returnValue;
		returnValue = temp;
		return returnValue;
	}
	WPTR(XnRegion) 	returnValue;
	returnValue = CAST(Filter,other)->fetchSpecialIntersect(this);
	return returnValue;
}


RPTR(Pair) OF1(Filter) Filter::fetchPairIntersect (APTR(Filter) other){
	/* return the pair of canonical filters (left == new1 | self, 
	right == new2 | other) */
	
	SPTR(Pair) OF1(Filter) result;
	
	result = this->fetchCanonicalIntersect(other);
	if (result != NULL) {
		WPTR(Pair) OF1(Filter) 	returnValue;
		returnValue = result;
		return returnValue;
	}
	result = other->fetchCanonicalIntersect(this);
	if (result != NULL) {
		WPTR(Pair) OF1(Filter) 	returnValue;
		returnValue = result->reversed();
		return returnValue;
	}
	return NULL;
}


RPTR(Pair) OF1(Filter) Filter::fetchPairUnion (APTR(Filter) other){
	/* return the pair of canonical filters (left == new1 | self, 
	right == new2 | other) */
	
	SPTR(Pair) OF1(Filter) result;
	
	result = this->fetchCanonicalUnion(other);
	if (result != NULL) {
		WPTR(Pair) OF1(Filter) 	returnValue;
		returnValue = result;
		return returnValue;
	}
	result = other->fetchCanonicalUnion(this);
	if (result != NULL) {
		WPTR(Pair) OF1(Filter) 	returnValue;
		returnValue = result->reversed();
		return returnValue;
	}
	return NULL;
}


RPTR(XnRegion) Filter::fetchSpecialIntersect (APTR(XnRegion) /* other */){
	return NULL;
}


RPTR(XnRegion) Filter::fetchSpecialUnion (APTR(XnRegion) /* other */){
	return NULL;
}


RPTR(XnRegion) Filter::fetchUnion (APTR(XnRegion) other){
	SPTR(XnRegion) temp;
	
	temp = this->fetchSpecialSubset(other);
	if (temp == NULL) {
		temp = CAST(Filter,other)->fetchSpecialSubset(this);
	}
	if (temp == this) {
		WPTR(XnRegion) 	returnValue;
		returnValue = other;
		return returnValue;
	}
	if ((Heaper * ) temp == other) {
		return this;
	}
	temp = this->fetchSpecialUnion(other);
	if (temp != NULL) {
		WPTR(XnRegion) 	returnValue;
		returnValue = temp;
		return returnValue;
	}
	WPTR(XnRegion) 	returnValue;
	returnValue = CAST(Filter,other)->fetchSpecialUnion(this);
	return returnValue;
}


RPTR(Pair) OF1(Filter) Filter::getPairIntersect (APTR(Filter) other){
	/* return the pair of canonical filters (left == new1 | self, 
	right == new2 | other) */
	
	SPTR(Pair) OF1(Filter) result;
	
	result = this->fetchCanonicalIntersect(other);
	if (result != NULL) {
		WPTR(Pair) OF1(Filter) 	returnValue;
		returnValue = result;
		return returnValue;
	}
	result = other->fetchCanonicalIntersect(this);
	if (result != NULL) {
		WPTR(Pair) OF1(Filter) 	returnValue;
		returnValue = result->reversed();
		return returnValue;
	}
	WPTR(Pair) OF1(Filter) 	returnValue;
	returnValue = Pair::make (this, other);
	return returnValue;
}


RPTR(Pair) OF1(Filter) Filter::getPairUnion (APTR(Filter) other){
	/* return the pair of canonical filters (left == new1 | self, 
	right == new2 | other) */
	
	SPTR(Pair) OF1(Filter) result;
	
	result = this->fetchCanonicalUnion(other);
	if (result != NULL) {
		WPTR(Pair) OF1(Filter) 	returnValue;
		returnValue = result;
		return returnValue;
	}
	result = other->fetchCanonicalUnion(this);
	if (result != NULL) {
		WPTR(Pair) OF1(Filter) 	returnValue;
		returnValue = result->reversed();
		return returnValue;
	}
	WPTR(Pair) OF1(Filter) 	returnValue;
	returnValue = Pair::make (this, other);
	return returnValue;
}
/* protected: enumerating */


RPTR(Stepper) OF1(Position) Filter::actualStepper (APTR(OrderSpec) order){
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}
/* protected: */



/* ************************************************************************ *
 * 
 *                    Class FilterPosition 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(FilterPosition) FilterPosition::make (APTR(XnRegion) region){
	/* A position containing the given region. */
	
	RETURN_CONSTRUCT(FilterPosition,(region, tcsj));
}
/* Encapsulates a Region in the baseSpace into a Position so that it 
can be treated as one for polymorphism. See Filter. */


/* testing */


UInt32 FilterPosition::actualHashForEqual (){
	return myRegion->hashForEqual() + 1;
}


BooleanVar FilterPosition::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(FilterPosition,rap) {
			return rap->baseRegion()->isEqual(myRegion);
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}
/* accessing */


RPTR(XnRegion) FilterPosition::asRegion (){
	WPTR(XnRegion) 	returnValue;
	returnValue = Filter::subsetFilter(this->coordinateSpace(), myRegion)->intersect(Filter::supersetFilter(this->coordinateSpace(), myRegion));
	return returnValue;
}


RPTR(CoordinateSpace) FilterPosition::coordinateSpace (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = FilterSpace::make (myRegion->coordinateSpace());
	return returnValue;
}
/* instance creation */


FilterPosition::FilterPosition (APTR(XnRegion) region, TCSJ) {
	myRegion = region;
}



/* ************************************************************************ *
 * 
 *                    Class FilterSpace 
 *
 * ************************************************************************ */


/* creation */


RPTR(FilterSpace) FilterSpace::make (APTR(CoordinateSpace) base){
	/* A FilterSpace on the given base space. */
	
	RETURN_CONSTRUCT(FilterSpace,(base, tcsj));
}
/* rcvr pseudo constructors */


RPTR(Heaper) FilterSpace::make (APTR(Rcvr) rcvr){
	WPTR(Heaper) 	returnValue;
	returnValue = new (CAST(SpecialistRcvr,rcvr)->makeIbid(cat_FilterSpace)) FilterSpace(CAST(CoordinateSpace,rcvr->receiveHeaper()), tcsj);
	return returnValue;
}
/* A FilterSpace can be described mathematically as a power space of 
its baseSpace, i.e. the set of all subsets of the baseSpace. Each 
position in a FilterSpace is a Region in the baseSpace, and each 
Filter is a set of Regions taken from the baseSpace. See Filter for 
more detail. */


/* creation */


FilterSpace::FilterSpace (APTR(CoordinateSpace) base, TCSJ) {
	this->finishCreate(ClosedFilter::make (this), OpenFilter::make (this), FilterDsp::make (this), NULL, NULL);
	myBaseSpace = base;
}
/* testing */


UInt32 FilterSpace::actualHashForEqual (){
	return myBaseSpace->hashForEqual() + 1;
}


BooleanVar FilterSpace::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(FilterSpace,fs) {
			return fs->baseSpace()->isEqual(myBaseSpace);
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}
/* accessing */
/* printing */


void FilterSpace::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myBaseSpace << ")";
}
/* making */
/* hooks: */


void FilterSpace::sendFilterSpaceTo (APTR(Xmtr) xmtr){
	xmtr->sendHeaper(myBaseSpace);
}



/* ************************************************************************ *
 * 
 *                    Class Joint 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(Joint) Joint::make (APTR(CoordinateSpace) space){
	/* An empty Joint in the given coordinate space. */
	
	RETURN_CONSTRUCT(Joint,(space->emptyRegion(), space->fullRegion()));
}


RPTR(Joint) Joint::make (APTR(Joint) left, APTR(Joint) right){
	/* A joint that is a parent of the two given Joints. */
	
	RETURN_CONSTRUCT(Joint,(left->unioned()->unionWith(right->unioned()), left->intersected()->intersect(right->intersected())));
}


RPTR(Joint) Joint::make (APTR(ScruSet) OF1(Joint) subs){
	/* A Joint that is a parent of all of the Joints in the set. */
	
	SPTR(XnRegion) unioned;
	SPTR(XnRegion) intersected;
	SPTR(Stepper) subStepper;
	
	subStepper = subs->stepper();
	unioned = CAST(Joint,subStepper->get())->unioned();
	intersected = CAST(Joint,subStepper->fetch())->intersected();
	subStepper->step();
	BEGIN_FOR_EACH(Joint,sub,(subStepper)) {
		unioned = unioned->unionWith(sub->unioned());
		intersected = intersected->intersect(sub->intersected());
	} END_FOR_EACH;
	RETURN_CONSTRUCT(Joint,(unioned, intersected));
}


RPTR(Joint) Joint::make (APTR(XnRegion) both){
	/* A Joint containing only the given region. */
	
	RETURN_CONSTRUCT(Joint,(both, both));
}


RPTR(Joint) Joint::make (APTR(XnRegion) unioned, APTR(XnRegion) intersected){
	/* A Joint with the given union and intersection regions. */
	
	RETURN_CONSTRUCT(Joint,(unioned, intersected));
}
/* Joints are used to prune searches through trees of Regions. Each 
Joint summarizes the Joints and Regions at its node and its children 
using their intersection and union. If you maintain this information 
at each each node in the tree, then you can search for Regions in the 
tree efficiently using Filter::pass() to adapt the search criteria to 
the contents of the subtree. See also Filter::pass(Joint *). */


/* creation */


Joint::Joint (APTR(XnRegion) unioned, APTR(XnRegion) intersected) {
	myUnioned = unioned;
	myIntersected = intersected;
}
/* printing */


void Joint::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(union: " << myUnioned << "; intersected: " << myIntersected << ")";
}
/* accessing */


RPTR(Joint) Joint::with (APTR(XnRegion) region){
	/* A Joint that is a parent of this one and the given region. */
	
	WPTR(Joint) 	returnValue;
	returnValue = Joint::make (myUnioned->unionWith(region), myIntersected->intersect(region));
	return returnValue;
}
/* testing */


UInt32 Joint::actualHashForEqual (){
	return myUnioned->hashForEqual() + myIntersected->hashForEqual();
}


BooleanVar Joint::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(Joint,o) {
			{	BooleanVar crutch_Flag;
				/* myUnioned->isEqual(o->unioned()) && myIntersected->isEqual(o->intersected()) */
				
				crutch_Flag = myUnioned->isEqual(o->unioned());
				if(crutch_Flag) {
					crutch_Flag = myIntersected->isEqual(o->intersected());
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}



/* ************************************************************************ *
 * 
 *                    Class RegionDelta 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(RegionDelta) RegionDelta::make (APTR(XnRegion) before, APTR(XnRegion) after){
	RETURN_CONSTRUCT(RegionDelta,(before, after));
}
/* A RegionDelta represents a change in the state of a Region, 
holding the state before and after some change. They are in some 
sense complementary to Joints: In the same way that you can use 
Filters to examine Joints, you can use RegionDeltas to examine 
Filters. See also Filter::isSwitchedBy(RegionDelta *) and related methods. */


/* creation */


RegionDelta::RegionDelta (APTR(XnRegion) before, APTR(XnRegion) after) {
	myBefore = before;
	myAfter = after;
}
/* testing */


UInt32 RegionDelta::actualHashForEqual (){
	return myBefore->hashForEqual() + myAfter->hashForEqual();
}


BooleanVar RegionDelta::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(RegionDelta,rd) {
			{	BooleanVar crutch_Flag;
				/* rd->before()->isEqual(myBefore) && rd->after()->isEqual(myAfter) */
				
				crutch_Flag = rd->before()->isEqual(myBefore);
				if(crutch_Flag) {
					crutch_Flag = rd->after()->isEqual(myAfter);
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}
/* accessing */



/* ************************************************************************ *
 * 
 *                    Class AndFilter 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(Filter) AndFilter::make (APTR(FilterSpace) cs, APTR(ImmuSet) OF1(Filter) subs){
	/* assumes that the interactions between elements have 
	already been removed */
	
	if (subs->isEmpty()) {
		return CAST(Filter,cs->fullRegion());
	}
	if (subs->count() == 1) {
		return CAST(Filter,subs->theOne());
	}
	RETURN_CONSTRUCT(AndFilter,(cs, subs));
}
/* creation */


AndFilter::AndFilter (APTR(FilterSpace) cs, APTR(ImmuSet) OF1(Filter) subs) 
	: Filter(cs, tcsj) {
	mySubFilters = subs;
}
/* filtering */


BooleanVar AndFilter::match (APTR(XnRegion) region){
	/* tell whether a region passes this filter */
	
	BEGIN_FOR_EACH(Filter,sub,(this->subFilters()->stepper())) {
		if (!sub->match(region)) {
			return FALSE;
		}
	} END_FOR_EACH;
	return TRUE;
}


RPTR(Filter) AndFilter::pass (APTR(Joint) parent){
	/* return the simplest filter for looking at the children */
	
	SPTR(XnRegion) result;
	
	result = Filter::openFilter(this->coordinateSpace());
	BEGIN_FOR_EACH(Filter,sub,(this->subFilters()->stepper())) {
		result = result->intersect(sub->pass(parent));
	} END_FOR_EACH;
	return CAST(Filter,result);
}


RPTR(ImmuSet) OF1(Filter) AndFilter::subFilters (){
	return (ImmuSet*) mySubFilters;
}
/* printing */


void AndFilter::printOn (ostream& oo){
	oo << this->getCategory()->name();
	this->subFilters()->printOnWithSimpleSyntax(oo, "(", " && ", ")");
}
/* testing */


UInt32 AndFilter::actualHashForEqual (){
	return this->coordinateSpace()->hashForEqual() ^ mySubFilters->hashForEqual() ^ cat_AndFilter->hashForEqual();
}


BooleanVar AndFilter::isAllFilter (){
	return FALSE;
}


BooleanVar AndFilter::isAnyFilter (){
	return FALSE;
}


BooleanVar AndFilter::isEmpty (){
	return FALSE;
}


BooleanVar AndFilter::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(AndFilter,af) {
			return af->subFilters()->isEqual(this->subFilters());
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


BooleanVar AndFilter::isFull (){
	return FALSE;
}
/* operations */


RPTR(XnRegion) AndFilter::complement (){
	SPTR(XnRegion) result;
	
	result = Filter::closedFilter(this->coordinateSpace());
	BEGIN_FOR_EACH(XnRegion,sub,(this->subFilters()->stepper())) {
		result = result->unionWith(sub->complement());
	} END_FOR_EACH;
	WPTR(XnRegion) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* protected operations */


RPTR(XnRegion) AndFilter::fetchSpecialSubset (APTR(XnRegion) other){
	/* return self or other if one is clearly a subset of the 
	other, else NULL */
	
	SPTR(Filter) filter;
	SPTR(XnRegion) defaultRegion;
	
	filter = CAST(Filter,other);
	defaultRegion = other;
	BEGIN_FOR_EACH(Filter,subfilter,(this->subFilters()->stepper())) {
		SPTR(XnRegion) a;
		SPTR(XnRegion) b;
		
		if ((a = subfilter->fetchSpecialSubset(filter)) == subfilter) {
			return this;
		}
		if ((b = filter->fetchSpecialSubset(subfilter)) == subfilter) {
			return this;
		}
		{	BooleanVar crutch_Flag;
			/* (Heaper * ) a == other || (Heaper * ) b == other */
			
			crutch_Flag = (Heaper * ) a == other;
			if(!crutch_Flag) {
				crutch_Flag = (Heaper * ) b == other;
			}
			if (!crutch_Flag) {
				defaultRegion = NULL;
			}
		}
	} END_FOR_EACH;
	WPTR(XnRegion) 	returnValue;
	returnValue = defaultRegion;
	return returnValue;
}
/* enumerating */


RPTR(Stepper) OF1(Filter) AndFilter::intersectedFilters (){
	WPTR(Stepper) OF1(Filter) 	returnValue;
	returnValue = mySubFilters->stepper();
	return returnValue;
}


RPTR(Stepper) OF1(Filter) AndFilter::unionedFilters (){
	WPTR(Stepper) OF1(Filter) 	returnValue;
	returnValue = Stepper::itemStepper(this);
	return returnValue;
}
/* accessing */


RPTR(XnRegion) AndFilter::baseRegion (){
	BLAST(NotSimpleEnough);
	return NULL;
}


RPTR(XnRegion) AndFilter::relevantRegion (){
	SPTR(XnRegion) result;
	
	result = this->filterSpace()->baseSpace()->emptyRegion();
	BEGIN_FOR_EACH(Filter,sub,(mySubFilters->stepper())) {
		result = result->unionWith(sub->relevantRegion());
	} END_FOR_EACH;
	WPTR(XnRegion) 	returnValue;
	returnValue = result;
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class ClosedFilter 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(Filter) ClosedFilter::make (APTR(CoordinateSpace) space){
	RETURN_CONSTRUCT(ClosedFilter,(CAST(FilterSpace,space), tcsj));
}
/* creation */


ClosedFilter::ClosedFilter (APTR(FilterSpace) cs, TCSJ) 
	: Filter(cs, tcsj) {
	
}
/* operations */


RPTR(XnRegion) ClosedFilter::complement (){
	WPTR(XnRegion) 	returnValue;
	returnValue = Filter::openFilter(this->coordinateSpace());
	return returnValue;
}


RPTR(XnRegion) ClosedFilter::intersect (APTR(XnRegion) /* other */){
	return this;
}


RPTR(XnRegion) ClosedFilter::minus (APTR(XnRegion) /* other */){
	return this;
}


RPTR(XnRegion) ClosedFilter::unionWith (APTR(XnRegion) other){
	WPTR(XnRegion) 	returnValue;
	returnValue = other;
	return returnValue;
}
/* filtering */


BooleanVar ClosedFilter::match (APTR(XnRegion) /* region */){
	/* tell whether a region passes this filter */
	
	return FALSE;
}


RPTR(Filter) ClosedFilter::pass (APTR(Joint) /* parent */){
	/* return the simplest filter for looking at the children */
	
	return this;
}
/* testing */


UInt32 ClosedFilter::actualHashForEqual (){
	return this->coordinateSpace()->hashForEqual() ^ cat_ClosedFilter->hashForEqual();
}


BooleanVar ClosedFilter::isAllFilter (){
	return FALSE;
}


BooleanVar ClosedFilter::isAnyFilter (){
	return TRUE;
}


BooleanVar ClosedFilter::isEmpty (){
	return TRUE;
}


BooleanVar ClosedFilter::isEnumerable (APTR(OrderSpec) order/* = NULL*/){
	return TRUE;
}


BooleanVar ClosedFilter::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(ClosedFilter,cf) {
			return cf->coordinateSpace()->isEqual(this->coordinateSpace());
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


BooleanVar ClosedFilter::isFull (){
	return FALSE;
}
/* printing */


void ClosedFilter::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << this->coordinateSpace() << ")";
}
/* protected: protected operations */


RPTR(XnRegion) ClosedFilter::fetchSpecialSubset (APTR(XnRegion) /* other */){
	return this;
}
/* protected: enumerating */


RPTR(Stepper) OF1(Position) ClosedFilter::actualStepper (APTR(OrderSpec) order){
	WPTR(Stepper) OF1(Position) 	returnValue;
	returnValue = Stepper::emptyStepper();
	return returnValue;
}
/* enumerating */


RPTR(Stepper) OF1(Filter) ClosedFilter::intersectedFilters (){
	WPTR(Stepper) OF1(Filter) 	returnValue;
	returnValue = Stepper::itemStepper(this);
	return returnValue;
}


RPTR(Stepper) OF1(Filter) ClosedFilter::unionedFilters (){
	WPTR(Stepper) OF1(Filter) 	returnValue;
	returnValue = Stepper::emptyStepper();
	return returnValue;
}
/* accessing */


RPTR(XnRegion) ClosedFilter::baseRegion (){
	WPTR(XnRegion) 	returnValue;
	returnValue = CAST(FilterSpace,this->coordinateSpace())->emptyRegion();
	return returnValue;
}


RPTR(XnRegion) ClosedFilter::relevantRegion (){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->filterSpace()->baseSpace()->emptyRegion();
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class FilterDsp 
 *
 * ************************************************************************ */



/* Initializers for FilterDsp */

/* Initializers for FilterDsp */
/* pseudo constructors */


RPTR(FilterDsp) FilterDsp::make (APTR(FilterSpace) cs){
	/* An identity Dsp on the given FilterSpace. */
	
	RETURN_CONSTRUCT(FilterDsp,(cs, tcsj));
}
/* There are no non-trivial Dsps currently defined on a FilterSpace.

It would be possible to define them with reference to a Dsp in the 
baseSpace, as
	filterDsp->of(filter)->match(R) iff filter->match(filterDsp->baseDsp(
)->inverseOf(R))
		for all R in the base space.
However, we have not yet found a use for them. */


/* creation */


FilterDsp::FilterDsp (APTR(CoordinateSpace) cs, TCSJ) {
	myCS = CAST(FilterSpace,cs);
}
/* testing */


UInt32 FilterDsp::actualHashForEqual (){
	return myCS->hashForEqual() + cat_FilterDsp->hashForEqual();
}


BooleanVar FilterDsp::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(FilterDsp,fd) {
			return fd->coordinateSpace()->isEqual(myCS);
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}
/* accessing */


RPTR(CoordinateSpace) FilterDsp::coordinateSpace (){
	return (FilterSpace*) myCS;
}



/* ************************************************************************ *
 * 
 *                    Class NotSubsetFilter 
 *
 * ************************************************************************ */


/* filtering */


BooleanVar NotSubsetFilter::match (APTR(XnRegion) region){
	/* tell whether a region passes this filter */
	
	return !region->isSubsetOf(myRegion);
}


RPTR(Filter) NotSubsetFilter::pass (APTR(Joint) parent){
	/* return the simplest filter for looking at the children */
	
	if (!parent->intersected()->isSubsetOf(myRegion)) {
		WPTR(Filter) 	returnValue;
		returnValue = Filter::openFilter(this->coordinateSpace());
		return returnValue;
	}
	if (parent->unioned()->isSubsetOf(myRegion)) {
		WPTR(Filter) 	returnValue;
		returnValue = Filter::closedFilter(this->coordinateSpace());
		return returnValue;
	}
	return this;
}


RPTR(XnRegion) NotSubsetFilter::region (){
	return (XnRegion*) myRegion;
}
/* testing */


UInt32 NotSubsetFilter::actualHashForEqual (){
	return this->coordinateSpace()->hashForEqual() ^ myRegion->hashForEqual() ^ cat_NotSubsetFilter->hashForEqual();
}


BooleanVar NotSubsetFilter::isAllFilter (){
	return FALSE;
}


BooleanVar NotSubsetFilter::isAnyFilter (){
	return TRUE;
}


BooleanVar NotSubsetFilter::isEmpty (){
	return FALSE;
}


BooleanVar NotSubsetFilter::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(NotSubsetFilter,nsf) {
			return nsf->region()->isEqual(myRegion);
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


BooleanVar NotSubsetFilter::isFull (){
	return FALSE;
}
/* operations */


RPTR(XnRegion) NotSubsetFilter::complement (){
	WPTR(XnRegion) 	returnValue;
	returnValue = Filter::subsetFilter(this->coordinateSpace(), myRegion);
	return returnValue;
}
/* creation */


NotSubsetFilter::NotSubsetFilter (APTR(FilterSpace) cs, APTR(XnRegion) region) 
	: Filter(cs, tcsj) {
	myRegion = region;
}
/* printing */


void NotSubsetFilter::printOn (ostream& oo){
	oo << "IntersectionFilter(" << myRegion->complement() << ")";
}
/* protected operations */


RPTR(XnRegion) NotSubsetFilter::fetchSpecialIntersect (APTR(XnRegion) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(SubsetFilter,sf) {
			if (sf->region()->isSubsetOf(myRegion)) {
				WPTR(XnRegion) 	returnValue;
				returnValue = Filter::closedFilter(this->coordinateSpace());
				return returnValue;
			} else {
				return NULL;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return NULL;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return NULL;
}


RPTR(XnRegion) NotSubsetFilter::fetchSpecialSubset (APTR(XnRegion) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(NotSubsetFilter,nsf) {
			SPTR(XnRegion) others;
			
			others = nsf->region();
			if (others->isSubsetOf(myRegion)) {
				return this;
			}
			if (myRegion->isSubsetOf(others)) {
				WPTR(XnRegion) 	returnValue;
				returnValue = other;
				return returnValue;
			}
		} END_KIND;
		BEGIN_OTHERS {
			
		} END_OTHERS;
	} END_CHOOSE;
	return NULL;
}


RPTR(XnRegion) NotSubsetFilter::fetchSpecialUnion (APTR(XnRegion) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(SubsetFilter,sf) {
			if (myRegion->isSubsetOf(sf->region())) {
				WPTR(XnRegion) 	returnValue;
				returnValue = Filter::openFilter(this->coordinateSpace());
				return returnValue;
			} else {
				return NULL;
			}
		} END_KIND;
		BEGIN_KIND(NotSubsetFilter,nsf) {
			WPTR(XnRegion) 	returnValue;
			returnValue = Filter::notSubsetFilter(this->coordinateSpace(), myRegion->intersect(nsf->region()));
			return returnValue;
		} END_KIND;
		BEGIN_OTHERS {
			return NULL;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return NULL;
}
/* enumerating */


RPTR(Stepper) OF1(Filter) NotSubsetFilter::intersectedFilters (){
	WPTR(Stepper) OF1(Filter) 	returnValue;
	returnValue = Stepper::itemStepper(this);
	return returnValue;
}


RPTR(Stepper) OF1(Filter) NotSubsetFilter::unionedFilters (){
	WPTR(Stepper) OF1(Filter) 	returnValue;
	returnValue = Stepper::itemStepper(this);
	return returnValue;
}
/* accessing */


RPTR(XnRegion) NotSubsetFilter::baseRegion (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myRegion->complement();
	return returnValue;
}


RPTR(XnRegion) NotSubsetFilter::relevantRegion (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myRegion->complement();
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class NotSupersetFilter 
 *
 * ************************************************************************ */


/* filtering */


BooleanVar NotSupersetFilter::match (APTR(XnRegion) region){
	/* tell whether a region passes this filter */
	
	return !myRegion->isSubsetOf(region);
}


RPTR(Filter) NotSupersetFilter::pass (APTR(Joint) parent){
	/* return the simplest filter for looking at the children */
	
	if (!myRegion->isSubsetOf(parent->unioned())) {
		WPTR(Filter) 	returnValue;
		returnValue = Filter::openFilter(this->coordinateSpace());
		return returnValue;
	}
	if (myRegion->isSubsetOf(parent->intersected())) {
		WPTR(Filter) 	returnValue;
		returnValue = Filter::closedFilter(this->coordinateSpace());
		return returnValue;
	}
	return this;
}


RPTR(XnRegion) NotSupersetFilter::region (){
	return (XnRegion*) myRegion;
}
/* operations */


RPTR(XnRegion) NotSupersetFilter::complement (){
	WPTR(XnRegion) 	returnValue;
	returnValue = Filter::supersetFilter(this->coordinateSpace(), myRegion);
	return returnValue;
}
/* testing */


UInt32 NotSupersetFilter::actualHashForEqual (){
	return this->coordinateSpace()->hashForEqual() ^ myRegion->hashForEqual() ^ cat_NotSupersetFilter->hashForEqual();
}


BooleanVar NotSupersetFilter::isAllFilter (){
	return FALSE;
}


BooleanVar NotSupersetFilter::isAnyFilter (){
	return FALSE;
}


BooleanVar NotSupersetFilter::isEmpty (){
	return FALSE;
}


BooleanVar NotSupersetFilter::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(NotSupersetFilter,nsf) {
			return nsf->region()->isEqual(myRegion);
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


BooleanVar NotSupersetFilter::isFull (){
	return FALSE;
}
/* creation */


NotSupersetFilter::NotSupersetFilter (APTR(FilterSpace) cs, APTR(XnRegion) region) 
	: Filter(cs, tcsj) {
	myRegion = region;
}
/* printing */


void NotSupersetFilter::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myRegion << ")";
}
/* protected operations */


RPTR(Pair) OF1(Filter) NotSupersetFilter::fetchCanonicalIntersect (APTR(Filter) other){
	/* return NULL, or the pair of canonical filters (left == 
	new1 | self, right == new2 | other) */
	
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(SubsetFilter,subF) {
			SPTR(XnRegion) others;
			
			others = subF->region();
			if (myRegion->isSubsetOf(others)) {
				return NULL;
			} else {
				WPTR(Pair) OF1(Filter) 	returnValue;
				returnValue = Pair::make (Filter::notSupersetFilter(this->coordinateSpace(), myRegion->intersect(others)), other);
				return returnValue;
			}
		} END_KIND;
		BEGIN_KIND(SupersetFilter,superF) {
			SPTR(XnRegion) others;
			
			others = superF->region();
			if (myRegion->intersects(others)) {
				WPTR(Pair) OF1(Filter) 	returnValue;
				returnValue = Pair::make (Filter::notSupersetFilter(this->coordinateSpace(), myRegion->minus(superF->region())), other);
				return returnValue;
			} else {
				return NULL;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return NULL;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return NULL;
}


RPTR(Pair) OF1(Filter) NotSupersetFilter::fetchCanonicalUnion (APTR(Filter) other){
	/* return NULL, or the pair of canonical filters (left == 
	new1 | self, right == new2 | other) */
	
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(SupersetFilter,sf) {
			SPTR(XnRegion) others;
			
			others = sf->region();
			if (myRegion->intersects(others)) {
				WPTR(Pair) OF1(Filter) 	returnValue;
				returnValue = Pair::make (this, Filter::supersetFilter(this->coordinateSpace(), sf->region()->minus(myRegion)));
				return returnValue;
			} else {
				return NULL;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return NULL;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return NULL;
}


RPTR(XnRegion) NotSupersetFilter::fetchSpecialIntersect (APTR(XnRegion) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(SupersetFilter,sf) {
			if (myRegion->isSubsetOf(sf->region())) {
				WPTR(XnRegion) 	returnValue;
				returnValue = Filter::closedFilter(this->coordinateSpace());
				return returnValue;
			} else {
				return NULL;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return NULL;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return NULL;
}


RPTR(XnRegion) NotSupersetFilter::fetchSpecialSubset (APTR(XnRegion) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(SubsetFilter,subF) {
			if (!myRegion->isSubsetOf(subF->region())) {
				WPTR(XnRegion) 	returnValue;
				returnValue = other;
				return returnValue;
			}
		} END_KIND;
		BEGIN_KIND(NotSupersetFilter,nSuperF) {
			SPTR(XnRegion) others;
			
			others = nSuperF->region();
			if (myRegion->isSubsetOf(others)) {
				return this;
			}
			if (others->isSubsetOf(myRegion)) {
				WPTR(XnRegion) 	returnValue;
				returnValue = other;
				return returnValue;
			}
		} END_KIND;
		BEGIN_OTHERS {
			
		} END_OTHERS;
	} END_CHOOSE;
	return NULL;
}


RPTR(XnRegion) NotSupersetFilter::fetchSpecialUnion (APTR(XnRegion) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(NotSubsetFilter,nSubF) {
			if (!myRegion->isSubsetOf(nSubF->region())) {
				WPTR(XnRegion) 	returnValue;
				returnValue = Filter::openFilter(this->coordinateSpace());
				return returnValue;
			}
		} END_KIND;
		BEGIN_KIND(SupersetFilter,superF) {
			if (superF->region()->isSubsetOf(myRegion)) {
				WPTR(XnRegion) 	returnValue;
				returnValue = Filter::openFilter(this->coordinateSpace());
				return returnValue;
			}
		} END_KIND;
		BEGIN_KIND(NotSupersetFilter,nSuperF) {
			WPTR(XnRegion) 	returnValue;
			returnValue = Filter::notSupersetFilter(this->coordinateSpace(), myRegion->unionWith(nSuperF->region()));
			return returnValue;
		} END_KIND;
		BEGIN_OTHERS {
			
		} END_OTHERS;
	} END_CHOOSE;
	return NULL;
}
/* enumerating */


RPTR(Stepper) OF1(Filter) NotSupersetFilter::intersectedFilters (){
	WPTR(Stepper) OF1(Filter) 	returnValue;
	returnValue = Stepper::itemStepper(this);
	return returnValue;
}


RPTR(Stepper) OF1(Filter) NotSupersetFilter::unionedFilters (){
	WPTR(Stepper) OF1(Filter) 	returnValue;
	returnValue = Stepper::itemStepper(this);
	return returnValue;
}
/* accessing */


RPTR(XnRegion) NotSupersetFilter::baseRegion (){
	BLAST(NotSimpleEnough);
	return NULL;
}


RPTR(XnRegion) NotSupersetFilter::relevantRegion (){
	return (XnRegion*) myRegion;
}



/* ************************************************************************ *
 * 
 *                    Class OpenFilter 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(Filter) OpenFilter::make (APTR(CoordinateSpace) space){
	RETURN_CONSTRUCT(OpenFilter,(CAST(FilterSpace,space), tcsj));
}
/* operations */


RPTR(XnRegion) OpenFilter::complement (){
	WPTR(XnRegion) 	returnValue;
	returnValue = Filter::closedFilter(this->coordinateSpace());
	return returnValue;
}


RPTR(XnRegion) OpenFilter::intersect (APTR(XnRegion) other){
	WPTR(XnRegion) 	returnValue;
	returnValue = other;
	return returnValue;
}


RPTR(XnRegion) OpenFilter::minus (APTR(XnRegion) other){
	WPTR(XnRegion) 	returnValue;
	returnValue = other->complement();
	return returnValue;
}


RPTR(XnRegion) OpenFilter::unionWith (APTR(XnRegion) /* other */){
	return this;
}
/* filtering */


BooleanVar OpenFilter::match (APTR(XnRegion) /* region */){
	/* tell whether a region passes this filter */
	
	return TRUE;
}


RPTR(Filter) OpenFilter::pass (APTR(Joint) /* parent */){
	/* return the simplest filter for looking at the children */
	
	return this;
}
/* testing */


UInt32 OpenFilter::actualHashForEqual (){
	return this->coordinateSpace()->hashForEqual() ^ cat_OpenFilter->hashForEqual();
}


BooleanVar OpenFilter::isAllFilter (){
	return TRUE;
}


BooleanVar OpenFilter::isAnyFilter (){
	return FALSE;
}


BooleanVar OpenFilter::isEmpty (){
	return FALSE;
}


BooleanVar OpenFilter::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(OpenFilter,of) {
			return of->coordinateSpace()->isEqual(this->coordinateSpace());
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


BooleanVar OpenFilter::isFull (){
	return TRUE;
}
/* creation */


OpenFilter::OpenFilter (APTR(FilterSpace) cs, TCSJ) 
	: Filter(cs, tcsj) {
	
}
/* printing */


void OpenFilter::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << this->coordinateSpace() << ")";
}
/* protected: protected operations */


RPTR(XnRegion) OpenFilter::fetchSpecialSubset (APTR(XnRegion) other){
	WPTR(XnRegion) 	returnValue;
	returnValue = other;
	return returnValue;
}
/* enumerating */


RPTR(Stepper) OF1(Filter) OpenFilter::intersectedFilters (){
	WPTR(Stepper) OF1(Filter) 	returnValue;
	returnValue = Stepper::emptyStepper();
	return returnValue;
}


RPTR(Stepper) OF1(Filter) OpenFilter::unionedFilters (){
	WPTR(Stepper) OF1(Filter) 	returnValue;
	returnValue = Stepper::itemStepper(this);
	return returnValue;
}
/* accessing */


RPTR(XnRegion) OpenFilter::baseRegion (){
	WPTR(XnRegion) 	returnValue;
	returnValue = CAST(FilterSpace,this->coordinateSpace())->emptyRegion();
	return returnValue;
}


RPTR(XnRegion) OpenFilter::relevantRegion (){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->filterSpace()->baseSpace()->emptyRegion();
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class OrFilter 
 *
 * ************************************************************************ */


/* creation */


OrFilter::OrFilter (APTR(FilterSpace) cs, APTR(ImmuSet) OF1(Filter) subs) 
	: Filter(cs, tcsj) {
	mySubFilters = subs;
}
/* testing */


UInt32 OrFilter::actualHashForEqual (){
	return this->coordinateSpace()->hashForEqual() ^ mySubFilters->hashForEqual() ^ cat_OrFilter->hashForEqual();
}


BooleanVar OrFilter::isAllFilter (){
	return FALSE;
}


BooleanVar OrFilter::isAnyFilter (){
	return FALSE;
}


BooleanVar OrFilter::isEmpty (){
	return FALSE;
}


BooleanVar OrFilter::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(OrFilter,of) {
			return of->subFilters()->isEqual(this->subFilters());
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


BooleanVar OrFilter::isFull (){
	return FALSE;
}
/* printing */


void OrFilter::printOn (ostream& oo){
	oo << this->getCategory()->name();
	this->subFilters()->printOnWithSimpleSyntax(oo, "(", " || ", ")");
}
/* operations */


RPTR(XnRegion) OrFilter::complement (){
	SPTR(XnRegion) result;
	
	result = Filter::openFilter(this->coordinateSpace());
	BEGIN_FOR_EACH(XnRegion,sub,(this->subFilters()->stepper())) {
		result = result->intersect(sub->complement());
	} END_FOR_EACH;
	WPTR(XnRegion) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* filtering */


BooleanVar OrFilter::match (APTR(XnRegion) region){
	/* tell whether a region passes this filter */
	
	BEGIN_FOR_EACH(Filter,sub,(this->subFilters()->stepper())) {
		if (sub->match(region)) {
			return TRUE;
		}
	} END_FOR_EACH;
	return FALSE;
}


RPTR(Filter) OrFilter::pass (APTR(Joint) parent){
	/* return the simplest filter for looking at the children */
	
	SPTR(XnRegion) result;
	
	result = Filter::closedFilter(this->coordinateSpace());
	BEGIN_FOR_EACH(Filter,sub,(this->subFilters()->stepper())) {
		result = result->unionWith(sub->pass(parent));
	} END_FOR_EACH;
	return CAST(Filter,result);
}


RPTR(ImmuSet) OF1(Filter) OrFilter::subFilters (){
	return (ImmuSet*) mySubFilters;
}
/* protected: protected operations */


RPTR(XnRegion) OrFilter::fetchSpecialSubset (APTR(XnRegion) other){
	/* return self or other if one is clearly a subset of the 
	other, else NULL */
	
	SPTR(Filter) filter;
	SPTR(XnRegion) defaultRegion;
	
	filter = CAST(Filter,other);
	defaultRegion = this;
	BEGIN_FOR_EACH(Filter,subfilter,(this->subFilters()->stepper())) {
		SPTR(XnRegion) a;
		SPTR(XnRegion) b;
		
		if ((Heaper * ) (a = subfilter->fetchSpecialSubset(filter)) == other) {
			WPTR(XnRegion) 	returnValue;
			returnValue = other;
			return returnValue;
		}
		if ((Heaper * ) (b = filter->fetchSpecialSubset(subfilter)) == other) {
			WPTR(XnRegion) 	returnValue;
			returnValue = other;
			return returnValue;
		}
		{	BooleanVar crutch_Flag;
			/* (Heaper * ) a == other || (Heaper * ) b == other */
			
			crutch_Flag = (Heaper * ) a == other;
			if(!crutch_Flag) {
				crutch_Flag = (Heaper * ) b == other;
			}
			if (!crutch_Flag) {
				defaultRegion = NULL;
			}
		}
	} END_FOR_EACH;
	WPTR(XnRegion) 	returnValue;
	returnValue = defaultRegion;
	return returnValue;
}
/* enumerating */


RPTR(Stepper) OF1(Filter) OrFilter::intersectedFilters (){
	WPTR(Stepper) OF1(Filter) 	returnValue;
	returnValue = Stepper::itemStepper(this);
	return returnValue;
}


RPTR(Stepper) OF1(Filter) OrFilter::unionedFilters (){
	WPTR(Stepper) OF1(Filter) 	returnValue;
	returnValue = mySubFilters->stepper();
	return returnValue;
}
/* accessing */


RPTR(XnRegion) OrFilter::baseRegion (){
	BLAST(NotSimpleEnough);
	return NULL;
}


RPTR(XnRegion) OrFilter::relevantRegion (){
	SPTR(XnRegion) result;
	
	result = this->filterSpace()->baseSpace()->emptyRegion();
	BEGIN_FOR_EACH(Filter,sub,(mySubFilters->stepper())) {
		result = result->unionWith(sub->relevantRegion());
	} END_FOR_EACH;
	WPTR(XnRegion) 	returnValue;
	returnValue = result;
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class SubsetFilter 
 *
 * ************************************************************************ */


/* creation */


SubsetFilter::SubsetFilter (APTR(FilterSpace) cs, APTR(XnRegion) region) 
	: Filter(cs, tcsj) {
	myRegion = region;
}
/* operations */


RPTR(XnRegion) SubsetFilter::complement (){
	WPTR(XnRegion) 	returnValue;
	returnValue = Filter::notSubsetFilter(this->coordinateSpace(), myRegion);
	return returnValue;
}
/* filtering */


BooleanVar SubsetFilter::match (APTR(XnRegion) region){
	/* tell whether a region passes this filter */
	
	return region->isSubsetOf(myRegion);
}


RPTR(Filter) SubsetFilter::pass (APTR(Joint) parent){
	/* return the simplest filter for looking at the children */
	
	if (parent->unioned()->isSubsetOf(myRegion)) {
		WPTR(Filter) 	returnValue;
		returnValue = Filter::openFilter(this->coordinateSpace());
		return returnValue;
	}
	if (!parent->intersected()->isSubsetOf(myRegion)) {
		WPTR(Filter) 	returnValue;
		returnValue = Filter::closedFilter(this->coordinateSpace());
		return returnValue;
	}
	return this;
}


RPTR(XnRegion) SubsetFilter::region (){
	return (XnRegion*) myRegion;
}
/* testing */


UInt32 SubsetFilter::actualHashForEqual (){
	return this->coordinateSpace()->hashForEqual() ^ myRegion->hashForEqual() ^ cat_SubsetFilter->hashForEqual();
}


BooleanVar SubsetFilter::isAllFilter (){
	return FALSE;
}


BooleanVar SubsetFilter::isAnyFilter (){
	return FALSE;
}


BooleanVar SubsetFilter::isEmpty (){
	return FALSE;
}


BooleanVar SubsetFilter::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(SubsetFilter,ssf) {
			return ssf->region()->isEqual(myRegion);
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


BooleanVar SubsetFilter::isFull (){
	return FALSE;
}
/* printing */


void SubsetFilter::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myRegion << ")";
}
/* protected: protected operations */


RPTR(XnRegion) SubsetFilter::fetchSpecialUnion (APTR(XnRegion) /* other */){
	return NULL;
}
/* protected operations */


RPTR(XnRegion) SubsetFilter::fetchSpecialIntersect (APTR(XnRegion) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(SubsetFilter,sf) {
			WPTR(XnRegion) 	returnValue;
			returnValue = Filter::subsetFilter(this->coordinateSpace(), sf->region()->intersect(myRegion));
			return returnValue;
		} END_KIND;
		BEGIN_OTHERS {
			return NULL;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return NULL;
}


RPTR(XnRegion) SubsetFilter::fetchSpecialSubset (APTR(XnRegion) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(SubsetFilter,sf) {
			SPTR(XnRegion) others;
			
			others = sf->region();
			if (others->isSubsetOf(myRegion)) {
				WPTR(XnRegion) 	returnValue;
				returnValue = other;
				return returnValue;
			}
			if (myRegion->isSubsetOf(others)) {
				return this;
			}
		} END_KIND;
		BEGIN_OTHERS {
			
		} END_OTHERS;
	} END_CHOOSE;
	return NULL;
}
/* enumerating */


RPTR(Stepper) OF1(Filter) SubsetFilter::intersectedFilters (){
	WPTR(Stepper) OF1(Filter) 	returnValue;
	returnValue = Stepper::itemStepper(this);
	return returnValue;
}


RPTR(Stepper) OF1(Filter) SubsetFilter::unionedFilters (){
	WPTR(Stepper) OF1(Filter) 	returnValue;
	returnValue = Stepper::itemStepper(this);
	return returnValue;
}
/* accessing */


RPTR(XnRegion) SubsetFilter::baseRegion (){
	BLAST(NotSimpleEnough);
	return NULL;
}


RPTR(XnRegion) SubsetFilter::relevantRegion (){
	WPTR(XnRegion) 	returnValue;
	returnValue = myRegion->complement();
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class SupersetFilter 
 *
 * ************************************************************************ */


/* filtering */


BooleanVar SupersetFilter::match (APTR(XnRegion) region){
	/* tell whether a region passes this filter */
	
	return myRegion->isSubsetOf(region);
}


RPTR(Filter) SupersetFilter::pass (APTR(Joint) parent){
	/* return the simplest filter for looking at the children */
	
	if (myRegion->isSubsetOf(parent->intersected())) {
		WPTR(Filter) 	returnValue;
		returnValue = Filter::openFilter(this->coordinateSpace());
		return returnValue;
	}
	if (!myRegion->isSubsetOf(parent->unioned())) {
		WPTR(Filter) 	returnValue;
		returnValue = Filter::closedFilter(this->coordinateSpace());
		return returnValue;
	}
	return this;
}


RPTR(XnRegion) SupersetFilter::region (){
	return (XnRegion*) myRegion;
}
/* operations */


RPTR(XnRegion) SupersetFilter::complement (){
	WPTR(XnRegion) 	returnValue;
	returnValue = Filter::notSupersetFilter(this->coordinateSpace(), myRegion);
	return returnValue;
}
/* testing */


UInt32 SupersetFilter::actualHashForEqual (){
	return this->coordinateSpace()->hashForEqual() ^ myRegion->hashForEqual() ^ cat_SupersetFilter->hashForEqual();
}


BooleanVar SupersetFilter::isAllFilter (){
	return TRUE;
}


BooleanVar SupersetFilter::isAnyFilter (){
	return FALSE;
}


BooleanVar SupersetFilter::isEmpty (){
	return FALSE;
}


BooleanVar SupersetFilter::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(SupersetFilter,ssf) {
			return ssf->region()->isEqual(myRegion);
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


BooleanVar SupersetFilter::isFull (){
	return FALSE;
}
/* protected: protected operations */


RPTR(XnRegion) SupersetFilter::fetchSpecialUnion (APTR(XnRegion) /* other */){
	return NULL;
}
/* creation */


SupersetFilter::SupersetFilter (APTR(FilterSpace) cs, APTR(XnRegion) region) 
	: Filter(cs, tcsj) {
	myRegion = region;
}
/* printing */


void SupersetFilter::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myRegion << ")";
}
/* protected operations */


RPTR(Pair) OF1(Filter) SupersetFilter::fetchCanonicalUnion (APTR(Filter) other){
	/* return NULL, or the pair of canonical filters (left == 
	new1 | self, right == new2 | other) */
	
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(NotSubsetFilter,nsf) {
			SPTR(XnRegion) others;
			
			others = nsf->region();
			if (!myRegion->isSubsetOf(others)) {
				WPTR(Pair) OF1(Filter) 	returnValue;
				returnValue = Pair::make (Filter::supersetFilter(this->coordinateSpace(), myRegion->intersect(nsf->region())), other);
				return returnValue;
			}
		} END_KIND;
		BEGIN_OTHERS {
			
		} END_OTHERS;
	} END_CHOOSE;
	return NULL;
}


RPTR(XnRegion) SupersetFilter::fetchSpecialIntersect (APTR(XnRegion) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(SubsetFilter,subF) {
			if (!myRegion->isSubsetOf(subF->region())) {
				WPTR(XnRegion) 	returnValue;
				returnValue = Filter::closedFilter(this->coordinateSpace());
				return returnValue;
			}
		} END_KIND;
		BEGIN_KIND(SupersetFilter,superF) {
			WPTR(XnRegion) 	returnValue;
			returnValue = Filter::supersetFilter(this->coordinateSpace(), myRegion->unionWith(superF->region()));
			return returnValue;
		} END_KIND;
		BEGIN_OTHERS {
			
		} END_OTHERS;
	} END_CHOOSE;
	return NULL;
}


RPTR(XnRegion) SupersetFilter::fetchSpecialSubset (APTR(XnRegion) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(NotSubsetFilter,nSubF) {
			if (!myRegion->isSubsetOf(nSubF->region())) {
				return this;
			}
		} END_KIND;
		BEGIN_KIND(SupersetFilter,superF) {
			SPTR(XnRegion) others;
			
			others = superF->region();
			if (myRegion->isSubsetOf(others)) {
				WPTR(XnRegion) 	returnValue;
				returnValue = other;
				return returnValue;
			}
			if (others->isSubsetOf(myRegion)) {
				return this;
			}
		} END_KIND;
		BEGIN_OTHERS {
			
		} END_OTHERS;
	} END_CHOOSE;
	return NULL;
}
/* enumerating */


RPTR(Stepper) OF1(Filter) SupersetFilter::intersectedFilters (){
	WPTR(Stepper) OF1(Filter) 	returnValue;
	returnValue = Stepper::itemStepper(this);
	return returnValue;
}


RPTR(Stepper) OF1(Filter) SupersetFilter::unionedFilters (){
	WPTR(Stepper) OF1(Filter) 	returnValue;
	returnValue = Stepper::itemStepper(this);
	return returnValue;
}
/* accessing */


RPTR(XnRegion) SupersetFilter::baseRegion (){
	return (XnRegion*) myRegion;
}


RPTR(XnRegion) SupersetFilter::relevantRegion (){
	return (XnRegion*) myRegion;
}

#ifndef FILTERX_SXX
#include "filterx.sxx"
#endif /* FILTERX_SXX */


#ifndef FILTERP_SXX
#include "filterp.sxx"
#endif /* FILTERP_SXX */



#endif /* FILTERX_CXX */

