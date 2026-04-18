'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:45 pm'!

FMHighLevelAction subclass: #FMHLActions
	instanceVariableNames: 'myActionMap {ScruTable of: PackOBits and: Thunk}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Control'!
FMHLActions comment:
'This action controller maps from any number of
event specifiers to particular actions.'!

(FMHLActions getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMHLActions methodsFor: 'creation'!

create: onType {PackOBits} with: mapTable {ScruTable of: PackOBits and: Thunk} 
	super create: onType.
	myActionMap _ mapTable! !

!FMHLActions methodsFor: 'control'!

{void} handleEvent: anEvent {FMEvent} 
	"handle an incoming event."
 
	((myActionMap get: (anEvent basicCast: FMHighLevelEvent) eventSpecifier)
		cast: Thunk) execute!

{BooleanVar} requestEvents: anEvent {FMEvent} 
	"Inform the handler if event is desired."

	^(super requestEvents: anEvent)
		and: [myActionMap includesKey: (anEvent basicCast: FMHighLevelEvent) eventSpecifier]! !