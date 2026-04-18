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

#ifndef CROSSP_HXX
#define CROSSP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef CROSSX_HXX
#include "crossx.hxx"
#endif /* CROSSX_HXX */

#ifndef CROSSP_OXX
#include "crossp.oxx"
#endif /* CROSSP_OXX */


#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */


#ifndef CACHEX_OXX
#include "cachex.oxx"
#endif /* CACHEX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class ActualTuple 
 *
 * ************************************************************************ */




	/* Default implementation of position in a crossed coordinate 
	space. NOT.A.TYPE */

class ActualTuple : public Tuple {

/* Attributes for class ActualTuple */
	CONCRETE(ActualTuple)
	COPY(ActualTuple,XppCuisine)
	AUTO_GC(ActualTuple)
  public: /* pseudoconstructors */

	
	static RPTR(Tuple) make (APTR(PtrArray) OF1(Position) ARG(coordinates));
	
  public: /* accessing */

	
	virtual RPTR(XnRegion) asRegion ();
	
	
	virtual RPTR(PtrArray) OF1(Position) coordinates ();
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual Int32 count ();
	
	
	virtual RPTR(Position) positionAt (Int32 ARG(dimension));
	
  public: /* comparing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  private: /* private: creation */

	
	ActualTuple (APTR(PtrArray) OF1(Position) ARG(coordinates), TCSJ);
	
  private: /* private: accessing */

	/* The internal array of coordinates. Do not modify this array! */
	
	virtual RPTR(PtrArray) OF1(Position) secretCoordinates ();
	
  private:
	CHKPTR(PtrArray) OF1(Position) myCoordinates;
/* Friends for class ActualTuple */
friend class GenericCrossDsp;



};  /* end class ActualTuple */



/* ************************************************************************ *
 * 
 *                    Class BoxAccumulator 
 *
 * ************************************************************************ */



/* Initializers for BoxAccumulator */







	/* was NOT.A.TYPE but this prevented compilation  */

class BoxAccumulator : public Accumulator {

/* Attributes for class BoxAccumulator */
	CONCRETE(BoxAccumulator)
	AUTO_GC(BoxAccumulator)

/* Initializers for BoxAccumulator */



friend class INIT_TIME_NAME(BoxAccumulator,initTimeNonInherited);

  public: /* creation */

	
	static RPTR(BoxAccumulator) make (APTR(GenericCrossRegion) ARG(region));
	
	
	static RPTR(BoxAccumulator) make (APTR(CrossSpace) ARG(space), Int32 ARG(expectedBoxCount));
	
  public: /* creation */

	
	virtual RPTR(Accumulator) copy ();
	
  protected: /* protected: creation */

	
	BoxAccumulator (APTR(GenericCrossRegion) ARG(region), TCSJ);
	
	
	BoxAccumulator (APTR(CrossSpace) ARG(space), Int32 ARG(expectedBoxCount));
	
	
	BoxAccumulator (
			APTR(CrossSpace) ARG(space), 
			APTR(PtrArray) OF1(XnRegion) ARG(regions), 
			Int32 ARG(expectedBoxCount))
	;
	
  private: /* private: */

	/* Make sure there is room to add a box */
	
	virtual void aboutToAdd ();
	
	/* Add a new box which is just like a current one except for 
	the projection on one dimension. Return its index */
	
	virtual Int32 addSubstitutedBox (
			Int32 ARG(current), 
			Int32 ARG(dimension), 
			APTR(XnRegion) ARG(newRegion))
	;
	
	
	virtual Int32 boxCount ();
	
	/* Change a projection of a box */
	
	virtual RPTR(XnRegion) boxProjection (Int32 ARG(box), Int32 ARG(dimension));
	
	/* Mark a box as deleted */
	
	virtual void deleteBox (Int32 ARG(box));
	
	/* Take my box at added
			and distribute it over my existing boxes from start to stop - 1
			meanwhile taking pieces out of my box at remainder
				and delete it if it becomes empty
		Return true if there is still something left in the remainder */
	
	virtual BooleanVar distributeUnion (
			Int32 ARG(added), 
			Int32 ARG(start), 
			Int32 ARG(stop))
	;
	
	
	virtual Int32 index ();
	
	/* Whether the box has been deleted */
	
	virtual BooleanVar isDeleted (Int32 ARG(box));
	
	
	virtual RPTR(PtrArray) OF1(XnRegion) secretRegions ();
	
