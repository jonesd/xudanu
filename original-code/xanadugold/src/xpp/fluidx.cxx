/*=========================================================================
  |
  |   COPYRIGHT (c) 1989 by Xanadu Operating Company, All Rights Reserved.
  |
  =========================================================================
  |
  | The information contained herein is confidential, proprietary to Xanadu
  | Operating Company, and considered a trade secret as defined in section
  | 499C of the penal code of the State of California.
  |
  | Use of this information by anyone other than authorized employees of
  | Xanadu is granted only under a written nondisclosure agreement,
  | expressly prescribing the scope and manner of such use.
  |
  | The above copyright notice is not to be construed as evidence of
  | publication or the intent to publish.
  |
  ========================================================================= */

/* $Id: fluidx.cxx,v 2.11 1993/03/16 22:29:51 eric Exp $ */

#include "tofux.hxx"
#include "fluidp.hxx"
#include "allocx.hxx"
PERMIT(N,"ALL")
#include <stdlib.h>
PERMIT(0,"ALL")

#include "fluidx.ixx"

static BooleanVar theUsedFluidsFlag = FALSE;


FluidVarDescription * FluidVarDescription::fetchNext ()
{
    return myNext;
}

unsigned FluidVarDescription::nextOffset ()
{
    return alignUp (myOffset + this->size());
}

FluidVarDescription::FluidVarDescription (Emulsion * emulsion)
{
    if (theUsedFluidsFlag) {
	BLAST(CANT_DEFINE_FLUIDS_AFTER_THEYVE_BEEN_USED);
    }
    myNext = emulsion->addToEmulsion (this);
    myOffset = myNext ? myNext->nextOffset () : 0;
    myEmulsion = emulsion;
}


Emulsion::Emulsion () {
    myFluidsList = NULL;
}

char * Emulsion::fluidsSpace ()
{
    char * result;
    result = (char *) this->fetchOldRawSpace();
    if (result != NULL) {
	return result;
    } else {
	return this->getNewFluidsSpace ();
    }
}

char * Emulsion::getNewFluidsSpace ()
{
    char * result;
    FluidVarDescription * fluid;

    if (myFluidsList == NULL) {
	BLAST(NO_FLUIDS);
      }
    result = (char *) this->fetchNewRawSpace (myFluidsList->nextOffset ());
    if (result == NULL) {
	BLAST(CANT_ALLOCATE_SPACE_FOR_FLUIDS);
    }
    theUsedFluidsFlag = TRUE;
    for (fluid = myFluidsList; fluid != NULL; fluid = fluid->fetchNext()) {
	/* NOTE: This call probably does a recursive entry to fluidsSpace,
	    so the Emulsion subclass had better return the same result
	    from fetchOldRawSpace that it just returned from fetchNewRawSpace
	force compile 10/17/94 hkh to fix calloc to fcalloc	*/
	fluid->init ();
    }
    return result;
}

void Emulsion::destructAll ()
{
    FluidVarDescription * fluid;
    for (fluid = myFluidsList; fluid != NULL; fluid = fluid->fetchNext()) {
	fluid->destructIt();
    }
}

FluidVarDescription * Emulsion::addToEmulsion (FluidVarDescription * fvd)
{
    FluidVarDescription * result = myFluidsList;
    myFluidsList = fvd;
    return result;
}

void * theGlobalFluidStorage = NULL;

void * GlobalEmulsion::fetchNewRawSpace (size_t size)
{
    return theGlobalFluidStorage = fcalloc (size, sizeof(char));
}

void * GlobalEmulsion::fetchOldRawSpace ()
{
    return theGlobalFluidStorage;
}

Emulsion * GlobalEmulsion::TheEmulsion = NULL;

Emulsion * globalEmulsion ()
{
    if (GlobalEmulsion::TheEmulsion == NULL) {
	GlobalEmulsion::TheEmulsion = new GlobalEmulsion();
    }
    return GlobalEmulsion::TheEmulsion;
}

