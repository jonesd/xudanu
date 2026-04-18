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

#ifndef SCHUNKX_HXX
#define SCHUNKX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SCHUNKX_OXX
#include "schunkx.oxx"
#endif /* SCHUNKX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */


#ifndef FLUIDX_OXX
#include "fluidx.oxx"
#endif /* FLUIDX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class ChunkCleaner 
 *
 * ************************************************************************ */



/* Initializers for ChunkCleaner */




	/* Chunk cleaners perform end-of-session cleanup work.  This 
	includes making sure that session level objects are released. */

class ChunkCleaner : public Heaper {

/* Attributes for class ChunkCleaner */
	DEFERRED(ChunkCleaner)
	EQ(ChunkCleaner)
	AUTO_GC(ChunkCleaner)

/* Initializers for ChunkCleaner */


  public: /* cleanup */

	
	static void beClean ();
	
  private: /* private: accessing */

	
	virtual RPTR(ChunkCleaner) next ();
	
  public: /* invoking */

	
	virtual void cleanup () DEFERRED_SUBR;
	
  protected: /* protected: create */

	
	ChunkCleaner ();
	
  private:
	CHKPTR(ChunkCleaner) myNext;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static GPTR(ChunkCleaner) FirstCleaner;
};  /* end class ChunkCleaner */



/* ************************************************************************ *
 * 
 *                    Class ServerChunk 
 *
 * ************************************************************************ */



/* Initializers for ServerChunk */
extern GPTR(ServerChunk) CurrentChunk;	/* in ServerChunk */




	/* This is the superclass for all the Chunks.  Chunks 
	represent pieces of the server that run for a while, then 
	return control.  Subclasses include Listeners that wait for 
	input.    When manually destroyed, this class flags itself 
	for cleanup after any current
	request is finished--myEnding state is alive, alive in 
	request, destruction requested, and ready for destruction. */

class ServerChunk : public Heaper {

/* Attributes for class ServerChunk */
	DEFERRED(ServerChunk)
	EQ(ServerChunk)
	AUTO_GC(ServerChunk)

/* Initializers for ServerChunk */


  public: /* accessing */

	
	static Emulsion * emulsion ();
	
  protected: /* protected: accessing */

	
	static INLINE Int32 aliveFlag ();
	
	
	static INLINE Int32 destroyReadyFlag ();
	
	
	static INLINE Int32 destroyRequestedFlag ();
	
	
	static INLINE Int32 inRequestFlag ();
	
  protected: /* protected: accessing */

	
	virtual BooleanVar destroyOKIfRequested ();
	
	
	virtual BooleanVar destroyPending ();
	
	
	virtual void inRequest ();
	
	
	virtual void notInRequest ();
	
  public: /* testing */

	/* Returns TRUE if this chunk wants to be deleted after 
	deregistration. */
	
	virtual BooleanVar shouldDestroy ();
	
  public: /* accessing */

	/* Attempt to execute another chunk.  Return whether there is 
	more to be done. */
	
	virtual BooleanVar execute () DEFERRED_FUNC;
	
	
	virtual char * fluidSpace ();
	
	
	virtual char * fluidSpace (char * ARG(aFluidSpace));
	
  protected: /* protected: destruct */

	/* ServerChunks are destroyed explicitly in the server loop. */
	
	virtual void destruct ();
	
  public: /* creation */

	
	ServerChunk ();
	
	
	virtual void destroy ();
	
  private:
	char * myFluidSpace;
	Int32 myEndingState;

  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static Emulsion * SecretEmulsion;
};  /* end class ServerChunk */


#ifdef USE_INLINE
#ifndef SCHUNKX_IXX
#include "schunkx.ixx"
#endif /* SCHUNKX_IXX */


#endif /* USE_INLINE */


#endif /* SCHUNKX_HXX */

