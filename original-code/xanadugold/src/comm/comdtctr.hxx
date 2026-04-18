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

#ifndef COMDTCTR_HXX
#define COMDTCTR_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef COMDTCTR_OXX
#include "comdtctr.oxx"
#endif /* COMDTCTR_OXX */


#ifndef DETECTX_HXX
#include "detectx.hxx"
#endif /* DETECTX_HXX */

#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef IDX_OXX
#include "idx.oxx"
#endif /* IDX_OXX */

#ifndef NKERNELX_OXX
#include "nkernelx.oxx"
#endif /* NKERNELX_OXX */

#ifndef PROMANX_OXX
#include "promanx.oxx"
#endif /* PROMANX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class CommFillDetector 
 *
 * ************************************************************************ */




	/* Send the detector events over comm. */

class CommFillDetector : public FeFillDetector {

/* Attributes for class CommFillDetector */
	CONCRETE(CommFillDetector)
	AUTO_GC(CommFillDetector)
  public: /* creation */

	
	static RPTR(CommFillDetector) make (
			APTR(PromiseManager) ARG(pm), 
			IntegerVar ARG(number), 
			APTR(FeRangeElement) ARG(target))
	;
	
  public: /* creation */

	
	CommFillDetector (
			APTR(PromiseManager) ARG(pm), 
			IntegerVar ARG(number), 
			APTR(FeRangeElement) ARG(target))
	;
	
  public: /* triggering */

	/* A single PlaceHolder has been filled to become another 
	kind of RangeElement */
	
	virtual void filled (APTR(FeRangeElement) ARG(newIdentity));
	
  private:
	CHKPTR(PromiseManager) myManager;
	IntegerVar myNumber;
	CHKPTR(FeRangeElement) myTarget;
};  /* end class CommFillDetector */



/* ************************************************************************ *
 * 
 *                    Class CommFillRangeDetector 
 *
 * ************************************************************************ */




	/* Send the detector events over comm. */

class CommFillRangeDetector : public FeFillRangeDetector {

/* Attributes for class CommFillRangeDetector */
	CONCRETE(CommFillRangeDetector)
	AUTO_GC(CommFillRangeDetector)
  public: /* creation */

	
	static RPTR(CommFillRangeDetector) make (
			APTR(PromiseManager) ARG(pm), 
			IntegerVar ARG(number), 
			APTR(FeEdition) ARG(target))
	;
	
  public: /* creation */

	
	CommFillRangeDetector (
			APTR(PromiseManager) ARG(pm), 
			IntegerVar ARG(number), 
			APTR(FeEdition) ARG(target))
	;
	
  public: /* triggering */

	/* Essential.  Some of the PlaceHolders in the Edition on 
	which I was placed have become something else. The Edition 
	has their new identies as its RangeElements, though the keys 
	may bear no relationship to those in the original Edition. */
	
	virtual void rangeFilled (APTR(FeEdition) ARG(newIdentities));
	
  private:
	CHKPTR(PromiseManager) myManager;
	IntegerVar myNumber;
	CHKPTR(FeEdition) myTarget;
};  /* end class CommFillRangeDetector */



/* ************************************************************************ *
 * 
 *                    Class CommRevisionDetector 
 *
 * ************************************************************************ */




	/* Send the detector events over comm. */

class CommRevisionDetector : public FeRevisionDetector {

/* Attributes for class CommRevisionDetector */
	CONCRETE(CommRevisionDetector)
	AUTO_GC(CommRevisionDetector)
  public: /* creation */

	
	static RPTR(CommRevisionDetector) make (
			APTR(PromiseManager) ARG(pm), 
			IntegerVar ARG(number), 
			APTR(FeWork) ARG(target))
	;
	
  public: /* creation */

	
	CommRevisionDetector (
			APTR(PromiseManager) ARG(pm), 
			IntegerVar ARG(number), 
			APTR(FeWork) ARG(target))
	;
	
  public: /* triggering */

	/* Essential. The Work has been revised. Gives the Work, the 
	current Edition, the 
		author ID who had it grabbed, the sequence number of the 
	revision to the 
		Work, and the clock time on the Server (note that the clock 
	time is only as 
		reliable as the Server's operating system, which is usually 
	not very). */
	
	virtual void revised (
			APTR(FeWork) ARG(work), 
			APTR(FeEdition) ARG(contents), 
			APTR(ID) ARG(author), 
			IntegerVar ARG(time), 
			IntegerVar ARG(sequence))
	;
	
  private:
	CHKPTR(PromiseManager) myManager;
	IntegerVar myNumber;
	CHKPTR(FeWork) myTarget;
};  /* end class CommRevisionDetector */



/* ************************************************************************ *
 * 
 *                    Class CommStatusDetector 
 *
 * ************************************************************************ */




	/* Send the detector events over comm. */

class CommStatusDetector : public FeStatusDetector {

/* Attributes for class CommStatusDetector */
	CONCRETE(CommStatusDetector)
	AUTO_GC(CommStatusDetector)
  public: /* creation */

	
	static RPTR(CommStatusDetector) make (
			APTR(PromiseManager) ARG(pm), 
			IntegerVar ARG(number), 
			APTR(FeWork) ARG(target))
	;
	
  public: /* creation */

	
	CommStatusDetector (
			APTR(PromiseManager) ARG(pm), 
			IntegerVar ARG(number), 
			APTR(FeWork) ARG(target))
	;
	
  public: /* triggering */

	/* Essential. The Work has been grabbed, or regrabbed. */
	
	virtual void grabbed (
			APTR(FeWork) ARG(work), 
			APTR(ID) ARG(author), 
			IntegerVar ARG(reason))
	;
	
	/* Essential. The revise capability of the Work has been lost. */
	
	virtual void released (APTR(FeWork) ARG(work), IntegerVar ARG(reason));
	
  private:
	CHKPTR(PromiseManager) myManager;
	IntegerVar myNumber;
	CHKPTR(FeWork) myTarget;
};  /* end class CommStatusDetector */



/* ************************************************************************ *
 * 
 *                    Class CommWaitDetector 
 *
 * ************************************************************************ */




	/* Send the detector events over comm. */

class CommWaitDetector : public FeWaitDetector {

/* Attributes for class CommWaitDetector */
	CONCRETE(CommWaitDetector)
	AUTO_GC(CommWaitDetector)
  public: /* creation */

	
	static RPTR(CommWaitDetector) make (APTR(PromiseManager) ARG(pm), IntegerVar ARG(number));
	
  public: /* creation */

	
	CommWaitDetector (APTR(PromiseManager) ARG(pm), IntegerVar ARG(number));
	
	
	virtual void destruct ();
	
  public: /* triggering */

	/* Essential.  Whatever I was waiting for has happened */
	
	virtual void done ();
	
  private:
	CHKPTR(PromiseManager) myManager;
	IntegerVar myNumber;
};  /* end class CommWaitDetector */



/* ************************************************************************ *
 * 
 *                    Class DetectorEvent 
 *
 * ************************************************************************ */




	/* The detectors for comm create these and queue them up 
	because they can only go out between requests. */

class DetectorEvent : public Heaper {

/* Attributes for class DetectorEvent */
	DEFERRED(DetectorEvent)
	AUTO_GC(DetectorEvent)
  public: /* accessing */

	
	virtual IntegerVar detector ();
	
	
	virtual RPTR(DetectorEvent) next ();
	
	
	virtual void setNext (APTR(DetectorEvent) ARG(event));
	
  public: /* triggering */

	/* Send the message across the wire. */
	
	virtual void trigger (APTR(PromiseManager) ARG(pm)) DEFERRED_SUBR;
	
  public: /* creation */

	
	DetectorEvent (IntegerVar ARG(detector), TCSJ);
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  private:
	CHKPTR(DetectorEvent) myNext;
	IntegerVar myDetector;
};  /* end class DetectorEvent */



#endif /* COMDTCTR_HXX */

