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

#ifndef SETTABX_HXX
#define SETTABX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SETTABX_OXX
#include "settabx.oxx"
#endif /* SETTABX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


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
 *                    Class SetTable 
 *
 * ************************************************************************ */




	/* SetTable is a table-like object (NOT at true table) that 
	can store multiple values at a single position.  See MuTable 
	for comments on the protocol.
	  The reason that this is not a table subclass is because of 
	several ambiguities in the contract.  For example, replace 
	for a table implies that the position must be previously 
	occupied, but in a settable the position is occupied only if 
	the exact association (key->value) is present. */

class SetTable : public Heaper {

/* Attributes for class SetTable */
	CONCRETE(SetTable)
	EQ(SetTable)
	COPY(SetTable,XppCuisine)
	AUTO_GC(SetTable)
  public: /* creation */

	
	static INLINE RPTR(SetTable) make (APTR(CoordinateSpace) ARG(cs));
	
	
	static RPTR(SetTable) make (APTR(CoordinateSpace) ARG(cs), IntegerVar ARG(size));
	
  public: /* accessing */

	/* Store anObject at position aKey; BLAST if position is 
	already occupied
		 (for SetTable, there must be an object that isEqual to 
	anObject at aKey 
		 for the position to be considered occupied) */
	
	virtual void introduce (APTR(Position) ARG(aKey), APTR(Heaper) ARG(anObject));
	
	/* Store anObject at position aKey; return TRUE if store 
	accomplished, FALSE otherwise */
	
	virtual BooleanVar store (APTR(Position) ARG(aKey), APTR(Heaper) ARG(anObject));
	
	
	virtual void atIntIntroduce (IntegerVar ARG(index), APTR(Heaper) ARG(anObject));
	
	
	virtual BooleanVar atIntStore (IntegerVar ARG(index), APTR(Heaper) ARG(anObject));
	
	
	INLINE RPTR(CoordinateSpace) coordinateSpace ();
	
	
	INLINE IntegerVar count ();
	
	
	virtual RPTR(XnRegion) domain ();
	
	
	virtual void intRemove (IntegerVar ARG(index), APTR(Heaper) ARG(value));
	
	
	virtual void remove (APTR(Position) ARG(key), APTR(Heaper) ARG(value));
	
	
	virtual BooleanVar wipe (IntegerVar ARG(index), APTR(Heaper) ARG(value));
	
	
	virtual BooleanVar wipeAssociation (APTR(Position) ARG(key), APTR(Heaper) ARG(value));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
	
	virtual void printOnWithSimpleSyntax (
			ostream& ARG(oo), 
			char * ARG(open), 
			char * ARG(sep), 
			char * ARG(close))
	;
	
  public: /* runLength */

	
	virtual RPTR(XnRegion) runAt (APTR(Position) ARG(index));
	
	
	virtual RPTR(XnRegion) runAtInt (IntegerVar ARG(index));
	
  public: /* enumerating */

	/* ignore order spec for now */
	
	virtual RPTR(TableStepper) stepper (APTR(OrderSpec) ARG(order) = NULL);
	
	
	virtual RPTR(Stepper) stepperAt (APTR(Position) ARG(key));
	
	
	virtual RPTR(Stepper) stepperAtInt (IntegerVar ARG(index));
	
  public: /* creation */

	
	SetTable (
			APTR(SharedPtrArray) OF1(TableEntry) ARG(entries), 
			Int32 ARG(tally), 
			APTR(CoordinateSpace) ARG(cs))
	;
	
	
	virtual void destruct ();
	
	/* return an empty table just like the current one */
	
	INLINE RPTR(SetTable) emptySize (IntegerVar ARG(size));
	
  public: /* testing */

	
	virtual BooleanVar includes (APTR(Position) ARG(key), APTR(Heaper) ARG(value));
	
	
	virtual BooleanVar includesKey (APTR(Position) ARG(aKey));
	
	
	virtual BooleanVar isEmpty ();
	
  private: /* private: resize */

	/* If my contents are shared, and I'm about to change them, 
	make a copy of them. */
	
	virtual void aboutToWrite ();
	
	
	virtual void checkSize ();
	
	
	virtual void storeEntry (APTR(TableEntry) ARG(entry));
	
  private:
	CHKPTR(SharedPtrArray) myHashEntries;
	Int32 myTally;
	CHKPTR(CoordinateSpace) myCoordinateSpace;
};  /* end class SetTable */


#ifdef USE_INLINE
#ifndef SETTABX_IXX
#include "settabx.ixx"
#endif /* SETTABX_IXX */


#endif /* USE_INLINE */


#endif /* SETTABX_HXX */

