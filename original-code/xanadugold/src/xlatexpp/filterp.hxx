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

#ifndef FILTERP_HXX
#define FILTERP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef FILTERX_HXX
#include "filterx.hxx"
#endif /* FILTERX_HXX */

#ifndef FILTERP_OXX
#include "filterp.oxx"
#endif /* FILTERP_OXX */


#ifndef SPACER_HXX
#include "spacer.hxx"
#endif /* SPACER_HXX */


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




/* ************************************************************************ *
 * 
 *                    Class AndFilter 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class AndFilter : public Filter {

/* Attributes for class AndFilter */
	CONCRETE(AndFilter)
	NOT_A_TYPE(AndFilter)
	COPY(AndFilter,XppCuisine)
	AUTO_GC(AndFilter)
  public: /* pseudo constructors */

	/* assumes that the interactions between elements have 
	already been removed */
	
	static RPTR(Filter) make (APTR(FilterSpace) ARG(cs), APTR(ImmuSet) OF1(Filter) ARG(subs));
	
  public: /* creation */

	
	AndFilter (APTR(FilterSpace) ARG(cs), APTR(ImmuSet) OF1(Filter) ARG(subs));
	
  public: /* filtering */

	/* tell whether a region passes this filter */
	
	virtual BooleanVar match (APTR(XnRegion) ARG(region));
	
	/* return the simplest filter for looking at the children */
	
	virtual RPTR(Filter) pass (APTR(Joint) ARG(parent));
	
	
	virtual RPTR(ImmuSet) OF1(Filter) subFilters ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isAllFilter ();
	
	
	virtual BooleanVar isAnyFilter ();
	
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFull ();
	
  public: /* operations */

	
	virtual RPTR(XnRegion) complement ();
	
  public: /* protected operations */

	/* return self or other if one is clearly a subset of the 
	other, else NULL */
	
	virtual RPTR(XnRegion) fetchSpecialSubset (APTR(XnRegion) ARG(other));
	
  public: /* enumerating */

	
	virtual RPTR(Stepper) OF1(Filter) intersectedFilters ();
	
	
	virtual RPTR(Stepper) OF1(Filter) unionedFilters ();
	
  public: /* accessing */

	
	virtual RPTR(XnRegion) baseRegion ();
	
	
	virtual RPTR(XnRegion) relevantRegion ();
	
  private:
	CHKPTR(ImmuSet) OF1(Filter) mySubFilters;
	friend class Filter;
};  /* end class AndFilter */



/* ************************************************************************ *
 * 
 *                    Class ClosedFilter 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ClosedFilter : public Filter {

/* Attributes for class ClosedFilter */
	CONCRETE(ClosedFilter)
	NOT_A_TYPE(ClosedFilter)
	COPY(ClosedFilter,XppCuisine)
	NO_GC(ClosedFilter)
  public: /* pseudo constructors */

	
	static RPTR(Filter) make (APTR(CoordinateSpace) ARG(space));
	
  public: /* creation */

	
	ClosedFilter (APTR(FilterSpace) ARG(cs), TCSJ);
	
  public: /* operations */

	
	virtual RPTR(XnRegion) complement ();
	
	
	virtual RPTR(XnRegion) intersect (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) minus (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) unionWith (APTR(XnRegion) ARG(other));
	
  public: /* filtering */

	/* tell whether a region passes this filter */
	
	virtual BooleanVar match (APTR(XnRegion) ARG(region));
	
	/* return the simplest filter for looking at the children */
	
	virtual RPTR(Filter) pass (APTR(Joint) ARG(parent));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isAllFilter ();
	
	
	virtual BooleanVar isAnyFilter ();
	
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isEnumerable (APTR(OrderSpec) ARG(order) = NULL);
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFull ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  protected: /* protected: protected operations */

	
	virtual RPTR(XnRegion) fetchSpecialSubset (APTR(XnRegion) ARG(other));
	
  protected: /* protected: enumerating */

	
	virtual RPTR(Stepper) OF1(Position) actualStepper (APTR(OrderSpec) ARG(order));
	
  public: /* enumerating */

	
	virtual RPTR(Stepper) OF1(Filter) intersectedFilters ();
	
	
	virtual RPTR(Stepper) OF1(Filter) unionedFilters ();
	
  public: /* accessing */

	
	virtual RPTR(XnRegion) baseRegion ();
	
	
	virtual RPTR(XnRegion) relevantRegion ();
	

	friend class Filter;
};  /* end class ClosedFilter */



