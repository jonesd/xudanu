'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:42 pm'!

Tester subclass: #WordArrayTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Testing'!

(WordArrayTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!WordArrayTester methodsFor: 'tests'!

{void} test1On: oo {ostream reference} 
	"WordArrayTester runTest: #test1On:"
	"test sequence for wordArray"

	| w1 {MuWordArray} p1 {Sequence} s1 {TableStepper} |
	oo << 'start of MuWordArray test 1.
'.
	w1 _ MuWordArray make.charVector: 'This is a test'.
	oo << 'first wordArray is ' << w1 << '
'.
	oo << 'asString: '.
	[oo << w1 asString] smalltalkOnly.
	'oo << (char*) w1->asString();' translateOnly.
	oo << '
'.
	p1 _ (w1 intFetch: 1) cast: Sequence.
	oo << 'w1->fetch(1) == ' << p1 << '
'.
	oo << 'step through all elements 
> '.
	s1 _ w1 stepper.
	[s1 hasValue]
		whileTrue: [oo << s1 get << ', '.
			s1 step]!

{void} test2On: oo {ostream reference} 
	"WordArrayTester runTest: #test2On:"
	"test sequence for wordArray"

	| w1 {MuWordArray} p1 {PrimIntValue} |
	oo << 'start of MuWordArray test 1.
'.
	w1 _ MuWordArray make.charVector: 'This is a test'.
	oo << 'first wordArray is ' << w1 << '
'.
	p1 _ (w1 intFetch: 1) cast: PrimIntValue.
	oo << 'w1->fetch(1) == ' << p1 << '
'.
	oo << 'change all elements  to ' << p1 << '
> '.
	IntegerVar0 to: w1 count - 1 do: [:i {IntegerVar} | w1 atInt: i store: p1].
	oo << 'the wordArray is now: ' << w1 << '
'! !

!WordArrayTester methodsFor: 'running tests'!

{void} allTestsOn: aStream {ostream reference} 
	"WordArrayTester runTest"

	aStream << 'Running all IntegerTable tests.
Test 1
'.
	self test1On: aStream.
	aStream << '
Test 2
'.
	self test2On: aStream.
	aStream << '
'.! !

!WordArrayTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !