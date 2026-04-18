'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:29 pm'!

Tester subclass: #GrandHashTableTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Grand'!

(GrandHashTableTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!GrandHashTableTester methodsFor: 'tests'!

{void} bigTableTestOn: aStream {ostream reference} 
	"self runTest: #bigTableTestOn:"
	"test growing"

	| tab {MuTable of: Pair} keys {MuSet of: HeaperAsPosition} |
	aStream << 'Test growth behavior of GrandHashTable
'.
	tab _ GrandHashTable make: HeaperSpace make.
	keys _ MuSet make: 4000.
	1 to: 4000 do: [ :i {Int32} | | thing {Pair} key {HeaperAsPosition} |
		thing _ Pair make: (IntegerPos make: 4000) with: (IntegerPos make: 3 * i).
		key _ HeaperAsPosition make: thing.
		tab at: key introduce: thing.

		keys introduce: key.
		"i > 400 ifTrue:
			[keys stepper forEach: [ : foo {HeaperAsPosition} |
				tab get: foo]]"].
	
	keys stepper forEach: [ :key {HeaperAsPosition} |
		tab get: key].
	
	aStream << 'Growth test successful.
'.!

{void} test1On: oo {ostream reference} 
	"self runTest: #test1On:"
	"test creation"

	| tab1 {MuTable} tab2 {MuTable} |
	oo << 'Create tables with create, create: and create:with:

'.
	tab1 _ GrandHashTable make: IntegerSpace make.
	tab2 _ GrandHashTable make: IntegerSpace make with: 4.	"test printing"
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
	tab1 atInt: 1 introduce: (UInt8Array string: 'filly').
	tab1 atInt: IntegerVar0 introduce: (UInt8Array string: 'mare').
	oo << 'Test introduce: ' << tab1 << ', table count now: ' << tab1 count << '

'.
	tab1 atInt: -1 introduce: (UInt8Array string: 'colt').
	oo << 'Test introduce: ' << tab1 << ', table count now: ' << tab1 count << '

'.
	tab1 atInt: 27 introduce: (UInt8Array string: 'stallion').
	oo << 'Test introduce: ' << tab1 << ', table count now: ' << tab1 count << '

'.
	MuTable problems.AlreadyInTable handle: [:ex | oo << 'already in table blast caught, table now:

' << tab1 << '

and table count: ' << tab1 count << '

'.
		^VOID]
		do: [tab1 atInt: 1 introduce: (UInt8Array string: 'palooka')].
	oo << 'Test empty table: '.
	tab1 isEmpty
			ifTrue: [oo << 'Empty']
			ifFalse: [oo << 'Not Empty'].
	oo << '

'.!

{void} test2On: aStream {ostream reference} 
	"self runTest: #test2On:"

	"test creation"
	| tab1 {MuTable} |
	aStream << 'Create tables.

'.
	tab1 _ GrandHashTable make: IntegerSpace make.
	tab1 atInt: 1 introduce: (UInt8Array string: 'filly').
	tab1 atInt: IntegerVar0 introduce: (UInt8Array string: 'mare').
	tab1 atInt: -1 introduce: (UInt8Array string: 'colt').
	tab1 atInt: 27 introduce: (UInt8Array string: 'stallion').
	aStream << 'Starting table is:

' << tab1 << '

'.
	tab1 atInt: 1 replace: (UInt8Array string: 'mare').
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
		do: [tab1 atInt: 2 replace: (UInt8Array string: 'palooka')].
	aStream << 'Test replace() with NULL. 
'.
	MuTable problems.NullInsertion handle: [:ex | aStream << 'NullInsertion blast caught, table now:
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
	tab1 _ GrandHashTable make: IntegerSpace make.
	tab1 atInt: 1 introduce: (UInt8Array string: 'filly').
	tab1 atInt: IntegerVar0 introduce: (UInt8Array string: 'mare').
	tab1 atInt: -1 introduce: (UInt8Array string: 'colt').
	tab1 atInt: 27 introduce: (UInt8Array string: 'stallion').
	aStream << 'Starting table is:

' << tab1 << '

'.
	tab1 atInt: 1 store: (UInt8Array string: 'mare').
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
		do: [tab1 atInt: 2 store: (UInt8Array string: 'palooka')].
	aStream << 'after store:

' << tab1 << ' and table count: ' << tab1 count << '

'.
	aStream << 'Test store() with NULL. 

'.
	MuTable problems.NullInsertion handle: [:ex | aStream << 'NullInsertion blast caught, table now:

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
	tab1 _ GrandHashTable make: IntegerSpace make.
	tab1 at: 1 integer introduce: (UInt8Array string: 'filly').
	tab1 at: Integer0 introduce: (UInt8Array string: 'mare').
	tab1 at: -1 integer introduce: (UInt8Array string: 'colt').
	tab1 at: 27 integer introduce: (UInt8Array string: 'stallion').
	aStream << 'Starting table is:

' << tab1 << '

with count ' << tab1 count << '

'.	"testing enclosure"
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
	tab1 _ GrandHashTable make: IntegerSpace make.
	tab1 atInt: 1 introduce: (UInt8Array string: 'filly').
	tab1 atInt: IntegerVar0 introduce: (UInt8Array string: 'mare').
	tab1 atInt: -1 introduce: (UInt8Array string: 'colt').
	tab1 atInt: 27 introduce: (UInt8Array string: 'stallion').
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

{void} test7On: aStream {ostream reference} 
	"self runTest: #test7On:"
	"Not currently appropriate to GrandHashTable"
	"runs {Iterator}"
	"test creation"
	| tab1 {MuTable} |
	aStream << 'Create tables.

'.
	tab1 _ GrandHashTable make: IntegerSpace make.
	tab1 atInt: 1 introduce: (UInt8Array string: 'filly').
	tab1 atInt: IntegerVar0 introduce: (UInt8Array string: 'mare').
	tab1 atInt: -1 introduce: (UInt8Array string: 'colt').
	tab1 atInt: 27 introduce: (UInt8Array string: 'stallion').
	aStream << 'Starting table is:

' << tab1 << '

with count ' << tab1 count << '

Now, testing runEnclosures

'.	"	runs _ tab1 domain. 
	
	aStream << 'And the results (ta ta TUM!!) 
	
	' << runs << ' 
	
	and now, run lengths.... 
	
	'."
	aStream << 'tab1 runAt: -20 ->' << (tab1 runAtInt: -20).
	aStream << '

tab1 runLengthAt: -10 ->' << (tab1 runAtInt: -10).
	aStream << '

tab1 runLengthAt: -9 ->' << (tab1 runAtInt: -9).
	-1 to: 4 do: [:i {IntegerVar} | aStream << '

tab1 runLengthAt: ' << i << ' ->' << (tab1 runAtInt: i)].
	aStream << '

tab1 runLengthAt: 26 ->' << (tab1 runAtInt: 26).
	aStream << '

tab1 runLengthAt: 27 ->' << (tab1 runAtInt: 27).
	aStream << '

tab1 runLengthAt: 28 ->' << (tab1 runAtInt: 28).
	aStream << '

tab1 runLengthAt: 30 ->' << (tab1 runAtInt: 30).
	aStream << '

tab1 runAt.IntegerVar: 31 ->' << (tab1 runAtInt: 31).
	aStream << '

tab1 runAt.IntegerVar: 32 ->' << (tab1 runAtInt: 32)! !

!GrandHashTableTester methodsFor: 'running tests'!

{void} allTestsOn: aStream {ostream reference} 

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

	self bigTableTestOn: aStream.! !

!GrandHashTableTester methodsFor: 'smalltalk: smalltalk tests'!

runTest: test 
	| str |
	str _ WriteStream on: (String new: 200).
	self perform: test with: str.
	Transcript show: str contents; endEntry!

{GrandHashTable} stomp: anInt {UInt32} 
	| table rGen rNum |
	table _ GrandHashTable make: anInt.
	rGen _ Random new.
	0 to: 1000 do: [:i | rNum _ rGen next * 32768.
		(table includesKey: rNum)
			ifTrue: [table at: rNum replace: i]
			ifFalse: [table at: rNum introduce: i]].
	^table!

{GrandHashTable} stomp: anInt {UInt32} with: anotherInt {UInt32}
|table rGen rNum|
table _ GrandHashTable make: anInt.
rGen _ Random new.
0 to: (anotherInt - 1) do: [:i |
	rNum _ ((rGen next) * 32768) asInteger.
	(table includesIntKey: rNum) ifTrue: [table atInt: rNum replace: i]
	ifFalse: [table atInt: rNum introduce: i]].
^ table! !

!GrandHashTableTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !