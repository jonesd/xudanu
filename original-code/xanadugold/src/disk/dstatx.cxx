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

#ifndef DSTATX_CXX
#define DSTATX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef DSTATP_HXX
#include "dstatp.hxx"
#endif /* DSTATP_HXX */

#ifndef DSTATP_IXX
#include "dstatp.ixx"
#endif /* DSTATP_IXX */


#ifndef NEGOTI8X_HXX
#include "negoti8x.hxx"
#endif /* NEGOTI8X_HXX */

#ifndef NSCOTTYX_HXX
#include "nscottyx.hxx"
#endif /* NSCOTTYX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef PACKERP_HXX
#include "packerp.hxx"
#endif /* PACKERP_HXX */

#ifndef PRIMTABX_HXX
#include "primtabx.hxx"
#endif /* PRIMTABX_HXX */

#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */

#ifndef SNFINFOX_HXX
#include "snfinfox.hxx"
#endif /* SNFINFOX_HXX */

#ifndef TXTCOMMX_HXX
#include "txtcommx.hxx"
#endif /* TXTCOMMX_HXX */

#ifndef URDIX_HXX
#include "urdix.hxx"
#endif /* URDIX_HXX */




/* ************************************************************************ *
 * 
 *                    Class SnarfStatistics 
 *
 * ************************************************************************ */


/* Print out some summary of the data currently on disk. */


/* running */


void SnarfStatistics::execute (){
	this->snarfAllocInfo();
	this->tallyFlockTypes();
}


void SnarfStatistics::snarfAllocInfo (){
	SPTR(Urdi) anUrdi;
	SPTR(UrdiView) view;
	SPTR(SnarfInfoHandler) info;
	IntegerVar totalReal;
	IntegerVar totalForget;
	IntegerVar totalRealSpace;
	IntegerVar totalForgetSpace;
	
	totalReal = IntegerVarZero;
	totalForget = IntegerVarZero;
	totalRealSpace = IntegerVarZero;
	totalForgetSpace = IntegerVarZero;
	anUrdi = ::urdi(myFilename, 2);
	view = anUrdi->makeReadView();
	info = SnarfInfoHandler::make (anUrdi, view);
	cerr << "There are " << info->snarfInfoCount() << " snarFInfo snarfs out of " << info->snarfCount() << " total snarfs.\nThere are " << view->getDataSizeOfSnarf(1) << " bytes in each snarf.\n";
	{
		Int32 LoopFinal = info->snarfCount();
		Int32 snarfID = info->snarfInfoCount();
		for (;;) {
			if (snarfID >= LoopFinal){
				break;
			}
			{
				if (info->getSpaceLeft(snarfID) < view->getDataSizeOfSnarf(snarfID)) {
					SPTR(SnarfHandler) handler;
					Int32 count;
					Int32 forwards;
					Int32 forgets;
					Int32 forgetSpace;
					Int32 flocks;
					Int32 liveSpace;
					
					handler = SnarfHandler::make (view->makeReadHandle(snarfID));
					count = handler->mapCount();
					forwards = forgets = forgetSpace = flocks = liveSpace = Int32Zero;
					{
						Int32 LoopFinal = count;
						Int32 i = Int32Zero;
						for (;;) {
							if (i >= LoopFinal){
								break;
							}
							{
								if (handler->isOccupied(i)) {
									if (handler->fetchForward(i) != NULL) {
										forwards += 1;
									} else {
										if (handler->isForgotten(i)) {
											forgets += 1;
											forgetSpace += handler->flockSize(i);
										} else {
											flocks += 1;
											liveSpace += handler->flockSize(i);
										}
									}
								}
							}
							i += 1;
						}
					}
					cerr << snarfID << ":\t" << flocks << " real in " << liveSpace << " bytes.\t";
					cerr << forgets << " forgets in " << forgetSpace << " bytes.\t";
					cerr << forwards << " forward.\t";
					/* << count << ' cells ' */
					cerr << handler->spaceLeft() << " spaceLeft.";
					cerr << "\tforgotten: " << info->getForgottenFlag(snarfID) << ".\n";
					{handler->destroy();  handler = NULL /* don't want stale (S/CHK)PTRs */;}
					totalReal += flocks;
					totalRealSpace += liveSpace;
					totalForget += forgets;
					totalForgetSpace += forgetSpace;
				}
			}
			snarfID += 1;
		}
	}
	cerr << "All others empty.\n";
	cerr << "Totals:  " << totalReal << " real in " << totalRealSpace << " bytes, " << totalForget << " forgets in " << totalForgetSpace << " bytes.\n";
	{info->destroy();  info = NULL /* don't want stale (S/CHK)PTRs */;}
	{view->destroy();  view = NULL /* don't want stale (S/CHK)PTRs */;}
	{anUrdi->destroy();  anUrdi = NULL /* don't want stale (S/CHK)PTRs */;}
}


