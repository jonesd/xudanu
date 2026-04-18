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

#ifndef PROMANX_HXX
#define PROMANX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PROMANX_OXX
#include "promanx.oxx"
#endif /* PROMANX_OXX */


#ifndef HANDLRSX_HXX
#include "handlrsx.hxx"
#endif /* HANDLRSX_HXX */

#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef BOMBX_OXX
#include "bombx.oxx"
#endif /* BOMBX_OXX */

#ifndef COMDTCTR_OXX
#include "comdtctr.oxx"
#endif /* COMDTCTR_OXX */

#ifndef LOGGERX_OXX
#include "loggerx.oxx"
#endif /* LOGGERX_OXX */

#ifndef NSCOTTYX_OXX
#include "nscottyx.oxx"
#endif /* NSCOTTYX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef PORTALX_OXX
#include "portalx.oxx"
#endif /* PORTALX_OXX */

#ifndef PRIMTABX_OXX
#include "primtabx.oxx"
#endif /* PRIMTABX_OXX */

#ifndef PROMANP_OXX
#include "promanp.oxx"
#endif /* PROMANP_OXX */

#ifndef PROMANR_OXX
#include "promanr.oxx"
#endif /* PROMANR_OXX */


/*  */
/*  */
typedef void (*VHFn) (APTR(Heaper));
#define ERRLIST_10(a,b,c,d,e,f,g,h,i,j)	STR(a),ERRLIST_9(b,c,d,e,f,g,h,i,j)
#include "loggerx.hxx"



/* ************************************************************************ *
 * 
 *                    Class PromiseManager 
 *
 * ************************************************************************ */



/* Initializers for PromiseManager */
LOGGER(BlastLog);	/* in PromiseManager */





/* exceptions: exceptions */

PROBLEM_LIST(EVERY_COMMFilter,10,(ALL_BUT,SUBCLASS_RESPONSIBILITY,URDI_JACKPOT,MEM_ALLOC_ERROR,NULL_CHKPTR,PURE_VIRTUAL,NullResponseResult,SOCKET_RECV_ERROR,SOCKET_SEND_ERROR,SanityViolation));



	/* NO CLASS COMMENT */

class PromiseManager : public Heaper {

/* Attributes for class PromiseManager */
	CONCRETE(PromiseManager)
	AUTO_GC(PromiseManager)

/* Initializers for PromiseManager */



friend class INIT_TIME_NAME(PromiseManager,initTimeNonInherited);

  public: /* constants */

	
	static Int32 ackResponse ();
	
	
	static Int32 doneResponse ();
	
	
	static Int32 errorResponse ();
	
	
	static Int32 excusedResponse ();
	
	
	static Int32 filledResponse ();
	
	
	static Int32 grabbedResponse ();
	
	
	static Int32 humberResponse ();
	
	
	static Int32 humbersResponse ();
	
	
	static Int32 IEEEResponse ();
	
	
	static Int32 IEEEsResponse ();
	
	
	static Int32 intsResponse ();
	
	/* The number that gets sent over the wire for the given 
	problem name */
	/* PromiseManager problemNumber: 'VALUE_IS_UNKIND'  */
	
	static Int32 problemNumber (char * ARG(prob));
	
	/* The number that gets sent over the wire for the given 
	problem file/line number */
	
	static Int32 problemSource (char * ARG(file), int ARG(line));
	
	
	static Int32 promisesResponse ();
	
	
	static Int32 rangeFilledResponse ();
	
	
	static Int32 releasedResponse ();
	
	
	static Int32 revisedResponse ();
	
	
	static Int32 terminatedResponse ();
	
  public: /* creation */

	
	static RPTR(PromiseManager) make (APTR(Portal) ARG(portal));
	
  public: /* detector requests */

	/* Create the comm detector and add it. */
	
	static void fillDetector (APTR(PromiseManager) ARG(pm));
	
	/* Create the comm detector and add it. */
	
	static void fillRangeDetector (APTR(PromiseManager) ARG(pm));
	
	/* Create the comm detector and add it. */
	
	static void revisionDetector (APTR(PromiseManager) ARG(pm));
	
	/* Create the comm detector and add it. */
	
	static void statusDetector (APTR(PromiseManager) ARG(pm));
	
	/* Create the comm detector and add it. */
	
	static void waitForConsequences (APTR(PromiseManager) ARG(pm));
	
	/* Create the comm detector and add it. */
	
	static void waitForWrite (APTR(PromiseManager) ARG(pm));
	
