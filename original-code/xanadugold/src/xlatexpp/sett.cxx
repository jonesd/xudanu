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

#ifndef SETT_CXX
#define SETT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef SETT_HXX
#include "sett.hxx"
#endif /* SETT_HXX */

#ifndef SETT_IXX
#include "sett.ixx"
#endif /* SETT_IXX */


#ifndef ARRAYX_HXX
#include "arrayx.hxx"
#endif /* ARRAYX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef SETP_HXX
#include "setp.hxx"
#endif /* SETP_HXX */




/* ************************************************************************ *
 * 
 *                    Class ScruSetTester 
 *
 * ************************************************************************ */


/* creation */


ScruSetTester::ScruSetTester () {
	myTestSets = NULL;
}
/* testing */


void ScruSetTester::allTestsOn (ostream& oo){
	oo << "Start ScruSet testing\n";
	BEGIN_FOR_EACH(ScruSet,s,(this->testScruSets()->stepper())) {
		this->unaryCheck(s);
	} END_FOR_EACH;
	this->testIsEmpty(oo);
	this->testhasMember(oo);
	this->testContentsEqual(oo);
	this->testIntersects(oo);
	this->testIsSubsetOf(oo);
	oo << "End of Scruset testing\n";
}
/* tests */


void ScruSetTester::testContentsEqual (ostream& oo){
	oo << "testing contentsEqual() and contentsHash()\n";
	if ( this->getScruSet(2)->contentsEqual(this->getScruSet(3)) ) {
		BLAST(contentsEqual_failed);
	}
	if ( this->getScruSet(2)->contentsEqual(this->getScruSet(4)) ) {
		BLAST(contentsEqual_failed);
	}
	if ( ! (this->getScruSet(2)->contentsEqual(this->getScruSet(6))) ) {
		BLAST(contentsEqual_failed);
	}
	if ( ! (this->getScruSet(2)->contentsEqual(this->getScruSet(8))) ) {
		BLAST(contentsEqual_failed);
	}
	/* ensure reflexive */
	if ( this->getScruSet(3)->contentsEqual(this->getScruSet(2)) ) {
		BLAST(contentsEqual_failed);
	}
	if ( this->getScruSet(4)->contentsEqual(this->getScruSet(2)) ) {
		BLAST(contentsEqual_failed);
	}
	if ( ! (this->getScruSet(6)->contentsEqual(this->getScruSet(2))) ) {
		BLAST(contentsEqual_failed);
	}
	if ( ! (this->getScruSet(8)->contentsEqual(this->getScruSet(2))) ) {
		BLAST(contentsEqual_failed);
	}
	if ( this->getScruSet(5)->contentsEqual(this->getScruSet(4)) ) {
		BLAST(contentsEqual_failed);
	}
	if ( ! (this->getScruSet(5)->contentsEqual(this->getScruSet(7))) ) {
		BLAST(contentsEqual_failed);
	}
	if ( ! (this->getScruSet(2)->contentsHash() == this->getScruSet(6)->contentsHash()) ) {
		BLAST(contentsEqual_failed);
	}
	if ( ! (this->getScruSet(5)->contentsHash() == this->getScruSet(7)->contentsHash()) ) {
		BLAST(contentsEqual_failed);
	}
	oo << "end of ContentsEqual tests\n";
}


void ScruSetTester::testhasMember (ostream& oo){
	SPTR(Heaper) mem1;
	SPTR(Heaper) mem2;
	
	oo << "testing hasMember and theOne\n";
	mem1 = this->getScruSet(2)->theOne();
	if ( ! (this->getScruSet(2)->hasMember(mem1)) ) {
		BLAST(hasMember_failed);
	}
	if ( ! (this->getScruSet(8)->hasMember(mem1)) ) {
		BLAST(hasMember_failed);
	}
	if ( ! (this->getScruSet(4)->hasMember(mem1)) ) {
		BLAST(hasMember_failed);
	}
	mem2 = this->getScruSet(3)->theOne();
	if ( ! (this->getScruSet(3)->hasMember(mem2)) ) {
		BLAST(hasMember_failed);
	}
	if ( this->getScruSet(2)->hasMember(mem2) ) {
		BLAST(hasMember_failed);
	}
	if ( this->getScruSet(5)->hasMember(mem2) ) {
		BLAST(hasMember_failed);
	}
	oo << "end of hasMember and theOne tests\n";
}


