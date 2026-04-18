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

#ifndef REALT_HXX
#define REALT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef REALX_HXX
#include "realx.hxx"
#endif /* REALX_HXX */

#ifndef REALT_OXX
#include "realt.oxx"
#endif /* REALT_OXX */


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
 *                    Class RealTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class RealTester : public RegionTester {

/* Attributes for class RealTester */
	CONCRETE(RealTester)
	COPY(RealTester,BootCuisine)
	NO_GC(RealTester)
  public: /* deferred: init */

	
	virtual RPTR(ImmuSet) OF1(XnRegion) initExamples ();
	

	/* automatic 0-argument constructor */
  public:
	RealTester();

};  /* end class RealTester */



#endif /* REALT_HXX */

