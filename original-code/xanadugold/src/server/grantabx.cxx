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

#ifndef GRANTABX_CXX
#define GRANTABX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef GRANTABX_HXX
#include "grantabx.hxx"
#endif /* GRANTABX_HXX */

#ifndef GRANTABX_IXX
#include "grantabx.ixx"
#endif /* GRANTABX_IXX */

#ifndef GRANTABP_HXX
#include "grantabp.hxx"
#endif /* GRANTABP_HXX */

#ifndef GRANTABP_IXX
#include "grantabp.ixx"
#endif /* GRANTABP_IXX */


#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef PSRANDX_HXX
#include "psrandx.hxx"
#endif /* PSRANDX_HXX */




/* ************************************************************************ *
 * 
 *                    Class GrandHashSet 
 *
 * ************************************************************************ */



/* Initializers for GrandHashSet */


BEGIN_INIT_TIME(GrandHashSet,initTimeNonInherited) {
	REQUIRES (ExponentialHashMap);
} END_INIT_TIME(GrandHashSet,initTimeNonInherited);



/* Initializers for GrandHashSet */



/* pseudoConstructors */


RPTR(GrandHashSet) GrandHashSet::make (){
	/* A Very big table */
	RETURN_CONSTRUCT(GrandHashSet,(32, tcsj));
}


RPTR(GrandHashSet) GrandHashSet::make (Int32 nNodes){
	RETURN_CONSTRUCT(GrandHashSet,(nNodes, tcsj));
}
/* adding-removing */


void GrandHashSet::introduce (APTR(Heaper) aHeaper){
	UInt32 hash;
	SPTR(GrandNode) node;
	
	this->checkSteppers();
	if (aHeaper == NULL) {
		BLAST(NullInsertion);
	}
	hash = ExponentialHashMap::exponentialMap(aHeaper->hashForEqual());
	node = CAST(GrandNode,grandNodes->fetch(hash / nodeIndexShift));
	if (node->fetch(aHeaper, hash) != NULL) {
		BLAST(AlreadyInSet);
	} else {
		SPTR(GrandEntry) newEntry;
		
		BEGIN_CONSISTENT(6) {
			newEntry = GrandSetEntry::make (aHeaper, hash);
			node->store(newEntry);
		} END_CONSISTENT;
	}
	myTally->increment();
	this->considerNeedForDoubling();
	this->invalidateCache();
}


void GrandHashSet::remove (APTR(Heaper) aHeaper){
	if (this->hasMember(aHeaper) == NULL) {
		BLAST(NotInSet);
	} else {
		this->wipe(aHeaper);
	}
}


void GrandHashSet::store (APTR(Heaper) aHeaper){
	UInt32 hash;
	SPTR(GrandNode) node;
	SPTR(GrandEntry) newEntry;
	BooleanVar test;
	
	this->checkSteppers();
	if (aHeaper == NULL) {
		BLAST(NullInsertion);
	}
	hash = ExponentialHashMap::exponentialMap(aHeaper->hashForEqual());
	node = CAST(GrandNode,grandNodes->fetch(hash / nodeIndexShift));
	test = node->fetch(aHeaper, hash) == NULL;
	BEGIN_CONSISTENT(6) {
		newEntry = GrandSetEntry::make (aHeaper, hash);
		node->store(newEntry);
	} END_CONSISTENT;
	if (test) {
		myTally->increment();
		this->considerNeedForDoubling();
	}
	this->invalidateCache();
}


void GrandHashSet::wipe (APTR(Heaper) aHeaper){
	UInt32 hash;
	SPTR(GrandNode) node;
	
	this->checkSteppers();
	hash = ExponentialHashMap::exponentialMap(aHeaper->hashForEqual());
	node = CAST(GrandNode,grandNodes->fetch(hash / nodeIndexShift));
	if (node->fetch(aHeaper, hash) != NULL) {
		node->wipe(aHeaper, hash);
		myTally->decrement();
	}
}
/* accessing */


IntegerVar GrandHashSet::count (){
	return myTally->count();
}


BooleanVar GrandHashSet::hasMember (APTR(Heaper) aHeaper){
	UInt32 hash;
	SPTR(Heaper) result;
	
	hash = ExponentialHashMap::exponentialMap(aHeaper->hashForEqual());
	/* (cacheKey ~~ NULL and: [cacheHash == hash and: [cacheKey 
		isEqual: key]]) ifTrue: [ ^ cacheValue ]. */
	result = CAST(GrandNode,grandNodes->fetch(hash / nodeIndexShift))->fetch(aHeaper, hash);
	/* result ~~ NULL ifTrue:
			[cacheHash _ hash.
			 cacheKey _ key.
			 cacheValue _ result]. */
	return result != NULL;
}
/* testing */


BooleanVar GrandHashSet::isEmpty (){
	return myTally->count() == IntegerVar0;
}
/* conversion */


RPTR(ImmuSet) GrandHashSet::asImmuSet (){
	BLAST(WILL_NOT_IMPLEMENT);
	return NULL;
}


RPTR(MuSet) GrandHashSet::asMuSet (){
	BLAST(WILL_NOT_IMPLEMENT);
	return NULL;
}
/* creation */


RPTR(ScruSet) GrandHashSet::copy (){
	SPTR(MuSet) newSet;
	
	newSet = GrandHashSet::make (numNodes);
	BEGIN_FOR_EACH(Heaper,e,(this->stepper())) {
		newSet->store(e);
	} END_FOR_EACH;
	WPTR(ScruSet) 	returnValue;
	returnValue = newSet;
	return returnValue;
}
/* printing */


void GrandHashSet::printOn (ostream& aStream){
	aStream << "GrandHashSet(" << this->count() << " entries over " << numNodes << " nodes)";
}


void GrandHashSet::printOnWithSimpleSyntax (
		ostream& oo, 
		char * open, 
		char * sep, 
		char * close)
{
	SPTR(Stepper) stomp;
	
	oo << open;
	if (this->isEmpty()) {
		oo << "empty";
	} else {
		stomp = this->stepper();
		while (stomp->hasValue()) {
			oo << stomp->fetch();
			stomp->step();
			if (stomp->hasValue()) {
				oo << sep;
			}
		}
		{stomp->destroy();  stomp = NULL /* don't want stale (S/CHK)PTRs */;}
	}
	oo << close;
}
/* enumerating */


RPTR(Stepper) GrandHashSet::stepper (){
	RETURN_CONSTRUCT(GrandHashSetStepper,(this, tcsj));
}
/* protected: creation */


GrandHashSet::GrandHashSet (Int32 nNodes, TCSJ) {
	SPTR(GrandNode) aNode;
	
	numNodes = nNodes;
	nodeIndexShift = ExponentialHashMap::hashBits() / numNodes;
	grandNodes = PtrArray::nulls(numNodes);
	BEGIN_CONSISTENT(2 * numNodes + 3) {
		{
			Int32 LoopFinal = numNodes;
			Int32 i = Int32Zero;
			for (;;) {
				if (i >= LoopFinal){
					break;
				}
				{
					aNode = GrandNode::make ();
					grandNodes->store(i, aNode);
				}
				i += 1;
			}
		}
		myTally = Counter::make ();
		myDoublingFrontIndex = Counter::make ();
		myDoublingPasses = Counter::make ();
	} END_CONSISTENT;
	myOutstandingSteppers = IntegerVarZero;
	this->invalidateCache();
}


void GrandHashSet::destruct (){
	SPTR(Heaper) temp;
	
	this->checkSteppers();
	BEGIN_CONSISTENT(numNodes) {
		{
			UInt32 LoopFinal = numNodes;
			UInt32 i = UInt32Zero;
			for (;;) {
				if (i >= LoopFinal){
					break;
				}
				{
					if ((temp = grandNodes->fetch(i)) != NULL) {
						{temp->destroy();  temp = NULL /* don't want stale (S/CHK)PTRs */;}
					}
				}
				i += 1;
			}
		}
	} END_CONSISTENT;
	this->MuSet::destruct();
}
/* private: housekeeping */


void GrandHashSet::considerNeedForDoubling (){
	/* Compute location of doubling front from tally.  If front 
	crosses a node boundary */
	/*  and that node has index higher than doublingFrontIndex 
	then double that node. */
	/*  Then increase doublingFrontIndex.  If the front has hit 
	the end of the table index */
	/*  reset it to zero.  This allows elements to be wiped from 
	the table without causing */
	/*  extra node doubling to occur on later insertions.  This 
	aims for 80% max table */
	/* loading using an approximation of the formula given in the 
	Fagin paper. */
	
	Int32 desiredDoublingIndex;
	IEEEDoubleVar x;
	Int32 dfi;
	
	/* Magic number */
	x = 0.05 * numNodes * (1 << myDoublingPasses->count().asLong()) * GrandNode::primaryPageSize();
	/* - 1 */
	desiredDoublingIndex = (Int32) ((IEEE32) myTally->count().asLong() / x);
	dfi = myDoublingFrontIndex->count().asLong();
	if (desiredDoublingIndex >= dfi + 1) {
		if (grandNodes->fetch(dfi) != NULL) {
			GrandNodeDoubler::make (CAST(GrandNode,grandNodes->fetch(dfi)))->schedule();
		}
		dfi = myDoublingFrontIndex->increment().asLong();
	}
	if (dfi >= numNodes) {
		myDoublingFrontIndex->setCount(IntegerVar0);
		myDoublingPasses->increment();
	}
}


void GrandHashSet::invalidateCache (){
	cacheValue = NULL;
}
/* receiver */


void GrandHashSet::restartGrandHashSet (APTR(Rcvr) /* trans *//* = NULL*/){
	/* re-initialize the non-persistent part */
	
	cacheValue = NULL;
	myOutstandingSteppers = IntegerVar0;
}
/* private: friendly */


RPTR(GrandNode) GrandHashSet::nodeAt (IntegerVar idx){
	return CAST(GrandNode,grandNodes->fetch(idx.asLong()));
}


IntegerVar GrandHashSet::nodeCount (){
	return numNodes;
}
/* private: enumerating */


void GrandHashSet::fewerSteppers (){
	myOutstandingSteppers -= 1;
	if (myOutstandingSteppers < IntegerVar0) {
		BLAST(TooManySteppersReleased);
	}
}


RPTR(Stepper) GrandHashSet::immuStepper (){
	/* Hack !!!! */
	
	/* This will have to be fixed if GrandHashSet::stepper ever 
	makes a copy */
	WPTR(Stepper) 	returnValue;
	returnValue = this->stepper();
	return returnValue;
}


void GrandHashSet::moreSteppers (){
	myOutstandingSteppers += 1;
}



/* ************************************************************************ *
 * 
 *                    Class GrandHashTable 
 *
 * ************************************************************************ */



/* Initializers for GrandHashTable */


BEGIN_INIT_TIME(GrandHashTable,initTimeNonInherited) {
	REQUIRES (ExponentialHashMap);
} END_INIT_TIME(GrandHashTable,initTimeNonInherited);



/* Initializers for GrandHashTable */



/* pseudoConstructors */


RPTR(GrandHashTable) GrandHashTable::make (APTR(CoordinateSpace) cs){
	/* A Very big table */
	RETURN_CONSTRUCT(GrandHashTable,(cs, 32));
}


RPTR(GrandHashTable) GrandHashTable::make (APTR(CoordinateSpace) cs, Int32 nNodes){
	RETURN_CONSTRUCT(GrandHashTable,(cs, nNodes));
}
/* adding-removing */


RPTR(Heaper) GrandHashTable::store (APTR(Position) aKey, APTR(Heaper) aHeaper){
	UInt32 hash;
	SPTR(GrandNode) node;
	SPTR(GrandEntry) newEntry;
	SPTR(Heaper) old;
	
	this->checkSteppers();
	if (aHeaper == NULL) {
		BLAST(NullInsertion);
	}
	hash = ExponentialHashMap::exponentialMap(aKey->hashForEqual());
	node = CAST(GrandNode,grandNodes->fetch(hash / nodeIndexShift));
	old = node->fetch(aKey, hash);
	BEGIN_CONSISTENT(1) {
		newEntry = 
				GrandTableEntry::make (aHeaper, aKey, hash);
	} END_CONSISTENT;
	node->store(newEntry);
	if (old == NULL) {
		myTally->increment();
		this->considerNeedForDoubling();
	}
	this->invalidateCache();
	WPTR(Heaper) 	returnValue;
	returnValue = old;
	return returnValue;
}


BooleanVar GrandHashTable::wipe (APTR(Position) aKey){
	UInt32 hash;
	SPTR(GrandNode) node;
	
	this->checkSteppers();
	hash = ExponentialHashMap::exponentialMap(aKey->hashForEqual());
	node = CAST(GrandNode,grandNodes->fetch(hash / nodeIndexShift));
	if (node->fetch(aKey, hash) != NULL) {
		node->wipe(aKey, hash);
		myTally->decrement();
		return TRUE;
	}
	return FALSE;
}
/* accessing */


RPTR(CoordinateSpace) GrandHashTable::coordinateSpace (){
	return (CoordinateSpace*) myCs;
}


IntegerVar GrandHashTable::count (){
	return myTally->count();
}


RPTR(XnRegion) GrandHashTable::domain (){
	SPTR(XnRegion) result;
	SPTR(TableStepper) stepper;
	
	result = this->coordinateSpace()->emptyRegion();
	BEGIN_FOR_EACH(Heaper,elem,(stepper = CAST(TableStepper,this->stepper()))) {
		result = result->with(stepper->position());
	} END_FOR_EACH;
	WPTR(XnRegion) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(Heaper) GrandHashTable::fetch (APTR(Position) key){
	UInt32 hash;
	SPTR(Heaper) result;
	
	hash = ExponentialHashMap::exponentialMap(key->hashForEqual());
	/* (cacheKey ~~ NULL 
			  and: [cacheHash == hash 
			  and: [cacheKey isEqual: key]]) 
			  	ifTrue: [ ^ cacheValue ].  */
	result = CAST(GrandNode,grandNodes->fetch(hash / nodeIndexShift))->fetch(key, hash);
	/* result ~~ NULL ifTrue:
			[cacheHash _ hash.
			 cacheKey _ key.
			 cacheValue _ result]. */
	WPTR(Heaper) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(ScruTable) GrandHashTable::subTable (APTR(XnRegion) region){
	SPTR(GrandHashTable) newTable;
	SPTR(TableStepper) elements;
	
	newTable = GrandHashTable::make (myCs, 8);
	elements = this->stepper();
	BEGIN_FOR_EACH(Heaper,elemValue,(elements)) {
		if (region->hasMember(elements->position())) {
			newTable->store(elements->position(), elemValue);
		}
	} END_FOR_EACH;
	WPTR(ScruTable) 	returnValue;
	returnValue = newTable;
	return returnValue;
}
/* testing */


BooleanVar GrandHashTable::includesIntKey (IntegerVar aKey){
	return this->MuTable::includesIntKey(aKey);
}


BooleanVar GrandHashTable::includesKey (APTR(Position) aKey){
	return this->fetch(aKey) != NULL;
}


BooleanVar GrandHashTable::isEmpty (){
	return myTally->count() == IntegerVar0;
}
/* creation */


RPTR(ScruTable) GrandHashTable::copy (){
	SPTR(GrandHashTable) newTable;
	SPTR(TableStepper) s;
	
	newTable = GrandHashTable::make (myCs, numNodes);
	BEGIN_FOR_EACH(Heaper,e,(s = this->stepper())) {
		newTable->store(s->position(), e);
	} END_FOR_EACH;
	WPTR(ScruTable) 	returnValue;
	returnValue = newTable;
	return returnValue;
}


RPTR(ScruTable) GrandHashTable::emptySize (IntegerVar /* size */){
	WPTR(ScruTable) 	returnValue;
	returnValue = GrandHashTable::make (myCs);
	return returnValue;
}
/* printing */


void GrandHashTable::printOn (ostream& aStream){
	aStream << "GrandHashTable(" << this->count() << " entries over " << numNodes << " nodes)";
}
/* runs */


RPTR(XnRegion) GrandHashTable::runAt (APTR(Position) index){
	if (this->includesKey(index)) {
		WPTR(XnRegion) 	returnValue;
		returnValue = index->asRegion();
		return returnValue;
	} else {
		WPTR(XnRegion) 	returnValue;
		returnValue = myCs->emptyRegion();
		return returnValue;
	}
}


RPTR(XnRegion) GrandHashTable::runAtInt (IntegerVar index){
	WPTR(XnRegion) 	returnValue;
	returnValue = this->MuTable::runAtInt(index);
	return returnValue;
}
/* private: enumerating */


void GrandHashTable::fewerSteppers (){
	myOutstandingSteppers -= 1;
	if (myOutstandingSteppers < IntegerVar0) {
		BLAST(TooManySteppersReleased);
	}
}


void GrandHashTable::moreSteppers (){
	myOutstandingSteppers += 1;
}
/* enumerating */


RPTR(TableStepper) GrandHashTable::stepper (APTR(OrderSpec) /* order *//* = NULL*/){
	RETURN_CONSTRUCT(GrandHashTableStepper,(this, tcsj));
}
/* protected: creation */


GrandHashTable::GrandHashTable (APTR(CoordinateSpace) cs, Int32 nNodes) {
	SPTR(GrandNode) aNode;
	
	myCs = cs;
	numNodes = nNodes;
	nodeIndexShift = ExponentialHashMap::hashBits() / numNodes;
	grandNodes = PtrArray::nulls(numNodes);
	BEGIN_CONSISTENT(2 * numNodes + 3) {
		{
			Int32 LoopFinal = numNodes;
			Int32 i = Int32Zero;
			for (;;) {
				if (i >= LoopFinal){
					break;
				}
				{
					aNode = GrandNode::make ();
					grandNodes->store(i, aNode);
				}
				i += 1;
			}
		}
		myTally = Counter::make ();
		myDoublingFrontIndex = Counter::make ();
		myDoublingPasses = Counter::make ();
	} END_CONSISTENT;
	myOutstandingSteppers = IntegerVarZero;
	this->invalidateCache();
}


void GrandHashTable::destruct (){
	SPTR(Heaper) temp;
	
	BEGIN_CONSISTENT(numNodes) {
		{
			UInt32 LoopFinal = numNodes;
			UInt32 i = UInt32Zero;
			for (;;) {
				if (i >= LoopFinal){
					break;
				}
				{
					if ((temp = grandNodes->fetch(i)) != NULL) {
						{temp->destroy();  temp = NULL /* don't want stale (S/CHK)PTRs */;}
					}
				}
				i += 1;
			}
		}
	} END_CONSISTENT;
	this->MuTable::destruct();
}
/* private: housekeeping */


void GrandHashTable::considerNeedForDoubling (){
	/* Compute location of doubling front from tally.  If front 
	crosses a node boundary */
	/*  and that node has index higher than doublingFrontIndex 
	then double that node. */
	/*  Then increase doublingFrontIndex.  If the front has hit 
	the end of the table index */
	/*  reset it to zero.  This allows elements to be wiped from 
	the table without causing */
	/*  extra node doubling to occur on later insertions.  This 
	aims for 80% max table */
	/* loading using an approximation of the formula given in the 
	Fagin paper. */
	
	Int32 desiredDoublingIndex;
	IEEEDoubleVar x;
	Int32 dfi;
	
	/* Magic number */
	x = 0.05 * numNodes * (1 << myDoublingPasses->count().asLong()) * GrandNode::primaryPageSize();
	/* - 1 */
	desiredDoublingIndex = (Int32) ((IEEE32) myTally->count().asLong() / x);
	dfi = myDoublingFrontIndex->count().asLong();
	if (desiredDoublingIndex >= dfi + 1) {
		if (grandNodes->fetch(dfi) != NULL) {
			GrandNodeDoubler::make (CAST(GrandNode,grandNodes->fetch(dfi)))->schedule();
		}
		dfi = myDoublingFrontIndex->increment().asLong();
	}
	if (dfi >= numNodes) {
		myDoublingFrontIndex->setCount(IntegerVar0);
		myDoublingPasses->increment();
	}
}


void GrandHashTable::invalidateCache (){
	cacheKey = NULL;
}
/* hooks: */


void GrandHashTable::restartGrandHashTable (APTR(Rcvr) /* trans *//* = NULL*/){
	/* re-initialize the non-persistent part */
	
	cacheKey = NULL;
	myOutstandingSteppers = IntegerVar0;
}
/* private: friendly */


RPTR(GrandNode) GrandHashTable::nodeAt (IntegerVar idx){
	return CAST(GrandNode,grandNodes->fetch(idx.asLong()));
}


IntegerVar GrandHashTable::nodeCount (){
	return numNodes;
}
/* conversion */


RPTR(ImmuTable) GrandHashTable::asImmuTable (){
	BLAST(WILL_NOT_IMPLEMENT);
	return NULL;
}


RPTR(MuTable) GrandHashTable::asMuTable (){
	BLAST(WILL_NOT_IMPLEMENT);
	return NULL;
}



/* ************************************************************************ *
 * 
 *                    Class ExponentialHashMap 
 *
 * ************************************************************************ */



/* Initializers for ExponentialHashMap */

UInt32 ExponentialHashMap::HashBits = (1 << 30) - 1;
GPTR(ExponentialHashMap) ExponentialHashMap::TheExponentialMap = NULL;





BEGIN_INIT_TIME(ExponentialHashMap,initTimeNonInherited) {
	CONSTRUCT(ExponentialHashMap::TheExponentialMap,ExponentialHashMap,(256, ExponentialHashMap::HashBits + 1));
	
} END_INIT_TIME(ExponentialHashMap,initTimeNonInherited);



/* Initializers for ExponentialHashMap */






/* accessing */
/* mapping */


UInt32 ExponentialHashMap::of (UInt32 aHash){
	Int32 pieceIndex;
	
	if (aHash > domain) {
		BLAST(outOfDomain);
	}
	pieceIndex = aHash / dSize;
	return rBottoms->uIntAt(pieceIndex) + (aHash - dBottoms->uIntAt(pieceIndex)) * rSizes->uIntAt(pieceIndex) / dSize;
}
/* creation */


ExponentialHashMap::ExponentialHashMap (Int32 numPieces, UInt32 range) {
	UInt32 rBottom;
	
	domain = range;
	dSize = range / numPieces;
	/* Depends on image having UInt32 _ Integer. */
	rBottoms = UInt32Array::make (numPieces);
	rSizes = UInt32Array::make (numPieces);
	dBottoms = UInt32Array::make (numPieces);
	rBottom = UInt32Zero;
	{
		UInt32 LoopFinal = numPieces;
		UInt32 d = UInt32Zero;
		for (;;) {
			if (d >= LoopFinal){
				break;
			}
			{
				dBottoms->storeUInt(d, d * dSize);
				rBottoms->storeUInt(d, rBottom);
				rBottom = this->expFuncWithin((d + 1) * dSize, range);
				rSizes->storeUInt(d, rBottom - rBottoms->uIntAt(d));
			}
			d += 1;
		}
	}
}
/* private: calculation */


UInt32 ExponentialHashMap::expFuncWithin (UInt32 domElem, UInt32 range){
	return (Int32) (range * (pow(2.0, (IEEE32) domElem / (IEEE32) range) - 1));
}
/* testing */


UInt32 ExponentialHashMap::actualHashForEqual (){
	return Heaper::takeOop();
}



/* ************************************************************************ *
 * 
 *                    Class GrandDataPage 
 *
 * ************************************************************************ */


/* creation */


RPTR(GrandDataPage) GrandDataPage::make (
		Int32 nEntries, 
		APTR(GrandNode) node, 
		UInt32 lowHashBits)
{
	RETURN_CONSTRUCT(GrandDataPage,(nEntries, node, lowHashBits));
}
/* GrandDataPage behaves as a small hash table.
Linear hashing and the GrandOverflow structure are used to resolve collisions.
The shift argument to the various methods is the number of pages in the
parent node to indicate how many low bits of the hash are ignored. */


/* accessing */


RPTR(Heaper) GrandDataPage::fetch (
		APTR(Heaper) OR(Position) toMatch, 
		UInt32 aHash, 
		Int32 shift)
{
	Int32 localIndex;
	Int32 originalIndex;
	SPTR(GrandEntry) entry;
	
	localIndex = originalIndex = aHash / shift % numEntries;
	entry = CAST(GrandEntry,entries->fetch(localIndex));
	while (entry != NULL) {
		if (aHash == entry->hashForEqual()) {
			if (entry->compare(toMatch)) {
				WPTR(Heaper) 	returnValue;
				returnValue = entry->value();
				return returnValue;
			}
		}
		localIndex = (localIndex + 1) % numEntries;
		entry = CAST(GrandEntry,entries->fetch(localIndex));
		if (localIndex == originalIndex) {
			/* break */
			entry = NULL;
		}
	}
	if (overflow != NULL) {
		WPTR(Heaper) 	returnValue;
		returnValue = overflow->fetch(toMatch, aHash);
		return returnValue;
	}
	return NULL;
}


void GrandDataPage::store (APTR(GrandEntry) newEntry, Int32 shift){
	UInt32 localIndex;
	UInt32 originalIndex;
	WPTR(GrandEntry) entry;
	
	localIndex = originalIndex = newEntry->hashForEqual() / shift % numEntries;
	entry = CAST(GrandEntry,entries->fetch(localIndex));
	while (entry != NULL) {
		if (newEntry->hashForEqual() == entry->hashForEqual()) {
			/* Note that this does not delete the contents */
			if (newEntry->matches(entry)) {
				BEGIN_CONSISTENT(1) {
					{entry->destroy();  entry = NULL /* don't want stale (S/CHK)PTRs */;}
					entries->store(localIndex, newEntry);
					this->diskUpdate();
				} END_CONSISTENT;
				return;
				
			}
		}
		localIndex = (localIndex + 1) % numEntries;
		/* This page is now full */
		if (localIndex == originalIndex) {
			if (overflow == NULL) {
				BEGIN_CONSISTENT(4) {
					overflow = myGroup->getOverflow()->store(newEntry);
					this->diskUpdate();
				} END_CONSISTENT;
			} else {
				overflow->store(newEntry);
			}
			return;
			
		}
		entry = CAST(GrandEntry,entries->fetch(localIndex));
	}
	/* Found empty slot. */
	BEGIN_CONSISTENT(1) {
		entries->store(localIndex, newEntry);
		this->diskUpdate();
	} END_CONSISTENT;
}


void GrandDataPage::wipe (
		APTR(Heaper) OR(Position) toMatch, 
		UInt32 aHash, 
		Int32 shift)
{
	Int32 localIndex;
	Int32 originalIndex;
	WPTR(GrandEntry) entry;
	
	localIndex = originalIndex = aHash / shift % numEntries;
	entry = CAST(GrandEntry,entries->fetch(localIndex));
	while (entry != NULL) {
		if (aHash == entry->hashForEqual()) {
			if (entry->compare(toMatch)) {
				BEGIN_CONSISTENT(2) {
					{entry->destroy();  entry = NULL /* don't want stale (S/CHK)PTRs */;}
					/* Note that this does not 
						delete the contents */
					entries->store(localIndex, NULL);
					this->repack(shift);
					this->diskUpdate();
				} END_CONSISTENT;
				return;
				
			}
		}
		localIndex = (localIndex + 1) % numEntries;
		entry = CAST(GrandEntry,entries->fetch(localIndex));
		/* break */
		if (localIndex == originalIndex) {
			entry = NULL;
		}
	}
	if (overflow != NULL) {
		overflow->wipe(toMatch, aHash);
	}
}
/* protected: creation */


GrandDataPage::GrandDataPage (
		Int32 nEntries, 
		APTR(GrandNode) node, 
		UInt32 lowHashBits) 
{
	myLowHashBits = lowHashBits;
	numEntries = nEntries;
	entries = PtrArray::nulls(numEntries);
	myGroup = node;
	overflow = NULL;
	this->newShepherd();
	this->remember();
}
/* private: private */


void GrandDataPage::repack (Int32 shift){
	/* This repacks the entry table after a wipe to keep the 
	table consistent with */
	/* the linear hash collision resolution technique. */
	
	SPTR(PtrArray) OF1(GrandEntry) newEntries;
	SPTR(GrandEntry) entry;
	Int32 preferedIndex;
	
	newEntries = PtrArray::nulls(numEntries);
	{
		Int32 LoopFinal = numEntries;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if ((entry = CAST(GrandEntry,entries->fetch(i))) != NULL) {
					preferedIndex = entry->hashForEqual() / shift % numEntries;
					if (newEntries->fetch(preferedIndex) != NULL) {
						while (newEntries->fetch(preferedIndex) != NULL) {
							preferedIndex = (preferedIndex + 1) % numEntries;
						}
					}
					newEntries->store(preferedIndex, entry);
				}
			}
			i += 1;
		}
	}
	{entries->destroy();  entries = NULL /* don't want stale (S/CHK)PTRs */;}
	entries = newEntries;
}
/* node doubling */


