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

#ifndef TCLUDEX_HXX
#define TCLUDEX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef TCLUDEX_OXX
#include "tcludex.oxx"
#endif /* TCLUDEX_OXX */


#ifndef CANOPYR_HXX
#include "canopyr.hxx"
#endif /* CANOPYR_HXX */

#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */

#ifndef TURTLEX_HXX
#include "turtlex.hxx"
#endif /* TURTLEX_HXX */


#ifndef BRANGE1X_OXX
#include "brange1x.oxx"
#endif /* BRANGE1X_OXX */

#ifndef BRANGE3X_OXX
#include "brange3x.oxx"
#endif /* BRANGE3X_OXX */

#ifndef CANOPYX_OXX
#include "canopyx.oxx"
#endif /* CANOPYX_OXX */

#ifndef CROSSX_OXX
#include "crossx.oxx"
#endif /* CROSSX_OXX */

#ifndef FILTERX_OXX
#include "filterx.oxx"
#endif /* FILTERX_OXX */

#ifndef HTREEX_OXX
#include "htreex.oxx"
#endif /* HTREEX_OXX */

#ifndef IDX_OXX
#include "idx.oxx"
#endif /* IDX_OXX */

#ifndef NKERNELX_OXX
#include "nkernelx.oxx"
#endif /* NKERNELX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef OROOTX_OXX
#include "orootx.oxx"
#endif /* OROOTX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef PROPSX_OXX
#include "propsx.oxx"
#endif /* PROPSX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */


/*  */
/*  */
/* Should only be called if I am not extinct. */

#define BEGIN_REANIMATE(fossil,Type,var)				\
	{							\
		SPTR(Type) var = CAST(Type,(fossil)->secretRecorder());	\
		PLANT_BOMB(ReleaseRecorder,Boom);			\
		ARM_BOMB(Boom,&*(fossil));			\
		{
		
#define END_REANIMATE	}	}



/* ************************************************************************ *
 * 
 *                    Class HashSetCache 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HashSetCache : public Heaper {

/* Attributes for class HashSetCache */
	CONCRETE(HashSetCache)
	EQ(HashSetCache)
	COPY(HashSetCache,DiskCuisine)
	AUTO_GC(HashSetCache)
  public: /* pseudo-constructors */

	
	static RPTR(HashSetCache) make ();
	
	
	static RPTR(HashSetCache) make (UInt32 ARG(size));
	
  public: /* accessing */

	
	virtual BooleanVar hasMember (APTR(Heaper) ARG(aHeaper));
	
	
	virtual void store (APTR(Heaper) ARG(aHeaper));
	
	
	virtual void wipe (APTR(Heaper) ARG(aHeaper));
	
  public: /* create/delete */

	
	HashSetCache (UInt32 ARG(size), TCSJ);
	
  protected: /* protected: creation */

	
	virtual void destruct ();
	
  private:
	UInt32 mySize;
	CHKPTR(PtrArray) myElements;
};  /* end class HashSetCache */



/* ************************************************************************ *
 * 
 *                    Class Matcher 
 *
 * ************************************************************************ */




	/* This is a one-shot agenda item.
	
	When doing a delayed backFollow, after the future is taken 
	care of (by posting recorders in the Sensor Canopy), the past 
	needs to be checked (by walking the HTree northwards filtered 
	by the Bert Canopy).  This AgendaItem is a one-shot used to 
	remember to backFollow thru the past.  (myOrglRoot == NULL 
	when the shot has been done.) */

class Matcher : public AgendaItem {

/* Attributes for class Matcher */
	CONCRETE(Matcher)
	SHEPHERD_PATRIARCH(Matcher,AgendaItem)
	LOCKED(Matcher)
	COPY(Matcher,DiskCuisine)
	AUTO_GC(Matcher)
  public: /* creation */

	
	static RPTR(Matcher) make (
			APTR(OrglRoot) ARG(oroot), 
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil))
	;
	
  public: /* accessing */

	
	virtual BooleanVar step ();
	
  public: /* creation */

	
	Matcher (
			APTR(OrglRoot) ARG(oroot), 
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil))
	;
	
	
	virtual void dismantle ();
	
  private:
	CHKPTR(OrglRoot) OR(NULL) myOrglRoot;
	CHKPTR(PropFinder) myFinder;
	CHKPTR(RecorderFossil) myFossil;
};  /* end class Matcher */



