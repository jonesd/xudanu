/* Copyright Xanadu Operating Company.  All Rights Reserved.
	6 September 1991 at 2:05:25 pm
******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
******************************************************************************
*/


#ifndef UBUILDX_HXX
#define UBUILDX_HXX

#include "thunkx.hxx"


/* ************************************************************************ *
 * 
 *                    Class BuildUrdiFile
 *
 * ************************************************************************ */


/* Declarations for BuildUrdiFile */

CLASS (BuildUrdiFile,Thunk) {
	CONCRETE(BuildUrdiFile)
	COPY(BuildUrdiFile,BootCuisine)
	NOT_A_TYPE(BuildUrdiFile)
	AUTO_GC(BuildUrdiFile)
  public:

	LEAF void execute ();

	BuildUrdiFile();

  private:
	char * myFilename;
	Int32 mySnarfSize;
	Int32 mySnarfCount;
	Int32 myStageCount;
};

#endif /* UBUILDX_HXX */
