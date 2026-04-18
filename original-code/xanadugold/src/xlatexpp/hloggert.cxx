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

#ifndef HLOGGERT_CXX
#define HLOGGERT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef HLOGGERT_HXX
#include "hloggert.hxx"
#endif /* HLOGGERT_HXX */

#ifndef HLOGGERT_IXX
#include "hloggert.ixx"
#endif /* HLOGGERT_IXX */


#ifndef LOGGERX_HXX
#include "loggerx.hxx"
#endif /* LOGGERX_HXX */




/* ************************************************************************ *
 * 
 *                    Class LogTester 
 *
 * ************************************************************************ */



/* Initializers for LogTester */

DEFINE_LOGGER(FooLog,NULL);	/* in LogTester */


/* Initializers for LogTester */



/* testing */


void LogTester::allTestsOn (ostream& oo){
	FooLog << "foo " << this << "\n";
	VanillaLog << "bar " << this << "\n";
	ErrorLog << "err " << this << "\n";
	LOG(FooLog,ooo) {
		ooo << "zip " << this << "\n";
	} END_LOG;
	LOG(VanillaLog,ooo) {
		ooo << "zap " << this << "\n";
	} END_LOG;
	LOG(ErrorLog,ooo) {
		ooo << "human " << this << "\n";
	} END_LOG;
}

	/* automatic 0-argument constructor */
LogTester::LogTester() {}

#ifndef HLOGGERT_SXX
#include "hloggert.sxx"
#endif /* HLOGGERT_SXX */



#endif /* HLOGGERT_CXX */

