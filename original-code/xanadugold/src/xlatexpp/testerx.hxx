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

#ifndef TESTERX_HXX
#define TESTERX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef TESTERX_OXX
#include "testerx.oxx"
#endif /* TESTERX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef THUNKX_HXX
#include "thunkx.hxx"
#endif /* THUNKX_HXX */


/*  */
/*  */
#include <string.h>



/* ************************************************************************ *
 * 
 *                    Class Tester 
 *
 * ************************************************************************ */




	/* Testers are for controlling the running of regression tests.  
	See "Regression Testing Procedures and Recommendations". */

class Tester : public Thunk {

/* Attributes for class Tester */
	DEFERRED(Tester)
	NO_GC(Tester)
  public: /* accessing */

	/* Returns the tester whose name is 'tName'.  NULL if none. */
	
	static RPTR(Tester) fetchTester (char * ARG(tName));
	
	/* Returns the tester whose name is 'tName'.  BLASTs if none. */
	
	static RPTR(Tester) getTester (char * ARG(tName));
	
  public: /* testing */

	/* A regression test is run by calling this method. What the 
	tester writes to 'oo' is 
		actually written to file *o.txt and compared against an 
	approved reference 
		file (*r.txt) of what this tester once used to output. If 
	they match exactly, 
		then the test is passed. Otherwise, someone needs to 
	manually understand why 
		they're different. The diff is in file *d.txt. 
		
		It is strongly recommended (in order to avoid regression 
	errors) that when a 
		tester is extended to test something new that its output 
	also be extended with 
		some result of the new test. The extended test will then 
	fail the first time. The 
		programmer should verify that the reason for failure is 
	exactly that the 
		tester now additionally outputs the correct results of the 
	new test, in which 
		case this output should be made into the new reference 
	output and the test run 
		again. */
	
	virtual void allTestsOn (ostream& ARG(oo)) DEFERRED_SUBR;
	
  public: /* running */

	/* The receiver reacts to the key and value (tested my 
	matches:with:), execute it. */
	
	virtual void execute ();
	
  public: /* creation */

	
	Tester ();
	

};  /* end class Tester */



#endif /* TESTERX_HXX */

