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

#ifndef GRANTABP_HXX
#define GRANTABP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef GRANTABX_HXX
#include "grantabx.hxx"
#endif /* GRANTABX_HXX */

#ifndef GRANTABP_OXX
#include "grantabp.oxx"
#endif /* GRANTABP_OXX */


#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */

#ifndef TURTLEX_HXX
#include "turtlex.hxx"
#endif /* TURTLEX_HXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef PSRANDX_OXX
#include "psrandx.oxx"
#endif /* PSRANDX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */


/* Presently the values called 'shift' in this module are used with
divide and modulo operations rather than bit operations.  Thus
the minimum shift for a hashed key is 1 and not 0. */
/*  */
#include "fhashx.hxx"



/* ************************************************************************ *
 * 
 *                    Class ExponentialHashMap 
 *
 * ************************************************************************ */



/* Initializers for ExponentialHashMap */







	/* NO CLASS COMMENT */

class ExponentialHashMap : public Heaper {

/* Attributes for class ExponentialHashMap */
	CONCRETE(ExponentialHashMap)
	AUTO_GC(ExponentialHashMap)

/* Initializers for ExponentialHashMap */



friend class INIT_TIME_NAME(ExponentialHashMap,initTimeNonInherited);

  public: /* accessing */

	
	static INLINE UInt32 exponentialMap (UInt32 ARG(aHash));
	
	
	static INLINE UInt32 hashBits ();
	
  public: /* mapping */

	
	virtual UInt32 of (UInt32 ARG(aHash));
	
  public: /* creation */

	
	ExponentialHashMap (Int32 ARG(numPieces), UInt32 ARG(range));
	
  private: /* private: calculation */

	
	virtual UInt32 expFuncWithin (UInt32 ARG(domElem), UInt32 ARG(range));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  private:
	Int32 domain;
	CHKPTR(UInt32Array) rBottoms;
	CHKPTR(UInt32Array) rSizes;
	CHKPTR(UInt32Array) dBottoms;
	Int32 dSize;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(PtrArray) FastHashMap;
	static UInt32 HashBits;
	static GPTR(ExponentialHashMap) TheExponentialMap;
};  /* end class ExponentialHashMap */



/* ************************************************************************ *
 * 
 *                    Class GrandDataPage 
 *
 * ************************************************************************ */




	/* GrandDataPage behaves as a small hash table.
	Linear hashing and the GrandOverflow structure are used to 
	resolve collisions.
	The shift argument to the various methods is the number of pages in the
	parent node to indicate how many low bits of the hash are ignored. */

class GrandDataPage : public Abraham {

/* Attributes for class GrandDataPage */
	CONCRETE(GrandDataPage)
	SHEPHERD_PATRIARCH(GrandDataPage,Abraham)
	LOCKED(GrandDataPage)
	COPY(GrandDataPage,DiskCuisine)
	AUTO_GC(GrandDataPage)
  public: /* creation */

	
	static RPTR(GrandDataPage) make (
			Int32 ARG(nEntries), 
			APTR(GrandNode) ARG(node), 
			UInt32 ARG(lowHashBits))
	;
	
  public: /* accessing */

	
	virtual RPTR(Heaper) fetch (
			APTR(Heaper) OR(Position) ARG(toMatch), 
			UInt32 ARG(aHash), 
			Int32 ARG(shift))
	;
	
	
	virtual void store (APTR(GrandEntry) ARG(newEntry), Int32 ARG(shift));
	
	
	virtual void wipe (
			APTR(Heaper) OR(Position) ARG(toMatch), 
			UInt32 ARG(aHash), 
			Int32 ARG(shift))
	;
	
  protected: /* protected: creation */

	
	GrandDataPage (
			Int32 ARG(nEntries), 
			APTR(GrandNode) ARG(node), 
			UInt32 ARG(lowHashBits))
	;
	
  private: /* private: private */

	/* This repacks the entry table after a wipe to keep the 
	table consistent with */
	/* the linear hash collision resolution technique. */
	
	virtual void repack (Int32 ARG(shift));
	
  public: /* node doubling */

	/* Create a new page with all entries of current page that have a */
	/* '1' in the new lowest significant bit of the hash. */
	/* Retain all '0' entries in this page. */
	
	virtual RPTR(GrandDataPage) makeDouble (Int32 ARG(newNumPages));
	
