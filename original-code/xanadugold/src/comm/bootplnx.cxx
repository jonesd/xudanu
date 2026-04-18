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

#ifndef BOOTPLNX_CXX
#define BOOTPLNX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef BOOTPLNX_HXX
#include "bootplnx.hxx"
#endif /* BOOTPLNX_HXX */

#ifndef BOOTPLNX_IXX
#include "bootplnx.ixx"
#endif /* BOOTPLNX_IXX */

#ifndef BOOTPLNR_HXX
#include "bootplnr.hxx"
#endif /* BOOTPLNR_HXX */

#ifndef BOOTPLNR_IXX
#include "bootplnr.ixx"
#endif /* BOOTPLNR_IXX */

#ifndef BOOTPLNP_HXX
#include "bootplnp.hxx"
#endif /* BOOTPLNP_HXX */

#ifndef BOOTPLNP_IXX
#include "bootplnp.ixx"
#endif /* BOOTPLNP_IXX */


#ifndef COOKBKX_HXX
#include "cookbkx.hxx"
#endif /* COOKBKX_HXX */

#ifndef RECIPEX_HXX
#include "recipex.hxx"
#endif /* RECIPEX_HXX */




/* ************************************************************************ *
 * 
 *                    Class BootPlan 
 *
 * ************************************************************************ */



/* Initializers for BootPlan */

Recipe * BootCuisine = NULL;	/* in BootPlan */



BEGIN_INIT_TIME(BootPlan,initTimeNonInherited) {
	Cookbook::declareCookbook("boot", cat_BootPlan, BootCuisine, XppCuisine);
} END_INIT_TIME(BootPlan,initTimeNonInherited);



/* Initializers for BootPlan */






/* accessing */
/* operate */


void BootPlan::execute (){
	/* A comm hook couldn't register the bootPlan because it's 
	working with a not-fully
		 constructed object, so we have to make bootPlans thunks and 
	register them here. */
	
	Connection::registerBootPlan(this);
}

	/* automatic 0-argument constructor */
BootPlan::BootPlan() {}



/* ************************************************************************ *
 * 
 *                    Class   BootMaker 
 *
 * ************************************************************************ */


/* accessing */


RPTR(Connection) BootMaker::connection (){
	/* Return the object representing the connection.  This gives 
	the client a handle by which to terminate the connection. */
	
	RETURN_CONSTRUCT(DirectConnection,(this->bootCategory(), this->bootHeaper()));
}
/* printing */


void BootMaker::printOn (ostream& oo){
	oo << this->getCategory()->name();
}
/* protected: */

	/* automatic 0-argument constructor */
BootMaker::BootMaker() {}



/* ************************************************************************ *
 * 
 *                    Class Connection 
 *
 * ************************************************************************ */



/* Initializers for Connection */

GPTR(PrimPtr2PtrTable) OF2(Category,BootPlan) Connection::TheBootPlans = NULL;



BEGIN_INIT_TIME(Connection,initTimeNonInherited) {
	Connection::TheBootPlans = PrimPtr2PtrTable::make (8);
} END_INIT_TIME(Connection,initTimeNonInherited);



/* Initializers for Connection */






/* registration */


void Connection::clearPlan (APTR(Category) cat){
	/* Throw out any plan associated with cat. */
	
	Connection::TheBootPlans->remove(cat);
}


void Connection::registerBootPlan (APTR(BootPlan) plan){
	/* For the current run, return plan if anyone looks for a 
	bootPlan that returns an instance of the category that plan returns. */
	
	Connection::TheBootPlans->introduce(plan->bootCategory(), plan);
}
/* creation */


RPTR(Connection) Connection::make (APTR(Category) category){
	WPTR(Connection) 	returnValue;
	returnValue = CAST(BootPlan,Connection::TheBootPlans->get(category))->connection();
	return returnValue;
}
/* Suclasses represent particular kinds of connections.  The 
connection object serves two purposes:  you can get the boot object 
from it, and you can destroy it to break the connection.  Note that 
destroying the bootObject does not break the connection because you 
might have gotten other objects from it. */


/* accessing */

	/* automatic 0-argument constructor */
Connection::Connection() {}



/* ************************************************************************ *
 * 
 *                    Class NestedConnection 
 *
 * ************************************************************************ */


/* creation */


RPTR(Connection) NestedConnection::make (
		APTR(Category) cat, 
		APTR(Heaper) heaper, 
		APTR(Connection) sub)
{
	RETURN_CONSTRUCT(NestedConnection,(cat, heaper, sub));
}
/* We just made an object that wraps another object, so the 
connection needs to wrap the connection by which that other object 
was obtained. */


/* accessing */


RPTR(Category) NestedConnection::bootCategory (){
	return (Category*) myCategory;
}


RPTR(Heaper) NestedConnection::bootHeaper (){
	return (Heaper*) myHeaper;
}
/* creation */


NestedConnection::NestedConnection (
		APTR(Category) cat, 
		APTR(Heaper) heaper, 
		APTR(Connection) sub) 
{
	myCategory = cat;
	myHeaper = heaper;
	mySub = sub;
}


void NestedConnection::destruct (){
	{mySub->destroy();  mySub = NULL /* don't want stale (S/CHK)PTRs */;}
	{myHeaper->destroy();  myHeaper = NULL /* don't want stale (S/CHK)PTRs */;}
	this->Connection::destruct();
}



/* ************************************************************************ *
 * 
 *                    Class ClearPlan 
 *
 * ************************************************************************ */


/* Remove a particular entry from the table of current BootPlans. */


/* accessing */


RPTR(Category) ClearPlan::bootCategory (){
	return (Category*) myCategory;
}


RPTR(Connection) ClearPlan::connection (){
	/* Return the object representing the connection.  This gives 
	the client a handle by which to terminate the connection. */
	
	BLAST(NoBootPlan);
	/* fodder */
	return NULL;
}
/* operate */


void ClearPlan::execute (){
	/* Use this hook to clear the element out of the bootPlan 
	registration table. */
	
	Connection::clearPlan(myCategory);
}
/* creation */


ClearPlan::ClearPlan (APTR(Category) cat, TCSJ) {
	myCategory = cat;
}



/* ************************************************************************ *
 * 
 *                    Class DirectConnection 
 *
 * ************************************************************************ */


/* We just made the object, so the connection is just a reference to 
the object. */


/* accessing */


RPTR(Category) DirectConnection::bootCategory (){
	return (Category*) myCategory;
}


RPTR(Heaper) DirectConnection::bootHeaper (){
	return (Heaper*) myHeaper;
}
/* creation */


DirectConnection::DirectConnection (APTR(Category) cat, APTR(Heaper) heaper) {
	myCategory = cat;
	myHeaper = heaper;
}


void DirectConnection::destruct (){
	/* myHeaper destroy. There are bootHeapers that you REALLY 
	don't want to destroy, such as the GrandMap */
	
	this->Connection::destruct();
}

#ifndef BOOTPLNX_SXX
#include "bootplnx.sxx"
#endif /* BOOTPLNX_SXX */


#ifndef BOOTPLNR_SXX
#include "bootplnr.sxx"
#endif /* BOOTPLNR_SXX */


#ifndef BOOTPLNP_SXX
#include "bootplnp.sxx"
#endif /* BOOTPLNP_SXX */



#endif /* BOOTPLNX_CXX */

