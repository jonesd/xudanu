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

#ifndef PACKERT_CXX
#define PACKERT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef PACKERT_HXX
#include "packert.hxx"
#endif /* PACKERT_HXX */

#ifndef PACKERT_IXX
#include "packert.ixx"
#endif /* PACKERT_IXX */


#ifndef ARRAYX_HXX
#include "arrayx.hxx"
#endif /* ARRAYX_HXX */

#ifndef FHASHX_HXX
#include "fhashx.hxx"
#endif /* FHASHX_HXX */

#ifndef GCHOOKSX_HXX
#include "gchooksx.hxx"
#endif /* GCHOOKSX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef NEGOTI8X_HXX
#include "negoti8x.hxx"
#endif /* NEGOTI8X_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef PACKERP_HXX
#include "packerp.hxx"
#endif /* PACKERP_HXX */

#ifndef PRIMTABX_HXX
#include "primtabx.hxx"
#endif /* PRIMTABX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */

#ifndef TURTLEX_HXX
#include "turtlex.hxx"
#endif /* TURTLEX_HXX */




/* ************************************************************************ *
 * 
 *                    Class DoublingFlock 
 *
 * ************************************************************************ */


/* creation */


RPTR(DoublingFlock) DoublingFlock::make (UInt32 hash){
	RETURN_CONSTRUCT(DoublingFlock,(hash, tcsj));
}


RPTR(DoublingFlock) DoublingFlock::make (UInt32 hash, Int32 count){
	RETURN_CONSTRUCT(DoublingFlock,(hash, count));
}
/* accessing */


Int32 DoublingFlock::count (){
	return myCount;
}


void DoublingFlock::doDouble (){
	BEGIN_CONSISTENT(1) {
		myCount *= 2;
		this->diskUpdate();
	} END_CONSISTENT;
}
/* hooks: */


void DoublingFlock::receiveTestFlock (APTR(Rcvr) rcvr){
	{
		Int32 LoopFinal = myCount;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (rcvr->receiveInt32() != i) {
					BLAST(MustMatch);
				}
			}
			i += 1;
		}
	}
}


void DoublingFlock::sendTestFlock (APTR(Xmtr) xmtr){
	{
		Int32 LoopFinal = myCount;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				xmtr->sendInt32(i);
			}
			i += 1;
		}
	}
}
/* printing */


void DoublingFlock::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << this->hashForEqual() << ", " << myCount << ")";
}
/* creation */


DoublingFlock::DoublingFlock (UInt32 hash, TCSJ) 
	: Abraham(hash, tcsj) {
	myCount = 1;
	this->newShepherd();
}


DoublingFlock::DoublingFlock (UInt32 hash, Int32 count) 
	: Abraham(hash, tcsj) {
	myCount = count;
	this->newShepherd();
}
/* testing */


UInt32 DoublingFlock::contentsHash (){
	return this->Abraham::contentsHash() ^ IntegerPos::integerHash(myCount);
}



/* ************************************************************************ *
 * 
 *                    Class HashStream 
 *
 * ************************************************************************ */


/* creation */


RPTR(XnWriteStream) HashStream::make (){
	RETURN_CONSTRUCT(HashStream,());
}
/* create */


HashStream::HashStream () {
	myHash = UInt32Zero;
}
/* accessing */


void HashStream::flush (){
	
}


UInt32 HashStream::hash (){
	/* The accumulated hash */
	
	return myHash;
}


void HashStream::putByte (UInt32 byte){
	myHash = ::fastHash(myHash ^ byte);
}


void HashStream::putData (APTR(UInt8Array) array){
	myHash ^= array->contentsHash();
}


void HashStream::putStr (char * string){
	myHash ^= ::fastHash(string);
}



/* ************************************************************************ *
 * 
 *                    Class HonestAbeIniter 
 *
 * ************************************************************************ */



/* Initializers for HonestAbeIniter */

GPTR(Connection) HonestAbeIniter::TheHonestConnection = NULL;
GPTR(BeGrandMap) HonestAbeIniter::TheHonestGrandMap = NULL;


/* Initializers for HonestAbeIniter */



/* accessing */


RPTR(BeGrandMap) HonestAbeIniter::fetchGrandMap (){
	WPTR(BeGrandMap) 	returnValue;
	returnValue = HonestAbeIniter::TheHonestGrandMap;
	return returnValue;
}
/* running */


void HonestAbeIniter::execute (){
	SPTR(Cookbook) cookbook;
	SPTR(Turtle) turtle;
	SPTR(Connection) conn;
	
	TestPacker::make (blastOnError, persistInterval);
	cookbook = Cookbook::make (myCategory);
	turtle = 
			Turtle::make (cookbook, myCategory, ProtocolBroker::diskProtocol());
	conn = Connection::make (myCategory);
	HonestAbeIniter::TheHonestConnection = conn;
	turtle->saveBootHeaper(conn->bootHeaper());
	/* The following is here so that later thunks can get the 
		GrandMap &c */
		/* [WorksBootMaker] USES.
			GrandConnection fluidSet: TheHonestConnection.ó */
	HonestAbeIniter::TheHonestGrandMap = CAST(BeGrandMap,conn->bootHeaper());
	/* CurrentPacker fluidSet: NULL.
		 */
	CurrentPacker.fluidGet()->purge();
}

	/* automatic 0-argument constructor */
HonestAbeIniter::HonestAbeIniter() {}



/* ************************************************************************ *
 * 
 *                    Class HonestAbePlan 
 *
 * ************************************************************************ */


/* accessing */


RPTR(Category) HonestAbePlan::bootCategory (){
	return (Category*) myCategory;
}


RPTR(Heaper) HonestAbePlan::bootHeaper (){
	WPTR(Heaper) 	returnValue;
	returnValue = CurrentPacker.fluidGet()->getInitialFlock()->bootHeaper();
	return returnValue;
}

	/* automatic 0-argument constructor */
HonestAbePlan::HonestAbePlan() {}



/* ************************************************************************ *
 * 
 *                    Class Honestly 
 *
 * ************************************************************************ */


/* running */


void Honestly::execute (){
	if (CurrentPacker.fluidFetch() == NULL) {
		TestPacker::make (blastOnError, persistInterval);
		Turtle::make (NULL, myCategory, ProtocolBroker::diskProtocol());
	}
	CurrentGrandMap.fluidSet(HonestAbeIniter::fetchGrandMap());
}

	/* automatic 0-argument constructor */
Honestly::Honestly() {}



/* ************************************************************************ *
 * 
 *                    Class PairFlock 
 *
 * ************************************************************************ */


/* creation */


RPTR(PairFlock) PairFlock::make (APTR(Abraham) left, APTR(Abraham) right){
	RETURN_CONSTRUCT(PairFlock,(left, right));
}
/* accessing */


RPTR(Abraham) PairFlock::left (){
	return (Abraham*) myLeft;
}


RPTR(Abraham) PairFlock::right (){
	return (Abraham*) myRight;
}
/* creation */


PairFlock::PairFlock (APTR(Abraham) left, APTR(Abraham) right) {
	myLeft = left;
	myRight = right;
	this->newShepherd();
}
/* testing */


UInt32 PairFlock::contentsHash (){
	return this->Abraham::contentsHash() ^ myLeft->hashForEqual() ^ myRight->hashForEqual();
}



/* ************************************************************************ *
 * 
 *                    Class TestFlockInfo 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(FlockInfo) TestFlockInfo::forgotten (
		APTR(Abraham) shep, 
		Int32 snarfID, 
		Int32 index)
{
	/* index = UInt32Zero assert: 'Should have index 0'. */
	
	RETURN_CONSTRUCT(TestFlockInfo,(shep, snarfID, index, FlockInfo::forgottenMask()));
}


