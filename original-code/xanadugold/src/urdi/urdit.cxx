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
//			urdit.cxx
//
//		Test of URDI internal data structures.
//
//		By Michael McClary		1989
//
/* ========================================================================== */
//
//	Merging with dean:
//	 - Added t.hxx, t.sxx files
//	 - Changed getDataP to return UInt8*, not char*
//		- michael May  7 1991
//
//	Adding tests for:
//	 - SnarfHandle::isWritable()
//	 - SnarfHandle::getSnarfID();
//	 - urdi(,,,)
//	 - SnarfHandle::atPut4();
//	 - SnarfHandle::get4();
//	 - SnarfHandle::moveBytes();
//	 - Urdi{View}::getDataSizeOfSnarf()
//		- michael May 11 1991
//
//	Added initializer code to main() while chasing hiesenbug.
//		- michael Jun  4 PDT 1991
//
//	Added scoreboard of Lions/Tigers/Bears vs Christians
//		- michael Aug  5 1991
//
//	 - Added "PLUMBER" memory-leak sniffer stuff.  (Move to alloc later.)
//	 - Removed catch-everything shield so could use debuggers more easily.
//	 - Moved output from cout to cerr and eliminated flush() calls.
//	   (This keeps buffer-flush irregularities from interfering with
//	    debugging.)
//	 - Changed remaining CONSTRUCT_ONs to pseudo-constructor calls
//	 - Removed Pad object.  (Leftover from before canonical printing.)
//	 - Added an argument for passing LRU max to testing subroutines.
//	 - Added sub4() to properly test LRUs.
//		- michael Aug  5-17 1991
//
//	Added print of LRU hits/misses.
//		- michael Aug 23 1991
//
//	Reacked SNARF_FILL() macro with STR() for ANSI
//	Cleaned up #endif text ditto
//		- michael Sep 5 1991 (Merged Sep 16)
//
//	Fixed for extinct lions--tigers took them over. bears are also gone
//		- ech Mar 11 1992
//
//	Changed interface to match new types and translations:
//	  - atPut4  --> put32
//	  - get4    --> get32
//		- ech Apr 24, 1992
//
//    Added WAIT_CAST - a quick hack for sgi.
//            - michael Sep 5 1991
  
#define	REUSE

#ifdef        sgi
#define       WAIT_CAST       int *
#else /* sgi */
#define       WAIT_CAST       union wait *
#endif        /* sgi */

#include "urdit.hxx"
#include "urdit.sxx"

#include "initx.hxx"

#ifdef	USING_SNEFRU
error 'snefru must be put back'
//#include "snefrux.hxx"
#endif	/* USING_SNEFRU */

PROBLEM_LIST(SECOND_WRITE,1,(ATTEMPT_TO_OPEN_SECOND_WRITE_VIEW));
PROBLEM_LIST(DROP_HELD,1,(CANT_DROP_VIEW_WITH_HANDLES_HELD));

PROBLEM_LIST(INVALID_ID,1,(INVALID_SNARF_I_D));
PROBLEM_LIST(READ_SEEK,1,(ERROR_SEEKING_TO_READ_SNARF));
PROBLEM_LIST(READ_ERR,1,(URDI_ERROR_READING_SNARF));

PROBLEM_LIST(NOT_WRITE,1,(NOT_WRITE_HANDLE));
PROBLEM_LIST(NOT_FROZEN,1,(HANDLE_NOT_FROZEN));

C_DECL_BEGIN
	int 		getopt(int argc, char **argv, char * /*optstring*/);
	extern char *	optarg;
	extern int	optind, opterr;
C_DECL_END

#define SNARF_FILL(VIEW,HANDLE,ID)	{			\
	sprintf((char *)CAT(snarfHandleP,HANDLE)->getDataP(),	\
	"View "STR(VIEW)", Handle "STR(HANDLE)", I.D. "STR(ID)"\n");	\
}

/* ========================================================================== */

	Urdi *			urdi1;
