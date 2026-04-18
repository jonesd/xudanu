'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:33 pm'!

MethodAction subclass: #BothAction
	instanceVariableNames: '
		myActionA {MethodAction}
		myActionB {MethodAction}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!BothAction methodsFor: 'creation'!

create: a {MethodAction} with: b {MethodAction}

	super create.
	myActionA _ a.
	myActionB _ b.! !

!BothAction methodsFor: 'accessing'!

{void} emphasizeText: text {Text}
	
	myActionA emphasizeText: text.
	myActionB emphasizeText: text!

{Interval | nil} fetchSelection: text {Text | String} startingAt: index {Integer}
	
	| a b |
	a _ myActionA fetchSelection: text startingAt: index.
	b _ myActionB fetchSelection: text startingAt: index.
	a == nil
		ifTrue: [^b].
	b == nil
		ifTrue: [^a].
	a first < b first
		ifTrue: [^a].
	b first < a first
		ifTrue: [^b].
	a last < b last
		ifTrue: [^a]
		ifFalse: [^b].!

{BooleanVar} isEditAction

	^super isEditAction or: [myActionA isEditAction or: [myActionB isEditAction]]!

{void} replacement: replacement {String}

	super replacement: replacement.
	myActionA fetchReplacement == nil
		ifTrue: [myActionA replacement: replacement].
	myActionB fetchReplacement == nil
		ifTrue: [myActionB replacement: replacement].!

{SequenceableCollection of: Text} replacementsIn: text {Text} of: span {Interval}
	
	| result |
	myReplacement ~~ nil
		ifTrue: [result _ super replacementsIn: text of: span]
		ifFalse: [result _ #()].
	^(myActionA replacementsIn: text of: span),
	 (myActionB replacementsIn: text of: span),
	 result! !