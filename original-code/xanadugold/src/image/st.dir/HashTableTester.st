'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:36 pm'!

Tester subclass: #HashTableTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Testing'!

(HashTableTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!HashTableTester methodsFor: 'tests'!

{void} test1On: oo {ostream reference} 
	"self runTest: #test1On:"
	"test creation"

	| tab1 {MuTable} tab2 {MuTable} |
	oo << 'Create tables with create, create: and create:with:

'.
	tab1 _ HashTable make.CoordinateSpace: IntegerSpace make.
	tab2 _ HashTable make.CoordinateSpace: IntegerSpace make with: 4.	"test printing"
	oo << 'Printing tables:

' << tab1 << '

' << tab2 << '

'.	"testing empty"
	oo << 'Test empty table: '.
	tab1 isEmpty
			ifTrue: [oo << 'Empty']
			ifFalse: [oo << 'Not Empty'].
	oo << '

'.	"inserting"
	tab1 atInt: 1 introduce: (Sequence string: 'filly').
	tab1 atInt: IntegerVar0 introduce: (Sequence string: 'mare').
	oo << 'Test introduce: ' << tab1 << ', table count now: ' << tab1 count << '

'.
	tab1 at: (Sequence string: 'mare') introduce: (Sequence string: 'colt').
	oo << 'Test introduce: ' << tab1 << ', table count now: ' << tab1 count << '

'.
	tab1 atInt: 27 introduce: (Sequence string: 'stallion').
	oo << 'Test introduce: ' << tab1 << ', table count now: ' << tab1 count << '

'.
	MuTable problems.AlreadyInTable handle: [:ex | oo << 'already in table blast caught, table now:

' << tab1 << '

and table count: ' << tab1 count << '

'.
		^VOID]
		do: [tab1 atInt: 1 introduce: (Sequence string: 'palooka')].
	oo << 'Test empty table: '.
	tab1 isEmpty
			ifTrue: [oo << 'Empty']
			ifFalse: [oo << 'Not Empty'].
	oo << '

'!

{void} test2On: aStream {ostream reference} 
	"self runTest: #test2On:"

	"test creation"
	| tab1 {MuTable} |
	aStream << 'Create tables.

'.
	tab1 _ HashTable make.CoordinateSpace: IntegerSpace make.
	tab1 atInt: 1 introduce: (Sequence string: 'filly').
	tab1 atInt: IntegerVar0 introduce: (Sequence string: 'mare').
	tab1 atInt: -1 introduce: (Sequence string: 'colt').
	tab1 atInt: 27 introduce: (Sequence string: 'stallion').
	aStream << 'Starting table is:

' << tab1 << '

'.
	tab1 atInt: 1 replace: (Sequence string: 'mare').
	aStream << 'after replace:
' << tab1 << ' and table count: ' << tab1 count << '
'.
	aStream << 'Test replace() in unknown territory. 
'.
	ScruTable problems.NotInTable handle: [:ex | aStream << 'NotInTable blast caught, table now:
' << tab1 << '
and table count: ' << tab1 count << '
'.
		^VOID]
		do: [tab1 atInt: 2 replace: (Sequence string: 'palooka')].
	aStream << 'Test replace() with NULL. 
'.
	MuTable problems.NullInsertion handle: [:x | aStream << 'NullInsertion blast caught, table now:
' << tab1 << '
and table count: ' << tab1 count << '
'.
		^VOID]
		do: [tab1 atInt: 1 replace: NULL.
			aStream << 'Replace(NULL) not caught!!
']!

{void} test3On: aStream {ostream reference} 
	"self runTest: #test3On:"

	"test creation"
	| tab1 {MuTable} |
	aStream << 'Create tables.

'.
	tab1 _ HashTable make.CoordinateSpace: IntegerSpace make.
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
	ScruTable problems.NotInTable handle: [:ex | aStream << 'NotInTable blast caught, table now:
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
	MuTable problems.NullInsertion handle: [:exc | aStream << 'NullInsertion blast caught, table now:
' << tab1 << '
and table count: ' << tab1 count << '
'.
		^VOID]
		do: [tab1 atInt: 3 store: NULL]!

{void} test4On: aStream {ostream reference} 
	"self runTest: #test4On:"

	"test creation"
	| tab1 {MuTable} |
	aStream << 'Create tables.

'.
	tab1 _ HashTable make.CoordinateSpace: IntegerSpace make.
	tab1 at: 1 integer introduce: (Sequence string: 'filly').
	tab1 at: Integer0 introduce: (Sequence string: 'mare').
	tab1 at: -1 integer introduce: (Sequence string: 'colt').
	tab1 at: 27 integer introduce: (Sequence string: 'stallion').
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
	ScruTable problems.NotInTable handle: [:ex | aStream << 'NotInTable blast caught, table now:
' << tab1 << '
and table count: ' << tab1 count << '
'.
		^VOID]
		do: [tab1 intGet: 14]!

{void} test5On: aStream {ostream reference} 
	"self runTest: #test5On:"

	"test creation"
	| tab1 {MuTable} |
	aStream << 'Create tables.

'.
	tab1 _ HashTable make.CoordinateSpace: IntegerSpace make.
	tab1 atInt: 1 introduce: (Sequence string: 'filly').
	tab1 atInt: IntegerVar0 introduce: (Sequence string: 'mare').
	tab1 atInt: -1 introduce: (Sequence string: 'colt').
	tab1 atInt: 27 introduce: (Sequence string: 'stallion').
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
	tab1 wipe: Integer0.
	aStream << 'Table now:
' << tab1 << '
with count ' << tab1 count << '
And wipe(0) again: '.
	tab1 wipe: Integer0.
	aStream << 'Table now:
' << tab1 << '
with count ' << tab1 count << '
'!

{void} test6On: aStream {ostream reference} 
	"self runTest: #test6On:"

	"test creation"
	| tab1 {MuTable} |
	aStream << 'Create tables.

'.
	tab1 _ HashTable make.CoordinateSpace: IntegerSpace make.
	tab1 atInt: 1 introduce: (Sequence string: 'filly').
	tab1 atInt: IntegerVar0 introduce: (Sequence string: 'mare').
	tab1 atInt: -1 introduce: (Sequence string: 'colt').
	tab1 atInt: 27 introduce: (Sequence string: 'stallion').	"	tab2 _ tab1 subTable: 0 integer with: 40. 
	
	aStream << 'Table now: 
	' << tab1 << ' 
	with count ' << tab1 count << ' 
	and the subtable is 
	' << tab2 << ' 
	and its count is ' << tab2 count << '. 
	'."
	aStream << 'Starting table is:
' << tab1 << '
with count ' << tab1 count << '
Now, testing subTable(0,40)
'!

{void} test7On: aStream {ostream reference} 
	"self runTest: #test7On:"

	"runs {Iterator}"
	"test creation"
	| tab1 {MuTable} domain {XnRegion} |
	aStream << 'Create tables.

'.
	tab1 _ HashTable make.CoordinateSpace: IntegerSpace make.
	tab1 atInt: 1 introduce: (UInt8Array string: 'filly').
	tab1 atInt: IntegerVar0 introduce: (UInt8Array string: 'mare').
	tab1 atInt: -1 introduce: (UInt8Array string: 'colt').
	tab1 atInt: 27 introduce: (UInt8Array string: 'stallion').
	aStream << 'Starting table is:
' << tab1 << '
with count ' << tab1 count << '
Now, testing domain
'.	
	domain _ tab1 domain. 
	
	aStream << 'And the results (ta ta TUM!!) 
	' << domain << '
'.!

{void} testStepperCopyOn: aStream {ostream reference} 
	"self runTest: #testStepperCopyOn:"

	| tab1 {MuTable} tab2 {MuTable} stp {TableStepper} |
	aStream << 'Test copy by stepper.
'.
	tab1 _ HashTable make.CoordinateSpace: IntegerSpace make.
	tab1 atInt: 1 introduce: (UInt8Array string: 'filly').
	tab1 atInt: IntegerVar0 introduce: (UInt8Array string: 'mare').
	tab1 atInt: -1 introduce: (UInt8Array string: 'colt').
	tab1 atInt: 27 introduce: (UInt8Array string: 'stallion').
	aStream << 'Starting table is:
' << tab1 << '
with count ' << tab1 count << '.
Now testing store during forEach loop
'.	
	(stp _ tab1 stepper) forEach: [ :e {Heaper} |
		aStream << 'at index ' << stp position << ' storing ' << stp position << ' on top of ' << e << '
'.
		tab1 at: stp position store: stp position].
	aStream << 'Ending table is:
' << tab1 << '
with count ' << tab1 count << '.
'.
	tab2 _ tab1 copy cast: MuTable.
	(stp _ tab2 stepper) forEach: [ :x {Heaper} |
		aStream << 'at index ' << stp position << ' storing ''foo'' on top of ' << x << '
'.
		tab2 at: stp position store: (UInt8Array string: 'foo')].
	aStream << 'Ending table is:
' << tab2 << '
with count ' << tab2 count << '.
Done with stepperCopy test.
'.! !

!HashTableTester methodsFor: 'running tests'!

{void} allTestsOn: aStream {ostream reference}
	"self runTest: #allTestsOn:"


	aStream << 'Running all HashTable tests.
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
	self test7On: aStream.
	self testStepperCopyOn: aStream.! !

!HashTableTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !