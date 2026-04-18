'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:03:05 pm'!

UpdateRecord subclass: #UnaryUpdateRecord
	instanceVariableNames: 'myParameter {Heaper}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-xmodel'!
UnaryUpdateRecord comment:
'A convenience for defining update records which are described by a single parameter.  Not a type.  In fact, the existence of this whole class is pretty silly--a usage of subclassing which doesn''t match any decent abstraction.'!

(UnaryUpdateRecord getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!UnaryUpdateRecord methodsFor: 'protected: create'!

create: parameter {Heaper}
	super create.
	myParameter _ parameter! !

!UnaryUpdateRecord methodsFor: 'accessing'!

{Heaper INLINE} parameter
	"The one parameter which, in addition to the type of this update record, 
	describes what changed."

	^myParameter! !