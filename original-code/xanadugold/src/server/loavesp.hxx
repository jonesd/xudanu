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

#ifndef LOAVESP_HXX
#define LOAVESP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef LOAVESX_HXX
#include "loavesx.hxx"
#endif /* LOAVESX_HXX */

#ifndef LOAVESP_OXX
#include "loavesp.oxx"
#endif /* LOAVESP_OXX */


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

#ifndef FLKINFOX_OXX
#include "flkinfox.oxx"
#endif /* FLKINFOX_OXX */

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
 *                    Class DspLoaf 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class DspLoaf : public InnerLoaf {

/* Attributes for class DspLoaf */
	CONCRETE(DspLoaf)
	SHEPHERD_ANCESTOR(DspLoaf,InnerLoaf)
	COPY(DspLoaf,DiskCuisine)
	LOCKED(DspLoaf)
	NOT_A_TYPE(DspLoaf)
	AUTO_GC(DspLoaf)
  public: /* accessing */

	/* return a mapping from my data to corresponding stuff in 
	the given trace */
	
	virtual RPTR(Mapping) compare (APTR(TracePosition) ARG(trace), APTR(XnRegion) ARG(region));
	
	
	virtual IntegerVar count ();
	
	
	virtual RPTR(XnRegion) domain ();
	
	/* Look up the range element for the key.  If it is embedded 
	within a virtual
		 structure, then make a virtual range element using the 
	edition and globalKey. */
	
	virtual RPTR(FeRangeElement) OR(NULL) fetch (
			APTR(Position) ARG(key), 
			APTR(BeEdition) ARG(edition), 
			APTR(Position) ARG(globalKey))
	;
	
	/* Return the bottom-most Loaf.  Used to get the owner and 
	such of a position. */
	
	virtual RPTR(OExpandingLoaf) fetchBottomAt (APTR(Position) ARG(key));
	
	/* Make an FeRangeElement for each position. */
	
	virtual void fill (
			APTR(XnRegion) ARG(keys), 
			APTR(Arrangement) ARG(toArrange), 
			APTR(PrimArray) ARG(toArray), 
			APTR(Dsp) ARG(globalDsp), 
			APTR(BeEdition) ARG(edition))
	;
	
	/* Get or Make the BeRangeElement at the location. */
	
	virtual RPTR(BeRangeElement) getBe (APTR(Position) ARG(key));
	
	/* This is used by the splay algorithms. */
	
	virtual RPTR(Loaf) inPart ();
	
	/* return the mapping into the domain space of the given trace */
	
	virtual RPTR(Mapping) mappingTo (APTR(TracePosition) ARG(trace), APTR(Mapping) ARG(initial));
	
	/* This is used by the splay algorithms. */
	
	virtual RPTR(Loaf) outPart ();
	
	
	virtual RPTR(XnRegion) rangeOwners (APTR(XnRegion) OR(NULL) ARG(positions));
	
	/* Recur assigning owners.  Return the portion of the o-tree 
	that couldn't be assigned. */
	
	virtual RPTR(OrglRoot) setAllOwners (APTR(ID) ARG(owner));
	
	
	virtual RPTR(XnRegion) usedDomain ();
	
  protected: /* protected: splay */

	/* Make each child completely contained or completely outside
		 the region.  Return the number of children completely in 
	the region. */
	
	virtual Int8 actualSplay (APTR(XnRegion) ARG(region), APTR(XnRegion) ARG(limitRegion));
	
  public: /* operations */

	/* Return a stepper of bundles according to the order. */
	
	virtual RPTR(Stepper) bundleStepper (
			APTR(XnRegion) ARG(region), 
			APTR(OrderSpec) ARG(order), 
			APTR(Dsp) ARG(globalDsp))
	;
	
	/* Accumulate dsp downward. */
	
	virtual RPTR(OrglRoot) combine (
			APTR(ActualOrglRoot) ARG(another), 
			APTR(XnRegion) ARG(limitRegion), 
			APTR(Dsp) ARG(globalDsp))
	;
	
	/* Just search for now. */
	
	virtual RPTR(XnRegion) keysLabelled (APTR(BeLabel) ARG(label));
	
	/* Return a region describing the stuff that can backfollow 
	to trace. */
	
	virtual RPTR(XnRegion) sharedRegion (APTR(TracePosition) ARG(trace), APTR(XnRegion) ARG(limitRegion));
	
	/* Return a copy with externalDsp added to the receiver's dsp. */
	
	virtual RPTR(Loaf) transformedBy (APTR(Dsp) ARG(externalDsp));
	
	/* Return a copy with externalDsp removed from the receiver's dsp. */
	
	virtual RPTR(Loaf) unTransformedBy (APTR(Dsp) ARG(externalDsp));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
  public: /* backfollow */

	/* add oparent to the set of upward pointers and update the 
	bertCrums my child. */
	
	virtual void addOParent (APTR(OPart) ARG(oparent));
	
	
	virtual RPTR(XnRegion) attachTrailBlazer (APTR(TrailBlazer) ARG(blazer));
	
	/* send checkRecorders to all children */
	
	virtual void checkChildRecorders (APTR(PropFinder) ARG(finder));
	
	
	virtual void checkTrailBlazer (APTR(TrailBlazer) ARG(blazer));
	
	
	virtual void delayedStoreMatching (
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(ResultRecorder) ARG(recorder), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	;
	
	
	virtual RPTR(TrailBlazer) OR(NULL) fetchTrailBlazer ();
	
	
	virtual void storeRecordingAgents (APTR(RecorderFossil) ARG(recorder), APTR(Agenda) ARG(agenda));
	
	
	virtual void triggerDetector (APTR(FeFillRangeDetector) ARG(detect));
	
	/* My bertCrum must not be leafward of newBCrum. 
		Thus it must be LE to newCrum. Otherwise correct it and recur. */
	
	virtual BooleanVar updateBCrumTo (APTR(BertCrum) ARG(newBCrum));
	
  public: /* create */

	
	DspLoaf (APTR(Loaf) ARG(loaf), APTR(Dsp) ARG(dsp));
	
  protected: /* protected: delete */

	
	virtual void dismantle ();
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	CHKPTR(Dsp) myDsp;
	CHKPTR(Loaf) myO;
	friend class InnerLoaf;
	friend class Loaf;
};  /* end class DspLoaf */



/* ************************************************************************ *
 * 
 *                    Class OPartialLoaf 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class OPartialLoaf : public OExpandingLoaf {

/* Attributes for class OPartialLoaf */
	CONCRETE(OPartialLoaf)
	SHEPHERD_ANCESTOR(OPartialLoaf,OExpandingLoaf)
	NOT_A_TYPE(OPartialLoaf)
	COPY(OPartialLoaf,DiskCuisine)
	LOCKED(OPartialLoaf)
	MAY_BECOME(OPartialLoaf,RegionLoaf)
	AUTO_GC(OPartialLoaf)
  public: /* accessing */

	/* Make a virtual PlaceHolder. */
	
	virtual RPTR(FeRangeElement) OR(NULL) fetch (
			APTR(Position) ARG(key), 
			APTR(BeEdition) ARG(edition), 
			APTR(Position) ARG(globalKey))
	;
	
	/* Get or make the BeRangeElement at the location. */
	/* My region had better be just onto the key.
		 become a RegionLoaf onto a new BePlaceHolder */
	
	virtual RPTR(BeRangeElement) getBe (APTR(Position) ARG(key));
	
	/* Return the owner of the atoms represented by the receiver. */
	
	virtual NOLOCK RPTR(ID) owner ();
	
	/* Return the PrimSpec that describes the representation of 
	the data. */
	
	virtual RPTR(PrimSpec) spec ();
	
	
	virtual RPTR(XnRegion) usedDomain ();
	
  public: /* operations */

	/* Return a stepper of bundles according to the order. */
	
	virtual RPTR(Stepper) bundleStepper (
			APTR(XnRegion) ARG(region), 
			APTR(OrderSpec) ARG(order), 
			APTR(Dsp) ARG(globalDsp))
	;
	
	/* Make an FeRangeElement for each position. */
	
	virtual void fill (
			APTR(XnRegion) ARG(keys), 
			APTR(Arrangement) ARG(toArrange), 
			APTR(PrimArray) ARG(toArray), 
			APTR(Dsp) ARG(dsp), 
			APTR(BeEdition) ARG(edition))
	;
	
	
	virtual void informTo (APTR(OrglRoot) ARG(orgl));
	
	/* Partial crums are always partial. */
	
	virtual NOLOCK BooleanVar isPartial ();
	
	/* If the CurrentKeyMaster includes the owner of this loaf
			then change the owner and return NULL
			else just return self. */
	
	virtual RPTR(OrglRoot) setAllOwners (APTR(ID) ARG(owner));
	
  protected: /* protected: splay */

	/* Don't expand me in place.  Just move it closer to the top. */
	
	virtual NOLOCK Int8 actualSoftSplay (APTR(XnRegion) ARG(region), APTR(XnRegion) ARG(limitRegion));
	
	/* Expand my partial tree in place. The area in the region must go 
		into the leftCrum of my substitute, or the splay algorithm 
	will fail! */
	
	virtual Int8 actualSplay (APTR(XnRegion) ARG(region), APTR(XnRegion) ARG(limitRegion));
	
  public: /* create */

	
	OPartialLoaf (APTR(XnRegion) ARG(region), TCSJ);
	
	
	OPartialLoaf (
			APTR(XnRegion) ARG(region), 
			APTR(HUpperCrum) ARG(hcrum), 
			APTR(SensorCrum) ARG(scrum))
	;
	
	
	OPartialLoaf (
			APTR(XnRegion) ARG(region), 
			APTR(HUpperCrum) ARG(hcrum), 
			APTR(SensorCrum) ARG(scrum), 
			APTR(ID) ARG(owner), 
			APTR(TrailBlazer) OR(NULL) ARG(blazer))
	;
	
  protected: /* protected: delete */

	
	virtual void dismantle ();
	
  public: /* backfollow */

	
	virtual RPTR(XnRegion) attachTrailBlazer (APTR(TrailBlazer) ARG(blazer));
	
	
	virtual void checkTrailBlazer (APTR(TrailBlazer) ARG(blazer));
	
	
	virtual RPTR(TrailBlazer) OR(NULL) fetchTrailBlazer ();
	
	/* do nothing */
	
	virtual NOLOCK void triggerDetector (APTR(FeFillRangeDetector) ARG(detect));
	
  private:
	CHKPTR(ID) myOwner;
	CHKPTR(TrailBlazer) OR(NULL) myTrailBlazer;
	friend class Loaf;
};  /* end class OPartialLoaf */



