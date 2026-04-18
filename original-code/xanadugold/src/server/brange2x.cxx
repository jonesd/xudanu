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

#ifndef BRANGE2X_CXX
#define BRANGE2X_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef BRANGE2X_HXX
#include "brange2x.hxx"
#endif /* BRANGE2X_HXX */

#ifndef BRANGE2X_IXX
#include "brange2x.ixx"
#endif /* BRANGE2X_IXX */

#ifndef BRANGE2P_HXX
#include "brange2p.hxx"
#endif /* BRANGE2P_HXX */

#ifndef BRANGE2P_IXX
#include "brange2p.ixx"
#endif /* BRANGE2P_IXX */


#ifndef CROSSX_HXX
#include "crossx.hxx"
#endif /* CROSSX_HXX */

#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef FLUIDX_HXX
#include "fluidx.hxx"
#endif /* FLUIDX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef NADMINX_HXX
#include "nadminx.hxx"
#endif /* NADMINX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef SCHUNKX_HXX
#include "schunkx.hxx"
#endif /* SCHUNKX_HXX */

#ifndef SEQUENCX_HXX
#include "sequencx.hxx"
#endif /* SEQUENCX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */




/* ************************************************************************ *
 * 
 *                    Class BeWork 
 *
 * ************************************************************************ */


/* creation */


RPTR(BeWork) BeWork::make (APTR(FeEdition) edition){
	BEGIN_CONSISTENT(-1) {
		RETURN_CONSTRUCT(BeWork,(edition, FALSE));
	} END_CONSISTENT;
}
/* This is the actual representation on disk; the Fe versions of 
these classes hide the actual representation.ó */


/* locking */


BooleanVar BeWork::canBeEditedBy (APTR(FeKeyMaster) km){
	/* Answer whether the KeyMaster has the authority to edit this work. */
	
	{	BooleanVar crutch_Flag;
		/* myEditClub != NULL && km->hasAuthority(myEditClub) */
		
		crutch_Flag = myEditClub != NULL;
		if(crutch_Flag) {
			crutch_Flag = km->hasAuthority(myEditClub);
		}
		return crutch_Flag;
	}
}


BooleanVar BeWork::canBeReadBy (APTR(FeKeyMaster) km){
	/* Return true if the KeyMaster has the authority to read this Work. */
	
	{	BooleanVar crutch_Flag;
		/* myReadClub != NULL && km->hasAuthority(myReadClub) || this->canBeEditedBy(km) */
		
		crutch_Flag = myReadClub != NULL;
		if(crutch_Flag) {
			crutch_Flag = km->hasAuthority(myReadClub);
		}
		if(!crutch_Flag) {
			crutch_Flag = this->canBeEditedBy(km);
		}
		return crutch_Flag;
	}
}


RPTR(FeWork) BeWork::makeLockedFeWork (){
	/* Make a frontend Work on me and lock it if possible. */
	
	SPTR(FeWork) result;
	SPTR(FeKeyMaster) ckm;
	
	result = CAST(FeWork,this->makeFe(NULL));
	ckm = CurrentKeyMaster.fluidGet();
	{	BooleanVar crutch_Flag;
		/* this->fetchLockingWork() == NULL && this->canBeEditedBy(ckm) */
		
		crutch_Flag = this->fetchLockingWork() == NULL;
		if(crutch_Flag) {
			crutch_Flag = this->canBeEditedBy(ckm);
		}
		if (crutch_Flag) {
			result->grab();
		}
	}
	WPTR(FeWork) 	returnValue;
	returnValue = result;
	return returnValue;
}


BooleanVar BeWork::tryLock (APTR(FeWork) work){
	/* Try to lock with the give FE Work. Return TRUE if successful */
	
	SPTR(FeWork) curLock;
	
	curLock = this->fetchLockingWork();
	{	BooleanVar crutch_Flag;
		/* curLock == NULL || curLock->isEqual(work) */
		
		crutch_Flag = curLock == NULL;
		if(!crutch_Flag) {
			crutch_Flag = curLock->isEqual(work);
		}
		if (crutch_Flag) {
			myLockingWork->store(Int32Zero, work);
			return TRUE;
		} else {
			return FALSE;
		}
	}
}


BooleanVar BeWork::tryUnlock (APTR(FeWork) work){
	/* If the given FE Work is locking, then unlock and return 
	TRUE; else return FALSE with no change in lock state */
	
	/* Unlock and tell everyone about the change */
	if (this->fetchLockingWork() == work) {
		myLockingWork->store(Int32Zero, NULL);
		this->updateFeStatus();
		return TRUE;
	} else {
		return FALSE;
	}
}
/* contents */


void BeWork::addRevisionWatcher (APTR(FeWork) work){
	/* Tell the FE Work whenever this Work is revised */
	
	if (myRevisionWatchers == NULL) {
		myRevisionWatchers = PrimSet::weak(7, RevisionWatcherExecutor::make (this));
	}
	myRevisionWatchers->introduce(work);
}


RPTR(FeEdition) BeWork::edition (){
	/* The current Edition.
		Note: If this is an unsponsored Work, the Edition might have 
	been discarded, and this operation will blast. */
	
	/* Thing to do !!!! */
	
	/* Cache this */
	WPTR(FeEdition) 	returnValue;
	returnValue = FeEdition::on(myEdition, FeLabel::on(myEditionLabel));
	return returnValue;
}


RPTR(ID) BeWork::lastRevisionAuthor (){
	/* The Club who made the last revision */
	
	return (ID*) myReviser;
}


IntegerVar BeWork::lastRevisionNumber (){
	/* The sequence number of the last revision of this Work. */
	
	return myRevisionCount;
}


IntegerVar BeWork::lastRevisionTime (){
	/* The time of the last revision of this Work. */
	
	return myRevisionTime;
}


void BeWork::recordHistory (){
	/* Change the current edition and notify anyone who cares 
	about the revision */
	
	SPTR(BeGrandMap) gm;
	
	if (myHistoryClub == NULL) {
		return;
		
	}
	gm = CurrentGrandMap.fluidGet();
	/* Bind all these because they not be set. */
	{	FLUID_BIND(InitialReadClub,myHistoryClub) {
			{	FLUID_BIND(InitialEditClub,gm->emptyClubID()) {
					{	FLUID_BIND(InitialOwner,this->owner()) {
							{	FLUID_BIND(InitialSponsor,gm->emptyClubID()) {
									SPTR(BeWork) legacy;
									
									legacy = gm->newWork(this->edition());
									legacy->setEditClub(NULL);
									/* Thing to do !!!! */
									
									/* legacy endorse: 
										(CurrentAuthor fluidGet with: 
										#revised). */
									myHistory = this->revisions()->with(IntegerPos::make (myRevisionCount), gm->carrier(legacy));
								}
							}
						}
					}
				}
			}
		}
	}
}


void BeWork::removeLastRevisionWatcher (){
	/* Inform the work that its last revision watcher is gone. */
	
	myRevisionWatchers = NULL;
}


void BeWork::removeRevisionWatcher (APTR(FeWork) work){
	/* Remove a previously added RevisionWatcher */
	
	if (myRevisionWatchers == NULL) {
		BLAST(NeverAddedRevisionWatcher);
	}
	myRevisionWatchers->remove(work);
	if (myRevisionWatchers->isEmpty()) {
		myRevisionWatchers = NULL;
	}
}


void BeWork::revise (APTR(FeEdition) edition){
	/* Change the current edition and notify anyone who cares 
	about the revision */
	
	BEGIN_CONSISTENT(-1) {
		/* Known bug !!!! */
		
		/* this may not be the right thing to do when not 
			grabbed - it only happens during booting anyway */
		if (this->fetchLockingWork() == NULL) {
			myReviser = CurrentAuthor.fluidGet();
		} else {
			myReviser = this->fetchLockingWork()->getAuthor();
		}
		myEdition->removeWork(this);
		myEdition = edition->beEdition();
		myEditionLabel = CAST(BeLabel,edition->label()->getOrMakeBe());
		myEdition->introduceWork(this);
		myRevisionCount += 1;
		myRevisionTime = ::xuTime();
		/* Trigger immediate revisionDetectors */
		if (myRevisionWatchers != NULL) {
			BEGIN_FOR_EACH(FeWork,work,(myRevisionWatchers->stepper())) {
				work->triggerRevisionDetectors(edition, myReviser, myRevisionTime, myRevisionCount);
			} END_FOR_EACH;
		}
		/* Record result into the trail */
		if (myHistoryClub != NULL) {
			this->recordHistory();
		}
		this->diskUpdate();
	} END_CONSISTENT;
}


