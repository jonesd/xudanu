/*
      (C) Copyright 1988, 89 by Xanadu Operating Company, All Rights Reserved.

******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
**************************************************************************** */

#include <stream.h>
#ifdef GNU
#include <fstream.h>
#endif
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "loggerx.hxx"
#include "loggerx.ixx"

Logger * OR(NULL) Logger::MyFirst = 0;


BooleanVar Logger::of (char * str)
{
    return myLogFn (this, str);
}

void Logger::init (char * OR(NULL) directive)
{
    myStream->flush();

    if (directive == NULL || strcmp (directive, "none") == 0) {
	myLogFn = &Logger::nopFn;
	return;
    }

    myLogFn = &Logger::logFn;
    if (strcmp (directive, "cerr") == 0) {
	myStream = &cerr;
    } else if (strcmp (directive, "cout") == 0) {
	myStream = &cout;
	
    } else if (strcmp (directive, "file") == 0) {
	
	/* copy the name of the logger plus enough extra for ".log" */
	Int32 len = strlen(myName);
	char * fname = new char [len + strlen(".log") + 1];
	strcpy (fname, myName);

	/* If the Logger's name ends in "Log", chop it off */
	Int32 suffixPos = len - strlen("Log");
	if (suffixPos > 0 && strcmp (&fname[suffixPos], "Log") == 0) {
	    fname[suffixPos] = '\0';
	}

	/* convert to lower case and append ".log" */
	for (Int32 i = 0; fname[i] != '\0'; i++) {
	    fname[i] = tolower(fname[i]);
	}
	strcat (fname, ".log");

	/* open a file of that name for output and set this logger to it */
	myStream = new ofstream (fname);

	/* delete the file name buffer */	
	delete fname;


    } else{
	cerr << "Logging directive \"" << directive;
	cerr << "\" unrecognized for logger \"" << myName << "\"\n";
	BLAST(UnrecognizedLoggingDirective);
    }
}

BooleanVar Logger::initFn (Logger * self, char * str)
{
    char * OR(NULL) directive = getenv (self->myName);
    if (directive == NULL) {
	directive = self->myDefault;
    }
    self->init (directive);
    return self->of (str);
}

BooleanVar Logger::nopFn (Logger * /*self*/, char * /*str*/)
{
    return FALSE;
}

BooleanVar Logger::logFn (Logger * self, char * str)
{
    (*self->stream()) << str;
    return TRUE;
}

ostream * Logger::stream ()
{
    return myStream;
}

Logger * OR(NULL) Logger::fetch (char * name)
{
    for (Logger * OR(NULL) p = MyFirst;
	 p != NULL;
	 p = p->myNext) {
	if (strcmp (name, p->myName) == 0) {
	    return p;
	}
    }
    return NULL;
}

Logger * Logger::get (char * name)
{
    Logger * OR(NULL) result = Logger::fetch (name);
    if (result == NULL) {
	BLAST(NotFound);
    } else {
	return result;
    }
}

void Logger::registerYourself ()
{
    myNext = MyFirst;
    MyFirst = this;
}



Logger& operator<< (Logger& logger, char * str)
{
    logger.of (str);
    return logger;
}

Logger& operator<< (Logger& logger, Int32 num)
{
    LOG(logger,oo) {
	oo << num;
    } END_LOG;
    return logger;
}

Logger& operator<< (Logger& logger, APTR(Heaper) obj)
{
    LOG(logger,oo) {
#ifdef GNU
	oo <<(char *) obj;
#else
	oo << obj;
#endif
    } END_LOG;
    return logger;

}


RegisterLogger::RegisterLogger (Logger * logger)
{
    logger->registerYourself();
}


DEFINE_LOGGER(VanillaLog,NULL);
DEFINE_LOGGER(ErrorLog,"cerr");
