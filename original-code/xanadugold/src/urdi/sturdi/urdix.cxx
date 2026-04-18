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
//				urdix.cxx
//
//		Unusually Reliable Disk Interface routines.
//
//			By Michael McClary	1989
//
/* ========================================================================== */
//
//	Notes:
//	 - Can't ever change group of more then "stagingAreaSize - 1" snarfs.
//		!!!! needs to be sanity-checked.
//	 - Snarf handles are "born frozen".
//
//	Bogosities:
//	 - Assumes char === byte, etc.
//
//	Potential improvements:
//	 - Batching of writes to closet.
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
//	Published SnarfHandle::thaw()
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
//	Removed CONSTRUCTOR_BOMBs.  (They were obsolete once the urdi
//	classes became Heapers.)
//		- michael Feb  3 1991
//
//	Added Urdi::getDataSizeOfSnarf();
//	Added UrdiView::getDataSizeOfSnarf();
//		- michael Feb  7 1991
//
//	Mergind with dean
//	 - Changed SnarfID type from IntegerVar to Int32
//	    (Should change various routines that return longs...!!!!)
//	 - Changed getDataP to return UInt8*, not char*
//	 - Added a pseudo-constructor for initializing partition.
//	   !!!! TAKE IT OUT LATER !!!!
//	 - Re-added isWritable(), which had gotten lost.
//		- michael May  7 1991
//
//	Added pseudo-constructors for re-openning existing partition and for
//	initializing blank partition.
//		- ech May 28 1991 (imported - michael Jun  4 1991)
//
//	- Moved canPtr() cannonical pointer printing routine from urdip.hxx
//	  to urdix.cxx
//	- Changed canPtr for one-based numbering (so there will be no more
//	  fuss when initial allocs change.)
//		- michael Jun  4 1991
//
//	- Changed problem on  (uninitialized or) shuffled snarf (for clarity).
//	- Reordered BOMB planting to match new construction-order semantics.
//		- michael Jun -26 1991
//
//	Upgrading for LRU:
//	 - fixed memory leak of dummy handles in ~UrdiView().  (Also
//	   added initializers for member vars of dummy UrdiView in ctor.)
//		- michael Aug  4-7 1991
//	 - Added LRU cache to Urdi object.  New vars and routines:
//	    - Urdi::lRUMax
//	    - Urdi::lRUCurrent
//	    - Urdi::snarfCacheLRURoot
//	    - Urdi::snarfCacheDummyP
//	    - aLRUMax argument added to urdi constructors and pseudocons.
//	    - SnarfCache::addToLRU()
//	    - SnarfCache::unlinkLRU()
//	    - Urdi::extractFromLRU()
//	 - Modifications:
//	    - Urdi ctors & dtor (to initialize/relelase LRU queue and count)
//	    - Urdi reopen constructor (flush LRU after crash repair)
//	    - Urdi::printOn() (to display new queues & vars)
//	    - Urdi::mightCleanSomeSnarfs() (to save unheld snarfs on LRU,
//		purging older versions)
//	    - SnarfCache::dropping() (to save unheld snarfs on LRU)
//	    - SnarfHandle ctor: (to extract snarfs from LRU)
//		- michael Aug -13 1991
//
//	Added counts of LRU hits/misses and accessor functions.  (No provision
//	for clearing or faking the counts.)
//		- michael Aug 23 1991
//
//	Changed partition locking to use flock() rather than lockf()  (Latter
//	got broken about SunOS 4.1.  Former only works locally rather than
//	over the net, but then so does partition I/O.
//		- michael Sep 14 1991
//
//	 - Cleaned up #elseif/#endif comments for ANSI
//		- michael Sep  6 1991 (Merged Sep 16)
//
//	Changing hash processing to do switchable between snefru and fastHash
//		- michael Sep 16 1991
//
//	Removed shield ordering so obsolete stuff can be retired.
//	No check for other correctness.  (Merge by replacing with other fork.)
//		- michael Feb 27 1992
//
//	Changed interface to match new types and translations:
//	  - atPut4  --> put32
//	  - get4    --> get32
//		- ech Apr 24, 1992
//
//	NOTE:	These classes are only "Heapers" by curteousy.  They do their
//		own memory management on the persistent heap, require explicit
//		destruction by the client, and are only tested to work when
//		that destruction is done using the "delete" c++ primitive.
//		The timing of the destruction of each of these classes is
//		part of its interface semantics.  Destruction amounts to a
//		message from the client that some major operation must be done.
//
//    Moved system includes after xanadu includes to pick up switches
//    from compat, so lock definitions will expand correctly.
//            - michael Apr 15 1992
//
//    Removed ifdefed out Snefru stuff.
//    Added URDI specific mechanism for acquiring snarfs
//
#include <sys/types.h>
#include <sys/stat.h>

#ifdef WIN32
#	include <stdlib.h>
#   include <io.h>
#   include <errno.h>
#	define open _open
#	define close _close
#	define lseek _lseek
#	define creat _creat
#	define read _read
#	define write _write
#else
#ifdef unix

#   ifdef __sgi
/* turns on the decl of flock(); */
#	    define _BSD_COMPAT
#   endif
#ifdef GNU
#   include <file.h>
#else
#   include <sys/file.h>
#endif
#else
#ifdef HIGHC
#	include <io.h>
#	include <fcntl.h>
#	include <stdlib.h>
#endif
#endif
#endif

#include "urdix.hxx"
#include "urdix.sxx"

#include "urdip.hxx"
#include "urdip.sxx"

#include <stream.h>	/* for tests. */
#ifdef unix
#	include <osfcn.h>
#	include <fcntl.h>
#	include <unistd.h>	/* Get lseek()'s SEEK_* (= L_*) from here, because no file.h! */
#endif
#include <errno.h>

#define BEFORE_FIRST_STAGING_SLOT	0

#define	DEBUGHACK	1024L

#define	MASK	0
#define	MODE	0600

#define	MIN_SNARFS	2

#define CLAIM_WITH_VAL(assertion,gripe,value)	\
	if (!(assertion)) {	\
		BLAST_WITH_VAL(gripe,value);	\
	}

int uwrite (int fd, char * buf, int nbyte) {
	return write (fd, buf, nbyte);
}

#ifdef HIGHC
// hack!!
#define ARGPATHNAME (char *) argPathName
#else
#define ARGPATHNAME argPathName
#endif
/*^L*//* ========================================================================== */
//
//	Urdi object:  One per virtual disk.
//
//	!!!! Constructors will change later, to take multiple devices,
//	     variable-length partitions..
//
/* ========================================================================== */

ORDER_BOMB      (urdiDelete,	char *);

BUILD_BOMB_BEGIN(urdiDelete,	char *)		{
	delete(CHARGE);
} BUILD_BOMB_END(urdiDelete);

ORDER_BOMB      (urdiClose,	int);

BUILD_BOMB_BEGIN(urdiClose,	int)		{
	close(CHARGE);
} BUILD_BOMB_END(urdiClose);

ORDER_BOMB      (urdiUnlink,	const char *);

BUILD_BOMB_BEGIN(urdiUnlink,	const char *)	{
	unlink(CHARGE);
} BUILD_BOMB_END(urdiUnlink);

/* ========================================================================== */
//
//	Constructor for initializing test file simulating partition.
//
/* ========================================================================== */

Urdi *
urdi(
    const char * argPathName
  , long	argSnarfSize
  , long	argSnarfCount
  , long	argStagingAreaSize
  , long	aLRUMax
) {
	RETURN_CONSTRUCT_ON(PERSISTENT,Urdi,(
	    argPathName
	  , argSnarfSize
	  , argSnarfCount
	  , argStagingAreaSize
	  , aLRUMax
	));
}

Urdi::
Urdi(
    const char * argPathName
  , long	argSnarfSize
  , long	argSnarfCount
  , long	argStagingAreaSize
  , long	aLRUMax
) {
	long			i;
	int			oldMask;
	int			rc;
	off_t			rcoff;
	int			localfd;
	char *			p;
	Int8			c;

	CLAIM_WITH_VAL(EXPECTED_SIZE_OF_GUARD_RECORD == sizeof(struct UrdiGuardRecord),
		SIZE_OF_GUARD_RECORD_WRONG,sizeof (struct UrdiGuardRecord));

	CLAIM_WITH_VAL(EXPECTED_SIZE_OF_SNARF_HEADER == sizeof(struct SnarfHeader),
		SIZE_OF_SNARF_HEADER_WRONG,sizeof (struct SnarfHeader));

	PLANT_BOMB(urdiUnlink, argPathName);	/* Note order: unlink last */
	PLANT_BOMB(urdiClose,  localfd);	/* Note order: after closing */
	PLANT_BOMB(urdiDelete, p);

	viewRoot = viewDummyP = NULL;	// In case constructor fails;
	snarfCacheRoot = NULL;		// In case constructor fails;
	fd = -1;			// In case constructor fails;

	if (argSnarfSize < sizeof(struct UrdiGuardRecord)) {
		BLAST(SNARFS_TOO_SMALL_FOR_GUARD_BLOCK);
	}

#ifdef unix
	oldMask = umask(MASK);		// Mutex with other lightweight tasks????
#endif
	// shap: The file may already exist. If so, the creat(2) will fail.  
	// If the creat fails, open(2) will return ENOENT.

	int didcreate = 0;

	// Try to create the repository, but not more than a few times:

	for(int attempt = 0; attempt < 5; attempt++) {
#ifdef unix
		localfd = open(ARGPATHNAME, O_RDWR | O_EXCL | O_SYNC);
#else
		localfd = open(ARGPATHNAME, O_RDWR | O_EXCL);
#endif

		// !!!! If we ever decide to run over NFS, do this by creating
		// the file with some hashed name and relink(2) it to target.
		// relink(2) is atomic over NFS, creat is not do to a protocol
		// bug.

		if (localfd < 0 && errno == ENOENT) {
			int creatfd;
			close(creatfd = creat(ARGPATHNAME, MODE));
			if (creatfd != -1) {
				didcreate = 1;
			}
			// loop again
		} else {
	/**/		break;
		}

	} ;

#ifdef unix
	umask(oldMask);
#endif

	// !!!! Someday we should fstatfs the open file descriptor to
	// verify that it is not an NFS mounted file. Stateless file
	// systems are the work of the Devil.

	if (localfd < 0) {
		BLAST(CANT_CREATE_OR_OPEN_URDI_FILE);
	}

	ARM_BOMB(argPathName,argPathName);
	ARM_BOMB(localfd,localfd);
#ifdef unix
	if (lockf(localfd, F_TLOCK, 0L) < 0) {
		BLAST(CANT_LOCK_URDI_FILE);
	}
#endif

	/*p = new char[argSnarfSize];*/
	p = (char *) falloc(argSnarfSize);  /*zzz reg to escape alloc stuff oct 27 1994 */
	ARM_BOMB(p,p);

	if(!didcreate) {
		rc = read(localfd, p, sizeof(struct UrdiGuardRecord));

		/*
		 * It is okay for the file to be short. In that case, we
		 * probably just created it. In any case, it ain't an
		 * URDI.
		 */
		if ((rc == sizeof(struct UrdiGuardRecord)) &&
		    ( ((UrdiGuardRecord *)p)->urdi_magic == URDI_MAGIC
		      || ((UrdiGuardRecord *)p)->urdi_magic == URDI_MAGIC_2143
		      || ((UrdiGuardRecord *)p)->urdi_magic == URDI_MAGIC_3412
		      || ((UrdiGuardRecord *)p)->urdi_magic == URDI_MAGIC_4321
		    )
		) {
			BLAST(PARTITION_ALREADY_HAS_URDI_FILE);
		}

	}

	for (i=0; i<argSnarfSize; i++) {
		p[i] = !(i&1) ? 0xDE : 0xAD;	/* Spray with "DEAD"	*/
	}

	for (i=0; i<argSnarfCount; i++) {
		rc = uwrite(localfd, p, (int)argSnarfSize);
		if (rc != argSnarfSize) {
			BLAST(NOT_ENOUGH_DISK_TO_CREATE_URDI_FILE);
		}
	}

	for (c=0; c<SHUFFLE_CHARS; c++) {
		((UrdiGuardRecord *)p)->shuffle[c]		= c;
	}
	((UrdiGuardRecord *)p)->urdi_magic			= URDI_MAGIC;
	((UrdiGuardRecord *)p)->version		= version	= VERS;
	((UrdiGuardRecord *)p)->snarfSize	= snarfSize	= argSnarfSize;
	((UrdiGuardRecord *)p)->snarfCount	= snarfCount	= argSnarfCount;
	((UrdiGuardRecord *)p)->stagingAreaSize	= stagingAreaSize = argStagingAreaSize;

	((UrdiGuardRecord *)p)->hash[0] = fastHash(
		  (UInt8 *)&(((UrdiGuardRecord *)p)->hash[HASH_SIZE])
		, sizeof(struct UrdiGuardRecord) - (sizeof(((UrdiGuardRecord *)p)->hash[1])*HASH_SIZE)
	);

	rcoff = lseek(localfd, 0, SEEK_SET);
	if (rcoff < 0) {
		BLAST(ERROR_SEEKING_TO_WRITE_GUARD_RECORD);
	}
	rc = uwrite(localfd, p, (int)argSnarfSize);
	if (rc != argSnarfSize) {
		BLAST(ERROR_WRITING_GUARD_RECORD);
	}
	rcoff = lseek(localfd, (argSnarfSize * (argSnarfCount - 1)), SEEK_SET);
	if (rcoff < 0) {
		BLAST(ERROR_SEEKING_TO_WRITE_GUARD_RECORD);
	}
	rc = uwrite(localfd, p, (int)argSnarfSize);
	if (rc != argSnarfSize) {
		BLAST(ERROR_WRITING_GUARD_RECORD);
	}
	DETONATE_BOMB(p);
	DISARM_BOMB(localfd);
	DISARM_BOMB(argPathName);
	fd = localfd;

	cycleNumber = 1;
	writableSnarfs = 0;
	latestStagingSlot = BEFORE_FIRST_STAGING_SLOT;

	CONSTRUCT_ON(PERSISTENT,viewDummyP,UrdiView,(this, DUMMY_VIEW));
	viewRoot = viewDummyP;
				// Check mem alloc ????

	writeViewP		= NULL;

	CONSTRUCT_ON(PERSISTENT,snarfCacheDummyP,SnarfCache,(DUMMY_CACHE, this));	/* !!!! Dummy object */
	snarfCacheRoot = snarfCacheDummyP;

	CONSTRUCT_ON(PERSISTENT,snarfCacheGoatP,SnarfCache,(GOAT_CACHE, this));
	latestCommittedP = latestSafeOnDiskP = latestSafeOnStageP =
	  snarfCacheGoatP;
						/* !!!! Goat object */
	
	snarfCacheGoatP->linkBefore(snarfCacheDummyP);

	lRUMax = aLRUMax;
	lRUCurrent = 0;
	CONSTRUCT_ON(PERSISTENT,snarfCacheLRUDummyP,SnarfCache,(DUMMY_CACHE, this));
	snarfCacheLRURoot = snarfCacheLRUDummyP;
	myLRUHits = myLRUMisses = 0;
}
/*^L*//* ========================================================================== */
//
//	Constructor for initializing blank partition.
//
/* ========================================================================== */

