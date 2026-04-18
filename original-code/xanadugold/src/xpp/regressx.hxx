/*  (C) Copyright 1988, 89 by Xanadu Operating Company, All Rights Reserved.

    ****************************************************************
    *                                                              *
    *  The information contained herein is confidential,           *
    *  proprietary to Xanadu Operating Company, and considered     *
    *  a trade secret as defined in section 499C of the penal code *
    *  of the State of California.  Use of this information by     *
    *  anyone other than authorized employees of Xanadu is granted *
    *  only under a  written non-disclosure agreement, expressly   *
    *  prescribing the scope and  manner of such use.              *
    *                                                              *
    **************************************************************** */

static char regressx_hxx_rcsid[] = "$Id: regressx.hxx,v 2.2 1992/08/14 22:10:51 shap Exp $";

#include <stream.h>
#include "bombx.hxx"

#define TEST(expr) { cerr << STR(expr) << " == " << (expr) << "\n\n"; }

//#define BOOBY_TRAP( // Michael to fill in here ...
