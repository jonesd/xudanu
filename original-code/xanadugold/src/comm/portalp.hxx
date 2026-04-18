/* Copyright Xanadu Operating Company.  All Rights Reserved. */

/******************************************************************************
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

#ifndef PORTALP_HXX
#define PORTALP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PORTALX_HXX
#include "portalx.hxx"
#endif /* PORTALX_HXX */

#ifndef PORTALP_OXX
#include "portalp.oxx"
#endif /* PORTALP_OXX */


#ifndef NSCOTTYX_HXX
#include "nscottyx.hxx"
#endif /* NSCOTTYX_HXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef PORTALR_OXX
#include "portalr.oxx"
#endif /* PORTALR_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class XnBufferedWriteStream 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class XnBufferedWriteStream : public XnWriteStream {

/* Attributes for class XnBufferedWriteStream */
	CONCRETE(XnBufferedWriteStream)
	EQ(XnBufferedWriteStream)
	NOT_A_TYPE(XnBufferedWriteStream)
	AUTO_GC(XnBufferedWriteStream)
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* private */

	
	virtual void writePacket ();
	
  public: /* accessing */

	
	virtual void flush ();
	
	
	virtual void putByte (UInt32 ARG(byte));
	
	/* This should be optimized to use a memcpy or something 
	rather than a loop */
	
	virtual void putData (APTR(UInt8Array) ARG(array));
	
	/*  */
	/* This should be optimized to use a memcpy or something 
	rather than a loop */
	
	virtual void putStr (char * ARG(string));
	
  public: /* creation */

	
	XnBufferedWriteStream (APTR(PacketPortal) ARG(portal), TCSJ);
	
  private:
	CHKPTR(PacketPortal) myPortal;
	CHKPTR(UInt8Array) myBuffer;
	Int32 myNext;
	friend class XnWriteStream;
};  /* end class XnBufferedWriteStream */



#endif /* PORTALP_HXX */

