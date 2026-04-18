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

#ifndef OROOTX_HXX
#define OROOTX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef OROOTX_OXX
#include "orootx.oxx"
#endif /* OROOTX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */


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

#ifndef LOAVESX_OXX
#include "loavesx.oxx"
#endif /* LOAVESX_OXX */

#ifndef NKERNELX_OXX
#include "nkernelx.oxx"
#endif /* NKERNELX_OXX */

#ifndef OROOTP_OXX
#include "orootp.oxx"
#endif /* OROOTP_OXX */

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

#ifndef TABLESX_OXX
#include "tablesx.oxx"
#endif /* TABLESX_OXX */

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
 *                    Class OPart 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class OPart : public Abraham {

/* Attributes for class OPart */
	DEFERRED(OPart)
	SHEPHERD_ANCESTOR(OPart,Abraham)
	COPY(OPart,DiskCuisine)
	DEFERRED_LOCKED(OPart)
	AUTO_GC(OPart)
  public: /* backfollow */

	/* Attach the TrailBlazer to this Edition, and return the 
	region of partiality it is attached to */
	
	virtual RPTR(XnRegion) attachTrailBlazer (APTR(TrailBlazer) ARG(blazer)) DEFERRED_FUNC;
	
	/* Make sure that everyone below here that might have a 
	TrailBlazer, has the given one */
	
	virtual void checkTrailBlazer (APTR(TrailBlazer) ARG(blazer)) DEFERRED_SUBR;
	
	/* If there is a TrailBlazer somewhere below this Edition, 
	return one of them */
	
	virtual RPTR(TrailBlazer) OR(NULL) fetchTrailBlazer () DEFERRED_FUNC;
	
	
	virtual RPTR(HistoryCrum) hCrum () DEFERRED_FUNC;
	
  public: /* accessing */

	/* return the mapping into the domain space of the given trace */
	
	virtual RPTR(Mapping) mappingTo (APTR(TracePosition) ARG(trace), APTR(Mapping) ARG(initial));
	
	
	virtual NOLOCK RPTR(SensorCrum) sensorCrum ();
	
  protected: /* protected: delete */

	
	virtual void dismantle ();
	
  protected: /* protected: create */

	
	OPart (APTR(SensorCrum) OR(NULL) ARG(scrum), TCSJ);
	
	
	OPart (UInt32 ARG(hash), APTR(SensorCrum) OR(NULL) ARG(scrum));
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	CHKPTR(SensorCrum) mySensorCrum;
};  /* end class OPart */



