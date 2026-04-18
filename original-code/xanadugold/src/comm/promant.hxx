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

#ifndef PROMANT_HXX
#define PROMANT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PROMANX_HXX
#include "promanx.hxx"
#endif /* PROMANX_HXX */

#ifndef PROMANT_OXX
#include "promant.oxx"
#endif /* PROMANT_OXX */


#ifndef TESTERX_HXX
#include "testerx.hxx"
#endif /* TESTERX_HXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class ShuffleTester 
 *
 * ************************************************************************ */




	/* test the ByteShufflers  */

class ShuffleTester : public Tester {

/* Attributes for class ShuffleTester */
	CONCRETE(ShuffleTester)
	COPY(ShuffleTester,BootCuisine)
	NO_GC(ShuffleTester)
  public: /* testing */

	/* self tryTest: #test1On: */
	
	virtual void test1On (ostream& ARG(aStream));
	
  public: /* running tests */

	/* ShuffleTester runTest */
	
	virtual void allTestsOn (ostream& ARG(aStream));
	

	/* automatic 0-argument constructor */
  public:
	ShuffleTester();

};  /* end class ShuffleTester */



#endif /* PROMANT_HXX */