void ScruSetTester::testIntersects (ostream& oo){
	oo << "testing intersects\n";
	if ( this->getScruSet(2)->intersects(this->getScruSet(1)) ) {
		BLAST(failed_intersects__test);
	}
	if ( this->getScruSet(1)->intersects(this->getScruSet(2)) ) {
		BLAST(failed_intersects__test);
	}
	if ( this->getScruSet(2)->intersects(this->getScruSet(3)) ) {
		BLAST(failed_intersects__test);
	}
	if ( this->getScruSet(3)->intersects(this->getScruSet(2)) ) {
		BLAST(failed_intersects__test);
	}
	if ( this->getScruSet(5)->intersects(this->getScruSet(4)) ) {
		BLAST(failed_intersects__test);
	}
	if ( this->getScruSet(5)->intersects(this->getScruSet(3)) ) {
		BLAST(failed_intersects__test);
	}
	if ( this->getScruSet(5)->intersects(this->getScruSet(2)) ) {
		BLAST(failed_intersects__test);
	}
	if ( this->getScruSet(5)->intersects(this->getScruSet(1)) ) {
		BLAST(failed_intersects__test);
	}
	if ( this->getScruSet(4)->intersects(this->getScruSet(5)) ) {
		BLAST(failed_intersects__test);
	}
	if ( this->getScruSet(3)->intersects(this->getScruSet(5)) ) {
		BLAST(failed_intersects__test);
	}
	if ( this->getScruSet(2)->intersects(this->getScruSet(5)) ) {
		BLAST(failed_intersects__test);
	}
	if ( this->getScruSet(1)->intersects(this->getScruSet(5)) ) {
		BLAST(failed_intersects__test);
	}
	if ( ! (this->getScruSet(2)->intersects(this->getScruSet(6))) ) {
		BLAST(failed_intersects__test);
	}
	if ( ! (this->getScruSet(6)->intersects(this->getScruSet(2))) ) {
		BLAST(failed_intersects__test);
	}
	if ( ! (this->getScruSet(7)->intersects(this->getScruSet(5))) ) {
		BLAST(failed_intersects__test);
	}
	if ( ! (this->getScruSet(5)->intersects(this->getScruSet(7))) ) {
		BLAST(failed_intersects__test);
	}
	if ( ! (this->getScruSet(2)->intersects(this->getScruSet(8))) ) {
		BLAST(failed_intersects__test);
	}
	if ( ! (this->getScruSet(8)->intersects(this->getScruSet(2))) ) {
		BLAST(failed_intersects__test);
	}
	if ( ! (this->getScruSet(9)->intersects(this->getScruSet(5))) ) {
		BLAST(failed_intersects__test);
	}
	if ( ! (this->getScruSet(5)->intersects(this->getScruSet(9))) ) {
		BLAST(failed_intersects__test);
	}
	oo << "end of intersects tests\n";
}


void ScruSetTester::testIsEmpty (ostream& oo){
	oo << "testing isEmpty\n";
	if ( ! (this->getScruSet(1)->isEmpty()) ) {
		BLAST(failed_isEmpty_test);
	}
	if ( this->getScruSet(2)->isEmpty() ) {
		BLAST(failed_isEmpty_test);
	}
	if ( this->getScruSet(3)->isEmpty() ) {
		BLAST(failed_isEmpty_test);
	}
	if ( this->getScruSet(4)->isEmpty() ) {
		BLAST(failed_isEmpty_test);
	}
	if ( this->getScruSet(5)->isEmpty() ) {
		BLAST(failed_isEmpty_test);
	}
	if ( this->getScruSet(6)->isEmpty() ) {
		BLAST(failed_isEmpty_test);
	}
	if ( this->getScruSet(7)->isEmpty() ) {
		BLAST(failed_isEmpty_test);
	}
	if ( this->getScruSet(8)->isEmpty() ) {
		BLAST(failed_isEmpty_test);
	}
	if ( this->getScruSet(9)->isEmpty() ) {
		BLAST(failed_isEmpty_test);
	}
	oo << "end of isEmpty tests\n";
}


