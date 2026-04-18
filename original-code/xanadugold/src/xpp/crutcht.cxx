/* $Id: crutcht.cxx,v 1.5 1993/02/15 23:53:03 eric Exp $ */

#include <stream.h>
#include "xcompatx.hxx"

void ok (int result, int expected)
{
    if (result == expected) {
	cerr << "good ";
    } else {
	cerr << "bad ";
    }
}

void testNot (int a, int expected)
{
    int result = ! a;
    ok (result, expected);
    cerr << "! " << a << "\n";

    if (! a) {
	ok (1, expected);
    } else {
	ok (0, expected);
    }
    cerr << "if ! " << a << "\n";
}

void notTest ()
{
    testNot (0, 1);
    testNot (1, 0);
}

void testAnd (int a, int b, int expected)
{
    int result = a && b;
    ok (result, expected);
    cerr << a << " && " << b << "\n";

    if (a && b) {
	ok (1, expected);
    } else {
	ok (0, expected);
    }
    cerr << "if " << a << " && " << b << "\n";
}

void testNotAnd (int a, int b, int expected)
{
    int result = !(a && b);
    ok (result, expected);
    cerr << "! ( " << a << " && " << b << " )\n";

    if (!(a && b)) {
	ok (1, expected);
    } else {
	ok (0, expected);
    }
    cerr << "if ! ( " << a << " && " << b << " )\n";
}

void andTest ()
{
    testAnd (1, 1, 1);
    testAnd (1, 0, 0);
    testAnd (0, 1, 0);
    testAnd (0, 0, 0);

    testNotAnd (1, 1, 0);
    testNotAnd (1, 0, 1);
    testNotAnd (0, 1, 1);
    testNotAnd (0, 0, 1);
}

void testOr (int a, int b, int expected)
{
    int result = a || b;
    ok (result, expected);
    cerr << a << " || " << b << "\n";

    if (a || b) {
	ok (1, expected);
    } else {
	ok (0, expected);
    }
    cerr << "if " << a << " || " << b << "\n";
}

void testNotOr (int a, int b, int expected)
{
    int result = !(a || b);
    ok (result, expected);
    cerr << "! ( " << a << " || " << b << " )\n";

    if (!(a || b)) {
	ok (1, expected);
    } else {
	ok (0, expected);
    }
    cerr << "if ! ( " << a << " || " << b << " )\n";
}

void orTest ()
{
    testOr (1, 1, 1);
    testOr (1, 0, 1);
    testOr (0, 1, 1);
    testOr (0, 0, 0);

    testNotOr (1, 1, 0);
    testNotOr (1, 0, 0);
    testNotOr (0, 1, 0);
    testNotOr (0, 0, 1);
}

void testAndOrLeft (int a, int b, int c, int expected)
{
    int result = a && b || c;
    ok (result, expected);
    cerr << a << " && " << b << " || " << c << "\n";

    if (a && b || c) {
	ok (1, expected);
    } else {
	ok (0, expected);
    }
    cerr << "if " << a << " && " << b << " || " << c << "\n";
}

void testAndOrRight (int a, int b, int c, int expected)
{
    int result = a && (b || c);
    ok (result, expected);
    cerr << a << " && ( " << b << " || " << c << " )\n";

    if (a && (b || c)) {
	ok (1, expected);
    } else {
	ok (0, expected);
    }
    cerr << "if " << a << " && ( " << b << " || " << c << " )\n";
}

void andOrTest ()
{
    /*      a && b || c      */
    testAndOrLeft (1, 1, 1, 1);
    testAndOrLeft (1, 1, 0, 1);
    testAndOrLeft (1, 0, 1, 1);
    testAndOrLeft (1, 0, 0, 0);
    testAndOrLeft (0, 1, 1, 1);
    testAndOrLeft (0, 1, 0, 0);
    testAndOrLeft (0, 0, 1, 1);
    testAndOrLeft (0, 0, 0, 0);

    /*     a && ( b || c )    */
    testAndOrRight (1, 1, 1, 1);
    testAndOrRight (1, 1, 0, 1);
    testAndOrRight (1, 0, 1, 1);
    testAndOrRight (1, 0, 0, 0);
    testAndOrRight (0, 1, 1, 0);
    testAndOrRight (0, 1, 0, 0);
    testAndOrRight (0, 0, 1, 0);
    testAndOrRight (0, 0, 0, 0);
}

void forTest ()
{
    cerr << "for ";
    for (int i = 0; i < 10; i++) {
	cerr << i << " ";
    }
    cerr << "\n";
}

int XU_MAIN (int, char**)
{
    notTest ();
    andTest ();
    orTest ();
    andOrTest ();
    forTest ();
    return 0;
}
