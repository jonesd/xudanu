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

#ifndef LOGGERX_HXX
#define LOGGERX_HXX

#include "xcompatx.hxx"
#include "tofux.hxx"
#include "loggerx.oxx"


typedef BooleanVar LogFn (Logger * self, char * str);

/* Nothing virtual & no constructor!  That way it's all link-time
intialization */

struct Logger ROOTCLASS {
  
  public:

    BooleanVar of (char * str);

    void init (char * OR(NULL) directive);

    static BooleanVar initFn (Logger * self, char * str);
    static BooleanVar nopFn  (Logger * self, char * str);
    static BooleanVar logFn  (Logger * self, char * str);

    ostream * stream ();

    static Logger * OR(NULL) fetch (char * name);
    static Logger * get (char * name);

    void registerYourself (); /* "register" is a keyword */

  private:

    static Logger * OR(NULL) MyFirst;

  public:

    LogFn * myLogFn;

    char * myName;

    ostream * myStream;

    Logger * OR(NULL) myNext;

    char * OR(NULL) myDefault;
};

extern Logger& operator<< (Logger& logger, char * str);
extern Logger& operator<< (Logger& logger, Int32 num);
extern Logger& operator<< (Logger& logger, APTR(Heaper) obj);


ORDER_BOMB(StreamFlush,ostream *);


#define LOG(logger,oo)					\
	if (logger.of("")) {				\
	    ostream& oo = *logger.myStream;		\
	    PLANT_BOMB(StreamFlush,Toilet);		\
	    ARM_BOMB(Toilet,logger.myStream);		\
	    {

#define END_LOG } }


/* 
** class RegisterLogger exists in X++ but not in XTalk because C++
** doesn't allow both Link time and static time initialization of a class
*/

class RegisterLogger ROOTCLASS {

  public:

    RegisterLogger (Logger * logger);
};


#define DEFINE_LOGGER(name,default)		\
Logger name = { 				\
    &Logger::initFn,				\
    STR(name),					\
    &cerr,					\
    NULL,					\
    default					\
};						\
						\
RegisterLogger CAT(Register,name) (&name);


LOGGER(VanillaLog);
LOGGER(ErrorLog);


#ifdef USE_INLINE
#	include "loggerx.ixx"
#endif /* USE_INLINE */


#endif /* LOGGERX_HXX */