RPTR(GrandDataPage) GrandDataPage::makeDouble (Int32 newNumPages){
	/* Create a new page with all entries of current page that have a */
	/* '1' in the new lowest significant bit of the hash. */
	/* Retain all '0' entries in this page. */
	
	SPTR(GrandDataPage) newPage;
	WPTR(GrandEntry) oldEntry;
	Int32 oldNumPages;
	
	BEGIN_CONSISTENT(2) {
		oldNumPages = newNumPages / 2;
		newPage = 
				GrandDataPage::make (numEntries, myGroup, myLowHashBits + oldNumPages);
		overflow = NULL;
		/* Reset overflow structure. Old one is held by parent node. */
		{
			Int32 LoopFinal = numEntries;
			Int32 i = Int32Zero;
			for (;;) {
				if (i >= LoopFinal){
					break;
				}
				{
					oldEntry = CAST(GrandEntry,entries->fetch(i));
					/* This test is necessary 
						since page to be doubled may 
						not be full. */
					if (oldEntry != NULL) {
						if ((oldEntry->hashForEqual() / oldNumPages & 1) == 1) {
							newPage->store(oldEntry, newNumPages);
							entries->store(i, NULL);
						}
					}
				}
				i += 1;
			}
		}
		/* Now let pages sort themselves out. */
		this->repack(newNumPages);
		this->diskUpdate();
	} END_CONSISTENT;
	WPTR(GrandDataPage) 	returnValue;
	returnValue = newPage;
	return returnValue;
}
/* special */


IEEEDoubleVar GrandDataPage::loadFactor (){
	Int32 loadCount;
	
	loadCount = Int32Zero;
	{
		Int32 LoopFinal = numEntries;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (entries->fetch(i) != NULL) {
					loadCount += 1;
				}
			}
			i += 1;
		}
	}
	return (IEEE32) loadCount / (IEEE32) numEntries;
}


UInt32 GrandDataPage::lowHashBits (){
	return myLowHashBits;
}
/* printing */


void GrandDataPage::printOn (ostream& aStream){
	Int32 count;
	
	aStream << "GrandDataPage(" << numEntries << " slots, ";
	count = Int32Zero;
	{
		Int32 LoopFinal = numEntries;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (entries->fetch(i) != NULL) {
					count += 1;
				}
			}
			i += 1;
		}
	}
	aStream << count << " full";
	if (overflow != NULL) {
		aStream << " and overflow";
	}
	aStream << ")";
}
/* protected: destruction */


void GrandDataPage::dismantle (){
	BEGIN_CONSISTENT(1 + numEntries) {
		SPTR(Heaper) entry;
		
		if (entries != NULL) {
			{
				Int32 LoopFinal = numEntries;
				Int32 i = Int32Zero;
				for (;;) {
					if (i >= LoopFinal){
						break;
					}
					{
						entry = entries->fetch(i);
						if (entry != NULL) {
							{entry->destroy();  entry = NULL /* don't want stale (S/CHK)PTRs */;}
							entries->store(i, NULL);
						}
					}
					i += 1;
				}
			}
			{entries->destroy();  entries = NULL /* don't want stale (S/CHK)PTRs */;}
			entries = NULL;
		}
		this->Abraham::dismantle();
	} END_CONSISTENT;
}
/* testing */


UInt32 GrandDataPage::contentsHash (){
	return this->Abraham::contentsHash() ^ IntegerPos::integerHash(myLowHashBits) ^ IntegerPos::integerHash(numEntries) ^ entries->contentsHash() ^ overflow->hashForEqual() ^ myGroup->hashForEqual();
}


BooleanVar GrandDataPage::isEmpty (){
	{
		UInt32 LoopFinal = numEntries;
		UInt32 i = UInt32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (entries->fetch(i) != NULL) {
					return FALSE;
				}
			}
			i += 1;
		}
	}
	return TRUE;
}
/* private: friendly */


RPTR(GrandEntry) GrandDataPage::entryAt (IntegerVar idx){
	return CAST(GrandEntry,entries->fetch(idx.asLong()));
}


IntegerVar GrandDataPage::entryCount (){
	return numEntries;
}



/* ************************************************************************ *
 * 
 *                    Class GrandDataPageStepper 
 *
 * ************************************************************************ */


/* operations */


RPTR(GrandEntry) GrandDataPageStepper::entry (){
	return (GrandEntry * ) page->entryAt(entryIndex);
}


WPTR(Heaper) GrandDataPageStepper::fetch (){
	BLAST(SHOULD_NOT_IMPLEMENT);
	return NULL;
}


BooleanVar GrandDataPageStepper::hasValue (){
	return entryIndex < page->entryCount();
}


void GrandDataPageStepper::step (){
	entryIndex += 1;
	this->verifyEntry();
}
/* private: create */


GrandDataPageStepper::GrandDataPageStepper (APTR(GrandDataPage) aPage, IntegerVar index) {
	page = aPage;
	entryIndex = index;
	this->verifyEntry();
}
/* private: private */


void GrandDataPageStepper::verifyEntry (){
	for (;;) {	BooleanVar crutch_Flag;
		/* entryIndex < page->entryCount() && page->entryAt(entryIndex) == NULL */
		
		crutch_Flag = entryIndex < page->entryCount();
		if(crutch_Flag) {
			crutch_Flag = page->entryAt(entryIndex) == NULL;
		}
		if (crutch_Flag) {
			entryIndex += 1;
		} else {
			break;
		}
	}
}
/* create */


RPTR(Stepper) GrandDataPageStepper::copy (){
	RETURN_CONSTRUCT(GrandDataPageStepper,(page, entryIndex));
}


GrandDataPageStepper::GrandDataPageStepper (APTR(GrandDataPage) aPage, TCSJ) {
	page = aPage;
	entryIndex = IntegerVar0;
	this->verifyEntry();
}



/* ************************************************************************ *
 * 
 *                    Class GrandEntry 
 *
 * ************************************************************************ */


/* GrandEntries probably want to not be remembered right when they are created,
and remembered when they are finally put into their place in the GrandDataPages
or GrandOverflows */


/* accessing */


RPTR(Heaper) GrandEntry::value (){
	if (objectInternal == NULL) {
		BLAST(NotInTable);
	}
	return (Heaper*) objectInternal;
}
/* protected: creation */


GrandEntry::GrandEntry (APTR(Heaper) value, UInt32 hash) 
	: Abraham(hash, tcsj) {
	if (value == NULL) {
		BLAST(NullInsertion);
	}
	
	objectInternal = value;
}
/* deferred: testing */
/* testing */


UInt32 GrandEntry::contentsHash (){
	return this->Abraham::contentsHash() ^ IntegerPos::integerHash(this->hashForEqual()) ^ objectInternal->hashForEqual();
}



/* ************************************************************************ *
 * 
 *                    Class   GrandSetEntry 
 *
 * ************************************************************************ */


/* create */


RPTR(GrandEntry) GrandSetEntry::make (APTR(Heaper) value, UInt32 hash){
	RETURN_CONSTRUCT(GrandSetEntry,(value, hash));
}
/* testing */


BooleanVar GrandSetEntry::compare (APTR(Heaper) OR(Position) anObj){
	return this->value()->isEqual(anObj);
}


BooleanVar GrandSetEntry::matches (APTR(GrandEntry) anEntry){
	return this->value()->isEqual(anEntry->value());
}
/* protected: creation */


GrandSetEntry::GrandSetEntry (APTR(Heaper) value, UInt32 hash) 
	: GrandEntry(value, hash) {
	this->newShepherd();
	this->remember();
}
/* printing */


void GrandSetEntry::printOn (ostream& aStream){
	aStream << "GrandSetEntry(hash=" << this->hashForEqual() << ", value=" << this->value() << ")";
}



/* ************************************************************************ *
 * 
 *                    Class   GrandTableEntry 
 *
 * ************************************************************************ */


/* create */


RPTR(GrandEntry) GrandTableEntry::make (
		APTR(Heaper) value, 
		APTR(Position) key, 
		UInt32 hash)
{
	RETURN_CONSTRUCT(GrandTableEntry,(value, key, hash));
}
/* printing */


void GrandTableEntry::printOn (ostream& aStream){
	aStream << "GrandTableEntry(hash=" << this->hashForEqual() << ", key=" << keyInternal << ", value=" << this->value() << ")";
}
/* accessing */


RPTR(Position) GrandTableEntry::key (){
	return (Position*) keyInternal;
}


RPTR(Position) GrandTableEntry::position (){
	return (Position*) keyInternal;
}
/* testing */


BooleanVar GrandTableEntry::compare (APTR(Heaper) OR(Position) anObj){
	return keyInternal->isEqual(anObj);
}


UInt32 GrandTableEntry::contentsHash (){
	return this->GrandEntry::contentsHash() ^ keyInternal->hashForEqual();
}


BooleanVar GrandTableEntry::matches (APTR(GrandEntry) anEntry){
	return keyInternal->isEqual(CAST(GrandTableEntry,anEntry)->position());
}
/* protected: creation */


GrandTableEntry::GrandTableEntry (
		APTR(Heaper) value, 
		APTR(Position) key, 
		UInt32 hash) 

	: GrandEntry(value, hash) {
	keyInternal = key;
	this->newShepherd();
	this->remember();
}



/* ************************************************************************ *
 * 
 *                    Class GrandHashSetStepper 
 *
 * ************************************************************************ */


/* private: private */


void GrandHashSetStepper::verifyEntry (){
	for (;;) {	BooleanVar crutch_Flag;
		/* nodeIndex < set->nodeCount() && set->nodeAt(nodeIndex)->isEmpty() */
		
		crutch_Flag = nodeIndex < set->nodeCount();
		if(crutch_Flag) {
			crutch_Flag = set->nodeAt(nodeIndex)->isEmpty();
		}
		if (crutch_Flag) {
			nodeIndex += 1;
		} else {
			break;
		}
	}
	if (nodeIndex < set->nodeCount()) {
		CONSTRUCT(nodeStepper,GrandNodeStepper,(set->nodeAt(nodeIndex), tcsj));
	}
}
/* operations */


WPTR(Heaper) GrandHashSetStepper::fetch (){
	{	BooleanVar crutch_Flag;
		/* nodeStepper != NULL && nodeStepper->hasValue() */
		
		crutch_Flag = nodeStepper != NULL;
		if(crutch_Flag) {
			crutch_Flag = nodeStepper->hasValue();
		}
		if (crutch_Flag) {
			WPTR(Heaper) 	returnValue;
			returnValue = nodeStepper->entry()->value();
			return returnValue;
		} else {
			return NULL;
		}
	}
}


BooleanVar GrandHashSetStepper::hasValue (){
	{	BooleanVar crutch_Flag;
		/* nodeIndex < set->nodeCount() && nodeStepper->hasValue() */
		
		crutch_Flag = nodeIndex < set->nodeCount();
		if(crutch_Flag) {
			crutch_Flag = nodeStepper->hasValue();
		}
		return crutch_Flag;
	}
}


void GrandHashSetStepper::step (){
	nodeStepper->step();
	if (!nodeStepper->hasValue()) {
		{nodeStepper->destroy();  nodeStepper = NULL /* don't want stale (S/CHK)PTRs */;}
		nodeStepper = NULL;
		nodeIndex += 1;
		this->verifyEntry();
	}
}
/* protected: create */


GrandHashSetStepper::GrandHashSetStepper (
		APTR(GrandHashSet) aSet, 
		APTR(GrandNodeStepper) aNodeStepper, 
		IntegerVar aNodeIndex) 
{
	set = aSet;
	set->moreSteppers();
	nodeStepper = aNodeStepper;
	nodeIndex = aNodeIndex;
}


void GrandHashSetStepper::destruct (){
	if (nodeStepper != NULL) {
		{nodeStepper->destroy();  nodeStepper = NULL /* don't want stale (S/CHK)PTRs */;}
	}
	set->fewerSteppers();
	this->Stepper::destruct();
}
/* create */


RPTR(Stepper) GrandHashSetStepper::copy (){
	RETURN_CONSTRUCT(GrandHashSetStepper,(set, nodeStepper, nodeIndex));
}


GrandHashSetStepper::GrandHashSetStepper (APTR(GrandHashSet) aSet, TCSJ) {
	set = aSet;
	set->moreSteppers();
	nodeIndex = IntegerVar0;
	nodeStepper = NULL;
	this->verifyEntry();
}



/* ************************************************************************ *
 * 
 *                    Class GrandHashTableStepper 
 *
 * ************************************************************************ */


/* private: private */


void GrandHashTableStepper::verifyEntry (){
	for (;;) {	BooleanVar crutch_Flag;
		/* nodeIndex < table->nodeCount() && table->nodeAt(nodeIndex)->isEmpty() */
		
		crutch_Flag = nodeIndex < table->nodeCount();
		if(crutch_Flag) {
			crutch_Flag = table->nodeAt(nodeIndex)->isEmpty();
		}
		if (crutch_Flag) {
			nodeIndex += 1;
		} else {
			break;
		}
	}
	if (nodeIndex < table->nodeCount()) {
		CONSTRUCT(nodeStepper,GrandNodeStepper,(table->nodeAt(nodeIndex), tcsj));
	}
}
/* operations */


WPTR(Heaper) GrandHashTableStepper::fetch (){
	{	BooleanVar crutch_Flag;
		/* nodeStepper != NULL && nodeStepper->hasValue() */
		
		crutch_Flag = nodeStepper != NULL;
		if(crutch_Flag) {
			crutch_Flag = nodeStepper->hasValue();
		}
		if (crutch_Flag) {
			WPTR(Heaper) 	returnValue;
			returnValue = nodeStepper->entry()->value();
			return returnValue;
		} else {
			return NULL;
		}
	}
}


BooleanVar GrandHashTableStepper::hasValue (){
	return nodeStepper != NULL;
}


void GrandHashTableStepper::step (){
	nodeStepper->step();
	if (!nodeStepper->hasValue()) {
		{nodeStepper->destroy();  nodeStepper = NULL /* don't want stale (S/CHK)PTRs */;}
		nodeStepper = NULL;
		nodeIndex += 1;
		this->verifyEntry();
	}
}
/* special */


RPTR(Position) GrandHashTableStepper::position (){
	WPTR(Position) 	returnValue;
	returnValue = CAST(GrandTableEntry,nodeStepper->entry())->position();
	return returnValue;
}
/* create */


RPTR(Stepper) GrandHashTableStepper::copy (){
	RETURN_CONSTRUCT(GrandHashTableStepper,(table, nodeStepper, nodeIndex));
}


GrandHashTableStepper::GrandHashTableStepper (APTR(GrandHashTable) aTable, TCSJ) {
	table = aTable;
	table->moreSteppers();
	nodeIndex = IntegerVar0;
	nodeStepper = NULL;
	this->verifyEntry();
}
/* protected: creation */


GrandHashTableStepper::GrandHashTableStepper (
		APTR(GrandHashTable) aTable, 
		APTR(GrandNodeStepper) aNodeStepper, 
		IntegerVar aNodeIndex) 
{
	table = aTable;
	table->moreSteppers();
	nodeStepper = aNodeStepper;
	nodeIndex = aNodeIndex;
}


void GrandHashTableStepper::destruct (){
	if (nodeStepper != NULL) {
		{nodeStepper->destroy();  nodeStepper = NULL /* don't want stale (S/CHK)PTRs */;}
	}
	table->fewerSteppers();
	this->TableStepper::destruct();
}



/* ************************************************************************ *
 * 
 *                    Class GrandNode 
 *
 * ************************************************************************ */



/* Initializers for GrandNode */

Int32 GrandNode::OverflowPageSize = 8;


/* Initializers for GrandNode */



/* create */


RPTR(GrandNode) GrandNode::make (){
	RETURN_CONSTRUCT(GrandNode,());
}
/* static functions */
/* oldOverflowRoot holds onto the overflow tree that was in place 
when a node doubling starts.
It allows an object stored to be found at any time during the doubling. */


/* accessing */


RPTR(Heaper) GrandNode::fetch (APTR(Heaper) OR(Position) toMatch, UInt32 aHash){
	SPTR(Heaper) result;
	
	result = 
			CAST(GrandDataPage,primaryPages->fetch(aHash % numPrimaries))->fetch(toMatch, aHash, numPrimaries);
	if (result != NULL) {
		WPTR(Heaper) 	returnValue;
		returnValue = result;
		return returnValue;
	}
	if (oldOverflowRoot != NULL) {
		WPTR(Heaper) 	returnValue;
		returnValue = oldOverflowRoot->fetch(toMatch, aHash);
		return returnValue;
	}
	return NULL;
}


