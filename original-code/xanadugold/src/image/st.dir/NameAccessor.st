'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:04 pm'!

Object subclass: #NameAccessor
	instanceVariableNames: 'nameTranslation '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Framework-List'!
NameAccessor comment:
'An instance of NameAccessor a translator of name access protocol.  The instance knows the message to send to its referenced object in order to obtain the name of that object.
Instance Variables:
	nameTranslation	<Symbol>	a message selector to send to an object to determine its name'!


!NameAccessor methodsFor: 'accessing'!

nameFor: anObject
	"Answer a printable name for anObject."

	^anObject perform: nameTranslation! !

!NameAccessor methodsFor: 'private: private'!

setName: nameSelector
	"Set the adaptor message for the receiver."

	nameTranslation := nameSelector! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

NameAccessor class
	instanceVariableNames: ''!


!NameAccessor class methodsFor: 'instance creation'!

name: nameSelector 
	"Create a new instance of the receiver with appropriate adaptor 
	message, that is nameSelector is the message selector by which an 
	object finds out another object's name. However, the sending object 
	only has to know the protocol of this class."

	^self new setName: nameSelector! !