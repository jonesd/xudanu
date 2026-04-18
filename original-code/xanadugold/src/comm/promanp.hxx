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

#ifndef PROMANP_HXX
#define PROMANP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef PROMANX_HXX
#include "promanx.hxx"
#endif /* PROMANX_HXX */

#ifndef PROMANP_OXX
#include "promanp.oxx"
#endif /* PROMANP_OXX */


#ifndef PROMANR_HXX
#include "promanr.hxx"
#endif /* PROMANR_HXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class ExceptionRecord 
 *
 * ************************************************************************ */




	/* myPromise is the number of the promise that caused this 
	error.  It will be the excuse for an Excused promise. */

class ExceptionRecord : public Heaper {

/* Attributes for class ExceptionRecord */
	CONCRETE(ExceptionRecord)
	NO_GC(ExceptionRecord)
  public: /* constant */

	
	static Int32 badCategory ();
	
	
	static Int32 excused ();
	
	
	static Int32 typeMismatch ();
	
	
	static Int32 wasNull ();
	
  public: /* creation */

	
	static RPTR(ExceptionRecord) badCategory (IntegerVar ARG(promise));
	
	
	static RPTR(ExceptionRecord) excuse (IntegerVar ARG(promise));
	
	
	static RPTR(ExceptionRecord) mismatch (IntegerVar ARG(promise));
	
	
	static RPTR(ExceptionRecord) wasNull (IntegerVar ARG(promise));
	
  public: /* accessing */

	/* Return the error most useful to the client for figuring 
	out what happened.  This returns the earliest cause of an 
	error (typically a broken promise. */
	
	virtual RPTR(ExceptionRecord) best (APTR(ExceptionRecord) OR(NULL) ARG(rec));
	
	
	virtual Int32 error ();
	
	
	virtual BooleanVar isExcused ();
	
	
	virtual IntegerVar promise ();
	
  public: /* creation */

	
	ExceptionRecord (IntegerVar ARG(promise), Int32 ARG(error));
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
  private:
	IntegerVar myPromise;
	Int32 myError;
};  /* end class ExceptionRecord */



/* ************************************************************************ *
 * 
 *                    Class NoShuffler 
 *
 * ************************************************************************ */




	/* No transformation. */

class NoShuffler : public ByteShuffler {

/* Attributes for class NoShuffler */
	CONCRETE(NoShuffler)
	NO_GC(NoShuffler)
  public: /* shuffle */

	/* Do nothing. */
	
	virtual void shuffle16 (void * ARG(buffer), Int32 ARG(count));
	
	/* Do nothing. */
	
	virtual void shuffle32 (void * ARG(buffer), Int32 ARG(count));
	
	/* Do nothing. */
	
	virtual void shuffle64 (void * ARG(buffer), Int32 ARG(count));
	

	/* automatic 0-argument constructor */
  public:
	NoShuffler();

};  /* end class NoShuffler */



/* ************************************************************************ *
 * 
 *                    Class SimpleShuffler 
 *
 * ************************************************************************ */




	/* shuffle big-endian to little-endian transformation. */

class SimpleShuffler : public ByteShuffler {

/* Attributes for class SimpleShuffler */
	CONCRETE(SimpleShuffler)
	NO_GC(SimpleShuffler)
  public: /* shuffle */

	/*  shuffle alternating bytes.  */
	
	virtual void shuffle16 (void * ARG(buffer), Int32 ARG(count));
	
	/*  shuffle alternating words.  */
	
	virtual void shuffle32 (void * ARG(buffer), Int32 ARG(count));
	
	
	virtual void shuffle64 (void * ARG(buffer), Int32 ARG(count));
	

	/* automatic 0-argument constructor */
  public:
	SimpleShuffler();

};  /* end class SimpleShuffler */



/* ************************************************************************ *
 * 
 *                    Class SpecialHandler 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class SpecialHandler : public RequestHandler {

/* Attributes for class SpecialHandler */
	CONCRETE(SpecialHandler)
	NOT_A_TYPE(SpecialHandler)
	NO_GC(SpecialHandler)
  public: /* creation */

	
	static RPTR(RequestHandler) make (VHFn ARG(fn));
	
  public: /* request handling */

	
	virtual void handleRequest (APTR(PromiseManager) ARG(pm));
	
  public: /* creation */

	
	SpecialHandler (VHFn ARG(fn), TCSJ);
	
  private:
	VHFn myFn;
};  /* end class SpecialHandler */



#endif /* PROMANP_HXX */

