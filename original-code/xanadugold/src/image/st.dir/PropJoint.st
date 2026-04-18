'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:59 pm'!

Heaper subclass: #PropJoint
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy'!
PropJoint comment:
'A PropJoint is an abstraction of property information used to filter tree walks.  When stored on or extracted from a canopy crum it contains both a union and an intersection of the properties of the parent and all its children recursively.  They also serve as intermediates when collecting this information'!

(PropJoint getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!PropJoint methodsFor: 'accessing'!

{UInt32} hashForEqual
	self subclassResponsibility!

{BooleanVar} isEqual: other {Heaper}
	"Return true if the two objects are equal."
	self subclassResponsibility!

{PropJoint} join: other {PropJoint}
	self subclassResponsibility!

{PropJoint} with: prop {Prop}
	self subclassResponsibility! !