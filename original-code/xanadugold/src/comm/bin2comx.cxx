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

#ifndef BIN2COMX_CXX
#define BIN2COMX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef BIN2COMX_HXX
#include "bin2comx.hxx"
#endif /* BIN2COMX_HXX */

#ifndef BIN2COMX_IXX
#include "bin2comx.ixx"
#endif /* BIN2COMX_IXX */

#ifndef BIN2COMP_HXX
#include "bin2comp.hxx"
#endif /* BIN2COMP_HXX */

#ifndef BIN2COMP_IXX
#include "bin2comp.ixx"
#endif /* BIN2COMP_IXX */


#ifndef NEGOTI8X_HXX
#include "negoti8x.hxx"
#endif /* NEGOTI8X_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef STRINGX_HXX
#include "stringx.hxx"
#endif /* STRINGX_HXX */




/* ************************************************************************ *
 * 
 *                    Class Binary2XcvrMaker 
 *
 * ************************************************************************ */



/* Initializers for Binary2XcvrMaker */

/* Initializer inherited from XcvrMaker */


BEGIN_INIT_TIME(Binary2XcvrMaker,initTimeInherited) {
	SPTR(XcvrMaker) maker;
	
	REQUIRES (ProtocolBroker);
	CONSTRUCT(maker,Binary2XcvrMaker,());
	ProtocolBroker::registerXcvrProtocol(maker);
} END_INIT_TIME(Binary2XcvrMaker,initTimeInherited);



/* Initializers for Binary2XcvrMaker */

/* Initializer inherited from XcvrMaker */



/* creation */


RPTR(XcvrMaker) Binary2XcvrMaker::make (){
	RETURN_CONSTRUCT(Binary2XcvrMaker,());
}
/* xcvr creation */


RPTR(SpecialistRcvr) Binary2XcvrMaker::makeRcvr (APTR(TransferSpecialist) specialist, APTR(XnReadStream) readStream){
	WPTR(SpecialistRcvr) 	returnValue;
	returnValue = Binary2Rcvr::make (specialist, readStream);
	return returnValue;
}


RPTR(SpecialistXmtr) Binary2XcvrMaker::makeXmtr (APTR(TransferSpecialist) specialist, APTR(XnWriteStream) writeStream){
	WPTR(SpecialistXmtr) 	returnValue;
	returnValue = Binary2Xmtr::make (specialist, writeStream);
	return returnValue;
}
/* testing */


char * Binary2XcvrMaker::id (){
	char * 	returnValue;
	returnValue = "binary2";
	return returnValue;
}

	/* automatic 0-argument constructor */
Binary2XcvrMaker::Binary2XcvrMaker() {}



/* ************************************************************************ *
 * 
 *                    Class Binary2Rcvr 
 *
 * ************************************************************************ */



/* Initializers for Binary2Rcvr */

GPTR(InstanceCache) Binary2Rcvr::SomeRcvrs = NULL;



BEGIN_INIT_TIME(Binary2Rcvr,initTimeNonInherited) {
	Binary2Rcvr::SomeRcvrs = InstanceCache::make (8);
} END_INIT_TIME(Binary2Rcvr,initTimeNonInherited);



/* Initializers for Binary2Rcvr */






/* creation */


RPTR(SpecialistRcvr) Binary2Rcvr::make (APTR(TransferSpecialist) specialist, APTR(XnReadStream) stream){
	SPTR(Heaper) result;
	
	result = Binary2Rcvr::SomeRcvrs->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(Binary2Rcvr,(specialist, stream));
	} else {
		WPTR(SpecialistRcvr) 	returnValue;
		returnValue = new (result) Binary2Rcvr(specialist, stream);
		return returnValue;
	}
}
/* receiving */


BooleanVar Binary2Rcvr::receiveBooleanVar (){
	BooleanVar result;
	
	this->startThing();
	result = myStream->getByte();
	this->endThing();
	if (result == 1) {
		return TRUE;
	} else {
		if (result == Int0) {
			return FALSE;
		} else {
			BLAST(InvalidRequest);
		}
	}
	/* fodder */
	return FALSE;
}


RPTR(Category) OR(NULL) Binary2Rcvr::receiveCategory (){
	IntegerVar num;
	
	num = this->getIntegerVar();
	if (num == IntegerVar0) {
		myDepth -= 1;
		this->endThing();
		return NULL;
	} else {
		WPTR(Category) OR(NULL) 	returnValue;
		returnValue = this->specialist()->getCategoryFor(num - 1);
		return returnValue;
	}
}


void Binary2Rcvr::receiveData (APTR(UInt8Array) array){
	/* Fill the array with data from the stream. */
	
	this->startThing();
	{
		Int32 LoopFinal = array->count() - 1;
		Int32 i = Int32Zero;
		for (;;) {
			if (i > LoopFinal){
				break;
			}
			{
				array->storeUInt(i, myStream->getByte());
			}
			i += 1;
		}
	}
	this->endThing();
}


IEEEDoubleVar Binary2Rcvr::receiveIEEEDoubleVar (){
	/* | result {IEEEDoubleVar} |
		self startThing.
		result _ Double make: self getIntegerVar with: self getIntegerVar.
		self endThing.
		^result */
	
	BLAST(NOT_YET_IMPLEMENTED);
	return NULL;
}


Int32 Binary2Rcvr::receiveInt32 (){
	Int32 result;
	
	this->startThing();
	result = this->getIntegerVar().asLong();
	this->endThing();
	return result;
}


Int8 Binary2Rcvr::receiveInt8 (){
	Int8 result;
	
	this->startThing();
	result = myStream->getByte();
	
	this->endThing();
	return result;
}


IntegerVar Binary2Rcvr::receiveIntegerVar (){
	IntegerVar result;
	
	this->startThing();
	result = this->getIntegerVar();
	this->endThing();
	return result;
}


char * Binary2Rcvr::receiveString (){
	Int32 size;
	char * result;
	
	size = this->getIntegerVar().asLong();
	this->startThing();
	
	
	result = new char[size+1];
	char c;
	int soFar = 0;
	for (; soFar < size ; soFar++) {
		c = myStream->getByte();
		result[soFar] = c;
	}
	result[soFar] = '\0';
	
	this->endThing();
	char * 	returnValue;
	returnValue = result;
	return returnValue;
}


UInt32 Binary2Rcvr::receiveUInt32 (){
	UInt32 result;
	
	this->startThing();
	result = this->getIntegerVar().asLong();
	this->endThing();
	return result;
}


UInt8 Binary2Rcvr::receiveUInt8 (){
	UInt8 result;
	
	this->startThing();
	result = myStream->getByte();
	this->endThing();
	return result;
}
/* protected: specialist */


void Binary2Rcvr::endOfInstance (){
	myDepth -= 1;
	this->endThing();
}


void Binary2Rcvr::endPacket (){
	if ( ! (myStream->getByte() == uint8('!')) ) {
		BLAST(End_of_packet_marker_required);
	}
	if ( ! (myStream->getByte() == uint8('!')) ) {
		BLAST(End_of_packet_marker_required);
	}
	this->SpecialistRcvr::endPacket();
}


RPTR(Category) OR(NULL) Binary2Rcvr::fetchStartOfInstance (){
	this->startThing();
	myDepth += 1;
	WPTR(Category) OR(NULL) 	returnValue;
	returnValue = this->receiveCategory();
	return returnValue;
}


IntegerVar Binary2Rcvr::getIntegerVar (){
	/* A new representation that requires less shifting (eventually). */
	/* 
	7/1 		0<7>
	14/2	10<6>		<8>
	21/3	110<5>		<16>
	28/4	1110<4>		<24>
	35/5	11110<3>	<32>
	42/6	111110<2>	<40>
	49/7	1111110<1>	<48>
	56/8	11111110 	<56>
	?/?	11111111  <humber count>
	 */
	
	UInt8 byte;
	WPTR(XnReadStream) stream;
	UInt8 mask;
	Int32 count;
	Int32 num;
	
	/* count is bytes following first word or -1 if bignum 
	meaning next byte is humber for actual count */
	stream = this->stream();
	byte = stream->getByte();
	if (byte <= 63) {
		return byte;
	}
	if (byte <= 127) {
		return byte - 128;
	}
	if (byte <= 191) {
		mask = 63;
		count = 1;
	} else {
		if (byte <= 223) {
			mask = 31;
			count = 2;
		} else {
			if (byte <= 239) {
				mask = 15;
				count = 3;
			} else {
				if (byte <= 247) {
					mask = 7;
					count = 4;
				} else {
					BLAST(NOT_YET_IMPLEMENTED);
				}
			}
		}
	}
	byte &= mask;
	if ((byte & (~mask >> 1 & mask)) != Int32Zero) {
		byte |= ~mask;
		num = -1;
	} else {
		num = Int32Zero;
		{	BooleanVar crutch_Flag;
			/* count > 3 && byte != (byte & mask) */
			
			crutch_Flag = count > 3;
			if(crutch_Flag) {
				crutch_Flag = byte != (byte & mask);
			}
			if (crutch_Flag) {
				BLAST(NOT_YET_IMPLEMENTED);
			}
		}
	}
	num = (num << 8) + byte;
	{
		Int32 LoopFinal = count;
		Int32 i = 1;
		for (;;) {
			if (i > LoopFinal){
				break;
			}
			{
				num = (num << 8) + stream->getByte();
			}
			i += 1;
		}
	}
	return num;
}
/* private: */