Urdi *
urdi(
    const char * argPathName
  , long	argSnarfSize
  , long	argStagingAreaSize
  , long	aLRUMax
) {
	RETURN_CONSTRUCT_ON(PERSISTENT,Urdi,(
	    argPathName
	  , argSnarfSize
	  , argStagingAreaSize
	  , aLRUMax
	));
}

Urdi::
Urdi(
    const char * argPathName
  , long	 argSnarfSize
  , long	 argStagingAreaSize
  , long	 aLRUMax
) {
	long			i;
	int			rc;
	off_t			rcoff;
	int			localfd;
	char *			p;
	Int8			c;
	struct stat		statBuf;

	CLAIM_WITH_VAL(EXPECTED_SIZE_OF_GUARD_RECORD == sizeof(struct UrdiGuardRecord),
		SIZE_OF_GUARD_RECORD_WRONG,sizeof (struct UrdiGuardRecord));

	CLAIM_WITH_VAL(EXPECTED_SIZE_OF_SNARF_HEADER == sizeof(struct SnarfHeader),
		SIZE_OF_SNARF_HEADER_WRONG,sizeof (struct SnarfHeader));

	PLANT_BOMB(urdiClose,  localfd);
	PLANT_BOMB(urdiDelete, p);

	viewRoot = viewDummyP = NULL;	// In case constructor fails;
	snarfCacheRoot = NULL;		// In case constructor fails;
	fd = -1;			// In case constructor fails;

#ifdef unix
	localfd = open(ARGPATHNAME, O_RDWR | O_EXCL | O_SYNC, MODE);
#else
	localfd = open(ARGPATHNAME, O_RDWR | O_EXCL, MODE);
#endif
	if (localfd < 0) {
		BLAST(CANT_CREATE_URDI_PARTITION);
	}
	ARM_BOMB(localfd,localfd);

	//======================================================================
	// Use flock() for partitions.  lockf() got broken about SunOS 4.1.
	// flock() won't work over the net, which is fine for partitions.
	//======================================================================
#ifdef unix
#ifndef GNU
	if (flock(localfd, LOCK_EX | LOCK_NB) < 0) {
		BLAST(CANT_LOCK_URDI_PARTITION);
	}
#endif
#endif

	//========================================
	// sniff the URDI partition 
	//
	// !!!! Needs lots more sanity checks.
	//========================================
	if (fstat(localfd, &statBuf) != 0) {
		BLAST(CANT_STAT_URDI_PARTITION);
	}
#ifdef unix
	if ((statBuf.st_mode & S_IFMT) != S_IFBLK) {
		BLAST(URDI_WANTS_BLOCK_SPECIAL);
	}
#endif

	if (argSnarfSize < sizeof(struct UrdiGuardRecord)) {
		BLAST(SNARFS_TOO_SMALL_FOR_GUARD_BLOCK);
	}

	/*p = new char[argSnarfSize];*/
	p = (char *) falloc(argSnarfSize);  /*zzz reg to escape alloc stuff oct 27 1994 */
	ARM_BOMB(p,p);

	rc = read(localfd, p, sizeof(struct UrdiGuardRecord));
	if (rc != sizeof(struct UrdiGuardRecord)) {
		BLAST(ERROR_READING_OLD_GUARD_RECORD);
	}

	if ( ((UrdiGuardRecord *)p)->urdi_magic == URDI_MAGIC
	  || ((UrdiGuardRecord *)p)->urdi_magic == URDI_MAGIC_2143
	  || ((UrdiGuardRecord *)p)->urdi_magic == URDI_MAGIC_3412
	  || ((UrdiGuardRecord *)p)->urdi_magic == URDI_MAGIC_4321
	) {
		BLAST(PARTITION_ALREADY_HAS_URDI_FILE);
	}

	for (i=0; i<argSnarfSize; i++) {
		p[i] = !(i&1) ? 0xDE : 0xAD;	/* Spray with "DEAD"	*/
	}

	rcoff = lseek(localfd, 0, SEEK_SET);
	if (rcoff < 0) {
		BLAST(ERROR_SEEKING_TO_SPRAY_DEAD);
	}

	snarfCount = 0;
	while ( (rc = uwrite(localfd, p, (int)argSnarfSize)) == argSnarfSize ) {
		snarfCount++;
	}
	if (snarfCount < argStagingAreaSize + 2 + MIN_SNARFS) {
		BLAST(URDI_INSUFFICIENT_SNARFS);
	}

	//===========================
	// initialize the partition
	//===========================

	for (c=0; c<SHUFFLE_CHARS; c++) {
		((UrdiGuardRecord *)p)->shuffle[c]		= c;
	}
	((UrdiGuardRecord *)p)->urdi_magic			= URDI_MAGIC;
	((UrdiGuardRecord *)p)->version		= version	= VERS;
	((UrdiGuardRecord *)p)->snarfSize	= snarfSize	= argSnarfSize;
	((UrdiGuardRecord *)p)->snarfCount	= snarfCount;
	((UrdiGuardRecord *)p)->stagingAreaSize	= stagingAreaSize = argStagingAreaSize;

	((UrdiGuardRecord *)p)->hash[0] = fastHash(
		  (UInt8 *)&(((UrdiGuardRecord *)p)->hash[HASH_SIZE])
		, sizeof(struct UrdiGuardRecord) - (sizeof(((UrdiGuardRecord *)p)->hash[1])*HASH_SIZE)
	);

	rcoff = lseek(localfd, 0, SEEK_SET);
	if (rcoff < 0) {
		BLAST(ERROR_SEEKING_TO_WRITE_GUARD_RECORD);
	}
	rc = uwrite(localfd, p, (int)argSnarfSize);
	if (rc != argSnarfSize) {
		BLAST(ERROR_WRITING_GUARD_RECORD);
	}
	rcoff = lseek(localfd, (argSnarfSize * (snarfCount - 1)), SEEK_SET);
	if (rcoff < 0) {
		BLAST(ERROR_SEEKING_TO_WRITE_GUARD_RECORD);
	}
	rc = uwrite(localfd, p, (int)argSnarfSize);
	if (rc != argSnarfSize) {
		BLAST(ERROR_WRITING_GUARD_RECORD);
	}
	DETONATE_BOMB(p);
	DISARM_BOMB(localfd);
	fd = localfd;

	cycleNumber = 1;
	writableSnarfs = 0;
	latestStagingSlot = BEFORE_FIRST_STAGING_SLOT;

	CONSTRUCT_ON(PERSISTENT,viewDummyP,UrdiView,(this, DUMMY_VIEW));
	viewRoot = viewDummyP;
				// Check mem alloc ????

	writeViewP		= NULL;

	CONSTRUCT_ON(PERSISTENT,snarfCacheDummyP,SnarfCache,(DUMMY_CACHE, this));	/* !!!! Dummy object */
	snarfCacheRoot = snarfCacheDummyP;

	CONSTRUCT_ON(PERSISTENT,snarfCacheGoatP,SnarfCache,(GOAT_CACHE, this));
	latestCommittedP = latestSafeOnDiskP = latestSafeOnStageP =
	  snarfCacheGoatP;
						/* !!!! Goat object */
	
	snarfCacheGoatP->linkBefore(snarfCacheDummyP);

	lRUMax = aLRUMax;
	lRUCurrent = 0;
	CONSTRUCT_ON(PERSISTENT,snarfCacheLRUDummyP,SnarfCache,(DUMMY_CACHE, this));
	snarfCacheLRURoot = snarfCacheLRUDummyP;
	myLRUHits = myLRUMisses = 0;
}
/*^L*//* ========================================================================== */
//
//	Constructor for re-opening currently existing partition.
//
/* ========================================================================== */

PROBLEM_LIST(allStageReadProblems,5,(SEEKING,READING,SHUFFLED,HASH,BAD_I_D));

Urdi *
urdi(
    const char * argPathName
  , long	aLRUMax
) {
	RETURN_CONSTRUCT_ON(PERSISTENT,Urdi,(
	    argPathName
	  , aLRUMax
	));
}

