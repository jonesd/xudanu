/*=========================================================================
  |
  |   Copyright (c) 1989 by Xanadu Operating Company, All Rights Reserved.
  |
  =========================================================================
  |
  | The information contained herein is confidential, proprietary to Xanadu
  | Operating Company, and considered a trade secret as defined in section
  | 499C of the penal code of the State of California.
  |
  | Use of this information by anyone other than authorized employees of
  | Xanadu is granted only under a written nondisclosure agreement,
  | expressly prescribing the scope and manner of such use.
  |
  | The above copyright notice is not to be construed as evidence of
  | publication or the intent to publish.
  |
  ========================================================================= */

static char ccompatc_c_rcsid[] = "$Id: ccompatc.c,v 2.2 1992/08/14 22:06:59 shap Exp $";

#include "ccompatc.h"


#define ALIGNMENT_MODULUS (sizeof (long))
/* the worst case alignment modulus of the current machine */



#ifdef PROTOTYPES_UNDERSTOOD
	unsigned long alignUp (unsigned long offset)
#else
	unsigned long alignUp (offset)
	  unsigned long offset;
#endif
{
    return ((offset + ALIGNMENT_MODULUS -1) / ALIGNMENT_MODULUS) 
      * ALIGNMENT_MODULUS;
}

#ifdef PROTOTYPES_UNDERSTOOD
	void doNothingWith (void * ptr)
#else
	void doNothingWith (ptr)
	  void * ptr;
#endif
{
}

