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

#ifndef TOKENSX_CXX
#define TOKENSX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef TOKENSX_HXX
#include "tokensx.hxx"
#endif /* TOKENSX_HXX */

#ifndef TOKENSX_IXX
#include "tokensx.ixx"
#endif /* TOKENSX_IXX */




/* ************************************************************************ *
 * 
 *                    Class TokenSource 
 *
 * ************************************************************************ */


/* creation */


RPTR(TokenSource) TokenSource::make (){
	RETURN_CONSTRUCT(TokenSource,());
}
/* Manage a set of integerVars as tokens.  The Available array is 
tokens that have been returned to the pool.  They get used in 
preference to allocating new ones so that we keep the numbers dense. */


/* accessing */


void TokenSource::returnToken (Int32 token){
	if (token == myCeiling) {
		myCeiling -= 1;
		return;
		
	}
	if (myAvailableCount >= myAvailable->count()) {
		myAvailable = CAST(Int32Array,myAvailable->copyGrow(myAvailableCount + 1));
	}
	myAvailable->storeInt(myAvailableCount, token);
	myAvailableCount += 1;
}


Int32 TokenSource::takeToken (){
	Int32 tmp;
	
	if (myAvailableCount > Int32Zero) {
		myAvailableCount -= 1;
		tmp = myAvailable->intAt(myAvailableCount);
	} else {
		myCeiling += 1;
		tmp = myCeiling;
	}
	
	return tmp;
}
/* creation */


TokenSource::TokenSource () {
	myAvailable = Int32Array::make (10);
	myAvailableCount = Int32Zero;
	myCeiling = Int32Zero;
}

#ifndef TOKENSX_SXX
#include "tokensx.sxx"
#endif /* TOKENSX_SXX */



#endif /* TOKENSX_CXX */