Urdi::
Urdi(
    const char * argPathName
  , long	aLRUMax
) {
	int		rc;
	off_t		rcoff;
	int		localfd;
	char *		p;
	Int8		c;
	UInt32		hashCheckBuffer[HASH_SIZE];
	int		j;
	struct stat	statBuf;

	CLAIM_WITH_VAL(EXPECTED_SIZE_OF_GUARD_RECORD == sizeof(struct UrdiGuardRecord),
		SIZE_OF_GUARD_RECORD_WRONG,sizeof (struct UrdiGuardRecord));

	CLAIM_WITH_VAL(EXPECTED_SIZE_OF_SNARF_HEADER == sizeof(struct SnarfHeader),
		SIZE_OF_SNARF_HEADER_WRONG,sizeof (struct SnarfHeader));

	PLANT_BOMB(urdiClose,  localfd);
	PLANT_BOMB(urdiDelete, p);

	viewRoot = viewDummyP = NULL;	// In case constructor fails;
	snarfCacheRoot = NULL;		// In case constructor fails;
	fd = -1;			// In case constructor fails;

	/* ???? Can we check for only one open in this task?	*/
	/* ???? How about lock w/other task?			*/

#ifdef unix
	localfd = open(ARGPATHNAME, O_RDWR | O_EXCL | O_SYNC);
#else
	localfd = open(ARGPATHNAME, O_RDWR | O_EXCL);
#endif
	if (localfd < 0) {
		BLAST(CANT_OPEN_URDI_FILE);
	}
	ARM_BOMB(localfd,localfd);

	if (fstat(localfd, &statBuf) != 0) {
		BLAST(CANT_STAT_URDI_PARTITION);
	}

#ifdef unix
#ifndef GNU
	if ((statBuf.st_mode & S_IFMT) == S_IFBLK) {
		if (flock(localfd, LOCK_EX | LOCK_NB) < 0) {
			BLAST(CANT_LOCK_URDI_PARTITION);
		}
	} else {
		if (lockf(localfd, F_TLOCK, 0L) < 0) {
			BLAST(CANT_LOCK_URDI_FILE);
		}
	}
#endif
#endif

#ifdef	DEBUGHACK
	/*p = new char[DEBUGHACK];*/
	p = (char *) falloc(DEBUGHACK);  /*zzz reg to escape alloc stuff oct 27 1994 */
#else	/* DEBUGHACK */
	/*p = new char[sizeof(struct UrdiGuardRecord)];*/
	p = (char *) falloc(sizeof(struct UrdiGuardRecord));  /*zzz reg to escape alloc stuff oct 27 1994 */
#endif	/* DEBUGHACK */
	ARM_BOMB(p,p);

	/* open() left pointer at start of file, so don't need lseek() */

	rc = read(localfd, p, sizeof(struct UrdiGuardRecord));
	if (rc != sizeof(struct UrdiGuardRecord)) {
		BLAST(ERROR_READING_GUARD_RECORD);
	}

	if ( ((UrdiGuardRecord *)p)->urdi_magic != URDI_MAGIC
	  && ((UrdiGuardRecord *)p)->urdi_magic != URDI_MAGIC_2143
	  && ((UrdiGuardRecord *)p)->urdi_magic != URDI_MAGIC_3412
	  && ((UrdiGuardRecord *)p)->urdi_magic != URDI_MAGIC_4321
	) {
		BLAST(NOT_AN_URDI_FILE);
	}
	for (c=0; c<SHUFFLE_CHARS; c++) {
		if (((UrdiGuardRecord *)p)->shuffle[c] != c) {
			BLAST(URDI_GUARD_RECORD_SHUFFLED);	// !!!! unshuffle some day
		}
	}

	hashCheckBuffer[0] = fastHash(
		  (UInt8 *)&(((UrdiGuardRecord *)p)->hash[HASH_SIZE])
		, sizeof(struct UrdiGuardRecord) - (sizeof(((UrdiGuardRecord *)p)->hash[1])*HASH_SIZE)
	);

	for (j=0; j<HASH_SIZE; j++) {
		if (((UrdiGuardRecord *)p)->hash[j] != hashCheckBuffer[j]) {
			BLAST(URDI_GUARD_RECORD_HASH_CHECK_FAILED);
		}
	}

	version		= ((UrdiGuardRecord *)p)->version;
	snarfSize	= ((UrdiGuardRecord *)p)->snarfSize;
	snarfCount	= ((UrdiGuardRecord *)p)->snarfCount;
	stagingAreaSize = ((UrdiGuardRecord *)p)->stagingAreaSize;

	rcoff = lseek(localfd, (snarfSize * (snarfCount - 1)), SEEK_SET);
					//// Sanity check ????
	if (rcoff < 0) {
		BLAST(ERROR_SEEKING_TO_READ_GUARD_RECORD);
	}
	rc = read(localfd, p, sizeof(struct UrdiGuardRecord));
	if (rc != sizeof(struct UrdiGuardRecord)) {
		BLAST(ERROR_READING_GUARD_RECORD);
	}

	for (j=0; j<HASH_SIZE; j++) {
		if (((UrdiGuardRecord *)p)->hash[j] != hashCheckBuffer[j]) {
			BLAST(GUARD_RECORDS_DONT_MATCH);
		}
	}

	hashCheckBuffer[0] = fastHash(
		  (UInt8 *)&(((UrdiGuardRecord *)p)->hash[HASH_SIZE])
		, sizeof(struct UrdiGuardRecord) - (sizeof(((UrdiGuardRecord *)p)->hash[1])*HASH_SIZE)
	);

	for (j=0; j<HASH_SIZE; j++) {
		if (((UrdiGuardRecord *)p)->hash[j] != hashCheckBuffer[j]) {
			BLAST(GUARD_RECORDS_DONT_MATCH_ON_REHASH);
		}
	}

	DETONATE_BOMB(p);
	DISARM_BOMB(localfd);
	fd = localfd;

	cycleNumber = 1;
	writableSnarfs = 0;
	latestStagingSlot = BEFORE_FIRST_STAGING_SLOT;

	CONSTRUCT_ON(PERSISTENT,viewDummyP,UrdiView,(this, DUMMY_VIEW));
	viewRoot = viewDummyP;

	/* ???? Sanity check?  Common code?	*/

	writeViewP		= NULL;

	CONSTRUCT_ON(PERSISTENT,snarfCacheDummyP,SnarfCache,(DUMMY_CACHE, this));	/* !!!! Dummy object */
	snarfCacheRoot = snarfCacheDummyP;

	CONSTRUCT_ON(PERSISTENT,snarfCacheGoatP,SnarfCache,(GOAT_CACHE, this));
	latestCommittedP = latestSafeOnDiskP = latestSafeOnStageP =
	  snarfCacheGoatP;
						/* !!!! Goat object */
	
	snarfCacheGoatP->linkBefore(snarfCacheDummyP);

	lRUMax = aLRUMax;
	lRUCurrent = 0;
	CONSTRUCT_ON(PERSISTENT,snarfCacheLRUDummyP,SnarfCache,(DUMMY_CACHE, this));
	snarfCacheLRURoot = snarfCacheLRUDummyP;
	myLRUHits = myLRUMisses = 0;

	// ====================================================================
	//	Now that the in-RAM structure is constructed,
	//	suck in last set of modifications
	// ====================================================================

	INSTALL_SHIELD(StageReadDone);

	SnarfCache *	tempSnarfCacheP;
	long		workingStagingSlot;

	workingStagingSlot = BEFORE_FIRST_STAGING_SLOT;
	for (;;) {

		CONSTRUCT_ON(PERSISTENT,tempSnarfCacheP,SnarfCache
			,(DATA_CACHE, this));

		SHIELD_UP(StageReadDone,allStageReadProblems,{
	/**/		SHIELD_BREAK;
		});
		tempSnarfCacheP->getStage(++workingStagingSlot);
		SHIELD_DOWN(StageReadDone);

		if (snarfCacheRoot == snarfCacheGoatP) {
			   cycleNumber  = ((SnarfHeader *)tempSnarfCacheP
				->snarfP)->cycleNumber;
		} else if (cycleNumber != ((SnarfHeader *)tempSnarfCacheP
		    ->snarfP)->cycleNumber) {
	/**/		break;
		}

		tempSnarfCacheP->linkBefore(snarfCacheRoot);
		tempSnarfCacheP = NULL;
		latestSafeOnStageP = snarfCacheRoot;

		if (snarfCacheRoot->isGroupEnd()) {
			latestCommittedP = snarfCacheRoot;

			//// once were're batching closet writes, can save RAM
			//// and/or prevent disaster by doing
			//// 	latestStagingSlot = workingStagingSlot;
			//// and writing closet here.
		}

		if (((SnarfHeader *)snarfCacheRoot->snarfP)->groupFlag
		  == GROUP_SET_END) {
	/**/		break;
		}
	}

	if (tempSnarfCacheP != NULL) {
		tempSnarfCacheP->destroy ();
	}

	while (snarfCacheRoot != latestCommittedP) {
		tempSnarfCacheP = snarfCacheRoot;
		latestSafeOnStageP = tempSnarfCacheP->unlinkReturnSuccessorP();
		tempSnarfCacheP->destroy ();
	}

	latestStagingSlot = BEFORE_FIRST_STAGING_SLOT;
	while (latestSafeOnDiskP != latestSafeOnStageP) {
		latestSafeOnDiskP->previousSnarfCacheP->putCloset();
		latestSafeOnDiskP =latestSafeOnDiskP->previousSnarfCacheP;
	}

	mightCleanSomeSnarfs();

	//
	// Purge the snarf cache (so we don't have to test whether it
	// gets bogus during error recovery, and so tests aren't dependent
	// on the staging area from the creation of the partition).
	//

	while ((tempSnarfCacheP = snarfCacheLRURoot) != snarfCacheLRUDummyP) {
		tempSnarfCacheP->unlinkLRU();
		tempSnarfCacheP->destroy ();
	}
	myLRUHits = myLRUMisses = 0;	// One more time...
}
/*^L*//* ========================================================================== */
//
//	Destructor:   Close the partition.
//
//	(Mostly used for changable media.
//	 The expected shutdown mode for the backend is a system crash.)
//
/* ========================================================================== */

void Urdi::
destruct()
{
#ifdef HIGHC_DEBUG
cerr << "Urdi::destruct\n";
#endif
	SnarfCache *	snarfCacheP;

	if (viewRoot != viewDummyP) {
		BLAST(VIEWS_STILL_OPEN);
	}

	if (viewDummyP != NULL) {
		viewDummyP->destroy ();
	}

	// De-allocate SnarfCache objects.

	while ((snarfCacheP = snarfCacheRoot) != NULL) {
		(void)snarfCacheP->unlinkReturnSuccessorP();
		snarfCacheP->destroy ();
	}

	while ((snarfCacheP = snarfCacheLRURoot) != NULL) {
		snarfCacheP->unlinkLRU();
		snarfCacheP->destroy ();
	}

	if (fd >= 0) {
		if (close(fd) < 0) {
			if (errno != EPERM) {	/* Ignore Sun bug thru 4.0.3 */
				BLAST(CANT_CLOSE_URDI_FILE);
			}
		}
	}

	// !!!! eject ejectable disks

	this->Heaper::destruct ();
}
/*^L*//* ========================================================================== */
//
//	printOn(ostream& oo)
//
/* ========================================================================== */

