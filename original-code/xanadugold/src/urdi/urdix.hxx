/* ========================================================================== */
//
//	Copyright (c) 1989 by Xanadu Operating Company, All Rights Reserved.
//
/* ========================================================================== */
//
// The information contained herein is confidential, proprietary to Xanadu
// Operating Company, and considered a trade secret as defined in section
// 499C of the penal code of the State of California.
//
// Use of this information by anyone other than authorized employees of
// Xanadu is granted only under a written nondisclosure agreement,
// expressly prescribing the scope and manner of such use.
//
// The above copyright notice is not to be construed as evidence of
// publication or the intent to publish.
//
/* ========================================================================== */
//
//			urdix.hxx
//
//		Header file for URDI routines.
//
//		By Michael McClary	1989
//
/* ========================================================================== */
//
//	Changed all classes to be "Heapers", not "Objects"
//
//	Replaced constructor macros with member functions in related classes:
//
//	 - ReadView(URDI)               =>	URDI->makeReadView()
//	 - WriteView(URDI)              =>	URDI->makeWriteView()
//	 - HandleOnReadSnarf(VIEW, ID)  =>	VIEW->makeReadHandle(ID)
//	 - HandleOnBlankSnarf(VIEW, ID) =>	VIEW->makeErasingHandle(ID)
//
//	Published SnarfHandle::thaw();
//
//		- michael Nov 28-30 1990
//
//	Changed View to UrdiView in type declarations (but not diagnostic
//	output) to merge with dean's code.
//		- michael Dec  4 1990
//
//	Added SnarfHandle::getSnarfID();
//	Added SnarfHandle::atPut4();
//	Added SnarfHandle::get4();
//	Added SnarfHandle::moveBytes();
//		- michael Jan 28 1991
//
//	Added Urdi::getDataSizeOfSnarf();
//	Added UrdiView::getDataSizeOfSnarf();
//		- michael Feb  7 1991
//
//	Merging with dean:
//	 - Added .oxx file
//	 - Changed SnarfID type from IntegerVar to Int32
//	 - Changed getDataP to return UInt8*, not char*
//	 - Added a pseudo-constructor for initializing the partition.
//	   !!!! TAKE IT OUT LATER !!!!
//	 - Re-added isWritable(), which had gotten lost.
//		- michael May  7 1991
//
//	Added pseudo-constructors for re-openning existing partition and for
//	initializing blank partition.
//		- ech May 28 1991 (imported - michael Jun  4 1991)
//
//	Upgrading for LRU:
//	 - fixed memory leak of dummy handles in ~UrdiView()
//		- michael Aug 4-7 1991
//	 - Added LRU cache to Urdi object.  New vars and routines:
//	    - Urdi::lRUMax
//	    - Urdi::lRUCurrent
//	    - Urdi::snarfCacheLRURoot
//	    - Urdi::snarfCacheDummyP
//	    - aLRUMax argument added to urdi constructors and pseudocons.
//	    - SnarfCache::addToLRU()
//	    - SnarfCache::unlinkLRU()
//	    - Urdi::extractFromLRU()
//		- michael Aug 7-16 1991
//
//	Added counts of LRU hits/misses and accessor functions.  (No provision
//	for clearing or faking the counts.)
//		- michael Aug 23 1991
//
//	Changed interface to match new types and translations:
//	  - atPut4  --> put32
//	  - get4    --> get32
//		- ech Apr 24, 1992

#ifndef	URDI_HXX
#define	URDI_HXX

#include "bombx.hxx"
#include "tofux.hxx"
#include "intvarx.hxx"

#include "urdix.oxx"

typedef	Int32	SnarfID;

enum 	ViewType	{ WRITE_VIEW=0, READ_VIEW=1, DUMMY_VIEW=2,
				VIEW_CONSTRUCTOR_FAILED=3 };
enum 	SnarfHandleType	{ WRITE_HANDLE=0, READ_HANDLE=1, DUMMY_HANDLE=2,
				SNARF_HANDLE_CONSTRUCTOR_FAILED=3 };
enum 	SnarfCacheType	{ DUMMY_CACHE=0, GOAT_CACHE=1, DATA_CACHE=2 };
/* ========================================================================== */
//
//	Urdi object:  One per virtual disk.
//
/* ========================================================================== */

