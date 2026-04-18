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

#ifndef GRANMAPX_HXX
#define GRANMAPX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef GRANMAPX_OXX
#include "granmapx.oxx"
#endif /* GRANMAPX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */


#ifndef BRANGE1X_OXX
#include "brange1x.oxx"
#endif /* BRANGE1X_OXX */

#ifndef BRANGE2X_OXX
#include "brange2x.oxx"
#endif /* BRANGE2X_OXX */

#ifndef BRANGE3X_OXX
#include "brange3x.oxx"
#endif /* BRANGE3X_OXX */

#ifndef COUNTERX_OXX
#include "counterx.oxx"
#endif /* COUNTERX_OXX */

#ifndef CROSSX_OXX
#include "crossx.oxx"
#endif /* CROSSX_OXX */

#ifndef DISKMANX_OXX
#include "diskmanx.oxx"
#endif /* DISKMANX_OXX */

#ifndef ENTX_OXX
#include "entx.oxx"
#endif /* ENTX_OXX */

#ifndef FILTERX_OXX
#include "filterx.oxx"
#endif /* FILTERX_OXX */

#ifndef FLUIDX_OXX
#include "fluidx.oxx"
#endif /* FLUIDX_OXX */

#ifndef IDX_OXX
#include "idx.oxx"
#endif /* IDX_OXX */

#ifndef NKERNELX_OXX
#include "nkernelx.oxx"
#endif /* NKERNELX_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef PRIMVALX_OXX
#include "primvalx.oxx"
#endif /* PRIMVALX_OXX */

#ifndef SEQUENCX_OXX
#include "sequencx.oxx"
#endif /* SEQUENCX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */

#ifndef TABLESX_OXX
#include "tablesx.oxx"
#endif /* TABLESX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class BeGrandMap 
 *
 * ************************************************************************ */



/* Initializers for BeGrandMap */
DESIGN_FLUID(BeGrandMap,CurrentGrandMap);	/* in BeGrandMap */


/* global: time */

/* Seconds since the beginning of time */

IntegerVar  xuTime ();



	/* Rewrite notes
	3/7/92 ravi
	- we had decided to have myRangeElementIDs be a 
	GrandSetTable, but for now its just a Table onto IDRegions, 
	since that is what we have implemented right now */

class BeGrandMap : public Abraham {

/* Attributes for class BeGrandMap */
	CONCRETE(BeGrandMap)
	SHEPHERD_PATRIARCH(BeGrandMap,Abraham)
	LOCKED(BeGrandMap)
	COPY(BeGrandMap,DiskCuisine)
	AUTO_GC(BeGrandMap)

/* Initializers for BeGrandMap */


  private: /* private: pseudo constructors */

	
	static RPTR(BeGrandMap) make ();
	
  private: /* private: booting */

	/* Check that the BeClub structure matches the Editions 
	underneath them */
	
	virtual void clubConsistencyCheck ();
	
	
	virtual void coldBoot ();
	
  private: /* private: create */

	
	BeGrandMap (APTR(Sequence) ARG(identifier), TCSJ);
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK void restartBeGrandMap (APTR(Rcvr) ARG(rcvr));
	
  public: /* purging */

	/* Allow the GrandMap to be purged.  The GrandMap should NOT 
	be used after this is called. */
	
	virtual NOLOCK void bePurgeable ();
	
	/* The Grandmap never gets purged unless explicitly allowed 
	by calling bePurgeable. */
	
	virtual NOLOCK BooleanVar isPurgeable ();
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  public: /* accessing */

	/* See FeAdminer */
	
	virtual NOLOCK void acceptConnections (BooleanVar ARG(open));
	
	/* Remember the two way association between value and its new ID. */
	
	virtual RPTR(ID) assignID (APTR(BeRangeElement) ARG(value));
	
	/* Remember the two way association between value and the 
	supplied ID. */
	
	virtual BooleanVar tryIntroduce (APTR(ID) ARG(iD), APTR(BeRangeElement) ARG(value));
	
	
	virtual NOLOCK RPTR(ID) clubDirectoryID ();
	
	
	virtual NOLOCK RPTR(FilterSpace) endorsementFilterSpace ();
	
	
	virtual NOLOCK RPTR(CrossSpace) endorsementSpace ();
	
	/* The actual BeRangeElement at that ID, or NULL if there is none */
	
