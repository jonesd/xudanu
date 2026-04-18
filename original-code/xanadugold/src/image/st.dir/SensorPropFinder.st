'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:02 pm'!

PropFinder subclass: #SensorPropFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
SensorPropFinder comment:
'Used to filter by the sensor canopy'!

(SensorPropFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #NOT.A.TYPE; add: #DEFERRED; yourself)!

!SensorPropFinder methodsFor: 'create'!

create
	super create "for generated code"!

create: flags {UInt32}

	super create: flags! !

!SensorPropFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition}
	
	self subclassResponsibility!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	self subclassResponsibility! !

!SensorPropFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: crum {CanopyCrum}

	self subclassResponsibility! !