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

#ifndef EDGEP_HXX
#define EDGEP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef EDGEP_OXX
#include "edgep.oxx"
#endif /* EDGEP_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */


#ifndef CACHEX_OXX
#include "cachex.oxx"
#endif /* CACHEX_OXX */

#ifndef EDGER_OXX
#include "edger.oxx"
#endif /* EDGER_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class EdgeAccumulator 
 *
 * ************************************************************************ */



/* Initializers for EdgeAccumulator */







	/* NO CLASS COMMENT */

class EdgeAccumulator : public Accumulator {

/* Attributes for class EdgeAccumulator */
	CONCRETE(EdgeAccumulator)
	COPY(EdgeAccumulator,XppCuisine)
	AUTO_GC(EdgeAccumulator)

/* Initializers for EdgeAccumulator */



friend class INIT_TIME_NAME(EdgeAccumulator,initTimeNonInherited);

  public: /* create */

	
	static RPTR(EdgeAccumulator) make (APTR(EdgeManager) ARG(manager), BooleanVar ARG(startsInside));
	
  protected: /* protected: create */

	
	EdgeAccumulator (APTR(EdgeManager) ARG(manager), BooleanVar ARG(startsInside));
	
	
	EdgeAccumulator (
			APTR(EdgeManager) ARG(manager), 
			BooleanVar ARG(startsInside), 
			APTR(PtrArray) OF1(TransitionEdge) ARG(edges), 
			Int32 ARG(index), 
			APTR(TransitionEdge) ARG(pending))
	;
	
  public: /* creation */

	
	virtual RPTR(Accumulator) copy ();
	
	
	virtual void destroy ();
	
  public: /* operations */

	
	virtual void step (APTR(Heaper) ARG(someObj));
	
	
	virtual RPTR(Heaper) value ();
	
  public: /* edge operations */

	/* add a transition at the given position. doing it again cancels it */
	
	virtual void edge (APTR(TransitionEdge) ARG(x));
	
	/* add a whole bunch of edges at once, assuming that they are 
	sorted and there are no duplicates */
	/* do the first step manually in case it is the same as the 
	current edge
		then do all the rest without checking for repeats */
	
	virtual void edges (APTR(EdgeStepper) ARG(stepper));
	
	/* make a region out of the accumulated edges */
	
	virtual RPTR(XnRegion) region ();
	
  private: /* private: */

	/* Just store an edge into the array and increment the count */
	
	virtual void storeStep (APTR(TransitionEdge) ARG(edge));
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK void restartEdgeAccumulator (APTR(Rcvr) ARG(rcvr));
	
  private:
	CHKPTR(EdgeManager) myManager;
	BooleanVar myStartsInside;
	CHKPTR(PtrArray) OF1(TransitionEdge) myEdges;
	Int32 myIndex;
	CHKPTR(TransitionEdge) myPending;
	NOCOPY BooleanVar myResultGiven;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(InstanceCache) SomeAccumulators;
};  /* end class EdgeAccumulator */



/* ************************************************************************ *
 * 
 *                    Class EdgeSimpleRegionStepper 
 *
 * ************************************************************************ */




	/* Consider this a "protected" class.  See class comment in 
	EdgeAccumulator */

class EdgeSimpleRegionStepper : public Stepper {

/* Attributes for class EdgeSimpleRegionStepper */
	CONCRETE(EdgeSimpleRegionStepper)
	AUTO_GC(EdgeSimpleRegionStepper)
  public: /* create */

	
	static RPTR(EdgeSimpleRegionStepper) make (APTR(EdgeManager) ARG(manager), APTR(EdgeStepper) ARG(edges));
	
  public: /* accessing */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
  protected: /* protected: create */

	
	EdgeSimpleRegionStepper (APTR(EdgeManager) ARG(manager), APTR(EdgeStepper) ARG(edges));
	
	
	EdgeSimpleRegionStepper (
			APTR(EdgeManager) ARG(manager), 
			APTR(EdgeStepper) OR(NULL) ARG(edges), 
			APTR(XnRegion) OR(NULL) ARG(simple))
	;
	
  private:
	CHKPTR(EdgeManager) myManager;
	CHKPTR(EdgeStepper) myEdges;
	CHKPTR(XnRegion) mySimple;
};  /* end class EdgeSimpleRegionStepper */



/* ************************************************************************ *
 * 
 *                    Class EdgeStepper 
 *
 * ************************************************************************ */



/* Initializers for EdgeStepper */







	/* A single instance of this class is cached.  To take 
	advantage of this, a method
	that uses EdgeSteppers should explicitly destroy at least one of them.
	Consider this a "protected" class.  See class comment in 
	EdgeAccumulator. */

class EdgeStepper : public Stepper {

/* Attributes for class EdgeStepper */
	CONCRETE(EdgeStepper)
	AUTO_GC(EdgeStepper)

/* Initializers for EdgeStepper */



friend class INIT_TIME_NAME(EdgeStepper,initTimeNonInherited);

  public: /* create */

	
	static RPTR(EdgeStepper) make (BooleanVar ARG(entering), APTR(PtrArray) OF1(TransitionEdge) ARG(edges));
	
	
	static RPTR(EdgeStepper) make (
			BooleanVar ARG(entering), 
			APTR(PtrArray) OF1(TransitionEdge) ARG(edges), 
			Int32 ARG(count))
	;
	
  public: /* accessing */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* edge accessing */

	
	virtual RPTR(TransitionEdge) OR(NULL) fetchEdge ();
	
	
	virtual RPTR(TransitionEdge) getEdge ();
	
	/* whether the current transition is entering or leaving the set */
	
	virtual BooleanVar isEntering ();
	
  protected: /* protected: create */

	
	EdgeStepper (
			BooleanVar ARG(entering), 
			APTR(PtrArray) OF1(TransitionEdge) ARG(edges), 
			Int32 ARG(count))
	;
	
	
	EdgeStepper (
			BooleanVar ARG(entering), 
			APTR(PtrArray) OF1(TransitionEdge) ARG(edges), 
			Int32 ARG(count), 
			Int32 ARG(index))
	;
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
  public: /* destroy */

	
	virtual void destroy ();
	
  private:
	BooleanVar myEntering;
	CHKPTR(PtrArray) OF1(TransitionEdge) myEdges;
	Int32 myEdgesCount;
	Int32 myIndex;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(InstanceCache) SomeEdgeSteppers;
};  /* end class EdgeStepper */



#endif /* EDGEP_HXX */

