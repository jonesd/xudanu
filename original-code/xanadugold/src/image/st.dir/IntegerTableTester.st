'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:38 pm'!

Tester subclass: #IntegerTableTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Testing'!

(IntegerTableTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!IntegerTableTester methodsFor: 'testing'!

{void} cleanTable: aTable {ScruTable} 
	| stomp {TableStepper} |
	stomp _ aTable stepper.
	[stomp hasValue]
		whileTrue: 
			[stomp fetch destroy.
			stomp step].
	aTable destroy!

{void} test1On: oo {ostream reference} 
	"IntegerTableTester runTest: #test1On:"

	"test creation"
	| tab1 {MuTable} tab2 {MuTable} tab3 {MuTable} |
	oo << 'Create tables with create, create: and create:with:
'.
	tab1 _ IntegerTable make.
	tab2 _ IntegerTable make.IntegerVar: 4.
	tab3 _ IntegerTable make.IntegerVar: 5 with: 9.	"test printing"
	oo << 'Printing tables:
' << tab1 << '
' << tab2 << '
' << tab3 << '
'.	"testing"
	oo << 'Test empty table: '.
	tab2 isEmpty
			ifTrue: [oo << 'Empty']
			ifFalse: [oo << 'Not Empty'].
	oo << '
'.	"inserting"
	tab1 at: (9 integer)
		introduce: (Sequence string: 'filly').
	tab1 atInt: IntegerVar0
		introduce: (Sequence string: 'mare').
	oo << 'Test introduce: ' << tab1 << ', table count now: ' << tab1 count << '
'.
	tab1 atInt: -11
		introduce: (Sequence string: 'colt').
	oo << 'Test introduce: ' << tab1 << ', table count now: ' << tab1 count << '
'.
	tab1 atInt: 47
		introduce: (Sequence string: 'stallion').
	oo << 'Test introduce: ' << tab1 << ', table count now: ' << tab1 count << '
'.
	MuTable problems.AlreadyInTable handle: [:ex | oo << 'already in table blast caught, table now:
' << tab1 << '
and table count: ' << tab1 count << '
'.
		^VOID]
		do: [tab1 atInt: 1
				introduce: (Sequence string: 'palooka')].
	oo << 'Test introduce: 
'.
	oo << 'Testing introduce and fetch boundary conditions
'.
	5 to: 9 do: [:i {IntegerVar} | tab3 atInt: i introduce: i integer.
		oo << 'fetch of (' << i << ') is ' << (tab3 intFetch: i) << '
'].
	oo << 'table 3 now:
' << tab3 << '
and its count is ' << tab3 count << '
'.
	tab3 atInt: 4
		introduce: 4 integer.
	tab3 atInt: 10
		introduce: 10 integer.
	tab3 atInt: 11
		introduce: 11 integer.
	oo << 'table 3 now:
' << tab3 << '
and its count is ' << tab3 count << '
'.
	self cleanTable: tab1.
	self cleanTable: tab2.
	self cleanTable: tab3!

{void} test2On: aStream {ostream reference} 
	"self runTest: #test2On:"

	"test creation"
	| tab1 {MuTable} |
	aStream << 'Create tables.
'.
	tab1 _ IntegerTable make.
	tab1 atInt: 1
		introduce: (Sequence string: 'filly').
	tab1 atInt: IntegerVar0
		introduce: (Sequence string: 'mare').
	tab1 atInt: -1
		introduce: (Sequence string: 'colt').
	tab1 atInt: 27
		introduce: (Sequence string: 'stallion').
	aStream << 'Starting table is:
' << tab1 << '
'.
	tab1 atInt: 1
		replace: (Sequence string: 'mare').
	aStream << 'after replace:
' << tab1 << ' and table count: ' << tab1 count << '
'.
	aStream << 'Test replace() in unknown territory. 
'.
	(ScruTable problems.NotInTable) handle: [:ex | aStream << 'NotInTable blast caught, table now:
' << tab1 << '
and table count: ' << tab1 count << '
'.
		^VOID]
		do: [tab1 atInt: 2
				replace: (Sequence string: 'palooka')].
	aStream << 'Test replace() with NULL. 
'.
	(MuTable problems.NullInsertion) handle: [:exc | aStream << 'NullInsertion blast caught, table now:
' << tab1 << '
and table count: ' << tab1 count << '
'.
		^VOID]
		do: [tab1 atInt: 1
				replace: NULL.
			aStream << 'Replace(NULL) not caught!!
'].
	self cleanTable: tab1!

{void} test3On: aStream {ostream reference} 
	"self runTest: #test3On:"

	"test creation"
	| tab1 {MuTable} |
	aStream << 'Create tables.
'.
	tab1 _ IntegerTable make.
	tab1 atInt: 1 introduce: (Sequence string: 'filly').
	tab1 atInt: IntegerVar0 introduce: (Sequence string: 'mare').
	tab1 atInt: -1 introduce: (Sequence string: 'colt').
	tab1 atInt: 27 introduce: (Sequence string: 'stallion').
	aStream << 'Starting table is:
' << tab1 << '
'.
	tab1 atInt: 1 store: (Sequence string: 'mare').
	aStream << 'after store:
' << tab1 << ' and table count: ' << tab1 count << '
'.
	aStream << 'Test store() in unknown territory. 
'.
	(ScruTable problems.NotInTable) handle: [:ex | aStream << 'NotInTable blast caught, table now:
' << tab1 << '
and table count: ' << tab1 count << '
'.
		^VOID]
		do: [tab1 atInt: 2 store: (Sequence string: 'palooka')].
	aStream << 'after store:
' << tab1 << ' and table count: ' << tab1 count << '
'.
	aStream << 'Test store() with NULL. 
'.
	(MuTable problems.NullInsertion) handle: [:exc | aStream << 'NullInsertion blast caught, table now:
' << tab1 << '
and table count: ' << tab1 count << '
'.
		^VOID]
		do: [tab1 atInt: 3 store: NULL].
	self cleanTable: tab1!

{void} test4On: aStream {ostream reference} 
	"self runTest: #test4On:"

	"test creation"
	| tab1 {MuTable} |
	aStream << 'Create tables.
'.
	tab1 _ IntegerTable make.
	tab1 atInt: 1
		introduce: (Sequence string: 'filly').
	tab1 atInt: IntegerVar0
		introduce: (Sequence string: 'mare').
	tab1 atInt: -1
		introduce: (Sequence string: 'colt').
	tab1 atInt: 27
		introduce: (Sequence string: 'stallion').
	aStream << 'Starting table is:
' << tab1 << '
with count ' << tab1 count << '
'.	"testing domain"
	aStream << 'Testing domain
' << tab1 domain << '
'.	"test get"
	aStream << 'Test get(1) ' << (tab1 intGet: 1) << '
'.
	aStream << 'Test get() in unknown territory. 
'.
	(ScruTable problems.NotInTable) handle: [:ex | aStream << 'NotInTable blast caught, table now:
' << tab1 << '
and table count: ' << tab1 count << '
'.
		^VOID]
		do: [tab1 intGet:14].
	self cleanTable: tab1!

{void} test5On: aStream {ostream reference} 
	"self runTest: #test5On:"

	"test creation"
	| tab1 {MuTable} |
	aStream << 'Create tables.
'.
	tab1 _ IntegerTable make.
	tab1 atInt: 1
		introduce: (Sequence string: 'filly').
	tab1 atInt: IntegerVar0
		introduce: (Sequence string: 'mare').
	tab1 atInt: -1
		introduce: (Sequence string: 'colt').
	tab1 atInt: 27
		introduce: (Sequence string: 'stallion').
	aStream << 'Starting table is:
' << tab1 << '
with count ' << tab1 count << '
Now, testing remove(1)
'.
	tab1 intRemove: 1.
	aStream << 'Table now:
' << tab1 << '
with count ' << tab1 count << '
'.
	aStream << 'Test remove(1) in unknown territory. 
'.
	ScruTable problems.NotInTable handle: [:ex | aStream << 'NotInTable blast caught, table now:
' << tab1 << '
and table count: ' << tab1 count << '
'.
		^VOID]
		do: [tab1 intRemove: 1].
	aStream << 'Test wipe(0)
'.
	tab1 intWipe: IntegerVar0.
	aStream << 'Table now:
' << tab1 << '
with count ' << tab1 count << '
And wipe(0) again: '.
	tab1 intWipe: IntegerVar0.
	aStream << 'Table now:
' << tab1 << '
with count ' << tab1 count << '
'.
	self cleanTable: tab1!

{void} test6On: aStream {ostream reference} 
	"self runTest: #test6On:"

	"test creation"
	| tab1 {MuTable} tab2 {ScruTable} |
	aStream << 'Create tables.
'.
	tab1 _ IntegerTable make.
	tab1 atInt: 1
		introduce: (Sequence string: 'filly').
	tab1 atInt: IntegerVar0
		introduce: (Sequence string: 'mare').
	tab1 atInt: -1
		introduce: (Sequence string: 'colt').
	tab1 atInt: 27
		introduce: (Sequence string: 'stallion').
	aStream << 'Starting table is:
' << tab1 << '
with count ' << tab1 count << '
Now, testing subTable(0,40)
'.
	tab2 _ (tab1 cast: IntegerTable)
				subTable: (IntegerRegion make: IntegerVar0
										with: 40).
	aStream << 'Table now:
' << tab1 << '
with count ' << tab1 count << '
and the subtable is
' << tab2 << '
and its count is ' << tab2 count << '.
'.
	self cleanTable: tab1!

{void} test7On: aStream {ostream reference} 
	"self runTest: #test7On:"

	"runs {Iterator}"
	"test creation"
	| tab1 {MuTable} dom {XnRegion} |
	aStream << 'Create tables.
'.
	tab1 _ IntegerTable make.
	tab1 atInt: 1 introduce: (Sequence string: 'filly').
	tab1 atInt: IntegerVar0 introduce: (Sequence string: 'mare').
	tab1 atInt: -1 introduce: (Sequence string: 'colt').
	tab1 atInt: 27 introduce: (Sequence string: 'stallion').
	aStream << 'Starting table is:
' << tab1 << '
with count ' << tab1 count << '
Now, testing domain
'.		
	dom _ tab1 domain. 
	aStream << 'And the results (ta ta TUM!!) 
	' << dom << '
'.
	aStream << '
and now, run lengths....
'.
	aStream << 'tab1 runAt.IntegerVar: -20 ->' << (tab1 runAtInt: -20).
	aStream << '
tab1 runAt.IntegerVar: -10 ->' << (tab1 runAtInt: -10).
	aStream << '
tab1 runAt.IntegerVar:  -9 ->' << (tab1 runAtInt: -9).
	-1 to: 4 do: [:i {IntegerVar} | aStream << '
tab1 runAt.IntegerVar:  ' << i << ' ->' << (tab1 runAtInt: i)].
	aStream << '
tab1 runAt.IntegerVar:  26 ->' << (tab1 runAtInt: 26).
	aStream << '
tab1 runAt.IntegerVar:  27 ->' << (tab1 runAtInt: 27).
	aStream << '
tab1 runAt.IntegerVar:  28 ->' << (tab1 runAtInt: 28).
	aStream << '
tab1 runAt.IntegerVar:  30 ->' << (tab1 runAtInt: 30).
	aStream << '
tab1 runAt.IntegerVar:  31 ->' << (tab1 runAtInt: 31).
	aStream << '
tab1 runAt.IntegerVar:  32 ->' << (tab1 runAtInt: 32).
	aStream << '
'.
	self cleanTable: tab1! !

!IntegerTableTester methodsFor: 'running tests'!

{void} allTestsOn: aStream {ostream reference} 
	"IntegerTableTester runTest"

	aStream << 'Running all IntegerTable tests.
Test 1
'.
	self test1On: aStream.
	aStream << '
Test 2
'.
	self test2On: aStream.
	aStream << '
Test 3
'.
	self test3On: aStream.
	aStream << '
Test 4
'.
	self test4On: aStream.
	aStream << '
Test 5
'.
	self test5On: aStream.
	aStream << '
Test 6
'.
	self test6On: aStream.
	aStream << '
Test 7
'.
	self test7On: aStream! !

!IntegerTableTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !