/*
      (C) Copyright 1990 by Xanadu Operating Company, All Rights Reserved.

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
static char initt_cxx_id[] = "$Id: initt.cxx,v 2.6 1993/02/15 23:53:21 eric Exp $";

#include "initx.hxx"
#include "initt.hxx"
#include "gchooksx.hxx"
#include <stream.h>

#include "initt.sxx"

InitTestingSuperclass::InitTestingSuperclass ()
{ /* necessary 0-argument constructor, since we have subclasses */ }

Foo::Foo ()
{ /* necessary 0-argument constructor, since we have subclasses */ }

Bar::Bar ()
{ /* necessary 0-argument constructor, since we have subclasses */ }

Bazz::Bazz ()
{ /* necessary 0-argument constructor, since we have subclasses */ }

BEGIN_INIT_TIME(Foo,init1) {
    cerr << "init1\n";
} END_INIT_TIME(Foo,init1);

BEGIN_INIT_TIME(Bar,init2) {
    REQUIRES(Foo);
    cerr << "init2 (requires Foo)\n";
} END_INIT_TIME(Bar,init2);

BEGIN_INIT_TIME(Bar,init3) {
    REQUIRES(Foo);
    cerr << "init3 (requires Foo)\n";
} END_INIT_TIME(Bar,init3);

BEGIN_INIT_TIME(Foo,init4) {
    cerr << "init4\n";
} END_INIT_TIME(Foo,init4);

BEGIN_INIT_TIME(Bazz,init5_p) {
    cerr << "init5_p\n";
} END_INIT_TIME(Bazz,init5_p);

BEGIN_INIT_TIME(Bazz,init5_q) {
    cerr << "init5_q\n";
} END_INIT_TIME(Bazz,init5_q);

BEGIN_INIT_TIME(Foo,init6) {
    REQUIRES(Tofu);
    cerr << "init6 (requires Tofu)\n";
} END_INIT_TIME(Foo,init6);

BEGIN_INIT_TIME(Foo,init7) {
    REQUIRES(Bazz);
    cerr << "init7 (requires Bazz)\n";
} END_INIT_TIME(Foo,init7);

BEGIN_EXIT_TIME(Foo,exit1) {
    cerr << "exit1\n";
} END_EXIT_TIME(Foo,exit1);

BEGIN_EXIT_TIME(Foo,exit2) {
    cerr << "exit2\n"; 
} END_EXIT_TIME(Foo,exit2);

int XU_MAIN (int ac, char *av[]) 
{
    Int32 stackObj;
    StackExaminer::stackEnd (&stackObj);

    cerr << "\nstarting dynamic initialization\n\n";

    Initializer mainInit(ac,av);

    cerr << "\n\nin main\n\n";

    dumpInitState (cat_InitTestingSuperclass);

    return 0;
}
