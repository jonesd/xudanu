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

#ifndef TABLESP_HXX
#define TABLESP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef TABLESX_HXX
#include "tablesx.hxx"
#endif /* TABLESX_HXX */

#ifndef TABLESP_OXX
#include "tablesp.oxx"
#endif /* TABLESP_OXX */


#ifndef INTTABX_OXX
#include "inttabx.oxx"
#endif /* INTTABX_OXX */

#ifndef SPACEX_OXX
#include "spacex.oxx"
#endif /* SPACEX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class ImmuTableOnMu 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ImmuTableOnMu : public ImmuTable {

/* Attributes for class ImmuTableOnMu */
	CONCRETE(ImmuTableOnMu)
	NOT_A_TYPE(ImmuTableOnMu)
	COPY(ImmuTableOnMu,XppCuisine)
	AUTO_GC(ImmuTableOnMu)
  private: /* private: instance creation */

	/* use the given Mu to store current value */
	/* it should be a copy for my exclusive use */
	/* this should only be called from the pseudo constructor or 
	from class methods */
	
	ImmuTableOnMu (APTR(MuTable) ARG(aMuTable), TCSJ);
	
  public: /* accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual IntegerVar count ();
	
	
	virtual RPTR(XnRegion) domain ();
	
	
	virtual RPTR(Heaper) fetch (APTR(Position) ARG(key));
	
	
	virtual RPTR(Heaper) intFetch (IntegerVar ARG(key));
	
	
	virtual RPTR(ScruTable) subTable (APTR(XnRegion) ARG(region));
	
  public: /* SEF manipulation */

	
	virtual RPTR(ImmuTable) combineWith (APTR(ImmuTable) ARG(other));
	
	
	virtual RPTR(ImmuTable) without (APTR(Position) ARG(index));
	
  public: /* conversion */

	
	virtual RPTR(MuTable) asMuTable ();
	
  public: /* testing */

	
	virtual BooleanVar includesIntKey (IntegerVar ARG(aKey));
	
	
	virtual BooleanVar includesKey (APTR(Position) ARG(aKey));
	
	
	virtual BooleanVar isEmpty ();
	
  public: /* enumerating */

	
	virtual RPTR(TableStepper) stepper (APTR(OrderSpec) ARG(order) = NULL);
	
	
	virtual RPTR(Heaper) theOne ();
	
  private: /* private: accessing */

	
	virtual RPTR(MuTable) getMuTable ();
	
  public: /* creation */

	
	virtual RPTR(ScruTable) emptySize (IntegerVar ARG(size));
	
  public: /* runs */

	
	virtual RPTR(XnRegion) runAt (APTR(Position) ARG(key));
	
	
	virtual RPTR(XnRegion) runAtInt (IntegerVar ARG(key));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	CHKPTR(MuTable) myMuTable;
/* Friends for class ImmuTableOnMu */
friend SPTR(ImmuTable) immuTable (MuTable*);
friend SPTR(ImmuTable) immuTable (CoordinateSpace * cs);
friend SPTR(ImmuTable) MuTable::asImmuTable ();


	friend class ImmuTable;
};  /* end class ImmuTableOnMu */



/* ************************************************************************ *
 * 
 *                    Class IntegerScruTable 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class IntegerScruTable : public ScruTable {

/* Attributes for class IntegerScruTable */
	CONCRETE(IntegerScruTable)
	NOT_A_TYPE(IntegerScruTable)
	COPY(IntegerScruTable,XppCuisine)
	AUTO_GC(IntegerScruTable)
  public: /* pseudo constructors */

	
	static RPTR(ScruTable) make (APTR(IntegerTable) ARG(fromTable));
	
  public: /* accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual IntegerVar count ();
	
	
	virtual RPTR(XnRegion) domain ();
	
	
	virtual RPTR(Heaper) fetch (APTR(Position) ARG(key));
	
	
	virtual RPTR(Heaper) intFetch (IntegerVar ARG(key));
	
	
	virtual RPTR(ScruTable) subTable (APTR(XnRegion) ARG(reg));
	
	/* Return a table which contains the intersection of this 
	table's domain and the 
		domain specified by the enclosure. */
	
	virtual RPTR(ScruTable) subTableBetween (IntegerVar ARG(start), IntegerVar ARG(stop));
	
  public: /* creation */

	
	virtual RPTR(ScruTable) copy ();
	
	
	IntegerScruTable (APTR(IntegerTable) ARG(fromTable), TCSJ);
	
	
	virtual RPTR(ScruTable) emptySize (IntegerVar ARG(size));
	
  public: /* runs */

	
	virtual RPTR(XnRegion) runAt (APTR(Position) ARG(key));
	
	
	virtual RPTR(XnRegion) runAtInt (IntegerVar ARG(key));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar includesIntKey (IntegerVar ARG(aKey));
	
	
	virtual BooleanVar includesKey (APTR(Position) ARG(aKey));
	
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* enumerating */

	
	virtual RPTR(TableStepper) stepper (APTR(OrderSpec) ARG(order) = NULL);
	
  public: /* conversion */

	
	virtual RPTR(ImmuTable) asImmuTable ();
	
	
	virtual RPTR(MuTable) asMuTable ();
	
  private: /* private: private */

	
	virtual RPTR(ScruTable) innerTable ();
	
  private:
	CHKPTR(IntegerTable) tableToScru;
};  /* end class IntegerScruTable */