////	Urdi *			urdi2;

#define	PATH_NAME1	"urdi.dat"

#define	TEST_NAME_1	"../urdi1.dat"
#define	TEST_NAME_2	"../urdi2.dat"
#define	TEST_NAME_3	"../urdi3.dat"

#define	TEST_SAVE_1	"../urdi1new.dat"
#define	TEST_SAVE_2	"../urdi2new.dat"
#define	TEST_SAVE_3	"../urdi3new.dat"

BooleanVar	filesMatch(char *, char *);
void		saveFile(char *, char *);
void		dumpBuff (ostream&, UInt8 *, long);

void	sub1(long);
void	sub2(long);
void	sub3(long);
void	sub4(long);
/* ========================================================================== */
//
//	Memory leak detection.
//
/* ========================================================================== */

UInt32	initialTigers		= 0;
UInt32	initialChristians	= 0;

void
scoreboard(char * aLabel) {

	cerr	<< aLabel
		<< "\n Christians: "	<< christians()	- initialChristians
		<< ", Tigers: "		<< tigers()	- initialTigers
		<< ", Oh, my: "		<<
			  (tigers()	- initialTigers)
			- (christians() - initialChristians)
		<< "\n";
}

void
initializeScoreboard()
{
	scoreboard("Handicap:");

	initialTigers	= tigers();
	initialChristians = christians();
}

/* ========================================================================== */
//
//	Memory leak display.
//
/* ========================================================================== */

#ifdef PLUMBER

static Queue *		thePersistentHeap;
static Queue *		lastUninterestingItem;

void
showAnAllocatedItem(char * aLabel, Queue* anItem)
{
	cerr	<< aLabel
		<< urdiCanPtr(anItem)
		<<   (urdiCanRef == 0xFFFFFFFF ? " absolute\n":" canonical\n");
}

void
showLeftovers()
{
	showAnAllocatedItem(
		  "Last uninteresting item is: "
		, lastUninterestingItem
	);
	showAnAllocatedItem(
		  "Persistent heap queuehead prints as: "
		, thePersistentHeap
	);

	Queue *	item = lastUninterestingItem;
	while (item = thePersistentHeap->next(item)) {

		showAnAllocatedItem(
			"Persistent item "
			, item
		);
	}
}

void
initializePlumber()
{
	Queue		aJunkQueuehead;
	static char *	boringP		= new char[2];

	lastUninterestingItem = (Queue*) TRUEHEADER(boringP);
	thePersistentHeap = aJunkQueuehead.next(lastUninterestingItem);

	showLeftovers();
}

#endif /* PLUMBER */
/* ========================================================================== */
//
//
//
/* ========================================================================== */

int main(int argc, char** argv)
{
	Initializer mainInit(argc, argv);
	char *	cmd[100];

#ifdef USING_SNEFRU
if (secureHash == NULL) {
	secureHash = new Snefru();
}
#endif /* USING_SNEFRU */

	cerr << "Testing URDI\n\n";

#ifdef PLUMBER
	initializePlumber();
#endif /* PLUMBER */
	initializeScoreboard();

	cerr << "Prove that file compare works:\n";
	cerr << "Files "     TEST_NAME_1    " and "    TEST_NAME_2
	     << ((filesMatch(TEST_NAME_1,              TEST_NAME_2)) ? "" : " dont")
	     << " match.\n\n";
	cerr << "Files "     TEST_NAME_1    " and "    TEST_NAME_1
	     << ((filesMatch(TEST_NAME_1,              TEST_NAME_1)) ? "" : " dont")
	     << " match.\n\n";

	cerr << "Create virgin file:\n\n";

	unlink(PATH_NAME1);

	sub1(0);
	cerr << "Files "     PATH_NAME1    " and "    TEST_NAME_1
	     << ((filesMatch(PATH_NAME1,              TEST_NAME_1)) ? "" : " dont")
	     << " match.\n\n";
	     saveFile(PATH_NAME1,              TEST_SAVE_1);

	sub2(0);
	cerr << "Files "     PATH_NAME1    " and "    TEST_NAME_2
	     << ((filesMatch(PATH_NAME1,              TEST_NAME_2)) ? "" : " dont")
	     << " match.\n\n";
	     saveFile(PATH_NAME1,              TEST_SAVE_2);

	sub2(0);
	cerr << "Files "     PATH_NAME1    " and "    TEST_NAME_3
	     << ((filesMatch(PATH_NAME1,              TEST_NAME_3)) ? "" : " dont")
	     << " match.\n\n";
	     saveFile(PATH_NAME1,              TEST_SAVE_3);

	sub3(0);

	sub4(0);

	sub4(3);

	cerr << "End of urdi test.\n\n";
	return 0;
}
/* ========================================================================== */
//
//
//
/* ========================================================================== */

