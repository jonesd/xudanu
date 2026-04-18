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

#ifndef COMDTCTP_HXX
#define COMDTCTP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef COMDTCTP_OXX
#include "comdtctp.oxx"
#endif /* COMDTCTP_OXX */


#ifndef COMDTCTR_HXX
#include "comdtctr.hxx"
#endif /* COMDTCTR_HXX */

#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef PROMANX_OXX
#include "promanx.oxx"
#endif /* PROMANX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class DoneEvent 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class DoneEvent : public DetectorEvent {

/* Attributes for class DoneEvent */
	CONCRETE(DoneEvent)
	NOT_A_TYPE(DoneEvent)
	NO_GC(DoneEvent)
  public: /* creation */

	
	static RPTR(DetectorEvent) make (IntegerVar ARG(detector));
	
  public: /* triggering */

	/* Send the message across the wire. */
	
	virtual void trigger (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	DoneEvent (IntegerVar ARG(detector), TCSJ);
	

};  /* end class DoneEvent */



/* ************************************************************************ *
 * 
 *                    Class FilledEvent 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class FilledEvent : public DetectorEvent {

/* Attributes for class FilledEvent */
	CONCRETE(FilledEvent)
	NOT_A_TYPE(FilledEvent)
	AUTO_GC(FilledEvent)
  public: /* creation */

	
	static RPTR(DetectorEvent) make (IntegerVar ARG(detector), APTR(Heaper) ARG(filling));
	
  public: /* triggering */

	/* Send the message across the wire. */
	
	virtual void trigger (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	FilledEvent (IntegerVar ARG(detector), APTR(Heaper) ARG(filling));
	
  private:
	CHKPTR(Heaper) myFilling;
};  /* end class FilledEvent */



/* ************************************************************************ *
 * 
 *                    Class GrabbedEvent 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class GrabbedEvent : public DetectorEvent {

/* Attributes for class GrabbedEvent */
	CONCRETE(GrabbedEvent)
	NOT_A_TYPE(GrabbedEvent)
	AUTO_GC(GrabbedEvent)
  public: /* creation */

	
	static RPTR(DetectorEvent) make (
			IntegerVar ARG(detector), 
			APTR(Heaper) ARG(work), 
			APTR(Heaper) ARG(author), 
			IntegerVar ARG(reason))
	;
	
  public: /* triggering */

	/* Send the message across the wire. */
	
	virtual void trigger (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	GrabbedEvent (
			IntegerVar ARG(detector), 
			APTR(Heaper) ARG(work), 
			APTR(Heaper) ARG(author), 
			IntegerVar ARG(reason))
	;
	
  private:
	CHKPTR(Heaper) myWork;
	CHKPTR(Heaper) myAuthor;
	IntegerVar myReason;
};  /* end class GrabbedEvent */



/* ************************************************************************ *
 * 
 *                    Class RangeFilledEvent 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class RangeFilledEvent : public DetectorEvent {

/* Attributes for class RangeFilledEvent */
	CONCRETE(RangeFilledEvent)
	NOT_A_TYPE(RangeFilledEvent)
	AUTO_GC(RangeFilledEvent)
  public: /* creation */

	
	static RPTR(DetectorEvent) make (IntegerVar ARG(detector), APTR(Heaper) ARG(filling));
	
  public: /* creation */

	
	RangeFilledEvent (IntegerVar ARG(detector), APTR(Heaper) ARG(filling));
	
  public: /* triggering */

	/* Send the message across the wire. */
	
	virtual void trigger (APTR(PromiseManager) ARG(pm));
	
  private:
	CHKPTR(Heaper) myFilling;
};  /* end class RangeFilledEvent */



/* ************************************************************************ *
 * 
 *                    Class ReleasedEvent 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ReleasedEvent : public DetectorEvent {

/* Attributes for class ReleasedEvent */
	CONCRETE(ReleasedEvent)
	NOT_A_TYPE(ReleasedEvent)
	AUTO_GC(ReleasedEvent)
  public: /* creation */

	
	static RPTR(DetectorEvent) make (
			IntegerVar ARG(detector), 
			APTR(Heaper) ARG(work), 
			IntegerVar ARG(reason))
	;
	
  public: /* creation */

	
	ReleasedEvent (
			IntegerVar ARG(detector), 
			APTR(Heaper) ARG(work), 
			IntegerVar ARG(reason))
	;
	
  public: /* triggering */

	/* Send the message across the wire. */
	
	virtual void trigger (APTR(PromiseManager) ARG(pm));
	
  private:
	CHKPTR(Heaper) myWork;
	IntegerVar myReason;
};  /* end class ReleasedEvent */



/* ************************************************************************ *
 * 
 *                    Class RevisedEvent 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class RevisedEvent : public DetectorEvent {

/* Attributes for class RevisedEvent */
	CONCRETE(RevisedEvent)
	NOT_A_TYPE(RevisedEvent)
	AUTO_GC(RevisedEvent)
  public: /* creation */

	
	static RPTR(DetectorEvent) make (
			IntegerVar ARG(detector), 
			APTR(Heaper) ARG(work), 
			APTR(Heaper) ARG(contents), 
			APTR(Heaper) ARG(author), 
			IntegerVar ARG(time), 
			IntegerVar ARG(sequence))
	;
	
  public: /* creation */

	
	RevisedEvent (
			IntegerVar ARG(detector), 
			APTR(Heaper) ARG(work), 
			APTR(Heaper) ARG(contents), 
			APTR(Heaper) ARG(author), 
			IntegerVar ARG(time), 
			IntegerVar ARG(sequence))
	;
	
  public: /* triggering */

	/* Send the message across the wire. */
	
	virtual void trigger (APTR(PromiseManager) ARG(pm));
	
  private:
	CHKPTR(Heaper) myWork;
	CHKPTR(Heaper) myContents;
	CHKPTR(Heaper) myAuthor;
	IntegerVar myTime;
	IntegerVar mySequence;
};  /* end class RevisedEvent */



#endif /* COMDTCTP_HXX */