void Binary2Rcvr::endThing (){
	if (myDepth == IntegerVar0) {
		this->endPacket();
	}
}


void Binary2Rcvr::startThing (){
	if (myDepth == IntegerVar0) {
		myStream->refill();
	}
}
/* creation */


Binary2Rcvr::Binary2Rcvr (APTR(TransferSpecialist) specialist, APTR(XnReadStream) stream) 
	: SpecialistRcvr(specialist, tcsj) {
	myStream = stream;
	myDepth = IntegerVar0;
}


void Binary2Rcvr::destroy (){
	if (!Binary2Rcvr::SomeRcvrs->store(this)) {
		this->SpecialistRcvr::destroy();
	}
}
/* printing */


void Binary2Rcvr::printOn (ostream& oo){
	oo << this->getCategory()->name() << "( " << myStream << ")";
}
/* protected: accessing */



/* ************************************************************************ *
 * 
 *                    Class Binary2Xmtr 
 *
 * ************************************************************************ */



/* Initializers for Binary2Xmtr */

Int32 Binary2Xmtr::MaxNumberLength = 400;
UInt8 * Binary2Xmtr::NumberBuffer = new UInt8[Binary2Xmtr::MaxNumberLength];

GPTR(InstanceCache) Binary2Xmtr::SomeXmtrs = NULL;



BEGIN_INIT_TIME(Binary2Xmtr,initTimeNonInherited) {
	Binary2Xmtr::SomeXmtrs = InstanceCache::make (8);
} END_INIT_TIME(Binary2Xmtr,initTimeNonInherited);



/* Initializers for Binary2Xmtr */






/* creation */


RPTR(SpecialistXmtr) Binary2Xmtr::make (APTR(TransferSpecialist) specialist, APTR(XnWriteStream) stream){
	SPTR(Heaper) result;
	
	result = Binary2Xmtr::SomeXmtrs->fetch();
	if (result == NULL) {
		RETURN_CONSTRUCT(Binary2Xmtr,(specialist, stream));
	} else {
		WPTR(SpecialistXmtr) 	returnValue;
		returnValue = new (result) Binary2Xmtr(specialist, stream);
		return returnValue;
	}
}
/* sending */


void Binary2Xmtr::sendBooleanVar (BooleanVar b){
	if (b) {
		myStream->putByte(1);
	} else {
		myStream->putByte(Int0);
	}
	this->endThing();
}


void Binary2Xmtr::sendCategory (APTR(Category) cat){
	this->putIntegerVar(this->specialist()->numberOfCategory(cat) + 1);
	this->endThing();
}


void Binary2Xmtr::sendIEEEDoubleVar (IEEEDoubleVar x){
	/* Sending the normal decimal approximation doesn't work 
	because it introduces 
		roundoff error. What we need to do instead is send a hex 
	encoding of the IEEE 
		double precision (64-bit) representation of the number. For 
	clarity in the 
		textual protocol, we also include the decimal approximation 
	in a comment. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	/* self putIntegerVar: x DOTmantissa.
			self putIntegerVar: x DOTexponent. */
	this->endThing();
}


void Binary2Xmtr::sendInt32 (Int32 n){
	this->putIntegerVar(n);
	this->endThing();
}


void Binary2Xmtr::sendInt8 (Int8 n){
	myStream->putByte(n % 256);
	this->endThing();
}


void Binary2Xmtr::sendIntegerVar (IntegerVar n){
	this->putIntegerVar(n);
	this->endThing();
}


void Binary2Xmtr::sendString (char * s){
	this->putIntegerVar(IntegerVar(::strlen(s)));
	myStream->putStr(s);
	this->endThing();
}


void Binary2Xmtr::sendUInt32 (UInt32 n){
	this->putIntegerVar(n);
	this->endThing();
}


void Binary2Xmtr::sendUInt4 (UInt4 n){
	this->putIntegerVar(n);
	this->endThing();
}


void Binary2Xmtr::sendUInt8 (UInt8 n){
	myStream->putByte(n);
	this->endThing();
}


void Binary2Xmtr::sendUInt8Data (APTR(UInt8Array) array){
	myStream->putData(array);
	this->endThing();
}
/* printing */


void Binary2Xmtr::printOn (ostream& oo){
	oo << this->getCategory()->name() << "( " << myStream << ")";
}
/* protected: sending */


void Binary2Xmtr::endPacket (){
	/* Put in a separator pattern so we can detect the packets visually. */
	
	myStream->putByte(uint8('!'));
	myStream->putByte(uint8('!'));
	myStream->flush();
	this->SpecialistXmtr::endPacket();
}


void Binary2Xmtr::endThing (){
	if (myDepth <= IntegerVar0) {
		this->endPacket();
	}
}


void Binary2Xmtr::putIntegerVar (IntegerVar num){
	/* Send a Dean style humber.  Like Drexler style, except all 
	the tag bits go into the first byte. */
	/* 
	7/1 		0<7>
	14/2	10<6>		<8>
	21/3	110<5>		<16>
	28/4	1110<4>		<24>
	35/5	11110<3>	<32>
	42/6	111110<2>	<40>
	49/7	1111110<1>	<48>
	56/8	11111110 	<56>
	?/?	11111111  <humber count>
	 */
	
	IntegerVar abs;
	WPTR(XnWriteStream) stream;
	Int32 val;
	
	stream = this->stream();
	val = num.asLong();
	if (val < Int32Zero) {
		abs = -val;
	} else {
		abs = val;
	}
	/* 2**6 */
	if (abs < 64) {
		stream->putByte(val & 127);
		return;
		
	}
	/* 2**13 */
	if (abs < 8192) {
		stream->putByte(val >> 8 & 63 | 128);
		stream->putByte(val & 255);
		return;
		
	}
	/* 2**20 */
	if (abs < 1048576) {
		stream->putByte(val >> 16 & 31 | 192);
		stream->putByte(val >> 8 & 255);
		stream->putByte(val & 255);
		return;
		
	}
	/* 2**27 */
	if (abs < 134217728) {
		stream->putByte(val >> 24 & 15 | 224);
		stream->putByte(val >> 16 & 255);
		stream->putByte(val >> 8 & 255);
		stream->putByte(val & 255);
		return;
		
	}
	/* abs < (2**34) */
	if (TRUE) {
		stream->putByte(val >> 32 & 7 | 240);
		stream->putByte(val >> 24 & 255);
		stream->putByte(val >> 16 & 255);
		stream->putByte(val >> 8 & 255);
		stream->putByte(val & 255);
		return;
		
	}
	/* humber case */
	/* Eric -- Thing to do !!!! */
	
}


void Binary2Xmtr::sendNULL (){
	myStream->putByte(Int0);
	this->endThing();
}


void Binary2Xmtr::startNewInstance (APTR(Category) cat){
	/* start sending an instance of a particular class. Add one 
	because 0 means NULL */
	
	myDepth += 1;
	this->sendCategory(cat);
}
/* creation */


Binary2Xmtr::Binary2Xmtr (APTR(TransferSpecialist) specialist, APTR(XnWriteStream) stream) 
	: SpecialistXmtr(specialist, tcsj) {
	myStream = stream;
	myDepth = IntegerVar0;
}


void Binary2Xmtr::destroy (){
	if (!Binary2Xmtr::SomeXmtrs->store(this)) {
		this->SpecialistXmtr::destroy();
	}
}
/* specialist sending */


void Binary2Xmtr::endInstance (){
	/* end sending an instance */
	
	myDepth -= 1;
	this->endThing();
}

#ifndef BIN2COMX_SXX
#include "bin2comx.sxx"
#endif /* BIN2COMX_SXX */


#ifndef BIN2COMP_SXX
#include "bin2comp.sxx"
#endif /* BIN2COMP_SXX */



#endif /* BIN2COMX_CXX */

