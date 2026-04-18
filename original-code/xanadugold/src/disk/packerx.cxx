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

#ifndef PACKERX_CXX
#define PACKERX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef PACKERX_HXX
#include "packerx.hxx"
#endif /* PACKERX_HXX */

#ifndef PACKERX_IXX
#include "packerx.ixx"
#endif /* PACKERX_IXX */

#ifndef PACKERP_HXX
#include "packerp.hxx"
#endif /* PACKERP_HXX */

#ifndef PACKERP_IXX
#include "packerp.ixx"
#endif /* PACKERP_IXX */


#ifndef BOOTPLNX_HXX
#include "bootplnx.hxx"
#endif /* BOOTPLNX_HXX */

#ifndef FLKINFOX_HXX
#include "flkinfox.hxx"
#endif /* FLKINFOX_HXX */

#ifndef GRANMAPX_HXX
#include "granmapx.hxx"
#endif /* GRANMAPX_HXX */

#ifndef NEGOTI8X_HXX
#include "negoti8x.hxx"
#endif /* NEGOTI8X_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef RECIPEX_HXX
#include "recipex.hxx"
#endif /* RECIPEX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */

#ifndef STRINGX_HXX
#include "stringx.hxx"
#endif /* STRINGX_HXX */

#ifndef TXTCOMMX_HXX
#include "txtcommx.hxx"
#endif /* TXTCOMMX_HXX */




/* ************************************************************************ *
 * 
 *                    Class SnarfPacker 
 *
 * ************************************************************************ */



/* Initializers for SnarfPacker */

Int32 SnarfPacker::LRUCount = 50;

/* exceptions: private: */

/* Initializers for SnarfPacker */



/* creation */


RPTR(DiskManager) SnarfPacker::initializeUrdiOnDisk (char * fname){
	SPTR(Urdi) anUrdi;
	SPTR(UrdiView) view;
	SPTR(DiskManager) disk;
	
	anUrdi = ::urdi(fname, SnarfPacker::LRUCount);
	view = anUrdi->makeWriteView();
	SnarfInfoHandler::initializeSnarfInfo(anUrdi, view);
	view->commitWrite();
	{view->destroy();  view = NULL /* don't want stale (S/CHK)PTRs */;}
	CONSTRUCT(disk,SnarfPacker,(anUrdi, tcsj));
	CurrentPacker.fluidSet(disk);
	WPTR(DiskManager) 	returnValue;
	returnValue = CurrentPacker.fluidGet();
	return returnValue;
}


RPTR(SnarfPacker) SnarfPacker::make (char * fname){
	RETURN_CONSTRUCT(SnarfPacker,(::urdi(fname, SnarfPacker::LRUCount), tcsj));
}
/* Should myFlocks contain full flockInfos for forwarded flocks?  
Both the flags and the size mean nothing.

A SnarfPacker maintains the relationship between Shepherds and the 
set of snarfs representing the disk.  A SnarfPacker assigns flocks to 
snarfs based loosely on the flocks's Shepherd's preferences.  When a 
flock changes, it informs the SnarfPacker.  When the SnarfPacker 
decides to write to the disk, it ensures that the changed objects 
still fit in their snarf (migrating them if necessary), writes them 
to the snarf, then writes out the snarf.

mySnarfInfo {MuTable of: XuInteger}
		- How much space remains in each snarf.
mySnarfMap {MuTable of: SnarfRecord}
		- Map from snarfIDs to a SnarfRecord that handles that snarf.
myChangedSnarfs {MuSet of: XuInteger}
		- The IDs for all snarfs in which an imaged flock has changed.
myFlocks {SetTable of: XuInteger and: FlockInfo}
		- Indexed by Abraham hash, contains all FlockInfos that refer to 
flocks in memory.
		  Multiple infos may refer to the same flock if it is referenced 
through forwarding.
		  The only info considered to have the correct state wrt its flocks 
suitability for
		  purging is the info pointed to by its Abraham.
myInsideCommit {BooleanVar}
		- True while writing new and changed flocks to disk to prevent purging,
		  and during purgeClean to prevent recursive call through Purgeror 
recycling. */


/* shepherds */


void SnarfPacker::destroyFlock (APTR(FlockInfo) info){
	/* Queue destroy of the given flock.  The destroy will happen later. */
	
	SPTR(Abraham) flock;
	
	flock = info->getShepherd();
	if (::isDestructed(flock)) {
		BLAST(DestructedAbe);
	}
	info->markDestroyed();
	if (info->markForgotten()) {
		this->recordUpdate(info);
	}
	if (info->isNew()) {
		/* just so I can set a breakpoint */
		flock = flock;
	} else {
		mySnarfInfo->setForgottenFlag(info->snarfID(), TRUE);
	}
	myDestroyedFlocks->atIntIntroduce(myDestroyedFlocks->count(), flock);
}


void SnarfPacker::diskUpdate (APTR(FlockInfo) OR(NULL) info){
	if ( ! (InsideTransactionFlag.fluidFetch()) ) {
		BLAST(Must_be_inside_transation);
	}
	/* noop for unregistered flocks. */
	if (info == NULL) {
		return;
		
	}
	if (info->markContentsDirty()) {
		this->recordUpdate(info);
	}
}


void SnarfPacker::dismantleFlock (APTR(FlockInfo) info){
	/* Turn the flock designated by info into a Pumpkin.  It 
	should have completed all dismantle actions. */
	
	info->markDismantled();
	if (!info->isNew()) {
		/* Thing to do !!!! */
		
		/* Go remove this from all the forwarded locations as well. */
		this->getSnarfRecord(info->snarfID())->dismantleFlock(info);
	}
}


void SnarfPacker::dropFlock (Int32 token){
	/* The flock is being removed from memory.  For now, this is an error
		 if the flock has been updated.  If the flock has been forgotten, 
		 then it will be dismantled when next it comes in from disk.
		 Because of forwarding, there may be many FlockInfos refering
		 to the flock if it is not new. */
	
	SPTR(FlockInfo) info;
	
	info = FlockInfo::getInfo(token);
	{	BooleanVar crutch_Flag;
		/* info->isNew() || info->isForwarded() */
		
		crutch_Flag = info->isNew();
		if(!crutch_Flag) {
			crutch_Flag = info->isForwarded();
		}
		if (crutch_Flag) {
			myNewFlocks->intRemove(info->index());
		}
	}
	if (!info->isNew()) {
		if (!info->isForgotten()) {
			BLAST(OnlyRemoveUnchangedFlocks);
		}
		BEGIN_FOR_EACH(FlockInfo,oi,(myFlocks->stepperAtInt(info->flockHash()))) {
			if (oi->token() == token) {
				myFlocks->wipe(info->flockHash(), oi);
			}
		} END_FOR_EACH;
	}
	FlockInfo::removeInfo(token);
}


void SnarfPacker::forgetFlock (APTR(FlockInfo) info){
	/* Remember that there are no more persistent pointers to the shepherd
		 represented by info.  If it gets manually deleted, 
	dismantle it immediately.  
		 If it gets garbage collected, remember to dismantle it when 
	it comes back 
		 in from the disk. */
	
	if ( ! (InsideTransactionFlag.fluidFetch()) ) {
		BLAST(Must_be_inside_transation);
	}
	if (info->markForgotten()) {
		this->recordUpdate(info);
	}
	mySnarfInfo->setForgottenFlag(info->snarfID(), TRUE);
	/* Don't rewrite the entire flock if it has only been forgotten. */
	/* Thing to do !!!! */
	
}


RPTR(Turtle) SnarfPacker::getInitialFlock (){
	/* Return the starting object for the entire backend.  This 
	will be the 0th
		 flock in the first snarf following the snarfInfo tables. */
	
	SPTR(SnarfHandler) handler;
	SPTR(XnReadStream) stream;
	SPTR(Rcvr) rcvr;
	char * protocol;
	char * cookbook;
	SPTR(Agenda) agenda;
	
	if (myTurtle != NULL) {
		return (Turtle*) myTurtle;
	}
	handler = this->getReadHandler(mySnarfInfo->snarfInfoCount());
	rcvr = TextyXcvrMaker::makeReader(stream = handler->readStream(Int32Zero));
	protocol = rcvr->receiveString();
	cookbook = rcvr->receiveString();
	{rcvr->destroy();  rcvr = NULL /* don't want stale (S/CHK)PTRs */;}
	{stream->destroy();  stream = NULL /* don't want stale (S/CHK)PTRs */;}
	this->releaseReadHandler(handler);
	myXcvrMaker = ProtocolBroker::diskProtocol(protocol);
	myBook = Cookbook::make (cookbook);
	delete protocol;
	delete cookbook;
	myTurtle = CAST(Turtle,this->getFlock(mySnarfInfo->snarfInfoCount(), 1));
	myTurtle->setProtocol(myXcvrMaker, myBook);
	myNextHash = myTurtle->counter();
	/* Known bug !!!! */
	
	/* this agendaItem stepping should get done, but right now it 
		ends up happening before the backend is initialized 
		/ravi/10/22/92/ */
		/* agenda := myTurtle fetchAgenda.
			agenda ~~ NULL ifTrue:
				[InsideAgenda fluidBind: true during:
					[[myTurtle getAgenda step] whileTrue]]. */
	this->destroyAbandoned();
	return (Turtle*) myTurtle;
}


UInt32 SnarfPacker::nextHashForEqual (){
	/* Shepherds use a sequence number for their hash.  Return the next one
		and increment.  This should actually spread the hashes. */
	
	if (myNextHash == NULL) {
		BLAST(UninitializedPacker);
	}
	myNextHash->increment();
	/*  skip sequence numbers for the many object allocated
			at backend creation time that are likely to still be 
		around. */
	if ((myNextHash->count() & 134217727) == UInt32Zero) {
		myNextHash->setCount(myNextHash->count() + 100000);
	}
	return myNextHash->count().asLong();
}


void SnarfPacker::rememberFlock (APTR(FlockInfo) info){
	/* There are now persistent pointers to the shepherd help by info. */
	
	if ( ! (InsideTransactionFlag.fluidFetch()) ) {
		BLAST(Must_be_inside_transation);
	}
	if (info->markRemembered()) {
		this->recordUpdate(info);
	}
}


void SnarfPacker::storeAlmostNewShepherd (APTR(Abraham) /* shep */){
	/* Do nothing */
	
	
}


void SnarfPacker::storeInitialFlock (
		APTR(Abraham) turtle, 
		APTR(XcvrMaker) protocol, 
		APTR(Cookbook) cookbook)
{
	/* A turtle just got created!  Write out a pseudo-forwarder 
	that has all the protocol information encoded in the snarfID 
	and index. */
	
	SPTR(SnarfHandler) handler;
	Int32 length;
	SPTR(Xmtr) xmtr;
	SPTR(XnWriteStream) stream;
	
	myTurtle = CAST(Turtle,turtle);
	if ( ! (turtle->fetchInfo() == NULL) ) {
		BLAST(Must_not_have_an_info_yet);
	}
	handler = SnarfHandler::make (myUrdiView->makeErasingHandle(mySnarfInfo->snarfInfoCount()));
	handler->initializeSnarf();
	handler->allocateCells(1);
	length = ::strlen(protocol->id()) + ::strlen(cookbook->id()) + 20;
	/* Hack !!!! */
	
	/* The extra 20 is not a very good measure of overhead. */
	handler->allocate(Int32Zero, length);
	stream = handler->writeStream(IntegerVar0);
	xmtr = TextyXcvrMaker::makeWriter(stream);
	xmtr->sendString(protocol->id());
	xmtr->sendString(cookbook->id());
	{xmtr->destroy();  xmtr = NULL /* don't want stale (S/CHK)PTRs */;}
	{stream->destroy();  stream = NULL /* don't want stale (S/CHK)PTRs */;}
	mySnarfInfo->setSpaceLeft(handler->snarfID(), handler->spaceLeft());
	{handler->destroy();  handler = NULL /* don't want stale (S/CHK)PTRs */;}
	myBook = cookbook;
	myXcvrMaker = protocol;
	this->commitView();
	this->storeNewFlock(turtle);
}


void SnarfPacker::storeNewFlock (APTR(Abraham) shep){
	/* Shep just got created! On some later commit, assign it to a snarf 
		and write it to the disk. */
	
	SPTR(FlockInfo) info;
	IntegerVar newIndex;
	
	if ( ! (shep->fetchInfo() == NULL) ) {
		BLAST(Must_not_have_an_info_yet);
	}
	/* Put the flock at the next available location in myNewFlocks. */
	newIndex = myNewFlocks->highestIndex() + 1;
	if (newIndex < myLastNewCount) {
		myLastNewCount = newIndex;
	}
	info = FlockInfo::make (shep, newIndex);
	myNewFlocks->atIntIntroduce(newIndex, info);
	shep->flockInfo(info);
}
/* stubs */


RPTR(Abraham) SnarfPacker::fetchCanonical (
		UInt32 hash, 
		Int32 snarfID, 
		Int32 index)
{
	/* If something is already imaged at that location, then 
	return it. If there is already
		 an existing stub with the same hash at a different 
	location, follow them till we 
		 know that they are actually different objects. */
	
	SPTR(Stepper) flockStep;
	
	/* myFlocks may have several FlockInfos for the same flock if 
	the flocks
		 has been forwarded.  The actual location of the flock is 
	determined by 
		 the flockInfo that the shepherd points at. */
	BEGIN_FOR_EACH(FlockInfo,info,(flockStep = myFlocks->stepperAtInt(hash))) {
		{	BooleanVar crutch_Flag;
			/* info != NULL && info->snarfID() == snarfID && info->index() == index */
			
			crutch_Flag = info != NULL;
			if(crutch_Flag) {
				crutch_Flag = info->snarfID() == snarfID;
				if(crutch_Flag) {
					crutch_Flag = info->index() == index;
				}
			}
			if (crutch_Flag) {
				{flockStep->destroy();  flockStep = NULL /* don't want stale (S/CHK)PTRs */;}
				WPTR(Abraham) 	returnValue;
				returnValue = info->fetchShepherd();
				return returnValue;
			}
		}
	} END_FOR_EACH;
	/* Didn't find an info pointing to the same disk location, so 
		resolve infos
			 with the same hash to avoid forwarder aliasing. */
	flockStep = myFlocks->stepperAtInt(hash);
	if (flockStep->hasValue()) {
		SPTR(FlockLocation) newLoc;
		SPTR(FlockLocation) loc;
		SPTR(SnarfHandler) handler;
		
		loc = FlockLocation::make (snarfID, index);
		newLoc = NULL;
		while ((newLoc = (handler = this->getReadHandler(loc->snarfID()))->fetchForward(loc->index())) != NULL) {
			this->releaseReadHandler(handler);
			loc = newLoc;
		}
		this->releaseReadHandler(handler);
		BEGIN_FOR_EACH(FlockInfo,info,(flockStep)) {
			SPTR(FlockInfo) newInfo;
			
			if (info != NULL) {
				newInfo = this->resolveLocation(info);
				{	BooleanVar crutch_Flag;
					/* loc->snarfID() == newInfo->snarfID() && loc->index() == newInfo->index() */
					
					crutch_Flag = loc->snarfID() == newInfo->snarfID();
					if(crutch_Flag) {
						crutch_Flag = loc->index() == newInfo->index();
					}
					if (crutch_Flag) {
						{flockStep->destroy();  flockStep = NULL /* don't want stale (S/CHK)PTRs */;}
						WPTR(Abraham) 	returnValue;
						returnValue = newInfo->fetchShepherd();
						return returnValue;
					}
				}
			}
		} END_FOR_EACH;
	}
	return NULL;
}


void SnarfPacker::makeReal (APTR(FlockInfo) info){
	/* Retrieve from the disk the flock at index within the 
	specified snarf.  Since
		 stubs are canonical, and this only gets called by stubs, 
	the existing stub will 
		 *become* the shepherd for the flock. */
	
	SPTR(Abraham) stub;
	SPTR(SnarfHandler) handler;
	SPTR(FlockLocation) OR(NULL) loc;
	
	stub = info->getShepherd();
	if ( ! (stub->isStub()) ) {
		BLAST(Only_stubs_can_be_made_real);
	}
	/* myInsideCommit _ true. */
		/* to prevent purge during reification */
	{
		PLANT_BOMB(ResetCommit,Boom);
		ARM_BOMB(Boom,(this))
		{
			handler = this->getReadHandler(info->snarfID());
			loc = handler->fetchForward(info->index());
			/* Forwarded.  Register stub at the new 
				location.  We leave the old info in place so
							that later references through the 
				forwarder. */
			if (loc == NULL) {
				UInt32 oldHash;
				SPTR(XnReadStream) stream;
				SPTR(Rcvr) rcvr;
				
				oldHash = stub->hashForEqual();
				(rcvr = this->makeRcvr(stream = handler->readStream(info->index())))->receiveInto(stub);
				{rcvr->destroy();  rcvr = NULL /* don't want stale (S/CHK)PTRs */;}
				{stream->destroy();  stream = NULL /* don't want stale (S/CHK)PTRs */;}
				if ( ! (stub->hashForEqual() == oldHash) ) {
					BLAST(Hash_must_not_change);
				}
				info->setSize(handler->flockSize(info->index()));
				/* Receiving the flock has cleared 
					its info, so put it back */
				stub->flockInfo(info);
			} else {
				this->addInfo(
						FlockInfo::make (stub->getInfo(), loc->snarfID(), loc->index()), stub);
			}
			this->releaseReadHandler(handler);
			handler = NULL;
		}
	}
	/* If the flock is forwarded, then the first instantiate will 
		just change the location of the stub.  Retry. */
	if (info->getShepherd()->isStub()) {
		this->makeReal(stub->getInfo());
	}
}


void SnarfPacker::registerStub (
		APTR(Abraham) shep, 
		Int32 snarfID, 
		Int32 index)
{
	if ( ! (shep->isStub()) ) {
		BLAST(Must_be_stub);
	}
	this->addInfo(
			FlockInfo::remembered(shep, snarfID, index), shep);
}
/* internals */


void SnarfPacker::addInfo (APTR(FlockInfo) info, APTR(Abraham) shep){
	/* Add another flockInfo object to myFlocks with info about 
	another location for shep. */
	
	myFlocks->atIntStore(shep->hashForEqual(), info);
	shep->flockInfo(info);
}


Int32 SnarfPacker::computeSize (APTR(Abraham) flock){
	/* Send the snarf over a transmitter into a stream that just 
	counts the bytes put 
		into it. */
	
	SPTR(TransferSpecialist) specialist;
	SPTR(XnWriteStream) counter;
	SPTR(Xmtr) xmtr;
	Int32 size;
	
	counter = CountStream::make ();
	specialist = DiskCountSpecialist::make (myBook);
	xmtr = myXcvrMaker->makeXmtr(specialist, counter);
	xmtr->sendHeaper(flock);
	size = CAST(CountStream,counter)->size();
	{xmtr->destroy();  xmtr = NULL /* don't want stale (S/CHK)PTRs */;}
	/* specialist destroy. */
	{counter->destroy();  counter = NULL /* don't want stale (S/CHK)PTRs */;}
	return size;
}


RPTR(UrdiView) SnarfPacker::currentView (){
	/* Return the current urdiView. */
	
	return (UrdiView*) myUrdiView;
}


void SnarfPacker::destroyAbandoned (){
	/* Destroy all forgotten flocks that are no longer in memory. */
	
	if (TRUE) {
		return;
		
	}
	
	{
		Int32 LoopFinal = mySnarfInfo->snarfCount();
		Int32 snarfID = mySnarfInfo->snarfInfoCount();
		for (;;) {
			if (snarfID >= LoopFinal){
				break;
			}
			{
				BooleanVar reset;
				
				reset = FALSE;
				/* In case we run into unforgettable 
					objects. */
					/* Clear the flag first so 
					we'll catch newly forgotten 
					shepherds. */
				while (mySnarfInfo->getForgottenFlag(snarfID)) {
					mySnarfInfo->setForgottenFlag(snarfID, FALSE);
					BEGIN_FOR_EACH(IntegerPos,iD,(this->forgottenFlocks(snarfID)->stepper())) {
						Int32 index;
						
						index = iD->asIntegerVar().asLong();
						if (this->fetchInMemory(snarfID, index) == NULL) {
							this->getFlock(snarfID, index)->destroy();
							this->endConsistent(IntegerVarZero);
						} else {
							reset = TRUE;
						}
					} END_FOR_EACH;
				}
				if (reset) {
					mySnarfInfo->setForgottenFlag(snarfID, TRUE);
				}
			}
			snarfID += 1;
		}
	}
}


void SnarfPacker::forwardFlock (APTR(Abraham) shep){
	/* Shep has grown too large for its current place.  Treat it 
	as just a new flock and give it another place. */
	
	if ( shep->isEqual(Pumpkin::make ()) ) {
		BLAST(Only_forward_real_Flocks);
	}
	shep->getInfo()->forward(myNewFlocks->highestIndex().asLong() + 1);
	myNewFlocks->atIntIntroduce(myNewFlocks->highestIndex() + 1, shep->getInfo());
}


RPTR(SpecialistRcvr) SnarfPacker::makeRcvr (APTR(XnReadStream) readStream){
	WPTR(SpecialistRcvr) 	returnValue;
	returnValue = myXcvrMaker->makeRcvr(DiskSpecialist::make (myBook, this), readStream);
	return returnValue;
}


RPTR(SpecialistXmtr) SnarfPacker::makeXmtr (APTR(XnWriteStream) writeStream){
	WPTR(SpecialistXmtr) 	returnValue;
	returnValue = myXcvrMaker->makeXmtr(DiskSpecialist::make (myBook, this), writeStream);
	return returnValue;
}


void SnarfPacker::setHashCounter (APTR(Counter) aCounter){
	myNextHash = aCounter;
}


void SnarfPacker::testNewFlocks (){
	BEGIN_FOR_EACH(FlockInfo,info,(myNewFlocks->stepper())) {
		
	} END_FOR_EACH;
}
/* transactions */


void SnarfPacker::beginConsistent (IntegerVar dirtyFlocks){
	this->checkInfos();
	if (!InsideTransactionFlag.fluidFetch()) {
		Int32 dirtySnarfs;
		Int32 bytesPerSnarf;
		
		if (dirtyFlocks == -1) {
			dirtySnarfs = 10;
		} else {
			dirtySnarfs = min(dirtyFlocks.asLong(), 20);
		}
		bytesPerSnarf = myUrdiView->getDataSizeOfSnarf(Int32Zero);
		/* Now the dirtySnarfs from new flocks (including the 
			mapCell). */
		dirtySnarfs += ((myNewFlocks->count() * 8 + myNewEstimate) / bytesPerSnarf).asLong();
		/* Now the dirtySnarfs from changed flocks. */
		dirtySnarfs += mySnarfMap->count().asLong();
		/* Now a buffer for good measure. */
		dirtySnarfs += SpareStageSpace::cruftedSnarfsGuess();
		if (dirtySnarfs >= myUrdi->usableStages()) {
			this->makePersistent();
		}
	}
}


void SnarfPacker::endConsistent (IntegerVar /* dirty */){
	SPTR(Agenda) OR(NULL) agenda;
	
	if (InsideTransactionFlag.fluidFetch()) {
		return;
		
	}
	/* Measure all the new flocks from the previous consistent block. */
	{
		IntegerVar LoopFinal = myNewFlocks->highestIndex();
		IntegerVar i = myLastNewCount;
		for (;;) {
			if (i > LoopFinal){
				break;
			}
			{
				SPTR(FlockInfo) info;
				
				info = CAST(FlockInfo,myNewFlocks->intFetch(i));
				if (info != NULL) {
					SPTR(Abraham) shep;
					
					shep = info->fetchShepherd();
					if (shep != NULL) {
						Int32 size;
						
						size = this->computeSize(shep);
						info->setSize(size);
						/* + (size // 10) */
						myNewEstimate += size;
					}
				}
			}
			i += 1;
		}
	}
	myLastNewCount = myNewFlocks->highestIndex() + 1;
	myConsistentCount += 1;
	/* Hack !!!! */
	
	/* Do all agenda items before any destroys so we don't need 
		to worry about pointers
			 from Agenda Items into the data structures. */
	if (InsideAgenda.fluidFetch()) {
		return;
		
	}
	agenda = myTurtle->fetchAgenda();
	if (agenda != NULL) {
		{	FLUID_BIND(InsideAgenda,TRUE) {
				while (agenda->step()) {}
				
			}
		}
	}
	/* Now dismantled destroyed flocks. */
	if (myDestroyedFlocks->isEmpty()) {
		return;
		
	}
	{	FLUID_BIND(InsideAgenda,TRUE) {
			while (!myDestroyedFlocks->isEmpty()) {
				SPTR(Abraham) shep;
				
				/* The count of the table is used as 
				the index to insert things at, so it 
				get's manipulated carefully here. */
				/* The destroy table is LIFO so that 
				recursive destruction is depth first 
				(to queue size). */
				shep = CAST(Abraham,myDestroyedFlocks->intGet(myDestroyedFlocks->count() - 1));
				myDestroyedFlocks->intRemove(myDestroyedFlocks->count() - 1);
				if (shep->getInfo()->isForgotten()) {
					shep->dismantle();
				}
				myDestroyCount += 1;
			}
		}
	}
	this->checkInfos();
}


BooleanVar SnarfPacker::insideCommit (){
	return myInsideCommit;
}


void SnarfPacker::makePersistent (){
	/* The virtual image in memory is now in a consistent state. 
	Write the image of 
		all changed or new Shepherds out to the disk in a single 
	atomic action.  The 
		atomicity only happens on top of a real Urdi, however. */
	
	this->checkInfos();
	{
		PLANT_BOMB(ResetCommit,Boom);
		ARM_BOMB(Boom,(this))
		{
			myInsideCommit = TRUE;
			/* Note which flocks still fit in their 
				snarfs, and forwards ones that don't */
			this->refitFlocks();
			/* Assign all new and migrating flocks to a 
				snarf in a GC safe fashion. */
			{
				IntegerVar LoopFinal = myNewFlocks->highestIndex();
				IntegerVar i = IntegerVarZero;
				for (;;) {
					if (i > LoopFinal){
						break;
					}
					{
						SPTR(FlockInfo) info;
						
						info = CAST(FlockInfo,myNewFlocks->intFetch(i));
						/* IF we GC'd, flocks and 
							their infos might have been removed. */
						if (info != NULL) {
							SPTR(Abraham) shep;
							
							/* This might be the only 
							strong pointer to the object! */
							info->markShepNull();
							shep = info->fetchShepherd();
							if (shep != NULL) {
								this->assignSnarf(shep);
							}
						}
					}
					i += 1;
				}
			}
			/* Write out all the changes into URDI buffers. */
			this->flushFlocks();
			{myNewFlocks->destroy();  myNewFlocks = NULL /* don't want stale (S/CHK)PTRs */;}
			myNewFlocks = IntegerTable::make (500);
			this->commitView();
			
			myNewEstimate = IntegerVarZero;
		}
	}
	this->checkInfos();
}


void SnarfPacker::purge (){
	/* Flush everything out to disk and remove all purgeable imaged
		 objects from memory. */
	
	if (InsideTransactionFlag.fluidFetch()) {
		return;
		
	}
	this->makePersistent();
	this->purgeClean(TRUE);
}


void SnarfPacker::purgeClean (BooleanVar noneLocked/* = FALSE*/){
	/* purge all shepherds that are currently clean, not locked, not dirty,
		 and purgeable.  Purging just turns them into stubs, freeing 
	all their 
		 flocks.  Garbage collection can clean up the flocks and any stubs no 
		 longer pointed to by something in memory.  Because infos for new 
		 flocks don't appear in myFlocks, this will not throw out 
	any newFlocks 
		 (which will be marked dirty anyway).  For each FlockInfo, we check
		 that its flock refers to that exact instance to get correct 
	information
		 about its dirty state. */
	
	SPTR(PrimPtrTable) stackPtrs;
	
	if (myInsideCommit) {
		return;
		
	}
	{
		PLANT_BOMB(ResetCommit,Boom);
		ARM_BOMB(Boom,(this))
		{
			myInsideCommit = TRUE;
			/* to prevent recursive call */
			
			if (noneLocked) {
				stackPtrs = PrimPtrTable::make (1);
			} else {
				stackPtrs = StackExaminer::pointersOnStack();
			}
			BEGIN_FOR_EACH(FlockInfo,info,(myFlocks->stepper())) {
				SPTR(Abraham) shep;
				
				shep = info->fetchShepherd();
				
				if (shep && shep->fetchInfo() == info && !shep->isStub() && (stackPtrs->fetch((Int32)(void*)shep) == NULL) && shep->isPurgeable() && !info->isDirty()) {
			shep->becomeStub();
			}
				
			} END_FOR_EACH;
		}
	}
	if (!noneLocked) {
		myRepairer->setMustPurge();
	}
	
}
/* protected: destruction */


void SnarfPacker::destruct (){
	/* Destroy all objects imaged from this snarf. */
	
	{myPurgeror->destroy();  myPurgeror = NULL /* don't want stale (S/CHK)PTRs */;}
	if (!::isDestructed(mySnarfMap)) {
		BEGIN_FOR_EACH(Heaper,rec,(mySnarfMap->stepper())) {
			{rec->destroy();  rec = NULL /* don't want stale (S/CHK)PTRs */;}
		} END_FOR_EACH;
		{mySnarfMap->destroy();  mySnarfMap = NULL /* don't want stale (S/CHK)PTRs */;}
	}
	/* myFlocks getCategory ~= Heaper ifTrue:
				[myFlocks stepper forEach:
					[:info {FlockInfo} | 
					(Heaper isDestructed: info) ifFalse: 
						[info getShepherd flockInfo: NULL.
						info destroy]].
				myFlocks destroy].
			myNewFlocks getCategory ~= Heaper ifTrue:
				[myNewFlocks stepper forEach:
					[:info {FlockInfo} | 
					(Heaper isDestructed: info) ifFalse: 
						[info getShepherd flockInfo: NULL. 
						info destroy]].
				myNewFlocks destroy]. */
	{mySnarfInfo->destroy();  mySnarfInfo = NULL /* don't want stale (S/CHK)PTRs */;}
	myXcvrMaker = NULL;
	{myBook->destroy();  myBook = NULL /* don't want stale (S/CHK)PTRs */;}
	{myUrdiView->destroy();  myUrdiView = NULL /* don't want stale (S/CHK)PTRs */;}
	{myUrdi->destroy();  myUrdi = NULL /* don't want stale (S/CHK)PTRs */;}
	this->DiskManager::destruct();
}
/* private: */


void SnarfPacker::assignSnarf (APTR(Abraham) shep){
	/* Find a snarf in which to fit shep.  Then assign it to
		 that location, and mark that snarf as changed. */
	
	Int32 size;
	SPTR(SnarfRecord) rec;
	Int32 index;
	SPTR(FlockInfo) oldInfo;
	
	/* Migrating flocks already have a size computed.  Likewise new
		 flocks that haven't changed since they were estimated. */
	size = shep->getInfo()->oldSize();
	{	BooleanVar crutch_Flag;
		/* shep->getInfo()->isNew() && shep->getInfo()->isContentsDirty() */
		
		crutch_Flag = shep->getInfo()->isNew();
		if(crutch_Flag) {
			crutch_Flag = shep->getInfo()->isContentsDirty();
		}
		if (crutch_Flag) {
			size = this->computeSize(shep);
		}
	}
	/* Include the space for a slot in the snarf map table. */
	size += SnarfHandler::mapCellOverhead();
	/* Check that size fits in a snarf */
	/* Hack !!!! */
	
	/* This assumes that all snarfs are the same size */
	if (size > myUrdi->getDataSizeOfSnarf(Int32Zero)) {
		BLAST(Overgrazed);
	}
	/* Check in the snarf last allocated.  Search for another 
		(first up, then down) if it won't fit. */
	if (size > mySnarfInfo->getSpaceLeft(myAllocationSnarf)) {
		Int32 limitSnarf;
		Int32 snarfID;
		
		/* First search upward. */
		limitSnarf = mySnarfInfo->snarfCount();
		snarfID = myAllocationSnarf + 1;
		for (;;) {	BooleanVar crutch_Flag;
			/* snarfID < limitSnarf && size > mySnarfInfo->getSpaceLeft(snarfID) */
			
			crutch_Flag = snarfID < limitSnarf;
			if(crutch_Flag) {
				crutch_Flag = size > mySnarfInfo->getSpaceLeft(snarfID);
			}
			if (crutch_Flag) {
				snarfID += 1;
			} else {
				break;
			}
		}
		/* Then if we didn't find space, search downward. */
		if (snarfID >= limitSnarf) {
			limitSnarf = mySnarfInfo->snarfInfoCount() - 1;
			snarfID = myAllocationSnarf - 1;
			for (;;) {	BooleanVar crutch_Flag;
				/* snarfID > limitSnarf && size > mySnarfInfo->getSpaceLeft(snarfID) */
				
				crutch_Flag = snarfID > limitSnarf;
				if(crutch_Flag) {
					crutch_Flag = size > mySnarfInfo->getSpaceLeft(snarfID);
				}
				if (crutch_Flag) {
					snarfID -= 1;
				} else {
					break;
				}
			}
			if (snarfID <= limitSnarf) {
				BLAST(DiskFull);
			}
		}
		myAllocationSnarf = snarfID;
	}
	if ( ! (myAllocationSnarf >= mySnarfInfo->snarfInfoCount()) ) {
		BLAST(A_real_snarf);
	}
	if (shep->getInfo()->isForgotten()) {
		mySnarfInfo->setForgottenFlag(myAllocationSnarf, TRUE);
	}
	rec = this->getSnarfRecord(myAllocationSnarf);
	/* Update the size information and such inside the per-snarf 
		data-structure. */
	index = rec->allocate(size, shep);
	oldInfo = shep->getInfo();
	this->addInfo(
			FlockInfo::make (oldInfo, myAllocationSnarf, index), shep);
	/* Destroy the old location. */
	{	BooleanVar crutch_Flag;
		/* oldInfo->isNew() || oldInfo->isForwarded() */
		
		crutch_Flag = oldInfo->isNew();
		if(!crutch_Flag) {
			crutch_Flag = oldInfo->isForwarded();
		}
		if (crutch_Flag) {
			if (oldInfo->isForwarded()) {
				myFlocks->wipe(oldInfo->flockHash(), oldInfo);
			}
			myNewFlocks->intWipe(oldInfo->index());
			{oldInfo->destroy();  oldInfo = NULL /* don't want stale (S/CHK)PTRs */;}
		}
	}
	/* Remember the space is gone */
	mySnarfInfo->setSpaceLeft(myAllocationSnarf, rec->spaceLeft());
}


void SnarfPacker::checkInfos (){
	/* Perform the sanity check of the moment.  Beware the 
	compile cost of changing this comment. */
	/* myFlocks stepper forEach: [:info {FlockInfo} | info getShepherd].
		myNewFlocks stepper forEach: [:info {FlockInfo} | info getShepherd] */
	
	
}


void SnarfPacker::commitState (BooleanVar flag){
	/* Used by ResetCommit bomb */
	
	myInsideCommit = flag;
}


void SnarfPacker::commitView (){
	/* Commit by destroying the current view and creating a new one. */
	
	SPTR(UrdiView) newView;
	
	myUrdiView->commitWrite();
	{mySnarfInfo->destroy();  mySnarfInfo = NULL /* don't want stale (S/CHK)PTRs */;}
	mySnarfInfo = NULL;
	myUrdiView->becomeRead();
	newView = myUrdi->makeWriteView();
	{myUrdiView->destroy();  myUrdiView = NULL /* don't want stale (S/CHK)PTRs */;}
	myUrdiView = newView;
	mySnarfInfo = SnarfInfoHandler::make (myUrdi, myUrdiView);
}


RPTR(Abraham) OR(NULL) SnarfPacker::fetchInMemory (Int32 snarfID, Int32 index){
	/* Return true if the object is on disk but not in memory. */
	
	SPTR(SnarfHandler) handler;
	SPTR(FlockLocation) OR(NULL) loc;
	SPTR(XnReadStream) stream;
	SPTR(SpecialistRcvr) rcvr;
	UInt32 hash;
	SPTR(Category) cat;
	
	handler = this->getReadHandler(snarfID);
	loc = handler->fetchForward(index);
	if (loc != NULL) {
		this->releaseReadHandler(handler);
		return NULL;
	}
	/* Hack !!!! */
	
	/* This is partially reading in the flock in order to get its 
		hash!  Ick! */
	stream = handler->readStream(index);
	rcvr = CAST(SpecialistRcvr,this->makeRcvr(stream));
	if (!(cat = rcvr->receiveCategory())->isEqualOrSubclassOf(cat_Abraham)) {
		this->releaseReadHandler(handler);
		BLAST(NonShepherd);
	}
	/* Right now this keeps looking for an end-of-packet marker.  Grrr. */
	hash = rcvr->receiveUInt32();
	{rcvr->destroy();  rcvr = NULL /* don't want stale (S/CHK)PTRs */;}
	{stream->destroy();  stream = NULL /* don't want stale (S/CHK)PTRs */;}
	this->releaseReadHandler(handler);
	WPTR(Abraham) OR(NULL) 	returnValue;
	returnValue = this->fetchCanonical(hash, snarfID, index);
	return returnValue;
}


void SnarfPacker::flushFlocks (){
	/* Actually write all the changed and newly assigned flocks 
	to the disk. */
	
	BEGIN_FOR_INDICES(index,SnarfRecord,rec,(mySnarfMap->stepper())) {
		rec->flushChanges();
		mySnarfMap->intWipe(index);
		{rec->destroy();  rec = NULL /* don't want stale (S/CHK)PTRs */;}
	} END_FOR_INDICES;
	{mySnarfMap->destroy();  mySnarfMap = NULL /* don't want stale (S/CHK)PTRs */;}
	mySnarfMap = IntegerTable::make (50);
}


RPTR(MuSet) OF1(IntegerPos) SnarfPacker::forgottenFlocks (Int32 snarfID){
	/* Return the set of indices to flocks in snarf snarfID that 
	are forgotten. */
	
	SPTR(MuSet) OF1(IntegerPos) result;
	SPTR(SnarfHandler) handler;
	
	handler = this->getReadHandler(snarfID);
	result = MuSet::make ();
	{
		Int32 LoopFinal = handler->mapCount();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (handler->isForgotten(i)) {
					result->store(IntegerPos::make (i));
				}
			}
			i += 1;
		}
	}
	this->releaseReadHandler(handler);
	WPTR(MuSet) OF1(IntegerPos) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(Abraham) SnarfPacker::getFlock (Int32 snarfID, Int32 index){
	/* Return a flock at a particular location.  This needs to register
		 the flock if it doesn't exist already. */
	
	SPTR(XnReadStream) stream;
	SPTR(Rcvr) rcvr;
	SPTR(Abraham) result;
	SPTR(SnarfHandler) handler;
	SPTR(FlockLocation) forward;
	
	handler = this->getReadHandler(snarfID);
	/* Follow forwarders. */
	forward = handler->fetchForward(index);
	if (forward != NULL) {
		WPTR(Abraham) 	returnValue;
		returnValue = this->getFlock(forward->snarfID(), forward->index());
		return returnValue;
	}
	rcvr = this->makeRcvr(stream = handler->readStream(index));
	result = CAST(Abraham,rcvr->receiveHeaper());
	{rcvr->destroy();  rcvr = NULL /* don't want stale (S/CHK)PTRs */;}
	{stream->destroy();  stream = NULL /* don't want stale (S/CHK)PTRs */;}
	if (handler->isForgotten(index)) {
		this->addInfo(
				FlockInfo::forgotten(result, snarfID, index), result);
	} else {
		this->addInfo(
				FlockInfo::remembered(result, snarfID, index), result);
	}
	result->getInfo()->setSize(handler->flockSize(index));
	this->releaseReadHandler(handler);
	handler = NULL;
	WPTR(Abraham) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(SnarfHandler) SnarfPacker::getReadHandler (Int32 snarfID){
	/* Get the read handler on the snarf. */
	
	if ( ! (mySnarfInfo->getSpaceLeft(snarfID) <= myUrdiView->getDataSizeOfSnarf(snarfID)) ) {
		BLAST(Handle_must_aready_be_initialized);
	}
	WPTR(SnarfHandler) 	returnValue;
	returnValue = SnarfHandler::make (myUrdiView->makeReadHandle(snarfID));
	return returnValue;
}


RPTR(SnarfRecord) SnarfPacker::getSnarfRecord (Int32 snarfID){
	/* Return the snarfRecord for snarfID.  The SnarfRecord must 
	exist if there are
		 changed flocks imaged out of that snarf, but might not 
	otherwise.  Create it if necessary. */
	
	SPTR(SnarfRecord) rec;
	
	rec = CAST(SnarfRecord,mySnarfMap->intFetch(snarfID));
	if (rec == NULL) {
		Int32 spaceLeft;
		
		spaceLeft = mySnarfInfo->getSpaceLeft(snarfID);
		rec = 
				SnarfRecord::make (snarfID, this, spaceLeft);
		mySnarfMap->atIntIntroduce(snarfID, rec);
	}
	WPTR(SnarfRecord) 	returnValue;
	returnValue = rec;
	return returnValue;
}


void SnarfPacker::recordUpdate (APTR(FlockInfo) info){
	/* The flock represented by info has changed.  Record it in the
		 bookkeeping data-structures.  This must be called by all things 
		 that affect whether the flock gets rewritten to disk. */
	/* The following test should be unnecessary because infos for
		 new flocks should already be dirty, so we shouldn't get here. */
	
	if (!info->isNew()) {
		this->getSnarfRecord(info->snarfID())->changedFlock(info->index(), info->getShepherd());
	}
}


void SnarfPacker::refitFlocks (){
	/* Make sure all flocks that have changed still fit in their snarfs. 
		 Add any that don't to myNewFlocks and return the table 
		 from their current locations to the newShepherds. */
	
	BEGIN_FOR_INDICES(snarfID,SnarfRecord,rec,(mySnarfMap->stepper())) {
		rec->refitFlocks();
		mySnarfInfo->setSpaceLeft(snarfID.asLong(), rec->spaceLeft());
	} END_FOR_INDICES;
}


void SnarfPacker::releaseReadHandler (APTR(SnarfHandler) handler){
	/* Release the supplied snarfHandler and destroy it. */
	
	if ( handler->isWritable() ) {
		BLAST(Must_be_read_handle);
	}
	{handler->destroy();  handler = NULL /* don't want stale (S/CHK)PTRs */;}
}


RPTR(FlockInfo) SnarfPacker::resolveLocation (APTR(FlockInfo) info){
	/* Make sure that the shepherd or stub at that location actually points
		 at the real location for a shepherd.  This will resolve 
	forwarding pointers, 
		 but not instantiate any flocks. */
	
	SPTR(FlockInfo) newInfo;
	SPTR(FlockLocation) loc;
	SPTR(SnarfHandler) handler;
	
	if ( info->isNew() ) {
		BLAST(No_new_flocks_allowed);
	}
	loc = NULL;
	newInfo = info;
	while ((loc = (handler = this->getReadHandler(newInfo->snarfID()))->fetchForward(newInfo->index())) != NULL) {
		this->releaseReadHandler(handler);
		newInfo = 
				FlockInfo::make (info, loc->snarfID(), loc->index());
		this->addInfo(newInfo, info->getShepherd());
	}
	this->releaseReadHandler(handler);
	WPTR(FlockInfo) 	returnValue;
	returnValue = newInfo;
	return returnValue;
}
/* protected: creation */


SnarfPacker::SnarfPacker (APTR(Urdi) urdi, TCSJ) {
	myTurtle = NULL;
	myXcvrMaker = XcvrMaker::make ();
	/* Put in a bogus protocol maker. */
	myBook = NULL;
	myUrdi = urdi;
	myUrdiView = urdi->makeWriteView();
	mySnarfInfo = SnarfInfoHandler::make (urdi, myUrdiView);
	myAllocationSnarf = Int32Zero;
	mySnarfMap = IntegerTable::make (50);
	myFlocks = SetTable::make (IntegerSpace::make (), 501);
	myNewFlocks = IntegerTable::make (500);
	myDestroyedFlocks = MuArray::array();
	myConsistentCount = IntegerVarZero;
	myNextHash = NULL;
	myInsideCommit = FALSE;
	myDestroyCount = Int32Zero;
	myPurgeror = Purgeror::make (this);
	myRepairer = LiberalPurgeror::make (this);
	myNewEstimate = IntegerVarZero;
	myLastNewCount = IntegerVarZero;
	/* AbandonDisk make: self. */
	PersistentCleaner::make ();
}
/* testing */


BooleanVar SnarfPacker::isFake (){
	return FALSE;
}



/* ************************************************************************ *
 * 
 *                    Class CountStream 
 *
 * ************************************************************************ */



/* Initializers for CountStream */

GPTR(InstanceCache) CountStream::SomeStreams = NULL;



BEGIN_INIT_TIME(CountStream,initTimeNonInherited) {
	CountStream::SomeStreams = InstanceCache::make (16);
} END_INIT_TIME(CountStream,initTimeNonInherited);



/* Initializers for CountStream */






/* creation */


RPTR(XnWriteStream) CountStream::make (){
	SPTR(Heaper) result;
	
	result = CountStream::SomeStreams->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(CountStream,());
	} else {
		WPTR(XnWriteStream) 	returnValue;
		returnValue = new (result) CountStream();
		return returnValue;
	}
}
/* create */


