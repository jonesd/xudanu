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
//			urdi3t.cxx
//
//		URDI loop for plug-pull test
//
//		By Michael McClary		1989
//
/* ========================================================================== */
//
//	Merging with dean:
//	 - Changed getDataP to return UInt8*, not char*
//		- michael May  7 1991
//
//	Removed shield ordering so obsolete stuff can be retired.
//	No check for other correctness.  (Merge by replacing with other fork.)
//		- michael Feb 27 1992

#define	REUSE

#include <stream.h>
#include <string.h>
#ifdef unix
#	include <sys/wait.h>
#	include <osfcn.h>
#endif
#include "urdix.hxx"
#include "urdip.hxx"

PROBLEM_LIST(Everything,1,(ALL_BUT));

PROBLEM_LIST(SECOND_WRITE,1,(ATTEMPT_TO_OPEN_SECOND_WRITE_VIEW));
PROBLEM_LIST(DROP_HELD,1,(CANT_DROP_VIEW_WITH_HANDLES_HELD));

PROBLEM_LIST(INVALID_ID,1,(INVALID_SNARF_I_D));
PROBLEM_LIST(READ_SEEK,1,(ERROR_SEEKING_TO_READ_SNARF));
PROBLEM_LIST(READ_ERR,1,(URDI_ERROR_READING_SNARF));

C_DECL_BEGIN
	int 		getopt(int argc, char **argv, char * /*optstring*/);
	extern char *	optarg;
	extern int	optind, opterr;
C_DECL_END

#define SNARF_FILL(VIEW,HANDLE,ID)	\
	sprintf(((char *)CAT(snarfHandleP,HANDLE)->getDataP()),	\
	"View VIEW, Handle HANDLE, I.D. ID\n");

/* =========================================================================== */

	Urdi *			urdi1;
	Urdi *			urdi2;

#define	PATH_NAME1	"/dev/sd0d"
#define	PATH_NAME2	"/dev/sd0e"
#define	PATH_NAME3	"/dev/sd0f"
#define	PATH_NAME4	"/dev/sd0h"

void	sub1();
////void	sub2();

main()
{
////	ofstream	junk("/dev/null");
////	ofstream	trash("/dev/null");	/* Just a quick hack... */
////	junk.close();				/* Free 3 for regression test */

	INSTALL_LOUD_SHIELD(All);
	SHIELD_UP(All,Everything,{
		cerr << "Caught it.\n";
		BLAST(BAIL_OUT);
	});

	cout << "URDI loop for plug-pull test\n\n";

	sync();
	sync();
	sync();

	sub1();
	cout << "Back from sub1\n\n";

////	for (;;) {
////		sub2();
////	}

	cout.flush();
	cerr.flush();
}

/* =========================================================================== */
//
//	Create an URDI partition
//
/* =========================================================================== */

void
sub1()
{
	UridView *		viewP1;
	UridView *		viewP3;

	SnarfHandle *		snarfHandleP1;
	SnarfHandle *		snarfHandleP2;
	SnarfHandle *		snarfHandleP3;
	SnarfHandle *		snarfHandleP4;
	SnarfHandle *		snarfHandleP5;

	SnarfID		max1;
	SnarfID		middle;
	SnarfID		low;
	SnarfID		high;

	cout << "Open first partition:\n\n";

	CONSTRUCT_ON(PERSISTENT,urdi1,Urdi,(
		  PATH_NAME1
		, tcsj
	));

////	cout << "Open second partition:\n\n";

////	CONSTRUCT_ON(PERSISTENT,urdi2,Urdi,(
////		  PATH_NAME2
////		, tcsj
////	));

	max1   = ((urdi1->usableSnarfs() - 1));
	middle = ((urdi1->usableSnarfs() - 1)/2);
	low    = ((urdi1->usableSnarfs() - 1)/4);
	high   = ((urdi1->usableSnarfs() - 1)/4)*3;
	cerr
		<< "low    = " << low
		<< ", middle = " << middle
		<< ", high   = " << high
		<< ", max1   = " << max1
	<< "\n";

		viewP1 = urdi1->makeWriteView();

		snarfHandleP1 = viewP1->makeErasingHandle(1);
		snarfHandleP2 = viewP1->makeErasingHandle(max1);
		snarfHandleP3 = viewP1->makeErasingHandle(low);
		snarfHandleP4 = viewP1->makeErasingHandle(high);
		snarfHandleP5 = viewP1->makeErasingHandle(middle);

		viewP1->commitWrite();
		viewP1->becomeRead();

		snarfHandleP1->destroy ();
		snarfHandleP2->destroy ();
		snarfHandleP3->destroy ();
		snarfHandleP4->destroy ();
		snarfHandleP5->destroy ();

		viewP1->destroy ();

	int i;
	for (;;) {

		viewP3 = urdi1->makeWriteView();

		snarfHandleP1 = viewP3->makeReadHandle(1);
		snarfHandleP1->makeWritable();
		snarfHandleP2 = viewP3->makeReadHandle(max1);
		snarfHandleP2->makeWritable();
		snarfHandleP3 = viewP3->makeReadHandle(low);
		snarfHandleP3->makeWritable();
		snarfHandleP4 = viewP3->makeReadHandle(high);
		snarfHandleP4->makeWritable();
		snarfHandleP5 = viewP3->makeReadHandle(middle);
		snarfHandleP5->makeWritable();

		viewP3->commitWrite();
		viewP3->becomeRead();

		snarfHandleP1->destroy ();
		snarfHandleP2->destroy ();
		snarfHandleP3->destroy ();
		snarfHandleP4->destroy ();
		snarfHandleP5->destroy ();
		viewP3->destroy ();

	}

	cout << "Close first partition:\n\n";
	urdi1->destroy ();
////	cout << "Close second partition:\n\n";
////	urdi2->destroy ();
}
