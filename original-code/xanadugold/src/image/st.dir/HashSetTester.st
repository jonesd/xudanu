'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:35 pm'!

MuSetTester subclass: #HashSetTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Testing'!

(HashSetTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!HashSetTester methodsFor: 'tests'!

{void} basicTestsOn: oo {ostream reference} 

	| set1 {HashSet} set2 {HashSet} set3 {HashSet} set4 {HashSet}
	 set5 {HashSet} |

	oo << '
basic tests -- start with creation.
'.
	set1 _ HashSet make.
	set2 _ HashSet make.Heaper: (SHTO make: 'heaper' with:   1193046).
	set3 _ HashSet make.IntegerVar: 4.
	set4 _ HashSet make.IntegerVar: 19.
	set5 _ HashSet make.IntegerVar: IntegerVar0.
	oo << 'basic hash set is: ' << set1 << ' internals:
'.
	set1 printInternals: oo.
	oo << '
basic set on heaper is: ' << set2 << ' internals:
'.
	set2 printInternals: oo.
	oo << '
basic set make(4) is: ' << set3 << ' internals:
'.
	set3 printInternals: oo.
	oo << '
basic set make(19) is: ' << set4 << ' internals:
'.
	set4 printInternals: oo.
	oo << '
basic set make(0) is: ' << set5 << ' internals:
'.
	set5 printInternals: oo.

	set1 destroy.
	set3 destroy.
	set4 destroy.
	set5 destroy.
	
	set1 _ (set2 copy) cast: HashSet.
	oo << 'copy of ' << set2 << ' is ' << set1.
	oo << '
internals of source:
'.
	set2 printInternals: oo.
	oo << '
internals of copy:
'.
	set1 printInternals: oo.
	oo << '

End of basic tests
'!

{void} doIntroduceTestsOn: oo {ostream reference} 

	| set1 {HashSet} |
	oo << '
introduce tests
'.
	self introduceTestsOn: oo with: HashSet make with: (SHTO make: 'first' with: Int32Zero).
	self introduceTestsOn: oo with: HashSet make with: (SHTO make: 'second' with: 1).
	self introduceTestsOn: oo with: HashSet make with: (SHTO make: 'third' with: 6).
	self introduceTestsOn: oo with: HashSet make with: (SHTO make: 'fourth' with: 7).
	
	set1 _ HashSet make.
	self introduceTestsOn: oo with: set1 with: (SHTO make: 'one' with: 1).
	self introduceTestsOn: oo with: set1 with: (SHTO make: 'two' with: 1).
	self introduceTestsOn: oo with: set1 with: (SHTO make: 'three' with: 1).
	self introduceTestsOn: oo with: set1 with: (SHTO make: 'one' with: 1).
	
	set1 destroy.
	set1 _ HashSet make.
	self introduceTestsOn: oo with: set1 with: (SHTO make: 'one' with: 1).
	self introduceTestsOn: oo with: set1 with: (SHTO make: 'two' with: 1).
	self introduceTestsOn: oo with: set1 with: (SHTO make: 'three' with: 1).
	self introduceTestsOn: oo with: set1 with: (SHTO make: 'fower' with: 2).
	set1 destroy.
	
	oo << '

End of introduce tests
'!

{void} doStoreTestsOn: oo {ostream reference} 

	| set1 {HashSet} set2 {HashSet} |
	oo << '
store tests
'.
	self storeTestsOn: oo with: HashSet make with: (SHTO make: 'first' with: Int32Zero).
	self storeTestsOn: oo with: HashSet make with: (SHTO make: 'second' with: 1).
	self storeTestsOn: oo with: HashSet make with: (SHTO make: 'third' with: 6).
	self storeTestsOn: oo with: HashSet make with: (SHTO make: 'fourth' with: 7).
	
	set1 _ HashSet make.
	self storeTestsOn: oo with: set1 with: (SHTO make: 'one' with: 1).
	self storeTestsOn: oo with: set1 with: (SHTO make: 'two' with: 1).
	self storeTestsOn: oo with: set1 with: (SHTO make: 'three' with: 1).
	self storeTestsOn: oo with: set1 with: (SHTO make: 'one' with: 1).
	
	oo << 'testing storeAll

'.
	set2 _ HashSet make.
	set2 store: (SHTO make: 'duble' with: 2).
	set2 store: (SHTO make: 'triple' with: 3).
	self storeTestsOn: oo with: set2 with: (SHTO make: 'quadle' with: 4).
	self storeTestsOn: oo with: set1 with: (SHTO make: 'onele' with: 1).
	set1 storeAll: set2.
	oo << 'after storeAll, set1 now:
'.
	set1 printInternals: oo.
	oo << 'after storeAll, set2 now:
'.
	set2 printInternals: oo.
	
	oo << '

End of store tests
'!

{void} doWipeTestsOn: oo {ostream reference} 

	| set1 {HashSet} set2 {HashSet} |
	oo << '
wipe tests
'.
	set1 _ HashSet make.
	set1 store: (SHTO make: 'one' with: Int32Zero).
	self wipeTestsOn: oo with: set1 with: (SHTO make: 'one' with: Int32Zero).
	set1 destroy.
	
	set1 _ HashSet make.
	set1 store: (SHTO make: 'two' with: 1).
	self wipeTestsOn: oo with: set1 with: (SHTO make: 'two' with: 1).
	set1 destroy.
	
	set1 _ HashSet make.
	set1 store: (SHTO make: 'three' with: 6).
	self wipeTestsOn: oo with: set1 with: (SHTO make: 'three' with: 6).
	set1 destroy.
	
	set1 _ HashSet make.
	set1 store: (SHTO make: 'four' with: 7).
	self wipeTestsOn: oo with: set1 with: (SHTO make: 'four' with: 7).
	set1 destroy.
	
	set1 _ HashSet make.
	set1 store: (SHTO make: 'one' with: 1).
	set1 store: (SHTO make: 'two' with: 1).
	set1 store: (SHTO make: 'three' with: 1).
	set1 store: (SHTO make: 'fower' with: 2).
	
	set2 _ (set1 copy) cast: HashSet.
	self wipeTestsOn: oo with: set2 with: (SHTO make: 'one' with: 1).
	self wipeTestsOn: oo with: set2 with: (SHTO make: 'two' with: 1).
	self wipeTestsOn: oo with: set2 with: (SHTO make: 'three' with: 1).
	self wipeTestsOn: oo with: set2 with: (SHTO make: 'fower' with: 2).
	set2 destroy.

	set2 _ (set1 copy) cast: HashSet.
	self wipeTestsOn: oo with: set2 with: (SHTO make: 'three' with: 1).
	self wipeTestsOn: oo with: set2 with: (SHTO make: 'two' with: 1).
	self wipeTestsOn: oo with: set2 with: (SHTO make: 'one' with: 1).
	self wipeTestsOn: oo with: set2 with: (SHTO make: 'fower' with: 2).
	set2 destroy.

	set2 _ (set1 copy) cast: HashSet.
	self wipeTestsOn: oo with: set2 with: (SHTO make: 'fower' with: 2).
	self wipeTestsOn: oo with: set2 with: (SHTO make: 'three' with: 1).
	self wipeTestsOn: oo with: set2 with: (SHTO make: 'two' with: 1).
	self wipeTestsOn: oo with: set2 with: (SHTO make: 'one' with: 1).
	set2 destroy.
	
	oo << '

End of wipe tests
'!

{void} testBig: oo {ostream reference}

	| big1 {HashSet} big2 {HashSet} big3 {HashSet} |
	
	oo << '
	
start of big testing.
 
'. 
	big1 _ HashSet make.
	10000 downTo: 1 do: [:i {UInt32} | 
		big1 introduce: (SHTO make: 'some object' with: i)].
	oo << 'new big set (count ' << big1 count << ') is:
' << big1 << '
'.
	big2 _ (big1 copy) cast: HashSet.
	
	oo << '
	

big2 is a copy of big1 (count ' << big2 count << ')

'.
	(big2 isSubsetOf: big1)
		ifTrue: [oo << 'big2 is a subset of big1
']
		ifFalse: [oo << 'big2 is NOT a subset of big1
'].
	(big1 isSubsetOf: big2)
		ifTrue: [oo << 'big1 is a subset of big2
']
		ifFalse: [oo << 'big1 is NOT a subset of big2
'].
	3 to: 9999 by: 3 do: [:j {UInt32} |
		big2 remove: (SHTO make: 'some object' with: j)].
	oo << '
big2 now has every third element removed (count ' << big2 count << ')

'.
	(big2 isSubsetOf: big1)
		ifTrue: [oo << 'big2 is a subset of big1
']
		ifFalse: [oo << 'big2 is NOT a subset of big1
'].
	(big1 isSubsetOf: big2)
		ifTrue: [oo << 'big1 is a subset of big2
']
		ifFalse: [oo << 'big1 is NOT a subset of big2
'].
	big3 _ big1 copy cast: HashSet.
	big3 wipeAll: big2.
	oo << 'big3 is big1-big2 - count ' << big3 count << '

'.
	(big3 isSubsetOf: big1)
		ifTrue: [oo << 'big3 is a subset of big1
']
		ifFalse: [oo << 'big3 is NOT a subset of big1
'].
	(big1 isSubsetOf: big3)
		ifTrue: [oo << 'big1 is a subset of big3
']
		ifFalse: [oo << 'big1 is NOT a subset of big3
'].
	(big3 isSubsetOf: big2)
		ifTrue: [oo << 'big3 is a subset of big2
']
		ifFalse: [oo << 'big3 is NOT a subset of big2
'].
	(big2 isSubsetOf: big3)
		ifTrue: [oo << 'big2 is a subset of big3
']
		ifFalse: [oo << 'big2 is NOT a subset of big3
'].

	oo << '

end of bigset testing
'.
	big1 destroy.
	big2 destroy.
	big3 destroy! !

!HashSetTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference} 
	"HashSetTester runTest"

	oo << 'HashSet testing
'.
	super allTestsOn: oo.
	self basicTestsOn: oo.
	self doIntroduceTestsOn: oo.
	self doStoreTestsOn: oo.
	self doWipeTestsOn: oo.
	self testBig: oo.
	oo << '
End of black box testing - now for the White!!

'.
	oo << '
End of HashSet testing

'! !

!HashSetTester methodsFor: 'test support'!

{void} introduceTestsOn: oo {ostream reference} with: set1 {HashSet} with: object {SHTO}

	oo << 'set1 starts as: ' << set1 << ' internals:
'.
	set1 printInternals: oo.
	oo << 'set1 introduce: ' << object << '
'.
	MuSet problems.AlreadyInSet handle: [:ex | oo << '
PROBLEM: ' << object << ' is already in set!!
'. ^VOID]
		do: [set1 introduce: object].
		
	oo << 'set1 now: ' << set1 << ' internals:
'.
	set1 printInternals: oo.

	set1 stepper forEach: [:item {Heaper} |
		(set1 hasMember: item)
			ifFalse: [oo << 'PROBLEM: item ' << item << ' was not found in set!!
'. ^ VOID]]!

{void} removeTestsOn: oo {ostream reference} with: set1 {HashSet} with: object {SHTO}

	oo << 'set1 starts as: ' << set1 << ' internals:
'.
	set1 printInternals: oo.
	oo << 'set1 remove: ' << object << '
'.
	MuSet problems.NotInSet handle: [:ex | oo << '
PROBLEM: ' << object << ' is not in the set!!
'. ^ VOID]
		do: [set1 remove: object].
		
	oo << 'set1 now: ' << set1 << ' internals:
'.
	set1 printInternals: oo.

	set1 stepper forEach: [:item {Heaper} |
		(set1 hasMember: item)
			ifFalse: [oo << 'PROBLEM: item ' << item << ' was not found in set!!
'. ^ VOID]]!

{void} storeTestsOn: oo {ostream reference} with: set1 {HashSet} with: object {SHTO}

	oo << 'set1 starts as: ' << set1 << ' internals:
'.
	set1 printInternals: oo.
	oo << 'set1 store: ' << object << '
'.
	set1 store: object.
		
	oo << 'set1 now: ' << set1 << ' internals:
'.
	set1 printInternals: oo.

	set1 stepper forEach: [:item {Heaper} |
		(set1 hasMember: item)
			ifFalse: [oo << 'PROBLEM: item ' << item << ' was not found in set!!
'. ^ VOID]]!

{void} wipeTestsOn: oo {ostream reference} with: set1 {HashSet} with: object {SHTO}

	oo << 'set1 starts as: ' << set1 << ' internals:
'.
	set1 printInternals: oo.
	oo << 'set1 wipe: ' << object << '
'.
	set1 wipe: object.
		
	oo << 'set1 now: ' << set1 << ' internals:
'.
	set1 printInternals: oo.

	set1 stepper forEach: [:item {Heaper} |
		(set1 hasMember: item)
			ifFalse: [oo << 'PROBLEM: item ' << item << ' was not found in set!!
'. ^ VOID]]! !

!HashSetTester methodsFor: 'accessing'!

{ScruSet} generateSet

	"^ MuSet make		No - we're testing ActualHashSets, not MuSets."
	
	^ ActualHashSet make!

{ScruSet} generateSetContaining: stuff {Stepper}
	| t {MuSet} |
	
	"t _ MuSet make.			No - we're testing ActualHashSets, not MuSets."
	t _ ActualHashSet make.
	stuff forEach: [:e {Heaper} |
		t store: e].
	^ t! !

!HashSetTester methodsFor: 'smalltalk: obsolete tests'!

{void} oldTestsOn: oo {ostream reference} 
	"HashSetTester runTest"

	oo << 'HashSet testing
'.
	super allTestsOn: oo.
	self test1On: oo.
	self test2On: oo.
	self test3On: oo.
	self test4On: oo.
	self testCollisions: oo.
	"self testBig: oo.	"
	"self testOrderedDelete: oo."		"Turned off until regression sets match"
	oo << 'End of HashSet testing
'!

{void} printRemoveOf: pb {SHTO} in: set1 {MuSet} on: oo {ostream reference}

	| setSize {UInt32} |
	
	set1 remove: pb.

	"oo << 'remove of ' << pb << '
set 1 (count ' << set1 count << ') now : ' << set1 << '
'"
	setSize _ (set1  cast: ActualHashSet) entryTableSize.
	oo << 'hash of ' << pb << ' mod ' << setSize.
	oo << ' == ' << (pb hashForEqual \\ setSize) << '
'.
	oo << 'set 1 now : ' << set1 << '
internals:	'.
	(set1 cast: HashSet) printInternals: oo.!

{void} printStoreOf: pb {SHTO} in: set1 {MuSet} on: oo {ostream reference}

	| setSize {UInt32} |
	set1 store: pb.
	
	"oo << 'store of ' << pb << '
set 1 (count ' << set1 count << ') now : ' << set1 << '
'.  !!!!!!!!"
	setSize _ (set1 cast: ActualHashSet) entryTableSize.
	oo << 'hash of ' << pb << ' mod ' << setSize. 
	oo << ' == ' << (pb hashForEqual \\ setSize) << '
'.
	oo << 'set 1 now : ' << set1 << '
internals:	'.
	(set1 cast: HashSet) printInternals: oo.!

{void} test1On: oo {ostream reference} 
	"HashSetTester runTest: #test1On:"

	| set1 {HashSet} set2 {HashSet} |
	oo << 'start of test 1
'.	"create a set"
	set1 _ HashSet make.		"We're testing HashSets, not MuSets"
	oo << 'set 1 == ' << set1 << '
internals:	'.
	set1 printInternals: oo.
	oo << '
'.
	self printStoreOf: (SHTO make: 'element one' with: 360500835) in: set1 on: oo.
	self printStoreOf: (SHTO make: 'element two') in: set1 on: oo.
	self printStoreOf: (SHTO make: 'element three') in: set1 on: oo.
	self printStoreOf: (SHTO make: 'elemeno one') in: set1 on: oo.
	self printStoreOf: (SHTO make: 'elemano one') in: set1 on: oo.
	self printStoreOf: (SHTO make: 'element four') in: set1 on: oo.
	self printStoreOf: (SHTO make: 'element five') in: set1 on: oo.
	self printStoreOf: (SHTO make: 'element six') in: set1 on: oo.

	set2 _ set1 copy cast: HashSet.
	oo << 'set1 copy == set2 == ' << set2 << '
internals:	'.
	set2 printInternals: oo.
	oo << '

compare sets, set1 isSubsetOf: set2 ' << ((set1 isSubsetOf: set2)
			ifTrue: ['TRUE']
			ifFalse: ['FALSE']) << '

 - now remove ''elemano one'' from set1:
 '.
	set1 remove: (SHTO make: 'elemano one').
	oo << 'set 1 now : ' << set1 << '
internals:	'.
	set1 printInternals: oo.
	oo << '
compare sets, set1 isSubsetOf: set2 ' << ((set1 isSubsetOf: set2)
			ifTrue: ['TRUE']
			ifFalse: ['FALSE']) << '
compare sets, set2 isSubsetOf: set1 ' << ((set2 isSubsetOf: set1)
			ifTrue: ['TRUE']
			ifFalse: ['FALSE']) << '
'."
Remove elements three and one from set1.
'.
	set1 remove: (SHTO make: 'element three').
	set1 remove: (SHTO make: 'element one').
	oo << 'set 1 now : ' << set1 << '
'"
	set1 destroy.
	set2 destroy.!

{void} test2On: oo {ostream reference} 
	"HashSetTester runTest: #test2On:"
	"second test suite for HashSet"

	| set1 {HashSet} stomp {Stepper} |
	set1 _ HashSet make.
	set1 introduce: (SHTO make: 'element One').
	set1 introduce: (SHTO make: 'element Two').
	set1 introduce: (SHTO make: 'element Three').
	oo << 'Start of test 2, set1 starts as:
' << set1 << '
'.
	oo << 'set1 hasMember: (''element One'') == '.
	(set1 hasMember: (SHTO make: 'element One'))
		ifTrue: [oo << 'TRUE']
		ifFalse: ['FALSE'].
	oo << '
'.
	oo << 'set1 hasMember: (''element Five'') == '.
	(set1 hasMember: (SHTO make: 'element Five'))
		ifTrue: [oo << 'TRUE']
		ifFalse: [oo << 'FALSE'].
	oo << '
'.
	oo << 'set1->count() == ' << set1 count << '
'.
	oo << 'set1->stepper() produces: '.
	stomp _ set1 stepper.
	oo << stomp << '
and stepping produces elements:
'.
	[stomp hasValue]
		whileTrue: [oo << stomp fetch << '
'.
			stomp step].
	oo << '
'.
	set1 destroy!

{void} test3On: oo {ostream reference} 
	"HashSetTester runTest: #test3On:"

	| set1 {HashSet} set2 {HashSet} set3 {HashSet} |
	set1 _ HashSet make.
	set2 _ HashSet make.
	set1 introduce: (SHTO make: 'element One').
	set1 introduce: (SHTO make: 'element Two').
	set1 introduce: (SHTO make: 'element Three').
	set2 introduce: (SHTO make: 'element One').
	set2 introduce: (SHTO make: 'element Five').
	oo << 'Start of test 3, set1 (copied to set3) starts as:

' << set1 << '

and set2 starts as:

' << set2 << '

'.
	set3 _ set1 copy cast: HashSet.
	set3 restrictTo: set2.
	oo << 'set3->restrict(set2) == 

' << set3 << '

'.
	set3 destroy.
	set3 _ set1 copy cast: HashSet.
	set3 restrictTo: HashSet make.
	oo << 'set3->restrict({nullSet}) == 

' << set3 << '

'.
	set3 destroy.
	set3 _ HashSet make.
	set3 restrictTo: set2.
	oo << 'set3({nullSet})->restrict(set2) == 

' << set3 << '

'.
	set3 destroy.
	set3 _ set1 copy cast: HashSet.
	set3 storeAll: set2.
	oo << 'set3->storeAll(set2) == 

' << set3 << '

'.
	set3 destroy.
	set3 _ set1 copy cast: HashSet.
	set3 wipeAll: set2.
	oo << 'set3->wipeAll(set2) == 

' << set3 << '

'.
	set1 destroy.
	set2 destroy.
	set3 destroy.!

{void} test4On: oo {ostream reference} 
	"HashSetTester runTest: #test4On:"

	| set1 {HashSet} set3 {HashSet} |
	set1 _ HashSet make.
	set1 introduce: (SHTO make: 'One').
	set1 introduce: (SHTO make: 'Two').
	set1 introduce: (SHTO make: 'Three').
	oo << 'Start of test 4, set1 (copied to set3) starts as:

' << set1 << '
internals:
'.
set1 printInternals: oo.
	oo << '

set1 hasMember: (SHTO make: ''One'')' << ((set1 hasMember: (SHTO make: 'One'))
			ifTrue: ['TRUE']
			ifFalse: ['FALSE']) << '.
set1 hasMember: (SHTO make: ''Two'')' << ((set1 hasMember: (SHTO make: 'Two'))
			ifTrue: ['TRUE']
			ifFalse: ['FALSE']) << '.
set1 hasMember: (SHTO make: ''Three'')' << ((set1 hasMember: (SHTO make: 'Three'))
			ifTrue: ['TRUE']
			ifFalse: ['FALSE']) << '.
'.

	set3 _ set1 copy cast: HashSet.
	set3 store: (SHTO make: 'Three').
	oo << 'set3->store (''Three'') == 

' << set3 << '

'.
	set3 destroy.
	set3 _ set1 copy cast: HashSet.
	set3 store: (SHTO make: 'Five').
	oo << 'set3->store (''Five'') == 

' << set3 << '

'.
	set3 destroy.
	set3 _ set1 copy cast: HashSet.
	set3 wipe: (SHTO make: 'Three').
	oo << 'set3->wipe (''Three'') == 

' << set3 << '

'.
	set3 destroy.
	set3 _ set1 copy cast: HashSet.
	set3 wipe: (SHTO make: 'Five').
	oo << 'set3->wipe (''Five'') == 

' << set3 << '

'.
	set3 destroy.
	set3 _ set1 copy cast: HashSet.
	oo << 'set3->remove (''Ten'') == 

'.
	ScruSet problems.NotInSet handle: [:ex | oo << 'BLAST(NotInSet)'.
		^VOID]
		do: [set3 remove: (SHTO make: 'Ten')].
	oo << set3 << '

'!

{void} testCollisions: oo {ostream reference}

	| set1 {HashSet} |
	set1 _ HashSet make.
	oo << '

collision testing
'.
	self printStoreOf: (SHTO make: 'tast' with: 11) in: set1 on: oo.
	self printStoreOf: (SHTO make: 'tbst' with: 11) in: set1 on: oo.
	self printStoreOf: (SHTO make: 'tcst' with: 11) in: set1 on: oo.
	self printStoreOf: (SHTO make: 'tdst' with: 11) in: set1 on: oo.
	self printStoreOf: (SHTO make: 'test' with: 11) in: set1 on: oo.
	self printStoreOf: (SHTO make: 'tfst' with: 11) in: set1 on: oo.
	self printStoreOf: (SHTO make: 'tgst' with: 11) in: set1 on: oo.
	self printStoreOf: (SHTO make: 'thst' with: 11) in: set1 on: oo.
	self printStoreOf: (SHTO make: 'tist' with: 11) in: set1 on: oo.
	self printStoreOf: (SHTO make: 'tjst' with: 11) in: set1 on: oo.
	self printStoreOf: (SHTO make: 'tkst' with: 11) in: set1 on: oo.
oo << 'storing elements already present
'.
	self printStoreOf: (SHTO make: 'test' with: 11) in: set1 on: oo.
	self printStoreOf: (SHTO make: 'tast' with: 11) in: set1 on: oo.
	self printStoreOf: (SHTO make: 'tgst' with: 11) in: set1 on: oo.
oo << 'storing new element (tlst)
'.
	self printStoreOf: (SHTO make: 'tlst' with: 11) in: set1 on: oo.
	self printRemoveOf: (SHTO make: 'tast' with: 11) in: set1 on: oo.
	self printRemoveOf: (SHTO make: 'tdst' with: 11) in: set1 on: oo.
	set1 destroy!

{void} testOrderedDelete: oo {ostream reference}
	"0 to: 40 do: [:n | ((((n*7)+1) \\ 5) == 3) ifTrue: [Transcript show: 'another is '; print: ((n*7)+1); cr; endEntry]]."
	| testSet {HashSet} h1 {Heaper} h2 {Heaper} h3 {Heaper} h4 {Heaper} |
	
	oo << '
testing ordered hash chaining.
'.
	testSet _ HashSet make.
	testSet introduce: (h1 _ SHTO make: 'seventy-eight' with: 78).
	testSet introduce: (h2 _ SHTO make: 'forty-three' with: 43).
	testSet introduce: (h3 _ SHTO make: 'eight' with: 8).
	oo << 'testSet now ' << testSet << '
'.
	((testSet hasMember: h1) and: [(testSet hasMember: h2) and: [testSet hasMember: h3]])
		ifTrue: [oo << 'all members found
']
		ifFalse: [ oo << 'ERROR - not all members found
'].
	testSet remove: h2.

	oo << 'remove ' << h2 << ' , testSet now ' << testSet << '
'.
	(testSet hasMember: h1)
		ifTrue: [oo << 'set still professes to contain ' << h1 << '
']
		ifFalse: [oo << 'ERROR - set does not profess to contain ' << h1 << '
'].

	(testSet hasMember: h3)
		ifTrue: [oo << 'set still professes to contain ' << h3 << '
']
		ifFalse: [oo << 'ERROR - set does not profess to contain ' << h3 << '
'].

	testSet introduce: (h4 _ SHTO make: 'one-hundred-thirteen' with: 113).
	oo << 'introduce ' << h4 << ', testSet now ' << testSet << '
'.
	(testSet hasMember: h1)
		ifTrue: [oo << 'set still professes to contain ' << h1 << '
']
		ifFalse: [oo << 'ERROR - set does not profess to contain ' << h1 << '
'].
	(testSet hasMember: h3)
		ifTrue: [oo << 'set still professes to contain ' << h3 << '
']
		ifFalse: [oo << 'ERROR - set does not profess to contain ' << h3 << '
'].! !

!HashSetTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !