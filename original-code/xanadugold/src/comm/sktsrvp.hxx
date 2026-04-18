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

#ifndef SKTSRVP_HXX
#define SKTSRVP_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef SKTSRVX_HXX
#include "sktsrvx.hxx"
#endif /* SKTSRVX_HXX */

#ifndef SKTSRVP_OXX
#include "sktsrvp.oxx"
#endif /* SKTSRVP_OXX */


#ifndef SRVLOOPX_HXX
#include "srvloopx.hxx"
#endif /* SRVLOOPX_HXX */


#ifndef NXCVRX_OXX
#include "nxcvrx.oxx"
#endif /* NXCVRX_OXX */


/*  */
/*  */
#ifdef WIN32
#	include <fdset.h>
#else
#ifdef unix
#	include <sys/time.h>
#	include <unistd.h>
#endif /* unix */
#endif /* WIN32 */
#include <sys/types.h>



/* ************************************************************************ *
 * 
 *                    Class IPRendezvousListener 
 *
 * ************************************************************************ */




	/* An IPRendezvousListener binds to a known rendezvous socket address.
		Its handleInput method accepts connection on this socket and 
	sets up a FEBE connection
		on the spawned socket, including a IPConnectionListener. */

class IPRendezvousListener : public FDListener {

/* Attributes for class IPRendezvousListener */
	CONCRETE(IPRendezvousListener)
	COPY(IPRendezvousListener,BootCuisine)
	NOT_A_TYPE(IPRendezvousListener)
	NO_GC(IPRendezvousListener)
  public: /* creation */

	
	static RPTR(FDListener) make (UInt32 ARG(anAddress));
	
  public: /* hooks: */

	
	virtual RECEIVE_HOOK void restartIPRendezvous (APTR(Rcvr) ARG(rcvr) = NULL);
	
  public: /* creation */

	
	IPRendezvousListener (UInt32 ARG(anAddress), TCSJ);
	
  public: /* accessing */

	/* A client is trying to connect to the rendezvous socket.
	Accept the connection and spawn an IPconnectionListener for them.
	NOTE: in smalltalk (only) it is not guarnteed that there is 
	anyone there.
	so we do a non blocking operation and return quietly if there isn't */
	
	virtual BooleanVar execute ();
	
	
	virtual BooleanVar shouldBeReady ();
	
  private:
	UInt32 myAddress;
};  /* end class IPRendezvousListener */



/* ************************************************************************ *
 * 
 *                    Class SelectServerLoop 
 *
 * ************************************************************************ */




	/* This is a ServerLoop designed specifically for Berkeley 
	Sockets.  It allows socket listeners to be registered and it 
	dispatches among them based on a select() call */

class SelectServerLoop : public ServerLoop {

/* Attributes for class SelectServerLoop */
	CONCRETE(SelectServerLoop)
	COPY(SelectServerLoop,BootCuisine)
	NOT_A_TYPE(SelectServerLoop)
	NO_GC(SelectServerLoop)
  public: /* creation */

	
	static RPTR(Thunk) make ();
	
  public: /* creation */

	
	SelectServerLoop ();
	
  public: /* execution */

	/* Schedule any chunks that have become active. */
	
	virtual void scheduleChunks ();
	
  protected: /* protected: accessing */

	
	virtual void deregisterChunk (APTR(ServerChunk) ARG(aChunk));
	
	
	virtual void registerChunk (APTR(ServerChunk) ARG(aChunk));
	
  private:
	NOCOPY fd_set myFDSet;
};  /* end class SelectServerLoop */



#endif /* SKTSRVP_HXX */

