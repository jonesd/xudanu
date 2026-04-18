/* Copyright Xanadu Operating Company.  All Rights Reserved. */

/******************************************************************************
*                                                                            *
* The information contained herein is confidential, proprietary to Xanadu    *
* Operating Company, and considered a trade secret as defined in section     * 
* 499C of the penal code of the State of California.  Use of this information* 
* by anyone other than authorized employees of Xanadu is granted             *
* only under a  written non-disclosure agreement, expressly prescribing      * 
* the scope and  manner of such use.                                         *
*                                                                            *
***************************************************************************
Output from Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989
*/

#ifndef TABENTT_CXX
#define TABENTT_CXX


#ifndef CHOOSEX_HXX
#include "choosex.hxx"
#endif /* CHOOSEX_HXX */

#ifndef TABENTT_HXX
#include "tabentt.hxx"
#endif /* TABENTT_HXX */

#ifndef TABENTT_IXX
#include "tabentt.ixx"
#endif /* TABENTT_IXX */


#ifndef HSPACEX_HXX
#include "hspacex.hxx"
#endif /* HSPACEX_HXX */

#ifndef INTEGERX_HXX
#include "integerx.hxx"
#endif /* INTEGERX_HXX */

#ifndef SEQUENCX_HXX
#include "sequencx.hxx"
#endif /* SEQUENCX_HXX */




/* ************************************************************************ *
 * 
 *                    Class TableEntryTester 
 *
 * ************************************************************************ */


/* test entries in isolation just for fun */


/* testing */


void TableEntryTester::allTestsOn (ostream& oo){
	/* A regression test is run by calling this method. What the 
	tester writes to 'oo' is 
		actually written to file *o.txt and compared against an 
	approved reference 
		file (*r.txt) of what this tester once used to output. If 
	they match exactly, 
		then the test is passed. Otherwise, someone needs to 
	manually understand why 
		they're different. The diff is in file *d.txt. 
		
		It is strongly recommended (in order to avoid regression 
	errors) that when a 
		tester is extended to test something new that its output 
	also be extended with 
		some result of the new test. The extended test will then 
	fail the first time. The 
		programmer should verify that the reason for failure is 
	exactly that the 
		tester now additionally outputs the correct results of the 
	new test, in which 
		case this output should be made into the new reference 
	output and the test run 
		again. */
	
	this->test1on(oo);
	this->test2on(oo);
	this->test3on(oo);
}


void TableEntryTester::test1on (ostream& oo){
	SPTR(TableEntry) ent1;
	
	oo << "start of test 1 - basic stuff\n";
	ent1 = TableEntry::make (Sequence::string("one"), Sequence::string("two"));
	oo << "\nent1 == " << ent1 << "; key is " << ent1->position() << "; and value is " << ent1->value() << "; next is " << ent1->fetchNext() << "\n";
	oo << "\ntest match of ent1 with " << Sequence::string("one") << ": ";
	if (ent1->match(Sequence::string("one"))) {
		oo << "TRUE";
	} else {
		oo << "FALSE";
	}
	oo << "\ntest match of ent1 with " << Sequence::string("two") << ": ";
	if (ent1->match(Sequence::string("two"))) {
		oo << "TRUE";
	} else {
		oo << "FALSE";
	}
	oo << "\ntest matchValue of ent1 with " << Sequence::string("one") << ": ";
	if (ent1->matchValue(Sequence::string("one"))) {
		oo << "TRUE";
	} else {
		oo << "FALSE";
	}
	oo << "\ntest matchValue of ent1 with " << Sequence::string("two") << ": ";
	if (ent1->matchValue(Sequence::string("two"))) {
		oo << "TRUE";
	} else {
		oo << "FALSE";
	}
	oo << "\nend of test one\n\n";
}


void TableEntryTester::test2on (ostream& oo){
	SPTR(TableEntry) ent1;
	SPTR(TableEntry) ent2;
	SPTR(TableEntry) ent3;
	
	oo << "start of test 2 - linking stuff\n";
	ent1 = TableEntry::make (Sequence::string("one"), Sequence::string("value"));
	oo << "\nent1 == " << ent1 << "; key is " << ent1->position() << "; and value is " << ent1->value() << "; next is " << ent1->fetchNext() << "\n";
	ent2 = TableEntry::make (Sequence::string("two"), Sequence::string("value"));
	oo << "\nent2 == " << ent2 << "; key is " << ent2->position() << "; and value is " << ent2->value() << "; next is " << ent2->fetchNext() << "\n";
	ent3 = TableEntry::make (Sequence::string("three"), Sequence::string("value"));
	oo << "\nent3 == " << ent3 << "; key is " << ent3->position() << "; and value is " << ent3->value() << "; next is " << ent3->fetchNext() << "\n";
	ent1->setNext(ent2);
	ent2->setNext(ent3);
	oo << "ent1 next now: " << ent1->fetchNext();
	oo << "\nent2 next now: " << ent2->fetchNext();
	/* oo << 'step over chain:
		'.
			ent1 stepper forEach: [:ent {TableEntry} |
				oo << 'entry is ' << ent << '
		']. */
	oo << "\nent3 next now: " << ent3->fetchNext() << "\n";
}


void TableEntryTester::test3on (ostream& oo){
	SPTR(TableEntry) ent1;
	SPTR(TableEntry) ent2;
	SPTR(TableEntry) ent3;
	SPTR(TableEntry) ent4;
	
	
	oo << "start of test 2 - different entry types\n";
	ent1 = TableEntry::make (Sequence::string("one"), Sequence::string("value"));
	oo << "\nent1 == " << ent1 << "; key is " << ent1->position() << "; and value is " << ent1->value() << "; next is " << ent1->fetchNext() << "\n";
	ent2 = TableEntry::make (IntegerPos::make (1), Sequence::string("value"));
	oo << "\nent2 == " << ent2 << "; key is " << ent2->position() << "; and value is " << ent2->value() << "; next is " << ent2->fetchNext() << "\n";
	ent2 = TableEntry::make (1, Sequence::string("value"));
	oo << "\nent2 == " << ent2 << "; key is " << ent2->position() << "; and value is " << ent2->value() << "; next is " << ent2->fetchNext() << "\n";
	ent3 = TableEntry::make (HeaperAsPosition::make (Sequence::string("three")), Sequence::string("three"));
	oo << "\nent3 == " << ent3 << "; key is " << ent3->position() << "; and value is " << ent3->value() << "; next is " << ent3->fetchNext() << "\n";
	ent4 = TableEntry::make (IntegerPos::make (Sequence::string("value")->hashForEqual()), Sequence::string("value"));
	oo << "\nent4 == " << ent4 << "; key is " << ent4->position() << "; and value is " << ent4->value() << "; next is " << ent4->fetchNext() << "\n";
	ent4 = TableEntry::make (Sequence::string("value")->hashForEqual(), Sequence::string("value"));
	oo << "\nent4 == " << ent4 << "; key is " << ent4->position() << "; and value is " << ent4->value() << "; next is " << ent4->fetchNext() << "\n";
}

	/* automatic 0-argument constructor */
TableEntryTester::TableEntryTester() {}

#ifndef TABENTT_SXX
#include "tabentt.sxx"
#endif /* TABENTT_SXX */



#endif /* TABENTT_CXX */

