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

#ifndef XFRSPECX_CXX
#define XFRSPECX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */

#ifndef XFRSPECX_IXX
#include "xfrspecx.ixx"
#endif /* XFRSPECX_IXX */

#ifndef XFRSPECP_HXX
#include "xfrspecp.hxx"
#endif /* XFRSPECP_HXX */

#ifndef XFRSPECP_IXX
#include "xfrspecp.ixx"
#endif /* XFRSPECP_IXX */


#ifndef FHASHX_HXX
#include "fhashx.hxx"
#endif /* FHASHX_HXX */

#ifndef NEGOTI8X_HXX
#include "negoti8x.hxx"
#endif /* NEGOTI8X_HXX */

#ifndef NSCOTTYX_HXX
#include "nscottyx.hxx"
#endif /* NSCOTTYX_HXX */

#ifndef STRINGX_HXX
#include "stringx.hxx"
#endif /* STRINGX_HXX */




/* ************************************************************************ *
 * 
 *                    Class SpecialistRcvr 
 *
 * ************************************************************************ */



/* Initializers for SpecialistRcvr */

GPTR(PtrArray) SpecialistRcvr::RcvrIbidCache = NULL;


/* Initializers for SpecialistRcvr */



/* myIbids maps from ibid number to already sent objects.  The ibids 
table is explicitly managed as a PtrArray because it is such a bottleneck. */


/* receiving */


RPTR(Heaper) SpecialistRcvr::receiveHeaper (){
	/* receive the next heaper */
	
	SPTR(Category) cat;
	
	cat = this->fetchStartOfInstance();
	if (cat == NULL) {
		return NULL;
	}
	if (cat->isEqual(cat_CommIbid)) {
		Int32 ibidNum;
		SPTR(Heaper) result;
		
		ibidNum = this->receiveInt32();
		this->endOfInstance();
		result = myIbids->fetch(ibidNum);
		if (result == NULL) {
			BLAST(NotInTable);
		}
		WPTR(Heaper) 	returnValue;
		returnValue = result;
		return returnValue;
	} else {
		SPTR(Heaper) result;
		
		result = mySpecialist->receiveHeaperFrom(cat, this);
		this->endOfInstance();
		WPTR(Heaper) 	returnValue;
		returnValue = result;
		return returnValue;
	}
}


void SpecialistRcvr::receiveInto (APTR(Heaper) memory){
	/* Receive an object into another object. */
	
	SPTR(Category) cat;
	
	cat = this->fetchStartOfInstance();
	{	BooleanVar crutch_Flag;
		/* cat == NULL || cat->isEqual(cat_CommIbid) */
		
		crutch_Flag = cat == NULL;
		if(!crutch_Flag) {
			crutch_Flag = cat->isEqual(cat_CommIbid);
		}
		if (crutch_Flag) {
			BLAST(NotBecomable);
		}
	}
	mySpecialist->receiveHeaperIntoFrom(cat, memory, this);
	this->endOfInstance();
}
/* specialist receiving */


RPTR(Heaper) SpecialistRcvr::basicReceive (APTR(Recipe) recipe){
	/* Pull the contents of the next heaper off the wire. */
	
	BEGIN_CHOOSE(recipe) {
		BEGIN_KIND(CopyRecipe,copy) {
			WPTR(Heaper) 	returnValue;
			returnValue = copy->parse(this);
			return returnValue;
		} END_KIND;
		BEGIN_OTHERS {
			BLAST(BadRecipe);
		} END_OTHERS;
	} END_CHOOSE;
	return NULL;
}


void SpecialistRcvr::basicReceiveInto (APTR(Recipe) recipe, APTR(Heaper) memory){
	/* Pull the contents of the next heaper off the wire. */
	
	if (!memory->getCategory()->canYouBecome(recipe->categoryOfDish())) {
		BLAST(NotBecomable);
	}
	this->registerIbid(memory);
	
	BEGIN_CHOOSE(recipe) {
		BEGIN_KIND(CopyRecipe,copy) {
			copy->parseInto(this, memory);
		} END_KIND;
		BEGIN_OTHERS {
			BLAST(BadRecipe);
		} END_OTHERS;
	} END_CHOOSE;
}