void Urdi::
printOn(ostream& oo)
{
	UrdiView *	viewP;
	SnarfCache *	snarfCacheP;

	oo << canPtr((void *)this)	<< ": Urdi object\n";
	oo << "\tfd:\t\t\t"		<< fd				<< "\n";
	oo << "\tversion:\t\t"		<< version			<< "\n";
	oo << "\tsnarfSize:\t\t"	<< snarfSize			<< "\n";
	oo << "\tsnarfCount:\t\t"	<< snarfCount			<< "\n";
	oo << "\tstagingAreaSize:\t"	<< stagingAreaSize		<< "\n";
	oo << "\tcycleNumber:\t\t"	<< cycleNumber			<< "\n";
	oo << "\twritableSnarfs:\t\t"	<< writableSnarfs		<< "\n";
	oo << "\tlatestStagingSlot:\t"	<< latestStagingSlot		<< "\n";
	oo << "\tlRUMax:\t\t\t"		<< lRUMax			<< "\n";
	oo << "\tlRUCurrent:\t\t"	<< lRUCurrent			<< "\n";
	oo << "\tmyLRUHits:\t\t"	<< myLRUHits			<< "\n";
	oo << "\tmyLRUMisses:\t\t"	<< myLRUMisses			<< "\n";

	oo << "\tviewRoot:\t\t-> "	<< canPtr((void *)viewRoot)	<< "\n";
	oo << "\tviewDummyP:\t\t-> "	<< canPtr((void *)viewDummyP)	<< "\n";
	oo << "\twriteViewP:\t\t-> "	<< canPtr((void *)writeViewP)	<< "\n";
	oo << "\tsnarfCacheRoot:\t\t-> " << canPtr((void *)snarfCacheRoot)	<< "\n";
	oo << "\tlatestCommittedP:\t-> " << canPtr((void *)latestCommittedP)	<< "\n";
	oo << "\tlatestSafeOnStageP:\t-> "<< canPtr((void *)latestSafeOnStageP)	<< "\n";
	oo << "\tlatestSafeOnDiskP:\t-> " << canPtr((void *)latestSafeOnDiskP)	<< "\n";
	oo << "\tsnarfCacheGoatP:\t-> "  << canPtr((void *)snarfCacheGoatP)	<< "\n";
	oo << "\tsnarfCacheDummyP:\t-> " << canPtr((void *)snarfCacheDummyP)	<< "\n";
	oo << "\tsnarfCacheLRURoot:\t-> " << canPtr((void *)snarfCacheLRURoot)	<< "\n";
	oo << "\tsnarfCacheLRUDummyP:\t-> " << canPtr((void *)snarfCacheLRUDummyP)	<< "\n";
	oo << "\n";

	snarfCacheP = snarfCacheRoot;
	while ((snarfCacheP) != NULL) {
		snarfCacheP->printOn (oo);
		snarfCacheP = snarfCacheP->nextSnarfCacheP;
	}

	snarfCacheP = snarfCacheLRURoot;
	while ((snarfCacheP) != NULL) {
		snarfCacheP->printOn (oo);
		snarfCacheP = snarfCacheP->nextSnarfCacheP;
	}

	viewP = viewRoot;
	while ((viewP) != NULL) {
		viewP->printOn (oo);
		viewP = viewP->nextViewP;
	}
}
/*^L*//* ========================================================================== */
//
//	usableSnarfs(), usableStages():  Return size of closet, staging area.
//
/* ========================================================================== */

long Urdi::
usableSnarfs()
{
	return (snarfCount - stagingAreaSize) -1;
}

long Urdi::
usableStages()
{
	return stagingAreaSize -1;
}

/* ========================================================================== */
//
//	getDataSizeOfSnarf():	Return size of snarf without reading it in.
//
/* ========================================================================== */

long Urdi::
getDataSizeOfSnarf(SnarfID /* aSnarfID */)
{
	return snarfSize - sizeof(struct SnarfHeader);
}

/* ========================================================================== */
//
//	makeReadView():		Return a new read view
//
//	makeWriteView():	Return a new write view
//
/* ========================================================================== */

UrdiView * Urdi::
makeReadView()
{
	RETURN_CONSTRUCT_ON(PERSISTENT,UrdiView,(this,READ_VIEW));
}

UrdiView * Urdi::
makeWriteView()
{
	RETURN_CONSTRUCT_ON(PERSISTENT,UrdiView,(this,WRITE_VIEW));
}

/* ========================================================================== */
//
//	writingSnarf():  Is this snarf already being modified?
//
//	(No check for off-the-end.  May infinite loop if structure corrupted.)
//
/* ========================================================================== */

BooleanVar Urdi::
writingSnarf(SnarfID argSnarfID)
{
	SnarfCache *	snarfCacheP;

	snarfCacheP = snarfCacheRoot;
	while (snarfCacheP != latestCommittedP) {
		if (snarfCacheP->snarfID == argSnarfID) {
			return TRUE;
		}
		snarfCacheP = snarfCacheP->nextSnarfCacheP;
	}
	return FALSE;
}
/*^L*//* ========================================================================== */
//
//	commit():  Commit write to go to the disk.
//
/* ========================================================================== */

SnarfCache * Urdi::
commit()
{
	snarfCacheRoot->markGroupEnd();

	writableSnarfs = 0;
	return (latestCommittedP = snarfCacheRoot);
}

/* ========================================================================== */
//
//	abort():  Abort write.  Free the modified snarf cache objects.
//
/* ========================================================================== */

void Urdi::
abort()
{
	SnarfCache *	snarfCacheP;

	writableSnarfs = 0;

	while ((snarfCacheP = snarfCacheRoot) != latestCommittedP) {
		if (snarfCacheP->handlesOnMe		!= 0
		 || snarfCacheP->frozenHandlesOnMe	!= 0
		 || snarfCacheP->lockStartsOnMe		!= 0
		 || snarfCacheP->lockEndsOnMe		!= 0
		) {
			BLAST(SNARF_CACHE_STILL_HELD_IN_URDI_ABORT);
		}
		(void)snarfCacheP->unlinkReturnSuccessorP();
		snarfCacheP->destroy ();
	}
}
/*^L*//* ========================================================================== */
//
//	mightWriteSomeSnarfs():
//
//	Called when a lock start is dropped, to write snarfs if necessary.
//
//	!!!! Modifications needed here to de-bogusify URDI.
//
//	Current algorithm:
//	 - Walk up structure, writing to the Closet, until encountering
//	    - A lock start
//	    - The end of the committed snarfs.
//	    - The end of the cache.  (Shouldn't hit this case, because
//	      the previous one catches us first.) !!!!
//
/* ========================================================================== */

void Urdi::
mightWriteSomeSnarfs()
{
	SnarfCache *	prevSnarfCacheP;

	for (;;) {
/**/		if (latestSafeOnStageP->lockStartsOnMe > 0) return;
/**/		if (latestSafeOnStageP == latestCommittedP) return;

		prevSnarfCacheP = latestSafeOnStageP->previousSnarfCacheP;

/**//*????*/	if (prevSnarfCacheP == NULL) return;

		if (!(prevSnarfCacheP->isGroupEnd())) {
			prevSnarfCacheP->updateHeader(cycleNumber, FALSE);
		} else {
			prevSnarfCacheP->updateHeader(cycleNumber, TRUE);
			cycleNumber++;
		}

		prevSnarfCacheP->putStage(++latestStagingSlot);
		latestSafeOnStageP = prevSnarfCacheP;

		if (prevSnarfCacheP->isGroupEnd()) {
			latestStagingSlot = BEFORE_FIRST_STAGING_SLOT;
			do {
				latestSafeOnDiskP->previousSnarfCacheP->putCloset();
				latestSafeOnDiskP =latestSafeOnDiskP->previousSnarfCacheP;
			} while (latestSafeOnDiskP != latestSafeOnStageP);
		}
	}
}
/*^L*//* ========================================================================== */
//
//	mightCleanSomeSnarfs():
//
//	Called when a lock end is dropped, to deal with the released caches.
//
//	In principle these might be released earlier.  But I'm trading
//	cache RAM for reduced lock-arbitration overhead (in anticipation of
//	multiprocessor implementations), and keeping the algorithm simple
//	(for faster hacking).
//
//	!!!! Modifications needed here to de-bogusify URDI.
//
//	Current algorithm:
//	 - Walk up unlocked dirty snarfs until finding:
//	    - Start of cache, or
//	    - A locked region.
//	 - Dispose of snarfs as follows:
//	    - If there's one of the same number in the LRU, dump it.
//	    - If they're held, move them to the start of the clean queue.
//	      (Should never be another of same number in queue.)
//	    - Otherwise, move them to the LRU queue.
//	    - If "Urdi->latestCommitted" is cleaned, point that at the goat.
//	    - Ditto "latestSafeOnDisk" and "latestSafeOnStage".
//
/* ========================================================================== */

void Urdi::
mightCleanSomeSnarfs()
{
	if (snarfCacheGoatP->lockEndsOnMe > 0) return;

	SnarfCache *	tempSnarfCacheP;
	SnarfCache *	tempSnarfCacheP2;

	for (;;) {
		tempSnarfCacheP = snarfCacheGoatP->previousSnarfCacheP;
		if (tempSnarfCacheP == NULL) return;
		if (tempSnarfCacheP->lockEndsOnMe > 0) return;

		tempSnarfCacheP2 =
			this->extractFromLRU(tempSnarfCacheP->snarfID);
		if (tempSnarfCacheP2 != NULL) {
			tempSnarfCacheP2->destroy ();
		}

		tempSnarfCacheP->isDirty = FALSE;
		tempSnarfCacheP->groupEnd = FALSE;
		(void)tempSnarfCacheP->unlinkReturnSuccessorP();

		if (tempSnarfCacheP->handlesOnMe > 0) {
			tempSnarfCacheP->linkBefore(
				snarfCacheGoatP->nextSnarfCacheP
			);
		} else {
			tempSnarfCacheP->addToLRU();
		}

		if (latestCommittedP == tempSnarfCacheP) {
			latestCommittedP = snarfCacheGoatP;
		}
		if (latestSafeOnStageP == tempSnarfCacheP) {
			latestSafeOnStageP = snarfCacheGoatP;
		}
		if (latestSafeOnDiskP == tempSnarfCacheP) {
			latestSafeOnDiskP = snarfCacheGoatP;
		}
	}
}
/*^L*//* ========================================================================== */
//
// 	An LRU cache of SnarfCache objects is maintained.  Entries in this
//	cache represent snarfs which are on the disk, and on which there
//	are no current handles (though there were recently, so their contents
//	were already in RAM, and are thus deemed worth preserving).
//
//	The code which manages the LRU is distributed through the Urdi,
//	SnarfCache, and UrdiView objects.  (Perhaps it should be collected.)
//	It is documented here, near the first LRU-specific routine.
//
//	Routines that relate to the LRU:
//
//	Urdi::Urdi(...):
//	Urdi::~Urdi():
//	   The Urdi object contains the LRU queue, together with variables
//	   containing the current and maximum number of entries.  The
//	   The Urdi constructors initialize these queues and variables,
//	   while the destructor discards any objects remaining in the LRU.
//	   (The Urdi reopen constructor also flushes the LRU of any snarfs
//	   that were cached during disk repair.  This might not be necessary,
//	   but it makes debugging a lot easier.)
//
//	Urdi::printOn():
//	   printOn() was augmented to display the extra variables and the
//	   LRU queue.
//
//	SnarfHandle::SnarfHandle():
//	   If it doesn't find the desired snarf in the main cache (via
//	   UrdiView::findInCache()), this constructor now tries the LRU
//	   (via Urdi::extractFromLRU()) before resorting to the construction
//	   of a new SnarfCache object (which reads data from the disk).
//
//	SnarfCache::dropping()
//	   Rather than deleting unheld snarf caches, this routine now saves
//	   them at the start of the LRU queue.  (This catches two cases:
//	   destroying the last read handle and making the last read handle
//	   writable.)
//
//	Urdi::mightCleanSomeSnarfs():
//	   Rather than deleting unheld SnarfCache objects, this routine now
//	   also enqueues them at the start of the LRU queue.  (Each time it
//	   saves one, there may be one previous state of the snarf already
//	   in the LRU, so it first searches for one and deletes it if found.
//	   In principle the stale snarf might have been deleted sooner, but
//	   this is the first moment that is algorithmicly convenient.)
//
//	SnarfCache::addToLRU()
//	   Links this SnarfCache object at the beginning of the LRU.  (Removes
//	   and deletes the oldest item in the LRU if it would overflow, else
//	   bumps the count of saved items.)
//
//	SnarfCache::unlinkLRU()
//	   Unlinks this SnarfCache object from the LRU (updating the count).
//
//	Urdi::extractFromLRU()
//	   Searches for a snarf with the specified I.D. in the LRU, unlinking
//	   and returning it if found.  Decrements the count of items in the
//	   LRU if an item is unlinked.  (If we're looking for a snarf in the
//	   LRU, we want either to discard it or move it to the main queue and
//	   put a handle on it.)
//
//	Memory allocation could also be saved by:
//	 - maintaining another queue of dirtied cache objects from
//	   aborted writes, LRU overflows, and other places where a SnarfCache
//	   would otherwise be destroyed.
//	 - Reusing memory from this queue, and perhaps the tail of the
//	   LRU cache as well, when new caches are needed.
//	The idea here is to approximate allocating a limited number of
//	SnarfCaches (or perhaps the buffers from them) then keeping them
//	around and never hitting the allocator again.
//
/* ========================================================================== */

