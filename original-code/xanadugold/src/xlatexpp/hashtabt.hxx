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

#ifndef HASHTABT_HXX
#define HASHTABT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef HASHTABX_HXX
#include "hashtabx.hxx"
#endif /* HASHTABX_HXX */

#ifndef HASHTABT_OXX
#include "hashtabt.oxx"
#endif /* HASHTABT_OXX */


#ifndef TESTERX_HXX
#include "testerx.hxx"
#endif /* TESTERX_HXX */


/*  */
/*  */

#include <stream.h>



/* ************************************************************************ *
 * 
 *                    Class HashTableTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HashTableTester : public Tester {

/* Attributes for class HashTableTester */
	CONCRETE(HashTableTester)
	COPY(HashTableTester,BootCuisine)
	NO_GC(HashTableTester)
  public: /* tests */

	/* self runTest: #test1On: */
	/* test creation */
	
	virtual void test1On (ostream& ARG(oo));
	
	/* self runTest: #test2On: */
	/* test creation */
	
	virtual void test2On (ostream& ARG(aStream));
	
	/* self runTest: #test3On: */
	/* test creation */
	
	virtual void test3On (ostream& ARG(aStream));
	
	/* self runTest: #test4On: */
	/* test creation */
	
	virtual void test4On (ostream& ARG(aStream));
	
	/* self runTest: #test5On: */
	/* test creation */
	
	virtual void test5On (ostream& ARG(aStream));
	
	/* self runTest: #test6On: */
	/* test creation */
	
	virtual void test6On (ostream& ARG(aStream));
	
	/* self runTest: #test7On: */
	/* runs {Iterator} */
	/* test creation */
	
	virtual void test7On (ostream& ARG(aStream));
	
	/* self runTest: #testStepperCopyOn: */
	
	virtual void testStepperCopyOn (ostream& ARG(aStream));
	
  public: /* running tests */

	/* self runTest: #allTestsOn: */
	
	virtual void allTestsOn (ostream& ARG(aStream));
	

	/* automatic 0-argument constructor */
  public:
	HashTableTester();

};  /* end class HashTableTester */



#endif /* HASHTABT_HXX */

