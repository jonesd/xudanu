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

#ifndef LOAVESX_HXX
#define LOAVESX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef LOAVESX_OXX
#include "loavesx.oxx"
#endif /* LOAVESX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef OROOTX_HXX
#include "orootx.hxx"
#endif /* OROOTX_HXX */


#ifndef BRANGE1X_OXX
#include "brange1x.oxx"
#endif /* BRANGE1X_OXX */

#ifndef BRANGE3X_OXX
#include "brange3x.oxx"
#endif /* BRANGE3X_OXX */

#ifndef CANOPYX_OXX
#include "canopyx.oxx"
#endif /* CANOPYX_OXX */

#ifndef DETECTX_OXX
#include "detectx.oxx"
#endif /* DETECTX_OXX */

#ifndef HTREEX_OXX
#include "htreex.oxx"
#endif /* HTREEX_OXX */

#ifndef IDX_OXX
#include "idx.oxx"
#endif /* IDX_OXX */

#ifndef NKERNELX_OXX
#include "nkernelx.oxx"
#endif /* NKERNELX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef PRIMVALX_OXX
#include "primvalx.oxx"
#endif /* PRIMVALX_OXX */

#ifndef PROPSX_OXX
#include "propsx.oxx"
#endif /* PROPSX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */

#ifndef TCLUDEX_OXX
#include "tcludex.oxx"
#endif /* TCLUDEX_OXX */

#ifndef TRACEPX_OXX
#include "tracepx.oxx"
#endif /* TRACEPX_OXX */

#ifndef TURTLEX_OXX
#include "turtlex.oxx"
#endif /* TURTLEX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class Loaf 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class Loaf : public OPart {