RPTR(BeEdition) BeWork::revisions (){
	/* If there isn't already a shared Trail on this Work, create 
	a new one. Return it */
	
	if (myHistory == NULL) {
		BEGIN_CONSISTENT(-1) {
			myHistory = CurrentGrandMap.fluidGet()->newEmptyEdition(IntegerSpace::make ());
			this->diskUpdate();
		} END_CONSISTENT;
	}
	return (BeEdition*) myHistory;
}
/* permissions */


RPTR(ID) OR(NULL) BeWork::fetchEditClub (){
	/* The edit Club, or NULL if there is none */
	
	return (ID*) myEditClub;
}


RPTR(ID) OR(NULL) BeWork::fetchHistoryClub (){
	/* The history Club, or NULL if there is none */
	
	return (ID*) myHistoryClub;
}


RPTR(ID) OR(NULL) BeWork::fetchReadClub (){
	/* The read Club, or NULL if there is none */
	
	return (ID*) myReadClub;
}


void BeWork::setEditClub (APTR(ID) OR(NULL) club){
	/* Change the edit Club (or remove it if NULL). */
	
	BEGIN_CONSISTENT(1) {
		myEditClub = club;
		/* Known bug !!!! */
		
		/* props */
		this->diskUpdate();
	} END_CONSISTENT;
	this->updateFeStatus();
}


void BeWork::setHistoryClub (APTR(ID) OR(NULL) club){
	/* Change the history Club (or remove it if NULL). */
	
	BEGIN_CONSISTENT(-1) {
		SPTR(ID) OR(NULL) oldClub;
		
		oldClub = myHistoryClub;
		myHistoryClub = club;
		/* Known bug !!!! */
		
		/* What happens when you change the club. */
		{	BooleanVar crutch_Flag;
			/* oldClub == NULL && myHistoryClub != NULL */
			
			crutch_Flag = oldClub == NULL;
			if(crutch_Flag) {
				crutch_Flag = myHistoryClub != NULL;
			}
			if (crutch_Flag) {
				this->recordHistory();
			}
		}
		this->diskUpdate();
	} END_CONSISTENT;
}


void BeWork::setReadClub (APTR(ID) OR(NULL) club){
	/* Change the read Club (or remove it if NULL). */
	
	BEGIN_CONSISTENT(-1) {
		myReadClub = club;
		/* Known bug !!!! */
		
		/* props */
		this->diskUpdate();
	} END_CONSISTENT;
	this->updateFeStatus();
}
/* props */


void BeWork::endorse (APTR(CrossRegion) endorsements){
	/* Adds to the endorsements on this Work. The set of 
	endorsements must be a finite number of (club ID, token ID) 
	pairs. This requires the authority of all of the Clubs used 
	to endorse. The token IDs must not be named IDs. */
	
	if (endorsements->isEmpty()) {
		return;
		
	}
	BEGIN_CONSISTENT(8) {
		this->propChange(PropChange::endorsementsChange(), BertProp::endorsementsProp(endorsements->unionWith(myOwnProp->endorsements())));
	} END_CONSISTENT;
}


RPTR(CrossRegion) BeWork::endorsements (){
	/* All endorsements which have been placed on this Work. The 
	Edition::transclusions () operation will be able to find the 
	current Edition of this Work by filtering for these 
	endorsements; they are also used to filter various other 
	operations which directly return sets of Works. */
	
	return CAST(CrossRegion,myOwnProp->endorsements());
}


RPTR(BertProp) BeWork::localProp (){
	return (BertProp*) myOwnProp;
}


RPTR(BertProp) BeWork::prop (){
	return (BertProp*) myOwnProp;
}


void BeWork::propChange (APTR(PropChange) change, APTR(Prop) nw){
	SPTR(Prop) old;
	
	old = myOwnProp;
	if (!change->areEqualProps(old, nw)) {
		myOwnProp = CAST(BertProp,change->changed(old, nw));
		this->diskUpdate();
		myEdition->propChanged(change, old, nw, 
				change->fetchFinder(old, nw, this, NULL));
	}
}


void BeWork::retract (APTR(CrossRegion) endorsements){
	/* Removes endorsements from this Work. This requires the 
	authority of all of the Clubs whose endorsements are in the 
	list. Ignores all endorsements which you could have removed, 
	but which don't happen to be there right now. */
	
	if (endorsements->isEmpty()) {
		return;
		
	}
	BEGIN_CONSISTENT(5) {
		this->propChange(PropChange::endorsementsChange(), BertProp::endorsementsProp(myOwnProp->endorsements()->minus(endorsements)));
	} END_CONSISTENT;
}
/* accessing */


BooleanVar BeWork::isPurgeable (){
	{	BooleanVar crutch_Flag;
		/* this->BeRangeElement::isPurgeable() && this->fetchLockingWork() == NULL && myRevisionWatchers == NULL */
		
		crutch_Flag = this->BeRangeElement::isPurgeable();
		if(crutch_Flag) {
			crutch_Flag = this->fetchLockingWork() == NULL;
			if(crutch_Flag) {
				crutch_Flag = myRevisionWatchers == NULL;
			}
		}
		return crutch_Flag;
	}
}


RPTR(FeRangeElement) BeWork::makeFe (APTR(BeLabel) OR(NULL) label){
	WPTR(FeRangeElement) 	returnValue;
	returnValue = FeWork::on(this);
	return returnValue;
}


void BeWork::sponsor (APTR(IDRegion) clubs){
	/* Add new sponsors to the Work, and notify the Clubs */
	
	SPTR(IDRegion) newClubs;
	
	newClubs = CAST(IDRegion,clubs->minus(mySponsors));
	if (!newClubs->isEmpty()) {
		BEGIN_CONSISTENT(newClubs->count() + 1) {
			BEGIN_FOR_EACH(ID,clubID,(newClubs->stepper())) {
				CurrentGrandMap.fluidGet()->getClub(clubID)->addSponsored(this);
			} END_FOR_EACH;
			mySponsors = CAST(IDRegion,mySponsors->unionWith(newClubs));
			this->diskUpdate();
		} END_CONSISTENT;
	}
}


RPTR(IDRegion) BeWork::sponsors (){
	return (IDRegion*) mySponsors;
}


void BeWork::unsponsor (APTR(IDRegion) clubs){
	/* Remove sponsors from the Work, and notify the Clubs */
	
	SPTR(IDRegion) lostClubs;
	
	/* Thing to do !!!! */
	
	/* Remove unsponsored clubs from the grandmap. */
	/* Thing to do !!!! */
	
	/* When Clubs can have multiple IDs, then it might still be 
		in the set */
	lostClubs = CAST(IDRegion,clubs->intersect(mySponsors));
	if (!lostClubs->isEmpty()) {
		BEGIN_CONSISTENT(lostClubs->count() + 1) {
			BEGIN_FOR_EACH(ID,clubID,(lostClubs->stepper())) {
				CurrentGrandMap.fluidGet()->getClub(clubID)->removeSponsored(this);
			} END_FOR_EACH;
			mySponsors = CAST(IDRegion,mySponsors->minus(clubs));
			this->diskUpdate();
		} END_CONSISTENT;
	}
}
/* private: */


void BeWork::updateFeStatus (){
	/* Tell all the FeWorks on this one to update their status */
	
	
	BEGIN_FOR_EACH(FeWork,work,(this->feRangeElements()->stepper())) {
		work->updateStatus();
	} END_FOR_EACH;
}
/* hooks: */


void BeWork::restartWork (APTR(Rcvr) /* rcvr */){
	myLockingWork = WeakPtrArray::make (BeWorkLockExecutor::make (this), 1);
	myRevisionWatchers = NULL;
}
/* creation */


