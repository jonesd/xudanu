/* Copyright Xanadu Operating Company.  All Rights Reserved.
	14 August 1991 at 5:37:07 pm
******************************************************************************
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

/* $Id: copyrcpx.cxx,v 2.5 1993/02/15 23:53:01 eric Exp $ */

#ifndef COPYRCPX_HXX
#include "copyrcpx.hxx"
#endif /* COPYRCPX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */

#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


/* ************************************************************************ *
 * 
 *                    Class ActualCopyRecipe 
 *
 * ************************************************************************ */

/* creation */

ActualCopyRecipe::ActualCopyRecipe (APTR(Category) cat, Recipe* * cuisine, 
				    void (*maker)(APTR(Rcvr) rcvr, OUT void * storage))
	: CopyRecipe(cat, cuisine) {
	  
	  myMaker = maker;	
}

/* making */

void ActualCopyRecipe::parseInto (APTR(Rcvr) rcvr, void * memory){
	(*myMaker)(rcvr, memory);
}


/* ************************************************************************ *
 * 
 *                    Class PseudoCopyRecipe 
 *
 * ************************************************************************ */

/* creation */

PseudoCopyRecipe::PseudoCopyRecipe (APTR(Category) cat, Recipe* * cuisine, 
				    RPTR(Heaper) (*maker)(APTR(Rcvr) rcvr))
	: CopyRecipe(cat, cuisine) {
	  
	  myMaker = maker;	
}

/* making */

void PseudoCopyRecipe::parseInto (APTR(Rcvr), void *){
    BLAST(SHOULD_NOT_IMPLEMENT);
}

RPTR(Heaper) PseudoCopyRecipe::parse (APTR(SpecialistRcvr) rcvr){
    /* Register the result in the ibid table.  The most obvious
       alternative is to have all Heapers respond to isPseudoCopy
       so that the Xmtrs will not try to use ibids.  I think that
       the second choice is too messy. - ech 3-18-92 */

    SPTR(Heaper) result;
    result = (*myMaker)(rcvr);
    return result;
}

#ifndef COPYRCPX_SXX
#include "copyrcpx.sxx"
#endif /* COPYRCPX_SXX */
