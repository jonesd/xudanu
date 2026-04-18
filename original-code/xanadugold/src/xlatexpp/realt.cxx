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

#ifndef REALT_CXX
#define REALT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef REALT_HXX
#include "realt.hxx"
#endif /* REALT_HXX */

#ifndef REALT_IXX
#include "realt.ixx"
#endif /* REALT_IXX */


#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */




/* ************************************************************************ *
 * 
 *                    Class RealTester 
 *
 * ************************************************************************ */


/* deferred: init */


RPTR(ImmuSet) OF1(XnRegion) RealTester::initExamples (){
	SPTR(SetAccumulator) reals;
	SPTR(SetAccumulator) result;
	SPTR(ImmuSet) base;
	
	reals = SetAccumulator::make ();
	reals->step(RealPos::make (0.0));
	reals->step(RealPos::make (1.0));
	reals->step(RealPos::make (2.0));
	result = SetAccumulator::make ();
	BEGIN_FOR_EACH(RealPos,real,(CAST(ScruSet,reals->value())->stepper())) {
		result->step(RealSpace::make ()->above(real, TRUE));
		result->step(RealSpace::make ()->above(real, FALSE));
		result->step(RealSpace::make ()->below(real, TRUE));
		result->step(RealSpace::make ()->below(real, FALSE));
	} END_FOR_EACH;
	base = CAST(ImmuSet,result->value());
	BEGIN_FOR_EACH(RealRegion,r,(base->stepper())) {
		BEGIN_FOR_EACH(RealRegion,r2,(base->stepper())) {
			if (r->hashForEqual() < r2->hashForEqual()) {
				result->step(r->unionWith(r2));
				result->step(r->intersect(r2));
			}
		} END_FOR_EACH;
	} END_FOR_EACH;
	return CAST(ImmuSet,result->value());
}

	/* automatic 0-argument constructor */
RealTester::RealTester() {}

#ifndef REALT_SXX
#include "realt.sxx"
#endif /* REALT_SXX */



#endif /* REALT_CXX */

