/* Copyright Xanadu Operating Company.  All Rights Reserved.

	$Id: stubrcpx.hxx,v 2.4 1992/11/25 23:27:01 eric Exp $

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
#define STUBRCPX_HXX

#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef RECIPEX_HXX
#include "recipex.hxx"
#endif /* RECIPEX_HXX */

#ifndef STUBRCPX_OXX
#include "stubrcpx.oxx"
#endif /* STUBRCPX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */


/* ************************************************************************ *
 * 
 *                    Class ActualStubRecipe 
 *
 * ************************************************************************ */



/* Declarations for ActualStubRecipe */

class ActualStubRecipe : public StubRecipe {
    CONCRETE(ActualStubRecipe)
    NO_GC(ActualStubRecipe)

 public: /* accessing */

    virtual /*LEAF?*/ RPTR(Heaper) parseStub (APTR(Rcvr) rcvr, UInt32 hash);

 public: /* creation */

    /* cuisine points to the *variable* in which the receiver 
       should be registered. */

    ActualStubRecipe (APTR(Category) cat, Recipe* * cuisine, 
		      RPTR(Heaper) (*maker)(APTR(Rcvr) rcvr, UInt32 hash));

 private:
    RPTR(Heaper) (*myMaker)(APTR(Rcvr) rcvr, UInt32 hash);

};


#endif /* STUBRCPX_HXX */

