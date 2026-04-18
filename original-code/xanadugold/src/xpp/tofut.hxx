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

#ifndef TOFUT_HXX
#define TOFUT_HXX
/* $Id: tofut.hxx,v 2.3 1992/11/25 23:27:06 eric Exp $ */

#include "tofux.hxx"
#include "tofut.oxx"

CLASS(Foo,Heaper) {
    CONCRETE(Foo)
    NO_GC(Foo)
    EQ(Foo)
  public:
    virtual void sendTest (ostream& o, int i);
    Foo ();
};

CLASS(Bar,Foo) {
    CONCRETE(Bar)
    NO_GC(Bar)
  public:
    Bar ();
};

CLASS(Baz,Foo) {
    CONCRETE(Baz)
    NO_GC(Baz)
  public:
    Baz ();
};

CLASS(Blaster,Heaper) {
    CONCRETE(Blaster)
    NO_GC(Blaster)
  public:
    LEAF void printOn (ostream& oo);
    Blaster (int i);
    virtual void destruct ();
    LEAF void destroy ();
  private:
    int myI;
};

#endif /* TOFUT_HXX */
