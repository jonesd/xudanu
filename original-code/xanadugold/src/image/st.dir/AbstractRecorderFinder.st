'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:50 pm'!

SensorPropFinder subclass: #AbstractRecorderFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
AbstractRecorderFinder comment:
'The finders used to find recorders in the sensor canopy in response to some change in props of a Stamp.'!

(AbstractRecorderFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!AbstractRecorderFinder methodsFor: 'create'!

create
	super create "for generated code"!

create: flags {UInt32}

	super create: flags! !

!AbstractRecorderFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition}
	
	self subclassResponsibility!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	self subclassResponsibility! !

!AbstractRecorderFinder methodsFor: 'recording'!

{void} checkRecorder: recorder {ResultRecorder}
	with: fossil {RecorderFossil}
	"While doing one step of a southward walk in the O-tree,
	 filtered by the sensor canopy,
	 looking for recorders that represent queries that are newly passed by the change of properties,
	 where the object that changed properties and the change itself are represented by my state,
	 record my object into the recorder if it newly passes the recorder's filtering criteria.
	 
	 See class comments of the various subclasses for details on the purpose of each kindOf AbstractRecorderFinder."
	
	self subclassResponsibility! !

!AbstractRecorderFinder methodsFor: 'smalltalk: passe'!

{void} checkStamp: stamp {BeEdition} with: recorder {TransclusionRecorder}
	"record the stamp into the recorder if I pass this recorder's filters"
	
	self passe!

{void} checkStamp: stamp {BeEdition} 
	with: recorder {TransclusionRecorder}
	with: fossil {RecorderFossil}
	"While doing one step of a southward walk in the O-tree,
	 filtered by the sensor canopy,
	 looking for recorders that represent queries that are newly passed by the change of properties in the Stamp
	 (said change in properties being represented by my state),
	 record the stamp into the recorder if the stamp newly passes the fossil's filtering criteria.
	 
	 See class comments of the various subclasses for details on the purpose of each kindOf AbstractRecorderFinder."
	
	self passe! !

!AbstractRecorderFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: crum {CanopyCrum}

	self subclassResponsibility! !