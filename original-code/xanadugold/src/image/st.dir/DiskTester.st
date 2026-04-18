'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:54 pm'!

Tester subclass: #DiskTester
	instanceVariableNames: 'myBootCounter {Counter NOCOPY}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-diskman'!

(DiskTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!DiskTester methodsFor: 'tests'!

{void} destroyTest: oo {ostream reference unused} 
	"self runTest: #destroyTest:"

	| table {MuTable} |
	table _ MuTable make: IntegerSpace make.
	1 to: 100 do: [:i {Int32} |
		| shep {Abraham} |
		table atInt: i introduce: (DoublingFlock make: i with: i).
		shep _ (table intFetch: i // 2) cast: Abraham.
		shep ~~ NULL ifTrue:
			[shep destroy.
			table intWipe: i // 2].
		self unimplemented.
		"CurrentPacker fluidVar makeConsistent."
		i \\ 20 == Int32Zero ifTrue: [(CurrentPacker fluidGet cast: SnarfPacker) makePersistent]].
	CurrentPacker fluidGet purge!

{void} forward1Test:  oo {ostream reference} 
	"self runTest: #forward1Test:"

	| a {DoublingFlock} b {DoublingFlock} packer {SnarfPacker} |
	a _ DoublingFlock make: 1.
	b _ DoublingFlock make: 2.
	packer _ CurrentPacker fluidGet cast: SnarfPacker.
	oo << 'Flock a is ' << a << ' at ' << a getInfo <<'
Flock b is ' << b << ' at ' << b getInfo <<'
'.	packer makePersistent.
	[a getInfo snarfID == b getInfo snarfID] whileTrue:
		[a doDouble.
		b doDouble.
		oo << 'doubled to ' << a count << '
'.		"a count >= 512 ifTrue: [self halt]."
		packer makePersistent].!

{void} forward2Test:  oo {ostream reference} 
	"self runTest: #forward2Test:"

	| pair {PairFlock} packer {SnarfPacker} |
	pair _ PairFlock create: (DoublingFlock make: 1) with: (DoublingFlock make: 2).
	packer _ CurrentPacker fluidGet cast: SnarfPacker.
	oo << 'Flock a is ' << pair left << ' at ' << pair left getInfo <<'
Flock b is ' << pair right << ' at ' << pair right getInfo <<'
'.	packer makePersistent.
	[pair left getInfo snarfID == pair right getInfo snarfID] whileTrue:
		[(pair left cast: DoublingFlock) doDouble.
		(pair right cast: DoublingFlock) doDouble.
		oo << 'doubled to ' << (pair left cast: DoublingFlock) count << '
'.		"pair left count >= 512 ifTrue: [self halt]."
		packer purge].!

{void} toDiskAndBackTestOn:  aStream {ostream reference} 
	"self runTest: #toDiskAndBackTestOn:"
	"test writing to disk and reading back"

	| firstCounter {MultiCounter} secondCounter {MultiCounter} |
	aStream << '
Test ability to write an object to disk and read it back
'.
	firstCounter _ MultiCounter make: 5.
	firstCounter incrementBoth.
	secondCounter _ MultiCounter make.
	secondCounter incrementFirst; incrementFirst; incrementBoth.
	aStream << '
First MultiCounter = ' << firstCounter.
	aStream << '
Second MultiCounter = ' << secondCounter.

	aStream << '

Purging.'.
	CurrentPacker fluidGet purge.

	aStream << '

Bringing First MultiCounter back; value = ' << firstCounter.
	firstCounter decrementBoth; decrementSecond.
	aStream << '
First MultiCounter = ' << firstCounter.
	
	aStream << '

Bringing Second MultiCounter back and incrementing.'.
	secondCounter incrementSecond; incrementSecond; incrementBoth.
	aStream << '
Second MultiCounter = ' << secondCounter.

	aStream << '

Purging again.'.
	CurrentPacker fluidGet purge.

	aStream << '

Bringing First MultiCounter back; value = ' << firstCounter.
	firstCounter decrementBoth; decrementSecond.
	aStream << '
First MultiCounter = ' << firstCounter.
	
	aStream << '

Bringing Second MultiCounter back and incrementing.'.
	secondCounter incrementSecond; incrementSecond; incrementBoth.
	aStream << '
Second MultiCounter = ' << secondCounter.! !

!DiskTester methodsFor: 'running tests'!

{void} allTestsOn: oo {ostream reference}
	"DiskTester runTest"
	
	| conn {Connection} |
	conn _ Connection make: Counter.
	myBootCounter _ conn bootHeaper cast: Counter.
	self destroyTest: oo.
	self toDiskAndBackTestOn: oo.
	self forward1Test: oo.
	self forward2Test: oo.
	conn destroy! !

!DiskTester methodsFor: 'hooks:'!

{void RECEIVE.HOOK} restartDiskTester: rcvr {Rcvr unused default: NULL}
	myBootCounter _ NULL! !

!DiskTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	self restartDiskTester: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !