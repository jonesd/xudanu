
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
//
//	Changed "delete <ptr>;" to "<ptr>.destroyIt();" in two places
//		- michael Oct  7 1991
//
//	Changed to destroyIt to destroy since SPTRS are no longer a type
//		- ech Jan 18 1993

static char alloct_cxx_id[] = "$Id: alloct.cxx,v 2.8 1993/03/24 02:48:03 eric Exp $";

#include "allocp.hxx"
#include "alloct.hxx"
#include "initx.hxx"
#include <stream.h>

#include "alloct.sxx"

void Foo::sendTest (ostream& o, int i) {
    o << i;
}

long printPtr(void *ptr) {
  return (int) ptr;
}

void printPtrAndSize(ostream& oo, void * ptr, size_t size) {
  oo << size << " bytes @ 0x" << hex << printPtr(ptr) << dec << " ";
}

int main (int ac, char *av[]) {
  Initializer mainInit(ac,av);

  cerr << "sizeof(ABufHead) == " << sizeof(ABufHead) << "\n";
  SPTR(Foo) foo;
  CONSTRUCT(foo,Foo,());
  cerr << "foo is ";
  printPtrAndSize(cerr, foo, sizeof(Foo));
  cerr << "\nthree:";
  foo->sendTest (cerr, 3);
  cerr << "\n";
  cerr << foo << "\n";
  cerr << cat_Foo << "\n";
  foo->destroy();
  CONSTRUCT(foo,Foo,());
  cerr << "foo is ";
  printPtrAndSize(cerr, foo, sizeof(Foo));
  cerr << "\nthree:";
  foo->sendTest (cerr, 3);
  cerr << "\n";
  cerr << foo << "\n";
  cerr << cat_Foo << "\n";
  foo->destroy();
  void * zzz[10];
  cerr << "allocating\n";
  for (int i = 0; i < 10; i++) {
    zzz[i] = new Heaper*[5 + 5*(i&3)];
    cerr << " size = " << 5 + 5*(i&3) << "  " << hex << printPtr(zzz[i]) << dec << "\n";
  }
  cerr << "deleting\n";
  for (i = 0; i < 10; i++) {
    delete zzz[i];
  }
  cerr << "allocating again\n";
  for (i = 0; i < 10; i++) {
    zzz[i] = new Heaper*[5+5*(i&3)];
    cerr << " size = " << 5 + 5*(i&3) << "  " << hex << printPtr(zzz[i]) << dec << "\n";
  }
  return 0;
}
