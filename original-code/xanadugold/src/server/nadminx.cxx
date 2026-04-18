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

#ifndef NADMINX_CXX
#define NADMINX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef NADMINX_HXX
#include "nadminx.hxx"
#endif /* NADMINX_HXX */

#ifndef NADMINX_IXX
#include "nadminx.ixx"
#endif /* NADMINX_IXX */

#ifndef NADMINP_HXX
#include "nadminp.hxx"
#endif /* NADMINP_HXX */

#ifndef NADMINP_IXX
#include "nadminp.ixx"
#endif /* NADMINP_IXX */


#ifndef CRYPTOX_HXX
#include "cryptox.hxx"
#endif /* CRYPTOX_HXX */

#ifndef FLUIDX_HXX
#include "fluidx.hxx"
#endif /* FLUIDX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef NKERNELX_HXX
#include "nkernelx.hxx"
#endif /* NKERNELX_HXX */

#ifndef SCHUNKX_HXX
#include "schunkx.hxx"
#endif /* SCHUNKX_HXX */

#ifndef SEQUENCX_HXX
#include "sequencx.hxx"
#endif /* SEQUENCX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */




/* ************************************************************************ *
 * 
 *                    Class FeClubDescription 
 *
 * ************************************************************************ */



/* Initializers for FeClubDescription */

GPTR(FeWrapperSpec) FeClubDescription::TheClubDescriptionSpec = NULL;



BEGIN_INIT_TIME(FeClubDescription,initTimeNonInherited) {
	DIRECTWRAPPER("ClubDescription","Wrapper",FeClubDescription);
} END_INIT_TIME(FeClubDescription,initTimeNonInherited);



/* Initializers for FeClubDescription */






/* private: wrapping */


BooleanVar FeClubDescription::check (APTR(FeEdition) edition){
	/* Check that it has the right fields in the right places. 
	Ignore other contents. */
	
	{	BooleanVar crutch_Flag;
		/* FeWrapper::checkDomainIn(edition, Sequence::string("ClubDescription:LockSmith")->asRegion()->with(Sequence::string("ClubDescription:Membership"))) && FeWrapper::checkSubEdition(edition, Sequence::string("ClubDescription:Membership"), FeSet::spec(), FALSE) && 
							FeWrapper::checkSubEdition(edition, Sequence::string("ClubDescription:LockSmith"), FeLockSmith::spec(), FALSE) */
		
		crutch_Flag = FeWrapper::checkDomainIn(edition, Sequence::string("ClubDescription:LockSmith")->asRegion()->with(Sequence::string("ClubDescription:Membership")));
		if(crutch_Flag) {
			crutch_Flag = FeWrapper::checkSubEdition(edition, Sequence::string("ClubDescription:Membership"), FeSet::spec(), FALSE);
			if(crutch_Flag) {
				crutch_Flag = FeWrapper::checkSubEdition(edition, Sequence::string("ClubDescription:LockSmith"), FeLockSmith::spec(), FALSE);
			}
		}
		if (!crutch_Flag) {
			return FALSE;
		}
	}
	if (edition->includesKey(Sequence::string("ClubDescription:Membership"))) {
		SPTR(FeEdition) sub;
		
		sub = CAST(FeEdition,edition->get(Sequence::string("ClubDescription:Membership")));
		BEGIN_FOR_EACH(FeRangeElement,r,(sub->stepper())) {
			if (!r->isKindOf(cat_FeClub)) {
				return FALSE;
			}
		} END_FOR_EACH;
	}
	return TRUE;
}


RPTR(FeClubDescription) FeClubDescription::construct (APTR(FeEdition) edition){
	/* Create a new wrapper and endorse it */
	
	FeClubDescription::spec()->endorse(edition);
	return CAST(FeClubDescription,FeClubDescription::makeWrapper(edition));
}


RPTR(FeWrapper) FeClubDescription::makeWrapper (APTR(FeEdition) edition){
	/* Just create a new wrapper */
	
	RETURN_CONSTRUCT(FeClubDescription,(edition, FeClubDescription::spec()));
}


void FeClubDescription::setSpec (APTR(FeWrapperSpec) wrap){
	FeClubDescription::TheClubDescriptionSpec = wrap;
}
/* pseudo constructors */


RPTR(FeClubDescription) FeClubDescription::make (APTR(FeSet) OR(NULL) OF1(FeClub) membership, APTR(FeLockSmith) lockSmith/* = NULL*/){
	SPTR(FeEdition) result;
	
	result = FeEdition::empty(SequenceSpace::make ());
	if (membership != NULL) {
		result = result->with(Sequence::string("ClubDescription:Membership"), membership->edition());
	}
	if (lockSmith != NULL) {
		result = result->with(Sequence::string("ClubDescription:LockSmith"), lockSmith->edition());
	}
	return CAST(FeClubDescription,FeClubDescription::spec()->wrap(result));
}


RPTR(FeWrapperSpec) FeClubDescription::spec (){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FeClubDescription::TheClubDescriptionSpec;
	return returnValue;
}
/* Describes the state of Club -- who is in it, which Work is its 
home (if it has one), and how you can login to it */


/* accessing */


