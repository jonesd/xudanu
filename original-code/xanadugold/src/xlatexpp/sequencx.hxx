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

#ifndef SEQUENCX_HXX
#define SEQUENCX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SEQUENCX_OXX
#include "sequencx.oxx"
#endif /* SEQUENCX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */


#ifndef EDGER_OXX
#include "edger.oxx"
#endif /* EDGER_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SEQUENCP_OXX
#include "sequencp.oxx"
#endif /* SEQUENCP_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class Sequence 
 *
 * ************************************************************************ */



/* Initializers for Sequence */







	/* Represents an infinite sequence of integers (of which only 
	a finite number can be non-zero). They are lexically ordered, 
	and there is a "decimal point" between the numbers at -1 and 0.
	
	Implementation note:
	The array should have no zeros at either end, and noone else 
	should have a pointer to it. */

class Sequence : public Position {

/* Attributes for class Sequence */
	CONCRETE(Sequence)
	ON_CLIENT(Sequence)
	COPY(Sequence,XppCuisine)
	AUTO_GC(Sequence)

/* Initializers for Sequence */



friend class INIT_TIME_NAME(Sequence,initTimeNonInherited);

  public: /* pseudo constructors */

	
	static RPTR(Sequence) numbers (APTR(PrimIntegerArray) ARG(digits));
	
	/* A single element Sequence */
	
	static RPTR(Sequence) one (IntegerVar ARG(a));
	
	
	static RPTR(Sequence) string (char * ARG(string));
	
	/* A three element Sequence */
	
	static RPTR(Sequence) three (
			IntegerVar ARG(a), 
			IntegerVar ARG(b), 
			IntegerVar ARG(c))
	;
	
	/* A two element Sequence */
	
	static RPTR(Sequence) two (IntegerVar ARG(a), IntegerVar ARG(b));
	
	
	static INLINE RPTR(Sequence) zero ();
	
  private: /* private: */

	/* Print a sequence of numbers separated by dots. Deal with 
	strings specially. */
	
	static void printArrayOn (ostream& ARG(oo), APTR(PrimIntegerArray) ARG(numbers));
	
	/* Print a sequence of numbers separated by dots. Deal with 
	strings specially. */
	
	static void printOn (
			ostream& ARG(oo), 
			IntegerVar ARG(shift), 
			APTR(PrimIntegerArray) ARG(numbers))
	;
	
	/* Print a sequence of zeros separated by dots. Deal with 
	large numbers specially. */
	
	static void printZerosOn (ostream& ARG(oo), IntegerVar ARG(shift));
	
	/* Don't need to make a copy of the array */
	
	static RPTR(Sequence) usingx (IntegerVar ARG(shift), APTR(PrimIntegerArray) ARG(numbers));
	
  public: /* accessing */

	
	virtual RPTR(XnRegion) asRegion ();
	
	
	INLINE RPTR(CoordinateSpace) coordinateSpace ();
	
	/* How many numbers in the sequence, not counting leading or 
	trailing zeros */
	
	INLINE IntegerVar count ();
	
	/* The smallest index with a non-zero number. Blasts if it is 
	all zeros. */
	
	virtual CLIENT IntegerVar firstIndex ();
	
	/* The number at the given index in the Sequence. Returns 
	zeros beyond either end of the array. */
	
	virtual CLIENT IntegerVar integerAt (IntegerVar ARG(index));
	
	/* Essential. The numbers in this Sequence. This is a copy of 
	the array, so you may modify it.
		Note that two Sequences which are isEqual, may actually have 
	arrays of numbers which have different specs. Also, the array 
	will not have any zeros at the beginning or end. */
	
	virtual CLIENT RPTR(PrimIntegerArray) integers ();
	
	/* Whether all the numbers in the sequence are zero */
	
	virtual CLIENT BooleanVar isZero ();
	
	/* The largest index with a non-zero number. Blasts if it is 
	all zeros. */
	
	virtual CLIENT IntegerVar lastIndex ();
	
	/* The amount by which the numbers are shifted. Positive 
	means less significant, negative means more significant. This 
	is contrary to the usual arithmetic notions, but it is the 
	right thing for arrays. */
	
	INLINE IntegerVar shift ();
	
  private: /* private: comparing */

