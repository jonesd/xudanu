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

#ifndef SCHUNKX_CXX
#define SCHUNKX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef SCHUNKX_HXX
#include "schunkx.hxx"
#endif /* SCHUNKX_HXX */

#ifndef SCHUNKX_IXX
#include "schunkx.ixx"
#endif /* SCHUNKX_IXX */

#ifndef SCHUNKP_HXX
#include "schunkp.hxx"
#endif /* SCHUNKP_HXX */

#ifndef SCHUNKP_IXX
#include "schunkp.ixx"
#endif /* SCHUNKP_IXX */


#ifndef SRVLOOPX_HXX
#include "srvloopx.hxx"
#endif /* SRVLOOPX_HXX */




/* ************************************************************************ *
 * 
 *                    Class ChunkCleaner 
 *
 * ************************************************************************ */



/* Initializers for ChunkCleaner */

GPTR(ChunkCleaner) ChunkCleaner::FirstCleaner = NULL;


/* Initializers for ChunkCleaner */



/* cleanup */


void ChunkCleaner::beClean (){
	SPTR(ChunkCleaner) cleaner;
	
	cleaner = ChunkCleaner::FirstCleaner;
	while (cleaner != NULL) {
		cleaner->cleanup();
		cleaner = cleaner->next();
	}
}
/* Chunk cleaners perform end-of-session cleanup work.  This includes 
making sure that session level objects are released. */


/* private: accessing */


RPTR(ChunkCleaner) ChunkCleaner::next (){
	return (ChunkCleaner*) myNext;
}
/* invoking */
/* protected: create */


ChunkCleaner::ChunkCleaner () {
	myNext = ChunkCleaner::FirstCleaner;
	ChunkCleaner::FirstCleaner = this;
}



/* ************************************************************************ *
 * 
 *                    Class ServerChunk 
 *
 * ************************************************************************ */



/* Initializers for ServerChunk */

GPTR(ServerChunk) CurrentChunk = NULL;	/* in ServerChunk */
Emulsion * ServerChunk::SecretEmulsion = NULL;


/* Initializers for ServerChunk */



/* accessing */


Emulsion * ServerChunk::emulsion (){
	
	if (ServerChunk::SecretEmulsion == NULL) {
		ServerChunk::SecretEmulsion = new ListenerEmulsion();
	}
	Emulsion * 	returnValue;
	returnValue = ServerChunk::SecretEmulsion;
	return returnValue;
}
/* protected: accessing */
/* This is the superclass for all the Chunks.  Chunks represent 
pieces of the server that run for a while, then return control.  
Subclasses include Listeners that wait for input.    When manually 
destroyed, this class flags itself for cleanup after any current
request is finished--myEnding state is alive, alive in request, 
destruction requested, and ready for destruction. */


/* protected: accessing */


BooleanVar ServerChunk::destroyOKIfRequested (){
	{	BooleanVar crutch_Flag;
		/* myEndingState == ServerChunk::inRequestFlag() || myEndingState == ServerChunk::destroyRequestedFlag() */
		
		crutch_Flag = myEndingState == ServerChunk::inRequestFlag();
		if(!crutch_Flag) {
			crutch_Flag = myEndingState == ServerChunk::destroyRequestedFlag();
		}
		if (crutch_Flag) {
			myEndingState = ServerChunk::destroyReadyFlag();
			return TRUE;
		} else {
			return FALSE;
		}
	}
}


BooleanVar ServerChunk::destroyPending (){
	return myEndingState == ServerChunk::destroyRequestedFlag();
}


void ServerChunk::inRequest (){
	myEndingState = ServerChunk::inRequestFlag();
}


void ServerChunk::notInRequest (){
	if (myEndingState == ServerChunk::destroyRequestedFlag()) {
		myEndingState = ServerChunk::destroyReadyFlag();
	} else {
		if (myEndingState == ServerChunk::inRequestFlag()) {
			myEndingState = ServerChunk::aliveFlag();
		}
	}
}
/* testing */


BooleanVar ServerChunk::shouldDestroy (){
	/* Returns TRUE if this chunk wants to be deleted after 
	deregistration. */
	
	return myEndingState == ServerChunk::destroyReadyFlag();
}
/* accessing */


char * ServerChunk::fluidSpace (){
	return (char*) myFluidSpace;
}


char * ServerChunk::fluidSpace (char * aFluidSpace){
	char * 	returnValue;
	returnValue = myFluidSpace = aFluidSpace;
	return returnValue;
}
/* protected: destruct */


void ServerChunk::destruct (){
	/* ServerChunks are destroyed explicitly in the server loop. */
	
	SPTR(ServerChunk) saveChunk;
	
	if (myFluidSpace != NULL) {
		saveChunk = CurrentChunk;
		CurrentChunk = this;
		ServerChunk::emulsion()->destructAll();
		CurrentChunk = saveChunk;
	}
	ServerLoop::removeChunk(this);
	ChunkCleaner::beClean();
	this->Heaper::destruct();
}
/* creation */


ServerChunk::ServerChunk () {
	myFluidSpace = NULL;
	myEndingState = Int32Zero;
}


void ServerChunk::destroy (){
	{	BooleanVar crutch_Flag;
		/* myEndingState == ServerChunk::aliveFlag() || myEndingState == ServerChunk::destroyReadyFlag() */
		
		crutch_Flag = myEndingState == ServerChunk::aliveFlag();
		if(!crutch_Flag) {
			crutch_Flag = myEndingState == ServerChunk::destroyReadyFlag();
		}
		if (crutch_Flag) {
			this->Heaper::destroy();
		} else {
			if (myEndingState == ServerChunk::destroyRequestedFlag()) {
				BLAST(AlreadyDestroyed);
			}
			myEndingState = ServerChunk::destroyRequestedFlag();
		}
	}
}



/* ************************************************************************ *
 * 
 *                    Class ListenerEmulsion 
 *
 * ************************************************************************ */


/* accessing */


void * ListenerEmulsion::fetchNewRawSpace (size_t size){
	if (CurrentChunk == NULL) {
		 return (defaultFluidSpace = (char *) fcalloc (size, sizeof(char)));
		
		
	} else {
		 return CurrentChunk->fluidSpace( (char *) fcalloc (size, sizeof(char)) );
		
		
	}
}


void * ListenerEmulsion::fetchOldRawSpace (){
	if (CurrentChunk == NULL) {
		return (char*) defaultFluidSpace;
	} else {
		void * 	returnValue;
		returnValue = CurrentChunk->fluidSpace();
		return returnValue;
	}
}
/* creation */


ListenerEmulsion::ListenerEmulsion () {
	defaultFluidSpace = NULL;
}

#ifndef SCHUNKX_SXX
#include "schunkx.sxx"
#endif /* SCHUNKX_SXX */


#ifndef SCHUNKP_SXX
#include "schunkp.sxx"
#endif /* SCHUNKP_SXX */



#endif /* SCHUNKX_CXX */

