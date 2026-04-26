//
//	Added fastHash(UInt8[], count)
//		- michael Jul  5 1991 (Touched merging Jul 22 1991)

#ifndef FHASHX_HXX
#define FHASHX_HXX

#include "xcompatx.hxx"

extern unsigned long fastHash (char * string);
extern unsigned long fastHash (char * vector, int count);
extern unsigned long fastHash (unsigned long value);

#endif /* FHASHX_HXX */
