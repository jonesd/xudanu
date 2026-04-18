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

#ifndef DISKMANT_CXX
#define DISKMANT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef DISKMANT_HXX
#include "diskmant.hxx"
#endif /* DISKMANT_HXX */

#ifndef DISKMANT_IXX
#include "diskmant.ixx"
#endif /* DISKMANT_IXX */


#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef PACKERT_HXX
#include "packert.hxx"
#endif /* PACKERT_HXX */

#ifndef PACKERX_HXX
#include "packerx.hxx"
#endif /* PACKERX_HXX */

#ifndef TABLESX_HXX
#include "tablesx.hxx"
#endif /* TABLESX_HXX */




/* ************************************************************************ *
 * 
 *                    Class DiskTester 
 *
 * ************************************************************************ */


/* tests */


void DiskTester::destroyTest (ostream& /* oo */){
	/* self runTest: #destroyTest: */
	
	SPTR(MuTable) table;
	
	table = MuTable::make (IntegerSpace::make ());
	{
		Int32 LoopFinal = 100;
		Int32 i = 1;
		for (;;) {
			if (i > LoopFinal){
				break;
			}
			{
				SPTR(Abraham) shep;
				
				table->atIntIntroduce(i, DoublingFlock::make (i, i));
				shep = CAST(Abraham,table->intFetch(i / 2));
				if (shep != NULL) {
					{shep->destroy();  shep = NULL /* don't want stale (S/CHK)PTRs */;}
					table->intWipe(i / 2);
				}
				BLAST(NOT_YET_IMPLEMENTED);
				/* CurrentPacker fluidVar makeConsistent. */
				if (i % 20 == Int32Zero) {
					CAST(SnarfPacker,CurrentPacker.fluidGet())->makePersistent();
				}
			}
			i += 1;
		}
	}
	CurrentPacker.fluidGet()->purge();
}


void DiskTester::forward1Test (ostream& oo){
	/* self runTest: #forward1Test: */
	
	SPTR(DoublingFlock) a;
	SPTR(DoublingFlock) b;
	SPTR(SnarfPacker) packer;
	
	a = DoublingFlock::make (1);
	b = DoublingFlock::make (2);
	packer = CAST(SnarfPacker,CurrentPacker.fluidGet());
	oo << "Flock a is " << a << " at " << a->getInfo() << "\nFlock b is " << b << " at " << b->getInfo() << "\n";
	packer->makePersistent();
	while (a->getInfo()->snarfID() == b->getInfo()->snarfID()) {
		a->doDouble();
		b->doDouble();
		oo << "doubled to " << a->count() << "\n";
		/* a count >= 512 ifTrue: [self halt]. */
		packer->makePersistent();
	}
}


void DiskTester::forward2Test (ostream& oo){
	/* self runTest: #forward2Test: */
	
	SPTR(PairFlock) pair;
	SPTR(SnarfPacker) packer;
	
	CONSTRUCT(pair,PairFlock,(DoublingFlock::make (1), DoublingFlock::make (2)));
	packer = CAST(SnarfPacker,CurrentPacker.fluidGet());
	oo << "Flock a is " << pair->left() << " at " << pair->left()->getInfo() << "\nFlock b is " << pair->right() << " at " << pair->right()->getInfo() << "\n";
	packer->makePersistent();
	while (pair->left()->getInfo()->snarfID() == pair->right()->getInfo()->snarfID()) {
		CAST(DoublingFlock,pair->left())->doDouble();
		CAST(DoublingFlock,pair->right())->doDouble();
		oo << "doubled to " << CAST(DoublingFlock,pair->left())->count() << "\n";
		/* pair left count >= 512 ifTrue: [self halt]. */
		packer->purge();
	}
}


