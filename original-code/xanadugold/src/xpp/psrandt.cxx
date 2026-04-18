/* Copyright Xanadu Operating Company.  All Rights Reserved.
	3 April 1990 at 1:39:32 pm
*/
static char psrandt_cxx_id[] = "$Id: psrandt.cxx,v 2.3 1993/01/05 17:29:51 ravi Exp $";

#include "psrandt.hxx"

#include "psrandt.sxx"


/* ************************************************************************ *
 * 
 *                    FibonacciRandomTester 
 *
 * ************************************************************************ */

/* main */
int  XU_MAIN (int /* ac */, char* * /* av */){
	test1On(cerr);
	return 0;
}

/* tests */
void  test1On (ostream& oo){
	/* FibonacciRandomTester runTest: #test1On: */
	
	srandom(1023, 11, 5);
	for (long i = 0; i <= 15; i += 1) {
		oo << random() << " ";
	}
	oo << "\n";
}

