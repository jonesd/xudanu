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

#ifndef PACKERP_HXX
#define PACKERP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PACKERX_HXX
#include "packerx.hxx"
#endif /* PACKERX_HXX */

#ifndef PACKERP_OXX
#include "packerp.oxx"
#endif /* PACKERP_OXX */


#ifndef NSCOTTYX_HXX
#include "nscottyx.hxx"
#endif /* NSCOTTYX_HXX */

#ifndef SCHUNKX_HXX
#include "schunkx.hxx"
#endif /* SCHUNKX_HXX */

#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */

#ifndef THUNKX_HXX
#include "thunkx.hxx"
#endif /* THUNKX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */


#ifndef CACHEX_OXX
#include "cachex.oxx"
#endif /* CACHEX_OXX */

#ifndef COOKBKX_OXX
#include "cookbkx.oxx"
#endif /* COOKBKX_OXX */

#ifndef FLKINFOX_OXX
#include "flkinfox.oxx"
#endif /* FLKINFOX_OXX */

#ifndef INTEGERX_OXX
#include "integerx.oxx"
#endif /* INTEGERX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef PRIMTABX_OXX
#include "primtabx.oxx"
#endif /* PRIMTABX_OXX */

#ifndef SNFINFOX_OXX
#include "snfinfox.oxx"
#endif /* SNFINFOX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class CountStream 
 *
 * ************************************************************************ */



/* Initializers for CountStream */







	/* NO CLASS COMMENT */

class CountStream : public XnWriteStream {

/* Attributes for class CountStream */
	CONCRETE(CountStream)
	EQ(CountStream)
	NOT_A_TYPE(CountStream)
	NO_GC(CountStream)

/* Initializers for CountStream */



friend class INIT_TIME_NAME(CountStream,initTimeNonInherited);

  public: /* creation */

	
	static RPTR(XnWriteStream) make ();
	
  public: /* create */

	
	CountStream ();
	
	
	virtual void destroy ();
	
  public: /* accessing */

	/* Must be a no-op since Xmtrs flush when done. */
	
	virtual void flush ();
	
	
	virtual void putByte (UInt32 ARG(byte));
	
	
	virtual void putData (APTR(UInt8Array) ARG(array));
	
	
	virtual void putStr (char * ARG(string));
	
	
	virtual Int32 size ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	Int32 mySize;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(InstanceCache) SomeStreams;
};  /* end class CountStream */



/* ************************************************************************ *
 * 
 *                    Class DiskCountSpecialist 
 *
 * ************************************************************************ */



/* Initializers for DiskCountSpecialist */







	/* NO CLASS COMMENT */

class DiskCountSpecialist : public TransferSpecialist {

/* Attributes for class DiskCountSpecialist */
	CONCRETE(DiskCountSpecialist)
	NOT_A_TYPE(DiskCountSpecialist)
	NO_GC(DiskCountSpecialist)

/* Initializers for DiskCountSpecialist */



friend class INIT_TIME_NAME(DiskCountSpecialist,initTimeNonInherited);

  public: /* creation */

	
	static RPTR(TransferSpecialist) make (APTR(Cookbook) ARG(aBook));
	
  public: /* creation */

	
	DiskCountSpecialist (APTR(Cookbook) ARG(cookbook), TCSJ);
	
	
	virtual void destroy ();
	
  public: /* communication */

	/* DiskCountSpecialist are only for sending. */
	
	virtual RPTR(Heaper) receiveHeaperFrom (APTR(Category) ARG(cat), APTR(SpecialistRcvr) ARG(rcvr));
	
	/* DiskCountSpecialist are only for sending. */
	
	virtual void receiveHeaperIntoFrom (
			APTR(Category) ARG(cat), 
			APTR(Heaper) ARG(memory), 
			APTR(SpecialistRcvr) ARG(rcvr))
	;
	
	/* Handle sending Shepherds specially. */
	
	virtual void sendHeaperTo (APTR(Heaper) ARG(hpr), APTR(SpecialistXmtr) ARG(xmtr));
	
  private:
	BooleanVar myInsideShepherd;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static Int32 MaxFlocks;
	static Int32 MaxSnarfs;
	static GPTR(InstanceCache) SomeSpecialists;
	friend class TransferSpecialist;
};  /* end class DiskCountSpecialist */



