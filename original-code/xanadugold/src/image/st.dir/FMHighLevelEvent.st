'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:50 pm'!

FMEvent subclass: #FMHighLevelEvent
	instanceVariableNames: '
		myType {PackOBits}
		mySpecifier {PackOBits}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Events'!

(FMHighLevelEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMHighLevelEvent methodsFor: 'creation'!

create: time {TimeVar} with: type {PackOBits} with: specifier {PackOBits}

	super create: time.
	myType _ type.
	mySpecifier _ specifier! !

!FMHighLevelEvent methodsFor: 'accessing'!

{PackOBits} eventSpecifier
	^ mySpecifier!

{PackOBits} eventType
	^ myType!

{PointPos} pointIn: aView {Viewer unused} 
	self unimplemented.
	^ NULL! !

!FMHighLevelEvent methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	super printOn: oo.
	oo << ' Type: ' << myType << '; specifier: ' <<
mySpecifier! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMHighLevelEvent class
	instanceVariableNames: ''!

(FMHighLevelEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMHighLevelEvent class methodsFor: 'pseudoconstructors'!

make: time {TimeVar} with: type {PackOBits} with: specifier {PackOBits}
	^ self create: time with: type with: specifier! !