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

#ifndef IDP_HXX
#define IDP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef IDX_HXX
#include "idx.hxx"
#endif /* IDX_HXX */

#ifndef IDP_OXX
#include "idp.oxx"
#endif /* IDP_OXX */


#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */


#ifndef INTEGERX_OXX
#include "integerx.oxx"
#endif /* INTEGERX_OXX */

#ifndef SEQUENCX_OXX
#include "sequencx.oxx"
#endif /* SEQUENCX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class IDSimpleStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class IDSimpleStepper : public Stepper {

/* Attributes for class IDSimpleStepper */
	CONCRETE(IDSimpleStepper)
	NOT_A_TYPE(IDSimpleStepper)
	AUTO_GC(IDSimpleStepper)
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	IDSimpleStepper (APTR(IDRegion) ARG(region), TCSJ);
	
	
	IDSimpleStepper (
			APTR(IDRegion) ARG(region), 
			APTR(Stepper) OF1(Sequence) ARG(backends), 
			APTR(Stepper) OF1(XnRegion) ARG(iDs), 
			APTR(IDRegion) OR(NULL) ARG(inexplicit))
	;
	
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  private:
	CHKPTR(IDRegion) myRegion;
	CHKPTR(Stepper) OF1(Sequence) OR(NULL) myBackends;
	CHKPTR(Stepper) OF1(XnRegion OF1(Integer)) OR(NULL) myIDs;
	CHKPTR(IDRegion) OR(NULL) myValue;
	CHKPTR(IDRegion) OR(NULL) myInexplicit;
};  /* end class IDSimpleStepper */



/* ************************************************************************ *
 * 
 *                    Class IDStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class IDStepper : public Stepper {

/* Attributes for class IDStepper */
	CONCRETE(IDStepper)
	NOT_A_TYPE(IDStepper)
	AUTO_GC(IDStepper)
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	IDStepper (APTR(IDRegion) ARG(region), TCSJ);
	
	
	IDStepper (
			APTR(IDRegion) ARG(region), 
			APTR(Stepper) OF1(Sequence) ARG(backends), 
			APTR(Stepper) OF1(IntegerPos) ARG(iDs))
	;
	
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  private:
	CHKPTR(IDRegion) myRegion;
	CHKPTR(Stepper) OF1(Sequence) OR(NULL) myBackends;
	CHKPTR(Stepper) OF1(IntegerPos) OR(NULL) myIDs;
	CHKPTR(ID) OR(NULL) myValue;
};  /* end class IDStepper */



/* ************************************************************************ *
 * 
 *                    Class IDUpOrder 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class IDUpOrder : public OrderSpec {

/* Attributes for class IDUpOrder */
	CONCRETE(IDUpOrder)
	COPY(IDUpOrder,DiskCuisine)
	NOT_A_TYPE(IDUpOrder)
	AUTO_GC(IDUpOrder)
  public: /* pseudo constructors */

	
	static RPTR(OrderSpec) make (APTR(IDSpace) ARG(space));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar follows (APTR(Position) ARG(x), APTR(Position) ARG(y));
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
	
	virtual BooleanVar isFullOrder (APTR(XnRegion) ARG(keys) = NULL);
	
	/* Return true if some position in before is less than or 
	equal to all positions in after. */
	
	virtual BooleanVar preceeds (APTR(XnRegion) ARG(before), APTR(XnRegion) ARG(after));
	
  public: /* accessing */

	
	virtual RPTR(Arrangement) arrange (APTR(XnRegion) ARG(region));
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
  public: /* create */

	
	IDUpOrder (APTR(IDSpace) ARG(space), TCSJ);
	
  private:
	CHKPTR(IDSpace) myIDSpace;
};  /* end class IDUpOrder */



#endif /* IDP_HXX */

