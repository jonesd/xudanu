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

#ifndef SETTABT_CXX
#define SETTABT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef SETTABT_HXX
#include "settabt.hxx"
#endif /* SETTABT_HXX */

#ifndef SETTABT_IXX
#include "settabt.ixx"
#endif /* SETTABT_IXX */


#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef SEQUENCX_HXX
#include "sequencx.hxx"
#endif /* SEQUENCX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */

#ifndef TABLESX_HXX
#include "tablesx.hxx"
#endif /* TABLESX_HXX */




/* ************************************************************************ *
 * 
 *                    Class SetTableTester 
 *
 * ************************************************************************ */


/* tests */


void SetTableTester::allTestsOn (ostream& oo){
	this->simpleAccess(oo);
	this->test1on(oo);
	this->growTestOn(oo);
	this->growTest2On(oo);
	this->stepTestOn(oo);
}


void SetTableTester::growTest2On (ostream& oo){
	SPTR(SetTable) tab;
	SPTR(ScruSet) keyPile;
	SPTR(ScruSet) valuePile;
	IntegerVar oc;
	
	keyPile = this->testKeys();
	valuePile = this->testValues();
	oo << "start of grow test 2, add key->value associations in a different order\n";
	tab = SetTable::make (this->testCS());
	oc = IntegerVar0;
	BEGIN_FOR_EACH(Heaper,val,(valuePile->stepper())) {
		BEGIN_FOR_EACH(Position,key,(keyPile->stepper())) {
			if (!(tab->count() == oc)) {
				oo << "table count wrong before store! " << tab << "\n";
			}
			tab->introduce(key, val);
			oc += 1;
			if (!(tab->count() == oc)) {
				oo << "table count wrong after store!  " << tab << "\n";
			}
			if (!(tab->count() == this->manualCount(tab))) {
				oo << "manual count doesn\'t match count!  " << tab << "\n";
			}
		} END_FOR_EACH;
	} END_FOR_EACH;
	oo << "end of grow test 2, table now:\n" << tab << "\n\nnow - remove all those entries, use a different order than the introduce order\n";
	BEGIN_FOR_EACH(Position,key2,(keyPile->stepper())) {
		BEGIN_FOR_EACH(Heaper,val2,(valuePile->stepper())) {
			if (!(tab->count() == oc)) {
				oo << "table count wrong before remove! " << tab << "\n";
			}
			tab->remove(key2, val2);
			oc -= 1;
			if (!(tab->count() == oc)) {
				oo << "table count wrong after remove!  " << tab << "\n";
			}
			if (!(tab->count() == this->manualCount(tab))) {
				oo << "manual count doesn\'t match count!  " << tab << "\n";
			}
		} END_FOR_EACH;
	} END_FOR_EACH;
	oo << "\nend of remove test. ta ta!\n";
}


void SetTableTester::growTestOn (ostream& oo){
	SPTR(SetTable) tab;
	SPTR(ScruSet) keyPile;
	SPTR(ScruSet) valuePile;
	IntegerVar oc;
	
	keyPile = this->testKeys();
	valuePile = this->testValues();
	oo << "start of grow test, keys =\n" << keyPile << "\nand values = " << valuePile << "\n";
	tab = SetTable::make (this->testCS());
	oc = IntegerVar0;
	BEGIN_FOR_EACH(Position,key,(keyPile->stepper())) {
		BEGIN_FOR_EACH(Heaper,val,(valuePile->stepper())) {
			if (!(tab->count() == oc)) {
				oo << "table count wrong before store! " << tab << "\n";
			}
			tab->introduce(key, val);
			oc += 1;
			if (!(tab->count() == oc)) {
				oo << "table count wrong after store!  " << tab << "\n";
			}
			if (!(tab->count() == this->manualCount(tab))) {
				oo << "manual count doesn\'t match count!  " << tab << "\n";
			}
		} END_FOR_EACH;
	} END_FOR_EACH;
	oo << "end of grow test, table now:\n" << tab << "\n\nand the domain is: " << tab->domain() << "\n\nnow - remove all those entries!\n";
	BEGIN_FOR_EACH(Position,key2,(keyPile->stepper())) {
		BEGIN_FOR_EACH(Heaper,val2,(valuePile->stepper())) {
			if (!(tab->count() == oc)) {
				oo << "table count wrong before remove! " << tab << "\n";
			}
			tab->remove(key2, val2);
			oc -= 1;
			if (!(tab->count() == oc)) {
				oo << "table count wrong after remove!  " << tab << "\n";
			}
			if (!(tab->count() == this->manualCount(tab))) {
				oo << "manual count doesn\'t match count!  " << tab << "\n";
			}
		} END_FOR_EACH;
	} END_FOR_EACH;
	oo << "\nend of remove test. ta ta!\n";
}