	/* Take my box at added
			and union it with my box at current
			delete it if it becomes empty
		Return true if there is still something left in the added box */
	
	virtual BooleanVar splitUnion (
			Int32 ARG(added), 
			Int32 ARG(current), 
			Int32 ARG(stop))
	;
	
	/* Change a projection of a box */
	
	virtual void storeBoxProjection (
			Int32 ARG(box), 
			Int32 ARG(dimension), 
			APTR(XnRegion) ARG(region))
	;
	
	/* If two boxes differ by only one projection, union the 
	second into the first and delete the second */
	
	virtual void tryMergeBoxes (Int32 ARG(i), Int32 ARG(j));
	
  public: /* operations */

	/* Add in all the boxes in another accumulator */
	
	virtual void addAccumulatedBoxes (APTR(BoxAccumulator) ARG(other));
	
	/* Add the current box to the end of the array */
	
	virtual Int32 addBox (APTR(BoxStepper) ARG(box));
	
	/* Add the current box, transformed by the inverse of the dsp */
	
	virtual void addInverseTransformedBox (APTR(BoxStepper) ARG(box), APTR(GenericCrossDsp) ARG(dsp));
	
	/* Add a box to the end of the array */
	
	virtual Int32 addProjections (APTR(PtrArray) OF1(XnRegion) ARG(projections), Int32 ARG(boxIndex));
	
	/* Add the current box, transformed by the dsp */
	
	virtual void addTransformedBox (APTR(BoxStepper) ARG(box), APTR(GenericCrossDsp) ARG(dsp));
	
	/* Intersect the current region with a box. May leave the 
	result uncanonicalized */
	
	virtual void intersectWithBox (APTR(BoxStepper) ARG(box));
	
	/* merge boxes which differ in only one projection */
	
	virtual void mergeBoxes ();
	
	/* The current region in the accumulator. CLIENT MUST KNOW 
	THAT IT IS CANONICAL */
	
	virtual RPTR(XnRegion) region ();
	
	/* Remove boxes which have been deleted */
	
	virtual void removeDeleted ();
	
	
	virtual void step (APTR(Heaper) ARG(someObj));
	
	/* Add the current box to the accumulator */
	
	virtual void unionWithBox (APTR(BoxStepper) ARG(box));
	
	/* Add a sequence of disjoint boxes to the accumulator */
	
	virtual void unionWithBoxes (APTR(BoxStepper) ARG(boxes));
	
	
	virtual RPTR(Heaper) value ();
	
  private:
	CHKPTR(CrossSpace) mySpace;
	CHKPTR(PtrArray) OF1(XnRegion) myRegions;
	Int32 myIndex;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(InstanceCache) SomeAccumulators;
};  /* end class BoxAccumulator */



/* ************************************************************************ *
 * 
 *                    Class BoxProjectionStepper 
 *
 * ************************************************************************ */



/* Initializers for BoxProjectionStepper */







	/* Steps over all projections of some boxes. was not.a.type 
	but this prevented compilation */

class BoxProjectionStepper : public Stepper {

/* Attributes for class BoxProjectionStepper */
	CONCRETE(BoxProjectionStepper)
	AUTO_GC(BoxProjectionStepper)

/* Initializers for BoxProjectionStepper */



friend class INIT_TIME_NAME(BoxProjectionStepper,initTimeNonInherited);

  public: /* create */

	
	static RPTR(BoxProjectionStepper) make (APTR(GenericCrossRegion) ARG(region));
	
	
	static RPTR(BoxProjectionStepper) make (
			APTR(GenericCrossRegion) ARG(region), 
			Int32 ARG(boxIndex), 
			Int32 ARG(boxLimit))
	;
	
  public: /* create */

	/* Return a new stepper which steps independently of me, but 
	whose current 
		value is the same as mine, and which must produce a future 
	history of values 
		which satisfies the same obligation that my contract 
	obligates me to produce 
		now. Typically, this will mean that he must produce the same 
	future history 
		that I'm going to produce. However, let's say that I am 
	enumerating the 
		elements of a partial order in some full order which is 
	consistent with the 
		partial order. If a copy of me is made after I'm part way 
	through, then me 
		and my copy may produce any future history compatable both 
	with the partial 
		order and the elements I've already produced by the time of 
	the copy. Of 
		course, a subclass or a Stepper creating message (like 
		IntegerRegion::stepper()) may specify the more stringent 
	requirement (that a 
		copy must produce the same sequence). 
		
		To prevent aliasing, Steppers should typically be passed by 
	copy. See class 
		comment. */
	
