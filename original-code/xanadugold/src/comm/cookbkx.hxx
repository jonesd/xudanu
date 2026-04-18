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

#ifndef COOKBKX_HXX
#define COOKBKX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef COOKBKX_OXX
#include "cookbkx.oxx"
#endif /* COOKBKX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef RECIPEX_OXX
#include "recipex.oxx"
#endif /* RECIPEX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class Cookbook 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class Cookbook : public Heaper {

/* Attributes for class Cookbook */
	DEFERRED(Cookbook)
	EQ(Cookbook)
	NO_GC(Cookbook)
  public: /* declaring */

	/* Create and register a cookbook.  The cookbook can be 
	looked up according to etiher its name or bootCategory. */
	
	static RPTR(Cookbook) declareCookbook (
			char * ARG(id), 
			APTR(Category) ARG(bootCat), 
			APTR(Recipe) ARG(cuisine))
	;
	
	/* Create and register a cookbook.  The cookbook can be 
	looked up according to etiher its name or bootCategory. */
	
	static RPTR(Cookbook) declareCookbook (
			char * ARG(id), 
			APTR(Category) ARG(bootCat), 
			APTR(Recipe) ARG(cuisine1), 
			APTR(Recipe) ARG(cuisine2))
	;
	
	/* Create and register a cookbook.  The cookbook can be 
	looked up according to etiher its name or bootCategory. */
	
	static RPTR(Cookbook) declareCookbook (
			char * ARG(id), 
			APTR(Category) ARG(bootCat), 
			APTR(Recipe) ARG(cuisine1), 
			APTR(Recipe) ARG(cuisine2), 
			APTR(Recipe) ARG(cuisine3))
	;
	
	/* Create and register a cookbook.  The cookbook can be 
	looked up according to etiher its name or bootCategory. */
	
	static RPTR(Cookbook) declareCookbook (
			char * ARG(id), 
			APTR(Category) ARG(bootCat), 
			APTR(Recipe) ARG(cuisine1), 
			APTR(Recipe) ARG(cuisine2), 
			APTR(Recipe) ARG(cuisine3), 
			APTR(Recipe) ARG(cuisine4))
	;
	
  public: /* creation */

	/* Just return the empty cookbook. */
	
	static RPTR(Cookbook) make ();
	
	/* Return the cookbook registered for the given bootCategory. */
	
	static RPTR(Cookbook) make (APTR(Category) ARG(bootCat));
	
	/* Return the cookbook registered for the given string. */
	
	static RPTR(Cookbook) make (char * ARG(id));
	
  public: /* accessing */

	
	virtual RPTR(Category) bootCategory () DEFERRED_FUNC;
	
	
	virtual RPTR(Recipe) fetchRecipe (APTR(Category) ARG(cat)) DEFERRED_FUNC;
	
	
	virtual RPTR(Category) getCategoryFor (IntegerVar ARG(no)) DEFERRED_FUNC;
	
	
	virtual RPTR(Recipe) getRecipe (APTR(Category) ARG(cat)) DEFERRED_FUNC;
	
	/* return a string that uniquely determines the version of 
	the cookbook. It 
		should change whenever classes are added or removed, or when 
	their storage 
		or transmission protocol changes */
	
	virtual char * id () DEFERRED_FUNC;
	
	
	virtual RPTR(Cookbook) next () DEFERRED_FUNC;
	
	
	virtual IntegerVar numberOfCategory (APTR(Category) ARG(cat)) DEFERRED_FUNC;
	
	
	virtual RPTR(PtrArray) recipes () DEFERRED_FUNC;
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo)) DEFERRED_SUBR;
	

	/* automatic 0-argument constructor */
  public:
	Cookbook();

};  /* end class Cookbook */



#endif /* COOKBKX_HXX */

