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

#ifndef FILTERX_HXX
#define FILTERX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef FILTERX_OXX
#include "filterx.oxx"
#endif /* FILTERX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */


#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */

#ifndef TABLESX_OXX
#include "tablesx.oxx"
#endif /* TABLESX_OXX */


/*  */
/*  */
/* xpp class */



/* ************************************************************************ *
 * 
 *                    Class Filter 
 *
 * ************************************************************************ */




	/* A position in a FilterSpace is a region in the baseSpace, 
	and a filter is a set of regions in the baseSpace. It is 
	often more useful to think of a Filter as a Boolean function 
	whose input is a region in the baseSpace, and of unions, 
	intersections, and complements of filters as ORs, ANDs, and 
	NOTs of functions. Not all possible such functions can be 
	represented as Filters, since there is an uncountable 
	infinity of them for any non-finite CoordinateSpace. There 
	are representations for some basic filters, and any filters 
	resulting from a finite sequence of unions, intersections, 
	and complements among them. The basic filters are:
		subsetFilter(cs,R) -- all subsets of R (i.e. all R1 such 
	that R1->isSubsetOf(R))
		supersetFilter(cs,R) -- all supersets of R (i.e. all R1 such 
	that R->isSubsetOf(R1))
	Mathematically, this is all that is necessary, since other 
	useful filters like intersection filters can be generated 
	from these. (e.g. intersectionFilter(R) is 
	subsetFilter(R->complement())->complement()). However, there 
	are several more pseudo constructors provided as shortcuts, 
	including intersectionFilters, closedFilters, emptyFilters, 
	and intersections and unions of sets of filters. */

class Filter : public XnRegion {

/* Attributes for class Filter */
	DEFERRED(Filter)
	ON_CLIENT(Filter)
	COPY(Filter,XppCuisine)
	AUTO_GC(Filter)
  public: /* pseudo constructors */

	/* A filter that matches only regions that all of the filters 
	in the set would have matched. */
	
	static RPTR(Filter) andFilter (APTR(CoordinateSpace) ARG(cs), APTR(ScruSet) OF1(Filter) ARG(subs));
	
	/* An filter that does match any region. */
	
	static RPTR(Filter) closedFilter (APTR(CoordinateSpace) ARG(cs));
	
	/* A filter that matches any region that intersects the given 
	region. */
	
	static RPTR(Filter) intersectionFilter (APTR(CoordinateSpace) ARG(cs), APTR(XnRegion) ARG(region));
	
	/* A filter matching any regions that is not a subset of the 
	given region. */
	
	static RPTR(Filter) notSubsetFilter (APTR(CoordinateSpace) ARG(cs), APTR(XnRegion) ARG(region));
	
	/* A filter that matches any region that is not a superset of 
	the given region. */
	
	static RPTR(Filter) notSupersetFilter (APTR(CoordinateSpace) ARG(cs), APTR(XnRegion) ARG(region));
	
	/* A filter that matches any region. */
	
	static RPTR(Filter) openFilter (APTR(CoordinateSpace) ARG(cs));
	
	/* A filter that matches any region that any of the filters 
	in the set would have matched. */
	
	static RPTR(Filter) orFilter (APTR(CoordinateSpace) ARG(cs), APTR(ScruSet) OF1(Filter) ARG(subs));
	
	/* A filter that matches any region that is a subset of the 
	given region. */
	
	static RPTR(Filter) subsetFilter (APTR(CoordinateSpace) ARG(cs), APTR(XnRegion) ARG(region));
	
	/* A region that matches any region that is a superset of the 
	given region. */
	
	static RPTR(Filter) supersetFilter (APTR(CoordinateSpace) ARG(cs), APTR(XnRegion) ARG(region));
	
  private: /* private: functions */

	/* assumes that the interactions between elements have 
	already been removed */
	
	static RPTR(Filter) andFilterPrivate (APTR(FilterSpace) ARG(cs), APTR(ImmuSet) OF1(Filter) ARG(subs));
	
	/* keep going around doing intersections until there are no 
	more special intersects */
	
	static RPTR(ImmuSet) OF1(Filter) combineIntersect (APTR(ImmuSet) OF1(Filter) ARG(set), APTR(Filter) ARG(filter));
	
	
	static RPTR(ImmuSet) OF1(Filter) combineIntersect (APTR(ImmuSet) OF1(Filter) ARG(a), APTR(ImmuSet) OF1(Filter) ARG(b));
	
	/* keep going around doing unions until there are no more 
	special unions */
	
