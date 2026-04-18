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

#ifndef TESTERX_CXX
#define TESTERX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef TESTERX_HXX
#include "testerx.hxx"
#endif /* TESTERX_HXX */

#ifndef TESTERX_IXX
#include "testerx.ixx"
#endif /* TESTERX_IXX */




/* ************************************************************************ *
 * 
 *                    Class Tester 
 *
 * ************************************************************************ */


/* accessing */


RPTR(Tester) Tester::fetchTester (char * tName){
	/* Returns the tester whose name is 'tName'.  NULL if none. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	/* Testers stepper forEach: [:tester {Tester} |
			(tester match: tName)
				ifTrue: [^tester]].
		^NULL */
	return NULL;
}


RPTR(Tester) Tester::getTester (char * tName){
	/* Returns the tester whose name is 'tName'.  BLASTs if none. */
	
	SPTR(Tester) result;
	
	result = Tester::fetchTester(tName);
	if (result == NULL) {
		BLAST(NotFound);
	}
	WPTR(Tester) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* Testers are for controlling the running of regression tests.  
See "Regression Testing Procedures and Recommendations". */


/* testing */
/* running */


void Tester::execute (){
	/* The receiver reacts to the key and value (tested my 
	matches:with:), execute it. */
	
	this->allTestsOn(cerr);
	
	/* [| str {Stream of: char} time {IntegerVar} |
			str _ WriteStream on: (String new: 200).
			time _ Time millisecondsToRun: [self allTestsOn: str].
			Transcript cr; nextPutAll: str contents.
			Transcript << 'Run Time = ' ; << time; show: ' ms
		'.	]  smalltalkOnly */
	
}
/* creation */


Tester::Tester () {
	
}

#ifndef TESTERX_SXX
#include "testerx.sxx"
#endif /* TESTERX_SXX */



#endif /* TESTERX_CXX */

