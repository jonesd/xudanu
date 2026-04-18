//
//	Added fastHash(UInt8[], count)
//		- michael Jul  5 1991 (Touched merging Jul 22 1991)

#ifndef FHASHX_HXX
#define FHASHX_HXX

#include "xcompatx.hxx"

VERSION_ID(fhashx_hxx,
	   "$Id: fhashx.hxx,v 2.5 1992/08/14 22:07:30 shap Exp $")

extern UInt32 fastHash (char * string);
extern UInt32 fastHash (UInt8 * vector, int count);
extern UInt32 fastHash (UInt32 value);
extern UInt32 fastFloatHash (IEEE64 value); // cannot overload with int

#endif /* FHASHX_HXX */