CountStream::CountStream () {
	mySize = Int32Zero;
}


void CountStream::destroy (){
	if (!CountStream::SomeStreams->store(this)) {
		this->XnWriteStream::destroy();
	}
}
/* accessing */


void CountStream::flush (){
	/* Must be a no-op since Xmtrs flush when done. */
	
	
}


void CountStream::putByte (UInt32 /* byte */){
	mySize += 1;
}


void CountStream::putData (APTR(UInt8Array) array){
	mySize += array->count();
}


void CountStream::putStr (char * string){
	mySize += ::strlen(string);
}


Int32 CountStream::size (){
	return mySize;
}
/* printing */


void CountStream::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << mySize << ")";
}



/* ************************************************************************ *
 * 
 *                    Class DiskCountSpecialist 
 *
 * ************************************************************************ */



/* Initializers for DiskCountSpecialist */

Int32 DiskCountSpecialist::MaxSnarfs = 3000000;
Int32 DiskCountSpecialist::MaxFlocks = 3000000;
GPTR(InstanceCache) DiskCountSpecialist::SomeSpecialists = NULL;



BEGIN_INIT_TIME(DiskCountSpecialist,initTimeNonInherited) {
	DiskCountSpecialist::SomeSpecialists = InstanceCache::make (16);
} END_INIT_TIME(DiskCountSpecialist,initTimeNonInherited);



/* Initializers for DiskCountSpecialist */






/* creation */


RPTR(TransferSpecialist) DiskCountSpecialist::make (APTR(Cookbook) aBook){
	SPTR(Heaper) result;
	
	result = DiskCountSpecialist::SomeSpecialists->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(DiskCountSpecialist,(aBook, tcsj));
	} else {
		WPTR(TransferSpecialist) 	returnValue;
		returnValue = new (result) DiskCountSpecialist(aBook, tcsj);
		return returnValue;
	}
}
/* creation */


DiskCountSpecialist::DiskCountSpecialist (APTR(Cookbook) cookbook, TCSJ) 
	: TransferSpecialist(cookbook, tcsj) {
	myInsideShepherd = FALSE;
}


void DiskCountSpecialist::destroy (){
	if (!DiskCountSpecialist::SomeSpecialists->store(this)) {
		this->TransferSpecialist::destroy();
	}
}
/* communication */


RPTR(Heaper) DiskCountSpecialist::receiveHeaperFrom (APTR(Category) /* cat */, APTR(SpecialistRcvr) /* rcvr */){
	/* DiskCountSpecialist are only for sending. */
	
	BLAST(IncompleteAbstraction);
	return NULL;
}


void DiskCountSpecialist::receiveHeaperIntoFrom (
		APTR(Category) /* cat */, 
		APTR(Heaper) /* memory */, 
		APTR(SpecialistRcvr) /* rcvr */)
{
	/* DiskCountSpecialist are only for sending. */
	
	BLAST(IncompleteAbstraction);
}


void DiskCountSpecialist::sendHeaperTo (APTR(Heaper) hpr, APTR(SpecialistXmtr) xmtr){
	/* Handle sending Shepherds specially. */
	
	BEGIN_CHOOSE(hpr) {
		BEGIN_KIND(Abraham,abe) {
			if (myInsideShepherd) {
				abe->getInfo();
				/* Test to verify that all 
					persistently pointed-at sheps 
					didi newShepherd. */
				xmtr->startInstance(abe, abe->getShepherdStubCategory());
				xmtr->sendUInt32(abe->hashForEqual());
				
				xmtr->sendUInt32(DiskCountSpecialist::MaxSnarfs);
				xmtr->sendUInt32(DiskCountSpecialist::MaxFlocks);
				xmtr->endInstance();
			} else {
				myInsideShepherd = TRUE;
				this->TransferSpecialist::sendHeaperTo(abe, xmtr);
				myInsideShepherd = FALSE;
			}
			return;
			
		} END_KIND;
		BEGIN_OTHERS {
			this->TransferSpecialist::sendHeaperTo(hpr, xmtr);
		} END_OTHERS;
	} END_CHOOSE;
}



/* ************************************************************************ *
 * 
 *                    Class DiskIniter 
 *
 * ************************************************************************ */


/* running */


void DiskIniter::execute (){
	SPTR(XcvrMaker) maker;
	SPTR(Cookbook) cookbook;
	SPTR(Turtle) turtle;
	SPTR(Connection) conn;
	
	DiskManager::initializeDisk(myFilename);
	maker = ProtocolBroker::diskProtocol();
	cookbook = Cookbook::make (myCategory);
	turtle = 
			Turtle::make (cookbook, myCategory, maker);
	conn = Connection::make (myCategory);
	turtle->saveBootHeaper(conn->bootHeaper());
	CAST(BeGrandMap,conn->bootHeaper())->bePurgeable();
	CurrentPacker.fluidGet()->purge();
	/* Let's make sure that the GC gets as much as possible. */
		/* [WorksBootMaker] USES.
			GrandConnection fluidSet: NULL. */
	conn = NULL;
	turtle = NULL;
	maker = NULL;
	cookbook = NULL;
	CurrentPacker.fluidGet()->destroy();
	CurrentPacker.fluidSet((DiskManager * ) NULL);
}

	/* automatic 0-argument constructor */
DiskIniter::DiskIniter() {}



/* ************************************************************************ *
 * 
 *                    Class DiskSpecialist 
 *
 * ************************************************************************ */



/* Initializers for DiskSpecialist */

GPTR(InstanceCache) DiskSpecialist::SomeSpecialists = NULL;



BEGIN_INIT_TIME(DiskSpecialist,initTimeNonInherited) {
	DiskSpecialist::SomeSpecialists = InstanceCache::make (16);
} END_INIT_TIME(DiskSpecialist,initTimeNonInherited);



/* Initializers for DiskSpecialist */






/* stream creation */


RPTR(TransferSpecialist) DiskSpecialist::make (APTR(Cookbook) book, APTR(DiskManager) packer){
	SPTR(Heaper) result;
	
	result = DiskSpecialist::SomeSpecialists->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(DiskSpecialist,(book, packer));
	} else {
		WPTR(TransferSpecialist) 	returnValue;
		returnValue = new (result) DiskSpecialist(book, packer);
		return returnValue;
	}
}
/* communication */


RPTR(Heaper) DiskSpecialist::receiveHeaperFrom (APTR(Category) cat, APTR(SpecialistRcvr) rcvr){
	/* There's a lot of smalltalk only stuff in here.  Smalltalk 
	stubs should move towards c++ stubs. */
	
	Int32 snarfID;
	Int32 index;
	UInt32 hash;
	SPTR(Heaper) result;
	
	
	if (!cat->isEqualOrSubclassOf(cat_Abraham)) {
		WPTR(Heaper) 	returnValue;
		returnValue = rcvr->basicReceive(this->getRecipe(cat));
		return returnValue;
	}
	if (!myInsideShepherd) {
		myInsideShepherd = TRUE;
		result = rcvr->basicReceive(this->getRecipe(cat));
		myInsideShepherd = FALSE;
		WPTR(Heaper) 	returnValue;
		returnValue = result;
		return returnValue;
	}
	hash = rcvr->receiveUInt32();
	
	snarfID = rcvr->receiveUInt32();
	index = rcvr->receiveUInt32();
	result = 
			myPacker->fetchCanonical(hash, snarfID, index);
	if (result == NULL) {
		
		result = CAST(StubRecipe,this->getRecipe(cat))->parseStub(rcvr, hash);
		
		if ( ! (result != NULL) ) {
			BLAST(Bad_Stub);
		}
		myPacker->registerStub(CAST(Abraham,result), snarfID, index);
	}
	rcvr->registerIbid(result);
	WPTR(Heaper) 	returnValue;
	returnValue = result;
	return returnValue;
}


void DiskSpecialist::receiveHeaperIntoFrom (
		APTR(Category) cat, 
		APTR(Heaper) memory, 
		APTR(SpecialistRcvr) rcvr)
{
	/* Return an object from the rcvr or NULL if cat is not a 
	category that we 
		handle specially. */
	
	if (cat->isEqualOrSubclassOf(cat_Abraham)) {
		if (this->getRecipe(cat)->isKindOf(cat_StubRecipe)) {
			BLAST(NotBecomable);
		} else {
			if (!myInsideShepherd) {
				myInsideShepherd = TRUE;
				rcvr->basicReceiveInto(this->getRecipe(cat), memory);
				myInsideShepherd = FALSE;
				return;
				
			}
		}
	}
	rcvr->basicReceiveInto(this->getRecipe(cat), memory);
}