/* Attributes for class Loaf */
	DEFERRED(Loaf)
	SHEPHERD_PATRIARCH(Loaf,OPart)
	COPY(Loaf,DiskCuisine)
	DEFERRED_LOCKED(Loaf)
	AUTO_GC(Loaf)
  public: /* create */

	
	static RPTR(Loaf) make (APTR(XnRegion) ARG(region), APTR(BeCarrier) ARG(element));
	
	
	static RPTR(Loaf) make (APTR(XnRegion) ARG(region));
	
	
	static RPTR(Loaf) make (APTR(PrimDataArray) ARG(values), APTR(Arrangement) ARG(arrangement));
	
  public: /* accessing */

	/* return a mapping from my data to corresponding stuff in 
	the given trace */
	
	virtual RPTR(Mapping) compare (APTR(TracePosition) ARG(trace), APTR(XnRegion) ARG(region)) DEFERRED_FUNC;
	
	
	virtual IntegerVar count () DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) domain () DEFERRED_FUNC;
	
	/* Look up the range element for the key.  If it is embedded 
	within a virtual
		 structure, then make a virtual range element using the 
	edition and globalKey. */
	
	virtual RPTR(FeRangeElement) OR(NULL) fetch (
			APTR(Position) ARG(key), 
			APTR(BeEdition) ARG(edition), 
			APTR(Position) ARG(globalKey))
	 DEFERRED_FUNC;
	
	/* Return the bottom-most Loaf.  Used to get the owner and 
	such of a position. */
	
	virtual RPTR(OExpandingLoaf) fetchBottomAt (APTR(Position) ARG(key)) DEFERRED_FUNC;
	
	/* Fill an array with my contents */
	
	virtual void fill (
			APTR(XnRegion) ARG(keys), 
			APTR(Arrangement) ARG(toArrange), 
			APTR(PrimArray) ARG(toArray), 
			APTR(Dsp) ARG(globalDsp), 
			APTR(BeEdition) ARG(edition))
	 DEFERRED_SUBR;
	
	/* Get or Make the BeRangeElement at the location. */
	
	virtual RPTR(BeRangeElement) getBe (APTR(Position) ARG(key)) DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) rangeOwners (APTR(XnRegion) OR(NULL) ARG(positions)) DEFERRED_FUNC;
	
	/* Recur assigning owners.  Return the portion of the o-tree that
		 couldn't be assigned, or NULL if it was all assigned. */
	
	virtual RPTR(OrglRoot) setAllOwners (APTR(ID) ARG(owner)) DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) usedDomain () DEFERRED_FUNC;
	
  public: /* operations */

	/* Return a stepper of bundles according to the order. */
	
	virtual RPTR(Stepper) bundleStepper (
			APTR(XnRegion) ARG(region), 
			APTR(OrderSpec) ARG(order), 
			APTR(Dsp) ARG(globalDsp))
	 DEFERRED_FUNC;
	
	
	virtual RPTR(OrglRoot) combine (
			APTR(ActualOrglRoot) ARG(another), 
			APTR(XnRegion) ARG(limitRegion), 
			APTR(Dsp) ARG(globalDsp))
	 DEFERRED_FUNC;
	
	/* Just search for now. */
	
	virtual RPTR(XnRegion) keysLabelled (APTR(BeLabel) ARG(label)) DEFERRED_FUNC;
	
	/* Return a region describing the stuff that can backfollow 
	to trace. */
	
	virtual RPTR(XnRegion) sharedRegion (APTR(TracePosition) ARG(trace), APTR(XnRegion) ARG(limitRegion)) DEFERRED_FUNC;
	
	/* Return a copy with externalDsp added to the receiver's dsp. */
	
	virtual RPTR(Loaf) transformedBy (APTR(Dsp) ARG(externalDsp));
	
	/* Return a copy with globalDsp removed from the receiver's dsp. */
	
	virtual RPTR(Loaf) unTransformedBy (APTR(Dsp) ARG(globalDsp));
	
  public: /* splay */

	/* Make each child completely contained or completely outside 
		the region. Return the number of children completely in the region. 
		Full containment cases can be handled generically. */
	
	virtual UInt8 splay (APTR(XnRegion) ARG(region), APTR(XnRegion) ARG(limitRegion));
	
  protected: /* protected: splay */

	/* Speciall handle the splay cases in which the region 
	partially intersects
		 with limitedRegion.  These require rotations and splitting. */
	
	virtual Int8 actualSplay (APTR(XnRegion) ARG(region), APTR(XnRegion) ARG(limitRegion)) DEFERRED_FUNC;
	
  public: /* backfollow */

	/* This should probably take a bertCanopyCrum argument, as well. */
	/* add oParent to the set of upward pointers. */
	
	virtual void addOParent (APTR(OPart) ARG(oParent));
	
	
	virtual RPTR(XnRegion) attachTrailBlazer (APTR(TrailBlazer) ARG(blazer)) DEFERRED_FUNC;
	
	/* send checkRecorders to all children */
	
	virtual void checkChildRecorders (APTR(PropFinder) ARG(finder)) DEFERRED_SUBR;
	
	/* check any recorders that might be triggered by a change in 
	the edition.
		 Walk leafward on O-plane, filtered by sensor canopy, 
	ringing recorders.
		 
		 Not in a consistent block:  It spawns unbounded work.  */
	
	virtual void checkRecorders (APTR(PropFinder) ARG(finder), APTR(SensorCrum) OR(NULL) ARG(scrum));
	
	
	virtual void checkTrailBlazer (APTR(TrailBlazer) ARG(blazer)) DEFERRED_SUBR;
	
	/* One step of walk south on the O-tree during the 'now' part 
	of a backfollow. */
	
	virtual void delayedStoreMatching (
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(ResultRecorder) ARG(recorder), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	 DEFERRED_SUBR;
	
	
	virtual RPTR(TrailBlazer) OR(NULL) fetchTrailBlazer () DEFERRED_FUNC;
	
	
	virtual NOLOCK RPTR(HistoryCrum) hCrum ();
	
	/* remove oparent from the set of upward pointers. */
	
	virtual void removeOParent (APTR(OPart) ARG(oparent));
	
	/* Go ahead and actually store the recorder in the sensor 
	canopy.  However, instead of propogating the props 
	immediately, accumulate all those agenda items into the 
	'agenda' parameter.  This is done instead of scheduling them 
	directly because our client needs to schedule something else 
	following all the prop propogation. */
	
	virtual void storeRecordingAgents (APTR(RecorderFossil) ARG(recorder), APTR(Agenda) ARG(agenda)) DEFERRED_SUBR;
	
	/* A Detector has been added to my parent. Walk down and 
	trigger it on all non-partial stuff */
	
	virtual void triggerDetector (APTR(FeFillRangeDetector) ARG(detect)) DEFERRED_SUBR;
	
	/* Ensure the my bertCrum is not be leafward of newBCrum. */
	
	virtual BooleanVar updateBCrumTo (APTR(BertCrum) ARG(newBCrum));
	
  protected: /* protected: */

	/* Make a FeEdition out of myself. Used for triggering Detectors */
	
	virtual RPTR(FeEdition) asFeEdition ();
	
	
	virtual void dismantle ();
	
  public: /* create */

	
	Loaf (APTR(HUpperCrum) OR(NULL) ARG(hcrum), APTR(SensorCrum) OR(NULL) ARG(scrum));
	
	
	Loaf (
			UInt32 ARG(hash), 
			APTR(HUpperCrum) OR(NULL) ARG(hcrum), 
			APTR(SensorCrum) OR(NULL) ARG(scrum))
	;
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	CHKPTR(HUpperCrum) myHCrum;
};  /* end class Loaf */



