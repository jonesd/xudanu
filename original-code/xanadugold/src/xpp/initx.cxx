/*
      (C) Copyright 1990 by Xanadu Operating Company, All Rights Reserved.

******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
**************************************************************************** */

/* $Id: initx.cxx,v 2.6 1993/03/24 02:48:12 eric Exp $ */

#include "initx.hxx"
#include "bombx.hxx"
PERMIT(N,"ALL")
#include <stream.h>
PERMIT(0,"ALL")

#include "initx.sxx"

/*
	See initx.hxx

	Author: Eric C. Hill

	Modified without comment by MSM
*/


static Initer * initerString = NULL;
// static Initer * initerTail = NULL;    UNUSED
static Terminator * terminationString = NULL;

PERMIT(2,"reference")
static ostream& operator<< (ostream& oo, Initer * initer)
{
    initer->printOn (oo);
    return oo;
}

void dumpInitState (Category * cat)
{
    cerr << "dumping initializer state\n";
    for (Initer * initer = initerString; initer; initer = initer->next()) {
	if (initer->myCat->isEqualOrSubclassOf (cat)) {
	     operator<<(cerr,((Initer *) initer));
        cerr << "\n";
	}
    }
    cerr << "\n";
}

static int argCount = 0;
static char ** argVector = NULL;

int mainAC ()
{
  return argCount;
}

char ** mainAV ()
{
  return argVector;
}

BooleanVar Initializer::InStaticDestruction = FALSE;

BooleanVar Initializer::inStaticDestruction ()
{
    return InStaticDestruction;
}

Initializer::Initializer (int ac /*= 0*/, char ** av /*= NULL*/)
{
    PERMIT(2,"assignment to global variable")
    argCount = ac;
    argVector = av;
    if (av == NULL && ac != 0) {
	BLAST(MUST_DEFAULT_BOTH_OR_NEITHER);
    }

    initializeCategoryInformation ();

    for (Initer * initer = initerString; initer; initer = initer->next()) {
	if (initer->initState() == NOT_DONE) {
	    initer->initialize();
	}
    }

}


Initializer::~Initializer ()
{
    Terminator * arnie = terminationString;
    for (; arnie; arnie = arnie->next()) {
	arnie->terminate ();
    }
    InStaticDestruction = TRUE;
    cout.flush();	// SGI, at one time, didn't do it automagically.
}

PERMIT(1,"reference")
void Initer::printOn (ostream& oo)
{
    oo << "Initer(" << myInitState << ", cat_" << myCat->name() << ")";
}

#define BACKWARDS_KLUDGE

#ifdef BACKWARDS_KLUDGE

Initer::Initer (Category * cat)
{
    myInitState = NOT_DONE;
    myNext = initerString;
    myCat = cat;
    PERMIT(1,"assignment to global variable")
    initerString = this;
}

#else

Initer::Initer (Category * cat)
{
    myInitState = NOT_DONE;
    myNext = NULL;
    myCat = cat;
    if (initerString == NULL) {
	initerString = initerTail = this;
    } else {
	initerTail->next (this);
	initerTail = this;
    }
}

#endif

void Initer::requires (Category * cat)
{
    for (Initer * init = initerString; init; init = init->next()) {
	if (init->matches (cat)) {
	    if (init->initState() == NOT_DONE) {
		init->initialize ();
	    } else if (init->initState() == IN_PROGRESS) {
		BLAST(CIRCULAR_INIT_DEPENDENCY);
	    }
	}
    }
}


void Initer::initState (IniterState iState)
{
    myInitState = iState;
}

IniterState Initer::initState ()
{
    return myInitState;
}

Initer * Initer::next ()
{
    return myNext;
}

void Initer::next (Initer * newNext)
{
    myNext = newNext;
}

BooleanVar Initer::matches (Category * cat)
{
    return myCat->isEqual (cat);
}


Terminator * Terminator::next ()
{
    return myNext;
}

Terminator::Terminator (Category * cat)
{
    myCat = cat;
    myNext = terminationString;
    PERMIT(1,"assignment to global variable") 
    terminationString = this;
}