	/* Compare my numbers up to and including index n with the 
	corresponding numbers in the other Sequence. Return -1, 0 or 
	1 depending on whether they are <, =, or > the other. */
	
	virtual Int32 comparePrefix (APTR(Sequence) ARG(other), IntegerVar ARG(n));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	/* Whether this sequence is greater than or equal to the 
	other sequence, using a lexical comparison of their 
	corresponding numbers. */
	
	virtual BooleanVar isGE (APTR(Position) ARG(other));
	
  private: /* private: */

	/* The array itself, for internal use */
	
	INLINE RPTR(PrimIntegerArray) secretNumbers ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* create */

	
	Sequence (IntegerVar ARG(shift), APTR(PrimIntegerArray) ARG(numbers));
	
  public: /* operations */

	/* The sequence consisting of all numbers in this one up to 
	but not including the first zero, or the entire thing if 
	there are no zeros */
	/* | zero {Int32} |
		zero := myNumbers indexOfInteger: IntegerVarZero.
		zero < Int32Zero ifTrue:
			[^self]
		ifFalse:
			[^Sequence create: ((myNumbers copy: zero) cast: 
	PrimIntegerArray)] */
	
	virtual RPTR(Sequence) first ();
	
	/* A sequence with the corresponding numbers subtracted from 
	each other */
	
	virtual RPTR(Sequence) minus (APTR(Sequence) ARG(other));
	
	/* A sequence with the corresponding numbers added to each other */
	
	virtual RPTR(Sequence) plus (APTR(Sequence) ARG(other));
	
	/* The sequence consisting of all numbers in this one after 
	but not including the first zero, or a null sequence if there 
	are no zeros */
	/* | zero {Int32} |
		zero := myNumbers indexOfInteger: IntegerVarZero.
		zero < Int32Zero ifTrue:
			[^Sequence zero]
		ifFalse:
			[^Sequence create: ((myNumbers
				copy: -1 with: 1 + zero) cast: PrimIntegerArray)] */
	
	virtual RPTR(Sequence) rest ();
	
	/* Shift the numbers by some number of places. Positive 
	shifts make it less significant, negative shifts make it more 
	significant. */
	
	virtual RPTR(Sequence) shift (IntegerVar ARG(offset));
	
	/* Change a single element of the sequence. */
	
	virtual CLIENT RPTR(Sequence) with (IntegerVar ARG(index), IntegerVar ARG(number));
	
	/* A Sequence with all my numbers followed by the given one */
	
	virtual RPTR(Sequence) withFirst (IntegerVar ARG(number));
	
	/* A Sequence with all my numbers followed by the given one */
	
	virtual RPTR(Sequence) withLast (IntegerVar ARG(number));
	
	/* A sequence containing all the numbers in this one, 
	followed by the other one, separated by a single zero. */
	
	virtual RPTR(Sequence) withRest (APTR(Sequence) ARG(other));
	
  private:
	IntegerVar myShift;
	CHKPTR(PrimIntegerArray) myNumbers;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(Sequence) TheZero;
/* Friends for class Sequence */
/* friends for class Sequence */
friend class AfterSequence;
friend class BeforeSequence;
friend class BeforeSequencePrefix;
friend class SequenceUpOrder;
friend class SequenceSpace;


};  /* end class Sequence */



/* ************************************************************************ *
 * 
 *                    Class SequenceMapping 
 *
 * ************************************************************************ */




	/* Transforms a Sequence by shifting some amount, and then 
	adding another Sequence to it. */

class SequenceMapping : public Dsp {

/* Attributes for class SequenceMapping */
	CONCRETE(SequenceMapping)
	ON_CLIENT(SequenceMapping)
	COPY(SequenceMapping,XppCuisine)
	AUTO_GC(SequenceMapping)
  private: /* private: pseudo constructors */

	
	static RPTR(SequenceMapping) make (IntegerVar ARG(shift), APTR(Sequence) ARG(translation));
	
  public: /* accessing */

	
	INLINE RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual BooleanVar isIdentity ();
	
	/* The amount by which it shifts a sequence */
	
	INLINE CLIENT IntegerVar shift ();
	
	/* What it adds to a sequence after shifting it */
	
	INLINE CLIENT RPTR(Sequence) translation ();
	