RPTR(FeLockSmith) FeClubDescription::lockSmith (){
	/* Describes how authority for this Club is gained */
	
	if (this->edition()->includesKey(Sequence::string("ClubDescription:LockSmith"))) {
		return CAST(FeLockSmith,FeLockSmith::spec()->wrap(CAST(FeEdition,this->edition()->get(Sequence::string("ClubDescription:LockSmith")))));
	} else {
		WPTR(FeLockSmith) 	returnValue;
		returnValue = FeWallLockSmith::make ();
		return returnValue;
	}
}


RPTR(FeSet) OF1(FeClub) FeClubDescription::membership (){
	/* The Clubs which are members of this one. */
	
	if (this->edition()->includesKey(Sequence::string("ClubDescription:Membership"))) {
		return CAST(FeSet,FeSet::spec()->wrap(CAST(FeEdition,this->edition()->get(Sequence::string("ClubDescription:Membership")))));
	} else {
		WPTR(FeSet) OF1(FeClub) 	returnValue;
		returnValue = FeSet::make ();
		return returnValue;
	}
}


RPTR(FeClubDescription) FeClubDescription::withLockSmith (APTR(FeLockSmith) lockSmith){
	/* Change how authority is gained */
	
	WPTR(FeClubDescription) 	returnValue;
	returnValue = FeClubDescription::construct(this->edition()->with(Sequence::string("ClubDescription:LockSmith"), lockSmith->edition()));
	return returnValue;
}


RPTR(FeClubDescription) FeClubDescription::withMembership (APTR(FeSet) OF1(FeClub) members){
	/* Change the entire membership list */
	
	WPTR(FeClubDescription) 	returnValue;
	returnValue = FeClubDescription::construct(this->edition()->with(Sequence::string("ClubDescription:Membership"), members->edition()));
	return returnValue;
}
/* private: create */


FeClubDescription::FeClubDescription (APTR(FeEdition) edition, APTR(FeWrapperSpec) spec) 
	: FeWrapper(edition, spec) {
	
}
/* printing */


void FeClubDescription::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << this->lockSmith() << ", " << this->membership() << ")";
}



/* ************************************************************************ *
 * 
 *                    Class FeLockSmith 
 *
 * ************************************************************************ */



/* Initializers for FeLockSmith */

GPTR(FeWrapperSpec) FeLockSmith::TheLockSmithSpec = NULL;



BEGIN_INIT_TIME(FeLockSmith,initTimeNonInherited) {
	ABSTRACTWRAPPER("LockSmith","Wrapper",FeLockSmith);
} END_INIT_TIME(FeLockSmith,initTimeNonInherited);



/* Initializers for FeLockSmith */






/* private: wrapping */


void FeLockSmith::setSpec (APTR(FeWrapperSpec) spec){
	FeLockSmith::TheLockSmithSpec = spec;
}
/* pseudo constructors */


RPTR(FeWrapperSpec) FeLockSmith::spec (){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FeLockSmith::TheLockSmithSpec;
	return returnValue;
}
/* Describes how to obtain the authority of a Club. */


/* server locks */
/* protected: create */


FeLockSmith::FeLockSmith (APTR(FeEdition) edition, APTR(FeWrapperSpec) spec) 
	: FeWrapper(edition, spec) {
	
}



/* ************************************************************************ *
 * 
 *                    Class   FeBooLockSmith 
 *
 * ************************************************************************ */



/* Initializers for FeBooLockSmith */

GPTR(FeWrapperSpec) FeBooLockSmith::TheBooLockSmithSpec = NULL;



BEGIN_INIT_TIME(FeBooLockSmith,initTimeNonInherited) {
	DIRECTWRAPPER("BooLockSmith","LockSmith",FeBooLockSmith);
} END_INIT_TIME(FeBooLockSmith,initTimeNonInherited);



/* Initializers for FeBooLockSmith */






/* private: wrapping */


BooleanVar FeBooLockSmith::check (APTR(FeEdition) edition){
	/* Hack !!!! */
	
	/* and: [((edition zoneOf: PrimSpec uInt8) domain
				isEqual: (IntegerRegion make: IntegerVarZero with: 3)) */
	/* ] */
	{	BooleanVar crutch_Flag;
		/* edition->domain()->isEqual(IntegerRegion::make (IntegerVarZero, 3)) && CAST(PrimIntegerArray,CAST(FeArrayBundle,edition->retrieve()->theOne())->array())->contentsEqual(UInt8Array::string("boo")) */
		
		crutch_Flag = edition->domain()->isEqual(IntegerRegion::make (IntegerVarZero, 3));
		if(crutch_Flag) {
			crutch_Flag = CAST(PrimIntegerArray,CAST(FeArrayBundle,edition->retrieve()->theOne())->array())->contentsEqual(UInt8Array::string("boo"));
		}
		return crutch_Flag;
	}
}


RPTR(FeBooLockSmith) FeBooLockSmith::construct (APTR(FeEdition) edition){
	FeBooLockSmith::spec()->endorse(edition);
	return CAST(FeBooLockSmith,FeBooLockSmith::makeWrapper(edition));
}


RPTR(FeWrapper) FeBooLockSmith::makeWrapper (APTR(FeEdition) edition){
	RETURN_CONSTRUCT(FeBooLockSmith,(edition, FeBooLockSmith::spec()));
}


