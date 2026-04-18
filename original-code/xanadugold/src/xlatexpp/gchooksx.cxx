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

#ifndef GCHOOKSX_CXX
#define GCHOOKSX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef GCHOOKSX_HXX
#include "gchooksx.hxx"
#endif /* GCHOOKSX_HXX */

#ifndef GCHOOKSX_IXX
#include "gchooksx.ixx"
#endif /* GCHOOKSX_IXX */




/* ************************************************************************ *
 * 
 *                    Class CloseExecutor 
 *
 * ************************************************************************ */



/* Initializers for CloseExecutor */

GPTR(Int32Array) CloseExecutor::FDArray = NULL;
GPTR(WeakPtrArray) CloseExecutor::FileDescriptorHolders = NULL;


/* Initializers for CloseExecutor */



/* accessing */


void CloseExecutor::registerHolder (APTR(Heaper) holder, Int32 fd){
	Int32 slot;
	
	slot = Int32Zero;
	if (CloseExecutor::FDArray == NULL) {
		SPTR(XnExecutor) exec;
		
		CloseExecutor::FDArray = Int32Array::make (32);
		CONSTRUCT(exec,CloseExecutor,());
		CloseExecutor::FileDescriptorHolders = WeakPtrArray::make (exec, 32);
	}
	slot = CloseExecutor::FileDescriptorHolders->indexOf(NULL);
	
	if (slot == -1) {
		
		slot = CloseExecutor::FDArray->count();
		CloseExecutor::FDArray = CAST(Int32Array,CloseExecutor::FDArray->copyGrow(16));
		CloseExecutor::FileDescriptorHolders = CAST(WeakPtrArray,CloseExecutor::FileDescriptorHolders->copyGrow(16));
	}
	CloseExecutor::FDArray->storeInt(slot, fd);
	CloseExecutor::FileDescriptorHolders->store(slot, holder);
}


void CloseExecutor::unregisterHolder (APTR(Heaper) holder, Int32 fd){
	Int32 slot;
	
	slot = CloseExecutor::FileDescriptorHolders->indexOfEQ(holder);
	for (;;) {	BooleanVar crutch_Flag;
		/* slot != -1 && slot < CloseExecutor::FDArray->count() && CloseExecutor::FDArray->intAt(slot) != fd */
		
		crutch_Flag = slot != -1;
		if(crutch_Flag) {
			crutch_Flag = slot < CloseExecutor::FDArray->count();
			if(crutch_Flag) {
				crutch_Flag = CloseExecutor::FDArray->intAt(slot) != fd;
			}
		}
		if (crutch_Flag) {
			slot = CloseExecutor::FileDescriptorHolders->indexOfEQ(holder, slot + 1);
		} else {
			break;
		}
	}
	{	BooleanVar crutch_Flag;
		/* slot == -1 || CloseExecutor::FDArray->intAt(slot) != fd */
		
		crutch_Flag = slot == -1;
		if(!crutch_Flag) {
			crutch_Flag = CloseExecutor::FDArray->intAt(slot) != fd;
		}
		if (crutch_Flag) {
			BLAST(SanityViolation);
		}
	}
	CloseExecutor::FileDescriptorHolders->store(slot, NULL);
	CloseExecutor::FDArray->storeInt(slot, -1);
}
/* This executor manages objects that need to close file descriptors 
on finalization. */


/* protected: create */


CloseExecutor::CloseExecutor () {
	
}
/* invoking */


void CloseExecutor::execute (Int32 estateIndex){
	Int32 fd;
	
	fd = CloseExecutor::FDArray->intAt(estateIndex);
	if (fd != -1) {
		
		close((int)fd);
		
		CloseExecutor::FDArray->storeInt(estateIndex, -1);
	}
}



/* ************************************************************************ *
 * 
 *                    Class DeleteExecutor 
 *
 * ************************************************************************ */



/* Initializers for DeleteExecutor */

void* * DeleteExecutor::StorageArray = NULL;
GPTR(WeakPtrArray) DeleteExecutor::StorageHolders = NULL;


/* Initializers for DeleteExecutor */



/* accessing */


void DeleteExecutor::registerHolder (APTR(Heaper) holder, void * storage){
	Int32 slot;
	
	if (DeleteExecutor::StorageArray == NULL) {
		SPTR(XnExecutor) exec;
		
		DeleteExecutor::StorageArray = new void* [32];
		memset (DeleteExecutor::StorageArray, 0, 32 * sizeof(void*));
		
		
		CONSTRUCT(exec,DeleteExecutor,());
		DeleteExecutor::StorageHolders = WeakPtrArray::make (exec, 32);
	}
	slot = DeleteExecutor::StorageHolders->indexOf(NULL);
	if (slot == -1) {
		slot = DeleteExecutor::StorageHolders->count();
		void ** newArray = new void* [slot + 16];
		memset(&newArray[slot], 0, 16 * sizeof(void*));
		MEMMOVE(newArray, DeleteExecutor::StorageArray, (int)slot);
		delete DeleteExecutor::StorageArray;
		DeleteExecutor::StorageArray = newArray;
		
		
		DeleteExecutor::StorageHolders = CAST(WeakPtrArray,DeleteExecutor::StorageHolders->copyGrow(16));
	}
	DeleteExecutor::StorageArray[slot] = storage;
	DeleteExecutor::StorageHolders->store(slot, holder);
}


void DeleteExecutor::unregisterHolder (APTR(Heaper) holder, void * storage){
	Int32 slot;
	
	slot = DeleteExecutor::StorageHolders->indexOfEQ(holder);
	for (;;) {	BooleanVar crutch_Flag;
		/* slot != -1 && slot < DeleteExecutor::StorageHolders->count() && DeleteExecutor::StorageArray[slot] != storage */
		
		crutch_Flag = slot != -1;
		if(crutch_Flag) {
			crutch_Flag = slot < DeleteExecutor::StorageHolders->count();
			if(crutch_Flag) {
				crutch_Flag = DeleteExecutor::StorageArray[slot] != storage;
			}
		}
		if (crutch_Flag) {
			slot = DeleteExecutor::StorageHolders->indexOfEQ(holder, slot + 1);
		} else {
			break;
		}
	}
	{	BooleanVar crutch_Flag;
		/* slot == -1 || DeleteExecutor::StorageArray[slot] != storage */
		
		crutch_Flag = slot == -1;
		if(!crutch_Flag) {
			crutch_Flag = DeleteExecutor::StorageArray[slot] != storage;
		}
		if (crutch_Flag) {
			BLAST(SanityViolation);
		}
	}
	DeleteExecutor::StorageArray[slot] = NULL;
	DeleteExecutor::StorageHolders->store(slot, NULL);
}
/* This executor manages objects that need to release non-Heaper 
storage on finalization. */


/* invoking */


void DeleteExecutor::execute (Int32 estateIndex){
	void * storage;
	
	storage = DeleteExecutor::StorageArray[estateIndex];
	if (storage != NULL) {
		delete storage;
	}
	DeleteExecutor::StorageArray[estateIndex] = NULL;
}
/* protected: create */


DeleteExecutor::DeleteExecutor () {
	
}



/* ************************************************************************ *
 * 
 *                    Class RepairEngineer 
 *
 * ************************************************************************ */



/* Initializers for RepairEngineer */

GPTR(RepairEngineer) RepairEngineer::FirstEngineer = NULL;


/* Initializers for RepairEngineer */



/* repairing */


void RepairEngineer::repairThings (){
	SPTR(RepairEngineer) se;
	
	se = RepairEngineer::FirstEngineer;
	while (se != NULL) {
		se->repair();
		se = se->next();
	}
}
/* RepairEngineers are invoked at the top of server loops and the 
like in order to perform damage control after such events as a 
conservative GC or a conservative purge in response to an resource 
emergency with a deep stack.  These modules should implement 
subclasses of RepairEngineer (RE) which implement the method {void} repair.
REs are registered by construction and deregistered by destruction. */


/* protected: create */


RepairEngineer::RepairEngineer () {
	if (RepairEngineer::FirstEngineer != NULL) {
		RepairEngineer::FirstEngineer->setPrev(this);
	}
	myNext = RepairEngineer::FirstEngineer;
	myPrev = NULL;
	RepairEngineer::FirstEngineer = this;
}


void RepairEngineer::destruct (){
	{	BooleanVar crutch_Flag;
		/* myPrev != NULL && myPrev->isKindOf(cat_RepairEngineer) */
		
		crutch_Flag = myPrev != NULL;
		if(crutch_Flag) {
			crutch_Flag = myPrev->isKindOf(cat_RepairEngineer);
		}
		if (crutch_Flag) {
			myPrev->setNext(myNext);
		} else {
			RepairEngineer::FirstEngineer = CAST(RepairEngineer,myNext);
		}
	}
	{	BooleanVar crutch_Flag;
		/* myNext != NULL && myNext->isKindOf(cat_RepairEngineer) */
		
		crutch_Flag = myNext != NULL;
		if(crutch_Flag) {
			crutch_Flag = myNext->isKindOf(cat_RepairEngineer);
		}
		if (crutch_Flag) {
			myNext->setPrev(myPrev);
		}
	}
	this->Heaper::destruct();
}
/* invoking */
/* private: accessing */