void ScruSetTester::testIsSubsetOf (ostream& oo){
	oo << "testing isSubsetOf\n";
	if ( this->getScruSet(3)->isSubsetOf(this->getScruSet(2)) ) {
		BLAST(failed_isSubsetOf_test);
	}
	if ( this->getScruSet(2)->isSubsetOf(this->getScruSet(3)) ) {
		BLAST(failed_isSubsetOf_test);
	}
	if ( ! (this->getScruSet(2)->isSubsetOf(this->getScruSet(4))) ) {
		BLAST(failed_isSubsetOf_test);
	}
	if ( this->getScruSet(4)->isSubsetOf(this->getScruSet(2)) ) {
		BLAST(failed_isSubsetOf_test);
	}
	if ( ! (this->getScruSet(8)->isSubsetOf(this->getScruSet(4))) ) {
		BLAST(failed_isSubsetOf_test);
	}
	if ( this->getScruSet(4)->isSubsetOf(this->getScruSet(8)) ) {
		BLAST(failed_isSubsetOf_test);
	}
	if ( ! (this->getScruSet(5)->isSubsetOf(this->getScruSet(9))) ) {
		BLAST(failed_isSubsetOf_test);
	}
	if ( ! (this->getScruSet(9)->isSubsetOf(this->getScruSet(5))) ) {
		BLAST(failed_isSubsetOf_test);
	}
	if ( this->getScruSet(5)->isSubsetOf(this->getScruSet(4)) ) {
		BLAST(failed_isSubsetOf_test);
	}
	if ( this->getScruSet(4)->isSubsetOf(this->getScruSet(5)) ) {
		BLAST(failed_isSubsetOf_test);
	}
	if ( ! (this->getScruSet(6)->isSubsetOf(this->getScruSet(2))) ) {
		BLAST(failed_isSubsetOf_test);
	}
	if ( ! (this->getScruSet(2)->isSubsetOf(this->getScruSet(6))) ) {
		BLAST(failed_isSubsetOf_test);
	}
	oo << "end of isSubsetOf tests\n";
}


void ScruSetTester::unaryCheck (APTR(ScruSet) a){
	if ( ! (a->contentsEqual(a)) ) {
		BLAST(identity_test_failed_);
	}
	if ( ! (!a->isEmpty() == a->intersects(a)) ) {
		BLAST(intersects_test_failed_);
	}
	if ( ! (a->isSubsetOf(a)) ) {
		BLAST(self_subset_test_failed_);
	}
	if ( ! (a->isEqual(a)) ) {
		BLAST(isEqual_test_failed);
	}
	BEGIN_FOR_EACH(Heaper,elem,(a->stepper())) {
		if ( ! (a->hasMember(elem)) ) {
			BLAST(failed_hasMember_for_a_stepped_element);
		}
	} END_FOR_EACH;
}
/* hooks: */


void ScruSetTester::restartScruSetTester (APTR(Rcvr) rcvr){
	myTestSets = NULL;
}
/* deferred: initialization */
/* protected: accessing */


RPTR(ScruSet) ScruSetTester::getScruSet (IntegerVar number){
	
	return CAST(ScruSet,myTestSets->get(IntegerPos::make (number - 1)));
}


void ScruSetTester::setTestSets (APTR(ScruTable) OF1(ScruSet) table){
	myTestSets = table;
}


RPTR(ScruTable) OF1(ScruSet) ScruSetTester::testScruSets (){
	if (myTestSets == NULL) {
		myTestSets = this->generateScruSets();
	}
	return (ScruTable*) myTestSets;
}
/* private: scruset generation */


RPTR(ScruTable) OF1(ScruSet) ScruSetTester::generateScruSets (){
	/* generateScruSets must generate a table of sets in the 
	following order:
		  1) an empty set
		  2) a set containing one element
		  3) a set containing one element which is different from 
	that in set 2
		  4) a set containing at least two elements, one equal to 
	the element in set 2
		  5) a set containing at least two elements, different from 
	all previous elements
		  6) a set with the same contents as set 2 not generated by copy()
		  7) a set with the same contents as set 5 not generated by copy()
		  8) a set generated by set 2 copy
		  9) a set generated by set 5 copy
		  other sets are optional and will only be tested with 
	general tests (check).
		   */
	
	SPTR(Accumulator) settab;
	SPTR(Accumulator) idTab1;
	SPTR(Accumulator) idTab2;
	SPTR(ScruTable) idTab3;
	
	/* settab is an accumulator for a table of sets to return.
		idTab1,2 are accumulators on tables used to generate a set containing
		desired elements for testing. */
	settab = MuArray::arrayAccumulator();
	idTab1 = MuArray::arrayAccumulator();
	idTab2 = MuArray::arrayAccumulator();
	settab->step(this->generateSet());
	/* #1 */
	idTab1->step(UInt8Array::string("One"));
	idTab3 = CAST(ScruTable,idTab1->value())->asImmuTable();
	settab->step(this->generateSetContaining(CAST(ScruTable,idTab1->value())->stepper()));
	/* #2 */
	idTab2->step(UInt8Array::string("Two"));
	settab->step(this->generateSetContaining(CAST(ScruTable,idTab2->value())->stepper()));
	/* #3 */
	idTab1->step(UInt8Array::string("Three"));
	settab->step(this->generateSetContaining(CAST(ScruTable,idTab1->value())->stepper()));
	/* #4 */
	{idTab2->destroy();  idTab2 = NULL /* don't want stale (S/CHK)PTRs */;}
	idTab2 = MuArray::arrayAccumulator();
	idTab2->step(UInt8Array::string("Four"));
	idTab2->step(UInt8Array::string("Five"));
	idTab2->step(UInt8Array::string("Six"));
	settab->step(this->generateSetContaining(CAST(ScruTable,idTab2->value())->stepper()));
	/* #5 */
	settab->step(this->generateSetContaining(idTab3->stepper()));
	/* #6 */
	settab->step(this->generateSetContaining(CAST(ScruTable,idTab2->value())->stepper()));
	/* #7 */
	settab->step(CAST(ScruSet,CAST(ScruTable,settab->value())->get(IntegerPos::make (1)))->copy());
	/* #8 */
	settab->step(CAST(ScruSet,CAST(ScruTable,settab->value())->get(IntegerPos::make (4)))->copy());
	/* #9 */
	return CAST(ScruTable,settab->value());
}



