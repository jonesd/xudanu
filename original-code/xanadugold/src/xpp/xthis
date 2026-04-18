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


#ifndef INTVARX_IXX
#define INTVARX_IXX

VERSION_ID(intvarx_ixx,
	   "$Id: intvarx.ixx,v 2.5 1992/08/14 22:08:59 shap Exp $")

#define INTVAR_INLINES

inline IntegerVar::IntegerVar ()
{
    longVal = 0;
}

inline IntegerVar::IntegerVar (long val)
{
    longVal = val;
}

inline long IntegerVar::asLong () CONST
{
    return longVal;
}

inline int IntegerVar::asInt () CONST
{
    /* overflow check */
    return (int) longVal;
}

    /* Arithmetic */

inline IntegerVar IntegerVar::operator+ (IntegerVar other)
{
    return IntegerVar (longVal + other.longVal);
}

inline IntegerVar IntegerVar::operator- (IntegerVar other)
{
    return IntegerVar (longVal - other.longVal);
}

inline IntegerVar IntegerVar::operator- ()
{
    return IntegerVar (-longVal);
}

inline IntegerVar IntegerVar::operator* (IntegerVar other)
{
    return IntegerVar (longVal * other.longVal);
}

inline IntegerVar IntegerVar::operator% (IntegerVar other)
{
    return IntegerVar (longVal % other.longVal);
}

inline IntegerVar IntegerVar::operator/ (IntegerVar other)
{
    return IntegerVar (longVal / other.longVal);
}

/* Conditionals */

inline BooleanVar IntegerVar::operator< (IntegerVar other)
{
    return longVal < other.longVal;
}

inline BooleanVar IntegerVar::operator== (IntegerVar other)
{
    return longVal == other.longVal;
}

inline BooleanVar IntegerVar::operator> (IntegerVar other)
{
    return other < *this;
}

inline BooleanVar IntegerVar::operator<= (IntegerVar other)
{
    return *this < other || *this == other;
}

inline BooleanVar IntegerVar::operator>= (IntegerVar other)
{
    return *this > other || *this == other;
}

inline BooleanVar IntegerVar::operator!= (IntegerVar other)
{
    return ! (*this == other);
}

/* Assignment */

inline IntegerVar IntegerVar::operator+= (IntegerVar other)
{
    return *this = *this + other;
}

inline IntegerVar IntegerVar::operator-= (IntegerVar other)
{
    return *this = *this - other;
}

inline IntegerVar IntegerVar::operator*= (IntegerVar other)
{
    return *this = *this * other;
}

inline IntegerVar IntegerVar::operator%= (IntegerVar other)
{
    return *this = *this % other;
}

    /* Bit twiddling.  Negative IntVArs act like they 
       have an infinite number of preceding 1s.  */

inline IntegerVar IntegerVar::operator<< (IntegerVar other)
{
    return IntegerVar (longVal << other.longVal);
}

inline IntegerVar IntegerVar::operator>> (IntegerVar other)
{
    return IntegerVar (longVal >> other.longVal);
}

inline IntegerVar IntegerVar::operator~ ()
{
    return IntegerVar (~longVal);
}

inline IntegerVar IntegerVar::operator| (IntegerVar other)
{
    return IntegerVar (longVal | other.longVal);
}

inline IntegerVar IntegerVar::operator& (IntegerVar other)
{
    return IntegerVar (longVal & other.longVal);
}

inline IntegerVar IntegerVar::operator^ (IntegerVar other)
{
    return IntegerVar (longVal ^ other.longVal);
}


inline IntegerVar IntegerVar::operator<<= (IntegerVar other)
{
    return *this = *this << other;
}

inline IntegerVar IntegerVar::operator>>= (IntegerVar other)
{
    return *this = *this >> other;
}

inline IntegerVar IntegerVar::operator|= (IntegerVar other)
{
    return *this = *this | other;
}

inline IntegerVar IntegerVar::operator&= (IntegerVar other)
{
    return *this = *this & other;
}

inline IntegerVar IntegerVar::operator^= (IntegerVar other)
{
    return *this = *this ^ other;
}


inline Int32 max(Int32 a, Int32 b)
{
    return a > b ? a : b;
}

inline Int32 min(Int32 a, Int32 b)
{
    return a < b ? a : b;
}

inline Int32 abs(Int32 a)
{
    return a < 0 ? -a : a;
}

inline IntegerVar max(IntegerVar a, IntegerVar b)
{
    return a > b ? a : b;
}

inline IntegerVar min(IntegerVar a, IntegerVar b)
{
    return a < b ? a : b;
}

inline IntegerVar abs(IntegerVar a)
{
    return a < 0 ? -a : a;
}

inline IntegerVar rounded(IEEE64 x)
{
    return IntegerVar((Int32)(x + 0.5));
}

#endif /* INTVARX_IXX */
