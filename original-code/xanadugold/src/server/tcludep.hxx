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

#ifndef TCLUDEP_HXX
#define TCLUDEP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef TCLUDEX_HXX
#include "tcludex.hxx"
#endif /* TCLUDEX_HXX */

#ifndef TCLUDEP_OXX
#include "tcludep.oxx"
#endif /* TCLUDEP_OXX */


#ifndef BRANGE1X_OXX
#include "brange1x.oxx"
#endif /* BRANGE1X_OXX */

#ifndef BRANGE3X_OXX
#include "brange3x.oxx"
#endif /* BRANGE3X_OXX */

#ifndef CANOPYX_OXX
#include "canopyx.oxx"
#endif /* CANOPYX_OXX */

#ifndef FILTERX_OXX
#include "filterx.oxx"
#endif /* FILTERX_OXX */

#ifndef HTREEX_OXX
#include "htreex.oxx"
#endif /* HTREEX_OXX */

#ifndef IDX_OXX
#include "idx.oxx"
#endif /* IDX_OXX */

#ifndef PROPSX_OXX
#include "propsx.oxx"
#endif /* PROPSX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class DirectEditionRecorder 
 *
 * ************************************************************************ */




	/* Represents the a persistent transcluders or 
	rangeTranscluders query with directContainersOnly flag on */

class DirectEditionRecorder : public EditionRecorder {

/* Attributes for class DirectEditionRecorder */
	CONCRETE(DirectEditionRecorder)
	NOT_A_TYPE(DirectEditionRecorder)
	NO_GC(DirectEditionRecorder)
  public: /* accessing */

	
	virtual BooleanVar isDirectOnly ();
	
  public: /* create */

	
	DirectEditionRecorder (
			APTR(Filter) ARG(directFilter), 
			APTR(Filter) ARG(indirectFilter), 
			APTR(TrailBlazer) ARG(trailBlazer))
	;
	

};  /* end class DirectEditionRecorder */



/* ************************************************************************ *
 * 
 *                    Class DirectWorkRecorder 
 *
 * ************************************************************************ */




	/* Represents the a persistent works or rangeWorks query with 
	the directContainersOnly flag on */

class DirectWorkRecorder : public WorkRecorder {

/* Attributes for class DirectWorkRecorder */
	CONCRETE(DirectWorkRecorder)
	NOT_A_TYPE(DirectWorkRecorder)
	NO_GC(DirectWorkRecorder)
  public: /* create */

	
	DirectWorkRecorder (APTR(Filter) ARG(endorsementsFilter), APTR(TrailBlazer) ARG(trailBlazer));
	
  public: /* accessing */

	
	virtual BooleanVar isDirectOnly ();
	
