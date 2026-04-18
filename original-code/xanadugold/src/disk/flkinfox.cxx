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

#ifndef FLKINFOX_CXX
#define FLKINFOX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef FLKINFOX_HXX
#include "flkinfox.hxx"
#endif /* FLKINFOX_HXX */

#ifndef FLKINFOX_IXX
#include "flkinfox.ixx"
#endif /* FLKINFOX_IXX */


#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef PRIMTABX_HXX
#include "primtabx.hxx"
#endif /* PRIMTABX_HXX */

#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */




/* ************************************************************************ *
 * 
 *                    Class FlockLocation 
 *
 * ************************************************************************ */


/* creation */


RPTR(FlockLocation) FlockLocation::make (Int32 snarfID, Int32 index){
	RETURN_CONSTRUCT(FlockLocation,(snarfID, index));
}
/* Represent the location of a flock on disk.  This ID of the snarf 
in which the flock is contained, and the index of the flock within 
that snarf.  This information side-effect free, even in subclasses. */


/* protected: accessing */


void FlockLocation::index (Int32 anIndex){
	/* This is used to set the index when a flock is bumped from 
	its snarf and forwarded by
		way of the new flocks table */
	
	myIndex = anIndex;
}
/* accessing */
/* creation */


FlockLocation::FlockLocation (Int32 snarfID, Int32 index) {
	mySnarfID = snarfID;
	myIndex = index;
}
/* printing */


void FlockLocation::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << mySnarfID << ", " << myIndex << ")";
}



/* ************************************************************************ *
 * 
 *                    Class   FlockInfo 
 *
 * ************************************************************************ */



/* Initializers for FlockInfo */




/* Initializers for FlockInfo */



/* creation */


RPTR(FlockInfo) FlockInfo::forgotten (
		APTR(Abraham) shep, 
		Int32 snarfID, 
		Int32 index)
{
	RETURN_CONSTRUCT(FlockInfo,(shep, snarfID, index, FlockInfo::forgottenMask(), Int32Zero));
}


RPTR(FlockInfo) FlockInfo::make (APTR(Abraham) shep, IntegerVar index){
	/* Make a ShepherdLocation for a new shepherd. Index is the index into 
		the new flocks table in the snarfPacker. The newmask indicates 
		that the index is into the newFlocks table rather than a snarf. */
	
	RETURN_CONSTRUCT(FlockInfo,(shep, Int32Zero, index.asLong(), (FlockInfo::contentsDirty() | FlockInfo::forgottenStateDirty()) & ~FlockInfo::forgottenMask() | FlockInfo::isNewMask(), Int32Zero));
}


RPTR(FlockInfo) FlockInfo::make (
		APTR(FlockInfo) info, 
		Int32 snarfID, 
		Int32 index)
{
	/* Make a flockInfo to a new location for the same shepherd.  
	Clear the new flag, and keep the rest the same. */
	
	RETURN_CONSTRUCT(FlockInfo,(info->getShepherd(), snarfID, index, info->flags() & ~FlockInfo::isNewMask(), info->oldSize()));
}


RPTR(FlockInfo) FlockInfo::remembered (
		APTR(Abraham) shep, 
		Int32 snarfID, 
		Int32 index)
{
	RETURN_CONSTRUCT(FlockInfo,(shep, snarfID, index, UInt32Zero, Int32Zero));
}
/* debugging tools */


BooleanVar FlockInfo::testContentsDirty (APTR(FlockInfo) info){
	return info->isContentsDirty();
}


BooleanVar FlockInfo::testForgotten (APTR(FlockInfo) info){
	return info->isForgotten();
}
/* testing flags */
/* flock tables */


RPTR(FlockInfo) FlockInfo::getInfo (Int32 index){
	
	return CAST(FlockInfo,CurrentPacker.fluidGet()->flockInfoTable()->get(index));
}


void FlockInfo::removeInfo (Int32 token){
	/* Abraham returnToken: token */
	CurrentPacker.fluidGet()->flockInfoTable()->remove(token);
}
/* Contains all the information the packer needs to know about the 
flock on disk (except forwarder stuff).  The packer knows about 
forwarders by having several FlockInfo objects for the same flock.  
We should consider having a separate class for forward information 
that does not contain the flags and the oldSize.

myOldSize - this is the size of the flock on disk as of the last 
commit.  If this is zero, it is uninitialized.  This is used to 
refitting without bringing in the snarf for this flock.

myFlags - keeps track of whether the receive is a new flock (isn't on 
disk yet), is forgotten, is in the process is fchanging its forggten 
state (isChanging), and is Update (contents have changed). */


/* testing */


BooleanVar FlockInfo::isContentsDirty (){
	/* Return true if my shepherd has changed and informed the 
	SnarfPacker. */
	
	return (myFlags & FlockInfo::contentsDirty()) != UInt32Zero;
}


BooleanVar FlockInfo::isDestroyed (){
	/* Return true if our shepherd has received destroy */
	
	return (myFlags & FlockInfo::destroyed()) != UInt32Zero;
}


BooleanVar FlockInfo::isDirty (){
	/* Return true if anything about my flock is changing 
	(including if the flock is new). */
	
	return (myFlags & (FlockInfo::isNewMask() | FlockInfo::contentsDirty() | FlockInfo::forgottenStateDirty())) != UInt32Zero;
}


BooleanVar FlockInfo::isDismantled (){
	/* Return true if our shepherd has been dismantled */
	
	return (myFlags & FlockInfo::dismantled()) != UInt32Zero;
}


BooleanVar FlockInfo::isForgotten (){
	/* Return true if my Shepherd's new state is it should be forgotten. */
	
	return this->wasForgotten() != this->isForgottenStateDirty();
}


