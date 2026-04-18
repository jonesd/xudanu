'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:05 pm'!

Object subclass: #Model
	instanceVariableNames: 'dependents '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Kernel-Objects'!
Model comment:
'Any object may have dependents that receive notification of any change to the object.  Class Model provides a variant representation for objects that are expected to have dependents;this representation is faster but takes more space than the one provided in class Object.

Instance Variables:
	dependents	<nil | Object | DependentsCollection>'!


!Model methodsFor: 'copying'!

copy
	"Answer another instance just like the receiver. 
	Do not copy the dependents list."

	^super copy breakDependents! !

!Model methodsFor: 'dependents access'!

addDependent: anObject
	"Add anObject as one of the receiver's dependents."

	dependents _ dependents asDependentsWith: anObject.
	^anObject!

dependents
	"Answer an Collection of the objects that are dependent on the receiver, that is, the objects that should be notified if the receiver changes."

	^dependents asDependentsAsCollection!

removeDependent: anObject
	"Remove the argument, anObject, as one of the receiver's dependents."

	dependents _ dependents asDependentsWithout: anObject.
	^anObject! !

!Model methodsFor: 'private: private'!

breakDependents
	"Deallocate the receiver's dependents."

	dependents _ nil!

myDependents
	"Answer the receiver's dependents or nil."

	^dependents! !