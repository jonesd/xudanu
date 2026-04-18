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

#ifndef TABENTP_HXX
#define TABENTP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef TABENTX_HXX
#include "tabentx.hxx"
#endif /* TABENTX_HXX */

#ifndef TABENTP_OXX
#include "tabentp.oxx"
#endif /* TABENTP_OXX */


#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */


#ifndef CACHEX_OXX
#include "cachex.oxx"
#endif /* CACHEX_OXX */

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
 *                    Class BucketArrayStepper 
 *
 * ************************************************************************ */



/* Initializers for BucketArrayStepper */







	/* NO CLASS COMMENT */

class BucketArrayStepper : public TableStepper {

/* Attributes for class BucketArrayStepper */
	CONCRETE(BucketArrayStepper)
	NOT_A_TYPE(BucketArrayStepper)
	AUTO_GC(BucketArrayStepper)

/* Initializers for BucketArrayStepper */



friend class INIT_TIME_NAME(BucketArrayStepper,initTimeNonInherited);

  public: /* creation */

	
	static RPTR(TableStepper) make (APTR(SharedPtrArray) ARG(entries));
	
  public: /* operations */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual void step ();
	
  private: /* private: */

	/* Step through the bucket till we find something with a 
	matching key. */
	
	virtual void verifyEntry ();
	
  public: /* special */

	
	virtual IntegerVar index ();
	
	
	virtual RPTR(Position) position ();
	
  protected: /* protected: create */

	
	BucketArrayStepper (
			APTR(SharedPtrArray) ARG(entries), 
			APTR(TableEntry) OR(NULL) ARG(entry), 
			Int32 ARG(nextBucket))
	;
	
	
	virtual void destruct ();
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
	
	virtual void destroy ();
	
  private:
	CHKPTR(TableEntry) OR(NULL) myEntry;
	CHKPTR(SharedPtrArray) OF1(TableEntry) myEntries;
	Int4 myNextBucket;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(InstanceCache) SomeSteppers;
};  /* end class BucketArrayStepper */



/* ************************************************************************ *
 * 
 *                    Class HashIndexEntry 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HashIndexEntry : public TableEntry {

/* Attributes for class HashIndexEntry */
	CONCRETE(HashIndexEntry)
	COPY(HashIndexEntry,XppCuisine)
	NOT_A_TYPE(HashIndexEntry)
	NO_GC(HashIndexEntry)
  public: /* accessing */

	/* Return true if my key matches key. */
	
	virtual BooleanVar match (APTR(Position) ARG(key));
	
	/* Return true if my key matches the position associated with index. */
	
	virtual BooleanVar matchInt (IntegerVar ARG(index));
	
	
	virtual RPTR(Position) position ();
	
	/* Return true if my value can be replaced in place, and 
	false if the entire entry must be replaced. */
	
	virtual BooleanVar replaceValue (APTR(Heaper) ARG(newValue));
	
  public: /* creation */

	
	virtual RPTR(TableEntry) copy ();
	
	
	HashIndexEntry (APTR(Heaper) ARG(value), TCSJ);
	
	
	HashIndexEntry (APTR(TableEntry) ARG(next), APTR(Heaper) ARG(value));
	

	friend class TableEntry;
	friend class TableEntry;
};  /* end class HashIndexEntry */



/* ************************************************************************ *
 * 
 *                    Class HeaperAsEntry 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class HeaperAsEntry : public TableEntry {

/* Attributes for class HeaperAsEntry */
	CONCRETE(HeaperAsEntry)
	COPY(HeaperAsEntry,XppCuisine)
	NOT_A_TYPE(HeaperAsEntry)
	NO_GC(HeaperAsEntry)
  public: /* accessing */

	/* Return true if my position matches position. */
	
	virtual BooleanVar match (APTR(Position) ARG(position));
	
	
	virtual RPTR(Position) position ();
	
	/* Return true if my value can be replaced in place, and 
	false if the entire entry must be replaced. */
	
	virtual BooleanVar replaceValue (APTR(Heaper) ARG(newValue));
	
  public: /* creation */

	
	virtual RPTR(TableEntry) copy ();
	
	
	HeaperAsEntry (APTR(Heaper) ARG(value), TCSJ);
	
	
	HeaperAsEntry (APTR(TableEntry) ARG(next), APTR(Heaper) ARG(value));
	

	friend class TableEntry;
	friend class TableEntry;
};  /* end class HeaperAsEntry */



/* ************************************************************************ *
 * 
 *                    Class IndexEntry 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class IndexEntry : public TableEntry {

/* Attributes for class IndexEntry */
	CONCRETE(IndexEntry)
	COPY(IndexEntry,XppCuisine)
	NOT_A_TYPE(IndexEntry)
	NO_GC(IndexEntry)
  public: /* accessing */

	
	virtual IntegerVar index ();
	
	/* Return true if my key matches key. */
	
	virtual BooleanVar match (APTR(Position) ARG(key));
	
	/* Return true if my key matches the position associated with index. */
	
	virtual BooleanVar matchInt (IntegerVar ARG(index));
	
	
	virtual RPTR(Position) position ();
	
  public: /* creation */

	
	virtual RPTR(TableEntry) copy ();
	
	
	IndexEntry (IntegerVar ARG(index), APTR(Heaper) ARG(value));
	
	
	IndexEntry (
			APTR(TableEntry) ARG(next), 
			APTR(Heaper) ARG(value), 
			IntegerVar ARG(index))
	;
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	IntegerVar myIndex;
	friend class TableEntry;
};  /* end class IndexEntry */



/* ************************************************************************ *
 * 
 *                    Class PositionEntry 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class PositionEntry : public TableEntry {

/* Attributes for class PositionEntry */
	CONCRETE(PositionEntry)
	COPY(PositionEntry,XppCuisine)
	NOT_A_TYPE(PositionEntry)
	AUTO_GC(PositionEntry)
  public: /* accessing */

	/* Return true if my key matches key. */
	
	virtual BooleanVar match (APTR(Position) ARG(key));
	
	
	virtual RPTR(Position) position ();
	
  public: /* creation */

	
	virtual RPTR(TableEntry) copy ();
	
	
	PositionEntry (APTR(Position) ARG(key), APTR(Heaper) ARG(value));
	
	
	PositionEntry (
			APTR(TableEntry) ARG(next), 
			APTR(Heaper) ARG(value), 
			APTR(Position) ARG(key))
	;
	
  private:
	CHKPTR(Position) myKey;
	friend class TableEntry;
};  /* end class PositionEntry */



#endif /* TABENTP_HXX */

