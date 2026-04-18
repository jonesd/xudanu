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

#ifndef CROSST_HXX
#define CROSST_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef CROSSX_HXX
#include "crossx.hxx"
#endif /* CROSSX_HXX */

#ifndef CROSST_OXX
#include "crosst.oxx"
#endif /* CROSST_OXX */


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
 *                    Class CrossTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class CrossTester : public RegionTester {

/* Attributes for class CrossTester */
	CONCRETE(CrossTester)
	COPY(CrossTester,BootCuisine)
	NOT_A_TYPE(CrossTester)
	NO_GC(CrossTester)
  public: /* init */

	
	virtual RPTR(ImmuSet) OF1(XnRegion) initExamples ();
	

	/* automatic 0-argument constructor */
  public:
	CrossTester();

};  /* end class CrossTester */



#endif /* CROSST_HXX */

