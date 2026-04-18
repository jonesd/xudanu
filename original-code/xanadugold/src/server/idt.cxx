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

#ifndef IDT_CXX
#define IDT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef IDT_HXX
#include "idt.hxx"
#endif /* IDT_HXX */

#ifndef IDT_IXX
#include "idt.ixx"
#endif /* IDT_IXX */


#ifndef GRANMAPX_HXX
#include "granmapx.hxx"
#endif /* GRANMAPX_HXX */

#ifndef NKERNELX_HXX
#include "nkernelx.hxx"
#endif /* NKERNELX_HXX */

#ifndef PARRAYX_HXX
#include "parrayx.hxx"
#endif /* PARRAYX_HXX */

#ifndef SEQUENCX_HXX
#include "sequencx.hxx"
#endif /* SEQUENCX_HXX */

#ifndef SETX_HXX
#include "setx.hxx"
#endif /* SETX_HXX */




/* ************************************************************************ *
 * 
 *                    Class IDTester 
 *
 * ************************************************************************ */


/* init */


void IDTester::destruct (){
	{myConnection->destroy();  myConnection = NULL /* don't want stale (S/CHK)PTRs */;}
	this->RegionTester::destruct();
}


RPTR(ImmuSet) OF1(XnRegion) IDTester::initExamples (){
	SPTR(SetAccumulator) iDs;
	SPTR(SetAccumulator) result;
	SPTR(Sequence) backend;
	SPTR(ImmuSet) base;
	SPTR(IDSpace) s;
	
	myConnection = Connection::make (cat_FeServer);
	myConnection->bootHeaper();
	iDs = SetAccumulator::make ();
	backend = FeServer::identifier();
	s = IDSpace::make (backend->withLast(3), 1);
	iDs->step(
			ID::usingx(s, backend, 3));
	iDs->step(
			ID::usingx(s, backend, 30));
	iDs->step(
			ID::usingx(s, backend->withLast(7), 77));
	iDs->step(
			ID::usingx(s, backend->withLast(7), 33));
	iDs->step(
			ID::usingx(s, backend->withLast(5), 99));
	result = SetAccumulator::make ();
	BEGIN_FOR_EACH(ID,iD,(CAST(ImmuSet,iDs->value())->stepper())) {
		result->step(iD->asRegion());
		result->step(iD->asRegion()->complement());
	} END_FOR_EACH;
	/* result step: (s iDsFromServer: backend).
			result step: (s iDsFromServer: (backend withLast: 7)).
			result step: (s iDsFromServer: (backend withLast: 9)).
			result step: (s iDsFromServer: backend) complement.
			result step: (s iDsFromServer: (backend withLast: 
		7))complement.
			result step: (s iDsFromServer: (backend withLast: 
		9))complement. */
	base = CAST(ImmuSet,result->value());
	BEGIN_FOR_EACH(IDRegion,r,(base->stepper())) {
		BEGIN_FOR_EACH(IDRegion,r2,(base->stepper())) {
			if (r->hashForEqual() < r2->hashForEqual()) {
				result->step(r->unionWith(r2));
				result->step(r->intersect(r2));
			}
		} END_FOR_EACH;
	} END_FOR_EACH;
	return CAST(ImmuSet,result->value());
}
/* testing */


void IDTester::allTestsOn (ostream& oo){
	this->RegionTester::allTestsOn(oo);
	this->testImportExportOn(oo);
}


void IDTester::shouldBeEqual (
		ostream& oo, 
		APTR(Heaper) original, 
		APTR(Heaper) imported, 
		APTR(Heaper) importedAgain)
{
	BooleanVar oi;
	BooleanVar oa;
	BooleanVar ia;
	
	oi = original->isEqual(imported);
	oa = original->isEqual(importedAgain);
	ia = imported->isEqual(importedAgain);
	{	BooleanVar crutch_Flag;
		/* oi && !oa && !ia */
		
		crutch_Flag = oi;
		if(crutch_Flag) {
			crutch_Flag = !oa;
			if(crutch_Flag) {
				crutch_Flag = !ia;
			}
		}
		if (crutch_Flag) {
			oo << "2nd import " << importedAgain << " is different from " << original << "\n";
		}
	}
	{	BooleanVar crutch_Flag;
		/* oa && !oi && !ia */
		
		crutch_Flag = oa;
		if(crutch_Flag) {
			crutch_Flag = !oi;
			if(crutch_Flag) {
				crutch_Flag = !ia;
			}
		}
		if (crutch_Flag) {
			oo << "import " << imported << " is different from " << original << "\n";
		}
	}
	{	BooleanVar crutch_Flag;
		/* ia && !oa && !oi */
		
		crutch_Flag = ia;
		if(crutch_Flag) {
			crutch_Flag = !oa;
			if(crutch_Flag) {
				crutch_Flag = !oi;
			}
		}
		if (crutch_Flag) {
			oo << "original " << importedAgain << " is different from " << original << "\n";
		}
	}
}