/* ************************************************************************ *
 * 
 *                    Class DiskIniter 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class DiskIniter : public Thunk {

/* Attributes for class DiskIniter */
	CONCRETE(DiskIniter)
	COPY(DiskIniter,BootCuisine)
	NOT_A_TYPE(DiskIniter)
	AUTO_GC(DiskIniter)
  public: /* running */

	
	virtual void execute ();
	

	/* automatic 0-argument constructor */
  public:
	DiskIniter();
  private:
	CHKPTR(Category) myCategory;
	char * myFilename;
	NOCOPY Int32 mySnarfSize;
	NOCOPY Int32 mySnarfCount;
	NOCOPY Int32 myStageCount;
};  /* end class DiskIniter */



/* ************************************************************************ *
 * 
 *                    Class DiskSpecialist 
 *
 * ************************************************************************ */



/* Initializers for DiskSpecialist */







	/* NO CLASS COMMENT */

class DiskSpecialist : public TransferSpecialist {

/* Attributes for class DiskSpecialist */
	CONCRETE(DiskSpecialist)
	NOT_A_TYPE(DiskSpecialist)
	AUTO_GC(DiskSpecialist)

/* Initializers for DiskSpecialist */



friend class INIT_TIME_NAME(DiskSpecialist,initTimeNonInherited);

  public: /* stream creation */

	
	static RPTR(TransferSpecialist) make (APTR(Cookbook) ARG(book), APTR(DiskManager) ARG(packer));
	
  public: /* communication */

	/* There's a lot of smalltalk only stuff in here.  Smalltalk 
	stubs should move towards c++ stubs. */
	
	virtual RPTR(Heaper) receiveHeaperFrom (APTR(Category) ARG(cat), APTR(SpecialistRcvr) ARG(rcvr));
	
	/* Return an object from the rcvr or NULL if cat is not a 
	category that we 
		handle specially. */
	
	virtual void receiveHeaperIntoFrom (
			APTR(Category) ARG(cat), 
			APTR(Heaper) ARG(memory), 
			APTR(SpecialistRcvr) ARG(rcvr))
	;
	
	/* Handle sending Shepherds specially. */
	
	virtual void sendHeaperTo (APTR(Heaper) ARG(hpr), APTR(SpecialistXmtr) ARG(xmtr));
	
  public: /* create */

	
	DiskSpecialist (APTR(Cookbook) ARG(cookbook), APTR(DiskManager) ARG(packer));
	
	
	virtual void destroy ();
	
  private:
	CHKPTR(DiskManager) myPacker;
	BooleanVar myInsideShepherd;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(InstanceCache) SomeSpecialists;
};  /* end class DiskSpecialist */



/* ************************************************************************ *
 * 
 *                    Class PersistentCleaner 
 *
 * ************************************************************************ */



/* Initializers for PersistentCleaner */




	/* This does a makePersistent when ServerChunks go away */

class PersistentCleaner : public ChunkCleaner {

/* Attributes for class PersistentCleaner */
	CONCRETE(PersistentCleaner)
	NO_GC(PersistentCleaner)

/* Initializers for PersistentCleaner */


  public: /* create */

	
	static RPTR(PersistentCleaner) make ();
	
  public: /* invoking */

	
	virtual void cleanup ();
	
  protected: /* protected: create */

	
	PersistentCleaner ();
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(PersistentCleaner) ThePersistentCleaner;
};  /* end class PersistentCleaner */



/* ************************************************************************ *
 * 
 *                    Class Pumpkin 
 *
 * ************************************************************************ */



/* Initializers for Pumpkin */




	/* NO CLASS COMMENT */

class Pumpkin : public Abraham {

/* Attributes for class Pumpkin */
	CONCRETE(Pumpkin)
	LOCKED(Pumpkin)
	COPY(Pumpkin,DiskCuisine)
	EQ(Pumpkin)
	NO_GC(Pumpkin)

/* Initializers for Pumpkin */


  public: /* pcreate */

	/* Just return the soleInstance. */
	
	static WPTR(Abraham) make ();
	
  protected: /* protected: protected */

	/* This can only be implemented by classes which are shepherds. */
	/* Each subclass will have expressions of the form: 'new 
	(this) MyStubClass()' */
	
	virtual void becomeStub ();
	
  public: /* creation */

	
	Pumpkin (UInt32 ARG(hash), TCSJ);
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(Abraham) TheGreatPumpkin;
};  /* end class Pumpkin */



/* ************************************************************************ *
 * 
 *                    Class SnarfRecord 
 *
 * ************************************************************************ */




	/* Manage retrieval, refitting, and rewriting of existing 
	flocks.  Assign indices for new flocks.  
	
	SnarfRecords can go away after their contents have been 
	flushed.  We might keep it around if we expect to be 
	assigning new flocks to the snarf again, just to keep 
	myOccupied.  The snarfRecord will be recreated when another 
	object is read in. */

