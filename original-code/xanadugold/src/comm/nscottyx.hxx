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

#ifndef NSCOTTYX_HXX
#define NSCOTTYX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef NSCOTTYX_OXX
#include "nscottyx.oxx"
#endif /* NSCOTTYX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class XnReadStream 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class XnReadStream : public Heaper {

/* Attributes for class XnReadStream */
	DEFERRED(XnReadStream)
	NO_GC(XnReadStream)
  public: /* creation */

	
	static RPTR(XnReadStream) make (APTR(UInt8Array) ARG(collection));
	
	
	static RPTR(XnReadStream) make (
			UInt8 * ARG(dataP), 
			Int32 ARG(start), 
			Int32 ARG(count))
	;
	
  public: /* accessing */

	
	virtual UInt8 getByte () DEFERRED_FUNC;
	
	/* Pour data directly into a buffer. */
	
	virtual void getBytes (
			void * ARG(buffer), 
			Int32 ARG(count), 
			Int32 ARG(start) = Int32Zero)
	;
	
	
	virtual void putBack (UInt8 ARG(c)) DEFERRED_SUBR;
	
	
	virtual void refill () DEFERRED_SUBR;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	

	/* automatic 0-argument constructor */
  public:
	XnReadStream();

};  /* end class XnReadStream */



/* ************************************************************************ *
 * 
 *                    Class XnWriteStream 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class XnWriteStream : public Heaper {

/* Attributes for class XnWriteStream */
	DEFERRED(XnWriteStream)
	NO_GC(XnWriteStream)
  public: /* creation */

	/* Make a stream which writes into the given array */
	
	static RPTR(XnWriteStream) make (APTR(UInt8Array) ARG(array));
	
	
	static RPTR(XnWriteStream) make (
			UInt8 * ARG(dataP), 
			Int32 ARG(start), 
			Int32 ARG(count))
	;
	
  public: /* accessing */

	
	virtual void flush () DEFERRED_SUBR;
	
	/* These are UInt32 to avoid an unneeded mask op that the 
	compiler generates */
	
	virtual void putByte (UInt32 ARG(byte)) DEFERRED_SUBR;
	
	
	virtual void putData (APTR(UInt8Array) ARG(array)) DEFERRED_SUBR;
	
	
	virtual void putStr (char * ARG(string)) DEFERRED_SUBR;
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	

	/* automatic 0-argument constructor */
  public:
	XnWriteStream();

};  /* end class XnWriteStream */



/* ************************************************************************ *
 * 
 *                    Class   WriteVariableArrayStream 
 *
 * ************************************************************************ */




	/* WriteVariableArrayStream is used to put an unpredictable 
	amount of data into a UInt8Array.  The array method returns 
	the current state of the buffer. */

class WriteVariableArrayStream : public XnWriteStream {

/* Attributes for class WriteVariableArrayStream */
	CONCRETE(WriteVariableArrayStream)
	EQ(WriteVariableArrayStream)
	AUTO_GC(WriteVariableArrayStream)
  public: /* creation */

	
	static RPTR(WriteVariableArrayStream) make (Int32 ARG(size));
	
  public: /* accessing */

	/* We can't test for underflow because we deliberately overestimate 
		 the size when we don't have exact information on where things go. */
	/* myIndex == myMax assert: 'Must fill up the space' */
	
	virtual void flush ();
	
	
	virtual void putByte (UInt32 ARG(byte));
	
	
	virtual void putData (APTR(UInt8Array) ARG(array));
	
	
	virtual void putStr (char * ARG(string));
	
  public: /* creation */

	
	WriteVariableArrayStream (APTR(UInt8Array) ARG(array), TCSJ);
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* special */

	
	virtual RPTR(UInt8Array) array ();
	
  private:
	CHKPTR(UInt8Array) myCollection;
	Int32 myIndex;
	friend class XnWriteStream;
};  /* end class WriteVariableArrayStream */



#endif /* NSCOTTYX_HXX */