/* ************************************************************************ *
 * 
 *                    Class   ImmuSetTester 
 *
 * ************************************************************************ */


/* testing */


void ImmuSetTester::allTestsOn (ostream& oo){
	oo << "ImmuSet testing\n";
	this->ScruSetTester::allTestsOn(oo);
	oo << "End of ImmuSet testing\n";
}
/* accessing */


RPTR(ScruSet) ImmuSetTester::generateSet (){
	WPTR(ScruSet) 	returnValue;
	returnValue = ImmuSet::make ();
	return returnValue;
}


RPTR(ScruSet) ImmuSetTester::generateSetContaining (APTR(Stepper) stuff){
	SPTR(MuSet) t;
	
	t = MuSet::make ();
	BEGIN_FOR_EACH(Heaper,e,(stuff)) {
		t->store(e);
	} END_FOR_EACH;
	WPTR(ScruSet) 	returnValue;
	returnValue = t->asImmuSet();
	return returnValue;
}

	/* automatic 0-argument constructor */
ImmuSetTester::ImmuSetTester() {}



/* ************************************************************************ *
 * 
 *                    Class   MuSetTester 
 *
 * ************************************************************************ */


/* deferred: initialization */
/* tests */


void MuSetTester::binaryCheck (APTR(MuSet) a, APTR(MuSet) b){
	SPTR(MuSet) anb;
	SPTR(MuSet) bna;
	SPTR(MuSet) amb;
	SPTR(MuSet) aub;
	SPTR(MuSet) bua;
	
	anb = CAST(MuSet,a->copy());
	anb->restrictTo(b);
	bna = CAST(MuSet,b->copy());
	bna->restrictTo(a);
	if ( ! (anb->contentsEqual(bna)) ) {
		BLAST(intersect_test_failed_);
	}
	if ( ! (anb->isSubsetOf(a)) ) {
		BLAST(intersect_subset_test_failed_);
	}
	if ( ! (anb->isSubsetOf(b)) ) {
		BLAST(intersect_subset_test_failed_);
	}
	if ( ! (bna->isSubsetOf(a)) ) {
		BLAST(intersect_subset_test_failed_);
	}
	if ( ! (bna->isSubsetOf(b)) ) {
		BLAST(intersect_subset_test_failed_);
	}
	if ( ! (a->intersects(b) == !anb->isEmpty()) ) {
		BLAST(intersects_test_failed_);
	}
	amb = CAST(MuSet,a->copy());
	amb->wipeAll(b);
	if ( amb->intersects(b) ) {
		BLAST(minus_intersect_test_failed_);
	}
	if ( ! (amb->isSubsetOf(a)) ) {
		BLAST(minus_subset_test_failed_);
	}
	aub = CAST(MuSet,a->copy());
	aub->storeAll(b);
	bua = CAST(MuSet,b->copy());
	bua->storeAll(a);
	if ( ! (aub->contentsEqual(bua)) ) {
		BLAST(unionWith_test_failed_);
	}
	if ( ! (a->isSubsetOf(aub)) ) {
		BLAST(union_subset_test_failed_);
	}
	if ( ! (b->isSubsetOf(aub)) ) {
		BLAST(union_subset_test_failed_);
	}
	if ( ! ((a->isSubsetOf(b) && b->isSubsetOf(a)) == a->contentsEqual(b)) ) {
		BLAST(subset_equals_test_failed_);
	}
}


void MuSetTester::binarySetTestsOn (ostream& oo){
	oo << "start binary tests\n";
	BEGIN_FOR_EACH(MuSet,setone,(this->testMuSets()->stepper())) {
		BEGIN_FOR_EACH(MuSet,settwo,(this->testMuSets()->stepper())) {
			this->binaryCheck(setone, settwo);
		} END_FOR_EACH;
	} END_FOR_EACH;
	oo << "end binary tests\n";
}


