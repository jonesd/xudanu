'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:50 pm'!

AbstractRecorderFinder subclass: #AnyRecorderFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
AnyRecorderFinder comment:
'NOT.A.TYPE A general superclass for finders that looks for all recorders, and all elements they might find, resulting from a given change.'!

(AnyRecorderFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!AnyRecorderFinder methodsFor: 'create'!

create
	super create "for generated code"!

create: flags {UInt32}

	super create: flags! !

!AnyRecorderFinder methodsFor: 'recording'!

{void} checkRecorder: recorder {ResultRecorder}
	with: fossil {RecorderFossil}

	"do nothing"! !

!AnyRecorderFinder methodsFor: 'accessing'!

{PropFinder} findPast: stamp {BeEdition unused}
	
	^self!

{BooleanVar} match: prop {Prop}

	self subclassResponsibility!

{PropFinder} nextFinder: edition {BeEdition}
	"An additional finder to use below the given Edition"
	
	self subclassResponsibility! !

!AnyRecorderFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}

	self subclassResponsibility! !