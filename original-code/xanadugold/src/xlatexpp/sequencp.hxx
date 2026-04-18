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

#ifndef SEQUENCP_HXX
#define SEQUENCP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SEQUENCX_HXX
#include "sequencx.hxx"
#endif /* SEQUENCX_HXX */

#ifndef SEQUENCP_OXX
#include "sequencp.oxx"
#endif /* SEQUENCP_OXX */


#ifndef EDGER_HXX
#include "edger.hxx"
#endif /* EDGER_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class SequenceEdge 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class SequenceEdge : public TransitionEdge {

/* Attributes for class SequenceEdge */
	DEFERRED(SequenceEdge)
	COPY(SequenceEdge,XppCuisine)
	AUTO_GC(SequenceEdge)
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
	
  public: /* accessing */

	
	virtual RPTR(Sequence) sequence ();
	
	/* Transform the edge by the given mapping */
	
	virtual RPTR(SequenceEdge) transformedBy (APTR(SequenceMapping) ARG(dsp)) DEFERRED_FUNC;
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
	/* Print a description of this transition */
	
	virtual void printTransitionOn (
			ostream& ARG(oo), 
			BooleanVar ARG(entering), 
			BooleanVar ARG(touchesPrevious))
	 DEFERRED_SUBR;
	
  public: /* create */

	
	SequenceEdge (APTR(Sequence) ARG(sequence), TCSJ);
	
  private:
	CHKPTR(Sequence) mySequence;
};  /* end class SequenceEdge */



/* ************************************************************************ *
 * 
 *                    Class   AfterSequence 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class AfterSequence : public SequenceEdge {

/* Attributes for class AfterSequence */
	CONCRETE(AfterSequence)
	COPY(AfterSequence,XppCuisine)
	NOT_A_TYPE(AfterSequence)
	NO_GC(AfterSequence)
  public: /* pseudo constructors */

	
	static RPTR(SequenceEdge) make (APTR(Sequence) ARG(sequence));
	
  public: /* accessing */

	
	virtual RPTR(Position) position ();
	
	
	virtual RPTR(SequenceEdge) transformedBy (APTR(SequenceMapping) ARG(dsp));
	
  public: /* create */

	
	AfterSequence (APTR(Sequence) ARG(sequence), TCSJ);
	
  public: /* printing */

	
	virtual void printTransitionOn (
			ostream& ARG(oo), 
			BooleanVar ARG(entering), 
			BooleanVar ARG(touchesPrevious))
	;
	
  public: /* comparing */

	
	virtual BooleanVar follows (APTR(Position) ARG(pos));
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFollowedBy (APTR(TransitionEdge) ARG(next));
	
	
	virtual BooleanVar isGE (APTR(TransitionEdge) ARG(other));
	
	
	virtual BooleanVar touches (APTR(TransitionEdge) ARG(other));
	

};  /* end class AfterSequence */



/* ************************************************************************ *
 * 
 *                    Class   BeforeSequence 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class BeforeSequence : public SequenceEdge {

/* Attributes for class BeforeSequence */
	CONCRETE(BeforeSequence)
	COPY(BeforeSequence,XppCuisine)
	NOT_A_TYPE(BeforeSequence)
	NO_GC(BeforeSequence)
  public: /* pseudo constructors */

	
	static RPTR(SequenceEdge) make (APTR(Sequence) ARG(sequence));
	
  public: /* comparing */

	
	virtual BooleanVar follows (APTR(Position) ARG(pos));
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFollowedBy (APTR(TransitionEdge) ARG(next));
	
	
	virtual BooleanVar isGE (APTR(TransitionEdge) ARG(other));
	
	
	virtual BooleanVar touches (APTR(TransitionEdge) ARG(other));
	
  public: /* accessing */

	
	virtual RPTR(Position) position ();
	
	
	virtual RPTR(SequenceEdge) transformedBy (APTR(SequenceMapping) ARG(dsp));
	
  public: /* create */

	
	BeforeSequence (APTR(Sequence) ARG(sequence), TCSJ);
	
  public: /* printing */

	
	virtual void printTransitionOn (
			ostream& ARG(oo), 
			BooleanVar ARG(entering), 
			BooleanVar ARG(touchesPrevious))
	;
	

};  /* end class BeforeSequence */



