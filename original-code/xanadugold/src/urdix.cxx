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

#ifndef URDIX_CXX
#define URDIX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef URDIX_HXX
#include "urdix.hxx"
#endif /* URDIX_HXX */

#ifndef URDIX_IXX
#include "urdix.ixx"
#endif /* URDIX_IXX */


#ifndef INTTABX_HXX
#include "inttabx.hxx"
#endif /* INTTABX_HXX */

#ifndef STEPPERX_HXX
#include "stepperx.hxx"
#endif /* STEPPERX_HXX */




/* ************************************************************************ *
 * 
 *                    Class SnarfHandle 
 *
 * ************************************************************************ */


/* accessing */


char * SnarfHandle::getDataP (){
	return (char*) myContents;
}


Int4 SnarfHandle::getDataSize (){
	return myContents->count();
}


Int32 SnarfHandle::getSnarfID (){
	return mySnarfID;
}


BooleanVar SnarfHandle::isWritable (){
	return isWritable;
}


void SnarfHandle::makeWritable (){
	isWritable = TRUE;
}


Int32 SnarfHandle::snarfID (){
	return mySnarfID;
}


void SnarfHandle::thaw (){
	/* Release the memory buffer locked into place for this snarfHandle. */
	
	BLAST(NOT_YET_IMPLEMENTED);
	if (isWritable) {
		myUrdi->writeHandle(mySnarfID, myContents);
	}
	myUrdi->releaseHandle(mySnarfID);
}
/* data manipulation */


void SnarfHandle::put32 (Int32 index, Int32 word){
	/* Store the supplied word into the snarf starting at index.  
	Put the high byte first. */
	
	if ( ! (isWritable) ) {
		BLAST(Must_be_writable);
	}
	myContents->storeUInt(index, word >> 24);
	myContents->storeUInt(index + 1, word >> 16 & 255);
	myContents->storeUInt(index + 2, word >> 8 & 255);
	myContents->storeUInt(index + 3, word & 255);
}


Int32 SnarfHandle::get32 (Int32 index){
	/* Return the Int4 represented by the 4 bytes starting at 
	index, high byte first.  This must return a negative number 
	when appropriate. */
	
	String * guts;
	Int32 result;
	
	guts = myContents->gutsOf();
	result = guts->basicAt(index + 1);
	result = (result << 8) + guts->basicAt(index + 2);
	result = (result << 8) + guts->basicAt(index + 3);
	result = (result << 8) + guts->basicAt(index + 4);
	return result;
}


void SnarfHandle::moveBytes (
		Int4 start, 
		Int4 newStart, 
		Int4 nBytes)
{
	if ( ! (isWritable) ) {
		BLAST(Must_be_writable);
	}
	myContents->storeMany(newStart, myContents, nBytes, start);
}
/* printing */


void SnarfHandle::printOn (ostream& oo){
	oo << this->getCategory()->name() << "(" << mySnarfID << ")";
}
/* protected: destruct */


void SnarfHandle::destruct (){
	/* When a handle keeping a snarf in memory is destroyed, the 
	snarf can then move around or go off to disk. */
	
	if (isWritable) {
		myUrdi->writeHandle(mySnarfID, myContents);
	}
	myUrdi->releaseHandle(mySnarfID);
	this->Heaper::destruct();
}
/* create */


SnarfHandle::SnarfHandle (
		Int32 snarfID, 
		APTR(UInt32Array) contents, 
		APTR(Urdi) urdi) 
{
	mySnarfID = snarfID;
	myContents = contents;
	myUrdi = urdi;
	isWritable = FALSE;
}



/* ************************************************************************ *
 * 
 *                    Class Urdi 
 *
 * ************************************************************************ */


/* global: make */


RPTR(Urdi)  make (String * string){
	RETURN_CONSTRUCT(Urdi,(string, tcsj));
}


RPTR(Urdi)  make (String * string, Int4 lruMax){
	RETURN_CONSTRUCT(Urdi,(string, tcsj));
}


RPTR(UNKNOWN)  urdi (String * string){
	RETURN_CONSTRUCT(Urdi,(string, tcsj));
}


RPTR(UNKNOWN)  urdi (String * string, Int4 lruMax){
	RETURN_CONSTRUCT(Urdi,(string, tcsj));
}
/* accessing */


Int4 Urdi::getDataSizeOfSnarf (Int32 snarf){
	return mySnarfSize;
}


RPTR(UrdiView) Urdi::makeReadView (){
	WPTR(UrdiView) 	returnValue;
	returnValue = this->makeWriteView();
	return returnValue;
}


RPTR(UrdiView) Urdi::makeWriteView (){
	RETURN_CONSTRUCT(UrdiView,(this, tcsj));
}


Int4 Urdi::usableSnarfs (){
	return mySnarfCount;
}


Int4 Urdi::usableStages (){
	return myStageCount;
}
/* private: private */