/* ========================================================================== */
//
//	extractFromLRU():  Friends-only routine to search LRU for desired snarf.
//
/* ========================================================================== */

SnarfCache * Urdi::
extractFromLRU(SnarfID argSnarfID)
{
	SnarfCache *	tempSnarfCacheP = snarfCacheLRURoot;

	while (tempSnarfCacheP->nextSnarfCacheP != NULL) {
		if (tempSnarfCacheP->snarfID == argSnarfID) {
			tempSnarfCacheP->unlinkLRU();
			return tempSnarfCacheP;
		}
		tempSnarfCacheP = tempSnarfCacheP->nextSnarfCacheP;
	}

	return NULL;
}

/* ========================================================================== */
//
//	lRUHits(), lRUMisses():  Extract cache hit statistics.
//
/* ========================================================================== */

long Urdi::
lRUHits()
{
	return myLRUHits;
}

long Urdi::
lRUMisses()
{
	return myLRUMisses;
}
/*^L*//* ========================================================================== */
//
//	SnarfCache object:  One slot in the snarf cache.
//
/* ========================================================================== */

SnarfCache::
SnarfCache(SnarfCacheType argSnarfCacheType, Urdi * argUrdiP)
{
	urdiP			= argUrdiP;
	nextSnarfCacheP		= NULL;
	previousSnarfCacheP	= NULL;
	snarfCacheType		= argSnarfCacheType;
	isDirty			= FALSE;
	groupEnd		= FALSE;
	snarfP			= NULL;
	if (snarfCacheType == DUMMY_CACHE) {
		handlesOnMe	= 1;
		frozenHandlesOnMe = 0;
		lockStartsOnMe	= 1;	/* ???? Could be 0 */
		lockEndsOnMe	= 1;	/* ???? Could be 0 */
		snarfSize	= 0;
		snarfID		= -1;		/* Must be impossible !!!! */
	} else if (snarfCacheType == GOAT_CACHE) {
		handlesOnMe	= 1;
		frozenHandlesOnMe = 0;
		lockStartsOnMe	= 0;
		lockEndsOnMe	= 0;
		snarfSize	= 0;
		snarfID		= -2;		/* Must be impossible !!!! */
	} else {
		handlesOnMe	= 0;
		frozenHandlesOnMe = 0;
		lockStartsOnMe	= 0;
		lockEndsOnMe	= 0;
		snarfSize	= urdiP->snarfSize;
	/*	snarfP		= new char[snarfSize];*/
	snarfP = (char *) falloc(snarfSize);  /*zzz reg to escape alloc stuff oct 27 1994 */
		snarfID		= -3;		/* !!!! */
	}
}

void SnarfCache::
destruct ()
{
#ifdef HIGHC_DEBUG
cerr << "SnarfCache::destruct\n";
#endif
	if (handlesOnMe != 0 && !isDummy()) {
		BLAST(CANT_DESTROY_SNARF_CACHE_WITH_HANDLE_ON_IT);
	}
	if (snarfP != NULL) {
		delete snarfP;
	}
	this->Heaper::destruct ();
}
/*^L*//* ========================================================================== */
//
//	printOn(ostream& oo)
//
/* ========================================================================== */

void SnarfCache::
printOn(ostream& oo)
{
	oo << canPtr((void *)this)		<< ": SnarfCache object\n";
	oo << "\turdiP:\t\t\t-> "		<< canPtr((void *)urdiP)		<< "\n";
	oo << "\tnextSnarfCacheP:\t-> "		<< canPtr((void *)nextSnarfCacheP)	<< "\n";
	oo << "\tpreviousSnarfCacheP:\t-> "	<< canPtr((void *)previousSnarfCacheP)	<< "\n";
	oo << "\tsnarfCacheType:\t\t"	<< (
			snarfCacheType == DUMMY_CACHE	? "DUMMY_CACHE\n" :
			snarfCacheType == GOAT_CACHE	? "GOAT_CACHE\n" :
			snarfCacheType == DATA_CACHE	? "DATA_CACHE\n" :
			"UNKNOWN_CACHE_TYPE\n"
	);
	oo << "\tsnarfSize:\t\t"		<< snarfSize				<< "\n";
	oo << "\tsnarfP:\t\t\t-> "		<< canPtr((void *)snarfP)		<< "\n";
	oo << "\tsnarfID:\t\t"			<< snarfID				<< "\n";
	oo << "\tisDirty:\t\t"			<< (isDirty ? "TRUE":"FALSE")		<< "\n";
	oo << "\tgroupEnd:\t\t"			<< (groupEnd ? "TRUE":"FALSE")		<< "\n";
	oo << "\thandlesOnMe:\t\t"		<< handlesOnMe				<< "\n";
	oo << "\tfrozenHandlesOnMe:\t"		<< frozenHandlesOnMe			<< "\n";
	oo << "\tlockStartsOnMe:\t\t"		<< lockStartsOnMe			<< "\n";
	oo << "\tlockEndsOnMe:\t\t"		<< lockEndsOnMe				<< "\n";
	oo << "\n";
}
/*^L*//* ========================================================================== */
//
//	linkBefore(SnarfCache * argSuccessor)
//	addToLRU()
//
//	Link this SnarfCache object into the doubly-linked URDI SnarfCache list.
//
//	(There is alway a successor:  The dummy end-of-list object is linked
//	 separately, and not unlinked until the Urdi object is being destroyed.)
//
//	(LRU version also maintains count of items in the LRU and deletes a
//	 crufty item if this one overfills it.  It may be this one, if the
//	 LRU is configured to remain empty.)
//
/* ========================================================================== */

void SnarfCache::
linkBefore(SnarfCache * argSuccessor)
{
	nextSnarfCacheP			= argSuccessor;
	previousSnarfCacheP		= argSuccessor->previousSnarfCacheP;

	nextSnarfCacheP->previousSnarfCacheP	= this;
	if (previousSnarfCacheP == NULL) {
		urdiP->snarfCacheRoot = this;
	} else {
		previousSnarfCacheP->nextSnarfCacheP	= this;
	}
}

void SnarfCache::
addToLRU()
{
	nextSnarfCacheP			= urdiP->snarfCacheLRURoot;
	previousSnarfCacheP		= nextSnarfCacheP->previousSnarfCacheP;

	nextSnarfCacheP->previousSnarfCacheP	= this;
	urdiP->snarfCacheLRURoot = this;

	if (++(urdiP->lRUCurrent) > (urdiP->lRUMax)) {
		SnarfCache *	tempSnarfCacheP;

		tempSnarfCacheP =
			urdiP->snarfCacheLRUDummyP->previousSnarfCacheP;
		tempSnarfCacheP->unlinkLRU();
		tempSnarfCacheP->destroy ();
	}
}
/*^L*//* ========================================================================== */
//
//	SnarfCache * unlinkReturnSuccessorP();		unlink from main queue
//	unlinkLRU();					unlink from LRU queue
//
//	Unlinks this SnarfCache object.
//	 - The unlink routine for the main queue returns pointer to the
//	   former successor item (because that's often needed next).
//	 - The unlink routine for the LRU queue updates the count of items
//	   in the LRU.
//
//	(Written so you can even unlink the dummy end-of-list object, at some
//	 cost in efficiency.)	!!!!
//
/* ========================================================================== */

SnarfCache * SnarfCache::
unlinkReturnSuccessorP()
{
	if (nextSnarfCacheP != NULL) {
		nextSnarfCacheP->previousSnarfCacheP	= previousSnarfCacheP;
	}
	if (previousSnarfCacheP == NULL) {
		urdiP->snarfCacheRoot			= nextSnarfCacheP;
	} else {
		previousSnarfCacheP->nextSnarfCacheP	= nextSnarfCacheP;
	}
	return (nextSnarfCacheP);
}

void SnarfCache::
unlinkLRU()
{
	if (nextSnarfCacheP != NULL) {
		nextSnarfCacheP->previousSnarfCacheP	= previousSnarfCacheP;
	}
	if (previousSnarfCacheP == NULL) {
		urdiP->snarfCacheLRURoot		= nextSnarfCacheP;
	} else {
		previousSnarfCacheP->nextSnarfCacheP	= nextSnarfCacheP;
	}
	(urdiP->lRUCurrent)--;
}

/* ========================================================================== */
//
//	isDummy():  Check whether snarf is real.
//
//	!!!! Change this.
//
/* ========================================================================== */

BooleanVar SnarfCache::
isDummy()
{
	return (snarfSize == 0);	// !!!! Use type.  (What to do about goat?)
}
/*^L*//* ========================================================================== */
//
//	lockStartGrabbed(), lockStartDropped(),
//	lockEndGrabbed(),   lockEndDropped():   Keep track of view locks.
//
//	Dropping a lock may cause snarfs to be scheduled to be written to disk.
//
//	Be sure to drop the start before dropping the end.
//
/* ========================================================================== */

void SnarfCache::
lockStartGrabbed()
{
	lockStartsOnMe++;
}

void SnarfCache::
lockEndGrabbed()
{
	lockEndsOnMe++;
}

void SnarfCache::
lockStartDropped()
{
	if (--lockStartsOnMe < 1) {
		urdiP->mightWriteSomeSnarfs();
	}
}

void SnarfCache::
lockEndDropped()
{
	if (--lockEndsOnMe < 1) {
		urdiP->mightCleanSomeSnarfs();
	}
}
/*^L*//* ========================================================================== */
//
//	markGroupEnd(): Mark end of group.
//
/* ========================================================================== */

void SnarfCache::
markGroupEnd()
{
	groupEnd = TRUE;
}

/* ========================================================================== */
//
//	isGroupEnd(): Return end-of-group mark.
//
/* ========================================================================== */

BooleanVar SnarfCache::
isGroupEnd()
{
	return groupEnd;
}

/* ========================================================================== */
//
//	updateHeader(argCycleNumber, argCycleEnd): Update header for write.
//
/* ========================================================================== */

