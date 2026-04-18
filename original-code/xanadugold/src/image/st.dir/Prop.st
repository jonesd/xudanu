'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:49 pm'!

Heaper subclass: #Prop
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Be-Canopy-Prop'!
Prop comment:
'A collection of properties which are to be found by navigating a Canopy.  PropJoints are the union/intersection style abstraction of the properties which provide for such navigation.'!

(Prop getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Prop methodsFor: 'accessing'!

{UInt32} flags
	"The flags used in the Canopy to tag this prop"
	
	self subclassResponsibility!

{Prop} with: other {Prop}
	self subclassResponsibility! !

!Prop methodsFor: 'smalltalk: suspended'!

{PropJoint} joint

	"Returns the filtering information from this one prop as a PropJoint. "
	
	self subclassResponsibility! !