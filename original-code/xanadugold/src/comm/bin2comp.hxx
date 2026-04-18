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

#ifndef BIN2COMP_HXX
#define BIN2COMP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef BIN2COMX_HXX
#include "bin2comx.hxx"
#endif /* BIN2COMX_HXX */

#ifndef BIN2COMP_OXX
#include "bin2comp.oxx"
#endif /* BIN2COMP_OXX */


#ifndef CACHEX_OXX
#include "cachex.oxx"
#endif /* CACHEX_OXX */

#ifndef NSCOTTYX_OXX
#include "nscottyx.oxx"
#endif /* NSCOTTYX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class Binary2Rcvr 
 *
 * ************************************************************************ */



/* Initializers for Binary2Rcvr */







	/* NO CLASS COMMENT */

class Binary2Rcvr : public SpecialistRcvr {

/* Attributes for class Binary2Rcvr */
	CONCRETE(Binary2Rcvr)
	NOT_A_TYPE(Binary2Rcvr)
	AUTO_GC(Binary2Rcvr)

/* Initializers for Binary2Rcvr */



friend class INIT_TIME_NAME(Binary2Rcvr,initTimeNonInherited);

  public: /* creation */

	
	static RPTR(SpecialistRcvr) make (APTR(TransferSpecialist) ARG(specialist), APTR(XnReadStream) ARG(stream));
	
  public: /* receiving */

	
	virtual BooleanVar receiveBooleanVar ();
	
	
	virtual RPTR(Category) OR(NULL) receiveCategory ();
	
	/* Fill the array with data from the stream. */
	
	virtual void receiveData (APTR(UInt8Array) ARG(array));
	
	/* | result {IEEEDoubleVar} |
		self startThing.
		result _ Double make: self getIntegerVar with: self getIntegerVar.
		self endThing.
		^result */
	
	virtual IEEEDoubleVar receiveIEEEDoubleVar ();
	
	
	virtual Int32 receiveInt32 ();
	
	
	virtual Int8 receiveInt8 ();
	
	
	virtual IntegerVar receiveIntegerVar ();
	
	
	virtual char * receiveString ();
	
	
	virtual UInt32 receiveUInt32 ();
	
	
	virtual UInt8 receiveUInt8 ();
	
  protected: /* protected: specialist */

	
	virtual void endOfInstance ();
	
	
	virtual void endPacket ();
	
	
	virtual RPTR(Category) OR(NULL) fetchStartOfInstance ();
	
	/* A new representation that requires less shifting (eventually). */
	/* 
	7/1 		0<7>
	14/2	10<6>		<8>
	21/3	110<5>		<16>
	28/4	1110<4>		<24>
	35/5	11110<3>	<32>
	42/6	111110<2>	<40>
	49/7	1111110<1>	<48>
	56/8	11111110 	<56>
	?/?	11111111  <humber count>
	 */
	
	virtual IntegerVar getIntegerVar ();
	
  private: /* private: */

	
	virtual void endThing ();
	
	
	virtual void startThing ();
	
  public: /* creation */

	
	Binary2Rcvr (APTR(TransferSpecialist) ARG(specialist), APTR(XnReadStream) ARG(stream));
	
	
	virtual void destroy ();
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  protected: /* protected: accessing */

	
	INLINE RPTR(XnReadStream) stream ();
	
  private:
	CHKPTR(XnReadStream) myStream;
	IntegerVar myDepth;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(InstanceCache) SomeRcvrs;
};  /* end class Binary2Rcvr */



/* ************************************************************************ *
 * 
 *                    Class Binary2Xmtr 
 *
 * ************************************************************************ */



/* Initializers for Binary2Xmtr */







	/* NO CLASS COMMENT */

class Binary2Xmtr : public SpecialistXmtr {

/* Attributes for class Binary2Xmtr */
	CONCRETE(Binary2Xmtr)
	NOT_A_TYPE(Binary2Xmtr)
	AUTO_GC(Binary2Xmtr)

/* Initializers for Binary2Xmtr */



friend class INIT_TIME_NAME(Binary2Xmtr,initTimeNonInherited);

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
	
	
	virtual void sendUInt4 (UInt4 ARG(n));
	
	
	virtual void sendUInt8 (UInt8 ARG(n));
	
	
	virtual void sendUInt8Data (APTR(UInt8Array) ARG(array));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  protected: /* protected: sending */

	/* Put in a separator pattern so we can detect the packets visually. */
	
	virtual void endPacket ();
	
	
	virtual void endThing ();
	
	/* Send a Dean style humber.  Like Drexler style, except all 
	the tag bits go into the first byte. */
	/* 
	7/1 		0<7>
	14/2	10<6>		<8>
	21/3	110<5>		<16>
	28/4	1110<4>		<24>
	35/5	11110<3>	<32>
	42/6	111110<2>	<40>
	49/7	1111110<1>	<48>
	56/8	11111110 	<56>
	?/?	11111111  <humber count>
	 */
	
	virtual void putIntegerVar (IntegerVar ARG(num));
	
	
	virtual void sendNULL ();
	
	/* start sending an instance of a particular class. Add one 
	because 0 means NULL */
	
	virtual void startNewInstance (APTR(Category) ARG(cat));
	
	
	INLINE RPTR(XnWriteStream) stream ();
	
  public: /* creation */

	
	Binary2Xmtr (APTR(TransferSpecialist) ARG(specialist), APTR(XnWriteStream) ARG(stream));
	
	
	virtual void destroy ();
	
  public: /* specialist sending */

	/* end sending an instance */
	
	virtual void endInstance ();
	
  private:
	CHKPTR(XnWriteStream) myStream;
	IntegerVar myDepth;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static Int32 MaxNumberLength;
	static UInt8 * NumberBuffer;
	static GPTR(InstanceCache) SomeXmtrs;
};  /* end class Binary2Xmtr */


#ifdef USE_INLINE
#ifndef BIN2COMP_IXX
#include "bin2comp.ixx"
#endif /* BIN2COMP_IXX */


#endif /* USE_INLINE */


#endif /* BIN2COMP_HXX */