	virtual RPTR(Stepper) copy ();
	
	
	virtual void destroy ();
	
  protected: /* protected: create */

	
	BoxProjectionStepper (APTR(GenericCrossRegion) ARG(region), TCSJ);
	
	
	BoxProjectionStepper (
			APTR(GenericCrossRegion) ARG(region), 
			Int32 ARG(boxIndex), 
			Int32 ARG(boxLimit))
	;
	
	
	BoxProjectionStepper (
			APTR(GenericCrossRegion) ARG(region), 
			Int32 ARG(boxIndex), 
			Int32 ARG(boxLimit), 
			Int32 ARG(dimension))
	;
	
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* accessing */

	
	virtual Int32 dimension ();
	
	
	virtual RPTR(XnRegion) projection ();
	
  private:
	CHKPTR(GenericCrossRegion) myRegion;
	Int32 myBoxIndex;
	Int32 myBoxLimit;
	Int32 myDimension;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(InstanceCache) SomeSteppers;
};  /* end class BoxProjectionStepper */



/* ************************************************************************ *
 * 
 *                    Class BoxStepper 
 *
 * ************************************************************************ */



/* Initializers for BoxStepper */







	/* Steps over all boxes. was NOT.A.TYPE but this prevented 
	compilation */

class BoxStepper : public Stepper {

/* Attributes for class BoxStepper */
	CONCRETE(BoxStepper)
	AUTO_GC(BoxStepper)

/* Initializers for BoxStepper */



friend class INIT_TIME_NAME(BoxStepper,initTimeNonInherited);

  public: /* create */

	
	static RPTR(BoxStepper) make (APTR(GenericCrossRegion) ARG(region));
	
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	virtual void destroy ();
	
  protected: /* protected: create */

	
	BoxStepper (APTR(GenericCrossRegion) ARG(region), TCSJ);
	
	
	BoxStepper (
			APTR(GenericCrossRegion) ARG(region), 
			Int32 ARG(index), 
			APTR(XnRegion) OR(NULL) ARG(value))
	;
	
  public: /* accessing */

	/* The complement of this box */
	
	virtual RPTR(GenericCrossRegion) boxComplement ();
	
	/* The complement of this box */
	
	virtual RPTR(BoxAccumulator) boxComplementAccumulator ();
	
	
	virtual UInt32 boxHash ();
	
	/* Whether my current box contains a position */
	
	virtual BooleanVar boxHasMember (APTR(ActualTuple) ARG(tuple));
	
	
	virtual Int32 boxIndex ();
	
	/* Whether my current box intersects others current box */
	
	virtual BooleanVar boxIntersects (APTR(BoxStepper) ARG(other));
	
	/* Whether my current box isEqual others current box */
	
	virtual BooleanVar boxIsEqual (APTR(BoxStepper) ARG(other));
	
	/* Whether my current box isSubsetOf others current box */
	
	virtual BooleanVar boxIsSubsetOf (APTR(BoxStepper) ARG(other));
	
	/* Intersect each projection in the box into the array. 
	Return false if the result is empty, stopping at the first 
	dimension for which the intersection is empty. */
	
	virtual BooleanVar intersectBoxInto (APTR(PtrArray) OF1(XnRegion) ARG(result), Int32 ARG(boxIndex));
	
	/* Whether my box is also a box in the other region */
	
	virtual BooleanVar isBoxOf (APTR(GenericCrossRegion) ARG(other));
	
	/* The projection of my current box into one dimension */
	
	virtual RPTR(XnRegion) projection (Int32 ARG(dimension));
	
	/* A stepper over all the projections in the current box */
	
	virtual RPTR(BoxProjectionStepper) projectionStepper ();
	
	
	virtual RPTR(GenericCrossRegion) region ();
	
	/* Union each projection in the box into the array */
	
	virtual void unionBoxInto (APTR(PtrArray) OF1(XnRegion) ARG(result), Int32 ARG(boxIndex));
	