/* ************************************************************************ *
 * 
 *                    Class FilterDsp 
 *
 * ************************************************************************ */



/* Initializers for FilterDsp */

	/* There are no non-trivial Dsps currently defined on a FilterSpace.
	
	It would be possible to define them with reference to a Dsp 
	in the baseSpace, as
		filterDsp->of(filter)->match(R) iff filter->match(filterDsp->
	baseDsp()->inverseOf(R))
			for all R in the base space.
	However, we have not yet found a use for them. */

class FilterDsp : public IdentityDsp {

/* Attributes for class FilterDsp */
	CONCRETE(FilterDsp)
	COPY(FilterDsp,XppCuisine)
	AUTO_GC(FilterDsp)

/* Initializers for FilterDsp */  public: /* pseudo constructors */

	/* An identity Dsp on the given FilterSpace. */
	
	static RPTR(FilterDsp) make (APTR(FilterSpace) ARG(cs));
	
  public: /* creation */

	
	FilterDsp (APTR(CoordinateSpace) ARG(cs), TCSJ);
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
  private:
	CHKPTR(FilterSpace) myCS;

  /* ---------- Static Member variables (class inst vars) ----------- */
  private:
	static IdentityDsp * theDsp;
};  /* end class FilterDsp */



/* ************************************************************************ *
 * 
 *                    Class NotSubsetFilter 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class NotSubsetFilter : public Filter {

/* Attributes for class NotSubsetFilter */
	CONCRETE(NotSubsetFilter)
	NOT_A_TYPE(NotSubsetFilter)
	COPY(NotSubsetFilter,XppCuisine)
	AUTO_GC(NotSubsetFilter)
  public: /* filtering */

	/* tell whether a region passes this filter */
	
	virtual BooleanVar match (APTR(XnRegion) ARG(region));
	
	/* return the simplest filter for looking at the children */
	
	virtual RPTR(Filter) pass (APTR(Joint) ARG(parent));
	
	
	virtual RPTR(XnRegion) region ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isAllFilter ();
	
	
	virtual BooleanVar isAnyFilter ();
	
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFull ();
	
  public: /* operations */

	
	virtual RPTR(XnRegion) complement ();
	
  public: /* creation */

	
	NotSubsetFilter (APTR(FilterSpace) ARG(cs), APTR(XnRegion) ARG(region));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* protected operations */

	
	virtual RPTR(XnRegion) fetchSpecialIntersect (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) fetchSpecialSubset (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) fetchSpecialUnion (APTR(XnRegion) ARG(other));
	
  public: /* enumerating */

	
	virtual RPTR(Stepper) OF1(Filter) intersectedFilters ();
	
	
	virtual RPTR(Stepper) OF1(Filter) unionedFilters ();
	
  public: /* accessing */

	
	virtual RPTR(XnRegion) baseRegion ();
	
	
	virtual RPTR(XnRegion) relevantRegion ();
	
  private:
	CHKPTR(XnRegion) myRegion;
	friend class Filter;
};  /* end class NotSubsetFilter */



