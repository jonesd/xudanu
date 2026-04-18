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

#ifndef SETTABT_HXX
#define SETTABT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SETTABX_HXX
#include "settabx.hxx"
#endif /* SETTABX_HXX */

#ifndef SETTABT_OXX
#include "settabt.oxx"
#endif /* SETTABT_OXX */


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
 *                    Class SetTableTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class SetTableTester : public Tester {

/* Attributes for class SetTableTester */
	CONCRETE(SetTableTester)
	COPY(SetTableTester,BootCuisine)
	NOT_A_TYPE(SetTableTester)
	NO_GC(SetTableTester)
  public: /* tests */

	
	virtual void allTestsOn (ostream& ARG(oo));
	
	
	virtual void growTest2On (ostream& ARG(oo));
	
	
	virtual void growTestOn (ostream& ARG(oo));
	
	
	virtual void simpleAccess (ostream& ARG(oo));
	
	
	virtual void stepTestOn (ostream& ARG(oo));
	
	
	virtual void test1on (ostream& ARG(oo));
	
  private: /* private: testing */

	
	virtual IntegerVar lastTestValue ();
	
	
	virtual IntegerVar manualCount (APTR(SetTable) ARG(table));
	
	
	virtual RPTR(CoordinateSpace) testCS ();
	
	
	virtual RPTR(ScruSet) OF1(Position) testKeys ();
	
	
	virtual RPTR(ScruSet) OF1(Heaper) testValues ();
	

	/* automatic 0-argument constructor */
  public:
	SetTableTester();

};  /* end class SetTableTester */



#endif /* SETTABT_HXX */

