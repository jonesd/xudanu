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

#ifndef RCMAINX_CXX
#define RCMAINX_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef RCMAINX_HXX
#include "rcmainx.hxx"
#endif /* RCMAINX_HXX */

#ifndef RCMAINX_IXX
#include "rcmainx.ixx"
#endif /* RCMAINX_IXX */


#ifndef COOKBKX_HXX
#include "cookbkx.hxx"
#endif /* COOKBKX_HXX */

#ifndef FILETPX_HXX
#include "filetpx.hxx"
#endif /* FILETPX_HXX */

#ifndef FLUIDX_HXX
#include "fluidx.hxx"
#endif /* FLUIDX_HXX */

#ifndef GCHOOKSX_HXX
#include "gchooksx.hxx"
#endif /* GCHOOKSX_HXX */

#ifndef NXCVRX_HXX
#include "nxcvrx.hxx"
#endif /* NXCVRX_HXX */

#ifndef THUNKX_HXX
#include "thunkx.hxx"
#endif /* THUNKX_HXX */

#ifndef TXTCOMMX_HXX
#include "txtcommx.hxx"
#endif /* TXTCOMMX_HXX */

#ifndef XFRSPECX_HXX
#include "xfrspecx.hxx"
#endif /* XFRSPECX_HXX */




/* ************************************************************************ *
 * 
 *                    Class MainDummy 
 *
 * ************************************************************************ */



/* Initializers for MainDummy */

BUILD_FLUID(Rcvr,CurrentMainReceiver, NULL, ::globalEmulsion());	/* in MainDummy */
BUILD_FLUID(Heaper,MainActiveThunk, NULL, ::globalEmulsion());	/* in MainDummy */

/* global: booting */


int  XU_MAIN (int argc, char* * argv){
	Int32 stackObject;
	
	
	StackExaminer::stackEnd(&stackObject);
	
	Initializer mainInit(argc,argv);
	SPTR(Rcvr) rc;
	SPTR(Heaper) OR(NULL) next;
	
	if (argc < 2) {
		cerr << "usage: " << argv[Int32Zero] << " rcFileName\n";
		return 1;
	}
	rc = TextyXcvrMaker::make ()->makeRcvr(TransferSpecialist::make (Cookbook::make ("boot")), XnReadFile::make (argv[1]));
	{	FLUID_BIND(CurrentMainReceiver,rc) {
			next = CurrentMainReceiver.fluidGet()->receiveHeaper();
			while (next != NULL) {
				{	FLUID_BIND(MainActiveThunk,next) {
						BEGIN_CHOOSE(next) {
							BEGIN_KIND(Thunk,thunk) {
								thunk->execute();
							} END_KIND;
							BEGIN_OTHERS {
								
							} END_OTHERS;
						} END_CHOOSE;
					}
				}
				next = CurrentMainReceiver.fluidGet()->receiveHeaper();
			}
			CurrentMainReceiver.fluidGet()->destroy();
		}
	}
	return Int32Zero;
}

/* Initializers for MainDummy */



/* A dummy class on which to hang the main that reads in an rc file. */


/* testing */


UInt32 MainDummy::actualHashForEqual (){
	return Heaper::takeOop();
}

	/* automatic 0-argument constructor */
MainDummy::MainDummy() {}

#ifndef RCMAINX_SXX
#include "rcmainx.sxx"
#endif /* RCMAINX_SXX */



#endif /* RCMAINX_CXX */