/* ************************************************************************ *
 * 
 *                    Class   InnerLoaf 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class InnerLoaf : public Loaf {

/* Attributes for class InnerLoaf */
	DEFERRED(InnerLoaf)
	SHEPHERD_ANCESTOR(InnerLoaf,Loaf)
	COPY(InnerLoaf,DiskCuisine)
	DEFERRED_LOCKED(InnerLoaf)
	NO_GC(InnerLoaf)
  public: /* create */

	/* Make a loaf that transforms the contents of newO. */
	
	static RPTR(InnerLoaf) make (APTR(Loaf) ARG(newO), APTR(Dsp) ARG(dsp));
	
	/* The contents of newIn must be completely contained in newSplit. 
		 newOut must be completely outside newSplit.  Should this just 
		 forward to make:with:with:with:?  This should extract shared dsp 
		 from newIn and newOut. */
	
	static RPTR(InnerLoaf) make (
			APTR(XnRegion) ARG(newSplit), 
			APTR(Loaf) ARG(newIn), 
			APTR(Loaf) ARG(newOut))
	;
	
	/* The contents of newIn must be completely contained in newSplit. 
		 newOut must be completely outside newSplit */
	
	static RPTR(InnerLoaf) make (
			APTR(XnRegion) ARG(newSplit), 
			APTR(Loaf) ARG(newIn), 
			APTR(Loaf) ARG(newOut), 
			APTR(HUpperCrum) ARG(hcrum))
	;
	
  public: /* create */

	
	InnerLoaf (APTR(HUpperCrum) ARG(hcrum), APTR(SensorCrum) ARG(scrum));
	
	
	InnerLoaf (
			UInt32 ARG(hash), 
			APTR(HUpperCrum) ARG(hcrum), 
			APTR(SensorCrum) ARG(scrum))
	;
	
  protected: /* protected: splay */

	/* Special handle the splay cases in which the region 
	partially intersects
		 with limitedRegion.  These require rotations and splitting. */
	
	virtual Int8 actualSplay (APTR(XnRegion) ARG(region), APTR(XnRegion) ARG(limitRegion)) DEFERRED_FUNC;
	
  public: /* accessing */

	/* return a mapping from my data to corresponding stuff in 
	the given trace */
	
	virtual RPTR(Mapping) compare (APTR(TracePosition) ARG(trace), APTR(XnRegion) ARG(region)) DEFERRED_FUNC;
	
	
	virtual IntegerVar count () DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) domain () DEFERRED_FUNC;
	
	
	virtual RPTR(FeRangeElement) OR(NULL) fetch (
			APTR(Position) ARG(key), 
			APTR(BeEdition) ARG(edition), 
			APTR(Position) ARG(globalKey))
	 DEFERRED_FUNC;
	
	/* Return the bottom-most Loaf.  Used to get the owner and 
	such of a position. */
	
	virtual RPTR(OExpandingLoaf) fetchBottomAt (APTR(Position) ARG(key)) DEFERRED_FUNC;
	
	
	virtual void fill (
			APTR(XnRegion) ARG(keys), 
			APTR(Arrangement) ARG(toArrange), 
			APTR(PrimArray) ARG(toArray), 
			APTR(Dsp) ARG(globalDsp), 
			APTR(BeEdition) ARG(edition))
	 DEFERRED_SUBR;
	
	/* Get or Make the BeRangeElement at the location. */
	
	virtual RPTR(BeRangeElement) getBe (APTR(Position) ARG(key)) DEFERRED_FUNC;
	
	/* This is used by the splay algorithms. */
	
	virtual RPTR(Loaf) inPart () DEFERRED_FUNC;
	
	/* This is used by the splay algorithms. */
	
	virtual RPTR(Loaf) outPart () DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) rangeOwners (APTR(XnRegion) OR(NULL) ARG(positions)) DEFERRED_FUNC;
	
	/* Recur assigning owners.  Return the portion of the o-tree that
		 couldn't be assigned, or NULL if it was all assigned. */
	
	virtual RPTR(OrglRoot) setAllOwners (APTR(ID) ARG(owner)) DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) usedDomain () DEFERRED_FUNC;
	
  public: /* backfollow */

	
	virtual RPTR(XnRegion) attachTrailBlazer (APTR(TrailBlazer) ARG(blazer)) DEFERRED_FUNC;
	
	
	virtual void checkChildRecorders (APTR(PropFinder) ARG(finder)) DEFERRED_SUBR;
	
	
	virtual void checkTrailBlazer (APTR(TrailBlazer) ARG(blazer)) DEFERRED_SUBR;
	
	/* Inner loaf:  Just forward south to all children. */
	
	virtual void delayedStoreMatching (
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(ResultRecorder) ARG(recorder), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	 DEFERRED_SUBR;
	
	
	virtual RPTR(TrailBlazer) OR(NULL) fetchTrailBlazer () DEFERRED_FUNC;
	
	
	virtual void storeRecordingAgents (APTR(RecorderFossil) ARG(recorder), APTR(Agenda) ARG(agenda)) DEFERRED_SUBR;
	
	
	virtual void triggerDetector (APTR(FeFillRangeDetector) ARG(detect)) DEFERRED_SUBR;
	
  public: /* operations */

	/* Return a stepper of bundles according to the order. */
	
	virtual RPTR(Stepper) bundleStepper (
			APTR(XnRegion) ARG(region), 
			APTR(OrderSpec) ARG(order), 
			APTR(Dsp) ARG(globalDsp))
	 DEFERRED_FUNC;
	
	
	virtual RPTR(OrglRoot) combine (
			APTR(ActualOrglRoot) ARG(another), 
			APTR(XnRegion) ARG(limitRegion), 
			APTR(Dsp) ARG(globalDsp))
	 DEFERRED_FUNC;
	
	/* Just search for now. */
	
	virtual RPTR(XnRegion) keysLabelled (APTR(BeLabel) ARG(label)) DEFERRED_FUNC;
	
	/* Return a region describing the stuff that can backfollow 
	to trace. */
	
	virtual RPTR(XnRegion) sharedRegion (APTR(TracePosition) ARG(trace), APTR(XnRegion) ARG(limitRegion)) DEFERRED_FUNC;
	

	friend class Loaf;
	friend class Loaf;
};  /* end class InnerLoaf */



