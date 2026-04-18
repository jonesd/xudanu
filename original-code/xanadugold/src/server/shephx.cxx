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

#ifndef SHEPHX_CXX
#define SHEPHX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */

#ifndef SHEPHX_IXX
#include "shephx.ixx"
#endif /* SHEPHX_IXX */

#ifndef SHEPHP_HXX
#include "shephp.hxx"
#endif /* SHEPHP_HXX */

#ifndef SHEPHP_IXX
#include "shephp.ixx"
#endif /* SHEPHP_IXX */


#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef FLUIDX_HXX
#include "fluidx.hxx"
#endif /* FLUIDX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef WPARRAYX_HXX
#include "wparrayx.hxx"
#endif /* WPARRAYX_HXX */




/* ************************************************************************ *
 * 
 *                    Class Abraham 
 *
 * ************************************************************************ */



/* Initializers for Abraham */

GPTR(TokenSource) Abraham::TheTokenSource = NULL;


BUILD_PRIM_FLUID(BooleanVar,InsideTransactionFlag, FALSE, DiskManager::emulsion());	/* in Abraham */



BEGIN_INIT_TIME(Abraham,initTimeNonInherited) {
	
	
	Abraham::TheTokenSource = TokenSource::make ();
} END_INIT_TIME(Abraham,initTimeNonInherited);


/* global: functions */

/* Initializers for Abraham */









/* tokens */


RPTR(Abraham) Abraham::fetchShepherd (Int32 token){
	SPTR(PtrArray) table;
	
	table = CurrentPacker.fluidGet()->flockTable();
	if (token < table->count()) {
		return CAST(Abraham,table->fetch(token));
	} else {
		return NULL;
	}
}


void Abraham::returnToken (Int32 token){
	Abraham::TheTokenSource->returnToken(token);
}
/* protected: destruction */


void Abraham::becomeStub (){
	/* Replace the shepherd in memory with a type compatible stub
		 instance that shares the same hash and flockInfo. */
	/* NOTE: Should this ensure that the flock is not dirty? */
	/* Each subclass of Abraham will have an implementation of the form: 
			new (this) MyStubClass()' or:
			'this->changeClassToThatOf(ProtoStubClass)' */
	
	
	BLAST(NOT_YET_IMPLEMENTED);
	
}


void Abraham::destruct (){
	/* Called when an object is leaving RAM.  Additional behavior 
	for subclasses of Abraham:
		Tell the snarfPacker that I am leaving RAM and should be 
	removed from its tables. */
	
	if (myInfo != NULL) {
		CurrentPacker.fluidGet()->dropFlock(myToken);
	}
	this->Heaper::destruct();
}


void Abraham::dismantle (){
	/* Disconnect me from the universe and throw me off the disk. 
		
		For GC safety, we keep a strongptr to ourself -- is this 
	still necessary? */
	
	SPTR(Abraham) spt;
	SPTR(DiskManager) packer;
	
	spt = this;
	
	/* Tell the disk the flock is dismantled. */
	packer = CurrentPacker.fluidGet();
	packer->dismantleFlock(myInfo);
	packer->flockTable()->store(myToken, NULL);
	if (myInfo != NULL) {
		packer->dropFlock(myToken);
	}
}
/* protected: disk */


void Abraham::diskUpdate (){
	/* The receiver has changed and so must eventually be 
	rewritten to disk. */
	
	/* Before a newShepherd. */
	if (myInfo == NULL) {
		CurrentPacker.fluidGet()->storeAlmostNewShepherd(this);
	} else {
		CurrentPacker.fluidGet()->diskUpdate(myInfo);
	}
}


void Abraham::forget (){
	/* Record on disk that there are no more persistent pointers 
	to the receiver.  When the in core pointers go away, the 
	receiver can be dismantled from disk.  That will happen eventually. */
	
	CurrentPacker.fluidGet()->forgetFlock(myInfo);
}


void Abraham::newShepherd (){
	/* The receiver has just been created. Put it on disk. */
	
	CurrentPacker.fluidGet()->storeNewFlock(this);
}


void Abraham::remember (){
	/* Record that there are now persistent pointers to the receiver. */
	
	CurrentPacker.fluidGet()->rememberFlock(myInfo);
}
/* destruction */


void Abraham::destroy (){
	/* Tell the packer I want to go away. It will mark me 
		as forgotten and actually dismantle me when it next 
		exits a consistent block. This avoids Jackpotting 
		when destroying a tree of objects. */
	/* [myToken < CurrentPacker fluidGet flockTable count 
			ifTrue: [CurrentPacker fluidGet flockTable at: myToken 
	store: NULL]] smalltalkOnly. */
	
	CurrentPacker.fluidGet()->destroyFlock(myInfo);
}
/* testing */