/* ************************************************************************ *
 * 
 *                    Class OffsetImmuTable 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class OffsetImmuTable : public ImmuTable {

/* Attributes for class OffsetImmuTable */
	CONCRETE(OffsetImmuTable)
	NOT_A_TYPE(OffsetImmuTable)
	AUTO_GC(OffsetImmuTable)
  public: /* accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual IntegerVar count ();
	
	
	virtual RPTR(XnRegion) domain ();
	
	
	virtual RPTR(Heaper) fetch (APTR(Position) ARG(anIndex));
	
	
	virtual RPTR(Heaper) intFetch (IntegerVar ARG(idx));
	
	
	virtual RPTR(ScruTable) subTable (APTR(XnRegion) ARG(encl));
	
	
	virtual RPTR(ScruTable) transformedBy (APTR(Dsp) ARG(dsp));
	
  public: /* runs */

	
	virtual RPTR(XnRegion) runAt (APTR(Position) ARG(key));
	
	
	virtual RPTR(XnRegion) runAtInt (IntegerVar ARG(anIdx));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar includesIntKey (IntegerVar ARG(aKey));
	
	
	virtual BooleanVar includesKey (APTR(Position) ARG(aKey));
	
	
	virtual BooleanVar isEmpty ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
  public: /* creation */

	
	OffsetImmuTable (APTR(ImmuTable) ARG(table), APTR(Dsp) ARG(dsp));
	
	
	virtual RPTR(ScruTable) emptySize (IntegerVar ARG(size));
	
  public: /* conversion */

	
	virtual RPTR(MuTable) asMuTable ();
	
  public: /* enumerating */

	
	virtual RPTR(TableStepper) stepper (APTR(OrderSpec) ARG(order) = NULL);
	
  private: /* private: private */

	
	virtual RPTR(Dsp) innerDsp ();
	
	
	virtual RPTR(ScruTable) innerTable ();
	
  public: /* SEF manipulation */

	
	virtual RPTR(ImmuTable) combineWith (APTR(ImmuTable) ARG(other));
	
	
	virtual RPTR(ImmuTable) without (APTR(Position) ARG(index));
	
  private:
	CHKPTR(ImmuTable) myTable;
	CHKPTR(Dsp) myDsp;
	friend class ImmuTable;
};  /* end class OffsetImmuTable */



/* ************************************************************************ *
 * 
 *                    Class OffsetScruTable 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class OffsetScruTable : public ScruTable {

/* Attributes for class OffsetScruTable */
	CONCRETE(OffsetScruTable)
	NOT_A_TYPE(OffsetScruTable)
	AUTO_GC(OffsetScruTable)
  public: /* accessing */

	
	virtual RPTR(CoordinateSpace) coordinateSpace ();
	
	
	virtual IntegerVar count ();
	
	
	virtual RPTR(XnRegion) domain ();
	
	
	virtual RPTR(Heaper) fetch (APTR(Position) ARG(anIndex));
	
	
	virtual RPTR(Heaper) intFetch (IntegerVar ARG(idx));
	
	
	virtual RPTR(ScruTable) subTable (APTR(XnRegion) ARG(encl));
	
	
	virtual RPTR(ScruTable) transformedBy (APTR(Dsp) ARG(dsp));
	
  public: /* runs */

	
	virtual RPTR(XnRegion) runAt (APTR(Position) ARG(key));
	
	
	virtual RPTR(XnRegion) runAtInt (IntegerVar ARG(anIdx));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	
	virtual BooleanVar includesIntKey (IntegerVar ARG(aKey));
	
	
	virtual BooleanVar includesKey (APTR(Position) ARG(aKey));
	
	
	virtual BooleanVar isEmpty ();
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(aStream));
	
  public: /* creation */

	
	virtual RPTR(ScruTable) copy ();
	
	
	OffsetScruTable (APTR(ScruTable) ARG(table), APTR(Dsp) ARG(dsp));
	
	
	virtual RPTR(ScruTable) emptySize (IntegerVar ARG(size));
	
  public: /* conversion */

	
	virtual RPTR(ImmuTable) asImmuTable ();
	
	
	virtual RPTR(MuTable) asMuTable ();
	
  public: /* enumerating */

	
	virtual RPTR(TableStepper) stepper (APTR(OrderSpec) ARG(order) = NULL);
	
  private: /* private: */

	
	virtual RPTR(Dsp) innerDsp ();
	
	
	virtual RPTR(ScruTable) innerTable ();
	
  private:
	CHKPTR(ScruTable) myTable;
	CHKPTR(Dsp) myDsp;
};  /* end class OffsetScruTable */



/* ************************************************************************ *
 * 
 *                    Class OffsetScruTableStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class OffsetScruTableStepper : public TableStepper {

/* Attributes for class OffsetScruTableStepper */
	CONCRETE(OffsetScruTableStepper)
	NOT_A_TYPE(OffsetScruTableStepper)
	AUTO_GC(OffsetScruTableStepper)
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual WPTR(Heaper) get ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  public: /* special */

	
	virtual IntegerVar index ();
	
	
	virtual RPTR(Position) position ();
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	OffsetScruTableStepper (APTR(TableStepper) ARG(onStepper), APTR(Dsp) ARG(aDsp));
	
  private:
	CHKPTR(TableStepper) myTableStepper;
	CHKPTR(Dsp) myDsp;
};  /* end class OffsetScruTableStepper */



#endif /* TABLESP_HXX */

