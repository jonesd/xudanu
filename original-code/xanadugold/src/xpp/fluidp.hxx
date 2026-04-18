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

#ifndef FLUIDP_HXX
#define FLUIDP_HXX

/* $Id: fluidp.hxx,v 2.5 1993/03/16 22:29:50 eric Exp $ */

#include "fluidx.hxx"

class GlobalEmulsion : public Emulsion {
  public:
    /* LEAF */ void * fetchNewRawSpace (size_t size);
    /* LEAF */ void * fetchOldRawSpace ();
  private:
    static Emulsion * TheEmulsion;
    friend Emulsion * globalEmulsion();
};

#endif /* FLUIDP_HXX */