  public: /* transforming */

	
	virtual RPTR(Position) inverseOf (APTR(Position) ARG(position));
	
	
	virtual RPTR(XnRegion) inverseOfAll (APTR(XnRegion) ARG(reg));
	
	
	virtual RPTR(Position) of (APTR(Position) ARG(position));
	
	
	virtual RPTR(XnRegion) ofAll (APTR(XnRegion) ARG(reg));
	
  public: /* combining */

	/* Return the composition of the two Dsps. Two Dsps of the 
	same space are always composable.
		(a->compose(b) ->minus(b))->isEqual (a)
		(a->compose(b) ->of(pos))->isEqual (a->of (b->of (pos)) */
	
	virtual RPTR(Dsp) compose (APTR(Dsp) ARG(dsp));
	
	
	virtual RPTR(Mapping) inverse ();
	
	
	virtual RPTR(Dsp) inverseCompose (APTR(Dsp) ARG(dsp));
	
	
	virtual RPTR(Dsp) minus (APTR(Dsp) ARG(dsp));
	
  private: /* private: create */

	
	SequenceMapping (IntegerVar ARG(shift), APTR(Sequence) ARG(translation));
	
  private:
	IntegerVar myShift;
	CHKPTR(Sequence) myTranslation;
/* Friends for class SequenceMapping */
/* friends for class SequenceDsp */
friend class SequenceSpace;



	friend class Mapping;
};  /* end class SequenceMapping */



/* ************************************************************************ *
 * 
 *                    Class SequenceRegion 
 *
 * ************************************************************************ */



/* Initializers for SequenceRegion */







	/* Represents a Region of Sequences. We can efficiently 
	represent unions of intervals, delimited either by individual 
	sequences or by a match with all sequences prefixed by some 
	sequence up to some index. */

class SequenceRegion : public XnRegion {

/* Attributes for class SequenceRegion */
	CONCRETE(SequenceRegion)
	ON_CLIENT(SequenceRegion)
	COPY(SequenceRegion,XppCuisine)
	AUTO_GC(SequenceRegion)

/* Initializers for SequenceRegion */



friend class INIT_TIME_NAME(SequenceRegion,initTimeNonInherited);

  public: /* pseudo constructors */

	
	static RPTR(SequenceRegion) above (APTR(Sequence) ARG(sequence));
	
	
	static RPTR(SequenceRegion) below (APTR(Sequence) ARG(sequence));
	
	
	static INLINE RPTR(SequenceRegion) empty ();
	
	
	static INLINE RPTR(SequenceRegion) full ();
	
	/* All sequences matching the given up to and including the 
	number at limit */
	
	static RPTR(SequenceRegion) prefixedBy (APTR(Sequence) ARG(sequence), IntegerVar ARG(limit));
	
	
	static RPTR(SequenceRegion) strictlyAbove (APTR(Sequence) ARG(sequence));
	
	
	static RPTR(SequenceRegion) strictlyBelow (APTR(Sequence) ARG(sequence));
	
  private: /* private: */

	/* Make a new region, reusing the given array. No one else 
	should ever modify it! */
	
	static RPTR(SequenceRegion) usingx (BooleanVar ARG(startsInside), APTR(PtrArray) OF1(TransitionEdge) ARG(transitions));
	
  public: /* constants */

	
	static INLINE CLIENT Int32 EXCLUSIVE () CONST;
	
	
	static INLINE CLIENT Int32 INCLUSIVE () CONST;
	
	
	static INLINE CLIENT Int32 PREFIX () CONST;
	
  public: /* create */

	
	SequenceRegion (BooleanVar ARG(startsInside), APTR(PtrArray) OF1(TransitionEdge) ARG(transitions));
	
	
	SequenceRegion (
			BooleanVar ARG(startsInside), 
			APTR(PtrArray) OF1(TransitionEdge) ARG(transitions), 
			Int32 ARG(count))
	;
	
  public: /* accessing */

	
	virtual RPTR(XnRegion) asSimpleRegion ();
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	/* The largest sequence such that all the positions in the 
	region are >= it.  Does not necessarily lie in the region.  
	For example, the region of all numbers > 2.3 has a lowerBound 
	of 2.3. Mathematically, this is called the 'greatest lower bound'. */
	
	virtual RPTR(Sequence) lowerBound ();
	