RPTR(Heaper) SpecialistRcvr::makeIbid (APTR(Category) cat){
	/* Create and register a memory slot for an instance of the 
	given category. */
	
	SPTR(Heaper) result;
	
	result = (Heaper *)Heaper::operator new (0, xcsj, cat);
	
	
	this->registerIbid(result);
	WPTR(Heaper) 	returnValue;
	returnValue = result;
	return returnValue;
}


void SpecialistRcvr::registerIbid (APTR(Heaper) obj){
	/* Grow the table. */
	if (myNextIbid >= myIbids->count()) {
		SPTR(PtrArray) oldIbids;
		
		oldIbids = myIbids;
		myIbids = PtrArray::nulls(myNextIbid * 2);
		{
			Int32 LoopFinal = myNextIbid;
			Int32 i = 1;
			for (;;) {
				if (i >= LoopFinal){
					break;
				}
				{
					myIbids->store(i, oldIbids->fetch(i));
				}
				i += 1;
			}
		}
		{oldIbids->destroy();  oldIbids = NULL /* don't want stale (S/CHK)PTRs */;}
	}
	myIbids->store(myNextIbid, obj);
	myNextIbid += 1;
}
/* protected: specialist */


void SpecialistRcvr::endPacket (){
	{
		Int32 LoopFinal = myNextIbid;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				myIbids->store(i, NULL);
			}
			i += 1;
		}
	}
	myNextIbid = Int32Zero;
}


RPTR(TransferSpecialist) SpecialistRcvr::specialist (){
	return (TransferSpecialist*) mySpecialist;
}
/* protected: creation */


SpecialistRcvr::SpecialistRcvr (APTR(TransferSpecialist) specialist, TCSJ) {
	mySpecialist = specialist;
	if (SpecialistRcvr::RcvrIbidCache == NULL) {
		myIbids = PtrArray::nulls(128);
	} else {
		myIbids = SpecialistRcvr::RcvrIbidCache;
		SpecialistRcvr::RcvrIbidCache = NULL;
	}
	myNextIbid = Int32Zero;
}


void SpecialistRcvr::destruct (){
	if (SpecialistRcvr::RcvrIbidCache == NULL) {
		myIbids->storeAll();
		SpecialistRcvr::RcvrIbidCache = CAST(PtrArray,myIbids);
		myIbids = NULL;
	} else {
		{myIbids->destroy();  myIbids = NULL /* don't want stale (S/CHK)PTRs */;}
	}
	/* mySpecialist destroy */
	this->Rcvr::destruct();
}



/* ************************************************************************ *
 * 
 *                    Class SpecialistXmtr 
 *
 * ************************************************************************ */



/* Initializers for SpecialistXmtr */

GPTR(PrimIndexTable) SpecialistXmtr::XmtrIbidCache = NULL;


/* Initializers for SpecialistXmtr */



/* myIbids maps from already sent heapers to their ibid numbers. */


/* sending */


void SpecialistXmtr::sendHeaper (APTR(Heaper) object){
	if (object == NULL) {
		this->sendNULL();
	} else {
		Int32 pos;
		
		pos = myIbids->fetch(object).asLong();
		if (pos != -1) {
			this->sendIbid(pos);
		} else {
			mySpecialist->sendHeaperTo(object, this);
		}
	}
}
/* specialist sending */


void SpecialistXmtr::startInstance (APTR(Heaper) heaper, APTR(Category) cat){
	/* Register heaper as an object to be sent across the wire, 
	and send cat
		 as its category. cat might be different from heaper->getCategory() 
		 if another object is being substituted for heaper. */
	
	myIbids->introduce(heaper, myNextIbid);
	myNextIbid += 1;
	this->startNewInstance(cat);
}
/* protected: */


void SpecialistXmtr::endPacket (){
	myIbids->clearAll();
	myNextIbid = Int32Zero;
}


RPTR(TransferSpecialist) SpecialistXmtr::specialist (){
	return (TransferSpecialist*) mySpecialist;
}
/* private: sending */


