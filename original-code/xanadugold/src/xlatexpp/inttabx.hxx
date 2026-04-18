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

#ifndef INTTABX_HXX
#define INTTABX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef INTTABX_OXX
#include "inttabx.oxx"
#endif /* INTTABX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef TABLESX_HXX
#include "tablesx.hxx"
#endif /* TABLESX_HXX */


#ifndef INTEGERX_OXX
#include "integerx.oxx"
#endif /* INTEGERX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */

#ifndef STEPPERX_OXX
#include "stepperx.oxx"
#endif /* STEPPERX_OXX */


/*  */
/* This file represents the tables with Integer domains.  It provides 
the abstract
classes IntegerTable and its (abstract) subclass Array.  IntegerTable 
may be used for
any Integer keys, while Array is restricted to be zero based, and to 
have contiguous
Integer keys. */




/* ************************************************************************ *
 * 
 *                    Class IntegerTable 
 *
 * ************************************************************************ */




	/* The IntegerTable class is used for tables that have 
	arbitrary XuInteger keys in their domain.  Since ScruTable & 
	MuTable already provide all the unboxed versions of the table 
	protocol, there is little need for this class to be a type.  
	However, this class does provide a bit of extra protocol 
	convenience: highestIndex & lowestIndex. Unless these are 
	retired, we cannot retire this class from type status.
		
		Note that there may be tables with XuInteger keys (i.e., 
	IntegerSpace domains) which are not kinds of IntegerTables.  
	In particular it is perfectly sensible to create a HashTable 
	with XuInteger keys when the domain region is likely to be sparse. */

class IntegerTable : public MuTable {

/* Attributes for class IntegerTable */
	DEFERRED(IntegerTable)
	NO_GC(IntegerTable)
  public: /* pseudoConstructors */

	/* A new empty IntegerTable */
	
	static RPTR(IntegerTable) make ();
	
	/* A new empty IntegerTable. 'someSize' is a hint about how 
	big the table is likely 
		to need to be ('highestIndex - lowestIndex + 1', not 'count'). */
	
	static RPTR(IntegerTable) make (IntegerVar ARG(someSize));
	
	/* Hint that the domain's lowerBound (inclusive) will 
	eventually be 'fromIdx', and 
		the domain's upperBound (exclusive) will eventually be 'toIdx'. */
	
	static RPTR(IntegerTable) make (IntegerVar ARG(fromIdx), IntegerVar ARG(toIdx));
	
	/* Hint that the domain of the new table will eventually be 
	(or at least resemble) 
		'reg'. */
	
	static RPTR(IntegerTable) make (APTR(IntegerRegion) ARG(reg));
	
  public: /* accessing */

	
	virtual void atIntIntroduce (IntegerVar ARG(key), APTR(Heaper) ARG(value));
	
	
	virtual void atIntReplace (IntegerVar ARG(key), APTR(Heaper) ARG(value));
	
	
	virtual RPTR(Heaper) atIntStore (IntegerVar ARG(key), APTR(Heaper) ARG(value)) DEFERRED_FUNC;
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual IntegerVar count () DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) domain () DEFERRED_FUNC;
	
	/* Given that the table is non-empty, 'intTab->highestIndex()'
	 is equivalent to 
		'CAST(IntegerRegion,intTab->domain())->upperBound() -1'. The 
	reason for the 
		'-1' is that the 'upperBound' is an exclusive upper bound (see 
		IntegerRegion::upperBound), whereas 'highestIndex' is the 
	highest index which is 
		in my domain. I need to here specify what 'highestIndex' 
	does if I am empty. */
	
	virtual IntegerVar highestIndex () DEFERRED_FUNC;
	
	
	virtual RPTR(Heaper) intFetch (IntegerVar ARG(key)) DEFERRED_FUNC;
	
	
	virtual void intRemove (IntegerVar ARG(anIdx));
	
	
	virtual BooleanVar intWipe (IntegerVar ARG(anIdx)) DEFERRED_FUNC;
	
	/* Given that the table is non-empty, 'intTab->lowestIndex()' 
	is equivalent to 
		'CAST(IntegerRegion,intTab->domain())->lowerBound()'. 
	'lowestIndex' is the 
		lowest index which is in my domain. I need to here specify 
	what 'lowestIndex' 
		does if I am empty. */
	
	virtual IntegerVar lowestIndex () DEFERRED_FUNC;
	
	
	virtual RPTR(ScruTable) subTable (APTR(XnRegion) ARG(reg)) DEFERRED_FUNC;
	
  public: /* accessing overloads */

	
	virtual void introduce (APTR(Position) ARG(key), APTR(Heaper) ARG(value));
	
	
	virtual void replace (APTR(Position) ARG(key), APTR(Heaper) ARG(value));
	
	
	virtual RPTR(Heaper) store (APTR(Position) ARG(key), APTR(Heaper) ARG(value));
	
	
	virtual RPTR(Heaper) fetch (APTR(Position) ARG(key));
	
	
	virtual BooleanVar includesKey (APTR(Position) ARG(aKey));
	
	
	virtual void remove (APTR(Position) ARG(aPos));
	
	
	virtual RPTR(XnRegion) runAt (APTR(Position) ARG(key));
	
	
	virtual BooleanVar wipe (APTR(Position) ARG(anIdx));
	
  public: /* testing */

	
	virtual BooleanVar includesIntKey (IntegerVar ARG(aKey)) DEFERRED_FUNC;
	
	
	virtual BooleanVar isEmpty () DEFERRED_FUNC;
	
  public: /* enumerating */

	
	virtual RPTR(TableStepper) stepper (APTR(OrderSpec) ARG(order) = NULL) DEFERRED_FUNC;
	
  public: /* runs */

	
	virtual RPTR(XnRegion) runAtInt (IntegerVar ARG(key)) DEFERRED_FUNC;
	
  public: /* creation */

	
	virtual RPTR(ScruTable) copy () DEFERRED_FUNC;
	
	/* Create a new table with an unspecified number of initial 
	domain positions. */
	
	IntegerTable ();
	
	
	virtual RPTR(ScruTable) emptySize (IntegerVar ARG(size)) DEFERRED_FUNC;
	
	/* Return a table which contains the elements from start to 
	stop, starting at 
		firstIndex. Zero-based subclasses will blast if firstIndex 
	is non-zero */
	
	virtual RPTR(ScruTable) offsetSubTableBetween (
			IntegerVar ARG(startIndex), 
			IntegerVar ARG(stopIndex), 
			IntegerVar ARG(firstIndex))
	 DEFERRED_FUNC;
	
	/* Hack for C++ overloading problem */
	
	virtual RPTR(ScruTable) subTableBetween (IntegerVar ARG(startIndex), IntegerVar ARG(stopIndex)) DEFERRED_FUNC;
	

};  /* end class IntegerTable */



#endif /* INTTABX_HXX */

