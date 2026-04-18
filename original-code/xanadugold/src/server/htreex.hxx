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

#ifndef HTREEX_HXX
#define HTREEX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef HTREEX_OXX
#include "htreex.oxx"
#endif /* HTREEX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef CANOPYX_OXX
#include "canopyx.oxx"
#endif /* CANOPYX_OXX */

#ifndef NKERNELX_OXX
#include "nkernelx.oxx"
#endif /* NKERNELX_OXX */

#ifndef OROOTX_OXX
#include "orootx.oxx"
#endif /* OROOTX_OXX */

#ifndef PROPSX_OXX
#include "propsx.oxx"
#endif /* PROPSX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

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
 *                    Class HistoryCrum 
 *
 * ************************************************************************ */



/* Initializers for HistoryCrum */




	/* invariant:  the parent's trace >= the child's trace
	
	The subclasses should differentiate between the number 
	of children:  0, 1, or more.  ORoots have 0 children and 
	always have a canopyCrum.  HCrums for OCrums in the 
	body of the ent have one child if they are at the top 
	of an unshared subtreee, and more if they are at the top 
	of a shared subtree.  HCrums with more than one child 
	almost always have a canopyCrum to represent the join 
	between the canopies of their multiple hchildren.
	
	The change would make the updateH method return a 
	new crum, which the oCrums would install.
	
	They don't do so now because I'm not sure if a crum with 
	no parents can appear in the middle of the ent.  If so, then 
	the version compare operations would gag.  Hmmm.  The 
	change doesn't make any difference for that.... */

class HistoryCrum : public Heaper {

/* Attributes for class HistoryCrum */
	DEFERRED(HistoryCrum)
	COPY(HistoryCrum,DiskCuisine)
	NO_GC(HistoryCrum)

/* Initializers for HistoryCrum */


  public: /* accessing */

	/* Shepherds use a sequence number for their hash.  Return the next one
		 and increment.  This should actually do spread the hashes. */
	/* This actually needs to roll over the UInt32 limit. */
	
	static UInt32 nextHistoryCrumSequenceNumber ();
	
  public: /* deferred filtering */

	/* See comment in HistoryCrum>>delayedStoreBackfollow:with:with: */
	
	virtual void actualDelayedStoreBackfollow (
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(ResultRecorder) ARG(recorder), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	 DEFERRED_SUBR;
	
	
	virtual BooleanVar anyPasses (APTR(PropFinder) ARG(finder)) DEFERRED_FUNC;
	
	/* These objects must have a crum in the bert canopy. */
	
	virtual RPTR(BertCrum) bertCrum () DEFERRED_FUNC;
	
  public: /* filtering */

	/* Do the northward H-tree walk for the 'now' part of a backfollow. */
	
	virtual void delayedStoreBackfollow (
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(ResultRecorder) ARG(recorder), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	;
	
	/* Ring all the detectors north of me with the given Edition 
	as argument */
	
	virtual void ringDetectors (APTR(FeEdition) ARG(edition)) DEFERRED_SUBR;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	/* Return true if their are no upward pointers.  This is used
		 by OParts to determine if they can be forgotten. */
	
	virtual BooleanVar isEmpty () DEFERRED_FUNC;
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* create */

	
	HistoryCrum ();
	
  public: /* deferred testing */

	/* Return true if the receiver can backfollow to trace. */
	
	virtual BooleanVar inTrace (APTR(TracePosition) ARG(trace)) DEFERRED_FUNC;
	
  public: /* deferred accessing */

	
	virtual RPTR(TracePosition) hCut () DEFERRED_FUNC;
	
	/* return the mapping into the domain space of the given trace */
	
	virtual RPTR(Mapping) mappingTo (APTR(TracePosition) ARG(trace), APTR(Mapping) ARG(initial)) DEFERRED_FUNC;
	
	
	virtual RPTR(ImmuSet) OF1(OPart) oParents () DEFERRED_FUNC;
	
  public: /* deferred updating */

	/* If bertCrum is leafward of newBCrum then change it and return true, 
		otherwise return false. */
	
	virtual BooleanVar propagateBCrum (APTR(BertCrum) ARG(newBCrum)) DEFERRED_FUNC;
	
  private:
	UInt32 myHash;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static UInt32 SequenceNumber;
};  /* end class HistoryCrum */



/* ************************************************************************ *
 * 
 *                    Class   HUpperCrum 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HUpperCrum : public HistoryCrum {

/* Attributes for class HUpperCrum */
	CONCRETE(HUpperCrum)
	COPY(HUpperCrum,DiskCuisine)
	AUTO_GC(HUpperCrum)
  public: /* instance creation */

	
	static RPTR(HUpperCrum) make ();
	
	
	static RPTR(HUpperCrum) make (APTR(BertCrum) ARG(bertCrum));
	
	
	static RPTR(HUpperCrum) make (APTR(HUpperCrum) ARG(hcrum));
	
  public: /* testing */

	/* Return true if the receiver can backfollow to trace. */
	/* This chase up the htree could terminate early if the trace equalled 
		the trace in the receiver. This would be correct except that 
		oplanes can be created with a particular trace, only part of which 
		actually get included in the real orgl with that trace. */
	
	virtual BooleanVar inTrace (APTR(TracePosition) ARG(trace));
	
	/* Return true if their are no upward pointers.  This is used
		 by OParts to determine if they can be forgotten. */
	
	virtual BooleanVar isEmpty ();
	
	/* If bertCrum is leafward of newBCrum then change it and return true, 
		otherwise return false. */
	
	virtual BooleanVar propagateBCrum (APTR(BertCrum) ARG(newBCrum));
	
  public: /* accessing */

	/* find the canopyCrum that goes with this hCrum. */
	
	virtual RPTR(BertCrum) bertCrum ();
	
	
	virtual RPTR(TracePosition) hCut ();
	
	/* return the mapping into the domain space of the given trace */
	
	virtual RPTR(Mapping) mappingTo (APTR(TracePosition) ARG(trace), APTR(Mapping) ARG(initial));
	
	
	virtual RPTR(ImmuSet) OF1(OPart) oParents ();
	
  public: /* updating */

	/* If this hcrum represents a fork, then it must get its own 
	canopy crum. */
	/* This routine could be drastically improved for orgl creation. */
	
	virtual void addOParent (APTR(OPart) ARG(newCrum));
	
	/* Make a history crum with no upward pointers. */
	
	virtual void removeOParent (APTR(OPart) ARG(newCrum));
	
  public: /* filtering */

	/* Apply filter on canopy */
	
	virtual void actualDelayedStoreBackfollow (
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(ResultRecorder) ARG(recorder), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	;
	
	
	virtual BooleanVar anyPasses (APTR(PropFinder) ARG(finder));
	
	
	virtual void ringDetectors (APTR(FeEdition) ARG(edition));
	
  private: /* private: */

	/* Make my bertCrum the join of its current value and bCrum. */
	
	virtual void updateBertCanopy (APTR(BertCrum) ARG(bCrum));
	
  public: /* create */

	
	HUpperCrum (APTR(TracePosition) ARG(trace), APTR(BertCrum) ARG(canopy));
	
	
	HUpperCrum (
			APTR(OPart) ARG(first), 
			APTR(OPart) ARG(second), 
			APTR(TracePosition) ARG(trace))
	;
	
  private:
	CHKPTR(TracePosition) hcut;
	CHKPTR(MuSet) OF1(OPart) hcrums;
	CHKPTR(BertCrum) myBertCrum;
};  /* end class HUpperCrum */



#endif /* HTREEX_HXX */

