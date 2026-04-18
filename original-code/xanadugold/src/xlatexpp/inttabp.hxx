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

#ifndef INTTABP_HXX
#define INTTABP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef INTTABX_HXX
#include "inttabx.hxx"
#endif /* INTTABX_HXX */

#ifndef INTTABP_OXX
#include "inttabp.oxx"
#endif /* INTTABP_OXX */


#ifndef INTTABR_HXX
#include "inttabr.hxx"
#endif /* INTTABR_HXX */


#ifndef INTEGERX_OXX
#include "integerx.oxx"
#endif /* INTEGERX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class ITAscendingStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ITAscendingStepper : public IntegerTableStepper {

/* Attributes for class ITAscendingStepper */
	CONCRETE(ITAscendingStepper)
	NOT_A_TYPE(ITAscendingStepper)
	AUTO_GC(ITAscendingStepper)
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	ITAscendingStepper (APTR(OberIntegerTable) ARG(array), TCSJ);
	
	
	ITAscendingStepper (APTR(OberIntegerTable) ARG(array), IntegerVar ARG(index));
	
	/* n.b. !!!! This constructor DOES NOT COPY the table because this 
		constructor is used by the table copy (which creates a stepper). 
		The copy is done in the table->stepper(NULL) routine before calling 
		this constructor. */
	
	ITAscendingStepper (
			APTR(OberIntegerTable) ARG(array), 
			IntegerVar ARG(start), 
			IntegerVar ARG(stop))
	;
	
  public: /* special */

	
	virtual IntegerVar index ();
	
	
	virtual RPTR(Position) position ();
	
  private: /* private: private */

	
	virtual void verifyEntry ();
	
  private:
	CHKPTR(OberIntegerTable) arrayInternal;
	UInt32 indexInternal;
	UInt32 lastValueInternal;
	friend class IntegerTableStepper;
	friend class IntegerTableStepper;
};  /* end class ITAscendingStepper */



/* ************************************************************************ *
 * 
 *                    Class ITDescendingStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ITDescendingStepper : public IntegerTableStepper {

/* Attributes for class ITDescendingStepper */
	CONCRETE(ITDescendingStepper)
	NOT_A_TYPE(ITDescendingStepper)
	AUTO_GC(ITDescendingStepper)
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	ITDescendingStepper (APTR(OberIntegerTable) ARG(array), TCSJ);
	
	
	ITDescendingStepper (APTR(OberIntegerTable) ARG(array), IntegerVar ARG(index));
	
	
	ITDescendingStepper (
			APTR(OberIntegerTable) ARG(array), 
			IntegerVar ARG(start), 
			IntegerVar ARG(stop))
	;
	
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* special */

	
	virtual IntegerVar index ();
	
	
	virtual RPTR(Position) position ();
	
  private: /* private: private */

	
	virtual void verifyEntry ();
	
  private:
	CHKPTR(OberIntegerTable) arrayInternal;
	UInt32 indexInternal;
	UInt32 lastValueInternal;
	friend class IntegerTableStepper;
	friend class IntegerTableStepper;
};  /* end class ITDescendingStepper */



/* ************************************************************************ *
 * 
 *                    Class ITGenericStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ITGenericStepper : public IntegerTableStepper {

/* Attributes for class ITGenericStepper */
	CONCRETE(ITGenericStepper)
	NOT_A_TYPE(ITGenericStepper)
	AUTO_GC(ITGenericStepper)
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* special */

	
	virtual IntegerVar index ();
	
	
	virtual RPTR(Position) position ();
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	ITGenericStepper (APTR(IntegerTable) ARG(array), TCSJ);
	
	
	ITGenericStepper (APTR(IntegerTable) ARG(onTable), APTR(OrderSpec) ARG(anOrder));
	
	
	ITGenericStepper (APTR(IntegerTable) ARG(array), IntegerVar ARG(index));
	
	
	ITGenericStepper (
			APTR(IntegerTable) ARG(array), 
			IntegerVar ARG(start), 
			IntegerVar ARG(stop))
	;
	
	
	ITGenericStepper (
			APTR(IntegerTable) ARG(array), 
			IntegerVar ARG(start), 
			IntegerVar ARG(stop), 
			IntegerVar ARG(direction))
	;
	
  private: /* private: private */

	
	virtual void verifyEntry ();
	
  private:
	CHKPTR(IntegerTable) arrayInternal;
	IntegerVar indexInternal;
	IntegerVar lastValueInternal;
	Int32 incrementInternal;
	friend class IntegerTableStepper;
	friend class IntegerTableStepper;
	friend class IntegerTableStepper;
	friend class IntegerTableStepper;
};  /* end class ITGenericStepper */



/* ************************************************************************ *
 * 
 *                    Class OberIntegerTable 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class OberIntegerTable : public IntegerTable {

/* Attributes for class OberIntegerTable */
	DEFERRED(OberIntegerTable)
	AUTO_GC(OberIntegerTable)
  public: /* accessing */

	
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
	
  public: /* creation */

	
	virtual RPTR(ScruTable) copy () DEFERRED_FUNC;
	
	
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
	
  public: /* runs */

	
	virtual RPTR(XnRegion) runAtInt (IntegerVar ARG(key)) DEFERRED_FUNC;
	
  public: /* testing */

	
	virtual BooleanVar includesIntKey (IntegerVar ARG(aKey)) DEFERRED_FUNC;
	
	
	virtual BooleanVar isEmpty () DEFERRED_FUNC;
	
  public: /* enumerating */

	
	virtual RPTR(TableStepper) stepper (APTR(OrderSpec) ARG(order) = NULL) DEFERRED_FUNC;
	
  private: /* private: */

	/* return the elements array for rapid processing */
	
	virtual RPTR(PtrArray) elementsArray () DEFERRED_FUNC;
	
	/* return the size of the elements array for rapid processing */
	
	virtual UInt32 endOffset () DEFERRED_FUNC;
	
	
	virtual IntegerVar startIndex () DEFERRED_FUNC;
	
	/* return the size of the elements array for rapid processing */
	
	virtual UInt32 startOffset () DEFERRED_FUNC;
	
  protected: /* protected: create */

	
	OberIntegerTable ();
	
  public: /* vulnerable: COW stuff */

	
	virtual void aboutToWrite ();
	
	
	virtual void becomeCloneOnWrite (APTR(Heaper) ARG(where)) DEFERRED_SUBR;
	
	
	virtual WPTR(COWIntegerTable) getNextCOW ();
	
	
	virtual void setNextCOW (APTR(COWIntegerTable) ARG(table));
	
  public: /* overload junk */

	
	virtual RPTR(Heaper) store (APTR(Position) ARG(key), APTR(Heaper) ARG(value));
	
	
	virtual RPTR(Heaper) fetch (APTR(Position) ARG(key));
	
	
	virtual BooleanVar includesKey (APTR(Position) ARG(aKey));
	
	
	virtual RPTR(XnRegion) runAt (APTR(Position) ARG(key));
	
	
	virtual BooleanVar wipe (APTR(Position) ARG(key));
	
  private:
	NOCOPY CHKPTR(COWIntegerTable) OR(NULL) myNextCOW;
/* Friends for class OberIntegerTable */
/* friends for class OberIntegerTable */
friend class ITAscendingStepper;
friend class ITDescendingStepper;
friend class ITGenericStepper;
friend class COWIntegerTable;


	friend class IntegerTable;
};  /* end class OberIntegerTable */



/* ************************************************************************ *
 * 
 *                    Class   ActualIntegerTable 
 *
 * ************************************************************************ */




	/* The IntegerTable class is intended to provide an integer indexed
	table which is not constrained to be zero based. */

class ActualIntegerTable : public OberIntegerTable {

/* Attributes for class ActualIntegerTable */
	CONCRETE(ActualIntegerTable)
	COPY(ActualIntegerTable,XppCuisine)
	AUTO_GC(ActualIntegerTable)
  public: /* testing */

	
	virtual UInt32 fastHash ();
	
	
	virtual BooleanVar includesIntKey (IntegerVar ARG(aKey));
	
	
	virtual BooleanVar isEmpty ();
	
  public: /* accessing */

	
	virtual RPTR(Heaper) atIntStore (IntegerVar ARG(index), APTR(Heaper) ARG(value));
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual IntegerVar count ();
	
	/*  */
	/* The domainIsSimple flag is used as an optimization in this 
	method.  When it is True, I 
		stop looking after the first simple domain I find.  
	Therefore, when True, it MUST BE 
		CORRECT.  When it is False, I do a complete search, and set 
	the flag if the domain
		turns out to be simple. */
	
