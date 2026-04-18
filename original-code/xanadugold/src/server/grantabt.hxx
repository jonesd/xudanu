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

#ifndef GRANTABT_HXX
#define GRANTABT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef GRANTABX_HXX
#include "grantabx.hxx"
#endif /* GRANTABX_HXX */

#ifndef GRANTABT_OXX
#include "grantabt.oxx"
#endif /* GRANTABT_OXX */


#ifndef SETT_HXX
#include "sett.hxx"
#endif /* SETT_HXX */

#ifndef TESTERX_HXX
#include "testerx.hxx"
#endif /* TESTERX_HXX */


#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */


/* Presently the values called 'shift' in this module are used with
divide and modulo operations rather than bit operations.  Thus
the minimum shift for a hashed key is 1 and not 0. */
/*  */
#include <stream.h>



/* ************************************************************************ *
 * 
 *                    Class GrandHashSetTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class GrandHashSetTester : public MuSetTester {

/* Attributes for class GrandHashSetTester */
	CONCRETE(GrandHashSetTester)
	COPY(GrandHashSetTester,BootCuisine)
	NO_GC(GrandHashSetTester)
  public: /* testing */

	
	virtual void allTestsOn (ostream& ARG(oo));
	
  public: /* accessing */

	
	virtual RPTR(ScruSet) generateSet ();
	
	
	virtual RPTR(ScruSet) generateSetContaining (APTR(Stepper) ARG(stuff));
	

	/* automatic 0-argument constructor */
  public:
	GrandHashSetTester();

};  /* end class GrandHashSetTester */



/* ************************************************************************ *
 * 
 *                    Class GrandHashTableTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class GrandHashTableTester : public Tester {

/* Attributes for class GrandHashTableTester */
	CONCRETE(GrandHashTableTester)
	COPY(GrandHashTableTester,BootCuisine)
	NO_GC(GrandHashTableTester)
  public: /* tests */

	/* self runTest: #bigTableTestOn: */
	/* test growing */
	
	virtual void bigTableTestOn (ostream& ARG(aStream));
	
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
	
	/* self runTest: #test7On: */
	/* Not currently appropriate to GrandHashTable */
	/* runs {Iterator} */
	/* test creation */
	
	virtual void test7On (ostream& ARG(aStream));
	
  public: /* running tests */

	
	virtual void allTestsOn (ostream& ARG(aStream));
	

	/* automatic 0-argument constructor */
  public:
	GrandHashTableTester();

};  /* end class GrandHashTableTester */



#endif /* GRANTABT_HXX */