BeWork::BeWork (APTR(FeEdition) contents, BooleanVar isClub) {
	SPTR(XnRegion) permissions;
	
	myEdition = contents->beEdition();
	myEditionLabel = CAST(BeLabel,contents->label()->getOrMakeBe());
	myReadClub = InitialReadClub.fluidFetch();
	if (myReadClub == NULL) {
		permissions = CurrentGrandMap.fluidGet()->globalIDSpace()->emptyRegion();
	} else {
		permissions = myReadClub->asRegion();
	}
	myEditClub = InitialEditClub.fluidFetch();
	if (myEditClub != NULL) {
		permissions = permissions->with(myEditClub);
	}
	myOwnProp = BertProp::permissionsProp(permissions);
	myRevisionCount = IntegerVarZero;
	myRevisionTime = ::xuTime();
	myReviser = CurrentAuthor.fluidGet();
	myHistory = NULL;
	myHistoryClub = NULL;
	/* Known bug !!!! */
	
	/* Should public shut off sponsorship? */
	if (InitialSponsor.fluidGet() == CurrentGrandMap.fluidGet()->emptyClubID()) {
		mySponsors = CAST(IDRegion,IDSpace::global()->emptyRegion());
	} else {
		mySponsors = CAST(IDRegion,InitialSponsor.fluidFetch()->asRegion());
	}
	this->restartWork(NULL);
	myEdition->introduceWork(this);
	/* Known bug !!!! */
	
	/* Is the above all right? */
	if (!isClub) {
		this->finishCreation();
	}
}


void BeWork::finishCreation (){
	/* Gets called once the object is created, to finish up */
	
	BEGIN_FOR_EACH(ID,iD,(mySponsors->stepper())) {
		CurrentGrandMap.fluidGet()->getClub(iD)->addSponsored(this);
	} END_FOR_EACH;
	this->newShepherd();
}
/* printing */


void BeWork::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << CurrentGrandMap.fluidGet()->iDsOf(this) << ")";
}



/* ************************************************************************ *
 * 
 *                    Class   BeClub 
 *
 * ************************************************************************ */



/* Initializers for BeClub */

BUILD_FLUID(BeClub,CurrentOwner, NULL, ServerChunk::emulsion());	/* in BeClub */
BUILD_FLUID(MuSet,ActiveClubs, MuSet::make (), DiskManager::emulsion());	/* in BeClub */


/* Initializers for BeClub */



/* creation */


RPTR(BeClub) BeClub::make (APTR(FeEdition) contents){
	BEGIN_CONSISTENT(-1) {
		RETURN_CONSTRUCT(BeClub,(contents, tcsj));
	} END_CONSISTENT;
}
/* dependents */


void BeClub::registerKeyMaster (APTR(FeKeyMaster) km){
	/* Notify the KeyMaster when the transitive super Clubs of 
	this Club change */
	
	if (myKeyMasters == NULL) {
		myKeyMasters = MuSet::make ();
		ActiveClubs.fluidGet()->introduce(this);
	}
	myKeyMasters->introduce(km);
}


void BeClub::unregisterKeyMaster (APTR(FeKeyMaster) km){
	/* Unregister a previously registered KeyMaster */
	
	if (myKeyMasters == NULL) {
		BLAST(NeverRegisteredKeyMaster);
	}
	myKeyMasters->remove(km);
	if (myKeyMasters->isEmpty()) {
		myKeyMasters = NULL;
		ActiveClubs.fluidGet()->remove(this);
	}
}
/* accessing */


void BeClub::addSponsored (APTR(BeWork) work){
	/* Add a sponsored Work (sent from the Work) */
	
	BEGIN_INSISTENT(1) {
		mySponsored->store(work);
		this->diskUpdate();
	} END_INSISTENT;
}


RPTR(ID) OR(NULL) BeClub::fetchSignatureClub (){
	/* The Club who can endorse and sponsor with this Club */
	
	return (ID*) mySignatureClub;
}


BooleanVar BeClub::isPurgeable (){
	{	BooleanVar crutch_Flag;
		/* this->BeWork::isPurgeable() && myKeyMasters == NULL */
		
		crutch_Flag = this->BeWork::isPurgeable();
		if(crutch_Flag) {
			crutch_Flag = myKeyMasters == NULL;
		}
		return crutch_Flag;
	}
}


RPTR(FeRangeElement) BeClub::makeFe (APTR(BeLabel) OR(NULL) label){
	WPTR(FeRangeElement) 	returnValue;
	returnValue = FeClub::on(this);
	return returnValue;
}


BooleanVar BeClub::membershipIncludes (APTR(BeClub) club){
	/* Whether the direct membership includes the given Club */
	
	return myMembers->hasMember(club);
}


