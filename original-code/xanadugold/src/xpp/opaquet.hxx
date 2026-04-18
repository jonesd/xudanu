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
//	Touched while merging with alpha-14
//		- michael Jul 22 1991

#ifndef OPAQUET_HXX
#define OPAQUET_HXX
static char opaquet_hxx_id[] = "$Id: opaquet.hxx,v 2.3 1992/11/25 23:26:35 eric Exp $";

#include "tofux.hxx"
#include "opaquet.oxx"

CLASS(Foo,Heaper) {
	CONCRETE(Foo)
	NO_GC(Foo)
	EQ(Foo)
  public:
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

CLASS(EqualCoercionTester,Heaper) {
	CONCRETE(EqualCoercionTester)
	NO_GC(EqualCoercionTester)
	EQ(EqualCoercionTester)
  public:
	EqualCoercionTester(APTR(Foo), APTR(Bar), APTR(Baz));
	void		testCoercions(APTR(Foo), APTR(Bar), APTR(Baz));
  private:
	CHKPTR(Foo)	myFooP;
	CHKPTR(Bar)	myBarP;
	CHKPTR(Baz)	myBazP;
};

CLASS(DestroyItTester,Heaper) {
	CONCRETE(DestroyItTester)
	NO_GC(DestroyItTester)
	EQ(DestroyItTester)
  public:
	DestroyItTester(APTR(DestroyItTester));
	void		destroy();
  private:
	CHKPTR(DestroyItTester)	myDestroyItTesterP;
};

#endif /* OPAQUET_HXX */
