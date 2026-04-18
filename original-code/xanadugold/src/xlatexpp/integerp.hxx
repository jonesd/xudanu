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

#ifndef INTEGERP_HXX
#define INTEGERP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef INTEGERP_OXX
#include "integerp.oxx"
#endif /* INTEGERP_OXX */


#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */


#ifndef CACHEX_OXX
#include "cachex.oxx"
#endif /* CACHEX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class AscendingIntegerStepper 
 *
 * ************************************************************************ */



/* Initializers for AscendingIntegerStepper */







	/* NO CLASS COMMENT */

class AscendingIntegerStepper : public Stepper {

/* Attributes for class AscendingIntegerStepper */
	CONCRETE(AscendingIntegerStepper)
	NOT_A_TYPE(AscendingIntegerStepper)
	AUTO_GC(AscendingIntegerStepper)

/* Initializers for AscendingIntegerStepper */



friend class INIT_TIME_NAME(AscendingIntegerStepper,initTimeNonInherited);

  public: /* creation */

	
	static RPTR(Stepper) make (APTR(IntegerVarArray) ARG(edges), UInt32 ARG(count));
	
  protected: /* protected: creation */

	
	AscendingIntegerStepper (APTR(IntegerVarArray) ARG(edges), UInt32 ARG(count));
	
	
	AscendingIntegerStepper (
			APTR(IntegerVarArray) ARG(edges), 
			UInt32 ARG(index), 
			UInt32 ARG(count), 
			IntegerVar ARG(position))
	;
	
  public: /* creation */

	
	virtual RPTR(Stepper) copy ();
	
	
	virtual void destroy ();
	
  public: /* accessing */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  private:
	CHKPTR(IntegerVarArray) myEdges;
	UInt32 myIndex;
	UInt32 myCount;
	IntegerVar myPosition;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(InstanceCache) SomeSteppers;
};  /* end class AscendingIntegerStepper */



/* ************************************************************************ *
 * 
 *                    Class DescendingIntegerStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class DescendingIntegerStepper : public Stepper {

/* Attributes for class DescendingIntegerStepper */
	CONCRETE(DescendingIntegerStepper)
	NOT_A_TYPE(DescendingIntegerStepper)
	AUTO_GC(DescendingIntegerStepper)
  public: /* creation */

	
	static RPTR(Stepper) make (APTR(IntegerVarArray) ARG(edges), UInt32 ARG(count));
	
  protected: /* protected: create */

	
	DescendingIntegerStepper (APTR(IntegerVarArray) ARG(edges), UInt32 ARG(count));
	
	
	DescendingIntegerStepper (
			APTR(IntegerVarArray) ARG(edges), 
			Int32 ARG(index), 
			IntegerVar ARG(position))
	;
	
  public: /* creation */

	
	virtual RPTR(Stepper) copy ();
	
  public: /* accessing */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  private:
	CHKPTR(IntegerVarArray) myEdges;
	Int32 myIndex;
	IntegerVar myPosition;
};  /* end class DescendingIntegerStepper */



/* ************************************************************************ *
 * 
 *                    Class IntegerArrangement 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class IntegerArrangement : public Arrangement {

/* Attributes for class IntegerArrangement */
	CONCRETE(IntegerArrangement)
	COPY(IntegerArrangement,XppCuisine)
	AUTO_GC(IntegerArrangement)
  public: /* creation */

	
	static RPTR(IntegerArrangement) make (APTR(XnRegion) ARG(region), APTR(OrderSpec) ARG(ordering));
	
  public: /* accessing */

	
	virtual void copyElements (
			APTR(PrimArray) ARG(toArray), 
			APTR(Dsp) ARG(toDsp), 
			APTR(PrimArray) ARG(fromArray), 
			APTR(Arrangement) ARG(fromArrange), 
			APTR(XnRegion) ARG(fromRegion))
	;
	
	/* Return the index of position into my Region according to 
	my OrderSpec. */
	
	virtual IntegerVar indexOf (APTR(Position) ARG(position));
	
	/* Return the region of all the indices corresponding to 
	positions in region. */
	
	virtual RPTR(IntegerRegion) indicesOf (APTR(XnRegion) ARG(region));
	
	/* Return the region that corresponds to a range of indices. */
	
	virtual RPTR(XnRegion) keysOf (Int32 ARG(start), Int32 ARG(stop));
	
	
	virtual RPTR(OrderSpec) ordering ();
	
	
	virtual RPTR(XnRegion) region ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  protected: /* protected: creation */

	
	IntegerArrangement (APTR(XnRegion) ARG(region), APTR(OrderSpec) ARG(ordering));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual UInt32 hashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  private:
	CHKPTR(OrderSpec) myOrdering;
	CHKPTR(IntegerRegion) myRegion;
};  /* end class IntegerArrangement */



