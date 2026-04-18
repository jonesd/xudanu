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

#ifndef FAKEDSKX_CXX
#define FAKEDSKX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef FAKEDSKP_HXX
#include "fakedskp.hxx"
#endif /* FAKEDSKP_HXX */

#ifndef FAKEDSKP_IXX
#include "fakedskp.ixx"
#endif /* FAKEDSKP_IXX */


#ifndef COOKBKX_HXX
#include "cookbkx.hxx"
#endif /* COOKBKX_HXX */

#ifndef COUNTERX_HXX
#include "counterx.hxx"
#endif /* COUNTERX_HXX */

#ifndef FLKINFOX_HXX
#include "flkinfox.hxx"
#endif /* FLKINFOX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */




/* ************************************************************************ *
 * 
 *                    Class FakeDisk 
 *
 * ************************************************************************ */


/* running */


void FakeDisk::execute (){
	FakePacker::make ();
	MockTurtle::make (myCategory);
}

	/* automatic 0-argument constructor */
FakeDisk::FakeDisk() {}



/* ************************************************************************ *
 * 
 *                    Class FakePacker 
 *
 * ************************************************************************ */


/* creation */


RPTR(DiskManager) FakePacker::make (){
	SPTR(DiskManager) packer;
	
	CONSTRUCT(packer,FakePacker,());
	CurrentPacker.fluidSet(packer);
	WPTR(DiskManager) 	returnValue;
	returnValue = packer;
	return returnValue;
}
/* Most of the disk operations are just no-ops. */


/* transactions */


void FakePacker::beginConsistent (IntegerVar /* dirty */){
	
}


void FakePacker::endConsistent (IntegerVar /* dirty */){
	SPTR(Agenda) OR(NULL) agenda;
	
	if (!InsideTransactionFlag.fluidFetch()) {
		agenda = myTurtle->fetchAgenda();
		{	BooleanVar crutch_Flag;
			/* agenda != NULL && !InsideAgenda.fluidFetch() */
			
			crutch_Flag = agenda != NULL;
			if(crutch_Flag) {
				crutch_Flag = !InsideAgenda.fluidFetch();
			}
			if (crutch_Flag) {
				{	FLUID_BIND(InsideAgenda,TRUE) {
						while (agenda->step()) {}
						
					}
				}
			}
		}
	}
}


BooleanVar FakePacker::insideCommit (){
	return FALSE;
}


void FakePacker::purge (){
	/* Flush everything out to disk and remove all purgeable imaged
		 objects from memory.  This doesn't clear the ShepherdMap table.  
		 This will have to be a weak table, and then the destruction of a 
		 shepherd or shepherdStub should remove it from myShepherdMap. */
	
	
}


void FakePacker::purgeClean (BooleanVar /* noneLocked *//* = FALSE*/){
	/* No shepherds are clean, so no-op. */
	
	
}
/* shepherds */


void FakePacker::destroyFlock (APTR(FlockInfo) info){
	/* Queue destroy of the given flock.  dismantle it 
	immediately in the FakePacker. */
	
	/* Known bug !!!! */
	
	/* This needs to stack shepherds for deletion after all 
		agenda items. */
	info->markDestroyed();
	info->getShepherd()->dismantle();
}


void FakePacker::diskUpdate (APTR(FlockInfo) OR(NULL) info){
	/* The flock identified by token is Dirty! On some later 
	commit, write it to the disk. */
	
	
}


void FakePacker::dismantleFlock (APTR(FlockInfo) info){
	/* Tehre are no local data-structures. */
	/* info markDismantled. */
	
	
}


void FakePacker::dropFlock (Int32 token){
	/* No prob. */
	
	
}


void FakePacker::forgetFlock (APTR(FlockInfo) info){
	/* Yeah. Right. */
	
	
}


RPTR(Turtle) FakePacker::getInitialFlock (){
	return (Turtle*) myTurtle;
}


UInt32 FakePacker::nextHashForEqual (){
	/* Shepherds use a sequence number for their hash.  Return the next one
		 and increment.  This should actually spread the hashes. */
	/* This actually needs to roll over the UInt32 limit. */
	
	myCount += 1;
	return myCount;
}


void FakePacker::rememberFlock (APTR(FlockInfo) info){
	/* There are now persistent pointers to the shepherd 
	represented by token. */
	
	
}


void FakePacker::storeAlmostNewShepherd (APTR(Abraham) /* shep */){
	/* Do nothing */
	
	
}


void FakePacker::storeInitialFlock (
		APTR(Abraham) /* turtle */, 
		APTR(XcvrMaker) /* protocol */, 
		APTR(Cookbook) /* cookbook */)
{
	BLAST(MustBeRealDiskManager);
}


void FakePacker::storeNewFlock (APTR(Abraham) shep){
	/* Shep just got created! On some later commit, assign it to a snarf 
		and write it to the disk. */
	
	SPTR(FlockInfo) info;
	
	if ( ! (shep->fetchInfo() == NULL) ) {
		BLAST(Must_not_have_an_info_yet);
	}
	/* Create a FlockInfo to make the FlockTable registration happy. */
	info = FlockInfo::make (shep, -myCount);
	shep->flockInfo(info);
}


void FakePacker::storeTurtle (APTR(Turtle) turtle){
	myTurtle = turtle;
}
/* stubs */


RPTR(Abraham) FakePacker::fetchCanonical (
		UInt32 /* hash */, 
		Int32 /* snarfID */, 
		Int32 /* index */)
{
	/* If something is already imaged at that location, then 
	return it. If there is already
		 an existing stub with the same hash at a different 
	location, follow them till we 
		 know that they are actually different objects. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	return NULL;
}


void FakePacker::makeReal (APTR(FlockInfo) /* info */){
	/* Retrieve from the disk the flock at index within the 
	specified snarf.  Since
		 stubs are canonical, and this only gets called by stubs, 
	the existing stub will 
		 *become* the shepherd for the flock. */
	
	BLAST(NOT_YET_IMPLEMENTED);
}


void FakePacker::registerStub (
		APTR(Abraham) /* shep */, 
		Int32 /* snarfID */, 
		Int32 /* index */)
{
	BLAST(NOT_YET_IMPLEMENTED);
}
/* protected: create */


FakePacker::FakePacker () {
	myTurtle = NULL;
	myCount = UInt32Zero;
}
/* testing */


BooleanVar FakePacker::isFake (){
	return TRUE;
}
/* internals */


void FakePacker::destroyAbandoned (){
	
}



/* ************************************************************************ *
 * 
 *                    Class MockTurtle 
 *
 * ************************************************************************ */


/* pseudo-constructor */


RPTR(Turtle) MockTurtle::make (APTR(Category) category){
	RETURN_CONSTRUCT(MockTurtle,(category, tcsj));
}
/* The MockTurtle is used with the FakePacker.  All it provides is an Agenda */


/* accessing */


RPTR(Category) MockTurtle::bootCategory (){
	return (Category*) myBootCategory;
}


RPTR(Heaper) MockTurtle::bootHeaper (){
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}


RPTR(Cookbook) MockTurtle::cookbook (){
	BLAST(WILL_NOT_IMPLEMENT);
	return NULL;
}


RPTR(Counter) MockTurtle::counter (){
	BLAST(WILL_NOT_IMPLEMENT);
	/* fodder */
	return NULL;
}


RPTR(Agenda) OR(NULL) MockTurtle::fetchAgenda (){
	return (Agenda*) myAgenda;
}


RPTR(XcvrMaker) MockTurtle::protocol (){
	BLAST(WILL_NOT_IMPLEMENT);
	return NULL;
}


void MockTurtle::saveBootHeaper (APTR(Heaper) boot){
	/* Right */
	
	BLAST(WILL_NOT_IMPLEMENT);
}


void MockTurtle::setProtocol (APTR(XcvrMaker) xcvrMaker, APTR(Cookbook) book){
	/* Right */
	
	BLAST(WILL_NOT_IMPLEMENT);
}
/* protected: creation */


MockTurtle::MockTurtle (APTR(Category) bootCategory, TCSJ) {
	CAST(FakePacker,CurrentPacker.fluidGet())->storeTurtle(this);
	myAgenda = NULL;
	myBootCategory = bootCategory;
	myAgenda = Agenda::make ();
}

#ifndef FAKEDSKP_SXX
#include "fakedskp.sxx"
#endif /* FAKEDSKP_SXX */



#endif /* FAKEDSKX_CXX */

