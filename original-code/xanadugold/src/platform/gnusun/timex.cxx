/*
	Copyright 1990, Xanadu Operating Company, all rights reserved
*/

/* time - a class for a (slightly) system independent time */
static char timex_cxx_id[] = "$Id: timex.cxx,v 2.2 1992/08/14 22:04:21 shap Exp $";
#include <stream.h>
#include "timex.hxx"

#ifndef USE_INLINE
#include "timex.ixx"
#endif

void TimeVar::printOn (ostream& oo) {
	oo << "TimeVar(" << timeInternal.tv_sec << timeInternal.tv_usec << ")";
}


