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

#ifndef COOKBKX_CXX
#define COOKBKX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef COOKBKX_HXX
#include "cookbkx.hxx"
#endif /* COOKBKX_HXX */

#ifndef COOKBKX_IXX
#include "cookbkx.ixx"
#endif /* COOKBKX_IXX */

#ifndef COOKBKP_HXX
#include "cookbkp.hxx"
#endif /* COOKBKP_HXX */

#ifndef COOKBKP_IXX
#include "cookbkp.ixx"
#endif /* COOKBKP_IXX */


#ifndef RECIPEX_HXX
#include "recipex.hxx"
#endif /* RECIPEX_HXX */

#ifndef STRINGX_HXX
#include "stringx.hxx"
#endif /* STRINGX_HXX */

#ifndef WPARRAYX_HXX
#include "wparrayx.hxx"
#endif /* WPARRAYX_HXX */




/* ************************************************************************ *
 * 
 *                    Class Cookbook 
 *
 * ************************************************************************ */


/* declaring */


RPTR(Cookbook) Cookbook::declareCookbook (
		char * id, 
		APTR(Category) bootCat, 
		APTR(Recipe) cuisine)
{
	/* Create and register a cookbook.  The cookbook can be 
	looked up according to etiher its name or bootCategory. */
	
	SPTR(PtrArray) recipes;
	Int32 count;
	
	/* preorder -> recipe. */
	recipes = WeakPtrArray::make (XnExecutor::noopExecutor(), cat_Heaper->preorderMax() + 1);
	count = ::addCuisineTo(cuisine, recipes);
	RETURN_CONSTRUCT(ActualCookbook,(bootCat, id, recipes, count));
}


RPTR(Cookbook) Cookbook::declareCookbook (
		char * id, 
		APTR(Category) bootCat, 
		APTR(Recipe) cuisine1, 
		APTR(Recipe) cuisine2)
{
	/* Create and register a cookbook.  The cookbook can be 
	looked up according to etiher its name or bootCategory. */
	
	SPTR(PtrArray) recipes;
	Int32 count;
	
	/* preorder -> recipe. */
	recipes = WeakPtrArray::make (XnExecutor::noopExecutor(), cat_Heaper->preorderMax() + 1);
	count = ::addCuisineTo(cuisine1, recipes);
	count += ::addCuisineTo(cuisine2, recipes);
	RETURN_CONSTRUCT(ActualCookbook,(bootCat, id, recipes, count));
}


RPTR(Cookbook) Cookbook::declareCookbook (
		char * id, 
		APTR(Category) bootCat, 
		APTR(Recipe) cuisine1, 
		APTR(Recipe) cuisine2, 
		APTR(Recipe) cuisine3)
{
	/* Create and register a cookbook.  The cookbook can be 
	looked up according to etiher its name or bootCategory. */
	
	SPTR(PtrArray) recipes;
	Int32 count;
	
	/* preorder -> recipe. */
	recipes = WeakPtrArray::make (XnExecutor::noopExecutor(), cat_Heaper->preorderMax() + 1);
	count = ::addCuisineTo(cuisine1, recipes);
	count += ::addCuisineTo(cuisine2, recipes);
	count += ::addCuisineTo(cuisine3, recipes);
	RETURN_CONSTRUCT(ActualCookbook,(bootCat, id, recipes, count));
}


RPTR(Cookbook) Cookbook::declareCookbook (
		char * id, 
		APTR(Category) bootCat, 
		APTR(Recipe) cuisine1, 
		APTR(Recipe) cuisine2, 
		APTR(Recipe) cuisine3, 
		APTR(Recipe) cuisine4)
{
	/* Create and register a cookbook.  The cookbook can be 
	looked up according to etiher its name or bootCategory. */
	
	SPTR(PtrArray) recipes;
	Int32 count;
	
	/* preorder -> recipe. */
	recipes = WeakPtrArray::make (XnExecutor::noopExecutor(), cat_Heaper->preorderMax() + 1);
	count = ::addCuisineTo(cuisine1, recipes);
	count += ::addCuisineTo(cuisine2, recipes);
	count += ::addCuisineTo(cuisine3, recipes);
	count += ::addCuisineTo(cuisine4, recipes);
	RETURN_CONSTRUCT(ActualCookbook,(bootCat, id, recipes, count));
}
/* creation */


RPTR(Cookbook) Cookbook::make (){
	/* Just return the empty cookbook. */
	
	WPTR(Cookbook) 	returnValue;
	returnValue = ActualCookbook::make ("empty");
	return returnValue;
}


RPTR(Cookbook) Cookbook::make (APTR(Category) bootCat){
	/* Return the cookbook registered for the given bootCategory. */
	
	WPTR(Cookbook) 	returnValue;
	returnValue = ActualCookbook::make (bootCat);
	return returnValue;
}


RPTR(Cookbook) Cookbook::make (char * id){
	/* Return the cookbook registered for the given string. */
	
	WPTR(Cookbook) 	returnValue;
	returnValue = ActualCookbook::make (id);
	return returnValue;
}
/* accessing */
/* printing */

	/* automatic 0-argument constructor */
Cookbook::Cookbook() {}



/* ************************************************************************ *
 * 
 *                    Class ActualCookbook 
 *
 * ************************************************************************ */