BooleanVar
filesMatch(char * argPath1, char * argPath2)
{
	char	cmd[100];

	strcpy(cmd, "cmp -s ");
	strcat(cmd, argPath1);
	strcat(cmd, " ");
	strcat(cmd, argPath2);

	return (system(cmd) == 0);
}

void
saveFile(char * argPath1, char * argPath2)
{
	char	cmd[100];

	strcpy(cmd, "cp -p ");
	strcat(cmd, argPath1);
	strcat(cmd, " ");
	strcat(cmd, argPath2);

////	(void)system(cmd);
}
/* =========================================================================== */
//
//	Create an URDI file
//
/* =========================================================================== */

void
sub1(
    long	aLRUMax
) {
	const long		SNARF_SIZE		= 1024; /*!!!!*/
	const long		SNARF_COUNT		= 20;
	const long		STAGING_AREA_SIZE	= 5;
	const long		LARGEST_SNARF_ID	= 
					((SNARF_COUNT - STAGING_AREA_SIZE) -1);

	UrdiView *		viewP1;
	SnarfHandle *		snarfHandleP1;
	SnarfHandle *		snarfHandleP2;
	SnarfHandle *		snarfHandleP3;
	SnarfHandle *		snarfHandleP4;

  int i;
  i = fork();
  if (i == -1) {
  	BLAST(FORK_FAILED);
  } else if (i == 0) {

	scoreboard("Start of sub1():");
#ifdef PLUMBER
	showLeftovers();
#endif /* PLUMBER */

	urdi1 = urdi(PATH_NAME1
		   , SNARF_SIZE
		   , SNARF_COUNT
		   , STAGING_AREA_SIZE
		   , aLRUMax
	);

	viewP1 = urdi1->makeWriteView();

	cerr << "viewP1->getDataSizeOfSnarf(9) = "
	     <<  viewP1->getDataSizeOfSnarf(9) <<  "\n";

	snarfHandleP1 = viewP1->makeErasingHandle(2);
	cerr << "snarfHandleP1->getSnarfID() = "
	     <<  snarfHandleP1->getSnarfID() << "\n";

	snarfHandleP2 = viewP1->makeErasingHandle(3);
	snarfHandleP3 = viewP1->makeErasingHandle(4);
	snarfHandleP4 = viewP1->makeErasingHandle(5);
	viewP1->commitWrite();
	viewP1->becomeRead();
	snarfHandleP1->destroy ();
	snarfHandleP2->destroy ();
	snarfHandleP3->destroy ();
	snarfHandleP4->destroy ();
	viewP1->destroy ();
	urdi1->destroy ();

	scoreboard("End of sub1():");
#ifdef PLUMBER
	showLeftovers();
#endif /* PLUMBER */

 	exit(0);
  }
  (void)wait((WAIT_CAST)0);
}

/* =========================================================================== */