/* ************************************************************************ *
 * 
 *                    Class OVirtualLoaf 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class OVirtualLoaf : public OExpandingLoaf {

/* Attributes for class OVirtualLoaf */
	CONCRETE(OVirtualLoaf)
	SHEPHERD_ANCESTOR(OVirtualLoaf,OExpandingLoaf)
	COPY(OVirtualLoaf,DiskCuisine)
	LOCKED(OVirtualLoaf)
	NOT_A_TYPE(OVirtualLoaf)
	AUTO_GC(OVirtualLoaf)
  public: /* accessing */

	/* Make a virtual DataHolder. */
	
	virtual RPTR(FeRangeElement) OR(NULL) fetch (
			APTR(Position) ARG(key), 
			APTR(BeEdition) ARG(edition), 
			APTR(Position) ARG(globalKey))
	;
	
	/* Get or make the BeRangeElement at the location. */
	/* My region had better be just onto the key.
		 become a RegionLoaf onto a new BeDataHolder containing the 
		 data extracted from my SharedData object. */
	
	virtual RPTR(BeRangeElement) getBe (APTR(Position) ARG(key));
	
	/* Return the owner of the atoms represented by the receiver. */
	
	virtual NOLOCK RPTR(ID) owner ();
	
	/* Return the primSpec for my data. */
	
	virtual RPTR(PrimSpec) spec ();
	
	
	virtual RPTR(XnRegion) usedDomain ();
	
  public: /* operations */

	/* Return a stepper of bundles according to the order. */
	
	virtual RPTR(Stepper) bundleStepper (
			APTR(XnRegion) ARG(region), 
			APTR(OrderSpec) ARG(order), 
			APTR(Dsp) ARG(globalDsp))
	;
	
	
	virtual void fill (
			APTR(XnRegion) ARG(keys), 
			APTR(Arrangement) ARG(toArrange), 
			APTR(PrimArray) ARG(toArray), 
			APTR(Dsp) ARG(dsp), 
			APTR(BeEdition) ARG(edition))
	;
	
	
	virtual void informTo (APTR(OrglRoot) ARG(orgl));
	
	/* If the CurrentKeyMaster includes the owner of this loaf
			then change the owner and return NULL
			else just return self. */
	
	virtual RPTR(OrglRoot) setAllOwners (APTR(ID) ARG(owner));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
  protected: /* protected: splay */

	/* Don't expand my virtual tree in place.  Just move it 
	closer to the top. */
	
	virtual NOLOCK Int8 actualSoftSplay (APTR(XnRegion) ARG(region), APTR(XnRegion) ARG(limitRegion));
	
	/* Expand my partial tree in place. The area in the region must go 
		into the leftCrum of my substitute, or the splay algorithm 
	will fail! */
	
	virtual Int8 actualSplay (APTR(XnRegion) ARG(region), APTR(XnRegion) ARG(limitRegion));
	
  public: /* create */

	
	OVirtualLoaf (APTR(XnRegion) ARG(region), APTR(SharedData) ARG(data));
	
	
	OVirtualLoaf (
			APTR(XnRegion) ARG(region), 
			APTR(SharedData) ARG(data), 
			APTR(HUpperCrum) ARG(hcrum), 
			APTR(SensorCrum) ARG(scrum))
	;
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  public: /* backfollow */

	
	virtual RPTR(XnRegion) attachTrailBlazer (APTR(TrailBlazer) ARG(blazer));
	
	/* it's OK */
	
	virtual NOLOCK void checkTrailBlazer (APTR(TrailBlazer) ARG(blazer));
	
	
	virtual NOLOCK RPTR(TrailBlazer) OR(NULL) fetchTrailBlazer ();
	
	
	virtual void triggerDetector (APTR(FeFillRangeDetector) ARG(detect));
	
  private:
	CHKPTR(ID) myOwner;
	CHKPTR(SharedData) myData;
	friend class Loaf;
	friend class Loaf;
};  /* end class OVirtualLoaf */