/* Initializers for ActualCookbook */

GPTR(Cookbook) ActualCookbook::TheCookbooks = NULL;



BEGIN_INIT_TIME(ActualCookbook,initTimeNonInherited) {
	Cookbook::declareCookbook("empty", cat_Heaper, NULL);
} END_INIT_TIME(ActualCookbook,initTimeNonInherited);


/* global: utility */


Int32  addCuisineTo (APTR(Recipe) cuisine, APTR(PtrArray) recipes){
	SPTR(Recipe) recipe;
	Int32 count;
	
	count = Int32Zero;
	recipe = cuisine;
	while (recipe != NULL) {
		recipes->store(recipe->categoryOfDish()->preorderNumber(), recipe);
		count += 1;
		recipe = recipe->next();
	}
	return count;
}

/* Initializers for ActualCookbook */






/* creation */


RPTR(Cookbook) ActualCookbook::make (APTR(Category) bootCat){
	SPTR(Cookbook) cookbook;
	
	cookbook = ActualCookbook::TheCookbooks;
	while (cookbook != NULL) {
		if (cookbook->bootCategory()->isEqual(bootCat)) {
			WPTR(Cookbook) 	returnValue;
			returnValue = cookbook;
			return returnValue;
		}
		cookbook = cookbook->next();
	}
	BLAST(UnknownCookbook);
	/* fodder */
	return NULL;
}


RPTR(Cookbook) ActualCookbook::make (char * id){
	SPTR(Cookbook) cookbook;
	
	cookbook = ActualCookbook::TheCookbooks;
	while (cookbook != NULL) {
		if (::strcmp(cookbook->id(), id) == Int32Zero) {
			WPTR(Cookbook) 	returnValue;
			returnValue = cookbook;
			return returnValue;
		}
		cookbook = cookbook->next();
	}
	BLAST(UnknownCookbook);
	/* fodder */
	return NULL;
}
/* We internally map from Category to preorder number for the 
category and lookup using that preorder number. */


/* accessing */


RPTR(Category) ActualCookbook::bootCategory (){
	return (Category*) myBootCategory;
}


RPTR(Recipe) ActualCookbook::fetchRecipe (APTR(Category) cat){
	return CAST(Recipe,myRecipes->fetch(cat->preorderNumber()));
}


RPTR(Category) ActualCookbook::getCategoryFor (IntegerVar no){
	SPTR(Category) category;
	
	category = CAST(Category,myDecoding->fetch(no.asLong()));
	if (category == NULL) {
		BLAST(NotInTable);
	}
	WPTR(Category) 	returnValue;
	returnValue = category;
	return returnValue;
}


RPTR(Recipe) ActualCookbook::getRecipe (APTR(Category) cat){
	SPTR(Recipe) recipe;
	
	recipe = CAST(Recipe,myRecipes->fetch(cat->preorderNumber()));
	if (recipe == NULL) {
		BLAST(NotInTable);
	}
	WPTR(Recipe) 	returnValue;
	returnValue = recipe;
	return returnValue;
}


char * ActualCookbook::id (){
	return (char*) myName;
}


RPTR(Cookbook) ActualCookbook::next (){
	return (Cookbook*) myNext;
}


IntegerVar ActualCookbook::numberOfCategory (APTR(Category) cat){
	Int32 num;
	
	num = myEncoding->uIntAt(cat->preorderNumber());
	if (num >= myRecipes->count()) {
		BLAST(UnencodedCategory);
	}
	return num;
}


RPTR(PtrArray) ActualCookbook::recipes (){
	return (PtrArray*) myRecipes;
}
/* creation */


ActualCookbook::ActualCookbook (
		APTR(Category) cat, 
		char * id, 
		APTR(PtrArray) OF1(Recipe) recipes, 
		Int32 count) 
{
	Int32 preorderLimit;
	Int32 code;
	
	myName = id;
	myBootCategory = cat;
	preorderLimit = cat_Heaper->preorderMax() + 1;
	/* preorder -> recipe. */
	myRecipes = recipes;
	/* preorder -> code. */
	myEncoding = UInt32Array::make (preorderLimit);
	/* code -> category */
	myDecoding = PtrArray::nulls(count);
	code = Int32Zero;
	{
		Int32 LoopFinal = preorderLimit;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				SPTR(Recipe) recipe;
				
				recipe = CAST(Recipe,myRecipes->fetch(i));
				if (recipe == NULL) {
					myEncoding->storeUInt(i, preorderLimit);
				} else {
					myEncoding->storeUInt(i, code);
					myDecoding->store(code, recipe->categoryOfDish());
					code += 1;
				}
			}
			i += 1;
		}
	}
	myNext = ActualCookbook::TheCookbooks;
	ActualCookbook::TheCookbooks = this;
}


void ActualCookbook::destroy (){
	/* ActualCookbooks last for the whole run. */
	
	
}
/* printing */


void ActualCookbook::printOn (ostream& oo){
	oo << "an " << this->getCategory()->name();
}

#ifndef COOKBKX_SXX
#include "cookbkx.sxx"
#endif /* COOKBKX_SXX */


#ifndef COOKBKP_SXX
#include "cookbkp.sxx"
#endif /* COOKBKP_SXX */



#endif /* COOKBKX_CXX */

