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

#ifndef NSCOTTYX_CXX
#define NSCOTTYX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef NSCOTTYX_HXX
#include "nscottyx.hxx"
#endif /* NSCOTTYX_HXX */

#ifndef NSCOTTYX_IXX
#include "nscottyx.ixx"
#endif /* NSCOTTYX_IXX */

#ifndef NSCOTTYP_HXX
#include "nscottyp.hxx"
#endif /* NSCOTTYP_HXX */

#ifndef NSCOTTYP_IXX
#include "nscottyp.ixx"
#endif /* NSCOTTYP_IXX */




/* ************************************************************************ *
 * 
 *                    Class XnReadStream 
 *
 * ************************************************************************ */


/* creation */


RPTR(XnReadStream) XnReadStream::make (APTR(UInt8Array) collection){
	RETURN_CONSTRUCT(ReadArrayStream,(collection, tcsj));
}


RPTR(XnReadStream) XnReadStream::make (
		UInt8 * dataP, 
		Int32 start, 
		Int32 count)
{
	WPTR(XnReadStream) 	returnValue;
	returnValue = ReadMemStream::make (dataP, start, count);
	return returnValue;
}
/* accessing */


void XnReadStream::getBytes (
		void * buffer, 
		Int32 count, 
		Int32 start/* = Int32Zero*/)
{
	/* Pour data directly into a buffer. */
	
	{
		Int32 LoopFinal = start + count;
		Int32 i = start;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				((char * ) buffer)[i] = this->getByte();
			}
			i += 1;
		}
	}
}
/* testing */


UInt32 XnReadStream::actualHashForEqual (){
	return Heaper::takeOop();
}

	/* automatic 0-argument constructor */
XnReadStream::XnReadStream() {}



/* ************************************************************************ *
 * 
 *                    Class XnWriteStream 
 *
 * ************************************************************************ */


/* creation */


RPTR(XnWriteStream) XnWriteStream::make (APTR(UInt8Array) array){
	/* Make a stream which writes into the given array */
	
	RETURN_CONSTRUCT(WriteArrayStream,(array, tcsj));
}


RPTR(XnWriteStream) XnWriteStream::make (
		UInt8 * dataP, 
		Int32 start, 
		Int32 count)
{
	WPTR(XnWriteStream) 	returnValue;
	returnValue = WriteMemStream::make (dataP, start, count);
	return returnValue;
}
/* accessing */
/* testing */


UInt32 XnWriteStream::actualHashForEqual (){
	return Heaper::takeOop();
}

	/* automatic 0-argument constructor */
XnWriteStream::XnWriteStream() {}



/* ************************************************************************ *
 * 
 *                    Class   WriteVariableArrayStream 
 *
 * ************************************************************************ */


/* creation */


RPTR(WriteVariableArrayStream) WriteVariableArrayStream::make (Int32 size){
	RETURN_CONSTRUCT(WriteVariableArrayStream,(UInt8Array::make (size), tcsj));
}
/* WriteVariableArrayStream is used to put an unpredictable amount of 
data into a UInt8Array.  The array method returns the current state 
of the buffer. */


/* accessing */


void WriteVariableArrayStream::flush (){
	/* We can't test for underflow because we deliberately overestimate 
		 the size when we don't have exact information on where things go. */
	/* myIndex == myMax assert: 'Must fill up the space' */
	
	
}


void WriteVariableArrayStream::putByte (UInt32 byte){
	if (myIndex >= myCollection->count()) {
		myCollection = CAST(UInt8Array,myCollection->copyGrow(myIndex * 2));
	}
	myCollection->storeUInt(myIndex, byte);
	myIndex += 1;
}


void WriteVariableArrayStream::putData (APTR(UInt8Array) array){
	{
		Int32 LoopFinal = array->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				this->putByte(array->uIntAt(i));
			}
			i += 1;
		}
	}
}


void WriteVariableArrayStream::putStr (char * string){
	
	
	while (*string) {
		this->putByte(*string++);
	}
	
}
/* creation */


WriteVariableArrayStream::WriteVariableArrayStream (APTR(UInt8Array) array, TCSJ) {
	myCollection = array;
	myIndex = UInt32Zero;
}
/* printing */


void WriteVariableArrayStream::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myIndex << ", " << myCollection->count() - myIndex << ", \"";
	{
		Int32 LoopFinal = myIndex;
		Int32 i = UInt32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				oo.put((char ) myCollection->uIntAt(i));
			}
			i += 1;
		}
	}
	oo << "<-|->";
	{
		Int32 LoopFinal = myCollection->count();
		Int32 j = myIndex;
		for (;;) {
			if (j >= LoopFinal){
				break;
			}
			{
				oo.put((char ) myCollection->uIntAt(j));
			}
			j += 1;
		}
	}
	oo << "\")";
}
/* special */


