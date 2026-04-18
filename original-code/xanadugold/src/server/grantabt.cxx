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

#ifndef GRANTABT_CXX
#define GRANTABT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef GRANTABT_HXX
#include "grantabt.hxx"
#endif /* GRANTABT_HXX */

#ifndef GRANTABT_IXX
#include "grantabt.ixx"
#endif /* GRANTABT_IXX */


#ifndef HSPACEX_HXX
#include "hspacex.hxx"
#endif /* HSPACEX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */




/* ************************************************************************ *
 * 
 *                    Class GrandHashSetTester 
 *
 * ************************************************************************ */


/* testing */


void GrandHashSetTester::allTestsOn (ostream& oo){
	oo << "GrandHashSet testing\n";
	this->MuSetTester::allTestsOn(oo);
	oo << "End of GrandHashSet testing\n";
}
/* accessing */


RPTR(ScruSet) GrandHashSetTester::generateSet (){
	WPTR(ScruSet) 	returnValue;
	returnValue = GrandHashSet::make (2);
	return returnValue;
}


RPTR(ScruSet) GrandHashSetTester::generateSetContaining (APTR(Stepper) stuff){
	SPTR(MuSet) t;
	
	t = GrandHashSet::make (2);
	BEGIN_FOR_EACH(Heaper,e,(stuff)) {
		t->store(e);
	} END_FOR_EACH;
	WPTR(ScruSet) 	returnValue;
	returnValue = t;
	return returnValue;
}

	/* automatic 0-argument constructor */
GrandHashSetTester::GrandHashSetTester() {}



/* ************************************************************************ *
 * 
 *                    Class GrandHashTableTester 
 *
 * ************************************************************************ */


/* tests */


void GrandHashTableTester::bigTableTestOn (ostream& aStream){
	/* self runTest: #bigTableTestOn: */
	/* test growing */
	
	SPTR(MuTable) OF1(Pair) tab;
	SPTR(MuSet) OF1(HeaperAsPosition) keys;
	
	aStream << "Test growth behavior of GrandHashTable\n";
	tab = GrandHashTable::make (HeaperSpace::make ());
	keys = MuSet::make (4000);
	{
		Int32 LoopFinal = 4000;
		Int32 i = 1;
		for (;;) {
			if (i > LoopFinal){
				break;
			}
			{
				SPTR(Pair) thing;
				SPTR(HeaperAsPosition) key;
				
				thing = Pair::make (IntegerPos::make (4000), IntegerPos::make (3 * i));
				key = HeaperAsPosition::make (thing);
				tab->introduce(key, thing);
				/* i > 400 ifTrue:
								[keys stepper forEach: [ : 
					foo {HeaperAsPosition} |
									tab get: foo]] */
				keys->introduce(key);
			}
			i += 1;
		}
	}
	BEGIN_FOR_EACH(HeaperAsPosition,key,(keys->stepper())) {
		tab->get(key);
	} END_FOR_EACH;
	aStream << "Growth test successful.\n";
}


void GrandHashTableTester::test1On (ostream& oo){
	/* self runTest: #test1On: */
	/* test creation */
	
	SPTR(MuTable) tab1;
	SPTR(MuTable) tab2;
	
	oo << "Create tables with create, create: and create:with:\n\n";
	tab1 = GrandHashTable::make (IntegerSpace::make ());
	tab2 = GrandHashTable::make (IntegerSpace::make (), 4);
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
	tab1->atIntIntroduce(1, UInt8Array::string("filly"));
	tab1->atIntIntroduce(IntegerVar0, UInt8Array::string("mare"));
	oo << "Test introduce: " << tab1 << ", table count now: " << tab1->count() << "\n\n";
	tab1->atIntIntroduce(-1, UInt8Array::string("colt"));
	oo << "Test introduce: " << tab1 << ", table count now: " << tab1->count() << "\n\n";
	tab1->atIntIntroduce(27, UInt8Array::string("stallion"));
	oo << "Test introduce: " << tab1 << ", table count now: " << tab1->count() << "\n\n";
	{
		INSTALL_SHIELD(ex);
		SHIELD_UP_BEGIN(ex, AlreadyInTableFilter) {
			oo << "already in table blast caught, table now:\n\n" << tab1 << "\n\nand table count: " << tab1->count() << "\n\n";
			return;
			
		} SHIELD_UP_END(ex);
		tab1->atIntIntroduce(1, UInt8Array::string("palooka"));
	}
	oo << "Test empty table: ";
	if (tab1->isEmpty()) {
		oo << "Empty";
	} else {
		oo << "Not Empty";
	}
	oo << "\n\n";
}


