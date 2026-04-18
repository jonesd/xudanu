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

#ifndef BRANGE1X_HXX
#define BRANGE1X_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef BRANGE1X_OXX
#include "brange1x.oxx"
#endif /* BRANGE1X_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */


#ifndef BRANGE3X_OXX
#include "brange3x.oxx"
#endif /* BRANGE3X_OXX */

#ifndef CANOPYX_OXX
#include "canopyx.oxx"
#endif /* CANOPYX_OXX */

#ifndef DETECTX_OXX
#include "detectx.oxx"
#endif /* DETECTX_OXX */

#ifndef FILTERX_OXX
#include "filterx.oxx"
#endif /* FILTERX_OXX */

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

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef OROOTX_OXX
#include "orootx.oxx"
#endif /* OROOTX_OXX */

#ifndef PRIMTABX_OXX
#include "primtabx.oxx"
#endif /* PRIMTABX_OXX */

#ifndef PRIMVALX_OXX
#include "primvalx.oxx"
#endif /* PRIMVALX_OXX */

#ifndef PROPSX_OXX
#include "propsx.oxx"
#endif /* PROPSX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */

#ifndef TCLUDEX_OXX
#include "tcludex.oxx"
#endif /* TCLUDEX_OXX */

#ifndef TRACEPX_OXX
#include "tracepx.oxx"
#endif /* TRACEPX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class BeCarrier 
 *
 * ************************************************************************ */




	/* These are used to carry a combination of a rangeElement 
	and a label.  Using FeRangeElements would be a hack that 
	drags in permissions checking, etc. */

class BeCarrier : public Heaper {

/* Attributes for class BeCarrier */
	CONCRETE(BeCarrier)
	AUTO_GC(BeCarrier)
  public: /* creation */

	/* For non-Editions only. */
	
	static RPTR(BeCarrier) label (APTR(BeRangeElement) ARG(element));
	
	/* For non-Editions only. */
	
	static RPTR(BeCarrier) make (APTR(BeRangeElement) ARG(element));
	
	/* For editions only. */
	
	static RPTR(BeCarrier) make (APTR(BeLabel) OR(NULL) ARG(label), APTR(BeRangeElement) ARG(element));
	
  public: /* accessing */

	
	virtual RPTR(BeLabel) OR(NULL) fetchLabel ();
	
	
	virtual RPTR(BeLabel) getLabel ();
	
	
	virtual RPTR(FeRangeElement) makeFe ();
	
	
	virtual RPTR(BeRangeElement) rangeElement ();
	
  public: /* creation */

	
	BeCarrier (APTR(BeLabel) OR(NULL) ARG(label), APTR(BeRangeElement) ARG(element));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  private:
	CHKPTR(BeLabel) OR(NULL) myLabel;
	CHKPTR(BeRangeElement) myRangeElement;
};  /* end class BeCarrier */



/* ************************************************************************ *
 * 
 *                    Class BeRangeElement 
 *
 * ************************************************************************ */




	/* This is the actual representation on disk; the Fe versions 
	of these classes hide the actual representation.ó */

class BeRangeElement : public Abraham {

/* Attributes for class BeRangeElement */
	DEFERRED(BeRangeElement)
	SHEPHERD_ANCESTOR(BeRangeElement,Abraham)
	COPY(BeRangeElement,DiskCuisine)
	DEFERRED_LOCKED(BeRangeElement)
	AUTO_GC(BeRangeElement)
  public: /* accessing */

	/* Add a new session level pointer */
	
	virtual void addFeRangeElement (APTR(FeRangeElement) ARG(element));
	
	
	virtual BooleanVar isPurgeable ();
	
	/* Make a front end object (session level) for this backend 
	object.  If the receiver is an Edition, there had better be a label. */
	
	virtual RPTR(FeRangeElement) makeFe (APTR(BeLabel) OR(NULL) ARG(label)) DEFERRED_FUNC;
	
