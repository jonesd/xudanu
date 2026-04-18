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

#ifndef INTEGERT_HXX
#define INTEGERT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef INTEGERT_OXX
#include "integert.oxx"
#endif /* INTEGERT_OXX */


#ifndef SPACET_HXX
#include "spacet.hxx"
#endif /* SPACET_HXX */


#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class IntegerRegionTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class IntegerRegionTester : public RegionTester {

/* Attributes for class IntegerRegionTester */
	CONCRETE(IntegerRegionTester)
	COPY(IntegerRegionTester,BootCuisine)
	NO_GC(IntegerRegionTester)
  public: /* init */

	/* IntegerRegionTester runTest */
	
	virtual RPTR(ImmuSet) OF1(XnRegion) initExamples ();
	

	/* automatic 0-argument constructor */
  public:
	IntegerRegionTester();

};  /* end class IntegerRegionTester */



#endif /* INTEGERT_HXX */

