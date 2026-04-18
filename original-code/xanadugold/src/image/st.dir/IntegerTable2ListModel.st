'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:40 pm'!

Converter subclass: #IntegerTable2ListModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Builders'!

(IntegerTable2ListModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!IntegerTable2ListModel methodsFor: 'create'!

create
	super create: IntegerTable with: ListModel! !

!IntegerTable2ListModel methodsFor: 'accessing'!

{Heaper} convert: value {Heaper} 
	"perform the conversion. This is defined by those who define a new 
	converter, but not directly called by clients. Clients invoke 
	conversion purely by using the CONVERT macro"

	^ ListModel make: (value basicCast: IntegerTable)! !