/* ************************************************************************ *
 * 
 *                    Class RegionLoaf 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class RegionLoaf : public OExpandingLoaf {

/* Attributes for class RegionLoaf */
	CONCRETE(RegionLoaf)
	SHEPHERD_ANCESTOR(RegionLoaf,OExpandingLoaf)
	COPY(RegionLoaf,DiskCuisine)
	LOCKED(RegionLoaf)
	NOT_A_TYPE(RegionLoaf)
	AUTO_GC(RegionLoaf)
  public: /* accessing */

	/* return a mapping from my data to corresponding stuff in 
	the given trace */
	
	virtual RPTR(Mapping) compare (APTR(TracePosition) ARG(trace), APTR(XnRegion) ARG(region));
	
	/* Make a virtual DataHolder. */
	
	virtual RPTR(FeRangeElement) OR(NULL) fetch (
			APTR(Position) ARG(key), 
			APTR(BeEdition) ARG(edition), 
			APTR(Position) ARG(globalKey))
	;
	
	/* Make an FeRangeElement for each position. */
	
	virtual void fill (
			APTR(XnRegion) ARG(keys), 
			APTR(Arrangement) ARG(toArrange), 
			APTR(PrimArray) ARG(toArray), 
			APTR(Dsp) ARG(dsp), 
			APTR(BeEdition) ARG(edition))
	;
	
	
	virtual void forwardTo (APTR(BeRangeElement) ARG(rangeElement));
	
	/* If I'm here it must be non-virtual. */
	
	virtual RPTR(BeRangeElement) getBe (APTR(Position) ARG(key));
	
	/* The keys in this Edition at which there are Editions with 
	the given label. */
	
	virtual RPTR(XnRegion) keysLabelled (APTR(BeLabel) ARG(label));
	
	/* return the mapping into the domain space of the given trace */
	
	virtual RPTR(Mapping) mappingTo (APTR(TracePosition) ARG(trace), APTR(Mapping) ARG(initial));
	
	/* Return the owner of the atoms represented by the receiver. */
	
	virtual RPTR(ID) owner ();
	
	/* Return a region describing the stuff that can backfollow 
	to trace.  Redefine this to pass down to my hRoot. */
	
	virtual RPTR(XnRegion) sharedRegion (APTR(TracePosition) ARG(trace), APTR(XnRegion) ARG(limitRegion));
	
	/* Return the PrimSpec that describes the representation of 
	the data. */
	
	virtual RPTR(PrimSpec) spec ();
	
	
	virtual RPTR(XnRegion) usedDomain ();
	
  public: /* operations */

	/* Return a stepper of bundles according to the order. */
	
	virtual RPTR(Stepper) bundleStepper (
			APTR(XnRegion) ARG(region), 
			APTR(OrderSpec) ARG(order), 
			APTR(Dsp) ARG(globalDsp))
	;
	
	
	virtual void informTo (APTR(OrglRoot) ARG(orgl));
	
	/* If the CurrentKeyMaster includes the owner of this loaf
			then change the owner and return NULL
			else just return self. */
	
	virtual RPTR(OrglRoot) setAllOwners (APTR(ID) ARG(owner));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
  protected: /* protected: splay */

	/* Don't expand me in place.  Just move it closer to the top. */
	
	virtual NOLOCK Int8 actualSoftSplay (APTR(XnRegion) ARG(region), APTR(XnRegion) ARG(limitRegion));
	
	/* Expand my partial tree in place.  The area in the region must go
		 into the leftCrum of my substitute, or the splay algorithm 
	will fail! */
	
	virtual Int8 actualSplay (APTR(XnRegion) ARG(region), APTR(XnRegion) ARG(limitRegion));
	
  public: /* create */

	
	RegionLoaf (
			APTR(XnRegion) ARG(region), 
			APTR(BeLabel) OR(NULL) ARG(label), 
			APTR(BeRangeElement) ARG(element), 
			APTR(HUpperCrum) OR(NULL) ARG(hcrum))
	;
	
	
	RegionLoaf (
			APTR(XnRegion) ARG(region), 
			APTR(BeRangeElement) ARG(element), 
			APTR(HUpperCrum) ARG(hcrum), 
			UInt32 ARG(hash), 
			APTR(FlockInfo) ARG(info))
	;
	
  public: /* backfollow */

	/* add oparent to the set of upward pointers and update the 
	bertCrums my child. */
	
	virtual void addOParent (APTR(OPart) ARG(oparent));
	
	
	virtual RPTR(XnRegion) attachTrailBlazer (APTR(TrailBlazer) ARG(blazer));
	
	
	virtual void checkChildRecorders (APTR(PropFinder) ARG(finder));
	
	
	virtual void checkTrailBlazer (APTR(TrailBlazer) ARG(blazer));
	
	/* RegionLoaf is the one kind of o-leaf which actually shares 
	range-element identity with other o-leafs.  The range element 
	identity is in myRangeElement rather than myself, so I 
	override my super's version of this method to forward it 
	south one more step to myRangeElement. */
	
	virtual void delayedStoreMatching (
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(ResultRecorder) ARG(recorder), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	;
	
	
	virtual RPTR(TrailBlazer) OR(NULL) fetchTrailBlazer ();
	
	
	virtual void storeRecordingAgents (APTR(RecorderFossil) ARG(recorder), APTR(Agenda) ARG(agenda));
	
	/* Return true if child is a child.  Used for debugging. */
	
	virtual BooleanVar testHChild (APTR(HistoryCrum) ARG(child));
	
	
	virtual void triggerDetector (APTR(FeFillRangeDetector) ARG(detect));
	
	/* My bertCrum must not be leafward of newBCrum. 
		Thus it must be LE to newCrum. Otherwise correct it and recur. */
	
	virtual BooleanVar updateBCrumTo (APTR(BertCrum) ARG(newBCrum));
	
  protected: /* protected: delete */

	
	virtual void dismantle ();
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	CHKPTR(BeRangeElement) myRangeElement;
	CHKPTR(BeLabel) myLabel;
	friend class Loaf;
};  /* end class RegionLoaf */