void SetTableTester::simpleAccess (ostream& oo){
	SPTR(SetTable) tab;
	
	tab = SetTable::make (IntegerSpace::make ());
	oo << "Introduce I(2) at I(1).\n";
	tab->introduce(IntegerPos::make (1), IntegerPos::make (2));
	oo << "Retrieve all from 1: \n";
	BEGIN_FOR_EACH(Heaper,elem,(tab->stepperAtInt(1))) {
		oo << "\t" << elem << "\n";
	} END_FOR_EACH;
	oo << "\n";
	oo << "Introduce I(2) at I(1) again and catch the blast.\n";
	do {
		INSTALL_SHIELD(ex);
		SHIELD_UP_BEGIN(ex, AlreadyInTableFilter) {
			oo << "Blasted while introducing.\n\n";
			break;
		} SHIELD_UP_END(ex);
		tab->introduce(IntegerPos::make (1), IntegerPos::make (2));
		oo << "Should have blasted on second introduce.\n";
	} while (FALSE);
	oo << "Store I(3) at 1.\n";
	tab->atIntStore(1, IntegerPos::make (3));
	oo << "Retrieve all from I(1): \n";
	BEGIN_FOR_EACH(Heaper,elem2,(tab->stepperAt(IntegerPos::make (1)))) {
		oo << "\t" << elem2 << "\n";
	} END_FOR_EACH;
	oo << "\n";
	oo << "Store I(4) at 1.\n";
	tab->atIntStore(1, IntegerPos::make (4));
	oo << "Retrieve all from 1: \n";
	BEGIN_FOR_EACH(Heaper,elem3,(tab->stepperAtInt(1))) {
		oo << "\t" << elem3 << "\n";
	} END_FOR_EACH;
	oo << "\n";
	oo << "Table is now: " << tab << "\nRemove I(3) at I(1).\n";
	tab->remove(IntegerPos::make (1), IntegerPos::make (3));
	oo << "Table is now: " << tab << "\n\n";
}


void SetTableTester::stepTestOn (ostream& oo){
	SPTR(Stepper) stepr;
	SPTR(ScruSet) OF1(Position) keyPile;
	SPTR(ScruSet) OF1(Heaper) valuePile;
	SPTR(SetTable) tab;
	
	oo << "Test fetching of steppers (stepper at a key).\n";
	keyPile = this->testKeys();
	valuePile = this->testValues();
	tab = SetTable::make (this->testCS());
	BEGIN_FOR_EACH(Position,key,(keyPile->stepper())) {
		BEGIN_FOR_EACH(Heaper,val,(valuePile->stepper())) {
			tab->introduce(key, val);
		} END_FOR_EACH;
	} END_FOR_EACH;
	BEGIN_FOR_EACH(Position,key2,(keyPile->stepper())) {
		SPTR(MuSet) valSet;
		
		valSet = this->testValues()->asMuSet();
		stepr = tab->stepperAt(key2);
		oo << "stepper for key " << key2 << " is " << stepr << "\n";
		BEGIN_FOR_EACH(Heaper,val3,(stepr)) {
			valSet->remove(val3);
		} END_FOR_EACH;
		if (!valSet->isEmpty()) {
			oo << "valSet contains " << valSet << "\n";
		}
	} END_FOR_EACH;
	oo << "end of stepperAt: test\n\n";
}


void SetTableTester::test1on (ostream& oo){
	SPTR(SetTable) tab1;
	SPTR(TableStepper) stp;
	
	tab1 = SetTable::make (IntegerSpace::make ());
	oo << "table is now " << tab1 << "\n";
	tab1->store(IntegerPos::make (1), Sequence::string("abcd"));
	tab1->store(IntegerPos::make (1), Sequence::string("abce"));
	tab1->store(IntegerPos::make (1), Sequence::string("abcf"));
	tab1->store(IntegerPos::make (1), Sequence::string("abcg"));
	tab1->store(IntegerPos::make (1), Sequence::string("abch"));
	tab1->store(IntegerPos::make (1), Sequence::string("abci"));
	oo << "tab1 is now " << tab1 << "\n";
	tab1->store(IntegerPos::make (2), Sequence::string("abcd"));
	tab1->store(IntegerPos::make (2), Sequence::string("abce"));
	tab1->store(IntegerPos::make (2), Sequence::string("abcf"));
	tab1->store(IntegerPos::make (2), Sequence::string("abcg"));
	tab1->store(IntegerPos::make (2), Sequence::string("abch"));
	tab1->store(IntegerPos::make (2), Sequence::string("abci"));
	oo << "tab1 is now " << tab1 << "\n";
	tab1->store(IntegerPos::make (3), Sequence::string("abcd"));
	tab1->store(IntegerPos::make (3), Sequence::string("abce"));
	tab1->store(IntegerPos::make (3), Sequence::string("abcf"));
	tab1->store(IntegerPos::make (3), Sequence::string("abcg"));
	tab1->store(IntegerPos::make (3), Sequence::string("abch"));
	tab1->store(IntegerPos::make (3), Sequence::string("abci"));
	oo << "tab1 is now " << tab1 << "\n";
	oo << "\ncontents of table are:\n";
	BEGIN_FOR_EACH(Heaper,elem,(stp = tab1->stepper())) {
		oo << "tab1 fetch: " << stp->position() << " == " << elem << "\n";
	} END_FOR_EACH;
}
/* private: testing */