  public: /* special */

	
	virtual IEEEDoubleVar loadFactor ();
	
	
	virtual NOLOCK UInt32 lowHashBits ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
  protected: /* protected: destruction */

	
	virtual void dismantle ();
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
	
	virtual BooleanVar isEmpty ();
	
  private: /* private: friendly */

	
	virtual RPTR(GrandEntry) entryAt (IntegerVar ARG(idx));
	
	
	virtual NOLOCK IntegerVar entryCount ();
	
  private:
	UInt32 myLowHashBits;
	Int32 numEntries;
	CHKPTR(PtrArray) OF1(GrandEntry) entries;
	CHKPTR(GrandOverflow) overflow;
	CHKPTR(GrandNode) myGroup;
/* Friends for class GrandDataPage */
/* friends for class GrandDataPage */
friend class GrandDataPageStepper;



};  /* end class GrandDataPage */



/* ************************************************************************ *
 * 
 *                    Class GrandDataPageStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class GrandDataPageStepper : public Stepper {

/* Attributes for class GrandDataPageStepper */
	CONCRETE(GrandDataPageStepper)
	AUTO_GC(GrandDataPageStepper)
  public: /* operations */

	
	virtual RPTR(GrandEntry) entry ();
	
	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  private: /* private: create */

	
	GrandDataPageStepper (APTR(GrandDataPage) ARG(aPage), IntegerVar ARG(index));
	
  private: /* private: private */

	
	virtual void verifyEntry ();
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	GrandDataPageStepper (APTR(GrandDataPage) ARG(aPage), TCSJ);
	
  private:
	CHKPTR(GrandDataPage) page;
	IntegerVar entryIndex;
};  /* end class GrandDataPageStepper */



/* ************************************************************************ *
 * 
 *                    Class GrandEntry 
 *
 * ************************************************************************ */




	/* GrandEntries probably want to not be remembered right when 
	they are created,
	and remembered when they are finally put into their place in 
	the GrandDataPages
	or GrandOverflows */

class GrandEntry : public Abraham {

/* Attributes for class GrandEntry */
	DEFERRED(GrandEntry)
	SHEPHERD_PATRIARCH(GrandEntry,Abraham)
	COPY(GrandEntry,DiskCuisine)
	DEFERRED_LOCKED(GrandEntry)
	AUTO_GC(GrandEntry)
  public: /* accessing */

	
	virtual RPTR(Heaper) value ();
	
  protected: /* protected: creation */

	
	GrandEntry (APTR(Heaper) ARG(value), UInt32 ARG(hash));
	
  public: /* deferred: testing */

	
	virtual BooleanVar compare (APTR(Heaper) OR(Position) ARG(anObj)) DEFERRED_FUNC;
	
	
	virtual BooleanVar matches (APTR(GrandEntry) ARG(anEntry)) DEFERRED_FUNC;
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	CHKPTR(Heaper) objectInternal;
};  /* end class GrandEntry */



/* ************************************************************************ *
 * 
 *                    Class   GrandSetEntry 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class GrandSetEntry : public GrandEntry {

/* Attributes for class GrandSetEntry */
	CONCRETE(GrandSetEntry)
	SHEPHERD_ANCESTOR(GrandSetEntry,GrandEntry)
	COPY(GrandSetEntry,DiskCuisine)
	LOCKED(GrandSetEntry)
	NOT_A_TYPE(GrandSetEntry)
	NO_GC(GrandSetEntry)
  public: /* create */

	
	static RPTR(GrandEntry) make (APTR(Heaper) ARG(value), UInt32 ARG(hash));
	
  public: /* testing */

	
	virtual BooleanVar compare (APTR(Heaper) OR(Position) ARG(anObj));
	
	
	virtual BooleanVar matches (APTR(GrandEntry) ARG(anEntry));
	
  protected: /* protected: creation */

	
	GrandSetEntry (APTR(Heaper) ARG(value), UInt32 ARG(hash));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	

};  /* end class GrandSetEntry */