void
sub2(
    long	aLRUMax
) {
	UrdiView *		viewP1;
	UrdiView *		viewP2;
	UrdiView *		viewP3;
	UrdiView *		viewP4;
	UrdiView *		viewP5;
	UrdiView *		viewP6;
	UrdiView *		viewP7;
	UrdiView *		viewP8;

	SnarfHandle *		snarfHandleP1;
	SnarfHandle *		snarfHandleP2;
	SnarfHandle *		snarfHandleP3;
	SnarfHandle *		snarfHandleP4;
	SnarfHandle *		snarfHandleP5;
	SnarfHandle *		snarfHandleP7;
	SnarfHandle *		snarfHandleP8;
	SnarfHandle *		snarfHandleP9;
	SnarfHandle *		snarfHandleP10;
	SnarfHandle *		snarfHandleP11;
	SnarfHandle *		snarfHandleP12;
	SnarfHandle *		snarfHandleP13;
	SnarfHandle *		snarfHandleP14;
	SnarfHandle *		snarfHandleP15;

  int i;
  i = fork();
  if (i == -1) {
  	BLAST(FORK_FAILED);
  } else if (i == 0) {

	scoreboard("Start of sub2():");
#ifdef PLUMBER
	showLeftovers();
#endif /* PLUMBER */

	INSTALL_SHIELD(BOOBY_TRAPPING);

	urdi1 = urdi(PATH_NAME1, aLRUMax);

	cerr << "Got urdi1 open\n";
	cerr << "    urdi1->usableSnarfs() = " << urdi1->usableSnarfs() << "\n";
	cerr << "    urdi1->usableStages() = " << urdi1->usableStages() << "\n";
	cerr << "\n";

	cerr << urdi1;

////	cerr
////		<< "Deleting -> "
////		<< canPtr((char *)snarfCacheP1)
////		<< ", which returned -> "
////		<< canPtr((char *)snarfCacheP1->unlinkReturnSuccessorP())
////		<< "\n"
////	;

	viewP1 = urdi1->makeReadView();
	viewP2 = urdi1->makeReadView();
	viewP3 = urdi1->makeWriteView();

	cerr << "\f";
	cerr << "viewP2->isWriteView() = " << (viewP2->isWriteView()?"TRUE\n":"FALSE\n");
	cerr << "viewP3->isWriteView() = " << (viewP3->isWriteView()?"TRUE\n":"FALSE\n");
	cerr << "\n";

	cerr << urdi1;

	cerr << "Handle test.\n\n";
	cerr << "\fHandleOnReadSnarf():\n";

	snarfHandleP1 = viewP2->makeReadHandle(2);
	snarfHandleP2 = viewP2->makeReadHandle(2);
	snarfHandleP3 = viewP1->makeReadHandle(2);
	snarfHandleP4 = viewP2->makeReadHandle(4);
	snarfHandleP5 = viewP3->makeReadHandle(3);

	cerr << "Original stuff in snarf 3 = \n";
	dumpBuff (cerr, snarfHandleP5->getDataP(), snarfHandleP5->getDataSize());

	cerr << "Data size of snarf 3 = " << snarfHandleP5->getDataSize() << "\n";

	cerr << urdi1;

	cerr << "\fmakeWritable()\n";

	cerr << "snarfHandleP5->isWritable() = "
	     << (snarfHandleP5->isWritable() ? "TRUE\n" : "FALSE\n");

	snarfHandleP5->makeWritable();

	cerr << "snarfHandleP5->isWritable() = "
	     << (snarfHandleP5->isWritable() ? "TRUE\n" : "FALSE\n");

/**/	SNARF_FILL(3,5,3);
	cerr << "New      stuff in snarf 3 = \n";
	dumpBuff (cerr, snarfHandleP5->getDataP(), snarfHandleP5->getDataSize());
////	printf("New      stuff in snarf 3 = %s\n", ((char *)snarfHandleP5->getDataP()));

	cerr << urdi1;

	cerr << "\fHandleOnBlankSnarf()\n";

////	BOOBY_TRAP(INVALID_ID,EXPECTED_INVALID_SNARF_I_D,{
////		snarfHandleP7 = viewP3->makeErasingHandle(-1);
////	});
////	BOOBY_TRAP(INVALID_ID,EXPECTED_INVALID_SNARF_I_D,{
////		snarfHandleP7 = viewP3->makeErasingHandle(LARGEST_SNARF_ID +1);
////	});
	snarfHandleP7 = viewP3->makeErasingHandle(5);

	{
		UInt8 *	p = snarfHandleP7->getDataP();
		long	i;
		char	c;
		long	j = snarfHandleP7->getDataSize();
		for (i = 0; i<j; i++) {
#ifdef HIGHC
			cerr << hex << (c = p[i]) << dec;
#else
			cerr << hex(c = p[i], 2);
#endif
			cerr << (((i+1) != j && ((i+1)&0xf) != 0) ? " " : "\n");
		}
	}

	cerr << urdi1;

	cerr << "\fthawHandles()\n";
	viewP2->thawHandles();
	viewP2->thawHandles();

	cerr << urdi1;

	cerr << "\fgetDataP()\n";
	(void)snarfHandleP1->getDataP();
	(void)snarfHandleP2->getDataP();
	cerr
		<< "(long)snarfHandleP4->getDataP() returned ->";
		if (!snarfHandleP4->getDataP()) {
			cerr << "NULL\n";
		} else {
			cerr << "&" << canPtr(snarfHandleP4->getDataP()
			                      - sizeof(struct SnarfHeader))
			     << "[" << dec << sizeof(struct SnarfHeader) << "]\n";
		}
	cerr << urdi1;

	cerr << "\fcommitWrite()\n";
	viewP3->commitWrite();
	cerr << urdi1;

	cerr << "\fSecond WriteView()\n";
	BOOBY_TRAP(SECOND_WRITE,EXPECTED_ATTEMPT_TO_OPEN_SECOND_WRITE_VIEW,{
		viewP4 = urdi1->makeWriteView();
	});
	cerr << urdi1;

	cerr << "\fbecomeRead()\n";
	viewP3->becomeRead();
	cerr << urdi1;

	viewP4 = urdi1->makeWriteView();
	cerr << urdi1;

	BOOBY_TRAP(DROP_HELD,EXPECTED_CANT_DROP_VIEW_WITH_HANDLES_HELD,{
		viewP2->destroy ();
	});

	snarfHandleP1->destroy ();
	snarfHandleP2->destroy ();
	snarfHandleP3->destroy ();
	snarfHandleP4->destroy ();

	viewP2->destroy ();
	cerr << urdi1;
	snarfHandleP8 = viewP4->makeReadHandle(3);
	cerr << urdi1;
	snarfHandleP8->makeWritable();
////	SNARF_FILL(4,8,3);
	cerr << urdi1;
	snarfHandleP5->destroy ();
	cerr << urdi1;
	viewP1->destroy ();		// Write happens here.
	cerr << urdi1;

	snarfHandleP7->destroy ();
	cerr << urdi1;
	viewP4->commitWrite();
	cerr << urdi1;

	viewP5 = urdi1->makeReadView();
	snarfHandleP9 = viewP5->makeReadHandle(5);
	cerr << urdi1;

	viewP4->commitWrite();
	snarfHandleP10 = viewP4->makeReadHandle(3);

	cerr << "Combined test of aborted write and "
	     << "SnarfHandle::put32(), get32(), and moveBytes()\n\n";

	BOOBY_TRAP(NOT_WRITE,EXPECTED_NOT_WRITE_HANDLE,{
		snarfHandleP10->put32(2,0x01020304);
	});
	BOOBY_TRAP(NOT_WRITE,EXPECTED_NOT_WRITE_HANDLE,{
		snarfHandleP10->moveBytes(6,12,13);
	});

	snarfHandleP10->makeWritable();

	SNARF_FILL(4,10,3);
	cerr << urdi1;

// Throwing in a test of the snarf data-peeker-poker routines, since we're
// about to abort the write, anyhow.

	snarfHandleP10->put32(2,0x01020304);
	snarfHandleP10->moveBytes(6,12,13);

	dumpBuff (cerr, snarfHandleP10->getDataP(),
			snarfHandleP10->getDataSize());
	cerr << "\n";

	snarfHandleP10->moveBytes(7,2,13);

	dumpBuff (cerr, snarfHandleP10->getDataP(),
			snarfHandleP10->getDataSize());
	cerr << "\n";

	cerr << "snarfHandleP10->get32(2) = 0x" << hex
	     <<  snarfHandleP10->get32(2) << dec << "\n\n";

// Now back to our regularly-scheduled test.

	snarfHandleP10->destroy ();
	snarfHandleP8->destroy ();
	viewP4->abortWrite();
	viewP4->becomeRead();
	viewP4->destroy ();
	cerr << urdi1;

	viewP3->destroy ();
	cerr << urdi1;

// All this to test moving a snarf cache past the goat.

	viewP6 = urdi1->makeWriteView();
	snarfHandleP11 = viewP6->makeReadHandle(4);
	snarfHandleP11->makeWritable();
	SNARF_FILL(6,11,4);
	viewP6->commitWrite();
	viewP6->becomeRead();
	viewP7 = urdi1->makeReadView();
	snarfHandleP12 = viewP7->makeReadHandle(5);
	snarfHandleP11->destroy ();
	viewP6->destroy ();
	cerr << urdi1;

	snarfHandleP9->destroy ();
	viewP5->destroy ();
	cerr << urdi1;

	snarfHandleP12->destroy ();
	viewP7->destroy ();

	cerr << "End of handle test.\n\n";

// (Note that this doesn't get regression tested by the normal route of
//  writing data to stdout/stderr and comparing them to a reference.
//  Instead, a forked process compares the URDI file to a binary
//  reference and reports whether that matches.)

	viewP8 = urdi1->makeWriteView();
	snarfHandleP13 = viewP8->makeReadHandle(5);
	snarfHandleP14 = viewP8->makeReadHandle(3);
	snarfHandleP15 = viewP8->makeReadHandle(4);
	snarfHandleP13->makeWritable();
	snarfHandleP14->makeWritable();
	snarfHandleP15->makeWritable();

// Take advantage of the current state to test
// SnarfHandle::put32(), get32(), and moveBytes()
// by thawing the handles and seeing if the routines detect it.

	viewP8->thawHandles();

	BOOBY_TRAP(NOT_FROZEN,EXPECTED_HANDLE_NOT_FROZEN,{
		snarfHandleP13->put32(2,0x01020304);
	});
	BOOBY_TRAP(NOT_FROZEN,EXPECTED_HANDLE_NOT_FROZEN,{
		(void) snarfHandleP13->get32(2);
	});
	BOOBY_TRAP(NOT_FROZEN,EXPECTED_HANDLE_NOT_FROZEN,{
		snarfHandleP13->moveBytes(6,12,13);
	});

// end of thawed write handle detection test.

	viewP8->commitWrite();
	snarfHandleP13->destroy ();
	snarfHandleP14->destroy ();
	snarfHandleP15->destroy ();
	viewP8->destroy ();

	viewP8 = urdi1->makeWriteView();
	snarfHandleP13 = viewP8->makeReadHandle(5);
	snarfHandleP14 = viewP8->makeReadHandle(3);
	snarfHandleP13->makeWritable();
	snarfHandleP14->makeWritable();
	viewP8->commitWrite();
	snarfHandleP13->destroy ();
	snarfHandleP14->destroy ();
	viewP8->destroy ();

////	cerr << urdi2;

	urdi1->destroy ();
////	urdi2->destroy ();

	scoreboard("End of sub2():");
#ifdef PLUMBER
	showLeftovers();
#endif /* PLUMBER */

 	exit(0);
  }
  (void)wait((WAIT_CAST)0);
}

