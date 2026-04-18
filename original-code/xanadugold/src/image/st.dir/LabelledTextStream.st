'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:38 pm'!

TextStream subclass: #LabelledTextStream
	instanceVariableNames: '
		labels {UNKNOWN}
		currentLabel {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Collections-Streams'!
LabelledTextStream comment:
'LabelledTextStreams write out strings, while accumulating changes of emphasis.  When asked for their contents, the instance answers a Text.
Eric Hill 4-30-92: Labels are introduced for index generation in hardcopies.'!



!LabelledTextStream methodsFor: 'labelling'!

label
	"Answers the receiver's current label."

	^currentLabel!

label: anObject
	"Change the receiver's current label to be anObject."

	| length |
	((anObject sameAs: currentLabel) or: [anObject == nil]) ifTrue: [^self].
	length _ position - runStartPosition.
	(length > 0 and: [currentLabel ~~ nil])
		ifTrue: [lengths nextPut: length.
				emphases nextPut: currentEmphasis.
				labels nextPut: currentLabel].
	currentLabel _ anObject.
	runStartPosition _ position.! !

!LabelledTextStream methodsFor: 'character writing'!

emphasis: anInteger
	"Change the receiver's current emphasis to be anInteger."

	| length |
	anInteger = currentEmphasis ifTrue: [^self].
	length _ position - runStartPosition.
	length > 0
		ifTrue: [lengths nextPut: length.
				emphases nextPut: currentEmphasis.
				labels nextPut: currentLabel].
	currentEmphasis _ anInteger.
	runStartPosition _ position.! !

!LabelledTextStream methodsFor: 'private:'!

on: aCollection 

	super on: aCollection.
	labels _ WriteStream on: (Array new: 50).
	currentLabel _ nil.! !

!LabelledTextStream methodsFor: 'accessing'!

contents
	"Answers the receiver's contents as Text."

	| length |
	length _ position - runStartPosition.
	length > 0
		ifTrue: [lengths nextPut: length.
				emphases nextPut: currentEmphasis.
				labels nextPut: currentLabel.
				runStartPosition _ position].
	^Text
		string: super contents
		runs: (LabelledRunArray runs: lengths contents values: emphases contents labels: labels contents)! !