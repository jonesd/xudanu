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

#ifndef REALP_HXX
#define REALP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef REALX_HXX
#include "realx.hxx"
#endif /* REALX_HXX */

#ifndef REALP_OXX
#include "realp.oxx"
#endif /* REALP_OXX */


#ifndef EDGER_HXX
#include "edger.hxx"
#endif /* EDGER_HXX */

#ifndef SPACER_HXX
#include "spacer.hxx"
#endif /* SPACER_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef PRIMVALX_OXX
#include "primvalx.oxx"
#endif /* PRIMVALX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class IEEE32Pos 
 *
 * ************************************************************************ */




	/* For representing exactly those real numbers that can be 
	represented in IEEE single precision */

class IEEE32Pos : public RealPos {

/* Attributes for class IEEE32Pos */
	CONCRETE(IEEE32Pos)
	COPY(IEEE32Pos,XppCuisine)
	NO_GC(IEEE32Pos)
  public: /* creation */

	
	IEEE32Pos (IEEE32 ARG(value), TCSJ);
	
  public: /* obsolete: */

	
	virtual IEEE64 asIEEE ();
	
	
	virtual IEEE64 asIEEE64 ();
	
	
	virtual Int32 precision ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* accessing */

	
	virtual RPTR(PrimFloatValue) value ();
	
  private:
	IEEE32 myValue;
	friend class RealPos;
};  /* end class IEEE32Pos */



/* ************************************************************************ *
 * 
 *                    Class IEEE64Pos 
 *
 * ************************************************************************ */




	/* For representing exactly those real numbers that can be 
	represented in IEEE double precision */

class IEEE64Pos : public RealPos {

/* Attributes for class IEEE64Pos */
	CONCRETE(IEEE64Pos)
	COPY(IEEE64Pos,XppCuisine)
	NO_GC(IEEE64Pos)
  public: /* creation */

	
	IEEE64Pos (IEEE64 ARG(value), TCSJ);
	
  public: /* obsolete: */

	
	virtual IEEE64 asIEEE ();
	
	
	virtual IEEE64 asIEEE64 ();
	
	
	virtual Int32 precision ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* accessing */

	
	virtual RPTR(PrimFloatValue) value ();
	
  private:
	IEEE64 myValue;
	friend class RealPos;
};  /* end class IEEE64Pos */



/* ************************************************************************ *
 * 
 *                    Class IEEE8Pos 
 *
 * ************************************************************************ */




	/* For representing exactly those real numbers that can be 
	represented in IEEE stupid precision */

class IEEE8Pos : public RealPos {

/* Attributes for class IEEE8Pos */
	CONCRETE(IEEE8Pos)
	COPY(IEEE8Pos,XppCuisine)
	NO_GC(IEEE8Pos)
  public: /* creation */

	
	IEEE8Pos (IEEE8 ARG(value), TCSJ);
	
  public: /* obsolete: */

	
	virtual IEEE64 asIEEE ();
	
	
	virtual IEEE64 asIEEE64 ();
	
	
	virtual Int32 precision ();
	
  public: /* accessing */

	
	virtual RPTR(PrimFloatValue) value ();
	
  private:
	IEEE8 myValue;
	friend class RealPos;
};  /* end class IEEE8Pos */



/* ************************************************************************ *
 * 
 *                    Class RealDsp 
 *
 * ************************************************************************ */



/* Initializers for RealDsp */
/* Declaration inherited from IdentityDsp */




/* Declaration inherited from IdentityDsp */





	/* NO CLASS COMMENT */

class RealDsp : public IdentityDsp {

/* Attributes for class RealDsp */
	CONCRETE(RealDsp)
	COPY(RealDsp,XppCuisine)
	NOT_A_TYPE(RealDsp)
	NO_GC(RealDsp)

/* Initializers for RealDsp */
/* Declaration inherited from IdentityDsp */




/* Declaration inherited from IdentityDsp */

friend class INIT_TIME_NAME(RealDsp,initTimeInherited);

  public: /* creation */

	
	static RPTR(Dsp) make ();
	
  public: /* deferred accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	

	/* automatic 0-argument constructor */
  public:
	RealDsp();


  /* ---------- Static Member variables (class inst vars) ----------- */
  private:
	static IdentityDsp * theDsp;
};  /* end class RealDsp */



/* ************************************************************************ *
 * 
 *                    Class RealEdge 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class RealEdge : public TransitionEdge {

/* Attributes for class RealEdge */
	DEFERRED(RealEdge)
	COPY(RealEdge,XppCuisine)
	AUTO_GC(RealEdge)
  public: /* accessing */

	
	virtual RPTR(RealPos) position ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar follows (APTR(Position) ARG(pos)) DEFERRED_FUNC;
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other)) DEFERRED_FUNC;
	
	
	virtual BooleanVar isFollowedBy (APTR(TransitionEdge) ARG(next)) DEFERRED_FUNC;
	
	
	virtual BooleanVar isGE (APTR(TransitionEdge) ARG(other)) DEFERRED_FUNC;
	
	
	virtual BooleanVar touches (APTR(TransitionEdge) ARG(other));
	
  public: /* printing */

	
	virtual void printTransitionOn (
			ostream& ARG(oo), 
			BooleanVar ARG(entering), 
			BooleanVar ARG(touchesPrevious))
	 DEFERRED_SUBR;
	
  public: /* creation */

	
	RealEdge (APTR(RealPos) ARG(pos), TCSJ);
	
  private:
	CHKPTR(RealPos) myPos;
};  /* end class RealEdge */



/* ************************************************************************ *
 * 
 *                    Class   AfterReal 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class AfterReal : public RealEdge {

/* Attributes for class AfterReal */
	CONCRETE(AfterReal)
	COPY(AfterReal,XppCuisine)
	NOT_A_TYPE(AfterReal)
	NO_GC(AfterReal)
  public: /* create */

	
	static RPTR(RealEdge) make (APTR(RealPos) ARG(pos));
	
  public: /* comparing */

	
	virtual BooleanVar follows (APTR(Position) ARG(pos));
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFollowedBy (APTR(TransitionEdge) ARG(next));
	
	
	virtual BooleanVar isGE (APTR(TransitionEdge) ARG(other));
	
  public: /* printing */

	
	virtual void printTransitionOn (
			ostream& ARG(oo), 
			BooleanVar ARG(entering), 
			BooleanVar ARG(touchesPrevious))
	;
	
  public: /* creation */

	
	AfterReal (APTR(RealPos) ARG(pos), TCSJ);
	

};  /* end class AfterReal */



/* ************************************************************************ *
 * 
 *                    Class   BeforeReal 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class BeforeReal : public RealEdge {

/* Attributes for class BeforeReal */
	CONCRETE(BeforeReal)
	COPY(BeforeReal,XppCuisine)
	NOT_A_TYPE(BeforeReal)
	NO_GC(BeforeReal)
  public: /* create */

	
	static RPTR(RealEdge) make (APTR(RealPos) ARG(pos));
	
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
	
  public: /* creation */

	
	BeforeReal (APTR(RealPos) ARG(pos), TCSJ);
	

};  /* end class BeforeReal */



/* ************************************************************************ *
 * 
 *                    Class RealManager 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class RealManager : public EdgeManager {

/* Attributes for class RealManager */
	CONCRETE(RealManager)
	COPY(RealManager,XppCuisine)
	NO_GC(RealManager)
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
	
	
	INLINE Int32 transitionsCount (APTR(XnRegion) ARG(region));
	

	/* automatic 0-argument constructor */
  public:
	RealManager();

};  /* end class RealManager */



/* ************************************************************************ *
 * 
 *                    Class RealStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class RealStepper : public Stepper {

/* Attributes for class RealStepper */
	CONCRETE(RealStepper)
	NOT_A_TYPE(RealStepper)
	NO_GC(RealStepper)
  public: /* operations */

	/* If I am exhausted (i.e., if (! this->hasValue())), then 
	return NULL. Else return 
		current element.  I return wimpily since most items returned 
	are held by collections.
		If I create a new object, I should cache it. */
	
	virtual WPTR(Heaper) fetch ();
	
	/* Iff I have a current value (i.e. this message returns 
	true), then I am not 
		exhasted. 'fetch' and 'get' will both return this value, and 
	I can be 'step'ped to 
		my next state. As I am stepped, eventually I may become 
	exhausted (the 
		reverse of all the above), which is a permanent condition. 
		
		Note that not all steppers have to be exhaustable. A Stepper which 
		enumerates all primes is perfectly reasonable. Assuming 
	otherwise will create 
		infinite loops.  See class comment. */
	
	virtual BooleanVar hasValue ();
	
	/* Essential.  If I am currently exhausted (see 
	Stepper::hasValue()), then it is an error to step me. The 
	result of doing so isn't currently specified (we probably 
	should specify it to BLAST, but I know that the 
	implementation doesn't currently live up to that spec). 
		
		If I am not exhausted, then this advances me to my next 
	state. If my current value (see Stepper::get()) was my final 
	value, then I am now exhausted, otherwise my new current 
	value is the next value. */
	
	virtual void step ();
	
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
	
	
	RealStepper (APTR(PtrArray) ARG(transitions), TCSJ);
	

};  /* end class RealStepper */



/* ************************************************************************ *
 * 
 *                    Class RealUpOrder 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class RealUpOrder : public OrderSpec {

/* Attributes for class RealUpOrder */
	CONCRETE(RealUpOrder)
	COPY(RealUpOrder,XppCuisine)
	NOT_A_TYPE(RealUpOrder)
	NO_GC(RealUpOrder)
  public: /* creation */

	
	static RPTR(OrderSpec) make ();
	
  public: /* accessing */

	
	virtual RPTR(Arrangement) arrange (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar follows (APTR(Position) ARG(x), APTR(Position) ARG(y));
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFullOrder (APTR(XnRegion) ARG(keys) = NULL);
	
	
	virtual BooleanVar preceeds (APTR(XnRegion) ARG(before), APTR(XnRegion) ARG(after));
	

	/* automatic 0-argument constructor */
  public:
	RealUpOrder();

};  /* end class RealUpOrder */


#ifdef USE_INLINE
#ifndef REALP_IXX
#include "realp.ixx"
#endif /* REALP_IXX */


#endif /* USE_INLINE */


#endif /* REALP_HXX */

