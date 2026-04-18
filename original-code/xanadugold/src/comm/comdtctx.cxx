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

#ifndef COMDTCTX_CXX
#define COMDTCTX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef COMDTCTR_HXX
#include "comdtctr.hxx"
#endif /* COMDTCTR_HXX */

#ifndef COMDTCTR_IXX
#include "comdtctr.ixx"
#endif /* COMDTCTR_IXX */

#ifndef COMDTCTP_HXX
#include "comdtctp.hxx"
#endif /* COMDTCTP_HXX */

#ifndef COMDTCTP_IXX
#include "comdtctp.ixx"
#endif /* COMDTCTP_IXX */


#ifndef IDX_HXX
#include "idx.hxx"
#endif /* IDX_HXX */

#ifndef PRIMVALX_HXX
#include "primvalx.hxx"
#endif /* PRIMVALX_HXX */




/* ************************************************************************ *
 * 
 *                    Class CommFillDetector 
 *
 * ************************************************************************ */


/* creation */


RPTR(CommFillDetector) CommFillDetector::make (
		APTR(PromiseManager) pm, 
		IntegerVar number, 
		APTR(FeRangeElement) target)
{
	RETURN_CONSTRUCT(CommFillDetector,(pm, number, target));
}
/* Send the detector events over comm. */


/* creation */


CommFillDetector::CommFillDetector (
		APTR(PromiseManager) pm, 
		IntegerVar number, 
		APTR(FeRangeElement) target) 
{
	myManager = pm;
	myNumber = number;
	myTarget = target;
}
/* triggering */


void CommFillDetector::filled (APTR(FeRangeElement) newIdentity){
	/* A single PlaceHolder has been filled to become another 
	kind of RangeElement */
	
	myManager->queueDetectorEvent(FilledEvent::make (myNumber, newIdentity));
}



/* ************************************************************************ *
 * 
 *                    Class CommFillRangeDetector 
 *
 * ************************************************************************ */


/* creation */


RPTR(CommFillRangeDetector) CommFillRangeDetector::make (
		APTR(PromiseManager) pm, 
		IntegerVar number, 
		APTR(FeEdition) target)
{
	RETURN_CONSTRUCT(CommFillRangeDetector,(pm, number, target));
}
/* Send the detector events over comm. */


/* creation */


CommFillRangeDetector::CommFillRangeDetector (
		APTR(PromiseManager) pm, 
		IntegerVar number, 
		APTR(FeEdition) target) 
{
	myManager = pm;
	myNumber = number;
	myTarget = target;
}
/* triggering */


void CommFillRangeDetector::rangeFilled (APTR(FeEdition) newIdentities){
	/* Essential.  Some of the PlaceHolders in the Edition on 
	which I was placed have become something else. The Edition 
	has their new identies as its RangeElements, though the keys 
	may bear no relationship to those in the original Edition. */
	
	myManager->queueDetectorEvent(RangeFilledEvent::make (myNumber, newIdentities));
}



/* ************************************************************************ *
 * 
 *                    Class CommRevisionDetector 
 *
 * ************************************************************************ */


/* creation */


RPTR(CommRevisionDetector) CommRevisionDetector::make (
		APTR(PromiseManager) pm, 
		IntegerVar number, 
		APTR(FeWork) target)
{
	RETURN_CONSTRUCT(CommRevisionDetector,(pm, number, target));
}
/* Send the detector events over comm. */


/* creation */


CommRevisionDetector::CommRevisionDetector (
		APTR(PromiseManager) pm, 
		IntegerVar number, 
		APTR(FeWork) target) 
{
	myManager = pm;
	myNumber = number;
	myTarget = target;
}
/* triggering */


void CommRevisionDetector::revised (
		APTR(FeWork) work, 
		APTR(FeEdition) contents, 
		APTR(ID) author, 
		IntegerVar time, 
		IntegerVar sequence)
{
	/* Essential. The Work has been revised. Gives the Work, the 
	current Edition, the 
		author ID who had it grabbed, the sequence number of the 
	revision to the 
		Work, and the clock time on the Server (note that the clock 
	time is only as 
		reliable as the Server's operating system, which is usually 
	not very). */
	
	myManager->queueDetectorEvent(
			RevisedEvent::make (myNumber, work, contents, author, time, sequence));
}



/* ************************************************************************ *
 * 
 *                    Class CommStatusDetector 
 *
 * ************************************************************************ */


/* creation */


RPTR(CommStatusDetector) CommStatusDetector::make (
		APTR(PromiseManager) pm, 
		IntegerVar number, 
		APTR(FeWork) target)
{
	RETURN_CONSTRUCT(CommStatusDetector,(pm, number, target));
}
/* Send the detector events over comm. */


/* creation */


CommStatusDetector::CommStatusDetector (
		APTR(PromiseManager) pm, 
		IntegerVar number, 
		APTR(FeWork) target) 
{
	myManager = pm;
	myNumber = number;
	myTarget = target;
}
/* triggering */


void CommStatusDetector::grabbed (
		APTR(FeWork) work, 
		APTR(ID) author, 
		IntegerVar reason)
{
	/* Essential. The Work has been grabbed, or regrabbed. */
	
	myManager->queueDetectorEvent(
			GrabbedEvent::make (myNumber, work, author, reason));
}


void CommStatusDetector::released (APTR(FeWork) work, IntegerVar reason){
	/* Essential. The revise capability of the Work has been lost. */
	
	myManager->queueDetectorEvent(
			ReleasedEvent::make (myNumber, work, reason));
}



/* ************************************************************************ *
 * 
 *                    Class CommWaitDetector 
 *
 * ************************************************************************ */


/* creation */


RPTR(CommWaitDetector) CommWaitDetector::make (APTR(PromiseManager) pm, IntegerVar number){
	RETURN_CONSTRUCT(CommWaitDetector,(pm, number));
}
/* Send the detector events over comm. */


/* creation */


CommWaitDetector::CommWaitDetector (APTR(PromiseManager) pm, IntegerVar number) {
	myManager = pm;
	myNumber = number;
}


void CommWaitDetector::destruct (){
	FeServer::removeWaitDetector(this);
	this->FeWaitDetector::destruct();
}
/* triggering */


void CommWaitDetector::done (){
	/* Essential.  Whatever I was waiting for has happened */
	
	myManager->queueDetectorEvent(DoneEvent::make (myNumber));
}



/* ************************************************************************ *
 * 
 *                    Class DetectorEvent 
 *
 * ************************************************************************ */


/* The detectors for comm create these and queue them up because they 
can only go out between requests. */


/* accessing */


IntegerVar DetectorEvent::detector (){
	return myDetector;
}


RPTR(DetectorEvent) DetectorEvent::next (){
	return (DetectorEvent*) myNext;
}


void DetectorEvent::setNext (APTR(DetectorEvent) event){
	myNext = event;
}
/* triggering */
/* creation */


DetectorEvent::DetectorEvent (IntegerVar detector, TCSJ) {
	myDetector = detector;
	myNext = NULL;
}
/* testing */


UInt32 DetectorEvent::actualHashForEqual (){
	return Heaper::takeOop();
}



/* ************************************************************************ *
 * 
 *                    Class DoneEvent 
 *
 * ************************************************************************ */


/* creation */


RPTR(DetectorEvent) DoneEvent::make (IntegerVar detector){
	RETURN_CONSTRUCT(DoneEvent,(detector, tcsj));
}
/* triggering */


void DoneEvent::trigger (APTR(PromiseManager) pm){
	/* Send the message across the wire. */
	
	pm->sendResponse(PromiseManager::doneResponse());
	pm->sendIntegerVar(this->detector());
}
/* creation */


DoneEvent::DoneEvent (IntegerVar detector, TCSJ) 
	: DetectorEvent(detector, tcsj) {
	
}



/* ************************************************************************ *
 * 
 *                    Class FilledEvent 
 *
 * ************************************************************************ */


/* creation */


RPTR(DetectorEvent) FilledEvent::make (IntegerVar detector, APTR(Heaper) filling){
	RETURN_CONSTRUCT(FilledEvent,(detector, filling));
}
/* triggering */


void FilledEvent::trigger (APTR(PromiseManager) pm){
	/* Send the message across the wire. */
	
	pm->sendResponse(PromiseManager::filledResponse());
	pm->sendIntegerVar(this->detector());
	pm->sendPromise(myFilling);
}
/* creation */


FilledEvent::FilledEvent (IntegerVar detector, APTR(Heaper) filling) 
	: DetectorEvent(detector, tcsj) {
	myFilling = filling;
}



/* ************************************************************************ *
 * 
 *                    Class GrabbedEvent 
 *
 * ************************************************************************ */


/* creation */


RPTR(DetectorEvent) GrabbedEvent::make (
		IntegerVar detector, 
		APTR(Heaper) work, 
		APTR(Heaper) author, 
		IntegerVar reason)
{
	RETURN_CONSTRUCT(GrabbedEvent,(detector, work, author, reason));
}
/* triggering */


void GrabbedEvent::trigger (APTR(PromiseManager) pm){
	/* Send the message across the wire. */
	
	pm->sendResponse(PromiseManager::grabbedResponse());
	pm->sendIntegerVar(this->detector());
	pm->sendPromise(myWork);
	pm->sendPromise(myAuthor);
	pm->sendIntegerVar(myReason);
	pm->sendPromise(PrimIntValue::make (myReason));
}
/* creation */


GrabbedEvent::GrabbedEvent (
		IntegerVar detector, 
		APTR(Heaper) work, 
		APTR(Heaper) author, 
		IntegerVar reason) 

	: DetectorEvent(detector, tcsj) {
	myWork = work;
	myAuthor = author;
	myReason = reason;
}



/* ************************************************************************ *
 * 
 *                    Class RangeFilledEvent 
 *
 * ************************************************************************ */


/* creation */


RPTR(DetectorEvent) RangeFilledEvent::make (IntegerVar detector, APTR(Heaper) filling){
	RETURN_CONSTRUCT(RangeFilledEvent,(detector, filling));
}
/* creation */


RangeFilledEvent::RangeFilledEvent (IntegerVar detector, APTR(Heaper) filling) 
	: DetectorEvent(detector, tcsj) {
	myFilling = filling;
}
/* triggering */


void RangeFilledEvent::trigger (APTR(PromiseManager) pm){
	/* Send the message across the wire. */
	
	pm->sendResponse(PromiseManager::rangeFilledResponse());
	pm->sendIntegerVar(this->detector());
	pm->sendPromise(myFilling);
}



/* ************************************************************************ *
 * 
 *                    Class ReleasedEvent 
 *
 * ************************************************************************ */


/* creation */


RPTR(DetectorEvent) ReleasedEvent::make (
		IntegerVar detector, 
		APTR(Heaper) work, 
		IntegerVar reason)
{
	RETURN_CONSTRUCT(ReleasedEvent,(detector, work, reason));
}
/* creation */


ReleasedEvent::ReleasedEvent (
		IntegerVar detector, 
		APTR(Heaper) work, 
		IntegerVar reason) 

	: DetectorEvent(detector, tcsj) {
	myWork = work;
	myReason = reason;
}
/* triggering */


void ReleasedEvent::trigger (APTR(PromiseManager) pm){
	/* Send the message across the wire. */
	
	pm->sendResponse(PromiseManager::releasedResponse());
	pm->sendIntegerVar(this->detector());
	pm->sendPromise(myWork);
	pm->sendIntegerVar(myReason);
	pm->sendPromise(PrimIntValue::make (myReason));
}



/* ************************************************************************ *
 * 
 *                    Class RevisedEvent 
 *
 * ************************************************************************ */


/* creation */


RPTR(DetectorEvent) RevisedEvent::make (
		IntegerVar detector, 
		APTR(Heaper) work, 
		APTR(Heaper) contents, 
		APTR(Heaper) author, 
		IntegerVar time, 
		IntegerVar sequence)
{
	RETURN_CONSTRUCT(RevisedEvent,(detector, work, contents, author, time, sequence));
}
/* creation */


RevisedEvent::RevisedEvent (
		IntegerVar detector, 
		APTR(Heaper) work, 
		APTR(Heaper) contents, 
		APTR(Heaper) author, 
		IntegerVar time, 
		IntegerVar sequence) 

	: DetectorEvent(detector, tcsj) {
	myWork = work;
	myContents = contents;
	myAuthor = author;
	myTime = time;
	mySequence = sequence;
}
/* triggering */


void RevisedEvent::trigger (APTR(PromiseManager) pm){
	/* Send the message across the wire. */
	
	pm->sendResponse(PromiseManager::revisedResponse());
	pm->sendIntegerVar(this->detector());
	pm->sendPromise(myWork);
	pm->sendPromise(myContents);
	pm->sendPromise(myAuthor);
	pm->sendIntegerVar(myTime);
	pm->sendPromise(PrimIntValue::make (myTime));
	pm->sendIntegerVar(mySequence);
	pm->sendPromise(PrimIntValue::make (mySequence));
}

#ifndef COMDTCTR_SXX
#include "comdtctr.sxx"
#endif /* COMDTCTR_SXX */


#ifndef COMDTCTP_SXX
#include "comdtctp.sxx"
#endif /* COMDTCTP_SXX */



#endif /* COMDTCTX_CXX */

