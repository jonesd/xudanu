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

#ifndef BECOMET_CXX
#define BECOMET_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef BECOMET_HXX
#include "becomet.hxx"
#endif /* BECOMET_HXX */

#ifndef BECOMET_IXX
#include "becomet.ixx"
#endif /* BECOMET_IXX */




/* ************************************************************************ *
 * 
 *                    Class BecomeTester 
 *
 * ************************************************************************ */


/* testing */


void BecomeTester::allTestsOn (ostream& oo){
	/* BecomeTester runTest */
	
	this->test1On(oo);
}


void BecomeTester::test1On (ostream& oo){
	/* BecomeTester runTest: #test1On: */
	
	SPTR(Chameleon) cham;
	
	cham = Moth::make ();
	cham->explain(oo);
	CAST(Moth,cham)->molt();
	cham->explain(oo);
}

	/* automatic 0-argument constructor */
BecomeTester::BecomeTester() {}



/* ************************************************************************ *
 * 
 *                    Class Chameleon 
 *
 * ************************************************************************ */


/* instance creation */


Chameleon::Chameleon () {
	myA = IntegerVar0;
	myB = NULL;
	myC = FALSE;
}


Chameleon::Chameleon (
		IntegerVar a, 
		APTR(Heaper) b, 
		BooleanVar c) 
{
	myA = a;
	myB = b;
	myC = c;
}
/* accessing */


void Chameleon::explain (ostream& oo){
	oo << this->getCategory()->name() << "\n";
}
/* testing */


UInt32 Chameleon::actualHashForEqual (){
	return Heaper::takeOop();
}



/* ************************************************************************ *
 * 
 *                    Class   Butterfly 
 *
 * ************************************************************************ */


/* instance creation */


Butterfly::Butterfly () {
	myE = IntegerVar0;
	myF = NULL;
}



/* ************************************************************************ *
 * 
 *                    Class     GoldButterfly 
 *
 * ************************************************************************ */



	/* automatic 0-argument constructor */
GoldButterfly::GoldButterfly() {}



/* ************************************************************************ *
 * 
 *                    Class     IronButterfly 
 *
 * ************************************************************************ */



	/* automatic 0-argument constructor */
IronButterfly::IronButterfly() {}



/* ************************************************************************ *
 * 
 *                    Class     LeadButterfly 
 *
 * ************************************************************************ */



	/* automatic 0-argument constructor */
LeadButterfly::LeadButterfly() {}



/* ************************************************************************ *
 * 
 *                    Class   DeadButterfly 
 *
 * ************************************************************************ */


/* instance creation */


DeadButterfly::DeadButterfly () {
	myJ = IntegerVar0;
	myK = NULL;
}



/* ************************************************************************ *
 * 
 *                    Class   DeadMoth 
 *
 * ************************************************************************ */


/* instance creation */


DeadMoth::DeadMoth () {
	myG = IntegerVar0;
	myH = NULL;
	myI = FALSE;
}



/* ************************************************************************ *
 * 
 *                    Class   Moth 
 *
 * ************************************************************************ */


/* instance creation */


RPTR(Moth) Moth::make (){
	RETURN_CONSTRUCT(Moth,(4, tcsj));
}
/* becoming */


void Moth::molt (){
	new (this) Butterfly();
}
/* instance creation */


Moth::Moth (IntegerVar d, TCSJ) {
	myD = d;
}

#ifndef BECOMET_SXX
#include "becomet.sxx"
#endif /* BECOMET_SXX */



#endif /* BECOMET_CXX */

