/*==========================================================================
  |                                                                        |
  |          tombx.cxx - entomb objects to catch dangling references       |
  |                                                                        |
  |          Written by Eric C. Hill                                       |
  |          Copyright (C) 1989, Xanadu Operating Company, Inc.            |
  |                                                                        |
  ==========================================================================*/

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

/* $Id: tombx.cxx,v 2.4 1993/03/23 00:55:27 hibbert Exp $ */

#include <stream.h>
#include "tofux.hxx"
#include "tombx.hxx"
#include "allocp.hxx"

#ifdef TOMBSTONES

typedef void (*Vptp)();
struct vtbl_entry {short delta; short idontknow; Vptp fct; };

#define MAXVTABLESIZE 1000
static vtbl_entry tombCategory_vtable[MAXVTABLESIZE];

struct TombCategory {
  vtbl_entry * vtable_ptr;
};

struct KlugeCategory {
  int (**_Tofu__vptr )();
  char *_KlugeCategory_nameOfCategory ;
  struct KlugeCategory *_KlugeCategory_baseCategory ;
};

static void violateTomb(struct TombCategory*);


void entomb(void * obj)
{
  struct TombCategory * object = (TombCategory*) obj;
  if (!((Heaper*)obj)->isKindOf(cat_Heaper)) {
    BLAST(NOT_EXACTLY_HEAPER_IN_ENTOMB);
  }
#ifdef TOFUMAGIC
  if (object->_Heaper__magicNumber == TOFUMAGIC) {
    if (object->vtable_ptr == tombCategory_vtable) {
      cerr << "in entomb: ";
      violateTomb(object);
    }
    if (object->vtable_ptr) {
      object->vtable_ptr = tombCategory_vtable;
    } else {
      cerr << "FATAL: Heaper thing " << (void*) object
	<< " with NULL vtbl ptr!!\n";
      BLAST(ROTTEN_TOFU);
    }
    ABufHead * head = (ABufHead*) obj - 1;
    head->allocClass.dechain();
    char * p = (char*)obj + 8;
    for (int i = 0; i < (head->numUnits-1)*sizeof(ABufHead) - 8; i++) {
      *p = 0xd;
    }
  } else {
    ABufHead * head = (ABufHead*) obj - 1;
    head->allocClass.dechain();
    char * p = (char*)obj;
    for (int i = 0; i < (head->numUnits-1)*sizeof(ABufHead); i++) {
      *p = 0xd;
    }
  }
#endif /* TOFUMAGIC */
#ifdef CAPTURE_STACK_AT_ALLOC
  HEADER(object)->deleteDepth = recordStack (&HEADER(object)->deleteStack);
#endif /* CAPTURE_STACK_AT_ALLOC */
}

static void violateTomb(struct TombCategory * _this)
{
  cerr << "\n***\nA tomb has been violated! this->" << (void*)_this << "\n";
#ifdef CAPTURE_STACK_AT_ALLOC
  cerr << "!echo allocated at\n";
  for (size_t i = 0; i < HEADER(_this)->heritageDepth; i++) {
    cerr << HEADER(_this)->heritage[i] << "?i\n";
  }
  cerr << "!echo deleted at\n";
  for (i = 0; i < HEADER(_this)->deleteDepth; i++) {
    cerr << HEADER(_this)->deleteStack[i] << "?i\n";
  }
#endif /* CAPTURE_STACK_AT_ALLOC */
  BLAST(TOMB_VIOLATION);
}

void consecrateGraveyard()
{
  int i;
  for (i = 0; i < MAXVTABLESIZE; i++) {
    tombCategory_vtable[i].fct = (void(*)()) violateTomb;
    tombCategory_vtable[i].delta = 0;
    tombCategory_vtable[i].idontknow = 0;
  }
}

#endif /* TOMBSTONES */


/*
		Stack Traceback Routines
*/

#ifdef sparc
#include <machine/frame.h>

extern "C" {
  static struct frame * frameP;
  static void  	      * stackP;
};
#endif /* sparc */

size_t recordStack (int saveArea[], size_t maxTraceback) {
#ifdef sparc
    struct frame * fr;
    int lastReturn = 0;
    size_t i;
    fr = frameP->fr_savfp;	/* get previous frame */
    for (i = 0;
	 fr >= stackP && fr->fr_savpc && i < maxTraceback;) {
	     if (fr->fr_savpc != lastReturn) {
		 saveArea[i++] = lastReturn = fr->fr_savpc;
	     }
	     fr = fr->fr_savfp;
	 }
    return i;
#else
    return 0;
#endif /* sparc */
}

size_t recordStack (void *** saveAreaP) {
  static int depth = 0;
  if (depth++) {
    BLAST(SHOULD_NOT_RECUR);
  }
  int callers[1000];
  size_t count = recordStack(callers, (size_t) 1000);
  *saveAreaP = (void**) (falloc (count * sizeof(void*)) + 1);
  /* has to go below pAlloc */
  for (size_t i = 1; i < count; i++) {
    (*saveAreaP)[i-1] = (void*) callers[i];
  }
  depth--;
  return count-1;
}

void recordStack (ostream& oo) {
  int callers[1000];
  size_t count = recordStack(callers, (size_t) 1000);
  for (int i = 1; i < count; i++) {
    oo << callers[i] << "?i\n";
  }
  oo << "!\n";
}