/* ************************************************************************ *
 * 
 *                    Class NorthRecorderChecker 
 *
 * ************************************************************************ */




	/* This is a one-shot agenda item.
	
	See comment in SouthRecorderChecker for constraints and 
	relationships to other pieces of the algorithm.
	
	Looks for and triggers WorkRecorders lying northward of this 
	Edition up to the next Edition. The Finder should only be 
	carrying around Works. */

class NorthRecorderChecker : public AgendaItem {

/* Attributes for class NorthRecorderChecker */
	CONCRETE(NorthRecorderChecker)
	SHEPHERD_PATRIARCH(NorthRecorderChecker,AgendaItem)
	LOCKED(NorthRecorderChecker)
	COPY(NorthRecorderChecker,DiskCuisine)
	AUTO_GC(NorthRecorderChecker)
  public: /* create */

	
	static RPTR(AgendaItem) make (APTR(BeEdition) ARG(edition), APTR(PropFinder) ARG(finder));
	
  public: /* accessing */

	
	virtual BooleanVar step ();
	
  public: /* create */

	
	NorthRecorderChecker (APTR(BeEdition) ARG(edition), APTR(PropFinder) ARG(finder));
	
  private:
	CHKPTR(BeEdition) myEdition;
	CHKPTR(PropFinder) myFinder;
};  /* end class NorthRecorderChecker */



/* ************************************************************************ *
 * 
 *                    Class RecorderFossil 
 *
 * ************************************************************************ */


/* exceptions: exceptions */

ORDER_BOMB(ReleaseRecorder, SPTR(RecorderFossil) );

;



	/* A Fossil for a ResultRecorder, which also stores its 
	permissions, filters, and a cache of the results which have 
	already been recorded. */

class RecorderFossil : public Abraham {

/* Attributes for class RecorderFossil */
	DEFERRED(RecorderFossil)
	SHEPHERD_PATRIARCH(RecorderFossil,Abraham)
	COPY(RecorderFossil,DiskCuisine)
	DEFERRED_LOCKED(RecorderFossil)
	AUTO_GC(RecorderFossil)
  public: /* create */

	
	static RPTR(RecorderFossil) transcluders (
			BooleanVar ARG(isDirectOnly), 
			APTR(IDRegion) ARG(loginAuthority), 
			APTR(Filter) OF1(Tuple OF2(ID,ID)) ARG(directFilter), 
			APTR(Filter) OF1(Tuple OF2(ID,ID)) ARG(indirectFilter), 
			APTR(TrailBlazer) ARG(trailBlazer))
	;
	
	
	static RPTR(RecorderFossil) works (
			BooleanVar ARG(isDirectOnly), 
			APTR(IDRegion) ARG(loginAuthority), 
			APTR(Filter) OF1(Tuple OF2(ID,ID)) ARG(endorsementsFilter), 
			APTR(TrailBlazer) ARG(trailBlazer))
	;
	
  public: /* accessing */

	
	virtual void addItem (APTR(AgendaItem) ARG(item));
	
	/* Should only be called from BeEdition::fossilRelease().  
	Results in my becoming extinct. */
	
	virtual void extinguish (APTR(TrailBlazer) ARG(trailBlazer));
	
	/* As a premature optimization, we don't destroy the waldo 
	when the count goes to zero, but rather when we consider 
	purging while the count is zero. */
	
	virtual void releaseRecorder ();
	
	
	virtual void removeItem (APTR(AgendaItem) ARG(item));
	
	/* The Recorder of which this Fossil is the imprint. If 
	necessary, reconstruct it using the information stored in the imprint.
		Should only be called if I am not extinct
		Should only be called from the reanimate macro. */
	
	virtual RPTR(ResultRecorder) secretRecorder ();
	
