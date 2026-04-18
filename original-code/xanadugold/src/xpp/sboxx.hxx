/* ========================================================================== */
//
//	Copyright (c) 1989 by Xanadu Operating Company.  All rights reserved.
//	Copyright (c) Xerox Corporation 1989.  All rights reserved.
//
//	NOT TO BE EXPORTED IN ANY FORM FROM THE UNITED STATES
//	WITHOUT ADVANCE APPROVAL OF THE U.S. GOVERNMENT.
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
// The code in this module is derived from the Xerox Secure Hash Function.
// It is used under license from the Xerox Corporation.
// (Contact Xerox Corporation for a version uncontaminated by Xanadu
//  proprietary code.)
//
/* ========================================================================== */
//
//				SBox.cxx
//
// X++ Header file for Merkle's "Pharonic cypher" Cryptographic hash S-boxes.
//
/* ========================================================================== */

#ifndef SBOX_HXX
#define SBOX_HXX

static char * sbox_hxx_version() {
    return "$Id: sboxx.hxx,v 2.2 1992/06/05 23:43:31 eric Exp $";
}

typedef unsigned long int SBox[256];

#define maxSBoxCount 8

extern SBox standardSBoxes[maxSBoxCount];

#endif /* SBOX_HXX */
