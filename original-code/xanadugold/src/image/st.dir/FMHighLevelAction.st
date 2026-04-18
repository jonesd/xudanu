'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:45 pm'!

FMController subclass: #FMHighLevelAction
	instanceVariableNames: 'myEventType {PackOBits}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Control'!
FMHighLevelAction comment:
'This controller is used to map from high level
events to actions (performed by thunks).  An individual
controller will map only one type of high level event, but
can map from several specifiers to particular actions. 
For example, this is useful to map several different MENU
events to their particular actions.'!

(FMHighLevelAction getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FMHighLevelAction methodsFor: 'creation'!

create: onType {PackOBits}

	super create.
	myEventType _ onType! !

!FMHighLevelAction methodsFor: 'control'!

{BooleanVar} requestEvents: anEvent {FMEvent} 
	"Inform the handler if event is desired."

	anEvent 
		cast: FMHighLevelEvent into: [:event |
			^event eventType isEqual: myEventType]
		others: [^false]! !

!FMHighLevelAction methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name << '(' << ' not really implemented ' << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMHighLevelAction class
	instanceVariableNames: ''!

(FMHighLevelAction getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!FMHighLevelAction class methodsFor: 'pseudo
constructors'!

make: onType {PackOBits} with: mapTable {ScruTable of: PackOBits and: Thunk} 
	^FMHLActions create: onType with: mapTable!

make: onType {PackOBits} with: specifier {PackOBits} with: action {Thunk} 
	^FMSimpleHLAction
		create: onType
		with: specifier
		with: action! !