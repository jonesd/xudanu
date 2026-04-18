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

#ifndef PROMANT_CXX
#define PROMANT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef PROMANT_HXX
#include "promant.hxx"
#endif /* PROMANT_HXX */

#ifndef PROMANT_IXX
#include "promant.ixx"
#endif /* PROMANT_IXX */


#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef PROMANP_HXX
#include "promanp.hxx"
#endif /* PROMANP_HXX */

#ifndef PROMANR_HXX
#include "promanr.hxx"
#endif /* PROMANR_HXX */




/* ************************************************************************ *
 * 
 *                    Class ShuffleTester 
 *
 * ************************************************************************ */


/* test the ByteShufflers  */


/* testing */


void ShuffleTester::test1On (ostream& aStream){
	/* self tryTest: #test1On: */
	
	SPTR(UInt8Array) simpleString;
	SPTR(ByteShuffler) shuffler;
	SPTR(UInt8Array) copy;
	
	CONSTRUCT(shuffler,SimpleShuffler,());
	simpleString = UInt8Array::string("abcdefghijkl");
	copy = CAST(UInt8Array,simpleString->copy());
	shuffler->shuffle(16, copy->gutsOf(), 6);
	copy->noMoreGuts();
	aStream << "\nShuffling 16: " << simpleString << " to: " << copy << "\n";
	copy = CAST(UInt8Array,simpleString->copy());
	shuffler->shuffle(32, copy->gutsOf(), 3);
	copy->noMoreGuts();
	aStream << "Shuffling 32: " << simpleString << " to: " << copy << "\n";
	simpleString = UInt8Array::string("");
	copy = CAST(UInt8Array,simpleString->copy());
	shuffler->shuffle(16, copy->gutsOf(), Int32Zero);
	copy->noMoreGuts();
	aStream << "Shuffling an empty string 16: " << copy << "\n";
	copy = CAST(UInt8Array,simpleString->copy());
	shuffler->shuffle(32, copy->gutsOf(), Int32Zero);
	copy->noMoreGuts();
	aStream << "Shuffling an empty string 32: " << copy << "\n";
	copy = UInt8Array::string("ab");
	shuffler->shuffle(16, copy->gutsOf(), 1);
	copy->noMoreGuts();
	aStream << "Shuffling a tiny string 16: " << copy << "\n";
	simpleString = UInt8Array::string("abcd");
	copy = CAST(UInt8Array,simpleString->copy());
	shuffler->shuffle(32, copy->gutsOf(), 1);
	copy->noMoreGuts();
	aStream << "Shuffling a tiny string 32: " << copy << "\n";
	copy = CAST(UInt8Array,simpleString->copy());
	shuffler->shuffle(16, copy->gutsOf(), 2);
	copy->noMoreGuts();
	aStream << "Shuffling a small string 16: " << copy << "\n";
	copy = UInt8Array::string("abcdef");
	shuffler->shuffle(16, copy->gutsOf(), 3);
	copy->noMoreGuts();
	aStream << "Shuffling a small string 16: " << copy << "\n";
}
/* running tests */


void ShuffleTester::allTestsOn (ostream& aStream){
	/* ShuffleTester runTest */
	
	aStream << "testing shuffler\n";
	this->test1On(aStream);
}

	/* automatic 0-argument constructor */
ShuffleTester::ShuffleTester() {}

#ifndef PROMANT_SXX
#include "promant.sxx"
#endif /* PROMANT_SXX */



#endif /* PROMANT_CXX */

