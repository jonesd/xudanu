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

static char rscid[] = "$Id: queuesx.cxx,v 2.3 1992/08/14 22:10:43 shap Exp $";

#include "queuesx.hxx"

#include "queuesx.ixx"

Int32 Queue::count () {
  Int32 l = 0;
  Queue * qp = this->nextP;
  while (qp != this) {
    l++;
    qp = qp->nextP;
  }
  return l;
}
