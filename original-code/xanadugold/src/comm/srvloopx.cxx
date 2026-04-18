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

#ifndef SRVLOOPX_CXX
#define SRVLOOPX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef SRVLOOPX_HXX
#include "srvloopx.hxx"
#endif /* SRVLOOPX_HXX */

#ifndef SRVLOOPX_IXX
#include "srvloopx.ixx"
#endif /* SRVLOOPX_IXX */


#ifndef BOOTPLNX_HXX
#include "bootplnx.hxx"
#endif /* BOOTPLNX_HXX */

#ifndef FLUIDX_HXX
#include "fluidx.hxx"
#endif /* FLUIDX_HXX */

#ifndef GCHOOKSX_HXX
#include "gchooksx.hxx"
#endif /* GCHOOKSX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef SCHUNKX_HXX
#include "schunkx.hxx"
#endif /* SCHUNKX_HXX */




/* ************************************************************************ *
 * 
 *                    Class ServerLoop 
 *
 * ************************************************************************ */



/* Initializers for ServerLoop */

GPTR(ServerLoop) ServerLoop::MyServerLoopInstance = NULL;
GPTR(MuSet) OF1(ServerChunk) ServerLoop::TheChunks = NULL;


BUILD_FLUID(Connection,CurrentServerConnection, NULL, ::globalEmulsion());	/* in ServerLoop */
BUILD_FLUID(ServerLoop,CurrentServerLoop, NULL, ::globalEmulsion());	/* in ServerLoop */



BEGIN_INIT_TIME(ServerLoop,initTimeNonInherited) {
	REQUIRES (MuSet);
	ServerLoop::TheChunks = MuSet::make ();
} END_INIT_TIME(ServerLoop,initTimeNonInherited);



/* Initializers for ServerLoop */









/* protected: accessing */


RPTR(MuSet) OF1(ServerChunk) ServerLoop::chunks (){
	WPTR(MuSet) OF1(ServerChunk) 	returnValue;
	returnValue = ServerLoop::TheChunks;
	return returnValue;
}
/* accessing */


RPTR(ServerLoop) ServerLoop::currentServerLoop (){
	WPTR(ServerLoop) 	returnValue;
	returnValue = ServerLoop::MyServerLoopInstance;
	return returnValue;
}


void ServerLoop::introduceChunk (APTR(ServerChunk) aChunk){
	ServerLoop::TheChunks->introduce(aChunk);
	if (ServerLoop::MyServerLoopInstance != NULL) {
		ServerLoop::MyServerLoopInstance->registerChunk(aChunk);
	}
}


void ServerLoop::registerServerLoop (APTR(ServerLoop) aLoop){
	if (ServerLoop::MyServerLoopInstance != NULL) {
		BLAST(CANNOT_HAVE_MULTIPLE_SERVER_LOOPS);
	}
	ServerLoop::MyServerLoopInstance = aLoop;
	BEGIN_FOR_EACH(ServerChunk,chunk,(ServerLoop::TheChunks->stepper())) {
		ServerLoop::MyServerLoopInstance->registerChunk(chunk);
	} END_FOR_EACH;
}


void ServerLoop::removeChunk (APTR(ServerChunk) aChunk){
	ServerLoop::TheChunks->wipe(aChunk);
	if (ServerLoop::MyServerLoopInstance != NULL) {
		ServerLoop::MyServerLoopInstance->deregisterChunk(aChunk);
	}
}


RPTR(ServerLoop) ServerLoop::removeServerLoop (){
	SPTR(ServerLoop) oldLoop;
	
	if (ServerLoop::MyServerLoopInstance == NULL) {
		BLAST(SERVERLOOP_IS_NULL);
		return NULL;
	}
	oldLoop = ServerLoop::MyServerLoopInstance;
	ServerLoop::MyServerLoopInstance = NULL;
	WPTR(ServerLoop) 	returnValue;
	returnValue = oldLoop;
	return returnValue;
}