	/* Change the identity of this object to that of the other.
		 Only placeHolders implement it at the moment, so the 
		 default is to reject the operation (return false). */
	
	virtual NOLOCK BooleanVar makeIdentical (APTR(BeRangeElement) ARG(other));
	
	/* The Club who has ownership */
	
	virtual NOLOCK RPTR(ID) owner ();
	
	/* Remove a session level pointer */
	
	virtual void removeFeRangeElement (APTR(FeRangeElement) ARG(element));
	
	/* Change the Club who has ownership */
	
	virtual void setOwner (APTR(ID) ARG(club));
	
  public: /* be accessing */

	/* add oparent to the set of upward pointers.  Editions may
		 also have to propagate BertCrum change downward. */
	
	virtual void addOParent (APTR(Loaf) ARG(oparent));
	
	
	virtual BooleanVar anyPasses (APTR(PropFinder) ARG(finder));
	
	
	virtual RPTR(BertCrum) bertCrum ();
	
	/* does nothing.  Overrides do something. */
	
	virtual NOLOCK void checkRecorders (APTR(PropFinder) ARG(finder), APTR(SensorCrum) OR(NULL) ARG(scrum));
	
	
	virtual UInt32 contentsHash ();
	
	
	virtual void delayedStoreBackfollow (
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(ResultRecorder) ARG(recorder), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	;
	
	
	virtual RPTR(PrimSet) OF1(FeRangeElement) feRangeElements ();
	
	
	virtual NOLOCK RPTR(HistoryCrum) hCrum ();
	
	/* Return true if the receiver can backfollow to trace. */
	
	virtual BooleanVar inTrace (APTR(TracePosition) ARG(trace));
	
	/* return a mapping from my data to corresponding stuff in 
	the given trace */
	
	virtual RPTR(Mapping) mappingTo (APTR(TracePosition) ARG(trace), APTR(Mapping) ARG(mapping));
	
	/* remove oparent from the set of upward pointers. */
	
	virtual void removeOParent (APTR(OPart) ARG(oparent));
	
	
	virtual NOLOCK RPTR(SensorCrum) sensorCrum ();
	
	/* Ensure the my bertCrum is not be leafward of newBCrum. */
	
	virtual BooleanVar updateBCrumTo (APTR(BertCrum) ARG(newBCrum));
	
  protected: /* protected: */

	
	BeRangeElement ();
	
	
	BeRangeElement (APTR(SensorCrum) ARG(sensorCrum), TCSJ);
	
	
	virtual void dismantle ();
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK NOLOCK void restartRE (APTR(Rcvr) ARG(rcvr));
	
  public: /* comparing */

	/* See comment in FeRangeElement */
	
	virtual RPTR(BeEdition) works (
			APTR(IDRegion) ARG(permissions), 
			APTR(Filter) ARG(endorsementsFilter), 
			Int32 ARG(flags))
	;
	
  private:
	CHKPTR(HUpperCrum) myHCrum;
	CHKPTR(SensorCrum) mySensorCrum;
	CHKPTR(ID) myOwner;
	NOCOPY CHKPTR(PrimSet) OF1(FeRangeElement) OR(NULL) myFeRangeElements;
};  /* end class BeRangeElement */



/* ************************************************************************ *
 * 
 *                    Class   BeDataHolder 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class BeDataHolder : public BeRangeElement {

/* Attributes for class BeDataHolder */
	CONCRETE(BeDataHolder)
	SHEPHERD_PATRIARCH(BeDataHolder,BeRangeElement)
	LOCKED(BeDataHolder)
	COPY(BeDataHolder,DiskCuisine)
	AUTO_GC(BeDataHolder)
  public: /* accessing */

	/* Return me wrapped with a session level DataHolder. */
	
	virtual RPTR(FeRangeElement) makeFe (APTR(BeLabel) OR(NULL) ARG(label));
	
	
	virtual NOLOCK RPTR(PrimValue) value ();
	