  private:
	CHKPTR(GenericCrossRegion) myRegion;
	Int32 myIndex;
	CHKPTR(XnRegion) OR(NULL) myValue;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(InstanceCache) SomeSteppers;
};  /* end class BoxStepper */



/* ************************************************************************ *
 * 
 *                    Class GenericCrossDsp 
 *
 * ************************************************************************ */




	/*  Was NOT.A.TYPE but that obstructed compilation. */

class GenericCrossDsp : public CrossMapping {

/* Attributes for class GenericCrossDsp */
	CONCRETE(GenericCrossDsp)
	COPY(GenericCrossDsp,XppCuisine)
	AUTO_GC(GenericCrossDsp)
  private: /* private: pseudoconstructors */

	/* Only used during construction; must pass the array in 
	explicitly since the space isnt initialized yet */
	
	static RPTR(GenericCrossDsp) identity (APTR(GenericCrossSpace) ARG(space), APTR(PtrArray) OF1(CoordinateSpace) ARG(subSpaces));
	
  public: /* accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual BooleanVar isIdentity ();
	
	
	virtual RPTR(Dsp) subMapping (Int32 ARG(index));
	
	
	virtual RPTR(PtrArray) OF1(Dsp) subMappings ();
	
  private: /* private: creation */

	
	GenericCrossDsp (APTR(CrossSpace) ARG(space), APTR(PtrArray) OF1(Dsp) ARG(subDsps));
	
  public: /* transforming */

	
	virtual RPTR(Position) inverseOf (APTR(Position) ARG(position));
	
	
	virtual RPTR(XnRegion) inverseOfAll (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(Position) of (APTR(Position) ARG(position));
	
	
	virtual RPTR(XnRegion) ofAll (APTR(XnRegion) ARG(region));
	
  public: /* combining */

	
	virtual RPTR(Dsp) compose (APTR(Dsp) ARG(other));
	
	
	virtual RPTR(Mapping) inverse ();
	
	
	virtual RPTR(Dsp) inverseCompose (APTR(Dsp) ARG(other));
	
	
	virtual RPTR(Dsp) minus (APTR(Dsp) ARG(other));
	
  private: /* private: accessing */

	/* The actual array of sub Dsps. DO NOT MODIFY */
	
	virtual RPTR(PtrArray) OF1(Dsp) secretSubDsps ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  private:
	CHKPTR(CrossSpace) mySpace;
	CHKPTR(PtrArray) OF1(Dsp) mySubDsps;
/* Friends for class GenericCrossDsp */
friend class GenericCrossSpace;



	friend class CrossMapping;
	friend class Mapping;
};  /* end class GenericCrossDsp */



/* ************************************************************************ *
 * 
 *                    Class GenericCrossRegion 
 *
 * ************************************************************************ */




	/* Represents a region as a two-dimensional array of crosses 
	of subregions.
	 Was NOT.A.TYPE but that obstructed compilation.
	I think this might work better if the array is lexically 
	sorted, but I am not sure there is any meaningful way to do 
	so. Thus there is no sorting assumed in the algorithms, 
	although the protocol may occasionally suggest that there might be.
	
	Eventually this implementation may save space by using NULL 
	to represent repetitions of a sub region such that
		fetchBoxProjection (box, dim) == NULL
	only if
		box > 0
		&& boxProjection (box, dim)->isEqual (boxProjection (box - 1, dim))
		&& (dim == 0
			|| fetchBoxProjection (box, dim - 1) == NULL) */

class GenericCrossRegion : public CrossRegion {

/* Attributes for class GenericCrossRegion */
	CONCRETE(GenericCrossRegion)
	COPY(GenericCrossRegion,XppCuisine)
	AUTO_GC(GenericCrossRegion)
  private: /* private: pseudo constructors */

	
	static RPTR(CrossRegion) empty (APTR(GenericCrossSpace) ARG(space));
	
	/* Only used during construction; must pass the array in 
	explicitly since the space isnt initialized yet */
	
	static RPTR(CrossRegion) full (APTR(GenericCrossSpace) ARG(space), APTR(PtrArray) OF1(CoordinateSpace) ARG(subSpaces));
	
  public: /* create */

	
	static RPTR(GenericCrossRegion) make (
			APTR(CrossSpace) ARG(space), 
			Int32 ARG(count), 
			APTR(PtrArray) OF1(XnRegion) ARG(regions))
	;
	
