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


#ifndef COPYRCPX_HXX
#define COPYRCPX_HXX

#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

VERSION_ID(copyrcpx_hxx,
	   "$Id: copyrcpx.hxx,v 2.6 1992/12/19 00:53:05 ravi Exp $")

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef COPYRCPX_OXX
#include "copyrcpx.oxx"
#endif /* COPYRCPX_OXX */


#ifndef RECIPEX_HXX
#include "recipex.hxx"
#endif /* RECIPEX_HXX */


#ifndef XFRSPECX_OXX
#include "xfrspecx.oxx"
#endif /* XFRSPECX_OXX */


/* ************************************************************************ *
 * 
 *                    Class ActualCopyRecipe 
 *
 * ************************************************************************ */



/* Declarations for ActualCopyRecipe */

class ActualCopyRecipe : public CopyRecipe {

/* Attributes for class ActualCopyRecipe */
	CONCRETE(ActualCopyRecipe)
	NO_GC(ActualCopyRecipe)
  public: /* creation */

	/* cuisine points to the *variable* in which the receiver 
	should be registered. */
	
	ActualCopyRecipe (APTR(Category) cat, 
			  Recipe* * cuisine, 
			  void (*maker)(APTR(Rcvr) rcvr, OUT void * storage));

  public: /* accessing */
	
	virtual /*LEAF?*/ void parseInto (APTR(Rcvr) rcvr, void * memory);
	
  private:
	void (*myMaker)(APTR(Rcvr) rcvr, OUT void * storage);

};


/* ************************************************************************ *
 * 
 *                    Class PseudoCopyRecipe 
 *
 * ************************************************************************ */



/* Declarations for PseudoCopyRecipe */

class PseudoCopyRecipe : public CopyRecipe {

/* Attributes for class PseudoCopyRecipe */
	CONCRETE(PseudoCopyRecipe)
	NO_GC(PseudoCopyRecipe)
	NOT_A_TYPE(PseudoCopyRecipe)

  public: /* creation */

	/* cuisine points to the *variable* in which the receiver 
	should be registered. */
	
	PseudoCopyRecipe (APTR(Category) cat, 
			  Recipe* * cuisine, 
			  RPTR(Heaper) (*pseudoCtor)(APTR(Rcvr) rcvr));

  public: /* accessing */
	
	virtual /*LEAF?*/ RPTR(Heaper) parse (APTR(SpecialistRcvr) rcvr);// override
	
	virtual /*LEAF?*/ void parseInto (APTR(Rcvr) rcvr, void * memory);

  private:
	RPTR(Heaper) (*myMaker)(APTR(Rcvr) rcvr);

};


#endif /* COPYRCPX_HXX */