/* ************************************************************************ *
 * 
 *                    Class   OrglRoot 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class OrglRoot : public OPart {

/* Attributes for class OrglRoot */
	DEFERRED(OrglRoot)
	SHEPHERD_PATRIARCH(OrglRoot,OPart)
	COPY(OrglRoot,DiskCuisine)
	DEFERRED_LOCKED(OrglRoot)
	AUTO_GC(OrglRoot)
  public: /* creation */

	/* create a new orgl root */
	/* This should definitely be cached!  We make them all the 
	time probably. */
	
	static RPTR(OrglRoot) make (APTR(CoordinateSpace) ARG(cs));
	
	
	static RPTR(OrglRoot) make (APTR(XnRegion) ARG(region));
	
	
	static RPTR(OrglRoot) make (
			APTR(XnRegion) ARG(keys), 
			APTR(OrderSpec) ARG(ordering), 
			APTR(PtrArray) OF1(FeRangeElement) ARG(values))
	;
	
	/* Make an Orgl from a bunch of Data. The data is 
		guaranteed to be of a reasonable size. */
	
	static RPTR(OrglRoot) makeData (APTR(PrimDataArray) ARG(values), APTR(Arrangement) ARG(arrangement));
	
	/* Make an Orgl from a bunch of Data. The data is 
		guaranteed to be of a reasonable size. */
	
	static RPTR(OrglRoot) makeData (
			APTR(XnRegion) ARG(keys), 
			APTR(OrderSpec) ARG(ordering), 
			APTR(PrimDataArray) ARG(values))
	;
	
  public: /* backfollow */

	
	virtual RPTR(XnRegion) attachTrailBlazer (APTR(TrailBlazer) ARG(blazer)) DEFERRED_FUNC;
	
	/* check any recorders that might be triggered by a change in 
	the stamp */
	
	virtual void checkRecorders (APTR(PropFinder) ARG(finder), APTR(SensorCrum) OR(NULL) ARG(scrum)) DEFERRED_SUBR;
	
	
	virtual void checkTrailBlazer (APTR(TrailBlazer) ARG(blazer)) DEFERRED_SUBR;
	
	
	virtual RPTR(TrailBlazer) OR(NULL) fetchTrailBlazer () DEFERRED_FUNC;
	
	/* NOTE: The AgendaItem returned is not yet scheduled.  Doing 
	so is up to my caller. */
	
	virtual RPTR(AgendaItem) propChanger (APTR(PropChange) ARG(change));
	
	/* A Detector has been added to my parent. Walk down and 
	trigger it on all non-partial stuff */
	
	virtual void triggerDetector (APTR(FeFillRangeDetector) ARG(detect)) DEFERRED_SUBR;
	
	/* Ensure the my bertCrum is not be leafward of newBCrum. */
	
	virtual BooleanVar updateBCrumTo (APTR(BertCrum) ARG(newBCrum));
	
  public: /* accessing */

	/* the kind of domain elements allowed */
	
	virtual RPTR(CoordinateSpace) coordinateSpace () DEFERRED_FUNC;
	
	
	virtual IntegerVar count () DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) domain () DEFERRED_FUNC;
	
	/* get an individual element */
	
	virtual RPTR(FeRangeElement) OR(NULL) fetch (APTR(Position) ARG(key), APTR(BeEdition) ARG(edition)) DEFERRED_FUNC;
	
	/* Get or Make the BeRangeElement at the location. */
	
	virtual RPTR(BeRangeElement) getBe (APTR(Position) ARG(key)) DEFERRED_FUNC;
	
	
	virtual NOLOCK RPTR(HistoryCrum) hCrum ();
	
	/* This is primarily for the example routines. */
	
	virtual RPTR(TracePosition) hCut ();
	
	
	virtual void introduceEdition (APTR(BeEdition) ARG(edition));
	
	
	virtual BooleanVar isEmpty () DEFERRED_FUNC;
	
	/* Just search for now. */
	
	virtual RPTR(XnRegion) keysLabelled (APTR(BeLabel) ARG(label)) DEFERRED_FUNC;
	
	/* return a mapping from my data to corresponding stuff in 
	the given trace */
	
	virtual RPTR(Mapping) mapSharedTo (APTR(TracePosition) ARG(trace)) DEFERRED_FUNC;
	
	/* Return the owner for the given position in the receiver. */
	
	virtual RPTR(ID) ownerAt (APTR(Position) ARG(key)) DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) rangeOwners (APTR(XnRegion) OR(NULL) ARG(positions)) DEFERRED_FUNC;
	
	
	virtual void removeEdition (APTR(BeEdition) ARG(stamp));
	
	/* Return the portiong whose owner couldn't be changed. */
	
	virtual RPTR(OrglRoot) setAllOwners (APTR(ID) ARG(owner)) DEFERRED_FUNC;
	
	/* Return a region for all the stuff in this orgl that can 
	backfollow to trace. */
	
	virtual RPTR(XnRegion) sharedRegion (APTR(TracePosition) ARG(trace)) DEFERRED_FUNC;
	
	/* Return a simple region that encloses the domain of the receiver. */
	
	virtual RPTR(XnRegion) simpleDomain () DEFERRED_FUNC;
	
	/* Return the owner for the given position in the receiver. */
	
	virtual RPTR(PrimSpec) specAt (APTR(Position) ARG(key)) DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) usedDomain () DEFERRED_FUNC;
	
  public: /* operations */

	/* Return a stepper of bundles according to the order. */
	
	virtual RPTR(Stepper) bundleStepper (APTR(XnRegion) ARG(region), APTR(OrderSpec) ARG(order)) DEFERRED_FUNC;
	
	
	virtual RPTR(OrglRoot) combine (APTR(OrglRoot) ARG(orgl)) DEFERRED_FUNC;
	
	
	virtual RPTR(OrglRoot) copy (APTR(XnRegion) ARG(externalRegion)) DEFERRED_FUNC;
	
	/* This does the 'now' part of setting up a recorder, once 
	the 'later' part has been set up.
		 It does a walk south on the O-tree, then walks back north 
	on all the H-trees, filtered by the Bert canopy. */
	
	virtual void delayedFindMatching (
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(ResultRecorder) ARG(recorder))
	 DEFERRED_SUBR;
	
	/* Go ahead and actually store the recorder in the sensor 
	canopy.  However, instead of propogating the props 
	immediately, accumulate all those agenda items into the 
	'agenda' parameter.  This is done instead of scheduling them 
	directly because our client needs to schedule something else 
	following all the prop propogation. */
	
	virtual void storeRecordingAgents (APTR(RecorderFossil) ARG(recorder), APTR(Agenda) ARG(agenda)) DEFERRED_SUBR;
	
	/* Return a copy with externalDsp added to the receiver's dsp. */
	
	virtual RPTR(OrglRoot) transformedBy (APTR(Dsp) ARG(externalDsp)) DEFERRED_FUNC;
	
	/* Return a copy with externalDsp removed from the receiver's dsp. */
	
	virtual RPTR(OrglRoot) unTransformedBy (APTR(Dsp) ARG(externalDsp)) DEFERRED_FUNC;
	
  protected: /* protected: */

	
	virtual void dismantle ();
	
  public: /* create */

	
	OrglRoot (APTR(SensorCrum) OR(NULL) ARG(scrum), TCSJ);
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	CHKPTR(HBottomCrum) myHCrum;
};  /* end class OrglRoot */



