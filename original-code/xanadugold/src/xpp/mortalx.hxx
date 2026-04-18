/*
      (C) Copyright 1988, 89 by Xanadu Operating Company, All Rights Reserved.

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
//
//	Spun off mortalx.ixx during change to ORDER/BUILD_BOMB_BEGIN/END form.
//		- michael Mar 11 1992

#ifndef MORTAL_HXX
#define MORTAL_HXX

/* $Id: mortalx.hxx,v 2.5 1992/12/19 09:50:42 eric Exp $ */

#include "tofux.hxx"

ORDER_BOMB(mortalDelete, Heaper*);

#define MORTAL(type,name,initializer)		\
       type* name = (initializer);		\
       SPTR(type) CAT(sptrTo_,name) = name;	\
       PLANT_BOMB(mortalDelete,name);          	\
       ARM_BOMB(name,name);

#define WIMPY_MORTAL(type,name,initializer)	\
       type* name = (initializer);		\
       PLANT_BOMB(mortalDelete,name);          	\
       ARM_BOMB(name,name);

/*********
Used as in:

   {
      MORTAL(Heaper, obj, somethingOrOther (...));
      ... obj ...
   }

This provides all the semantic costs of stack allocated objects, with 
all the run-time costs of heap allocated objects.  Actually, the point
is to create a heap allocated object whose lifetime is exactly as long 
as it would have been had it been stack allocated.  The reason not to 
simply stack allocate instead is that the storage space of the object
is dependent on its actual class, whereas the type given above is 
typically some compatable superclass.  When later optimizing the program,
code blocks like the above are good candidates to turn into stack 
allocation, given that one declares the union of all possible subclasses
in order to get enough storage.

Another cliche to consider is as follows:

   {
      MORTAL(Heaper, obj, somethingOrOther (...));
      ... obj ...
      DISARM_BOMB(obj);
      ... obj ...
   }

This says, "get rid of the object if we bail out during the first part,
but retain it even if we bail out during the second part."  Needless
to say, this would not be a candidate for turning into stack allocation.

**************/

#ifndef MORTALX_IXX
#include "mortalx.ixx"
#endif /* MORTALX_IXX */

#endif /* MORTAL_HXX */