void MuSetTester::unaryCheck (APTR(ScruSet) a){
	SPTR(MuSet) ta;
	
	this->ScruSetTester::unaryCheck(a);
	ta = CAST(MuSet,a->copy());
	ta->wipeAll(a);
	if ( ! (ta->isEmpty()) ) {
		BLAST(self_minus_isEmpty_failed_);
	}
	ta = CAST(MuSet,a->copy());
	ta->restrictTo(a);
	if ( ! (ta->contentsEqual(a)) ) {
		BLAST(intersect_isEqual_test_failed_);
	}
}
/* testing */


void MuSetTester::allTestsOn (ostream& oo){
	oo << "MuSet testing\n";
	this->ScruSetTester::allTestsOn(oo);
	this->binarySetTestsOn(oo);
	oo << "End of MuSet testing\n";
}
/* protected: accessing */


RPTR(ScruTable) OF1(MuSet) MuSetTester::testMuSets (){
	WPTR(ScruTable) OF1(MuSet) 	returnValue;
	returnValue = this->testScruSets();
	return returnValue;
}

	/* automatic 0-argument constructor */
MuSetTester::MuSetTester() {}



/* ************************************************************************ *
 * 
 *                    Class     HashSetTester 
 *
 * ************************************************************************ */


/* tests */


void HashSetTester::basicTestsOn (ostream& oo){
	SPTR(HashSet) set1;
	SPTR(HashSet) set2;
	SPTR(HashSet) set3;
	SPTR(HashSet) set4;
	SPTR(HashSet) set5;
	
	oo << "\nbasic tests -- start with creation.\n";
	set1 = HashSet::make ();
	set2 = HashSet::make (SHTO::make ("heaper", 1193046));
	set3 = HashSet::make (4);
	set4 = HashSet::make (19);
	set5 = HashSet::make (IntegerVar0);
	oo << "basic hash set is: " << set1 << " internals:\n";
	set1->printInternals(oo);
	oo << "\nbasic set on heaper is: " << set2 << " internals:\n";
	set2->printInternals(oo);
	oo << "\nbasic set make(4) is: " << set3 << " internals:\n";
	set3->printInternals(oo);
	oo << "\nbasic set make(19) is: " << set4 << " internals:\n";
	set4->printInternals(oo);
	oo << "\nbasic set make(0) is: " << set5 << " internals:\n";
	set5->printInternals(oo);
	{set1->destroy();  set1 = NULL /* don't want stale (S/CHK)PTRs */;}
	{set3->destroy();  set3 = NULL /* don't want stale (S/CHK)PTRs */;}
	{set4->destroy();  set4 = NULL /* don't want stale (S/CHK)PTRs */;}
	{set5->destroy();  set5 = NULL /* don't want stale (S/CHK)PTRs */;}
	set1 = CAST(HashSet,set2->copy());
	oo << "copy of " << set2 << " is " << set1;
	oo << "\ninternals of source:\n";
	set2->printInternals(oo);
	oo << "\ninternals of copy:\n";
	set1->printInternals(oo);
	oo << "\n\nEnd of basic tests\n";
}


void HashSetTester::doIntroduceTestsOn (ostream& oo){
	SPTR(HashSet) set1;
	
	oo << "\nintroduce tests\n";
	this->introduceTestsOn(oo, HashSet::make (), SHTO::make ("first", Int32Zero));
	this->introduceTestsOn(oo, HashSet::make (), SHTO::make ("second", 1));
	this->introduceTestsOn(oo, HashSet::make (), SHTO::make ("third", 6));
	this->introduceTestsOn(oo, HashSet::make (), SHTO::make ("fourth", 7));
	set1 = HashSet::make ();
	this->introduceTestsOn(oo, set1, SHTO::make ("one", 1));
	this->introduceTestsOn(oo, set1, SHTO::make ("two", 1));
	this->introduceTestsOn(oo, set1, SHTO::make ("three", 1));
	this->introduceTestsOn(oo, set1, SHTO::make ("one", 1));
	{set1->destroy();  set1 = NULL /* don't want stale (S/CHK)PTRs */;}
	set1 = HashSet::make ();
	this->introduceTestsOn(oo, set1, SHTO::make ("one", 1));
	this->introduceTestsOn(oo, set1, SHTO::make ("two", 1));
	this->introduceTestsOn(oo, set1, SHTO::make ("three", 1));
	this->introduceTestsOn(oo, set1, SHTO::make ("fower", 2));
	{set1->destroy();  set1 = NULL /* don't want stale (S/CHK)PTRs */;}
	oo << "\n\nEnd of introduce tests\n";
}


