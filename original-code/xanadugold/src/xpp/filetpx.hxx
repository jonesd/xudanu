/* Copyright Xanadu Operating Company.  All Rights Reserved.
	12 August 1991 at 10:59:55 pm
******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
***************************************************************************
Output from Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989
*/


#ifndef FILETPX_HXX
#define FILETPX_HXX

/* $Id: filetpx.hxx,v 2.7 1992/11/25 23:26:12 eric Exp $ */

#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef FILETPX_OXX
#include "filetpx.oxx"
#endif /* FILETPX_OXX */

#ifndef NSCOTTYX_HXX
#include "nscottyx.hxx"
#endif /* NSCOTTYX_HXX */

#include <stdio.h>


/* ************************************************************************ *
 * 
 *                    Class XnWriteFile 
 *
 * ************************************************************************ */

class XnWriteFile : public XnWriteStream {
    CONCRETE(XnWriteFile)
    NOT_A_TYPE(XnWriteFile)
    NO_GC(XnWriteFile)
 public: /* accessing */

    LEAF void flush ();

    LEAF void putByte (UInt32 byte);

    LEAF void putData (APTR(UInt8Array) array);

    LEAF void putStr (char * string);

 public:
    static RPTR(XnWriteStream) make (char * fileName);

 private: /* creation */
    XnWriteFile(FILE * fd, TCSJ);

 protected:
    virtual void destruct ();

 private:
    FILE * myFD;
};


/* ************************************************************************ *
 * 
 *                    Class XnReadFile 
 *
 * ************************************************************************ */

class XnReadFile : public XnReadStream {
    CONCRETE(XnReadFile)
    NOT_A_TYPE(XnReadFile)
    NO_GC(XnReadFile)
 public: /* accessing */

    LEAF UInt8 getByte ();

    LEAF void putBack (UInt8 c);

    LEAF void refill ();
	
 public:
    static RPTR(XnReadStream) make (char * fileName);

 private: /* creation */
	
    XnReadFile (FILE * fd, TCSJ);

 protected:
    virtual void destruct ();
	
 private:
    FILE * myFD;
};

#endif /* FILETPX_HXX */

