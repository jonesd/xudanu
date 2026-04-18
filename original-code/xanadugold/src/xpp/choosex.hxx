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

#ifndef CHOOSE_HXX
#define CHOOSE_HXX

#include "tofux.hxx"

VERSION_ID(choosex_hxx,
	   "$Id: choosex.hxx,v 2.8 1992/09/13 05:45:57 eric Exp $")

/******* 

The prime purpose of the CHOOSE macros is to provide a way to turn run
time type information into compile time type information.  The
construct can be thought of as a type-based variant on "switch":

{
    BEGIN_CHOOSE (expr) {
	BEGIN_KIND(Foo, p) {
	   ... p ...;
        } END_KIND;
	KIND3(Bar,Baz,Zorch, q, {
	   ... q ...;
        });
	BEGIN_ISNULL {
	   ... ...;
        } END_ISNULL;
	BEGIN_OTHERS {
	   ... ...;
        } END_OTHERS;
    } END_CHOOSE;
}


CHOOSE is like "switch"; KIND and ISNULL are both like "case"; and
OTHERS is like "default:".  What the above construct means is:

KINDn macros take block arguments rather than using the BEGIN/END
convention since the code must be duplicated for each type given.

a) Evaluate "expr" (whose static type must be compatible with pointer
to Heaper).

b) If the resulting value is a kind of Foo, then evaluate the clause
body in a scope where the expression's value bound to the variable "p"
which is of type "Foo *" (not "WPTR(Foo)"!  See below).

b) If no earlier clauses took, then see if the expression's value is
either a kind of Bar, Baz, or Zorch.  If so, then evaluate the body
with q bound to the value.  q will be of type "X *" where X is the
*first* of the above three classes which the value was a kind of.  For
example, if the value is not a kind of Bar, but is a kind of Baz and a
kind of Zorch, then q will be declared as a "Baz *" and the rest of
clause body executed.  It is useless to list a subclass after it's
superclass.

c) If no earlier clauses took, then see if the expression's value is
NULL.  If so then evaluate the body.

d) If no earlier clauses took, then evaluate the body.  It is useless
for there to be any clauses after an OTHERS clause.

e) If no clause is taken, then (unlike switch) the construct BLASTs.
The presence of an OTHERS clause above will ensure not encountering
the implicit BLAST.  Therefore there is no need for the common C
practice of providing a "default:" clause to abort a buggy program for
encountering an unexpected case (the lack of which is a source of C
bugs).

As with "switch", "break;"s are scoped so it will break you out of the
closest enclosing CHOOSE (unless of course another break catching
construct intervenes--switch/for/while/do-while).  Unlike "switch",
"break;"s are unneeded to prevent falling through from one clause to
another.  (The "switch"-style fall through is surely one of the most
error prone parts of C programming.)

DANGER DANGER WARNING WARNING: To be purely type safe, we should have
insisted that the only class names which can be listed in a
KIND-clause are types (i.e., not classes which are NOT_A_TYPE).
However, this breaks a possibly common usage which is to dispatch on
the class (which is not necessarily a type) and do one thing in each
clause body.  As long as you only do one thing with the expression's
value you are still perfectly safe.  However, consider the following
code:

    BEGIN_CHOOSE(q) {
	KIND(Foo, p) {
	    q->florch();
	    p->blorch();
        } END_KIND;
    } END_CHOOSE;

The problem is that, although the object must have been a kind of Foo
when the clause body was entered, it may become a non-Foo in response
to the florch message.  Then any use of "p" is inherently dangerous
because we are lying to the compiler--we are telling it that "p" is
pointing to a valid kind of Foo when it isn't.  In particular, the
actual type of the object may not implement a blorch message, and the
vtable entry looked up may cause jump into never never land.

The actual safety rule should be that "p" should not be used in the
clause body other than in the first time-block.  By "time-block" I
mean the code falling between things like ";", "&&", "||", and ",",
i.e., those markers that guarantee that all effects which precede it
occur before all those things which succeed it.  There's a name for
this concept in the C language standard, but I can't remember it right
now.

What we will probably do *real soon* is change KIND and KINDn so the
use WPTRs and so are perfectly safe.  If needed we will introduce a
parallel set of UNSAFE_KIND and UNSAFE_KINDn macros which preserve the
current unsafe behavior.

********/

extern void unkindBlast (CONST char * argFileName, int argLineNumber);

#define BEGIN_CHOOSE(expr) {				\
    SPTR(Heaper) _DVAR;					\
    _DVAR = (expr);	       				\
    for (int _CI = 0; _CI++ > 0 ? (unkindBlast(__FILE__,__LINE__),0):1;) {

#define END_CHOOSE } }
      
#define BEGIN_KIND(catName,ptr)				\
    if (_DVAR != NULL &&				\
	_DVAR->isKindOf (CAT(cat_,catName))) {		\
	catName * ptr = (catName *) &* _DVAR;

#define END_KIND					\
	break;						\
    }

#define BEGIN_ISNULL					\
    if (_DVAR == NULL) {

#define END_ISNULL					\
	break;						\
    }

#define BEGIN_OTHERS {

#define END_OTHERS	break; }

#define KIND1(catName,ptr,body)				\
    if (_DVAR != NULL &&				\
	_DVAR->isKindOf (CAT(cat_,catName))) {		\
	catName * ptr = (catName *) &* _DVAR;		\
	{ body }					\
	break;						\
    }

#define KIND2(c1,c2,ptr,body)				\
    KIND1(c1,ptr,body)					\
    KIND1(c2,ptr,body)

#define KIND3(c1,c2,c3,ptr,body)			\
    KIND1(c1,ptr,body)					\
    KIND2(c2,c3,ptr,body)

#define KIND4(c1,c2,c3,c4,ptr,body)			\
    KIND1(c1,ptr,body)					\
    KIND3(c2,c3,c4,ptr,body)

#define KIND5(c1,c2,c3,c4,c5,ptr,body)			\
    KIND1(c1,ptr,body)					\
    KIND4(c2,c3,c4,c5,ptr,body)

#define KIND6(c1,c2,c3,c4,c5,c6,ptr,body)		\
    KIND1(c1,ptr,body)					\
    KIND5(c2,c3,c4,c5,c6,ptr,body)

#define KIND7(c1,c2,c3,c4,c5,c6,c7,ptr,body)		\
    KIND1(c1,ptr,body)					\
    KIND6(c2,c3,c4,c5,c6,c7,ptr,body)

#define KIND8(c1,c2,c3,c4,c5,c6,c7,c8,ptr,body)		\
    KIND1(c1,ptr,body)					\
    KIND7(c2,c3,c4,c5,c6,c7,c8,ptr,body)



#endif /* CHOOSE_HXX */
