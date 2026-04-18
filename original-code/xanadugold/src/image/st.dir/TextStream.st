'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:41 pm'!

WriteStream subclass: #TextStream
	instanceVariableNames: 'lengths emphases currentEmphasis runStartPosition '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Streams'!
TextStream comment:
'TextStreams write out strings, while accumulating changes of emphasis.  When asked for their contents, the instance answers a Text.'!


!TextStream methodsFor: 'accessing'!

contents
	"Answers the receiver's contents as Text."

	| length |
	length _ position - runStartPosition.
	length > 0
		ifTrue: [lengths nextPut: length.
				emphases nextPut: currentEmphasis.
				runStartPosition _ position].
	^Text
		string: super contents
		runs: (RunArray runs: lengths contents values: emphases contents)! !

!TextStream methodsFor: 'character writing'!

emphasis
	"Answers the receiver's current emphasis."

	^currentEmphasis!

emphasis: anInteger
	"Change the receiver's current emphasis to be anInteger."

	| length |
	anInteger = currentEmphasis ifTrue: [^self].
	length _ position - runStartPosition.
	length > 0
		ifTrue: [lengths nextPut: length.
				emphases nextPut: currentEmphasis].
	currentEmphasis _ anInteger.
	runStartPosition _ position.! !

!TextStream methodsFor: 'private:'!

on: aCollection 

	super on: aCollection.
	lengths _ WriteStream on: (Array new: 50).
	emphases _ WriteStream on: (Array new: 50).
	currentEmphasis _ 1.
	runStartPosition _ 0.! !