	static RPTR(ImmuSet) OF1(Filter) combineUnion (APTR(ImmuSet) OF1(Filter) ARG(set), APTR(Filter) ARG(filter));
	
	
	static RPTR(ImmuSet) OF1(Filter) combineUnion (APTR(ImmuSet) OF1(Filter) ARG(a), APTR(ImmuSet) OF1(Filter) ARG(b));
	
	/* distribute the intersection of a filter with the union of 
	a set of filters */
	
	static RPTR(ImmuSet) OF1(Filter) distributeIntersect (
			APTR(CoordinateSpace) ARG(cs), 
			APTR(ImmuSet) OF1(Filter) ARG(set), 
			APTR(Filter) ARG(filter))
	;
	
	/* distribute the intersection of two unions of sets of filters */
	
	static RPTR(ImmuSet) OF1(Filter) distributeIntersect (
			APTR(CoordinateSpace) ARG(cs), 
			APTR(ImmuSet) OF1(Filter) ARG(a), 
			APTR(ImmuSet) OF1(Filter) ARG(b))
	;
	
	/* distribute the union of a filter with the intersection of 
	a set of filters */
	
	static RPTR(ImmuSet) OF1(Filter) distributeUnion (
			APTR(CoordinateSpace) ARG(cs), 
			APTR(ImmuSet) OF1(Filter) ARG(set), 
			APTR(Filter) ARG(filter))
	;
	
	/* distribute the union of an intersection and a union of 
	sets of filters */
	
	static RPTR(ImmuSet) OF1(Filter) distributeUnion (
			APTR(CoordinateSpace) ARG(cs), 
			APTR(ImmuSet) OF1(Filter) ARG(anded), 
			APTR(ImmuSet) OF1(Filter) ARG(ored))
	;
	
	/* assumes that the interactions between elements have 
	already been removed */
	
	static RPTR(Filter) orFilterPrivate (APTR(FilterSpace) ARG(cs), APTR(ImmuSet) OF1(Filter) ARG(subs));
	