void DiskSpecialist::sendHeaperTo (APTR(Heaper) hpr, APTR(SpecialistXmtr) xmtr){
	/* Handle sending Shepherds specially. */
	
	BEGIN_CHOOSE(hpr) {
		BEGIN_KIND(Abraham,abe) {
			if (myInsideShepherd) {
				abe->getInfo();
				/* Test to verify that all 
					persistently pointed-at sheps 
					didi newShepherd. */
				xmtr->startInstance(abe, abe->getShepherdStubCategory());
				xmtr->sendUInt32(abe->hashForEqual());
				
				xmtr->sendUInt32(abe->getInfo()->snarfID());
				xmtr->sendUInt32(abe->getInfo()->index());
				xmtr->endInstance();
			} else {
				myInsideShepherd = TRUE;
				this->TransferSpecialist::sendHeaperTo(abe, xmtr);
				myInsideShepherd = FALSE;
			}
			return;
			
		} END_KIND;
		BEGIN_OTHERS {
			this->TransferSpecialist::sendHeaperTo(hpr, xmtr);
		} END_OTHERS;
	} END_CHOOSE;
}
/* create */


DiskSpecialist::DiskSpecialist (APTR(Cookbook) cookbook, APTR(DiskManager) packer) 
	: TransferSpecialist(cookbook, tcsj) {
	myPacker = packer;
	myInsideShepherd = FALSE;
}


void DiskSpecialist::destroy (){
	if (!DiskSpecialist::SomeSpecialists->store(this)) {
		this->TransferSpecialist::destroy();
	}
}



/* ************************************************************************ *
 * 
 *                    Class PersistentCleaner 
 *
 * ************************************************************************ */



/* Initializers for PersistentCleaner */

GPTR(PersistentCleaner) PersistentCleaner::ThePersistentCleaner = NULL;


/* Initializers for PersistentCleaner */



/* create */


RPTR(PersistentCleaner) PersistentCleaner::make (){
	if (PersistentCleaner::ThePersistentCleaner == NULL) {
		CONSTRUCT(PersistentCleaner::ThePersistentCleaner,PersistentCleaner,());
	}
	WPTR(PersistentCleaner) 	returnValue;
	returnValue = PersistentCleaner::ThePersistentCleaner;
	return returnValue;
}
/* This does a makePersistent when ServerChunks go away */


/* invoking */


void PersistentCleaner::cleanup (){
	CurrentPacker.fluidGet()->purge();
}
/* protected: create */


PersistentCleaner::PersistentCleaner () {
	
}



/* ************************************************************************ *
 * 
 *                    Class Pumpkin 
 *
 * ************************************************************************ */



/* Initializers for Pumpkin */

GPTR(Abraham) Pumpkin::TheGreatPumpkin = NULL;


/* Initializers for Pumpkin */



/* pcreate */


WPTR(Abraham) Pumpkin::make (){
	/* Just return the soleInstance. */
	
	if (Pumpkin::TheGreatPumpkin == NULL) {
		CONSTRUCT(Pumpkin::TheGreatPumpkin,Pumpkin,(1, tcsj));
		Pumpkin::TheGreatPumpkin->flockInfo(
				FlockInfo::remembered(Pumpkin::TheGreatPumpkin, Int32Zero, Int32Zero));
	}
	WPTR(Abraham) 	returnValue;
	returnValue = Pumpkin::TheGreatPumpkin;
	return returnValue;
}
/* protected: protected */


void Pumpkin::becomeStub (){
	/* This can only be implemented by classes which are shepherds. */
	/* Each subclass will have expressions of the form: 'new 
	(this) MyStubClass()' */
	
	BLAST(SHOULD_NOT_IMPLEMENT);
}
/* creation */


Pumpkin::Pumpkin (UInt32 hash, TCSJ) 
	: Abraham(hash, tcsj) {
	
}



/* ************************************************************************ *
 * 
 *                    Class SnarfRecord 
 *
 * ************************************************************************ */


/* pcreate */


RPTR(SnarfRecord) SnarfRecord::make (
		Int32 snarfID, 
		APTR(SnarfPacker) packer, 
		Int32 spaceLeft)
{
	RETURN_CONSTRUCT(SnarfRecord,(snarfID, packer, spaceLeft));
}
/* Manage retrieval, refitting, and rewriting of existing flocks.  
Assign indices for new flocks.  

SnarfRecords can go away after their contents have been flushed.  We 
might keep it around if we expect to be assigning new flocks to the 
snarf again, just to keep myOccupied.  The snarfRecord will be 
recreated when another object is read in. */


/* writing */


Int32 SnarfRecord::allocate (Int32 size, APTR(Abraham) shep){
	/* Shep is being newly added to this snarf.  Allocate enough 
	space for it and return the newly assigned index for it. */
	/* The spaceLeft that we compute includes the size of the 
	cells, otherwise we couldn't keep the number up to date. */
	
	IntegerVar index;
	
	if ( ! (size <= mySpaceLeft) ) {
		BLAST(Must_have_space_left);
	}
	if ( shep->isEqual(Pumpkin::make ()) ) {
		BLAST(Only_allocate_real_shepherds);
	}
	if ( shep->isStub() ) {
		BLAST(Must_be_instantiated);
	}
	/* Thing to do !!!! */
	
	/* A hash check to see if shep is being forwarded back to 
		this snarf from elsewhere. */
	index = this->allocateIndex();
	shep->getInfo()->setSize(size - SnarfHandler::mapCellOverhead());
	this->setSpaceLeft(mySpaceLeft - size);
	myChangedFlocks->store(index, shep);
	return index.asLong();
}


void SnarfRecord::changedFlock (Int32 index, APTR(Abraham) shep){
	/* Remember that the flock at index must be written to the 
	snarf on the next update. */
	
	if ( shep->isEqual(Pumpkin::make ()) ) {
		BLAST(Record_changes_for_real_objects_only);
	}
	/* We don't return the flock's space to the pool here because 
		it might be a forwarded flock. */
	if ( ::isDestructed(shep) ) {
		BLAST(Must_not_be_destructed);
	}
	if ( shep->isStub() ) {
		BLAST(Must_be_instantiated);
	}
	myChangedFlocks->store(index, shep);
}


void SnarfRecord::dismantleFlock (APTR(FlockInfo) info){
	/* Remove the flock from the disk.  Replace it with a Pumpkin 
	so that the 
		 routine that flushes to disk knows to remove whatever's 
	there already. */
	/* Remove the flocks space allocation now so that we can 
	reallocate from the newly created pool. */
	
	
	this->setSpaceLeft(mySpaceLeft + info->oldSize());
	myChangedFlocks->store(info->index(), Pumpkin::make ());
	myDestroyCount += 1;
}
/* transactions */


void SnarfRecord::flushChanges (){
	/* Rewrite all flocks that have changed in this snarf. */
	
	Int32 highest;
	SPTR(SnarfHandler) handler;
	IntegerVar newHighest;
	SPTR(PrimPtrTableStepper) stepper;
	SPTR(Abraham) shep;
	
	handler = this->getWriteHandler();
	highest = handler->mapCount();
	newHighest = this->wipeBelowHighest(highest, handler);
	/* mySpaceLeft also has the size of the cells taken out of it. */
	/* Thing to do !!!! */
	
	/* Depending on tests, this might also preclear the total space for all
				of the flocks to be written.  Then we will only 
		compact once, and do
				it before writing any flocks. */
	/* Hack !!!! */
	
	/* This should get the highest index from myOccupied, except 
		that it might not be computed. */
	handler->allocateCells(newHighest - highest);
	stepper = myChangedFlocks->stepper();
	while ((shep = CAST(Abraham,stepper->fetch())) != NULL) {
		IntegerVar index;
		
		index = stepper->index();
		if (!shep->isEqual(Pumpkin::make ())) {
			/* Not forwarded. */
				/* We only get here for forwarded flocks. */
			if (shep->getInfo()->snarfID() == mySnarfID) {
				SPTR(Xmtr) xmtr;
				SPTR(XnWriteStream) stream;
				
				if ( shep->isStub() ) {
					BLAST(Must_be_instantiated);
				}
				handler->allocate(index, shep->getInfo()->oldSize());
				stream = handler->writeStream(index);
				xmtr = myPacker->makeXmtr(stream);
				xmtr->sendHeaper(shep);
				{xmtr->destroy();  xmtr = NULL /* don't want stale (S/CHK)PTRs */;}
				{stream->destroy();  stream = NULL /* don't want stale (S/CHK)PTRs */;}
				handler->storeForget(index.asLong(), shep->getInfo()->isForgotten());
				shep->getInfo()->commitFlags();
				shep->getInfo()->clearContentsDirty();
			} else {
				handler->forwardTo(index, shep->getInfo()->snarfID(), shep->getInfo()->index());
			}
		}
		stepper->step();
	}
	{stepper->destroy();  stepper = NULL /* don't want stale (S/CHK)PTRs */;}
	myChangedFlocks->clearAll();
	{handler->destroy();  handler = NULL /* don't want stale (S/CHK)PTRs */;}
}