  public: /* testing */

	/* A Fossil (unlike a Grabber or an Orgl) does not prevent 
	the grabbed IObject from being dismantled.  Instead, if the 
	IObject does get dismantled, then the Fossil is considered 
	extinct.  A waldo may not be gotten from an extinct fossil 
	(if the species is really extinct, then it cannot be revived 
	from its remaining fossils). */
	
	virtual BooleanVar isExtinct ();
	
	/* I can`t go to disk while someone has my WaldoSocket and 
	might be doing 
		something with the Waldo in it. */
	
	virtual BooleanVar isPurgeable ();
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK NOLOCK void restartRecorderFossil (APTR(Rcvr) ARG(rcvr) = NULL);
	
  protected: /* protected: destruction */

	
	virtual void dismantle ();
	
  protected: /* protected: accessing */

	/* Make the right kind of Recorder for this fossil */
	
	virtual RPTR(ResultRecorder) actualRecorder () DEFERRED_FUNC;
	
	
	virtual void memoryCheck ();
	
	
	virtual RPTR(TrailBlazer) trailBlazer ();
	
  public: /* create */

	
	RecorderFossil (APTR(IDRegion) ARG(loginAuthority), APTR(TrailBlazer) ARG(trailBlazer));
	
  public: /* backfollow */

	/* Store recording agents into a SensorCrum on data in the 
	original Edition that was a source of the query */
	
	virtual void storeDataRecordingAgents (APTR(SensorCrum) ARG(sensorCrum), APTR(Agenda) ARG(agenda));
	
	/* Store recording agents into a SensorCrum on partiality in 
	the original Edition that was a source of the query */
	
	virtual void storePartialityRecordingAgents (APTR(SensorCrum) ARG(sensorCrum), APTR(Agenda) ARG(agenda));
	
	/* Store recording agents into a SensorCrum on a RangeElement 
	in the original Edition that was a source of the query */
	
	virtual void storeRangeElementRecordingAgents (
			APTR(BeRangeElement) ARG(rangeElement), 
			APTR(SensorCrum) ARG(sensorCrum), 
			APTR(Agenda) ARG(agenda))
	;
	
  private:
	CHKPTR(IDRegion) myLoginAuthority;
	CHKPTR(TrailBlazer) OR(NULL) myTrailBlazer;
	NOCOPY CHKPTR(ResultRecorder) OR(NULL) myRecorder;
	NOCOPY IntegerVar myRecorderCount;
	IntegerVar myAgendaCount;
};  /* end class RecorderFossil */



/* ************************************************************************ *
 * 
 *                    Class RecorderHoister 
 *
 * ************************************************************************ */




	/*  NOT.A.TYPE I exist to hoist myCargo (a set of recorder 
	fossils) up the Sensor canopy as far as it needs to go, as 
	well as to propogate the props resulting from the planting of 
	these recorders.  When I no longer have any cargo to hoist, I 
	devolve into an ActualPropChanger
	
	I assume that RecorderCheckers do their southward walk in a 
	single step, so I can hoist recorders by an algorithm that 
	would occasionally cause a recorder to be missed if 
	RecorderCheckers were incremental. */

class RecorderHoister : public PropChanger {

/* Attributes for class RecorderHoister */
	CONCRETE(RecorderHoister)
	LOCKED(RecorderHoister)
	COPY(RecorderHoister,DiskCuisine)
	MAY_BECOME(RecorderHoister,ActualPropChanger)
	AUTO_GC(RecorderHoister)
  public: /* creation */

	/* Create a RecorderHoister. */
	
	static RPTR(AgendaItem) make (APTR(CanopyCrum) ARG(crum), APTR(ScruSet) OF1(RecorderFossil) ARG(aSetOfRecorders));
	
  public: /* creation */

	
	RecorderHoister (APTR(CanopyCrum) ARG(crum), APTR(MuSet) OF1(RecorderFossil) ARG(aSetOfRecorders));
	
  public: /* accessing */

	
	virtual BooleanVar step ();
	
