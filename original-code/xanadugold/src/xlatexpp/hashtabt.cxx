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

#ifndef HASHTABT_CXX
#define HASHTABT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef HASHTABT_HXX
#include "hashtabt.hxx"
#endif /* HASHTABT_HXX */

#ifndef HASHTABT_IXX
#include "hashtabt.ixx"
#endif /* HASHTABT_IXX */


#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef SEQUENCX_HXX
#include "sequencx.hxx"
#endif /* SEQUENCX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */




/* ************************************************************************ *
 * 
 *                    Class HashTableTester 
 *
 * ************************************************************************ */


/* tests */


void HashTableTester::test1On (ostream& oo){
	/* self runTest: #test1On: */
	/* test creation */
	
	SPTR(MuTable) tab1;
	SPTR(MuTable) tab2;
	
	oo << "Create tables with create, create: and create:with:\n\n";
	tab1 = HashTable::make (IntegerSpace::make ());
	tab2 = HashTable::make (IntegerSpace::make (), 4);
	/* test printing */
	oo << "Printing tables:\n\n" << tab1 << "\n\n" << tab2 << "\n\n";
	/* testing empty */
	oo << "Test empty table: ";
	if (tab1->isEmpty()) {
		oo << "Empty";
	} else {
		oo << "Not Empty";
	}
	oo << "\n\n";
	/* inserting */
	tab1->atIntIntroduce(1, Sequence::string("filly"));
	tab1->atIntIntroduce(IntegerVar0, Sequence::string("mare"));
	oo << "Test introduce: " << tab1 << ", table count now: " << tab1->count() << "\n\n";
	tab1->introduce(Sequence::string("mare"), Sequence::string("colt"));
	oo << "Test introduce: " << tab1 << ", table count now: " << tab1->count() << "\n\n";
	tab1->atIntIntroduce(27, Sequence::string("stallion"));
	oo << "Test introduce: " << tab1 << ", table count now: " << tab1->count() << "\n\n";
	{
		INSTALL_SHIELD(ex);
		SHIELD_UP_BEGIN(ex, AlreadyInTableFilter) {
			oo << "already in table blast caught, table now:\n\n" << tab1 << "\n\nand table count: " << tab1->count() << "\n\n";
			return;
			
		} SHIELD_UP_END(ex);
		tab1->atIntIntroduce(1, Sequence::string("palooka"));
	}
	oo << "Test empty table: ";
	if (tab1->isEmpty()) {
		oo << "Empty";
	} else {
		oo << "Not Empty";
	}
	oo << "\n\n";
}


void HashTableTester::test2On (ostream& aStream){
	/* self runTest: #test2On: */
	/* test creation */
	
	SPTR(MuTable) tab1;
	
	aStream << "Create tables.\n\n";
	tab1 = HashTable::make (IntegerSpace::make ());
	tab1->atIntIntroduce(1, Sequence::string("filly"));
	tab1->atIntIntroduce(IntegerVar0, Sequence::string("mare"));
	tab1->atIntIntroduce(-1, Sequence::string("colt"));
	tab1->atIntIntroduce(27, Sequence::string("stallion"));
	aStream << "Starting table is:\n\n" << tab1 << "\n\n";
	tab1->atIntReplace(1, Sequence::string("mare"));
	aStream << "after replace:\n" << tab1 << " and table count: " << tab1->count() << "\n";
	aStream << "Test replace() in unknown territory. \n";
	{
		INSTALL_SHIELD(ex);
		SHIELD_UP_BEGIN(ex, NotInTableFilter) {
			aStream << "NotInTable blast caught, table now:\n" << tab1 << "\nand table count: " << tab1->count() << "\n";
			return;
			
		} SHIELD_UP_END(ex);
		tab1->atIntReplace(2, Sequence::string("palooka"));
	}
	aStream << "Test replace() with NULL. \n";
	{
		INSTALL_SHIELD(x);
		SHIELD_UP_BEGIN(x, NullInsertionFilter) {
			aStream << "NullInsertion blast caught, table now:\n" << tab1 << "\nand table count: " << tab1->count() << "\n";
			return;
			
		} SHIELD_UP_END(x);
		tab1->atIntReplace(1, NULL);
		aStream << "Replace(NULL) not caught!\n";
	}
}


void HashTableTester::test3On (ostream& aStream){
	/* self runTest: #test3On: */
	/* test creation */
	
	SPTR(MuTable) tab1;
	
	aStream << "Create tables.\n\n";
	tab1 = HashTable::make (IntegerSpace::make ());
	tab1->atIntIntroduce(1, Sequence::string("filly"));
	tab1->atIntIntroduce(IntegerVar0, Sequence::string("mare"));
	tab1->atIntIntroduce(-1, Sequence::string("colt"));
	tab1->atIntIntroduce(27, Sequence::string("stallion"));
	aStream << "Starting table is:\n\n" << tab1 << "\n";
	tab1->atIntStore(1, Sequence::string("mare"));
	aStream << "after store:\n" << tab1 << " and table count: " << tab1->count() << "\n";
	aStream << "Test store() in unknown territory. \n";
	{
		INSTALL_SHIELD(ex);
		SHIELD_UP_BEGIN(ex, NotInTableFilter) {
			aStream << "NotInTable blast caught, table now:\n" << tab1 << "\nand table count: " << tab1->count() << "\n";
			return;
			
		} SHIELD_UP_END(ex);
		tab1->atIntStore(2, Sequence::string("palooka"));
	}
	aStream << "after store:\n" << tab1 << " and table count: " << tab1->count() << "\n";
	aStream << "Test store() with NULL. \n";
	{
		INSTALL_SHIELD(exc);
		SHIELD_UP_BEGIN(exc, NullInsertionFilter) {
			aStream << "NullInsertion blast caught, table now:\n" << tab1 << "\nand table count: " << tab1->count() << "\n";
			return;
			
		} SHIELD_UP_END(exc);
		tab1->atIntStore(3, NULL);
	}
}


void HashTableTester::test4On (ostream& aStream){
	/* self runTest: #test4On: */
	/* test creation */
	
	SPTR(MuTable) tab1;
	
	aStream << "Create tables.\n\n";
	tab1 = HashTable::make (IntegerSpace::make ());
	tab1->introduce(IntegerPos::make (1), Sequence::string("filly"));
	tab1->introduce(Integer0, Sequence::string("mare"));
	tab1->introduce(IntegerPos::make (-1), Sequence::string("colt"));
	tab1->introduce(IntegerPos::make (27), Sequence::string("stallion"));
	aStream << "Starting table is:\n" << tab1 << "\nwith count " << tab1->count() << "\n";
	/* testing domain */
	aStream << "Testing domain\n" << tab1->domain() << "\n";
	/* test get */
	aStream << "Test get(1) " << tab1->intGet(1) << "\n";
	aStream << "Test get() in unknown territory. \n";
	{
		INSTALL_SHIELD(ex);
		SHIELD_UP_BEGIN(ex, NotInTableFilter) {
			aStream << "NotInTable blast caught, table now:\n" << tab1 << "\nand table count: " << tab1->count() << "\n";
			return;
			
		} SHIELD_UP_END(ex);
		tab1->intGet(14);
	}
}


void HashTableTester::test5On (ostream& aStream){
	/* self runTest: #test5On: */
	/* test creation */
	
	SPTR(MuTable) tab1;
	
	aStream << "Create tables.\n\n";
	tab1 = HashTable::make (IntegerSpace::make ());
	tab1->atIntIntroduce(1, Sequence::string("filly"));
	tab1->atIntIntroduce(IntegerVar0, Sequence::string("mare"));
	tab1->atIntIntroduce(-1, Sequence::string("colt"));
	tab1->atIntIntroduce(27, Sequence::string("stallion"));
	aStream << "Starting table is:\n" << tab1 << "\nwith count " << tab1->count() << "\nNow, testing remove(1)\n";
	tab1->intRemove(1);
	aStream << "Table now:\n" << tab1 << "\nwith count " << tab1->count() << "\n";
	aStream << "Test remove(1) in unknown territory. \n";
	{
		INSTALL_SHIELD(ex);
		SHIELD_UP_BEGIN(ex, NotInTableFilter) {
			aStream << "NotInTable blast caught, table now:\n" << tab1 << "\nand table count: " << tab1->count() << "\n";
			return;
			
		} SHIELD_UP_END(ex);
		tab1->intRemove(1);
	}
	aStream << "Test wipe(0)\n";
	tab1->wipe(Integer0);
	aStream << "Table now:\n" << tab1 << "\nwith count " << tab1->count() << "\nAnd wipe(0) again: ";
	tab1->wipe(Integer0);
	aStream << "Table now:\n" << tab1 << "\nwith count " << tab1->count() << "\n";
}