void GrandNode::store (APTR(GrandEntry) newEntry){
	CAST(GrandDataPage,primaryPages->fetch(newEntry->hashForEqual() % numPrimaries))->store(newEntry, numPrimaries);
}


void GrandNode::wipe (APTR(Heaper) OR(Position) toMatch, UInt32 aHash){
	CAST(GrandDataPage,primaryPages->fetch(aHash % numPrimaries))->wipe(toMatch, aHash, numPrimaries);
	if (oldOverflowRoot != NULL) {
		oldOverflowRoot->wipe(toMatch, aHash);
	}
}
/* printing */


void GrandNode::printOn (ostream& aStream){
	aStream << "GrandNode(numPages=" << numPrimaries << ")";
}
/* protected: creation */


GrandNode::GrandNode () {
	SPTR(GrandDataPage) aPage;
	
	overflowRoot = NULL;
	oldOverflowRoot = NULL;
	numReinserters = Int32Zero;
	numPrimaries = 1;
	primaryPages = PtrArray::nulls(1);
	aPage = 
			GrandDataPage::make (GrandNode::primaryPageSize(), this, UInt32Zero);
	primaryPages->store(Int32Zero, aPage);
	this->newShepherd();
	this->remember();
}


void GrandNode::dismantle (){
	BEGIN_CONSISTENT(2 + numPrimaries) {
		SPTR(Heaper) page;
		
		if (primaryPages != NULL) {
			{
				Int32 LoopFinal = numPrimaries;
				Int32 i = Int32Zero;
				for (;;) {
					if (i >= LoopFinal){
						break;
					}
					{
						page = primaryPages->fetch(i);
						if (page != NULL) {
							{page->destroy();  page = NULL /* don't want stale (S/CHK)PTRs */;}
						}
					}
					i += 1;
				}
			}
			{primaryPages->destroy();  primaryPages = NULL /* don't want stale (S/CHK)PTRs */;}
		}
		if (overflowRoot != NULL) {
			{overflowRoot->destroy();  overflowRoot = NULL /* don't want stale (S/CHK)PTRs */;}
		}
		if (oldOverflowRoot != NULL) {
			{oldOverflowRoot->destroy();  oldOverflowRoot = NULL /* don't want stale (S/CHK)PTRs */;}
		}
		this->Abraham::dismantle();
	} END_CONSISTENT;
}
/* node doubling */


void GrandNode::addReinserter (){
	BEGIN_CONSISTENT(1) {
		numReinserters += 1;
		this->diskUpdate();
	} END_CONSISTENT;
}


void GrandNode::doubleNode (){
	SPTR(GrandDataPage) newPage;
	Int32 newNumPrimaries;
	SPTR(PtrArray) OF1(GrandDataPage) newPrimaries;
	
	BEGIN_CONSISTENT(this->doubleNodeConsistency()) {
		newNumPrimaries = numPrimaries * 2;
		newPrimaries = PtrArray::nulls(newNumPrimaries);
		{
			Int32 LoopFinal = numPrimaries;
			Int32 i = Int32Zero;
			for (;;) {
				if (i >= LoopFinal){
					break;
				}
				{
					newPage = CAST(GrandDataPage,primaryPages->fetch(i))->makeDouble(newNumPrimaries);
					newPrimaries->store(i, primaryPages->fetch(i));
					newPrimaries->store(newPage->lowHashBits(), newPage);
				}
				i += 1;
			}
		}
		{primaryPages->destroy();  primaryPages = NULL /* don't want stale (S/CHK)PTRs */;}
		primaryPages = newPrimaries;
		numPrimaries = newNumPrimaries;
		/* At this point, the structure is consistent, but 
			still doesn't have the full benefit of the node
					doubling.  Inserts will be faster now, but 
			reinsertion of the overflow data is required for fetch
					to improve. */
		if (overflowRoot != NULL) {
			if (oldOverflowRoot != NULL) {
				BLAST(FallenBehindInNodeDoubling);
			}
			oldOverflowRoot = overflowRoot;
			overflowRoot = NULL;
			GrandNodeReinserter::make (this, oldOverflowRoot)->schedule();
		}
		this->diskUpdate();
	} END_CONSISTENT;
}


IntegerVar GrandNode::doubleNodeConsistency (){
	/* Known bug !!!! */
	
	/* Sometimes this is off by one in either direction */
	return 2 * numPrimaries + 2;
}


void GrandNode::removeReinserter (){
	BEGIN_CONSISTENT(1) {
		numReinserters -= 1;
		if (numReinserters == Int32Zero) {
			{oldOverflowRoot->destroy();  oldOverflowRoot = NULL /* don't want stale (S/CHK)PTRs */;}
			oldOverflowRoot = NULL;
		}
		this->diskUpdate();
	} END_CONSISTENT;
}
/* private: friendly access */


RPTR(GrandDataPage) GrandNode::pageAt (IntegerVar idx){
	return CAST(GrandDataPage,primaryPages->fetch(idx.asLong()));
}


IntegerVar GrandNode::pageCount (){
	return numPrimaries;
}
/* testing */


UInt32 GrandNode::contentsHash (){
	UInt32 result;
	
	result = this->Abraham::contentsHash() ^ primaryPages->contentsHash() ^ IntegerPos::integerHash(numPrimaries);
	if (overflowRoot != NULL) {
		result ^= overflowRoot->hashForEqual();
	}
	if (oldOverflowRoot != NULL) {
		result ^= oldOverflowRoot->hashForEqual();
	}
	return result;
}


BooleanVar GrandNode::isEmpty (){
	{
		UInt32 LoopFinal = numPrimaries;
		UInt32 i = UInt32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (!CAST(GrandDataPage,primaryPages->fetch(i))->isEmpty()) {
					return FALSE;
				}
			}
			i += 1;
		}
	}
	{	BooleanVar crutch_Flag;
		/* overflowRoot == NULL && oldOverflowRoot == NULL */
		
		crutch_Flag = overflowRoot == NULL;
		if(crutch_Flag) {
			crutch_Flag = oldOverflowRoot == NULL;
		}
		return crutch_Flag;
	}
}
/* overflow */


RPTR(GrandOverflow) GrandNode::fetchOldOverflow (){
	return (GrandOverflow*) oldOverflowRoot;
}


RPTR(GrandOverflow) GrandNode::fetchOverflow (){
	return (GrandOverflow*) overflowRoot;
}


RPTR(GrandOverflow) GrandNode::getOverflow (){
	if (overflowRoot == NULL) {
		BEGIN_CONSISTENT(2) {
			CONSTRUCT(overflowRoot,GrandOverflow,(GrandNode::OverflowPageSize, 1));
			this->diskUpdate();
		} END_CONSISTENT;
	}
	return (GrandOverflow*) overflowRoot;
}
/* special */


IEEEDoubleVar GrandNode::loadFactor (){
	IEEEDoubleVar loadSum;
	
	loadSum = 0.0;
	{
		Int32 LoopFinal = numPrimaries;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				loadSum += CAST(GrandDataPage,primaryPages->fetch(i))->loadFactor();
			}
			i += 1;
		}
	}
	return loadSum / numPrimaries;
}



/* ************************************************************************ *
 * 
 *                    Class GrandNodeDoubler 
 *
 * ************************************************************************ */


/* creation */


RPTR(GrandNodeDoubler) GrandNodeDoubler::make (APTR(GrandNode) gNode){
	BEGIN_CONSISTENT(1) {
		RETURN_CONSTRUCT(GrandNodeDoubler,(gNode, tcsj));
	} END_CONSISTENT;
}
/* GrandNodeDoubler performs the page splitting required for the 
extensible GrandHash<collection>s in a deferred fashion. */


/* protected: creation */


GrandNodeDoubler::GrandNodeDoubler (APTR(GrandNode) gNode, TCSJ) {
	myNode = gNode;
	this->newShepherd();
}
/* accessing */


BooleanVar GrandNodeDoubler::step (){
	if (myNode != NULL) {
		BEGIN_CONSISTENT(myNode->doubleNodeConsistency() + 2) {
			myNode->doubleNode();
			myNode = NULL;
			this->diskUpdate();
		} END_CONSISTENT;
	}
	return FALSE;
}



/* ************************************************************************ *
 * 
 *                    Class GrandNodeReinserter 
 *
 * ************************************************************************ */


/* creation */


RPTR(GrandNodeReinserter) GrandNodeReinserter::make (APTR(GrandNode) gNode, APTR(GrandOverflow) gOverflow){
	BEGIN_CONSISTENT(2) {
		RETURN_CONSTRUCT(GrandNodeReinserter,(gNode, gOverflow));
	} END_CONSISTENT;
}
/* GrandNodeReinserter moves the contents of the GrandOverflow 
structure into the newly doubled GrandNode. */


/* protected: creation */


GrandNodeReinserter::GrandNodeReinserter (APTR(GrandNode) gNode, APTR(GrandOverflow) gOverflow) {
	myNode = gNode;
	myOverflow = gOverflow;
	myNode->addReinserter();
	this->newShepherd();
}
/* accessing */


