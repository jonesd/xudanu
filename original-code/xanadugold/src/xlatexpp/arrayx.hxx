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

#ifndef ARRAYX_HXX
#define ARRAYX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef ARRAYX_OXX
#include "arrayx.oxx"
#endif /* ARRAYX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef INTTABX_HXX
#include "inttabx.hxx"
#endif /* INTTABX_HXX */


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
/* xpp class */




/* ************************************************************************ *
 * 
 *                    Class MuArray 
 *
 * ************************************************************************ */




	/* The class XuArray is intended to model zero-based arrays 
	with integer keys (indices).
		
		This makes them like the array primitive in C and C++.  
	There is an additional constraint, which is they are to have 
	simple domains.  Therefore they should not be constructed 
	with non-contiguous sections.  This is not currently 
	enforced.  Given that it is enforced, an XuArray with count N 
	would have as its domain exactly the integers from 0 to N-1.
		
		There is some controversy over whether XuArray should be a 
	type and enforce this contraint (by BLASTing if an attempt is 
	made to violate the constraint), or whether XuArray is just a 
	specialized implementation for when an IntegerTable happens 
	to meet this constraint; in which case it should "become" a 
	more general implementation when an attempt is made to 
	violate the constraint (see "Type Safe Become").  In the 
	latter case, XuArray will probably be made a private class as 
	well.  Please give us your opinion.
		
		XuArray provides no additional protocol. */

class MuArray : public IntegerTable {

/* Attributes for class MuArray */
	DEFERRED(MuArray)
	NO_GC(MuArray)
  public: /* creation */

	/* A new empty XnArray */
	
	static INLINE RPTR(MuArray) array ();
	
	/* A new XnArray initialized with a single element, 'obj0', 
	stored at index 0. */
	
	static RPTR(MuArray) array (APTR(Heaper) ARG(obj0));
	
	/* A new XnArray initialized with a two elements stored at 
	indicies 0 and 1. */
	
	static RPTR(MuArray) array (APTR(Heaper) ARG(obj0), APTR(Heaper) ARG(obj1));
	
	/* A new XuArray initialized with a three elements stored at 
	indicies 0, 1, and 2. */
	
	static RPTR(MuArray) array (
			APTR(Heaper) ARG(obj0), 
			APTR(Heaper) ARG(obj1), 
			APTR(Heaper) ARG(obj2))
	;
	
	/* A new XuArray initialized with a four elements stored at 
	indicies 0 through 3. */
	
	static RPTR(MuArray) array (
			APTR(Heaper) ARG(obj0), 
			APTR(Heaper) ARG(obj1), 
			APTR(Heaper) ARG(obj2), 
			APTR(Heaper) ARG(obj3))
	;
	
	/* Returns an Accumulator which will produce an XuArray of 
	the elements 
		accumulated into it in order of accumulation. See XuArray. 
	Equivalent to 
		'tableAccumulator()'. Eventually either he or I should be 
	declared obsolete. */
	
	static RPTR(TableAccumulator) arrayAccumulator ();
	
	/* An accumulator which will accumulate by appending elements 
	onto the end of 
		'onArray'. It is an error for anyone else to modify 
	'onArray' between creating 
		this accumulator and accumulating into it. acc->value() will 
	return 'onArray' 
		itself. */
	
	static RPTR(TableAccumulator) arrayAccumulator (APTR(MuArray) ARG(onArray));
	
	/* 'someSize' is a hint about how big we should expect the 
	array to need to grow. */
	
	static RPTR(MuArray) make (IntegerVar ARG(someSize));
	
	/* The resulting ScruTable is a view onto 'array'. It is a 
	view in which each key 
		is offset by 'dsp' from where it is in 'array'. By saying it 
	is a view, we mean 
		that as 'array' is modified, the view tracks the changes. */
	
	static RPTR(ScruTable) offsetScruArray (APTR(MuArray) ARG(array), APTR(Dsp) ARG(dsp));
	
  public: /* accessing */

	
	virtual RPTR(Heaper) atIntStore (IntegerVar ARG(key), APTR(Heaper) ARG(value)) DEFERRED_FUNC;
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual IntegerVar count () DEFERRED_FUNC;
	
	
	virtual RPTR(XnRegion) domain () DEFERRED_FUNC;
	
	
	virtual IntegerVar highestIndex () DEFERRED_FUNC;
	
	
	virtual RPTR(Heaper) intFetch (IntegerVar ARG(key)) DEFERRED_FUNC;
	
	
	virtual BooleanVar intWipe (IntegerVar ARG(anIdx)) DEFERRED_FUNC;
	
	
	virtual IntegerVar lowestIndex () DEFERRED_FUNC;
	
	/* Return a table which contains the elements from start to 
	stop, starting at firstIndex.
		Zero-based subclasses will blast if firstIndex is non-zero */
	
	virtual RPTR(ScruTable) offsetSubTableBetween (
			IntegerVar ARG(startIndex), 
			IntegerVar ARG(stopIndex), 
			IntegerVar ARG(firstIndex))
	;
	
	
	virtual RPTR(ScruTable) subTable (APTR(XnRegion) ARG(region)) DEFERRED_FUNC;
	
	
	virtual RPTR(ScruTable) subTableBetween (IntegerVar ARG(startLoc), IntegerVar ARG(endLoc)) DEFERRED_FUNC;
	
	
	virtual RPTR(ScruTable) transformedBy (APTR(Dsp) ARG(dsp));
	
  public: /* creation */

	
	virtual RPTR(ScruTable) copy () DEFERRED_FUNC;
	
	
	virtual RPTR(ScruTable) emptySize (IntegerVar ARG(size)) DEFERRED_FUNC;
	
  public: /* testing */

	
	virtual BooleanVar includesIntKey (IntegerVar ARG(aKey));
	
	
	virtual BooleanVar isEmpty ();
	
  public: /* runs */

	
	virtual RPTR(XnRegion) runAtInt (IntegerVar ARG(key)) DEFERRED_FUNC;
	
  public: /* enumerating */

	/* Return a stepper on this table. */
	
	virtual RPTR(TableStepper) stepper (APTR(OrderSpec) ARG(order) = NULL) DEFERRED_FUNC;
	
	
	virtual RPTR(Heaper) theOne ();
	
  public: /* bulk operations */

	/* I 'wipe' from myself all associations whose key 
		is in 'region'. See MuTable::wipe */
	
	virtual void wipeAll (APTR(XnRegion) ARG(region));
	
  public: /* overload junk */

	
	virtual RPTR(Heaper) store (APTR(Position) ARG(key), APTR(Heaper) ARG(value));
	
	
	virtual RPTR(Heaper) fetch (APTR(Position) ARG(key));
	
	
	virtual BooleanVar includesKey (APTR(Position) ARG(aKey));
	
	
	virtual RPTR(XnRegion) runAt (APTR(Position) ARG(key));
	
	
	virtual BooleanVar wipe (APTR(Position) ARG(key));
	

	/* automatic 0-argument constructor */
  public:
	MuArray();


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	
};  /* end class MuArray */


#ifdef USE_INLINE
#ifndef ARRAYX_IXX
#include "arrayx.ixx"
#endif /* ARRAYX_IXX */


#endif /* USE_INLINE */


#endif /* ARRAYX_HXX */

