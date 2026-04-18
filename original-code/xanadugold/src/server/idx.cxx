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

#ifndef IDX_CXX
#define IDX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef IDX_HXX
#include "idx.hxx"
#endif /* IDX_HXX */

#ifndef IDX_IXX
#include "idx.ixx"
#endif /* IDX_IXX */

#ifndef IDP_HXX
#include "idp.hxx"
#endif /* IDP_HXX */

#ifndef IDP_IXX
#include "idp.ixx"
#endif /* IDP_IXX */


#ifndef BIN2COMX_HXX
#include "bin2comx.hxx"
#endif /* BIN2COMX_HXX */

#ifndef COOKBKX_HXX
#include "cookbkx.hxx"
#endif /* COOKBKX_HXX */

#ifndef GRANMAPX_HXX
#include "granmapx.hxx"
#endif /* GRANMAPX_HXX */

#ifndef NKERNELX_HXX
#include "nkernelx.hxx"
#endif /* NKERNELX_HXX */

#ifndef NSCOTTYX_HXX
#include "nscottyx.hxx"
#endif /* NSCOTTYX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef PRIMVALX_HXX
#include "primvalx.hxx"
#endif /* PRIMVALX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */




/* ************************************************************************ *
 * 
 *                    Class ID 
 *
 * ************************************************************************ */


/* module private create */


RPTR(ID) ID::make (
		APTR(IDSpace) OR(NULL) space, 
		APTR(Sequence) OR(NULL) backend, 
		IntegerVar number)
{
	RETURN_CONSTRUCT(ID,(space, backend, number));
}
/* private: pseudo constructors */


RPTR(ID) ID::usingx (
		APTR(IDSpace) OR(NULL) space, 
		APTR(Sequence) OR(NULL) backend, 
		IntegerVar number)
{
	/* Special for IDStepper - checks whether it should make 
	backend be NULL */
	
	
	{	BooleanVar crutch_Flag;
		/* backend == NULL || backend->isEqual(Sequence::zero()) || backend->isEqual(FeServer::identifier()) */
		
		crutch_Flag = backend == NULL;
		if(!crutch_Flag) {
			crutch_Flag = backend->isEqual(Sequence::zero());
		}
		if(!crutch_Flag) {
			crutch_Flag = backend->isEqual(FeServer::identifier());
		}
		if (crutch_Flag) {
			WPTR(ID) 	returnValue;
			returnValue = ID::make (space, NULL, number);
			return returnValue;
		} else {
			WPTR(ID) 	returnValue;
			returnValue = ID::make (space, backend, number);
			return returnValue;
		}
	}
}
/* creation */


RPTR(ID) ID::import (APTR(PrimIntArray) data){
	/* Essential. Take some information describing an ID and 
	create the ID it was exported from. */
	
	SPTR(SpecialistRcvr) rcvr;
	SPTR(Sequence) spaceBackend;
	IntegerVar spaceNumber;
	SPTR(Sequence) iDBackend;
	IntegerVar iDNumber;
	SPTR(IDSpace) space;
	
	rcvr = Binary2XcvrMaker::make ()->makeRcvr(TransferSpecialist::make (Cookbook::make ()), XnReadStream::make (CAST(UInt8Array,data)));
	spaceBackend = ID::importSequence(rcvr);
	spaceNumber = rcvr->receiveIntegerVar();
	iDBackend = ID::importSequence(rcvr);
	iDNumber = rcvr->receiveIntegerVar();
	space = IDSpace::make (spaceBackend, spaceNumber);
	if (space->isEqual(CurrentGrandMap.fluidGet()->globalIDSpace())) {
		space = NULL;
	}
	WPTR(ID) 	returnValue;
	returnValue = ID::usingx(space, iDBackend, iDNumber);
	return returnValue;
}
/* private: export/import for friends */


void ID::exportIntegerRegion (APTR(SpecialistXmtr) xmtr, APTR(IntegerRegion) integers){
	/* Write a IntegerRegion onto a stream */
	
	xmtr->sendIntegerVar(!integers->isBoundedBelow());
	xmtr->sendIntegerVar(integers->secretTransitions()->count());
	{
		Int32 LoopFinal = integers->secretTransitions()->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				xmtr->sendIntegerVar(integers->secretTransitions()->integerAt(i));
			}
			i += 1;
		}
	}
}


void ID::exportSequence (APTR(SpecialistXmtr) xmtr, APTR(Sequence) sequence){
	/* Write a Sequence onto a stream */
	
	if (sequence->isZero()) {
		xmtr->sendIntegerVar(IntegerVarZero);
		return;
		
	}
	xmtr->sendIntegerVar(sequence->lastIndex() - sequence->firstIndex() + 1);
	xmtr->sendIntegerVar(sequence->firstIndex());
	{
		IntegerVar LoopFinal = sequence->lastIndex();
		IntegerVar i = sequence->firstIndex();
		for (;;) {
			if (i > LoopFinal){
				break;
			}
			{
				xmtr->sendIntegerVar(sequence->integerAt(i));
			}
			i += 1;
		}
	}
}


RPTR(IntegerRegion) ID::importIntegerRegion (APTR(SpecialistRcvr) rcvr){
	/* Read a IntegerRegion from a stream */
	
	BooleanVar startsInside;
	Int32 n;
	SPTR(IntegerVarArray) transitions;
	
	startsInside = rcvr->receiveIntegerVar().asLong();
	n = rcvr->receiveIntegerVar().asLong();
	transitions = IntegerVarArray::zeros(n);
	{
		Int32 LoopFinal = n;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				transitions->storeInteger(i, rcvr->receiveIntegerVar());
			}
			i += 1;
		}
	}
	WPTR(IntegerRegion) 	returnValue;
	returnValue = IntegerRegion::usingx(startsInside, n, transitions);
	return returnValue;
}


RPTR(Sequence) ID::importSequence (APTR(SpecialistRcvr) rcvr){
	/* Read a Sequence from a stream */
	
	IntegerVar count;
	IntegerVar shift;
	SPTR(IntegerVarArray) numbers;
	
	count = rcvr->receiveIntegerVar();
	if (count == IntegerVarZero) {
		WPTR(Sequence) 	returnValue;
		returnValue = Sequence::zero();
		return returnValue;
	}
	numbers = IntegerVarArray::zeros(count.asLong());
	shift = rcvr->receiveIntegerVar();
	{
		Int32 LoopFinal = count.asLong();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				numbers->storeInteger(i, rcvr->receiveIntegerVar());
			}
			i += 1;
		}
	}
	WPTR(Sequence) 	returnValue;
	returnValue = SequenceSpace::make ()->position(numbers, shift);
	return returnValue;
}
/* Implementation note:

An ID exists within a particular IDSpace, and is generated by a 
particular Server. It holds onto the space and the Server which 
created it, along with a number identifying the ID uniquely. If 
mySpace is NULL, then the ID is in the global IDSpace. If myBackend 
is NULL, then this ID was generated by the current Server (unless 
myNumber is negative, in which case it is considered to have been 
generated by the "global" backend). If myBackend is non-NULL, then 
myNumber must be non-negative. */


/* accessing */


RPTR(XnRegion) ID::asRegion (){
	if (myBackend == NULL) {
		WPTR(XnRegion) 	returnValue;
		returnValue = IDRegion::make (mySpace, IntegerRegion::make (myNumber), NULL, FALSE);
		return returnValue;
	} else {
		SPTR(MuTable) OF2(Sequence,IntegerRegion) others;
		
		others = MuTable::make (SequenceSpace::make ());
		others->introduce(myBackend, IntegerRegion::make (myNumber));
		WPTR(XnRegion) 	returnValue;
		returnValue = IDRegion::make (mySpace, IntegerRegion::make (), others->asImmuTable(), FALSE);
		return returnValue;
	}
}


RPTR(CoordinateSpace) ID::coordinateSpace (){
	if (mySpace == NULL) {
		WPTR(CoordinateSpace) 	returnValue;
		returnValue = IDSpace::global();
		return returnValue;
	}
	return (IDSpace*) mySpace;
}


RPTR(UInt8Array) ID::export (){
	/* Essential. Export this iD in a form which can be handed to 
	Server::importID on any Server to generate the same ID */
	
	SPTR(SpecialistXmtr) xmtr;
	SPTR(WriteVariableArrayStream) result;
	
	result = WriteVariableArrayStream::make (200);
	xmtr = Binary2XcvrMaker::make ()->makeXmtr(TransferSpecialist::make (Cookbook::make ()), result);
	ID::exportSequence(xmtr, CAST(IDSpace,this->coordinateSpace())->backend());
	xmtr->sendIntegerVar(CAST(IDSpace,this->coordinateSpace())->spaceNumber());
	ID::exportSequence(xmtr, this->backend());
	xmtr->sendIntegerVar(this->number());
	WPTR(UInt8Array) 	returnValue;
	returnValue = result->array();
	return returnValue;
}
/* comparing */