void FeBooLockSmith::setSpec (APTR(FeWrapperSpec) wrap){
	FeBooLockSmith::TheBooLockSmithSpec = wrap;
}
/* pseudo constructors */


RPTR(FeBooLockSmith) FeBooLockSmith::make (){
	WPTR(FeBooLockSmith) 	returnValue;
	returnValue = FeBooLockSmith::construct(FeEdition::fromArray(UInt8Array::string("boo")));
	return returnValue;
}


RPTR(FeWrapperSpec) FeBooLockSmith::spec (){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FeBooLockSmith::TheBooLockSmithSpec;
	return returnValue;
}
/* Makes BooLocks; see the comment there */


/* server locks */


RPTR(Lock) FeBooLockSmith::newLock (APTR(ID) OR(NULL) clubID){
	/* Make a WallLock if clubID is NULL */
	
	if (clubID == NULL) {
		WPTR(Lock) 	returnValue;
		returnValue = FeWallLockSmith::make ()->newLock(NULL);
		return returnValue;
	} else {
		WPTR(Lock) 	returnValue;
		returnValue = BooLock::make (clubID, this);
		return returnValue;
	}
}
/* private: create */


FeBooLockSmith::FeBooLockSmith (APTR(FeEdition) edition, APTR(FeWrapperSpec) spec) 
	: FeLockSmith(edition, spec) {
	
}



/* ************************************************************************ *
 * 
 *                    Class   FeChallengeLockSmith 
 *
 * ************************************************************************ */



/* Initializers for FeChallengeLockSmith */

GPTR(FeWrapperSpec) FeChallengeLockSmith::TheChallengeLockSmithSpec = NULL;



BEGIN_INIT_TIME(FeChallengeLockSmith,initTimeNonInherited) {
	DIRECTWRAPPER("ChallengeLockSmith","LockSmith",FeChallengeLockSmith);
} END_INIT_TIME(FeChallengeLockSmith,initTimeNonInherited);



/* Initializers for FeChallengeLockSmith */






/* pseudo constructors */


RPTR(FeChallengeLockSmith) FeChallengeLockSmith::make (APTR(PrimIntArray) publicKey, APTR(Sequence) encrypterName){
	SPTR(FeEdition) result;
	
	result = FeEdition::fromOne(Sequence::string("ChallengeLockSmith:PublicKey"), FeEdition::fromArray(CAST(UInt8Array,publicKey)));
	result = result->with(Sequence::string("ChallengeLockSmith:EncrypterName"), FeEdition::fromArray(encrypterName->integers()));
	WPTR(FeChallengeLockSmith) 	returnValue;
	returnValue = FeChallengeLockSmith::construct(result);
	return returnValue;
}


RPTR(FeWrapperSpec) FeChallengeLockSmith::spec (){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FeChallengeLockSmith::TheChallengeLockSmithSpec;
	return returnValue;
}
/* private: wrapping */


BooleanVar FeChallengeLockSmith::check (APTR(FeEdition) edition){
	{	BooleanVar crutch_Flag;
		/* edition->domain()->isEqual(Sequence::string("ChallengeLockSmith:EncrypterName")->asRegion()->with(Sequence::string("ChallengeLockSmith:PublicKey"))) && FeWrapper::checkSubSequence(edition, Sequence::string("ChallengeLockSmith:EncrypterName"), TRUE) && 
							FeWrapper::checkSubSequence(edition, Sequence::string("ChallengeLockSmith:PublicKey"), TRUE) */
		
		crutch_Flag = edition->domain()->isEqual(Sequence::string("ChallengeLockSmith:EncrypterName")->asRegion()->with(Sequence::string("ChallengeLockSmith:PublicKey")));
		if(crutch_Flag) {
			crutch_Flag = FeWrapper::checkSubSequence(edition, Sequence::string("ChallengeLockSmith:EncrypterName"), TRUE);
			if(crutch_Flag) {
				crutch_Flag = FeWrapper::checkSubSequence(edition, Sequence::string("ChallengeLockSmith:PublicKey"), TRUE);
			}
		}
		return crutch_Flag;
	}
}


RPTR(FeChallengeLockSmith) FeChallengeLockSmith::construct (APTR(FeEdition) edition){
	FeChallengeLockSmith::spec()->endorse(edition);
	return CAST(FeChallengeLockSmith,FeChallengeLockSmith::makeWrapper(edition));
}


RPTR(FeWrapper) FeChallengeLockSmith::makeWrapper (APTR(FeEdition) edition){
	RETURN_CONSTRUCT(FeChallengeLockSmith,(edition, FeChallengeLockSmith::spec()));
}


void FeChallengeLockSmith::setSpec (APTR(FeWrapperSpec) wrap){
	FeChallengeLockSmith::TheChallengeLockSmithSpec = wrap;
}
/* Makes ChallengeLocks; see the comment there */


/* accessing */


RPTR(UInt8Array) FeChallengeLockSmith::encrypterName (){
	/* The type of encrypter used to create encrypted challenges. */
	
	return CAST(UInt8Array,CAST(FeArrayBundle,CAST(FeEdition,this->edition()->get(Sequence::string("ChallengeLockSmith:EncrypterName")))->retrieve()->theOne())->array());
}


RPTR(UInt8Array) FeChallengeLockSmith::publicKey (){
	/* The public key used to construct challenges. */
	
	return CAST(UInt8Array,CAST(FeArrayBundle,CAST(FeEdition,this->edition()->get(Sequence::string("ChallengeLockSmith:PublicKey")))->retrieve()->theOne())->array());
}
/* server locks */


RPTR(Lock) FeChallengeLockSmith::newLock (APTR(ID) OR(NULL) clubID){
	/* Thing to do !!!! */
	
	/* Make this random */
	WPTR(Lock) 	returnValue;
	returnValue = ChallengeLock::make (clubID, this, UInt8Array::string("random"));
	return returnValue;
}
/* private: create */


FeChallengeLockSmith::FeChallengeLockSmith (APTR(FeEdition) edition, APTR(FeWrapperSpec) spec) 
	: FeLockSmith(edition, spec) {
	
}



/* ************************************************************************ *
 * 
 *                    Class   FeMatchLockSmith 
 *
 * ************************************************************************ */



/* Initializers for FeMatchLockSmith */

GPTR(FeWrapperSpec) FeMatchLockSmith::TheMatchLockSmithSpec = NULL;



BEGIN_INIT_TIME(FeMatchLockSmith,initTimeNonInherited) {
	DIRECTWRAPPER("MatchLockSmith","LockSmith",FeMatchLockSmith);
} END_INIT_TIME(FeMatchLockSmith,initTimeNonInherited);



/* Initializers for FeMatchLockSmith */






/* private: wrapping */


BooleanVar FeMatchLockSmith::check (APTR(FeEdition) edition){
	{	BooleanVar crutch_Flag;
		/* edition->domain()->isEqual(Sequence::string("MatchLockSmith:ScramblerName")->asRegion()->with(Sequence::string("MatchLockSmith:ScrambledPassword"))) && FeWrapper::checkSubSequence(edition, Sequence::string("MatchLockSmith:ScramblerName"), TRUE) && 
							FeWrapper::checkSubSequence(edition, Sequence::string("MatchLockSmith:ScrambledPassword"), TRUE) */
		
		crutch_Flag = edition->domain()->isEqual(Sequence::string("MatchLockSmith:ScramblerName")->asRegion()->with(Sequence::string("MatchLockSmith:ScrambledPassword")));
		if(crutch_Flag) {
			crutch_Flag = FeWrapper::checkSubSequence(edition, Sequence::string("MatchLockSmith:ScramblerName"), TRUE);
			if(crutch_Flag) {
				crutch_Flag = FeWrapper::checkSubSequence(edition, Sequence::string("MatchLockSmith:ScrambledPassword"), TRUE);
			}
		}
		return crutch_Flag;
	}
}


RPTR(FeMatchLockSmith) FeMatchLockSmith::construct (APTR(FeEdition) edition){
	FeMatchLockSmith::spec()->endorse(edition);
	return CAST(FeMatchLockSmith,FeMatchLockSmith::makeWrapper(edition));
}


RPTR(FeWrapper) FeMatchLockSmith::makeWrapper (APTR(FeEdition) edition){
	RETURN_CONSTRUCT(FeMatchLockSmith,(edition, FeMatchLockSmith::spec()));
}


void FeMatchLockSmith::setSpec (APTR(FeWrapperSpec) wrap){
	FeMatchLockSmith::TheMatchLockSmithSpec = wrap;
}
/* pseudo constructors */


RPTR(FeMatchLockSmith) FeMatchLockSmith::make (APTR(PrimIntArray) scrambledPassword, APTR(Sequence) scramblerName){
	SPTR(FeEdition) result;
	
	result = FeEdition::fromOne(Sequence::string("MatchLockSmith:ScrambledPassword"), FeEdition::fromArray(CAST(UInt8Array,scrambledPassword)));
	result = result->with(Sequence::string("MatchLockSmith:ScramblerName"), FeEdition::fromArray(scramblerName->integers()));
	WPTR(FeMatchLockSmith) 	returnValue;
	returnValue = FeMatchLockSmith::construct(result);
	return returnValue;
}


RPTR(FeWrapperSpec) FeMatchLockSmith::spec (){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FeMatchLockSmith::TheMatchLockSmithSpec;
	return returnValue;
}
/* Makes MatchLocks; see the comment there */


/* accessing */


RPTR(UInt8Array) FeMatchLockSmith::scrambledPassword (){
	/* The password in scrambled form. If the scrambler is any 
	good, this should be meaningless. */
	
	return CAST(UInt8Array,CAST(FeArrayBundle,CAST(FeEdition,this->edition()->get(Sequence::string("MatchLockSmith:ScrambledPassword")))->retrieve()->theOne())->array());
}


RPTR(UInt8Array) FeMatchLockSmith::scramblerName (){
	/* The name of scrambler being used to scramble the password. */
	
	return CAST(UInt8Array,CAST(FeArrayBundle,CAST(FeEdition,this->edition()->get(Sequence::string("MatchLockSmith:ScramblerName")))->retrieve()->theOne())->array());
}
/* server locks */


RPTR(Lock) FeMatchLockSmith::newLock (APTR(ID) OR(NULL) clubID){
	WPTR(Lock) 	returnValue;
	returnValue = MatchLock::make (clubID, this);
	return returnValue;
}
/* private: create */


FeMatchLockSmith::FeMatchLockSmith (APTR(FeEdition) edition, APTR(FeWrapperSpec) spec) 
	: FeLockSmith(edition, spec) {
	
}



/* ************************************************************************ *
 * 
 *                    Class   FeMultiLockSmith 
 *
 * ************************************************************************ */



/* Initializers for FeMultiLockSmith */

GPTR(FeWrapperSpec) FeMultiLockSmith::TheMultiLockSmithSpec = NULL;



BEGIN_INIT_TIME(FeMultiLockSmith,initTimeNonInherited) {
	DIRECTWRAPPER("MultiLockSmith","LockSmith",FeMultiLockSmith);
} END_INIT_TIME(FeMultiLockSmith,initTimeNonInherited);



/* Initializers for FeMultiLockSmith */






/* private: wrapping */


BooleanVar FeMultiLockSmith::check (APTR(FeEdition) edition){
	{	BooleanVar crutch_Flag;
		/* SequenceSpace::make ()->isEqual(edition->coordinateSpace()) && 
					FeWrapper::checkSubEditions(edition, edition->domain(), FeLockSmith::spec(), TRUE) */
		
		crutch_Flag = SequenceSpace::make ()->isEqual(edition->coordinateSpace());
		if(crutch_Flag) {
			crutch_Flag = FeWrapper::checkSubEditions(edition, edition->domain(), FeLockSmith::spec(), TRUE);
		}
		return crutch_Flag;
	}
}


RPTR(FeMultiLockSmith) FeMultiLockSmith::construct (APTR(FeEdition) edition){
	FeMultiLockSmith::spec()->endorse(edition);
	return CAST(FeMultiLockSmith,FeMultiLockSmith::makeWrapper(edition));
}


RPTR(FeWrapper) FeMultiLockSmith::makeWrapper (APTR(FeEdition) edition){
	RETURN_CONSTRUCT(FeMultiLockSmith,(edition, FeMultiLockSmith::spec()));
}


void FeMultiLockSmith::setSpec (APTR(FeWrapperSpec) wrap){
	FeMultiLockSmith::TheMultiLockSmithSpec = wrap;
}
/* pseudo constructors */


RPTR(FeMultiLockSmith) FeMultiLockSmith::make (){
	WPTR(FeMultiLockSmith) 	returnValue;
	returnValue = FeMultiLockSmith::construct(FeEdition::empty(SequenceSpace::make ()));
	return returnValue;
}


RPTR(FeWrapperSpec) FeMultiLockSmith::spec (){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FeMultiLockSmith::TheMultiLockSmithSpec;
	return returnValue;
}
/* Makes MultiLocks; see the comment there */


/* server locks */


RPTR(Lock) FeMultiLockSmith::newLock (APTR(ID) OR(NULL) clubID){
	SPTR(MuTable) OF1(Lock) result;
	
	result = MuTable::make (SequenceSpace::make ());
	BEGIN_FOR_POSITIONS(Sequence,name,FeEdition,smith,(this->edition()->stepper())) {
		result->introduce(name, CAST(FeLockSmith,FeLockSmith::spec()->wrap(smith))->newLock(clubID));
	} END_FOR_POSITIONS;
	WPTR(Lock) 	returnValue;
	returnValue = MultiLock::make (clubID, this, result->asImmuTable());
	return returnValue;
}
/* accessing */


RPTR(FeLockSmith) FeMultiLockSmith::lockSmith (APTR(Sequence) name){
	/* The named LockSmith */
	
	return CAST(FeLockSmith,FeLockSmith::spec()->wrap(CAST(FeEdition,this->edition()->get(name))));
}


RPTR(SequenceRegion) OF1(Sequence) FeMultiLockSmith::lockSmithNames (){
	/* The names of all the Locksmiths this uses. */
	
	return CAST(SequenceRegion,this->edition()->domain());
}


RPTR(FeMultiLockSmith) FeMultiLockSmith::with (APTR(Sequence) name, APTR(FeLockSmith) smith){
	/* Add or change a LockSmith */
	
	return CAST(FeMultiLockSmith,FeMultiLockSmith::construct(this->edition()->with(name, smith->edition())));
}


RPTR(FeMultiLockSmith) FeMultiLockSmith::without (APTR(Sequence) name){
	/* Add or change a LockSmith */
	
	return CAST(FeMultiLockSmith,FeMultiLockSmith::construct(this->edition()->without(name)));
}
/* private: create */


FeMultiLockSmith::FeMultiLockSmith (APTR(FeEdition) edition, APTR(FeWrapperSpec) spec) 
	: FeLockSmith(edition, spec) {
	
}



/* ************************************************************************ *
 * 
 *                    Class   FeWallLockSmith 
 *
 * ************************************************************************ */



/* Initializers for FeWallLockSmith */

GPTR(FeWrapperSpec) FeWallLockSmith::TheWallLockSmithSpec = NULL;



BEGIN_INIT_TIME(FeWallLockSmith,initTimeNonInherited) {
	DIRECTWRAPPER("WallLockSmith","LockSmith",FeWallLockSmith);
} END_INIT_TIME(FeWallLockSmith,initTimeNonInherited);



/* Initializers for FeWallLockSmith */






/* private: wrapping */


BooleanVar FeWallLockSmith::check (APTR(FeEdition) edition){
	/* Hack !!!! */
	
	/* and: [((edition zoneOf: PrimSpec uInt8) domain
				isEqual: (IntegerRegion make: IntegerVarZero with: 4)) */
	/* ] */
	{	BooleanVar crutch_Flag;
		/* edition->domain()->isEqual(IntegerRegion::make (IntegerVarZero, 4)) && CAST(PrimIntegerArray,CAST(FeArrayBundle,edition->retrieve()->theOne())->array())->contentsEqual(UInt8Array::string("wall")) */
		
		crutch_Flag = edition->domain()->isEqual(IntegerRegion::make (IntegerVarZero, 4));
		if(crutch_Flag) {
			crutch_Flag = CAST(PrimIntegerArray,CAST(FeArrayBundle,edition->retrieve()->theOne())->array())->contentsEqual(UInt8Array::string("wall"));
		}
		return crutch_Flag;
	}
}


RPTR(FeWallLockSmith) FeWallLockSmith::construct (APTR(FeEdition) edition){
	FeWallLockSmith::spec()->endorse(edition);
	return CAST(FeWallLockSmith,FeWallLockSmith::makeWrapper(edition));
}


RPTR(FeWrapper) FeWallLockSmith::makeWrapper (APTR(FeEdition) edition){
	RETURN_CONSTRUCT(FeWallLockSmith,(edition, FeWallLockSmith::spec()));
}


void FeWallLockSmith::setSpec (APTR(FeWrapperSpec) wrap){
	FeWallLockSmith::TheWallLockSmithSpec = wrap;
}
/* pseudo constructors */


RPTR(FeWallLockSmith) FeWallLockSmith::make (){
	WPTR(FeWallLockSmith) 	returnValue;
	returnValue = FeWallLockSmith::construct(FeEdition::fromArray(UInt8Array::string("wall")));
	return returnValue;
}


RPTR(FeWrapperSpec) FeWallLockSmith::spec (){
	WPTR(FeWrapperSpec) 	returnValue;
	returnValue = FeWallLockSmith::TheWallLockSmithSpec;
	return returnValue;
}
/* Makes WallLocks; see the comment there */


/* server locks */


RPTR(Lock) FeWallLockSmith::newLock (APTR(ID) OR(NULL) clubID){
	WPTR(Lock) 	returnValue;
	returnValue = WallLock::make (clubID, this);
	return returnValue;
}
/* private: create */


FeWallLockSmith::FeWallLockSmith (APTR(FeEdition) edition, APTR(FeWrapperSpec) spec) 
	: FeLockSmith(edition, spec) {
	
}



/* ************************************************************************ *
 * 
 *                    Class FeSession 
 *
 * ************************************************************************ */



/* Initializers for FeSession */

BUILD_FLUID(FeSession,CurrentSession, DefaultSession::make (), ServerChunk::emulsion());	/* in FeSession */


/* Initializers for FeSession */



/* accessing */


RPTR(Stepper) OF1(FeSession) FeSession::allActive (){
	/* CurrentSessions fluidFetch == NULL
			ifTrue: [^Stepper itemStepper: CurrentSession fluidGet]
			ifFalse:
				[| acc {SetAccumulator} cur {FePromiseSession} |
				acc _ SetAccumulator make.
				cur _ CurrentSessions fluidGet.
				[cur ~~ NULL] whileTrue:
					[acc step: cur.
					cur _ cur next].
				^(acc value cast: ScruSet) stepper] */
	
	WPTR(Stepper) OF1(FeSession) 	returnValue;
	returnValue = ImmuSet::make ()->stepper();
	return returnValue;
}


RPTR(FeSession) FeSession::current (){
	WPTR(FeSession) 	returnValue;
	returnValue = CurrentSession.fluidGet();
	return returnValue;
}
/* Represent a single unique connection to the server over some 
underlying bytestream channel. */


/* accessing */


IntegerVar FeSession::connectTime (){
	/* Essential. The clock time at which the connection was initiated. */
	
	return myConnectTime;
}


RPTR(ID) FeSession::initialLogin (){
	/* Essential. The ID of the club that the session logged into 
	to get past the perimeter.  Blast of the session is not yet 
	admitted. */
	
	if (myInitialLogin == NULL) {
		BLAST(NotLoggedIn);
	}
	return (ID*) myInitialLogin;
}


BooleanVar FeSession::isLoggedIn (){
	/* Return whether the session has sucessfully logged in. */
	
	return myInitialLogin != NULL;
}
/* creation */


FeSession::FeSession () {
	myInitialLogin = NULL;
	myConnectTime = FeServer::currentTime();
	CurrentSession.fluidSet(this);
}
/* private: accessing */


void FeSession::setInitialLogin (APTR(ID) iD){
	/* Set the ID of the Club which initially logged in during 
	this session */
	
	if ( ! (myInitialLogin == NULL) ) {
		BLAST(Assertion_failed);
	}
	myInitialLogin = iD;
}



/* ************************************************************************ *
 * 
 *                    Class Lock 
 *
 * ************************************************************************ */


