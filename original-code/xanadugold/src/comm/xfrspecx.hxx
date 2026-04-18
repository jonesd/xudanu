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

#ifndef XFRSPECX_HXX
#define XFRSPECX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef XFRSPECX_OXX
#include "xfrspecx.oxx"
#endif /* XFRSPECX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */


#ifndef COOKBKX_OXX
#include "cookbkx.oxx"
#endif /* COOKBKX_OXX */

#ifndef NSCOTTYX_OXX
#include "nscottyx.oxx"
#endif /* NSCOTTYX_OXX */

#ifndef PARRAYX_OXX
#include "parrayx.oxx"
#endif /* PARRAYX_OXX */

#ifndef PRIMTABX_OXX
#include "primtabx.oxx"
#endif /* PRIMTABX_OXX */

#ifndef RECIPEX_OXX
#include "recipex.oxx"
#endif /* RECIPEX_OXX */


/*  */
/*  */
#include "choosex.hxx"



/* ************************************************************************ *
 * 
 *                    Class SpecialistRcvr 
 *
 * ************************************************************************ */



/* Initializers for SpecialistRcvr */




	/* myIbids maps from ibid number to already sent objects.  
	The ibids table is explicitly managed as a PtrArray because 
	it is such a bottleneck. */

class SpecialistRcvr : public Rcvr {

/* Attributes for class SpecialistRcvr */
	DEFERRED(SpecialistRcvr)
	AUTO_GC(SpecialistRcvr)

/* Initializers for SpecialistRcvr */


  public: /* receiving */

	
	virtual BooleanVar receiveBooleanVar () DEFERRED_FUNC;
	
	/* Return a category object using the internal coding that any 
		  rcvr must have to represent categories. */
	
	virtual RPTR(Category) receiveCategory () DEFERRED_FUNC;
	
	/* Fill the array with data from the stream. */
	
	virtual void receiveData (APTR(UInt8Array) ARG(array)) DEFERRED_SUBR;
	
	/* receive the next heaper */
	
	virtual RPTR(Heaper) receiveHeaper ();
	
	
	virtual IEEEDoubleVar receiveIEEEDoubleVar () DEFERRED_FUNC;
	
	
	virtual Int32 receiveInt32 () DEFERRED_FUNC;
	
	
	virtual Int8 receiveInt8 () DEFERRED_FUNC;
	
	
	virtual IntegerVar receiveIntegerVar () DEFERRED_FUNC;
	
	/* Receive an object into another object. */
	
	virtual void receiveInto (APTR(Heaper) ARG(memory));
	
	
	virtual char * receiveString () DEFERRED_FUNC;
	
	
	virtual UInt32 receiveUInt32 () DEFERRED_FUNC;
	
	
	virtual UInt8 receiveUInt8 () DEFERRED_FUNC;
	
  public: /* specialist receiving */

	/* Pull the contents of the next heaper off the wire. */
	
	virtual RPTR(Heaper) basicReceive (APTR(Recipe) ARG(recipe));
	
	/* Pull the contents of the next heaper off the wire. */
	
	virtual void basicReceiveInto (APTR(Recipe) ARG(recipe), APTR(Heaper) ARG(memory));
	
	/* Create and register a memory slot for an instance of the 
	given category. */
	
	virtual RPTR(Heaper) makeIbid (APTR(Category) ARG(cat));
	
	
	virtual void registerIbid (APTR(Heaper) ARG(obj));
	
  protected: /* protected: specialist */

	
	virtual void endOfInstance () DEFERRED_SUBR;
	
	
	virtual void endPacket ();
	
	
	virtual RPTR(Category) fetchStartOfInstance () DEFERRED_FUNC;
	
	
	virtual RPTR(TransferSpecialist) specialist ();
	
  protected: /* protected: creation */

	
	SpecialistRcvr (APTR(TransferSpecialist) ARG(specialist), TCSJ);
	
	
	virtual void destruct ();
	
  private:
	CHKPTR(TransferSpecialist) mySpecialist;
	CHKPTR(PtrArray) myIbids;
	Int4 myNextIbid;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(PtrArray) RcvrIbidCache;
};  /* end class SpecialistRcvr */



/* ************************************************************************ *
 * 
 *                    Class SpecialistXmtr 
 *
 * ************************************************************************ */



/* Initializers for SpecialistXmtr */




	/* myIbids maps from already sent heapers to their ibid numbers. */

class SpecialistXmtr : public Xmtr {

/* Attributes for class SpecialistXmtr */
	DEFERRED(SpecialistXmtr)
	AUTO_GC(SpecialistXmtr)

/* Initializers for SpecialistXmtr */


  public: /* sending */

	
	virtual void sendBooleanVar (BooleanVar ARG(b)) DEFERRED_SUBR;
	
	
	virtual void sendCategory (APTR(Category) ARG(cat)) DEFERRED_SUBR;
	
	
	virtual void sendHeaper (APTR(Heaper) ARG(object));
	
	
	virtual void sendIEEEDoubleVar (IEEEDoubleVar ARG(x)) DEFERRED_SUBR;
	
	
	virtual void sendInt32 (Int32 ARG(n)) DEFERRED_SUBR;
	
	
	virtual void sendInt8 (Int8 ARG(byte)) DEFERRED_SUBR;
	
	
	virtual void sendIntegerVar (IntegerVar ARG(n)) DEFERRED_SUBR;
	
	
	virtual void sendString (char * ARG(s)) DEFERRED_SUBR;
	
	
	virtual void sendUInt32 (UInt32 ARG(n)) DEFERRED_SUBR;
	
	
	virtual void sendUInt8 (UInt8 ARG(byte)) DEFERRED_SUBR;
	
