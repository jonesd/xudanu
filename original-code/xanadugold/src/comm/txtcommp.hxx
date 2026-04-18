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

#ifndef TXTCOMMP_HXX
#define TXTCOMMP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef TXTCOMMX_HXX
#include "txtcommx.hxx"
#endif /* TXTCOMMX_HXX */

#ifndef TXTCOMMP_OXX
#include "txtcommp.oxx"
#endif /* TXTCOMMP_OXX */


#ifndef NSCOTTYX_OXX
#include "nscottyx.oxx"
#endif /* NSCOTTYX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef STRINGX_OXX
#include "stringx.oxx"
#endif /* STRINGX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class TextyRcvr 
 *
 * ************************************************************************ */



/* Initializers for TextyRcvr */




	/* NO CLASS COMMENT */

class TextyRcvr : public SpecialistRcvr {

/* Attributes for class TextyRcvr */
	CONCRETE(TextyRcvr)
	NOT_A_TYPE(TextyRcvr)
	AUTO_GC(TextyRcvr)

/* Initializers for TextyRcvr */


  public: /* creation */

	
	static RPTR(SpecialistRcvr) make (APTR(TransferSpecialist) ARG(specialist), APTR(XnReadStream) ARG(stream));
	
  public: /* receiving */

	
	virtual BooleanVar receiveBooleanVar ();
	
	
	virtual RPTR(Category) receiveCategory ();
	
	/* Fill the array with data from the stream. */
	
	virtual void receiveData (APTR(UInt8Array) ARG(array));
	
	
	virtual IEEEDoubleVar receiveIEEEDoubleVar ();
	
	
	virtual Int32 receiveInt32 ();
	
	
	virtual Int8 receiveInt8 ();
	
	
	virtual IntegerVar receiveIntegerVar ();
	
	
	virtual char * receiveString ();
	
	
	virtual UInt32 receiveUInt32 ();
	
	
	virtual UInt8 receiveUInt8 ();
	
  protected: /* protected: lexer */

	
	virtual void decrementDepth ();
	
	
	virtual void endOfInstance ();
	
	
	virtual void endPacket ();
	
	
	virtual RPTR(Category) fetchStartOfInstance ();
	
	
	virtual UInt32 getByte ();
	
	/* match a character from the input stream */
	
	virtual void getCharToken (char ARG(referent));
	
	/* get an identifier from the stream into a pre-allocated buffer */
	
	virtual void getIdentifier (char * ARG(buf), Int32 ARG(limit));
	
	
	virtual void incrementDepth ();
	
	/* return the first character following white space */
	
	virtual char skipWhiteSpace ();
	
  private: /* private: receiving */

	/* Receive an arbitrary number.  Convert to the lesser types 
	by range checking and casting. */
	
	virtual IntegerVar receiveNumber ();
	
  public: /* creation */

	
	TextyRcvr (APTR(TransferSpecialist) ARG(specialist), APTR(XnReadStream) ARG(stream));
	
  protected: /* protected: receiving */

	
	virtual void endThing ();
	
	
	virtual void startThing ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  private:
	CHKPTR(XnReadStream) myStream;
	IntegerVar myDepth;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static char* ReceiveStringBuffer;
	static Int4 ReceiveStringBufferSize;
};  /* end class TextyRcvr */



/* ************************************************************************ *
 * 
 *                    Class TextyXmtr 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class TextyXmtr : public SpecialistXmtr {

/* Attributes for class TextyXmtr */
	CONCRETE(TextyXmtr)
	NOT_A_TYPE(TextyXmtr)
	AUTO_GC(TextyXmtr)
  public: /* creation */

	
	static RPTR(SpecialistXmtr) make (APTR(TransferSpecialist) ARG(specialist), APTR(XnWriteStream) ARG(stream));
	
  public: /* sending */

	
	virtual void sendBooleanVar (BooleanVar ARG(b));
	
	
	virtual void sendCategory (APTR(Category) ARG(cat));
	
	/* Sending the normal decimal approximation doesn't work 
	because it introduces 
		roundoff error. What we need to do instead is send a hex 
	encoding of the IEEE 
		double precision (64-bit) representation of the number. For 
	clarity in the 
		textual protocol, we also include the decimal approximation 
	in a comment. */
	
	virtual void sendIEEEDoubleVar (IEEEDoubleVar ARG(x));
	
	
	virtual void sendInt32 (Int32 ARG(n));
	
	
	virtual void sendInt8 (Int8 ARG(n));
	
	
	virtual void sendIntegerVar (IntegerVar ARG(n));
	
	
	virtual void sendString (char * ARG(s));
	
	
	virtual void sendUInt32 (UInt32 ARG(n));
	
	
	virtual void sendUInt8 (UInt8 ARG(n));
	
	
	virtual void sendUInt8Data (APTR(UInt8Array) ARG(array));
	
  public: /* specialist sending */

	/* end sending an instance */
	
	virtual void endInstance ();
	
  protected: /* protected: sending */

	
	virtual void decrementDepth ();
	
	
	virtual void endPacket ();
	
	
	virtual void endThing ();
	
	
	virtual void incrementDepth ();
	
	
	virtual void putByte (UInt8 ARG(b));
	
	
	virtual void sendNULL ();
	
	/* start sending an instance of a particular class */
	
	virtual void startNewInstance (APTR(Category) ARG(cat));
	
	
	virtual void startThing ();
	
  private: /* private: sending */

	/* send an identifier */
	
	virtual void sendIdentifier (char * ARG(identifier));
	
  public: /* creation */

	
	TextyXmtr (APTR(TransferSpecialist) ARG(specialist), APTR(XnWriteStream) ARG(stream));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* overloading junk */

	
	virtual void sendHeaper (APTR(Heaper) ARG(object));
	
  private:
	CHKPTR(XnWriteStream) myStream;
	IntegerVar myDepth;
	BooleanVar myNeedsSep;
};  /* end class TextyXmtr */



#endif /* TXTCOMMP_HXX */