/* ************************************************************************ *
 * 
 *                    Class   OExpandingLoaf 
 *
 * ************************************************************************ */




	/*  NOT.A.TYPE */

class OExpandingLoaf : public Loaf {

/* Attributes for class OExpandingLoaf */
	DEFERRED(OExpandingLoaf)
	SHEPHERD_ANCESTOR(OExpandingLoaf,Loaf)
	COPY(OExpandingLoaf,DiskCuisine)
	DEFERRED_LOCKED(OExpandingLoaf)
	MAY_BECOME(OExpandingLoaf,SplitLoaf)
	AUTO_GC(OExpandingLoaf)
  public: /* operations */

	/* Return a stepper of bundles according to the order. */
	
	virtual RPTR(Stepper) bundleStepper (
			APTR(XnRegion) ARG(region), 
			APTR(OrderSpec) ARG(order), 
			APTR(Dsp) ARG(globalDsp))
	 DEFERRED_FUNC;
	
	/* Accumulate dsp downward. */
	
	virtual RPTR(OrglRoot) combine (
			APTR(ActualOrglRoot) ARG(another), 
			APTR(XnRegion) ARG(limitRegion), 
			APTR(Dsp) ARG(globalDsp))
	;
	
	
	virtual void informTo (APTR(OrglRoot) ARG(orgl));
	
	
	virtual NOLOCK BooleanVar isPartial ();
	
	/* Make each child completely contained or completely outside 
		the region. Return the number of children completely in the region. 
		Handle the containment cases using myRegion. */
	
	virtual UInt8 splay (APTR(XnRegion) ARG(region), APTR(XnRegion) ARG(limitRegion));
	
  public: /* backfollow */

	
	virtual RPTR(XnRegion) attachTrailBlazer (APTR(TrailBlazer) ARG(blazer)) DEFERRED_FUNC;
	
	/* send checkRecorders to all children */
	