  public: /* operations */

	
	virtual RPTR(XnRegion) complement () DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) intersect (APTR(XnRegion) ARG(other));
	
	
	INLINE RPTR(XnRegion) simpleUnion (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) unionWith (APTR(XnRegion) ARG(other));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar hasMember (APTR(Position) ARG(pos));
	
	/* Essential. Whether this is an 'all' Filter, i.e. it only 
	matches Regions which contain everything in the baseRegion */
	
	virtual CLIENT BooleanVar isAllFilter () DEFERRED_FUNC;
	
	/* Essential. Whether this is an 'any' Filter, i.e. it 
	matches Regions which contain anything in the baseRegion */
	
	virtual CLIENT BooleanVar isAnyFilter () DEFERRED_FUNC;
	
	
	virtual BooleanVar isEmpty () DEFERRED_FUNC;
	
	
	virtual BooleanVar isEnumerable (APTR(OrderSpec) ARG(order) = NULL);
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other)) DEFERRED_FUNC;
	
	
	INLINE BooleanVar isFinite ();
	
	
	virtual BooleanVar isFull () DEFERRED_FUNC;
	
	
	INLINE BooleanVar isSimple ();
	
	
	virtual BooleanVar isSubsetOf (APTR(XnRegion) ARG(other));
	
  public: /* enumerating */

	
	virtual IntegerVar count ();
	
	/* Essential. Break this up into a bunch of Filters which 
	when intersected (anded) together give this one. If there is 
	only one sub Filter it will be the receiver; otherwise, the 
	sub Filters will be simple enough that either they or their 
	complements will return true from at least one of isAndFilter 
	or isOrFilter. If this is full (i.e. an open filter) then the 
	stepper will have no elements. */
	
	virtual CLIENT RPTR(Stepper) OF1(Filter) intersectedFilters () DEFERRED_FUNC;
	
	/* Essential. Break this up into a bunch of Filters which 
	when unioned (ored) together give this one. If there is only 
	one sub Filter it will be the receiver; otherwise, the sub 
	Filters will be simple enough that either they or their 
	complements will return true from at least one of isAndFilter 
	or isOrFilter. The sub Filters might not be disjoint Regions. 
	If this is empty (i.e. a closed filter) then the stepper will 
	have no elements. */
	
	virtual CLIENT RPTR(Stepper) OF1(Filter) unionedFilters () DEFERRED_FUNC;
	
  public: /* accessing */

	
	INLINE RPTR(XnRegion) asSimpleRegion ();
	
	/* Essential. A region in the base space identifying what 
	kind of filter this is. Succeeds only if this isAnyFilter or 
	isAllFilter. */
	
	virtual CLIENT RPTR(XnRegion) baseRegion () DEFERRED_FUNC;
	
	
	INLINE RPTR(CoordinateSpace) coordinateSpace ();
	
	/* The region which is relevant to this filter, i.e. whose 
	presence or absence in a region can change whether it passes 
	the filter */
	
	virtual RPTR(XnRegion) relevantRegion () DEFERRED_FUNC;
	
  public: /* filtering */

	/* Whether there might be anything in the tree beneath the 
	Joint that would pass the filter. */
	
	virtual BooleanVar doesPass (APTR(Joint) ARG(joint));
	
	/* Whether the change causes a change in the state of the 
	filter. (I.E. Whether the old region was in and the new out, 
	or vice versa.) */
	
	virtual BooleanVar isSwitchedBy (APTR(RegionDelta) ARG(delta));
	
	/* Whether the change switches the state of the filter from 
	on to off. (I.E. Whether the old region was inside the filter 
	and the new region outside.) */
	
	virtual BooleanVar isSwitchedOffBy (APTR(RegionDelta) ARG(delta));
	
	/* Whether the change switches the state of the filter from 
	off to on. (I.E. Whether the old region was outside the 
	filter and the new region inside.) */
	
	virtual BooleanVar isSwitchedOnBy (APTR(RegionDelta) ARG(delta));
	
	/* Whether a region is inside this filter. */
	
	virtual CLIENT BooleanVar match (APTR(XnRegion) ARG(region)) DEFERRED_FUNC;
	
	/* The simplest filter for looking at the tree beneath the node.
		The Joint keeps the intersection and union of all the nodes 
	beneath it, so the result of this message can be used to 
	prune a search. If the result is full, then everything 
	beneath the node is in the filter (e.g. if this filter 
	contained all subsets of S and the union was a superset of 
	S). If the result is empty, then nothing beneath the node is 
	in the filter (e.g. if this filter contained all subsets of S 
	and the intersection was not a subset of S). In less extreme 
	cases, this operation may at least simplify the filter by 
	throwing out irrelevant search criteria. */
	
	virtual RPTR(Filter) pass (APTR(Joint) ARG(parent)) DEFERRED_FUNC;
	
  public: /* creation */

	
	Filter (APTR(FilterSpace) ARG(cs), TCSJ);
	
  public: /* components */

	
	virtual RPTR(ScruSet) OF1(XnRegion) distinctions ();
	
	
	virtual RPTR(Stepper) simpleRegions (APTR(OrderSpec) ARG(order) = NULL);
	
  public: /* vulnerable: internal */

	
	virtual RPTR(XnRegion) complexIntersect (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) complexUnion (APTR(XnRegion) ARG(other));
	
	/* return NULL, or the pair of canonical filters (left == 
	new1 | self, right == new2 | other) */
	
	virtual RPTR(Pair) OF1(Filter) fetchCanonicalIntersect (APTR(Filter) ARG(other));
	
	/* return NULL, or the pair of canonical filters (left == 
	new1 | self, right == new2 | other) */
	
	virtual RPTR(Pair) OF1(Filter) fetchCanonicalUnion (APTR(Filter) ARG(other));
	
	
	virtual RPTR(XnRegion) fetchIntersect (APTR(XnRegion) ARG(other));
	
	/* return the pair of canonical filters (left == new1 | self, 
	right == new2 | other) */
	
	virtual RPTR(Pair) OF1(Filter) fetchPairIntersect (APTR(Filter) ARG(other));
	
	/* return the pair of canonical filters (left == new1 | self, 
	right == new2 | other) */
	
	virtual RPTR(Pair) OF1(Filter) fetchPairUnion (APTR(Filter) ARG(other));
	
	
	virtual RPTR(XnRegion) fetchSpecialIntersect (APTR(XnRegion) ARG(other));
	
	/* return self or other if one is clearly a subset of the 
	other, else NULL */
	
	virtual RPTR(XnRegion) fetchSpecialSubset (APTR(XnRegion) ARG(other)) DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) fetchSpecialUnion (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) fetchUnion (APTR(XnRegion) ARG(other));
	
	/* return the pair of canonical filters (left == new1 | self, 
	right == new2 | other) */
	
	virtual RPTR(Pair) OF1(Filter) getPairIntersect (APTR(Filter) ARG(other));
	
	/* return the pair of canonical filters (left == new1 | self, 
	right == new2 | other) */
	
	virtual RPTR(Pair) OF1(Filter) getPairUnion (APTR(Filter) ARG(other));
	
  protected: /* protected: enumerating */

	
	virtual RPTR(Stepper) OF1(Position) actualStepper (APTR(OrderSpec) ARG(order));
	
  protected: /* protected: */

	
	INLINE RPTR(FilterSpace) filterSpace ();
	
  private:
	CHKPTR(FilterSpace) myCS;
};  /* end class Filter */