/* ************************************************************************ *
 * 
 *                    Class     ActualOrglRoot 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ActualOrglRoot : public OrglRoot {

/* Attributes for class ActualOrglRoot */
	CONCRETE(ActualOrglRoot)
	SHEPHERD_PATRIARCH(ActualOrglRoot,OrglRoot)
	COPY(ActualOrglRoot,DiskCuisine)
	LOCKED(ActualOrglRoot)
	AUTO_GC(ActualOrglRoot)
  public: /* creation */

	/* create a new orgl root */
	
	static RPTR(ActualOrglRoot) make (APTR(Loaf) ARG(loaf), APTR(XnRegion) ARG(region));
	
  public: /* backfollow */

	
	virtual RPTR(XnRegion) attachTrailBlazer (APTR(TrailBlazer) ARG(blazer));
	
	
	virtual void checkRecorders (APTR(PropFinder) ARG(finder), APTR(SensorCrum) OR(NULL) ARG(scrum));
	
	
	virtual void checkTrailBlazer (APTR(TrailBlazer) ARG(blazer));
	
	
	virtual void delayedFindMatching (
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(ResultRecorder) ARG(recorder))
	;
	
	
	virtual RPTR(TrailBlazer) OR(NULL) fetchTrailBlazer ();
	
	
	virtual void storeRecordingAgents (APTR(RecorderFossil) ARG(recorder), APTR(Agenda) ARG(agenda));
	
	
	virtual void triggerDetector (APTR(FeFillRangeDetector) ARG(detect));
	
	/* My bertCrum must not be leafward of newBCrum. 
		Thus it must be LE to newCrum. Otherwise correct it and recur. */
	
	virtual BooleanVar updateBCrumTo (APTR(BertCrum) ARG(newBCrum));
	
  public: /* accessing */

	/* the kind of domain elements allowed */
	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual IntegerVar count ();
	
	
	virtual RPTR(XnRegion) domain ();
	
	/* get an individual element */
	
	virtual RPTR(FeRangeElement) OR(NULL) fetch (APTR(Position) ARG(key), APTR(BeEdition) ARG(edition));
	
	
	virtual NOLOCK RPTR(Loaf) fullcrum ();
	
	/* Get or Make the BeRangeElement at the location. */
	/* Separate the position from the rest of the oplane with 
	copy.  Then instantiate it. */
	
	virtual RPTR(BeRangeElement) getBe (APTR(Position) ARG(key));
	
	/* ActualOrglRoots believe they have stuff beneath them. */
	
	virtual NOLOCK BooleanVar isEmpty ();
	
	/* Just search for now. */
	
	virtual RPTR(XnRegion) keysLabelled (APTR(BeLabel) ARG(label));
	
	/* return a mapping from my data to corresponding stuff in 
	the given trace */
	
	virtual RPTR(Mapping) mapSharedTo (APTR(TracePosition) ARG(trace));
	
	/* Return the owner for the given position in the receiver. */
	
	virtual RPTR(ID) ownerAt (APTR(Position) ARG(key));
	
	
	virtual RPTR(XnRegion) rangeOwners (APTR(XnRegion) OR(NULL) ARG(positions));
	
	/* Recur assigning owners.  Return the portion of the receiver that
		 couldn't be assigned. */
	
	virtual RPTR(OrglRoot) setAllOwners (APTR(ID) ARG(owner));
	
	/* Return a region for all the stuff in this orgl that can 
	backfollow to trace. */
	
	virtual RPTR(XnRegion) sharedRegion (APTR(TracePosition) ARG(trace));
	
	
	virtual NOLOCK RPTR(XnRegion) simpleDomain ();
	
	/* Return the owner for the given position in the receiver. */
	
	virtual RPTR(PrimSpec) specAt (APTR(Position) ARG(key));
	
	/* Change the identities of the RangeElements of this Edition 
	to those at the same key in the other Edition. The left piece 
	of the result contains those object which are know to not be 
	able to become, because of
			- lack of ownership authority
			- different contents
			- incompatible types
			- no corresponding new identity
		The right piece of the result is NULL if there is nothing 
	more that might be done, or else the remainder of the 
	receiver on which we might be able to proceed. This material 
	might fail at a later time because of any of the reasons 
	above; or it might succeed , even though it failed this time because of
			- synchronization problem
			- just didn't feel like it
		This is always required to make progress if it can, although 
	it isn't required to make all the progress that it might. 
	Returns right=NULL when it can't make further progress. */
	
	virtual RPTR(Pair) OF1(OrglRoot) tryAllBecome (APTR(OrglRoot) ARG(other));
	
	
	virtual RPTR(XnRegion) usedDomain ();
	
  public: /* operations */

	/* Return a stepper of bundles according to the order. */
	
	virtual RPTR(Stepper) bundleStepper (APTR(XnRegion) ARG(region), APTR(OrderSpec) ARG(order));
	
	
	virtual RPTR(OrglRoot) combine (APTR(OrglRoot) ARG(another));
	
	/* Copy out each simple region and then combine them. */
	
	virtual RPTR(OrglRoot) copy (APTR(XnRegion) ARG(region));
	
	/* region must be a valid thing to store as a split. */
	
	virtual RPTR(OrglRoot) copyDistinction (APTR(XnRegion) ARG(region));
	
	/* simpleRegion must be simple!  Copy out each distinction. */
	
	virtual RPTR(OrglRoot) copySimple (APTR(XnRegion) ARG(simpleRegion));
	
	
	virtual void fill (
			APTR(XnRegion) ARG(keys), 
			APTR(Arrangement) ARG(toArrange), 
			APTR(PrimDataArray) ARG(toArray), 
			APTR(Dsp) ARG(dsp), 
			APTR(BeEdition) ARG(edition))
	;
	
	
	virtual RPTR(ActualOrglRoot) makeNew (
			APTR(XnRegion) ARG(newSplit), 
			APTR(ActualOrglRoot) ARG(newIn), 
			APTR(ActualOrglRoot) ARG(newOut))
	;
	
	/* Return a copy with externalDsp added to the receiver's dsp. */
	
	virtual RPTR(OrglRoot) transformedBy (APTR(Dsp) ARG(externalDsp));
	
	/* Return a copy with externalDsp removed from the receiver's dsp. */
	
	virtual RPTR(OrglRoot) unTransformedBy (APTR(Dsp) ARG(externalDsp));
	
  public: /* create */

	
	ActualOrglRoot (APTR(Loaf) ARG(fullcrum), APTR(XnRegion) ARG(region));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
  private: /* private: */

	
	virtual RPTR(ActualOrglRoot) OR(NULL) fetchEasyCombine (APTR(ActualOrglRoot) ARG(another));
	
	/* Splay a region into its own subtree as close as possible 
	to the root */
	
	virtual UInt8 splay (APTR(XnRegion) ARG(region));
	
  protected: /* protected: delete */

	
	virtual void dismantle ();
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	CHKPTR(Loaf) myO;
	CHKPTR(XnRegion) myRegion;
};  /* end class ActualOrglRoot */