void ServerLoop::scheduleTermination (){
	ServerLoop::currentServerLoop()->setTerminate(TRUE);
}
/*   This is the superclass of all server loops.  There is only one 
instance of this class in any backend.  Its execute method is the 
central backend processing loop.  When an instance is created, its 
creation method must register it with this class.  At that time, all 
listeners that have been created up to this point will be passed to 
the new server loop instance.  After this time, new listeners will be 
passed to the serverloop instance as they register themselves with this class.
 */


/* protected: accessing */


RPTR(MuSet) OF1(ServerChunk) ServerLoop::activeChunks (){
	return (MuSet*) myActiveChunks;
}


void ServerLoop::deregisterChunk (APTR(ServerChunk) aChunk){
	/* subclasses should call me too */
	
	myActiveChunks->wipe(aChunk);
}


void ServerLoop::registerChunk (APTR(ServerChunk) aChunk){
	/* subclass must call this one first */
	
	if (aChunk->execute()) {
		myActiveChunks->store(aChunk);
	}
}


void ServerLoop::setTerminate (BooleanVar toBoolean){
	myTerminateFlag = toBoolean;
}


RPTR(Stepper) ServerLoop::stepper (){
	return (Stepper*) myStepper;
}


void ServerLoop::stepper (APTR(Stepper) stepper){
	myStepper = stepper;
}


BooleanVar ServerLoop::terminate (){
	return myTerminateFlag;
}
/* execution */


void ServerLoop::execute (){
	SPTR(ServerLoop) deadLoop;
	
	{	FLUID_BIND(CurrentServerLoop,this) {
			{	FLUID_BIND(CurrentServerConnection,Connection::make (myCategory)) {
					CurrentServerConnection.fluidGet()->bootHeaper();
					ServerLoop::registerServerLoop(this);
					while (!CurrentServerLoop.fluidGet()->terminate()) {
						CurrentServerLoop.fluidGet()->stepper(CurrentServerLoop.fluidGet()->activeChunks()->stepper());
						while (CurrentServerLoop.fluidGet()->stepper()->hasValue()) {
							SPTR(ServerChunk) chunk;
							
							chunk = CAST(ServerChunk,CurrentServerLoop.fluidGet()->stepper()->fetch());
							if (!chunk->execute()) {
								CurrentServerLoop.fluidGet()->activeChunks()->remove(chunk);
								if (chunk->shouldDestroy()) {
									{chunk->destroy();  chunk = NULL /* don't want stale (S/CHK)PTRs */;}
								}
							}
							Heaplet::garbageCollect();
							RepairEngineer::repairThings();
							CurrentServerLoop.fluidGet()->stepper()->step();
						}
						CurrentServerLoop.fluidGet()->stepper(NULL);
						CurrentServerLoop.fluidGet()->scheduleChunks();
					}
					BEGIN_FOR_EACH(ServerChunk,c,(ServerLoop::TheChunks->stepper())) {
						{c->destroy();  c = NULL /* don't want stale (S/CHK)PTRs */;}
					} END_FOR_EACH;
					deadLoop = ServerLoop::removeServerLoop();
					if ((Heaper * ) deadLoop != CurrentServerLoop.fluidGet()) {
						BLAST(WRONG_SERVERLOOP);
					}
				}
			}
			CurrentServerConnection.fluidGet()->destroy();
			CurrentServerLoop.fluidGet()->destroy();
		}
	}
}
/* creation */


ServerLoop::ServerLoop () {
	this->restartServerLoop(NULL);
}
/* hooks: */


void ServerLoop::restartServerLoop (APTR(Rcvr) /* rcvr */){
	myTerminateFlag = FALSE;
	myActiveChunks = MuSet::make ();
	myStepper = NULL;
}

#ifndef SRVLOOPX_SXX
#include "srvloopx.sxx"
#endif /* SRVLOOPX_SXX */



#endif /* SRVLOOPX_CXX */

