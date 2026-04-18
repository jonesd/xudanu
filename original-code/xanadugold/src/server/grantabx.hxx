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

#ifndef GRANTABX_HXX
#define GRANTABX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef GRANTABX_OXX
#include "grantabx.oxx"
#endif /* GRANTABX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef TABLESX_HXX
#include "tablesx.hxx"
#endif /* TABLESX_HXX */


#ifndef COUNTERX_OXX
#include "counterx.oxx"
#endif /* COUNTERX_OXX */

#ifndef GRANTABP_OXX
#include "grantabp.oxx"
#endif /* GRANTABP_OXX */

#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */


/* Presently the values called 'shift' in this module are used with
divide and modulo operations rather than bit operations.  Thus
the minimum shift for a hashed key is 1 and not 0. */
/*  */




/* ************************************************************************ *
 * 
 *                    Class GrandHashSet 
 *
 * ************************************************************************ */



/* Initializers for GrandHashSet */




	/* NO CLASS COMMENT */

class GrandHashSet : public MuSet {

/* Attributes for class GrandHashSet */
	CONCRETE(GrandHashSet)
	COPY(GrandHashSet,DiskCuisine)
	AUTO_GC(GrandHashSet)

/* Initializers for GrandHashSet */
friend class INIT_TIME_NAME(GrandHashSet,initTimeNonInherited);

  public: /* pseudoConstructors */

	
	static RPTR(GrandHashSet) make ();
	
	
	static RPTR(GrandHashSet) make (Int32 ARG(nNodes));
	
  public: /* adding-removing */

	
	virtual void introduce (APTR(Heaper) ARG(aHeaper));
	
	
	virtual void remove (APTR(Heaper) ARG(aHeaper));
	
	
	virtual void store (APTR(Heaper) ARG(aHeaper));
	
	
	virtual void wipe (APTR(Heaper) ARG(aHeaper));
	
  public: /* accessing */

	
	virtual IntegerVar count ();
	
	
	virtual BooleanVar hasMember (APTR(Heaper) ARG(aHeaper));
	
  public: /* testing */

	
	virtual BooleanVar isEmpty ();
	
  public: /* conversion */

	
	virtual RPTR(ImmuSet) asImmuSet ();
	
	
	virtual RPTR(MuSet) asMuSet ();
	
  public: /* creation */

	
	virtual RPTR(ScruSet) copy ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
	
	virtual void printOnWithSimpleSyntax (
			ostream& ARG(oo), 
			char * ARG(open), 
			char * ARG(sep), 
			char * ARG(close))
	;
	
  public: /* enumerating */

	
	virtual RPTR(Stepper) stepper ();
	
  protected: /* protected: creation */

	
	GrandHashSet (Int32 ARG(nNodes), TCSJ);
	
	
	virtual void destruct ();
	
  private: /* private: housekeeping */

	/* Compute location of doubling front from tally.  If front 
	crosses a node boundary */
	/*  and that node has index higher than doublingFrontIndex 
	then double that node. */
	/*  Then increase doublingFrontIndex.  If the front has hit 
	the end of the table index */
	/*  reset it to zero.  This allows elements to be wiped from 
	the table without causing */
	/*  extra node doubling to occur on later insertions.  This 
	aims for 80% max table */
	/* loading using an approximation of the formula given in the 
	Fagin paper. */
	
	virtual void considerNeedForDoubling ();
	
	
	virtual void invalidateCache ();
	
  public: /* receiver */

	/* re-initialize the non-persistent part */
	
	virtual RECEIVE_HOOK void restartGrandHashSet (APTR(Rcvr) ARG(trans) = NULL);
	
  private: /* private: friendly */

	
	virtual RPTR(GrandNode) nodeAt (IntegerVar ARG(idx));
	
	
	virtual IntegerVar nodeCount ();
	
  private: /* private: enumerating */

	
	INLINE void checkSteppers ();
	
	
	virtual void fewerSteppers ();
	
	
	virtual RPTR(Stepper) immuStepper ();
	
	
	virtual void moreSteppers ();
	
  private:
	CHKPTR(PtrArray) OF1(GrandNode) grandNodes;
	Int32 numNodes;
	Int32 nodeIndexShift;
	CHKPTR(Counter) myTally;
	CHKPTR(Counter) myDoublingFrontIndex;
	CHKPTR(Counter) myDoublingPasses;
	NOCOPY UInt32 cacheHash;
	NOCOPY UNPTR(Heaper) cacheValue;
	NOCOPY IntegerVar myOutstandingSteppers;
/* Friends for class GrandHashSet */
/* friends for class GrandHashSet */
friend SPTR(GrandHashSet)  grandHashSet ();
friend SPTR(GrandHashSet)  grandHashSet (Int4 nNodes);
friend class GrandHashSetStepper;



};  /* end class GrandHashSet */



/* ************************************************************************ *
 * 
 *                    Class GrandHashTable 
 *
 * ************************************************************************ */



/* Initializers for GrandHashTable */




	/* NO CLASS COMMENT */

class GrandHashTable : public MuTable {

/* Attributes for class GrandHashTable */
	CONCRETE(GrandHashTable)
	COPY(GrandHashTable,DiskCuisine)
	AUTO_GC(GrandHashTable)

/* Initializers for GrandHashTable */
friend class INIT_TIME_NAME(GrandHashTable,initTimeNonInherited);

  public: /* pseudoConstructors */

	
	static RPTR(GrandHashTable) make (APTR(CoordinateSpace) ARG(cs));
	
	
	static RPTR(GrandHashTable) make (APTR(CoordinateSpace) ARG(cs), Int32 ARG(nNodes));
	
  public: /* adding-removing */

	
	virtual RPTR(Heaper) store (APTR(Position) ARG(aKey), APTR(Heaper) ARG(aHeaper));
	
	
	virtual BooleanVar wipe (APTR(Position) ARG(aKey));
	
  public: /* accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual IntegerVar count ();
	
	
	virtual RPTR(XnRegion) domain ();
	
	
	virtual RPTR(Heaper) fetch (APTR(Position) ARG(key));
	
	
	virtual RPTR(ScruTable) subTable (APTR(XnRegion) ARG(region));
	
  public: /* testing */

	
	virtual BooleanVar includesIntKey (IntegerVar ARG(aKey));
	
	
	virtual BooleanVar includesKey (APTR(Position) ARG(aKey));
	
	
	virtual BooleanVar isEmpty ();
	
  public: /* creation */

	
	virtual RPTR(ScruTable) copy ();
	
	
	virtual RPTR(ScruTable) emptySize (IntegerVar ARG(size));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
  public: /* runs */

	
	virtual RPTR(XnRegion) runAt (APTR(Position) ARG(index));
	
	
	virtual RPTR(XnRegion) runAtInt (IntegerVar ARG(index));
	
  private: /* private: enumerating */

	
	INLINE void checkSteppers ();
	
	
	virtual void fewerSteppers ();
	
	
	virtual void moreSteppers ();
	
  public: /* enumerating */

	
	virtual RPTR(TableStepper) stepper (APTR(OrderSpec) ARG(order) = NULL);
	
  protected: /* protected: creation */

	
	GrandHashTable (APTR(CoordinateSpace) ARG(cs), Int32 ARG(nNodes));
	
	
	virtual void destruct ();
	
  private: /* private: housekeeping */

	/* Compute location of doubling front from tally.  If front 
	crosses a node boundary */
	/*  and that node has index higher than doublingFrontIndex 
	then double that node. */
	/*  Then increase doublingFrontIndex.  If the front has hit 
	the end of the table index */
	/*  reset it to zero.  This allows elements to be wiped from 
	the table without causing */
	/*  extra node doubling to occur on later insertions.  This 
	aims for 80% max table */
	/* loading using an approximation of the formula given in the 
	Fagin paper. */
	
	virtual void considerNeedForDoubling ();
	
	
	virtual void invalidateCache ();
	
  public: /* hooks: */

	/* re-initialize the non-persistent part */
	
	virtual RECEIVE_HOOK void restartGrandHashTable (APTR(Rcvr) ARG(trans) = NULL);
	
  private: /* private: friendly */

	
	virtual RPTR(GrandNode) nodeAt (IntegerVar ARG(idx));
	
	
	virtual IntegerVar nodeCount ();
	
  public: /* conversion */

	
	virtual RPTR(ImmuTable) asImmuTable ();
	
	
	virtual RPTR(MuTable) asMuTable ();
	
  private:
	CHKPTR(PtrArray) OF1(GrandNode) grandNodes;
	Int32 numNodes;
	Int32 nodeIndexShift;
	CHKPTR(Counter) myTally;
	CHKPTR(Counter) myDoublingFrontIndex;
	CHKPTR(Counter) myDoublingPasses;
	CHKPTR(CoordinateSpace) myCs;
	NOCOPY UInt32 cacheHash;
	NOCOPY UNPTR(Position) cacheKey;
	NOCOPY UNPTR(Heaper) cacheValue;
	NOCOPY IntegerVar myOutstandingSteppers;
/* Friends for class GrandHashTable */
/* friends for class GrandHashTable */
friend SPTR(GrandHashTable) grandHashTable (CoordinateSpace *);
friend SPTR(GrandHashTable) grandHashTable (CoordinateSpace *, Int4 nNodes);
friend class GrandHashTableStepper;


};  /* end class GrandHashTable */


#ifdef USE_INLINE
#ifndef GRANTABX_IXX
#include "grantabx.ixx"
#endif /* GRANTABX_IXX */


#endif /* USE_INLINE */


#endif /* GRANTABX_HXX */