/* ************************************************************************ *
 * 
 *                    Class     EmptyOrglRoot 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class EmptyOrglRoot : public OrglRoot {

/* Attributes for class EmptyOrglRoot */
	CONCRETE(EmptyOrglRoot)
	SHEPHERD_PATRIARCH(EmptyOrglRoot,OrglRoot)
	COPY(EmptyOrglRoot,DiskCuisine)
	LOCKED(EmptyOrglRoot)
	AUTO_GC(EmptyOrglRoot)
  public: /* backfollow */

	
	virtual RPTR(XnRegion) attachTrailBlazer (APTR(TrailBlazer) ARG(blazer));
	
	
	virtual NOLOCK void checkRecorders (APTR(PropFinder) ARG(finder), APTR(SensorCrum) OR(NULL) ARG(scrum));
	
	
	virtual void checkTrailBlazer (APTR(TrailBlazer) ARG(blazer));
	
	
	virtual NOLOCK void delayedFindMatching (
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(ResultRecorder) ARG(recorder))
	;
	
	
	virtual NOLOCK RPTR(TrailBlazer) OR(NULL) fetchTrailBlazer ();
	
	
	virtual NOLOCK void storeRecordingAgents (APTR(RecorderFossil) ARG(recorder), APTR(Agenda) ARG(agenda));
	
	
	virtual NOLOCK void triggerDetector (APTR(FeFillRangeDetector) ARG(detect));
	
  public: /* accessing */

	/* the kind of domain elements allowed */
	
	virtual NOLOCK RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual NOLOCK IntegerVar count ();
	
	
	virtual RPTR(XnRegion) domain ();
	
	
	virtual NOLOCK RPTR(FeRangeElement) OR(NULL) fetch (APTR(Position) ARG(key), APTR(BeEdition) ARG(edition));
	
	/* Get or Make the BeRangeElement at the location. */
	
	virtual RPTR(BeRangeElement) getBe (APTR(Position) ARG(key));
	
	
	virtual NOLOCK BooleanVar isEmpty ();
	
	/* Just search for now. */
	
	virtual RPTR(XnRegion) keysLabelled (APTR(BeLabel) ARG(label));
	
	/* return a mapping from my data to corresponding stuff in 
	the given trace */
	
	virtual RPTR(Mapping) mapSharedTo (APTR(TracePosition) ARG(trace));
	
	/* Return the owner for the given position in the receiver. */
	
	virtual RPTR(ID) ownerAt (APTR(Position) ARG(key));
	
	
	virtual RPTR(XnRegion) rangeOwners (APTR(XnRegion) OR(NULL) ARG(positions));
	
	/* There aren't any contents, so just return self. */
	
	virtual NOLOCK RPTR(OrglRoot) setAllOwners (APTR(ID) ARG(owner));
	
	/* I have no contents, so I can't shared anything. */
	
	virtual RPTR(XnRegion) sharedRegion (APTR(TracePosition) ARG(trace));
	
	/* Return a simple region that encloses the domain of the receiver. */
	
	virtual RPTR(XnRegion) simpleDomain ();
	
	/* Return the owner for the given position in the receiver. */
	
	virtual RPTR(PrimSpec) specAt (APTR(Position) ARG(key));
	
	
	virtual RPTR(XnRegion) usedDomain ();
	
  public: /* operations */

	/* Return a stepper of bundles according to the order. */
	
	virtual RPTR(Stepper) bundleStepper (APTR(XnRegion) ARG(region), APTR(OrderSpec) ARG(order));
	
	
	virtual NOLOCK RPTR(OrglRoot) combine (APTR(OrglRoot) ARG(orgl));
	
	
	virtual NOLOCK RPTR(OrglRoot) copy (APTR(XnRegion) ARG(externalRegion));
	
	/* Return a copy with externalDsp added to the receiver's dsp. */
	
	virtual NOLOCK RPTR(OrglRoot) transformedBy (APTR(Dsp) ARG(externalDsp));
	
	/* Return a copy with externalDsp removed from the receiver's dsp. */
	
	virtual NOLOCK RPTR(OrglRoot) unTransformedBy (APTR(Dsp) ARG(externalDsp));
	
  public: /* create */

	
	EmptyOrglRoot (APTR(CoordinateSpace) ARG(cs), TCSJ);
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	CHKPTR(CoordinateSpace) myCS;
	friend class OrglRoot;
};  /* end class EmptyOrglRoot */



#endif /* OROOTX_HXX */

