'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:19 pm'!

StringHolder subclass: #TextCollector
	instanceVariableNames: 'entryStream '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Transcript'!
TextCollector comment:
'Class TextCollector represents a StringHolder into which text can also be gathered by sending messages using Stream protocol.

Instance Variables:
	entryStream	<WriteStream>
'!


!TextCollector methodsFor: 'initialize-release'!

initialize
	super initialize.
	self beginEntry! !

!TextCollector methodsFor: 'accessing'!

<< anObject 
	anObject isString
		ifTrue: [self nextPutAll: anObject]
		ifFalse: [anObject isCharacter
				ifTrue: [self nextPut: anObject]
				ifFalse: [self print: anObject]].
	entryStream size > 100 ifTrue: [self endEntry].
	^self!

next: anInteger put: aCharacter 
	"Insert the character, aCharacter, at position anInteger in the text."
	^entryStream next: anInteger put: aCharacter!

nextPut: aCharacter 
	"Append aCharacter to the text."
	^entryStream nextPut: aCharacter!

nextPutAll: aCollection 
	"Append all the characters in aCollection to the text."

	^entryStream nextPutAll: aCollection!

show: aString 
	"Append all the characters in aCollection to the text and display the text."
	self nextPutAll: aString.
	self endEntry! !

!TextCollector methodsFor: 'clearing'!

clear
	"Re-initialize the text to contain no characters."

	contents _ Text new.
	self beginEntry.
	self changed: #update
	"Transcript clear"!

refresh
	"Bring window to front on screen"

	self changed: #refresh
	"Transcript refresh"! !

!TextCollector methodsFor: 'entry control'!

appendEntry
	"Append the text contents of the receiver's WriteStream to its text."
	contents _ contents , self nextEntry asText.
	contents size > self characterLimit
		ifTrue: [contents _ 
					contents 
						copyFrom: contents size - (self characterLimit // 2)
						to: contents size].
	self beginEntry!

beginEntry
	"To speed up appending information to the receiver, a WriteStream is
	maintained.  Initialize it."
	entryStream _ WriteStream on: (String new: 200)!

endEntry
	"If the receiver's WriteStream is not empty, then reinitialize it.  Send all
	depends a message that the streaming has changed."
	entryStream isEmpty
		ifFalse: 
			[self changed: #appendEntry.
			self beginEntry]!

nextEntry
	"Answer the text contents of the receiver's WriteStream."
	^entryStream contents! !

!TextCollector methodsFor: 'character writing'!

cr
	"Append a carriage return to the text."
	^entryStream cr!

crtab
	"Append a carriage return and a tab to the text."
	^entryStream crtab!

crtab: anInteger 
	"Append a carriage return and anInteger number of tabs to the text."
	^entryStream crtab: anInteger!

space
	"Append a space to the text."
	^entryStream space!

tab
	"Append a tab to the text."
	^entryStream tab! !

!TextCollector methodsFor: 'printing'!

print: anObject 
	"Append a description of the object, anObject, to the text."
	^entryStream print: anObject!

store: anObject 
	"Have anObject print on me for rereading."

	anObject storeOn: self! !

!TextCollector methodsFor: 'private: private'!

characterLimit
	^50000! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextCollector class
	instanceVariableNames: ''!


!TextCollector class methodsFor: 'system'!

newTranscript: aTextCollector 
	"Store aTextCollector as the value of the system global Transcript."

	Smalltalk at: #Transcript put: aTextCollector.
	^aTextCollector! !

!TextCollector class methodsFor: 'examples'!

transcript
	"This example demonstrates how TextCollectors support WriteStream 
	protocol for appending characters to the System Transcript.  Leave
	the System Transcript in view so you can see the result of trying the
	example."

	"TextCollector transcript"

	Transcript show: (3 + 4) printString; cr.
	Transcript nextPutAll: '3+4 ='; space; print: 3 + 4; cr; endEntry! !

!TextCollector class methodsFor: 'instance creation'!

{TextCollector} make
	^ TextCollector new! !