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

#ifndef DISKMANX_CXX
#define DISKMANX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef DISKMANX_HXX
#include "diskmanx.hxx"
#endif /* DISKMANX_HXX */

#ifndef DISKMANX_IXX
#include "diskmanx.ixx"
#endif /* DISKMANX_IXX */

#ifndef DISKMANP_HXX
#include "diskmanp.hxx"
#endif /* DISKMANP_HXX */

#ifndef DISKMANP_IXX
#include "diskmanp.ixx"
#endif /* DISKMANP_IXX */


#ifndef COOKBKX_HXX
#include "cookbkx.hxx"
#endif /* COOKBKX_HXX */

#ifndef COUNTERX_HXX
#include "counterx.hxx"
#endif /* COUNTERX_HXX */

#ifndef FLKINFOX_HXX
#include "flkinfox.hxx"
#endif /* FLKINFOX_HXX */

#ifndef PACKERX_HXX
#include "packerx.hxx"
#endif /* PACKERX_HXX */

#ifndef RECIPEX_HXX
#include "recipex.hxx"
#endif /* RECIPEX_HXX */

#ifndef SHEPHX_HXX
#include "shephx.hxx"
#endif /* SHEPHX_HXX */

#ifndef TURTLEX_HXX
#include "turtlex.hxx"
#endif /* TURTLEX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */




/* ************************************************************************ *
 * 
 *                    Class DiskManager 
 *
 * ************************************************************************ */



/* Initializers for DiskManager */

Recipe * DiskCuisine = NULL;	/* in DiskManager */
Emulsion * DiskManager::SecretEmulsion = NULL;


BUILD_FLUID(DiskManager,CurrentPacker, NULL, ::globalEmulsion());	/* in DiskManager */
BUILD_PRIM_FLUID(BooleanVar,InsideAgenda, FALSE, DiskManager::emulsion());	/* in DiskManager */

/* exceptions: exceptions */

/* Initializers for DiskManager */






/* creation */


RPTR(DiskManager) DiskManager::initializeDisk (char * fname){
	/* This builds the disk managing structure. */
	
	CurrentPacker.fluidSet(SnarfPacker::initializeUrdiOnDisk(fname));
	WPTR(DiskManager) 	returnValue;
	returnValue = CurrentPacker.fluidGet();
	return returnValue;
}


RPTR(DiskManager) DiskManager::make (char * fname){
	CurrentPacker.fluidSet(SnarfPacker::make (fname));
	WPTR(DiskManager) 	returnValue;
	returnValue = CurrentPacker.fluidGet();
	return returnValue;
}
/* emulsion accessing */


Emulsion * DiskManager::emulsion (){
	
	if (DiskManager::SecretEmulsion == NULL) {
		DiskManager::SecretEmulsion = DiskManagerEmulsion::make ();
	}
	Emulsion * 	returnValue;
	returnValue = DiskManager::SecretEmulsion;
	return returnValue;
}
/* This is the public interface for managing objects that should go to disk.
This is also the anchor for the so-called Backend emulsion, but I'll call it
the DiskManager emulsion for simplicity. */


/* shepherds */


void DiskManager::setHashCounter (APTR(Counter) /* aCounter */){
	
}
/* stubs */
/* transactions */


void DiskManager::consistentBlockAt (char * /* fileName */, Int32 /* lineNo */){
	/* This is called after beginConsistent, but before entering 
	a consistent block, for debugging purposes.  Default is to do 
	nothing */
	
	
}
/* testing */


UInt32 DiskManager::actualHashForEqual (){
	return Heaper::takeOop();
}
/* protected: accessing */
/* accessing */
/* protected: creation */


DiskManager::DiskManager () {
	myFluidSpace = NULL;
	myFlockInfoTable = PrimPtrTable::make (2048);
	myFlockTable = WeakPtrArray::make (Cattleman::make (this), 2048);
}


void DiskManager::destruct (){
	if (myFluidSpace != NULL) {
		{	FLUID_BIND(CurrentPacker,this) {
				DiskManager::emulsion()->destructAll();
			}
		}
	}
	this->Heaper::destruct();
}
/* emulsion accessing */


char * DiskManager::fluidSpace (){
	return (char*) myFluidSpace;
}


char * DiskManager::fluidSpace (char * aFluidSpace){
	char * 	returnValue;
	returnValue = myFluidSpace = aFluidSpace;
	return returnValue;
}



/* ************************************************************************ *
 * 
 *                    Class ShepherdBootMaker 
 *
 * ************************************************************************ */


/* creation */


RPTR(BootPlan) ShepherdBootMaker::make (){
	RETURN_CONSTRUCT(ShepherdBootMaker,());
}
/* accessing */


RPTR(Category) ShepherdBootMaker::bootCategory (){
	WPTR(Category) 	returnValue;
	returnValue = cat_Counter;
	return returnValue;
}
/* protected: */


RPTR(Heaper) ShepherdBootMaker::bootHeaper (){
	WPTR(Heaper) 	returnValue;
	returnValue = Counter::make ();
	return returnValue;
}

	/* automatic 0-argument constructor */
ShepherdBootMaker::ShepherdBootMaker() {}



/* ************************************************************************ *
 * 
 *                    Class Cattleman 
 *
 * ************************************************************************ */


/* create */


RPTR(Cattleman) Cattleman::make (APTR(DiskManager) dm){
	RETURN_CONSTRUCT(Cattleman,(dm, tcsj));
}
/* Remove flocks from the snarfpacker */


/* create */


Cattleman::Cattleman (APTR(DiskManager) dm, TCSJ) {
	myPasture = dm;
}
/* invoking */


void Cattleman::execute (Int32 token){
	/* [Drops add: token] smalltalkOnly. */
	
	if (::isConstructed(myPasture)) {
		
		myPasture->dropFlock(token);
		
	}
}



/* ************************************************************************ *
 * 
 *                    Class DiskConnection 
 *
 * ************************************************************************ */


/* Keep an object from the disk.  For the moment, put the disk 
connection in a global variable and export a function so that anyone 
can destroy it.... */


/* accessing */


RPTR(Category) DiskConnection::bootCategory (){
	return (Category*) myCategory;
}


RPTR(Heaper) DiskConnection::bootHeaper (){
	return (Heaper*) myHeaper;
}
/* creation */


DiskConnection::DiskConnection (APTR(Category) cat, APTR(Heaper) heaper) {
	myCategory = cat;
	myHeaper = heaper;
}


void DiskConnection::destruct (){
	myHeaper = NULL;
	CurrentPacker.fluidGet()->purge();
	CurrentPacker.fluidGet()->destroy();
	CurrentPacker.fluidSet((DiskManager * ) NULL);
	this->Connection::destruct();
}



/* ************************************************************************ *
 * 
 *                    Class DiskManagerEmulsion 
 *
 * ************************************************************************ */


/* creation */


DiskManagerEmulsion * DiskManagerEmulsion::make (){
	DiskManagerEmulsion * 	returnValue;
	returnValue = new DiskManagerEmulsion();
	return returnValue;
}
/* accessing */


void * DiskManagerEmulsion::fetchNewRawSpace (size_t size){
	return CurrentPacker.fluidGet()->fluidSpace( (char *) fcalloc (size, sizeof(char)) );
	
	
}


void * DiskManagerEmulsion::fetchOldRawSpace (){
	void * 	returnValue;
	returnValue = CurrentPacker.fluidGet()->fluidSpace();
	return returnValue;
}
/* creation */


DiskManagerEmulsion::DiskManagerEmulsion () {
	
}



/* ************************************************************************ *
 * 
 *                    Class FromDiskPlan 
 *
 * ************************************************************************ */


/* Instances of this represent the plan for getting a particular kind 
of object from an urdi on a particular file.  They open the urdi, 
create a packer, retrieve the Turtle from the packer, and pull out 
the boot object. */


/* accessing */


RPTR(Category) FromDiskPlan::bootCategory (){
	return (Category*) myCategory;
}


RPTR(Connection) FromDiskPlan::connection (){
	/* Return the object representing the connection.  This gives 
	the client a handle by which to terminate the connection. */
	
	DiskManager::make (myFilename);
	RETURN_CONSTRUCT(DiskConnection,(this->bootCategory(), CurrentPacker.fluidGet()->getInitialFlock()->bootHeaper()));
}
/* creation */


FromDiskPlan::FromDiskPlan (APTR(Category) cat, char * filename) {
	myCategory = cat;
	myFilename = filename;
}

#ifndef DISKMANX_SXX
#include "diskmanx.sxx"
#endif /* DISKMANX_SXX */


#ifndef DISKMANP_SXX
#include "diskmanp.sxx"
#endif /* DISKMANP_SXX */



#endif /* DISKMANX_CXX */

