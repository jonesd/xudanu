'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:45 pm'!

FMHighLevelAction subclass: #FMSimpleHLAction
	instanceVariableNames: '
		mySpecifier {PackOBits}
		myAction {Thunk}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Control'!
FMSimpleHLAction comment:
'This action controller maps from a single high
level event to a single action.  It can be used in many
simple situations where a particular event is mapped to a
single action.'!

(FMSimpleHLAction getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMSimpleHLAction methodsFor: 'creation'!

create: onType {PackOBits} with: spec {PackOBits} with: action {Thunk} 
	super create: onType.
	mySpecifier _ spec.
	myAction _ action! !

!FMSimpleHLAction methodsFor: 'control'!

{void} handleEvent: anEvent {FMEvent unused} 
	"handle an incoming event."
	
	myAction execute!

{BooleanVar} requestEvents: anEvent {FMEvent} 
	"Inform the handler if event is desired."

	^(super requestEvents: anEvent)
		and: [(anEvent basicCast: FMHighLevelEvent) eventSpecifier isEqual: mySpecifier]! !