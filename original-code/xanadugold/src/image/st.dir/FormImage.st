'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:23 pm'!

Image subclass: #FormImage
	instanceVariableNames: 'myForm {Form}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Warp Display'!
FormImage comment:
'I am a Smalltalk version of the FM Image class.  I hold onto a Smalltalk Form (the direct FM equivalent).'!

(FormImage getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FormImage methodsFor: 'displaying'!

{void} displayOn: aWarp {Warp} 
	"I display my form onto the warp"

	aWarp copyBits: self enclosure
		from: myForm
		at: PointPos make! !

!FormImage methodsFor: 'accessing'!

{PointRegion} enclosure
	^ myForm enclosure! !

!FormImage methodsFor: 'creation'!

create: onForm 
	super create.
	myForm _ onForm! !

!FormImage methodsFor: 'testing'!

{UInt32} hashForEqual

	^ myForm hash!

{BooleanVar} isEqual: other {Heaper}

	(other isKindOf: FormImage) ifFalse: [^ false].
	^ myForm = other form! !

!FormImage methodsFor: 'private: accessing'!

{Form} form
	^ myForm! !