/* ************************************************************************ *
 * 
 *                    Class NotSupersetFilter 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class NotSupersetFilter : public Filter {

/* Attributes for class NotSupersetFilter */
	CONCRETE(NotSupersetFilter)
	NOT_A_TYPE(NotSupersetFilter)
	COPY(NotSupersetFilter,XppCuisine)
	AUTO_GC(NotSupersetFilter)
  public: /* filtering */

	/* tell whether a region passes this filter */
	
	virtual BooleanVar match (APTR(XnRegion) ARG(region));
	
	/* return the simplest filter for looking at the children */
	
	virtual RPTR(Filter) pass (APTR(Joint) ARG(parent));
	
	
	virtual RPTR(XnRegion) region ();
	
  public: /* operations */

	
	virtual RPTR(XnRegion) complement ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isAllFilter ();
	
	
	virtual BooleanVar isAnyFilter ();
	
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFull ();
	
  public: /* creation */

	
	NotSupersetFilter (APTR(FilterSpace) ARG(cs), APTR(XnRegion) ARG(region));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* protected operations */

	/* return NULL, or the pair of canonical filters (left == 
	new1 | self, right == new2 | other) */
	
	virtual RPTR(Pair) OF1(Filter) fetchCanonicalIntersect (APTR(Filter) ARG(other));
	
	/* return NULL, or the pair of canonical filters (left == 
	new1 | self, right == new2 | other) */
	
	virtual RPTR(Pair) OF1(Filter) fetchCanonicalUnion (APTR(Filter) ARG(other));
	
	
	virtual RPTR(XnRegion) fetchSpecialIntersect (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) fetchSpecialSubset (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) fetchSpecialUnion (APTR(XnRegion) ARG(other));
	
  public: /* enumerating */

	
	virtual RPTR(Stepper) OF1(Filter) intersectedFilters ();
	
	
	virtual RPTR(Stepper) OF1(Filter) unionedFilters ();
	
  public: /* accessing */

	
	virtual RPTR(XnRegion) baseRegion ();
	
	
	virtual RPTR(XnRegion) relevantRegion ();
	
  private:
	CHKPTR(XnRegion) myRegion;
	friend class Filter;
};  /* end class NotSupersetFilter */



/* ************************************************************************ *
 * 
 *                    Class OpenFilter 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class OpenFilter : public Filter {

/* Attributes for class OpenFilter */
	CONCRETE(OpenFilter)
	NOT_A_TYPE(OpenFilter)
	COPY(OpenFilter,XppCuisine)
	NO_GC(OpenFilter)
  public: /* pseudo constructors */

	
	static RPTR(Filter) make (APTR(CoordinateSpace) ARG(space));
	
  public: /* operations */

	
	virtual RPTR(XnRegion) complement ();
	
	
	virtual RPTR(XnRegion) intersect (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) minus (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) unionWith (APTR(XnRegion) ARG(other));
	
  public: /* filtering */

	/* tell whether a region passes this filter */
	
	virtual BooleanVar match (APTR(XnRegion) ARG(region));
	
	/* return the simplest filter for looking at the children */
	
	virtual RPTR(Filter) pass (APTR(Joint) ARG(parent));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isAllFilter ();
	
	
	virtual BooleanVar isAnyFilter ();
	
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFull ();
	
  public: /* creation */

	
	OpenFilter (APTR(FilterSpace) ARG(cs), TCSJ);
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  protected: /* protected: protected operations */

	
	virtual RPTR(XnRegion) fetchSpecialSubset (APTR(XnRegion) ARG(other));
	
  public: /* enumerating */

	
	virtual RPTR(Stepper) OF1(Filter) intersectedFilters ();
	
	
	virtual RPTR(Stepper) OF1(Filter) unionedFilters ();
	
  public: /* accessing */

	
	virtual RPTR(XnRegion) baseRegion ();
	
	
	virtual RPTR(XnRegion) relevantRegion ();
	

	friend class Filter;
};  /* end class OpenFilter */



/* ************************************************************************ *
 * 
 *                    Class OrFilter 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class OrFilter : public Filter {

/* Attributes for class OrFilter */
	CONCRETE(OrFilter)
	NOT_A_TYPE(OrFilter)
	COPY(OrFilter,XppCuisine)
	AUTO_GC(OrFilter)
  public: /* creation */

	
	OrFilter (APTR(FilterSpace) ARG(cs), APTR(ImmuSet) OF1(Filter) ARG(subs));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isAllFilter ();
	
	
	virtual BooleanVar isAnyFilter ();
	
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFull ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* operations */

	
	virtual RPTR(XnRegion) complement ();
	
  public: /* filtering */

	/* tell whether a region passes this filter */
	
	virtual BooleanVar match (APTR(XnRegion) ARG(region));
	
	/* return the simplest filter for looking at the children */
	
	virtual RPTR(Filter) pass (APTR(Joint) ARG(parent));
	
	
	virtual RPTR(ImmuSet) OF1(Filter) subFilters ();
	
  protected: /* protected: protected operations */

	/* return self or other if one is clearly a subset of the 
	other, else NULL */
	
	virtual RPTR(XnRegion) fetchSpecialSubset (APTR(XnRegion) ARG(other));
	
  public: /* enumerating */

	
	virtual RPTR(Stepper) OF1(Filter) intersectedFilters ();
	
	
	virtual RPTR(Stepper) OF1(Filter) unionedFilters ();
	
  public: /* accessing */

	
	virtual RPTR(XnRegion) baseRegion ();
	
	
	virtual RPTR(XnRegion) relevantRegion ();
	
  private:
	CHKPTR(ImmuSet) OF1(Filter) mySubFilters;
	friend class Filter;
};  /* end class OrFilter */



