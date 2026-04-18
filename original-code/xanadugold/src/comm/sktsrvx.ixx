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

#ifndef SKTSRVX_IXX
#define SKTSRVX_IXX


#include <sys/types.h>
#if defined(HIGHC) | defined(_MSC_VER)
#	include <sys/time.h>
#endif /* HIGHC | _MSC_VER */
#include <stdlib.h>
#include <stream.h>
#include <string.h>
#include <fcntl.h>

#ifdef unix
#	include <netdbx.hxx>
#	include <sys/socket.h>
#	include <netinet/in.h>
#	include <sys/socket.h>
#	include <osfcn.h>
#	ifdef __sgi
		int	getdtablesize();		/* SGI forgot to put it in osfcn.h */
#		include <libc.h>	/* for bzero(), which is called by FD_ZERO */
#		include <errno.h>
#	endif	/* sgi */
#endif /* unix */
#ifdef GNUSUN
extern "C"{
#include <signal.h>
}

#else
#include <signal.h>
#endif

#ifdef WIN32
#	include <winsock.h>
#	include <io.h>
#	define close _close
#endif /* WIN32 */

#ifdef HIGHC
extern "C" {
#	define NOMEMMGR /* TO AVOID GPTR MACRO CONFLICT */
#	include <nmpcip.h>
};
#endif /* HIGHC */
#include <socketx.hxx>




/* ************************************************************************ *
 * 
 *                    Class FDListener 
 *
 * ************************************************************************ */


/* exceptions: exceptions */
/* accessing */
/* creation */


#endif /* SKTSRVX_IXX */