  public: /* create */

	
	BeDataHolder (APTR(PrimValue) ARG(value), TCSJ);
	
  private:
	CHKPTR(PrimValue) myValue;
};  /* end class BeDataHolder */



/* ************************************************************************ *
 * 
 *                    Class   BeIDHolder 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class BeIDHolder : public BeRangeElement {

/* Attributes for class BeIDHolder */
	CONCRETE(BeIDHolder)
	SHEPHERD_PATRIARCH(BeIDHolder,BeRangeElement)
	LOCKED(BeIDHolder)
	COPY(BeIDHolder,DiskCuisine)
	AUTO_GC(BeIDHolder)
  public: /* creation */

	
	static RPTR(BeIDHolder) make (APTR(ID) ARG(iD));
	
  public: /* accessing */

	
	virtual NOLOCK RPTR(ID) iD ();
	
	
	virtual RPTR(FeRangeElement) makeFe (APTR(BeLabel) OR(NULL) ARG(label));
	
  protected: /* protected: dismantle */

	/* Does this need to clear the GrandMap table? */
	
	virtual void dismantle ();
	
  protected: /* protected: creation */

	
	BeIDHolder (APTR(ID) ARG(iD), TCSJ);
	
  private:
	CHKPTR(ID) myID;
};  /* end class BeIDHolder */



/* ************************************************************************ *
 * 
 *                    Class   BeLabel 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class BeLabel : public BeRangeElement {

/* Attributes for class BeLabel */
	CONCRETE(BeLabel)
	SHEPHERD_PATRIARCH(BeLabel,BeRangeElement)
	LOCKED(BeLabel)
	COPY(BeLabel,DiskCuisine)
	NO_GC(BeLabel)
  public: /* accessing */

	
	virtual RPTR(FeRangeElement) makeFe (APTR(BeLabel) OR(NULL) ARG(label));
	
  public: /* creation */

	
	BeLabel ();
	

};  /* end class BeLabel */



/* ************************************************************************ *
 * 
 *                    Class   BePlaceHolder 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class BePlaceHolder : public BeRangeElement {

/* Attributes for class BePlaceHolder */
	CONCRETE(BePlaceHolder)
	SHEPHERD_PATRIARCH(BePlaceHolder,BeRangeElement)
	LOCKED(BePlaceHolder)
	COPY(BePlaceHolder,DiskCuisine)
	AUTO_GC(BePlaceHolder)
  public: /* accessing */

	
	virtual void addDetector (APTR(FeFillDetector) ARG(detector));
	
	
	virtual BooleanVar isPurgeable ();
	
	
	virtual RPTR(FeRangeElement) makeFe (APTR(BeLabel) OR(NULL) ARG(label));
	
	/* Change the identity of this object to that of the other. */
	/* Make all my persistent oParents point at the other guy.
		make all the session level FeRangeElements point at the other guy. */
	
	virtual BooleanVar makeIdentical (APTR(BeRangeElement) ARG(other));
	
	
	virtual void removeDetector (APTR(FeFillDetector) ARG(detector));
	
	
	virtual NOLOCK void removeLastDetector ();
	
  public: /* creation */

	
	BePlaceHolder ();
	
	
	BePlaceHolder (APTR(TrailBlazer) OR(NULL) ARG(blazer), TCSJ);
	
  public: /* backfollow */

	
	virtual void attachTrailBlazer (APTR(TrailBlazer) ARG(blazer));
	
	
	virtual void checkTrailBlazer (APTR(TrailBlazer) ARG(blazer));
	
	
	virtual RPTR(TrailBlazer) OR(NULL) fetchTrailBlazer ();
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK NOLOCK void restartP (APTR(Rcvr) ARG(rcvr));
	
  private:
	CHKPTR(TrailBlazer) OR(NULL) myTrailBlazer;
	NOCOPY CHKPTR(PrimSet) OF1(FeFillDetector) OR(NULL) myDetectors;
};  /* end class BePlaceHolder */



#endif /* BRANGE1X_HXX */

