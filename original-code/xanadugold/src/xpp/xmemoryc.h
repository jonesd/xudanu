#ifndef XMEMORYC_H
#define XMEMORYC_H

static char xmemoryc_h_rcsid[] = "$Id: xmemoryc.h,v 2.3 1992/08/14 22:12:45 shap Exp $";

#include "ccompatc.h"

C_DECL_BEGIN
	void copyWords (UInt32 * dest, UInt32 * src, UInt32 numWords);
	void zeroWords (UInt32 * dest, UInt32 numWords);
C_DECL_END

#endif /* xmemoryc.h */