IntegerVar SetTableTester::lastTestValue (){
	return 9;
}


IntegerVar SetTableTester::manualCount (APTR(SetTable) table){
	IntegerVar cnt;
	
	cnt = IntegerVar0;
	BEGIN_FOR_EACH(Heaper,elem,(table->stepper())) {
		if (elem != NULL) {
			cnt += 1;
		}
	} END_FOR_EACH;
	/* kill st80 'elem not used' msg */
	return cnt;
}


RPTR(CoordinateSpace) SetTableTester::testCS (){
	WPTR(CoordinateSpace) 	returnValue;
	returnValue = SequenceSpace::make ();
	return returnValue;
}


RPTR(ScruSet) OF1(Position) SetTableTester::testKeys (){
	SPTR(MuSet) OF1(Position) keys;
	
	keys = MuSet::make ();
	keys->introduce(Sequence::string("fghijklmna"));
	keys->introduce(Sequence::string("fghijklmnb"));
	keys->introduce(Sequence::string("fghijklmnc"));
	keys->introduce(Sequence::string("fghijklmnd"));
	keys->introduce(Sequence::string("fghijklmne"));
	keys->introduce(Sequence::string("fghijklmao"));
	keys->introduce(Sequence::string("fghijklmbo"));
	keys->introduce(Sequence::string("fghijklmco"));
	keys->introduce(Sequence::string("fghijklmdo"));
	keys->introduce(Sequence::string("fghijklmeo"));
	keys->introduce(Sequence::string("fghijklano"));
	keys->introduce(Sequence::string("fghijklbno"));
	keys->introduce(Sequence::string("fghijklcno"));
	keys->introduce(Sequence::string("fghijkldno"));
	keys->introduce(Sequence::string("fghijkleno"));
	keys->introduce(Sequence::string("fghijkamno"));
	keys->introduce(Sequence::string("fghijkbmno"));
	keys->introduce(Sequence::string("fghijkcmno"));
	keys->introduce(Sequence::string("fghijkdmno"));
	keys->introduce(Sequence::string("fghijkemno"));
	keys->introduce(Sequence::string("fghijalmno"));
	keys->introduce(Sequence::string("fghijblmno"));
	keys->introduce(Sequence::string("fghijclmno"));
	keys->introduce(Sequence::string("fghijdlmno"));
	keys->introduce(Sequence::string("fghijelmno"));
	keys->introduce(Sequence::string("fghiaklmno"));
	keys->introduce(Sequence::string("fghibklmno"));
	keys->introduce(Sequence::string("fghicklmno"));
	keys->introduce(Sequence::string("fghidklmno"));
	keys->introduce(Sequence::string("fghieklmno"));
	keys->introduce(Sequence::string("fghajklmno"));
	keys->introduce(Sequence::string("fghbjklmno"));
	keys->introduce(Sequence::string("fghcjklmno"));
	keys->introduce(Sequence::string("fghdjklmno"));
	keys->introduce(Sequence::string("fghejklmno"));
	keys->introduce(Sequence::string("fgaijklmno"));
	keys->introduce(Sequence::string("fgbijklmno"));
	keys->introduce(Sequence::string("fgcijklmno"));
	keys->introduce(Sequence::string("fgdijklmno"));
	keys->introduce(Sequence::string("fgeijklmno"));
	keys->introduce(Sequence::string("fahijklmno"));
	keys->introduce(Sequence::string("fbhijklmno"));
	keys->introduce(Sequence::string("fchijklmno"));
	keys->introduce(Sequence::string("fdhijklmno"));
	keys->introduce(Sequence::string("fehijklmno"));
	keys->introduce(Sequence::string("aghijklmno"));
	keys->introduce(Sequence::string("bghijklmno"));
	keys->introduce(Sequence::string("cghijklmno"));
	keys->introduce(Sequence::string("dghijklmno"));
	keys->introduce(Sequence::string("eghijklmno"));
	WPTR(ScruSet) OF1(Position) 	returnValue;
	returnValue = keys;
	return returnValue;
}


RPTR(ScruSet) OF1(Heaper) SetTableTester::testValues (){
	SPTR(MuSet) OF1(IntegerPos) vals;
	
	vals = MuSet::make ();
	{
		IntegerVar LoopFinal = this->lastTestValue();
		IntegerVar ti = IntegerVar0;
		for (;;) {
			if (ti > LoopFinal){
				break;
			}
			{
				vals->introduce(IntegerPos::make (ti));
			}
			ti += 1;
		}
	}
	WPTR(ScruSet) OF1(Heaper) 	returnValue;
	returnValue = vals;
	return returnValue;
}

	/* automatic 0-argument constructor */
SetTableTester::SetTableTester() {}

#ifndef SETTABT_SXX
#include "settabt.sxx"
#endif /* SETTABT_SXX */



#endif /* SETTABT_CXX */

