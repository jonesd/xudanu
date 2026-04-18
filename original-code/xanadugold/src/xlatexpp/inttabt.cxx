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

#ifndef INTTABT_CXX
#define INTTABT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef INTTABT_HXX
#include "inttabt.hxx"
#endif /* INTTABT_HXX */

#ifndef INTTABT_IXX
#include "inttabt.ixx"
#endif /* INTTABT_IXX */


#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

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
 *                    Class IntegerTableTester 
 *
 * ************************************************************************ */


/* testing */


void IntegerTableTester::cleanTable (APTR(ScruTable) aTable){
	SPTR(TableStepper) stomp;
	
	stomp = aTable->stepper();
	while (stomp->hasValue()) {
		stomp->fetch()->destroy();
		stomp->step();
	}
	{aTable->destroy();  aTable = NULL /* don't want stale (S/CHK)PTRs */;}
}


void IntegerTableTester::test1On (ostream& oo){
	/* IntegerTableTester runTest: #test1On: */
	/* test creation */
	
	SPTR(MuTable) tab1;
	SPTR(MuTable) tab2;
	SPTR(MuTable) tab3;
	
	oo << "Create tables with create, create: and create:with:\n";
	tab1 = IntegerTable::make ();
	tab2 = IntegerTable::make (4);
	tab3 = IntegerTable::make (5, 9);
	/* test printing */
	oo << "Printing tables:\n" << tab1 << "\n" << tab2 << "\n" << tab3 << "\n";
	/* testing */
	oo << "Test empty table: ";
	if (tab2->isEmpty()) {
		oo << "Empty";
	} else {
		oo << "Not Empty";
	}
	oo << "\n";
	/* inserting */
	tab1->introduce(IntegerPos::make (9), Sequence::string("filly"));
	tab1->atIntIntroduce(IntegerVar0, Sequence::string("mare"));
	oo << "Test introduce: " << tab1 << ", table count now: " << tab1->count() << "\n";
	tab1->atIntIntroduce(-11, Sequence::string("colt"));
	oo << "Test introduce: " << tab1 << ", table count now: " << tab1->count() << "\n";
	tab1->atIntIntroduce(47, Sequence::string("stallion"));
	oo << "Test introduce: " << tab1 << ", table count now: " << tab1->count() << "\n";
	{
		INSTALL_SHIELD(ex);
		SHIELD_UP_BEGIN(ex, AlreadyInTableFilter) {
			oo << "already in table blast caught, table now:\n" << tab1 << "\nand table count: " << tab1->count() << "\n";
			return;
			
		} SHIELD_UP_END(ex);
		tab1->atIntIntroduce(1, Sequence::string("palooka"));
	}
	oo << "Test introduce: \n";
	oo << "Testing introduce and fetch boundary conditions\n";
	{
		IntegerVar LoopFinal = 9;
		IntegerVar i = 5;
		for (;;) {
			if (i > LoopFinal){
				break;
			}
			{
				tab3->atIntIntroduce(i, IntegerPos::make (i));
				oo << "fetch of (" << i << ") is " << tab3->intFetch(i) << "\n";
			}
			i += 1;
		}
	}
	oo << "table 3 now:\n" << tab3 << "\nand its count is " << tab3->count() << "\n";
	tab3->atIntIntroduce(4, IntegerPos::make (4));
	tab3->atIntIntroduce(10, IntegerPos::make (10));
	tab3->atIntIntroduce(11, IntegerPos::make (11));
	oo << "table 3 now:\n" << tab3 << "\nand its count is " << tab3->count() << "\n";
	this->cleanTable(tab1);
	this->cleanTable(tab2);
	this->cleanTable(tab3);
}


void IntegerTableTester::test2On (ostream& aStream){
	/* self runTest: #test2On: */
	/* test creation */
	
	SPTR(MuTable) tab1;
	
	aStream << "Create tables.\n";
	tab1 = IntegerTable::make ();
	tab1->atIntIntroduce(1, Sequence::string("filly"));
	tab1->atIntIntroduce(IntegerVar0, Sequence::string("mare"));
	tab1->atIntIntroduce(-1, Sequence::string("colt"));
	tab1->atIntIntroduce(27, Sequence::string("stallion"));
	aStream << "Starting table is:\n" << tab1 << "\n";
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
		INSTALL_SHIELD(exc);
		SHIELD_UP_BEGIN(exc, NullInsertionFilter) {
			aStream << "NullInsertion blast caught, table now:\n" << tab1 << "\nand table count: " << tab1->count() << "\n";
			return;
			
		} SHIELD_UP_END(exc);
		tab1->atIntReplace(1, NULL);
		aStream << "Replace(NULL) not caught!\n";
	}
	this->cleanTable(tab1);
}


void IntegerTableTester::test3On (ostream& aStream){
	/* self runTest: #test3On: */
	/* test creation */
	
	SPTR(MuTable) tab1;
	
	aStream << "Create tables.\n";
	tab1 = IntegerTable::make ();
	tab1->atIntIntroduce(1, Sequence::string("filly"));
	tab1->atIntIntroduce(IntegerVar0, Sequence::string("mare"));
	tab1->atIntIntroduce(-1, Sequence::string("colt"));
	tab1->atIntIntroduce(27, Sequence::string("stallion"));
	aStream << "Starting table is:\n" << tab1 << "\n";
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
	this->cleanTable(tab1);
}