/* To login to a club, you ask the server for a Lock. If you send the 
right message to the Lock, it will return you a new KeyMaster with 
the authority of the club. Each subclass of Lock defines its own 
protocol for opening. 

For each kind of Lock, there is a corresponding kind of LockSmith 
which creates it. Each ClubManager has a LockSmith sub-document, and 
when you ask the server for a Lock to that club, it asks the club`s 
LockSmith document Wrapper to create a newLock. The LockSmith then 
creates the corresponding kind of Lock. It may also use information 
stored in the LockSmith document, such as a password or scramblerName. */


/* create */


Lock::Lock (APTR(ID) loginID, APTR(FeLockSmith) lockSmith) {
	myLoginClubID = loginID;
	myLockSmith = lockSmith;
}
/* server accessing */


RPTR(FeKeyMaster) Lock::makeKeyMaster (){
	/* The lock is opened - make the right KeyMaster */
	
	/* Hack !!!! */
	
	/* This should eventually be done by manipulating the cookbooks */
	if (!FeSession::current()->isLoggedIn()) {
		FeSession::current()->setInitialLogin(myLoginClubID);
	}
	WPTR(FeKeyMaster) 	returnValue;
	returnValue = FeKeyMaster::make (myLoginClubID);
	return returnValue;
}
/* protected: */


RPTR(ID) Lock::fetchLoginClubID (){
	/* The ID of the club whose authority you can get by opening 
	this lock. */
	
	return (ID*) myLoginClubID;
}


RPTR(FeLockSmith) Lock::lockSmith (){
	/* Essential. The LockSmith which made this Lock. */
	
	return (FeLockSmith*) myLockSmith;
}



/* ************************************************************************ *
 * 
 *                    Class   BooLock 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(BooLock) BooLock::make (APTR(ID) clubID, APTR(FeLockSmith) lockSmith){
	RETURN_CONSTRUCT(BooLock,(clubID, lockSmith));
}
/* A BooLock is very easy to open. Just say "boo". 

Since anyone can get in, only public clubs with little authority, 
such as System Public, should have BooLockSmiths. */


/* accessing */


RPTR(FeKeyMaster) BooLock::boo (){
	/* Essential.  This is a very easy lock to open. Just say `boo'. */
	
	WPTR(FeKeyMaster) 	returnValue;
	returnValue = this->makeKeyMaster();
	return returnValue;
}
/* private: create */


BooLock::BooLock (APTR(ID) clubID, APTR(FeLockSmith) lockSmith) 
	: Lock(clubID, lockSmith) {
	
}



/* ************************************************************************ *
 * 
 *                    Class   ChallengeLock 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(ChallengeLock) ChallengeLock::make (
		APTR(ID) OR(NULL) loginID, 
		APTR(FeChallengeLockSmith) lockSmith, 
		APTR(UInt8Array) response)
{
	RETURN_CONSTRUCT(ChallengeLock,(loginID, lockSmith, Encrypter::make (Sequence::numbers(lockSmith->encrypterName()), lockSmith->publicKey())->encrypt(response), CAST(UInt8Array,response->copy())));
}
/* A ChallengeLock challenges the client with a random piece of data 
that has been encrypted with a publicKey, using an algorithm 
identified by the encrypterName. The client must decrypt it using the 
corresponding private key and respond with the decrypted challenge. 
If it matches the original random data, then the lock will open. The 
encrypterName and the publicKey are stored in the club`s 
ChallengeLockSmith.  */


/* private: create */


ChallengeLock::ChallengeLock (
		APTR(ID) allegedID, 
		APTR(FeLockSmith) lockSmith, 
		APTR(UInt8Array) challenge, 
		APTR(UInt8Array) response) 

	: Lock(allegedID, lockSmith) {
	myChallenge = challenge;
	myResponse = response;
}
/* accessing */


RPTR(UInt8Array) ChallengeLock::challenge (){
	/* Essential.  The challenge which must be signed correctly 
	to open the lock. */
	
	return CAST(UInt8Array,myChallenge->copy());
}


