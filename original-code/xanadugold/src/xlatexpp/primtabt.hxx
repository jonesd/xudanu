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

#ifndef PRIMTABT_HXX
#define PRIMTABT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PRIMTABX_HXX
#include "primtabx.hxx"
#endif /* PRIMTABX_HXX */

#ifndef PRIMTABT_OXX
#include "primtabt.oxx"
#endif /* PRIMTABT_OXX */


#ifndef TESTERX_HXX
#include "testerx.hxx"
#endif /* TESTERX_HXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class PrimIndexTableTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class PrimIndexTableTester : public Tester {

/* Attributes for class PrimIndexTableTester */
	CONCRETE(PrimIndexTableTester)
	COPY(PrimIndexTableTester,BootCuisine)
	NO_GC(PrimIndexTableTester)
  public: /* tests */

	
	virtual void accessTestOn (ostream& ARG(oo));
	
  public: /* testing */

	
	virtual void allTestsOn (ostream& ARG(oo));
	

	/* automatic 0-argument constructor */
  public:
	PrimIndexTableTester();

};  /* end class PrimIndexTableTester */



/* ************************************************************************ *
 * 
 *                    Class PrimPtrTableTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class PrimPtrTableTester : public Tester {

/* Attributes for class PrimPtrTableTester */
	CONCRETE(PrimPtrTableTester)
	COPY(PrimPtrTableTester,BootCuisine)
	NO_GC(PrimPtrTableTester)
  public: /* tests */

	
	virtual void accessTestOn (ostream& ARG(oo));
	
  public: /* testing */

	
	virtual void allTestsOn (ostream& ARG(oo));
	

	/* automatic 0-argument constructor */
  public:
	PrimPtrTableTester();

};  /* end class PrimPtrTableTester */



#endif /* PRIMTABT_HXX */

