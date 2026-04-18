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

#ifndef SPACET_CXX
#define SPACET_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef SPACET_HXX
#include "spacet.hxx"
#endif /* SPACET_HXX */

#ifndef SPACET_IXX
#include "spacet.ixx"
#endif /* SPACET_IXX */


#ifndef BOMBX_HXX
#include "bombx.hxx"
#endif /* BOMBX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */




/* ************************************************************************ *
 * 
 *                    Class RegionTester 
 *
 * ************************************************************************ */


/* deferred: init */
/* testing */


void RegionTester::allTestsOn (ostream& oo){
	myExampleRegions = this->initExamples();
	this->testExtraOn(oo);
	this->testUnaryRegionOpsOn(oo);
	this->testBinaryRegionOpsOn(oo);
}


void RegionTester::binaryCheck (APTR(XnRegion) a, APTR(XnRegion) b){
	SPTR(XnRegion) anb;
	SPTR(XnRegion) amb;
	SPTR(XnRegion) aub;
	
	anb = a->intersect(b);
	if ( ! (anb->isEqual(b->intersect(a))) ) {
		BLAST(intersect_test_failed_);
	}
	if ( ! (anb->isSubsetOf(a)) ) {
		BLAST(intersect_subset_test_failed_);
	}
	if ( ! (anb->isSubsetOf(b)) ) {
		BLAST(intersect_subset_test_failed_);
	}
	if ( ! (a->intersects(b) == !anb->isEmpty()) ) {
		BLAST(intersects_test_failed_);
	}
	amb = a->minus(b);
	if ( amb->intersects(b) ) {
		BLAST(minus_intersect_test_failed_);
	}
	if ( ! (amb->isSubsetOf(a)) ) {
		BLAST(minus_subset_test_failed_);
	}
	aub = a->unionWith(b);
	if ( ! (aub->isEqual(b->unionWith(a))) ) {
		BLAST(unionWith_test_failed_);
	}
	if ( ! (a->isSubsetOf(aub)) ) {
		BLAST(union_subset_test_failed_);
	}
	if ( ! (b->isSubsetOf(aub)) ) {
		BLAST(union_subset_test_failed_);
	}
	if ( ! ((a->isSubsetOf(b) && b->isSubsetOf(a)) == a->isEqual(b)) ) {
		BLAST(subset_equals_test_failed_);
	}
}


void RegionTester::testBinaryRegionOpsOn (ostream& oo){
	BEGIN_FOR_EACH(XnRegion,one,(myExampleRegions->stepper())) {
		BEGIN_FOR_EACH(XnRegion,two,(myExampleRegions->stepper())) {
			if (one->hashForEqual() <= two->hashForEqual()) {
				do {
					INSTALL_SHIELD(ex);
					SHIELD_UP_BEGIN(ex, AllBlastsFilter) {
						Problem * prob;
						
						prob = &PROBLEM(ex);
						
						
						
						operator<<(cerr,prob);
						
						cerr << "\n";
						oo << "problem checking binary ops of " << one << " and " << two << "\n";
						break;
					} SHIELD_UP_END(ex);
					this->binaryCheck(one, two);
				} while (FALSE);
			}
		} END_FOR_EACH;
	} END_FOR_EACH;
	oo << "binary regions tests succeeded\n";
}


void RegionTester::testExtraOn (ostream& oo){
	
}


void RegionTester::testUnaryRegionOpsOn (ostream& oo){
	BEGIN_FOR_EACH(XnRegion,one,(myExampleRegions->stepper())) {
		do {
			INSTALL_SHIELD(ex);
			SHIELD_UP_BEGIN(ex, AllBlastsFilter) {
				Problem * prob;
				
				prob = &PROBLEM(ex);
				
				
				
				operator<<(cerr,prob);
				
				cerr << "\n";
				oo << "problem checking unary ops of " << one << "\n";
				break;
			} SHIELD_UP_END(ex);
			this->unaryCheck(one);
		} while (FALSE);
	} END_FOR_EACH;
	oo << "unary regions tests succeeded\n";
}


void RegionTester::unaryCheck (APTR(XnRegion) a){
	if ( ! (a->isEqual(a)) ) {
		BLAST(identity_test_failed_);
	}
	if ( ! (!a->isEmpty() == a->intersects(a)) ) {
		BLAST(intersects_test_failed_);
	}
	if ( ! (a->minus(a)->isEmpty()) ) {
		BLAST(self_minus_isEmpty_failed_);
	}
	if ( ! (a->isSubsetOf(a)) ) {
		BLAST(self_subset_test_failed_);
	}
	if ( ! (a->intersect(a)->isEqual(a)) ) {
		BLAST(intersect_isEqual_test_failed_);
	}
	if ( ! (a->isFull() == a->complement()->isEmpty()) ) {
		BLAST(infinity_inverse_test_failed_);
	}
	if ( ! (a->intersect(a->complement())->isEmpty()) ) {
		BLAST(intersect_complement_test_failed_);
	}
	if ( ! (a->minus(a->complement())->isEqual(a)) ) {
		BLAST(minus_complement_test_failed_);
	}
	if ( ! (a->complement()->complement()->isEqual(a)) ) {
		BLAST(double_complement_test_failed_);
	}
	if ( ! (a->unionWith(a->complement())->isFull()) ) {
		BLAST(union_complement_test_failed_);
	}
}
/* protected: accessing */


RPTR(ImmuSet) OF1(XnRegion) RegionTester::exampleRegions (){
	return (ImmuSet*) myExampleRegions;
}
/* protected: creation */


RegionTester::RegionTester () {
	myExampleRegions = NULL;
}
/* hooks: */


void RegionTester::restartRegionTester (APTR(Rcvr) /* rcvr *//* = NULL*/){
	myExampleRegions = NULL;
}

#ifndef SPACET_SXX
#include "spacet.sxx"
#endif /* SPACET_SXX */



#endif /* SPACET_CXX */