RPTR(FeKeyMaster) ChallengeLock::response (APTR(PrimIntArray) signedChallenge){
	/* Essential.  The correctly signed challenge will open the lock. */
	
	{	BooleanVar crutch_Flag;
		/* this->fetchLoginClubID() != NULL && myResponse->contentsEqual(CAST(UInt8Array,signedChallenge)) */
		
		crutch_Flag = this->fetchLoginClubID() != NULL;
		if(crutch_Flag) {
			crutch_Flag = myResponse->contentsEqual(CAST(UInt8Array,signedChallenge));
		}
		if (!crutch_Flag) {
			BLAST(NotCorrectlySigned);
		}
	}
	WPTR(FeKeyMaster) 	returnValue;
	returnValue = this->makeKeyMaster();
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class   MatchLock 
 *
 * ************************************************************************ */


/* exceptions: exceptions */


/* pseudo constructors */


RPTR(MatchLock) MatchLock::make (APTR(ID) OR(NULL) clubID, APTR(FeMatchLockSmith) lockSmith){
	RETURN_CONSTRUCT(MatchLock,(clubID, lockSmith));
}
/* The correct password will open the lock. The password is actually 
stored in the club`s MatchLockSmith in scrambled form, using a 
Scrambler identified by scramblerName(). The scrambled cleartext 
supplied as a password is compared to the scrambledPassword in the 
MatchLockSmith. If they match, the lock is opened. 

The actual process is a bit more complicated than this. The user 
supplies a password in clear, which is encrypted with the current 
system public key and then sent to the server. There, it is first 
decrypted with the private key known only to the server. It is then 
scrambled and compared with the scrambled password stored in the 
MatchLockSmith of the club. This procedure both avoids sending 
passwords in clear over the network, and also allows the 
MatchLockSmith to be made readable without compromising security. */


/* accessing */


RPTR(FeKeyMaster) MatchLock::encryptedPassword (APTR(PrimIntArray) encrypted){
	/* Send the encrypted password to the server to be checked.
		NOTE: (for protocol review) The password must have been 
	encrypted using a (yet-to-be-defined) front end library 
	function, since this sort of front end computation can't be 
	done with Promises. */
	
	SPTR(FeServer) cs;
	
	cs = CurrentServer.fluidGet();
	{	BooleanVar crutch_Flag;
		/* this->fetchLoginClubID() != NULL && CAST(FeMatchLockSmith,this->lockSmith())->scrambledPassword()->contentsEqual(cs->encrypter()->decrypt(CAST(UInt8Array,encrypted))) */
		
		crutch_Flag = this->fetchLoginClubID() != NULL;
		if(crutch_Flag) {
			crutch_Flag = CAST(FeMatchLockSmith,this->lockSmith())->scrambledPassword()->contentsEqual(cs->encrypter()->decrypt(CAST(UInt8Array,encrypted)));
		}
		if (!crutch_Flag) {
			BLAST(DoesNotMatch);
		}
	}
	WPTR(FeKeyMaster) 	returnValue;
	returnValue = this->makeKeyMaster();
	return returnValue;
}
/* private: create */


MatchLock::MatchLock (APTR(ID) loginID, APTR(FeMatchLockSmith) lockSmith) 
	: Lock(loginID, lockSmith) {
	
}



/* ************************************************************************ *
 * 
 *                    Class   MultiLock 
 *
 * ************************************************************************ */


/* create */


RPTR(MultiLock) MultiLock::make (
		APTR(ID) OR(NULL) loginID, 
		APTR(FeMultiLockSmith) lockSmith, 
		APTR(ImmuTable) OF1(Lock) locks)
{
	RETURN_CONSTRUCT(MultiLock,(loginID, lockSmith, locks));
}
/* A MultiLock allows the client to open the lock with any of a list 
of Locks. This allows a Club to have different passwords for 
different people; or, the Locks can use different kinds of native 
authentication systems such as NIS or Kerberos. */


/* create */


MultiLock::MultiLock (
		APTR(ID) loginID, 
		APTR(FeMultiLockSmith) lockSmith, 
		APTR(ImmuTable) OF1(Lock) locks) 

	: Lock(loginID, lockSmith) {
	myLocks = locks;
}
/* accessing */


RPTR(Lock) MultiLock::lock (APTR(Sequence) name){
	/* Get the named lock. You don't get any authority through a 
	MultiLock directly, you merely get a Lock from which you can 
	get authority. */
	
	return CAST(Lock,myLocks->get(name));
}


RPTR(SequenceRegion) MultiLock::lockNames (){
	/* Essential. The names identifying the locks in the list */
	
	WPTR(SequenceRegion) 	returnValue;
	returnValue = CAST(FeMultiLockSmith,this->lockSmith())->lockSmithNames();
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class   WallLock 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(WallLock) WallLock::make (APTR(ID) OR(NULL) clubID, APTR(FeLockSmith) lockSmith){
	RETURN_CONSTRUCT(WallLock,(clubID, lockSmith));
}
/* A Wall cannot be opened. Sorry, dude!!

Clubs can have WallLockSmiths for a variety of reasons. Clubs that 
represent groups of users, and to which noone should be able to login 
directly (only as a member using loginToSuperClub), will have 
WallLockSmiths. Or, if you want to make a document read-only, remove 
all the members from its editClub, make it self-reading, and put a 
WallLockSmith on it; then, noone can login to the club, either 
directly or as a member, and noone can change it.  */


/* private: create */


WallLock::WallLock (APTR(ID) loginID, APTR(FeLockSmith) lockSmith) 
	: Lock(loginID, lockSmith) {
	
}



/* ************************************************************************ *
 * 
 *                    Class DefaultSession 
 *
 * ************************************************************************ */


/* creation */


RPTR(FeSession) DefaultSession::make (){
	RETURN_CONSTRUCT(DefaultSession,());
}
/* The default session. */


/* accessing */


void DefaultSession::endSession (BooleanVar withPrejudice/* = FALSE*/){
	/* Do nothing */
	
	
}


BooleanVar DefaultSession::isConnected (){
	/* Return whether the session has sucessfully logged in. */
	
	return TRUE;
}


RPTR(UInt8Array) DefaultSession::port (){
	/* Essential. A system-specific description of the actual 
	transport medium over which the connection is being maintained. */
	
	WPTR(UInt8Array) 	returnValue;
	returnValue = UInt8Array::string("default");
	return returnValue;
}

	/* automatic 0-argument constructor */
DefaultSession::DefaultSession() {}

#ifndef NADMINX_SXX
#include "nadminx.sxx"
#endif /* NADMINX_SXX */


#ifndef NADMINP_SXX
#include "nadminp.sxx"
#endif /* NADMINP_SXX */



#endif /* NADMINX_CXX */

