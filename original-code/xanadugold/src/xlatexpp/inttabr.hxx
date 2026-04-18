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

#ifndef INTTABR_HXX
#define INTTABR_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef INTTABX_HXX
#include "inttabx.hxx"
#endif /* INTTABX_HXX */

#ifndef INTTABR_OXX
#include "inttabr.oxx"
#endif /* INTTABR_OXX */


#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */


#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class IntegerTableStepper 
 *
 * ************************************************************************ */




	/* Consider this a protected class.  It is public only for 
	use by the "array" module. */

class IntegerTableStepper : public TableStepper {

/* Attributes for class IntegerTableStepper */
	DEFERRED(IntegerTableStepper)
	NO_GC(IntegerTableStepper)
  public: /* pseudoConstructors */

	/* Do not consider public.  Only for use by the modules 
	inttab, array, and awarray. */
	
	static RPTR(IntegerTableStepper) make (APTR(IntegerTable) ARG(aTable), APTR(OrderSpec) ARG(anOrder) = NULL);
	
	/* Do not consider public.  Only for use by the modules 
	inttab, array, and awarray. */
	
	static RPTR(IntegerTableStepper) make (
			APTR(IntegerTable) ARG(aTable), 
			IntegerVar ARG(start), 
			IntegerVar ARG(stop))
	;
	
  public: /* operations */

	
	virtual WPTR(Heaper) fetch () DEFERRED_FUNC;
	
	
	virtual WPTR(Heaper) get ();
	
	
	virtual BooleanVar hasValue () DEFERRED_FUNC;
	
	
	virtual void step () DEFERRED_SUBR;
	
  public: /* special */

	
	virtual RPTR(Position) position () DEFERRED_FUNC;
	
  public: /* create */

	
	virtual RPTR(Stepper) copy () DEFERRED_FUNC;
	

	/* automatic 0-argument constructor */
  public:
	IntegerTableStepper();

};  /* end class IntegerTableStepper */



#endif /* INTTABR_HXX */

