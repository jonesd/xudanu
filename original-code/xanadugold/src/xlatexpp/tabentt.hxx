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

#ifndef TABENTT_HXX
#define TABENTT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef TABENTX_HXX
#include "tabentx.hxx"
#endif /* TABENTX_HXX */

#ifndef TABENTT_OXX
#include "tabentt.oxx"
#endif /* TABENTT_OXX */


#ifndef TESTERX_HXX
#include "testerx.hxx"
#endif /* TESTERX_HXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class TableEntryTester 
 *
 * ************************************************************************ */




	/* test entries in isolation just for fun */

class TableEntryTester : public Tester {

/* Attributes for class TableEntryTester */
	CONCRETE(TableEntryTester)
	COPY(TableEntryTester,BootCuisine)
	NO_GC(TableEntryTester)
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
	
	virtual void allTestsOn (ostream& ARG(oo));
	
	
	virtual void test1on (ostream& ARG(oo));
	
	
	virtual void test2on (ostream& ARG(oo));
	
	
	virtual void test3on (ostream& ARG(oo));
	

	/* automatic 0-argument constructor */
  public:
	TableEntryTester();

};  /* end class TableEntryTester */



#endif /* TABENTT_HXX */