void SnarfStatistics::tallyFlockTypes (){
	SPTR(Urdi) anUrdi;
	SPTR(UrdiView) view;
	SPTR(SnarfInfoHandler) info;
	SPTR(PrimIndexTable) liveFlockCounts;
	SPTR(PrimPtr2PtrTable) liveFlockTypes;
	SPTR(PrimIndexTable) forgottenFlockCounts;
	SPTR(PrimPtr2PtrTable) forgottenFlockTypes;
	
	liveFlockCounts = PrimIndexTable::make (255);
	liveFlockTypes = PrimPtr2PtrTable::make (255);
	forgottenFlockCounts = PrimIndexTable::make (255);
	forgottenFlockTypes = PrimPtr2PtrTable::make (255);
	anUrdi = ::urdi(myFilename, 2);
	view = anUrdi->makeReadView();
	info = SnarfInfoHandler::make (anUrdi, view);
	this->diskCookbook(view, info);
	cerr << "Tallying types over all snarfs, this may take a while.\n";
	{
		Int32 LoopFinal = info->snarfCount();
		Int32 snarfID = info->snarfInfoCount();
		for (;;) {
			if (snarfID >= LoopFinal){
				break;
			}
			{
				if (info->getSpaceLeft(snarfID) < view->getDataSizeOfSnarf(snarfID)) {
					SPTR(SnarfHandler) handler;
					Int32 count;
					
					handler = SnarfHandler::make (view->makeReadHandle(snarfID));
					count = handler->mapCount();
					{
						Int32 LoopFinal = count;
						Int32 i = Int32Zero;
						for (;;) {
							if (i >= LoopFinal){
								break;
							}
							{
								{	BooleanVar crutch_Flag;
									/* handler->isOccupied(i) && handler->fetchForward(i) == NULL */
									
									crutch_Flag = handler->isOccupied(i);
									if(crutch_Flag) {
										crutch_Flag = handler->fetchForward(i) == NULL;
									}
									if (crutch_Flag) {
										SPTR(Rcvr) rcvr;
										SPTR(XnReadStream) stream;
										SPTR(Category) cat;
										
										rcvr = this->makeRcvr(stream = handler->readStream(i));
										cat = SpecialistRcvrJig::receiveCategory(rcvr);
										{rcvr->destroy();  rcvr = NULL /* don't want stale (S/CHK)PTRs */;}
										{stream->destroy();  stream = NULL /* don't want stale (S/CHK)PTRs */;}
										if (!cat->isEqualOrSubclassOf(cat_Abraham)) {
											cerr << "WARNING: non-Abraham flock at " << snarfID << ":" << i << " : ";
											cerr << cat->name() << "\n";
											cerr << "\tflock size = " << handler->flockSize(i) << "\n";
										}
										if (handler->isForgotten(i)) {
											if (forgottenFlockTypes->fetch(cat) == NULL) {
												forgottenFlockTypes->store(cat, cat);
												forgottenFlockCounts->store(cat, 1);
											} else {
												forgottenFlockCounts->store(cat, forgottenFlockCounts->fetch(cat) + 1);
											}
										} else {
											if (liveFlockTypes->fetch(cat) == NULL) {
												liveFlockTypes->store(cat, cat);
												liveFlockCounts->store(cat, 1);
											} else {
												liveFlockCounts->store(cat, liveFlockCounts->fetch(cat) + 1);
											}
										}
									}
								}
							}
							i += 1;
						}
					}
					{handler->destroy();  handler = NULL /* don't want stale (S/CHK)PTRs */;}
				}
			}
			snarfID += 1;
		}
	}
	cerr << "\ntally of live flocks.\n";
	BEGIN_FOR_EACH(Category,cat,(liveFlockTypes->stepper())) {
		cerr << liveFlockCounts->fetch(cat) << "\t" << cat->name() << "\n";
	} END_FOR_EACH;
	cerr << "\ntally of forgotten flocks.\n";
	BEGIN_FOR_EACH(Category,cat,(forgottenFlockTypes->stepper())) {
		cerr << forgottenFlockCounts->fetch(cat) << "\t" << cat->name() << "\n";
	} END_FOR_EACH;
	{info->destroy();  info = NULL /* don't want stale (S/CHK)PTRs */;}
	{view->destroy();  view = NULL /* don't want stale (S/CHK)PTRs */;}
	{anUrdi->destroy();  anUrdi = NULL /* don't want stale (S/CHK)PTRs */;}
}
/* private */