BooleanVar GrandNodeReinserter::step (){
	if (myNode != NULL) {
		BEGIN_CONSISTENT(myOverflow->reinsertEntriesConsistency() + 2) {
			myOverflow->reinsertEntries(myNode);
			myNode->removeReinserter();
			myNode = NULL;
			this->diskUpdate();
		} END_CONSISTENT;
	}
	return FALSE;
}



/* ************************************************************************ *
 * 
 *                    Class GrandNodeStepper 
 *
 * ************************************************************************ */


/* protected: creation */


GrandNodeStepper::GrandNodeStepper (
		APTR(GrandNode) aNode, 
		APTR(GrandDataPageStepper) curPageStepper, 
		IntegerVar curPageIndex, 
		APTR(GrandOverflowStepper) oflowStepper) 
{
	node = aNode;
	pageStepper = curPageStepper;
	pageIndex = curPageIndex;
	overflowStepper = oflowStepper;
}


void GrandNodeStepper::destruct (){
	if (pageStepper != NULL) {
		{pageStepper->destroy();  pageStepper = NULL /* don't want stale (S/CHK)PTRs */;}
	}
	if (overflowStepper != NULL) {
		{overflowStepper->destroy();  overflowStepper = NULL /* don't want stale (S/CHK)PTRs */;}
	}
	this->Stepper::destruct();
}
/* private: */


void GrandNodeStepper::verifyEntry (){
	for (;;) {	BooleanVar crutch_Flag;
		/* pageIndex < node->pageCount() && node->pageAt(pageIndex)->isEmpty() */
		
		crutch_Flag = pageIndex < node->pageCount();
		if(crutch_Flag) {
			crutch_Flag = node->pageAt(pageIndex)->isEmpty();
		}
		if (crutch_Flag) {
			pageIndex += 1;
		} else {
			break;
		}
	}
	if (pageIndex < node->pageCount()) {
		CONSTRUCT(pageStepper,GrandDataPageStepper,(node->pageAt(pageIndex), tcsj));
	} else {
		{	BooleanVar crutch_Flag;
			/* overflowStepper == NULL && node->fetchOverflow() != NULL */
			
			crutch_Flag = overflowStepper == NULL;
			if(crutch_Flag) {
				crutch_Flag = node->fetchOverflow() != NULL;
			}
			if (crutch_Flag) {
				CONSTRUCT(overflowStepper,GrandOverflowStepper,(node->fetchOverflow(), tcsj));
			} else {
				if (overflowStepper != NULL) {
					{overflowStepper->destroy();  overflowStepper = NULL /* don't want stale (S/CHK)PTRs */;}
				}
				overflowStepper = NULL;
				if (node->fetchOldOverflow() != NULL) {
					CONSTRUCT(overflowStepper,GrandOverflowStepper,(node->fetchOldOverflow(), tcsj));
				}
			}
		}
	}
}
/* operations */


RPTR(GrandEntry) GrandNodeStepper::entry (){
	if (overflowStepper != NULL) {
		WPTR(GrandEntry) 	returnValue;
		returnValue = overflowStepper->entry();
		return returnValue;
	} else {
		WPTR(GrandEntry) 	returnValue;
		returnValue = pageStepper->entry();
		return returnValue;
	}
}


WPTR(Heaper) GrandNodeStepper::fetch (){
	BLAST(SHOULD_NOT_IMPLEMENT);
	return NULL;
}


BooleanVar GrandNodeStepper::hasValue (){
	if (overflowStepper != NULL) {
		return overflowStepper->hasValue();
	} else {
		{	BooleanVar crutch_Flag;
			/* pageStepper != NULL && pageStepper->hasValue() */
			
			crutch_Flag = pageStepper != NULL;
			if(crutch_Flag) {
				crutch_Flag = pageStepper->hasValue();
			}
			return crutch_Flag;
		}
	}
}


void GrandNodeStepper::step (){
	if (overflowStepper != NULL) {
		overflowStepper->step();
	} else {
		pageStepper->step();
		if (!pageStepper->hasValue()) {
			{pageStepper->destroy();  pageStepper = NULL /* don't want stale (S/CHK)PTRs */;}
			pageStepper = NULL;
			pageIndex += 1;
			this->verifyEntry();
		}
	}
}
/* create */


RPTR(Stepper) GrandNodeStepper::copy (){
	RETURN_CONSTRUCT(GrandNodeStepper,(node, pageStepper, pageIndex, overflowStepper));
}


GrandNodeStepper::GrandNodeStepper (APTR(GrandNode) aNode, TCSJ) {
	node = aNode;
	pageIndex = IntegerVar0;
	pageStepper = NULL;
	overflowStepper = NULL;
	this->verifyEntry();
}



/* ************************************************************************ *
 * 
 *                    Class GrandOverflow 
 *
 * ************************************************************************ */



/* Initializers for GrandOverflow */

Int32 GrandOverflow::OTreeArity = 4;


/* Initializers for GrandOverflow */



/* This class has a comment
The instance variable depth actually holds the value OTreeArity ^ depth. */


/* accessing */


RPTR(Heaper) GrandOverflow::fetch (APTR(Heaper) OR(Position) toMatch, UInt32 aHash){
	Int32 localIndex;
	Int32 originalIndex;
	SPTR(GrandEntry) entry;
	UInt32 childIndex;
	
	localIndex = originalIndex = aHash / depth % numEntries;
	entry = CAST(GrandEntry,entries->fetch(localIndex));
	while (entry != NULL) {
		if (aHash == entry->hashForEqual()) {
			if (entry->compare(toMatch)) {
				WPTR(Heaper) 	returnValue;
				returnValue = entry->value();
				return returnValue;
			}
		}
		localIndex = (localIndex + 1) % numEntries;
		entry = CAST(GrandEntry,entries->fetch(localIndex));
		if (localIndex == originalIndex) {
			/* break from loop */
			entry = NULL;
		}
	}
	childIndex = aHash / depth % GrandOverflow::OTreeArity;
	if (children->fetch(childIndex) != NULL) {
		WPTR(Heaper) 	returnValue;
		returnValue = CAST(GrandOverflow,children->fetch(childIndex))->fetch(toMatch, aHash);
		return returnValue;
	}
	return NULL;
}


RPTR(GrandOverflow) GrandOverflow::store (APTR(GrandEntry) newEntry){
	Int32 localIndex;
	Int32 originalIndex;
	WPTR(GrandEntry) entry;
	
	localIndex = originalIndex = newEntry->hashForEqual() / depth % numEntries;
	entry = CAST(GrandEntry,entries->fetch(localIndex));
	while (entry != NULL) {
		if (newEntry->hashForEqual() == entry->hashForEqual()) {
			/* Note that this does not delete the contents */
			if (newEntry->matches(entry)) {
				BEGIN_CONSISTENT(2) {
					{entry->destroy();  entry = NULL /* don't want stale (S/CHK)PTRs */;}
					entries->store(localIndex, newEntry);
					this->diskUpdate();
				} END_CONSISTENT;
				return this;
			}
		}
		localIndex = (localIndex + 1) % numEntries;
		if (localIndex == originalIndex) {
			SPTR(GrandOverflow) newChild;
			UInt32 childIndex;
			
			/* This page is now full. Descend overflow 
			tree further. */
			childIndex = newEntry->hashForEqual() / depth % GrandOverflow::OTreeArity;
			if (children->fetch(childIndex) == NULL) {
				BEGIN_CONSISTENT(2) {
					CONSTRUCT(newChild,GrandOverflow,(numEntries, depth * GrandOverflow::OTreeArity));
					children->store(childIndex, newChild);
					this->diskUpdate();
				} END_CONSISTENT;
			}
			WPTR(GrandOverflow) 	returnValue;
			returnValue = CAST(GrandOverflow,children->fetch(childIndex))->store(newEntry);
			return returnValue;
		}
		entry = CAST(GrandEntry,entries->fetch(localIndex));
	}
	/* Found empty slot. */
	BEGIN_CONSISTENT(1) {
		entries->store(localIndex, newEntry);
		this->diskUpdate();
	} END_CONSISTENT;
	return this;
}


void GrandOverflow::wipe (APTR(Heaper) OR(Position) toMatch, UInt32 aHash){
	Int32 localIndex;
	Int32 originalIndex;
	Int32 childIndex;
	WPTR(GrandEntry) entry;
	
	localIndex = originalIndex = aHash / depth % numEntries;
	entry = CAST(GrandEntry,entries->fetch(localIndex));
	while (entry != NULL) {
		if (aHash == entry->hashForEqual()) {
			/* Note that this does not delete the contents */
			if (entry->compare(toMatch)) {
				BEGIN_CONSISTENT(2) {
					{entry->destroy();  entry = NULL /* don't want stale (S/CHK)PTRs */;}
					entries->store(localIndex, NULL);
					this->repack();
					this->diskUpdate();
				} END_CONSISTENT;
				return;
				
			}
		}
		localIndex = (localIndex + 1) % numEntries;
		entry = CAST(GrandEntry,entries->fetch(localIndex));
		/* break from loop */
		if (localIndex == originalIndex) {
			entry = NULL;
		}
	}
	childIndex = aHash / depth % GrandOverflow::OTreeArity;
	if (children->fetch(childIndex) != NULL) {
		CAST(GrandOverflow,children->fetch(childIndex))->wipe(toMatch, aHash);
	}
}
/* creation */


