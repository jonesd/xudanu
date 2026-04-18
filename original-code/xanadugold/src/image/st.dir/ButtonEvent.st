'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:48 pm'!

UserEvent subclass: #ButtonEvent
	instanceVariableNames: '
		buttonName {EventEnum}
		clickCountInternal {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Events'!
ButtonEvent comment:
'This should probably internally monitor the time of the last button click and add the appropriate click count.'!

(ButtonEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ButtonEvent methodsFor: 'transition testing'!

{BooleanVar}menuDownFn
	"Return true if this is the right button event."
	
	^buttonName == #menuDown!

{BooleanVar}menuUpFn
	"Return true if this is the right button event."
	^buttonName == #menuUp!

{BooleanVar}selectDownFn
	"Return true if this is the right button event."
	
	^buttonName == #selectDown!

{BooleanVar}selectUpFn
	"Return true if this is the right button event."
	
	^buttonName == #selectUp!

{BooleanVar}windowDownFn
	"Return true if this is the right button event."
	
	^buttonName == #windowDown!

{BooleanVar}windowUpFn
	"Return true if this is the right button event."
	
	^buttonName == #windowUp! !

!ButtonEvent methodsFor: 'accessing'!

{IntegerVar}clickCount
	"Return the number of times this button has been pressed in rapid succesion."

	^clickCountInternal! !

!ButtonEvent methodsFor: 'create'!

create: time {TimeVar} with: point {PointPos} with: metaBits {UInt32} with: button {EventEnum}
	super create: time with: point with: metaBits.
	buttonName _ button.
	clickCountInternal _ 1!

create: time {TimeVar} with: point {PointPos} with: metaBits {UInt32} with: button {EventEnum} with: clickCount {IntegerVar}
	super create: time with: point with: metaBits.
	buttonName _ button.
	clickCountInternal _ clickCount! !

!ButtonEvent methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	super printOn: aStream.
	aStream << ' name: ' << buttonName.
	clickCountInternal ~= 1 ifTrue: [aStream << ' click: ' << clickCountInternal]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ButtonEvent class
	instanceVariableNames: ''!

(ButtonEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!ButtonEvent class methodsFor: 'pseudo constructors'!

make: time {TimeVar} with: point {PointPos} with: metaBits {UInt32} with: button {EventEnum}
	^ ButtonEvent create: time with: point with: metaBits with: button!

make: time {TimeVar} with: point {PointPos} with: metaBits {UInt32} with: button {EventEnum} with: clickCount {IntegerVar}
	^ ButtonEvent create: time with: point with: metaBits with: button with: clickCount! !