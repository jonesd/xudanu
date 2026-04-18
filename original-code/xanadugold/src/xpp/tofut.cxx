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
//	Moved init, arg, and opaqueCoercion tests to new opaquet.cxx
//		- michael Jul 12 1991 (Touched merging Jul 22 1991)
//
//	Added test that UnconstructedHeaper correctly covers the
//	problem of an argument expression to a constructor BLAST()ing
//		- michael Jul 21 1992

/* $Id: tofut.cxx,v 2.5 1993/02/15 23:53:48 eric Exp $ */

#include "tofux.hxx"
#include "tofut.hxx"
#include "initx.hxx"
#include "gchooksx.hxx"
PERMIT(N,"ALL")
#include <stream.h>
PERMIT(0,"ALL")

#include "tofut.sxx"

void Foo::sendTest (ostream& o, int i) {
    o << i;
}

Foo::Foo ()
{}

Bar::Bar ()
{}

Baz::Baz ()
{}


PROBLEM_LIST(CAST_PROBLEM,1,(UNSAFE_CAST));

void testCast()
{
	SPTR(Foo) fooP;
	SPTR(Bar) barP;
	SPTR(Baz) bazP;

	cerr << "\ntestCast(): Testing CAST()\n";

	CONSTRUCT(barP,Bar,());
	CONSTRUCT(bazP,Baz,());

	fooP = barP;

	cerr << "About to cast a Bar to a Bar\n";
	barP = CAST(Bar,fooP);

	cerr << "About to cast a NULL to a Bar\n";
	barP = CAST(Bar, NULL);

	cerr << "About to cast a Bar to a Baz (should fail)\n";
	INSTALL_SHIELD(CAST_SHIELD);
	SHIELD_UP(CAST_SHIELD, CAST_PROBLEM, {
	  		cerr << "Caught UNSAFE_CAST\n";
			SHIELD_RETURN(SHIELD_VOID);
		      }
		 );
	bazP = CAST(Baz,fooP);
}


void testIsKindOf()
{
  SPTR(Foo) fooP;

  cerr << "\ntestIsKindOf(): Testing isKindOf\n";

  CONSTRUCT(fooP,Bar,());
  if (!fooP->isKindOf(cat_Foo)) {
    BLAST(ISKINDOF_SUPERCLASS_FAILED);
  }
  if (!fooP->isKindOf(cat_Bar)) {
    BLAST(ISKINDOF_SAMECLASS_FAILED);
  }
  if (fooP->isKindOf(cat_Baz)) {
    BLAST(ISKINDOF_WRONG_CLASS_FAILED);
  }

  cerr << "\tAll isKindOf tests succeeded\n";
}

/* constructor bomb test (of heaper constructor bombs) */
/* No constructor bombs with stack conservative gc */

PROBLEM_LIST(I_IS_THREE_PROBLEM,1,(I_IS_THREE));


void Blaster::printOn (ostream& oo)
{
    oo << this->getCategory()->name() << "(" << myI << ")";
}

Blaster::Blaster (int i)
{
    myI = 0;
    if (i == 3) {
	BLAST(I_IS_THREE);
    }
    myI = i;
    cerr << "new " << this << "\n";
}

void Blaster::destruct ()
{
    cerr << "deleting " << this << "\n";
}

void Blaster::destroy ()
{
    cerr << "destroying " << this << "\n";
    this->Heaper::destroy ();
}

void sub7 ()
{
    SPTR(Blaster) b;
    CONSTRUCT(b,Blaster,(2));
    cerr << "made " << b << "\n";
    b->destroy ();
    b = NULL;
    INSTALL_SHIELD(I_IS_THREE_SHIELD);
    SHIELD_UP(I_IS_THREE_SHIELD, I_IS_THREE_PROBLEM, {
	cerr << "Caught I_IS_THREE in sub7\n";
	cerr << "b == " << b << "\n";
	SHIELD_RETURN(SHIELD_VOID);
    });
    CONSTRUCT(b,Blaster,(3));
}



/* pseudo-constructor */

RPTR(Heaper) blaster (int i)
{
    RETURN_CONSTRUCT(Blaster,(i));
}

void sub8 ()
{
    SPTR(Heaper) b;
    b = blaster (2);
    cerr << "made " << b << "\n";
    b->destroy ();
    b = NULL;
    INSTALL_SHIELD(I_IS_THREE_SHIELD);
    SHIELD_UP(I_IS_THREE_SHIELD, I_IS_THREE_PROBLEM, {
	cerr << "Caught I_IS_THREE in sub8\n";
	cerr << "b == " << b << "\n";
	SHIELD_RETURN(SHIELD_VOID);
    });
    b = blaster (3);
}

/* Test that things don't go down in flames when an argument to
 * a constructor BLAST()s.
 *
 * (Code in Heaper::operator new(... HeaperConstructor_Bomb ...)
 * constructs an UnconstructedHeaper in the storage, which correctly
 * handles the destroy() call that result from a BLAST() during evaluation
 * of arguments to the constructor.)
 *
 * Failure of this test will probably manifest as a core dump from a
 * dereference of an uninitialized vtable pointer.
 *
 * Note that this only tests the Heaper::operator new() that supports
 * (RETURN_)CONSTRUCT(), not the identical cfeature in
 * the support for (RETURN_)CONSTRUCT_ON()
 */

PROBLEM_LIST(EALRY_DESTROY_PROBLEM,1,(EALRY_DESTROY));

int earlyDestroy() {
	BLAST(EALRY_DESTROY);
	return 1;	// never reached.
}

RPTR(Heaper) earlyDestroyer()
{
    RETURN_CONSTRUCT(Blaster,(earlyDestroy()));
}

void sub9()
{
    SPTR(Heaper) b;

    cerr << "\nBeginning EALRY_DESTROY test.\n";

    INSTALL_SHIELD(EALRY_DESTROY_SHIELD);
    SHIELD_UP(EALRY_DESTROY_SHIELD, EALRY_DESTROY_PROBLEM, {
	cerr << "Caught EALRY_DESTROY\n";
	SHIELD_RETURN(SHIELD_VOID);
    });

    b = earlyDestroyer();

    cerr << "Missed catching EALRY_DESTROY.  That means problems with\n";
    cerr << "HeaperConstructor_Bomb and UnconsructedHeaper.\n";
}

int XU_MAIN (int ac, char *av[])
{
    Int32 stackObj;
    StackExaminer::stackEnd(&stackObj);

    Initializer mainInit(ac,av);

    SPTR(Foo) foo;
    CONSTRUCT(foo,Foo,());

    cerr << "three:";
    foo->sendTest (cerr, 3);
    cerr << "\n";
    cerr << foo << "\n";
    cerr << cat_Foo << "\n";

    testIsKindOf ();
    testCast ();
    sub7 ();
    sub8 ();
    sub9 ();

    return 0;
}
