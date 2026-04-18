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

#ifndef INTEGERT_CXX
#define INTEGERT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef INTEGERT_HXX
#include "integert.hxx"
#endif /* INTEGERT_HXX */

#ifndef INTEGERT_IXX
#include "integert.ixx"
#endif /* INTEGERT_IXX */


#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */




/* ************************************************************************ *
 * 
 *                    Class IntegerRegionTester 
 *
 * ************************************************************************ */


/* init */


RPTR(ImmuSet) OF1(XnRegion) IntegerRegionTester::initExamples (){
	/* IntegerRegionTester runTest */
	
	SPTR(SetAccumulator) OF1(XnRegion) acc;
	
	acc = SetAccumulator::make ();
	acc->step(IntegerRegion::make ());
	acc->step(IntegerRegion::make ()->complement());
	acc->step(IntegerRegion::make (3, 7));
	acc->step(IntegerRegion::make (3, 7)->complement());
	acc->step(IntegerRegion::after(5));
	acc->step(IntegerRegion::before(5));
	return CAST(ImmuSet,acc->value());
}

	/* automatic 0-argument constructor */
IntegerRegionTester::IntegerRegionTester() {}

#ifndef INTEGERT_SXX
#include "integert.sxx"
#endif /* INTEGERT_SXX */



#endif /* INTEGERT_CXX */

