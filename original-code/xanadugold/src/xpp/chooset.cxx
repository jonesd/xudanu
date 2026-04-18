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
  ========================================================================= */
/* $Id: chooset.cxx,v 2.10 1993/02/15 23:53:00 eric Exp $ */

#include "choosex.hxx"
#include "chooset.hxx"
#include "initx.hxx"
#include "gchooksx.hxx"
#include <stream.h>

#include "chooset.sxx"


Foo::Foo ()
{ /* necessary 0-argument constructor, since we have subclasses */ }

void Foo::zip ()
{
    cerr << "Foo::zip()\n";
}

void Foo::zap (Foo *)
{
    cerr << "Foo zap Foo\n";
}


Bar::Bar ()
{ /* necessary 0-argument constructor, since we have subclasses */ }

void Bar::zip ()
{
    cerr << "Bar::zip()\n";
}

void Bar::zap (Foo *)
{
    cerr << "Bar zap Foo\n";
}

void Bar::zap (Bar *)
{
    cerr << "Bar zap Bar\n";
}


Baz::Baz ()
{ /* necessary 0-argument constructor, since we have subclasses */ }

void Baz::zip ()
{
    cerr << "Baz::zip()\n";
}

void Baz::zap (Foo *)
{
    cerr << "Baz zap Foo\n";
}

void Baz::zap (Bar *)
{
    cerr << "Baz zap Bar\n";
}

void Baz::zap (Baz *)
{
    cerr << "Baz zap Baz\n";
}



int XU_MAIN (int ac, char **av)
{
    Int32 stackObj;
    StackExaminer::stackEnd(&stackObj);
    Initializer mainInit(ac,av);

    const unsigned num = 4;
    Heaper * array [num];
    Heaper * temp;

    CONSTRUCT(temp,Foo,());
    array[0] = temp;
    CONSTRUCT(temp,Bar,());
    array[1] = temp;
    CONSTRUCT(temp,Baz,());
    array[2] = temp;
    array[3] = NULL;
    
    unsigned i;

    for (i = 0; i < num; i++) {
	BEGIN_CHOOSE(array[i]) {
	    BEGIN_KIND(Baz, p) {
		p->zap(p);
	    } END_KIND;
	    KIND2(Foo,Bar, p, {
		p->zip();
	    });
	    BEGIN_ISNULL {
		cerr << "it's NULL\n";
	    } END_ISNULL;
	} END_CHOOSE;
    }
    cerr << "\n";
    return 0;
}
