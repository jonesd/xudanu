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

#ifndef COOKBKP_HXX
#define COOKBKP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef COOKBKX_HXX
#include "cookbkx.hxx"
#endif /* COOKBKX_HXX */

#ifndef COOKBKP_OXX
#include "cookbkp.oxx"
#endif /* COOKBKP_OXX */


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
 *                    Class ActualCookbook 
 *
 * ************************************************************************ */



/* Initializers for ActualCookbook */





/* global: utility */


Int32  addCuisineTo (APTR(Recipe) ARG(cuisine), APTR(PtrArray) ARG(recipes));



	/* We internally map from Category to preorder number for the 
	category and lookup using that preorder number. */

class ActualCookbook : public Cookbook {

/* Attributes for class ActualCookbook */
	CONCRETE(ActualCookbook)
	NOT_A_TYPE(ActualCookbook)
	AUTO_GC(ActualCookbook)

/* Initializers for ActualCookbook */



friend class INIT_TIME_NAME(ActualCookbook,initTimeNonInherited);

  public: /* creation */

	
	static RPTR(Cookbook) make (APTR(Category) ARG(bootCat));
	
	
	static RPTR(Cookbook) make (char * ARG(id));
	
  public: /* accessing */

	
	virtual RPTR(Category) bootCategory ();
	
	
	virtual RPTR(Recipe) fetchRecipe (APTR(Category) ARG(cat));
	
	
	virtual RPTR(Category) getCategoryFor (IntegerVar ARG(no));
	
	
	virtual RPTR(Recipe) getRecipe (APTR(Category) ARG(cat));
	
	
	virtual char * id ();
	
	
	virtual RPTR(Cookbook) next ();
	
	
	virtual IntegerVar numberOfCategory (APTR(Category) ARG(cat));
	
	
	virtual RPTR(PtrArray) recipes ();
	
  public: /* creation */

	
	ActualCookbook (
			APTR(Category) ARG(cat), 
			char * ARG(id), 
			APTR(PtrArray) OF1(Recipe) ARG(recipes), 
			Int32 ARG(count))
	;
	
	/* ActualCookbooks last for the whole run. */
	
	virtual void destroy ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	char * myName;
	CHKPTR(Category) myBootCategory;
	CHKPTR(Cookbook) myNext;
	CHKPTR(PtrArray) OF1(Recipe) myRecipes;
	CHKPTR(PtrArray) OF1(Category) myDecoding;
	CHKPTR(UInt32Array) myEncoding;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(Cookbook) TheCookbooks;
	friend class Cookbook;
};  /* end class ActualCookbook */



#endif /* COOKBKP_HXX */

