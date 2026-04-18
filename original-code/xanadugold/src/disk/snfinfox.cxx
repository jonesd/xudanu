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

#ifndef SNFINFOX_CXX
#define SNFINFOX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef SNFINFOX_HXX
#include "snfinfox.hxx"
#endif /* SNFINFOX_HXX */

#ifndef SNFINFOX_IXX
#include "snfinfox.ixx"
#endif /* SNFINFOX_IXX */


#ifndef ARRAYX_HXX
#include "arrayx.hxx"
#endif /* ARRAYX_HXX */

#ifndef FLKINFOX_HXX
#include "flkinfox.hxx"
#endif /* FLKINFOX_HXX */

#ifndef NSCOTTYX_HXX
#include "nscottyx.hxx"
#endif /* NSCOTTYX_HXX */

#ifndef SPACEX_HXX
#include "spacex.hxx"
#endif /* SPACEX_HXX */




/* ************************************************************************ *
 * 
 *                    Class SnarfHandler 
 *
 * ************************************************************************ */



/* Initializers for SnarfHandler */

/* Hack !!!! */

/* These don't use the full 32 bits so that we don't start 
	manipulating LargeIntegers. */
UInt4 SnarfHandler::Flag = 1 << 25;
/* Flag - 1 */
UInt4 SnarfHandler::Value = (1 << 25) - 1;
/* The offset of the size from the begginging of a mapCell */
Int4 SnarfHandler::SizeOffset = 4;
BooleanVar SnarfHandler::UseFences = FALSE;


/* Initializers for SnarfHandler */



/* pcreate */


RPTR(SnarfHandler) SnarfHandler::make (APTR(SnarfHandle) snarfHandle){
	RETURN_CONSTRUCT(SnarfHandler,(snarfHandle, tcsj));
}
/* accessing */


Int32 SnarfHandler::fenceSize (){
	/* The number of bytes for one fence (Each flock requires two). */
	
	if (SnarfHandler::UseFences) {
		return 4;
	} else {
		return Int32Zero;
	}
}
/* private: sorting */


void SnarfHandler::quickSort (
		APTR(UInt32Array) offsets, 
		APTR(UInt32Array) indices, 
		Int32 first, 
		Int32 last)
{
	Int32 part;
	Int32 left;
	Int32 right;
	
	if (first >= last) {
		return;
		
	}
	left = first;
	right = last + 1;
	SnarfHandler::swap(offsets, first, (left + right) / 2);
	SnarfHandler::swap(indices, first, (left + right) / 2);
	part = offsets->uIntAt(first);
	while (left < right) {
		left += 1;
		while (offsets->uIntAt(left) > part) {
			left += 1;
		}
		right -= 1;
		while (part > offsets->uIntAt(right)) {
			right -= 1;
		}
		if (left < right) {
			SnarfHandler::swap(offsets, left, right);
			SnarfHandler::swap(indices, left, right);
		}
	}
	SnarfHandler::swap(offsets, first, right);
	SnarfHandler::swap(indices, first, right);
	SnarfHandler::quickSort(offsets, indices, first, right - 1);
	SnarfHandler::quickSort(offsets, indices, right + 1, last);
}


void SnarfHandler::quickSort (
		APTR(UInt32Array) offsets, 
		APTR(UInt32Array) indices, 
		APTR(OrderSpec) os, 
		IntegerVar first, 
		IntegerVar last)
{
	IntegerVar part;
	IntegerVar left;
	IntegerVar right;
	
	if (first >= last) {
		return;
		
	}
	left = first;
	right = last + 1;
	SnarfHandler::swap(offsets, first, (left + right) / 2);
	SnarfHandler::swap(indices, first, (left + right) / 2);
	part = offsets->uIntAt(first.asLong());
	while (left < right) {
		left += 1;
		while (!os->followsInt(offsets->uIntAt(left.asLong()), part)) {
			left += 1;
		}
		right -= 1;
		while (!os->followsInt(part, offsets->uIntAt(right.asLong()))) {
			right -= 1;
		}
		if (left < right) {
			SnarfHandler::swap(offsets, left, right);
			SnarfHandler::swap(indices, left, right);
		}
	}
	SnarfHandler::swap(offsets, first, right);
	SnarfHandler::swap(indices, first, right);
	SnarfHandler::quickSort(offsets, indices, os, first, right - 1);
	SnarfHandler::quickSort(offsets, indices, os, right + 1, last);
}


RPTR(UInt32Array) SnarfHandler::sort (APTR(UInt32Array) offsets){
	/* Sort the offsets array in place, and return an array of 
	the same size that maps from the new index of each element to 
	its original index.  The offsets array is *assumed* to be 
	terminated with a guard element which is greater than or 
	equal to all the other elements of the array according to 
	descending order.  If this isn't true, havoc may result. */
	
	SPTR(UInt32Array) result;
	
	result = UInt32Array::make (offsets->count());
	{
		Int32 LoopFinal = offsets->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				result->storeUInt(i, i);
			}
			i += 1;
		}
	}
	SnarfHandler::quickSort(offsets, result, Int32Zero, offsets->count() - 2);
	WPTR(UInt32Array) 	returnValue;
	returnValue = result;
	return returnValue;
}


RPTR(UInt32Array) SnarfHandler::sort (APTR(UInt32Array) offsets, APTR(OrderSpec) os){
	/* Sort the offsets array in place, and return an array of 
	the same size that maps from the new index of each element to 
	its original index.  The offsets array is *assumed* to be 
	terminated with a guard element which is greater than or 
	equal to all the other elements of the array according to the 
	sorting order.  If this isn't true, havoc may result. */
	
	SPTR(UInt32Array) result;
	
	result = UInt32Array::make (offsets->count());
	{
		Int32 LoopFinal = offsets->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				result->storeUInt(i, i);
			}
			i += 1;
		}
	}
	SnarfHandler::quickSort(offsets, result, os, Int32Zero, offsets->count() - 2);
	WPTR(UInt32Array) 	returnValue;
	returnValue = result;
	return returnValue;
}
/* A SnarfHandler breaks a snarf into abstract subarrays of bytes 
into whic flocks are stored.  These indexed flock storage areas are 
accessed through readStreams and writeStreams provided by the 
SnarfHandler.  SnarfHandlers also provide the ability to resize these 
flock areas and associate a couple of flag bits with them.  All 
access to the snarf goes through a single snarfHandler.

The beginning of the snarf is dedicated to a table that describes the 
locations and sizes of the contained flock areas.  Currently, we 
allocate space between the flock nearest the front of the snarf and 
the end of the mapTable.  When not enough space exists between the 
two, we compact the flock storage areas towards the back (highest 
address) of the snarf and try to allocate again.

An index in the snarfHAndler can be associated either with one of 
these flock storage areas or with a snarfID and index to look further 
for the storage of a given flock.  Right now, the SnarfHAndler keeps 
the forwarding information in a flock storage area, but it will soon 
be put into the mapTable directly.

Forwarding pointers occur when a flock outgrows a snarf, and must be 
moved elsewhere.  Eventually all other snarfs that have objects which 
point to the forwarding pointer are updated, and the forwarding 
pointer can be deallocated, but decisions about this must be made by 
objects external to the SnarfHandler.

The forwarded flag is stored on the snarfID.  The forgotten flag is 
stored on the size.  Both use the same Flag mask for accessing the 
flag, and the Value mask for accessing the value. */


/* reading */


RPTR(FlockLocation) OR(NULL) SnarfHandler::fetchForward (Int32 index){
	/* If the flock specified by index has been forwarded, return 
	a FlockLocation with the SnarfID and index of its new location. */
	
	this->checkIndex(index);
	/* Forwarded.  The info is stored in the mapCell. */
	if (this->isForwarded(index)) {
		WPTR(FlockLocation) OR(NULL) 	returnValue;
		returnValue = FlockLocation::make (this->getOffset(index), this->getSize(index));
		return returnValue;
	}
	return NULL;
}


Int32 SnarfHandler::flockSize (Int32 index){
	/* Return the number of bytes in the flock at index */
	
	return (myHandle->get32(this->mapCellOffset(index) + SnarfHandler::SizeOffset) & SnarfHandler::Value) - SnarfHandler::fenceSize() * 2;
}


BooleanVar SnarfHandler::isForgotten (Int32 index){
	/* The forgotten flag is the flag bit associated with each 
	flock.  It is set when the
		flock has been forgotten, which means that there are no more 
	persistent pointers
		to the flock.  When a flock is forgotten AND is not in RAM, 
	the SnarfPacker is
		free to bring the flock back into RAM and destroy it, which 
	deletes it from the snarf.
		 
		 Return true if the forgotten flag has been set for the 
	flock at index. */
	
	return (SnarfHandler::Flag & myHandle->get32(this->mapCellOffset(index) + SnarfHandler::SizeOffset)) == SnarfHandler::Flag;
}


BooleanVar SnarfHandler::isOccupied (Int32 index){
	/* Return true if there's a flock or forwarder at index. */
	
	{	BooleanVar crutch_Flag;
		/* index >= Int32Zero && index < myMapCount && (this->isForwarded(index) || this->getSize(index) > Int32Zero) */
		
		crutch_Flag = index >= Int32Zero;
		if(crutch_Flag) {
			crutch_Flag = index < myMapCount;
			if(crutch_Flag) {
				crutch_Flag = this->isForwarded(index);
				if(!crutch_Flag) {
					crutch_Flag = this->getSize(index) > Int32Zero;
				}
			}
		}
		return crutch_Flag;
	}
}


Int32 SnarfHandler::mapCount (){
	/* Return the number of slots allocated in the map table. */
	
	return myMapCount;
}


RPTR(XnReadStream) SnarfHandler::readStream (Int32 index){
	/* Return a stream on the area of the snarf allocated to mapIndex.  
		 This stream must be used immediately, then thrown away. */
	
	this->checkIndex(index);
	if (this->isForwarded(index)) {
		BLAST(MustBeAFlock);
	}
	WPTR(XnReadStream) 	returnValue;
	returnValue = XnReadStream::make (myHandle->getDataP(), this->flockOffset(index), this->flockSize(index));
	return returnValue;
}


Int32 SnarfHandler::snarfID (){
	/* Return the snarfID of the snarf this handle holds. */
	
	return myHandle->getSnarfID();
}


Int32 SnarfHandler::spaceLeft (){
	/* Return the amount space left in the snarf. */
	
	return mySpaceLeft;
}
/* writing */


void SnarfHandler::allocateCells (IntegerVar indices){
	/* Add more cells to the mapTable.  Make sure that there is 
	enough space for
		 those cells, then initialize.  The size is initially 0 and 
	the offset points past 
		 the end of the snarf. */
	
	Int32 newCells;
	Int32 space;
	
	newCells = indices.asLong();
	if (newCells <= Int32Zero) {
		return;
		
	}
	space = newCells * SnarfHandler::mapCellSize();
	this->clearSpace(space);
	myMapCount += newCells;
	mySpaceLeft -= space;
	/* Zero all the counts, just like wipeFlock. */
	{
		Int32 LoopFinal = myMapCount;
		Int32 index = myMapCount - newCells;
		for (;;) {
			if (index >= LoopFinal){
				break;
			}
			{
				myHandle->put32(this->mapCellOffset(index) + SnarfHandler::SizeOffset, Int32Zero);
				this->storeIndex(index, this->flocksEnd());
			}
			index += 1;
		}
	}
	this->consistencyCheck();
	this->checkFences();
}


void SnarfHandler::allocate (IntegerVar ind, Int32 flockSize){
	/* Allocate flockSize bytes for the flock at the index ind. */
	
	Int32 index;
	Int32 size;
	
	if ( ! (flockSize > Int32Zero) ) {
		BLAST(Must_allocate_some_space);
	}
	size = flockSize + SnarfHandler::fenceSize() * 2;
	index = ind.asLong();
	this->checkIndex(index);
	this->clearSpace(size);
	if (!this->isForwarded(index)) {
		mySpaceLeft += this->getSize(index);
	}
	mySpaceLeft -= size;
	this->storeIndex(index, this->nearestFlock() - size);
	this->storeSize(index, size);
	this->mendFences(index);
	this->consistencyCheck();
	this->checkFences();
}


void SnarfHandler::storeForget (Int32 index, BooleanVar flag){
	/* See the comment on isForgotten:.  Set or clear the 
	forgetFlag for the flock at index. */
	
	Int32 offset;
	
	this->checkIndex(index);
	offset = this->mapCellOffset(index) + SnarfHandler::SizeOffset;
	/* Keep everything else the same. */
	if (flag) {
		myHandle->put32(offset, SnarfHandler::Flag | myHandle->get32(offset));
	} else {
		myHandle->put32(offset, SnarfHandler::Value & myHandle->get32(offset));
	}
	this->checkFences();
}


void SnarfHandler::forwardTo (
		IntegerVar index, 
		Int32 newSnarfID, 
		Int32 newIndex)
{
	/* Associate a forwarder with index.  Throw away whatever storage
		 was assigned to it and store the forwarder information in 
	the mapCell. */
	
	this->wipeFlock(index);
	myHandle->put32(this->mapCellOffset(index.asLong()), newSnarfID | SnarfHandler::Flag);
	myHandle->put32(this->mapCellOffset(index.asLong()) + SnarfHandler::SizeOffset, newIndex & SnarfHandler::Value);
}


