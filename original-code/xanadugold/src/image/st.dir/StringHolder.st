'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:45 pm'!

Model subclass: #StringHolder
	instanceVariableNames: 'contents isLocked '
	classVariableNames: 'Workspace '
	poolDictionaries: ''
	category: 'Interface-Text'!
StringHolder comment:
'Class Stringholder represents a model for providing a layer of structure in order to view an aspect of structured information that is a string.

Instance Variables:
	contents		<String>
	isLocked		<Boolean> whether or not the contents has been changed but not stored

Class Variables:
	Workspace		<TextHolder>
	'!


!StringHolder methodsFor: 'initialize-release'!

initialize
	"Initialize the state of the receiver to be unlocked with default contents."
	isLocked _ false.
	contents _ self defaultContents! !

!StringHolder methodsFor: 'accessing'!

contents
	"Answer the contents that the receiver is holding--presumably a string."
	^contents!

contents: aString 
	"Set aString to be the contents of the receiver."
	contents _ aString string! !

!StringHolder methodsFor: 'doIt/accept/explain'!

doItContext
	"Answer the context in which a text selection can be evaluated."

	^nil!

doItReceiver
	"Answer the object that should be informed of the result of evaluating a
	text selection."

	^nil! !

!StringHolder methodsFor: 'lock access'!

isLocked
	"Answer whether the receiver is locked, that is, has the contents of the 
	receiver been modified since the last time it was unlocked."

	^isLocked!

isUnlocked
	"Answer whether the receiver is unlocked."
	^isLocked not!

lock
	"Note that the receiver has been modified."
	isLocked _ true!

unlock
	"Unlock the receiver.  Any modification has presumably been saved."
	isLocked _ false! !

!StringHolder methodsFor: 'private: private'!

defaultContents
	^ ''! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

StringHolder class
	instanceVariableNames: ''!


!StringHolder class methodsFor: 'class initialization'!

initialize
	"The class variables were initialized once, and 
	subsequently filled with information.  Re-executing this method is 
	therefore dangerous. 
	 
	workSpace  _ StringHolder new.


	StringHolder initialize"! !

!StringHolder class methodsFor: 'instance creation'!

new
	^super new initialize! !

!StringHolder class methodsFor: 'workspace constants'!

workspace
	"Answer the model for the system workspace."
	^Workspace! !

StringHolder initialize!
