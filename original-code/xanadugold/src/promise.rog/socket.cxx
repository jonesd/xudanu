#include <stdlib.h>
#include <stream.h>
#include <string.h>
#include <fcntl.h>
#ifndef macintosh
#	include <osfcn.h>
#	include <netdb.h>
#	include <sys/types.h>
#	include <time.h>
#	include <netinet/in.h>
#else
#   include "netdbx.hxx"
#   include "socket.h"
#   include "socket.tcp.h"
#   include <netincl/in.h>
#endif /* macintosh */
#include <sys/socket.h>

#define XU_SENDFLAGS (0)

#define RCV_TIMEOUT 666 /* thingToDo!! hack!! knownBug!! */

#include "socket.h"
#include "socket.hxx"

#ifdef unix
static
#  ifndef sgi
	void handleAlarm (DOTDOTDOT);
#  else /* sgi */
	int handleAlarm (int,...);
#  endif /* sgi */
#endif /* unix */

XuSocketPortalSpec::XuSocketPortalSpec ()
     : XuPortalSpec ("socket", xuTCS) {
}

XuPortalP XuSocketPortalSpec::fetchNewPortal (XuStringVar addr) {
	/* copied from SocketPortal::make 6/1/92/ravi */
	
	char hostName[50];
	int port;

	int socketFD;
	
	int status;

	if (strlen(addr) > sizeof(hostName)) {
		return NULL; /* hack!!! to avoid string overflow */
	}
	if (sscanf (addr, "%s %d", &hostName, &port) != 2) {
		return NULL;
	}

	struct	sockaddr_in	sockName;
	sockName.sin_family = AF_INET;
	sockName.sin_port = htons((unsigned short)port);

#ifdef macintosh
	sockName.sin_addr.s_addr = StrToIP( hostName );
	if (sockName.sin_addr.s_addr == 0) {
		return XU_NULL;
	}
#else

	hostent * host = gethostbyname(hostName);
	if (host == NULL) {
		return NULL;
	}
	sockName.sin_addr.s_addr = *(u_long*) host->h_addr;
#endif
	socketFD = socket( AF_INET, SOCK_STREAM, IPPROTO_TCP );
	if (socketFD < 0) {
		return NULL;
	}

	/* connect to destination host port */
	if (status = connect(socketFD,
			     (sockaddr*)&sockName,
			     sizeof(sockName))) {
		cerr << "Socket connect failure\n";
		cerr << "\tstatus = " << status << "\n";
		perror ("\tsystem error");
		cerr << "\n";
		return NULL;
	}
	
	return new XuSocketPortal (socketFD);
}

XuSocketPortalSpec XuSocketPortalSpec::TheOne;


void XuSocketPortal::sendByte (XuIntVar b) {
	/* hack!!! there must be a more efficient way */
	XuByteVar a[1];
	a[0] = (XuByteVar) b;
	this->sendBuffer (a, 1);
}

XuIntVar XuSocketPortal::receiveByte () {
	/* hack!!! there must be a more efficient way */
	XuByteVar a[1];
	this->receiveBuffer (a, 1);
	return a[0];
}

void XuSocketPortal::sendBuffer (XuBufferVar buffer, XuIntVar count) {
	int		status;
	
       	status = send (mySocketFD, (const char *) buffer, ((int)count), XU_SENDFLAGS);
	if (status != count) {
		xuError (XU_SOCKET_SEND_ERROR, errno);
	}
}
void XuSocketPortal::receiveBuffer (XuBufferVar buffer, XuIntVar count) {
	/* receive a buffer of data */
	
	int	status;

#ifdef unix
	struct sigvec myVec, oldVec;

# ifndef sgi
	void handleAlarm (DOTDOTDOT);
# else /* sgi */
	int handleAlarm (int,...);
# endif /* sgi */

	myVec.sv_handler = handleAlarm;
	myVec.sv_mask = 0;
	myVec.sv_flags = SV_INTERRUPT;
	sigvec (SIGALRM, &myVec, &oldVec);
#endif /* unix */

	char * buf   = (char *) buffer;
	int    size  = (int) count;
	int    total = 0;
#ifdef unix
	alarm (RCV_TIMEOUT);
#endif /* unix */
	do {
		status = recv (mySocketFD, buf, size, XU_SENDFLAGS);
		if (status < 0) {
#ifdef unix
			alarm (0);
#endif /* unix */
			if (errno == EINTR) {
				xuError (XU_SOCKET_RECV_TIMEOUT, XU_SOURCE);
			} else {
				xuError(XU_SOCKET_RECV_ERROR, errno);
			}
		} else if (status > 0) {
			buf += status;
			size -= status;
			total += status;
		}
	} while (total < count);
#ifdef unix
	alarm (0);
	sigvec (SIGALRM, &oldVec, NULL);
#endif /* unix */
}

void XuSocketPortal::flush () {
	/* this doesn't do anything; I believe that sockets are flushed automatically */
}

XuSocketPortal::XuSocketPortal (int fd) {
	mySocketFD = fd;
}

XuSocketPortal::~XuSocketPortal () {
	int status;
#ifdef macintosh
	if (fd >= 0) {
		status = s_close( mySocketFD );
	}
#else
	status = close( mySocketFD );
#endif
	if (status < 0) {
		/* Hey guys, is this right?  What's the deal with s_close? */
		xuError (XU_SOCKET_BAD_CLOSE, XU_SOURCE);
	}
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
/* xuError(XU_SOCKET_RECV_TIMEOUT);  unkosher in signal handler on some riscs */
#ifdef sgi
    return 0;
#endif /* sgi */
}
#endif /* unix */