BooleanVar FlockInfo::isForgottenStateDirty (){
	/* Return true if the shepherd I describe is changing between 
	being forgotten and being remembered. */
	
	return (myFlags & FlockInfo::forgottenStateDirty()) != UInt32Zero;
}


BooleanVar FlockInfo::isForwarded (){
	/* Return true if my shepherd has been forwarded. */
	
	return (myFlags & FlockInfo::forwarded()) != UInt32Zero;
}


BooleanVar FlockInfo::isNew (){
	/* Return true if the associated flock is new.  If so, myIndex
		 is an offset into the new flocks table inside the SnarfPacker. */
	
	return (myFlags & FlockInfo::isNewMask()) != UInt32Zero;
}


BooleanVar FlockInfo::wasForgotten (){
	/* Return true if my shepherd was forgotten after the last commit. */
	
	return (myFlags & FlockInfo::forgottenMask()) != UInt32Zero;
}


BooleanVar FlockInfo::wasShepNullInPersistent (){
	/* Return true if our shepherd pointer was NULL in makePersistent */
	
	return (myFlags & FlockInfo::shepNullInPersistent()) != UInt32Zero;
}
/* accessing */


void FlockInfo::clearContentsDirty (){
	/* Reset my contentsDirty flag.  This is primarily used to 
	know when a flock has
		 changed again after some info has been computed from it. */
	
	myFlags &= ~FlockInfo::contentsDirty();
}


void FlockInfo::commitFlags (){
	/* A write to the disk has happened.  Commit all the changes 
	in the flags. */
	
	if (this->isForgottenStateDirty()) {
		myFlags ^= FlockInfo::forgottenMask();
	}
	myFlags &= FlockInfo::forgottenMask();
}


Int32 FlockInfo::flags (){
	return myFlags;
}


UInt4 FlockInfo::flockHash (){
	return myFlockHash;
}


void FlockInfo::forward (Int32 index){
	/* As a freshly forwarded flock, I'll be treated as new for a while. */
	
	myFlags |= FlockInfo::forwarded();
	this->index(index);
}


BooleanVar FlockInfo::markContentsDirty (){
	/* Set my contentsDirty flag.  Return false if I was already 
	dirty (in either way). */
	
	BooleanVar flag;
	
	flag = !this->isDirty();
	myFlags |= FlockInfo::contentsDirty();
	return flag;
}


void FlockInfo::markDestroyed (){
	/* Set my shepNull flag. */
	
	myFlags |= FlockInfo::destroyed();
}


void FlockInfo::markDismantled (){
	/* Set my Dismantled flag.  BLAST if already set. */
	
	if ( this->isDismantled() ) {
		BLAST(Already_dismantled);
	}
	myFlags |= FlockInfo::dismantled();
}


BooleanVar FlockInfo::markForgotten (){
	/* Set my Forgotten flag.  Return false if I was already dirty. */
	
	BooleanVar flag;
	
	flag = !this->isDirty();
	if (!this->isForgotten()) {
		myFlags ^= FlockInfo::forgottenStateDirty();
	}
	return flag;
}


BooleanVar FlockInfo::markRemembered (){
	/* Clear my Forgotten flag.  Return false if I was already dirty. */
	
	BooleanVar flag;
	
	flag = !this->isDirty();
	if (this->isForgotten()) {
		myFlags ^= FlockInfo::forgottenStateDirty();
	}
	return flag;
}


void FlockInfo::markShepNull (){
	/* Set my shepNull flag. */
	
	myFlags |= FlockInfo::shepNullInPersistent();
}


Int32 FlockInfo::oldSize (){
	return myOldSize;
}


void FlockInfo::setSize (Int32 size){
	myOldSize = size;
}
/* tokens */


RPTR(Abraham) FlockInfo::fetchShepherd (){
	if (myToken == NULL) {
		return NULL;
	}
	if (myToken == -1) {
		
		return NULL;
	} else {
		WPTR(Abraham) 	returnValue;
		returnValue = Abraham::fetchShepherd(myToken);
		return returnValue;
	}
}


RPTR(Abraham) FlockInfo::getShepherd (){
	SPTR(Abraham) shep;
	
	shep = this->fetchShepherd();
	if (shep == NULL) {
		BLAST(NullShepherd);
	}
	WPTR(Abraham) 	returnValue;
	returnValue = shep;
	return returnValue;
}


void FlockInfo::registerInfo (){
	/* Register this info as the best known informatino about the flock. */
	
	CurrentPacker.fluidGet()->flockInfoTable()->store(myToken, this);
	
}


Int32 FlockInfo::token (){
	
	return myToken;
}
/* create */


FlockInfo::FlockInfo (
		APTR(Abraham) shep, 
		Int32 snarfID, 
		Int32 index, 
		Int32 flags, 
		Int32 size) 

	: FlockLocation(snarfID, index) {
	myFlockHash = shep->hashForEqual();
	myToken = shep->token();
	
	myFlags = flags;
	myOldSize = size;
	
}
/* printing */


void FlockInfo::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(";
	if (this->isContentsDirty()) {
		oo << "D";
	}
	if (this->isNew()) {
		oo << "N";
	}
	if (this->isDestroyed()) {
		/* X for Xtinct */
		oo << "X";
	}
	if (this->isDismantled()) {
		/* Z for zapped */
		oo << "Z";
	}
	if (this->wasForgotten()) {
		oo << "-";
	} else {
		oo << "+";
	}
	if (this->isForgotten()) {
		oo << "-";
	} else {
		oo << "+";
	}
	oo << ", " << this->snarfID() << ", " << this->index() << ", " << myOldSize << ")";
}

#ifndef FLKINFOX_SXX
#include "flkinfox.sxx"
#endif /* FLKINFOX_SXX */



#endif /* FLKINFOX_CXX */