void SnarfCache::
updateHeader(UInt32 argCycleNumber, BooleanVar argCycleEnd)
{
	long			i;
	Int8			c;

	for (i=0; i<sizeof(struct SnarfHeader); i++) {
		snarfP[i] = !(i&1) ? 0xDE : 0xAD;	/* Spray with "DEAD"	*/
	}
	for (c=0; c<SHUFFLE_CHARS; c++) {
		((SnarfHeader *)snarfP)->shuffle[c] = c;
	}
	((SnarfHeader *)snarfP)->snarfID = snarfID;

	((SnarfHeader *)snarfP)->cycleNumber = argCycleNumber;
	if (!(groupEnd)) {
		((SnarfHeader *)snarfP)->groupFlag = GROUP_MEMBER;
	} else if (!(argCycleEnd)) {
		((SnarfHeader *)snarfP)->groupFlag = GROUP_END;
	} else {
		((SnarfHeader *)snarfP)->groupFlag = GROUP_SET_END;
	}

	((SnarfHeader *)snarfP)->hash[0] = fastHash(
		  (UInt8 *)&(((SnarfHeader *)snarfP)->hash[HASH_SIZE])
		, (int)(snarfSize - (sizeof(((SnarfHeader *)snarfP)->hash[1])*HASH_SIZE))
	);
}
/*^L*//* ========================================================================== */
//
//	getDataSize():   Return size of this snarf's data buffer.
//
//	(Used when grabbing a snarf that's already in a cache.)
//
/* ========================================================================== */

long SnarfCache::
getDataSize()
{
	return snarfSize - sizeof(struct SnarfHeader);
}

/* ========================================================================== */
//
//	getBlank(): Fills in cache info, but don't read data.
//
//	Returns size of this snarf's data buffer.
//
//	(Assumes snarf is virgin, and will be filled in completely by client.)
//	(Note that allocation of snarfs is client's job.)
//
/* ========================================================================== */

long SnarfCache::
getBlank(SnarfID argSnarfID)
{
	snarfID = argSnarfID;
	if (snarfID < 0 || snarfID >= urdiP->usableSnarfs()) {
		BLAST(INVALID_SNARF_I_D);
	}

	isDirty = TRUE;
	return snarfSize - sizeof(struct SnarfHeader);
}

/* ========================================================================== */
//
//	copy(): Fills in cache with copy of existing read snarf.
//
//	(!!!! Read snarf may not have frozen handles on it.  If we upgrade
//	      to manage a limited number of real snarf cach buffers, this
//	      may have resulted in the read snarf being swapped out, so
//	      we'd have to check for that here, and (perhaps?) swap it back
//	      in, or make a copy on the swap medium.)
//
/* ========================================================================== */

#ifdef HIGHC
#	include <string.h>
#else
#ifdef	CxxV2
#	include <libc.h>
#else	/* CxxV2 */
#	include <libc.h>
#endif	/* CxxV2 */
#endif /* HIGHC */

void SnarfCache::
copy(SnarfCache * argSnarfCache)
{

	snarfID = argSnarfCache->snarfID;
	MEMMOVE(snarfP, argSnarfCache->snarfP, (int)snarfSize);
	isDirty = TRUE;		// (Should this be in the caller????)
}
/*^L*//* ========================================================================== */
//
//	putGuards()???? (Currently in Urdi() virgin constructor)
//
/* ========================================================================== */

/* ========================================================================== */
//
//	putStage(): Write a snarf to the staging area.
//
/* ========================================================================== */

void SnarfCache::
putStage(long argStagingSlot)
{
#ifdef HIGHC_DEBUG
cerr << "putStage (" << argStagingSlot << ")\n";
#endif
	// ???? Should we sanity check argStagingSlot first?

	if (lseek(urdiP->fd, (urdiP->snarfSize * argStagingSlot), SEEK_SET) < 0) {
		BLAST(ERROR_SEEKING_TO_WRITE_SNARF_TO_STAGING_AREA);
	}

	if (uwrite(urdiP->fd, snarfP, (int)snarfSize) != (int)snarfSize) {
		BLAST(URDI_ERROR_WRITING_SNARF_TO_STAGING_AREA);
	}
}

/* ========================================================================== */
//
//	putCloset(): Write a snarf to it's final location.
//
/* ========================================================================== */

void SnarfCache::
putCloset()
{
#ifdef HIGHC_DEBUG
cerr << "putCloset ()\n";
#endif
	if (lseek(urdiP->fd, (urdiP->snarfSize *
	    (snarfID + urdiP->stagingAreaSize)), SEEK_SET) < 0
	) {
		BLAST(ERROR_SEEKING_TO_WRITE_SNARF_TO_CLOSET);
	}

	if (uwrite(urdiP->fd, snarfP, (int)snarfSize) != (int)snarfSize) {
		BLAST(URDI_ERROR_WRITING_SNARF_TO_CLOSET);
	}
}
/*^L*//* ========================================================================== */
//
//	getGuards()???? (Currently in Urdi() constructor)
//
/* ========================================================================== */

/* ========================================================================== */
//
//	getStage(): Fills in cache by reading snarf from the staging area.
//
/* ========================================================================== */

void SnarfCache::
getStage(long argStagingSlot)
{
	UInt32		hashCheckBuffer[HASH_SIZE];
	int		j;
	Int8		c;

	// ???? Should we sanity check argStagingSlot first?

	if (lseek(urdiP->fd, (urdiP->snarfSize * argStagingSlot), SEEK_SET) < 0) {
		BLAST(SEEKING);
	}

	if (read(urdiP->fd, snarfP, (int)snarfSize) != (int)snarfSize) {
		BLAST(READING);
	}

	for (c=0; c<SHUFFLE_CHARS; c++) {
		if (((SnarfHeader *)snarfP)->shuffle[c] != c) {
			BLAST(SHUFFLED);	// !!!! unshuffle some day
		}
	}

	hashCheckBuffer[0] = fastHash(
		  (UInt8 *)&(((SnarfHeader *)snarfP)->hash[HASH_SIZE])
		, (int)(snarfSize - (sizeof(((SnarfHeader *)snarfP)->hash[1])*HASH_SIZE))
	);

	for (j=0; j<HASH_SIZE; j++) {
		if (((SnarfHeader *)snarfP)->hash[j] != hashCheckBuffer[j]) {
			BLAST(HASH);
		}
	}

	snarfID = ((SnarfHeader *)snarfP)->snarfID;
	if (snarfID < 0 || snarfID >= urdiP->usableSnarfs()) {
		BLAST(BAD_I_D);
	}

	groupEnd = (((SnarfHeader *)snarfP)->groupFlag != GROUP_MEMBER);
	isDirty = TRUE;
}
/*^L*//* ========================================================================== */
//
//	getCloset(): Fills in cache by reading snarf from the disk.
//
//	Returns size of this snarf's data buffer.
//
/* ========================================================================== */

long SnarfCache::
getCloset(SnarfID argSnarfID)
{
	UInt32		hashCheckBuffer[HASH_SIZE];
	int		j;
	Int8		c;

	snarfID = argSnarfID;
	if (snarfID < 0 || snarfID >= urdiP->usableSnarfs()) {
		BLAST(INVALID_SNARF_I_D);
	}

	if (lseek(urdiP->fd, (urdiP->snarfSize *
	    (snarfID + urdiP->stagingAreaSize)), SEEK_SET) < 0
	) {
		BLAST(ERROR_SEEKING_TO_READ_SNARF);
	}

	if (read(urdiP->fd, snarfP, (int)snarfSize) != (int)snarfSize) {
		BLAST(URDI_ERROR_READING_SNARF);
	}

	for (c=0; c<SHUFFLE_CHARS; c++) {
		if (((SnarfHeader *)snarfP)->shuffle[c] != c) {
			BLAST(URDI_SNARF_SHUFFLED_UNINITTED_OR_GARBAGE);
				// !!!! unshuffle some day
		}
	}

	hashCheckBuffer[0] = fastHash(
		  (UInt8 *)&(((SnarfHeader *)snarfP)->hash[HASH_SIZE])
		, (int)(snarfSize - (sizeof(((SnarfHeader *)snarfP)->hash[1])*HASH_SIZE))
	);

	for (j=0; j<HASH_SIZE; j++) {
		if (((SnarfHeader *)snarfP)->hash[j] != hashCheckBuffer[j]) {
			BLAST(URDI_SNARF_HASH_CHECK_FAILED);
		}
	}
	if (snarfID != ((SnarfHeader *)snarfP)->snarfID) {
		BLAST(URDI_WRONG_SNARF_READ);
	}

	isDirty = FALSE; // !!!! Redundant now, may need for optimizations later
	return snarfSize - sizeof(struct SnarfHeader);
}
/*^L*//* ========================================================================== */
//
//	grabbing(), dropping():  Keep track of handles holding this snarf.
//
//	(May move snarf to the LRU when last snarfhandle is dropped.)
//
/* ========================================================================== */

void SnarfCache::
grabbing()
{
	handlesOnMe++;
}

void SnarfCache::
dropping()
{
	if (handlesOnMe < 1) {
		BLAST(DROPPED_HANDLE_NOT_HELD);
	}
	handlesOnMe--;

	if (handlesOnMe < 1 && !isDirty) {
		(void)this->unlinkReturnSuccessorP();
		this->addToLRU();
	}
}

/* ========================================================================== */
//
//	freezing(), thawing():  Keep track of frozen handles holding this snarf.
//
//	(!!!! Hooks for the future, when unfrozen handles may allow the data
//	 buffer to be re-used.)
//
/* ========================================================================== */

char * SnarfCache::
freezing()
{
	frozenHandlesOnMe++;
	return snarfP + sizeof(struct SnarfHeader);
}

void SnarfCache::
thawing()
{
	frozenHandlesOnMe--;
}
/*^L*//* ========================================================================== */
//
// UrdiView:  Object representing a static view of a virtual disk.  (= a lock)
//
// (Comes in read and write flavors.  {argViewType is disgusting.})
// (First product:  Only one write view at a time.  Update is single-thread.)
//
/* ========================================================================== */

UrdiView::
UrdiView(Urdi* argUrdiP, ViewType argViewType)
{
	urdiP		= argUrdiP;
	viewType	= argViewType;

	if (viewType == DUMMY_VIEW) {
		nextViewP	= NULL;
		previousViewP	= NULL;
		/* Urdi object links it in */

		lockStartP		= NULL;
		lockEndP		= NULL;
		snarfHandleRoot		= NULL;
		snarfHandleDummyP	= NULL;
		frozenSnarfHandleRoot	= NULL;

	} else {
		if (viewType == WRITE_VIEW) {
			if (urdiP->writeViewP != NULL) {
				viewType = VIEW_CONSTRUCTOR_FAILED;
				BLAST(ATTEMPT_TO_OPEN_SECOND_WRITE_VIEW);
			}
			urdiP->writeViewP = this;
		}

		nextViewP	= urdiP->viewRoot;
		if (nextViewP != NULL) {		/* (Never false.) */
			nextViewP->previousViewP	= this;
		}

		previousViewP	= NULL;
		urdiP->viewRoot	= this;

		lockStartP = urdiP->latestCommittedP;
		lockEndP   = urdiP->latestSafeOnDiskP;
		lockStartP->lockStartGrabbed();
		lockEndP->lockEndGrabbed();

		CONSTRUCT_ON(PERSISTENT,snarfHandleDummyP,SnarfHandle,(this,-1,DUMMY_HANDLE));	// ???? if err?
		snarfHandleRoot = snarfHandleDummyP;
		frozenSnarfHandleRoot		= NULL;
	}
}
/*^L*//* ========================================================================== */
//
//	~UrdiView():  Destroy views (= release locks)
//
//	(Write views must first be "resolved", via becomeRead().)
//	(Currently, there is only one write view at a time.)
//
/* ========================================================================== */