/* ************************************************************************ *
 * 
 *                    Class FilterPosition 
 *
 * ************************************************************************ */




	/* Encapsulates a Region in the baseSpace into a Position so 
	that it can be treated as one for polymorphism. See Filter. */

class FilterPosition : public Position {

/* Attributes for class FilterPosition */
	CONCRETE(FilterPosition)
	ON_CLIENT(FilterPosition)
	COPY(FilterPosition,XppCuisine)
	AUTO_GC(FilterPosition)
  public: /* pseudo constructors */

	/* A position containing the given region. */
	
	static RPTR(FilterPosition) make (APTR(XnRegion) ARG(region));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* accessing */

	
	virtual RPTR(XnRegion) asRegion ();
	
	/* Essential. The region in the base space which I represent. */
	
	INLINE CLIENT RPTR(XnRegion) baseRegion ();
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
  public: /* instance creation */

	
	FilterPosition (APTR(XnRegion) ARG(region), TCSJ);
	
  private:
	CHKPTR(XnRegion) myRegion;
};  /* end class FilterPosition */



/* ************************************************************************ *
 * 
 *                    Class FilterSpace 
 *
 * ************************************************************************ */




	/* A FilterSpace can be described mathematically as a power 
	space of its baseSpace, i.e. the set of all subsets of the 
	baseSpace. Each position in a FilterSpace is a Region in the 
	baseSpace, and each Filter is a set of Regions taken from the 
	baseSpace. See Filter for more detail. */

class FilterSpace : public CoordinateSpace {

/* Attributes for class FilterSpace */
	CONCRETE(FilterSpace)
	PSEUDO_COPY(FilterSpace,XppCuisine)
	ON_CLIENT(FilterSpace)
	AUTO_GC(FilterSpace)
  public: /* creation */

	/* A FilterSpace on the given base space. */
	
	static CLIENT RPTR(FilterSpace) make (APTR(CoordinateSpace) ARG(base));
	
  public: /* rcvr pseudo constructors */

	
	static RPTR(Heaper) make (APTR(Rcvr) ARG(rcvr));
	
  public: /* creation */

	
	FilterSpace (APTR(CoordinateSpace) ARG(base), TCSJ);
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* accessing */

	/* Essential.  The CoordinateSpace of the Regions that are 
	the input to Filters in this FilterSpace. */
	
	INLINE CLIENT RPTR(CoordinateSpace) baseSpace ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* making */

	/* Essential. A region that matches any region that contains 
	all the Positions in, i.e. is a superset of, the given region. */
	
	INLINE CLIENT RPTR(Filter) allFilter (APTR(XnRegion) ARG(region));
	
	/* Essential. A filter that matches any region that 
	intersects the given region. */
	
	INLINE CLIENT RPTR(Filter) anyFilter (APTR(XnRegion) ARG(baseRegion));
	
	/* Essential. A filter that matches any region that 
	intersects the given region. */
	
	INLINE RPTR(Filter) intersectionFilter (APTR(XnRegion) ARG(region));
	
	/* A filter matching any regions that is not a subset of the 
	given region. */
	
	INLINE RPTR(Filter) notSubsetFilter (APTR(XnRegion) ARG(region));
	
	/* A filter that matches any region that is not a superset of 
	the given region. */
	
	INLINE RPTR(Filter) notSupersetFilter (APTR(XnRegion) ARG(region));
	
	/* A filter that matches any region that any of the filters 
	in the set would have matched. */
	
	INLINE RPTR(Filter) orFilter (APTR(ScruSet) OF1(Filter) ARG(subs));
	
	/* Essential. Given a Region in the baseSpace, make a 
	Position which corresponds to it, so that
			filter->hasMember (this->position (baseRegion)) iff 
	filter->match (baseRegion) */
	
	INLINE CLIENT RPTR(FilterPosition) position (APTR(XnRegion) ARG(baseRegion));
	
