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

#ifndef PROLSTNX_CXX
#define PROLSTNX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef PROLSTNX_HXX
#include "prolstnx.hxx"
#endif /* PROLSTNX_HXX */

#ifndef PROLSTNX_IXX
#include "prolstnx.ixx"
#endif /* PROLSTNX_IXX */

#ifndef PROLSTNP_HXX
#include "prolstnp.hxx"
#endif /* PROLSTNP_HXX */

#ifndef PROLSTNP_IXX
#include "prolstnp.ixx"
#endif /* PROLSTNP_IXX */


#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef FLUIDX_HXX
#include "fluidx.hxx"
#endif /* FLUIDX_HXX */

#ifndef SOCKPTLX_HXX
#include "sockptlx.hxx"
#endif /* SOCKPTLX_HXX */




/* ************************************************************************ *
 * 
 *                    Class IPPromiseListener 
 *
 * ************************************************************************ */


/* creation */


RPTR(FDListener) IPPromiseListener::make (int aSocket){
	RETURN_CONSTRUCT(IPPromiseListener,(aSocket, tcsj));
}
/* A IPConnectionListener is associated with the FD of a socket 
connection to a frontend.
Its handleInput method is used to invoke a waitForAndProcessMessage 
method to handle messages
from the frontend. */


/* protected: destruct */


void IPPromiseListener::destruct (){
	mySession = NULL;
	myPortal = NULL;
	{myManager->destroy();  myManager = NULL /* don't want stale (S/CHK)PTRs */;}
	myManager = NULL;
	this->FDListener::destruct();
}
/* creation */


IPPromiseListener::IPPromiseListener (int aSocket, TCSJ) {
	CurrentChunk = this;
	myPortal = SocketPortal::make (aSocket);
	myManager = PromiseManager::make (myPortal);
	this->registerFor(aSocket);
	FePromiseSession::make (UInt8Array::string("socket"), this, myManager);
	CurrentChunk = NULL;
}
/* testing */


BooleanVar IPPromiseListener::shouldBeReady (){
	BooleanVar result;
	
	result = !this->destroyPending();
	if (!result) {
		this->destroyOKIfRequested();
	}
	
	
#if defined(WIN32) | defined(HIGHC)
	return result;
#else
	if (!result) {
		return FALSE;
	}
	size_t	nready;
	ioctl (this->descriptor (), FIONREAD, &nready);
	return nready > 0;
#endif /* WIN32 */

	
}
/* accessing */


BooleanVar IPPromiseListener::execute (){
	/* Attempt to execute another chunk.  Return whether there is 
	more to be done. */
	
	if (!CAST(XnBufferedReadStream,myPortal->readStream())->isReady()) {
		return FALSE;
	}
	CurrentChunk = this;
	{
		INSTALL_SHIELD(ex);
		SHIELD_UP_BEGIN(ex, SOCKET_ERRSFilter) {
			/*cerr << &PROBLEM(ex);*/
			
			operator<<(cerr ,(Problem*)&PROBLEM(ex));
			
			cerr << " Connection closed.\n";
			CurrentChunk = NULL;
			{this->destroy();}
			this->destroyOKIfRequested();
			return FALSE;
		} SHIELD_UP_END(ex);
		this->inRequest();
		myManager->handleRequest();
		this->notInRequest();
	}
	CurrentChunk = NULL;
	if (this->destroyOKIfRequested()) {
		return FALSE;
	} else {
		return CAST(XnBufferedReadStream,myPortal->readStream())->isReady();
	}
}



/* ************************************************************************ *
 * 
 *                    Class FePromiseSession 
 *
 * ************************************************************************ */



/* Initializers for FePromiseSession */

BUILD_FLUID(FePromiseSession,CurrentSessions, NULL, DiskManager::emulsion());	/* in FePromiseSession */


/* Initializers for FePromiseSession */



/* ceration */


RPTR(FePromiseSession) FePromiseSession::make (
		APTR(UInt8Array) port, 
		APTR(Heaper) listener, 
		APTR(PromiseManager) manager)
{
	RETURN_CONSTRUCT(FePromiseSession,(port, listener, manager));
}
/* Represent a single unique connection to the server over some 
underlying bytestream channel. */


/* accessing */


void FePromiseSession::endSession (BooleanVar withPrejudice/* = FALSE*/){
	/* Essential. Terminate this connection.  If withPrejudice is 
	false, it completes the current request and flushes all 
	output before disconnecting. */
	
	if (!withPrejudice) {
		myManager->force();
	}
	myManager = NULL;
	{myListener->destroy();  myListener = NULL /* don't want stale (S/CHK)PTRs */;}
	myListener = NULL;
	if ((Heaper * ) CurrentSessions.fluidGet() == this) {
		CurrentSessions.fluidSet(this->next());
	} else {
		CurrentSessions.fluidGet()->remove(this);
	}
}


BooleanVar FePromiseSession::isConnected (){
	/* Return whether the session has sucessfully logged in. */
	
	return myManager != NULL;
}


RPTR(FePromiseSession) OR(NULL) FePromiseSession::next (){
	return (FePromiseSession*) myNext;
}


RPTR(UInt8Array) FePromiseSession::port (){
	/* Essential. A system-specific description of the actual 
	transport medium over which the connection is being maintained. */
	
	return (UInt8Array*) myPort;
}


void FePromiseSession::remove (APTR(FePromiseSession) session){
	if (myNext != NULL) {
		if (myNext->isEqual(session)) {
			myNext = session->next();
		} else {
			myNext->remove(session);
		}
	}
}
/* creation */


FePromiseSession::FePromiseSession (
		APTR(UInt8Array) port, 
		APTR(Heaper) listener, 
		APTR(PromiseManager) manager) 
{
	myPort = port;
	myManager = manager;
	myListener = listener;
	myNext = CurrentSessions.fluidFetch();
	CurrentSessions.fluidSet(this);
}

#ifndef PROLSTNX_SXX
#include "prolstnx.sxx"
#endif /* PROLSTNX_SXX */


#ifndef PROLSTNP_SXX
#include "prolstnp.sxx"
#endif /* PROLSTNP_SXX */



#endif /* PROLSTNX_CXX */