RPTR(UInt8Array) WriteVariableArrayStream::array (){
	return CAST(UInt8Array,myCollection->copy(myIndex));
}



/* ************************************************************************ *
 * 
 *                    Class ReadArrayStream 
 *
 * ************************************************************************ */


/* accessing */


UInt8 ReadArrayStream::getByte (){
	UInt8 result;
	
	result = myBuffer->uIntAt(myIndex);
	myIndex += 1;
	return result;
}


void ReadArrayStream::putBack (UInt8 b){
	if ( ! (myIndex > UInt32Zero) ) {
		BLAST(Must_have_room);
	}
	myIndex -= 1;
	if ( ! (myBuffer->uIntAt(myIndex) == b) ) {
		BLAST(Must_be_same_character);
	}
}


void ReadArrayStream::refill (){
	
}
/* creation */


ReadArrayStream::ReadArrayStream (APTR(UInt8Array) collection, TCSJ) {
	myBuffer = collection;
	myIndex = UInt32Zero;
}
/* printing */


void ReadArrayStream::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myIndex << ", " << myBuffer->count() - myIndex << ", \"";
	{
		Int32 LoopFinal = myIndex;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				oo.put((char ) myBuffer->uIntAt(i));
			}
			i += 1;
		}
	}
	oo << "<-|->";
	{
		Int32 LoopFinal = myBuffer->count();
		Int32 j = myIndex;
		for (;;) {
			if (j >= LoopFinal){
				break;
			}
			{
				oo.put((char ) myBuffer->uIntAt(j));
			}
			j += 1;
		}
	}
	oo << "\")";
}



/* ************************************************************************ *
 * 
 *                    Class ReadMemStream 
 *
 * ************************************************************************ */



/* Initializers for ReadMemStream */

GPTR(InstanceCache) ReadMemStream::SomeStreams = NULL;



BEGIN_INIT_TIME(ReadMemStream,initTimeNonInherited) {
	ReadMemStream::SomeStreams = InstanceCache::make (8);
} END_INIT_TIME(ReadMemStream,initTimeNonInherited);



/* Initializers for ReadMemStream */






/* creation */


RPTR(XnReadStream) ReadMemStream::make (
		UInt8 * dataP, 
		Int32 start, 
		Int32 count)
{
	SPTR(Heaper) result;
	
	result = ReadMemStream::SomeStreams->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(ReadMemStream,(dataP, start, count));
	} else {
		WPTR(XnReadStream) 	returnValue;
		returnValue = new (result) ReadMemStream(dataP, start, count);
		return returnValue;
	}
}
/* accessing */


UInt8 ReadMemStream::getByte (){
	UInt8 result;
	
	if ( ! (myIndex < myEnd) ) {
		BLAST(Stay_within_stream);
	}
	
	result = myBuffer[myIndex];
	
	myIndex += 1;
	return result;
}


void ReadMemStream::putBack (UInt8 b){
	if ( ! (myIndex > myStart) ) {
		BLAST(Must_have_room);
	}
	myIndex -= 1;
	
	if ( ! (myBuffer[myIndex] == b) ) {
		BLAST(Must_be_same_character);
	}
	
}


void ReadMemStream::refill (){
	
}
/* creation */


ReadMemStream::ReadMemStream (
		UInt8 * collection, 
		Int32 index, 
		Int32 count) 
{
	myBuffer = collection;
	myIndex = index;
	myStart = index;
	myEnd = index + count;
}


void ReadMemStream::destroy (){
	if (!ReadMemStream::SomeStreams->store(this)) {
		this->XnReadStream::destroy();
	}
}
/* printing */


void ReadMemStream::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myIndex - myStart << ", " << myEnd - myIndex << ", \"";
	{
		Int32 LoopFinal = myIndex;
		Int32 i = myStart;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				oo.put((char ) myBuffer[i]);
			}
			i += 1;
		}
	}
	oo << "<-|->";
	{
		Int32 LoopFinal = myEnd;
		Int32 j = myIndex;
		for (;;) {
			if (j >= LoopFinal){
				break;
			}
			{
				oo.put((char ) myBuffer[j]);
			}
			j += 1;
		}
	}
	oo << "\")";
}



/* ************************************************************************ *
 * 
 *                    Class WriteArrayStream 
 *
 * ************************************************************************ */


/* accessing */


void WriteArrayStream::flush (){
	/* We can't test for underflow because we deliberately overestimate 
		 the size when we don't have exact information on where things go. */
	/* myIndex == myMax assert: 'Must fill up the space' */
	
	
}


void WriteArrayStream::putByte (UInt32 byte){
	if (myIndex >= myCollection->count()) {
		BLAST(IndexOutOfBounds);
	}
	myCollection->storeUInt(myIndex, byte);
	myIndex += 1;
}


void WriteArrayStream::putData (APTR(UInt8Array) array){
	if (myIndex + array->count() >= myCollection->count()) {
		BLAST(IndexOutOfBounds);
	}
	{
		Int32 LoopFinal = array->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				this->putByte(array->uIntAt(i));
			}
			i += 1;
		}
	}
}


void WriteArrayStream::putStr (char * string){
	
	
	while (*string) {
		this->putByte(*string++);
	}
	
}
/* creation */


WriteArrayStream::WriteArrayStream (APTR(UInt8Array) array, TCSJ) {
	myCollection = array;
	myIndex = UInt32Zero;
}
/* printing */


void WriteArrayStream::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myIndex << ", " << myCollection->count() - myIndex << ", \"";
	{
		Int32 LoopFinal = myIndex;
		Int32 i = UInt32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				oo.put((char ) myCollection->uIntAt(i));
			}
			i += 1;
		}
	}
	oo << "<-|->";
	{
		Int32 LoopFinal = myCollection->count();
		Int32 j = myIndex;
		for (;;) {
			if (j >= LoopFinal){
				break;
			}
			{
				oo.put((char ) myCollection->uIntAt(j));
			}
			j += 1;
		}
	}
	oo << "\")";
}



/* ************************************************************************ *
 * 
 *                    Class WriteMemStream 
 *
 * ************************************************************************ */



/* Initializers for WriteMemStream */

GPTR(InstanceCache) WriteMemStream::SomeStreams = NULL;



BEGIN_INIT_TIME(WriteMemStream,initTimeNonInherited) {
	WriteMemStream::SomeStreams = InstanceCache::make (8);
} END_INIT_TIME(WriteMemStream,initTimeNonInherited);



/* Initializers for WriteMemStream */






/* creation */


RPTR(XnWriteStream) WriteMemStream::make (
		UInt8 * dataP, 
		Int32 start, 
		Int32 count)
{
	SPTR(Heaper) result;
	
	result = WriteMemStream::SomeStreams->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(WriteMemStream,(dataP, start, count));
	} else {
		WPTR(XnWriteStream) 	returnValue;
		returnValue = new (result) WriteMemStream(dataP, start, count);
		return returnValue;
	}
}
/* accessing */


void WriteMemStream::flush (){
	/* We can't test for underflow because we deliberately overestimate 
		 the size when we don't have exact information on where things go. */
	/* myIndex == myMax assert: 'Must fill up the space' */
	
	
}


void WriteMemStream::putByte (UInt32 byte){
	if ( ! (myIndex < myMax) ) {
		BLAST(Overrun);
	}
	myCollection[myIndex] = byte;
	myIndex += 1;
}


void WriteMemStream::putData (APTR(UInt8Array) array){
	Int32 index;
	Int32 count;
	
	index = myIndex;
	count = array->count();
	if ( ! (index + count < myMax) ) {
		BLAST(Overrun);
	}
	{
		Int32 LoopFinal = count;
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				myCollection[index + i] = array->uIntAt(i);
			}
			i += 1;
		}
	}
	myIndex = index + count;
}


void WriteMemStream::putStr (char * string){
	
	
	while (*string) {
		this->putByte(*string++);
	}
	
}
/* creation */


WriteMemStream::WriteMemStream (
		UInt8 * collection, 
		Int32 index, 
		Int32 count) 
{
	if ( ! (index >= Int32Zero) ) {
		BLAST(Must_start_inside_buffer);
	}
	myCollection = collection;
	myIndex = index;
	myMax = myIndex + count;
	myStart = index;
}


void WriteMemStream::destroy (){
	if (!WriteMemStream::SomeStreams->store(this)) {
		this->XnWriteStream::destroy();
	}
}
/* debugging */


char * WriteMemStream::contents (){
	
	char * result = new char [myMax - myStart];
	MEMMOVE(result, myCollection + myStart, myMax - myStart);
	return result;
	
}


Int32 WriteMemStream::size (){
	return myIndex - myStart;
}
/* printing */


void WriteMemStream::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myIndex - myStart << ", " << myMax - myIndex << ", \"";
	{
		Int32 LoopFinal = myIndex;
		Int32 i = myStart;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				oo.put((char ) myCollection[i]);
			}
			i += 1;
		}
	}
	oo << "<-|->";
	{
		Int32 LoopFinal = myMax;
		Int32 j = myIndex;
		for (;;) {
			if (j >= LoopFinal){
				break;
			}
			{
				oo.put((char ) myCollection[j]);
			}
			j += 1;
		}
	}
	oo << "\")";
}

#ifndef NSCOTTYX_SXX
#include "nscottyx.sxx"
#endif /* NSCOTTYX_SXX */


#ifndef NSCOTTYP_SXX
#include "nscottyp.sxx"
#endif /* NSCOTTYP_SXX */



#endif /* NSCOTTYX_CXX */