CLASS(Urdi,Heaper) {
	CONCRETE(Urdi)
	MANUAL_GC(Urdi)
	NOT_A_TYPE(Urdi)
    public:
	virtual void destruct ();				// Destructor:  Close & eject.

//	Urdi(
//		  Tuple *	deviceList
//		, Tuple *	partitionSizeList
//		, IntegerVar	stagingAreaSize
//	);

//	Urdi(
//		  Tuple *	deviceList
//		, TCSJ		tcsj
//	);

	Urdi(
		    const char * argPathName	// (Constructor for creating test
		  , long	argSnarfSize	//  file to simulate partition.)
		  , long	argSnarfCount
		  , long	argStagingAreaSize
		  , long	aLRUMax
	);

	Urdi(
		    const char * argPathName	// (Constructor for initting
		  , long	argSnarfSize	//  empty partition.)
		  , long	argStagingAreaSize
		  , long	aLRUMax
	);

	Urdi(
		    const char * argPathName	// (Constructor to re-open
		  , long	aLRUMax		//  existing partition or file.)
	);

	virtual	void		printOn(ostream& oo);

	virtual	long		usableSnarfs();
	virtual	long		usableStages();

	virtual long		getDataSizeOfSnarf(SnarfID argSnarfID);

	virtual	UrdiView *	makeReadView();
	virtual	UrdiView *	makeWriteView();

	virtual	long		lRUHits();
	virtual	long		lRUMisses();

    private:
	friend class		UrdiView;
	friend class		SnarfCache;
	friend class		SnarfHandle;

	virtual BooleanVar	writingSnarf(SnarfID argSnarfID);

	virtual	void		mightWriteSomeSnarfs();
	virtual	void		mightCleanSomeSnarfs();

	virtual SnarfCache *	extractFromLRU(SnarfID);

	virtual	void		abort();
	virtual	SnarfCache *	commit();

	int			fd;

	long			version;
	long			snarfSize;
	long			snarfCount;
	long			stagingAreaSize;	// (in snarfs)

	long			lRUMax;	//
	long			lRUCurrent;		// =0
	long			myLRUHits;		// =0
	long			myLRUMisses;		// =0

	UInt32			cycleNumber;		// =1 update cycle
	int			writableSnarfs;	// =0; since commit/abort
	long			latestStagingSlot;	// =0; Latest written to

	UrdiView *		viewRoot;		// = dummy view object;
	UrdiView *		viewDummyP;		// = dummy view object;
	UrdiView *		writeViewP;		// = NULL;
	SnarfCache *		snarfCacheRoot;		// = goat cache object;
	SnarfCache *		latestCommittedP;	// = goat cache object;
	SnarfCache *		latestSafeOnStageP;	// = goat cache object;
	SnarfCache *		latestSafeOnDiskP;	// = goat cache object;
	SnarfCache *		snarfCacheGoatP;	// = goat cache object;
	SnarfCache *		snarfCacheDummyP;	// = dummy cache object;
	SnarfCache *		snarfCacheLRURoot;	// = dummy cache #2;
	SnarfCache *		snarfCacheLRUDummyP;	// = dummy cache #2;

};

Urdi *
urdi(
    const char * argPathName	// (Pseudo-constructor for creating test
  , long	argSnarfSize	//  file to simulate partition.)
  , long	argSnarfCount
  , long	argStagingAreaSize
  , long	aLRUMax
);

Urdi *
urdi(
    const char * argPathName	// (Pseudo-constructor for initting
  , long	argSnarfSize	//  empty partition.)
  , long	argStagingAreaSize
  , long	aLRUMax
);

Urdi *
urdi(
    const char * argPathName	// (Pseudo-constructor to re-open
  , long	aLRUMax		//  existing partition or file.)
);
/* ========================================================================== */
//
//	SnarfCache object:  One slot in the snarf cache.
//
/* ========================================================================== */

CLASS(SnarfCache,Heaper) {
	CONCRETE(SnarfCache)
	MANUAL_GC(SnarfCache)
	NOT_A_TYPE(SnarfCache)
    public:
	// Only friends know about the snarf cache.
    private:

	virtual void destruct ();
	SnarfCache(SnarfCacheType argSnarfCacheType, Urdi * argUrdi);

	virtual	void		printOn(ostream& oo);

	virtual	void		linkBefore(SnarfCache * successor);
	virtual	void		addToLRU();
	virtual	SnarfCache *	unlinkReturnSuccessorP();
	virtual	void		unlinkLRU();
	virtual BooleanVar	isDummy();

	virtual void		lockStartGrabbed();
	virtual void		lockEndGrabbed();
	virtual void		lockStartDropped();
	virtual void		lockEndDropped();

	virtual long		getDataSize();
	virtual long		getBlank(SnarfID);
	virtual long		getCloset(SnarfID);
	virtual void		getStage(long);
	virtual void		copy(SnarfCache *);

	virtual void		markGroupEnd();
	virtual BooleanVar	isGroupEnd();
	virtual void		updateHeader(UInt32, BooleanVar);

	virtual void		putStage(long);
	virtual void		putCloset();
	virtual void		grabbing();
	virtual void		dropping();
	virtual char *		freezing();
	virtual void		thawing();

	Urdi *		urdiP;			// = argUrdiP;
	SnarfCache *	nextSnarfCacheP;	// = NULL;
	SnarfCache *	previousSnarfCacheP;	// = NULL;
	SnarfCacheType	snarfCacheType;		// = {DUMMY/GOAT/DATA}_CACHE

	long		snarfSize;		// = SNARFDATASIZE; (dummy: 0)
	char *		snarfP;		// = new([SNARFDATASIZE]); (dummy: NULL)
	SnarfID		snarfID;		// = -3; (goat: -2, dummy: -1)
	BooleanVar	isDirty;		// = FALSE;
	BooleanVar	groupEnd;		// = FALSE;

	int		handlesOnMe;		// = 0; (dummy, goat lie >0)
	int		frozenHandlesOnMe;	// = 0;
	int		lockStartsOnMe;		// = 0; (dummy lies >0)
	int		lockEndsOnMe;		// = 0; (dummy lies >0)

	friend class	Urdi;
	friend class	UrdiView;
	friend class	SnarfHandle;
	friend class	SnarfCache_Bomb;
};
/* ========================================================================== */
//
// UrdiView:  Object representing a static view of a virtual disk.
//
// (First product:  Only one write view at a time.  Update is single-thread.)
//
/* ========================================================================== */