GrandOverflow::GrandOverflow (Int32 maxEntries, UInt32 someDepth) {
	numEntries = maxEntries;
	entries = PtrArray::nulls(numEntries);
	children = PtrArray::nulls(GrandOverflow::OTreeArity);
	depth = someDepth;
	this->newShepherd();
	this->remember();
}
/* private: */


void GrandOverflow::repack (){
	/* This repacks the entry table after a wipe to keep the 
	table consistent with */
	/* the linear hash collision resolution technique. */
	
	SPTR(PtrArray) OF1(GrandEntry) newEntries;
	SPTR(GrandEntry) entry;
	Int32 preferedIndex;
	
	newEntries = PtrArray::nulls(numEntries);
	{
		Int32 LoopFinal = numEntries;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if ((entry = CAST(GrandEntry,entries->fetch(i))) != NULL) {
					preferedIndex = entry->hashForEqual() / depth % numEntries;
					if (newEntries->fetch(preferedIndex) != NULL) {
						while (newEntries->fetch(preferedIndex) != NULL) {
							preferedIndex = (preferedIndex + 1) % numEntries;
						}
					}
					newEntries->store(preferedIndex, entry);
				}
			}
			i += 1;
		}
	}
	{entries->destroy();  entries = NULL /* don't want stale (S/CHK)PTRs */;}
	entries = newEntries;
}
/* node doubling */


void GrandOverflow::reinsertEntries (APTR(GrandNode) node){
	/* Recursively insert all overflowed entries into a newly 
	doubled node. */
	
	SPTR(GrandEntry) entry;
	SPTR(GrandOverflow) child;
	
	BEGIN_CONSISTENT(this->reinsertEntriesConsistency()) {
		{
			Int32 LoopFinal = numEntries;
			Int32 i = Int32Zero;
			for (;;) {
				if (i >= LoopFinal){
					break;
				}
				{
					entry = CAST(GrandEntry,entries->fetch(i));
					if (entry != NULL) {
						node->store(entry);
						entries->store(i, NULL);
						this->diskUpdate();
					}
				}
				i += 1;
			}
		}
		{
			Int32 LoopFinal = GrandOverflow::OTreeArity;
			Int32 j = Int32Zero;
			for (;;) {
				if (j >= LoopFinal){
					break;
				}
				{
					child = CAST(GrandOverflow,children->fetch(j));
					if (child != NULL) {
						GrandNodeReinserter::make (node, child)->schedule();
					}
				}
				j += 1;
			}
		}
	} END_CONSISTENT;
}


IntegerVar GrandOverflow::reinsertEntriesConsistency (){
	return 4 * numEntries + GrandOverflow::OTreeArity + 2;
}
/* printing */


void GrandOverflow::printOn (ostream& aStream){
	aStream << "GrandOverflow(depth=" << depth << ")";
}
/* protected: creation */


void GrandOverflow::dismantle (){
	BEGIN_CONSISTENT(1 + numEntries + GrandOverflow::OTreeArity) {
		if (entries != NULL) {
			{
				Int32 LoopFinal = numEntries;
				Int32 i = Int32Zero;
				for (;;) {
					if (i >= LoopFinal){
						break;
					}
					{
						SPTR(GrandEntry) entry;
						
						entry = CAST(GrandEntry,entries->fetch(i));
						if (entry != NULL) {
							{entry->destroy();  entry = NULL /* don't want stale (S/CHK)PTRs */;}
						}
					}
					i += 1;
				}
			}
			{entries->destroy();  entries = NULL /* don't want stale (S/CHK)PTRs */;}
		}
		if (children != NULL) {
			{
				Int32 LoopFinal = GrandOverflow::OTreeArity;
				Int32 j = Int32Zero;
				for (;;) {
					if (j >= LoopFinal){
						break;
					}
					{
						SPTR(GrandOverflow) child;
						
						child = CAST(GrandOverflow,children->fetch(j));
						if (child != NULL) {
							{child->destroy();  child = NULL /* don't want stale (S/CHK)PTRs */;}
						}
					}
					j += 1;
				}
			}
			{children->destroy();  children = NULL /* don't want stale (S/CHK)PTRs */;}
		}
		this->Abraham::dismantle();
	} END_CONSISTENT;
}
/* private: friendly */


RPTR(GrandOverflow) GrandOverflow::childAt (IntegerVar idx){
	return CAST(GrandOverflow,children->fetch(idx.asLong()));
}


IntegerVar GrandOverflow::childCount (){
	return GrandOverflow::OTreeArity;
}


RPTR(GrandEntry) GrandOverflow::entryAt (IntegerVar idx){
	return CAST(GrandEntry,entries->fetch(idx.asLong()));
}


IntegerVar GrandOverflow::entryCount (){
	return numEntries;
}
/* testing */


UInt32 GrandOverflow::contentsHash (){
	return this->Abraham::contentsHash() ^ IntegerPos::integerHash(numEntries) ^ entries->contentsHash() ^ children->contentsHash() ^ IntegerPos::integerHash(depth);
}



/* ************************************************************************ *
 * 
 *                    Class GrandOverflowStepper 
 *
 * ************************************************************************ */


/* private: */


void GrandOverflowStepper::verifyEntry (){
	if (entryIndex < overflow->entryCount()) {
		for (;;) {	BooleanVar crutch_Flag;
			/* entryIndex < overflow->entryCount() && overflow->entryAt(entryIndex) == NULL */
			
			crutch_Flag = entryIndex < overflow->entryCount();
			if(crutch_Flag) {
				crutch_Flag = overflow->entryAt(entryIndex) == NULL;
			}
			if (crutch_Flag) {
				entryIndex += 1;
			} else {
				break;
			}
		}
	}
	if (entryIndex < overflow->entryCount()) {
		return;
		
	}
	if (childIndex < overflow->childCount()) {
		for (;;) {	BooleanVar crutch_Flag;
			/* childIndex < overflow->childCount() && overflow->childAt(childIndex) == NULL */
			
			crutch_Flag = childIndex < overflow->childCount();
			if(crutch_Flag) {
				crutch_Flag = overflow->childAt(childIndex) == NULL;
			}
			if (crutch_Flag) {
				childIndex += 1;
			} else {
				break;
			}
		}
		if (childIndex < overflow->childCount()) {
			CONSTRUCT(childStepper,GrandOverflowStepper,(overflow->childAt(childIndex), tcsj));
		}
	}
}
/* operations */


RPTR(GrandEntry) GrandOverflowStepper::entry (){
	if (childStepper == NULL) {
		WPTR(GrandEntry) 	returnValue;
		returnValue = overflow->entryAt(entryIndex);
		return returnValue;
	} else {
		WPTR(GrandEntry) 	returnValue;
		returnValue = childStepper->entry();
		return returnValue;
	}
}


WPTR(Heaper) GrandOverflowStepper::fetch (){
	BLAST(SHOULD_NOT_IMPLEMENT);
	return NULL;
}


BooleanVar GrandOverflowStepper::hasValue (){
	if (childStepper != NULL) {
		return childStepper->hasValue();
	} else {
		{	BooleanVar crutch_Flag;
			/* entryIndex < overflow->entryCount() && childIndex < overflow->childCount() */
			
			crutch_Flag = entryIndex < overflow->entryCount();
			if(crutch_Flag) {
				crutch_Flag = childIndex < overflow->childCount();
			}
			return crutch_Flag;
		}
	}
}


void GrandOverflowStepper::step (){
	if (childStepper != NULL) {
		childStepper->step();
		if (childStepper->hasValue()) {
			return;
			
		} else {
			{childStepper->destroy();  childStepper = NULL /* don't want stale (S/CHK)PTRs */;}
			childStepper = NULL;
			childIndex += 1;
		}
	} else {
		entryIndex += 1;
	}
	this->verifyEntry();
}
/* create */


RPTR(Stepper) GrandOverflowStepper::copy (){
	RETURN_CONSTRUCT(GrandOverflowStepper,(overflow, entryIndex, childStepper, childIndex));
}


GrandOverflowStepper::GrandOverflowStepper (APTR(GrandOverflow) aPage, TCSJ) {
	overflow = aPage;
	entryIndex = childIndex = IntegerVar0;
	childStepper = NULL;
	this->verifyEntry();
}
/* protected: creation */


GrandOverflowStepper::GrandOverflowStepper (
		APTR(GrandOverflow) anOverflow, 
		IntegerVar entryIdx, 
		APTR(GrandOverflowStepper) child, 
		IntegerVar childIdx) 
{
	overflow = anOverflow;
	entryIndex = entryIdx;
	childStepper = child;
	childIndex = childIdx;
}


void GrandOverflowStepper::destruct (){
	if (childStepper != NULL) {
		{childStepper->destroy();  childStepper = NULL /* don't want stale (S/CHK)PTRs */;}
	}
	this->Stepper::destruct();
}

#ifndef GRANTABX_SXX
#include "grantabx.sxx"
#endif /* GRANTABX_SXX */


#ifndef GRANTABP_SXX
#include "grantabp.sxx"
#endif /* GRANTABP_SXX */



#endif /* GRANTABX_CXX */