RPTR(FlockInfo) TestFlockInfo::make (APTR(Abraham) shep, IntegerVar index){
	/* index = UInt32Zero assert: 'Should have index 0'. */
	
	RETURN_CONSTRUCT(TestFlockInfo,(shep, Int32Zero, index.asLong(), (FlockInfo::contentsDirty() | FlockInfo::forgottenStateDirty()) & ~FlockInfo::forgottenMask() | FlockInfo::isNewMask()));
}


RPTR(FlockInfo) TestFlockInfo::make (
		APTR(FlockInfo) info, 
		Int32 snarfID, 
		Int32 index)
{
	/* index = UInt32Zero assert: 'Should have index 0'. */
	
	RETURN_CONSTRUCT(TestFlockInfo,(info->getShepherd(), snarfID, index, info->flags() & ~FlockInfo::isNewMask(), info->oldSize()));
}


RPTR(FlockInfo) TestFlockInfo::remembered (
		APTR(Abraham) shep, 
		Int32 snarfID, 
		Int32 index)
{
	if ( ! (index == UInt32Zero) ) {
		BLAST(Should_have_index_0);
	}
	RETURN_CONSTRUCT(TestFlockInfo,(shep, snarfID, index, UInt32Zero));
}
/* Used in conjunction with the TestPacker. Keeps a hash of the last 
contents that were written to disk. */


/* create */


TestFlockInfo::TestFlockInfo (
		APTR(Abraham) shep, 
		Int32 snarfID, 
		Int32 index, 
		UInt32 flags) 

	: FlockInfo(shep
		, snarfID
		, index
		, flags
		, Int32Zero) 
{
	myOldHash = UInt32Zero;
	myPreviousHash = UInt32Zero;
	myOldContents = NULL;
}


TestFlockInfo::TestFlockInfo (
		APTR(Abraham) shep, 
		Int32 snarfID, 
		Int32 index, 
		Int32 flags, 
		Int32 size) 

	: FlockInfo(shep
		, snarfID
		, index
		, flags
		, size) 
{
	myOldHash = UInt32Zero;
	myPreviousHash = UInt32Zero;
	myOldContents = NULL;
}
/* accessing */


void TestFlockInfo::setContents (APTR(UInt8Array) bits){
	myOldContents = bits;
}


BooleanVar TestFlockInfo::updateContentsInfo (){
	/* Update the contents hash and other information from the 
	current state of the shepherd. Return true if the HASH only 
	has changed since the last time. */
	
	myPreviousHash = myOldHash;
	if (this->fetchShepherd() == NULL) {
		myOldHash = UInt32Zero;
	} else {
		myOldHash = CAST(TestPacker,CurrentPacker.fluidGet())->computeHash(this->getShepherd());
	}
	return myPreviousHash != myOldHash;
}



/* ************************************************************************ *
 * 
 *                    Class TestPacker 
 *
 * ************************************************************************ */


/* exceptions: private: */
/* pseudo constructors */


