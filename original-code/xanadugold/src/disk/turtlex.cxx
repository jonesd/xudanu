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

#ifndef TURTLEX_CXX
#define TURTLEX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef TURTLEX_HXX
#include "turtlex.hxx"
#endif /* TURTLEX_HXX */

#ifndef TURTLEX_IXX
#include "turtlex.ixx"
#endif /* TURTLEX_IXX */

#ifndef TURTLEP_HXX
#include "turtlep.hxx"
#endif /* TURTLEP_HXX */

#ifndef TURTLEP_IXX
#include "turtlep.ixx"
#endif /* TURTLEP_IXX */


#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */




/* ************************************************************************ *
 * 
 *                    Class AgendaItem 
 *
 * ************************************************************************ */


/* A persistent representation of things that still need to be done.  
Can think of it like a persistent process record.  "schedule"ing me 
ensures that I will be stepped eventually, and repeatedly, until step 
returns FALSE, even if the process should crash after I am scheduled. 
 Scheduling me so that I am persistent may happen inside some other 
consistent block, however I will be stepped while outside of any 
consistent block (The FakePacker doesn't do this yet).  Creating an 
AgendaItem does not imply that it is scheduled, the client must 
explicitly schedule it as well.  Destroying it *does* ensure that it 
gets unscheduled, though it is valid & safe to destroy one which 
isn't scheduled.

NOTE: Right now there are no fairness guarantees (and there may never 
be), so all AgendaItems must eventually terminate in order for other 
things (like the ServerLoop) to be guaranteed of eventually executing */


/* accessing */


void AgendaItem::forgetYourself (){
	/* forget is protected.  This method exposes it for AgendaItems */
	
	this->forget();
}


void AgendaItem::rememberYourself (){
	/* remember is protected.  This method exposes it for AgendaItems */
	
	this->remember();
}


void AgendaItem::schedule (){
	/* Registers me with the top level Agenda, so that I will 
	eventually get stepped.  Also causes me to be remembered. */
	
	
	/* for debugging */
	CurrentPacker.fluidGet()->getInitialFlock()->getAgenda()->registerItem(this);
}


void AgendaItem::unschedule (){
	/* Unregisters me with the top level Agenda, so that I am no 
	longer scheduled to get stepped.  Also causes me to be forgotten. */
	
	CurrentPacker.fluidGet()->getInitialFlock()->getAgenda()->unregisterItem(this);
}
/* protected: creation */


AgendaItem::AgendaItem () {
	/* Not so special constructor for not becoming this class */
	
	
}


AgendaItem::AgendaItem (UInt32 hash, TCSJ) 
	: Abraham(hash, tcsj) {
	/* Special constructor for becoming this class */
	
	
}


void AgendaItem::dismantle (){
	BEGIN_CONSISTENT(2) {
		this->unschedule();
		this->Abraham::dismantle();
	} END_CONSISTENT;
}


void AgendaItem::newShepherd (){
	/* All AgendaItems use explicit deletion semantics. */
	/* ????? */
	
	this->Abraham::newShepherd();
}



/* ************************************************************************ *
 * 
 *                    Class   Agenda 
 *
 * ************************************************************************ */


/* creation */


RPTR(Agenda) Agenda::make (){
	/* Thing to do !!!! */
	
	/* see class comment for optimization possibility */
	BEGIN_CONSISTENT(1) {
		RETURN_CONSTRUCT(Agenda,());
	} END_CONSISTENT;
}
/* An AgendaItem composed of other AgendaItems.  My stepping action 
consists of stepping one of my component items.  When I exhaust a 
component item, I unregister and destroy it.

Note: The order in which I select a component item is currently 
unspecified and uncontrolled (depending on "MuSet::stepper()").  
Eventually, it may make sense for me to use the Escalator Algorithm 
to do prioritized scheduling.

Empty Agendas are also made as do-nothing AgendaItems.  The currently 
get duely get scheduled, stepped, and unscheduled.  A possible 
optimization would be to avoid scheduling do-nothing AgendaItems. */


/* accessing */


void Agenda::registerItem (APTR(AgendaItem) item){
	/* By registering the item, we ensure that if we crash and 
	reboot, the item will be eventually and repeatedly stepped 
	until step returns FALSE, provided we are registered up 
	through the Turtle.  Do NOT multiply register the same item. */
	
	BEGIN_CONSISTENT(2) {
		myToDoList->introduce(item);
		/* Why did we once have a 'bug?' annotation that this 
			introduce needs to preceed the rememberYourself? */
		item->rememberYourself();
		this->diskUpdate();
	} END_CONSISTENT;
}


