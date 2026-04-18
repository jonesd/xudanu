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

#ifndef TESTERT_CXX
#define TESTERT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef TESTERT_HXX
#include "testert.hxx"
#endif /* TESTERT_HXX */

#ifndef TESTERT_IXX
#include "testert.ixx"
#endif /* TESTERT_IXX */




/* ************************************************************************ *
 * 
 *                    Class HelloTester 
 *
 * ************************************************************************ */


/* testing */

#ifndef BAR
#ifdef FOO

IntegerVar HelloTester::ifdefTest (){
	return IntegerVar0;
}
#endif /* BAR */
#endif /* FOO */


void HelloTester::test1On (ostream& aStream){
	/* self tryTest: #test1On: */
	
	aStream << "Hello, translated world!\n";
}
/* running tests */


void HelloTester::allTestsOn (ostream& aStream){
	/* HelloTester runTest */
	
	aStream << " \nRunning Hello, world! test.\n";
	this->test1On(aStream);
}

	/* automatic 0-argument constructor */
HelloTester::HelloTester() {}

#ifndef TESTERT_SXX
#include "testert.sxx"
#endif /* TESTERT_SXX */



#endif /* TESTERT_CXX */

