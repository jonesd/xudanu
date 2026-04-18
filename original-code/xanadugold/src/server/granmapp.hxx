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

#ifndef GRANMAPP_HXX
#define GRANMAPP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef GRANMAPX_HXX
#include "granmapx.hxx"
#endif /* GRANMAPX_HXX */

#ifndef GRANMAPP_OXX
#include "granmapp.oxx"
#endif /* GRANMAPP_OXX */


#ifndef BOOTPLNX_HXX
#include "bootplnx.hxx"
#endif /* BOOTPLNX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */


#ifndef BRANGE3X_OXX
#include "brange3x.oxx"
#endif /* BRANGE3X_OXX */

#ifndef COOKBKX_OXX
#include "cookbkx.oxx"
#endif /* COOKBKX_OXX */

#ifndef IDX_OXX
#include "idx.oxx"
#endif /* IDX_OXX */

#ifndef NKERNELX_OXX
#include "nkernelx.oxx"
#endif /* NKERNELX_OXX */

#ifndef RECIPEX_OXX
#include "recipex.oxx"
#endif /* RECIPEX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class BackendBootMaker 
 *
 * ************************************************************************ */



/* Initializers for BackendBootMaker */




	/* NO CLASS COMMENT */

class BackendBootMaker : public BootMaker {

/* Attributes for class BackendBootMaker */
	CONCRETE(BackendBootMaker)
	COPY(BackendBootMaker,BootCuisine)
	NOT_A_TYPE(BackendBootMaker)
	NO_GC(BackendBootMaker)

/* Initializers for BackendBootMaker */
friend class INIT_TIME_NAME(BackendBootMaker,initTimeNonInherited);

  public: /* creation */

	
	static RPTR(BootPlan) make ();
	
  public: /* accessing */

	
	virtual RPTR(Category) bootCategory ();
	
  protected: /* protected: */

	
	virtual RPTR(Heaper) bootHeaper ();
	

	/* automatic 0-argument constructor */
  public:
	BackendBootMaker();

};  /* end class BackendBootMaker */



/* ************************************************************************ *
 * 
 *                    Class GrantStepper 
 *
 * ************************************************************************ */




	/* Has a Bundle Stepper on a piece of the Edition defining 
	the grants for this Server, and views it as a sequence of 
	associations from ClubIDs to IDRegions (which is the inverse 
	of its actual format) */

class GrantStepper : public TableStepper {

/* Attributes for class GrantStepper */
	CONCRETE(GrantStepper)
	NOT_A_TYPE(GrantStepper)
	AUTO_GC(GrantStepper)
  public: /* create */

	
	static RPTR(TableStepper) make (APTR(BeEdition) ARG(grants), APTR(IDRegion) OR(NULL) ARG(clubIDs));
	
  public: /* special */

	
	virtual RPTR(Position) position ();
	
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	GrantStepper (APTR(Stepper) OF1(FeBundle) ARG(bundles), APTR(IDRegion) OR(NULL) ARG(clubIDs));
	
  private:
	CHKPTR(Stepper) OF1(FeBundle) myBundles;
	CHKPTR(IDRegion) OR(NULL) myClubIDs;
};  /* end class GrantStepper */



#endif /* GRANMAPP_HXX */

