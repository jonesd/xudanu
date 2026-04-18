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

#ifndef LOAVESR_HXX
#define LOAVESR_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef LOAVESX_HXX
#include "loavesx.hxx"
#endif /* LOAVESX_HXX */

#ifndef LOAVESR_OXX
#include "loavesr.oxx"
#endif /* LOAVESR_OXX */


#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */


#ifndef NKERNELX_OXX
#include "nkernelx.oxx"
#endif /* NKERNELX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class MergeBundlesStepper 
 *
 * ************************************************************************ */




	/* A Stepper for doing a merge-sort like ordered interleaving 
	of two other steppers.  It is assumed that the other two 
	steppers are constructed so that their values are also 
	produced in order according to the same OrderSpec.  A tree of 
	these operates much like a heap as found in heapsort. */

class MergeBundlesStepper : public Stepper {

/* Attributes for class MergeBundlesStepper */
	CONCRETE(MergeBundlesStepper)
	COPY(MergeBundlesStepper,DiskCuisine)
	NOT_A_TYPE(MergeBundlesStepper)
	AUTO_GC(MergeBundlesStepper)
  public: /* creation */

	
	static RPTR(Stepper) make (
			APTR(Stepper) OF1(FeBundle) ARG(a), 
			APTR(Stepper) OF1(FeBundle) ARG(b), 
			APTR(OrderSpec) ARG(order))
	;
	
  public: /* operations */

	
	virtual RPTR(Stepper) copy ();
	
	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  private: /* private: creation */

	
	MergeBundlesStepper (
			APTR(Stepper) OF1(Position) ARG(a), 
			APTR(Stepper) OF1(Position) ARG(b), 
			APTR(OrderSpec) ARG(order), 
			APTR(FeBundle) OR(NULL) ARG(value))
	;
	
  private:
	CHKPTR(Stepper) OF1(FeBundle) myA;
	CHKPTR(Stepper) OF1(FeBundle) myB;
	CHKPTR(OrderSpec) myOrder;
	CHKPTR(FeBundle) OR(NULL) myValue;
};  /* end class MergeBundlesStepper */



#endif /* LOAVESR_HXX */