  private:
	CHKPTR(MuSet) OF1(TransclusionFossil) myCargo;
};  /* end class RecorderHoister */



/* ************************************************************************ *
 * 
 *                    Class RecorderTrigger 
 *
 * ************************************************************************ */




	/* This is a one-shot agenda item.
	
	Asks myFossil to record myElement.
	
	When an answer to a delayed backFollow is found, whether thru 
	a northwards h-walk (filtered by the Bert Canopy) of a 
	southwards o-walk (filtered by the Sensor Canopy), instead of 
	actually recording the answer into the backFollow trail 
	immediately, we shedule a RecorderTrigger to do the job. */

class RecorderTrigger : public AgendaItem {

/* Attributes for class RecorderTrigger */
	CONCRETE(RecorderTrigger)
	SHEPHERD_PATRIARCH(RecorderTrigger,AgendaItem)
	LOCKED(RecorderTrigger)
	COPY(RecorderTrigger,DiskCuisine)
	AUTO_GC(RecorderTrigger)
  public: /* creation */

	
	static RPTR(RecorderTrigger) make (APTR(RecorderFossil) ARG(fossil), APTR(BeRangeElement) ARG(element));
	
  public: /* accessing */

	
	virtual BooleanVar step ();
	
  public: /* creation */

	
	RecorderTrigger (APTR(RecorderFossil) ARG(fossil), APTR(BeRangeElement) ARG(element));
	
	
	virtual void dismantle ();
	
  private:
	CHKPTR(RecorderFossil) OR(NULL) myFossil;
	CHKPTR(BeRangeElement) myElement;
};  /* end class RecorderTrigger */



/* ************************************************************************ *
 * 
 *                    Class ResultRecorder 
 *
 * ************************************************************************ */




	/* Represents the persistent embodiment of a query operation. 
	Can be stored on disk in the form of a RecorderFossil. The 
	abstract protocol deals with:
		- caching previous results to avoid duplication
		- storing results in a trail at unique positions
		- managing persistent permissions
		- looking for immediate results
		- checking whether a good candidate (identified by the 
	canopy props) should really go into the trail */

class ResultRecorder : public Heaper {

/* Attributes for class ResultRecorder */
	DEFERRED(ResultRecorder)
	EQ(ResultRecorder)
	AUTO_GC(ResultRecorder)
  public: /* accessing */

	/* Whether this recorder accepts this kind of RangeElement */
	
	virtual BooleanVar accepts (APTR(BeRangeElement) ARG(element)) DEFERRED_FUNC;
	
	
	virtual RPTR(IDRegion) actualAuthority ();
	
	/* Something to find potential candidates given a source for 
	the query */
	
	virtual RPTR(PropFinder) bertPropFinder ();
	
	/* The endorsements I am looking for */
	
	virtual RPTR(Filter) endorsementsFilter ();
	
	/* Whether the recorder is for a query with the 
	directContainersOnly flag */
	
	virtual BooleanVar isDirectOnly () DEFERRED_FUNC;
	
	
	virtual RPTR(FeKeyMaster) keyMaster ();
	
	/* The permissions I am looking for */
	
	virtual RPTR(Filter) OF1(ID) permissionsFilter ();
	
	/* A SensorProp which corresponds to what I am looking for */
	
	virtual RPTR(SensorProp) sensorProp ();
	
  public: /* recording */

	/* tell my TrailBlazer to recorder it */
	
	virtual void record (APTR(BeRangeElement) ARG(answer));
	
	/* Trigger myself if I match the finder's profile */
	
	virtual void triggerIfMatching (APTR(PropFinder) ARG(finder), APTR(RecorderFossil) ARG(fossil));
	
  public: /* create */

	
	ResultRecorder (
			APTR(Filter) ARG(endorsementsFilter), 
			APTR(CrossRegion) ARG(relevantEndorsements), 
			APTR(TrailBlazer) ARG(trailBlazer))
	;
	
  public: /* backfollow */

	/* The immediate part of the backfollow has reached an 
	Edition while traversing northwards. I now get to decide what 
	to do next. */
	