void GrandHashTableTester::test2On (ostream& aStream){
	/* self runTest: #test2On: */
	/* test creation */
	
	SPTR(MuTable) tab1;
	
	aStream << "Create tables.\n\n";
	tab1 = GrandHashTable::make (IntegerSpace::make ());
	tab1->atIntIntroduce(1, UInt8Array::string("filly"));
	tab1->atIntIntroduce(IntegerVar0, UInt8Array::string("mare"));
	tab1->atIntIntroduce(-1, UInt8Array::string("colt"));
	tab1->atIntIntroduce(27, UInt8Array::string("stallion"));
	aStream << "Starting table is:\n\n" << tab1 << "\n\n";
	tab1->atIntReplace(1, UInt8Array::string("mare"));
	aStream << "after replace:\n" << tab1 << " and table count: " << tab1->count() << "\n";
	aStream << "Test replace() in unknown territory. \n";
	{
		INSTALL_SHIELD(ex);
		SHIELD_UP_BEGIN(ex, NotInTableFilter) {
			aStream << "NotInTable blast caught, table now:\n" << tab1 << "\nand table count: " << tab1->count() << "\n";
			return;
			
		} SHIELD_UP_END(ex);
		tab1->atIntReplace(2, UInt8Array::string("palooka"));
	}
	aStream << "Test replace() with NULL. \n";
	{
		INSTALL_SHIELD(ex);
		SHIELD_UP_BEGIN(ex, NullInsertionFilter) {
			aStream << "NullInsertion blast caught, table now:\n" << tab1 << "\nand table count: " << tab1->count() << "\n";
			return;
			
		} SHIELD_UP_END(ex);
		tab1->atIntReplace(1, NULL);
		aStream << "Replace(NULL) not caught!\n";
	}
}


void GrandHashTableTester::test3On (ostream& aStream){
	/* self runTest: #test3On: */
	/* test creation */
	
	SPTR(MuTable) tab1;
	
	aStream << "Create tables.\n\n";
	tab1 = GrandHashTable::make (IntegerSpace::make ());
	tab1->atIntIntroduce(1, UInt8Array::string("filly"));
	tab1->atIntIntroduce(IntegerVar0, UInt8Array::string("mare"));
	tab1->atIntIntroduce(-1, UInt8Array::string("colt"));
	tab1->atIntIntroduce(27, UInt8Array::string("stallion"));
	aStream << "Starting table is:\n\n" << tab1 << "\n\n";
	tab1->atIntStore(1, UInt8Array::string("mare"));
	aStream << "after store:\n\n" << tab1 << " and table count: " << tab1->count() << "\n\n";
	aStream << "Test store() in unknown territory. \n\n";
	{
		INSTALL_SHIELD(ex);
		SHIELD_UP_BEGIN(ex, NotInTableFilter) {
			aStream << "NotInTable blast caught, table now:\n\n" << tab1 << "\n\nand table count: " << tab1->count() << "\n\n";
			return;
			
		} SHIELD_UP_END(ex);
		tab1->atIntStore(2, UInt8Array::string("palooka"));
	}
	aStream << "after store:\n\n" << tab1 << " and table count: " << tab1->count() << "\n\n";
	aStream << "Test store() with NULL. \n\n";
	{
		INSTALL_SHIELD(ex);
		SHIELD_UP_BEGIN(ex, NullInsertionFilter) {
			aStream << "NullInsertion blast caught, table now:\n\n" << tab1 << "\n\nand table count: " << tab1->count() << "\n\n";
			return;
			
		} SHIELD_UP_END(ex);
		tab1->atIntStore(3, NULL);
	}
}


void GrandHashTableTester::test4On (ostream& aStream){
	/* self runTest: #test4On: */
	/* test creation */
	
	SPTR(MuTable) tab1;
	
	aStream << "Create tables.\n\n";
	tab1 = GrandHashTable::make (IntegerSpace::make ());
	tab1->introduce(IntegerPos::make (1), UInt8Array::string("filly"));
	tab1->introduce(Integer0, UInt8Array::string("mare"));
	tab1->introduce(IntegerPos::make (-1), UInt8Array::string("colt"));
	tab1->introduce(IntegerPos::make (27), UInt8Array::string("stallion"));
	aStream << "Starting table is:\n\n" << tab1 << "\n\nwith count " << tab1->count() << "\n\n";
	/* testing enclosure */
	aStream << "Testing domain\n\n" << tab1->domain() << "\n\n";
	/* test get */
	aStream << "Test get(1) " << tab1->intGet(1) << "\n\n";
	aStream << "Test get() in unknown territory. \n\n";
	{
		INSTALL_SHIELD(ex);
		SHIELD_UP_BEGIN(ex, NotInTableFilter) {
			aStream << "NotInTable blast caught, table now:\n\n" << tab1 << "\n\nand table count: " << tab1->count() << "\n\n";
			return;
			
		} SHIELD_UP_END(ex);
		tab1->intGet(14);
	}
}