  public: /* misc requests */

	
	static void delayCast (APTR(PromiseManager) ARG(pm));
	
	
	static void equals (APTR(PromiseManager) ARG(pm));
	
	/* The zero argument version of PrimArray export. */
	
	static void export0 (APTR(PromiseManager) ARG(pm));
	
	/* The one argument version of PrimArray export. */
	
	static void export1 (APTR(PromiseManager) ARG(pm));
	
	/* The two argument version of PrimArray export. */
	
	static void export2 (APTR(PromiseManager) ARG(pm));
	
	
	static void forceIt (APTR(PromiseManager) ARG(pm));
	
	/* PromiseManager makeRequestTable. */
	
	static RPTR(PtrArray) OF1(RequestHandler) makeRequestTable ();
	
	/* For illegal requests. */
	
	static void noRequest (APTR(PromiseManager) ARG(pm));
	
	/* For illegal requests. */
	
	static void notLoggedInRequest (APTR(PromiseManager) ARG(pm));
	
	
	static void promiseHash (APTR(PromiseManager) ARG(pm));
	
	/* The one argument version of PrimArray export. */
	
	static void setCurrentAuthor (APTR(PromiseManager) ARG(pm));
	
	/* Set the fluid. */
	
	static void setCurrentKeyMaster (APTR(PromiseManager) ARG(pm));
	
	/* Set the fluid. */
	
	static void setInitialEditClub (APTR(PromiseManager) ARG(pm));
	
	/* Set the fluid. */
	
	static void setInitialOwner (APTR(PromiseManager) ARG(pm));
	
	/* Set the fluid. */
	
	static void setInitialReadClub (APTR(PromiseManager) ARG(pm));
	
	/* Set the fluid. */
	
	static void setInitialSponsor (APTR(PromiseManager) ARG(pm));
	
	
	static void shutdown (APTR(PromiseManager) ARG(pm));
	
	
	static void testKindOf (APTR(PromiseManager) ARG(pm));
	
	
	static void waiveEm (APTR(PromiseManager) ARG(pm));
	
	
	static void waiveIt (APTR(PromiseManager) ARG(pm));
	
  public: /* making requests */

	/* <sizeof> <byte>*  */
	
	static void makeFloat (APTR(PromiseManager) ARG(pm));
	
	
	static void makeFloatArray (APTR(PromiseManager) ARG(pm));
	
	
	static void makeHumber (APTR(PromiseManager) ARG(pm));
	
	
	static void makeHumberArray (APTR(PromiseManager) ARG(pm));
	
	
	static void makeIntArray (APTR(PromiseManager) ARG(pm));
	
	/* If any of the promises is an error, then pm won't return 
	the PtrArray. */
	
	static void makePtrArray (APTR(PromiseManager) ARG(pm));
	
  public: /* translate: generated */

	
	static void fillClassTable (APTR(PtrArray) ARG(table));
	
	
	static void fillRequestTable1 (APTR(PtrArray) ARG(table));
	
	
	static void fillRequestTable2 (APTR(PtrArray) ARG(table));
	
	
	static void fillRequestTable3 (APTR(PtrArray) ARG(table));
	
	
	static void fillRequestTable4 (APTR(PtrArray) ARG(table));
	
	
	static void fillRequestTable5 (APTR(PtrArray) ARG(table));
	
	/* Requests for class Promise */
	
	static void fillRequestTable (APTR(PtrArray) ARG(table));
	
  public: /* operations */

	
	virtual void force ();
	
	
	virtual void handleRequest ();
	
	/* Return true if no errors have occurred in the current 
	transaction. */
	
	virtual BooleanVar noErrors ();
	
	/* Queue up the detector event.  It will be executed after 
	the next transaction. */
	
	virtual void queueDetectorEvent (APTR(DetectorEvent) ARG(event));
	
	/* Release the promise argument.  This could return a value 
	because the PromiseManager doesn't keep any state for void promises. */
	
	virtual void waive ();
	
	/* Release a range of promise argument, given a start and a 
	count.  This could return a value because the PromiseManager 
	doesn't keep any state for void promises. */
	
	virtual void waiveMany ();
	
  public: /* comm */

	/* Optimize promise arguments that are expected to point at 
	IntValues. */
	
	virtual BooleanVar fetchBooleanVar ();
	
	
	virtual RPTR(Category) OR(NULL) fetchCategory ();
	
	
	virtual RPTR(Heaper) fetchHeaper (APTR(Category) ARG(cat));
	
	
	virtual Int32 fetchInt32 ();
	