void
dumpBuff (ostream& oo, UInt8 * dataP, long dataSize)
{
#define	LINE_SIZE	16


	int		i;
	long		j = 0;
	UInt8 *		dataP2 = dataP;
	long		dataSize2 = dataSize;

	do {
#ifdef HIGHC
		oo << hex << j << dec << ": ";
#else
		oo << hex(j, 5) << ": ";
#endif

		for (i=0; i < LINE_SIZE; i++) {
			if (dataSize) {
				dataSize--;
				j++;
#ifdef HIGHC
				oo << hex << *dataP++ << dec;
#else
				oo << hex(*dataP++, 2);
#endif
			} else {
				oo << "  ";
			}
			oo << " ";
		}
		oo << "!";

		for (i=0; i < LINE_SIZE; i++) {
			if (dataSize2) {
				dataSize2--;
				if (*dataP2 >= ' ' && *dataP2 <= '~') {
					oo << (char) *dataP2;
				} else {
					oo << ".";
				}
				dataP2++;
			}
		}
		oo << "!\n";
	} while (dataSize);
}

/* ========================================================================== */
//
//	Test dean's shuffle bug.
//
/* ========================================================================== */

void
sub3(
    long	aLRUMax
) {
	UrdiView *		viewP1;
	SnarfHandle *		snarfHandleP1;
	SnarfHandle *		snarfHandleP2;

  int i;
  i = fork();
  if (i == -1) {
  	BLAST(FORK_FAILED);
  } else if (i == 0) {

	cerr << "Start of URDI shuffle-message test.\n";

	urdi1 = urdi(PATH_NAME1, aLRUMax);

	viewP1 = urdi1->makeWriteView();

	snarfHandleP1 = viewP1->makeErasingHandle(7);
	snarfHandleP2 = viewP1->makeReadHandle(7);
	snarfHandleP2->destroy ();
	snarfHandleP1->destroy ();

	viewP1->abortWrite();
	viewP1->becomeRead();
	viewP1->destroy ();
	urdi1->destroy ();

 	exit(0);
  }
  (void)wait((WAIT_CAST)0);

  cerr << "end of URDI shuffle-message test.\n";
}

