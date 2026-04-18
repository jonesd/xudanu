/*
		Copyright 1990, Xanadu Operating Company, all rights reserved */
		

/* time - a class for a (slightly) system independent time */

#ifndef TIME_HXX
#define TIME_HXX
static char timex_hxx_ident[] = "$Id: timex.hxx,v 2.3 1992/08/14 22:04:22 shap Exp $";

#include <sys/types.h>
#include <sys/time.h>
#include "xcompatx.hxx"

class ostream;

class TimeVar;
INLINE TimeVar timeVar ();
INLINE TimeVar timeVar (TimeVar from);
INLINE TimeVar timeVar (timeval from);

class TimeVar  {
	public:
		INLINE TimeVar ();
		INLINE TimeVar (UInt32 sec, UInt32 usec);
		INLINE TimeVar difference (const TimeVar from);
		
		INLINE BooleanVar isEqual (const TimeVar to);
		INLINE BooleanVar isGreaterOrEqual (const TimeVar to);
		
		INLINE TimeVar operator= (TimeVar newTime);
		INLINE Int32 asLong ();
		
		void printOn (ostream& oo);

	private:  /* private constructor */
		INLINE TimeVar (timeval);
		friend TimeVar timeVar (timeval t);
		friend TimeVar timeVar (TimeVar t);
		
	private:
		timeval	timeInternal;
}; /* Time */

overload operator<<;
INLINE ostream& operator<< (ostream&, TimeVar t);

#ifdef USE_INLINE
#include "timex.ixx"
#endif /* USE_INLINE */

#endif /* TIME_HXX */
