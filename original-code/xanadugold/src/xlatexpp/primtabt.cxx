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

#ifndef PRIMTABT_CXX
#define PRIMTABT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef PRIMTABT_HXX
#include "primtabt.hxx"
#endif /* PRIMTABT_HXX */

#ifndef PRIMTABT_IXX
#include "primtabt.ixx"
#endif /* PRIMTABT_IXX */


#ifndef BOOTPLNX_HXX
#include "bootplnx.hxx"
#endif /* BOOTPLNX_HXX */

#ifndef RECIPEX_HXX
#include "recipex.hxx"
#endif /* RECIPEX_HXX */




/* ************************************************************************ *
 * 
 *                    Class PrimIndexTableTester 
 *
 * ************************************************************************ */


/* tests */


void PrimIndexTableTester::accessTestOn (ostream& oo){
	SPTR(PrimIndexTable) tab;
	
	/* For this tests, I use as keys category pointers from the 
	minimal xpp set */
	tab = PrimIndexTable::make (7);
	/* first test a few introduces */
	tab->introduce(cat_Heaper, 1);
	tab->introduce(cat_Category, 2);
	tab->introduce(cat_PrimIndexTable, 3);
	if (tab->get(cat_Heaper) != 1) {
		BLAST(IntroduceFailed);
	}
	if (tab->get(cat_Category) != 2) {
		BLAST(IntroduceFailed);
	}
	if (tab->get(cat_PrimIndexTable) != 3) {
		BLAST(IntroduceFailed);
	}
	/* now do some more to cause a grow. */
	tab->introduce(cat_Tester, 4);
	tab->introduce(cat_PrimIndexTableTester, 5);
	tab->introduce(cat_Recipe, 7);
	tab->introduce(cat_BootMaker, 8);
	if (tab->get(cat_Heaper) != 1) {
		BLAST(IntroduceFailed);
	}
	if (tab->get(cat_Category) != 2) {
		BLAST(IntroduceFailed);
	}
	if (tab->get(cat_PrimIndexTable) != 3) {
		BLAST(IntroduceFailed);
	}
	if (tab->get(cat_Tester) != 4) {
		BLAST(IntroduceFailed);
	}
	if (tab->get(cat_PrimIndexTableTester) != 5) {
		BLAST(IntroduceFailed);
	}
	if (tab->get(cat_Recipe) != 7) {
		BLAST(IntroduceFailed);
	}
	if (tab->get(cat_BootMaker) != 8) {
		BLAST(IntroduceFailed);
	}
	/* Now remove some stuff. */
	tab->remove(cat_Recipe);
	if (tab->get(cat_Heaper) != 1) {
		BLAST(RemoveFouled);
	}
	if (tab->get(cat_Category) != 2) {
		BLAST(RemoveFouled);
	}
	if (tab->get(cat_PrimIndexTable) != 3) {
		BLAST(RemoveFouled);
	}
	if (tab->get(cat_Tester) != 4) {
		BLAST(IntroduceFailed);
	}
	if (tab->get(cat_PrimIndexTableTester) != 5) {
		BLAST(IntroduceFailed);
	}
	if (tab->get(cat_BootMaker) != 8) {
		BLAST(IntroduceFailed);
	}
}
/* testing */


void PrimIndexTableTester::allTestsOn (ostream& oo){
	this->accessTestOn(oo);
}

	/* automatic 0-argument constructor */
PrimIndexTableTester::PrimIndexTableTester() {}



/* ************************************************************************ *
 * 
 *                    Class PrimPtrTableTester 
 *
 * ************************************************************************ */


/* tests */


void PrimPtrTableTester::accessTestOn (ostream& oo){
	SPTR(PrimPtrTable) tab;
	
	/* For this tests, I use as keys category pointers from the 
	minimal xpp set */
	tab = PrimPtrTable::make (7);
	/* first test a few introduces */
	tab->introduce(1, cat_Heaper);
	tab->introduce(2, cat_Category);
	tab->introduce(3, cat_PrimIndexTable);
	if (tab->get(1) != cat_Heaper) {
		BLAST(IntroduceFailed);
	}
	if (tab->get(2) != cat_Category) {
		BLAST(IntroduceFailed);
	}
	if (tab->get(3) != cat_PrimIndexTable) {
		BLAST(IntroduceFailed);
	}
	/* now do some more to cause a grow. */
	tab->introduce(4, cat_Tester);
	tab->introduce(5, cat_PrimIndexTableTester);
	tab->introduce(7, cat_Recipe);
	tab->introduce(8, cat_BootMaker);
	if (tab->get(1) != cat_Heaper) {
		BLAST(IntroduceFailed);
	}
	if (tab->get(2) != cat_Category) {
		BLAST(IntroduceFailed);
	}
	if (tab->get(3) != cat_PrimIndexTable) {
		BLAST(IntroduceFailed);
	}
	if (tab->get(4) != cat_Tester) {
		BLAST(IntroduceFailed);
	}
	if (tab->get(5) != cat_PrimIndexTableTester) {
		BLAST(IntroduceFailed);
	}
	if (tab->get(7) != cat_Recipe) {
		BLAST(IntroduceFailed);
	}
	if (tab->get(8) != cat_BootMaker) {
		BLAST(IntroduceFailed);
	}
	/* Now remove some stuff. */
	tab->remove(7);
	if (tab->get(1) != cat_Heaper) {
		BLAST(RemoveFouled);
	}
	if (tab->get(2) != cat_Category) {
		BLAST(RemoveFouled);
	}
	if (tab->get(3) != cat_PrimIndexTable) {
		BLAST(RemoveFouled);
	}
	if (tab->get(4) != cat_Tester) {
		BLAST(RemoveFouled);
	}
	if (tab->get(5) != cat_PrimIndexTableTester) {
		BLAST(RemoveFouled);
	}
	if (tab->get(8) != cat_BootMaker) {
		BLAST(RemoveFouled);
	}
}
/* testing */


void PrimPtrTableTester::allTestsOn (ostream& oo){
	this->accessTestOn(oo);
}

	/* automatic 0-argument constructor */
PrimPtrTableTester::PrimPtrTableTester() {}

#ifndef PRIMTABT_SXX
#include "primtabt.sxx"
#endif /* PRIMTABT_SXX */



#endif /* PRIMTABT_CXX */

