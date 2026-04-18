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

static char intvart_cxx_id[] = "$Id: intvart.cxx,v 2.6 1993/02/15 23:53:23 eric Exp $";

#include "intvarx.hxx"
#include "initx.hxx"
#include "gchooksx.hxx"
#include <stream.h>

int main (int ac, char *av[])
{
    Int32 stackObj;
    StackExaminer::stackEnd (&stackObj);

    Initializer mainInit(ac,av);

    IntegerVar i = 3;

    cerr << i << " + " << 4 << " = " << i + 4 << "\n";
    cerr << i << " - " << 4 << " = " << i - 4 << "\n";
    cerr << i << " * " << 4 << " = " << i * 4 << "\n";

    IntegerVar j;

    WholeNumberVar * ip = &j;

    *ip = i + 4;

    cerr << *ip << "\n";

    for (IntegerVar k = 0; k < 10; k += 1) {
	cerr << k << " ";
    }
    cerr << "\n";
    return 0;
}
