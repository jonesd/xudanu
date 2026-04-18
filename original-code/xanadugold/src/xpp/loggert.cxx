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
#include "loggerx.hxx"

class Early ROOTCLASS {
  public:
    Early ();
};

Early::Early ()
{
    VanillaLog << "zip " << 4 << " zotch\n";
}

Early TheEarly;

XU_MAIN (int, char *[])
{
    VanillaLog << "foo " << 3 << " bar\n";
    if (!VanillaLog.of ("logged\n")) {
	cerr << "not logged\n";
    }
    return 0;
}