  public: /* backfollow */

	
	virtual void delayedStoreBackfollow (
			APTR(BeEdition) ARG(edition), 
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	;
	
	
	virtual void delayedStoreMatching (
			APTR(BeRangeElement) ARG(element), 
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	;
	

};  /* end class DirectWorkRecorder */



/* ************************************************************************ *
 * 
 *                    Class EditionRecorderFossil 
 *
 * ************************************************************************ */




	/* A Fossil for an EditionRecorder. */

class EditionRecorderFossil : public RecorderFossil {

/* Attributes for class EditionRecorderFossil */
	DEFERRED(EditionRecorderFossil)
	SHEPHERD_PATRIARCH(EditionRecorderFossil,RecorderFossil)
	COPY(EditionRecorderFossil,DiskCuisine)
	DEFERRED_LOCKED(EditionRecorderFossil)
	NOT_A_TYPE(EditionRecorderFossil)
	AUTO_GC(EditionRecorderFossil)
  protected: /* protected: accessing */

	
	virtual RPTR(ResultRecorder) actualRecorder () DEFERRED_FUNC;
	
	
	virtual NOLOCK RPTR(Filter) directFilter ();
	
	
	virtual NOLOCK RPTR(Filter) indirectFilter ();
	
  public: /* create */

	
	EditionRecorderFossil (
			APTR(IDRegion) ARG(loginAuthority), 
			APTR(Filter) ARG(directFilter), 
			APTR(Filter) ARG(indirectFilter), 
			APTR(TrailBlazer) ARG(trailBlazer))
	;
	
  private:
	CHKPTR(Filter) myDirectFilter;
	CHKPTR(Filter) myIndirectFilter;
	friend class RecorderFossil;
};  /* end class EditionRecorderFossil */



/* ************************************************************************ *
 * 
 *                    Class   DirectEditionRecorderFossil 
 *
 * ************************************************************************ */




	/* A Fossil for an EditionRecorder with the directOnly flag set. */

class DirectEditionRecorderFossil : public EditionRecorderFossil {

/* Attributes for class DirectEditionRecorderFossil */
	CONCRETE(DirectEditionRecorderFossil)
	SHEPHERD_PATRIARCH(DirectEditionRecorderFossil,EditionRecorderFossil)
	COPY(DirectEditionRecorderFossil,DiskCuisine)
	LOCKED(DirectEditionRecorderFossil)
	NOT_A_TYPE(DirectEditionRecorderFossil)
	NO_GC(DirectEditionRecorderFossil)
  protected: /* protected: accessing */

	
	virtual RPTR(ResultRecorder) actualRecorder ();
	
  public: /* create */

	
	DirectEditionRecorderFossil (
			APTR(IDRegion) ARG(loginAuthority), 
			APTR(Filter) ARG(directFilter), 
			APTR(Filter) ARG(indirectFilter), 
			APTR(TrailBlazer) ARG(trailBlazer))
	;
	

	friend class RecorderFossil;
};  /* end class DirectEditionRecorderFossil */



/* ************************************************************************ *
 * 
 *                    Class   IndirectEditionRecorderFossil 
 *
 * ************************************************************************ */




	/* A Fossil for an EditionRecorder with the directOnly flag off. */

class IndirectEditionRecorderFossil : public EditionRecorderFossil {

/* Attributes for class IndirectEditionRecorderFossil */
	CONCRETE(IndirectEditionRecorderFossil)
	SHEPHERD_PATRIARCH(IndirectEditionRecorderFossil,EditionRecorderFossil)
	COPY(IndirectEditionRecorderFossil,DiskCuisine)
	LOCKED(IndirectEditionRecorderFossil)
	NOT_A_TYPE(IndirectEditionRecorderFossil)
	NO_GC(IndirectEditionRecorderFossil)
  protected: /* protected: accessing */

	
	virtual RPTR(ResultRecorder) actualRecorder ();
	
  public: /* create */

	
	IndirectEditionRecorderFossil (
			APTR(IDRegion) ARG(loginAuthority), 
			APTR(Filter) ARG(directFilter), 
			APTR(Filter) ARG(indirectFilter), 
			APTR(TrailBlazer) ARG(trailBlazer))
	;
	

	friend class RecorderFossil;
};  /* end class IndirectEditionRecorderFossil */



/* ************************************************************************ *
 * 
 *                    Class IndirectEditionRecorder 
 *
 * ************************************************************************ */




	/* Represents the a persistent transcluders or 
	rangeTranscluders query with directContainersOnly flag off */

class IndirectEditionRecorder : public EditionRecorder {

/* Attributes for class IndirectEditionRecorder */
	CONCRETE(IndirectEditionRecorder)
	NOT_A_TYPE(IndirectEditionRecorder)
	NO_GC(IndirectEditionRecorder)
  public: /* accessing */

	
	virtual BooleanVar isDirectOnly ();
	
  public: /* create */

	
	IndirectEditionRecorder (
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
	

};  /* end class IndirectEditionRecorder */



/* ************************************************************************ *
 * 
 *                    Class IndirectWorkRecorder 
 *
 * ************************************************************************ */




	/* Represents the a persistent works or rangeWorks query with 
	the directContainersOnly flag off */

class IndirectWorkRecorder : public WorkRecorder {

/* Attributes for class IndirectWorkRecorder */
	CONCRETE(IndirectWorkRecorder)
	NOT_A_TYPE(IndirectWorkRecorder)
	NO_GC(IndirectWorkRecorder)
  public: /* create */

	
	IndirectWorkRecorder (APTR(Filter) ARG(endorsementsFilter), APTR(TrailBlazer) ARG(trailBlazer));
	
  public: /* accessing */

	
	virtual BooleanVar isDirectOnly ();
	
  public: /* backfollow */

	
	virtual void delayedStoreBackfollow (
			APTR(BeEdition) ARG(edition), 
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	;
	
	
	virtual void delayedStoreMatching (
			APTR(BeRangeElement) ARG(element), 
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	;
	

};  /* end class IndirectWorkRecorder */



/* ************************************************************************ *
 * 
 *                    Class WorkRecorderFossil 
 *
 * ************************************************************************ */




	/* A Fossil for a WorkRecorder. */

class WorkRecorderFossil : public RecorderFossil {

/* Attributes for class WorkRecorderFossil */
	DEFERRED(WorkRecorderFossil)
	SHEPHERD_PATRIARCH(WorkRecorderFossil,RecorderFossil)
	COPY(WorkRecorderFossil,DiskCuisine)
	DEFERRED_LOCKED(WorkRecorderFossil)
	NOT_A_TYPE(WorkRecorderFossil)
	AUTO_GC(WorkRecorderFossil)
  protected: /* protected: accessing */

	
	virtual RPTR(ResultRecorder) actualRecorder () DEFERRED_FUNC;
	
	
	virtual NOLOCK RPTR(Filter) endorsementsFilter ();
	
  public: /* create */

	
	WorkRecorderFossil (
			APTR(IDRegion) ARG(loginAuthority), 
			APTR(Filter) ARG(endorsementsFilter), 
			APTR(TrailBlazer) ARG(trailBlazer))
	;
	
  private:
	CHKPTR(Filter) myEndorsementsFilter;
	friend class RecorderFossil;
};  /* end class WorkRecorderFossil */



/* ************************************************************************ *
 * 
 *                    Class   DirectWorkRecorderFossil 
 *
 * ************************************************************************ */




	/* A Fossil for a DirectWorkRecorder. */

class DirectWorkRecorderFossil : public WorkRecorderFossil {

/* Attributes for class DirectWorkRecorderFossil */
	CONCRETE(DirectWorkRecorderFossil)
	SHEPHERD_PATRIARCH(DirectWorkRecorderFossil,WorkRecorderFossil)
	COPY(DirectWorkRecorderFossil,DiskCuisine)
	LOCKED(DirectWorkRecorderFossil)
	NOT_A_TYPE(DirectWorkRecorderFossil)
	NO_GC(DirectWorkRecorderFossil)
  protected: /* protected: accessing */

	
	virtual RPTR(ResultRecorder) actualRecorder ();
	
  public: /* create */

	
	DirectWorkRecorderFossil (
			APTR(IDRegion) ARG(loginAuthority), 
			APTR(Filter) ARG(endorsementsFilter), 
			APTR(TrailBlazer) ARG(trailBlazer))
	;
	
  public: /* backfollow */

	/* do nothing */
	
	virtual NOLOCK void storeDataRecordingAgents (APTR(SensorCrum) ARG(sensorCrum), APTR(Agenda) ARG(agenda));
	
	
	virtual void storeRangeElementRecordingAgents (
			APTR(BeRangeElement) ARG(rangeElement), 
			APTR(SensorCrum) ARG(sensorCrum), 
			APTR(Agenda) ARG(agenda))
	;
	

	friend class RecorderFossil;
};  /* end class DirectWorkRecorderFossil */



/* ************************************************************************ *
 * 
 *                    Class   IndirectWorkRecorderFossil 
 *
 * ************************************************************************ */




	/* A Fossil for a IndirectWorkRecorder. */

class IndirectWorkRecorderFossil : public WorkRecorderFossil {

/* Attributes for class IndirectWorkRecorderFossil */
	CONCRETE(IndirectWorkRecorderFossil)
	SHEPHERD_PATRIARCH(IndirectWorkRecorderFossil,WorkRecorderFossil)
	COPY(IndirectWorkRecorderFossil,DiskCuisine)
	LOCKED(IndirectWorkRecorderFossil)
	NOT_A_TYPE(IndirectWorkRecorderFossil)
	NO_GC(IndirectWorkRecorderFossil)
  protected: /* protected: accessing */

	
	virtual RPTR(ResultRecorder) actualRecorder ();
	
  public: /* create */

	
	IndirectWorkRecorderFossil (
			APTR(IDRegion) ARG(loginAuthority), 
			APTR(Filter) ARG(endorsementsFilter), 
			APTR(TrailBlazer) ARG(trailBlazer))
	;
	

	friend class RecorderFossil;
};  /* end class IndirectWorkRecorderFossil */



#endif /* TCLUDEP_HXX */

