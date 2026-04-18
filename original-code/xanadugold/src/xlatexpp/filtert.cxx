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

#ifndef FILTERT_CXX
#define FILTERT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef FILTERT_HXX
#include "filtert.hxx"
#endif /* FILTERT_HXX */

#ifndef FILTERT_IXX
#include "filtert.ixx"
#endif /* FILTERT_IXX */


#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */




/* ************************************************************************ *
 * 
 *                    Class FilterTester 
 *
 * ************************************************************************ */


/* creation */


FilterTester::FilterTester () {
	myBaseRegions = NULL;
}
/* init */


RPTR(ImmuSet) OF1(XnRegion) FilterTester::initExamples (){
	SPTR(SetAccumulator) OF1(XnRegion) acc;
	SPTR(SetAccumulator) OF1(Filter) result;
	SPTR(FilterSpace) space;
	SPTR(ImmuSet) simple;
	
	acc = SetAccumulator::make ();
	acc->step(IntegerRegion::make ());
	acc->step(IntegerRegion::make (3));
	acc->step(IntegerRegion::make (1, 7));
	acc->step(IntegerRegion::make (5, 7));
	acc->step(IntegerRegion::make (5, 9));
	BEGIN_FOR_EACH(XnRegion,each,(CAST(ImmuSet,acc->value())->stepper())) {
		acc->step(each->complement());
	} END_FOR_EACH;
	myBaseRegions = CAST(ImmuSet,acc->value());
	result = SetAccumulator::make ();
	space = FilterSpace::make (IntegerSpace::make ());
	BEGIN_FOR_EACH(XnRegion,region,(myBaseRegions->stepper())) {
		result->step(Filter::subsetFilter(space, region));
		result->step(Filter::notSubsetFilter(space, region));
		result->step(Filter::supersetFilter(space, region));
		result->step(Filter::notSupersetFilter(space, region));
	} END_FOR_EACH;
	simple = CAST(ImmuSet,result->value());
	BEGIN_FOR_EACH(Filter,one,(simple->stepper())) {
		BEGIN_FOR_EACH(Filter,two,(simple->stepper())) {
			if (one->hashForEqual() < two->hashForEqual()) {
				result->step(one->unionWith(two));
				result->step(one->intersect(two));
			}
		} END_FOR_EACH;
	} END_FOR_EACH;
	return CAST(ImmuSet,result->value());
}
/* testing */


void FilterTester::binaryCheck (APTR(XnRegion) a, APTR(XnRegion) b){
	SPTR(Filter) af;
	SPTR(Filter) bf;
	
	af = CAST(Filter,a);
	bf = CAST(Filter,b);
	this->RegionTester::binaryCheck(af, bf);
	if (af->isSubsetOf(bf)) {
		BEGIN_FOR_EACH(XnRegion,each,(myBaseRegions->stepper())) {
			if ( ! (!af->match(each) || bf->match(each)) ) {
				BLAST(subset_match_test_failed);
			}
		} END_FOR_EACH;
	}
}


void FilterTester::unaryCheck (APTR(XnRegion) a){
	this->RegionTester::unaryCheck(a);
	BEGIN_FOR_EACH(XnRegion,each,(myBaseRegions->stepper())) {
		if ( ! (CAST(Filter,a)->match(each) != CAST(Filter,a->complement())->match(each)) ) {
			BLAST(complement_match_test_failed);
		}
	} END_FOR_EACH;
}
/* hooks: */


void FilterTester::restartFilterTester (APTR(Rcvr) /* rcvr *//* = NULL*/){
	myBaseRegions = NULL;
}

#ifndef FILTERT_SXX
#include "filtert.sxx"
#endif /* FILTERT_SXX */



#endif /* FILTERT_CXX */

