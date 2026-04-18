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

#ifndef URDIT_HXX
#define URDIT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef URDIX_HXX
#include "urdix.hxx"
#endif /* URDIX_HXX */

#ifndef URDIT_OXX
#include "urdit.oxx"
#endif /* URDIT_OXX */


#ifndef TESTERX_HXX
#include "testerx.hxx"
#endif /* TESTERX_HXX */


#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class SnarfTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class SnarfTester : public Tester {

/* Attributes for class SnarfTester */
	CONCRETE(SnarfTester)
	COPY(SnarfTester,BootCuisine)
	NO_GC(SnarfTester)
  public: /* testing */

	/* SnarfTester runTest. */
	
	virtual void allTestsOn (ostream& ARG(oo));
	
	
	virtual void binaryCheck (APTR(XnRegion) ARG(a), APTR(XnRegion) ARG(b));
	
	/* packer _ snarfPacker create: UrdiVew create. */
	
	virtual void testAllocationsOn (ostream& ARG(oo));
	
	
	virtual void testBinaryRegionOpsOn (ostream& ARG(oo));
	
	
	virtual void testUnaryRegionOpsOn (ostream& ARG(oo));
	
	
	virtual void unaryCheck (APTR(XnRegion) ARG(a));
	
  protected: /* protected: accessing */

	
	virtual RPTR(ImmuSet) OF1(XnRegion) exampleRegions ();
	
  protected: /* protected: creation */

	
	SnarfTester (char * ARG(name), TCSJ);
	

};  /* end class SnarfTester */



/* ************************************************************************ *
 * 
 *                    Class UrdiTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class UrdiTester : public Tester {

/* Attributes for class UrdiTester */
	CONCRETE(UrdiTester)
	COPY(UrdiTester,BootCuisine)
	NO_GC(UrdiTester)
  public: /* running tests */

	/* UrdiTester runTest: #allTestsOn: */
	/* UrdiTester allTestsOn: cerr */
	
	static void allTestsOn (ostream& ARG(aStream));
	
  public: /* testing */

	/* self runTest: #tapeTest1On: */
	/* Time millisecondsToRun: [self tapeTest1On: cerr]  */
	
	static void tapeTest1On (ostream& ARG(aStream));
	
	/* self runTest: #tapeTest2On: */
	
	static void tapeTest2On (ostream& ARG(aStream));
	
  public: /* running tests */

	/* UrdiTester runTest: #allTestsOn: */
	/* UrdiTester allTestsOn: cerr */
	
	virtual void allTestsOn (ostream& ARG(aStream));
	
  public: /* testing */

	/* self runTest: #tapeTest1On: */
	/* Time millisecondsToRun: [self tapeTest1On: cerr]  */
	
	virtual void tapeTest1On (ostream& ARG(aStream));
	
	/* self runTest: #tapeTest2On: */
	
	virtual void tapeTest2On (ostream& ARG(aStream));
	

	/* automatic 0-argument constructor */
  public:
	UrdiTester();

};  /* end class UrdiTester */



#endif /* URDIT_HXX */