	/* A filter that matches any region that is a subset of the 
	given region. */
	
	INLINE RPTR(Filter) subsetFilter (APTR(XnRegion) ARG(region));
	
	/* Essential. A region that matches any region that is a 
	superset of the given region. */
	
	INLINE RPTR(Filter) supersetFilter (APTR(XnRegion) ARG(region));
	
  public: /* hooks: */

	
	virtual SEND_HOOK void sendFilterSpaceTo (APTR(Xmtr) ARG(xmtr));
	
  private:
	CHKPTR(CoordinateSpace) myBaseSpace;
};  /* end class FilterSpace */



/* ************************************************************************ *
 * 
 *                    Class Joint 
 *
 * ************************************************************************ */




	/* Joints are used to prune searches through trees of 
	Regions. Each Joint summarizes the Joints and Regions at its 
	node and its children using their intersection and union. If 
	you maintain this information at each each node in the tree, 
	then you can search for Regions in the tree efficiently using 
	Filter::pass() to adapt the search criteria to the contents 
	of the subtree. See also Filter::pass(Joint *). */

class Joint : public Heaper {

/* Attributes for class Joint */
	CONCRETE(Joint)
	COPY(Joint,XppCuisine)
	AUTO_GC(Joint)
  public: /* pseudo constructors */

	/* An empty Joint in the given coordinate space. */
	
	static RPTR(Joint) make (APTR(CoordinateSpace) ARG(space));
	
	/* A joint that is a parent of the two given Joints. */
	
	static RPTR(Joint) make (APTR(Joint) ARG(left), APTR(Joint) ARG(right));
	
	/* A Joint that is a parent of all of the Joints in the set. */
	
	static RPTR(Joint) make (APTR(ScruSet) OF1(Joint) ARG(subs));
	
	/* A Joint containing only the given region. */
	
	static RPTR(Joint) make (APTR(XnRegion) ARG(both));
	
	/* A Joint with the given union and intersection regions. */
	
	static RPTR(Joint) make (APTR(XnRegion) ARG(unioned), APTR(XnRegion) ARG(intersected));
	
  public: /* creation */

	
	Joint (APTR(XnRegion) ARG(unioned), APTR(XnRegion) ARG(intersected));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* accessing */

	/* The intersection of the regions at all child nodes in the tree. */
	
	INLINE RPTR(XnRegion) intersected ();
	
	/* A Joint that is a parent of this Joint and the given one. */
	
	INLINE RPTR(Joint) join (APTR(Joint) ARG(other));
	
	/* The union of the regions at all child nodes in the tree. */
	
	INLINE RPTR(XnRegion) unioned ();
	
	/* A Joint that is a parent of this one and the given region. */
	
	virtual RPTR(Joint) with (APTR(XnRegion) ARG(region));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  private:
	CHKPTR(XnRegion) myUnioned;
	CHKPTR(XnRegion) myIntersected;
};  /* end class Joint */



/* ************************************************************************ *
 * 
 *                    Class RegionDelta 
 *
 * ************************************************************************ */




	/* A RegionDelta represents a change in the state of a 
	Region, holding the state before and after some change. They 
	are in some sense complementary to Joints: In the same way 
	that you can use Filters to examine Joints, you can use 
	RegionDeltas to examine Filters. See also 
	Filter::isSwitchedBy(RegionDelta *) and related methods. */

class RegionDelta : public Heaper {

/* Attributes for class RegionDelta */
	CONCRETE(RegionDelta)
	COPY(RegionDelta,XppCuisine)
	AUTO_GC(RegionDelta)
  public: /* pseudo constructors */

	
	static RPTR(RegionDelta) make (APTR(XnRegion) ARG(before), APTR(XnRegion) ARG(after));
	
  public: /* creation */

	
	RegionDelta (APTR(XnRegion) ARG(before), APTR(XnRegion) ARG(after));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	/* if the before and after are the same */
	
	INLINE BooleanVar isSame ();
	
  public: /* accessing */

	/* The region after the change. */
	
	INLINE RPTR(XnRegion) after ();
	
	/* The region before the change. */
	
	INLINE RPTR(XnRegion) before ();
	
  private:
	CHKPTR(XnRegion) myBefore;
	CHKPTR(XnRegion) myAfter;
};  /* end class RegionDelta */


#ifdef USE_INLINE
#ifndef FILTERX_IXX
#include "filterx.ixx"
#endif /* FILTERX_IXX */


#endif /* USE_INLINE */


#endif /* FILTERX_HXX */