/* ************************************************************************ *
 * 
 *                    Class   GrandTableEntry 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class GrandTableEntry : public GrandEntry {

/* Attributes for class GrandTableEntry */
	CONCRETE(GrandTableEntry)
	SHEPHERD_ANCESTOR(GrandTableEntry,GrandEntry)
	COPY(GrandTableEntry,DiskCuisine)
	LOCKED(GrandTableEntry)
	NOT_A_TYPE(GrandTableEntry)
	AUTO_GC(GrandTableEntry)
  public: /* create */

	
	static RPTR(GrandEntry) make (
			APTR(Heaper) ARG(value), 
			APTR(Position) ARG(key), 
			UInt32 ARG(hash))
	;
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
  public: /* accessing */

	
	virtual NOLOCK RPTR(Position) key ();
	
	
	virtual NOLOCK RPTR(Position) position ();
	
  public: /* testing */

	
	virtual BooleanVar compare (APTR(Heaper) OR(Position) ARG(anObj));
	
	
	virtual UInt32 contentsHash ();
	
	
	virtual BooleanVar matches (APTR(GrandEntry) ARG(anEntry));
	
  protected: /* protected: creation */

	
	GrandTableEntry (
			APTR(Heaper) ARG(value), 
			APTR(Position) ARG(key), 
			UInt32 ARG(hash))
	;
	
  private:
	CHKPTR(Position) keyInternal;
};  /* end class GrandTableEntry */



/* ************************************************************************ *
 * 
 *                    Class GrandHashSetStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class GrandHashSetStepper : public Stepper {

/* Attributes for class GrandHashSetStepper */
	CONCRETE(GrandHashSetStepper)
	NOT_A_TYPE(GrandHashSetStepper)
	AUTO_GC(GrandHashSetStepper)
  private: /* private: private */

	
	virtual void verifyEntry ();
	
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  protected: /* protected: create */

	
	GrandHashSetStepper (
			APTR(GrandHashSet) ARG(aSet), 
			APTR(GrandNodeStepper) ARG(aNodeStepper), 
			IntegerVar ARG(aNodeIndex))
	;
	
	
	virtual void destruct ();
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	GrandHashSetStepper (APTR(GrandHashSet) ARG(aSet), TCSJ);
	
  private:
	CHKPTR(GrandHashSet) set;
	CHKPTR(GrandNodeStepper) OR(NULL) nodeStepper;
	IntegerVar nodeIndex;
};  /* end class GrandHashSetStepper */



/* ************************************************************************ *
 * 
 *                    Class GrandHashTableStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class GrandHashTableStepper : public TableStepper {

/* Attributes for class GrandHashTableStepper */
	CONCRETE(GrandHashTableStepper)
	NOT_A_TYPE(GrandHashTableStepper)
	AUTO_GC(GrandHashTableStepper)
  private: /* private: private */

	
	virtual void verifyEntry ();
	
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* special */

	
	virtual RPTR(Position) position ();
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	GrandHashTableStepper (APTR(GrandHashTable) ARG(aTable), TCSJ);
	
  protected: /* protected: creation */

	
	GrandHashTableStepper (
			APTR(GrandHashTable) ARG(aTable), 
			APTR(GrandNodeStepper) ARG(aNodeStepper), 
			IntegerVar ARG(aNodeIndex))
	;
	
	
	virtual void destruct ();
	
  private:
	CHKPTR(GrandHashTable) table;
	CHKPTR(GrandNodeStepper) OR(NULL) nodeStepper;
	IntegerVar nodeIndex;
};  /* end class GrandHashTableStepper */



/* ************************************************************************ *
 * 
 *                    Class GrandNode 
 *
 * ************************************************************************ */



/* Initializers for GrandNode */




	/* oldOverflowRoot holds onto the overflow tree that was in 
	place when a node doubling starts.
	It allows an object stored to be found at any time during the 
	doubling. */

class GrandNode : public Abraham {

/* Attributes for class GrandNode */
	CONCRETE(GrandNode)
	SHEPHERD_PATRIARCH(GrandNode,Abraham)
	LOCKED(GrandNode)
	COPY(GrandNode,DiskCuisine)
	AUTO_GC(GrandNode)

/* Initializers for GrandNode */


  public: /* create */

	
	static RPTR(GrandNode) make ();
	
  public: /* static functions */

	
	static INLINE Int32 primaryPageSize ();
	
  public: /* accessing */

	
	virtual RPTR(Heaper) fetch (APTR(Heaper) OR(Position) ARG(toMatch), UInt32 ARG(aHash));
	
	
	virtual void store (APTR(GrandEntry) ARG(newEntry));
	
	
	virtual void wipe (APTR(Heaper) OR(Position) ARG(toMatch), UInt32 ARG(aHash));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
  protected: /* protected: creation */

	
	GrandNode ();
	
	
	virtual void dismantle ();
	
