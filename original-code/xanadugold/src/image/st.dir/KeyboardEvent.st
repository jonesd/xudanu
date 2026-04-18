'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:45 pm'!

Object subclass: #KeyboardEvent
	instanceVariableNames: 'keyCharacter metaState '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Support'!
KeyboardEvent comment:
'Class KeyboardEvent represents a keyboard event consisting of a non-meta key being struck plus the state of the meta keys at that moment.  Only InputState creates instances of the class.

Instance Variables:
		keyCharacter	<Integer> non-meta key character
		metaState		<Integer> combined state of meta keys
		
'!


!KeyboardEvent methodsFor: 'accessing'!

keyCharacter
	"Answer the character that was pressed."
	"Fix because the mac (for some reason) stopped accepting the apple key
	as the control key."
	
	self hasCtrl
		ifTrue: [keyCharacter > 127
			ifTrue: [^ keyCharacter asCharacter]
			ifFalse: [
			^(keyCharacter asCharacter asUppercase asciiValue bitAnd: -65)
					 asCharacter]]
		ifFalse: [^keyCharacter asCharacter]!

keyValue
	"Answer the keyboard character of the receiver."
	self hasCtrl
		ifTrue: [^keyCharacter bitAnd: 191]
		ifFalse: [^keyCharacter]!

metaState
	"Answer the state of the special keyboard characters--control, shift, lock."

	^metaState! !

!KeyboardEvent methodsFor: 'testing'!

hasCtrl
	"Answer whether a control key was pressed."

	^metaState anyMask: 2!

hasLock
	"Answer whether the shift key is locked."

	^metaState anyMask: 4!

hasShift
	"Answer whether a shift key was pressed."

	^metaState anyMask: 1! !

!KeyboardEvent methodsFor: 'private: private'!

key: anInteger meta: meta 

	keyCharacter _ anInteger.
	metaState _ meta! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

KeyboardEvent class
	instanceVariableNames: ''!


!KeyboardEvent class methodsFor: 'instance creation'!

code: code meta: meta 
	"Answer an instance of the receiver, with code the regular key and meta the special
	keys--ctrl, shift, lock."

	^self new key: code meta: meta! !