	/* Essential. The Sequence associated with the lower edge of 
	the Region. To find out where the boundary is in relation to 
	this sequence, check lowerEdgeType. BLASTS if unbounded below. */
	
	virtual CLIENT RPTR(Sequence) lowerEdge ();
	
	/* Essential. If lowerEdgeType is prefix, then it includes an 
	Sequence matching each integer in the lowerEdge up to and 
	including lowerEdgePrefixLimit. */
	
	virtual CLIENT IntegerVar lowerEdgePrefixLimit ();
	
	/* Essential. The kind of Sequence associated with the lower 
	edge of the Region. If SequenceRegion::inclusive then it 
	includes the lowerEdge; if exclusive, then it does not; if 
	prefix, then it includes any Sequence matching each integer 
	in the lowerEdge up to and including lowerEdgePrefixLimit. */
	
	virtual CLIENT Int32 lowerEdgeType ();
	
	/* The smallest Sequence such that all the positions in the 
	region are <= it.  Does not necessarily lie in the region.  
	For example, the region of all numbers < 2.3 has an 
	upperBound of 2.3. Mathematically, this is called the 'least 
	upper bound'. */
	
	virtual RPTR(Sequence) upperBound ();
	
	/* Essential. The Sequence associated with the upper edge of 
	the Region. To find out where the boundary is in relation to 
	this sequence, check upperEdgeType. BLASTS if unbounded below. */
	
	virtual CLIENT RPTR(Sequence) upperEdge ();
	
	/* Essential. If upperEdgeType is prefix, then it includes a 
	Sequence matching each integer in the upperEdge up to and 
	including upperEdgePrefixLimit. */
	
	virtual CLIENT IntegerVar upperEdgePrefixLimit ();
	
	/* Essential. The kind of Sequence associated with the upper 
	edge of the Region. If SequenceRegion::inclusive then it 
	includes the upperEdge; if exclusive, then it does not; if 
	prefix, then it includes any Sequence matching each integer 
	in the upperEdge up to and including upperEdgePrefixLimit. */
	
	virtual CLIENT Int32 upperEdgeType ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar hasMember (APTR(Position) ARG(position));
	
	/* Same meaning as IntegerRegion::isBoundedAbove */
	
	INLINE CLIENT BooleanVar isBoundedAbove ();
	
	/* Same meaning as IntegerRegion::isBoundedBelow */
	
	INLINE CLIENT BooleanVar isBoundedBelow ();
	
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isEnumerable (APTR(OrderSpec) ARG(order) = NULL);
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFinite ();
	
	
	virtual BooleanVar isFull ();
	
	
	virtual BooleanVar isSimple ();
	
	
	virtual BooleanVar isSubsetOf (APTR(XnRegion) ARG(other));
	
  protected: /* protected: enumerating */

	
	virtual RPTR(Stepper) OF1(Position) actualStepper (APTR(OrderSpec) ARG(order));
	
  public: /* enumerating */

	
	virtual IntegerVar count ();
	
	
	virtual RPTR(ScruSet) OF1(XnRegion) distinctions ();
	
	/* Essential. Break this up into disjoint intervals */
	
	INLINE CLIENT RPTR(Stepper) OF1(SequenceRegion) intervals (APTR(OrderSpec) ARG(order) = NULL);
	
	/* Whether this Region is a non-empty interval, i.e. if A, B 
	in the Region and A <= C <= B then C is in the Region. This 
	includes inequalities (e.g. {x | x > 5.3}) and the fullRegion 
	in addition to ordinary two-ended intervals. */
	
	INLINE CLIENT BooleanVar isInterval ();
	
	
	virtual RPTR(Stepper) simpleRegions (APTR(OrderSpec) ARG(order) = NULL);
	
	
	virtual RPTR(Stepper) OF1(Position) stepper (APTR(OrderSpec) ARG(order) = NULL);
	
  public: /* operations */

	
	virtual RPTR(XnRegion) complement ();
	
	
	virtual RPTR(XnRegion) intersect (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) simpleUnion (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) unionWith (APTR(XnRegion) ARG(other));
	
	
	virtual RPTR(XnRegion) with (APTR(Position) ARG(pos));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* secret */

	
	INLINE RPTR(PtrArray) OF1(SequenceEdge) secretTransitions ();
	
	
	INLINE Int32 secretTransitionsCount ();
	
	
	INLINE BooleanVar startsInside ();
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK void receiveSequenceRegion (APTR(Rcvr) ARG(rcvr));
	
	
	virtual SEND_HOOK void sendSequenceRegion (APTR(Xmtr) ARG(xmtr));
	