  public: /* node doubling */

	
	virtual void addReinserter ();
	
	
	virtual void doubleNode ();
	
	
	virtual IntegerVar doubleNodeConsistency ();
	
	
	virtual void removeReinserter ();
	
  private: /* private: friendly access */

	
	virtual RPTR(GrandDataPage) pageAt (IntegerVar ARG(idx));
	
	
	virtual NOLOCK IntegerVar pageCount ();
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
	
	virtual BooleanVar isEmpty ();
	
  public: /* overflow */

	
	virtual NOLOCK RPTR(GrandOverflow) fetchOldOverflow ();
	
	
	virtual NOLOCK RPTR(GrandOverflow) fetchOverflow ();
	
	
	virtual RPTR(GrandOverflow) getOverflow ();
	
  public: /* special */

	
	virtual IEEEDoubleVar loadFactor ();
	
  private:
	CHKPTR(PtrArray) OF1(GrandDataPage) primaryPages;
	Int32 numPrimaries;
	CHKPTR(GrandOverflow) overflowRoot;
	CHKPTR(GrandOverflow) oldOverflowRoot;
	Int32 numReinserters;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static Int32 OverflowPageSize;
/* Friends for class GrandNode */
/* friends for class GrandNode */
friend class GrandNodeStepper;
friend class GrandNodeDoubler;
friend class GrandNodeReinserter;



};  /* end class GrandNode */



/* ************************************************************************ *
 * 
 *                    Class GrandNodeDoubler 
 *
 * ************************************************************************ */




	/* GrandNodeDoubler performs the page splitting required for 
	the extensible GrandHash<collection>s in a deferred fashion. */

class GrandNodeDoubler : public AgendaItem {

/* Attributes for class GrandNodeDoubler */
	CONCRETE(GrandNodeDoubler)
	SHEPHERD_PATRIARCH(GrandNodeDoubler,AgendaItem)
	LOCKED(GrandNodeDoubler)
	COPY(GrandNodeDoubler,DiskCuisine)
	AUTO_GC(GrandNodeDoubler)
  public: /* creation */

	
	static RPTR(GrandNodeDoubler) make (APTR(GrandNode) ARG(gNode));
	
  protected: /* protected: creation */

	
	GrandNodeDoubler (APTR(GrandNode) ARG(gNode), TCSJ);
	
  public: /* accessing */

	
	virtual BooleanVar step ();
	
  private:
	CHKPTR(GrandNode) OR(NULL) myNode;
};  /* end class GrandNodeDoubler */



/* ************************************************************************ *
 * 
 *                    Class GrandNodeReinserter 
 *
 * ************************************************************************ */




	/* GrandNodeReinserter moves the contents of the 
	GrandOverflow structure into the newly doubled GrandNode. */

class GrandNodeReinserter : public AgendaItem {

/* Attributes for class GrandNodeReinserter */
	CONCRETE(GrandNodeReinserter)
	SHEPHERD_PATRIARCH(GrandNodeReinserter,AgendaItem)
	LOCKED(GrandNodeReinserter)
	COPY(GrandNodeReinserter,DiskCuisine)
	AUTO_GC(GrandNodeReinserter)
  public: /* creation */

	
	static RPTR(GrandNodeReinserter) make (APTR(GrandNode) ARG(gNode), APTR(GrandOverflow) ARG(gOverflow));
	
  protected: /* protected: creation */

	
	GrandNodeReinserter (APTR(GrandNode) ARG(gNode), APTR(GrandOverflow) ARG(gOverflow));
	
  public: /* accessing */

	
	virtual BooleanVar step ();
	
  private:
	CHKPTR(GrandNode) OR(NULL) myNode;
	CHKPTR(GrandOverflow) myOverflow;
};  /* end class GrandNodeReinserter */



/* ************************************************************************ *
 * 
 *                    Class GrandNodeStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class GrandNodeStepper : public Stepper {

/* Attributes for class GrandNodeStepper */
	CONCRETE(GrandNodeStepper)
	AUTO_GC(GrandNodeStepper)
  protected: /* protected: creation */

	
	GrandNodeStepper (
			APTR(GrandNode) ARG(aNode), 
			APTR(GrandDataPageStepper) ARG(curPageStepper), 
			IntegerVar ARG(curPageIndex), 
			APTR(GrandOverflowStepper) ARG(oflowStepper))
	;
	
	
	virtual void destruct ();
	
  private: /* private: */

	
	virtual void verifyEntry ();
	
  public: /* operations */

	
	virtual RPTR(GrandEntry) entry ();
	
	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	GrandNodeStepper (APTR(GrandNode) ARG(aNode), TCSJ);
	
  private:
	CHKPTR(GrandNode) node;
	CHKPTR(GrandDataPageStepper) pageStepper;
	IntegerVar pageIndex;
	CHKPTR(GrandOverflowStepper) overflowStepper;
};  /* end class GrandNodeStepper */



