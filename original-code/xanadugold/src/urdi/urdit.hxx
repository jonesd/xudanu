/* ========================================================================== */
//
//	Copyright (c) 1989 by Xanadu Operating Company, All Rights Reserved.
//
/* ========================================================================== */
//
// The information contained herein is confidential, proprietary to Xanadu
// Operating Company, and considered a trade secret as defined in section
// 499C of the penal code of the State of California.
//
// Use of this information by anyone other than authorized employees of
// Xanadu is granted only under a written nondisclosure agreement,
// expressly prescribing the scope and manner of such use.
//
// The above copyright notice is not to be construed as evidence of
// publication or the intent to publish.
//
/* ========================================================================== */
//
//			urdit.hxx
//
//	Include file for test of URDI internal data structures.
//
//		By Michael McClary	1991
//
/* ========================================================================== */

#ifndef URDIT_HXX
#define URDIT_HXX

#include <stream.h>
#include <string.h>
#ifdef unix
#	include <sys/wait.h>
#	include <osfcn.h>
#endif
#include "urdix.hxx"
#include "urdip.hxx"

#include "tofux.hxx"

/* ========================================================================== */
//
//		A stubble-visible padding class.
//
/* ========================================================================== */

CLASS(Pad,Heaper){
	CONCRETE(Pad)
	NO_GC(Pad)
	NOT_A_TYPE(Pad)
    public:
	Pad();
};

#endif /* URDIT_HXX */