/* ************************************************************************ *
 * 
 *                    Class   BeforeSequencePrefix 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class BeforeSequencePrefix : public SequenceEdge {

/* Attributes for class BeforeSequencePrefix */
	CONCRETE(BeforeSequencePrefix)
	COPY(BeforeSequencePrefix,XppCuisine)
	NOT_A_TYPE(BeforeSequencePrefix)
	NO_GC(BeforeSequencePrefix)
  public: /* pseudo constructors */

	
	static RPTR(TransitionEdge) above (APTR(Sequence) ARG(sequence), IntegerVar ARG(limit));
	
	
	static RPTR(TransitionEdge) below (APTR(Sequence) ARG(sequence), IntegerVar ARG(limit));
	
  public: /* comparing */

	
	virtual BooleanVar follows (APTR(Position) ARG(pos));
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFollowedBy (APTR(TransitionEdge) ARG(next));
	
	
	virtual BooleanVar isGE (APTR(TransitionEdge) ARG(other));
	
	
	virtual BooleanVar touches (APTR(TransitionEdge) ARG(other));
	
  public: /* accessing */

	
	virtual IntegerVar limit ();
	
	
	virtual RPTR(Position) position ();
	
	
	virtual RPTR(SequenceEdge) transformedBy (APTR(SequenceMapping) ARG(dsp));
	
  public: /* create */

	
	BeforeSequencePrefix (APTR(Sequence) ARG(sequence), IntegerVar ARG(limit));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
	
	virtual void printTransitionOn (
			ostream& ARG(oo), 
			BooleanVar ARG(entering), 
			BooleanVar ARG(touchesPrevious))
	;
	
  private:
	IntegerVar myLimit;
};  /* end class BeforeSequencePrefix */



/* ************************************************************************ *
 * 
 *                    Class SequenceManager 
 *
 * ************************************************************************ */




	/* Specialized object for managing TumblerSpace objects. Is a 
	type so that inlining could potentially be used. */

class SequenceManager : public EdgeManager {

/* Attributes for class SequenceManager */
	CONCRETE(SequenceManager)
	COPY(SequenceManager,XppCuisine)
	NO_GC(SequenceManager)
  protected: /* protected: */

	
	virtual RPTR(Position) edgePosition (APTR(TransitionEdge) ARG(edge));
	
	
	virtual RPTR(XnRegion) makeNew (BooleanVar ARG(startsInside), APTR(PtrArray) OF1(TransitionEdge) ARG(transitions));
	
	
	virtual RPTR(XnRegion) makeNew (
			BooleanVar ARG(startsInside), 
			APTR(PtrArray) OF1(TransitionEdge) ARG(transitions), 
			Int32 ARG(count))
	;
	
	
	virtual RPTR(PtrArray) OF1(TransitionEdge) posTransitions (APTR(Position) ARG(pos));
	
	
	virtual BooleanVar startsInside (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(PtrArray) OF1(TransitionEdge) transitions (APTR(XnRegion) ARG(region));
	
	
	virtual Int32 transitionsCount (APTR(XnRegion) ARG(region));
	

	/* automatic 0-argument constructor */
  public:
	SequenceManager();

};  /* end class SequenceManager */



/* ************************************************************************ *
 * 
 *                    Class SequenceStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class SequenceStepper : public Stepper {

/* Attributes for class SequenceStepper */
	CONCRETE(SequenceStepper)
	NOT_A_TYPE(SequenceStepper)
	AUTO_GC(SequenceStepper)
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	SequenceStepper (APTR(PtrArray) OF1(IDEdge) ARG(transitions), Int32 ARG(count));
	
	
	SequenceStepper (
			Int32 ARG(index), 
			APTR(PtrArray) OF1(IDEdge) ARG(transitions), 
			Int32 ARG(count))
	;
	
  private:
	Int32 myIndex;
	CHKPTR(PtrArray) OF1(SequenceEdge) myTransitions;
	Int32 myTransitionsCount;
};  /* end class SequenceStepper */



/* ************************************************************************ *
 * 
 *                    Class SequenceUpOrder 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class SequenceUpOrder : public OrderSpec {

/* Attributes for class SequenceUpOrder */
	CONCRETE(SequenceUpOrder)
	COPY(SequenceUpOrder,XppCuisine)
	NOT_A_TYPE(SequenceUpOrder)
	NO_GC(SequenceUpOrder)
  public: /* pseudo constructors */

	
	static RPTR(OrderSpec) make ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar follows (APTR(Position) ARG(x), APTR(Position) ARG(y));
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFullOrder (APTR(XnRegion) ARG(keys) = NULL);
	
	
	virtual BooleanVar preceeds (APTR(XnRegion) ARG(before), APTR(XnRegion) ARG(after));
	
  public: /* accessing */

	
	virtual RPTR(Arrangement) arrange (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	

	/* automatic 0-argument constructor */
  public:
	SequenceUpOrder();

};  /* end class SequenceUpOrder */



#endif /* SEQUENCP_HXX */