void Urdi::commitWrite (){
	SPTR(TableStepper) stpr;
	
	BEGIN_FOR_EACH(SnarfHandle,handle,(stpr = myHandles->stepper())) {
		this->positionStream(stpr->index());
		myStream->nextPutAll(handle->getDataP()->gutsOf());
	} END_FOR_EACH;
	/* myHandles destroy.
			myHandles _ IntegerTable make: myStageCount */
	myStream->flush();
}


void Urdi::destruct (){
	this->commitWrite();
	Urdi::CachedID = Urdi::CachedData = NULL;
	myStream->close();
	this->Heaper::destruct();
}


RPTR(SnarfHandle) Urdi::eraseHandle (Int32 snarfID){
	SPTR(SnarfHandle) handle;
	
	if ( ! (snarfID < this->usableSnarfs()) ) {
		BLAST(nonexistent_snarf);
	}
	CONSTRUCT(handle,SnarfHandle,(snarfID, UInt8Array::make (mySnarfSize), this));
	handle->makeWritable();
	WPTR(SnarfHandle) 	returnValue;
	returnValue = handle;
	return returnValue;
}


RPTR(SnarfHandle) Urdi::getHandle (Int32 snarfID){
	SPTR(SnarfHandle) handle;
	
	/* Hack !!!! */
	
	/* Need to check for multiple write handles on same snarf 
		(when making writable) and too many write handles.  Also when
			getting erase handle. */
	if ( ! (snarfID < this->usableSnarfs()) ) {
		BLAST(nonexistent_snarf);
	}
	CONSTRUCT(handle,SnarfHandle,(snarfID, this->readData(snarfID), this));
	WPTR(SnarfHandle) 	returnValue;
	returnValue = handle;
	return returnValue;
}


Int4 Urdi::headerSize (){
	/* This is just the number of snarfs and their size. */
	
	return 8;
}


void Urdi::positionStream (Int32 snarfID){
	/* Position the stream to start at the location in the file 
	of the give snarf. */
	
	myStream->position(snarfID * mySnarfSize + this->headerSize());
}


RPTR(Int1Array) Urdi::readData (Int32 snarfID){
	if (snarfID == Urdi::CachedID) {
		WPTR(Int1Array) 	returnValue;
		returnValue = Urdi::CachedData;
		return returnValue;
	} else {
		this->positionStream(snarfID);
		Urdi::CachedData = myStream->next(mySnarfSize)->changeClassToThatOf(UInt8Array::basicNew());
		Urdi::CachedID = snarfID;
		WPTR(Int1Array) 	returnValue;
		returnValue = Urdi::CachedData;
		return returnValue;
	}
}


void Urdi::releaseHandle (Int32 snarfID){
	myHandles->intWipe(snarfID);
}


void Urdi::writeHandle (Int32 snarfID, APTR(UInt1Array) contents){
	SPTR(UNKNOWN) class;
	
	this->positionStream(snarfID);
	class = ;
	contents->changeClassToThatOf(String::new());
	myStream->nextPutAll(contents);
	contents->changeClassToThatOf(class->basicNew());
}
/* create */


Urdi::Urdi (String * fileName, TCSJ) {
	myStageCount = 50;
	/* : myStageCount */
	myHandles = IntegerTable::make ();
	myStream = Filename::named(fileName)->readWriteStream()->lineEndTransparent();
	mySnarfCount = myStream->nextLong();
	if (mySnarfCount == FALSE) {
		BLAST(badLongInRead);
	}
	/* These Proto collections are so we can directly use the object
			 returned from stream accessing operations. */
	mySnarfSize = myStream->nextLong();
}



/* ************************************************************************ *
 * 
 *                    Class UrdiView 
 *
 * ************************************************************************ */


/* operations */


void UrdiView::abortWrite (){
	
}


void UrdiView::becomeRead (){
	
}


void UrdiView::commitWrite (){
	myUrdi->commitWrite();
}


Int4 UrdiView::getDataSizeOfSnarf (Int32 snarf){
	return myUrdi->getDataSizeOfSnarf(snarf);
}


BooleanVar UrdiView::isWriteView (){
	/* ^myStream name isWritable */
	return TRUE;
}


RPTR(SnarfHandle) UrdiView::makeErasingHandle (Int32 snarfID){
	WPTR(SnarfHandle) 	returnValue;
	returnValue = myUrdi->eraseHandle(snarfID);
	return returnValue;
}


RPTR(SnarfHandle) UrdiView::makeReadHandle (Int32 snarfID){
	WPTR(SnarfHandle) 	returnValue;
	returnValue = myUrdi->getHandle(snarfID);
	return returnValue;
}


void UrdiView::thawHandles (){
	myUrdi->commitWrite();
}

	/* automatic 0-argument constructor */
UrdiView::UrdiView() {}

#ifndef URDIX_SXX
#include "urdix.sxx"
#endif /* URDIX_SXX */



#endif /* URDIX_CXX */