/* ************************************************************************ *
 * 
 *                    Class IntegerEdgeAccumulator 
 *
 * ************************************************************************ */



/* Initializers for IntegerEdgeAccumulator */







	/* NO CLASS COMMENT */

class IntegerEdgeAccumulator : public Accumulator {

/* Attributes for class IntegerEdgeAccumulator */
	CONCRETE(IntegerEdgeAccumulator)
	AUTO_GC(IntegerEdgeAccumulator)

/* Initializers for IntegerEdgeAccumulator */



friend class INIT_TIME_NAME(IntegerEdgeAccumulator,initTimeNonInherited);

  public: /* creation */

	
	static RPTR(IntegerEdgeAccumulator) make (BooleanVar ARG(startsInside), UInt32 ARG(count));
	
  protected: /* protected: creation */

	
	IntegerEdgeAccumulator (BooleanVar ARG(startsInside), UInt32 ARG(count));
	
	
	IntegerEdgeAccumulator (
			BooleanVar ARG(startsInside), 
			APTR(IntegerVarArray) ARG(edges), 
			UInt32 ARG(index), 
			BooleanVar ARG(hasPending), 
			IntegerVar ARG(pending))
	;
	
  public: /* creation */

	
	virtual RPTR(Accumulator) copy ();
	
	
	virtual void destroy ();
	
  public: /* operations */

	
	virtual void step (APTR(Heaper) ARG(someObj));
	
	
	virtual RPTR(Heaper) value ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* edge operations */

	/* add a transition at the given position. doing it again 
	cancels it.  This particular coding is used for C++ inlinability */
	
	virtual void edge (IntegerVar ARG(x));
	
	/* add a whole bunch of edges at once, assuming that they are 
	sorted and there are no duplicates */
	
	virtual void edges (APTR(IntegerEdgeStepper) ARG(stepper));
	
	/* make a region out of the accumulated edges */
	
	virtual RPTR(IntegerRegion) region ();
	
  private:
	BooleanVar myStartsInside;
	CHKPTR(IntegerVarArray) myEdges;
	UInt32 myIndex;
	BooleanVar havePending;
	IntegerVar myPending;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(InstanceCache) SomeAccumulators;
};  /* end class IntegerEdgeAccumulator */



/* ************************************************************************ *
 * 
 *                    Class IntegerEdgeStepper 
 *
 * ************************************************************************ */



/* Initializers for IntegerEdgeStepper */







	/* A single instance of this class is cached.  To take 
	advantage of this, a method
	that uses IntegerEdgeSteppers should explicitly destroy at 
	least one of them. */

class IntegerEdgeStepper : public Stepper {

/* Attributes for class IntegerEdgeStepper */
	CONCRETE(IntegerEdgeStepper)
	AUTO_GC(IntegerEdgeStepper)

/* Initializers for IntegerEdgeStepper */



friend class INIT_TIME_NAME(IntegerEdgeStepper,initTimeNonInherited);

  public: /* errors */

	
	static void outOfBounds ();
	
  public: /* create */

	
	static RPTR(IntegerEdgeStepper) make (
			BooleanVar ARG(entering), 
			UInt32 ARG(count), 
			APTR(IntegerVarArray) ARG(edges))
	;
	
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	INLINE BooleanVar hasValue ();
	
	
	INLINE void step ();
	