void BeClub::removeSponsored (APTR(BeWork) work){
	/* Add a sponsored Work (sent from the Work) */
	
	BEGIN_INSISTENT(1) {
		mySponsored->wipe(work);
		this->diskUpdate();
	} END_INSISTENT;
}


void BeClub::setSignatureClub (APTR(ID) OR(NULL) clubID){
	/* Change the Club who can endorse and sponsor with this Club */
	
	mySignatureClub = clubID;
}


RPTR(ImmuSet) OF1(BeWork) BeClub::sponsored (){
	WPTR(ImmuSet) OF1(BeWork) 	returnValue;
	returnValue = mySponsored->asImmuSet();
	return returnValue;
}


RPTR(IDRegion) BeClub::transitiveMemberIDs (){
	return (IDRegion*) myTransitiveMemberIDs;
}


RPTR(IDRegion) BeClub::transitiveSuperClubIDs (){
	return (IDRegion*) myTransitiveSuperClubIDs;
}
/* private: propagating */


void BeClub::updateKeyMasters (){
	/* notify any KeyMasters who care that my transitive super 
		clubs have changed */
	if (myKeyMasters != NULL) {
		BEGIN_FOR_EACH(FeKeyMaster,km,(myKeyMasters->stepper())) {
			km->updateAuthority();
		} END_FOR_EACH;
	}
}
/* private: accessing */


RPTR(MuSet) OF1(BeClub) BeClub::immediateSuperClubs (){
	return (MuSet*) myImmediateSuperClubs;
}


RPTR(MuSet) OF1(BeClub) BeClub::members (){
	return (MuSet*) myMembers;
}
/* contents */


void BeClub::revise (APTR(FeEdition) contents){
	/* Update cached information */
	
	SPTR(MuSet) OF1(BeClub) oldMembers;
	SPTR(FeEdition) oldMembership;
	SPTR(FeEdition) newMembership;
	BooleanVar memberTest;
	
	if (!FeClubDescription::check(contents)) {
		BLAST(MustBeClubDescription);
	}
	BEGIN_CONSISTENT(-1) {
		oldMembership = CAST(FeEdition,this->edition()->fetch(Sequence::string("ClubDescription:Membership")));
		this->BeWork::revise(contents);
		/* Do this first so that permissions will change 
			after the revision */
		newMembership = CAST(FeEdition,contents->fetch(Sequence::string("ClubDescription:Membership")));
		/* Update cached info if membership changes */
		{	BooleanVar crutch_Flag;
			/* oldMembership == NULL || oldMembership->isEmpty() */
			
			crutch_Flag = oldMembership == NULL;
			if(!crutch_Flag) {
				crutch_Flag = oldMembership->isEmpty();
			}
			if (crutch_Flag) {
				memberTest = newMembership == NULL || newMembership->isEmpty();
			} else {
				memberTest = newMembership != NULL && newMembership->isIdentical(oldMembership);
			}
		}
		if (!memberTest) {
			oldMembers = myMembers;
			myMembers = MuSet::make ();
			BEGIN_FOR_EACH(FeWork,mem,(newMembership->stepper())) {
				myMembers->introduce(CAST(BeClub,mem->getOrMakeBe()));
			} END_FOR_EACH;
			/* Update all new members */
			BEGIN_FOR_EACH(BeClub,newMem,(myMembers->asImmuSet()->minus(oldMembers)->stepper())) {
				newMem->addImmediateSuperClub(this);
			} END_FOR_EACH;
			/* Update all lost members */
			BEGIN_FOR_EACH(BeClub,lostMem,(oldMembers->asImmuSet()->minus(myMembers)->stepper())) {
				lostMem->removeImmediateSuperClub(this);
			} END_FOR_EACH;
			/* Update self and all parents with new 
				membership list */
			this->updateTransitiveMemberIDs();
			this->diskUpdate();
		}
	} END_CONSISTENT;
}
/* propagating */


void BeClub::addImmediateSuperClub (APTR(BeClub) parent){
	/* Add an immediate super Club and update my cached 
	information, and those of my members */
	
	myImmediateSuperClubs->store(parent);
	this->updateTransitiveSuperClubIDs();
}


