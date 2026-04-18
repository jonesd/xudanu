
#include "scalar.hxx"
#include "scalar.ixx"
#include "xanadu.h"
#include "blasts.h"

XuPositionP::XuPositionP ( XuValueP& /*value*/)
{
    xuError (XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}


XuIEEE128Var::XuIEEE128Var ()
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}

XuIEEE128Var::XuIEEE128Var (XuIEEE128Var& /*other*/)
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}

XuIEEE128Var::XuIEEE128Var (XuIEEE64Var& /*other*/)
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}

XuIEEE128Var::XuIEEE128Var (XuIEEE32Var& /*other*/)
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}

XuIEEE128Var::XuIEEE128Var (XuIEEE8Var& /*other*/)
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}

XuIEEE128Var::XuIEEE128Var (float /*other*/)
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}

XuIEEE128Var::XuIEEE128Var (double /*other*/)
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}

XuIEEE128Var::operator float ()
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
    return 0.0;
}

XuIEEE128Var::operator double ()
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
    return 0.0;
}


XuIEEE64Var::XuIEEE64Var ()
{
    myData = 0.0;
}

XuIEEE64Var::XuIEEE64Var (XuIEEE128Var& /*other*/)
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}

XuIEEE64Var::XuIEEE64Var (XuIEEE64Var& other)
{
    myData = other.myData;
}

XuIEEE64Var::XuIEEE64Var (XuIEEE32Var& /*other*/)
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}

XuIEEE64Var::XuIEEE64Var (XuIEEE8Var& /*other*/)
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}

XuIEEE64Var::XuIEEE64Var (float other)
{
    myData = other;
}

XuIEEE64Var::XuIEEE64Var (double other)
{
    myData = other;
}

XuIEEE64Var::operator float ()
{
    return myData;
}

XuIEEE64Var::operator double ()
{
    return myData;
}


XuIEEE32Var::XuIEEE32Var ()
{
    myData = 0.0;
}

XuIEEE32Var::XuIEEE32Var (XuIEEE128Var& /*other*/)
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}

XuIEEE32Var::XuIEEE32Var (XuIEEE64Var& /*other*/)
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}

XuIEEE32Var::XuIEEE32Var (XuIEEE32Var& other)
{
    myData = other.myData;
}

XuIEEE32Var::XuIEEE32Var (XuIEEE8Var& /*other*/)
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}

XuIEEE32Var::XuIEEE32Var (float other)
{
    myData = other;
}

XuIEEE32Var::XuIEEE32Var (double other)
{
    myData = other;
}

XuIEEE32Var::operator float ()
{
    return myData;
}

XuIEEE32Var::operator double ()
{
    return myData;
}


XuIEEE8Var::XuIEEE8Var ()
{
    myData = 0;
}

XuIEEE8Var::XuIEEE8Var (XuIEEE128Var& /*other*/)
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}

XuIEEE8Var::XuIEEE8Var (XuIEEE64Var& /*other*/)
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}

XuIEEE8Var::XuIEEE8Var (XuIEEE32Var& /*other*/)
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}

XuIEEE8Var::XuIEEE8Var (XuIEEE8Var& other)
{
    myData = other.myData;
}

XuIEEE8Var::XuIEEE8Var (float /*other*/)
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}

XuIEEE8Var::XuIEEE8Var (double /*other*/)
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
}

XuIEEE8Var::operator float ()
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
    return 0.0;
}

XuIEEE8Var::operator double ()
{
    xuError(XU_NOT_YET_IMPLEMENTED_PROBLEM, XU_SOURCE);
    return 0.0;
}

