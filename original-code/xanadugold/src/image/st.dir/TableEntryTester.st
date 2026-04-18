'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:11 pm'!

Tester subclass: #TableEntryTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tabent'!
TableEntryTester comment:
'test entries in isolation just for fun'!

(TableEntryTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!TableEntryTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference} 
	"A regression test is run by calling this method. What the tester writes to 'oo' is 
	actually written to file *o.txt and compared against an approved reference 
	file (*r.txt) of what this tester once used to output. If they match exactly, 
	then the test is passed. Otherwise, someone needs to manually understand why 
	they're different. The diff is in file *d.txt. 
	
	It is strongly recommended (in order to avoid regression errors) that when a 
	tester is extended to test something new that its output also be extended with 
	some result of the new test. The extended test will then fail the first time. The 
	programmer should verify that the reason for failure is exactly that the 
	tester now additionally outputs the correct results of the new test, in which 
	case this output should be made into the new reference output and the test run 
	again."

	self test1on: oo.
	self test2on: oo.
	self test3on: oo.!

{void} test1on: oo {ostream reference}

	| ent1 {TableEntry} |
	oo << 'start of test 1 - basic stuff
'.
	ent1 _ TableEntry make: (Sequence string: 'one') with: (Sequence string: 'two').
	oo << '
ent1 == ' << ent1 << '; key is ' << ent1 position << '; and value is ' << ent1 value <<
	'; next is ' << ent1 fetchNext << '
'.
	oo << '
test match of ent1 with ' << (Sequence string: 'one') << ': '.
	(ent1 match: (Sequence string: 'one'))
		ifTrue: [oo << 'TRUE']
		ifFalse: [oo << 'FALSE'].
	oo << '
test match of ent1 with ' << (Sequence string: 'two') << ': '.
	(ent1 match: (Sequence string: 'two'))
		ifTrue: [oo << 'TRUE']
		ifFalse: [oo << 'FALSE'].
	oo << '
test matchValue of ent1 with ' << (Sequence string: 'one') << ': '.
	(ent1 matchValue: (Sequence string: 'one'))
		ifTrue: [oo << 'TRUE']
		ifFalse: [oo << 'FALSE'].
	oo << '
test matchValue of ent1 with ' << (Sequence string: 'two') << ': '.
	(ent1 matchValue: (Sequence string: 'two'))
		ifTrue: [oo << 'TRUE']
		ifFalse: [oo << 'FALSE'].
	oo << '
end of test one

'!

{void} test2on: oo {ostream reference}

	| ent1 {TableEntry} ent2 {TableEntry} ent3 {TableEntry} |
	oo << 'start of test 2 - linking stuff
'.
	ent1 _ TableEntry make: (Sequence string: 'one') with: (Sequence string: 'value').
	oo << '
ent1 == ' << ent1 << '; key is ' << ent1 position << '; and value is ' << ent1 value <<
	'; next is ' << ent1 fetchNext << '
'.
	ent2 _ TableEntry make: (Sequence string: 'two') with: (Sequence string: 'value').
	oo << '
ent2 == ' << ent2 << '; key is ' << ent2 position << '; and value is ' << ent2 value <<
	'; next is ' << ent2 fetchNext << '
'.
	ent3 _ TableEntry make: (Sequence string: 'three') with: (Sequence string: 'value').
	oo << '
ent3 == ' << ent3 << '; key is ' << ent3 position << '; and value is ' << ent3 value <<
	'; next is ' << ent3 fetchNext << '
'.
	ent1 setNext: ent2.
	ent2 setNext: ent3.
	oo << 'ent1 next now: ' << ent1 fetchNext.
	oo << '
ent2 next now: ' << ent2 fetchNext.
	oo << '
ent3 next now: ' << ent3 fetchNext << '
'.
	"oo << 'step over chain:
'.
	ent1 stepper forEach: [:ent {TableEntry} |
		oo << 'entry is ' << ent << '
']."!

{void} test3on: oo {ostream reference}

	| ent1 {TableEntry} ent2 {TableEntry} ent3 {TableEntry} ent4 {TableEntry} |
	[IntegerPos] USES.
	oo << 'start of test 2 - different entry types
'.
	ent1 _ TableEntry make: (Sequence string: 'one') with: (Sequence string: 'value').
	oo << '
ent1 == ' << ent1 << '; key is ' << ent1 position << '; and value is ' << ent1 value <<
	'; next is ' << ent1 fetchNext << '
'.
	ent2 _ TableEntry make: (1 integer) with: (Sequence string: 'value').
	oo << '
ent2 == ' << ent2 << '; key is ' << ent2 position << '; and value is ' << ent2 value <<
	'; next is ' << ent2 fetchNext << '
'.
	ent2 _ TableEntry make.IntegerVar: 1 with: (Sequence string: 'value').
	oo << '
ent2 == ' << ent2 << '; key is ' << ent2 position << '; and value is ' << ent2 value <<
	'; next is ' << ent2 fetchNext << '
'.
	ent3 _ TableEntry make: (HeaperAsPosition make: (Sequence string: 'three')) with: (Sequence string: 'three').
	oo << '
ent3 == ' << ent3 << '; key is ' << ent3 position << '; and value is ' << ent3 value <<
	'; next is ' << ent3 fetchNext << '
'.
	ent4 _ TableEntry make: (Sequence string: 'value') hashForEqual integer with: (Sequence string: 'value').
	oo << '
ent4 == ' << ent4 << '; key is ' << ent4 position << '; and value is ' << ent4 value <<
	'; next is ' << ent4 fetchNext << '
'.
	ent4 _ TableEntry make.IntegerVar: (Sequence string: 'value') hashForEqual with: (Sequence string: 'value').
	oo << '
ent4 == ' << ent4 << '; key is ' << ent4 position << '; and value is ' << ent4 value <<
	'; next is ' << ent4 fetchNext << '
'.! !

!TableEntryTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !