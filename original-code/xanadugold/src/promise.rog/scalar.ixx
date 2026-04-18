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

#ifndef XU_SCALAR_IXX
#define XU_SCALAR_IXX

#include "xanadu.hxx"


XU_INLINE1 XuIntVar xuMin (XuIntVar a, XuIntVar b)
{
    return a < b ? a : b;
}

XU_INLINE1 XuIntVar xuMax (XuIntVar a, XuIntVar b)
{
    return a > b ? a : b;
}


XU_INLINE1 XuValueP::XuValueP (char value)
   : XuPtrVar (XuIntValue::signedMake (value))
{}

XU_INLINE1 XuValueP::XuValueP (unsigned char value)
   : XuPtrVar (XuIntValue::unsignedMake (value))
{}

XU_INLINE1 XuValueP::XuValueP (short value)
   : XuPtrVar (XuIntValue::signedMake (value))
{}

XU_INLINE1 XuValueP::XuValueP (unsigned short value)
   : XuPtrVar (XuIntValue::unsignedMake (value))
{}

XU_INLINE1 XuValueP::XuValueP (int value)
   : XuPtrVar (XuIntValue::signedMake (value))
{}

XU_INLINE1 XuValueP::XuValueP (unsigned int value)
   : XuPtrVar (XuIntValue::unsignedMake (value))
{}

XU_INLINE1 XuValueP::XuValueP (long value)
   : XuPtrVar (XuIntValue::signedMake (value))
{}

XU_INLINE1 XuValueP::XuValueP (unsigned long value)
   : XuPtrVar (XuIntValue::unsignedMake (value))
{}


XU_INLINE1 XuValueP::XuValueP (XuIEEE128Var value)
   : XuPtrVar (XuFloatValue::make (value))
{}

XU_INLINE1 XuValueP::XuValueP (XuIEEE64Var value)
   : XuPtrVar (XuFloatValue::make (value))
{}

XU_INLINE1 XuValueP::XuValueP (XuIEEE32Var value)
   : XuPtrVar (XuFloatValue::make (value))
{}

XU_INLINE1 XuValueP::XuValueP (XuIEEE8Var value)
   : XuPtrVar (XuFloatValue::make (value))
{}

XU_INLINE1 XuValueP::XuValueP (double value)
   : XuPtrVar (XuFloatValue::make (value))
{}

XU_INLINE1 XuValueP::XuValueP (float value)
   : XuPtrVar (XuFloatValue::make (value))
{}




XU_INLINE1 XuIntValueP::XuIntValueP (char value)
   : XuPtrVar (XuIntValue::signedMake (value))
{}

XU_INLINE1 XuIntValueP::XuIntValueP (unsigned char value)
   : XuPtrVar (XuIntValue::unsignedMake (value))
{}

XU_INLINE1 XuIntValueP::XuIntValueP (short value)
   : XuPtrVar (XuIntValue::signedMake (value))
{}

XU_INLINE1 XuIntValueP::XuIntValueP (unsigned short value)
   : XuPtrVar (XuIntValue::unsignedMake (value))
{}

XU_INLINE1 XuIntValueP::XuIntValueP (int value)
   : XuPtrVar (XuIntValue::signedMake (value))
{}

XU_INLINE1 XuIntValueP::XuIntValueP (unsigned int value)
   : XuPtrVar (XuIntValue::unsignedMake (value))
{}

XU_INLINE1 XuIntValueP::XuIntValueP (long value)
   : XuPtrVar (XuIntValue::signedMake (value))
{}

XU_INLINE1 XuIntValueP::XuIntValueP (unsigned long value)
   : XuPtrVar (XuIntValue::unsignedMake (value))
{}

/* Arithmetic */

XU_INLINE1 XuIntValueP XuIntValueP::operator+ (XuIntValueP& other)
{
    return (*this)->plus (other);
}

XU_INLINE1 XuIntValueP XuIntValueP::operator- (XuIntValueP& other)
{
    return (*this)->minus (other);
}

