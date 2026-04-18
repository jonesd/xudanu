'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:15 pm'!

Heaper subclass: #EditRecord
	instanceVariableNames: '
		myStart {IntegerVar}
		myOldStop {IntegerVar}
		myNewStop {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Support'!
EditRecord comment:
'I remember that an object with linear addressing (like an OrderedCollection or a Text) has been edited, by remembering the bounds of an interval and how many elements replaced the elements in that interval.

Instance Variables:
	start	<Integer>
	stop	<Integer>
	delta	<Integer>
'!

(EditRecord getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!EditRecord methodsFor: 'accessing'!

{IntegerVar} delta
	"This should be the change in size of the range from start ot oldStop."
	^myNewStop - myOldStop!

{BooleanVar} isChanged
	^myStart ~~ myOldStop or: [myStart ~~ myNewStop]!

{IntegerVar} newStop
	^myNewStop!

{IntegerVar} oldStop
	^myOldStop!

{void} replaceFrom: start {IntegerVar} to: stop {IntegerVar} count: size {IntegerVar}
	"Combine this edit with any previous ones."
	
	| delStop{IntegerVar} |
	self isChanged
		ifTrue:
			[myStart _ start.
			myOldStop _ stop.
			myNewStop _ start + size]
		ifFalse:
			[start > myNewStop
				ifTrue: 
					[myOldStop _ myOldStop + stop - myNewStop].
			myStart _ myStart min: start.
			delStop _ stop - myNewStop.
			delStop > IntegerVar0 ifTrue: [myOldStop _ myOldStop + delStop].
			myNewStop _ myNewStop max: stop - size.  "not sure this is right"
			self unimplemented]!

{IntegerVar} start
	^myStart! !

!EditRecord methodsFor: 'create'!

create
	super create.
	myStart _ myOldStop _ myNewStop _ IntegerVar0.!

create: start {IntegerVar} with: stop {IntegerVar} 
	"Start with the edit record initialized to replacing the entire range with the 
	entire range (the whole range changed)."

	super create.
	myStart _ start.
	myOldStop _ myNewStop _ stop! !

!EditRecord methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name << '(' << ' not really implemented ' << ') '! !