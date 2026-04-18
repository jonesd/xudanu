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

#ifndef HLOGGERT_HXX
#define HLOGGERT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef HLOGGERT_OXX
#include "hloggert.oxx"
#endif /* HLOGGERT_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef TESTERX_HXX
#include "testerx.hxx"
#endif /* TESTERX_HXX */


#ifndef LOGGERX_OXX
#include "loggerx.oxx"
#endif /* LOGGERX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class LogTester 
 *
 * ************************************************************************ */



/* Initializers for LogTester */
LOGGER(FooLog);	/* in LogTester */




	/* NO CLASS COMMENT */

class LogTester : public Tester {

/* Attributes for class LogTester */
	CONCRETE(LogTester)
	COPY(LogTester,BootCuisine)
	NO_GC(LogTester)

/* Initializers for LogTester */


  public: /* testing */

	
	virtual void allTestsOn (ostream& ARG(oo));
	

	/* automatic 0-argument constructor */
  public:
	LogTester();

};  /* end class LogTester */



#endif /* HLOGGERT_HXX */

