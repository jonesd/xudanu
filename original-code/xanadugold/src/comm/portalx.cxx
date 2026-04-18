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

#ifndef PORTALX_CXX
#define PORTALX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef PORTALX_HXX
#include "portalx.hxx"
#endif /* PORTALX_HXX */

#ifndef PORTALX_IXX
#include "portalx.ixx"
#endif /* PORTALX_IXX */

#ifndef PORTALR_HXX
#include "portalr.hxx"
#endif /* PORTALR_HXX */

#ifndef PORTALR_IXX
#include "portalr.ixx"
#endif /* PORTALR_IXX */

#ifndef PORTALP_HXX
#include "portalp.hxx"
#endif /* PORTALP_HXX */

#ifndef PORTALP_IXX
#include "portalp.ixx"
#endif /* PORTALP_IXX */


#ifndef SOCKPTLX_HXX
#include "sockptlx.hxx"
#endif /* SOCKPTLX_HXX */




/* ************************************************************************ *
 * 
 *                    Class Portal 
 *
 * ************************************************************************ */


/* pseudo constructors */


RPTR(Portal) Portal::make (char * host, UInt32 port){
	WPTR(Portal) 	returnValue;
	returnValue = SocketPortal::make (host, port);
	return returnValue;
}
/* accessing */

	/* automatic 0-argument constructor */
Portal::Portal() {}



/* ************************************************************************ *
 * 
 *                    Class PacketPortal 
 *
 * ************************************************************************ */


/* protected: creation */


PacketPortal::PacketPortal () {
	CONSTRUCT(myReadStream,XnBufferedReadStream,(this, tcsj));
	CONSTRUCT(myWriteStream,XnBufferedWriteStream,(this, tcsj));
}


PacketPortal::PacketPortal (APTR(XnReadStream) readStr, APTR(XnWriteStream) writeStr) {
	myReadStream = readStr;
	myWriteStream = writeStr;
}
/* accessing */


RPTR(XnReadStream) PacketPortal::readStream (){
	return (XnReadStream*) myReadStream;
}


RPTR(XnWriteStream) PacketPortal::writeStream (){
	return (XnWriteStream*) myWriteStream;
}
/* internal */



/* ************************************************************************ *
 * 
 *                    Class PairPortal 
 *
 * ************************************************************************ */


/* creation */


RPTR(PairPortal) PairPortal::make (APTR(XnReadStream) read, APTR(XnWriteStream) write){
	RETURN_CONSTRUCT(PairPortal,(read, write));
}
/* accessing */


RPTR(XnReadStream) PairPortal::readStream (){
	return (XnReadStream*) myReadStream;
}


RPTR(XnWriteStream) PairPortal::writeStream (){
	return (XnWriteStream*) myWriteStream;
}
/* protected: creation */


PairPortal::PairPortal (APTR(XnReadStream) readStr, APTR(XnWriteStream) writeStr) {
	myReadStream = readStr;
	myWriteStream = writeStr;
}


void PairPortal::destruct (){
	{myReadStream->destroy();  myReadStream = NULL /* don't want stale (S/CHK)PTRs */;}
	{myWriteStream->destroy();  myWriteStream = NULL /* don't want stale (S/CHK)PTRs */;}
	this->Portal::destruct();
}



/* ************************************************************************ *
 * 
 *                    Class XnBufferedReadStream 
 *
 * ************************************************************************ */


/* accessing */


RPTR(UInt8Array) XnBufferedReadStream::contents (){
	if (myBuffer == NULL) {
		return CAST(UInt8Array,PrimIntArray::zeros(8, Int32Zero));
	}
	return CAST(UInt8Array,myBuffer->copy(myMax - myNext, myNext));
}


UInt8 XnBufferedReadStream::getByte (){
	UInt8 result;
	
	while (myNext >= myMax) {
		this->refill();
	}
	result = myBuffer->uIntAt(myNext);
	myNext += 1;
	return result;
}


void XnBufferedReadStream::getBytes (
		void * buffer, 
		Int32 count, 
		Int32 start/* = Int32Zero*/)
{
	/* Pour data directly into a buffer. */
	
	/* Thing to do !!!! */
	
	/* Make a more efficient version of this. */
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


BooleanVar XnBufferedReadStream::isReady (){
	this->refill();
	return myNext < myMax;
}


void XnBufferedReadStream::putBack (UInt8 c){
	if (myNext <= Int32Zero) {
		BLAST(BeginningOfPacket);
	}
	if (myBuffer->uIntAt(myNext - 1) != c) {
		BLAST(DoesNotMatch);
	}
	myNext -= 1;
}


void XnBufferedReadStream::refill (){
	if (!(myNext < myMax)) {
		if (myBuffer == NULL) {
			myBuffer = myPortal->readBuffer();
		}
		myMax = myPortal->readPacket(myBuffer, myBuffer->count());
		myNext = Int32Zero;
	}
}
/* creation */


XnBufferedReadStream::XnBufferedReadStream (APTR(PacketPortal) portal, TCSJ) {
	myPortal = portal;
	myBuffer = NULL;
	myNext = Int32Zero;
	myMax = myNext;
}
/* printing */


void XnBufferedReadStream::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myNext << ", " << myMax;
	if (myBuffer == NULL) {
		oo << ")";
		return;
		
	}
	oo << ", \"";
	{
		Int32 LoopFinal = myNext;
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
		Int32 LoopFinal = myMax;
		Int32 j = myNext;
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
 *                    Class XnBufferedWriteStream 
 *
 * ************************************************************************ */


/* printing */


void XnBufferedWriteStream::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << myNext;
	if (myBuffer == NULL) {
		oo << ")";
		return;
		
	}
	oo << ", " << myBuffer->count() << ", \"";
	{
		Int32 LoopFinal = myNext;
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
		Int32 j = myNext;
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
/* private */


void XnBufferedWriteStream::writePacket (){
	myPortal->writePacket(myBuffer, myNext);
	myNext = Int32Zero;
}
/* accessing */


void XnBufferedWriteStream::flush (){
	this->writePacket();
	myPortal->flush();
}


void XnBufferedWriteStream::putByte (UInt32 byte){
	if (myBuffer == NULL) {
		myBuffer = myPortal->writeBuffer();
	}
	myBuffer->storeUInt(myNext, byte);
	myNext += 1;
	if (myNext >= myBuffer->count()) {
		this->writePacket();
	}
}


void XnBufferedWriteStream::putData (APTR(UInt8Array) array){
	/* This should be optimized to use a memcpy or something 
	rather than a loop */
	
	UInt32 size;
	
	size = array->count();
	/* Thing to do !!!! */
	
	{
		Int32 LoopFinal = size - 1;
		Int32 i = Int32Zero;
		for (;;) {
			if (i > LoopFinal){
				break;
			}
			{
				this->putByte(array->uIntAt(i));
			}
			i += 1;
		}
	}
}


void XnBufferedWriteStream::putStr (char * string){
	/*  */
	/* This should be optimized to use a memcpy or something 
	rather than a loop */
	
	
	
	while (*string) {
		this->putByte(*string++);
	}
	
}
/* creation */


XnBufferedWriteStream::XnBufferedWriteStream (APTR(PacketPortal) portal, TCSJ) {
	myPortal = portal;
	myBuffer = NULL;
	myNext = Int32Zero;
}

#ifndef PORTALX_SXX
#include "portalx.sxx"
#endif /* PORTALX_SXX */


#ifndef PORTALR_SXX
#include "portalr.sxx"
#endif /* PORTALR_SXX */


#ifndef PORTALP_SXX
#include "portalp.sxx"
#endif /* PORTALP_SXX */



#endif /* PORTALX_CXX */

