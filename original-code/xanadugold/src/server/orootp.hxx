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

#ifndef OROOTP_HXX
#define OROOTP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef OROOTX_HXX
#include "orootx.hxx"
#endif /* OROOTX_HXX */

#ifndef OROOTP_OXX
#include "orootp.oxx"
#endif /* OROOTP_OXX */


#ifndef HTREEX_HXX
#include "htreex.hxx"
#endif /* HTREEX_HXX */


#ifndef BRANGE3X_OXX
#include "brange3x.oxx"
#endif /* BRANGE3X_OXX */

#ifndef CANOPYX_OXX
#include "canopyx.oxx"
#endif /* CANOPYX_OXX */

#ifndef NKERNELX_OXX
#include "nkernelx.oxx"
#endif /* NKERNELX_OXX */

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

#ifndef TURTLEX_OXX
#include "turtlex.oxx"
#endif /* TURTLEX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class HBottomCrum 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HBottomCrum : public HistoryCrum {

/* Attributes for class HBottomCrum */
	CONCRETE(HBottomCrum)
	COPY(HBottomCrum,DiskCuisine)
	AUTO_GC(HBottomCrum)
  public: /* instance creation */

	
	static RPTR(HBottomCrum) make ();
	
  public: /* testing */

	/* Return true if there are stamps that
		 point at this orgl. */
	
	virtual BooleanVar hasRefs ();
	
	/* Return true if the receiver can backfollow to trace. */
	
	virtual BooleanVar inTrace (APTR(TracePosition) ARG(trace));
	
	/* Return true if their are no upward pointers.  This is used
		 by OParts to determine if they can be forgotten. */
	
	virtual BooleanVar isEmpty ();
	
	/* If bertCrum is leafward of newBCrum then change it and return true, 
		otherwise return false. */
	
	virtual BooleanVar propagateBCrum (APTR(BertCrum) ARG(newBCrum));
	
  public: /* accessing */

	
	virtual RPTR(TracePosition) hCut ();
	
	/* return the mapping into the domain space of the given trace */
	
	virtual RPTR(Mapping) mappingTo (APTR(TracePosition) ARG(trace), APTR(Mapping) ARG(initial));
	
	
	virtual RPTR(ImmuSet) OF1(OPart) oParents ();
	
  public: /* filtering */

	
	virtual void actualDelayedStoreBackfollow (
			APTR(PropFinder) ARG(finder), 
			APTR(RecorderFossil) ARG(fossil), 
			APTR(ResultRecorder) ARG(recorder), 
			APTR(HashSetCache) OF1(HistoryCrum) ARG(hCrumCache))
	;
	
	
	virtual BooleanVar anyPasses (APTR(PropFinder) ARG(finder));
	
	
	virtual RPTR(BertCrum) bertCrum ();
	
	
	virtual void introduceEdition (APTR(BeEdition) ARG(edition));
	
	/* NOTE: The AgendaItem returned is not yet scheduled.  Doing 
	so is up to my caller. */
	
	virtual RPTR(AgendaItem) propChanger (APTR(PropChange) ARG(change));
	
	
	virtual void removeEdition (APTR(BeEdition) ARG(edition));
	
	
	virtual void ringDetectors (APTR(FeEdition) ARG(edition));
	
  public: /* create */

	
	HBottomCrum (APTR(TracePosition) ARG(trace), APTR(BertCrum) ARG(canopy));
	
  public: /* deferred accessing */

	
	virtual RPTR(XnRegion) fetchRegionIn (
			APTR(BeEdition) ARG(stamp), 
			APTR(TracePosition) ARG(hCut), 
			APTR(XnRegion) ARG(region))
	;
	
  private:
	CHKPTR(TracePosition) myTrace;
	CHKPTR(BertCrum) myBertCrum;
	CHKPTR(MuSet) OF1(BeEditions) myEditions;
};  /* end class HBottomCrum */



#endif /* OROOTP_HXX */

