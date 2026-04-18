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

#ifndef CHOOSET_HXX
#define CHOOSET_HXX
static char chooset_hxx_id[] = "$Id: chooset.hxx,v 2.2 1992/08/14 22:07:06 shap Exp $";

#include "tofux.hxx"

#include "chooset.oxx"

CLASS(Foo,Heaper) {
    CONCRETE(Foo)
    AUTO_GC(Foo)
    EQ(Foo)
  public:
    LEAF void zip ();
    LEAF void zap (Foo *);
    Foo();
};

CLASS(Bar,Heaper) {
    CONCRETE(Bar)
    AUTO_GC(Bar)
    EQ(Bar)
  public:
    virtual void zip ();
    LEAF void zap (Foo *);
    LEAF void zap (Bar *);
    Bar();
};


CLASS(Baz,Heaper) {
    CONCRETE(Baz)
    AUTO_GC(Baz)
    EQ(Baz)
  public:
    LEAF void zip ();
    LEAF void zap (Foo *);
    LEAF void zap (Bar *);
    LEAF void zap (Baz *);
    Baz();
};

#endif /* CHOOSET_HXX */