CLASS(UrdiView,Heaper) {
	CONCRETE(UrdiView)
	MANUAL_GC(UrdiView)
	NOT_A_TYPE(UrdiView)
    public:
	virtual void destruct ();
    private:
	UrdiView(Urdi* argUrdiP, ViewType argViewType);	// Called by Urdi

    public:
	virtual	void		printOn(ostream& oo);

	virtual void		thawHandles();

	virtual BooleanVar	isWriteView();

	virtual void		abortWrite();		// Write only
	virtual void		commitWrite();		// Write only
	virtual void		becomeRead();		// Write only

	virtual long		getDataSizeOfSnarf(SnarfID argSnarfID);

	virtual SnarfHandle *	makeReadHandle(SnarfID);
	virtual SnarfHandle *	makeErasingHandle(SnarfID);

    private:
	virtual SnarfCache *	findInCache(SnarfID);

	Urdi *			urdiP;			// = argUrdi
	UrdiView *		nextViewP;		// -> next view
	UrdiView *		previousViewP;		// = NULL;
	ViewType		viewType;			

	SnarfCache *		lockStartP;		// = urdiP->latestCommittedP
	SnarfCache *		lockEndP;		// = urdiP->latestSafeOnDiskP

	SnarfHandle *		snarfHandleRoot;	// = dummy handle object;
	SnarfHandle *		snarfHandleDummyP;	// = dummy handle object;
	SnarfHandle *		frozenSnarfHandleRoot;	// = NULL;

	friend class		SnarfHandle;
	friend class		Urdi;
};
/* ========================================================================== */
//
//	SnarfHandle object:  All access to a snarf goes through this.
//
//	("handle" comes from an Apple-ism for a double-indirect pointer.
//	 Using handles allows the system to move things around if necessary,
//	 for instance:  paging out a snarf when things get tight.
//	 SnarfHandles are objects which perform the analogous function.)
//
//	The SnarfHandle class makes the snarfs visible to clients.
//	The member functions do all urdi-specific operations to
//	the snarf, and the class provides a pointer to the snarf's
//	data area, and the area's size.
//
//	NOTE the folliowing behavior of snarf handles:
//	 - Snarfs held by read handles appear unchanging.
//	 - In a read view, grabbing a new handle gives you the version of
//	   the snarf as of the time you created the view.
//	 - In a write view, grabbing a new handle gives you the version of
//	   the snarf as of the most recent commit().
//	 - If you hold both a write and a read handle on the same snarf,
//	   you hold two copies of the same snarf.  Changes to the writeable
//	   snarf will not appear in the readable copy.
//	 - Thus, in a WRITE view, you can end up holding handles on several
//	   versions of the same snarf.
//
/* ========================================================================== */

CLASS(SnarfHandle,Heaper) {
	CONCRETE(SnarfHandle)
	MANUAL_GC(SnarfHandle)
	NOT_A_TYPE(SnarfHandle)
    public:
	virtual void destruct ();
    private:
	SnarfHandle(
		  UrdiView *		argViewP
		, SnarfID		argSnarfID
		, SnarfHandleType	argSnarfHandleType
	);					// Called by UrdiView

    public:
	virtual	void		printOn(ostream& oo);

////	virtual SnarfHandle *	cloneReadHandle();
	virtual void		makeWritable();
	virtual BooleanVar	isWritable();

	virtual UInt8 *		getDataP();
	virtual long		getDataSize();
	virtual SnarfID		getSnarfID();
	virtual void		thaw();

	virtual void		put32(UInt32 anIndex, UInt32 aWord);
	virtual UInt32		get32(UInt32 anIndex);
	virtual void		moveBytes(UInt32 aFrom, UInt32 aTo, UInt32 aCount);
    private:

	UrdiView *		viewP;			// = argViewP
	SnarfHandle *		nextSnarfHandleP;	// -> next handle
	SnarfHandle *		previousSnarfHandleP;	// = NULL;
	SnarfHandle *		nextFrozenSnarfHandleP;	// = NULL;
	SnarfHandle *		previousFrozenSnarfHandleP; // = NULL;
	SnarfCache *		snarfCacheP;		// = argSnarfCacheP
	SnarfHandleType		snarfHandleType;	// = argSnarfHandleType

	SnarfID			snarfID;
	BooleanVar		isFrozen;	// = FALSE
	long			dataSize;
	char *			dataP;		// Valid only when handle frozen


	friend class		Urdi;
	friend class		SnarfCache;
	friend class		UrdiView;
};

#endif	/* URDI_HXX */
