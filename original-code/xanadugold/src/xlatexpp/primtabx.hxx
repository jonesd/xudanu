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

#ifndef PRIMTABX_HXX
#define PRIMTABX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PRIMTABX_OXX
#include "primtabx.oxx"
#endif /* PRIMTABX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef WPARRAYX_OXX
#include "wparrayx.oxx"
#endif /* WPARRAYX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class PrimIndexTable 
 *
 * ************************************************************************ */




	/* Map possibly wimpy pointers to integers.  Common usage 
	almost never does a
	remove on this class, therefore we rehash in order to save 
	time on other ops. */

class PrimIndexTable : public Heaper {

/* Attributes for class PrimIndexTable */
	CONCRETE(PrimIndexTable)
	AUTO_GC(PrimIndexTable)
  public: /* create */

	
	static RPTR(PrimIndexTable) make (Int32 ARG(size));
	
	
	static RPTR(PrimIndexTable) wimpyIndexTable (Int32 ARG(size));
	
  public: /* accessing */

	
	virtual void introduce (APTR(Heaper) ARG(ptr), IntegerVar ARG(index));
	
	
	virtual void store (APTR(Heaper) ARG(ptr), IntegerVar ARG(index));
	
	/* Clear all entries from the table. I know this looks like a 
	hack, but the 
		alternative is to throw away the table and build a new one: 
	an expensive 
		prospect for comm. */
	
	virtual void clearAll ();
	
	
	INLINE Int32 count ();
	
	/* return -1 on not found. */
	
	virtual IntegerVar fetch (APTR(Heaper) ARG(ptr));
	
	
	virtual IntegerVar get (APTR(Heaper) ARG(ptr));
	
	
	virtual void remove (APTR(Heaper) ARG(ptr));
	
  protected: /* protected: */

	
	PrimIndexTable (Int32 ARG(size), BooleanVar ARG(wimpy));
	
	
	virtual void destruct ();
	
  private: /* private: */

	
	virtual void grow ();
	
	
	virtual Int32 hashFind (APTR(Heaper) ARG(value));
	
	
	virtual Int32 hashFindFetch (APTR(Heaper) ARG(value));
	
	
	virtual void rehash (
			APTR(PtrArray) ARG(oldPtrs), 
			APTR(IntegerVarArray) ARG(oldIndices), 
			Int32 ARG(newSize))
	;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  public: /* enumerating */

	
	virtual RPTR(PrimIndexTableStepper) stepper ();
	
  private:
	CHKPTR(PtrArray) myPtrs;
	CHKPTR(IntegerVarArray) myIndices;
	Int4 myTally;
	BooleanVar amWimpy;
	Int4 myOriginalSize;
/* Friends for class PrimIndexTable */
/* friends for class PrimIndexTable */
friend SPTR(PrimIndexTable) primIndexTable (Int4 size);
friend SPTR(PrimIndexTable) wimpyIndexTable (Int4 size);
friend class PrimIndexTableTester;


};  /* end class PrimIndexTable */



/* ************************************************************************ *
 * 
 *                    Class PrimIndexTableStepper 
 *
 * ************************************************************************ */




	/* Stepper over map from pointers to integers */

class PrimIndexTableStepper : public Stepper {

/* Attributes for class PrimIndexTableStepper */
	CONCRETE(PrimIndexTableStepper)
	AUTO_GC(PrimIndexTableStepper)
  public: /* accessing */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	/* This does not necessarily return a Position */
	
	virtual RPTR(Heaper) key ();
	
	
	virtual void step ();
	
	
	virtual IntegerVar value ();
	
  protected: /* protected: create */

	
	PrimIndexTableStepper (
			APTR(PtrArray) ARG(from), 
			APTR(IntegerVarArray) ARG(to), 
			Int32 ARG(index))
	;
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
  private:
	CHKPTR(PtrArray) myPtrs;
	CHKPTR(IntegerVarArray) myIndices;
	Int4 myIndex;
/* Friends for class PrimIndexTableStepper */
/* friends for class PrimIndexTableStepper */
friend class PrimIndexTable;


};  /* end class PrimIndexTableStepper */



/* ************************************************************************ *
 * 
 *                    Class PrimPtr2PtrTable 
 *
 * ************************************************************************ */




	/* Map wimpy pointers to strong ptrs */