void UrdiView::
destruct ()
{
#ifdef HIGHC_DEBUG
cerr << "UrdiView::destruct\n";
#endif
	if (viewType == VIEW_CONSTRUCTOR_FAILED) {
		return;
	}

	if (snarfHandleRoot != snarfHandleDummyP) {
		BLAST(CANT_DROP_VIEW_WITH_HANDLES_HELD);
	}

	if (viewType == WRITE_VIEW) {
		this->becomeRead();
	}

	if (nextViewP != NULL) {
		nextViewP->previousViewP = previousViewP;
	}
	if (previousViewP != NULL) {
		previousViewP->nextViewP = nextViewP;
	}
	if (urdiP->viewRoot == this) {
		urdiP->viewRoot = nextViewP;
	}
	if (urdiP->viewDummyP == this) {
		urdiP->viewDummyP = previousViewP;	// Better be NULL!!!!
	}

	if (viewType != DUMMY_VIEW) {
		lockStartP->lockStartDropped();
		lockEndP->lockEndDropped();
	}

	if (snarfHandleDummyP != NULL) {
		snarfHandleDummyP->destroy ();
	}

	this->Heaper::destruct ();
}
/*^L*//* ========================================================================== */
//
//	printOn(ostream& oo)
//
/* ========================================================================== */

void UrdiView::
printOn(ostream& oo)
{
	SnarfHandle *	snarfHandleP;

	oo << canPtr((void *)this)		<< ": View object\n";

	oo << "\turdiP\t\t\t-> "		<< canPtr((void *)urdiP)		<< "\n";
	oo << "\tnextViewP:\t\t-> "		<< canPtr((void *)nextViewP)		<< "\n";
	oo << "\tpreviousViewP:\t\t-> "		<< canPtr((void *)previousViewP)	<< "\n";
	oo << "\tviewType:\t\t"			<< (
				viewType == WRITE_VIEW	? "WRITE_VIEW\n" :
				viewType == READ_VIEW	? "READ_VIEW\n" :
				viewType == DUMMY_VIEW	? "DUMMY_VIEW\n" :
				"UNKNOWN_VIEW_TYPE\n"
	);
	oo << "\tlockStartP\t\t-> "		<< canPtr((void *)lockStartP)		<< "\n";
	oo << "\tlockEndP\t\t-> "		<< canPtr((void *)lockEndP)		<< "\n";
	oo << "\tsnarfHandleRoot\t\t-> "	<< canPtr((void *)snarfHandleRoot)	<< "\n";
	oo << "\tsnarfHandleDummyP\t-> "	<< canPtr((void *)snarfHandleDummyP)	<< "\n";
	oo << "\tfrozenSnarfHandleRoot\t-> " << canPtr((void *)frozenSnarfHandleRoot)	<< "\n";

	oo << "\n";

	snarfHandleP = snarfHandleRoot;
	while ((snarfHandleP) != NULL) {
		snarfHandleP->printOn (oo);
		snarfHandleP = snarfHandleP->nextSnarfHandleP;
	}
}
/*^L*//* ========================================================================== */
//
//	thawHandles():  Thaws all frozen snarfHandles within this view.
//
//	(!!!! Later versions may re-use snarf buffers, "paging out" the
//	      former contents, to conserve memory.  For now these are just
//	      hooks to be sure client routines behave correctly.)
//
//	!!!! Void the data pointer !
//
/* ========================================================================== */

void UrdiView::
thawHandles()
{
	while (frozenSnarfHandleRoot != NULL) {
		frozenSnarfHandleRoot->thaw();
	}
}

/* ========================================================================== */
//
//	isWriteView():  Return TRUE if this is a (THE!) write view.
//
/* ========================================================================== */

BooleanVar UrdiView::
isWriteView()
{
	return (viewType == WRITE_VIEW);
}
/*^L*//* ========================================================================== */
//
//	Once you've started making changes (by making a handle writable or
//	grabbing a handle on a blank snarf), you must "resolve the write"
//	(tell URDI what you want done) before you can release the write view.
//
//	You do this by committing it or aborting it.
//
/* ========================================================================== */
//
//	commitWrite():	Commit the write.
//			(Maintains the write view to make additional changes.)
//
/* ========================================================================== */

void UrdiView::
commitWrite()
{
#ifdef HIGHC_DEBUG
cerr << "commitWrite ()\n";
#endif
	if (viewType != WRITE_VIEW) {
		BLAST(NOT_WRITE_VIEW);
	}

	SnarfHandle *	snarfHandleP = snarfHandleRoot;
	while (snarfHandleP != NULL) {
		if (snarfHandleP->snarfHandleType == WRITE_HANDLE) {
			snarfHandleP->snarfHandleType = READ_HANDLE;
		}
		snarfHandleP = snarfHandleP->nextSnarfHandleP;
	}

	SnarfCache *	snarfCacheP;
	snarfCacheP = urdiP->commit();		// !!!! Need mutex here...
	snarfCacheP->lockStartGrabbed();
	lockStartP->lockStartDropped();
	lockStartP = snarfCacheP;		// !!!! ... to here.
}

/* ========================================================================== */
//
//	abortWrite():	Abort the write.
//			(Maintains the write view to try another change.)
//
/* ========================================================================== */

void UrdiView::
abortWrite()
{
#ifdef HIGHC_DEBUG
cerr << "abortWrite ()\n";
#endif
	if (viewType != WRITE_VIEW) {
		BLAST(NOT_WRITE_VIEW);
	}

	SnarfHandle *	snarfHandleP = snarfHandleRoot;
	while (snarfHandleP != NULL) {
		if (snarfHandleP->snarfHandleType == WRITE_HANDLE) {
			BLAST(WRITE_HANDLES_HELD_WHILE_ABORTING);
		}
		snarfHandleP = snarfHandleP->nextSnarfHandleP;
	}

	urdiP->abort();	/* Deletes the changed snarf cache objects. */
}
/*^L*//* ========================================================================== */
//
//	becomeRead():	Become a read view.
//			(If changes were started, they must be resolved
//			 by commitWrite() or abortWrite().)
//
/* ========================================================================== */

void UrdiView::
becomeRead()
{
	if (viewType != WRITE_VIEW) {
		BLAST(NOT_WRITE_VIEW);
	}

	if (urdiP->latestCommittedP != urdiP->snarfCacheRoot) {
		BLAST(DIDNT_RESOLVE_WRITE_IN_PROGRESS);
	}

	viewType		= READ_VIEW;
	urdiP->writeViewP	= NULL;

	//// unblock waiting write task
}

/* ========================================================================== */
//
//	getDataSizeOfSnarf():	Return size of snarf without reading it in.
//
/* ========================================================================== */

long UrdiView::
getDataSizeOfSnarf(SnarfID aSnarfID)
{
	return urdiP->getDataSizeOfSnarf(aSnarfID);
}

/* ========================================================================== */
//
//	makeReadHandle():	Return a new handle on a read snarf.
//					(Client may make it writable later.)
//
//	makeErasingHandle():	Return a new handle on a blank snarf.
//					(Client tells US it's blank.)
//
/* ========================================================================== */

SnarfHandle * UrdiView::
makeReadHandle(SnarfID aSnarfID)
{
	RETURN_CONSTRUCT_ON(PERSISTENT,SnarfHandle,(this,aSnarfID,READ_HANDLE));
}

SnarfHandle * UrdiView::
makeErasingHandle(SnarfID aSnarfID)
{
	RETURN_CONSTRUCT_ON(PERSISTENT,SnarfHandle,(this,aSnarfID,WRITE_HANDLE));
}
/*^L*//* ========================================================================== */
//
//	findInCache():  Friends-only routine to search cache for desired snarf.
//
/* ========================================================================== */

SnarfCache * UrdiView::
findInCache(SnarfID argSnarfID)
{
	SnarfCache *	tempSnarfCacheP = lockStartP;

	while (tempSnarfCacheP->nextSnarfCacheP != NULL) {
		if (tempSnarfCacheP->snarfID == argSnarfID) {
			return tempSnarfCacheP;
		}
		tempSnarfCacheP = tempSnarfCacheP->nextSnarfCacheP;
	}
	return NULL;
}
/*^L*//* ========================================================================== */
//
//	SnarfHandle object:  All access to a snarf goes through this.
//
//	(A "handle" is an Apple-ism for a double-indirect pointer.
//	 Using handles allows the system to move things around if necessary,
//	 for instance:  paging out a snarf when things get tight.)
//
//	Clients may get more than one handle on a snarf within a read view,
//	and thus need not check for identical snarf i.d.s when doing lookups.
//	Within write views the clients must be more careful.
//
//	It is the client's job to allocate snarfs.  When he uses the
//	HandleOnBlankSnarf() macro to obtain a blank writable snarf,
//	he client is assuring us this is a virgin snarf, so we can
//	skip reading and error-checking the data.
//
/* ========================================================================== */

SnarfHandle::
SnarfHandle(UrdiView * argViewP, SnarfID argSnarfID, SnarfHandleType argSnarfHandleType)
{
	viewP		= argViewP;
	snarfHandleType	= argSnarfHandleType;
	snarfID		= argSnarfID;

	if (snarfHandleType == DUMMY_HANDLE) {
		nextSnarfHandleP	= NULL;
		previousSnarfHandleP	= NULL;
		/* View object links it in */

	} else {
		if (snarfHandleType == WRITE_HANDLE) {
			if (!viewP->isWriteView()) {
				snarfHandleType	=
					SNARF_HANDLE_CONSTRUCTOR_FAILED;
				BLAST(NOT_WRITE_VIEW);
			}
			if (viewP->urdiP->writableSnarfs >=
			    viewP->urdiP->usableStages()) {
				snarfHandleType	=
					SNARF_HANDLE_CONSTRUCTOR_FAILED;
				BLAST(URDI_JACKPOT);	// TOO_MANY_SNARFS_CHANGED
			}
			viewP->urdiP->writableSnarfs++;
		}

		nextSnarfHandleP	= viewP->snarfHandleRoot;
		if (nextSnarfHandleP != NULL) {
			nextSnarfHandleP->previousSnarfHandleP	= this;
		}

		previousSnarfHandleP	= NULL;
		viewP->snarfHandleRoot	= this;
	}
	nextFrozenSnarfHandleP	= NULL;
	previousFrozenSnarfHandleP = NULL;
	isFrozen		= FALSE;	// Non-DUMMY will freeze later.

	if (snarfHandleType == DUMMY_HANDLE) {
		snarfCacheP	= NULL;
		dataSize	= 0;
		dataP		= NULL;

	} else if (snarfHandleType == WRITE_HANDLE) {	/* Getting blank snarf */
		CONSTRUCT_ON(PERSISTENT,snarfCacheP,SnarfCache,(DATA_CACHE, viewP->urdiP));
		snarfCacheP->grabbing();
		dataSize	= snarfCacheP->getBlank(snarfID);
		(void)getDataP();	// (calls snarfCacheP->freezing() and stores dataP)

		{			// Spray with "DEAD"
			long	i;
			for (i=0; i<dataSize; i++) {
				dataP[i] = !(i&1) ? 0xDE : 0xAD;
			}
		}

		snarfCacheP->linkBefore(viewP->urdiP->snarfCacheRoot);

	} else if (snarfHandleType == READ_HANDLE) {
		snarfCacheP	= viewP->findInCache(snarfID);
		if (snarfCacheP == NULL) {
			snarfCacheP = viewP->urdiP->extractFromLRU(snarfID);
			if (snarfCacheP != NULL) {
				viewP->urdiP->myLRUHits++;
				snarfCacheP->linkBefore(viewP->urdiP->
					snarfCacheGoatP->nextSnarfCacheP);
			} else {
				viewP->urdiP->myLRUMisses++;
			}
		}
		if (snarfCacheP != NULL) {
			snarfCacheP->grabbing();
			dataSize	= snarfCacheP->getDataSize();
			(void)getDataP();	// (calls snarfCacheP->freezing() and stores dataP)
		} else {
			CONSTRUCT_ON(PERSISTENT,snarfCacheP,SnarfCache,(DATA_CACHE, viewP->urdiP));
			snarfCacheP->grabbing();
			dataSize	= snarfCacheP->getCloset(snarfID);
			(void)getDataP();	// (calls snarfCacheP->freezing() and stores dataP)
			snarfCacheP->linkBefore(viewP->urdiP->snarfCacheGoatP->nextSnarfCacheP);
		}
	}
#ifdef HIGHC_DEBUG
cerr << "SnarfHandle::SnarfHandle\n" << this;
#endif
}