	/* Send the contents of the UInt8Array as data. */
	
	virtual void sendUInt8Data (APTR(UInt8Array) ARG(array)) DEFERRED_SUBR;
	
  public: /* specialist sending */

	
	virtual void endInstance () DEFERRED_SUBR;
	
	/* Register heaper as an object to be sent across the wire, 
	and send cat
		 as its category. cat might be different from heaper->getCategory() 
		 if another object is being substituted for heaper. */
	
	virtual void startInstance (APTR(Heaper) ARG(heaper), APTR(Category) ARG(cat));
	
  protected: /* protected: */

	
	virtual void endPacket ();
	
	
	virtual void sendNULL () DEFERRED_SUBR;
	
	
	virtual RPTR(TransferSpecialist) specialist ();
	
	
	virtual void startNewInstance (APTR(Category) ARG(cat)) DEFERRED_SUBR;
	
  private: /* private: sending */

	/* The object represented by pos has already been sent.  Send 
	just a reference by number. */
	
	virtual void sendIbid (Int32 ARG(pos));
	
  protected: /* protected: creation */

	
	SpecialistXmtr (APTR(TransferSpecialist) ARG(specialist), TCSJ);
	
	
	virtual void destruct ();
	
  private:
	CHKPTR(TransferSpecialist) mySpecialist;
	CHKPTR(PrimIndexTable) myIbids;
	Int4 myNextIbid;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(PrimIndexTable) XmtrIbidCache;
};  /* end class SpecialistXmtr */



/* ************************************************************************ *
 * 
 *                    Class TransferSpecialist 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class TransferSpecialist : public Heaper {

/* Attributes for class TransferSpecialist */
	DEFERRED(TransferSpecialist)
	EQ(TransferSpecialist)
	AUTO_GC(TransferSpecialist)
  public: /* creation */

	/* Return a specialist that does nothing. */
	
	static RPTR(TransferSpecialist) make (APTR(Cookbook) ARG(aBook));
	
  public: /* cookbook */

	
	virtual RPTR(Category) getCategoryFor (IntegerVar ARG(no));
	
	
	virtual RPTR(Recipe) getRecipe (APTR(Category) ARG(cat));
	
	
	virtual IntegerVar numberOfCategory (APTR(Category) ARG(cat));
	
  public: /* communication */

	/* Return an object from the rcvr or NULL if cat
		 is not a category that we handle specially. */
	/* Make sure all objects created get rcvr registerIbid:
		 called on them so that the rcvr doesn't get out of sync. */
	
	virtual RPTR(Heaper) receiveHeaperFrom (APTR(Category) ARG(cat), APTR(SpecialistRcvr) ARG(rcvr)) DEFERRED_FUNC;
	
	/* Return an object from the rcvr or NULL if cat is not a 
	category that we handle specially. */
	
	virtual void receiveHeaperIntoFrom (
			APTR(Category) ARG(cat), 
			APTR(Heaper) ARG(memory), 
			APTR(SpecialistRcvr) ARG(rcvr))
	 DEFERRED_SUBR;
	
	/* Transmit heapers on xmtr.  Subclasses intercept and handle 
	special cases here. */
	
	virtual void sendHeaperTo (APTR(Heaper) ARG(hpr), APTR(SpecialistXmtr) ARG(xmtr));
	
  public: /* creation */

	
	TransferSpecialist (APTR(Cookbook) ARG(aBook), TCSJ);
	
  private:
	CHKPTR(Cookbook) myCookbook;
};  /* end class TransferSpecialist */



/* ************************************************************************ *
 * 
 *                    Class XcvrMaker 
 *
 * ************************************************************************ */



/* Initializers for XcvrMaker */

	/* NO CLASS COMMENT */

class XcvrMaker : public Heaper {

/* Attributes for class XcvrMaker */
	DEFERRED(XcvrMaker)
	NO_GC(XcvrMaker)

/* Initializers for XcvrMaker */  public: /* xcvr creation */

	
	static RPTR(XcvrMaker) make ();
	
  public: /* xcvr creation */

	
	virtual RPTR(SpecialistRcvr) makeRcvr (APTR(TransferSpecialist) ARG(specialist), APTR(XnReadStream) ARG(readStream)) DEFERRED_FUNC;
	
	
	virtual RPTR(SpecialistXmtr) makeXmtr (APTR(TransferSpecialist) ARG(specialist), APTR(XnWriteStream) ARG(writeStream)) DEFERRED_FUNC;
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  public: /* testing */

	
	virtual UInt32 actualHashForEqual ();
	
	/* Return the name by which this protocol should be known. */
	
	virtual char * id () DEFERRED_FUNC;
	
	
	virtual BooleanVar isEqual (APTR(Heaper) ARG(other));
	

	/* automatic 0-argument constructor */
  public:
	XcvrMaker();

};  /* end class XcvrMaker */



#endif /* XFRSPECX_HXX */

