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

#ifndef SETTABP_HXX
#define SETTABP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SETTABX_HXX
#include "settabx.hxx"
#endif /* SETTABX_HXX */

#ifndef SETTABP_OXX
#include "settabp.oxx"
#endif /* SETTABP_OXX */


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
 *                    Class SetTableStepper 
 *
 * ************************************************************************ */



/* Initializers for SetTableStepper */




	/* NO CLASS COMMENT */

class SetTableStepper : public Stepper {

/* Attributes for class SetTableStepper */
	CONCRETE(SetTableStepper)
	EQ(SetTableStepper)
	AUTO_GC(SetTableStepper)

/* Initializers for SetTableStepper */


  public: /* create */

	
	static RPTR(SetTableStepper) make (APTR(PtrArray) ARG(array));
	
  public: /* accessing */

	
	static RPTR(PtrArray) array ();
	
  public: /* accessing */

	
	virtual RPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	virtual void destroy ();
	
  protected: /* protected: create */

	
	SetTableStepper (APTR(PtrArray) ARG(array), TCSJ);
	
	
	SetTableStepper (APTR(PtrArray) ARG(array), Int32 ARG(index));
	
  private:
	CHKPTR(PtrArray) myPtrs;
	Int32 myIndex;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(PtrArray) AnArray;
	static GPTR(SetTableStepper) AStepper;
};  /* end class SetTableStepper */



#endif /* SETTABP_HXX */