void HashSetTester::doStoreTestsOn (ostream& oo){
	SPTR(HashSet) set1;
	SPTR(HashSet) set2;
	
	oo << "\nstore tests\n";
	this->storeTestsOn(oo, HashSet::make (), SHTO::make ("first", Int32Zero));
	this->storeTestsOn(oo, HashSet::make (), SHTO::make ("second", 1));
	this->storeTestsOn(oo, HashSet::make (), SHTO::make ("third", 6));
	this->storeTestsOn(oo, HashSet::make (), SHTO::make ("fourth", 7));
	set1 = HashSet::make ();
	this->storeTestsOn(oo, set1, SHTO::make ("one", 1));
	this->storeTestsOn(oo, set1, SHTO::make ("two", 1));
	this->storeTestsOn(oo, set1, SHTO::make ("three", 1));
	this->storeTestsOn(oo, set1, SHTO::make ("one", 1));
	oo << "testing storeAll\n\n";
	set2 = HashSet::make ();
	set2->store(SHTO::make ("duble", 2));
	set2->store(SHTO::make ("triple", 3));
	this->storeTestsOn(oo, set2, SHTO::make ("quadle", 4));
	this->storeTestsOn(oo, set1, SHTO::make ("onele", 1));
	set1->storeAll(set2);
	oo << "after storeAll, set1 now:\n";
	set1->printInternals(oo);
	oo << "after storeAll, set2 now:\n";
	set2->printInternals(oo);
	oo << "\n\nEnd of store tests\n";
}


void HashSetTester::doWipeTestsOn (ostream& oo){
	SPTR(HashSet) set1;
	SPTR(HashSet) set2;
	
	oo << "\nwipe tests\n";
	set1 = HashSet::make ();
	set1->store(SHTO::make ("one", Int32Zero));
	this->wipeTestsOn(oo, set1, SHTO::make ("one", Int32Zero));
	{set1->destroy();  set1 = NULL /* don't want stale (S/CHK)PTRs */;}
	set1 = HashSet::make ();
	set1->store(SHTO::make ("two", 1));
	this->wipeTestsOn(oo, set1, SHTO::make ("two", 1));
	{set1->destroy();  set1 = NULL /* don't want stale (S/CHK)PTRs */;}
	set1 = HashSet::make ();
	set1->store(SHTO::make ("three", 6));
	this->wipeTestsOn(oo, set1, SHTO::make ("three", 6));
	{set1->destroy();  set1 = NULL /* don't want stale (S/CHK)PTRs */;}
	set1 = HashSet::make ();
	set1->store(SHTO::make ("four", 7));
	this->wipeTestsOn(oo, set1, SHTO::make ("four", 7));
	{set1->destroy();  set1 = NULL /* don't want stale (S/CHK)PTRs */;}
	set1 = HashSet::make ();
	set1->store(SHTO::make ("one", 1));
	set1->store(SHTO::make ("two", 1));
	set1->store(SHTO::make ("three", 1));
	set1->store(SHTO::make ("fower", 2));
	set2 = CAST(HashSet,set1->copy());
	this->wipeTestsOn(oo, set2, SHTO::make ("one", 1));
	this->wipeTestsOn(oo, set2, SHTO::make ("two", 1));
	this->wipeTestsOn(oo, set2, SHTO::make ("three", 1));
	this->wipeTestsOn(oo, set2, SHTO::make ("fower", 2));
	{set2->destroy();  set2 = NULL /* don't want stale (S/CHK)PTRs */;}
	set2 = CAST(HashSet,set1->copy());
	this->wipeTestsOn(oo, set2, SHTO::make ("three", 1));
	this->wipeTestsOn(oo, set2, SHTO::make ("two", 1));
	this->wipeTestsOn(oo, set2, SHTO::make ("one", 1));
	this->wipeTestsOn(oo, set2, SHTO::make ("fower", 2));
	{set2->destroy();  set2 = NULL /* don't want stale (S/CHK)PTRs */;}
	set2 = CAST(HashSet,set1->copy());
	this->wipeTestsOn(oo, set2, SHTO::make ("fower", 2));
	this->wipeTestsOn(oo, set2, SHTO::make ("three", 1));
	this->wipeTestsOn(oo, set2, SHTO::make ("two", 1));
	this->wipeTestsOn(oo, set2, SHTO::make ("one", 1));
	{set2->destroy();  set2 = NULL /* don't want stale (S/CHK)PTRs */;}
	oo << "\n\nEnd of wipe tests\n";
}


