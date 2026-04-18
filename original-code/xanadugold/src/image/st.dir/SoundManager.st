'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:07 pm'!

Object subclass: #SoundManager
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'OS-Mac-Support'!


!SoundManager methodsFor: 'primitives'!

enumerateSoundsFrom: aFileOrNil
	" argument is a MacFilename or nil. Returns
	an array of Strings of the names of sounds"
	"SoundManager new enumerateSoundsFrom: nil "

	<primitive: 772>
	^self primitiveFailed!

playSoundFrom: aFileOrNil sound: aString
	" argument aFileOrNil is a MacFilename or nil.
	argument aString is the identifier for a sound.
	 Returns true or false."
	"SoundManager new playSoundFrom: nil sound: 'Simple Beep'"

	<primitive: 773 >
	^self primitiveFailed!

simpleBeep: aNumber
	" argument is a number, Plays the system beep
	associated with the number.  Returns true or false"
	"SoundManager new simpleBeep: 1 "

	<primitive: 774 >
	^self primitiveFailed! !