void IDTester::shouldBeUnEqual (
		ostream& oo, 
		APTR(Heaper) original, 
		APTR(Heaper) imported, 
		APTR(Heaper) importedAgain)
{
	if (original->isEqual(imported)) {
		oo << "original and import are the same: " << original << "\n";
	}
	if (original->isEqual(importedAgain)) {
		oo << "original and 2nd import are the same: " << original << "\n";
	}
	if (imported->isEqual(importedAgain)) {
		oo << "1st and 2nd import are the same: " << imported << "\n";
	}
}


void IDTester::testIDOn (ostream& oo, APTR(ID) iD){
	/* Test an ID */
	
	SPTR(UInt8Array) exported;
	SPTR(UInt8Array) exportedAgain;
	SPTR(ID) imported;
	SPTR(ID) importedAgain;
	
	exported = iD->export();
	exportedAgain = iD->export();
	if (!exported->contentsEqual(exportedAgain)) {
		oo << "ID " << iD << " exported once to " << exported << " and then to " << exportedAgain << "\n";
	}
	imported = ID::import(exported);
	importedAgain = ID::import(exported);
	this->shouldBeEqual(oo, iD, imported, importedAgain);
	this->shouldBeEqual(oo, iD->coordinateSpace(), imported->coordinateSpace(), importedAgain->coordinateSpace());
	this->shouldBeUnEqual(oo, CAST(IDSpace,iD->coordinateSpace())->newID(), CAST(IDSpace,imported->coordinateSpace())->newID(), CAST(IDSpace,importedAgain->coordinateSpace())->newID());
	oo << "Finished testing ID " << iD << "\n\n";
}


void IDTester::testIDSpaceOn (
		ostream& oo, 
		APTR(IDSpace) space, 
		APTR(IDSpace) OR(NULL) special)
{
	/* Test an IDSpace */
	
	SPTR(UInt8Array) exported;
	SPTR(UInt8Array) exportedAgain;
	SPTR(IDSpace) imported;
	SPTR(IDSpace) importedAgain;
	
	exported = space->export();
	exportedAgain = space->export();
	if (!exported->contentsEqual(exportedAgain)) {
		oo << "IDSpace " << space << " exported once to " << exported << " and then to " << exportedAgain << "\n";
	}
	imported = IDSpace::import(exported);
	importedAgain = IDSpace::import(exported);
	this->shouldBeEqual(oo, space, imported, importedAgain);
	this->shouldBeUnEqual(oo, space->newID(), imported->newID(), importedAgain->newID());
	this->testIDOn(oo, space->newID());
	
	this->testIDOn(oo, 
			ID::usingx(special, CurrentGrandMap.fluidGet()->identifier()->withLast(33), 1));
	oo << "Finished testing IDSpace " << space << "\n";
}


void IDTester::testImportExportOn (ostream& oo){
	/* Test import/export of ID objects */
	
	SPTR(IDSpace) s;
	
	s = IDSpace::make (CurrentGrandMap.fluidGet()->identifier()->withLast(22), 7);
	this->testIDSpaceOn(oo, s, s);
	s = CurrentGrandMap.fluidGet()->newIDSpace();
	this->testIDSpaceOn(oo, s, s);
	this->testIDSpaceOn(oo, CurrentGrandMap.fluidGet()->globalIDSpace(), NULL);
}

	/* automatic 0-argument constructor */
IDTester::IDTester() {}

#ifndef IDT_SXX
#include "idt.sxx"
#endif /* IDT_SXX */



#endif /* IDT_CXX */