BooleanVar SnarfHandler::isWritable (){
	/* Return true if I represent a writable snarf.  */
	
	return myHandle->isWritable();
}


void SnarfHandler::makeWritable (){
	/* Make the handle for the receiver writable. */
	
	myHandle->makeWritable();
}


void SnarfHandler::rewrite (){
	/* Write out to the snarf any values held in instance variables (space 
		remaining, number of entries, etc.). */
	
	myHandle->put32(Int32Zero, myMapCount);
	myHandle->put32(SnarfHandler::SizeOffset, mySpaceLeft);
}


void SnarfHandler::wipeFlock (IntegerVar index){
	/* Deallocate all space for the flock at index.  The slot for 
	index remains however, and can be reused for another flock. */
	
	this->checkIndex(index.asLong());
	if (!this->isForwarded(index.asLong())) {
		mySpaceLeft += this->getSize(index.asLong());
	}
	myHandle->put32(this->mapCellOffset(index.asLong()) + SnarfHandler::SizeOffset, Int32Zero);
	this->storeIndex(index.asLong(), this->flocksEnd());
	this->consistencyCheck();
	this->checkFences();
}


RPTR(XnWriteStream) SnarfHandler::writeStream (IntegerVar index){
	/* Return a stream that can write into the bytes allocated to 
	the flock at index. 
		 The stream must be used immediately and thrown away. */
	
	this->checkIndex(index.asLong());
	if (this->isForwarded(index.asLong())) {
		BLAST(MustBeAFlock);
	}
	WPTR(XnWriteStream) 	returnValue;
	returnValue = XnWriteStream::make (myHandle->getDataP(), this->flockOffset(index.asLong()), this->flockSize(index.asLong()));
	return returnValue;
}
/* initialize */


void SnarfHandler::initializeSnarf (){
	/* Put in the minimum necessary for a starting snarf.  
		 All it needs is the number of objects and the spaceLeft.
		 This also writes the information to the real snarf. */
	
	myMapCount = Int32Zero;
	mySpaceLeft = this->flocksEnd() - SnarfHandler::mapOverhead();
	this->rewrite();
}
/* private: operations */


BooleanVar SnarfHandler::checkFence (Int32 index){
	/* If we are using fences around flock storage areas, then 
	return true only if the fences are still in place for the 
	flock at index.  Fences are extra storage at the front and 
	back of a flock storage area that contains the index of that 
	flock.  These are used for runtime checks that one flock 
	hasn't stepped into the space of another. */
	
	if (SnarfHandler::UseFences) {
		Int32 offset;
		Int32 size;
		
		if (this->isForwarded(index)) {
			return TRUE;
		}
		size = this->getSize(index);
		{	BooleanVar crutch_Flag;
			/* size <= Int32Zero || myHandle->get32(offset = this->getOffset(index)) == index && myHandle->get32(offset + this->getSize(index) - SnarfHandler::fenceSize()) == index */
			
			crutch_Flag = size <= Int32Zero;
			if(!crutch_Flag) {
				crutch_Flag = myHandle->get32(offset = this->getOffset(index)) == index;
				if(crutch_Flag) {
					crutch_Flag = myHandle->get32(offset + this->getSize(index) - SnarfHandler::fenceSize()) == index;
				}
			}
			return crutch_Flag;
		}
	} else {
		return TRUE;
	}
}


void SnarfHandler::checkFences (){
	/* See checkFence:  Check the fences for all flocks and blast 
	if any are violated. */
	/* Int32Zero to: myMapCount-1 do:
			[:i {Int32} | (self checkFence: i) ifFalse: [SnarfHandler 
	BLAST: #BrokenFence]] */
	
	
}


void SnarfHandler::checkIndex (Int32 index){
	/* Blast if the index is not represented in the table.  This 
	is just simple bounds checking. */
	
	{	BooleanVar crutch_Flag;
		/* index >= myMapCount && index >= Int32Zero */
		
		crutch_Flag = index >= myMapCount;
		if(crutch_Flag) {
			crutch_Flag = index >= Int32Zero;
		}
		if (crutch_Flag) {
			BLAST(NotInTable);
		}
	}
}


void SnarfHandler::clearSpace (Int32 count){
	/* This checks for count bytes available at the end of the 
	mapTable.  If
		 there isn't enough, it compacts everything and tries again. */
	
	this->consistencyCheck();
	if (this->nearestFlock() < this->mapEnd() + count) {
		this->recomputeNearest();
		if (this->nearestFlock() < this->mapEnd() + count) {
			this->compact();
			if (!(this->nearestFlock() >= this->mapEnd() + count)) {
				BLAST(MustHaveRoom);
			}
		}
	}
}


