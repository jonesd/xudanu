'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:48 pm'!

GenerateMethods subclass: #OrMethodGenerator
	instanceVariableNames: '
		myGenA {GenerateMethods}
		myGenB {GenerateMethods}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!OrMethodGenerator methodsFor: 'creation'!

create: filterA {MethodFilter} with: filterB {MethodFilter}

	super create.
	myGenA _ filterA.
	myGenB _ filterB! !

!OrMethodGenerator methodsFor: 'accessing'!

{MethodAction | nil} fetchAction

	^MethodAction combine: myGenA fetchAction with: myGenB fetchAction!

{String} label
	
	^'(', myGenA label, ' or ', myGenB label, ')'!

{Collection of: MethodRep} methodReps: filter {MethodFilter}

	| result {Collection of: MethodRep} |
	result _ Set new.
	result addAll: (myGenA methodReps: filter).
	result addAll: (myGenB methodReps: filter).
	^result.!

{BooleanVar} passes: cls {Behavior} 

	^(myGenA passes: cls) or: [myGenB passes: cls]!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^((myGenA passes: cls) and: [myGenA passes: cls with: sel with: code]) 
	 or: [(myGenB passes: cls) and: [myGenB passes: cls with: sel with: code]]! !

!OrMethodGenerator methodsFor: 'protected:'!

{void} behaviorsDo: aBlock {BlockClosure of: Behavior} 
	""
	"Like subclassResponsibility, but subclasses are only obligated to override this if 
	they don't override the default methodReps:, which uses it."

	self hack.
	self subclassResponsibility! !