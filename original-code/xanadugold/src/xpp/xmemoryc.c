static char xmemoryc_cxx_rcsid[] = "$Id: xmemoryc.c,v 2.3 1992/08/14 22:12:43 shap Exp $";

#include "xmemoryc.h"

void copyWords (dest, src, nWords)
	UInt32 * dest;
	UInt32 * src;
	UInt32 nWords;
{
    while (nWords--) {
	*dest++ = *src++;
    }
}


void zeroWords (dest, nWords)
	UInt32 * dest;
	UInt32 nWords;
{
    while (nWords--) {
	*dest++ = 0;
    }
}