UInt32 ID::actualHashForEqual (){
	UInt32 result;
	
	result = this->getCategory()->hashForEqual();
	if (mySpace != NULL) {
		result ^= mySpace->hashForEqual();
	}
	if (myBackend != NULL) {
		result ^= myBackend->hashForEqual();
	}
	return result ^ myNumber.hashForEqual();
}


BooleanVar ID::isEqual (APTR(Heaper) heaper){
	BEGIN_CHOOSE(heaper) {
		BEGIN_KIND(ID,other) {
			if (mySpace == NULL) {
				if (!(other->fetchSpace() == NULL)) {
					return FALSE;
				}
			} else {
				{	BooleanVar crutch_Flag;
					/* other->fetchSpace() != NULL && mySpace->isEqual(other->fetchSpace()) */
					
					crutch_Flag = other->fetchSpace() != NULL;
					if(crutch_Flag) {
						crutch_Flag = mySpace->isEqual(other->fetchSpace());
					}
					if (!crutch_Flag) {
						return FALSE;
					}
				}
			}
			if (myBackend == NULL) {
				if (!(other->fetchBackend() == NULL)) {
					return FALSE;
				}
			} else {
				{	BooleanVar crutch_Flag;
					/* other->fetchBackend() != NULL && myBackend->isEqual(other->fetchBackend()) */
					
					crutch_Flag = other->fetchBackend() != NULL;
					if(crutch_Flag) {
						crutch_Flag = myBackend->isEqual(other->fetchBackend());
					}
					if (!crutch_Flag) {
						return FALSE;
					}
				}
			}
			return myNumber == other->number();
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}
/* protected: create */


ID::ID (
		APTR(IDSpace) OR(NULL) space, 
		APTR(Sequence) OR(NULL) backend, 
		IntegerVar number) 
{
	mySpace = space;
	myBackend = backend;
	myNumber = number;
}
/* printing */


void ID::printOn (ostream& oo){
	oo << CAST(IDSpace,this->coordinateSpace())->identifier() << ":" << this->identifier();
}
/* private: */


RPTR(Sequence) ID::backend (){
	/* Essential. A Sequence identifying the server on which this 
	was created */
	
	if (myBackend == NULL) {
		if (myNumber < IntegerVarZero) {
			WPTR(Sequence) 	returnValue;
			returnValue = Sequence::zero();
			return returnValue;
		} else {
			WPTR(Sequence) 	returnValue;
			returnValue = FeServer::identifier();
			return returnValue;
		}
	} else {
		return (Sequence*) myBackend;
	}
}


RPTR(Sequence) OR(NULL) ID::fetchBackend (){
	return (Sequence*) myBackend;
}


RPTR(IDSpace) OR(NULL) ID::fetchSpace (){
	return (IDSpace*) mySpace;
}


IntegerVar ID::number (){
	/* Essential. The number identifying this ID from all others 
	generated by the same Server in the same IDSpace. */
	
	return myNumber;
}
/* obsolete: */


RPTR(Sequence) ID::identifier (){
	/* A sequence of numbers which uniquely identify this ID 
	within its space */
	
	/* Ravi -- Thing to do !!!! */
	
	/* get rid of this, and clients */
	WPTR(Sequence) 	returnValue;
	returnValue = this->backend()->withLast(myNumber);
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class IDDsp 
 *
 * ************************************************************************ */



/* Initializers for IDDsp */

/* Initializer inherited from IdentityDsp */

IdentityDsp * IDDsp::theDsp = NULL;


/* Initializer inherited from IdentityDsp */


BEGIN_INIT_TIME(IDDsp,initTimeInherited) {
	CONSTRUCT_ON(PERSISTENT,IDDsp::theDsp,IDDsp,());
} END_INIT_TIME(IDDsp,initTimeInherited);



/* Initializers for IDDsp */

/* Initializer inherited from IdentityDsp */




/* Initializer inherited from IdentityDsp */



/* rcvr pseudo constructors */


RPTR(Heaper) IDDsp::make (APTR(Rcvr) rcvr){
	CAST(SpecialistRcvr,rcvr)->registerIbid(IDDsp::theDsp);
	WPTR(Heaper) 	returnValue;
	returnValue = IDDsp::theDsp;
	return returnValue;
}
/* pseudo constructors */


RPTR(IDDsp) IDDsp::make (APTR(IDSpace) space){
	RETURN_CONSTRUCT(IDDsp,(space, tcsj));
}
/* There are no non-trivial Dsps on IDs. */


/* accessing */


RPTR(CoordinateSpace) IDDsp::coordinateSpace (){
	return (IDSpace*) mySpace;
}
/* creation */


IDDsp::IDDsp () {
	
}


IDDsp::IDDsp (APTR(IDSpace) space, TCSJ) {
	mySpace = space;
}



/* ************************************************************************ *
 * 
 *                    Class IDRegion 
 *
 * ************************************************************************ */



/* Initializers for IDRegion */

GPTR(IntegerRegion) IDRegion::TheLocalNumbers = NULL;
GPTR(IntegerRegion) IDRegion::TheGlobalNumbers = NULL;



BEGIN_INIT_TIME(IDRegion,initTimeNonInherited) {
	REQUIRES (PrimSpec);
	REQUIRES (IntegerRegion);
	IDRegion::TheLocalNumbers = IntegerRegion::after(IntegerVarZero);
	IDRegion::TheGlobalNumbers = IntegerRegion::before(IntegerVarZero);
} END_INIT_TIME(IDRegion,initTimeNonInherited);



/* Initializers for IDRegion */






/* private: */


RPTR(IDRegion) IDRegion::usingx (
		APTR(IDSpace) OR(NULL) space, 
		APTR(IntegerRegion) localIDs, 
		APTR(ImmuTable) OF2(Sequence,IntegerRegion) OR(NULL) importedIDs, 
		BooleanVar includesRest)
{
	/* For IDSpace constructor only. Space had better be NULL if 
	it's the global space */
	
	RETURN_CONSTRUCT(IDRegion,(space, localIDs, importedIDs, includesRest));
}
/* creation */


RPTR(IDRegion) IDRegion::import (APTR(PrimIntArray) data){
	/* Essential. Take some information describing an IDRegion 
	and create the IDRegion it was exported from. */
	
	SPTR(SpecialistRcvr) rcvr;
	SPTR(Sequence) spaceBackend;
	IntegerVar spaceNumber;
	SPTR(IDSpace) space;
	SPTR(IntegerRegion) localIDs;
	IntegerVar n;
	SPTR(ImmuTable) OR(NULL) imported;
	BooleanVar includesRest;
	
	rcvr = Binary2XcvrMaker::make ()->makeRcvr(TransferSpecialist::make (Cookbook::make ()), XnReadStream::make (CAST(UInt8Array,data)));
	spaceBackend = ID::importSequence(rcvr);
	spaceNumber = rcvr->receiveIntegerVar();
	space = IDSpace::make (spaceBackend, spaceNumber);
	if (space->isEqual(CurrentGrandMap.fluidGet()->globalIDSpace())) {
		space = NULL;
	}
	localIDs = ID::importIntegerRegion(rcvr);
	n = rcvr->receiveIntegerVar();
	if (n == IntegerVarZero) {
		imported = NULL;
	} else {
		SPTR(MuTable) table;
		
		table = MuTable::make (SequenceSpace::make ());
		{
			IntegerVar LoopFinal = n;
			IntegerVar i = 1;
			for (;;) {
				if (i > LoopFinal){
					break;
				}
				{
					SPTR(Sequence) key;
					SPTR(IntegerRegion) value;
					
					key = ID::importSequence(rcvr);
					value = ID::importIntegerRegion(rcvr);
					table->introduce(key, value);
				}
				i += 1;
			}
		}
		imported = table->asImmuTable();
	}
	includesRest = rcvr->receiveIntegerVar().asLong();
	WPTR(IDRegion) 	returnValue;
	returnValue = IDRegion::usingx(space, localIDs, imported, includesRest);
	return returnValue;
}


RPTR(IDRegion) IDRegion::make (
		APTR(IDSpace) OR(NULL) space, 
		APTR(IntegerRegion) localIDs, 
		APTR(ImmuTable) OF2(Sequence,IntegerRegion) OR(NULL) importedIDs, 
		BooleanVar includesRest)
{
	RETURN_CONSTRUCT(IDRegion,(space, localIDs, importedIDs, includesRest));
}
/* If mySpace is NULL, then it is assumed to be global IDSpace.
The non-negative part of myLocalIDs contains the number portion of 
all IDs in the region that were generated by the current backend. The 
negative part contains all IDs which were generated by the "global" backend.
If myImportedIDs is NULL, it is considered to be empty. If it is 
non-NULL, it must be non-empty. It contains the numbers of all IDs in 
this region which were generated by other backends. If an entry in 
the table could be omitted without effect, then it should be omitted. 
(i.e. if myIncludesRest and the region is full, or myIncludesRest not 
and the region is empty, then the entry should be omitted).
If myIncludesRest is true, then the region includes, in addition to 
those IDs explictly listed in myLocalIDs and myImportedIDs, all ID 
generated by all other backends. */


/* accessing */


RPTR(XnRegion) IDRegion::asSimpleRegion (){
	/* Ravi -- Thing to do !!!! */
	
	/* make this more efficient and return fullRegion less often */
	if (this->isSimple()) {
		return this;
	}
	if (myImportedIDs != NULL) {
		WPTR(XnRegion) 	returnValue;
		returnValue = this->coordinateSpace()->fullRegion();
		return returnValue;
	}
	WPTR(XnRegion) 	returnValue;
	returnValue = IDRegion::make (mySpace, CAST(IntegerRegion,myLocalIDs->asSimpleRegion()), NULL, myIncludesRest);
	return returnValue;
}


RPTR(CoordinateSpace) IDRegion::coordinateSpace (){
	if (mySpace == NULL) {
		WPTR(CoordinateSpace) 	returnValue;
		returnValue = IDSpace::global();
		return returnValue;
	}
	return (IDSpace*) mySpace;
}


RPTR(UInt8Array) IDRegion::export (){
	/* Essential. Export the IDRegion in a form that can be used 
	to recreate it with IDRegion::import. */
	
	SPTR(SpecialistXmtr) xmtr;
	SPTR(WriteVariableArrayStream) result;
	
	result = WriteVariableArrayStream::make (500);
	xmtr = Binary2XcvrMaker::make ()->makeXmtr(TransferSpecialist::make (Cookbook::make ()), result);
	ID::exportSequence(xmtr, CAST(IDSpace,this->coordinateSpace())->backend());
	ID::exportIntegerRegion(xmtr, myLocalIDs);
	if (myImportedIDs == NULL) {
		xmtr->sendIntegerVar(IntegerVarZero);
	} else {
		xmtr->sendIntegerVar(myImportedIDs->count());
		BEGIN_FOR_POSITIONS(Sequence,key,IntegerRegion,value,(myImportedIDs->stepper())) {
			ID::exportSequence(xmtr, key);
			ID::exportIntegerRegion(xmtr, value);
		} END_FOR_POSITIONS;
	}
	xmtr->sendIntegerVar(myIncludesRest);
	WPTR(UInt8Array) 	returnValue;
	returnValue = result->array();
	return returnValue;
}


RPTR(Position) IDRegion::theOne (){
	if (!myIncludesRest) {
		if (myLocalIDs->isEmpty()) {
			if (myImportedIDs != NULL) {
				WPTR(Position) 	returnValue;
				returnValue = ID::make (mySpace, CAST(Sequence,myImportedIDs->domain()->theOne()), CAST(IntegerPos,CAST(IntegerRegion,myImportedIDs->theOne())->theOne())->asIntegerVar());
				return returnValue;
			}
		} else {
			if (myImportedIDs == NULL) {
				WPTR(Position) 	returnValue;
				returnValue = ID::make (mySpace, NULL, CAST(IntegerPos,myLocalIDs->theOne())->asIntegerVar());
				return returnValue;
			}
		}
	}
	BLAST(NotOneElement);
	return NULL;
}
/* testing */


UInt32 IDRegion::actualHashForEqual (){
	UInt32 result;
	
	result = this->getCategory()->hashForEqual() ^ myLocalIDs->hashForEqual();
	if (mySpace != NULL) {
		result ^= mySpace->hashForEqual();
	}
	if (myImportedIDs != NULL) {
		result ^= myImportedIDs->hashForEqual();
	}
	if (myIncludesRest) {
		result ^= 65535;
	}
	return result;
}


BooleanVar IDRegion::hasMember (APTR(Position) position){
	BEGIN_CHOOSE(position) {
		BEGIN_KIND(ID,iD) {
			SPTR(Sequence) OR(NULL) be;
			SPTR(IntegerRegion) OR(NULL) region;
			
			be = iD->fetchBackend();
			if (be == NULL) {
				return myLocalIDs->hasIntMember(iD->number());
			} else {
				if (myImportedIDs != NULL) {
					region = CAST(IntegerRegion,myImportedIDs->fetch(be));
				} else {
					region = NULL;
				}
				if (region == NULL) {
					return myIncludesRest;
				} else {
					return region->hasIntMember(iD->number());
				}
			}
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


BooleanVar IDRegion::isEmpty (){
	{	BooleanVar crutch_Flag;
		/* !myIncludesRest && myImportedIDs == NULL && myLocalIDs->isEmpty() */
		
		crutch_Flag = !myIncludesRest;
		if(crutch_Flag) {
			crutch_Flag = myImportedIDs == NULL;
			if(crutch_Flag) {
				crutch_Flag = myLocalIDs->isEmpty();
			}
		}
		return crutch_Flag;
	}
}


BooleanVar IDRegion::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(IDRegion,iDs) {
			if (mySpace == NULL) {
				if (!(iDs->fetchSpace() == NULL)) {
					return FALSE;
				}
			} else {
				{	BooleanVar crutch_Flag;
					/* iDs->fetchSpace() != NULL && iDs->fetchSpace()->isEqual(mySpace) */
					
					crutch_Flag = iDs->fetchSpace() != NULL;
					if(crutch_Flag) {
						crutch_Flag = iDs->fetchSpace()->isEqual(mySpace);
					}
					if (!crutch_Flag) {
						return FALSE;
					}
				}
			}
			{	BooleanVar crutch_Flag;
				/* myIncludesRest == iDs->includesRest() && myLocalIDs->isEqual(iDs->localIDs()) */
				
				crutch_Flag = myIncludesRest == iDs->includesRest();
				if(crutch_Flag) {
					crutch_Flag = myLocalIDs->isEqual(iDs->localIDs());
				}
				if (crutch_Flag) {
					if (myImportedIDs == NULL) {
						return iDs->fetchImportedIDs() == NULL;
					} else {
						{	BooleanVar crutch_Flag;
							/* iDs->fetchImportedIDs() != NULL && iDs->fetchImportedIDs()->isEqual(myImportedIDs) */
							
							crutch_Flag = iDs->fetchImportedIDs() != NULL;
							if(crutch_Flag) {
								crutch_Flag = iDs->fetchImportedIDs()->isEqual(myImportedIDs);
							}
							return crutch_Flag;
						}
					}
				}
			}
			return FALSE;
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


BooleanVar IDRegion::isFinite (){
	{	BooleanVar crutch_Flag;
		/* !myIncludesRest && myLocalIDs->isFinite() */
		
		crutch_Flag = !myIncludesRest;
		if(crutch_Flag) {
			crutch_Flag = myLocalIDs->isFinite();
		}
		if (!crutch_Flag) {
			return FALSE;
		}
	}
	if (myImportedIDs != NULL) {
		BEGIN_FOR_EACH(IntegerRegion,numbers,(myImportedIDs->stepper())) {
			if (!numbers->isFinite()) {
				return FALSE;
			}
		} END_FOR_EACH;
	}
	return TRUE;
}


BooleanVar IDRegion::isFull (){
	{	BooleanVar crutch_Flag;
		/* myImportedIDs == NULL && myIncludesRest && myLocalIDs->isFull() */
		
		crutch_Flag = myImportedIDs == NULL;
		if(crutch_Flag) {
			crutch_Flag = myIncludesRest;
			if(crutch_Flag) {
				crutch_Flag = myLocalIDs->isFull();
			}
		}
		return crutch_Flag;
	}
}


BooleanVar IDRegion::isSimple (){
	if (myImportedIDs == NULL) {
		return myLocalIDs->isSimple();
	}
	if (myIncludesRest) {
		if (!myLocalIDs->isSimple()) {
			return FALSE;
		}
		BEGIN_FOR_EACH(IntegerRegion,iDs,(myImportedIDs->stepper())) {
			if (!iDs->isSimple()) {
				return FALSE;
			}
		} END_FOR_EACH;
		return TRUE;
	} else {
		{	BooleanVar crutch_Flag;
			/* myLocalIDs->isEmpty() && myImportedIDs->count() == 1 && CAST(IntegerRegion,myImportedIDs->theOne())->isSimple() */
			
			crutch_Flag = myLocalIDs->isEmpty();
			if(crutch_Flag) {
				crutch_Flag = myImportedIDs->count() == 1;
				if(crutch_Flag) {
					crutch_Flag = CAST(IntegerRegion,myImportedIDs->theOne())->isSimple();
				}
			}
			return crutch_Flag;
		}
	}
}


BooleanVar IDRegion::isSubsetOf (APTR(XnRegion) region){
	BEGIN_CHOOSE(region) {
		BEGIN_KIND(IDRegion,other) {
			if (!myLocalIDs->isSubsetOf(other->localIDs())) {
				return FALSE;
			}
			if (myImportedIDs == NULL) {
				{	BooleanVar crutch_Flag;
					/* !myIncludesRest || other->includesRest() && other->fetchImportedIDs() == NULL */
					
					crutch_Flag = !myIncludesRest;
					if(!crutch_Flag) {
						crutch_Flag = other->includesRest();
						if(crutch_Flag) {
							crutch_Flag = other->fetchImportedIDs() == NULL;
						}
					}
					return crutch_Flag;
				}
			}
			if (other->fetchImportedIDs() == NULL) {
				/* since we know I have imported IDs */
				return other->includesRest();
			}
			if (myIncludesRest) {
				{	BooleanVar crutch_Flag;
					/* other->includesRest() && other->fetchImportedIDs()->domain()->isSubsetOf(myImportedIDs->domain()) */
					
					crutch_Flag = other->includesRest();
					if(crutch_Flag) {
						crutch_Flag = other->fetchImportedIDs()->domain()->isSubsetOf(myImportedIDs->domain());
					}
					if (!crutch_Flag) {
						return FALSE;
					}
				}
			}
			BEGIN_FOR_POSITIONS(Sequence,backend,IntegerRegion,iDs,(myImportedIDs->stepper())) {
				SPTR(IntegerRegion) OR(NULL) otherIDs;
				
				otherIDs = CAST(IntegerRegion,other->getImportedIDs()->fetch(backend));
				if (otherIDs == NULL) {
					{	BooleanVar crutch_Flag;
						/* other->includesRest() || iDs->isEmpty() */
						
						crutch_Flag = other->includesRest();
						if(!crutch_Flag) {
							crutch_Flag = iDs->isEmpty();
						}
						if (!crutch_Flag) {
							return FALSE;
						}
					}
				} else {
					if (!iDs->isSubsetOf(otherIDs)) {
						return FALSE;
					}
				}
			} END_FOR_POSITIONS;
		} END_KIND;
	} END_CHOOSE;
	return TRUE;
}
/* protected: enumerating */


RPTR(Stepper) OF1(Position) IDRegion::actualStepper (APTR(OrderSpec) order/* = NULL*/){
	/* Known bug !!!! */
	
	/* might be enumerable in other cases */
	if (!this->isFinite()) {
		BLAST(NotEnumerable);
	}
	RETURN_CONSTRUCT(IDStepper,(this, tcsj));
}
/* enumerating */


IntegerVar IDRegion::count (){
	IntegerVar result;
	
	if (myIncludesRest) {
		BLAST(MustBeFinite);
	}
	result = myLocalIDs->count();
	if (myImportedIDs != NULL) {
		BEGIN_FOR_EACH(IntegerRegion,iDs,(myImportedIDs->stepper())) {
			result += iDs->count();
		} END_FOR_EACH;
	}
	return result;
}


RPTR(ScruSet) OF1(XnRegion) IDRegion::distinctions (){
	SPTR(SetAccumulator) result;
	SPTR(MuTable) OF1(Sequence) table;
	
	/* Ravi -- Thing to do !!!! */
	
	/* consolidate duplicated code */
	result = SetAccumulator::make ();
	if (myImportedIDs == NULL) {
		BEGIN_FOR_EACH(IntegerRegion,local,(myLocalIDs->distinctions()->stepper())) {
			SPTR(IDRegion) region;
			
			region = 
					IDRegion::make (mySpace, local, NULL, myIncludesRest);
			result->step(region);
		} END_FOR_EACH;
	} else {
		if (myIncludesRest) {
			BEGIN_FOR_EACH(IntegerRegion,local,(myLocalIDs->distinctions()->stepper())) {
				SPTR(IDRegion) region;
				
				region = 
						IDRegion::make (mySpace, local, NULL, TRUE);
				result->step(region);
			} END_FOR_EACH;
			BEGIN_FOR_POSITIONS(Sequence,backend,IntegerRegion,iDs,(myImportedIDs->stepper())) {
				BEGIN_FOR_EACH(IntegerRegion,import,(iDs->distinctions()->stepper())) {
					SPTR(IDRegion) region;
					
					table = MuTable::make (SequenceSpace::make ());
					table->store(backend, import);
					region = 
							IDRegion::make (mySpace, IntegerRegion::allIntegers(), table->asImmuTable(), TRUE);
					result->step(region);
				} END_FOR_EACH;
			} END_FOR_POSITIONS;
		} else {
			SPTR(Sequence) backend;
			
			{	BooleanVar crutch_Flag;
				/* myLocalIDs->isEmpty() && myImportedIDs->count() == 1 */
				
				crutch_Flag = myLocalIDs->isEmpty();
				if(crutch_Flag) {
					crutch_Flag = myImportedIDs->count() == 1;
				}
				if (!crutch_Flag) {
					BLAST(MustBeSimple);
				}
			}
			backend = CAST(Sequence,myImportedIDs->domain()->theOne());
			BEGIN_FOR_EACH(Sequence,import,(CAST(IntegerRegion,myImportedIDs->theOne())->distinctions()->stepper())) {
				SPTR(IDRegion) region;
				
				table = MuTable::make (SequenceSpace::make ());
				table->store(backend, import);
				region = 
						IDRegion::make (mySpace, myLocalIDs, table->asImmuTable(), FALSE);
				result->step(region);
			} END_FOR_EACH;
		}
	}
	return CAST(ScruSet,result->value());
}


RPTR(Stepper) IDRegion::simpleRegions (APTR(OrderSpec) order/* = NULL*/){
	RETURN_CONSTRUCT(IDSimpleStepper,(this, tcsj));
}
/* private: */


RPTR(SequenceRegion) IDRegion::backends (){
	/* All backends which have generated IDs in this Region */
	
	SPTR(XnRegion) result;
	
	if (myIncludesRest) {
		result = SequenceSpace::make ()->fullRegion();
		if (!myLocalIDs->intersects(IDRegion::TheGlobalNumbers)) {
			result = result->without(Sequence::zero());
		}
		if (!myLocalIDs->intersects(IDRegion::TheLocalNumbers)) {
			result = result->without(FeServer::identifier());
		}
		if (myImportedIDs != NULL) {
			BEGIN_FOR_POSITIONS(Sequence,backend,IntegerRegion,iDs,(myImportedIDs->stepper())) {
				if (iDs->isEmpty()) {
					result = result->without(backend);
				}
			} END_FOR_POSITIONS;
		}
		return CAST(SequenceRegion,result);
	} else {
		result = SequenceSpace::make ()->emptyRegion();
		if (myLocalIDs->intersects(IDRegion::TheGlobalNumbers)) {
			result = result->with(Sequence::zero());
		}
		if (myLocalIDs->intersects(IDRegion::TheLocalNumbers)) {
			result = result->with(FeServer::identifier());
		}
		if (myImportedIDs != NULL) {
			result = result->unionWith(myImportedIDs->domain());
		}
		return CAST(SequenceRegion,result);
	}
}


RPTR(XnRegion) OF1(Sequence) IDRegion::explicitBackends (){
	/* All backends which are non-empty and are explicitly 
	listed. For IDSimpleStepper */
	
	SPTR(XnRegion) result;
	
	result = SequenceSpace::make ()->emptyRegion();
	if (myLocalIDs->intersects(IDRegion::TheGlobalNumbers)) {
		result = result->with(Sequence::zero());
	}
	if (myLocalIDs->intersects(IDRegion::TheLocalNumbers)) {
		result = result->with(FeServer::identifier());
	}
	if (myImportedIDs != NULL) {
		if (myIncludesRest) {
			BEGIN_FOR_POSITIONS(Sequence,backend,IntegerRegion,iDs,(myImportedIDs->stepper())) {
				if (!iDs->isEmpty()) {
					result = result->with(backend);
				}
			} END_FOR_POSITIONS;
		} else {
			result = result->unionWith(myImportedIDs->domain());
		}
	}
	WPTR(XnRegion) OF1(Sequence) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(ImmuTable) OF2(Sequence,IntegerRegion) OR(NULL) IDRegion::fetchImportedIDs (){
	return (ImmuTable*) myImportedIDs;
}


RPTR(IDRegion) IDRegion::fetchInexplicit (){
	/* The region which covers material not in the 
	explicitBackends list, or NULL if there is none. */
	
	SPTR(MuTable) OR(NULL) result;
	SPTR(ImmuTable) OR(NULL) actualResult;
	
	if (!myIncludesRest) {
		return NULL;
	}
	if (myImportedIDs == NULL) {
		result = NULL;
	} else {
		result = MuTable::make (SequenceSpace::make ());
		BEGIN_FOR_POSITIONS(Sequence,backend,IntegerRegion,iDs,(myImportedIDs->stepper())) {
			result->introduce(backend, IntegerRegion::make ());
		} END_FOR_POSITIONS;
	}
	if (result != NULL) {
		actualResult = result->asImmuTable();
	} else {
		actualResult = NULL;
	}
	WPTR(IDRegion) 	returnValue;
	returnValue = IDRegion::make (mySpace, IntegerRegion::make (), actualResult, TRUE);
	return returnValue;
}


RPTR(IDSpace) IDRegion::fetchSpace (){
	return (IDSpace*) mySpace;
}


RPTR(ImmuTable) OF2(Sequence,IntegerRegion) OR(NULL) IDRegion::getImportedIDs (){
	if (myImportedIDs == NULL) {
		BLAST(InvalidRequest);
	}
	return (ImmuTable*) myImportedIDs;
}


RPTR(XnRegion) OF1(IntegerPos) IDRegion::iDNumbersFrom (APTR(Sequence) backend){
	/* The numbers of all IDs in this region that were generated 
	by the given backend */
	
	SPTR(XnRegion) result;
	
	if (backend->isEqual(Sequence::zero())) {
		WPTR(XnRegion) OF1(IntegerPos) 	returnValue;
		returnValue = myLocalIDs->intersect(IDRegion::TheGlobalNumbers);
		return returnValue;
	}
	if (backend->isEqual(FeServer::identifier())) {
		WPTR(XnRegion) OF1(IntegerPos) 	returnValue;
		returnValue = myLocalIDs->intersect(IDRegion::TheLocalNumbers);
		return returnValue;
	}
	if (myImportedIDs != NULL) {
		result = CAST(XnRegion,myImportedIDs->fetch(backend));
		if (result != NULL) {
			WPTR(XnRegion) OF1(IntegerPos) 	returnValue;
			returnValue = result;
			return returnValue;
		}
	}
	if (myIncludesRest) {
		WPTR(XnRegion) OF1(IntegerPos) 	returnValue;
		returnValue = IDRegion::TheLocalNumbers;
		return returnValue;
	} else {
		WPTR(XnRegion) OF1(IntegerPos) 	returnValue;
		returnValue = IntegerSpace::make ()->emptyRegion();
		return returnValue;
	}
}


BooleanVar IDRegion::includesRest (){
	return myIncludesRest;
}


RPTR(IntegerRegion) IDRegion::localIDs (){
	return (IntegerRegion*) myLocalIDs;
}
/* operations */


RPTR(XnRegion) IDRegion::complement (){
	SPTR(MuTable) OF2(Sequence,IntegerRegion) result;
	SPTR(ImmuTable) resTable;
	
	if (myImportedIDs == NULL) {
		result = NULL;
	} else {
		result = MuTable::make (SequenceSpace::make ());
		BEGIN_FOR_POSITIONS(Sequence,backend,IntegerRegion,iDs,(myImportedIDs->stepper())) {
			result->store(backend, IDRegion::TheLocalNumbers->minus(iDs));
		} END_FOR_POSITIONS;
	}
	if (result == NULL) {
		resTable = NULL;
	} else {
		resTable = result->asImmuTable();
	}
	WPTR(XnRegion) 	returnValue;
	returnValue = IDRegion::make (mySpace, CAST(IntegerRegion,myLocalIDs->complement()), resTable, !myIncludesRest);
	return returnValue;
}


RPTR(XnRegion) IDRegion::intersect (APTR(XnRegion) region){
	SPTR(ImmuTable) resTable;
	
	BEGIN_CHOOSE(region) {
		BEGIN_KIND(IDRegion,other) {
			SPTR(MuTable) result;
			
			if (myImportedIDs == NULL) {
				{	BooleanVar crutch_Flag;
					/* myIncludesRest && other->fetchImportedIDs() != NULL */
					
					crutch_Flag = myIncludesRest;
					if(crutch_Flag) {
						crutch_Flag = other->fetchImportedIDs() != NULL;
					}
					if (crutch_Flag) {
						result = other->fetchImportedIDs()->asMuTable();
					} else {
						result = NULL;
					}
				}
			} else {
				if (other->fetchImportedIDs() == NULL) {
					if (other->includesRest()) {
						result = myImportedIDs->asMuTable();
					} else {
						result = NULL;
					}
				} else {
					result = MuTable::make (SequenceSpace::make ());
					BEGIN_FOR_POSITIONS(Sequence,backend,IntegerRegion,iDs,(myImportedIDs->stepper())) {
						SPTR(IntegerRegion) otherIDs;
						
						otherIDs = CAST(IntegerRegion,other->getImportedIDs()->fetch(backend));
						if (otherIDs != NULL) {
							result->store(backend, iDs->intersect(otherIDs));
						} else {
							if (other->includesRest()) {
								result->store(backend, iDs);
							}
						}
					} END_FOR_POSITIONS;
					if (myIncludesRest) {
						BEGIN_FOR_POSITIONS(Sequence,backend,IntegerRegion,otherIDs,(other->getImportedIDs()->stepper())) {
							SPTR(IntegerRegion) iDs;
							
							iDs = CAST(IntegerRegion,myImportedIDs->fetch(backend));
							if (iDs == NULL) {
								result->store(backend, otherIDs);
							}
						} END_FOR_POSITIONS;
					}
				}
			}
			if (result != NULL) {
				BEGIN_FOR_POSITIONS(Sequence,backend,IntegerRegion,iDs,(result->stepper())) {
					BooleanVar f;
					
					{	BooleanVar crutch_Flag;
						/* myIncludesRest && other->includesRest() */
						
						crutch_Flag = myIncludesRest;
						if(crutch_Flag) {
							crutch_Flag = other->includesRest();
						}
						if (crutch_Flag) {
							f = iDs->isEqual(IDRegion::TheLocalNumbers);
						} else {
							f = iDs->isEmpty();
						}
					}
					if (f) {
						result->wipe(backend);
					}
				} END_FOR_POSITIONS;
				if (result->isEmpty()) {
					result = NULL;
				}
			}
			if (result == NULL) {
				resTable = NULL;
			} else {
				resTable = result->asImmuTable();
			}
			WPTR(XnRegion) 	returnValue;
			returnValue = IDRegion::make (mySpace, CAST(IntegerRegion,myLocalIDs->intersect(other->localIDs())), resTable, myIncludesRest && other->includesRest());
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return NULL;
}


RPTR(XnRegion) IDRegion::simpleUnion (APTR(XnRegion) region){
	BEGIN_CHOOSE(region) {
		BEGIN_KIND(IDRegion,other) {
			/* Ravi -- Thing to do !!!! */
			
			/* return fullRegion less often */
			{	BooleanVar crutch_Flag;
				/* myImportedIDs != NULL || other->fetchImportedIDs() != NULL */
				
				crutch_Flag = myImportedIDs != NULL;
				if(!crutch_Flag) {
					crutch_Flag = other->fetchImportedIDs() != NULL;
				}
				if (crutch_Flag) {
					WPTR(XnRegion) 	returnValue;
					returnValue = this->coordinateSpace()->fullRegion();
					return returnValue;
				}
			}
			WPTR(XnRegion) 	returnValue;
			returnValue = IDRegion::make (mySpace, CAST(IntegerRegion,myLocalIDs->simpleUnion(other->localIDs())), NULL, myIncludesRest);
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return NULL;
}


RPTR(XnRegion) IDRegion::unionWith (APTR(XnRegion) region){
	SPTR(ImmuTable) resTable;
	
	BEGIN_CHOOSE(region) {
		BEGIN_KIND(IDRegion,other) {
			SPTR(MuTable) result;
			
			if (myImportedIDs == NULL) {
				{	BooleanVar crutch_Flag;
					/* myIncludesRest || other->fetchImportedIDs() == NULL */
					
					crutch_Flag = myIncludesRest;
					if(!crutch_Flag) {
						crutch_Flag = other->fetchImportedIDs() == NULL;
					}
					if (crutch_Flag) {
						result = NULL;
					} else {
						result = other->fetchImportedIDs()->asMuTable();
					}
				}
			} else {
				if (other->fetchImportedIDs() == NULL) {
					if (other->includesRest()) {
						result = NULL;
					} else {
						result = myImportedIDs->asMuTable();
					}
				} else {
					result = MuTable::make (SequenceSpace::make ());
					BEGIN_FOR_POSITIONS(Sequence,backend,IntegerRegion,iDs,(myImportedIDs->stepper())) {
						SPTR(IntegerRegion) otherIDs;
						
						otherIDs = CAST(IntegerRegion,other->getImportedIDs()->fetch(backend));
						if (otherIDs != NULL) {
							result->store(backend, iDs->unionWith(otherIDs));
						} else {
							if (!other->includesRest()) {
								result->store(backend, iDs);
							}
						}
					} END_FOR_POSITIONS;
					if (!myIncludesRest) {
						BEGIN_FOR_POSITIONS(Sequence,backend,IntegerRegion,otherIDs,(other->getImportedIDs()->stepper())) {
							SPTR(IntegerRegion) iDs;
							
							iDs = CAST(IntegerRegion,myImportedIDs->fetch(backend));
							if (iDs == NULL) {
								result->store(backend, otherIDs);
							}
						} END_FOR_POSITIONS;
					}
				}
			}
			if (result != NULL) {
				BEGIN_FOR_POSITIONS(Sequence,backend,IntegerRegion,iDs,(result->stepper())) {
					BooleanVar f;
					
					{	BooleanVar crutch_Flag;
						/* myIncludesRest || other->includesRest() */
						
						crutch_Flag = myIncludesRest;
						if(!crutch_Flag) {
							crutch_Flag = other->includesRest();
						}
						if (crutch_Flag) {
							f = iDs->isEqual(IDRegion::TheLocalNumbers);
						} else {
							f = iDs->isEmpty();
						}
					}
					if (f) {
						result->wipe(backend);
					}
				} END_FOR_POSITIONS;
				if (result->isEmpty()) {
					result = NULL;
				}
			}
			if (result == NULL) {
				resTable = NULL;
			} else {
				resTable = result->asImmuTable();
			}
			WPTR(XnRegion) 	returnValue;
			returnValue = IDRegion::make (mySpace, CAST(IntegerRegion,myLocalIDs->unionWith(other->localIDs())), resTable, myIncludesRest || other->includesRest());
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return NULL;
}


RPTR(XnRegion) IDRegion::with (APTR(Position) pos){
	SPTR(ImmuTable) resTable;
	SPTR(IntegerRegion) newLocalIDs;
	
	BEGIN_CHOOSE(pos) {
		BEGIN_KIND(ID,id) {
			SPTR(MuTable) result;
			
			if (myImportedIDs == NULL) {
				{	BooleanVar crutch_Flag;
					/* myIncludesRest || id->fetchBackend() == NULL */
					
					crutch_Flag = myIncludesRest;
					if(!crutch_Flag) {
						crutch_Flag = id->fetchBackend() == NULL;
					}
					if (crutch_Flag) {
						result = NULL;
					} else {
						result = MuTable::make (id->fetchSpace());
						result->introduce(id->fetchBackend(), IntegerRegion::make (id->number()));
					}
				}
			} else {
				if (id->fetchBackend() == NULL) {
					result = myImportedIDs->asMuTable();
				} else {
					result = MuTable::make (SequenceSpace::make ());
					BEGIN_FOR_POSITIONS(Sequence,backend,IntegerRegion,iDs,(myImportedIDs->stepper())) {
						if (id->fetchBackend()->isEqual(backend)) {
							result->store(backend, iDs->withInt(id->number()));
						} else {
							result->store(backend, iDs);
						}
					} END_FOR_POSITIONS;
				}
				if (!myIncludesRest) {
					result->store(id->fetchBackend(), IntegerRegion::make (id->number()));
				}
			}
			if (result != NULL) {
				BEGIN_FOR_POSITIONS(Sequence,backend,IntegerRegion,iDs,(result->stepper())) {
					BooleanVar f;
					
					if (myIncludesRest) {
						f = iDs->isEqual(IDRegion::TheLocalNumbers);
					} else {
						f = iDs->isEmpty();
					}
					if (f) {
						result->wipe(backend);
					}
				} END_FOR_POSITIONS;
				if (result->isEmpty()) {
					result = NULL;
				}
			}
			if (result == NULL) {
				resTable = NULL;
			} else {
				resTable = result->asImmuTable();
			}
			newLocalIDs = myLocalIDs;
			if (id->fetchBackend() == NULL) {
				newLocalIDs = CAST(IntegerRegion,newLocalIDs->withInt(id->number()));
			}
			WPTR(XnRegion) 	returnValue;
			returnValue = IDRegion::make (mySpace, newLocalIDs, resTable, myIncludesRest);
			return returnValue;
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return NULL;
}
/* protected: create */


IDRegion::IDRegion (
		APTR(IDSpace) OR(NULL) space, 
		APTR(IntegerRegion) localIDs, 
		APTR(ImmuTable) OF2(Sequence,IntegerRegion) OR(NULL) importedIDs, 
		BooleanVar includesRest) 
{
	mySpace = space;
	myLocalIDs = localIDs;
	myImportedIDs = importedIDs;
	myIncludesRest = includesRest;
}
/* printing */


void IDRegion::printOn (ostream& oo){
	SPTR(XnRegion) iDs;
	
	oo << "{" << CAST(IDSpace,this->coordinateSpace())->identifier() << " |";
	iDs = myLocalIDs->intersect(IntegerRegion::before(IntegerVarZero));
	if (!iDs->isEmpty()) {
		oo << " !" << iDs;
	}
	iDs = myLocalIDs->intersect(IntegerRegion::after(IntegerVarZero));
	if (!iDs->isEmpty()) {
		oo << " " << FeServer::identifier() << "." << iDs;
	}
	if (!(myImportedIDs == NULL)) {
		BEGIN_FOR_POSITIONS(Sequence,backend,IntegerRegion,iDs,(myImportedIDs->stepper())) {
			oo << " " << backend << "." << iDs;
		} END_FOR_POSITIONS;
	}
	if (myIncludesRest) {
		oo << " ...{...} ";
	}
	oo << "}";
}



/* ************************************************************************ *
 * 
 *                    Class IDSpace 
 *
 * ************************************************************************ */


/* creation */


RPTR(IDSpace) IDSpace::global (){
	/* Return the global ID space. */
	
	WPTR(IDSpace) 	returnValue;
	returnValue = CurrentGrandMap.fluidGet()->globalIDSpace();
	return returnValue;
}


RPTR(IDSpace) IDSpace::import (APTR(PrimIntArray) data){
	/* Essential. Take some information describing an IDSpace and 
	create the IDSpace it was exported from. */
	
	SPTR(SpecialistRcvr) rcvr;
	SPTR(Sequence) backend;
	IntegerVar number;
	
	rcvr = Binary2XcvrMaker::make ()->makeRcvr(TransferSpecialist::make (Cookbook::make ()), XnReadStream::make (CAST(UInt8Array,data)));
	backend = ID::importSequence(rcvr);
	number = rcvr->receiveIntegerVar();
	WPTR(IDSpace) 	returnValue;
	returnValue = IDSpace::make (backend, number);
	return returnValue;
}


RPTR(IDSpace) IDSpace::unique (){
	/* Essential. Create a new globally unique space of IDs */
	
	WPTR(IDSpace) 	returnValue;
	returnValue = CurrentGrandMap.fluidGet()->newIDSpace();
	return returnValue;
}
/* private: pseudo constructors */


RPTR(IDSpace) IDSpace::make (APTR(Sequence) OR(NULL) identifier, IntegerVar number){
	WPTR(IDSpace) 	returnValue;
	returnValue = IDSpace::make (identifier, number, CurrentGrandMap.fluidGet()->getOrMakeIDCounter(identifier, number));
	return returnValue;
}


RPTR(IDSpace) IDSpace::make (
		APTR(Sequence) OR(NULL) identifier, 
		IntegerVar number, 
		APTR(Counter) counter)
{
	SPTR(BeGrandMap) cgm;
	
	cgm = CurrentGrandMap.fluidFetch();
	{	BooleanVar crutch_Flag;
		/* identifier != NULL && (identifier->isZero() || cgm != NULL && identifier->isEqual(cgm->identifier())) */
		
		crutch_Flag = identifier != NULL;
		if(crutch_Flag) {
			crutch_Flag = identifier->isZero();
			if(!crutch_Flag) {
				crutch_Flag = cgm != NULL;
				if(crutch_Flag) {
					crutch_Flag = identifier->isEqual(cgm->identifier());
				}
			}
		}
		if (crutch_Flag) {
			RETURN_CONSTRUCT(IDSpace,(NULL, number, counter));
		}
	}
	RETURN_CONSTRUCT(IDSpace,(identifier, number, counter));
}
/* rcvr pseudo constructors */


RPTR(Heaper) IDSpace::make (APTR(Rcvr) rcvr){
	SPTR(Heaper) memory;
	SPTR(Sequence) backend;
	IntegerVar space;
	SPTR(Counter) idCounter;
	
	/* Thing to do !!!! */
	
	/* Should intern someday */
	memory = CAST(SpecialistRcvr,rcvr)->makeIbid(cat_IDSpace);
	backend = CAST(Sequence,rcvr->receiveHeaper());
	space = rcvr->receiveIntegerVar();
	idCounter = CAST(Counter,rcvr->receiveHeaper());
	WPTR(Heaper) 	returnValue;
	returnValue = new (memory) IDSpace(backend, space, idCounter);
	return returnValue;
}
/* A space of IDs, which can generate globally unique IDs.

Implementation note:
	myBackend - the identifier of the Server which generated this space. 
If NULL, then it was generated by the current Server (unless 
mySpaceNumber is -1, in which case it is the single global IDSpace 
shared by all Servers.
	mySpaceNumber - identifies which space this is. If -1, then it is 
the global ID space, and myBackend must be NULL. */


/* making */


RPTR(IDRegion) IDSpace::iDsFromServer (APTR(Sequence) identifier){
	/* Essential. The Region of IDs in this space which might be 
	genrated by the given Server */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* fodder */
	return NULL;
}


RPTR(ID) IDSpace::newID (){
	/* Essential. A new ID guaranteed to be different from every 
	other newID generated by this IDSpace or any IDSpace isEqual 
	to it, on any Server. (Although of course IDs generated using 
	this->oldID () may conflict if the right numbers happen to 
	have been supplied.) */
	
	WPTR(ID) 	returnValue;
	returnValue = ID::make (this->fetchIDSpace(), NULL, myNewIDCounter->increment());
	return returnValue;
}


RPTR(IDRegion) IDSpace::newIDs (IntegerVar count){
	/* A region containing a finite number of globally unique 
	IDs. See newID for uniqueness guarantees. */
	
	WPTR(IDRegion) 	returnValue;
	returnValue = IDRegion::make (this->fetchIDSpace(), IntegerRegion::integerExtent(myNewIDCounter->incrementBy(count), count), NULL, FALSE);
	return returnValue;
}
/* private: for friends */


RPTR(Sequence) IDSpace::backend (){
	/* Essential. The Server which created this IDSpace */
	
	if (myBackend == NULL) {
		if (mySpaceNumber == -1) {
			WPTR(Sequence) 	returnValue;
			returnValue = Sequence::zero();
			return returnValue;
		} else {
			WPTR(Sequence) 	returnValue;
			returnValue = FeServer::identifier();
			return returnValue;
		}
	}
	return (Sequence*) myBackend;
}


RPTR(Sequence) OR(NULL) IDSpace::fetchBackend (){
	return (Sequence*) myBackend;
}


RPTR(IDSpace) OR(NULL) IDSpace::fetchIDSpace (){
	/* NULL if this is the global IDSpace, self otherwise */
	
	{	BooleanVar crutch_Flag;
		/* myBackend == NULL && mySpaceNumber == -1 */
		
		crutch_Flag = myBackend == NULL;
		if(crutch_Flag) {
			crutch_Flag = mySpaceNumber == -1;
		}
		if (crutch_Flag) {
			return NULL;
		} else {
			return this;
		}
	}
}


RPTR(IDRegion) IDSpace::oldIDs (APTR(Sequence) backend, APTR(IntegerRegion) numbers){
	/* Recreate a region of IDs from information that was stored 
	outside the Server */
	
	if (backend->isZero()) {
		if (numbers->intersects(IntegerRegion::after(IntegerVarZero))) {
			BLAST(InvalidRequest);
		} else {
			WPTR(IDRegion) 	returnValue;
			returnValue = IDRegion::make (this->fetchIDSpace(), numbers, NULL, FALSE);
			return returnValue;
		}
	} else {
		SPTR(MuTable) table;
		
		if (!numbers->isSubsetOf(IntegerRegion::after(IntegerVarZero))) {
			BLAST(InvalidRequest);
		}
		if (backend->isEqual(FeServer::identifier())) {
			WPTR(IDRegion) 	returnValue;
			returnValue = IDRegion::make (this->fetchIDSpace(), numbers, NULL, FALSE);
			return returnValue;
		}
		table = MuTable::make (SequenceSpace::make ());
		table->store(backend, numbers);
		WPTR(IDRegion) 	returnValue;
		returnValue = IDRegion::make (this->fetchIDSpace(), IntegerRegion::make (), table->asImmuTable(), FALSE);
		return returnValue;
	}
	/* fodder */
	return NULL;
}


IntegerVar IDSpace::spaceNumber (){
	/* Essential. Identifies this particular space among all 
	those generated by the same Server. */
	
	return mySpaceNumber;
}
/* private: create */


IDSpace::IDSpace (
		APTR(Sequence) OR(NULL) backend, 
		IntegerVar number, 
		APTR(Counter) counter) 
{
	myBackend = backend;
	mySpaceNumber = number;
	this->finishCreation();
	myNewIDCounter = counter;
}


void IDSpace::finishCreation (){
	SPTR(IDSpace) myself;
	
	{	BooleanVar crutch_Flag;
		/* myBackend == NULL && mySpaceNumber == -1 */
		
		crutch_Flag = myBackend == NULL;
		if(crutch_Flag) {
			crutch_Flag = mySpaceNumber == -1;
		}
		if (crutch_Flag) {
			myself = NULL;
		} else {
			myself = this;
		}
	}
	this->finishCreate(
			IDRegion::usingx(myself, CAST(IntegerRegion,IntegerSpace::make ()->emptyRegion()), NULL, FALSE), 
			IDRegion::usingx(myself, CAST(IntegerRegion,IntegerSpace::make ()->fullRegion()), NULL, TRUE), IDDsp::make (this), IDUpOrder::make (this), NULL);
}
/* testing */


UInt32 IDSpace::actualHashForEqual (){
	if (myBackend == NULL) {
		return mySpaceNumber.hashForEqual() ^ this->getCategory()->hashForEqual();
	} else {
		return myBackend->hashForEqual() ^ mySpaceNumber.hashForEqual() ^ this->getCategory()->hashForEqual();
	}
}


BooleanVar IDSpace::isEqual (APTR(Heaper) other){
	BEGIN_CHOOSE(other) {
		BEGIN_KIND(IDSpace,space) {
			{	BooleanVar crutch_Flag;
				/* this == space || mySpaceNumber == space->spaceNumber() && (myBackend == NULL && space->fetchBackend() == NULL || myBackend != NULL && space->fetchBackend() != NULL && myBackend->isEqual(space->fetchBackend())) */
				
				crutch_Flag = this == space;
				if(!crutch_Flag) {
					crutch_Flag = mySpaceNumber == space->spaceNumber();
					if(crutch_Flag) {
						crutch_Flag = myBackend == NULL;
						if(crutch_Flag) {
							crutch_Flag = space->fetchBackend() == NULL;
						}
						if(!crutch_Flag) {
							crutch_Flag = myBackend != NULL;
							if(crutch_Flag) {
								crutch_Flag = space->fetchBackend() != NULL;
								if(crutch_Flag) {
									crutch_Flag = myBackend->isEqual(space->fetchBackend());
								}
							}
						}
					}
				}
				return crutch_Flag;
			}
		} END_KIND;
		BEGIN_OTHERS {
			return FALSE;
		} END_OTHERS;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}
/* printing */


void IDSpace::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(";
	if (this->fetchIDSpace() == NULL) {
		oo << "!0";
	} else {
		oo << this->backend() << "." << mySpaceNumber;
	}
	oo << ")";
}
/* accessing */


RPTR(UInt8Array) IDSpace::export (){
	/* Essential. Produce an array which can be handed to 
	Server::importIDSpace on any Server to get back the same IDSpace */
	
	SPTR(SpecialistXmtr) xmtr;
	SPTR(WriteVariableArrayStream) result;
	
	result = WriteVariableArrayStream::make (200);
	xmtr = Binary2XcvrMaker::make ()->makeXmtr(TransferSpecialist::make (Cookbook::make ()), result);
	ID::exportSequence(xmtr, this->backend());
	xmtr->sendIntegerVar(this->spaceNumber());
	WPTR(UInt8Array) 	returnValue;
	returnValue = result->array();
	return returnValue;
}
/* obsolete: */


RPTR(Sequence) IDSpace::identifier (){
	/* A Sequence uniquely identifying this IDSpace, so that
			FeServer::current ()->oldIDSpace (this->identifier ())
				->isEqual (this) */
	
	/* Ravi -- Thing to do !!!! */
	
	/* get rid of this message and its clients */
	WPTR(Sequence) 	returnValue;
	returnValue = this->backend()->withLast(mySpaceNumber);
	return returnValue;
}
/* hooks: */


void IDSpace::sendIDSpaceTo (APTR(Xmtr) xmtr){
	xmtr->sendHeaper(myBackend);
	xmtr->sendIntegerVar(mySpaceNumber);
	xmtr->sendHeaper(myNewIDCounter);
}



/* ************************************************************************ *
 * 
 *                    Class IDSimpleStepper 
 *
 * ************************************************************************ */


/* create */


RPTR(Stepper) IDSimpleStepper::copy (){
	RETURN_CONSTRUCT(IDSimpleStepper,(myRegion, myBackends->copy(), myIDs->copy(), myInexplicit));
}


IDSimpleStepper::IDSimpleStepper (APTR(IDRegion) region, TCSJ) {
	myRegion = region;
	myBackends = region->explicitBackends()->stepper();
	if (myBackends->hasValue()) {
		myIDs = region->iDNumbersFrom(CAST(Sequence,myBackends->fetch()))->simpleRegions();
	} else {
		myIDs = NULL;
		myBackends = NULL;
	}
	myValue = NULL;
	myInexplicit = region->fetchInexplicit();
}


IDSimpleStepper::IDSimpleStepper (
		APTR(IDRegion) region, 
		APTR(Stepper) OF1(Sequence) backends, 
		APTR(Stepper) OF1(XnRegion) iDs, 
		APTR(IDRegion) OR(NULL) inexplicit) 
{
	myRegion = region;
	myBackends = backends;
	myIDs = iDs;
	myValue = NULL;
	myInexplicit = inexplicit;
}
/* operations */


WPTR(Heaper) IDSimpleStepper::fetch (){
	if (myInexplicit != NULL) {
		return (IDRegion*) myInexplicit;
	}
	{	BooleanVar crutch_Flag;
		/* myValue == NULL && myBackends != NULL */
		
		crutch_Flag = myValue == NULL;
		if(crutch_Flag) {
			crutch_Flag = myBackends != NULL;
		}
		if (crutch_Flag) {
			myValue = CAST(IDSpace,myRegion->coordinateSpace())->oldIDs(CAST(Sequence,myBackends->fetch()), CAST(IntegerRegion,myIDs->fetch()));
		}
	}
	return (IDRegion*) myValue;
}


BooleanVar IDSimpleStepper::hasValue (){
	{	BooleanVar crutch_Flag;
		/* myInexplicit != NULL || myBackends != NULL */
		
		crutch_Flag = myInexplicit != NULL;
		if(!crutch_Flag) {
			crutch_Flag = myBackends != NULL;
		}
		return crutch_Flag;
	}
}


void IDSimpleStepper::step (){
	if (myInexplicit != NULL) {
		myInexplicit = NULL;
	} else {
		if (myBackends != NULL) {
			myValue = NULL;
			myIDs->step();
			if (!myIDs->hasValue()) {
				myBackends->step();
				if (!myBackends->hasValue()) {
					myBackends = NULL;
					myIDs = NULL;
					return;
					
				}
				myIDs = myRegion->iDNumbersFrom(CAST(Sequence,myBackends->fetch()))->simpleRegions();
			}
		}
	}
}



/* ************************************************************************ *
 * 
 *                    Class IDStepper 
 *
 * ************************************************************************ */


/* create */


RPTR(Stepper) IDStepper::copy (){
	RETURN_CONSTRUCT(IDStepper,(myRegion, myBackends->copy(), myIDs->copy()));
}


IDStepper::IDStepper (APTR(IDRegion) region, TCSJ) {
	myRegion = region;
	myBackends = region->backends()->stepper();
	if (myBackends->hasValue()) {
		myIDs = region->iDNumbersFrom(CAST(Sequence,myBackends->fetch()))->stepper();
	} else {
		myIDs = NULL;
		myBackends = NULL;
	}
	myValue = NULL;
}


IDStepper::IDStepper (
		APTR(IDRegion) region, 
		APTR(Stepper) OF1(Sequence) backends, 
		APTR(Stepper) OF1(IntegerPos) iDs) 
{
	myRegion = region;
	myBackends = backends;
	myIDs = iDs;
	myValue = NULL;
}
/* operations */


WPTR(Heaper) IDStepper::fetch (){
	{	BooleanVar crutch_Flag;
		/* myValue == NULL && myBackends != NULL */
		
		crutch_Flag = myValue == NULL;
		if(crutch_Flag) {
			crutch_Flag = myBackends != NULL;
		}
		if (crutch_Flag) {
			myValue = 
					ID::usingx(myRegion->fetchSpace(), CAST(Sequence,myBackends->fetch()), CAST(IntegerPos,myIDs->fetch())->asIntegerVar());
		}
	}
	return (ID*) myValue;
}


BooleanVar IDStepper::hasValue (){
	return myBackends != NULL;
}


void IDStepper::step (){
	if (myBackends != NULL) {
		myValue = NULL;
		myIDs->step();
		if (!myIDs->hasValue()) {
			myBackends->step();
			if (!myBackends->hasValue()) {
				myBackends = NULL;
				myIDs = NULL;
				return;
				
			}
			myIDs = myRegion->iDNumbersFrom(CAST(Sequence,myBackends->fetch()))->stepper();
		}
	}
}



/* ************************************************************************ *
 * 
 *                    Class IDUpOrder 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(OrderSpec) IDUpOrder::make (APTR(IDSpace) space){
	RETURN_CONSTRUCT(IDUpOrder,(space, tcsj));
}
/* testing */


UInt32 IDUpOrder::actualHashForEqual (){
	return this->getCategory()->hashForEqual();
}


BooleanVar IDUpOrder::follows (APTR(Position) x, APTR(Position) y){
	BEGIN_CHOOSE(x) {
		BEGIN_KIND(ID,a) {
			BEGIN_CHOOSE(y) {
				BEGIN_KIND(ID,b) {
					/* Ravi -- Thing to do !!!! */
					
					/* more efficient comparison */
					{	BooleanVar crutch_Flag;
						/* !b->backend()->isGE(a->backend()) || a->backend()->isEqual(b->backend()) && a->number() >= b->number() */
						
						crutch_Flag = !b->backend()->isGE(a->backend());
						if(!crutch_Flag) {
							crutch_Flag = a->backend()->isEqual(b->backend());
							if(crutch_Flag) {
								crutch_Flag = a->number() >= b->number();
							}
						}
						return crutch_Flag;
					}
				} END_KIND;
			} END_CHOOSE;
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}


BooleanVar IDUpOrder::isEqual (APTR(Heaper) other){
	return other->isKindOf(cat_IDUpOrder);
}


BooleanVar IDUpOrder::isFullOrder (APTR(XnRegion) keys/* = NULL*/){
	return TRUE;
}


BooleanVar IDUpOrder::preceeds (APTR(XnRegion) before, APTR(XnRegion) after){
	/* Return true if some position in before is less than or 
	equal to all positions in after. */
	
	SPTR(SequenceRegion) beforeB;
	SPTR(SequenceRegion) afterB;
	SPTR(Sequence) bound;
	
	BEGIN_CHOOSE(before) {
		BEGIN_KIND(IDRegion,beforeIDs) {
			BEGIN_CHOOSE(after) {
				BEGIN_KIND(IDRegion,afterIDs) {
					beforeB = beforeIDs->backends();
					afterB = afterIDs->backends();
					if (!SequenceSpace::make ()->ascending()->preceeds(beforeB, afterB)) {
						return FALSE;
					}
					if (!beforeB->isBoundedBelow()) {
						return TRUE;
					}
					bound = beforeB->lowerBound();
					if (!bound->isEqual(afterB->lowerBound())) {
						return TRUE;
					}
					return IntegerSpace::make ()->ascending()->preceeds(beforeIDs->iDNumbersFrom(bound), afterIDs->iDNumbersFrom(bound));
				} END_KIND;
			} END_CHOOSE;
		} END_KIND;
	} END_CHOOSE;
	/* fodder */
	return FALSE;
}
/* accessing */


RPTR(Arrangement) IDUpOrder::arrange (APTR(XnRegion) region){
	SPTR(Stepper) stepper;
	SPTR(PtrArray) array;
	
	if (!region->isFinite()) {
		BLAST(MustBeFinite);
	}
	stepper = CAST(IDRegion,region)->stepper();
	array = CAST(PtrArray,stepper->stepMany());
	if (!stepper->atEnd()) {
		BLAST(NOT_YET_IMPLEMENTED);
	}
	WPTR(Arrangement) 	returnValue;
	returnValue = ExplicitArrangement::make (array);
	return returnValue;
}


RPTR(CoordinateSpace) IDUpOrder::coordinateSpace (){
	return (IDSpace*) myIDSpace;
}
/* create */


IDUpOrder::IDUpOrder (APTR(IDSpace) space, TCSJ) {
	myIDSpace = space;
}

#ifndef IDX_SXX
#include "idx.sxx"
#endif /* IDX_SXX */


#ifndef IDP_SXX
#include "idp.sxx"
#endif /* IDP_SXX */



#endif /* IDX_CXX */

