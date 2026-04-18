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

#ifndef TXTCOMMX_CXX
#define TXTCOMMX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef TXTCOMMX_HXX
#include "txtcommx.hxx"
#endif /* TXTCOMMX_HXX */

#ifndef TXTCOMMX_IXX
#include "txtcommx.ixx"
#endif /* TXTCOMMX_IXX */

#ifndef TXTCOMMP_HXX
#include "txtcommp.hxx"
#endif /* TXTCOMMP_HXX */

#ifndef TXTCOMMP_IXX
#include "txtcommp.ixx"
#endif /* TXTCOMMP_IXX */


#ifndef COOKBKX_HXX
#include "cookbkx.hxx"
#endif /* COOKBKX_HXX */

#ifndef NEGOTI8X_HXX
#include "negoti8x.hxx"
#endif /* NEGOTI8X_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef STRINGX_HXX
#include "stringx.hxx"
#endif /* STRINGX_HXX */




/* ************************************************************************ *
 * 
 *                    Class TextyXcvrMaker 
 *
 * ************************************************************************ */



/* Initializers for TextyXcvrMaker */

/* Initializer inherited from XcvrMaker */


BEGIN_INIT_TIME(TextyXcvrMaker,initTimeInherited) {
	SPTR(XcvrMaker) maker;
	
	REQUIRES (ProtocolBroker);
	CONSTRUCT(maker,TextyXcvrMaker,());
	ProtocolBroker::registerXcvrProtocol(maker);
} END_INIT_TIME(TextyXcvrMaker,initTimeInherited);



/* Initializers for TextyXcvrMaker */

/* Initializer inherited from XcvrMaker */



/* creation */


RPTR(XcvrMaker) TextyXcvrMaker::make (){
	RETURN_CONSTRUCT(TextyXcvrMaker,());
}


RPTR(Rcvr) TextyXcvrMaker::makeReader (APTR(XnReadStream) stream){
	RETURN_CONSTRUCT(TextyRcvr,(TransferSpecialist::make (Cookbook::make ()), stream));
}


RPTR(Xmtr) TextyXcvrMaker::makeWriter (APTR(XnWriteStream) stream){
	RETURN_CONSTRUCT(TextyXmtr,(TransferSpecialist::make (Cookbook::make ()), stream));
}
/* xcvr creation */


RPTR(SpecialistRcvr) TextyXcvrMaker::makeRcvr (APTR(TransferSpecialist) specialist, APTR(XnReadStream) readStream){
	RETURN_CONSTRUCT(TextyRcvr,(specialist, readStream));
}


RPTR(SpecialistXmtr) TextyXcvrMaker::makeXmtr (APTR(TransferSpecialist) specialist, APTR(XnWriteStream) writeStream){
	RETURN_CONSTRUCT(TextyXmtr,(specialist, writeStream));
}
/* testing */


char * TextyXcvrMaker::id (){
	char * 	returnValue;
	returnValue = "texty";
	return returnValue;
}

	/* automatic 0-argument constructor */
TextyXcvrMaker::TextyXcvrMaker() {}



/* ************************************************************************ *
 * 
 *                    Class TextyRcvr 
 *
 * ************************************************************************ */



/* Initializers for TextyRcvr */

Int4 TextyRcvr::ReceiveStringBufferSize = 4096;
/* 4088 is longest allowable C++ class name. */
static char permReceiveStringBuffer[4096];
char * TextyRcvr::ReceiveStringBuffer = permReceiveStringBuffer;




/* Initializers for TextyRcvr */



/* creation */


RPTR(SpecialistRcvr) TextyRcvr::make (APTR(TransferSpecialist) specialist, APTR(XnReadStream) stream){
	RETURN_CONSTRUCT(TextyRcvr,(specialist, stream));
}
/* receiving */


BooleanVar TextyRcvr::receiveBooleanVar (){
	BooleanVar result;
	
	this->startThing();
	result = this->skipWhiteSpace();
	this->endThing();
	if (result == '1') {
		return TRUE;
	} else {
		if (result == '0') {
			return FALSE;
		} else {
			BLAST(InvalidRequest);
		}
	}
	/* fodder */
	return FALSE;
}


RPTR(Category) TextyRcvr::receiveCategory (){
	this->getIdentifier(TextyRcvr::ReceiveStringBuffer, TextyRcvr::ReceiveStringBufferSize - 1);
	if (::strcmp(TextyRcvr::ReceiveStringBuffer, "NULL") == UInt32Zero) {
		this->endThing();
		return NULL;
	}
	
	WPTR(Category) 	returnValue;
	returnValue = Category::find(TextyRcvr::ReceiveStringBuffer);
	return returnValue;
}


void TextyRcvr::receiveData (APTR(UInt8Array) array){
	/* Fill the array with data from the stream. */
	
	this->startThing();
	this->getCharToken('\"');
	{
		Int32 LoopFinal = array->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				array->storeUInt(i, myStream->getByte());
			}
			i += 1;
		}
	}
	this->getCharToken('\"');
	this->endThing();
}


IEEEDoubleVar TextyRcvr::receiveIEEEDoubleVar (){
	this->startThing();
	BLAST(NOT_YET_IMPLEMENTED);
	this->endThing();
	return 0.0;
}


Int32 TextyRcvr::receiveInt32 (){
	Int32 result;
	
	this->startThing();
	result = this->receiveNumber().asLong();
	this->endThing();
	return result;
}


Int8 TextyRcvr::receiveInt8 (){
	Int8 result;
	
	this->startThing();
	result = this->receiveNumber().asInt();
	this->endThing();
	return result;
}


IntegerVar TextyRcvr::receiveIntegerVar (){
	IntegerVar result;
	
	this->startThing();
	result = this->receiveNumber();
	this->endThing();
	/* [^IntegerVar localIntVar: self with: #tcsj] translateOnly. */
	return result;
}


char * TextyRcvr::receiveString (){
	char * result;
	
	this->startThing();
	
	char *buf = TextyRcvr::ReceiveStringBuffer;
	UInt32 max = TextyRcvr::ReceiveStringBufferSize;
	this->getCharToken('"');
	for (char c = myStream->getByte();
	  c != '\"';
	  c = myStream->getByte()) {
		if (max <= 1) {
			BLAST(STRING_TOO_LONG);
		}
		max -= 1;
		if (c != '\\') {
			*buf++ = c;
		} else {
			c = myStream->getByte();
			switch (c) {
			case 'a':
				*buf++ = ALERT_CHAR;
				break;
			case '?':
/* ANSI permits, but does not require, '?' to be escaped.  Therefore, even */
/*  though we do not send it escaped, for consistency with the standard, we */
/*  can receive it either way.  */
				*buf++ = '?';
				break;
			case '\n':
				max += 1;
				break;
			case 'n':
				*buf++ = '\n';
				break;
			case 't':
				*buf++ = '\t';
				break;
			case 'b':
				*buf++ = '\b';
				break;
			case 'r':
				*buf++ = '\r';
				break;
			case 'f':
				*buf++ = '\f';
				break;
			case 'v':
				*buf++ = '\v';
				break;
			case '\\':
				*buf++ = '\\';
				break;
			case '\'':
				*buf++ = '\'';
				break;
			case '\"':
				*buf++ = '\"';
				break;
			default:
				BLAST(UNRECOGNIZED_ESCAPE);
			}
		}
	}
	*buf++ = '\0';
	Int32 size = buf - ReceiveStringBuffer;
  	result = strcpy(new char[size],ReceiveStringBuffer);
	
	this->endThing();
	char * 	returnValue;
	returnValue = result;
	return returnValue;
}


UInt32 TextyRcvr::receiveUInt32 (){
	UInt32 result;
	
	this->startThing();
	result = this->receiveNumber().asLong();
	this->endThing();
	return result;
}


UInt8 TextyRcvr::receiveUInt8 (){
	UInt8 result;
	
	this->startThing();
	result = this->receiveNumber().asInt();
	this->endThing();
	return result;
}
/* protected: lexer */


void TextyRcvr::decrementDepth (){
	myDepth -= 1;
}


void TextyRcvr::endOfInstance (){
	this->getCharToken(')');
	myDepth -= 1;
	this->endThing();
}


void TextyRcvr::endPacket (){
	this->getCharToken(';');
	this->SpecialistRcvr::endPacket();
}


RPTR(Category) TextyRcvr::fetchStartOfInstance (){
	SPTR(Category) cat;
	
	this->startThing();
	cat = this->receiveCategory();
	if (cat == NULL) {
		return NULL;
	}
	myDepth += 1;
	this->getCharToken('(');
	WPTR(Category) 	returnValue;
	returnValue = cat;
	return returnValue;
}


UInt32 TextyRcvr::getByte (){
	return myStream->getByte();
}


void TextyRcvr::getCharToken (char referent){
	/* match a character from the input stream */
	
	char c;
	
	c = this->skipWhiteSpace();
	if (c != referent) {
		BLAST(WrongCharacter);
	}
}


void TextyRcvr::getIdentifier (char * buf, Int32 limit){
	/* get an identifier from the stream into a pre-allocated buffer */
	
	char c;
	Int32 nextPos;
	
	nextPos = Int32Zero;
	c = this->skipWhiteSpace();
	for (;;) {	BooleanVar crutch_Flag;
		/* isalnum(c) || c == '_' */
		
		crutch_Flag = isalnum(c);
		if(!crutch_Flag) {
			crutch_Flag = c == '_';
		}
		if (crutch_Flag) {
			if (nextPos >= limit) {
				BLAST(IdentifierTooLong);
			}
			
			buf[nextPos] = c;
			
			nextPos += 1;
			c = char(myStream->getByte());
		} else {
			break;
		}
	}
	myStream->putBack(uint8(c));
	
	buf[nextPos] = char(UInt32Zero);
	
}


void TextyRcvr::incrementDepth (){
	myDepth += 1;
}


char TextyRcvr::skipWhiteSpace (){
	/* return the first character following white space */
	
	char c;
	
	c = char(myStream->getByte());
	for (;;) {	BooleanVar crutch_Flag;
		/* isspace(c) || c == ',' */
		
		crutch_Flag = isspace(c);
		if(!crutch_Flag) {
			crutch_Flag = c == ',';
		}
		if (crutch_Flag) {
			c = char(myStream->getByte());
		} else {
			break;
		}
	}
	return c;
}
/* private: receiving */


IntegerVar TextyRcvr::receiveNumber (){
	/* Receive an arbitrary number.  Convert to the lesser types 
	by range checking and casting. */
	
	IntegerVar value;
	BooleanVar neg;
	UInt8 c;
	
	c = this->skipWhiteSpace();
	neg = c == '-';
	if (neg) {
		c = char(myStream->getByte());
	}
	value = IntegerVar0;
	while (isdigit(c)) {
		UInt8 digit;
		
		digit = uint8(c) - uint8('0');
		value = value * 10 + digit;
		c = char(myStream->getByte());
	}
	myStream->putBack(uint8(c));
	if (neg) {
		return -value;
	}
	return value;
}
/* creation */


TextyRcvr::TextyRcvr (APTR(TransferSpecialist) specialist, APTR(XnReadStream) stream) 
	: SpecialistRcvr(specialist, tcsj) {
	myStream = stream;
	myDepth = IntegerVar0;
}
/* protected: receiving */


void TextyRcvr::endThing (){
	if (myDepth == IntegerVar0) {
		this->endPacket();
	}
}


void TextyRcvr::startThing (){
	if (myDepth == IntegerVar0) {
		myStream->refill();
	}
}
/* printing */


void TextyRcvr::printOn (ostream& oo){
	oo << this->getCategory()->name() << "( " << myStream << ")";
}



/* ************************************************************************ *
 * 
 *                    Class TextyXmtr 
 *
 * ************************************************************************ */


/* creation */


RPTR(SpecialistXmtr) TextyXmtr::make (APTR(TransferSpecialist) specialist, APTR(XnWriteStream) stream){
	RETURN_CONSTRUCT(TextyXmtr,(specialist, stream));
}
/* sending */


void TextyXmtr::sendBooleanVar (BooleanVar b){
	this->startThing();
	if (b) {
		myStream->putByte(uint8('1'));
	} else {
		myStream->putByte(uint8('0'));
	}
	this->endThing();
}


void TextyXmtr::sendCategory (APTR(Category) cat){
	this->startThing();
	this->sendIdentifier(cat->name());
	
	
	this->endThing();
}


void TextyXmtr::sendIEEEDoubleVar (IEEEDoubleVar x){
	/* Sending the normal decimal approximation doesn't work 
	because it introduces 
		roundoff error. What we need to do instead is send a hex 
	encoding of the IEEE 
		double precision (64-bit) representation of the number. For 
	clarity in the 
		textual protocol, we also include the decimal approximation 
	in a comment. */
	
	this->startThing();
	
	
	char 	str[CONVERTSTRLEN];
	sprintf(str, "%g", x);
	myStream->putStr(str);
	
	this->endThing();
}


void TextyXmtr::sendInt32 (Int32 n){
	this->startThing();
	
	
	char 	str[CONVERTSTRLEN];
	sprintf(str, "%d", n);
	myStream->putStr(str);
	
	this->endThing();
}


void TextyXmtr::sendInt8 (Int8 n){
	this->startThing();
	
	
	char 	str[CONVERTSTRLEN];
	sprintf(str, "%d", n);
	myStream->putStr(str);
	
	this->endThing();
}


void TextyXmtr::sendIntegerVar (IntegerVar n){
	this->startThing();
	
	(&n)->sendSelfTo(this);
	
	this->endThing();
}


void TextyXmtr::sendString (char * s){
	this->startThing();
	myStream->putByte(uint8('\"'));
	
	for(; *s != '\0'; s++) {
		switch (*s) {
		/*case ALERT_CHAR:
			myStream->putStr("\\a");
			break;*/
		case '\n':
			myStream->putStr("\\n\\\n");
			break;
		case '\t':
			myStream->putStr("\\t");
			break;
		case '\b':
			myStream->putStr("\\b");
			break;
		case '\r':
			myStream->putStr("\\r");
			break;
		case '\f':
			myStream->putStr("\\f");
			break;
		case '\v':
			myStream->putStr("\\v");
			break;
		case '\\':
			myStream->putStr("\\\\");
			break;
		case '\'':
			myStream->putStr("\\\'");
			break;
		case '\"':
			myStream->putStr("\\\"");
			break;
		default:
			if (isprint(*s)) {
				myStream->putByte(*s);
			} else {
				BLAST(NON_PRINTING_CHARACTER);
			}
		}
	}
	
	myStream->putByte(uint8('\"'));
	this->endThing();
}


void TextyXmtr::sendUInt32 (UInt32 n){
	this->startThing();
	
	 
	char 	str[CONVERTSTRLEN];
	sprintf(str, "%u", n);
	myStream->putStr(str);
	
	this->endThing();
}


void TextyXmtr::sendUInt8 (UInt8 n){
	this->startThing();
	
	
	char 	str[CONVERTSTRLEN];
	sprintf(str, "%u", n);
	myStream->putStr(str);
	
	this->endThing();
}


void TextyXmtr::sendUInt8Data (APTR(UInt8Array) array){
	this->startThing();
	myStream->putByte(uint8('\"'));
	{
		Int32 LoopFinal = array->count();
		Int32 i = Int32Zero;
		for (;;) {
			if (i >= LoopFinal){
				break;
			}
			{
				myStream->putByte((UInt8 ) array->uIntAt(i));
			}
			i += 1;
		}
	}
	myStream->putByte(uint8('\"'));
	this->endThing();
}
/* specialist sending */


void TextyXmtr::endInstance (){
	/* end sending an instance */
	
	myStream->putByte(uint8(')'));
	myDepth -= 1;
	this->endThing();
}
/* protected: sending */


void TextyXmtr::decrementDepth (){
	myDepth -= 1;
}


void TextyXmtr::endPacket (){
	myStream->putByte(uint8(';'));
	myStream->flush();
	myNeedsSep = FALSE;
	this->SpecialistXmtr::endPacket();
}


void TextyXmtr::endThing (){
	if (myDepth == IntegerVar0) {
		this->endPacket();
	} else {
		myNeedsSep = TRUE;
	}
}


void TextyXmtr::incrementDepth (){
	myDepth += 1;
}


void TextyXmtr::putByte (UInt8 b){
	myStream->putByte(b);
}


void TextyXmtr::sendNULL (){
	this->startThing();
	this->sendIdentifier("NULL");
	this->endThing();
}


void TextyXmtr::startNewInstance (APTR(Category) cat){
	/* start sending an instance of a particular class */
	
	myDepth += 1;
	this->sendCategory(cat);
	myStream->putByte(uint8('('));
	myNeedsSep = FALSE;
}


void TextyXmtr::startThing (){
	if (myNeedsSep) {
		myStream->putByte(uint8(','));
	}
	myNeedsSep = FALSE;
}
/* private: sending */


void TextyXmtr::sendIdentifier (char * identifier){
	/* send an identifier */
	
	myStream->putStr(identifier);
}
/* creation */


TextyXmtr::TextyXmtr (APTR(TransferSpecialist) specialist, APTR(XnWriteStream) stream) 
	: SpecialistXmtr(specialist, tcsj) {
	myStream = stream;
	myDepth = IntegerVar0;
	myNeedsSep = FALSE;
}
/* printing */


void TextyXmtr::printOn (ostream& oo){
	oo << this->getCategory()->name() << "( " << myStream << ")";
}
/* overloading junk */


void TextyXmtr::sendHeaper (APTR(Heaper) object){
	this->SpecialistXmtr::sendHeaper(object);
}

#ifndef TXTCOMMX_SXX
#include "txtcommx.sxx"
#endif /* TXTCOMMX_SXX */


#ifndef TXTCOMMP_SXX
#include "txtcommp.sxx"
#endif /* TXTCOMMP_SXX */



#endif /* TXTCOMMX_CXX */

