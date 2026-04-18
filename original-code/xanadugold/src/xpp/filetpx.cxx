/* Copyright Xanadu Operating Company.  All Rights Reserved.
	12 August 1991 at 10:59:55 pm
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
Output from Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989
*/

/* $Id: filetpx.cxx,v 2.11 1993/04/10 00:53:39 eric Exp $ */

#include "filetpx.hxx"
#include "filetpp.hxx"

#include "initx.hxx"
#include "parrayx.hxx"

#include <stdlib.h>


/* ************************************************************************ *
 * 
 *                    Class XnWriteFile 
 *
 * ************************************************************************ */

RPTR(XnWriteStream) XnWriteFile::make (char * filename) {
    FILE * fd = fopen (filename, "w");
    if (fd == NULL) {
	BLAST(OPEN_FAILED);
    }
    RETURN_CONSTRUCT(XnWriteFile,(fd, tcsj));
}

/* accessing */

void XnWriteFile::flush () {
    if (fflush (myFD) != 0) {
	BLAST(FLUSH_FAILED);
    }
}

void XnWriteFile::putByte (UInt32 byte) {
    if (fputc ((char)byte, myFD) == EOF) {
	BLAST(PUT_FAILED);
    }
}

void XnWriteFile::putData (APTR(UInt8Array) array) {
    for (Int32 i = 0; i < array->count(); i++) {
	if (fputc ((char)array->uIntAt(i), myFD) == EOF) {
	    BLAST(PUT_FAILED);
	}
    }
}

void XnWriteFile::putStr (char * string) {
    if (fputs (string, myFD) == EOF) {
	BLAST(PUT_FAILED);
    }
}


/* creation */
XnWriteFile::XnWriteFile(FILE * fd, TCSJ) {
    FCloseExecutor::registerHolder(this, fd);
    myFD = fd;
}

void XnWriteFile::destruct () {
    FCloseExecutor::unregisterHolder(this, myFD);
    if (fclose (myFD) != 0) {
	BLAST(CLOSE_FAILED);
    }
}


/* ************************************************************************ *
 * 
 *                    Class XnReadFile 
 *
 * ************************************************************************ */



/* creation */

RPTR(XnReadStream)  XnReadFile::make (char * filename){
    FILE * fd = fopen (filename, "r");
    if (fd == NULL) {
	BLAST(OPEN_FAILED);
    }
    RETURN_CONSTRUCT(XnReadFile,(fd, tcsj));
}


/* accessing */

UInt8 XnReadFile::getByte (){
    int ch;
    ch = getc (myFD);
    if (ch == EOF) {
	BLAST(END_OF_FILE);
    }
    return (UInt8) ch;
}

void XnReadFile::putBack (UInt8 c){
    if (ungetc (c, myFD) == EOF) {
	BLAST(PUTBACK_FAILED);
    }
}


void XnReadFile::refill () {}

/* creation */

XnReadFile::XnReadFile (FILE * fd, TCSJ) {
    FCloseExecutor::registerHolder(this, fd);
    myFD = fd;
}


void XnReadFile::destruct (){
    FCloseExecutor::unregisterHolder(this, myFD);
    if (fclose (myFD) != 0) {
	BLAST(CLOSE_FAILED);
    }
    this->XnReadStream::destruct();
}


/* ************************************************************************ *
 * 
 *                    Class FCloseExecutor 
 *
 * ************************************************************************ */



/* Initializers for FCloseExecutor */

FILE ** FCloseExecutor::FDArray = NULL;
GPTR(WeakPtrArray) FCloseExecutor::FileDescriptorHolders = NULL;


/* accessing */


void FCloseExecutor::registerHolder (APTR(Heaper) holder, FILE * fd){
	Int32 slot;
	
	if (FCloseExecutor::FDArray == NULL) {
		SPTR(XnExecutor) exec;
		
		FCloseExecutor::FDArray = new FILE* [32];
		memset (FCloseExecutor::FDArray, 0, 32 * sizeof(FILE*));

		CONSTRUCT(exec,FCloseExecutor,());
		FCloseExecutor::FileDescriptorHolders = WeakPtrArray::make (exec, 32);
	}
	slot = FCloseExecutor::FileDescriptorHolders->indexOf(NULL);
	if (slot == -1) {
		slot = FCloseExecutor::FileDescriptorHolders->count();
		FILE ** newArray = new FILE* [slot + 16];
		memset(&newArray[slot], 0, 16 * sizeof(FILE*));
		MEMMOVE(newArray, FCloseExecutor::FDArray, (int)slot);
		delete FCloseExecutor::FDArray;
		FCloseExecutor::FDArray = newArray;
		FCloseExecutor::FileDescriptorHolders = CAST(WeakPtrArray,FCloseExecutor::FileDescriptorHolders->copyGrow(16));
	}
	FCloseExecutor::FDArray[slot] = fd;
	FCloseExecutor::FileDescriptorHolders->store(slot, holder);
}


void FCloseExecutor::unregisterHolder (APTR(Heaper) holder, FILE * fd){
	Int32 slot;
	
	slot = FCloseExecutor::FileDescriptorHolders->indexOf(holder);
	for (;;) {	BooleanVar crutch_Flag;
		/* slot != -1 && slot < FCloseExecutor::FileDescriptorHolders->count() && FCloseExecutor::FDArray[slot] != fd */
		
		crutch_Flag = slot != -1;
		if(crutch_Flag) {
			crutch_Flag = slot < FCloseExecutor::FileDescriptorHolders->count();
			if(crutch_Flag) {
				crutch_Flag = FCloseExecutor::FDArray[slot] != fd;
			}
		}
		if (crutch_Flag) {
			slot = FCloseExecutor::FileDescriptorHolders->indexOf(holder, slot + 1);
		} else {
			break;
		}
	}
	{	BooleanVar crutch_Flag;
		/* slot == -1 || FCloseExecutor::FDArray[slot] != fd */
		
		crutch_Flag = slot == -1;
		if(!crutch_Flag) {
			crutch_Flag = FCloseExecutor::FDArray[slot] != fd;
		}
		if (crutch_Flag) {
			BLAST(SanityViolation);
		}
	}
	FCloseExecutor::FileDescriptorHolders->store(slot, NULL);
	FCloseExecutor::FDArray[slot] = NULL;
}
/* This executor manages objects that need to close file descriptors 
on finalization. */


/* protected: create */


FCloseExecutor::FCloseExecutor () {
	
}
/* invoking */


void FCloseExecutor::execute (Int32 estateIndex){
	FILE * fd;
	
	fd = FCloseExecutor::FDArray[estateIndex];
	if (fd != NULL) {
		
		fclose(fd);
		
		FCloseExecutor::FDArray[estateIndex] = NULL;
	}
}

#ifndef FILETPX_SXX
#include "filetpx.sxx"
#endif /* FILETPX_SXX */
#ifndef FILETPP_SXX
#include "filetpp.sxx"
#endif /* FILETPP_SXX */