class SnarfRecord : public Heaper {

/* Attributes for class SnarfRecord */
	CONCRETE(SnarfRecord)
	EQ(SnarfRecord)
	AUTO_GC(SnarfRecord)
  public: /* pcreate */

	
	static RPTR(SnarfRecord) make (
			Int32 ARG(snarfID), 
			APTR(SnarfPacker) ARG(packer), 
			Int32 ARG(spaceLeft))
	;
	
  public: /* writing */

	/* Shep is being newly added to this snarf.  Allocate enough 
	space for it and return the newly assigned index for it. */
	/* The spaceLeft that we compute includes the size of the 
	cells, otherwise we couldn't keep the number up to date. */
	
	virtual Int32 allocate (Int32 ARG(size), APTR(Abraham) ARG(shep));
	
	/* Remember that the flock at index must be written to the 
	snarf on the next update. */
	
	virtual void changedFlock (Int32 ARG(index), APTR(Abraham) ARG(shep));
	
	/* Remove the flock from the disk.  Replace it with a Pumpkin 
	so that the 
		 routine that flushes to disk knows to remove whatever's 
	there already. */
	/* Remove the flocks space allocation now so that we can 
	reallocate from the newly created pool. */
	
	virtual void dismantleFlock (APTR(FlockInfo) ARG(info));
	
  public: /* transactions */

	/* Rewrite all flocks that have changed in this snarf. */
	
	virtual void flushChanges ();
	
	/* Recompute size information for all changed shepherds and 
	see if they still fit.
		 Any that don't get handed to the SnarfPacker to treat as 
	new flocks.   The 
		 old space changed and dismantled flocks has been returned 
	to the pool.  
		 Reallocate space for the changed flocks out of the pool.  
	Any that don't fit 
		 are handed back to myPacker to go in other snarfs. */
	
	virtual void refitFlocks ();
	
	/* Return the amount of space currently left in the snarf. */
	
	virtual Int32 spaceLeft ();
	
  protected: /* protected: destruct */

	/* Destroy all objects imaged from this snarf. */
	
	virtual void destruct ();
	
  private: /* private: private */

	/* Return the first unoccupied index in the snarf.  Compute the lowest
		 element >= 0 that is not already in the occupied region by 
	subtracting 
		 the occupied region from the region >= 0. */
	
	virtual IntegerVar allocateIndex ();
	
	/* Get the handler for my snarf so that I can send or receive 
	data from it. */
	
	virtual RPTR(SnarfHandler) getWriteHandler ();
	
	/* Create an array with the sizes of every flock in the snarf. */
	
	virtual void readOccupied ();
	
	
	virtual void setSpaceLeft (Int32 ARG(spaceLeft));
	
	
	virtual IntegerVar wipeBelowHighest (Int32 ARG(highest), APTR(SnarfHandler) ARG(handler));
	
  public: /* create */

	
	SnarfRecord (
			Int32 ARG(snarfID), 
			APTR(SnarfPacker) ARG(packer), 
			Int32 ARG(spaceLeft))
	;
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	Int32 mySnarfID;
	CHKPTR(SnarfPacker) myPacker;
	Int32 mySpaceLeft;
	CHKPTR(IntegerRegion) OR(NULL) myOccupied;
	CHKPTR(PrimPtrTable) OF1(Abraham) myChangedFlocks;
	Int32 myDestroyCount;
};  /* end class SnarfRecord */



/* ************************************************************************ *
 * 
 *                    Class SpareStageSpace 
 *
 * ************************************************************************ */



/* Initializers for SpareStageSpace */




	/* NO CLASS COMMENT */

class SpareStageSpace : public Thunk {

/* Attributes for class SpareStageSpace */
	CONCRETE(SpareStageSpace)
	COPY(SpareStageSpace,BootCuisine)
	NO_GC(SpareStageSpace)

/* Initializers for SpareStageSpace */


  public: /* accessing */

	
	static Int32 cruftedSnarfsGuess ();
	
	
	static Int32 flocksPerSnarfGuess ();
	
  public: /* execute */

	
	virtual void execute ();
	

	/* automatic 0-argument constructor */
  public:
	SpareStageSpace();
  private:
	Int32 myCruftedSnarfCount;
	Int32 myFlocksPerSnarf;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static Int32 CruftedSnarfCount;
	static Int32 FlocksPerSnarf;
};  /* end class SpareStageSpace */



#endif /* PACKERP_HXX */