void GrandHashTableTester::test5On (ostream& aStream){
	/* self runTest: #test5On: */
	/* test creation */
	
	SPTR(MuTable) tab1;
	
	aStream << "Create tables.\n\n";
	tab1 = GrandHashTable::make (IntegerSpace::make ());
	tab1->atIntIntroduce(1, UInt8Array::string("filly"));
	tab1->atIntIntroduce(IntegerVar0, UInt8Array::string("mare"));
	tab1->atIntIntroduce(-1, UInt8Array::string("colt"));
	tab1->atIntIntroduce(27, UInt8Array::string("stallion"));
	aStream << "Starting table is:\n\n" << tab1 << "\n\nwith count " << tab1->count() << "\n\nNow, testing remove(1)\n\n";
	tab1->intRemove(1);
	aStream << "Table now:\n\n" << tab1 << "\n\nwith count " << tab1->count() << "\n\n";
	aStream << "Test remove(1) in unknown territory. \n\n";
	{
		INSTALL_SHIELD(ex);
		SHIELD_UP_BEGIN(ex, NotInTableFilter) {
			aStream << "NotInTable blast caught, table now:\n\n" << tab1 << "\n\nand table count: " << tab1->count() << "\n\n";
			return;
			
		} SHIELD_UP_END(ex);
		tab1->intRemove(1);
	}
	aStream << "Test wipe(0)\n\n";
	tab1->wipe(Integer0);
	aStream << "Table now:\n\n" << tab1 << "\n\nwith count " << tab1->count() << "\n\nAnd wipe(0) again: ";
	tab1->wipe(Integer0);
	aStream << "Table now:\n\n" << tab1 << "\n\nwith count " << tab1->count() << "\n\n";
}


void GrandHashTableTester::test7On (ostream& aStream){
	/* self runTest: #test7On: */
	/* Not currently appropriate to GrandHashTable */
	/* runs {Iterator} */
	/* test creation */
	
	SPTR(MuTable) tab1;
	
	aStream << "Create tables.\n\n";
	tab1 = GrandHashTable::make (IntegerSpace::make ());
	tab1->atIntIntroduce(1, UInt8Array::string("filly"));
	tab1->atIntIntroduce(IntegerVar0, UInt8Array::string("mare"));
	tab1->atIntIntroduce(-1, UInt8Array::string("colt"));
	tab1->atIntIntroduce(27, UInt8Array::string("stallion"));
	aStream << "Starting table is:\n\n" << tab1 << "\n\nwith count " << tab1->count() << "\n\nNow, testing runEnclosures\n\n";
	/* 	runs _ tab1 domain. 
			
			aStream << 'And the results (ta ta TUM!) 
			
			' << runs << ' 
			
			and now, run lengths.... 
			
			'. */
	aStream << "tab1 runAt: -20 ->" << tab1->runAtInt(-20);
	aStream << "\n\ntab1 runLengthAt: -10 ->" << tab1->runAtInt(-10);
	aStream << "\n\ntab1 runLengthAt: -9 ->" << tab1->runAtInt(-9);
	{
		IntegerVar LoopFinal = 4;
		IntegerVar i = -1;
		for (;;) {
			if (i > LoopFinal){
				break;
			}
			{
				aStream << "\n\ntab1 runLengthAt: " << i << " ->" << tab1->runAtInt(i);
			}
			i += 1;
		}
	}
	aStream << "\n\ntab1 runLengthAt: 26 ->" << tab1->runAtInt(26);
	aStream << "\n\ntab1 runLengthAt: 27 ->" << tab1->runAtInt(27);
	aStream << "\n\ntab1 runLengthAt: 28 ->" << tab1->runAtInt(28);
	aStream << "\n\ntab1 runLengthAt: 30 ->" << tab1->runAtInt(30);
	aStream << "\n\ntab1 runAt.IntegerVar: 31 ->" << tab1->runAtInt(31);
	aStream << "\n\ntab1 runAt.IntegerVar: 32 ->" << tab1->runAtInt(32);
}
/* running tests */


void GrandHashTableTester::allTestsOn (ostream& aStream){
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
	this->bigTableTestOn(aStream);
}

	/* automatic 0-argument constructor */
GrandHashTableTester::GrandHashTableTester() {}

#ifndef GRANTABT_SXX
#include "grantabt.sxx"
#endif /* GRANTABT_SXX */



#endif /* GRANTABT_CXX */

