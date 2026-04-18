/*
		Copyright 1990, Xanadu Operating Company, all rights reserved */
		

/* time - a class for a (slightly) system independent time */

/* This is a sun specific time module.  */
#ifndef TIMEX_IXX
#define TIMEX_IXX
static char timex_ixx_id[] = "$Id: timex.ixx,v 2.3 1992/08/14 22:04:23 shap Exp $";
#include "timex.hxx"

INLINE TimeVar::TimeVar () {
	gettimeofday(&timeInternal,0);
}

INLINE TimeVar::TimeVar (UInt32 secx,UInt32 usecx) {
	timeInternal.tv_usec = usecx;
	timeInternal.tv_sec = secx;
}

INLINE TimeVar::TimeVar (timeval start) {
	timeInternal = start;
}

INLINE TimeVar TimeVar::difference (const TimeVar from) {
	return TimeVar (timeInternal.tv_sec - from.timeInternal.tv_sec, timeInternal.tv_usec - from.timeInternal.tv_usec);
}

INLINE BooleanVar TimeVar::isEqual (const TimeVar to) {
	return timeInternal.tv_sec == to.timeInternal.tv_sec&&timeInternal.tv_usec == to.timeInternal.tv_usec;
}

INLINE BooleanVar TimeVar::isGreaterOrEqual (const TimeVar to) {
	return timeInternal.tv_sec > to.timeInternal.tv_sec && timeInternal.tv_usec >= to.timeInternal.tv_usec;
}
INLINE TimeVar timeVar () {
	return TimeVar ();
}

INLINE TimeVar timeVar (TimeVar from) {
	return TimeVar ( from.timeInternal);
}
INLINE TimeVar timeVar (timeval from){
    return  TimeVar(from);
}
INLINE TimeVar TimeVar::operator= (TimeVar t) {
	timeInternal = t.timeInternal;
	return t;
}

INLINE Int32 TimeVar::asLong () {
	return timeInternal.tv_sec + timeInternal.tv_usec;
}

ostream& operator<< (ostream& oo, TimeVar t) {
	t.printOn (oo);
	return oo;
}

#endif TIME_IXX
