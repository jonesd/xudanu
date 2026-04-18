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

#ifndef CROSST_CXX
#define CROSST_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef CROSST_HXX
#include "crosst.hxx"
#endif /* CROSST_HXX */

#ifndef CROSST_IXX
#include "crosst.ixx"
#endif /* CROSST_IXX */


#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef PRIMVALX_HXX
#include "primvalx.hxx"
#endif /* PRIMVALX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */




/* ************************************************************************ *
 * 
 *                    Class CrossTester 
 *
 * ************************************************************************ */


/* init */


RPTR(ImmuSet) OF1(XnRegion) CrossTester::initExamples (){
	SPTR(SetAccumulator) result;
	SPTR(CrossSpace) space;
	SPTR(PtrArray) OF1(XnRegion) regions;
	SPTR(PtrArray) OF1(XnRegion) crosses;
	
	result = SetAccumulator::make ();
	space = CrossSpace::make (CAST(PtrArray,PrimSpec::pointer()->arrayWithThree(IntegerSpace::make (), IntegerSpace::make (), IntegerSpace::make ())));
	regions = PtrArray::nulls(3);
	regions->store(Int32Zero, IntegerRegion::make (Int32Zero, 10));
	regions->store(1, IntegerRegion::make (5, 15));
	regions->store(2, IntegerRegion::make (10, 20));
	crosses = PtrArray::nulls(3);
	{
		Int32 LoopFinal = 27;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				crosses->store(Int32Zero, regions->fetch(i % 3));
				crosses->store(1, regions->fetch(i / 3 % 3));
				crosses->store(2, regions->fetch(i / 9));
				result->step(space->crossOfRegions(crosses));
			}
			i += 1;
		}
	}
	return CAST(ImmuSet,result->value());
}

	/* automatic 0-argument constructor */
CrossTester::CrossTester() {}

#ifndef CROSST_SXX
#include "crosst.sxx"
#endif /* CROSST_SXX */



#endif /* CROSST_CXX */