void BeClub::removeImmediateSuperClub (APTR(BeClub) parent){
	/* Add an immediate super Club and update my cached 
	information, and those of my members */
	
	myImmediateSuperClubs->remove(parent);
	this->updateTransitiveSuperClubIDs();
}


void BeClub::updateTransitiveMemberIDs (){
	/* Figure out result of changes in membership, then propagate 
	upwards */
	
	SPTR(XnRegion) result;
	
	result = IDSpace::global()->emptyRegion();
	BEGIN_FOR_EACH(BeClub,mem,(myMembers->stepper())) {
		result = result->unionWith(mem->transitiveMemberIDs());
	} END_FOR_EACH;
	result = result->with(CurrentGrandMap.fluidGet()->iDOf(this));
	if (!result->isEqual(myTransitiveMemberIDs)) {
		BEGIN_INSISTENT(4) {
			myTransitiveMemberIDs = CAST(IDRegion,result);
			this->diskUpdate();
			if (!myImmediateSuperClubs->isEmpty()) {
				UpdateTransitiveMemberIDs::make (myImmediateSuperClubs->copy()->asMuSet())->schedule();
			}
		} END_INSISTENT;
	}
}


void BeClub::updateTransitiveSuperClubIDs (){
	/* Figure out result of changes in membership, then propagate 
	upwards */
	
	SPTR(XnRegion) result;
	
	result = IDSpace::global()->emptyRegion();
	BEGIN_FOR_EACH(BeClub,sup,(myImmediateSuperClubs->stepper())) {
		result = result->unionWith(sup->transitiveSuperClubIDs());
	} END_FOR_EACH;
	result = result->with(CurrentGrandMap.fluidGet()->iDOf(this));
	if (!result->isEqual(myTransitiveSuperClubIDs)) {
		BEGIN_INSISTENT(4) {
			myTransitiveSuperClubIDs = CAST(IDRegion,result);
			this->diskUpdate();
			if (!myMembers->isEmpty()) {
				UpdateTransitiveSuperClubIDs::make (myMembers->copy()->asMuSet(), CurrentGrandMap.fluidGet())->schedule();
			}
		} END_INSISTENT;
		/* notify any KeyMasters who care that my transitive 
			super clubs have changed */
		if (myKeyMasters != NULL) {
			BEGIN_FOR_EACH(FeKeyMaster,km,(myKeyMasters->stepper())) {
				km->updateAuthority();
			} END_FOR_EACH;
		}
	}
}
/* hooks: */


void BeClub::restartClub (APTR(Rcvr) rcvr){
	myKeyMasters = NULL;
}
/* creation */


BeClub::BeClub (APTR(FeEdition) contents, TCSJ) 
	: BeWork(contents, TRUE) {
	SPTR(FeEdition) membership;
	
	mySignatureClub = InitialOwner.fluidGet();
	myMembers = MuSet::make ();
	membership = CAST(FeEdition,contents->fetch(Sequence::string("ClubDescription:Membership")));
	if (membership != NULL) {
		BEGIN_FOR_EACH(FeClub,club,(membership->stepper())) {
			myMembers->introduce(club->beClub());
		} END_FOR_EACH;
	}
	myImmediateSuperClubs = MuSet::make ();
	mySponsored = MuSet::make ();
	/* Known bug !!!! */
	
	/* wall flag */
	myWallFlag = FALSE;
	myTransitiveSuperClubIDs = CAST(IDRegion,IDSpace::global()->emptyRegion());
	myTransitiveMemberIDs = CAST(IDRegion,IDSpace::global()->emptyRegion());
	BEGIN_FOR_EACH(BeClub,mem,(myMembers->stepper())) {
		myTransitiveMemberIDs = CAST(IDRegion,myTransitiveMemberIDs->unionWith(mem->transitiveMemberIDs()));
	} END_FOR_EACH;
	this->restartClub(NULL);
	this->finishCreation();
}



/* ************************************************************************ *
 * 
 *                    Class BeWorkLockExecutor 
 *
 * ************************************************************************ */


/* pseudoconstructors */


RPTR(BeWorkLockExecutor) BeWorkLockExecutor::make (APTR(BeWork) work){
	RETURN_CONSTRUCT(BeWorkLockExecutor,(work, tcsj));
}
/* invoking */


