/* ========================================================================== */
//
//	Copyright (c) 1991 by Xanadu Operating Company
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
//			garbaget.cxx
//
//      Garbage Collector Test
//
/* ========================================================================== */

/* $Id: garbaget.cxx,v 2.7 1993/02/15 23:53:14 eric Exp $ */

#include <stream.h>
#include "garbaget.hxx"
#include "garbaget.ixx"

#include "allocx.hxx"
#include "initx.hxx"
#include "gchooksx.hxx"

#include "garbaget.sxx"

#define TEST(expr) { cerr << STR(expr) << " == " << (expr) << "\n"; }

PROBLEM_LIST(HICCUP,1,(HICCUP));

void sub1();

//
//  Note that this is NOT a complete set of tests.  It tests only the
//  fix of the SPTR()s disappear during BLAST()ing bug.
//  More tests must be added!!!!
//

int XU_MAIN (int ac, char *av[]) 
{
    Int32 stackObj;
    StackExaminer::stackEnd (&stackObj);

    Initializer mainInit(ac,av);

    cerr << "Testing garbage collector.\n";
    cerr << "\nInitialization complete\n";

    sub1();

    cerr << "End of GC tests.\n";
    return 0;
}

void sub1()
{
    cerr << "\nsub1():  Are SPTR()s still visible during BLAST()s?\n";

    SPTR(ConsCell) consCellP;

    CONSTRUCT(consCellP,ConsCell,(NULL,NULL));
    TEST(consCellP);

    INSTALL_LOUD_SHIELD(BOOBY_TRAPPING);

    BOOBY_TRAP_BEGIN(HICCUP,DIDNT_HICCUP) {

	PLANT_BOMB(gc,gc);
	ARM_BOMB(gc,-1);

	BLAST(HICCUP);
    } BOOBY_TRAP_END();

    gcOpportunity(-1);

    TEST(consCellP);
}