void DiskTester::toDiskAndBackTestOn (ostream& aStream){
	/* self runTest: #toDiskAndBackTestOn: */
	/* test writing to disk and reading back */
	
	SPTR(MultiCounter) firstCounter;
	SPTR(MultiCounter) secondCounter;
	
	aStream << "\nTest ability to write an object to disk and read it back\n";
	firstCounter = MultiCounter::make (5);
	firstCounter->incrementBoth();
	secondCounter = MultiCounter::make ();
	/* CASCADE */
	secondCounter->incrementFirst();
	secondCounter->incrementFirst();
	secondCounter->incrementBoth();
	aStream << "\nFirst MultiCounter = " << firstCounter;
	aStream << "\nSecond MultiCounter = " << secondCounter;
	aStream << "\n\nPurging.";
	CurrentPacker.fluidGet()->purge();
	aStream << "\n\nBringing First MultiCounter back; value = " << firstCounter;
	/* CASCADE */
	firstCounter->decrementBoth();
	firstCounter->decrementSecond();
	aStream << "\nFirst MultiCounter = " << firstCounter;
	aStream << "\n\nBringing Second MultiCounter back and incrementing.";
	/* CASCADE */
	secondCounter->incrementSecond();
	secondCounter->incrementSecond();
	secondCounter->incrementBoth();
	aStream << "\nSecond MultiCounter = " << secondCounter;
	aStream << "\n\nPurging again.";
	CurrentPacker.fluidGet()->purge();
	aStream << "\n\nBringing First MultiCounter back; value = " << firstCounter;
	/* CASCADE */
	firstCounter->decrementBoth();
	firstCounter->decrementSecond();
	aStream << "\nFirst MultiCounter = " << firstCounter;
	aStream << "\n\nBringing Second MultiCounter back and incrementing.";
	/* CASCADE */
	secondCounter->incrementSecond();
	secondCounter->incrementSecond();
	secondCounter->incrementBoth();
	aStream << "\nSecond MultiCounter = " << secondCounter;
}
/* running tests */


void DiskTester::allTestsOn (ostream& oo){
	/* DiskTester runTest */
	
	SPTR(Connection) conn;
	
	conn = Connection::make (cat_Counter);
	myBootCounter = CAST(Counter,conn->bootHeaper());
	this->destroyTest(oo);
	this->toDiskAndBackTestOn(oo);
	this->forward1Test(oo);
	this->forward2Test(oo);
	{conn->destroy();  conn = NULL /* don't want stale (S/CHK)PTRs */;}
}
/* hooks: */


void DiskTester::restartDiskTester (APTR(Rcvr) /* rcvr *//* = NULL*/){
	myBootCounter = NULL;
}

	/* automatic 0-argument constructor */
DiskTester::DiskTester() {}



/* ************************************************************************ *
 * 
 *                    Class MultiCounter 
 *
 * ************************************************************************ */


/* pseudo constructors  */


RPTR(MultiCounter) MultiCounter::make (){
	RETURN_CONSTRUCT(MultiCounter,());
}


RPTR(MultiCounter) MultiCounter::make (IntegerVar count){
	RETURN_CONSTRUCT(MultiCounter,(count, tcsj));
}
/* accessing */


void MultiCounter::decrementBoth (){
	BEGIN_CONSISTENT(2) {
		myFirst->decrement();
		mySecond->decrement();
	} END_CONSISTENT;
}


IntegerVar MultiCounter::decrementFirst (){
	return myFirst->decrement();
}


IntegerVar MultiCounter::decrementSecond (){
	return mySecond->decrement();
}


IntegerVar MultiCounter::firstCount (){
	return myFirst->count();
}


void MultiCounter::incrementBoth (){
	BEGIN_CONSISTENT(2) {
		myFirst->increment();
		mySecond->increment();
	} END_CONSISTENT;
}


IntegerVar MultiCounter::incrementFirst (){
	return myFirst->increment();
}


IntegerVar MultiCounter::incrementSecond (){
	return mySecond->increment();
}


IntegerVar MultiCounter::secondCount (){
	return mySecond->count();
}
/* creation */


MultiCounter::MultiCounter () {
	myFirst = Counter::make (IntegerVar0);
	mySecond = Counter::make (IntegerVar0);
	this->newShepherd();
	this->remember();
}


MultiCounter::MultiCounter (IntegerVar first, TCSJ) {
	myFirst = Counter::make (first);
	mySecond = Counter::make (IntegerVar0);
	this->newShepherd();
	this->remember();
}


MultiCounter::MultiCounter (IntegerVar first, IntegerVar second) {
	myFirst = Counter::make (first);
	mySecond = Counter::make (second);
	this->newShepherd();
	this->remember();
}
/* printing */


void MultiCounter::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myFirst->count() << ", " << mySecond->count() << ")";
}
/* testing */


UInt32 MultiCounter::contentsHash (){
	return this->Abraham::contentsHash() ^ myFirst->hashForEqual() ^ mySecond->hashForEqual();
}

#ifndef DISKMANT_SXX
#include "diskmant.sxx"
#endif /* DISKMANT_SXX */



#endif /* DISKMANT_CXX */

