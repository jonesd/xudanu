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

#ifndef TURTLEP_HXX
#define TURTLEP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef TURTLEX_HXX
#include "turtlex.hxx"
#endif /* TURTLEX_HXX */

#ifndef TURTLEP_OXX
#include "turtlep.oxx"
#endif /* TURTLEP_OXX */


#ifndef COOKBKX_OXX
#include "cookbkx.oxx"
#endif /* COOKBKX_OXX */

#ifndef COUNTERX_OXX
#include "counterx.oxx"
#endif /* COUNTERX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef XFRSPECX_OXX
#include "xfrspecx.oxx"
#endif /* XFRSPECX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class SimpleTurtle 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class SimpleTurtle : public Turtle {

/* Attributes for class SimpleTurtle */
	CONCRETE(SimpleTurtle)
	LOCKED(SimpleTurtle)
	COPY(SimpleTurtle,DiskCuisine)
	AUTO_GC(SimpleTurtle)
  public: /* pseudo-constructors */

	
	static RPTR(SimpleTurtle) make (
			APTR(Cookbook) ARG(cookbook), 
			APTR(Category) ARG(bootCategory), 
			APTR(XcvrMaker) ARG(maker))
	;
	
  public: /* accessing */

	
	virtual NOLOCK RPTR(Category) bootCategory ();
	
	
	virtual NOLOCK RPTR(Heaper) bootHeaper ();
	
	
	virtual NOLOCK RPTR(Cookbook) cookbook ();
	
	
	virtual NOLOCK RPTR(Counter) counter ();
	
	
	virtual NOLOCK RPTR(Agenda) OR(NULL) fetchAgenda ();
	
	
	virtual NOLOCK RPTR(XcvrMaker) protocol ();
	
	
	virtual void saveBootHeaper (APTR(Heaper) ARG(boot));
	
	
	virtual NOLOCK void setProtocol (APTR(XcvrMaker) ARG(xcvrMaker), APTR(Cookbook) ARG(book));
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK void restartSimpleTurtle (APTR(Rcvr) ARG(rcvr) = NULL);
	
  protected: /* protected: creation */

	
	SimpleTurtle (
			APTR(Cookbook) ARG(cookbook), 
			APTR(Category) ARG(bootCategory), 
			APTR(XcvrMaker) ARG(maker))
	;
	
  private:
	CHKPTR(Counter) myCounter;
	CHKPTR(Heaper) myBootHeaper;
	NOCOPY CHKPTR(XcvrMaker) myProtocol;
	NOCOPY CHKPTR(Cookbook) myCookbook;
	CHKPTR(Category) myBootCategory;
	CHKPTR(Agenda) OR(NULL) myAgenda;
};  /* end class SimpleTurtle */



#endif /* TURTLEP_HXX */

