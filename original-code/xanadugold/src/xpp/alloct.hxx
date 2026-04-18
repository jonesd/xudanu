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

static char alloct_hxx_id[] = "$Id: alloct.hxx,v 2.2 1992/08/14 22:06:31 shap Exp $";

#include "tofux.hxx"

#include "alloct.oxx"

CLASS(Foo,Heaper) {
    CONCRETE(Foo)
    EQ(Foo)
    NO_GC(Foo)
  public:
    Foo() {}
    virtual void sendTest (ostream& o, int i);
};

