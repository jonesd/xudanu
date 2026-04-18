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

#ifndef URDIT_CXX
#define URDIT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef URDIT_HXX
#include "urdit.hxx"
#endif /* URDIT_HXX */

#ifndef URDIT_IXX
#include "urdit.ixx"
#endif /* URDIT_IXX */


#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */




/* ************************************************************************ *
 * 
 *                    Class SnarfTester 
 *
 * ************************************************************************ */


/* testing */


void SnarfTester::allTestsOn (ostream& oo){
	/* SnarfTester runTest. */
	
	this->testAllocationsOn(oo);
}


void SnarfTester::binaryCheck (APTR(XnRegion) a, APTR(XnRegion) b){
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


void SnarfTester::testAllocationsOn (ostream& oo){
	/* packer _ snarfPacker create: UrdiVew create. */
	
	SPTR(UNKNOWN) handle;
	SPTR(UNKNOWN) handler;
	SPTR(UNKNOWN) index;
	
	CONSTRUCT(handle,SnarfHandle,(1, 5000));
	CONSTRUCT(handler,SnarfHandler,(handle, tcsj));
	index = handler->allocate(100);
	if ( ! (handler->refit(index, 1000)) ) {
		BLAST(refit_failed);
	}
	if ( ! (handler->refit(index, 10)) ) {
		BLAST(refit_failed);
	}
	if ( ! (handler->refit(index, IntegerVar0)) ) {
		BLAST(refit_failed);
	}
}


void SnarfTester::testBinaryRegionOpsOn (ostream& oo){
	BEGIN_FOR_EACH(XnRegion,one,(myExampleRegions->stepper())) {
		BEGIN_FOR_EACH(XnRegion,two,(myExampleRegions->stepper())) {
			if (one->asOop() <= two->asOop()) {
				oo << "checking binary ops of " << one << " and " << two << "\n";
				
				/* smalltalk runs out of space */
				this->binaryCheck(one, two);
			}
		} END_FOR_EACH;
	} END_FOR_EACH;
	oo << "binary regions tests succeeded\n";
}


void SnarfTester::testUnaryRegionOpsOn (ostream& oo){
	BEGIN_FOR_EACH(XnRegion,one,(myExampleRegions->stepper())) {
		oo << "checking unary ops of " << one << "\n";
		
		/* smalltalk runs out of space */
		this->unaryCheck(one);
	} END_FOR_EACH;
	oo << "unary regions tests succeeded\n";
}


void SnarfTester::unaryCheck (APTR(XnRegion) a){
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


RPTR(ImmuSet) OF1(XnRegion) SnarfTester::exampleRegions (){
	WPTR(ImmuSet) OF1(XnRegion) 	returnValue;
	returnValue = myExampleRegions;
	return returnValue;
}
/* protected: creation */


SnarfTester::SnarfTester (char * name, TCSJ) 
	: Tester(name, tcsj) {
	myExampleRegions = NULL;
}



/* ************************************************************************ *
 * 
 *                    Class UrdiTester 
 *
 * ************************************************************************ */


/* running tests */


void UrdiTester::allTestsOn (ostream& aStream){
	/* UrdiTester runTest: #allTestsOn: */
	/* UrdiTester allTestsOn: cerr */
	
	aStream << "\nRunning all Urdi tests.\nTest 1\n";
	UrdiTester::test1On(aStream);
}
/* testing */


void UrdiTester::tapeTest1On (ostream& aStream){
	/* self runTest: #tapeTest1On: */
	/* Time millisecondsToRun: [self tapeTest1On: cerr]  */
	
	SPTR(UNKNOWN) tIOAccessor;
	SPTR(UNKNOWN) tString;
	SPTR(UNKNOWN) tByteArray;
	
	/* tCharStringPtr */
	/* r/w */
		/* create if not exist */
	tIOAccessor = 
			IOAccessor::openFileNamedDirectionCreation("smalltalk:sd0d", 2, 1);
	/* CASCADE */
	aStream << "tIOAccessor = ";
	aStream << tIOAccessor;
	aStream << "\n";
	tString = "12345";
	/* (tCharStringPtr _ CharPtr newZeroed: 512) putAll: tString. */
	(tByteArray = ByteArray::new(512))->replaceBytesFromToStartingAt(1, tString->size(), tString, 1);
	/* CASCADE */
	aStream << "tIOAccessor fileSize = ";
	aStream << tIOAccessor->fileSize();
	aStream << "\n";
	/* tIOAccessor seekTo: (512 * 3). */
	/* CASCADE */
	aStream << "wrote: ";
	aStream << tIOAccessor->writeAll(tByteArray);
	aStream << "\n";
	/* CASCADE */
	aStream << "tIOAccessor fileSize = ";
	aStream << tIOAccessor->fileSize();
	aStream << "\n";
	tIOAccessor->commit();
	/* CASCADE */
	aStream << "tIOAccessor fileSize = ";
	aStream << tIOAccessor->fileSize();
	aStream << "\n";
	tIOAccessor->close();
	/* CASCADE */
	aStream << "tIOAccessor = ";
	aStream << tIOAccessor;
	aStream << "\n";
}


void UrdiTester::tapeTest2On (ostream& aStream){
	/* self runTest: #tapeTest2On: */
	
	SPTR(UNKNOWN) tIOAccessor;
	SPTR(UNKNOWN) tUInt1Ptr;
	
	/* r/w */
		/* create if not exist */
	tIOAccessor = 
			IOAccessor::openFileNamedDirectionCreation("smalltalk:sd0d", 2, 1);
	tUInt1Ptr = UInt1Ptr::newZeroed(512);
	*tUInt1Ptr = 1;
	tIOAccessor->writeAll(tUInt1Ptr->underlyingArray());
	*tUInt1Ptr = 2;
	tIOAccessor->writeAll(tUInt1Ptr->underlyingArray());
	*tUInt1Ptr = 3;
	tIOAccessor->writeAll(tUInt1Ptr->underlyingArray());
	tIOAccessor->seekTo(512);
	*tUInt1Ptr = 4;
	tIOAccessor->writeAll(tUInt1Ptr->underlyingArray());
	tIOAccessor->commit();
	tIOAccessor->close();
}
/* running tests */


void UrdiTester::allTestsOn (ostream& aStream){
	/* UrdiTester runTest: #allTestsOn: */
	/* UrdiTester allTestsOn: cerr */
	
	aStream << "\nRunning all Urdi tests.\nTest 1\n";
	this->test1On(aStream);
}
/* testing */


void UrdiTester::tapeTest1On (ostream& aStream){
	/* self runTest: #tapeTest1On: */
	/* Time millisecondsToRun: [self tapeTest1On: cerr]  */
	
	SPTR(UNKNOWN) tIOAccessor;
	SPTR(UNKNOWN) tString;
	SPTR(UNKNOWN) tByteArray;
	
	/* tCharStringPtr */
	/* r/w */
		/* create if not exist */
	tIOAccessor = 
			IOAccessor::openFileNamedDirectionCreation("smalltalk:sd0d", 2, 1);
	/* CASCADE */
	aStream << "tIOAccessor = ";
	aStream << tIOAccessor;
	aStream << "\n";
	tString = "12345";
	/* (tCharStringPtr _ CharPtr newZeroed: 512) putAll: tString. */
	(tByteArray = ByteArray::new(512))->replaceBytesFromToStartingAt(1, tString->size(), tString, 1);
	/* CASCADE */
	aStream << "tIOAccessor fileSize = ";
	aStream << tIOAccessor->fileSize();
	aStream << "\n";
	/* tIOAccessor seekTo: (512 * 3). */
	/* CASCADE */
	aStream << "wrote: ";
	aStream << tIOAccessor->writeAll(tByteArray);
	aStream << "\n";
	/* CASCADE */
	aStream << "tIOAccessor fileSize = ";
	aStream << tIOAccessor->fileSize();
	aStream << "\n";
	tIOAccessor->commit();
	/* CASCADE */
	aStream << "tIOAccessor fileSize = ";
	aStream << tIOAccessor->fileSize();
	aStream << "\n";
	tIOAccessor->close();
	/* CASCADE */
	aStream << "tIOAccessor = ";
	aStream << tIOAccessor;
	aStream << "\n";
}


void UrdiTester::tapeTest2On (ostream& aStream){
	/* self runTest: #tapeTest2On: */
	
	SPTR(UNKNOWN) tIOAccessor;
	SPTR(UNKNOWN) tUInt1Ptr;
	
	/* r/w */
		/* create if not exist */
	tIOAccessor = 
			IOAccessor::openFileNamedDirectionCreation("smalltalk:sd0d", 2, 1);
	tUInt1Ptr = UInt1Ptr::newZeroed(512);
	*tUInt1Ptr = 1;
	tIOAccessor->writeAll(tUInt1Ptr->underlyingArray());
	*tUInt1Ptr = 2;
	tIOAccessor->writeAll(tUInt1Ptr->underlyingArray());
	*tUInt1Ptr = 3;
	tIOAccessor->writeAll(tUInt1Ptr->underlyingArray());
	tIOAccessor->seekTo(512);
	*tUInt1Ptr = 4;
	tIOAccessor->writeAll(tUInt1Ptr->underlyingArray());
	tIOAccessor->commit();
	tIOAccessor->close();
}

	/* automatic 0-argument constructor */
UrdiTester::UrdiTester() {}

#ifndef URDIT_SXX
#include "urdit.sxx"
#endif /* URDIT_SXX */



#endif /* URDIT_CXX */