void HashSetTester::testBig (ostream& oo){
	SPTR(HashSet) big1;
	SPTR(HashSet) big2;
	SPTR(HashSet) big3;
	
	oo << "\n\t\nstart of big testing.\n \n";
	big1 = HashSet::make ();
	{
		UInt32 LoopFinal = 1;
		UInt32 i = 10000;
		for (;;) {
			if (i < LoopFinal){
				break;
			}
			{
				big1->introduce(SHTO::make ("some object", i));
			}
			i -= 1;
		}
	}
	oo << "new big set (count " << big1->count() << ") is:\n" << big1 << "\n";
	big2 = CAST(HashSet,big1->copy());
	oo << "\n\t\n\nbig2 is a copy of big1 (count " << big2->count() << ")\n\n";
	if (big2->isSubsetOf(big1)) {
		oo << "big2 is a subset of big1\n";
	} else {
		oo << "big2 is NOT a subset of big1\n";
	}
	if (big1->isSubsetOf(big2)) {
		oo << "big1 is a subset of big2\n";
	} else {
		oo << "big1 is NOT a subset of big2\n";
	}
	{
		UInt32 LoopFinal = 9999;
		UInt32 j = 3;
		for (;;) {
			if (j > LoopFinal){
				break;
			}
			{
				big2->remove(SHTO::make ("some object", j));
			}
			j += 3;
		}
	}
	oo << "\nbig2 now has every third element removed (count " << big2->count() << ")\n\n";
	if (big2->isSubsetOf(big1)) {
		oo << "big2 is a subset of big1\n";
	} else {
		oo << "big2 is NOT a subset of big1\n";
	}
	if (big1->isSubsetOf(big2)) {
		oo << "big1 is a subset of big2\n";
	} else {
		oo << "big1 is NOT a subset of big2\n";
	}
	big3 = CAST(HashSet,big1->copy());
	big3->wipeAll(big2);
	oo << "big3 is big1-big2 - count " << big3->count() << "\n\n";
	if (big3->isSubsetOf(big1)) {
		oo << "big3 is a subset of big1\n";
	} else {
		oo << "big3 is NOT a subset of big1\n";
	}
	if (big1->isSubsetOf(big3)) {
		oo << "big1 is a subset of big3\n";
	} else {
		oo << "big1 is NOT a subset of big3\n";
	}
	if (big3->isSubsetOf(big2)) {
		oo << "big3 is a subset of big2\n";
	} else {
		oo << "big3 is NOT a subset of big2\n";
	}
	if (big2->isSubsetOf(big3)) {
		oo << "big2 is a subset of big3\n";
	} else {
		oo << "big2 is NOT a subset of big3\n";
	}
	oo << "\n\nend of bigset testing\n";
	{big1->destroy();  big1 = NULL /* don't want stale (S/CHK)PTRs */;}
	{big2->destroy();  big2 = NULL /* don't want stale (S/CHK)PTRs */;}
	{big3->destroy();  big3 = NULL /* don't want stale (S/CHK)PTRs */;}
}
/* testing */


void HashSetTester::allTestsOn (ostream& oo){
	/* HashSetTester runTest */
	
	oo << "HashSet testing\n";
	this->MuSetTester::allTestsOn(oo);
	this->basicTestsOn(oo);
	this->doIntroduceTestsOn(oo);
	this->doStoreTestsOn(oo);
	this->doWipeTestsOn(oo);
	this->testBig(oo);
	oo << "\nEnd of black box testing - now for the White!\n\n";
	oo << "\nEnd of HashSet testing\n\n";
}
/* test support */


void HashSetTester::introduceTestsOn (
		ostream& oo, 
		APTR(HashSet) set1, 
		APTR(SHTO) object)
{
	oo << "set1 starts as: " << set1 << " internals:\n";
	set1->printInternals(oo);
	oo << "set1 introduce: " << object << "\n";
	{
		INSTALL_SHIELD(ex);
		SHIELD_UP_BEGIN(ex, AlreadyInSetFilter) {
			oo << "\nPROBLEM: " << object << " is already in set!\n";
			return;
			
		} SHIELD_UP_END(ex);
		set1->introduce(object);
	}
	oo << "set1 now: " << set1 << " internals:\n";
	set1->printInternals(oo);
	BEGIN_FOR_EACH(Heaper,item,(set1->stepper())) {
		if (!set1->hasMember(item)) {
			oo << "PROBLEM: item " << item << " was not found in set!\n";
			return;
			
		}
	} END_FOR_EACH;
}


void HashSetTester::removeTestsOn (
		ostream& oo, 
		APTR(HashSet) set1, 
		APTR(SHTO) object)
{
	oo << "set1 starts as: " << set1 << " internals:\n";
	set1->printInternals(oo);
	oo << "set1 remove: " << object << "\n";
	{
		INSTALL_SHIELD(ex);
		SHIELD_UP_BEGIN(ex, NotInSetFilter) {
			oo << "\nPROBLEM: " << object << " is not in the set!\n";
			return;
			
		} SHIELD_UP_END(ex);
		set1->remove(object);
	}
	oo << "set1 now: " << set1 << " internals:\n";
	set1->printInternals(oo);
	BEGIN_FOR_EACH(Heaper,item,(set1->stepper())) {
		if (!set1->hasMember(item)) {
			oo << "PROBLEM: item " << item << " was not found in set!\n";
			return;
			
		}
	} END_FOR_EACH;
}


