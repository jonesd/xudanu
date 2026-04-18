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
//			urdi2t.cxx
//
//	URDI partition initializer for plug-pull test
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

	cout << "URDI partition initializer for plug-pull test\n\n";

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
	const long		SNARF_SIZE		= 1024; /*!!!!*/
	const long		SNARF_COUNT		= 20;
	const long		STAGING_AREA_SIZE	= 10;
////	const long		LARGEST_SNARF_ID	= 
////					((SNARF_COUNT - STAGING_AREA_SIZE) -1);

////	UrdiView *		viewP1;
////	SnarfHandle *		snarfHandleP1;
////	SnarfHandle *		snarfHandleP2;
////	SnarfHandle *		snarfHandleP3;
////	SnarfHandle *		snarfHandleP4;

	cout << "Create first virgin partition:\n\n";

	CONSTRUCT_ON(PERSISTENT,urdi1,Urdi,(
		  PATH_NAME1
		, SNARF_SIZE
		, STAGING_AREA_SIZE
	));

////	cout << "Create second virgin partition:\n\n";

////	CONSTRUCT_ON(PERSISTENT,urdi2,Urdi,(
////		  PATH_NAME2
////		, SNARF_SIZE
////		, STAGING_AREA_SIZE
////	));

	cout << "Close first partition:\n\n";
	urdi1->destroy ();
////	cout << "Close second partition:\n\n";
////	urdi2->destroy ();
}