	virtual RPTR(XnRegion) domain ();
	
	
	virtual IntegerVar highestIndex ();
	
	
	virtual RPTR(Heaper) intFetch (IntegerVar ARG(index));
	
	
	virtual BooleanVar intWipe (IntegerVar ARG(index));
	
	
	virtual IntegerVar lowestIndex ();
	
  public: /* creation */

	
	virtual RPTR(ScruTable) copy ();
	
	/* The optional argument just hints at the number of elements
		 to eventually be added.  It makes no difference semantically. */
	
	ActualIntegerTable ();
	
	/* The optional argument just hints at the number of elements
		 to eventually be added.  It makes no difference semantically. */
	
	ActualIntegerTable (IntegerVar ARG(size), TCSJ);
	
	/* Hint at the domain to be accessed (inclusive, exclusive). */
	
	ActualIntegerTable (IntegerVar ARG(begin), IntegerVar ARG(end));
	
	
	ActualIntegerTable (
			APTR(PtrArray) ARG(array), 
			IntegerVar ARG(begin), 
			UInt32 ARG(count), 
			UInt32 ARG(first), 
			UInt32 ARG(last), 
			UInt32 ARG(aTally), 
			BooleanVar ARG(simple))
	;
	
	
	virtual void destroy ();
	
	
	virtual RPTR(ScruTable) emptySize (IntegerVar ARG(size));
	
	/* Copy the given range into a new IntegerTable. 
		The range is startIndex (inclusive) to stopIndex (exclusive)
		The first element in the sub table will be at firstIndex */
	
	virtual RPTR(ScruTable) offsetSubTableBetween (
			IntegerVar ARG(startIndex), 
			IntegerVar ARG(stopIndex), 
			IntegerVar ARG(firstIndex))
	;
	
	
	virtual RPTR(ScruTable) subTable (APTR(XnRegion) ARG(reg));
	
	/* Hack for C++ overloading problem */
	
	virtual RPTR(ScruTable) subTableBetween (IntegerVar ARG(startIndex), IntegerVar ARG(stopIndex));
	
  public: /* runs */

	
	virtual RPTR(XnRegion) runAtInt (IntegerVar ARG(anIdx));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
  public: /* enumerating */

	/* ignore order spec for now */
	/* Note that this method depends on the ITAscendingStepper 
	NOT copying the table. */
	
	virtual RPTR(TableStepper) stepper (APTR(OrderSpec) ARG(order) = NULL);
	
	
	virtual RPTR(Heaper) theOne ();
	
  private: /* private: */

	
	virtual RPTR(IntegerRegion) contigDomainStarting (UInt32 ARG(anIdx));
	
	/* return the elements array for rapid processing */
	
	virtual RPTR(PtrArray) elementsArray ();
	
	/* return the size of the elements array for rapid processing */
	
	virtual UInt32 endOffset ();
	
	/* Enlarge the receiver to contain more slots filled with nil. */
	
	virtual void enlargeAfter (IntegerVar ARG(toMinimum));
	
	/* Enlarge the receiver to contain more slots filled with nil. */
	
	virtual void enlargeBefore (IntegerVar ARG(toMinimum));
	
	/* This method returns the first table entry that is not NULL 
	after index. */
	
	virtual UInt32 firstElemAfter (UInt32 ARG(index));
	
	
	virtual RPTR(IntegerRegion) generateDomain ();
	
	/* This method returns the first table entry that is not NULL 
	after index. */
	
	virtual UInt32 lastElemBefore (UInt32 ARG(index));
	
	/* return the size of the elements array for rapid processing */
	
	virtual UInt32 maxElements ();
	
	
	virtual RPTR(IntegerRegion) nullDomainStarting (UInt32 ARG(anIdx));
	
	/* return the size of the elements array for rapid processing */
	
	virtual IntegerVar startIndex ();
	
	/* return the size of the elements array for rapid processing */
	
	virtual UInt32 startOffset ();
	
  protected: /* protected: destruct */

	
	virtual void destruct ();
	
  protected: /* protected: COW stuff */

	
	virtual void becomeCloneOnWrite (APTR(Heaper) ARG(where));
	
  public: /* overload junk */

	
	virtual RPTR(Heaper) store (APTR(Position) ARG(key), APTR(Heaper) ARG(value));
	
	
	virtual RPTR(Heaper) fetch (APTR(Position) ARG(key));
	
	
	virtual BooleanVar includesKey (APTR(Position) ARG(aKey));
	
	
	virtual RPTR(XnRegion) runAt (APTR(Position) ARG(anIdx));
	
	
	virtual BooleanVar wipe (APTR(Position) ARG(key));
	