void SpecialistXmtr::sendIbid (Int32 pos){
	/* The object represented by pos has already been sent.  Send 
	just a reference by number. */
	
	this->startNewInstance(cat_CommIbid);
	this->sendInt32(pos);
	this->endInstance();
}
/* protected: creation */


SpecialistXmtr::SpecialistXmtr (APTR(TransferSpecialist) specialist, TCSJ) {
	mySpecialist = specialist;
	if (SpecialistXmtr::XmtrIbidCache == NULL) {
		myIbids = PrimIndexTable::make (255);
	} else {
		myIbids = SpecialistXmtr::XmtrIbidCache;
		SpecialistXmtr::XmtrIbidCache = NULL;
	}
	myNextIbid = Int32Zero;
}


void SpecialistXmtr::destruct (){
	if (SpecialistXmtr::XmtrIbidCache == NULL) {
		myIbids->clearAll();
		SpecialistXmtr::XmtrIbidCache = CAST(PrimIndexTable,myIbids);
		myIbids = NULL;
	} else {
		{myIbids->destroy();  myIbids = NULL /* don't want stale (S/CHK)PTRs */;}
	}
	/* mySpecialist destroy */
	this->Xmtr::destruct();
}



/* ************************************************************************ *
 * 
 *                    Class TransferSpecialist 
 *
 * ************************************************************************ */


/* creation */


RPTR(TransferSpecialist) TransferSpecialist::make (APTR(Cookbook) aBook){
	/* Return a specialist that does nothing. */
	
	RETURN_CONSTRUCT(TransferGeneralist,(aBook, tcsj));
}
/* cookbook */


RPTR(Category) TransferSpecialist::getCategoryFor (IntegerVar no){
	WPTR(Category) 	returnValue;
	returnValue = myCookbook->getCategoryFor(no);
	return returnValue;
}


RPTR(Recipe) TransferSpecialist::getRecipe (APTR(Category) cat){
	WPTR(Recipe) 	returnValue;
	returnValue = myCookbook->getRecipe(cat);
	return returnValue;
}


IntegerVar TransferSpecialist::numberOfCategory (APTR(Category) cat){
	return myCookbook->numberOfCategory(cat);
}
/* communication */


void TransferSpecialist::sendHeaperTo (APTR(Heaper) hpr, APTR(SpecialistXmtr) xmtr){
	/* Transmit heapers on xmtr.  Subclasses intercept and handle 
	special cases here. */
	
	xmtr->startInstance(hpr, hpr->getCategory());
	hpr->sendSelfTo(xmtr);
	xmtr->endInstance();
}
/* creation */


TransferSpecialist::TransferSpecialist (APTR(Cookbook) aBook, TCSJ) {
	myCookbook = aBook;
}



/* ************************************************************************ *
 * 
 *                    Class XcvrMaker 
 *
 * ************************************************************************ */



/* Initializers for XcvrMaker */

/* Initializers for XcvrMaker */
/* xcvr creation */


RPTR(XcvrMaker) XcvrMaker::make (){
	RETURN_CONSTRUCT(BogusXcvrMaker,());
}
/* xcvr creation */
/* printing */


void XcvrMaker::printOn (ostream& oo){
	oo << "A " << this->getCategory()->name();
}
/* testing */


UInt32 XcvrMaker::actualHashForEqual (){
	return this->getCategory()->hashForEqual() * 997 + ::fastHash(this->id());
}


BooleanVar XcvrMaker::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(XcvrMaker,xm) {
			return ::strcmp(this->id(), xm->id()) == Int32Zero;
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}

	/* automatic 0-argument constructor */
XcvrMaker::XcvrMaker() {}



/* ************************************************************************ *
 * 
 *                    Class BogusXcvrMaker 
 *
 * ************************************************************************ */



/* Initializers for BogusXcvrMaker */

/* Initializer inherited from XcvrMaker */


BEGIN_INIT_TIME(BogusXcvrMaker,initTimeInherited) {
	SPTR(XcvrMaker) maker;
	
	REQUIRES (ProtocolBroker);
	CONSTRUCT(maker,BogusXcvrMaker,());
	ProtocolBroker::registerXcvrProtocol(maker);
} END_INIT_TIME(BogusXcvrMaker,initTimeInherited);



/* Initializers for BogusXcvrMaker */

/* Initializer inherited from XcvrMaker */



/* testing */


char * BogusXcvrMaker::id (){
	char * 	returnValue;
	returnValue = "bogus";
	return returnValue;
}
/* xcvr creation */


RPTR(SpecialistRcvr) BogusXcvrMaker::makeRcvr (APTR(TransferSpecialist) /* specialist */, APTR(XnReadStream) /* readStream */){
	BLAST(BogusProtocol);
	return NULL;
}


RPTR(SpecialistXmtr) BogusXcvrMaker::makeXmtr (APTR(TransferSpecialist) specialist, APTR(XnWriteStream) writeStream){
	BLAST(BogusProtocol);
	return NULL;
}

	/* automatic 0-argument constructor */
BogusXcvrMaker::BogusXcvrMaker() {}



/* ************************************************************************ *
 * 
 *                    Class CategoryRecipe 
 *
 * ************************************************************************ */



/* Initializers for CategoryRecipe */

extern Category * cat_Category;
		CategoryRecipe categoryRecipe(cat_Category, &XppCuisine);




/* Initializers for CategoryRecipe */



/* accessing */


RPTR(Heaper) CategoryRecipe::parse (APTR(SpecialistRcvr) rcvr){
	SPTR(Category) cat;
	
	cat = CAST(SpecialistRcvr,rcvr)->receiveCategory();
	rcvr->registerIbid(cat);
	WPTR(Heaper) 	returnValue;
	returnValue = cat;
	return returnValue;
}


void CategoryRecipe::parseInto (APTR(Rcvr) /* rcvr */, void * /* memory */){
	BLAST(NotBecomable);
}
/* creation */


CategoryRecipe::CategoryRecipe (APTR(Category) cat, Recipe* * cuisine) 
	: CopyRecipe(cat, cuisine) {
	/* cuisine points to the *variable* in which the receiver 
	should be registered. */
	
	
}



/* ************************************************************************ *
 * 
 *                    Class CommIbid 
 *
 * ************************************************************************ */


/* creation */


RPTR(CommIbid) CommIbid::make (IntegerVar number){
	RETURN_CONSTRUCT(CommIbid,(number, tcsj));
}
/* creation */


CommIbid::CommIbid (IntegerVar number, TCSJ) {
	myNumber = number;
}
/* accessing */


IntegerVar CommIbid::number (){
	return myNumber;
}
/* printing */


void CommIbid::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myNumber << ")";
}
/* testing */


UInt32 CommIbid::actualHashForEqual (){
	return Heaper::takeOop();
}



/* ************************************************************************ *
 * 
 *                    Class TransferGeneralist 
 *
 * ************************************************************************ */


/* creation */


RPTR(TransferSpecialist) TransferGeneralist::make (APTR(Cookbook) aBook){
	RETURN_CONSTRUCT(TransferGeneralist,(aBook, tcsj));
}
/* create */


TransferGeneralist::TransferGeneralist (APTR(Cookbook) aBook, TCSJ) 
	: TransferSpecialist(aBook, tcsj) {
	
}
/* communication */


RPTR(Heaper) TransferGeneralist::receiveHeaperFrom (APTR(Category) cat, APTR(SpecialistRcvr) rcvr){
	/* No special cases.  Punt to the rcvr. */
	
	WPTR(Heaper) 	returnValue;
	returnValue = rcvr->basicReceive(this->getRecipe(cat));
	return returnValue;
}


void TransferGeneralist::receiveHeaperIntoFrom (
		APTR(Category) cat, 
		APTR(Heaper) memory, 
		APTR(SpecialistRcvr) rcvr)
{
	/* No special cases.  Punt to the rcvr. */
	
	rcvr->basicReceiveInto(this->getRecipe(cat), memory);
}

#ifndef XFRSPECX_SXX
#include "xfrspecx.sxx"
#endif /* XFRSPECX_SXX */


#ifndef XFRSPECP_SXX
#include "xfrspecp.sxx"
#endif /* XFRSPECP_SXX */



#endif /* XFRSPECX_CXX */

