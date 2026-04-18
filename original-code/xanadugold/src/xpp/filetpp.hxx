/* Copyright 1993 Xanadu Operating Company.  All Rights Reserved.
******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
***************************************************************************
*/

#include "filetpx.hxx"

#include "filetpp.oxx"

#include "wparrayx.hxx"
#include <stdio.h>

/* ************************************************************************ *
 * 
 *                    Class FCloseExecutor 
 *
 * ************************************************************************ */



/* Initializers for FCloseExecutor */




	/* This executor manages objects that need to close file 
	descriptors on finalization. */

class FCloseExecutor : public XnExecutor {

/* Attributes for class FCloseExecutor */
	CONCRETE(FCloseExecutor)
	EQ(FCloseExecutor)
	NOT_A_TYPE(FCloseExecutor)
	NO_GC(FCloseExecutor)

/* Initializers for FCloseExecutor */


  public: /* accessing */

	
	static void registerHolder (APTR(Heaper) ARG(holder), FILE * ARG(fd));
	
	
	static void unregisterHolder (APTR(Heaper) ARG(holder), FILE * ARG(fd));
	
  protected: /* protected: create */

	
	FCloseExecutor ();
	
  public: /* invoking */

	
	virtual void execute (Int32 ARG(estateIndex));
	


  /* ---------- Static Member variables (class vars) ----------- */
  private:
	static FILE ** FDArray;
	static GPTR(WeakPtrArray) FileDescriptorHolders;
};  /* end class FCloseExecutor */