void SnarfHandle::
destruct ()
{
#ifdef HIGHC_DEBUG
cerr << "SnarfHandle::destruct\n" << this;
#endif
////	if (something not right) {
////		BLAST(gripe);
////	}

	if (snarfHandleType == SNARF_HANDLE_CONSTRUCTOR_FAILED) {
		return;
	}

	if (isFrozen) {
		(void)this->thaw();
	}

	if (snarfHandleType != DUMMY_HANDLE) {
		snarfCacheP->dropping();
	}

	if (nextSnarfHandleP != NULL) {
		nextSnarfHandleP->previousSnarfHandleP = previousSnarfHandleP;
	}
	if (previousSnarfHandleP == NULL) {
		viewP->snarfHandleRoot			= nextSnarfHandleP;
	} else {
		previousSnarfHandleP->nextSnarfHandleP = nextSnarfHandleP;
	}

	this->Heaper::destruct ();
}
/*^L*//* ========================================================================== */
//
//	printOn(ostream& oo)
//
/* ========================================================================== */

void SnarfHandle::
printOn(ostream& oo)
{
	oo << canPtr((void *)this)	<< ": SnarfHandle object\n";

	oo << "\tviewP:\t\t\t-> "
	   << canPtr((void *)viewP)	<< "\n";
	oo << "\tnextSnarfHandleP:\t-> "
	   << canPtr((void *)nextSnarfHandleP) << "\n";
	oo << "\tpreviousSnarfHandleP:\t-> "
	   << canPtr((void *)previousSnarfHandleP) << "\n";
	oo << "\tnextFrozenSnarfHandleP:\t-> "
	   << canPtr((void *)nextFrozenSnarfHandleP) << "\n";
	oo << "\tpreviousFrozenSnarfHandleP:\t-> "
	   << canPtr((void *)previousFrozenSnarfHandleP) << "\n";
	oo << "\tsnarfCacheP:\t\t-> "
	   << canPtr((void *)snarfCacheP)	<< "\n";
	oo << "\tsnarfHandleType:\t"	<< (
			snarfHandleType == WRITE_HANDLE	? "WRITE_HANDLE\n" :
			snarfHandleType == READ_HANDLE	? "READ_HANDLE\n" :
			snarfHandleType == DUMMY_HANDLE	? "DUMMY_HANDLE\n" :
			"UNKNOWN_HANDLE_TYPE\n"
	);
	oo << "\tsnarfID:\t\t"		<< snarfID			<< "\n";
	oo << "\tisFrozen:\t\t"		<< (isFrozen ? "TRUE":"FALSE")	<< "\n";
	oo << "\tdataSize:\t\t"		<< dataSize			<< "\n";
	oo << "\tdataP:\t\t\t-> ";
		if (!dataP) {
			oo << "NULL\n";
		} else {
			oo << "&" << canPtr((void *)((char *)dataP - sizeof(struct SnarfHeader)))
				<< "[" << sizeof(struct SnarfHeader) << "]\n";
		}

	oo << "\n";
}
/*^L*//* ========================================================================== */
//
//	makeWritable():  Change this read handle to a write handle on the
//			 same snarf.  To do this:
//
//	 - This must be a write view.
//	 - You must not already have a write handle on this snarf.
//	 - (It's OK to pass in a write handle.)
//
//	If you have other read handles on this snarf, they will remain read
//	handles on a separate, unchanging, copy of the snarf.
//
//	(!!!! Later:  If no other handles and not dirty, move, don't copy.)
//
/* ========================================================================== */

void SnarfHandle::
makeWritable()
{
#ifdef HIGHC_DEBUG
cerr << "SnarfHandle::makeWritable\n" << this;
#endif
	if (snarfHandleType != WRITE_HANDLE) {

		if (!viewP->isWriteView()) {
			BLAST(NOT_WRITE_VIEW);
		}

		if (viewP->urdiP->writingSnarf(snarfID)) {
			BLAST(ALREADY_WRITING_THIS_SNARF);
		}

		if (viewP->urdiP->writableSnarfs >=
		    viewP->urdiP->usableStages()) {
			BLAST(URDI_JACKPOT);	// TOO_MANY_SNARFS_CHANGED
		}
		viewP->urdiP->writableSnarfs++;

		snarfHandleType = WRITE_HANDLE;

		SnarfCache * tempSnarfCacheP;

		CONSTRUCT_ON(PERSISTENT,tempSnarfCacheP,SnarfCache,(DATA_CACHE, viewP->urdiP));
		tempSnarfCacheP->grabbing();
		tempSnarfCacheP->copy(snarfCacheP); /* Gets id from original */
		if (isFrozen) {
			dataP = tempSnarfCacheP->freezing();
		}
		tempSnarfCacheP->linkBefore(viewP->urdiP->snarfCacheRoot);

		if (isFrozen) {
			snarfCacheP->thawing();
		}
		snarfCacheP->dropping();

		snarfCacheP = tempSnarfCacheP;
	}
}
/* ========================================================================== */
//
//	isWritable():  Return true if this snarf is writable through this handle
//
/* ========================================================================== */

BooleanVar SnarfHandle::
isWritable()
{
	return (snarfHandleType == WRITE_HANDLE);
}
/*^L*//* ========================================================================== */
//
//	getDataSize():  Return the size (in bytes) of the snarf's data buffer.
//
/* ========================================================================== */

long SnarfHandle::
getDataSize()
{
	return dataSize;
}

/* ========================================================================== */
//
//	getDataP():  Return a pointer to the data buffer, and freeze it
//	             in place while we're hacking it.
//
//	Clients must freeze a handle by calling getDataP() before referencing
//	the data.  While the handle is frozen, the data is guaranteed to be
//	valid and unmoving.  (It's OK to freeze a handle that's already frozen.)
//
//	Clients thaw handles by calling the VIEW's member function
//	thawHandles().  This thaws all the handles in the view.
//	While a handle is thawed, the data buffer may be re-used for other
//	data, and the pointer may change.  Therefore:
//
//	NEVER use a copy of the data pointer while the handle is thawed!
//
//	(!!!! This is a hook for future versions.  We don't currently
//	 re-use the data buffer while the handle is thawed.)
//
//	(Clients may also thaw handles one-by-one.)
//
/* ========================================================================== */

UInt8 * SnarfHandle::
getDataP()
{
	if (!isFrozen) {

		nextFrozenSnarfHandleP	= viewP->frozenSnarfHandleRoot;
		if (nextFrozenSnarfHandleP != NULL) {
			nextFrozenSnarfHandleP->previousFrozenSnarfHandleP
				= this;
		}
		previousFrozenSnarfHandleP	= NULL;
		viewP->frozenSnarfHandleRoot	= this;

		dataP = snarfCacheP->freezing();
		isFrozen = TRUE;
	}
#ifdef HIGHC_DEBUG
cerr << "SnarfHandle::getDataP\n\t";
for (int i = 0; i < 16; i++) {
	cerr << hex << (int) ((UInt8 *) dataP)[i] << dec << (i < 15 ? " " : "\n");
}
cerr << this;
#endif
	return (UInt8 *) dataP;
}

/* ========================================================================== */
//
//	getSnarfID():  Return the ID of the snarf.  (Because it's there...)
//
/* ========================================================================== */

SnarfID SnarfHandle::
getSnarfID()
{
	return snarfID;
}
/*^L*//* ========================================================================== */
//
//	Byte-twiddling routines (To make things easier for Smalltalk... B-( )
//
//	put32():     Store four bytes at a particular location.
//	get32():     Store four bytes from a particular location.
//	moveBytes(): Move some bytes around.
//
/* ========================================================================== */

void SnarfHandle::
put32(UInt32 anIndex, UInt32 aWord)
{
	if (snarfHandleType != WRITE_HANDLE) {
		BLAST(NOT_WRITE_HANDLE);
	}
	if (!isFrozen) {			//// Take out later
		BLAST(HANDLE_NOT_FROZEN);
	}

	dataP[anIndex    ] = (unsigned char)((aWord >> 24) & 0xff);
	dataP[anIndex + 1] = (unsigned char)((aWord >> 16) & 0xff);
	dataP[anIndex + 2] = (unsigned char)((aWord >>  8) & 0xff);
	dataP[anIndex + 3] = (unsigned char)((aWord      ) & 0xff);
#ifdef HIGHC_DEBUG
cerr << "put32 (" << anIndex << ", " << aWord << ") = " << this->get32 (anIndex) << "\n";
#endif
}

UInt32 SnarfHandle::
get32(UInt32 anIndex)
{
	if (!isFrozen) {			//// Take out later
		BLAST(HANDLE_NOT_FROZEN);
	}

	return	  ((UInt32)((unsigned char)(dataP[anIndex    ])) << 24)
		| ((UInt32)((unsigned char)(dataP[anIndex + 1])) << 16)
		| ((UInt32)((unsigned char)(dataP[anIndex + 2])) <<  8)
		| ((UInt32)((unsigned char)(dataP[anIndex + 3]))      );
}

void SnarfHandle::
moveBytes(UInt32 aFrom, UInt32 aTo, UInt32 aCount)
{
	if (snarfHandleType != WRITE_HANDLE) {
		BLAST(NOT_WRITE_HANDLE);
	}
	if (!isFrozen) {			//// Take out later
		BLAST(HANDLE_NOT_FROZEN);
	}

	MEMMOVE(&dataP[aTo], &dataP[aFrom], (int)aCount);
}
/*^L*//* ========================================================================== */
//
//	thaw():  Thaw handle and unlink it from the frozen handles list.
//
//	(Currently only used by self and friends.)
//	(It's OK to thaw a thawed handle.)
//
/* ========================================================================== */

void SnarfHandle::
thaw()
{
#ifdef HIGHC_DEBUG
cerr << "SnarfHandle::thaw\n" << this;
#endif
	if (isFrozen) {
		isFrozen = FALSE;
		snarfCacheP->thawing();

		if (nextFrozenSnarfHandleP != NULL) {
			nextFrozenSnarfHandleP->previousFrozenSnarfHandleP
				= previousFrozenSnarfHandleP;
		}
		if (previousFrozenSnarfHandleP == NULL) {
			viewP->frozenSnarfHandleRoot = nextFrozenSnarfHandleP;
		} else {
			previousFrozenSnarfHandleP->nextFrozenSnarfHandleP
				= nextFrozenSnarfHandleP;
		}
	}
}
/*^L*//* ========================================================================== */
//
//	canPtr:  Convert pointer to cannonical form for printing.
//
//	Visible only to Urdi and urdi tester.  (As "canPtr", due to a #define)
//
//	(Should be moved to Heaper some day...)
//
/* ========================================================================== */

UInt32	urdiCanRef = 0xFFFFFFFF;

char *
urdiCanPtr(void * pointer, int columns /* =0 */)  /* Print canonical pointer */
{
	if (pointer == (char *)NULL) {
		return "NULL";
	} else {
		if (urdiCanRef == 0xFFFFFFFF) {
			urdiCanRef = sequenceNumber(pointer);
		}
		int result = (sequenceNumber(pointer) - urdiCanRef + 1);
#if defined(_MSC_VER) || defined(HIGHC)
		// knownBug: not concurrent
		// knownBug: ignores column parameter
		static char string[20];
		sprintf (string, "%d", result);
		return string;
#else
		return dec((sequenceNumber(pointer) - urdiCanRef + 1), columns);
#endif
	}
}