  public: /* accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual IntegerVar count ();
	
	
	virtual RPTR(XnRegion) projection (Int32 ARG(index));
	
	
	virtual RPTR(PtrArray) OF1(XnRegion) projections ();
	
	
	virtual RPTR(Position) theOne ();
	
  protected: /* protected: */

	
	virtual RPTR(CrossSpace) crossSpace ();
	
  private: /* private: */

	
	virtual Int32 boxCount ();
	
	/* A region is at a given 2D place in the array */
	
	virtual RPTR(XnRegion) boxProjection (Int32 ARG(box), Int32 ARG(dimension));
	
	/* A stepper over all projections of all boxes in the region */
	
	virtual RPTR(BoxProjectionStepper) boxProjectionStepper ();
	
	/* A stepper over all boxes */
	
	virtual RPTR(BoxStepper) boxStepper ();
	
	/* Whether a region is at a given 2D place in the array. 
	Searches forward and backward through adjacent boxes which 
	have the same hash value */
	
	virtual BooleanVar hasBoxProjection (
			APTR(XnRegion) ARG(other), 
			Int32 ARG(box), 
			Int32 ARG(dimension))
	;
	
	/* The array holding the regions. DO NOT MODIFY */
	
	virtual RPTR(PtrArray) OF1(XnRegion) secretRegions ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar hasMember (APTR(Position) ARG(position));
	
	
	virtual BooleanVar intersects (APTR(XnRegion) ARG(other));
	
	
	virtual BooleanVar isDistinction ();
	
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isEnumerable (APTR(OrderSpec) ARG(order) = NULL);
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFinite ();
	
	
	virtual BooleanVar isFull ();
	
	
	virtual BooleanVar isSimple ();
	
	
	virtual BooleanVar isSubsetOf (APTR(XnRegion) ARG(other));
	
  public: /* operations */

	
	virtual RPTR(XnRegion) asSimpleRegion ();
	
	
	virtual RPTR(XnRegion) complement ();
	
	
	virtual RPTR(XnRegion) intersect (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(XnRegion) unionWith (APTR(XnRegion) ARG(region));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* enumerating */

	
	virtual RPTR(Stepper) OF1(CrossRegion) boxes ();
	
	
	virtual RPTR(ScruSet) OF1(XnRegion) distinctions ();
	
	
	virtual BooleanVar isBox ();
	
	
	virtual RPTR(Stepper) simpleRegions (APTR(OrderSpec) ARG(order) = NULL);
	
  protected: /* protected: enumerating */

	
	virtual RPTR(Stepper) OF1(Position) actualStepper (APTR(OrderSpec) ARG(order));
	
  protected: /* protected: create */

	
	GenericCrossRegion (
			APTR(CrossSpace) ARG(space), 
			Int32 ARG(count), 
			APTR(PtrArray) OF1(XnRegion) ARG(regions))
	;
	
  private:
	CHKPTR(CrossSpace) mySpace;
	Int32 myCount;
	CHKPTR(PtrArray) OF1(XnRegion) myRegions;
/* Friends for class GenericCrossRegion */
friend class BoxAccumulator;
friend class BoxProjectionStepper;
friend class BoxStepper;
friend class GenericCrossDsp;
friend class GenericCrossSpace;
friend class CrossOrderSpec;



};  /* end class GenericCrossRegion */



/* ************************************************************************ *
 * 
 *                    Class GenericCrossSimpleRegionStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class GenericCrossSimpleRegionStepper : public Stepper {

/* Attributes for class GenericCrossSimpleRegionStepper */
	CONCRETE(GenericCrossSimpleRegionStepper)
	EQ(GenericCrossSimpleRegionStepper)
	NOT_A_TYPE(GenericCrossSimpleRegionStepper)
	AUTO_GC(GenericCrossSimpleRegionStepper)
  public: /* create */

	
	static RPTR(Stepper) make (APTR(CrossSpace) ARG(space), APTR(Stepper) ARG(boxes));
	
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  private: /* private: */

	/* Replenish all steppers starting at index */
	
	virtual void replenishSteppers (Int32 ARG(index));
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
  protected: /* protected: create */

	
	GenericCrossSimpleRegionStepper (APTR(CrossSpace) ARG(space), APTR(Stepper) ARG(boxes));
	
	
	GenericCrossSimpleRegionStepper (
			APTR(CrossSpace) ARG(space), 
			APTR(Stepper) ARG(boxes), 
			APTR(PtrArray) ARG(simples))
	;
	
