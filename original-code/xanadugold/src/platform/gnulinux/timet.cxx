/*
		Copyright 1990, Xanadu Operating Company, all rights reserved */
		

#include <stream.h>
#include "timex.hxx"

int
main (int, char * av[]) {

	TimeVar	t0;
	TimeVar	t1 = TimeVar ();
	TimeVar	t2 = time ();
	TimeVar	t3;
	TimeVar	t4;
	UInt32	i = 0;

	cout << "start of time test\n";
	cout << "t0 == ";
	t0.printOn (cout);
	cout << "\n";
	
	cout << "t1 == " << t1 << ", t2 == " << t2 << ", t3 == " << t3 << "\n";
	
	/* delay a bit */
	for (i=0; i<100000; i++) {};
	
	t3 = time ();
	
	cout << "t3 == " << t3 << "\n";
	cout << "t3.difference (t1) == " << t3.difference (t1) << "\n";
	
	t4 = time (t3);
	cout << "t4 == " << t4 << "; t4.asLong () == " << t4.asLong () << "\n";
	
	cout << "t0.isEqual (t1) == ";
	if (t0.isEqual (t1)) {cout << "true";} else {cout << "false";};
	cout << "\n";
	
	cout << "t3.isEqual (t2) == ";
	if (t3.isEqual (t2)) {cout << "true";} else {cout << "false";};
	cout << "\n";
	
	cout << "t0.isGreaterOrEqual (t1) == ";
	if (t0.isGreaterOrEqual (t1)) {cout << "true";} else {cout << "false";};
	cout << "\n";
	
	cout << "t3.isGreaterOrEqual (t2) == ";
	if (t3.isGreaterOrEqual (t2)) {cout << "true";} else {cout << "false";};
	cout << "\n";
	
	cout << "t2.isGreaterOrEqual (t3) == ";
	if (t2.isGreaterOrEqual (t3)) {cout << "true";} else {cout << "false";};
	cout << "\n";
	
	cout << "end of time test\n\n";
	return 0;
}
