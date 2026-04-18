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

#ifndef TESTERT_HXX
#define TESTERT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef TESTERX_HXX
#include "testerx.hxx"
#endif /* TESTERX_HXX */

#ifndef TESTERT_OXX
#include "testert.oxx"
#endif /* TESTERT_OXX */


/*  */
/*  */
#include <string.h>
#include <stream.h>



/* ************************************************************************ *
 * 
 *                    Class HelloTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HelloTester : public Tester {

/* Attributes for class HelloTester */
	CONCRETE(HelloTester)
	COPY(HelloTester,BootCuisine)
	NO_GC(HelloTester)
  public: /* testing */

#ifndef BAR
#ifdef FOO
	
	virtual IntegerVar ifdefTest ();
#endif /* BAR */
#endif /* FOO */
	
	/* self tryTest: #test1On: */
	
	virtual void test1On (ostream& ARG(aStream));
	
  public: /* running tests */

	/* HelloTester runTest */
	
	virtual void allTestsOn (ostream& ARG(aStream));
	

	/* automatic 0-argument constructor */
  public:
	HelloTester();

};  /* end class HelloTester */



#endif /* TESTERT_HXX */

