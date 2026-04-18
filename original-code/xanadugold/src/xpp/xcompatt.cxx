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
//    Added cerr.flush() because (at one time) SGI didn't do it automagically.
//            - michael (Merged Mar 24 1992)

static char xcompatt_cxx_id[]
	= "$Id: xcompatt.cxx,v 2.5 1993/01/05 17:29:57 ravi Exp $";

#include <stream.h>
#include <setjmp.h>
#include "xcompatx.hxx"

#define STR2(x) STR(x)

#define FOO_BAR CAT(foo,bar)

void jumpTest (jmp_buf env)
{
    longjmp (env, 3);
}

void volatileTest ()
{
    jmp_buf env;
    VOLATILE(int,i,17);

    cerr << "#1: i == " << i << "\n";
    if (! setjmp (env)) {
	i = 42;
	cerr << "#2: i == " << i << "\n";
	jumpTest (env);
    }
    cerr << "#3: i == " << i << "\n";
}    



int XU_MAIN (int, char *av[]) 
{
     cerr << STR(CAT(foo,bar)) << "\n";
     cerr << STR2(CAT(foo,bar)) << "\n";
     cerr << STR2(FOO_BAR) << "\n";
     cerr << CAT(a,v)[0] << "\n";
     cerr << STR_CAT(foo,bar) << "\n";
     volatileTest ();
     cerr.flush();	// SGI doesn't do it automagically
     return 0;
}