/* ************************************************************************ *
 * 
 *                    Class SanitationEngineer 
 *
 * ************************************************************************ */



/* Initializers for SanitationEngineer */

GPTR(SanitationEngineer) SanitationEngineer::FirstEngineer = NULL;


/* Initializers for SanitationEngineer */



/* sanitizing */


void SanitationEngineer::garbageDay (BooleanVar required){
	SPTR(SanitationEngineer) se;
	
	se = SanitationEngineer::FirstEngineer;
	while (se != NULL) {
		se->recycle(required);
		se = se->next();
	}
}
/* SanitationEngineers are used by modules that can perform clever 
resource management at garbage collection time.  These modules should 
implement subclasses of SanitationEngineer (SE) which implement the 
method {void} recycle.
The garbage collector calls the recycle method for each existing SE 
prior to the marking phase.  SEs are registered
by construction and deregistered by destruction. */


/* invoking */
/* protected: create */


SanitationEngineer::SanitationEngineer () {
	if (SanitationEngineer::FirstEngineer != NULL) {
		SanitationEngineer::FirstEngineer->setPrev(this);
	}
	myNext = SanitationEngineer::FirstEngineer;
	myPrev = NULL;
	SanitationEngineer::FirstEngineer = this;
}


void SanitationEngineer::destruct (){
	{	BooleanVar crutch_Flag;
		/* myPrev != NULL && myPrev->isKindOf(cat_SanitationEngineer) */
		
		crutch_Flag = myPrev != NULL;
		if(crutch_Flag) {
			crutch_Flag = myPrev->isKindOf(cat_SanitationEngineer);
		}
		if (crutch_Flag) {
			myPrev->setNext(myNext);
		} else {
			SanitationEngineer::FirstEngineer = CAST(SanitationEngineer,myNext);
		}
	}
	{	BooleanVar crutch_Flag;
		/* myNext != NULL && myNext->isKindOf(cat_SanitationEngineer) */
		
		crutch_Flag = myNext != NULL;
		if(crutch_Flag) {
			crutch_Flag = myNext->isKindOf(cat_SanitationEngineer);
		}
		if (crutch_Flag) {
			myNext->setPrev(myPrev);
		}
	}
	this->Heaper::destruct();
}
/* private: accessing */



/* ************************************************************************ *
 * 
 *                    Class StackExaminer 
 *
 * ************************************************************************ */



/* Initializers for StackExaminer */

Int32 * StackExaminer::StackEnd = NULL;
GPTR(PrimPtrTable) StackExaminer::TheStackSet = NULL;


/* Initializers for StackExaminer */



/* accessing */


RPTR(PrimPtrTable) StackExaminer::pointersOnStack (){
	/* Do NOT destroy the result table.  It is reused to avoid 
	allocation during purgeClean. */
	
	SPTR(PrimPtrTable) result;
	
	if (StackExaminer::TheStackSet == NULL) {
		StackExaminer::TheStackSet = PrimPtrTable::make (1024);
	}
	result = StackExaminer::TheStackSet;
	result->clearAll();
	
	Int32 stack;
	Int32 * stackPtr = & stack;
	if (StackExaminer::stackEnd() == NULL) {
		BLAST(StackEndUninitialized);
	}
	for (; stackPtr < (Int32 *) StackExaminer::stackEnd(); stackPtr++) {
		if (*stackPtr != 0 && (*stackPtr & 3) == 0) {
			result->store((Int32)(void*)*stackPtr, result);
		}
	}
	
	WPTR(PrimPtrTable) 	returnValue;
	returnValue = result;
	return returnValue;
}


void StackExaminer::stackEnd (Int32 * end){
	StackExaminer::StackEnd = end;
}
/* main() routines that are going to invoke garbage collection should
call StackExaminer::stackEnd(&stackObj), where stackObj is an Int32
local to main's stack frame.  This should be called before anything
else, even invoking the Initializer object. */


/* testing */


UInt32 StackExaminer::actualHashForEqual (){
	return Heaper::takeOop();
}

	/* automatic 0-argument constructor */
StackExaminer::StackExaminer() {}

#ifndef GCHOOKSX_SXX
#include "gchooksx.sxx"
#endif /* GCHOOKSX_SXX */



#endif /* GCHOOKSX_CXX */