void SnarfStatistics::diskCookbook (APTR(UrdiView) view, APTR(SnarfInfoHandler) info){
	/* Get the cookbook and protocol-stream maker for the disk. */
	
	SPTR(SnarfHandler) handler;
	SPTR(XnReadStream) stream;
	SPTR(Rcvr) rcvr;
	char * protocol;
	char * cookbook;
	
	handler = SnarfHandler::make (view->makeReadHandle(info->snarfInfoCount()));
	rcvr = TextyXcvrMaker::makeReader(stream = handler->readStream(Int32Zero));
	protocol = rcvr->receiveString();
	cookbook = rcvr->receiveString();
	{rcvr->destroy();  rcvr = NULL /* don't want stale (S/CHK)PTRs */;}
	{stream->destroy();  stream = NULL /* don't want stale (S/CHK)PTRs */;}
	{handler->destroy();  handler = NULL /* don't want stale (S/CHK)PTRs */;}
	myProtocol = ProtocolBroker::diskProtocol(protocol);
	myCookbook = Cookbook::make (cookbook);
	delete protocol;
	delete cookbook;
}


RPTR(SpecialistRcvr) SnarfStatistics::makeRcvr (APTR(XnReadStream) readStream){
	WPTR(SpecialistRcvr) 	returnValue;
	returnValue = myProtocol->makeRcvr(DiskSpecialist::make (myCookbook, NULL), readStream);
	return returnValue;
}

	/* automatic 0-argument constructor */
SnarfStatistics::SnarfStatistics() {}



/* ************************************************************************ *
 * 
 *                    Class SpecialistRcvrJig 
 *
 * ************************************************************************ */


/* receiving */


RPTR(Category) SpecialistRcvrJig::receiveCategory (APTR(Rcvr) rcvr){
	WPTR(Category) 	returnValue;
	returnValue = CAST(SpecialistRcvr,rcvr)->fetchStartOfInstance();
	return returnValue;
}
/* A tool to read partial packets from the disk to measure statistics. */


/* testing */


UInt32 SpecialistRcvrJig::actualHashForEqual (){
	return Heaper::takeOop();
}

	/* automatic 0-argument constructor */
SpecialistRcvrJig::SpecialistRcvrJig() {}

#ifndef DSTATP_SXX
#include "dstatp.sxx"
#endif /* DSTATP_SXX */



#endif /* DSTATX_CXX */

