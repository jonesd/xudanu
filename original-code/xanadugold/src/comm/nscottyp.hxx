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

#ifndef NSCOTTYP_HXX
#define NSCOTTYP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef NSCOTTYX_HXX
#include "nscottyx.hxx"
#endif /* NSCOTTYX_HXX */

#ifndef NSCOTTYP_OXX
#include "nscottyp.oxx"
#endif /* NSCOTTYP_OXX */


#ifndef CACHEX_OXX
#include "cachex.oxx"
#endif /* CACHEX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class ReadArrayStream 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class ReadArrayStream : public XnReadStream {

/* Attributes for class ReadArrayStream */
	CONCRETE(ReadArrayStream)
	EQ(ReadArrayStream)
	NOT_A_TYPE(ReadArrayStream)
	AUTO_GC(ReadArrayStream)
  public: /* accessing */

	
	virtual UInt8 getByte ();
	
	
	virtual void putBack (UInt8 ARG(b));
	
	
	virtual void refill ();
	
  public: /* creation */

	
	ReadArrayStream (APTR(UInt8Array) ARG(collection), TCSJ);
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	CHKPTR(UInt8Array) myBuffer;
	Int32 myIndex;
	friend class XnReadStream;
};  /* end class ReadArrayStream */



/* ************************************************************************ *
 * 
 *                    Class ReadMemStream 
 *
 * ************************************************************************ */



/* Initializers for ReadMemStream */







	/* NO CLASS COMMENT */

class ReadMemStream : public XnReadStream {

/* Attributes for class ReadMemStream */
	CONCRETE(ReadMemStream)
	EQ(ReadMemStream)
	NOT_A_TYPE(ReadMemStream)
	AUTO_GC(ReadMemStream)

/* Initializers for ReadMemStream */



friend class INIT_TIME_NAME(ReadMemStream,initTimeNonInherited);

  public: /* creation */

	
	static RPTR(XnReadStream) make (
			UInt8 * ARG(dataP), 
			Int32 ARG(start), 
			Int32 ARG(count))
	;
	
  public: /* accessing */

	
	virtual UInt8 getByte ();
	
	
	virtual void putBack (UInt8 ARG(b));
	
	
	virtual void refill ();
	
  public: /* creation */

	
	ReadMemStream (
			UInt8 * ARG(collection), 
			Int32 ARG(index), 
			Int32 ARG(count))
	;
	
	
	virtual void destroy ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	UInt8 * myBuffer;
	Int32 myIndex;
	Int32 myStart;
	Int32 myEnd;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(InstanceCache) SomeStreams;
};  /* end class ReadMemStream */



/* ************************************************************************ *
 * 
 *                    Class WriteArrayStream 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class WriteArrayStream : public XnWriteStream {

/* Attributes for class WriteArrayStream */
	CONCRETE(WriteArrayStream)
	EQ(WriteArrayStream)
	NOT_A_TYPE(WriteArrayStream)
	AUTO_GC(WriteArrayStream)
  public: /* accessing */

	/* We can't test for underflow because we deliberately overestimate 
		 the size when we don't have exact information on where things go. */
	/* myIndex == myMax assert: 'Must fill up the space' */
	
	virtual void flush ();
	
	
	virtual void putByte (UInt32 ARG(byte));
	
	
	virtual void putData (APTR(UInt8Array) ARG(array));
	
	
	virtual void putStr (char * ARG(string));
	
  public: /* creation */

	
	WriteArrayStream (APTR(UInt8Array) ARG(array), TCSJ);
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	CHKPTR(UInt8Array) myCollection;
	Int32 myIndex;
	friend class XnWriteStream;
};  /* end class WriteArrayStream */



/* ************************************************************************ *
 * 
 *                    Class WriteMemStream 
 *
 * ************************************************************************ */



/* Initializers for WriteMemStream */







	/* NO CLASS COMMENT */

class WriteMemStream : public XnWriteStream {

/* Attributes for class WriteMemStream */
	CONCRETE(WriteMemStream)
	EQ(WriteMemStream)
	NOT_A_TYPE(WriteMemStream)
	AUTO_GC(WriteMemStream)

/* Initializers for WriteMemStream */



friend class INIT_TIME_NAME(WriteMemStream,initTimeNonInherited);

  public: /* creation */

	
	static RPTR(XnWriteStream) make (
			UInt8 * ARG(dataP), 
			Int32 ARG(start), 
			Int32 ARG(count))
	;
	
  public: /* accessing */

	/* We can't test for underflow because we deliberately overestimate 
		 the size when we don't have exact information on where things go. */
	/* myIndex == myMax assert: 'Must fill up the space' */
	
	virtual void flush ();
	
	
	virtual void putByte (UInt32 ARG(byte));
	
	
	virtual void putData (APTR(UInt8Array) ARG(array));
	
	
	virtual void putStr (char * ARG(string));
	
  public: /* creation */

	
	WriteMemStream (
			UInt8 * ARG(collection), 
			Int32 ARG(index), 
			Int32 ARG(count))
	;
	
	
	virtual void destroy ();
	
  public: /* debugging */

	
	virtual char * contents ();
	
	
	virtual Int32 size ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	UInt8 * myCollection;
	Int32 myStart;
	Int32 myIndex;
	Int32 myMax;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(InstanceCache) SomeStreams;
};  /* end class WriteMemStream */



#endif /* NSCOTTYP_HXX */

