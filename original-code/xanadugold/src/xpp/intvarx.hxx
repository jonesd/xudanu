/*============================================================================
  |
  |   IntegerVar
  |
  ============================================================================

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
//	Grabbed for hacking.
//	Moved readHumber to tcxcvrp.hxx  (and copy in humberx.xxx for
//	future terse protocols).
//		- michael Jun 23 1990
//
//	Eliminated SELF_COPY
//		- michael Jun 28 1990
//
//	Merged changes from wjr's:  IntegerVar0, rounded().
//		- michael Jul 13 1990
//
//	Changed:
//	 - receiveIntegerVar() to a constructor (to be followed by assignment),
//	 - sendIntegerVar() to sendSelfTo()
//	to be consistent with rest of xcvr modularity.
//		- michael Sep 11 1990

#ifndef INTVAR_HXX
#define INTVAR_HXX

#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

VERSION_ID(intvarx_hxx,
	   "$Id: intvarx.hxx,v 2.6 1992/08/14 22:08:57 shap Exp $")

class ostream;

class IntegerVar ROOTCLASS {
  public:
/*    inline operator long ()
      {
	return longVal;
      }
    inline operator int ()
      {
	return (int) longVal;
      } */
    inline long asLong () CONST;
    inline int asInt () CONST;
    inline Int32 asInt32() { return (Int32) longVal; }
    inline UInt32 asUInt32() { return (UInt32) longVal; }

    /* Arithmetic */
    inline IntegerVar operator+ (IntegerVar other);
    inline IntegerVar operator- (IntegerVar other);
    inline IntegerVar operator- ();
    inline IntegerVar operator* (IntegerVar other);
    inline IntegerVar operator% (IntegerVar other);
    inline IntegerVar operator/ (IntegerVar other);
    
    /* Conditionals */
    inline BooleanVar operator< (IntegerVar other);
    inline BooleanVar operator== (IntegerVar other);
    inline BooleanVar operator> (IntegerVar other);
    inline BooleanVar operator<= (IntegerVar other);
    inline BooleanVar operator>= (IntegerVar other);
    inline BooleanVar operator!= (IntegerVar other);
    
    /* Assignment */
    inline IntegerVar operator+= (IntegerVar other);
    inline IntegerVar operator-= (IntegerVar other);
    inline IntegerVar operator*= (IntegerVar other);
    inline IntegerVar operator%= (IntegerVar other);
    
    /* Bit twiddling.  Negative numbers have an infinite number of preceding 1's */
    inline IntegerVar operator<< (IntegerVar other);
    inline IntegerVar operator>> (IntegerVar other);
    inline IntegerVar operator~ ();
    inline IntegerVar operator| (IntegerVar other);
    inline IntegerVar operator& (IntegerVar other);
    inline IntegerVar operator^ (IntegerVar other);
    
    /* Bit Twiddling Assignment */
    inline IntegerVar operator<<= (IntegerVar other);
    inline IntegerVar operator>>= (IntegerVar other);
    inline IntegerVar operator|= (IntegerVar other);
    inline IntegerVar operator&= (IntegerVar other);
    inline IntegerVar operator^= (IntegerVar other);

    /* Testing */
    UInt32 hashForEqual ();

    /* Initialization */
    inline IntegerVar ();
    inline IntegerVar (long val);

    friend ostream& operator<<(ostream& oo, IntegerVar i);

  /* SENDER: */
    void sendSelfTo (Xmtr * trans);

  /* RECEIVER: */
    IntegerVar (Rcvr * trans, TCSJ);

  private:
    long longVal;
};

typedef IntegerVar WholeNumberVar; /* Non-negative integer variable */

typedef WholeNumberVar NaturalNumberVar; /* Positive integer variable */

inline Int32 max(Int32, Int32);
inline Int32 min(Int32, Int32);
inline Int32 abs(Int32);

inline IntegerVar max(IntegerVar, IntegerVar);
inline IntegerVar min(IntegerVar, IntegerVar);
inline IntegerVar abs(IntegerVar);

#define IntegerVar0 IntegerVar(0)
#define IntegerVarZero IntegerVar(0)

inline IntegerVar rounded (IEEE64 x);

#ifndef INTVARX_IXX
#include "intvarx.ixx"
#endif /* INTVARX_IXX */

#endif /* INTVAR_HXX */