void BeWorkLockExecutor::execute (Int32 /* estateIndex */){
	/* The work's locking pointer will already be NULL, so we 
	only have to update */
	
	myWork->updateFeStatus();
}
/* create */


BeWorkLockExecutor::BeWorkLockExecutor (APTR(BeWork) work, TCSJ) {
	myWork = work;
}



/* ************************************************************************ *
 * 
 *                    Class RevisionWatcherExecutor 
 *
 * ************************************************************************ */


/* create */


RPTR(XnExecutor) RevisionWatcherExecutor::make (APTR(BeWork) work){
	RETURN_CONSTRUCT(RevisionWatcherExecutor,(work, tcsj));
}
/* This executor tells its BeWork when the last of its revision 
watchers have gone away. */


/* protected: create */


RevisionWatcherExecutor::RevisionWatcherExecutor (APTR(BeWork) work, TCSJ) {
	myWork = work;
}
/* execute */


void RevisionWatcherExecutor::execute (Int32 arg){
	if (arg == Int32Zero) {
		myWork->removeLastRevisionWatcher();
	}
}



/* ************************************************************************ *
 * 
 *                    Class UpdateTransitiveMemberIDs 
 *
 * ************************************************************************ */


/* creation */


RPTR(UpdateTransitiveMemberIDs) UpdateTransitiveMemberIDs::make (APTR(MuSet) OF1(BeClub) clubs){
	RETURN_CONSTRUCT(UpdateTransitiveMemberIDs,(clubs, tcsj));
}
/* This carries on the updating of transitive member IDs for the given club. */


/* accessing */


BooleanVar UpdateTransitiveMemberIDs::step (){
	if (!myClubs->isEmpty()) {
		BEGIN_CONSISTENT(5) {
			SPTR(BeClub) club;
			SPTR(Stepper) stomp;
			
			club = CAST(BeClub,(stomp = myClubs->stepper())->fetch());
			{stomp->destroy();  stomp = NULL /* don't want stale (S/CHK)PTRs */;}
			club->updateTransitiveMemberIDs();
			myClubs->remove(club);
			this->diskUpdate();
		} END_CONSISTENT;
	}
	return !myClubs->isEmpty();
}
/* protected: creation */


UpdateTransitiveMemberIDs::UpdateTransitiveMemberIDs (APTR(MuSet) OF1(BeClub) clubs, TCSJ) {
	myClubs = clubs;
	this->newShepherd();
}



/* ************************************************************************ *
 * 
 *                    Class UpdateTransitiveSuperClubIDs 
 *
 * ************************************************************************ */


/* creation */


RPTR(UpdateTransitiveSuperClubIDs) UpdateTransitiveSuperClubIDs::make (APTR(MuSet) OF1(BeClub) clubs, APTR(BeGrandMap) grandMap){
	RETURN_CONSTRUCT(UpdateTransitiveSuperClubIDs,(clubs, grandMap));
}
/* This carries on the updating of transitive superclass IDs for the 
given club. */


/* accessing */


BooleanVar UpdateTransitiveSuperClubIDs::step (){
	if (!myClubs->isEmpty()) {
		BEGIN_CONSISTENT(2) {
			SPTR(BeClub) club;
			SPTR(Stepper) stomp;
			
			club = CAST(BeClub,(stomp = myClubs->stepper())->fetch());
			{stomp->destroy();  stomp = NULL /* don't want stale (S/CHK)PTRs */;}
			{	FLUID_BIND(CurrentGrandMap,myGrandMap) {
					club->updateTransitiveSuperClubIDs();
				}
			}
			myClubs->remove(club);
			this->diskUpdate();
		} END_CONSISTENT;
	}
	return !myClubs->isEmpty();
}
/* protected: creation */


UpdateTransitiveSuperClubIDs::UpdateTransitiveSuperClubIDs (APTR(MuSet) OF1(BeClub) clubs, APTR(BeGrandMap) grandMap) {
	myClubs = clubs;
	myGrandMap = grandMap;
	this->newShepherd();
}

#ifndef BRANGE2X_SXX
#include "brange2x.sxx"
#endif /* BRANGE2X_SXX */


#ifndef BRANGE2P_SXX
#include "brange2p.sxx"
#endif /* BRANGE2P_SXX */



#endif /* BRANGE2X_CXX */

