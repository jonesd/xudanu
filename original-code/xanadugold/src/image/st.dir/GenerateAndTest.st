'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:41 pm'!

GenerateMethods subclass: #GenerateAndTest
	instanceVariableNames: '
		myGen {MethodGenerator}
		myFilter {MethodFilter}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!GenerateAndTest methodsFor: 'creation'!

create: gen {MethodGenerator} with: filter {MethodFilter}
	
	super create.
	myGen _ gen.
	myFilter _ filter! !

!GenerateAndTest methodsFor: 'accessing'!

{MethodAction | nil} fetchAction

	^MethodAction combine: myGen fetchAction with: myFilter fetchAction!

{MethodGenerator} filteredBy: filter {MethodFilter}
	
	^GenerateAndTest create: myGen with: (myFilter intersect: filter)!

{String} label
	
	| filtLab {String} genLab {String} |
	filtLab _ myFilter label.
	genLab _ myGen label.
	filtLab == nil
		ifTrue: [^genLab].
	genLab == nil
		ifTrue: [^filtLab].
	^filtLab, ' in ', genLab!

{Collection of: MethodRep} methodReps

	(myGen isKindOf: SourceMethods)
		ifTrue: [^self methodReps: (AllMethods make)]
		ifFalse: [^super methodReps]!

{Collection of: MethodRep} methodReps: filter {MethodFilter}

	^myGen methodReps: (filter intersect: myFilter)!

{BooleanVar} passes: cls {Behavior}
	
	^(myGen passes: cls) and: [myFilter passes: cls]!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	^(myGen passes: cls with: sel with: code) 
	  and: [myFilter passes: cls with: sel with: code]! !

!GenerateAndTest methodsFor: 'protected:'!

{void} behaviorsDo: aBlock {BlockClosure of: Behavior} 

	self doesntNeedToBeImplemented! !