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

#ifndef URDIX_HXX
#define URDIX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef URDIX_OXX
#include "urdix.oxx"
#endif /* URDIX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef ARRAYX_OXX
#include "arrayx.oxx"
#endif /* ARRAYX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class SnarfHandle 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class SnarfHandle : public Heaper {

/* Attributes for class SnarfHandle */
	CONCRETE(SnarfHandle)
	NOT_A_TYPE(SnarfHandle)
	AUTO_GC(SnarfHandle)
  public: /* accessing */

	
	virtual char * getDataP ();
	
	
	virtual Int4 getDataSize ();
	
	
	virtual Int32 getSnarfID ();
	
	
	virtual BooleanVar isWritable ();
	
	
	virtual void makeWritable ();
	
	
	virtual Int32 snarfID ();
	
	/* Release the memory buffer locked into place for this snarfHandle. */
	
	virtual void thaw ();
	
  public: /* data manipulation */

	/* Store the supplied word into the snarf starting at index.  
	Put the high byte first. */
	
	virtual void put32 (Int32 ARG(index), Int32 ARG(word));
	
	/* Return the Int4 represented by the 4 bytes starting at 
	index, high byte first.  This must return a negative number 
	when appropriate. */
	
	virtual Int32 get32 (Int32 ARG(index));
	
	
	virtual void moveBytes (
			Int4 ARG(start), 
			Int4 ARG(newStart), 
			Int4 ARG(nBytes))
	;
	
  public: /* printing */

	
	virtual void printOn (ostream& ARG(oo));
	
  protected: /* protected: destruct */

	/* When a handle keeping a snarf in memory is destroyed, the 
	snarf can then move around or go off to disk. */
	
	virtual void destruct ();
	
  public: /* create */

	
	SnarfHandle (
			Int32 ARG(snarfID), 
			APTR(UInt32Array) ARG(contents), 
			APTR(Urdi) ARG(urdi))
	;
	
  private:
	UInt4 mySnarfID;
	char * myContents;
	CHKPTR(Urdi) myUrdi;
	BooleanVar isWritable;
};  /* end class SnarfHandle */



/* ************************************************************************ *
 * 
 *                    Class Urdi 
 *
 * ************************************************************************ */


/* global: make */


RPTR(Urdi)  make (String * ARG(string));


RPTR(Urdi)  make (String * ARG(string), Int4 ARG(lruMax));


RPTR(UNKNOWN)  urdi (String * ARG(string));


RPTR(UNKNOWN)  urdi (String * ARG(string), Int4 ARG(lruMax));



	/* NO CLASS COMMENT */

class Urdi : public Heaper {

/* Attributes for class Urdi */
	CONCRETE(Urdi)
	NOT_A_TYPE(Urdi)
	AUTO_GC(Urdi)
  public: /* accessing */

	
	virtual Int4 getDataSizeOfSnarf (Int32 ARG(snarf));
	
	
	virtual RPTR(UrdiView) makeReadView ();
	
	
	virtual RPTR(UrdiView) makeWriteView ();
	
	
	virtual Int4 usableSnarfs ();
	
	
	virtual Int4 usableStages ();
	
  private: /* private: private */

	
	virtual void commitWrite ();
	
	
	virtual void destruct ();
	
	
	virtual RPTR(SnarfHandle) eraseHandle (Int32 ARG(snarfID));
	
	
	virtual RPTR(SnarfHandle) getHandle (Int32 ARG(snarfID));
	
	/* This is just the number of snarfs and their size. */
	
	virtual Int4 headerSize ();
	
	/* Position the stream to start at the location in the file 
	of the give snarf. */
	
	virtual void positionStream (Int32 ARG(snarfID));
	
	
	virtual RPTR(Int1Array) readData (Int32 ARG(snarfID));
	
	
	virtual void releaseHandle (Int32 ARG(snarfID));
	
	
	virtual void writeHandle (Int32 ARG(snarfID), APTR(UInt1Array) ARG(contents));
	
  public: /* create */

	
	Urdi (String * ARG(fileName), TCSJ);
	
  private:
	void * myStream;
	CHKPTR(MuArray) OF1(SnarfHandle) myHandles;
	UInt4 myStageCount;
	UInt4 mySnarfCount;
	UInt4 mySnarfSize;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(UNKNOWN) CachedData;
	static GPTR(UNKNOWN) CachedID;
};  /* end class Urdi */



/* ************************************************************************ *
 * 
 *                    Class UrdiView 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class UrdiView : public Heaper {

/* Attributes for class UrdiView */
	CONCRETE(UrdiView)
	NOT_A_TYPE(UrdiView)
	AUTO_GC(UrdiView)
  public: /* operations */

	
	virtual void abortWrite ();
	
	
	virtual void becomeRead ();
	
	
	virtual void commitWrite ();
	
	
	virtual Int4 getDataSizeOfSnarf (Int32 ARG(snarf));
	
	
	virtual BooleanVar isWriteView ();
	
	
	virtual RPTR(SnarfHandle) makeErasingHandle (Int32 ARG(snarfID));
	
	
	virtual RPTR(SnarfHandle) makeReadHandle (Int32 ARG(snarfID));
	
	
	virtual void thawHandles ();
	

	/* automatic 0-argument constructor */
  public:
	UrdiView();
  private:
	CHKPTR(Urdi) myUrdi;
};  /* end class UrdiView */



#endif /* URDIX_HXX */

