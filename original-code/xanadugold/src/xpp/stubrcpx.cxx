/* Copyright Xanadu Operating Company.  All Rights Reserved.

	$Id: stubrcpx.cxx,v 2.4 1992/11/25 23:27:00 eric Exp $

******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
******************************************************************************
*/

#ifndef STUBRCPX_HXX
#include "stubrcpx.hxx"
#endif /* STUBRCPX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

/* ************************************************************************ *
 * 
 *                    Class ActualStubRecipe 
 *
 * ************************************************************************ */

/* making */

RPTR(Heaper) ActualStubRecipe::parseStub (APTR(Rcvr) rcvr, UInt32 hash) {
    return (*myMaker)(rcvr, hash);
}

/* creation */

ActualStubRecipe::
ActualStubRecipe (APTR(Category) cat, Recipe* * cuisine, 
		   SPTR(Heaper) (*maker)(APTR(Rcvr) rcvr, UInt32 hash))
	: StubRecipe(cat, cuisine) {
	myMaker = maker;
	
}

#ifndef STUBRCPX_SXX
#include "stubrcpx.sxx"
#endif /* STUBRCPX_SXX */
