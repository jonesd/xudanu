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

#ifndef STEPPERP_HXX
#define STEPPERP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */

#ifndef STEPPERP_OXX
#include "stepperp.oxx"
#endif /* STEPPERP_OXX */


#ifndef CACHEX_OXX
#include "cachex.oxx"
#endif /* CACHEX_OXX */

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
 *                    Class EmptyStepper 
 *
 * ************************************************************************ */




	/* This is a Stepper when you just want to step across a 
	single item. */

class EmptyStepper : public Stepper {

/* Attributes for class EmptyStepper */
	CONCRETE(EmptyStepper)
	NOT_A_TYPE(EmptyStepper)
	NO_GC(EmptyStepper)
  protected: /* protected: destruct */

	/* This object is a canonical single instance, so its 
	destructor should only be called after main has exited. */
	
	virtual void destruct ();
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	/* No */
	
	virtual void destroy ();
	
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	

	/* automatic 0-argument constructor */
  public:
	EmptyStepper();

};  /* end class EmptyStepper */



/* ************************************************************************ *
 * 
 *                    Class ItemStepper 
 *
 * ************************************************************************ */



/* Initializers for ItemStepper */







	/* This is a Stepper when you just want to step across a 
	single item. */

class ItemStepper : public Stepper {

/* Attributes for class ItemStepper */
	CONCRETE(ItemStepper)
	NOT_A_TYPE(ItemStepper)
	AUTO_GC(ItemStepper)

/* Initializers for ItemStepper */



friend class INIT_TIME_NAME(ItemStepper,initTimeNonInherited);

  public: /* create */

	
	static RPTR(Stepper) make (APTR(Heaper) ARG(item));
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	ItemStepper (APTR(Heaper) OR(NULL) ARG(item), TCSJ);
	
	
	virtual void destroy ();
	
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  private:
	CHKPTR(Heaper) OR(NULL) myItem;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(InstanceCache) SomeSteppers;
};  /* end class ItemStepper */



/* ************************************************************************ *
 * 
 *                    Class PtrArrayAccumulator 
 *
 * ************************************************************************ */




	/* To save array copies, this class will hand out its 
	internal array if the size is right.  If it does so it 
	remembers so that if new elements are introduced, a copy can 
	be made for further use. */

class PtrArrayAccumulator : public Accumulator {

/* Attributes for class PtrArrayAccumulator */
	CONCRETE(PtrArrayAccumulator)
	NOT_A_TYPE(PtrArrayAccumulator)
	AUTO_GC(PtrArrayAccumulator)
  public: /* operations */

	
	virtual RPTR(Accumulator) copy ();
	
	
	virtual void step (APTR(Heaper) ARG(x));
	
	
	virtual RPTR(Heaper) value ();
	
  public: /* create */

	
	PtrArrayAccumulator ();
	
	
	PtrArrayAccumulator (UInt32 ARG(count), TCSJ);
	
	
	PtrArrayAccumulator (APTR(PtrArray) ARG(values), UInt32 ARG(n));
	
  private:
	CHKPTR(PtrArray) myValues;
	UInt4 myN;
	BooleanVar myValuesGiven;
	friend class Accumulator;
};  /* end class PtrArrayAccumulator */



/* ************************************************************************ *
 * 
 *                    Class PtrArrayStepper 
 *
 * ************************************************************************ */




	/* A Stepper for stepping over the elements of a PtrArray in 
	ascending or descending order.  This is a TableStepper even 
	though it is stepping over a PtrArray instead of a table.  
	Should probably eventually be generalized to PrimArrays. NOT.A.TYPE */

class PtrArrayStepper : public TableStepper {

/* Attributes for class PtrArrayStepper */
	CONCRETE(PtrArrayStepper)
	COPY(PtrArrayStepper,XppCuisine)
	AUTO_GC(PtrArrayStepper)
  public: /* creation */

	/* Note: this being a low level operation, and there being no 
	lightweight form of immutable or lazily copied PtrArray, it 
	is my caller's responsibility to pass me a PtrArray which 
	will in fact not be changed during the life of this stepper.  
	This is an unchecked an uncheckable precondition on my clients. */
	
	static RPTR(TableStepper) ascending (APTR(PtrArray) ARG(array));
	
	/* Note: this being a low level operation, and there being no 
	lightweight form of immutable or lazily copied PtrArray, it 
	is my caller's responsibility to pass me a PtrArray which 
	will in fact not be changed during the life of this stepper.  
	This is an unchecked an uncheckable precondition on my clients. */
	
	static RPTR(TableStepper) descending (APTR(PtrArray) ARG(array));
	
  public: /* operations */

	
	virtual RPTR(Stepper) copy ();
	
	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* special */

	
	virtual IntegerVar index ();
	
	
	virtual RPTR(Position) position ();
	
  private: /* private: creation */

	
	PtrArrayStepper (
			APTR(PtrArray) ARG(array), 
			Int32 ARG(start), 
			Int32 ARG(pastEnd), 
			Int32 ARG(step))
	;
	
  private:
	CHKPTR(PtrArray) OF1(Heaper) myArray;
	Int32 myIndex;
	Int32 myPastEnd;
	Int32 myStep;
};  /* end class PtrArrayStepper */



#endif /* STEPPERP_HXX */

