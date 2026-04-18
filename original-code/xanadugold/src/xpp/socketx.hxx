#ifndef SOCKET_HXX
#define SOCKET_HXX

/* "$Id: socketx.hxx,v 2.3 1993/03/26 01:34:47 eric Exp $ */

#include <sys/types.h>
#include <sys/time.h>
#include <sys/socket.h>

/*
C_DECL_BEGIN
extern void bzero (char *, int); // for FD_ZERO

extern int socket (int, int, int);
extern int accept (int, sockaddr *, int *);
extern int bind (int, sockaddr *, int);
extern int connect (int, sockaddr *, int);
extern int select (int, fd_set *, fd_set *, fd_set *, timeval *);
extern int listen (int, int);
extern int recv (int, char *, int, int);
extern int send (int, char *, int, int);

extern int getdtablesize ();
C_DECL_END
*/
#endif /* SOCKET_HXX */