  public: /* edge accessing */

	/* the current transition */
	
	INLINE IntegerVar edge ();
	
	/* whether the current transition is entering or leaving the set */
	
	INLINE BooleanVar isEntering ();
	
  protected: /* protected: create */

	
	IntegerEdgeStepper (
			BooleanVar ARG(entering), 
			UInt32 ARG(count), 
			APTR(IntegerVarArray) ARG(edges))
	;
	
	
	IntegerEdgeStepper (
			BooleanVar ARG(entering), 
			UInt32 ARG(index), 
			UInt32 ARG(count), 
			APTR(IntegerVarArray) ARG(edges))
	;
	
  public: /* destroy */

	
	virtual void destroy ();
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	BooleanVar myEntering;
	UInt32 myIndex;
	UInt32 myCount;
	CHKPTR(IntegerVarArray) myEdges;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(InstanceCache) SomeEdgeSteppers;
};  /* end class IntegerEdgeStepper */



/* ************************************************************************ *
 * 
 *                    Class IntegerSimpleRegionStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class IntegerSimpleRegionStepper : public Stepper {

/* Attributes for class IntegerSimpleRegionStepper */
	CONCRETE(IntegerSimpleRegionStepper)
	NOT_A_TYPE(IntegerSimpleRegionStepper)
	AUTO_GC(IntegerSimpleRegionStepper)
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* unprotected create */

	
	IntegerSimpleRegionStepper (
			APTR(IntegerVarArray) ARG(edges), 
			UInt32 ARG(count), 
			BooleanVar ARG(leftBounded))
	;
	
	
	IntegerSimpleRegionStepper (
			APTR(IntegerVarArray) ARG(edges), 
			UInt32 ARG(index), 
			UInt32 ARG(count), 
			BooleanVar ARG(leftBounded), 
			APTR(IntegerRegion) ARG(simple))
	;
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	CHKPTR(IntegerVarArray) myEdges;
	UInt32 myIndex;
	UInt32 myCount;
	BooleanVar isLeftBounded;
	CHKPTR(IntegerRegion) mySimple;
};  /* end class IntegerSimpleRegionStepper */



/* ************************************************************************ *
 * 
 *                    Class IntegerUpOrder 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class IntegerUpOrder : public OrderSpec {

/* Attributes for class IntegerUpOrder */
	CONCRETE(IntegerUpOrder)
	COPY(IntegerUpOrder,XppCuisine)
	NOT_A_TYPE(IntegerUpOrder)
	NO_GC(IntegerUpOrder)
  public: /* pseudoconstructors */

	
	static RPTR(OrderSpec) make ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar follows (APTR(Position) ARG(x), APTR(Position) ARG(y));
	
	/* See discussion in XuInteger class comment about boxed vs 
	unboxed integers */
	
	virtual BooleanVar followsInt (IntegerVar ARG(x), IntegerVar ARG(y));
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFullOrder (APTR(XnRegion) ARG(keys) = NULL);
	
	/* Return true if some position in before is less than or 
	equal to all positions in after. */
	
	virtual BooleanVar preceeds (APTR(XnRegion) ARG(before), APTR(XnRegion) ARG(after));
	
  public: /* accessing */

	
	virtual RPTR(Arrangement) arrange (APTR(XnRegion) ARG(region));
	
	/* Return the first n positions in the region according to my 
	ordering. */
	
	virtual RPTR(XnRegion) chooseMany (APTR(XnRegion) ARG(region), IntegerVar ARG(n));
	
	/* Return the first position in the region according to my ordering. */
	
	virtual RPTR(Position) chooseOne (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	

	/* automatic 0-argument constructor */
  public:
	IntegerUpOrder();

};  /* end class IntegerUpOrder */


#ifdef USE_INLINE
#ifndef INTEGERP_IXX
#include "integerp.ixx"
#endif /* INTEGERP_IXX */


#endif /* USE_INLINE */


#endif /* INTEGERP_HXX */