  private:
	BooleanVar myStartsInside;
	NOCOPY CHKPTR(PtrArray) OF1(SequenceEdge) myTransitions;
	Int32 myTransitionsCount;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(SequenceRegion) TheEmptySequenceRegion;
	static GPTR(SequenceRegion) TheFullSequenceRegion;
	static GPTR(SequenceManager) TheManager;
/* Friends for class SequenceRegion */
/* friends for class SequenceRegion */

friend class Sequence;
friend class SequenceSpace;
friend class SequenceMapping;
friend class SequenceManager;



};  /* end class SequenceRegion */



/* ************************************************************************ *
 * 
 *                    Class SequenceSpace 
 *
 * ************************************************************************ */



/* Initializers for SequenceSpace */







	/* The space of all Sequences */

class SequenceSpace : public CoordinateSpace {

/* Attributes for class SequenceSpace */
	CONCRETE(SequenceSpace)
	PSEUDO_COPY(SequenceSpace,XppCuisine)
	ON_CLIENT(SequenceSpace)
	NO_GC(SequenceSpace)

/* Initializers for SequenceSpace */



friend class INIT_TIME_NAME(SequenceSpace,initTimeNonInherited);

  public: /* rcvr creation */

	
	static RPTR(Heaper) make (APTR(Rcvr) ARG(rcvr));
	
  public: /* creation */

	/* Get the receiver for wire requests. */
	
	static INLINE RPTR(SequenceSpace) implicitReceiver ();
	
	
	static INLINE CLIENT RPTR(SequenceSpace) make ();
	
  public: /* create */

	
	SequenceSpace ();
	
  public: /* temporary */

	
	INLINE CLIENT RPTR(Sequence) position (APTR(PrimArray) ARG(numbers));
	
  public: /* making */

	/* Essential. All sequences >= sequence if inclusive, > 
	sequence if not. */
	
	virtual CLIENT RPTR(SequenceRegion) above (APTR(Sequence) ARG(sequence), BooleanVar ARG(inclusive));
	
	/* Essential. All sequences <= sequence if inclusive, < 
	sequence if not. */
	
	virtual CLIENT RPTR(SequenceRegion) below (APTR(Sequence) ARG(sequence), BooleanVar ARG(inclusive));
	
	/* Return a region of all sequence >= lower and < upper. */
	/* Ravi thingToDo. */
	/* use a single constructor */
	/* Performance */
	
	virtual CLIENT RPTR(SequenceRegion) interval (APTR(Sequence) ARG(start), APTR(Sequence) ARG(stop));
	
	/* A transformation which shifts a value by some number of 
	places and then adds a translation to it. */
	
	virtual CLIENT RPTR(SequenceMapping) mapping (IntegerVar ARG(shift), APTR(Sequence) ARG(translation) = NULL);
	
	/* Essential. A sequence using the given numbers and shift. 
	Leading and trailing zeros will be stripped, and a copy will 
	be made so that noone modifies it */
	/* IntegerVars cannot have default arguments */
	
	virtual CLIENT RPTR(Sequence) position (APTR(PrimArray) ARG(arg), IntegerVar ARG(shift));
	
	/* Essential. All sequences which match the given one up to 
	and including the given index. */
	
	virtual CLIENT RPTR(SequenceRegion) prefixedBy (APTR(Sequence) ARG(sequence), IntegerVar ARG(limit));
	
  public: /* testing */

	/* is equal to any basic space on the same category of positions */
	
	virtual UInt32 actualHashForEqual ();
	
	/* is equal to any basic space on the same category of positions */
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(anObject));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(SequenceSpace) TheSequenceSpace;
/* Friends for class SequenceSpace */
/* friends for class SequenceSpace */

friend class Sequence;



};  /* end class SequenceSpace */


#ifdef USE_INLINE
#ifndef SEQUENCX_IXX
#include "sequencx.ixx"
#endif /* SEQUENCX_IXX */


#endif /* USE_INLINE */


#endif /* SEQUENCX_HXX */