void HashTableTester::test6On (ostream& aStream){
	/* self runTest: #test6On: */
	/* test creation */
	
	SPTR(MuTable) tab1;
	
	aStream << "Create tables.\n\n";
	tab1 = HashTable::make (IntegerSpace::make ());
	tab1->atIntIntroduce(1, Sequence::string("filly"));
	tab1->atIntIntroduce(IntegerVar0, Sequence::string("mare"));
	tab1->atIntIntroduce(-1, Sequence::string("colt"));
	tab1->atIntIntroduce(27, Sequence::string("stallion"));
	/* 	tab2 _ tab1 subTable: 0 integer with: 40. 
			
			aStream << 'Table now: 
			' << tab1 << ' 
			with count ' << tab1 count << ' 
			and the subtable is 
			' << tab2 << ' 
			and its count is ' << tab2 count << '. 
			'. */
	aStream << "Starting table is:\n" << tab1 << "\nwith count " << tab1->count() << "\nNow, testing subTable(0,40)\n";
}


void HashTableTester::test7On (ostream& aStream){
	/* self runTest: #test7On: */
	/* runs {Iterator} */
	/* test creation */
	
	SPTR(MuTable) tab1;
	SPTR(XnRegion) domain;
	
	aStream << "Create tables.\n\n";
	tab1 = HashTable::make (IntegerSpace::make ());
	tab1->atIntIntroduce(1, UInt8Array::string("filly"));
	tab1->atIntIntroduce(IntegerVar0, UInt8Array::string("mare"));
	tab1->atIntIntroduce(-1, UInt8Array::string("colt"));
	tab1->atIntIntroduce(27, UInt8Array::string("stallion"));
	aStream << "Starting table is:\n" << tab1 << "\nwith count " << tab1->count() << "\nNow, testing domain\n";
	domain = tab1->domain();
	aStream << "And the results (ta ta TUM!) \n\t" << domain << "\n";
}


void HashTableTester::testStepperCopyOn (ostream& aStream){
	/* self runTest: #testStepperCopyOn: */
	
	SPTR(MuTable) tab1;
	SPTR(MuTable) tab2;
	SPTR(TableStepper) stp;
	
	aStream << "Test copy by stepper.\n";
	tab1 = HashTable::make (IntegerSpace::make ());
	tab1->atIntIntroduce(1, UInt8Array::string("filly"));
	tab1->atIntIntroduce(IntegerVar0, UInt8Array::string("mare"));
	tab1->atIntIntroduce(-1, UInt8Array::string("colt"));
	tab1->atIntIntroduce(27, UInt8Array::string("stallion"));
	aStream << "Starting table is:\n" << tab1 << "\nwith count " << tab1->count() << ".\nNow testing store during forEach loop\n";
	BEGIN_FOR_EACH(Heaper,e,(stp = tab1->stepper())) {
		aStream << "at index " << stp->position() << " storing " << stp->position() << " on top of " << e << "\n";
		tab1->store(stp->position(), stp->position());
	} END_FOR_EACH;
	aStream << "Ending table is:\n" << tab1 << "\nwith count " << tab1->count() << ".\n";
	tab2 = CAST(MuTable,tab1->copy());
	BEGIN_FOR_EACH(Heaper,x,(stp = tab2->stepper())) {
		aStream << "at index " << stp->position() << " storing \'foo\' on top of " << x << "\n";
		tab2->store(stp->position(), UInt8Array::string("foo"));
	} END_FOR_EACH;
	aStream << "Ending table is:\n" << tab2 << "\nwith count " << tab2->count() << ".\nDone with stepperCopy test.\n";
}
/* running tests */


void HashTableTester::allTestsOn (ostream& aStream){
	/* self runTest: #allTestsOn: */
	
	aStream << "Running all HashTable tests.\nTest 1\n";
	this->test1On(aStream);
	aStream << "\nTest 2\n";
	this->test2On(aStream);
	aStream << "\nTest 3\n";
	this->test3On(aStream);
	aStream << "\nTest 4\n";
	this->test4On(aStream);
	aStream << "\nTest 5\n";
	this->test5On(aStream);
	aStream << "\nTest 6\n";
	this->test6On(aStream);
	aStream << "\nTest 7\n";
	this->test7On(aStream);
	this->testStepperCopyOn(aStream);
}

	/* automatic 0-argument constructor */
HashTableTester::HashTableTester() {}

#ifndef HASHTABT_SXX
#include "hashtabt.sxx"
#endif /* HASHTABT_SXX */



#endif /* HASHTABT_CXX */

