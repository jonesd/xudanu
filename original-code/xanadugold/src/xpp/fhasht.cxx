static char fhasht_cxx_id[] = "$Id: fhasht.cxx,v 2.5 1993/01/05 17:29:38 ravi Exp $";

#include "fhashx.hxx"
#include <stream.h>
//
//	Added test for fastHash(char *, int, int)
//		- michael Sep 18 1991

#define STRING_TEST(str)			\
	cerr << "'" << str			\
	     << "'->" << fastHash(str)		\
	     << "\n"

#define STRING_TEST_2(str,start,count)		\
	cerr << "'"   << str			\
	     << "', " << start			\
	     << ", "  << count			\
	     << " ->" << fastHash(&(((UInt8 *)str)[start]),count)	\
	     << "\n"


int XU_MAIN (int, char**) {
  cerr << "The original data for this test was produced by Smalltalk\n";
  cerr <<
    "This test verifies that the X++ version produces compatible hashes\n";
  
  for (UInt32 i = 0; i < 20000; i += 431) {
    cerr << i << "->" << fastHash(i) << "\n";
  }

  cerr << "\n";

  STRING_TEST("foo");
  STRING_TEST("oof");
  STRING_TEST("bar");
  STRING_TEST("car");
  STRING_TEST("cars");
  STRING_TEST("this is a long string to hash");
  STRING_TEST("this is a longer string to hash");

//
// New tests for the counted, null-processing version.
//
// First check that it matches
//

  cerr << "\n";

  STRING_TEST_2("foo",0,3);
  STRING_TEST_2("oof",0,3);
  STRING_TEST_2("bar",0,3);
  STRING_TEST_2("car",0,3);
  STRING_TEST_2("cars",0,4);
  STRING_TEST_2("this is a long string to hash",0,29);
  STRING_TEST_2("this is a longer string to hash",0,31);

  cerr << "\n";
  STRING_TEST_2("abc_this is a longer string to hash_xyz",4,31);

  cerr << "\n";
  STRING_TEST_2("abc/this is a longer string to hash_xyz",4,31);
  STRING_TEST_2("abc_this is a longer string to hash/xyz",4,31);
  STRING_TEST_2("abc_/his is a longer string to hash_xyz",4,31);
  STRING_TEST_2("abc_this is a longer string to has/_xyz",4,31);
  STRING_TEST_2("abc_this is a longer*string to hash_xyz",4,31);

  cerr << "\nThe next three replace the star with a null and repeat the\n";
  cerr << "hash_xyz, hash/xyz, and has/_xyz tests.  The printing of the\n";
  cerr << "string will stop at the null.\n\n";

  STRING_TEST_2("abc_this is a longer\0string to hash_xyz",4,31);
  STRING_TEST_2("abc_this is a longer\0string to hash/xyz",4,31);
  STRING_TEST_2("abc_this is a longer\0string to has/_xyz",4,31);

  return 0;
}
