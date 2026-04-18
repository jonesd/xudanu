/*
      (C) Copyright 1988, 89 by Xanadu Operating Company, All Rights Reserved.

******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
**************************************************************************** */
//
//	Added isKindOf() test to exercise all possibilities.
//		- ech Nov 2 1990
//
//	Created opaquet.* and moved the pointer-related tests from tofut.*
//	Added tests for == and != upgrade.
//		- michael (& markm) Jul 12-14 1991
//
//	Added test for destroyIt() method.
//		- michael Jul 15 1991
//
//	Touched while merging with alpha-14
//		- michael Jul 22 1991
static char opaquet_cxx_id[] = "$Id: opaquet.cxx,v 2.5 1993/02/15 23:53:26 eric Exp $";

#include "tofux.hxx"
#include "opaquet.hxx"
#include "initx.hxx"
#include "gchooksx.hxx"
PERMIT(N,"ALL")
#include <stream.h>
PERMIT(0,"ALL")

#include "opaquet.sxx"

Foo::Foo ()
{}

Bar::Bar ()
{}

Baz::Baz ()
{}


void initTest (GPTR(Bar) barP)
{
    cerr << "initTest\n";
    SPTR(Heaper) fooP = barP;
}

void argTest1 (APTR(Foo) /* fooP */)
{
    cerr << "argTest1\n";
}

void argTest2 (GPTR(Foo) /* fooP */)
{
    cerr << "argTest2\n";
}

RPTR(Foo) returnTest (GPTR(Bar) barP)
{
    cerr << "returnTest\n";
    return barP;
}

void testOpaqueCoercion ()
{
    SPTR(Bar) barP;
    CONSTRUCT(barP,Bar,());

    initTest (barP);
    argTest1 (barP);
    argTest2 (barP);
    returnTest (barP);
}	
/* ========================================================================== */
//
//	This section tests the == and != operators when used to compare two
//	instances of the Xanadu pointer types.
//
//	It is here more to see that the compiler doesn't refuse to generate
//	code than to test that the comparison actually does the right thing,
//	(though it DOES do a little of the latter).
//
//	(Given that the various operator definitions consist of reassuring
//	 the compiler that it's OK to do the same thing to several diverse
//	 types, it is hard to imagine what code the compiler could decide to
//	 generate that would do the WRONG thing, though computer programming
//	 IS continually surprising.  B-)   -michael )
//
/* ========================================================================== */

void testEqualEqualCoercion()
{
	SPTR(Foo) fooP;
	SPTR(Bar) barP;
	SPTR(Baz) bazP;
	SPTR(EqualCoercionTester) equalCoercionTesterP;

	CONSTRUCT(fooP,Foo,());
	CONSTRUCT(barP,Bar,());
	CONSTRUCT(bazP,Baz,());
	CONSTRUCT(equalCoercionTesterP,EqualCoercionTester,(fooP,barP,bazP));

	cerr << "\nTesting SPTR() and SPTR()/* == and !=\n\n";

	cerr << "fooP == fooP = "
	     << (fooP == fooP ? "TRUE" : "FALSE") << "\n";
	cerr << "fooP == barP = "
	     << (fooP == barP ? "TRUE" : "FALSE") << "\n";
	cerr << "barP == fooP = "
	     << (barP == fooP ? "TRUE" : "FALSE") << "\n";
	cerr << "barP == bazP = "
	     << (barP == bazP ? "TRUE" : "FALSE") << "\n";

	cerr << "(Foo *)fooP == fooP = "
	     << ((Foo *)fooP == fooP ? "TRUE" : "FALSE") << "\n";
	cerr << "(Foo *)fooP == barP = "
	     << ((Foo *)fooP == barP ? "TRUE" : "FALSE") << "\n";
	cerr << "(Bar *)barP == fooP = "
	     << ((Bar *)barP == fooP ? "TRUE" : "FALSE") << "\n";
	cerr << "(Bar *)barP == bazP = "
	     << ((Bar *)barP == bazP ? "TRUE" : "FALSE") << "\n";

	cerr << "fooP == (Foo *)fooP = "
	     << (fooP == (Foo *)fooP ? "TRUE" : "FALSE") << "\n";
	cerr << "fooP == (Bar *)barP = "
	     << (fooP == (Bar *)barP ? "TRUE" : "FALSE") << "\n";
	cerr << "barP == (Foo *)fooP = "
	     << (barP == (Foo *)fooP ? "TRUE" : "FALSE") << "\n";
	cerr << "barP == (Baz *)bazP = "
	     << (barP == (Baz *)bazP ? "TRUE" : "FALSE") << "\n";

	cerr << "(Foo *)fooP == (Foo *)fooP = "
	     << ((Foo *)fooP == (Foo *)fooP ? "TRUE" : "FALSE") << "\n";
	cerr << "(Foo *)fooP == (Bar *)barP = "
	     << ((Foo *)fooP == (Bar *)barP ? "TRUE" : "FALSE") << "\n";
	cerr << "(Bar *)barP == (Foo *)fooP = "
	     << ((Bar *)barP == (Foo *)fooP ? "TRUE" : "FALSE") << "\n";

	cerr << "(barP != fooP && barP == bazP) = "
	     << ((barP != fooP && barP == bazP) ? "TRUE" : "FALSE") << "\n";

	cerr << "NULL == fooP = "
	     << (NULL == fooP ? "TRUE" : "FALSE") << "\n";

	cerr << "barP == NULL = "
	     << (barP == NULL ? "TRUE" : "FALSE") << "\n";

	cerr << "NULL != fooP = "
	     << (NULL != fooP ? "TRUE" : "FALSE") << "\n";

	cerr << "barP != NULL = "
	     << (barP != NULL ? "TRUE" : "FALSE") << "\n";

	equalCoercionTesterP->testCoercions(fooP, barP, bazP);
}