/* ************************************************************************ *
 * 
 *                    Class SubsetFilter 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class SubsetFilter : public Filter {

/* Attributes for class SubsetFilter */
	CONCRETE(SubsetFilter)
	NOT_A_TYPE(SubsetFilter)
	COPY(SubsetFilter,XppCuisine)
	AUTO_GC(SubsetFilter)
  public: /* creation */

	
	SubsetFilter (APTR(FilterSpace) ARG(cs), APTR(XnRegion) ARG(region));
	
  public: /* operations */

	
	virtual RPTR(XnRegion) complement ();
	
  public: /* filtering */

	/* tell whether a region passes this filter */
	
	virtual BooleanVar match (APTR(XnRegion) ARG(region));
	
	/* return the simplest filter for looking at the children */
	
	virtual RPTR(Filter) pass (APTR(Joint) ARG(parent));
	
	
	virtual RPTR(XnRegion) region ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isAllFilter ();
	
	
	virtual BooleanVar isAnyFilter ();
	
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFull ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  protected: /* protected: protected operations */

	
	virtual RPTR(XnRegion) fetchSpecialUnion (APTR(XnRegion) ARG(other));
	
  public: /* protected operations */

	
	virtual RPTR(XnRegion) fetchSpecialIntersect (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) fetchSpecialSubset (APTR(XnRegion) ARG(other));
	
  public: /* enumerating */

	
	virtual RPTR(Stepper) OF1(Filter) intersectedFilters ();
	
	
	virtual RPTR(Stepper) OF1(Filter) unionedFilters ();
	
  public: /* accessing */

	
	virtual RPTR(XnRegion) baseRegion ();
	
	
	virtual RPTR(XnRegion) relevantRegion ();
	
  private:
	CHKPTR(XnRegion) myRegion;
	friend class Filter;
};  /* end class SubsetFilter */



/* ************************************************************************ *
 * 
 *                    Class SupersetFilter 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class SupersetFilter : public Filter {

/* Attributes for class SupersetFilter */
	CONCRETE(SupersetFilter)
	NOT_A_TYPE(SupersetFilter)
	COPY(SupersetFilter,XppCuisine)
	AUTO_GC(SupersetFilter)
  public: /* filtering */

	/* tell whether a region passes this filter */
	
	virtual BooleanVar match (APTR(XnRegion) ARG(region));
	
	/* return the simplest filter for looking at the children */
	
	virtual RPTR(Filter) pass (APTR(Joint) ARG(parent));
	
	
	virtual RPTR(XnRegion) region ();
	
  public: /* operations */

	
	virtual RPTR(XnRegion) complement ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isAllFilter ();
	
	
	virtual BooleanVar isAnyFilter ();
	
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFull ();
	
  protected: /* protected: protected operations */

	
	virtual RPTR(XnRegion) fetchSpecialUnion (APTR(XnRegion) ARG(other));
	
  public: /* creation */

	
	SupersetFilter (APTR(FilterSpace) ARG(cs), APTR(XnRegion) ARG(region));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* protected operations */

	/* return NULL, or the pair of canonical filters (left == 
	new1 | self, right == new2 | other) */
	
	virtual RPTR(Pair) OF1(Filter) fetchCanonicalUnion (APTR(Filter) ARG(other));
	
	
	virtual RPTR(XnRegion) fetchSpecialIntersect (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) fetchSpecialSubset (APTR(XnRegion) ARG(other));
	
  public: /* enumerating */

	
	virtual RPTR(Stepper) OF1(Filter) intersectedFilters ();
	
	
	virtual RPTR(Stepper) OF1(Filter) unionedFilters ();
	
  public: /* accessing */

	
	virtual RPTR(XnRegion) baseRegion ();
	
	
	virtual RPTR(XnRegion) relevantRegion ();
	
  private:
	CHKPTR(XnRegion) myRegion;
	friend class Filter;
};  /* end class SupersetFilter */



#endif /* FILTERP_HXX */

