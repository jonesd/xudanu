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
  =========================================================================
  |
  |         fluidt.hxx - Fluid Variables
  |
  ========================================================================= */
/*
	For now, tests involving the class Bar are disabled.  A new fluid type,
	a CLASS_FLUID will have to be written to accomodate them.
*/
#ifndef FLUIDT_HXX
#define FLUIDT_HXX
/* $Id: fluidt.hxx,v 2.6 1992/12/12 00:05:11 eric Exp $ */

#include "tofux.hxx"
#include "fluidx.hxx"

#include "fluidt.oxx"

class Foo : public Heaper {
    CONCRETE(Foo)
    NO_GC(Foo)
  public:
    Foo (int y);
    void printOn (ostream& oo);
  private:
    int x;
};

// class Bar is, in XPidgin terminology, a new Var class.  It is being
// defined here to test fluids, because fluids live at a lower level than
// most of the things they're used for, so trying to use more proper
// XPidgin would involve separately defining much of the higher levels just
// to support this test.
// XPidgin users are generally not supposed to be defining new Var classes,
// so please don't use the fluid test code as an example of good XPidgin form.

/*
class Bar ROOTCLASS {
 public:
    Bar (int y);
    Bar ();
    ~Bar ();
    void printOn (ostream& oo);
 private:
    int x;
};
*/

DESIGN_FLUID(Foo,p1);

DESIGN_PRIM_FLUID(int,i1);

DESIGN_PRIM_FLUID(float,f1);

//DESIGN_FLUID(Bar,b1);

DESIGN_FLUID(Foo,p2);

DESIGN_PRIM_FLUID(int,i2);

DESIGN_PRIM_FLUID(float,f2);


DESIGN_FLUID(Foo,sp2);

DESIGN_PRIM_FLUID(int,si2);

DESIGN_PRIM_FLUID(float,sf2);

//DESIGN_FLUID(Bar,sb2);

class TestSpace ROOTCLASS {
 public:
    void * fluidSpace ();
    void * fluidSpace (void * aSpace);
    TestSpace ();
    ~TestSpace ();
 private:
    void * mySpace;
 public:
    static TestSpace * Current;
};

class TestEmulsion : public Emulsion {

 public: /* static accessing */

    static Emulsion * get ();

 public: /* accessing */

    virtual void * fetchNewRawSpace (size_t ARG(size));

    virtual void * fetchOldRawSpace ();

 public: /* creation */

    TestEmulsion ();

 private:
    void * myDefaultSpace;

    static Emulsion * TheTestEmulsion;
};

#endif /* FLUIDT_HXX */