BooleanVar Agenda::step (){
	/* 'step' one of my component items.  If I return FALSE, that 
	means there's nothing currently left to do.  However, since 
	more AgendaItems may get registered later, there may later be 
	something more for me to do, so I shouldn't necessarily be 
	destroyed.  This creates a composition problem: If an Agenda 
	is stored as an item within another Agenda, then when the 
	outer Agenda is stepped and it in turn steps the inner 
	Agenda, if the inner Agenda returns FALSE, the outer Agenda 
	will destroy it.  This is all legal and shouldn't be a 
	problem as long as one is aware of this behavior */
	
	SPTR(AgendaItem) OR(NULL) item;
	SPTR(Stepper) stomp;
	
	/* fetch some one item from myToDOList by creating a stepper, 
	fetching with it, and
		destroying the stepper.
		If there were no items left
			return, telling the caller that there is nothing left to 
	do.  (We may do this repeatedly...)
		step the item.
			if it returned false
				unregister the item
				atomically
					destroy it  (nuke it?)
		return whether there are any more things to do. */
	item = CAST(AgendaItem,(stomp = myToDoList->stepper())->fetch());
	{stomp->destroy();  stomp = NULL /* don't want stale (S/CHK)PTRs */;}
	/* Thing to do !!!! */
	
	/* The above code is n-squared.  It should probably be fixed 
		up during tuning. */
	if (item == NULL) {
		return FALSE;
	}
	if (!item->step()) {
		this->unregisterItem(item);
		BEGIN_CONSISTENT(2) {
			{item->destroy();  item = NULL /* don't want stale (S/CHK)PTRs */;}
			/* find out if the consistent block is 
				necessary/appropriate */
			/* Thing to do !!!! */
			
		} END_CONSISTENT;
	}
	return !myToDoList->isEmpty();
}


void Agenda::unregisterItem (APTR(AgendaItem) item){
	/* An item should be unregistered either when it is done 
	(when 'step' returns FALSE) or when it no longer represents 
	something that needs to be done should we crash and reboot.  
	Unregistering an item which is not registered and already 
	forgotten is legal and has no effect. */
	
	BEGIN_CONSISTENT(2) {
		myToDoList->wipe(item);
		item->forgetYourself();
		this->diskUpdate();
	} END_CONSISTENT;
}
/* creation */


Agenda::Agenda () {
	myToDoList = MuSet::make ();
	/* Known bug !!!! */
	
	/* A MuSet may become too big to fit within a snarf.  
		However, GrandHashSets spawn AgendaItems and force 
		propogating consistent block counts up through 
		anything else that uses them. */
	this->newShepherd();
}


void Agenda::dismantle (){
	BEGIN_FOR_EACH(AgendaItem,each,(myToDoList->stepper())) {
		this->unregisterItem(each);
		{each->destroy();  each = NULL /* don't want stale (S/CHK)PTRs */;}
	} END_FOR_EACH;
	BEGIN_CONSISTENT(2) {
		{myToDoList->destroy();  myToDoList = NULL /* don't want stale (S/CHK)PTRs */;}
		this->AgendaItem::dismantle();
	} END_CONSISTENT;
}



/* ************************************************************************ *
 * 
 *                    Class   Sequencer 
 *
 * ************************************************************************ */


/* creation */


RPTR(AgendaItem) Sequencer::make (APTR(AgendaItem) first, APTR(AgendaItem) rest){
	BEGIN_CONSISTENT(3) {
		RETURN_CONSTRUCT(Sequencer,(first, rest));
	} END_CONSISTENT;
}
/* An AgendaItem composed of two other AgendaItems.  Used for when 
all of the first needs to be done before any of the second may be done.

My stepping action consists of stepping myFirst.  When it is 
exhausted, I destroy it and then start stepping myRest */


/* protected: creation */


Sequencer::Sequencer (APTR(AgendaItem) first, APTR(AgendaItem) rest) {
	myFirst = first;
	myRest = rest;
	first->rememberYourself();
	rest->rememberYourself();
	this->newShepherd();
}
/* accessing */


BooleanVar Sequencer::step (){
	if (myFirst == NULL) {
		return myRest->step();
	} else {
		if (!myFirst->step()) {
			BEGIN_CONSISTENT(2) {
				{myFirst->destroy();  myFirst = NULL /* don't want stale (S/CHK)PTRs */;}
				myFirst = NULL;
				this->diskUpdate();
			} END_CONSISTENT;
		}
		return TRUE;
	}
}
/* creation */


void Sequencer::dismantle (){
	BEGIN_CONSISTENT(3) {
		if (myFirst != NULL) {
			{myFirst->destroy();  myFirst = NULL /* don't want stale (S/CHK)PTRs */;}
		}
		{myRest->destroy();  myRest = NULL /* don't want stale (S/CHK)PTRs */;}
		this->AgendaItem::dismantle();
	} END_CONSISTENT;
}



/* ************************************************************************ *
 * 
 *                    Class Turtle 
 *
 * ************************************************************************ */


/* pseudo-constructors */


RPTR(Turtle) Turtle::make (
		APTR(Cookbook) cookbook, 
		APTR(Category) bootCategory, 
		APTR(XcvrMaker) maker)
{
	WPTR(Turtle) 	returnValue;
	returnValue = SimpleTurtle::make (cookbook, bootCategory, maker);
	return returnValue;
}
/* accessing */


RPTR(Agenda) Turtle::getAgenda (){
	/* See Turtle::fetchAgenda() */
	
	SPTR(Agenda) OR(NULL) result;
	
	result = this->fetchAgenda();
	if (result == NULL) {
		BLAST(TurtleNotMature);
	}
	WPTR(Agenda) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* protected: creation */


Turtle::Turtle () {
	
}


Turtle::Turtle (UInt32 hash, TCSJ) 
	: Abraham(hash, tcsj) {
	
}



/* ************************************************************************ *
 * 
 *                    Class SimpleTurtle 
 *
 * ************************************************************************ */


/* pseudo-constructors */


RPTR(SimpleTurtle) SimpleTurtle::make (
		APTR(Cookbook) cookbook, 
		APTR(Category) bootCategory, 
		APTR(XcvrMaker) maker)
{
	RETURN_CONSTRUCT(SimpleTurtle,(cookbook, bootCategory, maker));
}
/* accessing */


RPTR(Category) SimpleTurtle::bootCategory (){
	return (Category*) myBootCategory;
}


RPTR(Heaper) SimpleTurtle::bootHeaper (){
	return (Heaper*) myBootHeaper;
}


RPTR(Cookbook) SimpleTurtle::cookbook (){
	return (Cookbook*) myCookbook;
}


RPTR(Counter) SimpleTurtle::counter (){
	return (Counter*) myCounter;
}


RPTR(Agenda) OR(NULL) SimpleTurtle::fetchAgenda (){
	return (Agenda*) myAgenda;
}


RPTR(XcvrMaker) SimpleTurtle::protocol (){
	return (XcvrMaker*) myProtocol;
}


void SimpleTurtle::saveBootHeaper (APTR(Heaper) boot){
	if (myBootHeaper == NULL) {
		BEGIN_CONSISTENT(1) {
			myBootHeaper = boot;
			this->diskUpdate();
		} END_CONSISTENT;
	} else {
		BLAST(DontChangeTurtlesBootHeaper);
	}
}


void SimpleTurtle::setProtocol (APTR(XcvrMaker) xcvrMaker, APTR(Cookbook) book){
	myProtocol = xcvrMaker;
	myCookbook = book;
}
/* testing */


UInt32 SimpleTurtle::contentsHash (){
	return this->Turtle::contentsHash() ^ myCounter->hashForEqual() ^ myBootHeaper->hashForEqual() ^ myProtocol->hashForEqual();
}
/* hooks: */


void SimpleTurtle::restartSimpleTurtle (APTR(Rcvr) /* rcvr *//* = NULL*/){
	myProtocol = XcvrMaker::make ();
	/* The bogus protocol */
		/* with the empty cookbook */
	myCookbook = Cookbook::make ();
}
/* protected: creation */


SimpleTurtle::SimpleTurtle (
		APTR(Cookbook) cookbook, 
		APTR(Category) bootCategory, 
		APTR(XcvrMaker) maker) 

	: Turtle(1, tcsj) {
	SPTR(DiskManager) packer;
	
	packer = CAST(DiskManager,CurrentPacker.fluidGet());
	BEGIN_CONSISTENT(1) {
		myCounter = NULL;
		myBootHeaper = NULL;
		myProtocol = maker;
		myCookbook = cookbook;
		myBootCategory = bootCategory;
		myAgenda = NULL;
		packer->storeInitialFlock(this, myProtocol, cookbook);
	} END_CONSISTENT;
	BEGIN_CONSISTENT(3) {
		/* Thing to do !!!! */
		
		/* tune the number 5000 */
		myCounter = 
				Counter::fakeCounter(3, 5000, 2);
		packer->setHashCounter(myCounter);
		this->remember();
		myCounter->newShepherd();
		myCounter->remember();
		myAgenda = Agenda::make ();
		myAgenda->rememberYourself();
	} END_CONSISTENT;
}

#ifndef TURTLEX_SXX
#include "turtlex.sxx"
#endif /* TURTLEX_SXX */


#ifndef TURTLEP_SXX
#include "turtlep.sxx"
#endif /* TURTLEP_SXX */



#endif /* TURTLEX_CXX */

