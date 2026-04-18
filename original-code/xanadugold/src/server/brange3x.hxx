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

#ifndef BRANGE3X_HXX
#define BRANGE3X_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef BRANGE3X_OXX
#include "brange3x.oxx"
#endif /* BRANGE3X_OXX */


#ifndef BRANGE1X_HXX
#include "brange1x.hxx"
#endif /* BRANGE1X_HXX */

#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef BRANGE2X_OXX
#include "brange2x.oxx"
#endif /* BRANGE2X_OXX */

#ifndef CANOPYX_OXX
#include "canopyx.oxx"
#endif /* CANOPYX_OXX */

#ifndef CROSSX_OXX
#include "crossx.oxx"
#endif /* CROSSX_OXX */

#ifndef DETECTX_OXX
#include "detectx.oxx"
#endif /* DETECTX_OXX */

#ifndef FILTERX_OXX
#include "filterx.oxx"
#endif /* FILTERX_OXX */

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

#ifndef PROPSX_OXX
#include "propsx.oxx"
#endif /* PROPSX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */

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


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class BeEdition 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class BeEdition : public BeRangeElement {

/* Attributes for class BeEdition */
	CONCRETE(BeEdition)
	SHEPHERD_PATRIARCH(BeEdition,BeRangeElement)
	LOCKED(BeEdition)
	COPY(BeEdition,DiskCuisine)
	AUTO_GC(BeEdition)
  public: /* creation */

	
	static RPTR(BeEdition) make (APTR(OrglRoot) ARG(oroot));
	
  public: /* operations */

	/* An Edition with the contents of both Editions; where they 
	share keys, they must have the same RangeElement. */
	
	virtual RPTR(BeEdition) combine (APTR(BeEdition) ARG(other));
	
	/* A new Edition with the domain restricted to the given set 
	of keys. */
	
	virtual RPTR(BeEdition) copy (APTR(XnRegion) ARG(keys));
	
	/* An Edition with the contents of both Editions; where they 
	share keys, use the contents of the other Edition. Equivalent to
			this->copy (other->domain ()->complement ())->combine (other) */
	
	virtual RPTR(BeEdition) replace (APTR(BeEdition) ARG(other));
	
	/* An Edition with the keys transformed according to the 
	given Mapping. Where the Mapping takes several keys in the 
	domain to a single key in the range, this Edition must have 
	the same RangeElement at all the domain keys. */
	
	virtual RPTR(BeEdition) transformedBy (APTR(Mapping) ARG(mapping));
	
	/* A new Edition with a RangeElement at a specified key. The 
	old value, if there is one, is superceded. Equivalent to
			this->replace (theServer ()->makeEditionWith (key, value)) */
	
	virtual RPTR(BeEdition) with (APTR(Position) ARG(key), APTR(BeCarrier) ARG(value));
	
	/* A new Edition with a RangeElement at a specified set of 
	keys. The old values, if there are any, are superceded. Equivalent to
			this->replace (theServer ()->makeEditionWithAll (keys, value)) */
	
	virtual RPTR(BeEdition) withAll (APTR(XnRegion) ARG(keys), APTR(BeCarrier) ARG(value));
	
	/* A new Edition without any RangeElement at a specified key. 
	The old value, if there is one, is removed. Equivalent to
			this->copy (key->asRegion ()->complement ()) */
	
	virtual RPTR(BeEdition) without (APTR(Position) ARG(key));
	
	/* A new Edition without any RangeElements at the specified 
	keys. The old values, if there are any, are removed. Equivalent to
			this->copy (keys->complement ()) */
	
	virtual RPTR(BeEdition) withoutAll (APTR(XnRegion) ARG(keys));
	
  public: /* accessing */

	/* The space from which the keys of this Edition are taken. 
	Equivalent to
			this->domain ()->coordinateSpace () */
	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	/* The number of keys in this Edition. Blasts if infinite. 
	Equivalent to
			this->domain ()->count () */
	
	virtual IntegerVar count ();
	
	/* All the keys in this Edition. May be infinite, or empty. */
	
	virtual RPTR(XnRegion) domain ();
	
	/* Create a front end representation for what is at the given key. */
	
	virtual RPTR(FeRangeElement) OR(NULL) fetch (APTR(Position) ARG(key));
	
	/* The value at the given key, or blast if there is no such 
	key (i.e. if ! this->domain ()->hasMember (key)). */
	
	virtual RPTR(FeRangeElement) get (APTR(Position) ARG(key));
	
	/* Whether the given key is in the Edition. Equivalent to
			this->domain ()->hasMember (key) */
	
	virtual BooleanVar includesKey (APTR(Position) ARG(key));
	
	/* Whether there are any keys in this Edition. Equivalent to
			this->domain ()->isEmpty () */
	
	virtual BooleanVar isEmpty ();
	
	/* Whether there is a finite number of keys in this Edition. 
	Equivalent to
			this->domain ()->isFinite () */
	
	virtual BooleanVar isFinite ();
	
	
	virtual BooleanVar isPurgeable ();
	
	
	virtual RPTR(FeRangeElement) makeFe (APTR(BeLabel) OR(NULL) ARG(label));
	
	/* The owners of all the RangeElements in the given Region, 
	or in the entire 
		Edition if no Region is specified. */
	
	virtual RPTR(IDRegion) rangeOwners (APTR(XnRegion) ARG(positions) = NULL);
	
	/* Essential.  This is the fundamental retrieval operation.  
	Return a stepper of bundles.  Each bundle is an association 
	between a region in the domain and the range elements 
	associated with that region.  Where the region is associated 
	with data, for instance, the bundle contains a PrimArray of 
	the data elements.
		If no Region is given, then reads out the whole thing. */
	
	virtual CLIENT RPTR(Stepper) OF1(Bundle) retrieve (
			APTR(XnRegion) ARG(region) = NULL, 
			APTR(OrderSpec) ARG(order) = NULL, 
			Int32 ARG(flags) = Int32Zero)
	;
	
	/* If this Edition has a single key, then the value at that 
	key; if not, blasts. Equivalent to
			this->get (this->domain ()->theOne ()) */
	
	virtual RPTR(FeRangeElement) theOne ();
	
	/* All of the endorsements on this Edition and all Works 
	which the CurrentKeyMaster can read. */
	
	virtual RPTR(CrossRegion) visibleEndorsements ();
	
  public: /* props */

	/* Adds to the endorsements on this Edition. The set of 
	endorsements must be a finite number of (club ID, token ID) pairs. */
	
	virtual void endorse (APTR(CrossRegion) ARG(endorsements));
	
	/* All of the endorsements on this Edition. */
	
	virtual RPTR(CrossRegion) endorsements ();
	
	
	virtual NOLOCK RPTR(BertProp) prop ();
	
	
	virtual void propChange (APTR(PropChange) ARG(change), APTR(Prop) ARG(nw));
	
	/* update props */
	
	virtual void propChanged (
			APTR(PropChange) ARG(change), 
			APTR(Prop) ARG(old), 
			APTR(Prop) ARG(nw), 
			APTR(PropFinder) ARG(oldFinder) = NULL)
	;
	
	/* Removes endorsements from this Edition. Ignores all 
	endorsements which you could have removed, but which don't 
	happen to be there right now. */
	
	virtual void retract (APTR(CrossRegion) ARG(endorsements));
	
	/* All of the endorsements on this Edition and all Works 
	directly on it */
	
	virtual RPTR(CrossRegion) totalEndorsements ();
	
  public: /* becoming */

	/* Add a detector which will be triggered with a FeEdition 
	when a PlaceHolder becomes a non-PlaceHolder */
	
	virtual void addDetector (APTR(FeFillRangeDetector) ARG(detect));
	
	/* Return the owner for the given position in the receiver. */
	
	virtual RPTR(ID) ownerAt (APTR(Position) ARG(key));
	
	/* Remove a previously added detector */
	
	virtual void removeDetector (APTR(FeFillRangeDetector) ARG(detect));
	
	/* Notify the edition that there are no remaining detectors on it. */
	
	virtual void removeLastDetector ();
	
	/* Ring all my detectors with the given Edition as an argument */
	
	virtual void ringDetectors (APTR(FeEdition) ARG(newIdentities));
	
	/* Changes the owner of all RangeElements; requires the 
	authority of the current owner.
		Returns the subset of this Edition whose owners did not get 
	changed because of lack of authority. */
	
	virtual RPTR(BeEdition) setRangeOwners (APTR(ID) ARG(newOwner), APTR(XnRegion) ARG(region));
	
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
	
	virtual RPTR(Pair) OF1(BeEdition) tryAllBecome (APTR(BeEdition) ARG(newIdentities));
	
  public: /* labelling */

	/* The keys in this Edition at which there are Editions with 
	the given label. */
	
	virtual RPTR(XnRegion) keysLabelled (APTR(BeLabel) ARG(label));
	
	/* Replace the Edition at the given key, leaving the Label 
	the same. Equivalent to
			this->store (key, edition->labelled (CAST(FeEdition,this->ge
	t (key))->label ())) */
	
	virtual RPTR(BeEdition) rebind (APTR(Position) ARG(key), APTR(BeEdition) ARG(edition));
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK NOLOCK void restartE (APTR(Rcvr) ARG(rcvr));
	
  protected: /* protected: */

	
	virtual NOLOCK RPTR(OrglRoot) orglRoot ();
	
  public: /* be accessing */

	/* add oparent to the set of upward pointers.  Editions may
		 also have to propagate BertCrum change downward. */
	
	virtual void addOParent (APTR(Loaf) ARG(oparent));
	
	
	virtual BooleanVar anyPasses (APTR(PropFinder) ARG(finder));
	
	
	virtual void checkRecorders (APTR(PropFinder) ARG(finder), APTR(SensorCrum) OR(NULL) ARG(scrum));
	
	/* The Works currently on this Edition */
	
	virtual RPTR(ImmuSet) OF1(BeWork) currentWorks ();
	
	/* An actual, non-virtual FE range element at that key. Used 
	by become operation to get something to pass into 
	BeRangeElement::become () */
	
	virtual RPTR(BeRangeElement) getOrMakeBe (APTR(Position) ARG(key));
	
	/* A Work has been newly revised to point at me. */
	
	virtual void introduceWork (APTR(BeWork) ARG(work));
	
	/* The Work is no longer onto this Edition.  Remove the backpointer. */
	
	virtual void removeWork (APTR(BeWork) ARG(work));
	
	/* My bertCrum must not be leafward of newBCrum. 
		Thus it must be LE to newCrum. Otherwise correct it and recur. */
	
	virtual BooleanVar updateBCrumTo (APTR(BertCrum) ARG(newBCrum));
	
  public: /* comparing */

	/* All of the keys in this Edition at which the given 
	RangeElement can be found. Equivalent to
			this->sharedRegion (theServer ()->makeEditionWith (some 
	position, value)) */
	
	virtual RPTR(XnRegion) keysOf (APTR(FeRangeElement) ARG(value));
	
	/* A Mapping from each of the keys in this Edition to all of 
	the keys in the other Edition which have the same RangeElement. */
	
	virtual RPTR(Mapping) mapSharedTo (APTR(BeEdition) ARG(other));
	
	/* The subset of this Edition whose RangeElements are not in 
	the other Edition. Equivalent to
			this->copy (this->sharedRegion (other, flags)->complement ()) */
	
	virtual RPTR(BeEdition) notSharedWith (APTR(BeEdition) ARG(other), Int32 ARG(flags) = Int32Zero);
	
	/* The subset of the keys of this Edition which  have 
	RangeElements that are in the other Edition. If both flags 
	are false, then equivalent to
			this->mapSharedTo (other)->domain ()
		If nestThis, then returns not only keys of RangeElements 
	which are in the other, but also keys of Editions which lead 
	to RangeElements which are in the other.
		If nestOther, then looks not only for RangeElements which 
	are values of the other Edition, but also those which are 
	values of sub-Editions of the other Edition. (This option 
	will probably not be supported in version 1.0) */
	
	virtual RPTR(XnRegion) sharedRegion (APTR(BeEdition) ARG(other), Int32 ARG(flags) = Int32Zero);
	
	/* The subset of this Edition whose RangeElements are in the 
	other Edition. If the same RangeElement is in this Edition at 
	several different keys, all keys will be in the result 
	(provided the RangeElement is also in the other Edition). Equivalent to
			this->copy (this->sharedRegion (other, flags)) */
	
	virtual RPTR(BeEdition) sharedWith (APTR(BeEdition) ARG(other), Int32 ARG(flags) = Int32Zero);
	
	
	virtual RPTR(BeEdition) works (
			APTR(IDRegion) ARG(permissions), 
			APTR(Filter) ARG(endorsementsFilter), 
			Int32 ARG(flags))
	;
	
  public: /* creation */

	
	BeEdition (APTR(OrglRoot) ARG(root), TCSJ);
	
	
	virtual void dismantle ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* transclusions */

	/* Attach the TrailBlazer to this Edition, and return the 
	region of partiality it is attached to */
	
	virtual RPTR(XnRegion) attachTrailBlazer (APTR(TrailBlazer) ARG(blazer));
	
	
	virtual void fossilRelease (APTR(RecorderFossil) ARG(oldGrabber));
	
	/* Get or make a TrailBlazer for recording results into this 
	Edition. Blast if there is already more than one */
	
	virtual RPTR(TrailBlazer) getOrMakeTrailBlazer ();
	
	/* See FeEdition */
	
	virtual RPTR(BeEdition) rangeTranscluders (
			APTR(XnRegion) OR(NULL) ARG(region), 
			APTR(Filter) ARG(directFilter), 
			APTR(Filter) ARG(indirectFilter), 
			Int32 ARG(flags), 
			APTR(BeEdition) OR(NULL) ARG(otherTrail))
	;
	
	/* See FeEdition */
	
	virtual RPTR(BeEdition) rangeWorks (
			APTR(XnRegion) OR(NULL) ARG(region), 
			APTR(Filter) ARG(filter), 
			Int32 ARG(flags), 
			APTR(BeEdition) OR(NULL) ARG(otherTrail))
	;
	
	/* Walk down orgl's O-tree (onto range elements of interest) 
	planting pointers to a Fossil of BackfollowRecorder in the 
	sensor canopy and collecting agenda items to propagate their 
	endorsement and permission filtering info rootward in the 
	sensor canopy.
		Create and schedule a structure of AgendaItems to:
			- First:  Do the filtering info propagation.
			- Second: Find and record any currently matching stamps.
		
		This is done in this order so collection of the future part 
	of recorder information is completed before the present part 
	is extracted, keeping significant information from falling 
	through the crack. */
	
	virtual void scheduleDelayedBackfollow (APTR(RecorderFossil) ARG(fossil), APTR(XnRegion) OR(NULL) ARG(region));
	
	/* Find and record any currently matching Editions. */
	
	virtual void scheduleImmediateBackfollow (APTR(RecorderFossil) ARG(fossil), APTR(XnRegion) OR(NULL) ARG(region));
	
  private:
	CHKPTR(OrglRoot) myOrglRoot;
	CHKPTR(MuSet) OF1(BeWork) myWorks;
	CHKPTR(BertProp) myOwnProp;
	CHKPTR(BertProp) myProp;
	NOCOPY CHKPTR(PrimSet) OR(NULL) OF1(FeFillRangeDetector) myDetectors;
/* Friends for class BeEdition */
friend class Matcher;



};  /* end class BeEdition */



#endif /* BRANGE3X_HXX */