/* ************************************************************************ *
 * 
 *                    Class SharedData 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class SharedData : public Abraham {

/* Attributes for class SharedData */
	CONCRETE(SharedData)
	SHEPHERD_PATRIARCH(SharedData,Abraham)
	LOCKED(SharedData)
	COPY(SharedData,DiskCuisine)
	AUTO_GC(SharedData)
  public: /* accessing */

	
	virtual UInt32 contentsHash ();
	
	
	virtual RPTR(Heaper) OR(NULL) fetch (APTR(Position) ARG(key));
	
	/* Transfer my data into the toArray mapping through my 
	arrangement and his arrangement. */
	
	virtual void fill (
			APTR(XnRegion) ARG(keys), 
			APTR(Arrangement) ARG(toArrange), 
			APTR(PrimArray) ARG(toArray), 
			APTR(Dsp) ARG(dsp))
	;
	
	/* Return the primSpec for my data. */
	
	virtual RPTR(PrimSpec) spec ();
	
  public: /* creation */

	
	SharedData (APTR(PrimDataArray) ARG(data), APTR(Arrangement) ARG(arrange));
	
  private:
	CHKPTR(Arrangement) myArrangement;
	CHKPTR(PrimArray) myData;
};  /* end class SharedData */



/* ************************************************************************ *
 * 
 *                    Class SplitLoaf 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class SplitLoaf : public InnerLoaf {

/* Attributes for class SplitLoaf */
	CONCRETE(SplitLoaf)
	SHEPHERD_ANCESTOR(SplitLoaf,InnerLoaf)
	MAY_BECOME_ANY_SUBCLASS_OF(SplitLoaf,OExpandingLoaf)
	COPY(SplitLoaf,DiskCuisine)
	LOCKED(SplitLoaf)
	NOT_A_TYPE(SplitLoaf)
	AUTO_GC(SplitLoaf)
  public: /* accessing */

	/* return a mapping from my data to corresponding stuff in 
	the given trace */
	
	virtual RPTR(Mapping) compare (APTR(TracePosition) ARG(trace), APTR(XnRegion) ARG(region));
	
	
	virtual IntegerVar count ();
	
	
	virtual RPTR(XnRegion) domain ();
	
	/* Look up the range element for the key.  If it is embedded 
	within a virtual
		 structure, then make a virtual range element using the 
	edition and globalKey. */
	
	virtual RPTR(FeRangeElement) OR(NULL) fetch (
			APTR(Position) ARG(key), 
			APTR(BeEdition) ARG(edition), 
			APTR(Position) ARG(globalKey))
	;
	
	/* Return the bottom-most Loaf.  Used to get the owner and 
	such of a position. */
	
	virtual RPTR(OExpandingLoaf) fetchBottomAt (APTR(Position) ARG(key));
	
	/* Get or Make the BeRangeElement at the location. */
	
	virtual RPTR(BeRangeElement) getBe (APTR(Position) ARG(key));
	
	/* This effectively copies the region represented by my distinction. */
	
	virtual NOLOCK RPTR(Loaf) inPart ();
	
	
	virtual NOLOCK BooleanVar isLeaf ();
	
	/* This is used by the splay algorithms. */
	
	virtual NOLOCK RPTR(Loaf) outPart ();
	
	
	virtual RPTR(XnRegion) rangeOwners (APTR(XnRegion) OR(NULL) ARG(positions));
	
	/* Recur assigning owners.  Return the portion of the o-tree 
	that couldn't be assigned. */
	
	virtual RPTR(OrglRoot) setAllOwners (APTR(ID) ARG(owner));
	
	
	virtual RPTR(XnRegion) usedDomain ();
	
  public: /* operations */

	/* Return a stepper of bundles according to the order. */
	
	virtual RPTR(Stepper) bundleStepper (
			APTR(XnRegion) ARG(region), 
			APTR(OrderSpec) ARG(order), 
			APTR(Dsp) ARG(globalDsp))
	;
	
	/* Break another into pieces according to mySplit, and combine
		 the corresponding pieces with my children transformed to global 
		 coordinates.  Combine the two non-overlapping results. */
	
	virtual RPTR(OrglRoot) combine (
			APTR(ActualOrglRoot) ARG(another), 
			APTR(XnRegion) ARG(limitRegion), 
			APTR(Dsp) ARG(globalDsp))
	;
	
	/* Make an FeRangeElement for each position. */
	
	virtual void fill (
			APTR(XnRegion) ARG(keys), 
			APTR(Arrangement) ARG(toArrange), 
			APTR(PrimArray) ARG(toArray), 
			APTR(Dsp) ARG(globalDsp), 
			APTR(BeEdition) ARG(edition))
	;
	
	/* Copy the enclosure in orgl appropriate for this crum, then 
	hand it down to the 
		subCrums. */
	
	virtual void informTo (APTR(OrglRoot) ARG(orgl));
	
	/* Just search for now. */
	
	virtual RPTR(XnRegion) keysLabelled (APTR(BeLabel) ARG(label));
	
	/* Return a region describing the stuff I share with the orgl 
	under trace. */
	
	virtual RPTR(XnRegion) sharedRegion (APTR(TracePosition) ARG(trace), APTR(XnRegion) ARG(limitRegion));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
  public: /* create */

	
	SplitLoaf (
			APTR(XnRegion) ARG(split), 
			APTR(Loaf) ARG(inLoaf), 
			APTR(Loaf) ARG(outLoaf))
	;
	
	
	SplitLoaf (
			APTR(XnRegion) ARG(split), 
			APTR(Loaf) ARG(inLoaf), 
			APTR(Loaf) ARG(outLoaf), 
			APTR(HUpperCrum) ARG(hcrum))
	;
	
	
	SplitLoaf (
			APTR(XnRegion) ARG(split), 
			APTR(Loaf) ARG(inLoaf), 
			APTR(Loaf) ARG(outLoaf), 
			APTR(HUpperCrum) ARG(hcrum), 
			UInt32 ARG(hash))
	;
	
	/* Special constructor for becoming this class */
	
	SplitLoaf (
			APTR(XnRegion) ARG(split), 
			APTR(Loaf) ARG(inLoaf), 
			APTR(Loaf) ARG(outLoaf), 
			APTR(HUpperCrum) ARG(hcrum), 
			UInt32 ARG(hash), 
			APTR(FlockInfo) ARG(info))
	;
	
  public: /* backfollow */

	/* add oparent to the set of upward pointers and update the 
	bertCrums in 
		southern children. */
	
	virtual void addOParent (APTR(OPart) ARG(oparent));
	
	
	virtual RPTR(XnRegion) attachTrailBlazer (APTR(TrailBlazer) ARG(blazer));
	
	
	virtual void checkChildRecorders (APTR(PropFinder) ARG(finder));
	
	
	virtual void checkTrailBlazer (APTR(TrailBlazer) ARG(blazer));
	
	
	virtual void delayedStoreMatching (
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(ResultRecorder) ARG(recorder), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	;
	
	
	virtual RPTR(TrailBlazer) OR(NULL) fetchTrailBlazer ();
	
	
	virtual void storeRecordingAgents (APTR(RecorderFossil) ARG(recorder), APTR(Agenda) ARG(agenda));
	
	
	virtual void triggerDetector (APTR(FeFillRangeDetector) ARG(detect));
	
	/* My bertCrum must not be leafward of newBCrum. 
		Thus it must be LE to newCrum. Otherwise correct it and recur. */
	
	virtual BooleanVar updateBCrumTo (APTR(BertCrum) ARG(newBCrum));
	
  protected: /* protected: splay */

	/* Make each child completely contained or completely outside
		 the region.  Return the number of children completely in the region. 
		 The transformation table follows:
	 #   in 	    out 	  return 	operation		rearrange
	1|	 0		0		0		none			none
	2|	 0		1		1		swap #4		(A (B* C)) -> (B* (A C))
	3|	 0		2		1		swap #7		(A B*) -> (B* A)
	4|	 1		0		1		rotateRight		((A* B) C) -> (A* (B C))
	5|	 1		1		1		interleave		((A* B) (C* D)) -> ((A* C*) (B D))
	6|	 1		2		1		swap #8		((A* B) C*) -> ((A* C*) B)
	7|	 2		0		1		none			none
	8|	 2		1		1		rotateLeft		(A* (B* C)) -> ((A* B*) C)
	9|	 2		2		2		none			none */
	
	virtual Int8 actualSplay (APTR(XnRegion) ARG(region), APTR(XnRegion) ARG(limitRegion));
	
  private: /* private: splay */

	/* Install new in and out children at the same 
		 time. This will need to be in a critical section.  Add me as
		 parent to the new loaves first in case the only ent reference
		 to the new loaf is through one of my children (which might 
		 delete it if I'm *their* last reference). */
	
	virtual void install (
			APTR(Loaf) ARG(newIn), 
			APTR(Loaf) ARG(newOut), 
			APTR(XnRegion) ARG(newSplit))
	;
	
	/* Make a new crum to replace some existing crums during a splay 
		operation. The new crum must have the same trace as me to 
		guarantee the hTree property. Optimization: look at parents of the 
		new loaves to find a pre-existing parent with the same trace and 
		wisps. This will coalesce the shearing that splaying causes. */
	/* The new loaf is made from pieces of me, so they are 
	distinguished by my split. */
	
	virtual RPTR(Loaf) makeNew (APTR(Loaf) ARG(newIn), APTR(Loaf) ARG(newOut));
	
	/* This is a support for the splay routine. Swapping the children 
		reduces the number of cases. This way, if this crum is partially 
		in a region being splayed, the part contained in the region 
		resides in the left slot. */
	
	virtual void swapChildren ();
	
  protected: /* protected: delete */

	
	virtual void dismantle ();
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	CHKPTR(XnRegion) mySplit;
	CHKPTR(Loaf) myIn;
	CHKPTR(Loaf) myOut;
	friend class InnerLoaf;
	friend class Loaf;
	friend class InnerLoaf;
	friend class Loaf;
};  /* end class SplitLoaf */



#endif /* LOAVESP_HXX */