void HashSetTester::storeTestsOn (
		ostream& oo, 
		APTR(HashSet) set1, 
		APTR(SHTO) object)
{
	oo << "set1 starts as: " << set1 << " internals:\n";
	set1->printInternals(oo);
	oo << "set1 store: " << object << "\n";
	set1->store(object);
	oo << "set1 now: " << set1 << " internals:\n";
	set1->printInternals(oo);
	BEGIN_FOR_EACH(Heaper,item,(set1->stepper())) {
		if (!set1->hasMember(item)) {
			oo << "PROBLEM: item " << item << " was not found in set!\n";
			return;
			
		}
	} END_FOR_EACH;
}


void HashSetTester::wipeTestsOn (
		ostream& oo, 
		APTR(HashSet) set1, 
		APTR(SHTO) object)
{
	oo << "set1 starts as: " << set1 << " internals:\n";
	set1->printInternals(oo);
	oo << "set1 wipe: " << object << "\n";
	set1->wipe(object);
	oo << "set1 now: " << set1 << " internals:\n";
	set1->printInternals(oo);
	BEGIN_FOR_EACH(Heaper,item,(set1->stepper())) {
		if (!set1->hasMember(item)) {
			oo << "PROBLEM: item " << item << " was not found in set!\n";
			return;
			
		}
	} END_FOR_EACH;
}
/* accessing */


RPTR(ScruSet) HashSetTester::generateSet (){
	/* ^ MuSet make		No - we're testing ActualHashSets, not MuSets. */
	
	WPTR(ScruSet) 	returnValue;
	returnValue = ActualHashSet::make ();
	return returnValue;
}


RPTR(ScruSet) HashSetTester::generateSetContaining (APTR(Stepper) stuff){
	SPTR(MuSet) t;
	
	/* t _ MuSet make.			No - we're testing ActualHashSets, not MuSets. */
	t = ActualHashSet::make ();
	BEGIN_FOR_EACH(Heaper,e,(stuff)) {
		t->store(e);
	} END_FOR_EACH;
	WPTR(ScruSet) 	returnValue;
	returnValue = t;
	return returnValue;
}

	/* automatic 0-argument constructor */
HashSetTester::HashSetTester() {}



/* ************************************************************************ *
 * 
 *                    Class SetTester 
 *
 * ************************************************************************ */


/* testing */


void SetTester::allTestsOn (ostream& oo){
	SPTR(Tester) aTester;
	
	CONSTRUCT(aTester,HashSetTester,());
	aTester->allTestsOn(oo);
	CONSTRUCT(aTester,ImmuSetTester,());
	aTester->allTestsOn(oo);
}

	/* automatic 0-argument constructor */
SetTester::SetTester() {}



/* ************************************************************************ *
 * 
 *                    Class SHTO 
 *
 * ************************************************************************ */


/* make */


RPTR(SHTO) SHTO::make (char* aString, UInt32 aHashVal){
	SPTR(Sequence) pack;
	
	pack = Sequence::string(aString);
	RETURN_CONSTRUCT(SHTO,(pack, aHashVal));
}
/* SHTO (SpecialHashTestObject) is used for testing hash sets.  It 
stores an identifying string, along with the hash that it is to 
return.  This allows a) system independent testing - as the hash will 
be the same in all test output files, and b) provides for testing 
complex hash value interactions with spending years looking for the 
right objects to generate critical hash values. */


/* tests */


UInt32 SHTO::actualHashForEqual (){
	return myHashValue;
}


BooleanVar SHTO::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(SHTO,foo) {
			{	BooleanVar crutch_Flag;
				/* myHashValue == foo->hashForEqual() && myStringValue->isEqual(foo->stringValue()) */
				
				crutch_Flag = myHashValue == foo->hashForEqual();
				if(crutch_Flag) {
					crutch_Flag = myStringValue->isEqual(foo->stringValue());
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}
/* creation */


SHTO::SHTO (APTR(Sequence) onString, UInt32 onHash) {
	myStringValue = onString;
	myHashValue = onHash;
}
/* printing */


void SHTO::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(";
	
	{
		char	buffer[9];
		sprintf(buffer, "%X", myHashValue);
		oo << buffer;
	}
	
	oo << ", " << myStringValue << ")";
}
/* private: accessing */


RPTR(Sequence) SHTO::stringValue (){
	return (Sequence*) myStringValue;
}

#ifndef SETT_SXX
#include "sett.sxx"
#endif /* SETT_SXX */



#endif /* SETT_CXX */