void IntegerTableTester::test4On (ostream& aStream){
	/* self runTest: #test4On: */
	/* test creation */
	
	SPTR(MuTable) tab1;
	
	aStream << "Create tables.\n";
	tab1 = IntegerTable::make ();
	tab1->atIntIntroduce(1, Sequence::string("filly"));
	tab1->atIntIntroduce(IntegerVar0, Sequence::string("mare"));
	tab1->atIntIntroduce(-1, Sequence::string("colt"));
	tab1->atIntIntroduce(27, Sequence::string("stallion"));
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
	this->cleanTable(tab1);
}


void IntegerTableTester::test5On (ostream& aStream){
	/* self runTest: #test5On: */
	/* test creation */
	
	SPTR(MuTable) tab1;
	
	aStream << "Create tables.\n";
	tab1 = IntegerTable::make ();
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
	tab1->intWipe(IntegerVar0);
	aStream << "Table now:\n" << tab1 << "\nwith count " << tab1->count() << "\nAnd wipe(0) again: ";
	tab1->intWipe(IntegerVar0);
	aStream << "Table now:\n" << tab1 << "\nwith count " << tab1->count() << "\n";
	this->cleanTable(tab1);
}


void IntegerTableTester::test6On (ostream& aStream){
	/* self runTest: #test6On: */
	/* test creation */
	
	SPTR(MuTable) tab1;
	SPTR(ScruTable) tab2;
	
	aStream << "Create tables.\n";
	tab1 = IntegerTable::make ();
	tab1->atIntIntroduce(1, Sequence::string("filly"));
	tab1->atIntIntroduce(IntegerVar0, Sequence::string("mare"));
	tab1->atIntIntroduce(-1, Sequence::string("colt"));
	tab1->atIntIntroduce(27, Sequence::string("stallion"));
	aStream << "Starting table is:\n" << tab1 << "\nwith count " << tab1->count() << "\nNow, testing subTable(0,40)\n";
	tab2 = CAST(IntegerTable,tab1)->subTable(IntegerRegion::make (IntegerVar0, 40));
	aStream << "Table now:\n" << tab1 << "\nwith count " << tab1->count() << "\nand the subtable is\n" << tab2 << "\nand its count is " << tab2->count() << ".\n";
	this->cleanTable(tab1);
}


void IntegerTableTester::test7On (ostream& aStream){
	/* self runTest: #test7On: */
	/* runs {Iterator} */
	/* test creation */
	
	SPTR(MuTable) tab1;
	SPTR(XnRegion) dom;
	
	aStream << "Create tables.\n";
	tab1 = IntegerTable::make ();
	tab1->atIntIntroduce(1, Sequence::string("filly"));
	tab1->atIntIntroduce(IntegerVar0, Sequence::string("mare"));
	tab1->atIntIntroduce(-1, Sequence::string("colt"));
	tab1->atIntIntroduce(27, Sequence::string("stallion"));
	aStream << "Starting table is:\n" << tab1 << "\nwith count " << tab1->count() << "\nNow, testing domain\n";
	dom = tab1->domain();
	aStream << "And the results (ta ta TUM!) \n\t" << dom << "\n";
	aStream << "\nand now, run lengths....\n";
	aStream << "tab1 runAt.IntegerVar: -20 ->" << tab1->runAtInt(-20);
	aStream << "\ntab1 runAt.IntegerVar: -10 ->" << tab1->runAtInt(-10);
	aStream << "\ntab1 runAt.IntegerVar:  -9 ->" << tab1->runAtInt(-9);
	{
		IntegerVar LoopFinal = 4;
		IntegerVar i = -1;
		for (;;) {
			if (i > LoopFinal){
				break;
			}
			{
				aStream << "\ntab1 runAt.IntegerVar:  " << i << " ->" << tab1->runAtInt(i);
			}
			i += 1;
		}
	}
	aStream << "\ntab1 runAt.IntegerVar:  26 ->" << tab1->runAtInt(26);
	aStream << "\ntab1 runAt.IntegerVar:  27 ->" << tab1->runAtInt(27);
	aStream << "\ntab1 runAt.IntegerVar:  28 ->" << tab1->runAtInt(28);
	aStream << "\ntab1 runAt.IntegerVar:  30 ->" << tab1->runAtInt(30);
	aStream << "\ntab1 runAt.IntegerVar:  31 ->" << tab1->runAtInt(31);
	aStream << "\ntab1 runAt.IntegerVar:  32 ->" << tab1->runAtInt(32);
	aStream << "\n";
	this->cleanTable(tab1);
}
/* running tests */


void IntegerTableTester::allTestsOn (ostream& aStream){
	/* IntegerTableTester runTest */
	
	aStream << "Running all IntegerTable tests.\nTest 1\n";
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
}

	/* automatic 0-argument constructor */
IntegerTableTester::IntegerTableTester() {}

#ifndef INTTABT_SXX
#include "inttabt.sxx"
#endif /* INTTABT_SXX */



#endif /* INTTABT_CXX */

