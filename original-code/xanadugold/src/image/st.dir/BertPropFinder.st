'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:53 pm'!

PropFinder subclass: #BertPropFinder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
BertPropFinder comment:
'Used to filter by the bert canopy'!

(BertPropFinder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #NOT.A.TYPE; add: #DEFERRED; yourself)!

!BertPropFinder methodsFor: 'create'!

create
	super create "for comm"!

create: flags {UInt32}

	super create: flags! !

!BertPropFinder methodsFor: 'accessing'!

{PropFinder} findPast: edition {BeEdition}
	
	self subclassResponsibility!

{BooleanVar} match: prop {Prop}
	"tell whether a prop matches this filter"
	self subclassResponsibility! !

!BertPropFinder methodsFor: 'smalltalk: suspended'!

{PropFinder} oldPass: parent {PropJoint}
	"return a simple enough finder for looking at the children"
	self subclassResponsibility! !