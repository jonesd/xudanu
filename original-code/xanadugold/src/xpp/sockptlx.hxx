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

#ifndef SOCKPTLX_HXX
#define SOCKPTLX_HXX
static char SOCKPTLX_HXX_ident[] ="$Id: sockptlx.hxx,v 1.4 1993/03/16 22:30:08 eric Exp $"; static char *SOCKPTLX_HXX_ident_func() { return SOCKPTLX_HXX_ident; }

#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SOCKPTLX_OXX
#include "sockptlx.oxx"
#endif /* SOCKPTLX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef PORTALR_HXX
#include "portalr.hxx"
#endif /* PORTALR_HXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef ALLOCX_HXX
#include "allocx.hxx"
#endif /* ALLOCX_HXX */

/* This module has no comment */
/*  */
/* This file has no header */




/* ************************************************************************ *
 * 
 *                    Class SocketPortal 
 *
 * ************************************************************************ */



class SocketPortal : public PacketPortal {

/* Attributes for class SocketPortal */
	CONCRETE(SocketPortal)
	NOT_A_TYPE(SocketPortal)
	NO_GC(SocketPortal)
  public: /* creation */

	
	static RPTR(PacketPortal) make (int ARG(socketFD));
	
	/* SocketTransporter make: 'vlad' with: 16rcafe */
	/* I suspect this doesn't do a close under some situations 
	where it should (and 
		where the old code did). */
	
	static RPTR(PacketPortal) make (char * ARG(hostName), UInt32 ARG(port));
	
  public: /* accessing */

	/* Make sure the bits go out. */
	
	virtual void flush ();
	
	/* Return a buffer of a size that the unerlying transport 
	layer likes. */
	
	virtual RPTR(UInt8Array) readBuffer ();
	
	/* receive data into a buffer */
	
	virtual Int32 readPacket (APTR(UInt8Array) ARG(buffer), Int32 ARG(count));
	
	/* Return a buffer of a size that the unerlying transport 
	layer likes. */
	
	virtual RPTR(UInt8Array) writeBuffer ();
	
	/* send a buffer of data */
	
	virtual void writePacket (APTR(UInt8Array) ARG(packet), Int32 ARG(count));
	
  protected: /* protected: creation */

	
	SocketPortal (int ARG(socketFD), TCSJ);
	
	
	virtual void destruct ();
	
  private:
	int mySocketFD;
	int myTimeoutCount;	// successive timeouts since last successful read
};  /* end class SocketPortal */



#endif /* SOCKPTLX_HXX */

