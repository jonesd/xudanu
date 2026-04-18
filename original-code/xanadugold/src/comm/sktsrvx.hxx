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

#ifndef SKTSRVX_HXX
#define SKTSRVX_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SKTSRVX_OXX
#include "sktsrvx.oxx"
#endif /* SKTSRVX_OXX */


#ifndef INITX_HXX
#include "initx.hxx"
#endif /* INITX_HXX */

#ifndef SCHUNKX_HXX
#include "schunkx.hxx"
#endif /* SCHUNKX_HXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class FDListener 
 *
 * ************************************************************************ */



/* Initializers for FDListener */


/* exceptions: exceptions */

PROBLEM_LIST(SOCKET_ERRSFilter,2,(SOCKET_RECV_ERROR,SOCKET_SEND_ERROR));



	/* This is the superclass for Listeners that use Berkeley 
	UNIX sockets. */

class FDListener : public ServerChunk {

/* Attributes for class FDListener */
	DEFERRED(FDListener)
	EQ(FDListener)
	NO_GC(FDListener)

/* Initializers for FDListener */
friend class INIT_TIME_NAME(FDListener,initTimeNonInherited);

  public: /* accessing */

	
	virtual int descriptor ();
	
	/* Attempt to execute another chunk.  Return whether there is 
	more to be done. */
	
	virtual BooleanVar execute () DEFERRED_FUNC;
	
	/* There should be data waiting on this FD. Return TRUE if I 
	am still in a reasonable state to continue, FALSE if not (in 
	which case the Listener will be destroyed by the caller) */
	
	virtual BooleanVar shouldBeReady () DEFERRED_FUNC;
	
  public: /* creation */

	
	FDListener ();
	
	
	virtual void destruct ();
	
	
	virtual void registerFor (int ARG(anFD));
	
  private:
	NOCOPY int myFD;
	friend class ServerChunk;
};  /* end class FDListener */



#endif /* SKTSRVX_HXX */

