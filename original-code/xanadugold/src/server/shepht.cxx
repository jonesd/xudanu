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

#ifndef SHEPHT_CXX
#define SHEPHT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef SHEPHT_HXX
#include "shepht.hxx"
#endif /* SHEPHT_HXX */

#ifndef SHEPHT_IXX
#include "shepht.ixx"
#endif /* SHEPHT_IXX */


#ifndef BOOTPLNX_HXX
#include "bootplnx.hxx"
#endif /* BOOTPLNX_HXX */

#ifndef COUNTERX_HXX
#include "counterx.hxx"
#endif /* COUNTERX_HXX */

#ifndef GCHOOKSX_HXX
#include "gchooksx.hxx"
#endif /* GCHOOKSX_HXX */

#ifndef PRIMTABX_HXX
#include "primtabx.hxx"
#endif /* PRIMTABX_HXX */




/* ************************************************************************ *
 * 
 *                    Class ShepherdLocked 
 *
 * ************************************************************************ */


/* instance creation */


RPTR(ShepherdLocked) ShepherdLocked::makeLocked (){
	RETURN_CONSTRUCT(ShepherdLocked,());
}


RPTR(ShepherdLocked) ShepherdLocked::makeUnlocked (){
	SPTR(ShepherdLocked) aLockedShepherd;
	
	CONSTRUCT(aLockedShepherd,ShepherdLocked,());
	aLockedShepherd->publicUnlock();
	WPTR(ShepherdLocked) 	returnValue;
	returnValue = aLockedShepherd;
	return returnValue;
}
/* instance creation */


ShepherdLocked::ShepherdLocked () {
	
}
/* accessing */


BooleanVar ShepherdLocked::isReallyUnlocked (){
	
	return StackExaminer::pointersOnStack()->fetch((Int32)(void*)this) == NULL;
	
}
/* testing locks */


void ShepherdLocked::publicUnlock (){
	/* self unlock */
	
	
}



/* ************************************************************************ *
 * 
 *                    Class ShepherdLockTester 
 *
 * ************************************************************************ */


/* testing */


void ShepherdLockTester::allTestsOn (ostream& oo){
	/* ShepherdLockTester runTest */
	
	SPTR(Connection) conn;
	
	conn = Connection::make (cat_Counter);
	this->test1On(oo);
	{conn->destroy();  conn = NULL /* don't want stale (S/CHK)PTRs */;}
}


void ShepherdLockTester::test1On (ostream& oo){
	/* ShepherdLockTester runTest: #test1On: */
	
	SPTR(ShepherdLocked) aLocked;
	SPTR(ShepherdLocked) anUnlocked;
	SPTR(PrimPtrTable) stackPtrs;
	
	stackPtrs = StackExaminer::pointersOnStack();
	aLocked = ShepherdLocked::makeLocked();
	anUnlocked = ShepherdLocked::makeUnlocked();
	oo << "aLocked Shepherd ";
	
	if (stackPtrs->fetch((Int32)(void*)aLocked) == NULL) {
		oo << "is locked";
	} else {
		oo << "is not locked";
	}
	
	if (aLocked->isReallyUnlocked()) {
		oo << "; is really not locked";
	} else {
		oo << "; is really locked";
	}
	oo << "\nanUnlocked Shepherd ";
	
	if (stackPtrs->fetch((Int32)(void*)anUnlocked) == NULL) {
		oo << "is locked";
	} else {
		oo << "is not locked";
	}
	
	if (anUnlocked->isReallyUnlocked()) {
		oo << "; is really not locked";
	} else {
		oo << "; is really locked";
	}
	oo << "\n";
}

	/* automatic 0-argument constructor */
ShepherdLockTester::ShepherdLockTester() {}

#ifndef SHEPHT_SXX
#include "shepht.sxx"
#endif /* SHEPHT_SXX */



#endif /* SHEPHT_CXX */