/* ========================================================================== */
//
//	sub4():  Test LRU.
//
//	Called once with aLRUMax = 0 (Urdi should behave as if it had no LRU),
//	once with aLRUMax = 3 (to test the LRU routines).  Comments below
//	relate to the call with aLRUMax = 3.
//
//	(Caveat:  The comments at the end were added after the code was
//	 tested, and may be slightly in error.)
//
/* ========================================================================== */

void
sub4(
    long	aLRUMax
) {
	UrdiView *		viewP1;
	UrdiView *		viewP2;

	SnarfHandle *		snarfHandleP2;
	SnarfHandle *		snarfHandleP3;
	SnarfHandle *		snarfHandleP4;
	SnarfHandle *		snarfHandleP5;
	SnarfHandle *		snarfHandleP5a;
	SnarfHandle *		snarfHandleP4b;

  int i;
  i = fork();
  if (i == -1) {
  	BLAST(FORK_FAILED);
  } else if (i == 0) {

	scoreboard("Start of sub4():");
#ifdef PLUMBER
	showLeftovers();
#endif /* PLUMBER */

// Reopen an Urdi:  Also tests that the LRU is cleared of what gets put there
// during crash recovery.

	urdi1 = urdi(PATH_NAME1, aLRUMax);
	cerr << urdi1;

	viewP1 = urdi1->makeReadView();
	snarfHandleP2 = viewP1->makeReadHandle(2);
	snarfHandleP3 = viewP1->makeReadHandle(3);
	snarfHandleP4 = viewP1->makeReadHandle(4);
	snarfHandleP5 = viewP1->makeReadHandle(5);

	cerr << urdi1;

// Test putting SnarfCache objects on the LRU when handle is dropped, and
// overflowing it when too many are added.

	snarfHandleP2->destroy ();
	cerr << urdi1;

	snarfHandleP3->destroy ();
	cerr << urdi1;

	snarfHandleP4->destroy ();
	cerr << urdi1;

	snarfHandleP5->destroy ();
	cerr << urdi1;
	cerr << "Hits = " << urdi1->lRUHits()
	     << ", Misses = " << urdi1->lRUMisses()
	     << "\n";

// Test recovering SnarfCache objects from the LRU.  Order is changed, so
// it tests both extraction from the middle of, and beginning of, the LRU
// (which use different pieces of dequeueing code).

	snarfHandleP4 = viewP1->makeReadHandle(4);
	cerr << urdi1;

	snarfHandleP5 = viewP1->makeReadHandle(5);
	cerr << urdi1;

	snarfHandleP2 = viewP1->makeReadHandle(2);
	cerr << urdi1;

	snarfHandleP3 = viewP1->makeReadHandle(3);
	cerr << urdi1;

	snarfHandleP2->destroy ();
	snarfHandleP3->destroy ();
	snarfHandleP4->destroy ();
	snarfHandleP5->destroy ();

	viewP1->destroy ();
	cerr << urdi1;
	cerr << "Hits = " << urdi1->lRUHits()
	     << ", Misses = " << urdi1->lRUMisses()
	     << "\n";
//
// Now test whether items are saved correctly when changes are committed
// and the view is dropped.
//
	cerr << "\nMaking WriteView and three read handles on two snarfs.\n";

	viewP1 = urdi1->makeWriteView();
	snarfHandleP4 = viewP1->makeReadHandle(4);
	snarfHandleP5 = viewP1->makeReadHandle(5);
	snarfHandleP5a = viewP1->makeReadHandle(5);
	cerr << urdi1;
//
// Keep a read handle on one unmodified snarf and not on the other.  (This
// gets an unmodified copy at the head of the LRU to test the purging code.)
//
	cerr << "\nMaking two read handles writable.\n";

	snarfHandleP4->makeWritable();
	snarfHandleP5->makeWritable();
	cerr << urdi1;
//
// In this case when write is committed and the read handle is dropped,
// various state changes but the caches don't get reorganized.
//
	cerr << "\nCommitting write.\n";

	viewP1->commitWrite();
	cerr << urdi1;

	cerr << "\nDropping handles.\n";

	snarfHandleP4->destroy ();
	snarfHandleP5->destroy ();
	snarfHandleP5a->destroy ();
	cerr << urdi1;
//
// Get a new read view with a handle on one changed snarf, to be sure only
// unheld snarfs go to the LRU when the view is dropped.
//
	cerr << "\nMaking an additional read view and an additional handle.\n";

	viewP2 = urdi1->makeReadView();
	snarfHandleP4b = viewP2->makeReadHandle(4);
	cerr << urdi1;
//
// When we drop the write view, the modified snarf held by the second view goes
// to the active cache (is moved behind the goat) and the out-of-date version
// is purged from the LRU.
//
	cerr << "\nDropping the write view.\n";

	viewP1->destroy ();
	cerr << urdi1;
//
// Now we drop the read handle and the first snarf goes into the LRU.
//
// Then we drop the read view (which cleans the remaining modified
// snarf) and it, too, goes into the LRU, purging it of the out-of-date,
// unmodified version.
//
// Note that, in principle, the LRU could be purged earlier.
// This was easier to implement and debug.  Perhaps things should be
// improved later.
//
	cerr << "\nDropping read handle and read view.\n";

	snarfHandleP4b->destroy ();
	viewP2->destroy ();
	cerr << urdi1;
	cerr << "Hits = " << urdi1->lRUHits()
	     << ", Misses = " << urdi1->lRUMisses()
	     << "\n";

// Delete the Urdi object and test that all allocated memory is freed.
// If the leak sniffing tools are available, identify any leaked objects.

	cerr << "\nDeleting the Urdi.\n";

	urdi1->destroy ();

	scoreboard("End of sub4():");
#ifdef PLUMBER
	showLeftovers();
#endif /* PLUMBER */

 	exit(0);
  }
  (void)wait((WAIT_CAST)0);
}
