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

#ifndef TURTLEX_HXX
#define TURTLEX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef TURTLEX_OXX
#include "turtlex.oxx"
#endif /* TURTLEX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */


#ifndef COOKBKX_OXX
#include "cookbkx.oxx"
#endif /* COOKBKX_OXX */

#ifndef COUNTERX_OXX
#include "counterx.oxx"
#endif /* COUNTERX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

#ifndef XFRSPECX_OXX
#include "xfrspecx.oxx"
#endif /* XFRSPECX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class AgendaItem 
 *
 * ************************************************************************ */




	/* A persistent representation of things that still need to 
	be done.  Can think of it like a persistent process record.  
	"schedule"ing me ensures that I will be stepped eventually, 
	and repeatedly, until step returns FALSE, even if the process 
	should crash after I am scheduled.  Scheduling me so that I 
	am persistent may happen inside some other consistent block, 
	however I will be stepped while outside of any consistent 
	block (The FakePacker doesn't do this yet).  Creating an 
	AgendaItem does not imply that it is scheduled, the client 
	must explicitly schedule it as well.  Destroying it *does* 
	ensure that it gets unscheduled, though it is valid & safe to 
	destroy one which isn't scheduled.
	
	NOTE: Right now there are no fairness guarantees (and there 
	may never be), so all AgendaItems must eventually terminate 
	in order for other things (like the ServerLoop) to be 
	guaranteed of eventually executing */

class AgendaItem : public Abraham {

/* Attributes for class AgendaItem */
	DEFERRED(AgendaItem)
	SHEPHERD_PATRIARCH(AgendaItem,Abraham)
	COPY(AgendaItem,DiskCuisine)
	DEFERRED_LOCKED(AgendaItem)
	NO_GC(AgendaItem)
  public: /* accessing */

	/* forget is protected.  This method exposes it for AgendaItems */
	
	virtual void forgetYourself ();
	
	/* remember is protected.  This method exposes it for AgendaItems */
	
	virtual void rememberYourself ();
	
	/* Registers me with the top level Agenda, so that I will 
	eventually get stepped.  Also causes me to be remembered. */
	
	virtual void schedule ();
	
	/* Return FALSE when there's nothing left to do (at which 
	time I should usually be unregistered and destroyed, but see 
	Agenda::step()) */
	
	virtual BooleanVar step () DEFERRED_FUNC;
	
	/* Unregisters me with the top level Agenda, so that I am no 
	longer scheduled to get stepped.  Also causes me to be forgotten. */
	
	virtual void unschedule ();
	
  protected: /* protected: creation */

	/* Not so special constructor for not becoming this class */
	
	AgendaItem ();
	
	/* Special constructor for becoming this class */
	
	AgendaItem (UInt32 ARG(hash), TCSJ);
	
	
	virtual void dismantle ();
	
	/* All AgendaItems use explicit deletion semantics. */
	/* ????? */
	
	virtual void newShepherd ();
	

};  /* end class AgendaItem */



/* ************************************************************************ *
 * 
 *                    Class   Agenda 
 *
 * ************************************************************************ */




	/* An AgendaItem composed of other AgendaItems.  My stepping 
	action consists of stepping one of my component items.  When 
	I exhaust a component item, I unregister and destroy it.
	
	Note: The order in which I select a component item is 
	currently unspecified and uncontrolled (depending on 
	"MuSet::stepper()").  Eventually, it may make sense for me to 
	use the Escalator Algorithm to do prioritized scheduling.
	
	Empty Agendas are also made as do-nothing AgendaItems.  The 
	currently get duely get scheduled, stepped, and unscheduled.  
	A possible optimization would be to avoid scheduling 
	do-nothing AgendaItems. */

class Agenda : public AgendaItem {

/* Attributes for class Agenda */
	CONCRETE(Agenda)
	SHEPHERD_PATRIARCH(Agenda,AgendaItem)
	LOCKED(Agenda)
	COPY(Agenda,DiskCuisine)
	AUTO_GC(Agenda)
  public: /* creation */

	
	static RPTR(Agenda) make ();
	
  public: /* accessing */