class PrimPtr2PtrTable : public Heaper {

/* Attributes for class PrimPtr2PtrTable */
	CONCRETE(PrimPtr2PtrTable)
	AUTO_GC(PrimPtr2PtrTable)
  public: /* create */

	
	static RPTR(PrimPtr2PtrTable) make (Int32 ARG(size));
	
  public: /* enumerating */

	
	virtual RPTR(PrimPtr2PtrTableStepper) stepper ();
	
  public: /* accessing */

	
	virtual void introduce (APTR(Heaper) ARG(key), APTR(Heaper) ARG(value));
	
	
	virtual void store (APTR(Heaper) ARG(key), APTR(Heaper) ARG(value));
	
	
	INLINE Int32 count ();
	
	
	virtual RPTR(Heaper) fetch (APTR(Heaper) ARG(key));
	
	
	virtual RPTR(Heaper) get (APTR(Heaper) ARG(ptr));
	
	
	virtual void remove (APTR(Heaper) ARG(key));
	
  protected: /* protected: destruct */

	
	virtual void destruct ();
	
  protected: /* protected: create */

	
	PrimPtr2PtrTable (Int32 ARG(size), TCSJ);
	
  private: /* private: */

	
	virtual void grow ();
	
	
	virtual Int32 hashFind (APTR(Heaper) ARG(key));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  private:
	CHKPTR(PtrArray) myFromPtrs;
	CHKPTR(PtrArray) myToPtrs;
	Int4 myTally;
/* Friends for class PrimPtr2PtrTable */
/* friends for class PrimPtr2PtrTable */
friend SPTR(PrimPtr2PtrTable)  primPtr2PtrTable (Int4 size);


};  /* end class PrimPtr2PtrTable */



/* ************************************************************************ *
 * 
 *                    Class PrimPtr2PtrTableStepper 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class PrimPtr2PtrTableStepper : public Stepper {

/* Attributes for class PrimPtr2PtrTableStepper */
	CONCRETE(PrimPtr2PtrTableStepper)
	AUTO_GC(PrimPtr2PtrTableStepper)
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
  public: /* accessing */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual RPTR(Heaper) heaperKey ();
	
	
	virtual void step ();
	
  protected: /* protected: create */

	
	PrimPtr2PtrTableStepper (
			APTR(PtrArray) ARG(from), 
			APTR(PtrArray) ARG(to), 
			Int32 ARG(index))
	;
	
  private:
	CHKPTR(PtrArray) myFromPtrs;
	CHKPTR(PtrArray) myToPtrs;
	Int4 myIndex;
/* Friends for class PrimPtr2PtrTableStepper */
/* friends for class PrimPtr2PtrTableStepper */
friend class PrimPtr2PtrTable;


};  /* end class PrimPtr2PtrTableStepper */



/* ************************************************************************ *
 * 
 *                    Class PrimPtrTable 
 *
 * ************************************************************************ */




	/* Map integers to strong or weak pointers */

class PrimPtrTable : public Heaper {

/* Attributes for class PrimPtrTable */
	CONCRETE(PrimPtrTable)
	AUTO_GC(PrimPtrTable)
  public: /* create */

	
	static RPTR(PrimPtrTable) make (Int32 ARG(size));
	
	
	static RPTR(PrimPtrTable) weak (Int32 ARG(size), APTR(XnExecutor) ARG(executor) = NULL);
	
  public: /* accessing */

	
	virtual void introduce (IntegerVar ARG(index), APTR(Heaper) ARG(ptr));
	
	
	virtual void store (IntegerVar ARG(index), APTR(Heaper) ARG(ptr));
	
	/* Clear all entries from the table. I know this looks like a 
	hack, but the 
		alternative is to throw away the table and build a new one: 
	an expensive 
		prospect for comm. */
	
	virtual void clearAll ();
	
	
	INLINE Int32 count ();
	
	
	virtual RPTR(Heaper) OR(NULL) fetch (IntegerVar ARG(index));
	
	
	virtual RPTR(Heaper) get (IntegerVar ARG(index));
	
	
	virtual void remove (IntegerVar ARG(index));
	
	
	virtual void wipe (IntegerVar ARG(index));
	
  protected: /* protected: destruct */

	
	virtual void destruct ();
	
  private: /* private: */

	
	virtual void grow ();
	
	
	virtual Int32 hashFind (IntegerVar ARG(value));
	
  protected: /* protected: create */

	
	PrimPtrTable (Int32 ARG(size), TCSJ);
	
	
	PrimPtrTable (Int32 ARG(size), APTR(XnExecutor) OR(NULL) ARG(executor));
	
  public: /* enumerating */

	
	virtual RPTR(PrimPtrTableStepper) stepper ();
	
  private: /* private: weakness */

	/* By way of a weird kluge, this passes the index that the 
	item was stored at in this table
		to the follow up executor */
	
	virtual void weakRemove (Int32 ARG(index), APTR(XnExecutor) OR(NULL) ARG(follower));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  private:
	CHKPTR(PtrArray) myPtrs;
	CHKPTR(IntegerVarArray) myIndices;
	Int4 myTally;
	CHKPTR(XnExecutor) OR(NULL) myExecutor;
/* Friends for class PrimPtrTable */
/* friends for class PrimPtrTable */
friend class PrimPtrTableExecutor;


};  /* end class PrimPtrTable */



/* ************************************************************************ *
 * 
 *                    Class PrimPtrTableStepper 
 *
 * ************************************************************************ */




	/* Stepper over map from integers to strong or wimpy pointers */

class PrimPtrTableStepper : public Stepper {

/* Attributes for class PrimPtrTableStepper */
	CONCRETE(PrimPtrTableStepper)
	AUTO_GC(PrimPtrTableStepper)
  protected: /* protected: create */

	
	PrimPtrTableStepper (
			APTR(IntegerVarArray) ARG(from), 
			APTR(PtrArray) ARG(to), 
			Int32 ARG(index))
	;
	
  public: /* accessing */

	
	virtual WPTR(Heaper) fetch ();
	
	
	virtual BooleanVar hasValue ();
	
	
	virtual IntegerVar index ();
	
	
	virtual void step ();
	
  public: /* create */

	
	virtual RPTR(Stepper) copy ();
	
  private:
	CHKPTR(PtrArray) myPtrs;
	CHKPTR(IntegerVarArray) myIndices;
	Int4 myIndex;
/* Friends for class PrimPtrTableStepper */
/* friends for class PrimPtrTableStepper */
friend class PrimPtrTable;


};  /* end class PrimPtrTableStepper */



/* ************************************************************************ *
 * 
 *                    Class PrimSet 
 *
 * ************************************************************************ */




	/* A set of pointers.  May be strong or weak.  If we have a 
	separate executor, it is called with the remaining size after 
	removal. */

class PrimSet : public Heaper {

/* Attributes for class PrimSet */
	CONCRETE(PrimSet)
	AUTO_GC(PrimSet)
  public: /* create */

	
	static RPTR(PrimSet) make ();
	
	
	static RPTR(PrimSet) make (Int32 ARG(size));
	
	
	static RPTR(PrimSet) weak ();
	
	
	static RPTR(PrimSet) weak (Int32 ARG(size));
	
	
	static RPTR(PrimSet) weak (Int32 ARG(size), APTR(XnExecutor) ARG(exec));
	
  public: /* enumerating */

	
	virtual RPTR(Stepper) stepper ();
	
  public: /* adding-removing */

	
	virtual void introduce (APTR(Heaper) ARG(value));
	
	
	virtual void remove (APTR(Heaper) ARG(value));
	
	
	virtual void store (APTR(Heaper) ARG(value));
	
	
	virtual void wipe (APTR(Heaper) ARG(value));
	
	
	virtual void wipeAll ();
	
  public: /* accessing */

	
	INLINE Int32 count ();
	
	
	virtual BooleanVar hasMember (APTR(Heaper) ARG(element));
	
	
	virtual BooleanVar isEmpty ();
	
  private: /* private: */

	
	virtual void grow ();
	
	
	virtual Int32 hashFind (APTR(Heaper) ARG(value));
	
  protected: /* protected: create */

	
	PrimSet (Int32 ARG(size), APTR(XnExecutor) ARG(exec));
	
	
	PrimSet (Int32 ARG(size), BooleanVar ARG(weakness));
	
  private: /* private: weakness */

	
	virtual void weakRemove (Int32 ARG(index));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  private:
	CHKPTR(PtrArray) myPtrs;
	Int4 myTally;
	BooleanVar myWeakness;
	CHKPTR(XnExecutor) OR(NULL) myExecutor;
/* Friends for class PrimSet */
/* friends for class PrimSet */
friend class PrimSetExecutor;


};  /* end class PrimSet */


#ifdef USE_INLINE
#ifndef PRIMTABX_IXX
#include "primtabx.ixx"
#endif /* PRIMTABX_IXX */


#endif /* USE_INLINE */


#endif /* PRIMTABX_HXX */