RPTR(DiskManager) TestPacker::make (BooleanVar blast, IntegerVar persistInterval){
	SPTR(DiskManager) result;
	
	CONSTRUCT(result,TestPacker,(blast, persistInterval));
	CurrentPacker.fluidSet(result);
	WPTR(DiskManager) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* Does not actually go to disk, but just tests that the protocol is 
being followed correctly. Some of these tests may make it into the 
real SnarfPacker, but some of them will remain debugging tools. Most 
operations only do enough real stuff to be able to check that they work.


The TestPacker holds onto an IntegerTable of UInt8Arrays that contain 
the disk representations of all the flocks.  It also holds 

myDisk contains a UInt8Array for every flock that made it to disk.  
They are assigned sequential numbers.
myNewFlocks contains the flockInfos for new flocks, and thus contains 
the new flocks wimpily.
myAlmostNewFlocks contains flocks that are under construction but 
have not yet finished.
myDestroyedFlocks contains flocks that will be destroyed upon exiting 
the current consistent block.
myChangedFlocks points strongly at flocks that must be rewritten to disk.
 */


/* shepherds */


void TestPacker::destroyFlock (APTR(FlockInfo) info){
	/* Queue destroy of the given flock.  The destroy will 
	probably happen later. */
	
	SPTR(Abraham) flock;
	
	flock = CAST(Abraham,info->getShepherd());
	/* Check for destructed essentially */
	this->mustKnowShepherd(info);
	this->mustBeInsideTransaction();
	this->mustNotBeCommitting();
	this->countDown();
	info->markDestroyed();
	if (info->markForgotten()) {
		this->recordUpdate(info);
	}
	myDestroyedFlocks->atIntIntroduce(myDestroyedFlocks->count(), flock);
}


void TestPacker::diskUpdate (APTR(FlockInfo) info){
	if (info == NULL) {
		return;
		
	}
	/* noop for new shepherds. */
	this->mustKnowShepherd(info);
	this->mustBeInsideTransaction();
	this->mustNotBeCommitting();
	this->countDown();
	/* sanity check */
	if (info->markContentsDirty()) {
		this->recordUpdate(info);
	} else {
		if (info->isNew()) {
			if ( ! (myNewFlocks->includesIntKey(info->index())) ) {
				BLAST(Something_is_wrong);
			}
		} else {
			if ( ! (myChangedFlocks->includesIntKey(info->index())) ) {
				BLAST(Something_is_wrong);
			}
		}
	}
}


void TestPacker::dismantleFlock (APTR(FlockInfo) info){
	/* The flock designated by info has completed all dismantling 
	actions; throw it off the disk. */
	
	SPTR(Abraham) flock;
	
	flock = CAST(Abraham,info->getShepherd());
	/* Check for destructed essentially */
	this->mustKnowShepherd(info);
	this->mustNotBeCommitting();
	this->countDown();
	info->markDismantled();
	if (!info->isNew()) {
		myChangedFlocks->atIntStore(info->index(), Pumpkin::make ());
	}
}


void TestPacker::dropFlock (Int32 token){
	SPTR(FlockInfo) info;
	
	info = FlockInfo::getInfo(token);
	if (info->isNew()) {
		myNewFlocks->intRemove(info->index());
	} else {
		if (!info->isForgotten()) {
			BLAST(OnlyRemoveUnchangedFlocks);
		}
		myChangedFlocks->intWipe(info->index());
		myFlocks->intRemove(info->index());
	}
	FlockInfo::removeInfo(token);
}


void TestPacker::forgetFlock (APTR(FlockInfo) info){
	this->mustKnowShepherd(info);
	this->mustBeInsideTransaction();
	this->mustNotBeCommitting();
	this->countDown();
	if (info->markForgotten()) {
		this->recordUpdate(info);
	}
}


RPTR(Turtle) TestPacker::getInitialFlock (){
	return CAST(Turtle,myInitialFlock);
}


UInt32 TestPacker::nextHashForEqual (){
	myNextHash += 1;
	/* This actually needs to roll over the UInt32 limit. */
	return myNextHash;
}


void TestPacker::rememberFlock (APTR(FlockInfo) info){
	this->mustBeInsideTransaction();
	this->countDown();
	if (info->markRemembered()) {
		this->recordUpdate(info);
	}
}


void TestPacker::storeAlmostNewShepherd (APTR(Abraham) shep){
	myAlmostNewFlocks->store(shep);
}


void TestPacker::storeInitialFlock (
		APTR(Abraham) turtle, 
		APTR(XcvrMaker) protocol, 
		APTR(Cookbook) cookbook)
{
	myInitialFlock = turtle;
	myXcvrMaker = protocol;
	myBook = cookbook;
	this->storeNewFlock(turtle);
}


void TestPacker::storeNewFlock (APTR(Abraham) shep){
	/* Shep just got created! On some later commit, assign it to a snarf 
		and write it to the disk. */
	
	SPTR(FlockInfo) info;
	
	if (!(shep->fetchInfo() == NULL)) {
		BLAST(NewShepherdMustNotHaveInfo);
	}
	this->countDown();
	myAlmostNewFlocks->wipe(shep);
	info = TestFlockInfo::make (shep, myNewFlocks->highestIndex() + 1);
	myNewFlocks->atIntIntroduce(myNewFlocks->highestIndex() + 1, info);
	shep->flockInfo(info);
}
/* private: testing */


void TestPacker::checkNewFlockIndices (){
	BEGIN_FOR_INDICES(index,FlockInfo,value,(myNewFlocks->stepper())) {
		if (!(index.asLong() == value->index())) {
			BLAST(NewFlockIndexDoesNotMatch);
		}
	} END_FOR_INDICES;
}


void TestPacker::committing (BooleanVar flag){
	amCommitting = flag;
}


IntegerVar TestPacker::countDown (){
	/* Decrement the countdown and return its new value */
	
	myCountDown -= 1;
	return myCountDown;
}


void TestPacker::mustBeInsideTransaction (){
	if (!InsideTransactionFlag.fluidFetch()) {
		if (blastOnError) {
			BLAST(MustBeInsideTransaction);
		}
		
		cerr << "A consistent block is missing\n";
	}
}


void TestPacker::mustKnowShepherd (APTR(FlockInfo) info){
	/* Check that I know about this shepherd */
	
	SPTR(Heaper) t;
	
	if (info->isNew()) {
		t = myNewFlocks->intFetch(info->index());
	} else {
		t = myFlocks->intFetch(info->index());
	}
	{	BooleanVar crutch_Flag;
		/* t != NULL && t->isEqual(info) */
		
		crutch_Flag = t != NULL;
		if(crutch_Flag) {
			crutch_Flag = t->isEqual(info);
		}
		if (!crutch_Flag) {
			BLAST(IncorrectFlockInfo);
		}
	}
}


void TestPacker::mustNotBeCommitting (){
	if (amCommitting) {
		BLAST(MustNotChangeDuringCommit);
	}
}


void TestPacker::resetCountDown (){
	myCountDown = myPersistInterval;
}
/* stubs */


RPTR(Abraham) TestPacker::fetchCanonical (
		UInt32 /* hash */, 
		Int32 /* snarfID */, 
		Int32 index)
{
	return CAST(Abraham,myFlocks->intFetch(index));
}


void TestPacker::makeReal (APTR(FlockInfo) info){
	SPTR(Abraham) stub;
	UInt32 oldHash;
	SPTR(XnReadStream) stream;
	SPTR(Rcvr) rcvr;
	
	stub = info->getShepherd();
	if (!stub->isStub()) {
		BLAST(MustBeAStub);
	}
	oldHash = stub->hashForEqual();
	(rcvr = this->makeRcvr(stream = this->readStream(info)))->receiveInto(stub);
	{rcvr->destroy();  rcvr = NULL /* don't want stale (S/CHK)PTRs */;}
	{stream->destroy();  stream = NULL /* don't want stale (S/CHK)PTRs */;}
	if (!(stub->hashForEqual() == oldHash)) {
		BLAST(HashMustNotChange);
	}
	info->setSize(this->computeSize(info->getShepherd()));
	/* Receiving the flock will have cleared its info, so put it back. */
	stub->flockInfo(info);
}


void TestPacker::registerStub (
		APTR(Abraham) shep, 
		Int32 snarfID, 
		Int32 index)
{
	SPTR(FlockInfo) info;
	
	if ( ! (shep->isStub()) ) {
		BLAST(Must_be_stub);
	}
	info = 
			TestFlockInfo::remembered(shep, snarfID, index);
	shep->flockInfo(info);
	myFlocks->atIntIntroduce(index, info);
}
/* private: streams */


Int32 TestPacker::computeSize (APTR(Abraham) flock){
	/* Send the snarf over a transmitter into a stream that just 
	counts the bytes put into it. */
	
	SPTR(XnWriteStream) counter;
	SPTR(Xmtr) xmtr;
	Int32 size;
	
	counter = CountStream::make ();
	xmtr = this->makeXmtr(counter);
	xmtr->sendHeaper(flock);
	size = CAST(CountStream,counter)->size();
	{xmtr->destroy();  xmtr = NULL /* don't want stale (S/CHK)PTRs */;}
	{counter->destroy();  counter = NULL /* don't want stale (S/CHK)PTRs */;}
	return size;
}


RPTR(SpecialistRcvr) TestPacker::makeRcvr (APTR(XnReadStream) readStream){
	WPTR(SpecialistRcvr) 	returnValue;
	returnValue = myXcvrMaker->makeRcvr(DiskSpecialist::make (myBook, this), readStream);
	return returnValue;
}


RPTR(SpecialistXmtr) TestPacker::makeXmtr (APTR(XnWriteStream) writeStream){
	WPTR(SpecialistXmtr) 	returnValue;
	returnValue = myXcvrMaker->makeXmtr(DiskSpecialist::make (myBook, this), writeStream);
	return returnValue;
}


RPTR(XnReadStream) TestPacker::readStream (APTR(FlockInfo) info){
	/* Get a read stream on the disk contents of the info */
	
	WPTR(XnReadStream) 	returnValue;
	returnValue = XnReadStream::make (CAST(UInt8Array,myDisk->intGet(info->index())));
	return returnValue;
}


RPTR(XnWriteStream) TestPacker::writeStream (APTR(FlockInfo) info){
	/* Get a write stream on the disk contents of the info */
	
	SPTR(UInt8Array) result;
	
	result = UInt8Array::make (this->computeSize(info->getShepherd()));
	myDisk->atIntStore(info->index(), result);
	/* Hack !!!! */
	
	/* You can't use gutsOf in something that will do an allocation. */
	WPTR(XnWriteStream) 	returnValue;
	returnValue = XnWriteStream::make (result);
	return returnValue;
}
/* private: disk */


void TestPacker::assignSnarf (APTR(Abraham) shep){
	SPTR(FlockInfo) oldInfo;
	Int32 snarf;
	
	oldInfo = shep->getInfo();
	snarf = myDisk->highestIndex().asLong() + 1;
	myDisk->atIntStore(snarf, UInt8Array::make (UInt32Zero));
	shep->flockInfo(
			TestFlockInfo::make (oldInfo, snarf, snarf));
	/* Destroy the old location if it is for a new flock (rather 
		than forwarded). */
	if (oldInfo->isNew()) {
		myNewFlocks->intWipe(oldInfo->index());
		{oldInfo->destroy();  oldInfo = NULL /* don't want stale (S/CHK)PTRs */;}
		CAST(TestFlockInfo,shep->getInfo())->updateContentsInfo();
	}
	oldInfo = NULL;
	myFlocks->atIntIntroduce(snarf, shep->getInfo());
	myChangedFlocks->atIntStore(snarf, shep);
}


void TestPacker::flushChanges (){
	/* Rewrite all flocks that have changed in this snarf. */
	/* check that all changed flocks are in fact in myChangedFlocks */
	
	SPTR(TableStepper) flocks;
	
	BEGIN_FOR_EACH(TestFlockInfo,info,(myFlocks->stepper())) {
		{	BooleanVar crutch_Flag;
			/* info->fetchShepherd() != NULL && !info->isNew() && (info->updateContentsInfo() || info->isContentsDirty()) && !myChangedFlocks->includesIntKey(info->snarfID()) */
			
			crutch_Flag = info->fetchShepherd() != NULL;
			if(crutch_Flag) {
				crutch_Flag = !info->isNew();
				if(crutch_Flag) {
					crutch_Flag = info->updateContentsInfo();
					if(!crutch_Flag) {
						crutch_Flag = info->isContentsDirty();
					}
					if(crutch_Flag) {
						crutch_Flag = !myChangedFlocks->includesIntKey(info->snarfID());
					}
				}
			}
			if (crutch_Flag) {
				if (blastOnError) {
					BLAST(ShouldHaveDoneDiskUpdateOnChangedShepherd);
				}
				cerr << "Shepherd " << info->fetchShepherd() << " with info " << info << " should have done a diskUpdate\n";
				this->recordUpdate(info);
			}
		}
	} END_FOR_EACH;
	/* actually write changed flocks to disk */
	BEGIN_FOR_EACH(Heaper,thing,(flocks = myChangedFlocks->stepper())) {
		BEGIN_CHOOSE(thing) {
			BEGIN_KIND(Pumpkin,pumpkin) {
				myDisk->intWipe(flocks->index());
			} END_KIND;
			BEGIN_KIND(Abraham,shep) {
				SPTR(FlockInfo) inf;
				
				inf = shep->fetchInfo();
				if (inf == NULL) {
					BLAST(ShepherdMustNotHaveNullFlockInfo);
				}
				/* We only get here for forwarded flocks. */
				if (inf->index() == flocks->index().asLong()) {
					SPTR(Xmtr) xmtr;
					SPTR(XnWriteStream) stream;
					
					/* Not forwarded. */
					if (shep->isStub()) {
						BLAST(MustBeInstantiated);
					}
					(xmtr = this->makeXmtr(stream = this->writeStream(inf)))->sendHeaper(shep);
					{xmtr->destroy();  xmtr = NULL /* don't want stale (S/CHK)PTRs */;}
					{stream->destroy();  stream = NULL /* don't want stale (S/CHK)PTRs */;}
					CAST(TestFlockInfo,inf)->setContents(CAST(UInt8Array,myDisk->intFetch(inf->index())));
					inf->commitFlags();
				} else {
					BLAST(TestPackerDoesNotForward);
				}
			} END_KIND;
		} END_CHOOSE;
	} END_FOR_EACH;
	{myChangedFlocks->destroy();  myChangedFlocks = NULL /* don't want stale (S/CHK)PTRs */;}
	myChangedFlocks = IntegerTable::make ();
}


void TestPacker::recordUpdate (APTR(FlockInfo) info){
	/* The flock represented by info has changed.  Record it in the
		 bookkeeping data-structures.  This must be called by all things 
		 that affect whether the flock gets rewritten to disk. */
	
	SPTR(Abraham) shep;
	
	if (!info->isNew()) {
		if ((shep = info->fetchShepherd()) != NULL) {
			if (shep->isEqual(Pumpkin::make ())) {
				if (blastOnError) {
					BLAST(MustNotRecordChangesForPumpkins);
				}
				cerr << "Pumpkin " << info << " tried to diskUpdate\n";
				return;
				
			}
		}
		myChangedFlocks->atIntStore(info->index(), shep);
	}
}


void TestPacker::refitFlocks (){
	/* do nothing for now */
	
	
}
/* create */


TestPacker::TestPacker (BooleanVar blast, IntegerVar persistInterval) {
	myNextHash = UInt32Zero;
	myInitialFlock = NULL;
	myFlocks = IntegerTable::make ();
	myChangedFlocks = IntegerTable::make ();
	myDestroyedFlocks = MuArray::array();
	myAlmostNewFlocks = MuSet::make ();
	myNewFlocks = IntegerTable::make ();
	myXcvrMaker = NULL;
	myBook = NULL;
	myPersistInterval = persistInterval;
	this->resetCountDown();
	myDisk = IntegerTable::make ();
	amCommitting = FALSE;
	blastOnError = blast;
}
/* internals */


UInt32 TestPacker::computeHash (APTR(Abraham) flock){
	/* Compute a hash on the contents */
	
	SPTR(XnWriteStream) hasher;
	UInt32 hash;
	SPTR(SpecialistXmtr) xmtr;
	
	hasher = HashStream::make ();
	xmtr = this->makeXmtr(hasher);
	xmtr->sendHeaper(flock);
	hash = CAST(HashStream,hasher)->hash();
	{xmtr->destroy();  xmtr = NULL /* don't want stale (S/CHK)PTRs */;}
	{hasher->destroy();  hasher = NULL /* don't want stale (S/CHK)PTRs */;}
	return hash;
}
/* transactions */


void TestPacker::beginConsistent (IntegerVar /* dirty */){
	if (!InsideTransactionFlag.fluidFetch()) {
		if (this->countDown() < IntegerVar0) {
			this->makePersistent();
			this->resetCountDown();
		}
	}
}


void TestPacker::endConsistent (IntegerVar /* dirty */){
	SPTR(Agenda) OR(NULL) agenda;
	
	if (InsideTransactionFlag.fluidFetch()) {
		return;
		
	}
	if (!myAlmostNewFlocks->isEmpty()) {
		if (blastOnError) {
			BLAST(MustDoNewShepherdAfterDiskUpdate);
		}
		cerr << "These flocks should have done a newShepherd: " << myAlmostNewFlocks << "\n";
		BEGIN_FOR_EACH(Abraham,each,(myAlmostNewFlocks->stepper())) {
			each->newShepherd();
		} END_FOR_EACH;
	}
	if (InsideAgenda.fluidFetch()) {
		return;
		
	}
	agenda = CAST(Turtle,myInitialFlock)->fetchAgenda();
	if (agenda != NULL) {
		{	FLUID_BIND(InsideAgenda,TRUE) {
				while (agenda->step()) {}
				
			}
		}
	}
	if (myDestroyedFlocks->isEmpty()) {
		return;
		
	}
	{	FLUID_BIND(InsideAgenda,TRUE) {
			while (!myDestroyedFlocks->isEmpty()) {
				SPTR(Abraham) flock;
				
				flock = CAST(Abraham,myDestroyedFlocks->intGet(myDestroyedFlocks->count() - 1));
				myDestroyedFlocks->intRemove(myDestroyedFlocks->count() - 1);
				if (flock->getInfo()->isForgotten()) {
					flock->dismantle();
				}
			}
		}
	}
}


BooleanVar TestPacker::insideCommit (){
	return amCommitting;
}


void TestPacker::makePersistent (){
	{
		PLANT_BOMB(EndCommit,Boom);
		ARM_BOMB(Boom,(this))
		{
			amCommitting = TRUE;
			this->refitFlocks();
			BEGIN_FOR_EACH(FlockInfo,info,(myNewFlocks->stepper())) {
				SPTR(Abraham) shep;
				
				if ((shep = info->fetchShepherd()) != NULL) {
					this->assignSnarf(shep);
				}
			} END_FOR_EACH;
			this->flushChanges();
			{myNewFlocks->destroy();  myNewFlocks = NULL /* don't want stale (S/CHK)PTRs */;}
			myNewFlocks = IntegerTable::make (500);
		}
	}
}


void TestPacker::purge (){
	if (!InsideTransactionFlag.fluidFetch()) {
		this->makePersistent();
		this->purgeClean(TRUE);
	}
}


void TestPacker::purgeClean (BooleanVar noneLocked/* = FALSE*/){
	SPTR(PrimPtrTable) stackPtrs;
	
	
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
/* testing */


BooleanVar TestPacker::isFake (){
	return FALSE;
}

#ifndef PACKERT_SXX
#include "packert.sxx"
#endif /* PACKERT_SXX */



#endif /* PACKERT_CXX */