/* ************************************************************************ *
 * 
 *                    Class GrandOverflow 
 *
 * ************************************************************************ */



/* Initializers for GrandOverflow */




	/* This class has a comment
	The instance variable depth actually holds the value 
	OTreeArity ^ depth. */

class GrandOverflow : public Abraham {

/* Attributes for class GrandOverflow */
	CONCRETE(GrandOverflow)
	SHEPHERD_PATRIARCH(GrandOverflow,Abraham)
	LOCKED(GrandOverflow)
	COPY(GrandOverflow,DiskCuisine)
	AUTO_GC(GrandOverflow)

/* Initializers for GrandOverflow */


  public: /* accessing */

	
	virtual RPTR(Heaper) fetch (APTR(Heaper) OR(Position) ARG(toMatch), UInt32 ARG(aHash));
	
	
	virtual RPTR(GrandOverflow) store (APTR(GrandEntry) ARG(newEntry));
	
	
	virtual void wipe (APTR(Heaper) OR(Position) ARG(toMatch), UInt32 ARG(aHash));
	
  public: /* creation */

	
	GrandOverflow (Int32 ARG(maxEntries), UInt32 ARG(someDepth));
	
  private: /* private: */

	/* This repacks the entry table after a wipe to keep the 
	table consistent with */
	/* the linear hash collision resolution technique. */
	
	virtual void repack ();
	
  public: /* node doubling */

	/* Recursively insert all overflowed entries into a newly 
	doubled node. */
	
	virtual void reinsertEntries (APTR(GrandNode) ARG(node));
	
	
	virtual IntegerVar reinsertEntriesConsistency ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
  protected: /* protected: creation */

	
	virtual void dismantle ();
	
  private: /* private: friendly */

	
	virtual RPTR(GrandOverflow) childAt (IntegerVar ARG(idx));
	
	
	virtual NOLOCK IntegerVar childCount ();
	
	
	virtual RPTR(GrandEntry) entryAt (IntegerVar ARG(idx));
	
	
	virtual NOLOCK IntegerVar entryCount ();
	
  public: /* testing */

	
	virtual UInt32 contentsHash ();
	
  private:
	Int32 numEntries;
	CHKPTR(PtrArray) OF1(GrandEntry) entries;
	CHKPTR(PtrArray) OF1(GrandOverflow) children;
	Int32 depth;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static Int32 OTreeArity;
/* Friends for class GrandOverflow */
/* friends for class GrandOverflow */
friend class GrandOverflowStepper;


};  /* end class GrandOverflow */



/* ************************************************************************ *
 * 
 *                    Class GrandOverflowStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class GrandOverflowStepper : public Stepper {

/* Attributes for class GrandOverflowStepper */
	CONCRETE(GrandOverflowStepper)
	AUTO_GC(GrandOverflowStepper)
  private: /* private: */

	
	virtual void verifyEntry ();
	
  public: /* operations */

	
	virtual RPTR(GrandEntry) entry ();
	
	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	GrandOverflowStepper (APTR(GrandOverflow) ARG(aPage), TCSJ);
	
  protected: /* protected: creation */

	
	GrandOverflowStepper (
			APTR(GrandOverflow) ARG(anOverflow), 
			IntegerVar ARG(entryIdx), 
			APTR(GrandOverflowStepper) ARG(child), 
			IntegerVar ARG(childIdx))
	;
	
	
	virtual void destruct ();
	
  private:
	CHKPTR(GrandOverflow) overflow;
	IntegerVar entryIndex;
	CHKPTR(GrandOverflowStepper) childStepper;
	IntegerVar childIndex;
};  /* end class GrandOverflowStepper */


#ifdef USE_INLINE
#ifndef GRANTABP_IXX
#include "grantabp.ixx"
#endif /* GRANTABP_IXX */


#endif /* USE_INLINE */


#endif /* GRANTABP_HXX */