	virtual void delayedStoreBackfollow (
			APTR(BeEdition) ARG(edition), 
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	 DEFERRED_SUBR;
	
	/* The immediate part of the backfollow has reached an 
	RangeElement of the original Edition. I now get to decide 
	what to do next to continue the operation */
	
	virtual void delayedStoreMatching (
			APTR(BeRangeElement) ARG(element), 
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	;
	
  private:
	CHKPTR(Filter) myPermissionsFilter;
	CHKPTR(Filter) myEndorsementsFilter;
	CHKPTR(CrossRegion) myRelevantEndorsements;
	CHKPTR(FeKeyMaster) myKeyMaster;
	CHKPTR(TrailBlazer) myTrailBlazer;
};  /* end class ResultRecorder */



/* ************************************************************************ *
 * 
 *                    Class   EditionRecorder 
 *
 * ************************************************************************ */




	/* Represents the a persistent transcluders or 
	rangeTranscluders query */

class EditionRecorder : public ResultRecorder {

/* Attributes for class EditionRecorder */
	DEFERRED(EditionRecorder)
	AUTO_GC(EditionRecorder)
  public: /* accessing */

	
	virtual BooleanVar accepts (APTR(BeRangeElement) ARG(element));
	
	
	virtual RPTR(Filter) directFilter ();
	
	
	virtual RPTR(Filter) indirectFilter ();
	
	
	virtual BooleanVar isDirectOnly () DEFERRED_FUNC;
	
  public: /* create */

	
	EditionRecorder (
			APTR(Filter) ARG(directFilter), 
			APTR(Filter) ARG(indirectFilter), 
			APTR(TrailBlazer) ARG(trailBlazer))
	;
	
  public: /* backfollow */

	
	virtual void delayedStoreBackfollow (
			APTR(BeEdition) ARG(edition), 
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	;
	
  private:
	CHKPTR(Filter) myDirectFilter;
	CHKPTR(Filter) myIndirectFilter;
};  /* end class EditionRecorder */



/* ************************************************************************ *
 * 
 *                    Class   WorkRecorder 
 *
 * ************************************************************************ */




	/* Represents the a persistent works or rangeWorks query */

class WorkRecorder : public ResultRecorder {

/* Attributes for class WorkRecorder */
	DEFERRED(WorkRecorder)
	NO_GC(WorkRecorder)
  public: /* create */

	
	WorkRecorder (APTR(Filter) ARG(endorsementsFilter), APTR(TrailBlazer) ARG(trailBlazer));
	
  public: /* accessing */

	
	virtual BooleanVar accepts (APTR(BeRangeElement) ARG(element));
	
	
	virtual BooleanVar isDirectOnly () DEFERRED_FUNC;
	
  public: /* backfollow */

	
	virtual void delayedStoreBackfollow (
			APTR(BeEdition) ARG(edition), 
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	 DEFERRED_SUBR;
	
	/* If there are any Works directly on the RangeElement which 
	pass the filters, record them */
	
	virtual void recordImmediateWorks (APTR(BeRangeElement) ARG(element), APTR(RecorderFossil) ARG(fossil));
	

};  /* end class WorkRecorder */



/* ************************************************************************ *
 * 
 *                    Class SouthRecorderChecker 
 *
 * ************************************************************************ */




	/* This is a one-shot agenda item.
	
	When changing the prop(ertie)s of a Stamp, we need to first 
	take care of the future backFollow requests (by updating the 
	Bert Canopy so the filtered HTree walk will find this Stamp) 
	before taking care of the past (the Recorders that were 
	looking for this Stamp in their future).  This AgendaItem is 
	to remember to take care of the past (by doing a southwards 
	o-walk filtered by the Sensor Canopy) after the future is 
	properly dealt with.
	
	The RecorderHoister assumes that this southward walk is done 
	in a single-step, so it is free to make changes in a way 
	that, if it were interleaved with an incremental southward 
	walk by a RecorderChecker looking for the recorder(s) being 
	hoisted, might cause the hoisted recorder to be missed.
	
	This is also used recursively by this very o-walk to schedule 
	a further o-walk on appropriate sub-Stamps.
	
	Keeping track of whether persistent objects are 
	garbage-on-disk during AgendaItem processing only remains 
	open for Stamps, except here where it also arises for an 
	OrglRoot.  The OrglRoot is itself held by a persistent Stamp, 
	from which it can be easily obtained, so we should probably 
	just hold onto two Stamps instead of a Stamp and an OrglRoot 
	(so I only have to solve the "how to keep it around" problem 
	for Stamps). */

class SouthRecorderChecker : public AgendaItem {

/* Attributes for class SouthRecorderChecker */
	CONCRETE(SouthRecorderChecker)
	SHEPHERD_PATRIARCH(SouthRecorderChecker,AgendaItem)
	LOCKED(SouthRecorderChecker)
	COPY(SouthRecorderChecker,DiskCuisine)
	AUTO_GC(SouthRecorderChecker)
  public: /* creation */

	
	static RPTR(SouthRecorderChecker) make (
			APTR(OrglRoot) ARG(oroot), 
			APTR(PropFinder) ARG(finder), 
			APTR(SensorCrum) OR(NULL) ARG(scrum))
	;
	
  public: /* creation */

	
	SouthRecorderChecker (
			APTR(OrglRoot) ARG(oroot), 
			APTR(PropFinder) ARG(finder), 
			APTR(SensorCrum) OR(NULL) ARG(scrum))
	;
	
	
	virtual void dismantle ();
	
  public: /* accessing */

	
	virtual BooleanVar step ();
	
  private:
	CHKPTR(OrglRoot) OR(NULL) myORoot;
	CHKPTR(PropFinder) myFinder;
	CHKPTR(SensorCrum) OR(NULL) mySCrum;
};  /* end class SouthRecorderChecker */



/* ************************************************************************ *
 * 
 *                    Class TrailBlazer 
 *
 * ************************************************************************ */


/* exceptions: */

PROBLEM_LIST(RecordFailureFilter,3,(MustBeOwner,CantMakeIdentical,NotInTable));



	/* The object responsible for recording results into a trail.  */

class TrailBlazer : public Abraham {

/* Attributes for class TrailBlazer */
	CONCRETE(TrailBlazer)
	SHEPHERD_PATRIARCH(TrailBlazer,Abraham)
	COPY(TrailBlazer,DiskCuisine)
	EQ(TrailBlazer)
	LOCKED(TrailBlazer)
	AUTO_GC(TrailBlazer)
  public: /* create */

	/* should only be called from Edition::getOrMakeTrailBlazer */
	
	static RPTR(TrailBlazer) make (APTR(BeEdition) ARG(trail));
	
  public: /* create */

	
	TrailBlazer ();
	
  private: /* private: */

	
	virtual void setEdition (APTR(BeEdition) ARG(trail));
	
  public: /* accessing */

	/* Whether this TrailBlazer was in fact successfully attached */
	
	virtual BooleanVar isAlive ();
	
	/* record the answer into my Edition, and keep only the partial part.
	
		Should usually suppress redundant records of the same 
	object.  (These are typically generated by a race between the 
	now and future parts of a backfollow, which are guaranteed to 
	err by overlapping rather than gapping.  They may also be 
	generated by a crash/reboot during AgendaItem processing.) */
	
	virtual void record (APTR(BeRangeElement) ARG(answer));
	
  public: /* storage */

	/* Increment the reference count */
	
	virtual void addReference (APTR(Abraham) ARG(object));
	
	/* Decrement the reference count */
	
	virtual void removeReference (APTR(Abraham) ARG(object));
	
  private:
	CHKPTR(BeEdition) myTrail;
	CHKPTR(HashSetCache) OF1(BeRangeElement) myRecorded;
	IntegerVar myRefCount;
};  /* end class TrailBlazer */


#ifdef USE_INLINE
#ifndef TCLUDEX_IXX
#include "tcludex.ixx"
#endif /* TCLUDEX_IXX */


#endif /* USE_INLINE */


#endif /* TCLUDEX_HXX */