XU_INLINE1 XuIntValueP XuIntValueP::operator- ()
{
    return (*this)->negated();
}

XU_INLINE1 XuIntValueP XuIntValueP::operator* (XuIntValueP& other)
{
    return (*this)->times (other);
}

XU_INLINE1 XuIntValueP XuIntValueP::operator% (XuIntValueP& other)
{
    return (*this)->mod (other);
}

XU_INLINE1 XuIntValueP XuIntValueP::operator/ (XuIntValueP& other)
{
    return (*this)->dividedBy (other);
}


/* Equality */

XU_INLINE1 XuBooleanVar XuIntValueP::operator== (XuFakeNull* other) 
{
    return this->XuPtrVar::operator== (other);
}

XU_INLINE1 XuBooleanVar XuIntValueP::operator!= (XuFakeNull* other) 
{
    return this->XuPtrVar::operator!= (other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator== (XuIntValueP& other)
{
    return (*this)->equals (other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator== (char other)
{
    return *this == XuIntValueP(other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator== (unsigned char other)
{
    return *this == XuIntValueP(other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator== (short other)
{
    return *this == XuIntValueP(other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator== (unsigned short other)
{
    return *this == XuIntValueP(other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator== (int other)
{
    return *this == XuIntValueP(other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator== (unsigned int other)
{
    return *this == XuIntValueP(other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator== (long other)
{
    return *this == XuIntValueP(other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator== (unsigned long other)
{
    return *this == XuIntValueP(other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator!= (XuIntValueP& other)
{
    return (*this)->notEquals (other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator!= (char other)
{
    return *this != XuIntValueP(other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator!= (unsigned char other)
{
    return *this != XuIntValueP(other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator!= (short other)
{
    return *this != XuIntValueP(other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator!= (unsigned short other)
{
    return *this != XuIntValueP(other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator!= (int other)
{
    return *this != XuIntValueP(other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator!= (unsigned int other)
{
    return *this != XuIntValueP(other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator!= (long other)
{
    return *this != XuIntValueP(other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator!= (unsigned long other)
{
    return *this != XuIntValueP(other);
}

    
/* Comparison */

XU_INLINE1 XuBooleanValueP XuIntValueP::operator< (XuIntValueP& other)
{
    return (*this)->isLT (other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator> (XuIntValueP& other)
{
    return (*this)->isGT (other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator<= (XuIntValueP& other)
{
    return (*this)->isLE (other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator>= (XuIntValueP& other)
{
    return (*this)->isGE (other);
}

    
/* Assignment */

XU_INLINE1 XuIntValueP& XuIntValueP::operator+= (XuIntValueP& other)
{
    *this = *this + other;
    return *this;
}

XU_INLINE1 XuIntValueP& XuIntValueP::operator-= (XuIntValueP& other)
{
    *this = *this - other;
    return *this;
}

XU_INLINE1 XuIntValueP& XuIntValueP::operator*= (XuIntValueP& other)
{
    *this = *this * other;
    return *this;
}

XU_INLINE1 XuIntValueP& XuIntValueP::operator%= (XuIntValueP& other)
{
    *this = *this % other;
    return *this;
}

XU_INLINE1 XuIntValueP& XuIntValueP::operator/= (XuIntValueP& other)
{
    *this = *this / other;
    return *this;
}

#ifdef XU_ARM_COMPLIANT

XU_INLINE1 XuIntValueP& XuIntValueP::operator++ ()
{
    *this = *this + 1;
    return *this;
}

XU_INLINE1 XuIntValueP& XuIntValueP::operator-- ()
{
    *this = *this - 1;
    return *this;
}

XU_INLINE1 XuIntValueP XuIntValueP::operator++ (int)
{
    XuIntValueP result = *this;
    *this = *this + 1;
    return result;
}

XU_INLINE1 XuIntValueP XuIntValueP::operator-- (int)
{
    XuIntValueP result = *this;
    *this = *this - 1;
    return result;
}

#endif /* XU_ARM_COMPLIANT */

    
/* Bit twiddling.  Negative numbers have an infinite number of preceding 1's */

XU_INLINE1 XuIntValueP XuIntValueP::operator<< (XuIntValueP& other)
{
    return (*this)->leftShift (other);
}

XU_INLINE1 XuIntValueP XuIntValueP::operator>> (XuIntValueP& other)
{
    return (*this)->rightShift (other);
}

XU_INLINE1 XuIntValueP XuIntValueP::operator~ ()
{
    return (*this)->bitwiseComplement ();
}

XU_INLINE1 XuIntValueP XuIntValueP::operator| (XuIntValueP& other)
{
    return (*this)->bitwiseOr (other);
}

XU_INLINE1 XuIntValueP XuIntValueP::operator& (XuIntValueP& other)
{
    return (*this)->bitwiseAnd (other);
}

XU_INLINE1 XuIntValueP XuIntValueP::operator^ (XuIntValueP& other)
{
    return (*this)->bitwiseXor (other);
}

    
/* Bit Twiddling Assignment */

XU_INLINE1 XuIntValueP& XuIntValueP::operator<<= (XuIntValueP& other)
{
    *this = *this << other;
    return *this;
}

XU_INLINE1 XuIntValueP& XuIntValueP::operator>>= (XuIntValueP& other)
{
    *this = *this >> other;
    return *this;
}

XU_INLINE1 XuIntValueP& XuIntValueP::operator|= (XuIntValueP& other)
{
    *this = *this | other;
    return *this;
}

XU_INLINE1 XuIntValueP& XuIntValueP::operator&= (XuIntValueP& other)
{
    *this = *this & other;
    return *this;
}

XU_INLINE1 XuIntValueP& XuIntValueP::operator^= (XuIntValueP& other)
{
    *this = *this ^ other;
    return *this;
}


/* As XuBooleanValueP */
XU_INLINE1 XuBooleanValueP XuIntValueP::operator! ()
{
    return (*this)->logicalNot ();
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator&& (XuBooleanValueP& other)
{
    return (*this)->logicalAnd (other);
}

XU_INLINE1 XuBooleanValueP XuIntValueP::operator|| (XuBooleanValueP& other)
{
    return (*this)->logicalOr (other);
}



XU_INLINE1 XuFloatValueP::XuFloatValueP (XuIEEE128Var value)
   : XuPtrVar (XuFloatValue::make (value))
{}

XU_INLINE1 XuFloatValueP::XuFloatValueP (XuIEEE64Var value)
   : XuPtrVar (XuFloatValue::make (value))
{}

XU_INLINE1 XuFloatValueP::XuFloatValueP (XuIEEE32Var value)
   : XuPtrVar (XuFloatValue::make (value))
{}

XU_INLINE1 XuFloatValueP::XuFloatValueP (XuIEEE8Var value)
   : XuPtrVar (XuFloatValue::make (value))
{}

XU_INLINE1 XuFloatValueP::XuFloatValueP (double value)
   : XuPtrVar (XuFloatValue::make (value))
{}

XU_INLINE1 XuFloatValueP::XuFloatValueP (float value)
   : XuPtrVar (XuFloatValue::make (value))
{}


XU_INLINE1 XuArrayP::XuArrayP (char * value)
   : XuPtrVar (XuIntArray::string (value))
{}


XU_INLINE1 XuIntArrayP::XuIntArrayP (char * value)
   : XuPtrVar (XuIntArray::string (value))
{}


/****/


XU_INLINE1 XuPositionP::XuPositionP (XuIntValueP& value)
   : XuPtrVar (XuIntegerSpace::make()->position (value))
{}

XU_INLINE1 XuPositionP::XuPositionP (XuFloatValueP& value)
   : XuPtrVar (XuRealSpace::make()->position (value))
{}


XU_INLINE1 XuPositionP::XuPositionP (char value)
   : XuPtrVar (XuIntegerSpace::make()->position (value))
{}

XU_INLINE1 XuPositionP::XuPositionP (unsigned char value)
   : XuPtrVar (XuIntegerSpace::make()->position (value))
{}

XU_INLINE1 XuPositionP::XuPositionP (short value)
   : XuPtrVar (XuIntegerSpace::make()->position (value))
{}

XU_INLINE1 XuPositionP::XuPositionP (unsigned short value)
   : XuPtrVar (XuIntegerSpace::make()->position (value))
{}

XU_INLINE1 XuPositionP::XuPositionP (int value)
   : XuPtrVar (XuIntegerSpace::make()->position (value))
{}

XU_INLINE1 XuPositionP::XuPositionP (unsigned int value)
   : XuPtrVar (XuIntegerSpace::make()->position (value))
{}

XU_INLINE1 XuPositionP::XuPositionP (long value)
   : XuPtrVar (XuIntegerSpace::make()->position (value))
{}

XU_INLINE1 XuPositionP::XuPositionP (unsigned long value)
   : XuPtrVar (XuIntegerSpace::make()->position (value))
{}


XU_INLINE1 XuPositionP::XuPositionP (XuIEEE128Var value)
   : XuPtrVar (XuRealSpace::make()->position (value))
{}

XU_INLINE1 XuPositionP::XuPositionP (XuIEEE64Var value)
   : XuPtrVar (XuRealSpace::make()->position (value))
{}

XU_INLINE1 XuPositionP::XuPositionP (XuIEEE32Var value)
   : XuPtrVar (XuRealSpace::make()->position (value))
{}

XU_INLINE1 XuPositionP::XuPositionP (XuIEEE8Var value)
   : XuPtrVar (XuRealSpace::make()->position (value))
{}

XU_INLINE1 XuPositionP::XuPositionP (double value)
   : XuPtrVar (XuRealSpace::make()->position (value))
{}

XU_INLINE1 XuPositionP::XuPositionP (float value)
   : XuPtrVar (XuRealSpace::make()->position (value))
{}


XU_INLINE1 XuPositionP::XuPositionP (char * value)
   : XuPtrVar (XuSequenceSpace::make()->position (value))
{}



XU_INLINE1 XuIntegerP::XuIntegerP (XuIntValueP& value)
   : XuPtrVar (XuIntegerSpace::make()->position (value))
{}


XU_INLINE1 XuIntegerP::XuIntegerP (char value)
   : XuPtrVar (XuIntegerSpace::make()->position (value))
{}

XU_INLINE1 XuIntegerP::XuIntegerP (unsigned char value)
   : XuPtrVar (XuIntegerSpace::make()->position (value))
{}

XU_INLINE1 XuIntegerP::XuIntegerP (short value)
   : XuPtrVar (XuIntegerSpace::make()->position (value))
{}

XU_INLINE1 XuIntegerP::XuIntegerP (unsigned short value)
   : XuPtrVar (XuIntegerSpace::make()->position (value))
{}

XU_INLINE1 XuIntegerP::XuIntegerP (int value)
   : XuPtrVar (XuIntegerSpace::make()->position (value))
{}

XU_INLINE1 XuIntegerP::XuIntegerP (unsigned int value)
   : XuPtrVar (XuIntegerSpace::make()->position (value))
{}

XU_INLINE1 XuIntegerP::XuIntegerP (long value)
   : XuPtrVar (XuIntegerSpace::make()->position (value))
{}

XU_INLINE1 XuIntegerP::XuIntegerP (unsigned long value)
   : XuPtrVar (XuIntegerSpace::make()->position (value))
{}



XU_INLINE1 XuRealP::XuRealP (XuFloatValueP& value)
   : XuPtrVar (XuRealSpace::make()->position (value))
{}


XU_INLINE1 XuRealP::XuRealP (XuIEEE128Var value)
   : XuPtrVar (XuRealSpace::make()->position (value))
{}

XU_INLINE1 XuRealP::XuRealP (XuIEEE64Var value)
   : XuPtrVar (XuRealSpace::make()->position (value))
{}

XU_INLINE1 XuRealP::XuRealP (XuIEEE32Var value)
   : XuPtrVar (XuRealSpace::make()->position (value))
{}

XU_INLINE1 XuRealP::XuRealP (XuIEEE8Var value)
   : XuPtrVar (XuRealSpace::make()->position (value))
{}

XU_INLINE1 XuRealP::XuRealP (double value)
   : XuPtrVar (XuRealSpace::make()->position (value))
{}

XU_INLINE1 XuRealP::XuRealP (float value)
   : XuPtrVar (XuRealSpace::make()->position (value))
{}


XU_INLINE1 XuSequenceP::XuSequenceP (char * value)
   : XuPtrVar (XuSequenceSpace::make()->position (value))
{}


XU_INLINE1 XuMappingP::XuMappingP (XuIntValueP& value)
   : XuPtrVar (XuIntegerSpace::make()->translation (value))
{}


XU_INLINE1 XuMappingP::XuMappingP (char value)
   : XuPtrVar (XuIntegerSpace::make()->translation (value))
{}

XU_INLINE1 XuMappingP::XuMappingP (unsigned char value)
   : XuPtrVar (XuIntegerSpace::make()->translation (value))
{}

XU_INLINE1 XuMappingP::XuMappingP (short value)
   : XuPtrVar (XuIntegerSpace::make()->translation (value))
{}

XU_INLINE1 XuMappingP::XuMappingP (unsigned short value)
   : XuPtrVar (XuIntegerSpace::make()->translation (value))
{}

XU_INLINE1 XuMappingP::XuMappingP (int value)
   : XuPtrVar (XuIntegerSpace::make()->translation (value))
{}

XU_INLINE1 XuMappingP::XuMappingP (unsigned int value)
   : XuPtrVar (XuIntegerSpace::make()->translation (value))
{}

XU_INLINE1 XuMappingP::XuMappingP (long value)
   : XuPtrVar (XuIntegerSpace::make()->translation (value))
{}

XU_INLINE1 XuMappingP::XuMappingP (unsigned long value)
   : XuPtrVar (XuIntegerSpace::make()->translation (value))
{}



XU_INLINE1 XuIntegerMappingP::XuIntegerMappingP (XuIntValueP& value)
   : XuPtrVar (XuIntegerSpace::make()->translation (value))
{}


XU_INLINE1 XuIntegerMappingP::XuIntegerMappingP (char value)
   : XuPtrVar (XuIntegerSpace::make()->translation (value))
{}

XU_INLINE1 XuIntegerMappingP::XuIntegerMappingP (unsigned char value)
   : XuPtrVar (XuIntegerSpace::make()->translation (value))
{}

XU_INLINE1 XuIntegerMappingP::XuIntegerMappingP (short value)
   : XuPtrVar (XuIntegerSpace::make()->translation (value))
{}

XU_INLINE1 XuIntegerMappingP::XuIntegerMappingP (unsigned short value)
   : XuPtrVar (XuIntegerSpace::make()->translation (value))
{}

XU_INLINE1 XuIntegerMappingP::XuIntegerMappingP (int value)
   : XuPtrVar (XuIntegerSpace::make()->translation (value))
{}

XU_INLINE1 XuIntegerMappingP::XuIntegerMappingP (unsigned int value)
   : XuPtrVar (XuIntegerSpace::make()->translation (value))
{}

XU_INLINE1 XuIntegerMappingP::XuIntegerMappingP (long value)
   : XuPtrVar (XuIntegerSpace::make()->translation (value))
{}

XU_INLINE1 XuIntegerMappingP::XuIntegerMappingP (unsigned long value)
   : XuPtrVar (XuIntegerSpace::make()->translation (value))
{}



#endif /* XU_SCALAR_IXX */
