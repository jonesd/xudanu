'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:58 pm'!

MethodFilter subclass: #MethodFinder
	instanceVariableNames: '
		myTester {BlockClosure of: Behavior with: Symbol}
		myLabel {String}
		myPattern {String}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser'!



!MethodFinder methodsFor: 'accessing'!

{String} label

	^myLabel!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^myTester value: cls value: sel!

{String | BlockClosure} pattern
	^myPattern! !

!MethodFinder methodsFor: 'instance creation'!

create: tester {BlockClosure of: Behavior with: Symbol} 
	with: label {String} 
	with: pattern {String} 
	super create.
	myTester _ tester.
	myLabel _ label.
	myPattern _ pattern.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MethodFinder class
	instanceVariableNames: ''!



!MethodFinder class methodsFor: 'instance creation'!

make: tester {BlockClosure of: Behavior with: Symbol} 
	with: label {String} 
	with: pattern {String} 
	^self create: tester with: label with: pattern! !