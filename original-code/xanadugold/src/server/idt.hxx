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

#ifndef IDT_HXX
#define IDT_HXX


#ifndef TOFUX_HXX
#include "tofux.hxx"
#endif /* TOFUX_HXX */

#ifndef INTVARX_HXX
#include "intvarx.hxx"
#endif /* INTVARX_HXX */

#ifndef IDX_HXX
#include "idx.hxx"
#endif /* IDX_HXX */

#ifndef IDT_OXX
#include "idt.oxx"
#endif /* IDT_OXX */


#ifndef SPACET_HXX
#include "spacet.hxx"
#endif /* SPACET_HXX */


#ifndef BOOTPLNX_OXX
#include "bootplnx.oxx"
#endif /* BOOTPLNX_OXX */

#ifndef SETX_OXX
#include "setx.oxx"
#endif /* SETX_OXX */


/*  */
/*  */




/* ************************************************************************ *
 * 
 *                    Class IDTester 
 *
 * ************************************************************************ */




	/* NO CLASS COMMENT */

class IDTester : public RegionTester {

/* Attributes for class IDTester */
	CONCRETE(IDTester)
	COPY(IDTester,BootCuisine)
	AUTO_GC(IDTester)
  public: /* init */

	
	virtual void destruct ();
	
	
	virtual RPTR(ImmuSet) OF1(XnRegion) initExamples ();
	
  public: /* testing */

	
	virtual void allTestsOn (ostream& ARG(oo));
	
	
	virtual void shouldBeEqual (
			ostream& ARG(oo), 
			APTR(Heaper) ARG(original), 
			APTR(Heaper) ARG(imported), 
			APTR(Heaper) ARG(importedAgain))
	;
	
	
	virtual void shouldBeUnEqual (
			ostream& ARG(oo), 
			APTR(Heaper) ARG(original), 
			APTR(Heaper) ARG(imported), 
			APTR(Heaper) ARG(importedAgain))
	;
	
	/* Test an ID */
	
	virtual void testIDOn (ostream& ARG(oo), APTR(ID) ARG(iD));
	
	/* Test an IDSpace */
	
	virtual void testIDSpaceOn (
			ostream& ARG(oo), 
			APTR(IDSpace) ARG(space), 
			APTR(IDSpace) OR(NULL) ARG(special))
	;
	
	/* Test import/export of ID objects */
	
	virtual void testImportExportOn (ostream& ARG(oo));
	

	/* automatic 0-argument constructor */
  public:
	IDTester();
  private:
	NOCOPY CHKPTR(Connection) myConnection;
};  /* end class IDTester */



#endif /* IDT_HXX */