	/* By registering the item, we ensure that if we crash and 
	reboot, the item will be eventually and repeatedly stepped 
	until step returns FALSE, provided we are registered up 
	through the Turtle.  Do NOT multiply register the same item. */
	
	virtual void registerItem (APTR(AgendaItem) ARG(item));
	
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
	
	virtual BooleanVar step ();
	
	/* An item should be unregistered either when it is done 
	(when 'step' returns FALSE) or when it no longer represents 
	something that needs to be done should we crash and reboot.  
	Unregistering an item which is not registered and already 
	forgotten is legal and has no effect. */
	
	virtual void unregisterItem (APTR(AgendaItem) ARG(item));
	
  public: /* creation */

	
	Agenda ();
	
	
	virtual void dismantle ();
	
  private:
	CHKPTR(MuSet) OF1(AgendaItem) myToDoList;
};  /* end class Agenda */



/* ************************************************************************ *
 * 
 *                    Class   Sequencer 
 *
 * ************************************************************************ */




	/* An AgendaItem composed of two other AgendaItems.  Used for 
	when all of the first needs to be done before any of the 
	second may be done.
	
	My stepping action consists of stepping myFirst.  When it is 
	exhausted, I destroy it and then start stepping myRest */

class Sequencer : public AgendaItem {

/* Attributes for class Sequencer */
	CONCRETE(Sequencer)
	SHEPHERD_PATRIARCH(Sequencer,AgendaItem)
	COPY(Sequencer,DiskCuisine)
	LOCKED(Sequencer)
	NOT_A_TYPE(Sequencer)
	AUTO_GC(Sequencer)
  public: /* creation */

	
	static RPTR(AgendaItem) make (APTR(AgendaItem) ARG(first), APTR(AgendaItem) ARG(rest));
	
  protected: /* protected: creation */

	
	Sequencer (APTR(AgendaItem) ARG(first), APTR(AgendaItem) ARG(rest));
	
  public: /* accessing */

	
	virtual BooleanVar step ();
	
  public: /* creation */

	
	virtual void dismantle ();
	
  private:
	CHKPTR(AgendaItem) OR(NULL) myFirst;
	CHKPTR(AgendaItem) myRest;
};  /* end class Sequencer */



/* ************************************************************************ *
 * 
 *                    Class Turtle 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class Turtle : public Abraham {

/* Attributes for class Turtle */
	DEFERRED(Turtle)
	SHEPHERD_PATRIARCH(Turtle,Abraham)
	COPY(Turtle,DiskCuisine)
	DEFERRED_LOCKED(Turtle)
	NO_GC(Turtle)
  public: /* pseudo-constructors */

	
	static RPTR(Turtle) make (
			APTR(Cookbook) ARG(cookbook), 
			APTR(Category) ARG(bootCategory), 
			APTR(XcvrMaker) ARG(maker))
	;
	
  public: /* accessing */

	
	virtual RPTR(Category) bootCategory () DEFERRED_FUNC;
	
	
	virtual RPTR(Heaper) bootHeaper () DEFERRED_FUNC;
	
	
	virtual RPTR(Cookbook) cookbook () DEFERRED_FUNC;
	
	
	virtual RPTR(Counter) counter () DEFERRED_FUNC;
	
	/* Under all normal conditions, a Turtle has an Agenda.  
	However, during the construction of a Turtle, there may arise 
	situations when a piece of code is invoked which normally 
	asks the Turtle for its agenda before the Turtle is mature 
	enough to have one. */
	
	virtual RPTR(Agenda) OR(NULL) fetchAgenda () DEFERRED_FUNC;
	
	/* See Turtle::fetchAgenda() */
	
	virtual RPTR(Agenda) getAgenda ();
	
	
	virtual RPTR(XcvrMaker) protocol () DEFERRED_FUNC;
	
	
	virtual void saveBootHeaper (APTR(Heaper) ARG(boot)) DEFERRED_SUBR;
	
	
	virtual void setProtocol (APTR(XcvrMaker) ARG(xcvrMaker), APTR(Cookbook) ARG(book)) DEFERRED_SUBR;
	
  protected: /* protected: creation */

	
	Turtle ();
	
	
	Turtle (UInt32 ARG(hash), TCSJ);
	

};  /* end class Turtle */



#endif /* TURTLEX_HXX */