EqualCoercionTester::
EqualCoercionTester(APTR(Foo) aFooP, APTR(Bar) aBarP, APTR(Baz) aBazP)
{
	myFooP = aFooP;
	myBarP = aBarP;
	myBazP = aBazP;
}

void EqualCoercionTester::
testCoercions(APTR(Foo) aFooP, APTR(Bar) aBarP, APTR(Baz) aBazP)
{
	SPTR(Foo)	fooP = aFooP;
	SPTR(Bar)	barP = aBarP;
	SPTR(Baz)	bazP = aBazP;

	cerr << "\nTesting SPTR()/CHKPTR() == and !=\n\n";

	cerr << "(barP != myFooP && myBarP == bazP) = "
	     << ((barP != myFooP && myBarP == bazP) ? "TRUE" : "FALSE") << "\n";
}

/* ========================================================================== */
//
//	This section tests the destoryIt() method of GPTR()s and CHKPTR()s
//
/* ========================================================================== */

void testDestroyIt()
{
	GPTR(DestroyItTester) destroyItTester1P;
	GPTR(DestroyItTester) destroyItTester2P;

	cerr << "\nTesting GPTR() and CHKPTR() destroyIt()\n\n";

	CONSTRUCT(destroyItTester1P,DestroyItTester,(NULL));
	CONSTRUCT(destroyItTester2P,DestroyItTester,(destroyItTester1P));

	cerr << "(destroyItTester1P == NULL) = "
	     << ((destroyItTester1P == NULL) ? "TRUE" : "FALSE")
	     << "\n";

	cerr << "(destroyItTester2P == NULL) = "
	     << ((destroyItTester2P == NULL) ? "TRUE" : "FALSE")
	     << "\n";

	destroyItTester1P = NULL;

	cerr << "(destroyItTester1P == NULL) = "
	     << ((destroyItTester1P == NULL) ? "TRUE" : "FALSE")
	     << "\n";

	cerr << "(destroyItTester2P == NULL) = "
	     << ((destroyItTester2P == NULL) ? "TRUE" : "FALSE")
	     << "\n";

	destroyItTester2P.destroyIt();

	cerr << "(destroyItTester1P == NULL) = "
	     << ((destroyItTester1P == NULL) ? "TRUE" : "FALSE")
	     << "\n";

	cerr << "(destroyItTester2P == NULL) = "
	     << ((destroyItTester2P == NULL) ? "TRUE" : "FALSE")
	     << "\n";
}

DestroyItTester::
DestroyItTester(APTR(DestroyItTester) aDestroyItTesterP)
{
	myDestroyItTesterP = aDestroyItTesterP;
}

void DestroyItTester::
destroy()
{
	cerr << "(myDestroyItTesterP == NULL) = "
	     << ((myDestroyItTesterP == NULL) ? "TRUE" : "FALSE")
	     << "\n";

	if (myDestroyItTesterP != NULL) {
		myDestroyItTesterP.destroyIt();

		cerr << "now (myDestroyItTesterP == NULL) = "
		     << ((myDestroyItTesterP == NULL) ? "TRUE" : "FALSE")
		     << "\n";
	}
}

int XU_MAIN (int ac, char *av[])
{
    Int32 stackObj;
    StackExaminer::stackEnd (&stackObj);

    Initializer mainInit(ac,av);
    SPTR(Foo) foo;
    CONSTRUCT(foo,Foo,());

    testEqualEqualCoercion();

    testDestroyIt();

    testOpaqueCoercion();
    return 0;
}
