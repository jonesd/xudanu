'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:52:30 pm'!

Object subclass: #CodeLabel
	instanceVariableNames: 'references definition '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Compiler-Support'!
CodeLabel comment:
'I represent a label in the compiled code stream.  I store references and definitions as stream indices, which are 0-origin, not 1-origin.

Instance variables:
	references	<Array of: (Association key: Integer value: Integer) | nil>  "the locations of the forward references: key = location, value = opcode"
	definition	<Integer | nil>  "the location where the label is defined"

Since the great majority of CodeLabels only have a single reference, we initialize references to nil, and create an array at the first reference, rather than copying an empty array.'!


!CodeLabel methodsFor: 'accessing'!

definition
	^definition!

definition: codePos
	definition _ codePos!

reference: codePos opcode: op
	| ref |
	ref _ Association key: codePos value: op.
	references == nil
		ifTrue: [references _ Array with: ref]
		ifFalse: [references _ references copyWith: ref]!

references
	^references! !

!CodeLabel methodsFor: 'scrunching'!

fixAcross: codePos in: code long: longop
	"If appropriate, fix any branches across
	a place where a scrunch is about to happen.
	Also adjust any labels beyond the scrunch point."
	| refpos op |
	"Note that all definitions and references are
	stream positions, which are 0-origin.
	This is compatible with the accessing protocol
	of CodeReadWriteStream."
	references notNil
		ifTrue:
			[references do: [:ref |
				refpos _ ref key.
				refpos > codePos ifTrue: [ref key: refpos - 1].
				definition notNil ifTrue:
					[definition > codePos
						ifTrue:
							["Might be a crossing forward branch,
							either short or long."
							refpos < codePos ifTrue:
								["Crossing forward branch.
								Subtract 1 from the displacement."
								(op _ code at: refpos) < longop
									ifTrue:
										["Short branch"
										code at: refpos put: op - 1]
									ifFalse:
										["Long branch"
										code adjustBranchAt: refpos by: -1]]]
						ifFalse:
							["Might be a crossing backward branch.
							All backward branches are long."
							refpos > codePos ifTrue:
								["Crossing backward branch.
								Add 1 to the displacement."
								code adjustBranchAt: refpos by: 1]]]]].
	(definition notNil and: [definition > codePos])
		ifTrue: [definition _ definition - 1]! !

!CodeLabel methodsFor: 'printing'!

printOn: aStream
	self storeOn: aStream!

storeOn: aStream
	aStream nextPutAll: '(';
		nextPutAll: self class name;
		nextPutAll: ' new definition: ';
		store: definition.
	references do: [:ref |
		aStream nextPutAll: '; reference: ';
			store: ref key;
			nextPutAll: ' opcode: ';
			store: ref value].
	aStream nextPutAll: ')'! !