  private:
	CHKPTR(CrossSpace) mySpace;
	CHKPTR(Stepper) OF1(CrossRegion) myBoxes;
	CHKPTR(PtrArray) OF1(Stepper OF1(XnRegion)) mySimples;
};  /* end class GenericCrossSimpleRegionStepper */



/* ************************************************************************ *
 * 
 *                    Class GenericCrossSpace 
 *
 * ************************************************************************ */




	/* Default implementation of cross coordinate space.
	was NOT.A.TYPE but that prevented compilation */

class GenericCrossSpace : public CrossSpace {

/* Attributes for class GenericCrossSpace */
	CONCRETE(GenericCrossSpace)
	PSEUDO_COPY(GenericCrossSpace,XppCuisine)
	NO_GC(GenericCrossSpace)
  public: /* rcvr pseudoconstructors */

	
	static RPTR(Heaper) make (APTR(Rcvr) ARG(rcvr));
	
  public: /* pseudoconstructors */

	
	static RPTR(CrossSpace) make (APTR(PtrArray) OF1(CoordinateSpace) ARG(subSpaces));
	
  public: /* making */

	
	virtual RPTR(Mapping) crossOfMappings (APTR(PtrArray) OF1(Mapping OR(NULL)) ARG(subMappings) = NULL);
	
	
	virtual RPTR(CrossOrderSpec) crossOfOrderSpecs (APTR(PtrArray) OF1(OrderSpec OR(NULL)) ARG(subOrderings) = NULL, APTR(PrimIntArray) ARG(subSpaceOrdering) = NULL);
	
	
	virtual RPTR(Tuple) crossOfPositions (APTR(PtrArray) OF1(Position) ARG(coordinates));
	
	
	virtual RPTR(CrossRegion) crossOfRegions (APTR(PtrArray) OF1(XnRegion OR(NULL)) ARG(subRegions));
	
	
	virtual RPTR(CrossRegion) extrusion (Int32 ARG(dimension), APTR(XnRegion) ARG(subRegion));
	
  private: /* private: creation */

	
	GenericCrossSpace (APTR(PtrArray) OF1(CoordinateSpace) ARG(subSpaces), TCSJ);
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* hooks: */

	
	virtual SEND_HOOK void sendGenericCrossSpaceTo (APTR(Xmtr) ARG(xmtr));
	

	friend class CrossSpace;
};  /* end class GenericCrossSpace */



/* ************************************************************************ *
 * 
 *                    Class TupleStepper 
 *
 * ************************************************************************ */




	/* A stepper for stepping through the positions in a simple 
	cross region in order according to a lexicographic 
	composition of OrderSpecs of each of the projections of the 
	region.  See CrossOrderSpec.NOT.A.TYPE  */

class TupleStepper : public Stepper {

/* Attributes for class TupleStepper */
	CONCRETE(TupleStepper)
	COPY(TupleStepper,XppCuisine)
	AUTO_GC(TupleStepper)
  public: /* pseudoconstructors */

	
	static RPTR(Stepper) make (
			APTR(CrossSpace) ARG(space), 
			APTR(PtrArray) OF1(Stepper OF1(Position)) ARG(virginSteppers), 
			APTR(PrimIntArray) ARG(lexOrder) = NULL)
	;
	
  private: /* private: creation */

	
	TupleStepper (
			APTR(CrossSpace) ARG(space), 
			APTR(PtrArray) OF1(Stepper OF1(Position)) ARG(virginSteppers), 
			APTR(PtrArray) OF1(Stepper OF1(Position)) ARG(steppers), 
			APTR(PrimIntArray) ARG(lexOrder))
	;
	
  private: /* private: */

	
	virtual void setValueFromSteppers ();
	
  public: /* operations */

	
	virtual RPTR(Stepper) copy ();
	
	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  private:
	CHKPTR(CrossSpace) mySpace;
	CHKPTR(PtrArray) OF1(Stepper OF1(Position)) myVirginSteppers;
	CHKPTR(PtrArray) OF1(Stepper OF1(Position)) mySteppers;
	CHKPTR(PrimIntArray) myLexOrder;
	CHKPTR(Tuple) OR(NULL) myValue;
};  /* end class TupleStepper */



#endif /* CROSSP_HXX */