	virtual NOLOCK void checkChildRecorders (APTR(PropFinder) ARG(finder));
	
	
	virtual void checkTrailBlazer (APTR(TrailBlazer) ARG(blazer)) DEFERRED_SUBR;
	
	/* Default south-to-north turnaround point during 'now' part 
	of backfollow (which is leafward, then rootward, in the 
	H-tree, filtered by the Bert canopy).  (Sometimes overridden).
		(OExpandingLoaf is the supercalss of all O-tree leaf types.) */
	
	virtual void delayedStoreMatching (
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(ResultRecorder) ARG(recorder), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	;
	
	
	virtual RPTR(TrailBlazer) OR(NULL) fetchTrailBlazer () DEFERRED_FUNC;
	
	
	virtual void storeRecordingAgents (APTR(RecorderFossil) ARG(recorder), APTR(Agenda) ARG(agenda));
	
	
	virtual void triggerDetector (APTR(FeFillRangeDetector) ARG(detect)) DEFERRED_SUBR;
	
  public: /* accessing */

	/* return a mapping from my data to corresponding stuff in 
	the given trace */
	
	virtual RPTR(Mapping) compare (APTR(TracePosition) ARG(trace), APTR(XnRegion) ARG(region));
	
	
	virtual IntegerVar count ();
	
	
	virtual NOLOCK RPTR(XnRegion) domain ();
	
	
	virtual RPTR(FeRangeElement) OR(NULL) fetch (
			APTR(Position) ARG(key), 
			APTR(BeEdition) ARG(edition), 
			APTR(Position) ARG(globalKey))
	 DEFERRED_FUNC;
	
	/* I'm at the bottom. */
	
	virtual NOLOCK RPTR(OExpandingLoaf) fetchBottomAt (APTR(Position) ARG(key));
	
	/* Fill an array with my contents */
	
	virtual void fill (
			APTR(XnRegion) ARG(keys), 
			APTR(Arrangement) ARG(toArrange), 
			APTR(PrimArray) ARG(toArray), 
			APTR(Dsp) ARG(globalDsp), 
			APTR(BeEdition) ARG(edition))
	 DEFERRED_SUBR;
	
	/* Get or Make the BeRangeElement at the location. */
	
	virtual RPTR(BeRangeElement) getBe (APTR(Position) ARG(key)) DEFERRED_FUNC;
	
	/* This gets overridden by RegionLoaf. */
	
	virtual RPTR(XnRegion) keysLabelled (APTR(BeLabel) ARG(label));
	
	/* Return the owner of the atoms represented by the receiver. */
	
	virtual RPTR(ID) owner () DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) rangeOwners (APTR(XnRegion) OR(NULL) ARG(positions));
	
	/* If the CurrentKeyMaster includes the owner of this loaf
			then change the owner and return NULL
			else just return self. */
	
	virtual RPTR(OrglRoot) setAllOwners (APTR(ID) ARG(owner)) DEFERRED_FUNC;
	
	/* Return a region describing the stuff that can backfollow 
	to trace. */
	
	virtual RPTR(XnRegion) sharedRegion (APTR(TracePosition) ARG(trace), APTR(XnRegion) ARG(limitRegion));
	
	/* Return the PrimSpec that describes the representation of 
	the data. */
	
	virtual RPTR(PrimSpec) spec () DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) usedDomain () DEFERRED_FUNC;
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
  protected: /* protected: splay */

	/* Return an Inner loaf which is an expansion of me.  The 
	area in the region must go
		 into the leftCrum of my substitute, or the splay algorithm 
	will fail!  implementations
		 must call diskUpdate. */
	
	virtual Int8 actualSplay (APTR(XnRegion) ARG(region), APTR(XnRegion) ARG(limitRegion)) DEFERRED_FUNC;
	
  public: /* create */

	
	OExpandingLoaf (APTR(XnRegion) ARG(region), TCSJ);
	
	
	OExpandingLoaf (
			APTR(XnRegion) ARG(region), 
			APTR(HUpperCrum) OR(NULL) ARG(hcrum), 
			APTR(SensorCrum) ARG(sensor))
	;
	
	
	OExpandingLoaf (
			UInt32 ARG(hash), 
			APTR(XnRegion) ARG(region), 
			APTR(HUpperCrum) ARG(hcrum), 
			APTR(SensorCrum) ARG(sensor))
	;
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	CHKPTR(XnRegion) myRegion;
	friend class Loaf;
	friend class Loaf;
};  /* end class OExpandingLoaf */



#endif /* LOAVESX_HXX */