void SnarfHandler::compact (){
	/* Compress flock storage areas towards the end of the snarf, 
	leaving all
		 freespace between the end of the mapTable and the nearest flock. */
	
	Int32 sweeper;
	SPTR(UInt32Array) offsets;
	SPTR(UInt32Array) indices;
	
	this->checkFences();
	sweeper = this->flocksEnd();
	myNearest = sweeper;
	/* Load up all the offset into an array.  Make cells that are 
		forwarded just point past the end of the snarf. */
	offsets = UInt32Array::make (myMapCount + 1);
	{
		Int32 LoopFinal = myMapCount;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				if (this->isForwarded(i)) {
					offsets->storeUInt(i, sweeper);
				} else {
					offsets->storeUInt(i, this->getOffset(i));
				}
			}
			i += 1;
		}
	}
	offsets->storeUInt(myMapCount, UInt32Zero);
	indices = SnarfHandler::sort(offsets);
	{
		Int32 LoopFinal = myMapCount;
		Int32 i2 = Int32Zero;
		for (;;) {
			if (i2 >= LoopFinal){
				break;
			}
			{
				Int32 indexToMove;
				Int32 offsetToMove;
				Int32 count;
				
				indexToMove = indices->uIntAt(i2);
				offsetToMove = offsets->uIntAt(i2);
				if (offsetToMove < sweeper) {
					count = this->getSize(indexToMove);
					sweeper -= count;
					myHandle->moveBytes(offsetToMove, sweeper, count);
					/* This storeIndex will also 
						push myNearest. */
					this->storeIndex(indexToMove, sweeper);
				}
			}
			i2 += 1;
		}
	}
	this->checkFences();
	{offsets->destroy();  offsets = NULL /* don't want stale (S/CHK)PTRs */;}
}


void SnarfHandler::consistencyCheck (){
	/* Generic checking hook to do slow runtime consistency 
	checking when debugging.  No checks are active currently. */
	/* self compact.
		mySpaceLeft == (self nearestFlock - self mapEnd) assert: 
	'space mismatch'. */
	/* | sum {Int32} |
		sum _ Int32Zero.
		Int32Zero almostTo: myMapCount do: 
			[:i {Int32} |
			(self isForwarded: i) ifFalse: [sum _ sum + (self getSize: i)]].
		sum + self mapEnd + mySpaceLeft == myHandle getDataSize 
	assert: 'Space difference' */
	
	
}


void SnarfHandler::mendFences (Int32 index){
	/* Couldn't resist the name.  Set up the fences for the flock 
	at index.  See checkFence: */
	
	if (SnarfHandler::UseFences) {
		Int32 offset;
		
		offset = this->getOffset(index);
		myHandle->put32(offset, index);
		myHandle->put32(offset + this->getSize(index) - SnarfHandler::fenceSize(), index);
	}
}


Int32 SnarfHandler::nearestFlock (){
	/* Return the location of the nearest flock. Everything between the 
		end of the map and the nearest flock is free space. We normally 
		allocate everything from the back of the snarf forward. When we 
		run out of enough contiguous space, we simply compact.
		
		We keep a cache of the current nearest flock.  The cache 
	maintins the invariant that it
		 *must* point to an offset less than or equal to the 
	nearestFlock.  Thus it can be too close 
		 to the mapTable, in which case we will recompute it from scratch. */
	
	if (myNearest == Int32Zero) {
		this->recomputeNearest();
	}
	return myNearest;
}


void SnarfHandler::recomputeNearest (){
	/* Recalculate the nearest flock by looking at the start of 
	every flock and taking the min. */
	
	myNearest = this->flocksEnd();
	{
		Int32 LoopFinal = myMapCount;
		Int32 index = Int32Zero;
		for (;;) {
			if (index >= LoopFinal){
				break;
			}
			{
				{	BooleanVar crutch_Flag;
					/* !this->isForwarded(index) && this->getSize(index) > Int32Zero */
					
					crutch_Flag = !this->isForwarded(index);
					if(crutch_Flag) {
						crutch_Flag = this->getSize(index) > Int32Zero;
					}
					if (crutch_Flag) {
						Int32 offset;
						
						offset = this->getOffset(index);
						if (offset < myNearest) {
							myNearest = offset;
						}
					}
				}
			}
			index += 1;
		}
	}
}
/* private: layout */


void SnarfHandler::storeIndex (Int32 index, Int32 offset){
	/* Store the offset as the starting location for the data of 
	the flock at index.  
		 Update the cache of nearestFlock.  This also clears the 
	forwarded flag. */
	
	if (offset < myNearest) {
		myNearest = offset;
	}
	myHandle->put32(this->mapCellOffset(index), offset & SnarfHandler::Value);
}


void SnarfHandler::storeSize (Int32 index, Int32 size){
	/* Store size as the number of bytes for the flock at index.  If the 
		 space is at a 0, then change the corresponding pointer to 
	past the end of 
		 the snarf so that we don't find it in our searches. */
	
	Int32 offset;
	
	offset = this->mapCellOffset(index) + SnarfHandler::SizeOffset;
	/* Keep the old flags. */
	myHandle->put32(offset, size & SnarfHandler::Value | myHandle->get32(offset) & SnarfHandler::Flag);
	if (size == Int32Zero) {
		this->storeIndex(index, this->flocksEnd());
	}
}


Int32 SnarfHandler::flockOffset (Int32 index){
	/* Return the index of the first byte of the actual data 
	associated with flock number index.  This is like indexOf: 
	except that it leaves room for fencePosts on either side of 
	the flock storage area. */
	
	return (myHandle->get32(this->mapCellOffset(index)) & SnarfHandler::Value) + SnarfHandler::fenceSize();
}


Int32 SnarfHandler::flocksEnd (){
	/* Return the index of the cell one greater than the size of 
	the entire snarf.  This is just past the end of the storage 
	area for flocks. */
	
	return myHandle->getDataSize();
}


Int32 SnarfHandler::getOffset (Int32 index){
	/* Return the index of the first byte of the actual data 
	associated with
		 flock number index.  This area includes space for 
	fencePosts and whatever 
		 other things we might dream up that go with the flock in 
	its storage area. */
	
	Int32 offset;
	
	offset = myHandle->get32(this->mapCellOffset(index));
	return offset & SnarfHandler::Value;
}


Int32 SnarfHandler::getSize (Int32 index){
	/* Return the number of bytes in the flock at index.  This 
	includes space allocated internally for fencePosts and the like. */
	
	Int32 size;
	
	size = myHandle->get32(this->mapCellOffset(index) + SnarfHandler::SizeOffset) & SnarfHandler::Value;
	return size;
}


BooleanVar SnarfHandler::isForwarded (Int32 index){
	/* Return the internal bit that says whether the flock at 
	index is represented by forwarding information or by a flock area */
	
	return (SnarfHandler::Flag & myHandle->get32(this->mapCellOffset(index))) == SnarfHandler::Flag;
}


Int32 SnarfHandler::mapEnd (){
	/* Return the index of the cell just after the end of the 
	map.  This is based on the number of entries in the map. */
	
	return this->mapCellOffset(myMapCount);
}


Int32 SnarfHandler::snarfMapCount (){
	/* Actually get from the snarf the number of map slots 
	currently allocated, 
		including ones that are free for reuse. This is stored as 
	the first thing in the 
		snarf. */
	
	return myHandle->get32(Int32Zero);
}


Int32 SnarfHandler::snarfSpaceLeft (){
	/* Actually get from the snarf the amount of unallocated 
	space remaining. */
	
	return myHandle->get32(SnarfHandler::SizeOffset);
}
/* protected: destruct */


void SnarfHandler::destruct (){
	/* Write my internal constants to the snarf before I go away. */
	
	if (myHandle->isWritable()) {
		this->rewrite();
	}
	{myHandle->destroy();  myHandle = NULL /* don't want stale (S/CHK)PTRs */;}
	myHandle = NULL;
	this->Heaper::destruct();
}
/* create */


SnarfHandler::SnarfHandler (APTR(SnarfHandle) handle, TCSJ) {
	
	myHandle = handle;
	myMapCount = this->snarfMapCount();
	/* If I'm uninitialized, then generate the necessary data. */
	if (myMapCount == Int32Zero) {
		mySpaceLeft = this->flocksEnd() - SnarfHandler::mapOverhead();
	} else {
		mySpaceLeft = this->snarfSpaceLeft();
	}
	myNearest = Int32Zero;
}
/* testing */


UInt32 SnarfHandler::actualHashForEqual (){
	return Heaper::takeOop();
}



/* ************************************************************************ *
 * 
 *                    Class SnarfInfoHandler 
 *
 * ************************************************************************ */



/* Initializers for SnarfInfoHandler */

Int4 SnarfInfoHandler::ForgottenFlag = 1 << 24;
Int4 SnarfInfoHandler::SizeMask = (1 << 24) - 1;


/* Initializers for SnarfInfoHandler */



/* pcreate */


void SnarfInfoHandler::initializeSnarfInfo (APTR(Urdi) urdi, APTR(UrdiView) view){
	SPTR(SnarfInfoHandler) handler;
	
	CONSTRUCT(handler,SnarfInfoHandler,(urdi, view));
	{handler->destroy();  handler = NULL /* don't want stale (S/CHK)PTRs */;}
}


RPTR(SnarfInfoHandler) SnarfInfoHandler::make (APTR(Urdi) urdi, APTR(UrdiView) view){
	RETURN_CONSTRUCT(SnarfInfoHandler,(view, urdi));
}
/* The SnarfInfoHandler is an interface to the first few snarfs in an 
urdi that tells how much space is unallocated in each of the 
remaining snarfs, and keeps a bit as to whether any forgotten objects 
are in each snarf.

The data is kept packed in the first few snarfs with 4 bytes per 
snarf recorded.  The forgotten bit is the high bit of each entry.

mySnarfs is a table of SnarfHandles onto the snarfInfo snarfs (the 
first few snarfs in the Urdi).  You release those snarfs by 
destroying the snarfInfoHandler and creating a new one when you want 
the information again.

myTotal is the total number of snarfs in the Urdi. */


/* accessing */


BooleanVar SnarfInfoHandler::getForgottenFlag (Int32 snarfID){
	/* Return the forgotten bit for the snarf at snarfID. */
	
	Int32 offset;
	
	offset = this->locate(snarfID);
	return (myCurrentHandle->get32(offset) & SnarfInfoHandler::ForgottenFlag) != Int32Zero;
}


Int32 SnarfInfoHandler::getSpaceLeft (Int32 snarfID){
	/* Return the spaceLeft for the snarf at snarfID. */
	
	Int32 offset;
	
	offset = this->locate(snarfID);
	return myCurrentHandle->get32(offset) & SnarfInfoHandler::SizeMask;
}


void SnarfInfoHandler::setForgottenFlag (Int32 snarfID, BooleanVar flag){
	/* Set or clear the forgotten bit for the snarf at snarfID. */
	
	Int32 offset;
	
	offset = this->locate(snarfID);
	myCurrentHandle->makeWritable();
	if (flag) {
		myCurrentHandle->put32(offset, myCurrentHandle->get32(offset) | SnarfInfoHandler::ForgottenFlag);
	} else {
		myCurrentHandle->put32(offset, myCurrentHandle->get32(offset) & ~SnarfInfoHandler::ForgottenFlag);
	}
}


void SnarfInfoHandler::setSpaceLeft (Int32 snarfID, Int32 space){
	/* Set the space for the snarf at snarfID. */
	
	Int32 offset;
	
	offset = this->locate(snarfID);
	myCurrentHandle->makeWritable();
	myCurrentHandle->put32(offset, space + (myCurrentHandle->get32(offset) & ~SnarfInfoHandler::SizeMask));
}


Int32 SnarfInfoHandler::snarfCount (){
	/* Return the total number of snarfs in the urdi. */
	
	return myTotal;
}


Int32 SnarfInfoHandler::snarfInfoCount (){
	/* Return the number of snarfs that the snarf info information takes 
		up. This is used to know what snarf to get the first object from. */
	
	return mySnarfs->count().asLong();
}
/* private: */


void SnarfInfoHandler::initializeSpaceLeft (Int32 snarfID, Int32 space){
	/* Se the spaceLeft to a certain amount, and clear all the 
	flags. This is used 
		when initializing the snarfInfo so we don't get confused by 
	the flags. */
	
	Int32 offset;
	
	offset = this->locate(snarfID);
	myCurrentHandle->makeWritable();
	myCurrentHandle->put32(offset, space);
}


Int32 SnarfInfoHandler::locate (Int32 snarfID){
	/* Return the snarfHandle for the snarfInfo snarf that 
	contains the spaceLeft and forgotten flag for the snarf at snarfID. */
	
	{	BooleanVar crutch_Flag;
		/* myCurrentHandle != NULL && snarfID >= myCurrentStart && snarfID < myCurrentStart + myCurrentHandle->getDataSize() / 4 */
		
		crutch_Flag = myCurrentHandle != NULL;
		if(crutch_Flag) {
			crutch_Flag = snarfID >= myCurrentStart;
			if(crutch_Flag) {
				crutch_Flag = snarfID < myCurrentStart + myCurrentHandle->getDataSize() / 4;
			}
		}
		if (crutch_Flag) {
			return (snarfID - myCurrentStart) * 4;
		}
	}
	{	BooleanVar crutch_Flag;
		/* snarfID < myCurrentStart || myCurrentHandle == NULL */
		
		crutch_Flag = snarfID < myCurrentStart;
		if(!crutch_Flag) {
			crutch_Flag = myCurrentHandle == NULL;
		}
		if (crutch_Flag) {
			myCurrentIndex = IntegerVar0;
			myCurrentHandle = CAST(SnarfHandle,mySnarfs->intGet(myCurrentIndex));
			myCurrentStart = Int32Zero;
		}
	}
	while (myCurrentHandle != NULL) {
		Int32 count;
		
		count = myCurrentHandle->getDataSize() / 4;
		if (snarfID < count + myCurrentStart) {
			return (snarfID - myCurrentStart) * 4;
		}
		myCurrentIndex += 1;
		myCurrentHandle = CAST(SnarfHandle,mySnarfs->intFetch(myCurrentIndex));
		myCurrentStart += count;
	}
	BLAST(NoSnarfInfo);
	return Int32Zero;
}
/* protected: destruct */


void SnarfInfoHandler::destruct (){
	/* Release all my handles before going away. */
	
	myCurrentHandle = NULL;
	if (mySnarfs->getCategory() != cat_Heaper) {
		BEGIN_FOR_EACH(SnarfHandle,handle,(mySnarfs->stepper())) {
			{handle->destroy();  handle = NULL /* don't want stale (S/CHK)PTRs */;}
		} END_FOR_EACH;
	}
	mySnarfs = NULL;
	this->Heaper::destruct();
}
/* create */


SnarfInfoHandler::SnarfInfoHandler (APTR(Urdi) urdi, APTR(UrdiView) view) {
	/* This constructor is for a newly created urdi with no 
	existing snarfInfo 
		information. Set the spaceLeft for each snarf to its maximum 
	and clear the 
		forgotten flag. Note that this figures out how many 
	snarfInfo snarfs to use on 
		the fly by allocating as many snarfInfo cells as it can in 
	the first snarf, then 
		going on to the second snarf, until enough snarfInfo snarfs 
	are allocated. Then 
		it goes through all the entries in the snarfInfo for each 
	non-snarfInfo snarf 
		and set the spaceLeft appropriately. */
	
	Int32 snarfID;
	Int32 total;
	
	snarfID = Int32Zero;
	myTotal = urdi->usableSnarfs();
	mySnarfs = MuArray::array();
	myCurrentStart = Int32Zero;
	myCurrentIndex = IntegerVar0;
	myCurrentHandle = NULL;
	total = Int32Zero;
	/* Initialize enough snarfInfo snarfs for all snarfs in the Urdi. */
	while (total < myTotal) {
		SPTR(SnarfHandle) handle;
		
		handle = view->makeErasingHandle(snarfID);
		mySnarfs->atIntIntroduce(snarfID, handle);
		this->initializeSpaceLeft(snarfID, Int32Zero);
		total += handle->getDataSize() / 4;
		snarfID += 1;
	}
	/* Initialize the entries for all non-snarfInfo snarfs. */
	{
		SnarfID LoopFinal = myTotal;
		Int32 dataSnarfID = snarfID;
		for (;;) {
			if (dataSnarfID >= LoopFinal){
				break;
			}
			{
				this->initializeSpaceLeft(dataSnarfID, urdi->getDataSizeOfSnarf(dataSnarfID));
			}
			dataSnarfID += 1;
		}
	}
}


SnarfInfoHandler::SnarfInfoHandler (APTR(UrdiView) view, APTR(Urdi) urdi) {
	/* This constructor is for reopening an existing urdi and 
	using its existing snarfInfo.
		 Read snarfs until it has enough cells for all snarfs in fthe urdi. */
	
	Int32 snarfID;
	Int32 total;
	
	snarfID = Int32Zero;
	myTotal = urdi->usableSnarfs();
	mySnarfs = MuArray::array();
	myCurrentStart = Int32Zero;
	myCurrentIndex = IntegerVar0;
	myCurrentHandle = NULL;
	total = UInt32Zero;
	while (total < myTotal) {
		SPTR(SnarfHandle) handle;
		
		handle = view->makeReadHandle(snarfID);
		mySnarfs->atIntIntroduce(snarfID, handle);
		total += handle->getDataSize() / 4;
		snarfID += 1;
	}
}
/* testing */


UInt32 SnarfInfoHandler::actualHashForEqual (){
	return Heaper::takeOop();
}

#ifndef SNFINFOX_SXX
#include "snfinfox.sxx"
#endif /* SNFINFOX_SXX */



#endif /* SNFINFOX_CXX */

