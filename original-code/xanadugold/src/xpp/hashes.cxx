
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "fhashx.hxx"

#define BUF_SIZE 10000

main (int, char *[])
{
    char buffer [BUF_SIZE];
    
    for (UInt32 lineNo = 1; fgets (buffer, BUF_SIZE, stdin) != NULL; lineNo++) {
	UInt32 len = strlen(buffer);
	if (buffer [len - 1] != '\n') {
	    fprintf (stderr, "line number %d is too long\n", lineNo);
	    exit(-1);
	}
	buffer [len - 1] = '\0';
	printf ("0x%.6x %s\n", 0xFFFFFF & fastHash (buffer), buffer);
    }
    return 0;
}
