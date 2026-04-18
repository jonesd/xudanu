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

#ifndef RECIPEX_HXX
#define RECIPEX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef RECIPEX_OXX
#include "recipex.oxx"
#endif /* RECIPEX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef COPYRCPX_OXX
#include "copyrcpx.oxx"
#endif /* COPYRCPX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef XFRSPECX_OXX
#include "xfrspecx.oxx"
#endif /* XFRSPECX_OXX */


/*  */
/*  */
#include "parrayx.oxx" // definition for friend function in Recipe



/* ************************************************************************ *
 * 
 *                    Class Recipe 
 *
 * ************************************************************************ */



/* Initializers for Recipe */
extern Recipe * XppCuisine;	/* in Recipe */







	/* The table of all recipes in the system is maintained in 
	the Cookbook module.  
	Subclasses know how to craete instances of a particular class. */

class Recipe : public Heaper {

/* Attributes for class Recipe */
	DEFERRED(Recipe)
	NO_GC(Recipe)

/* Initializers for Recipe */





  public: /* accessing */

	
	virtual RPTR(Category) categoryOfDish ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  private: /* private: accessing */

	/* Returnt the next recipe in the receiver's cuisine. */
	
	virtual RPTR(Recipe) next ();
	
  protected: /* protected: creation */

	/* cuisine points to the *variable* in which the receiver 
	should be registered. */
	
	Recipe (APTR(Category) ARG(cat), Recipe* * ARG(cuisine));
	
  private:
	CHKPTR(Category) myCat;
	CHKPTR(Recipe) myNext;
/* Friends for class Recipe */
friend class Cookbook;
friend Int4  addCuisineTo (APTR(Recipe) cuisine, APTR(PtrArray) recipes);


};  /* end class Recipe */



/* ************************************************************************ *
 * 
 *                    Class   CopyRecipe 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class CopyRecipe : public Recipe {

/* Attributes for class CopyRecipe */
	DEFERRED(CopyRecipe)
	NO_GC(CopyRecipe)
  public: /* accessing */

	/* create a new object from the information in the transceiver */
	
	virtual RPTR(Heaper) parse (APTR(SpecialistRcvr) ARG(rcvr));
	
	/* create a new object from the information in the rcvr and 
	give it the identity 
		of memory. The c++ version of this builds the first object 
	received into the 
		area of supplied memory. */
	
	virtual void parseInto (APTR(Rcvr) ARG(rcvr), void * ARG(memory)) DEFERRED_SUBR;
	
  protected: /* protected: creation */

	/* cuisine points to the *variable* in which the receiver 
	should be registered. */
	
	CopyRecipe (APTR(Category) ARG(cat), Recipe* * ARG(cuisine));
	

};  /* end class CopyRecipe */



/* ************************************************************************ *
 * 
 *                    Class   StubRecipe 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class StubRecipe : public Recipe {

/* Attributes for class StubRecipe */
	DEFERRED(StubRecipe)
	NO_GC(StubRecipe)
  public: /* accessing */

	
	virtual RPTR(Heaper) parseStub (APTR(Rcvr) ARG(rcvr), UInt32 ARG(hash)) DEFERRED_FUNC;
	
  protected: /* protected: creation */

	/* cuisine points to the *variable* in which the receiver 
	should be registered. */
	
	StubRecipe (APTR(Category) ARG(cat), Recipe* * ARG(cuisine));
	

};  /* end class StubRecipe */



#endif /* RECIPEX_HXX */

