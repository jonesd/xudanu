'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:48 pm'!

Tester subclass: #ShepherdLockTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-sheph'!

(ShepherdLockTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!ShepherdLockTester methodsFor: 'testing'!

{void} allTestsOn: oo {ostream reference} 
	"ShepherdLockTester runTest"

	| conn {Connection} |
	conn _ Connection make: Counter.
	self test1On: oo.
	conn destroy!

{void} test1On: oo {ostream reference} 
	"ShepherdLockTester runTest: #test1On:"
	| aLocked {ShepherdLocked} anUnlocked {ShepherdLocked} stackPtrs {PrimPtrTable} |
	stackPtrs _ StackExaminer pointersOnStack.
	aLocked _ ShepherdLocked makeLocked.
	anUnlocked _ ShepherdLocked makeUnlocked.
	oo << 'aLocked Shepherd '.
	[(stackPtrs fetch: aLocked asOop) == NULL
		ifFalse: [oo << 'is locked']
		ifTrue: [oo << 'is not locked']] smalltalkOnly.
	'if (stackPtrs->fetch((Int32)(void*)aLocked) == NULL) {
		oo << "is locked";
	} else {
		oo << "is not locked";
	}' translateOnly.
	aLocked isReallyUnlocked
		ifFalse: [oo << '; is really locked']
		ifTrue: [oo << '; is really not locked'].
	oo << '
anUnlocked Shepherd '.
	[(stackPtrs fetch: anUnlocked asOop) == NULL
		ifFalse: [oo << 'is locked']
		ifTrue: [oo << 'is not locked']] smalltalkOnly.
	'if (stackPtrs->fetch((Int32)(void*)anUnlocked) == NULL) {
		oo << "is locked";
	} else {
		oo << "is not locked";
	}' translateOnly.
	anUnlocked isReallyUnlocked
		ifFalse: [oo << '; is really locked']
		ifTrue: [oo << '; is really not locked'].
	oo << '
'.! !

!ShepherdLockTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !