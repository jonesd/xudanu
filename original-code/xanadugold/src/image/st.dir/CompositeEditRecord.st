'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:02 pm'!

Heaper subclass: #CompositeEditRecord
	instanceVariableNames: '
		displayStartInternal {IntegerVar}
		displayStopInternal {IntegerVar}
		composeStartInternal {IntegerVar}
		composeStopInternal {IntegerVar}
		deltaInternal {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Multi'!

(CompositeEditRecord getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CompositeEditRecord methodsFor: 'accessing'!

{IntegerVar}composeStart
	^composeStartInternal!

{IntegerVar}composeStop
	^composeStopInternal!

{IntegerVar}delta
	^deltaInternal!

{IntegerVar}displayStart ^displayStartInternal!

{IntegerVar}displayStop ^displayStopInternal!

{BooleanVar}shouldCompose
	"A composition change has occurred."

	^composeStartInternal ~~ NULL!

{BooleanVar}shouldDisplay
	"A display change has occurred."

	^displayStartInternal ~~ NULL! !

!CompositeEditRecord methodsFor: 'changes'!

{void}addAt: index {IntegerVar} 
	"A subview has just been added."

	composeStartInternal == NULL
				ifTrue: [composeStartInternal _ index]
				ifFalse: [composeStartInternal _ composeStartInternal min: index].
	composeStopInternal _ composeStopInternal + 1 max: index.
	deltaInternal _ deltaInternal + 1.
	displayStartInternal == NULL
				ifTrue: [displayStartInternal _ index]
				ifFalse: [displayStartInternal _ displayStartInternal min: index].
	displayStopInternal _ displayStopInternal + 1 max: index!

{void}redisplayAt: index  {IntegerVar}
	"A subview's image just changed."

	displayStartInternal == NULL
				ifTrue: [displayStartInternal _ index]
				ifFalse: [displayStartInternal _ displayStartInternal min: index].
	displayStopInternal _ displayStopInternal max: index!

{void}removeAt: index {IntegerVar}
	"A subview has just been removed."

	composeStartInternal == NULL
				ifTrue: [composeStartInternal _ index]
				ifFalse: [composeStartInternal _ composeStartInternal min: index].
	composeStopInternal _ composeStopInternal - 1 max: index.
	deltaInternal _ deltaInternal - 1.
	displayStartInternal == NULL
				ifTrue: [displayStartInternal _ index]
				ifFalse: [displayStartInternal _ displayStartInternal min: index].
	displayStopInternal _ displayStopInternal - 1 max: index!

{void}replaceAt: index {IntegerVar}
	"A subview has just been replaced."

	composeStartInternal == NULL
				ifTrue: [composeStartInternal _ index]
				ifFalse: [composeStartInternal _ composeStartInternal min: index].
	composeStopInternal _ composeStopInternal max: index.
	displayStartInternal == NULL
				ifTrue: [displayStartInternal _ index]
				ifFalse: [displayStartInternal _ displayStartInternal min: index].
	displayStopInternal _ displayStopInternal max: index!

{void}replaceFrom: start {IntegerVar} to: stop {IntegerVar}
	"A range of subViews have been replaced."

	composeStartInternal == NULL
				ifTrue: [composeStartInternal _ start]
				ifFalse: [composeStartInternal _ composeStartInternal min: start].
	composeStopInternal _ composeStopInternal max: stop.
	displayStartInternal == NULL
				ifTrue: [displayStartInternal _ start]
				ifFalse: [displayStartInternal _ displayStartInternal min: start].
	displayStopInternal _ displayStopInternal max: stop!

{void} replaceFrom: startIndex {IntegerVar} to: stopIndex {IntegerVar} count: size {IntegerVar} 
	"Combine this edit with any previous ones"

	| newDelta {IntegerVar} |
	self unimplemented.
	newDelta _ size - (stopIndex - startIndex).
	composeStartInternal == NULL
				ifTrue: [composeStartInternal _ startIndex]
				ifFalse: [composeStartInternal _ composeStartInternal min: startIndex].
	composeStopInternal > stopIndex
				ifTrue: [composeStopInternal _ composeStopInternal + newDelta]
				ifFalse: [composeStopInternal _ startIndex + size].
	deltaInternal _ deltaInternal + newDelta.
	displayStartInternal == NULL
				ifTrue: [displayStartInternal _ startIndex]
				ifFalse: [displayStartInternal _ displayStartInternal min: startIndex].
	displayStopInternal >= stopIndex
				ifTrue: [displayStopInternal _ displayStopInternal + newDelta]
				ifFalse: [displayStopInternal _ stopIndex]! !

!CompositeEditRecord methodsFor: 'create'!

create
	super create.
	deltaInternal _ displayStopInternal _ composeStopInternal _ IntegerVar0.
	displayStartInternal _ composeStartInternal _ NULL! !

!CompositeEditRecord methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name << '(' << ' not really implemented ' << ') '! !