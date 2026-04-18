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

#ifndef SPACER_HXX
#define SPACER_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */

#ifndef SPACER_OXX
#include "spacer.oxx"
#endif /* SPACER_OXX */


#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */


#ifndef INTEGERX_OXX
#include "integerx.oxx"
#endif /* INTEGERX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class ExplicitArrangement 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ExplicitArrangement : public Arrangement {

/* Attributes for class ExplicitArrangement */
	CONCRETE(ExplicitArrangement)
	COPY(ExplicitArrangement,XppCuisine)
	NOT_A_TYPE(ExplicitArrangement)
	AUTO_GC(ExplicitArrangement)
  public: /* create */

	
	static RPTR(Arrangement) make (APTR(PtrArray) OF1(Position) ARG(positions));
	
  public: /* create */

	
	ExplicitArrangement (APTR(PtrArray) OF1(Position) ARG(positions), TCSJ);
	
  public: /* accessing */

	
	virtual IntegerVar indexOf (APTR(Position) ARG(position));
	
	
	virtual RPTR(IntegerRegion) indicesOf (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(XnRegion) keysOf (Int32 ARG(start), Int32 ARG(stop));
	
	
	virtual RPTR(XnRegion) region ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual UInt32 hashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  private: /* private: accessing */

	
	virtual RPTR(PtrArray) positions ();
	
  private:
	CHKPTR(PtrArray) OF1(Position) myPositions;
};  /* end class ExplicitArrangement */



/* ************************************************************************ *
 * 
 *                    Class IdentityDsp 
 *
 * ************************************************************************ */



/* Initializers for IdentityDsp */

	/* An implementation sharing convenience for Dsp classes 
	which only provide the identity mapping functionality for 
	their coordinate spaces.  This provides everything except the 
	coordinate space itself (which must be provided by the 
	subclass).  Will eventually be declared NOT_A_TYPE, so don't 
	use it in type declarations.  
		
		Assumes that if a given space uses it as its identity Dsp, 
	then the one cached instance will be the only identity Dsp 
	for that space.  I.e., I do equality comparison as an EQ 
	object.  If this assumpsion isn't true, please override 
	isEqual and hashForEqual.  See PathDsp.
		
		IdentityDsp is in module "unorder" because typically 
	unordered spaces will only have an identity Dsp and so want 
	to subclass this class.  Non-unordered spaces should also 
	feel free to use this as appropriate. */

class IdentityDsp : public Dsp {

/* Attributes for class IdentityDsp */
	DEFERRED(IdentityDsp)
	NOT_A_TYPE(IdentityDsp)
	NO_GC(IdentityDsp)

/* Initializers for IdentityDsp */  public: /* creation */

	
	IdentityDsp ();
	
  public: /* transforming */

	
	virtual RPTR(Position) inverseOf (APTR(Position) ARG(pos));
	
	
	virtual RPTR(XnRegion) inverseOfAll (APTR(XnRegion) ARG(reg));
	
	
	virtual RPTR(Position) of (APTR(Position) ARG(pos));
	
	
	virtual RPTR(XnRegion) ofAll (APTR(XnRegion) ARG(reg));
	
  public: /* combining */

	
	virtual RPTR(Dsp) compose (APTR(Dsp) ARG(other));
	
	
	virtual RPTR(Mapping) inverse ();
	
	
	virtual RPTR(Dsp) inverseCompose (APTR(Dsp) ARG(other));
	
	
	virtual RPTR(Dsp) minus (APTR(Dsp) ARG(other));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* accessing */

	
	virtual BooleanVar isIdentity ();
	
  public: /* deferred accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace () DEFERRED_FUNC;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	


  /* ---------- Static Member variables (class inst vars) ----------- */
  private:
	static IdentityDsp * theDsp;
/* Friends for class IdentityDsp */
/* friends for class IdentityDsp */
friend SPTR(Dsp) dsp(CoordinateSpace*);
friend SPTR(Dsp) dsp(IntegerVar);


};  /* end class IdentityDsp */



/* ************************************************************************ *
 * 
 *                    Class MergeStepper 
 *
 * ************************************************************************ */




	/* A Stepper for doing a merge-sort like ordered interleaving 
	of two other steppers.  It is assumed that the other two 
	steppers are constructed so that their values are also 
	produced in order according to the same OrderSpec.  A tree of 
	these operates much like a heap as found in heapsort. */

class MergeStepper : public Stepper {

/* Attributes for class MergeStepper */
	CONCRETE(MergeStepper)
	COPY(MergeStepper,XppCuisine)
	NOT_A_TYPE(MergeStepper)
	AUTO_GC(MergeStepper)
  public: /* pseudoconstructors */

	
	static RPTR(Stepper) make (
			APTR(Stepper) OF1(Position) ARG(a), 
			APTR(Stepper) OF1(Position) ARG(b), 
			APTR(OrderSpec) ARG(order))
	;
	
  public: /* operations */

	
	virtual RPTR(Stepper) copy ();
	
	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  private: /* private: creation */

	
	MergeStepper (
			APTR(Stepper) OF1(Position) ARG(a), 
			APTR(Stepper) OF1(Position) ARG(b), 
			APTR(OrderSpec) ARG(order), 
			APTR(Position) OR(NULL) ARG(value))
	;
	
  private:
	CHKPTR(Stepper) OF1(Position) myA;
	CHKPTR(Stepper) OF1(Position) myB;
	CHKPTR(OrderSpec) myOrder;
	CHKPTR(Position) OR(NULL) myValue;
};  /* end class MergeStepper */



#endif /* SPACER_HXX */

