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

#ifndef PORTALR_HXX
#define PORTALR_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PORTALX_HXX
#include "portalx.hxx"
#endif /* PORTALX_HXX */

#ifndef PORTALR_OXX
#include "portalr.oxx"
#endif /* PORTALR_OXX */


#ifndef NSCOTTYX_HXX
#include "nscottyx.hxx"
#endif /* NSCOTTYX_HXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class PacketPortal 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class PacketPortal : public Portal {

/* Attributes for class PacketPortal */
	DEFERRED(PacketPortal)
	AUTO_GC(PacketPortal)
  protected: /* protected: creation */

	
	PacketPortal ();
	
	
	PacketPortal (APTR(XnReadStream) ARG(readStr), APTR(XnWriteStream) ARG(writeStr));
	
  public: /* accessing */

	
	virtual RPTR(XnReadStream) readStream ();
	
	
	virtual RPTR(XnWriteStream) writeStream ();
	
  public: /* internal */

	/* Make sure the bits go out. */
	
	virtual void flush () DEFERRED_SUBR;
	
	/* Return a buffer of a size that the unerlying transport 
	layer likes. */
	
	virtual RPTR(UInt8Array) readBuffer () DEFERRED_FUNC;
	
	
	virtual Int32 readPacket (APTR(UInt8Array) ARG(buffer), Int32 ARG(count)) DEFERRED_FUNC;
	
	/* Return a buffer of a size that the unerlying transport 
	layer likes. */
	
	virtual RPTR(UInt8Array) writeBuffer () DEFERRED_FUNC;
	
	
	virtual void writePacket (APTR(UInt8Array) ARG(packet), Int32 ARG(count)) DEFERRED_SUBR;
	
  private:
	CHKPTR(XnReadStream) myReadStream;
	CHKPTR(XnWriteStream) myWriteStream;
};  /* end class PacketPortal */



/* ************************************************************************ *
 * 
 *                    Class PairPortal 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class PairPortal : public Portal {

/* Attributes for class PairPortal */
	CONCRETE(PairPortal)
	AUTO_GC(PairPortal)
  public: /* creation */

	
	static RPTR(PairPortal) make (APTR(XnReadStream) ARG(read), APTR(XnWriteStream) ARG(write));
	
  public: /* accessing */

	
	virtual RPTR(XnReadStream) readStream ();
	
	
	virtual RPTR(XnWriteStream) writeStream ();
	
  protected: /* protected: creation */

	
	PairPortal (APTR(XnReadStream) ARG(readStr), APTR(XnWriteStream) ARG(writeStr));
	
	
	virtual void destruct ();
	
  private:
	CHKPTR(XnReadStream) myReadStream;
	CHKPTR(XnWriteStream) myWriteStream;
};  /* end class PairPortal */



/* ************************************************************************ *
 * 
 *                    Class XnBufferedReadStream 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class XnBufferedReadStream : public XnReadStream {

/* Attributes for class XnBufferedReadStream */
	CONCRETE(XnBufferedReadStream)
	EQ(XnBufferedReadStream)
	NOT_A_TYPE(XnBufferedReadStream)
	AUTO_GC(XnBufferedReadStream)
  public: /* accessing */

	
	virtual RPTR(UInt8Array) contents ();
	
	
	virtual UInt8 getByte ();
	
	/* Pour data directly into a buffer. */
	
	virtual void getBytes (
			void * ARG(buffer), 
			Int32 ARG(count), 
			Int32 ARG(start) = Int32Zero)
	;
	
	
	virtual BooleanVar isReady ();
	
	
	virtual void putBack (UInt8 ARG(c));
	
	
	virtual void refill ();
	
  public: /* creation */

	
	XnBufferedReadStream (APTR(PacketPortal) ARG(portal), TCSJ);
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	CHKPTR(PacketPortal) myPortal;
	CHKPTR(UInt8Array) myBuffer;
	Int32 myNext;
	Int32 myMax;
	friend class XnReadStream;
};  /* end class XnBufferedReadStream */



#endif /* PORTALR_HXX */

