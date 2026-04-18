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
//	Renamed Transceiver to Xcvr, part of Xcvr class reorganization.
//		-michael Jun 14 1990
//
//	Changed IntegerVar::sendSelfTo(Xcvr) and ::IntegerVar(Xcvr *, TCSJ)
//	to use send/receive(long) regardless of whether protocol is verbose.
//	(Previously they tried to do compression themselves for terse protos.
//	Data compression is a protocol matter, and should live in the Xcvr.
//	(Perhaps this code was never run, because we only have verbose Xcvrs
//	so far.))
// !!!! Note that this should be changed to IntWhatever someday.
//	Fixed readHumber so ) is also a terminator/separator.
//		-michael Jun 22 1990
//
//	Moved readHumber to tcxcvrx.cxx  (and copy in humberx.xxx for
//	future terse protocols).
//		-michael Jun 23 1990
//
//	Eliminated SELF_COPY
//		-michael Jun 23 1990
//
//	Merged changes from wjr's:  IntegerVar0, rounded().
//		- michael Jul 13 1990
//
//	Changed:
//	 - receiveIntegerVar() to a constructor (to be followed by assignment),
//	 - sendIntegerVar() to sendSelfTo()
//	to be consistent with rest of xcvr modularity.
//		- michael Sep 11 1990

#include <stream.h>
#include "intvarx.hxx"
VERSION_ID(intvarx_cxx,
	   "$Id: intvarx.cxx,v 2.5 1992/08/14 22:08:52 shap Exp $")

#include "nxcvrx.hxx"

#include "intvarx.ixx"
#include "intvarx.sxx"

UInt32 IntegerVar::hashForEqual ()
{
    return longVal;
}

void IntegerVar::sendSelfTo (Xmtr * xmtr)
{
    xmtr->sendInt32 (longVal);
}

IntegerVar::IntegerVar (Rcvr * rcvr, TCSJ)
{
    longVal = rcvr->receiveInt32();
}

ostream& operator<<(ostream& oo, IntegerVar i)
{
    return oo << i.longVal;
}

