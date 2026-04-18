/*
      (C) Copyright 1990 by Xanadu Operating Company, All Rights Reserved.

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

#ifndef INITT_HXX
#define INITT_HXX
static char initt_hxx_id[] = "$Id: initt.hxx,v 2.2 1992/08/14 22:08:36 shap Exp $";

#include "tofux.hxx"
#include "initt.oxx"

CLASS(InitTestingSuperclass,Heaper) {
    DEFERRED(InitTestingSuperclass)
    NO_GC(InitTestingSuperclass)
  public:
    InitTestingSuperclass ();
};      

CLASS(Foo,InitTestingSuperclass) {
    CONCRETE(Foo)
    NO_GC(Foo)
  public:
    Foo();
};

CLASS(Bar,InitTestingSuperclass) {
    CONCRETE(Bar)
    NO_GC(Bar)
  public:
    Bar();
};

CLASS(Bazz,InitTestingSuperclass) {
    CONCRETE(Bazz)
    NO_GC(Bazz)
  public:
    Bazz();
};

#endif /* INITT_HXX */
