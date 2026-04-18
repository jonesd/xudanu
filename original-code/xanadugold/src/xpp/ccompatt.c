/*
      (C) Copyright 1988, 89 by Xanadu Operating Company

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

static char ccompatt_c_id[] = "$Id: ccompatt.c,v 2.3 1992/12/19 00:53:02 ravi Exp $";

#include <stdio.h>
#include "ccompatc.h"

#define STR2(x) STR(x)

int main (ac, av)
     int ac;
     char *av[];
{
    fprintf (stderr, "%s\n", STR(CAT(foo,bar)));
    fprintf (stderr, "%s\n", STR2(CAT(foo,bar)));
    fprintf (stderr, "%s\n", CAT(a,v)[0]);
    return 0;
}
