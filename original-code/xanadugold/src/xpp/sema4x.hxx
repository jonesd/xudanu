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
//	Fixed to use SPTR macro on return.
//		- michael Jun 29 1991 (Touched merging Jul 22 1991)
//
//	Spun off sema4x.ixx while going to ORDER/BUILD_BOMB.
//		- michael Mar 11 1992

#ifndef SEMA4X_HXX
#define SEMA4X_HXX

/* $Id: sema4x.hxx,v 2.9 1992/12/19 00:53:27 ravi Exp $ */

#include "tofux.hxx"
#include "intvarx.hxx"

#include "sema4x.oxx"

class Sema4 : public Heaper {
    CONCRETE(Sema4)
    NO_GC(Sema4)
    EQ(Sema4)
  public:
    LEAF void       v (); /* signal */
    LEAF void       p (); /* wait */
    LEAF IntegerVar t (); /* test */
      /* returns count before possibly decrementing.  Therefore the */
      /*  traditional t operation can just use the return value as a */
      /*  BooleanVar */

    Sema4 (IntegerVar initialCount, TCSJ);

    static RPTR(Sema4) make (IntegerVar initialCount);

  private:
    IntegerVar count;
};



ORDER_BOMB(mutex, Sema4 *);

#define MUTEX_BEGIN_WITH_EXPR(tag,sema4Expr)	\
   PLANT_BOMB(mutex,tag);			\
   (sema4Expr)->p();                   		\
   ARM_BOMB(tag,(sema4Expr))

#define MUTEX_BEGIN(sema4Name) MUTEX_BEGIN_WITH_EXPR(sema4Name,sema4Name)

#define MUTEX_END(tag)  DETONATE_BOMB(tag)


/**********
Used as in:

   {
      ...
      MUTEX_BEGIN(sema4Name);
      // critical section code 
      ...
      // optional: 
      MUTEX_END(sema4Name);
      ...
   }

If the MUTEX_END is left off, then the critical section lasts till the
end of the block.  Regardless, the critical section is always yielded
should we bail out of the block.  The Sema4 involved should be one which
has been initialized as "Sema4::make (1);", where the initial count 
indicates how many tasks are allowed in simultaneously (and will probably
always be 1).

sema4Name is being used both as an identifier for tagging the DETONATE_BOMB 
instance and as an expression of type "Sema4 *".  Accordingly, it should be
the name of a variable of type "Sema4 *" which points at the sema4 which
protects to resource of interest.  Where we use an object as a Tony Hoare 
style monitor, the object's state is itself the resource, and it's member 
functions are what aquires and releases it.  In these cases, we can expect 
code like this:

CLASS(Stack,Heaper) {
    CONCRETE(Stack)
    AUTO_GC(Stack)
  public:
    LEAF void push (Heaper * item)
      {
	  MUTEX_BEGIN(mutexSema4);
	  state = cons (item, state);
	  stackSize += 1;
      }
    LEAF Heaper * pop ()
      {
	  MUTEX_BEGIN(mutexSema4);
	  Heaper * result = state->first();
	  state = state->rest();
	  stackSize -= 1;
	  return result;
      }
    Stack ()
      {
	  mutexSema4 = Sema4::make (1);
	  state = list ();
	  stackSize = 0;
      }
  private:
    Sema4 * mutexSema4;
    OTuple * state;
    WholeNumberVar stackSize;
};

Notice what happens if we pop an empty stack.  The "state->first()"
expression raises an exception and we bail out.  On the way out
we yield our lock on the stack object.  Without the mutual exclusion,
multiple processes updating the same stack could easily cause "state"
and "stackSize" to get out of sync.

To actually do Tony Hoare style monitors would require more mechanism
(condition variables).  The above is adequate for our current code 
though.

****/


/*  CRITICAL_BLOCK
Execute the block iff no other critical block is currently
executing using the *same* Sema4.  Otherwise, wait until it's done
before executing (thereby excluding all others).  If multiple guys are
waiting for the same Sema4, we do not specify that they be resolved in
FiFo order, but we do specify starvation-freeness: that as long as
each critical-block execution takes finite time everyone will
eventually get their turn.  Mutual exclusion is yielded when the block
is exited, no matter whether the exit is normal or exceptional.

Note that the Sema4 must be initialized with a count of 1, as in:

	Sema4 * mutex = Sema4::make(1);

	...
	
	BEGIN_CRITICAL_BLOCK(mutex) {
		...
	} END_CRITICAL_BLOCK;

*/


#define BEGIN_CRITICAL_BLOCK(sema4Expr) {	\
    PLANT_BOMB(mutex,mutex);			\
    (sema4Expr)->p();				\
    ARM_BOMB(mutex,(sema4Expr));


#define END_CRITICAL_BLOCK    }

#ifdef USE_INLINE
#ifndef SEMA4X_IXX
#include "sema4x.ixx"
#endif /* SEMA4X_IXX */
#endif

#endif /* SEMA4X_HXX */