void SnarfRecord::refitFlocks (){
	/* Recompute size information for all changed shepherds and 
	see if they still fit.
		 Any that don't get handed to the SnarfPacker to treat as 
	new flocks.   The 
		 old space changed and dismantled flocks has been returned 
	to the pool.  
		 Reallocate space for the changed flocks out of the pool.  
	Any that don't fit 
		 are handed back to myPacker to go in other snarfs. */
	
	BEGIN_FOR_EACH(Abraham,shep,(myChangedFlocks->stepper())) {
		this->setSpaceLeft(mySpaceLeft + shep->getInfo()->oldSize());
		if ( ! (mySpaceLeft >= Int32Zero) ) {
			BLAST(Must_have_space_left);
		}
	} END_FOR_EACH;
	/* Leave Pumpkins here so they will be seen by flushChanges. */
	BEGIN_FOR_EACH(Abraham,shep,(myChangedFlocks->stepper())) {
		if (!shep->isEqual(Pumpkin::make ())) {
			Int32 size;
			
			size = myPacker->computeSize(shep);
			shep->getInfo()->setSize(size);
			if (size <= mySpaceLeft) {
				this->setSpaceLeft(mySpaceLeft - size);
			} else {
				myPacker->forwardFlock(shep);
			}
		}
		if ( ! (mySpaceLeft >= Int32Zero) ) {
			BLAST(Must_have_space_left);
		}
	} END_FOR_EACH;
}


Int32 SnarfRecord::spaceLeft (){
	/* Return the amount of space currently left in the snarf. */
	
	return mySpaceLeft;
}
/* protected: destruct */


void SnarfRecord::destruct (){
	/* Destroy all objects imaged from this snarf. */
	
	{myChangedFlocks->destroy();  myChangedFlocks = NULL /* don't want stale (S/CHK)PTRs */;}
	if (myOccupied != NULL) {
		{myOccupied->destroy();  myOccupied = NULL /* don't want stale (S/CHK)PTRs */;}
	}
	this->Heaper::destruct();
}
/* private: private */


IntegerVar SnarfRecord::allocateIndex (){
	/* Return the first unoccupied index in the snarf.  Compute the lowest
		 element >= 0 that is not already in the occupied region by 
	subtracting 
		 the occupied region from the region >= 0. */
	
	IntegerVar index;
	
	this->readOccupied();
	index = myOccupied->nearestIntHole(IntegerVar0);
	myOccupied = CAST(IntegerRegion,myOccupied->withInt(index));
	return index;
}


RPTR(SnarfHandler) SnarfRecord::getWriteHandler (){
	/* Get the handler for my snarf so that I can send or receive 
	data from it. */
	
	SPTR(SnarfHandler) handler;
	BooleanVar flag;
	
	flag = myOccupied != NULL && myOccupied->count() == myChangedFlocks->count();
	/* We also need to compare regions in case as many things are 
		dismantled as are unchanged. */
		/* Change this to iterate myOCcupied and check the 
		presence of each element. 
			 Either that or use an IntegerTable for myChangedFlocks. */
		/* myChangedFlocks really wants to be an optimizing 
		representation. */
	if (flag) {
		SPTR(PrimPtrTableStepper) stepper;
		
		/* calculate myOccupied isSuperSetOf: myChangedFlocks domain */
		stepper = myChangedFlocks->stepper();
		for (;;) {	BooleanVar crutch_Flag;
			/* flag && stepper->hasValue() */
			
			crutch_Flag = flag;
			if(crutch_Flag) {
				crutch_Flag = stepper->hasValue();
			}
			if (crutch_Flag) {
				if (!myOccupied->hasIntMember(stepper->index())) {
					flag = FALSE;
				}
				stepper->step();
			} else {
				break;
			}
		}
		flag = flag && !stepper->hasValue();
		{stepper->destroy();  stepper = NULL /* don't want stale (S/CHK)PTRs */;}
	}
	if (flag) {
		handler = SnarfHandler::make (myPacker->currentView()->makeErasingHandle(mySnarfID));
		handler->initializeSnarf();
	} else {
		handler = SnarfHandler::make (myPacker->currentView()->makeReadHandle(mySnarfID));
	}
	handler->makeWritable();
	WPTR(SnarfHandler) 	returnValue;
	returnValue = handler;
	return returnValue;
}


void SnarfRecord::readOccupied (){
	/* Create an array with the sizes of every flock in the snarf. */
	
	SPTR(SnarfHandler) handler;
	Int32 count;
	
	if (myOccupied != NULL) {
		return;
		
	}
	if (mySpaceLeft >= myPacker->currentView()->getDataSizeOfSnarf(mySnarfID)) {
		myOccupied = IntegerRegion::make ();
		return;
		
	}
	handler = SnarfHandler::make (myPacker->currentView()->makeReadHandle(mySnarfID));
	count = handler->mapCount();
	myOccupied = IntegerRegion::make (IntegerVar0, count);
	{
		Int32 LoopFinal = count;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				SPTR(Abraham) OR(NULL) shep;
				
				shep = CAST(Abraham,myChangedFlocks->fetch(i));
				{	BooleanVar crutch_Flag;
					/* !handler->isOccupied(i) || shep != NULL && shep->isEqual(Pumpkin::make ()) */
					
					crutch_Flag = !handler->isOccupied(i);
					if(!crutch_Flag) {
						crutch_Flag = shep != NULL;
						if(crutch_Flag) {
							crutch_Flag = shep->isEqual(Pumpkin::make ());
						}
					}
					if (crutch_Flag) {
						myOccupied = CAST(IntegerRegion,myOccupied->without(IntegerPos::make (i)));
					}
				}
			}
			i += 1;
		}
	}
	{handler->destroy();  handler = NULL /* don't want stale (S/CHK)PTRs */;}
}


void SnarfRecord::setSpaceLeft (Int32 spaceLeft){
	if ( ! (spaceLeft >= Int32Zero) ) {
		BLAST(Space_is_positive);
	}
	mySpaceLeft = spaceLeft;
}


IntegerVar SnarfRecord::wipeBelowHighest (Int32 highest, APTR(SnarfHandler) handler){
	IntegerVar newHighest;
	SPTR(PrimPtrTableStepper) stepper;
	
	/* (myChangedFlocks domain intersect: (IntegerRegion before: 
	highest)) stepper forEach: 
			[:key {XnInteger} | handler wipeFlock: key asIntegerVar]. 
	----  too inefficient.  also compute the upper bound for later. */
	newHighest = highest;
	stepper = myChangedFlocks->stepper();
	while (stepper->hasValue()) {
		IntegerVar index;
		
		index = stepper->index();
		if (index < highest) {
			handler->wipeFlock(index);
		}
		if (index >= newHighest) {
			/* Must be above the new key. */
			newHighest = index + 1;
		}
		stepper->step();
	}
	{stepper->destroy();  stepper = NULL /* don't want stale (S/CHK)PTRs */;}
	return newHighest;
}
/* create */


SnarfRecord::SnarfRecord (
		Int32 snarfID, 
		APTR(SnarfPacker) packer, 
		Int32 spaceLeft) 
{
	mySnarfID = snarfID;
	myPacker = packer;
	myChangedFlocks = PrimPtrTable::make (128);
	this->setSpaceLeft(spaceLeft);
	myOccupied = NULL;
	if (mySpaceLeft >= myPacker->currentView()->getDataSizeOfSnarf(mySnarfID)) {
		mySpaceLeft = myPacker->currentView()->getDataSizeOfSnarf(mySnarfID) - SnarfHandler::mapOverhead();
		myOccupied = IntegerRegion::make ();
	}
	myDestroyCount = Int32Zero;
}
/* printing */


void SnarfRecord::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << mySnarfID << ")";
}



/* ************************************************************************ *
 * 
 *                    Class SpareStageSpace 
 *
 * ************************************************************************ */



/* Initializers for SpareStageSpace */

Int32 SpareStageSpace::CruftedSnarfCount = 7;
Int32 SpareStageSpace::FlocksPerSnarf = 100;


/* Initializers for SpareStageSpace */



/* accessing */


Int32 SpareStageSpace::cruftedSnarfsGuess (){
	return SpareStageSpace::CruftedSnarfCount;
}


Int32 SpareStageSpace::flocksPerSnarfGuess (){
	return SpareStageSpace::FlocksPerSnarf;
}
/* execute */


void SpareStageSpace::execute (){
	SpareStageSpace::CruftedSnarfCount = myCruftedSnarfCount;
	SpareStageSpace::FlocksPerSnarf = myFlocksPerSnarf;
}

	/* automatic 0-argument constructor */
SpareStageSpace::SpareStageSpace() {}

#ifndef PACKERX_SXX
#include "packerx.sxx"
#endif /* PACKERX_SXX */


#ifndef PACKERP_SXX
#include "packerp.sxx"
#endif /* PACKERP_SXX */



#endif /* PACKERX_CXX */

