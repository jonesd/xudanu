#ifndef PARRAYT_HXX
#define PARRAYT_HXX
static char parrayt_hxx_id[] = "$Id: parrayt.hxx,v 2.2 1992/08/14 22:09:56 shap Exp $";

#include "tofux.hxx"

/* I don''t want to use the maint.cxx main(), therefore I can''t use
   the libt.os */

#include "parrayt.oxx"

CLASS(PrimArrayTester,Heaper) {
    CONCRETE(PrimArrayTester)
    NO_GC(PrimArrayTester)
 public:
    void allTestsOn (ostream&);
    PrimArrayTester ();

 private:
    void compactTestOn (ostream&);
    void testUnsignedness (ostream&);
    void oldTestsOn (ostream&);
};

#endif /* PARRAYT_HXX */
