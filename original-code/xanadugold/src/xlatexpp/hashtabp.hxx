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

#ifndef HASHTABP_HXX
#define HASHTABP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef HASHTABX_HXX
#include "hashtabx.hxx"
#endif /* HASHTABX_HXX */

#ifndef HASHTABP_OXX
#include "hashtabp.oxx"
#endif /* HASHTABP_OXX */


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

#ifndef TABENTX_OXX
#include "tabentx.oxx"
#endif /* TABENTX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class ActualHashTable 
 *
 * ************************************************************************ */




	/* The HashTable is an implementation class that is intended 
	to provide the weakest Position->Object mapping.  It can map 
	from arbitrary Position classes (such as HeaperAsPosition or 
	TreePosition).  HashTable can also be used for very sparse 
	integer domains.
		
		HashTable, and the entire hashtab module, is private 
	implementation.  Not to be included by clients. */

class ActualHashTable : public HashTable {

/* Attributes for class ActualHashTable */
	CONCRETE(ActualHashTable)
	COPY(ActualHashTable,XppCuisine)
	AUTO_GC(ActualHashTable)
  public: /* creation */

	
	static RPTR(HashTable) make (APTR(CoordinateSpace) ARG(cs));
	
	
	static RPTR(HashTable) make (APTR(CoordinateSpace) ARG(cs), IntegerVar ARG(size));
	
  public: /* accessing */

	
	virtual RPTR(Heaper) OR(NULL) store (APTR(Position) ARG(key), APTR(Heaper) ARG(aHeaper));
	
	
	virtual RPTR(Heaper) OR(NULL) atIntStore (IntegerVar ARG(key), APTR(Heaper) ARG(aHeaper));
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual IntegerVar count ();
	
	
	virtual RPTR(XnRegion) domain ();
	
	
	virtual RPTR(Heaper) OR(NULL) fetch (APTR(Position) ARG(key));
	
	
	virtual RPTR(Heaper) OR(NULL) intFetch (IntegerVar ARG(key));
	
	
	virtual RPTR(ScruTable) subTable (APTR(XnRegion) ARG(region));
	
	
	virtual BooleanVar wipe (APTR(Position) ARG(aKey));
	
  public: /* testing */

	
	virtual UInt32 fastHash ();
	
	
	virtual BooleanVar includesKey (APTR(Position) ARG(aKey));
	
	
	virtual BooleanVar isEmpty ();
	
  public: /* creation */

	
	virtual RPTR(ScruTable) copy ();
	
	
	virtual RPTR(ScruTable) emptySize (IntegerVar ARG(size));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* runLength */

	
	virtual RPTR(XnRegion) runAt (APTR(Position) ARG(index));
	
  public: /* enumerating */

	/* ignore order spec for now */
	
	virtual RPTR(TableStepper) stepper (APTR(OrderSpec) ARG(order) = NULL);
	
	
	virtual RPTR(Heaper) theOne ();
	
  public: /* hooks: */

	/* This currently doesn't take advantage of the optimizations 
	in TableEntries.  It should. */
	
	virtual RECEIVE_HOOK void receiveHashTable (APTR(Rcvr) ARG(rcvr));
	
	/* This currently doesn't take advantage of the optimizations 
	in TableEntries.  It should. */
	
	virtual SEND_HOOK void sendHashTable (APTR(Xmtr) ARG(xmtr));
	
  protected: /* protected: */

	
	ActualHashTable (
			APTR(SharedPtrArray) OF1(TableEntry) ARG(entries), 
			Int32 ARG(tally), 
			APTR(CoordinateSpace) ARG(cs))
	;
	
	
	virtual void destruct ();
	
  private: /* private: */

	/* If my contents are shared, and I'm about to change them, 
	make a copy of them. */
	
	virtual void aboutToWrite ();
	
	
	virtual void checkSize ();
	
	/* Store the tableentry into the entry table */
	
	virtual void storeEntry (APTR(TableEntry) ARG(anEntry));
	
  private:
	NOCOPY CHKPTR(SharedPtrArray) myHashEntries;
	Int32 myTally;
	CHKPTR(CoordinateSpace) myCoordinateSpace;
/* Friends for class ActualHashTable */
/* friends for class HashTable */
friend SPTR(HashTable)  actualHashTable (APTR(CoordinateSpace) cs);
friend SPTR(HashTable)  actualHashTable (APTR(CoordinateSpace) cs, IntegerVar size);



};  /* end class ActualHashTable */



#endif /* HASHTABP_HXX */