  private:
	CHKPTR(PtrArray) elements;
	IntegerVar start;
	UInt32 elemCount;
	UInt32 firstElem;
	UInt32 lastElem;
	UInt32 tally;
	BooleanVar domainIsSimple;
/* Friends for class ActualIntegerTable */
/* friends for class ActualIntegerTable */
friend class ITAscendingStepper;
friend class ITDescendingStepper;
friend class ITGenericStepper;


	friend class IntegerTable;
	friend class IntegerTable;
	friend class IntegerTable;
};  /* end class ActualIntegerTable */



/* ************************************************************************ *
 * 
 *                    Class   COWIntegerTable 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class COWIntegerTable : public OberIntegerTable {

/* Attributes for class COWIntegerTable */
	CONCRETE(COWIntegerTable)
	MAY_BECOME(COWIntegerTable,ActualIntegerTable)
	COPY(COWIntegerTable,XppCuisine)
	AUTO_GC(COWIntegerTable)
  public: /* accessing */

	
	virtual RPTR(Heaper) atIntStore (IntegerVar ARG(aKey), APTR(Heaper) ARG(anObject));
	
	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual IntegerVar count ();
	
	
	virtual RPTR(XnRegion) domain ();
	
	
	virtual IntegerVar highestIndex ();
	
	
	virtual RPTR(Heaper) intFetch (IntegerVar ARG(key));
	
	
	virtual BooleanVar intWipe (IntegerVar ARG(anIdx));
	
	
	virtual IntegerVar lowestIndex ();
	
	
	virtual RPTR(ScruTable) subTable (APTR(XnRegion) ARG(reg));
	
  public: /* creation */

	
	virtual RPTR(ScruTable) copy ();
	
	
	COWIntegerTable (APTR(OberIntegerTable) ARG(table), TCSJ);
	
	/* only recover these during GC.  otherwise crashes occur */
	
	virtual void destroy ();
	
	
	virtual RPTR(ScruTable) emptySize (IntegerVar ARG(size));
	
	
	virtual RPTR(ScruTable) offsetSubTableBetween (
			IntegerVar ARG(startIndex), 
			IntegerVar ARG(stopIndex), 
			IntegerVar ARG(firstIndex))
	;
	
	
	virtual RPTR(ScruTable) subTableBetween (IntegerVar ARG(startIndex), IntegerVar ARG(stopIndex));
	
  public: /* runs */

	
	virtual RPTR(XnRegion) runAtInt (IntegerVar ARG(index));
	
  public: /* testing */

	
	virtual BooleanVar includesIntKey (IntegerVar ARG(aKey));
	
	
	virtual BooleanVar isEmpty ();
	
  public: /* enumerating */

	
	virtual RPTR(TableStepper) stepper (APTR(OrderSpec) ARG(order) = NULL);
	
  public: /* COW stuff */

	
	virtual WPTR(OberIntegerTable) getPrev ();
	
	
	virtual void setMuTable (APTR(OberIntegerTable) ARG(table));
	
	
	virtual void setPrev (APTR(OberIntegerTable) ARG(set));
	
  private: /* private: */

	/* return the elements array for rapid processing */
	
	virtual RPTR(PtrArray) elementsArray ();
	
	/* return the size of the elements array for rapid processing */
	
	virtual UInt32 endOffset ();
	
	
	virtual IntegerVar startIndex ();
	
	/* return the size of the elements array for rapid processing */
	
	virtual UInt32 startOffset ();
	
  protected: /* protected: COW stuff */

	
	virtual void aboutToWrite ();
	
	
	virtual void becomeCloneOnWrite (APTR(Heaper) ARG(where));
	
  public: /* overload junk */

	
	virtual RPTR(Heaper) store (APTR(Position) ARG(key), APTR(Heaper) ARG(value));
	
	
	virtual RPTR(Heaper) fetch (APTR(Position) ARG(key));
	
	
	virtual BooleanVar includesKey (APTR(Position) ARG(aKey));
	
	
	virtual RPTR(XnRegion) runAt (APTR(Position) ARG(key));
	
	
	virtual BooleanVar wipe (APTR(Position) ARG(key));
	
  private:
	NOCOPY CHKPTR(OberIntegerTable) OR(NULL) myPrev;
	CHKPTR(OberIntegerTable) myTable;
};  /* end class COWIntegerTable */



#endif /* INTTABP_HXX */

