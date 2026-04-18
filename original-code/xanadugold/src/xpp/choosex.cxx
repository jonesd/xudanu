/*=========================================================================
  |
  |   Copyright (c) 1989 by Xanadu Operating Company, All Rights Reserved.
  |
  =========================================================================
  |
  | The information contained herein is confidential, proprietary to Xanadu
  | Operating Company, and considered a trade secret as defined in section
  | 499C of the penal code of the State of California.
  |
  | Use of this information by anyone other than authorized employees of
  | Xanadu is granted only under a written nondisclosure agreement,
  | expressly prescribing the scope and manner of such use.
  |
  | The above copyright notice is not to be construed as evidence of
  | publication or the intent to publish.
  |
  ========================================================================= */

/* $Id: choosex.cxx,v 2.3 1992/09/13 05:45:56 eric Exp $ */

#include "choosex.hxx"

void unkindBlast (CONST char * argFileName, int argLineNumber) {

    Problem problem("VALUE_IS_UNKIND", 1,
#ifdef BOMB_REPORT_LINE
		     argFileName, argLineNumber
#endif /* BOMB_REPORT_LINE */
		    );

    blast(&problem);
}
