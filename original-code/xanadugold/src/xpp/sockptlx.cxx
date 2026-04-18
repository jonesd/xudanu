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

// Comments from the version of socktpx.cxx that this diverges from:
//
//	added logging code
//		- ech 91-5-29
//
//
//      Changed to use <netinet/in.h> rather than "inc.h" 
//      (canonical version for the system, not a local copy.)
//              - michael Apr 6 1992 
//
//    Added TEMPORARY!!!! kludge for sgi BSD handlers to return an ignored int
//    (Should find out what proper return protocol is.)
//            - michael Apr 7 1992
 
#ifndef SOCKPTLX_CXX
#define SOCKPTLX_CXX

/* $Id: sockptlx.cxx,v 1.16 1993/04/10 00:54:01 eric Exp $ */

#include "sockptlx.hxx"

#include "sockptlx.ixx"

#include "parrayx.hxx"
#include "gchooksx.hxx"

#ifdef unix
#	include <signal.h>
#	include <sys/types.h>
#	include <sys/time.h>
#endif /* unix */

#define RCV_TIMEOUT 10

#include <stdlib.h>
#include <stream.h>
#include <string.h>
#include <fcntl.h>
#ifdef unix
//#	include <osfcn.h>
#	include <netdb.h>
#	include <sys/types.h>
#	include <time.h>
#	include <netinet/in.h>
#	include <sys/socket.h>
#   ifdef __sgi
#	    include <errno.h>
#       include <sys/ioctl.h>
#   else
#       include <sys/filio.h>
#   endif
#endif /* unix */
#ifdef HIGHC
#	define NOMEMMGR /* to avoid GPTR macro name conflict */
#	include <nmpcip.h>
#	include <time.h>
#endif /* HIGHC */

#define SENDFLAGS (0)

#ifndef DOTDOTDOT
#define DOTDOTDOT
#endif

//#include <fstream.h>
//ofstream socketRecorder("socket.text");

static void recordBuffer (APTR(UInt8Array) buffer, int status) {
/*
    if (socketRecorder) {
	{
	    PLANT_BOMB(ReleaseGuts,guts);
	    ARM_BOMB(guts,buffer);
	    socketRecorder.write(buffer->gutsOf(), status);
	}
    }
*/
}


/* ************************************************************************ *
 * 
 *		    Class SocketPortal 
 *
 * ************************************************************************ */


/* log file initialization and closing */

static int logFD = -1;

BEGIN_INIT_TIME(SocketPortal,initLogFile) {
    for (UInt32 i = 1; i < mainAC(); i++) {
	if (mainAV()[i][0] == '-' && mainAV()[i][1] == 'l') {
	    logFD = open (mainAV()[i]+2, O_CREAT | O_WRONLY | O_TRUNC, 0660);
	    if (logFD == -1) {
		BLAST(CANT_OPEN_LOG_FILE);
	    }
	}
    }
} END_INIT_TIME(SocketPortal,initLogFile);

BEGIN_EXIT_TIME(SocketPortal,closeLogFile) {
    if (logFD != -1) {
	close (logFD);
    }
} END_EXIT_TIME(SocketPortal,closeLogFile);


/* pseudo constructors */

RPTR(PacketPortal) SocketPortal::make (char * hostName, UInt32 port){
	/* Portal make: 'vlad' with: 16rcafe */
	/* I suspect this doesn't do a close under some situations where it should (and 
	where the old code did). */
	int socketFD;
	
	
	int status;
	struct	sockaddr_in *	sockName= (struct  sockaddr_in *)falloc(sizeof (struct sockaddr_in));
	sockName->sin_family = AF_INET;
	sockName->sin_port = htons((unsigned short)port);

	hostent * host = gethostbyname(hostName);
	if (host == NULL) {
	  BLAST(HOSTNAME_LOOKUP_FAILURE);
	}
	sockName->sin_addr.s_addr = *(u_long*) host->h_addr;
	socketFD = socket( AF_INET, SOCK_STREAM, IPPROTO_TCP );
	if (socketFD < 0) {
		BLAST_WITH_VAL(FAILED_TO_ALLOCATE_SOCKET, socketFD);
	}

	// connect to destination host port
	if (status = connect(socketFD,
#ifdef HIGHC
				 sockName,
#else
				 (sockaddr*)sockName,
#endif
			     sizeof(struct sockaddr_in))) {
		cerr << "Socket connect failure\n";
		cerr << "\tstatus = " << status << "\n";
		perror ("\tsystem error");
		cerr << "\n";
		BLAST_WITH_VAL(SOCKET_CONNECT_FAILURE, status);
	}
	
	
	
	RETURN_CONSTRUCT(SocketPortal,(socketFD, tcsj));
}

RPTR(PacketPortal) SocketPortal::make (int fd)
{
  RETURN_CONSTRUCT(SocketPortal,(fd,tcsj));
}


/* accessing */

void SocketPortal::flush (){
    /* Make sure the bits go out. */
	
}


RPTR(UInt8Array) SocketPortal::readBuffer (){
    /* Return a buffer of a size that the unerlying transport 
       layer likes. */
	
    WPTR(UInt8Array) 	returnValue;
	
    returnValue = UInt8Array::make (512, (void *)falloc(512));

    return returnValue;
}

#ifdef GNUSUN
	extern "C" {
	int sigvec(...);
	}
#endif
Int32 SocketPortal::readPacket (APTR(UInt8Array) buffer, Int32 count){
	/* receive a buffer of data */

	if (count > buffer->count()) {
	    BLAST(MEM_ALLOC_ERROR);
	}

	int	status;
#ifdef unix
	long availCount;
	struct timeval timeout;
	ioctl(mySocketFD, FIONREAD, (char*)&availCount);
	availCount = min(availCount, count);
	if (availCount == 0) {
	    timeout.tv_sec = 0;
	    timeout.tv_usec = 10000;
	    select(0, NULL, NULL, NULL, &timeout);
	    ioctl(mySocketFD, FIONREAD, (char*)&availCount);
	    availCount = min(availCount, count);
	}
	if (availCount != 0) {
	    PLANT_BOMB(ReleaseGuts,guts);
	    ARM_BOMB(guts,buffer);
	    status = recv (mySocketFD, buffer->gutsOf(), (int)availCount, SENDFLAGS);
	    if (status < 0) {
		BLAST_WITH_VAL(SOCKET_RECV_ERROR, errno);
	    } else {
		recordBuffer (buffer, status);
		return status;
	    }
	}
	/* if still nothing, drop down to more expensive recv */

	static struct sigvec myVec, oldVec;

# ifndef sgi
	void handleAlarm(DOTDOTDOT);
# else /* sgi */
	int handleAlarm(int,...);
	int sigvec(...);
# endif /* sgi */

	myVec.sv_handler = handleAlarm;
	myVec.sv_mask = 0;
	myVec.sv_flags = SV_INTERRUPT;
	sigvec (SIGALRM, &myVec, &oldVec);
	alarm (RCV_TIMEOUT);
#endif /* unix */
	{
	    PLANT_BOMB(ReleaseGuts,guts);
	    ARM_BOMB(guts,buffer);
	    status = recv (mySocketFD, buffer->gutsOf(), (int)count, SENDFLAGS);
	}
	if (status < 0) {
#ifdef unix
	    alarm (0);
#endif /* unix */
	    if (errno == EINTR) {
		status = 0;
		myTimeoutCount += 1;
		if (myTimeoutCount > 8) {
		    myTimeoutCount = 0;
		    BLAST_WITH_VAL(SOCKET_RECV_ERROR, errno);
		}
	    } else {
		BLAST_WITH_VAL(SOCKET_RECV_ERROR, errno);
	    }
	}
#ifdef unix
	alarm (0);
	sigvec (SIGALRM, &oldVec, NULL);
#endif /* unix */
	if (logFD != -1) {
	    long lTime = time(0);
	    char * timeStr = ctime(&lTime);
	    write (logFD, "received @ ", 11);
	    write (logFD, timeStr, strlen(timeStr) - 1);
	    write (logFD, ":\n", 2);
	    {
		PLANT_BOMB(ReleaseGuts,guts);
		ARM_BOMB(guts,buffer);
		write (logFD, buffer->gutsOf(), (int)status);
	    }
	    write (logFD, "\n\n", 2);
	}
	if (status != 0) {
	    myTimeoutCount = 0;
	}
	recordBuffer (buffer, status);
	return status;
}



RPTR(UInt8Array) SocketPortal::writeBuffer (){  /*zzz*/
	/* Return a buffer of a size that the underlying transport 
	   layer wants. */
	
	WPTR(UInt8Array) 	returnValue;
    returnValue = UInt8Array::make (512, (void *)falloc(512));
	return returnValue;
}


void SocketPortal::writePacket (UInt8Array * packet, Int32 count){
	/* send a buffer of data */
	/* packet->gutsOf() is only called immediately at time of system
	   calls in order to be compaction safe. */

	int status;
	{
	    PLANT_BOMB(ReleaseGuts,guts);
	    ARM_BOMB(guts,packet);
	    status = send (mySocketFD, packet->gutsOf(), (int)count, SENDFLAGS);
	}
	if (status != count) {
		BLAST_WITH_VAL(SOCKET_SEND_ERROR, errno);
	}
	
	if (logFD != -1) {
	    long lTime = time(0);
	    char * timeStr = ctime(&lTime);
	    write (logFD, "sent @ ", 7);
	    write (logFD, timeStr, strlen(timeStr) - 1);
	    write (logFD, ":\n", 2);
	    {
		PLANT_BOMB(ReleaseGuts,guts);
		ARM_BOMB(guts,packet);
		write (logFD, packet->gutsOf(), (int)count);
	    }
	    write (logFD, "\n\n", 2);
	}
}

/* protected: creation */

void SocketPortal::destruct (){
    int status;
    CloseExecutor::unregisterHolder(this, mySocketFD);
    status = close( mySocketFD );
    if (status < 0) {
	BLAST(BAD_CLOSE);
    }
    this->PacketPortal::destruct();
}

/* creation */

SocketPortal::SocketPortal (int socketFD, TCSJ) {
	mySocketFD = socketFD;
	CloseExecutor::registerHolder(this, mySocketFD);
	myTimeoutCount = 0;
}


/* Don't really have to do anything here.  Just catch the signal
   and return so that recv() returns with EINTR in the status */

#ifdef unix
static
#  ifndef sgi
	void handleAlarm (DOTDOTDOT)
#  else /* sgi */
	int handleAlarm (int,...)
#  endif /* sgi */
{
    cerr << "Socket receive timed out!\n";
// BLAST(SOCKET_RECV_TIMEOUT);  unkosher in signal handler on some riscs
#ifdef sgi
    return 0;
#endif /* sgi */
}
#endif /* unix */



#ifndef SOCKPTLX_SXX
#	include "sockptlx.sxx"
#endif /* SOCKPTLX_SXX */



#endif /* SOCKPTLX_CXX */

