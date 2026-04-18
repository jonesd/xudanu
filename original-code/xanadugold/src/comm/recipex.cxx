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

#ifndef RECIPEX_CXX
#define RECIPEX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef RECIPEX_HXX
#include "recipex.hxx"
#endif /* RECIPEX_HXX */

#ifndef RECIPEX_IXX
#include "recipex.ixx"
#endif /* RECIPEX_IXX */


#ifndef COPYRCPX_HXX
#include "copyrcpx.hxx"
#endif /* COPYRCPX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */




/* ************************************************************************ *
 * 
 *                    Class Recipe 
 *
 * ************************************************************************ */



/* Initializers for Recipe */

Recipe * XppCuisine = NULL;	/* in Recipe */





/* Initializers for Recipe */






/* The table of all recipes in the system is maintained in the 
Cookbook module.  
Subclasses know how to craete instances of a particular class. */


/* accessing */


RPTR(Category) Recipe::categoryOfDish (){
	return (Category*) myCat;
}
/* printing */


void Recipe::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myCat << ")";
}
/* testing */


UInt32 Recipe::actualHashForEqual (){
	return this->categoryOfDish()->hashForEqual() * 701;
}


BooleanVar Recipe::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(Recipe,rec) {
			return rec->categoryOfDish()->isEqual(this->categoryOfDish());
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	return FALSE;
}
/* private: accessing */


RPTR(Recipe) Recipe::next (){
	/* Returnt the next recipe in the receiver's cuisine. */
	
	return (Recipe*) myNext;
}
/* protected: creation */


Recipe::Recipe (APTR(Category) cat, Recipe* * cuisine) {
	/* cuisine points to the *variable* in which the receiver 
	should be registered. */
	
	myCat = cat;
	myNext = *cuisine;
	*cuisine = this;
}



/* ************************************************************************ *
 * 
 *                    Class   CopyRecipe 
 *
 * ************************************************************************ */


/* accessing */


RPTR(Heaper) CopyRecipe::parse (APTR(SpecialistRcvr) rcvr){
	/* create a new object from the information in the transceiver */
	
	void * result;
	
	 
	result = Heaper::operator new (0, xcsj, this->categoryOfDish());
	
	
	rcvr->registerIbid((Heaper * ) result);
	this->parseInto(rcvr, result);
	return (Heaper * ) result;
}
/* protected: creation */


CopyRecipe::CopyRecipe (APTR(Category) cat, Recipe* * cuisine) 
	: Recipe(cat, cuisine) {
	/* cuisine points to the *variable* in which the receiver 
	should be registered. */
	
	
}



/* ************************************************************************ *
 * 
 *                    Class   StubRecipe 
 *
 * ************************************************************************ */


/* accessing */
/* protected: creation */


StubRecipe::StubRecipe (APTR(Category) cat, Recipe* * cuisine) 
	: Recipe(cat, cuisine) {
	/* cuisine points to the *variable* in which the receiver 
	should be registered. */
	
	
}

#ifndef RECIPEX_SXX
#include "recipex.sxx"
#endif /* RECIPEX_SXX */



#endif /* RECIPEX_CXX */

