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

#ifndef ARRAYP_HXX
#define ARRAYP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef ARRAYX_HXX
#include "arrayx.hxx"
#endif /* ARRAYX_HXX */

#ifndef ARRAYP_OXX
#include "arrayp.oxx"
#endif /* ARRAYP_OXX */


#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */

#ifndef TABLESX_HXX
#include "tablesx.hxx"
#endif /* TABLESX_HXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class ActualArray 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ActualArray : public MuArray {

/* Attributes for class ActualArray */
	CONCRETE(ActualArray)
	COPY(ActualArray,XppCuisine)
	AUTO_GC(ActualArray)
  public: /* testing */

	
	virtual UInt32 fastHash ();
	
	
	virtual BooleanVar isEmpty ();
	
  public: /* accessing */

	/* store the new value at the specified position.  Note that 
	this is an insertion iff
		the index is the same as the tally (that is, we're adding at 
	the first empty position
		at the end of the array). */
	
	virtual RPTR(Heaper) atIntStore (IntegerVar ARG(index), APTR(Heaper) ARG(value));
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual IntegerVar count ();
	
	
	virtual RPTR(XnRegion) domain ();
	
	
	virtual IntegerVar highestIndex ();
	
	
	virtual RPTR(Heaper) intFetch (IntegerVar ARG(index));
	
	/* Remove if the index is the last thing in the table. 
		 Blast if the index is some other element of the table.  
		 *Ignore* the request if it is any element not in the table. */
	
	virtual BooleanVar intWipe (IntegerVar ARG(index));
	
	
	virtual IntegerVar lowestIndex ();
	
	
	virtual RPTR(ScruTable) offsetSubTableBetween (
			IntegerVar ARG(startIndex), 
			IntegerVar ARG(stopIndex), 
			IntegerVar ARG(firstIndex))
	;
	
	
	virtual RPTR(ScruTable) subTable (APTR(XnRegion) ARG(reg));
	
	
	virtual RPTR(ScruTable) subTableBetween (IntegerVar ARG(start), IntegerVar ARG(stop));
	
  public: /* creation */

	
	virtual RPTR(ScruTable) copy ();
	
	
	virtual RPTR(ScruTable) emptySize (IntegerVar ARG(size));
	
  private: /* private: creation */

	/* The optional argument just hints at the number of elements
		 to eventually be added.  It makes no difference semantically. */
	
	ActualArray ();
	
	/* The optional argument just hints at the number of elements
		 to eventually be added.  It makes no difference semantically. */
	
	ActualArray (IntegerVar ARG(size), TCSJ);
	
	
	ActualArray (APTR(PtrArray) OF1(Heaper) ARG(newElems), UInt32 ARG(newTally));
	
	
	virtual void destruct ();
	
  public: /* runs */

	
	virtual RPTR(XnRegion) runAtInt (IntegerVar ARG(anIdx));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
  private: /* private: private */

	/* return the elements array for rapid processing */
	
	virtual RPTR(PtrArray) elementsArray ();
	
	/* return the size of the elements array for rapid processing */
	
	virtual UInt32 endOffset ();
	
	/* Enlarge the receiver to contain more slots filled with nil. */
	
	virtual void enlarge ();
	
	/* return the size of the elements array for rapid processing */
	
	virtual UInt32 maxElements ();
	
	/* return the size of the elements array for rapid processing */
	
	virtual UInt32 startOffset ();
	
  public: /* enumerating */

	
	virtual RPTR(TableStepper) stepper (APTR(OrderSpec) ARG(order) = NULL);
	
  public: /* overload junk */

	
	virtual RPTR(Heaper) store (APTR(Position) ARG(key), APTR(Heaper) ARG(value));
	
	
	virtual RPTR(Heaper) fetch (APTR(Position) ARG(key));
	
	
	virtual RPTR(XnRegion) runAt (APTR(Position) ARG(anIdx));
	
	
	virtual BooleanVar wipe (APTR(Position) ARG(key));
	
  private:
	CHKPTR(PtrArray) elements;
	UInt32 tally;
/* Friends for class ActualArray */
/* friends for class ActualArray */
friend class AscendingArrayStepper;
friend SPTR(MuArray) MuArray::make(IntegerVar);


	friend class IntegerTable;
	friend class IntegerTable;
	friend class MuArray;
	friend class IntegerTable;
};  /* end class ActualArray */



/* ************************************************************************ *
 * 
 *                    Class ArrayAccumulator 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ArrayAccumulator : public TableAccumulator {

/* Attributes for class ArrayAccumulator */
	CONCRETE(ArrayAccumulator)
	NOT_A_TYPE(ArrayAccumulator)
	AUTO_GC(ArrayAccumulator)
  public: /* create */

	
	static RPTR(TableAccumulator) make (APTR(MuArray) ARG(onTable));
	
  protected: /* protected: create */

	
	ArrayAccumulator (APTR(MuArray) ARG(onTable), TCSJ);
	
  public: /* operations */

	
	virtual void step (APTR(Heaper) ARG(obj));
	
	
	virtual RPTR(Heaper) value ();
	
  public: /* create */

	
	virtual RPTR(Accumulator) copy ();
	
  private:
	CHKPTR(MuArray) arrayInternal;
/* Friends for class ArrayAccumulator */
friend class XuArray;


};  /* end class ArrayAccumulator */



/* ************************************************************************ *
 * 
 *                    Class ArrayStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ArrayStepper : public TableStepper {

/* Attributes for class ArrayStepper */
	DEFERRED(ArrayStepper)
	NOT_A_TYPE(ArrayStepper)
	AUTO_GC(ArrayStepper)
  public: /* operations */

	
	virtual WPTR(Heaper) fetch () DEFERRED_FUNC;
	
	
	virtual WPTR(Heaper) get ();
	
	
	virtual BooleanVar hasValue () DEFERRED_FUNC;
	
	
	virtual void step () DEFERRED_SUBR;
	
  public: /* special */

	
	virtual IntegerVar index ();
	
	
	virtual RPTR(Position) position ();
	
  protected: /* protected: accessing */

	
	virtual RPTR(ActualArray) array ();
	
	
	virtual void setIndex (Int32 ARG(i));
	
  public: /* create */

	
	virtual RPTR(Stepper) copy () DEFERRED_FUNC;
	
  protected: /* protected: create */

	
	ArrayStepper (APTR(MuArray) ARG(array), TCSJ);
	
	
	ArrayStepper (APTR(MuArray) ARG(array), IntegerVar ARG(index));
	
  private:
	CHKPTR(ActualArray) arrayInternal;
	Int32 indexInternal;
};  /* end class ArrayStepper */



/* ************************************************************************ *
 * 
 *                    Class   AscendingArrayStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class AscendingArrayStepper : public ArrayStepper {

/* Attributes for class AscendingArrayStepper */
	CONCRETE(AscendingArrayStepper)
	NOT_A_TYPE(AscendingArrayStepper)
	NO_GC(AscendingArrayStepper)
  public: /* create */

	
	static RPTR(TableStepper) make (APTR(ActualArray) ARG(array));
	
	
	static RPTR(TableStepper) make (APTR(ActualArray) ARG(array), IntegerVar ARG(index));
	
	
	static RPTR(TableStepper) make (
			APTR(ActualArray) ARG(array), 
			IntegerVar ARG(start), 
			IntegerVar ARG(stop))
	;
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
  protected: /* protected: create */

	
	AscendingArrayStepper (APTR(ActualArray) ARG(array), TCSJ);
	
	
	AscendingArrayStepper (APTR(ActualArray) ARG(array), IntegerVar ARG(index));
	
	
	AscendingArrayStepper (
			APTR(ActualArray) ARG(array), 
			IntegerVar ARG(start), 
			IntegerVar ARG(stop))
	;
	
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	Int32 lastValueInternal;
};  /* end class AscendingArrayStepper */



/* ************************************************************************ *
 * 
 *                    Class OffsetArrayStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class OffsetArrayStepper : public TableStepper {

/* Attributes for class OffsetArrayStepper */
	CONCRETE(OffsetArrayStepper)
	NOT_A_TYPE(OffsetArrayStepper)
	AUTO_GC(OffsetArrayStepper)
  public: /* create */

	
	static RPTR(TableStepper) make (APTR(TableStepper) ARG(arrayStepper), APTR(Dsp) ARG(aDsp));
	
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual WPTR(Heaper) get ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* special */

	
	virtual IntegerVar index ();
	
	
	virtual RPTR(Position) position ();
	
  protected: /* protected: create */

	
	OffsetArrayStepper (APTR(TableStepper) ARG(onStepper), APTR(Dsp) ARG(aDsp));
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
  private:
	CHKPTR(TableStepper) myArrayStepper;
	CHKPTR(Dsp) myDsp;
};  /* end class OffsetArrayStepper */



/* ************************************************************************ *
 * 
 *                    Class OffsetScruArray 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class OffsetScruArray : public ScruTable {

/* Attributes for class OffsetScruArray */
	CONCRETE(OffsetScruArray)
	NOT_A_TYPE(OffsetScruArray)
	COPY(OffsetScruArray,XppCuisine)
	AUTO_GC(OffsetScruArray)
  public: /* create */

	
	static RPTR(ScruTable) make (APTR(MuArray) ARG(array), APTR(Dsp) ARG(dsp));
	
  public: /* accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual IntegerVar count ();
	
	
	virtual RPTR(XnRegion) domain ();
	
	
	virtual RPTR(Heaper) fetch (APTR(Position) ARG(anIndex));
	
	
	virtual RPTR(Heaper) intFetch (IntegerVar ARG(idx));
	
	
	virtual RPTR(ScruTable) subTable (APTR(XnRegion) ARG(encl));
	
	
	virtual RPTR(ScruTable) subTableBetween (IntegerVar ARG(startLoc), IntegerVar ARG(endLoc));
	
	
	virtual RPTR(ScruTable) transformedBy (APTR(Dsp) ARG(dsp));
	
  public: /* runs */

	
	virtual RPTR(XnRegion) runAt (APTR(Position) ARG(key));
	
	
	virtual RPTR(XnRegion) runAtInt (IntegerVar ARG(anIdx));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar includesIntKey (IntegerVar ARG(aKey));
	
	
	virtual BooleanVar includesKey (APTR(Position) ARG(aKey));
	
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
  protected: /* protected: create */

	
	OffsetScruArray (APTR(MuArray) ARG(array), APTR(Dsp) ARG(dsp));
	
  public: /* creation */

	
	virtual RPTR(ScruTable) copy ();
	
	
	virtual RPTR(ScruTable) empty ();
	
	
	virtual RPTR(ScruTable) emptySize (IntegerVar ARG(size));
	
  public: /* conversion */

	
	virtual RPTR(ImmuTable) asImmuTable ();
	
	
	virtual RPTR(MuTable) asMuTable ();
	
  public: /* enumerating */

	
	virtual RPTR(TableStepper) stepper (APTR(OrderSpec) ARG(order) = NULL);
	
  private: /* private: private */

	
	virtual RPTR(MuArray) innerArray ();
	
	
	virtual RPTR(Dsp) innerDsp ();
	
  private:
	CHKPTR(MuArray) myArray;
	CHKPTR(Dsp) myDsp;
/* Friends for class OffsetScruArray */
friend class XuArray;


};  /* end class OffsetScruArray */



#endif /* ARRAYP_HXX */