	virtual RPTR(BeRangeElement) OR(NULL) fetch (APTR(ID) ARG(iD));
	
	/* If there is a club at the given ID, return it. */
	
	virtual RPTR(BeClub) OR(NULL) fetchClub (APTR(ID) OR(NULL) ARG(iD));
	
	
	virtual RPTR(FeEdition) gateLockSmithEdition ();
	
	/* The actual BeRangeElement at that ID, or blast if there is none */
	
	virtual RPTR(BeRangeElement) get (APTR(ID) ARG(iD));
	
	/* Get a BeClub from the GrandMap. */
	
	virtual RPTR(BeClub) getClub (APTR(ID) ARG(iD));
	
	/* Get what is at the the given ID as a front end object; 
	blast if there is nothing there */
	
	virtual RPTR(FeRangeElement) getFe (APTR(ID) ARG(iD));
	
	/* Get a canonical Counter for an IDSpace, or make a new one */
	
	virtual RPTR(Counter) getOrMakeIDCounter (APTR(Sequence) OR(NULL) ARG(backend), IntegerVar ARG(number));
	
	/* If there is already an IDHolder for the ID then return it, 
	otherwise make one */
	
	virtual RPTR(BeIDHolder) getOrMakeIDHolder (APTR(ID) ARG(iD));
	
	/* The FilterSpace on global IDSpace */
	
	virtual NOLOCK RPTR(FilterSpace) globalIDFilterSpace ();
	
	/* The global IDSpace */
	
	virtual NOLOCK RPTR(IDSpace) globalIDSpace ();
	
	/* See FeAdminer */
	
	virtual void grant (APTR(ID) ARG(clubID), APTR(IDRegion) ARG(globalIDs));
	
	/* Who has been granted authority to assign that ID */
	
	virtual RPTR(ID) grantAt (APTR(ID) ARG(iD));
	
	/* See FeAdminer */
	
	virtual RPTR(TableStepper) OF2(ID,IDRegion) grants (APTR(IDRegion) OR(NULL) ARG(clubIDs), APTR(IDRegion) OR(NULL) ARG(globalIDs));
	
	
	virtual NOLOCK RPTR(Sequence) identifier ();
	
	/* Find the ID of a BeRangeElement. Blast if there is no ID 
	or if there is more than one */
	
	virtual RPTR(ID) iDOf (APTR(BeRangeElement) ARG(value));
	
	/* Find the IDs of a BeRangeElement, whether there are none, 
	one, or several */
	
	virtual RPTR(IDRegion) iDsOf (APTR(BeRangeElement) ARG(value));
	
	/* See FeAdminer */
	
	virtual NOLOCK BooleanVar isAcceptingConnections ();
	
	
	virtual RPTR(ID) newID ();
	
	/* Make a new globally unique IDSpace */
	
	virtual RPTR(IDSpace) newIDSpace ();
	
	/* The ID of the Club which owns whatever is at the given ID */
	
	virtual RPTR(ID) placeOwnerID (APTR(ID) ARG(iD));
	
	
	virtual void setGateLockSmithEdition (APTR(FeEdition) ARG(edition));
	
	/* A mapping from wrapper names to endorsements */
	
	virtual RPTR(ScruTable) OF2(Sequence,CrossRegion) wrapperEndorsements ();
	
  public: /* making editions */

	/* Creates an Edition mapping from a Region of keys to the 
	values in an array. The ordering specifies the correspondance 
	between the keys and the indices in the array.
		The Region must have the same count as the array.
		You must give an owner for the newly created DataHolders. */
	
	virtual RPTR(BeEdition) newDataEdition (
			APTR(PrimDataArray) ARG(values), 
			APTR(XnRegion) ARG(keys), 
			APTR(OrderSpec) ARG(ordering))
	;
	
	/* A single key-value mapping */
	
	virtual RPTR(BeEdition) newEditionWith (APTR(Position) ARG(key), APTR(BeCarrier) ARG(value));
	
	/* A single key-value mapping */
	
	virtual RPTR(BeEdition) newEditionWithAll (APTR(XnRegion) ARG(keys), APTR(BeCarrier) ARG(value));
	
	/* Create an empty Edition.  This should really be canonicalized. */
	
	virtual RPTR(BeEdition) newEmptyEdition (APTR(CoordinateSpace) ARG(cs));
	
	/* Make an Edition with a region full of unique PlaceHolders */
	
	virtual RPTR(BeEdition) newPlaceHolders (APTR(XnRegion) ARG(region));
	
	/* Creates an Edition mapping from a Region of keys to the 
	values in an array. The ordering specifies the correspondance 
	between the keys and the indices in the array.
		The Region must have the same count as the array. */
	/* compute the join of the existing traces and bert crums in 
	the table */
	/* make new ones if there are none */
	
	virtual RPTR(BeEdition) newValueEdition (
			APTR(PtrArray) OF1(FeRangeElement) ARG(values), 
			APTR(XnRegion) ARG(keys), 
			APTR(OrderSpec) ARG(ordering))
	;
	
  public: /* making other things */

	/* Return a carrier that has the rangeElement with a new 
	Label if appropriate. */
	
	virtual RPTR(BeCarrier) carrier (APTR(BeRangeElement) ARG(element));
	
	/* Make a new Club assigned to either iD or a generated ID id 
	iD is NULL. */
	
	virtual RPTR(BeClub) newClub (APTR(FeEdition) ARG(desc), APTR(ID) ARG(iD) = NULL);
	
	/* Make a new DataHolder with the given contents. */
	
	virtual RPTR(BeDataHolder) newDataHolder (APTR(PrimValue) ARG(value));
	
	/* Make a new IDHolder for the given ID. Uses an existing one 
	if it exists. */
	
	virtual RPTR(BeIDHolder) newIDHolder (APTR(ID) ARG(iD));
	
	/* Make a new label. */
	
	virtual RPTR(BeLabel) newLabel ();
	
	/* Make a new PlaceHolder. */
	
	virtual RPTR(BePlaceHolder) newPlaceHolder ();
	
	/* Make a new Work (without an ID) with the given contents.  
	Everything 
		 else comes from the fluid environment. */
	
	virtual RPTR(BeWork) newWork (APTR(FeEdition) ARG(contents));
	
  public: /* clubs */

	
	virtual NOLOCK RPTR(ID) accessClubID ();
	
	
	virtual NOLOCK RPTR(ID) adminClubID ();
	
	
	virtual NOLOCK RPTR(ID) archiveClubID ();
	
	
	virtual NOLOCK RPTR(ID) emptyClubID ();
	
	
	virtual NOLOCK RPTR(ID) publicClubID ();
	
  private:
	CHKPTR(Sequence) myIdentifier;
	CHKPTR(IDSpace) myGlobalIDSpace;
	CHKPTR(Counter) myLocalIDSpaceCounter;
	CHKPTR(FilterSpace) OF1(IDSpace) myGlobalIDFilterSpace;
	CHKPTR(CrossSpace) myEndorsementSpace;
	CHKPTR(FilterSpace) OF1(CrossSpace) myEndorsementFilterSpace;
	CHKPTR(MuTable) OF2(ID,IDHolder) myIDHolders;
	CHKPTR(MuTable) OF2(Tuple OF2(Sequence,IntegerPos),Counter) myIDCounters;
	CHKPTR(MuTable) OF2(ID,BeRangeElement) myRangeElements;
	CHKPTR(MuTable) OF2(HeaperAsPosition OF1(BeRangeElement),IDRegion OR(ID)) myRangeElementIDs;
public:
	CHKPTR(Ent) myEnt;
private:
	CHKPTR(ID) myEmptyClubID;
	CHKPTR(ID) myPublicClubID;
	CHKPTR(ID) myAdminClubID;
	CHKPTR(ID) myArchiveClubID;
	CHKPTR(ID) myAccessClubID;
	CHKPTR(ID) myClubDirectoryID;
	CHKPTR(BeEdition) myGateLockSmithEdition;
	CHKPTR(ImmuTable) OF2(Sequence,CrossRegion) myWrapperEndorsements;
	CHKPTR(PtrArray) OF1(Tuple OR(CrossRegion)) myEndorsementFlags;
	NOCOPY BooleanVar myPurgeable;
	CHKPTR(BeEdition) OF1(Club) myGrants;
	NOCOPY BooleanVar myAcceptingConnectionsFlag;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	
/* Friends for class BeGrandMap */
friend class BackendBootMaker;



};  /* end class BeGrandMap */



#endif /* GRANMAPX_HXX */