	/* Optimize promise arguments that are expected to point at 
	IntValues. */
	
	virtual IntegerVar fetchIntegerVar ();
	
	
	virtual RPTR(Heaper) fetchNonNullHeaper (APTR(Category) ARG(cat));
	
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
	+/+	11111111  <humber count>
	 */
	/* This is smalltalk only because smalltalk doesn't do sign-extend. */
	
	virtual IntegerVar receiveIntegerVar ();
	
	
	virtual void respondBooleanVar (BooleanVar ARG(val));
	
	
	virtual void respondHeaper (APTR(Heaper) ARG(result));
	
	
	virtual void respondIntegerVar (IntegerVar ARG(val));
	
	
	virtual void respondVoid ();
	
	
	virtual void sendIEEE32 (IEEE32 ARG(f));
	
	
	virtual void sendIEEE64 (IEEE64 ARG(f));
	
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
	+/+	11111111  <humber count>
	 */
	
	virtual void sendIntegerVar (IntegerVar ARG(num));
	
	/* Register heaper with the next Server promise number and 
	increment it.  The client must stay in sync. */
	
	virtual void sendPromise (APTR(Heaper) ARG(heaper));
	
	/* Use a representation optimized for small positive numbers. */
	/* If the number is less than 255 then just send it.  
	Otherwise send 255, subtract 255 and recur. */
	
	virtual void sendResponse (Int32 ARG(num));
	
  public: /* arrays */

	/* Send a bunch of IntegerVars to the client. */
	
	virtual void sendHumbers (
			APTR(IntegerVarArray) ARG(array), 
			Int32 ARG(count), 
			Int32 ARG(start))
	;
	
	/* Send a bunch of fixed precision integers to the client. */
	
	virtual void sendIEEEs (
			APTR(PrimFloatArray) ARG(array), 
			Int32 ARG(count), 
			Int32 ARG(start))
	;
	
	/* Send a bunch of fixed precision integers to the client. */
	
	virtual void sendInts (
			APTR(PrimIntArray) ARG(array), 
			Int32 ARG(count), 
			Int32 ARG(start))
	;
	
	/* Register heaper with the next Server promise number and 
	increment it.  The client must stay in sync. */
	
	virtual void sendPromises (
			APTR(PtrArray) ARG(array), 
			Int32 ARG(count), 
			Int32 ARG(start))
	;
	
  private: /* private: comm */

	/* Release the promise argument.  This could return a value 
	because the PromiseManager doesn't keep any state for void promises. */
	
	virtual void actualWaive (IntegerVar ARG(prnum));
	
	
	virtual IntegerVar clientPromiseNumber ();
	
	/* If any acks have accumulated, flush them. */
	
	virtual void flushAcks ();
	
	
	virtual RPTR(XnReadStream) readStream ();
	
	/* Receive a request number.  The first byte is either 
	between 0 and 254 or it
		 is 255 and the second byte + 255 is the number. */
	
	virtual Int32 receiveRequestNumber ();
	
	
	virtual void respondError ();
	
	
	virtual void respondProblem (Problem * ARG(problem));
	
	
	virtual IntegerVar serverPromiseNumber ();
	
  protected: /* protected: creation */

	
	PromiseManager (
			APTR(Portal) ARG(portal), 
			char * ARG(clientID), 
			APTR(ByteShuffler) ARG(shuffler))
	;
	
	
	virtual void destruct ();
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  private:
	CHKPTR(Portal) myPortal;
	CHKPTR(XnReadStream) myReadStream;
	CHKPTR(XnWriteStream) myWriteStream;
	CHKPTR(PrimPtrTable) myActuals;
	CHKPTR(PrimIndexTable) myRefCounts;
	CHKPTR(DetectorEvent) myDetectorEvents;
	IntegerVar myNextClientPromise;
	IntegerVar myNextServerPromise;
	CHKPTR(PtrArray) myHandlers;
	IntegerVar myAcks;
	CHKPTR(ExceptionRecord) myError;
	BooleanVar amInsideRequest;
	CHKPTR(ByteShuffler) myShuffler;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(PtrArray) OF1(RequestHandler) AllRequests;
	static GPTR(PtrArray) OF1(RequestHandler) LoginRequests;
	
	
	static GPTR(PtrArray) OF1(Category) PromiseClasses;
};  /* end class PromiseManager */



#endif /* PROMANX_HXX */