UInt32 Abraham::actualHashForEqual (){
	return myHash;
}


UInt32 Abraham::contentsHash (){
	/* A hash of the contents of this flock */
	
	return this->getCategory()->hashForEqual();
}


BooleanVar Abraham::isEqual (APTR(Heaper) other){
	return this == other;
}


BooleanVar Abraham::isPurgeable (){
	/* Return false only if the object cannot be flushed to disk. 
	This will probably 
		only be false for Stamps and the like that contain session 
	level pointers. */
	
	return TRUE;
}


BooleanVar Abraham::isShepherd (){
	/* This should be replaced with an isKindOf: that first checks to see
		  if you're asking about Abraham, and then otherwise 
	possible faults. */
	
	/* Hack !!!! */
	
	return TRUE;
}


BooleanVar Abraham::isStub (){
	/* Distinguish between stubs and shepherds. */
	
	return FALSE;
}


BooleanVar Abraham::isUnlocked (){
	/* All manually generated subclasses are locked.  Automatically
		 defined unlocked classes will reimplement this. */
	
	return FALSE;
}
/* accessing */


RPTR(FlockInfo) Abraham::fetchInfo (){
	/* Return the object that describes the state of this flock 
	wrt disk. */
	/* This should be made protected. */
	
	return (FlockInfo*) myInfo;
}


void Abraham::flockInfo (APTR(FlockInfo) info){
	/* Set the object that knows where this flock is on disk.  
	Change it when the object moves. */
	
	SPTR(WeakPtrArray) flocks;
	
	
	myInfo = info;
	{	BooleanVar crutch_Flag;
		/* info->token() != myToken && myToken != NULL */
		
		crutch_Flag = info->token() != myToken;
		if(crutch_Flag) {
			crutch_Flag = myToken != NULL;
		}
		if (crutch_Flag) {
			Abraham::returnToken(myToken);
		}
	}
	myToken = myInfo->token();
	/* Register when a flockInfo has been assigned. */
	flocks = CurrentPacker.fluidGet()->flockTable();
	if (myToken != NULL) {
		/* Grow if necessary. */
		if (myToken >= flocks->count()) {
			CurrentPacker.fluidGet()->flockTable(CAST(WeakPtrArray,flocks->copyGrow(myToken)));
			{flocks->destroy();  flocks = NULL /* don't want stale (S/CHK)PTRs */;}
			flocks = CurrentPacker.fluidGet()->flockTable();
		}
	} else {
		
	}
	flocks->store(myToken, this);
	myInfo->registerInfo();
}


RPTR(FlockInfo) Abraham::getInfo (){
	/* Return the object that describes the state of this flock 
	wrt disk. */
	
	if (myInfo == NULL) {
		BLAST(MustBeInitialized);
	}
	
	return (FlockInfo*) myInfo;
}


RPTR(Category) Abraham::getShepherdStubCategory (){
	/* Return the category of stubs used for the receiver. 
	Shepherd Patriarch classes reimplement this to use more 
	specific Stub types. */
	
	
	
	BLAST(SHEPHERD_HAS_NO_STUB_DEFINED);
	return NULL;
	
}


Int32 Abraham::token (){
	/* Return the object that describes the state of this flock 
	wrt disk. */
	
	if (myToken == NULL) {
		
		myToken = Abraham::TheTokenSource->takeToken();
	}
	return myToken;
}
/* protected: create */


Abraham::Abraham () {
	/* New Shepherds must be stored to disk. */
	
	myHash = CurrentPacker.fluidGet()->nextHashForEqual();
	/* Start out remembered, changing to forgotten.  They also start out as
			 if they were on disk (newShepherd must be called to 
		make it so.  This
			 prevents intermediate diskUpdates from forcing a 
		new object to disk 
			 before creation is finished. */
	this->restartAbraham();
}


Abraham::Abraham (
		ShepFlag /* ignored */, 
		UInt32 hash, 
		APTR(FlockInfo) info) 
{
	/* This is the root of the automatically generated 
	constructors for creating Stubs. */
	
	myHash = hash;
	
	this->restartAbraham();
	if (info != NULL) {
		this->flockInfo(info);
	}
}
/* hooks: */


void Abraham::restartAbraham (APTR(Rcvr) /* trans *//* = NULL*/){
	myToken = Abraham::TheTokenSource->takeToken();
	if (myToken == NULL) 
	myInfo = NULL;
}

#ifndef SHEPHX_SXX
#include "shephx.sxx"
#endif /* SHEPHX_SXX */


#ifndef SHEPHP_SXX
#include "shephp.sxx"
#endif /* SHEPHP_SXX */



#endif /* SHEPHX_CXX */

