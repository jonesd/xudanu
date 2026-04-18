'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:37 pm'!

GenerateMethods subclass: #EnumerateMethods
	instanceVariableNames: '
		myMethods {Collection of: MethodRep}
		myLabel {String}
		myPattern {String}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!EnumerateMethods methodsFor: 'accessing'!

{String} label
	
	^myLabel!

{Collection of: MethodRep} methodReps: filter {MethodFilter}

	| result {Collection of: MethodRep} |
	result _ OrderedCollection new.
	myMethods do: [:rep {MethodRep} |
		((filter passes: rep methodClass) 
		 and: [filter passes: rep methodClass with: rep selector])
		 	ifTrue: [result add: rep copy]].
	^result!

{BooleanVar} passes: cls {Behavior} 

	^true!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	myMethods includes: (MethodRep make: cls with: sel)! !

!EnumerateMethods methodsFor: 'creation'!

create: methods {Collection of: MethodRep} 
	with: label {String}
	with: pattern {String default: nil}

	super create.
	myMethods _ methods.
	myLabel _ label.
	myPattern _ pattern! !

!EnumerateMethods methodsFor: 'protected:'!

{void} behaviorsDo: aBlock {BlockClosure of: Behavior} 

	self doesntNeedToBeImplemented! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EnumerateMethods class
	instanceVariableNames: ''!



!EnumerateMethods class methodsFor: 'creation'!

make: methods {Collection of: MethodRep} 
	with: label {String}
	with: pattern {String default: nil}

	^self create: methods with: label with: pattern! !

!EnumerateMethods class methodsFor: 'smalltalk: defaults'!

make: methods {Collection of: MethodRep} with: label {String}

	^self make: methods with: label with: nil! !