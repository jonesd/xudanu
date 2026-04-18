#include <stream.h>
#include <string.h>
#include <stdlib.h>

#include "xanadu.hxx"

int main (int argc, const char *argv[]) {
	XuAdminerP adminer;

	if (argc != 3) {
		cerr << "usage: " << argv[0] << " <transport> <address>\n";
		exit (-1);
	}

	XuIntVar error = XuServer::connect (argv[1], argv[2]);
	if (error) {
		cerr << argv[0] << ": connect error " << error << '\n';
		exit (-1);
	}

    XuDelay {	
	cerr << "Logging in.\n";
	XuCurrentKeyMaster.set (XuBooLock::cast (
		XuServer::loginByName("System Admin"))->boo ());

	cerr << "Making Adminer.\n";
	adminer = XuAdminer::make();

    } XuEndDelay

	cerr << "No more connections.\n";
	adminer->acceptConnections(FALSE);

	cerr << "Shutting down.\n";
	adminer->shutDown();

	cerr << "Done.\n";

	return 0;
}

