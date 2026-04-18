/*=========================================================================
  |
  |   Copyright (c) 1989 by Xanadu Operating Company, All Rights Reserved.
  |
  =========================================================================
  |
  | The information contained herein is confidential, proprietary to Xanadu
  | Operating Company, and considered a trade secret as defined in section
  | 499C of the penal code of the State of California.
  |
  | Use of this information by anyone other than authorized employees of
  | Xanadu is granted only under a written nondisclosure agreement,
  | expressly prescribing the scope and manner of such use.
  |
  | The above copyright notice is not to be construed as evidence of
  | publication or the intent to publish.
  |
  =========================================================================
  |
  |         fluidx.hxx - Fluid Variables
  |
  =========================================================================

	Added test for sessionEmulsion
		- ech,michael,dean	sep 23 1991

	Changed sessionEmulsion tests to listenerEmulsion. Session objects
	have been eliminated.
		- wjr 			jan 3 1992
*/
/* $Id: fluidt.cxx,v 2.11 1993/01/05 17:29:39 ravi Exp $ */

#include <stream.h>
#include <stdlib.h>
#include "tofux.hxx"
#include "fluidx.hxx"
#include "fluidt.hxx"
#include "initx.hxx"
#include "gchooksx.hxx"
#include "fluidt.sxx"
#include "allocx.hxx"

Foo::Foo (int y) 
{
    x = y; 
}

void Foo::printOn (ostream& oo)
{
    oo << "Foo(" << x << ")";
}

// See note about Bar in fluidt.hxx.  DON'T use the code involving the
// Bar type as an example of proper XPidgin form.
/*
Bar::Bar (int y)
{
    cerr << "Bar::Bar(" << y << ")\n";
    x = y;
}

Bar::Bar ()
{
    cerr << "Bar::Bar()\n";
    x = -7;
}

Bar::~Bar ()
{
    cerr << "Bar::~Bar(" << x << ")\n";
}

void Bar::printOn (ostream& oo)
{
    oo << "Bar(" << x << ")";
}

REQUIRE(3,"reference")
ostream& operator<< (ostream& oo, Bar & item)
{
    item.printOn (oo);
    return oo;
}
PERMIT(0,"reference")
*/
/* TestSpace */

TestSpace * TestSpace::Current = NULL;

void * TestSpace::fluidSpace (){
    return (char*) mySpace;
}

void * TestSpace::fluidSpace (void * aSpace){
    return mySpace = aSpace;
}

TestSpace::TestSpace () {
    mySpace = NULL;
}

TestSpace::~TestSpace () {
    TestSpace * saveSpace;

    if (mySpace != NULL) {
	saveSpace = Current;
	Current = this;
	TestEmulsion::get()->destructAll();
	Current = saveSpace;
    }
}

/* TestEmulsion */

Emulsion * TestEmulsion::TheTestEmulsion = NULL;

Emulsion * TestEmulsion::get () {
    if (TheTestEmulsion == NULL) {
	TheTestEmulsion = new TestEmulsion();
    }
    return TheTestEmulsion;
}

void * TestEmulsion::fetchNewRawSpace (size_t size) {
    if (TestSpace::Current == NULL) {
	return (myDefaultSpace = fcalloc (size, sizeof(char)));
    } else {
	return TestSpace::Current->fluidSpace(fcalloc (size, sizeof(char)));
    }
}

void * TestEmulsion::fetchOldRawSpace () {
    if (TestSpace::Current == NULL) {
	return myDefaultSpace;
    } else {
	return TestSpace::Current->fluidSpace();
    }
}

TestEmulsion::TestEmulsion () {
    myDefaultSpace = NULL;
}

BUILD_FLUID(Foo,p1,NULL,globalEmulsion());

BUILD_PRIM_FLUID(int,i1,0,globalEmulsion());

BUILD_PRIM_FLUID(float,f1,0.2,globalEmulsion());

//BUILD_FLUID(Bar,b1,1000,globalEmulsion());


DEFINE_FLUID(Foo,p2,globalEmulsion());

DEFINE_PRIM_FLUID(int,i2,globalEmulsion());

DEFINE_PRIM_FLUID(float,f2,globalEmulsion());


BUILD_FLUID(Foo,sp2,NULL,TestEmulsion::get());

BUILD_PRIM_FLUID(int,si2,5,TestEmulsion::get());

BUILD_PRIM_FLUID(float,sf2,3.141,TestEmulsion::get());

//BUILD_FLUID(Bar,sb2,2000,TestEmulsion::get());

void printGlobalFluids ()
{
    cerr << "Global Fluids\n";		// Stay oriented

    cerr << "fluidFetch(p1) == " << p1.fluidFetch() << "\n";
    cerr << "fluidFetch(i1) == " << i1.fluidFetch() << "\n";
    cerr << "fluidFetch(f1) == " << f1.fluidFetch() << "\n";
//    cerr << "fluidFetch(b1) == " << b1.fluidFetch() << "\n";

    cerr << "fluidFetch(p2) == " << p2.fluidFetch() << "\n";
    cerr << "fluidFetch(i2) == " << i2.fluidFetch() << "\n";
    cerr << "fluidFetch(f2) == " << f2.fluidFetch() << "\n";
}

void globalFluidTest () {

    SPTR(Foo) p;

    CONSTRUCT(p,Foo,(3));

    FLUID_BIND(p2,NULL);
    FLUID_BIND(i2,0);
    FLUID_BIND(f2,0.2);
    printGlobalFluids ();
    {
	FLUID_BIND(f1, 1.3);
	FLUID_BIND(f2, 1.3);
	printGlobalFluids ();
	FLUID_BIND(p1, p);
	FLUID_BIND(p2, p);
	FLUID_BIND(i1, 1);
	FLUID_BIND(i2, 1);
	printGlobalFluids ();
	i1.fluidSet(2);
	i2.fluidSet(2);
	printGlobalFluids ();
    }
    printGlobalFluids ();
}


void setupTestSpaceFluids (int arg) {
    SPTR(Foo) p;

    CONSTRUCT(p,Foo,(arg * 10));	// Create an instance to point at
    sp2.fluidSet(p);			// Set the pointer var
    si2.fluidSet(arg * 10);		// Set the integer
    sf2.fluidSet(arg * 10.0);		// set the float
//    sb2.fluidSet(arg * 10000);		// Make a bar using one-arg constructor
    f2.fluidSet(arg * 10.0);		// Set a global (be sure they're global)
}

void printTestSpaceFluids (char * arg)
{
    cerr << "listener " << arg << "\n";	// So we can stay oriented

    cerr << "fluidFetch(sp2) == " << sp2.fluidFetch() << "\n";
    cerr << "fluidFetch(si2) == " << si2.fluidFetch() << "\n";
    cerr << "fluidFetch(sf2) == " << sf2.fluidFetch() << "\n";
//    cerr << "fluidFetch(sb2) == " << sb2.fluidFetch() << "\n";
    					// Print the twiddled global, too
    cerr << "fluidFetch(f2) == " << f2.fluidFetch() << "\n";
}


void spaceFluidTest () {

    TestSpace * space1;
    TestSpace * space2;

    TestSpace::Current = NULL;		// Be sure we're using the null space
    printTestSpaceFluids ("# 3");	// Print initial values
    setupTestSpaceFluids (3);		// Change them around
    printTestSpaceFluids ("# 3");	// See that they changed
    space1 = new TestSpace ();		// Create first space
    TestSpace::Current = space1;	// Switch to that.
    printTestSpaceFluids ("# 1");	// Print initial values
    setupTestSpaceFluids (1);		// Change them around
    printTestSpaceFluids ("# 1");	// See that they changed
    TestSpace::Current = NULL;		// Go look at the null space
    printTestSpaceFluids ("# 3");	// See that it didn't change
    setupTestSpaceFluids (4);		// Change the null space fluids
    printTestSpaceFluids ("# 4 was # 3"); // See that the did change
    space2 = new TestSpace ();		// Create second space
    TestSpace::Current = space2;	// Switch to that
    printTestSpaceFluids ("# 2");	// Look at initial values
    setupTestSpaceFluids (2);		// Change them around
    printTestSpaceFluids ("# 2");	// See that they changed
    TestSpace::Current = space1;	// Back to first
    printTestSpaceFluids ("# 1");	// See that they weren't changed by:
					//  - constructing second space
					//  - changing second or null space
    TestSpace::Current = NULL;		// Change back to null space
    printTestSpaceFluids ("# 4 was # 3"); // See that it wasn't trashed either.
    printGlobalFluids ();		// See that globals weren't trashed
    delete space1;			// Destroy the spaces, to see that
    delete space2;			// fluid var destructors get invoked
    printGlobalFluids ();		// See that globals still aren't trashed
}

int XU_MAIN (int ac, char **av)
{
    Int32 stackObj;
    StackExaminer::stackEnd (&stackObj);
    Initializer mainInit (ac,av);
    globalFluidTest ();
    spaceFluidTest ();
    return 0;
}
