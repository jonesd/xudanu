'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:54 pm'!

MethodChange subclass: #MethodDefinitionChange
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Changes'!
MethodDefinitionChange comment:
'Class MethodDefinitionChange represents a change to the text of a method (as opposed to a category change or a removal).'!


!MethodDefinitionChange methodsFor: 'accessing'!

name
	^className, ' ', selector! !

!MethodDefinitionChange methodsFor: 'file accessing'!

fileName
	file isNil
		ifTrue: [^'current system']
		ifFalse: [^super fileName]! !

!MethodDefinitionChange methodsFor: 'source code'!

getSource
	"Get the source code for this method from information currently in the system."
	self sourceFileAndPosition:
		[:aFile :aPosition |
		file _ aFile.
		position _ aPosition]!

sourceFileAndPosition: aBlock
	"Get the source code for this method from information currently in the system."
	| class method fileIndex  |
	(class _ self classObject) isNil ifTrue: [^nil].
	(class includesSelector: selector) ifFalse: [^nil].
	method _ class compiledMethodAt: selector.
	SourceFiles isNil ifTrue: [^nil].
	fileIndex _ method fileIndex.
	(fileIndex between: 1 and: SourceFiles size) ifFalse: [^nil].
	^aBlock value: (SourceFiles at: fileIndex) value: method filePosition!

text
	"Answer the text displayed by the receiver."

	| aStream numArgs |
	file == nil ifTrue:
		[aStream _ WriteStream on: (String new: 60).
		(numArgs _ selector numArgs) = 0
			ifTrue: [aStream nextPutAll: selector]
			ifFalse:
				[selector keywords with: (1 to: numArgs) do:
					[:word :i |
					aStream nextPutAll: word; nextPutAll: ' t'; print: i; space]].
		aStream cr; tab; nextPutAll: '"Source code not available"'.
		^aStream contents].
	^super text! !

!MethodDefinitionChange methodsFor: 'checking'!

checkWith: aChecker
	| systemVersion oldChanges |
	aChecker changesAt: self name add: self.
	aChecker checkSystem ifTrue:
		[self isInSystem ifFalse:
			[systemVersion _ self class new className: className; category: category; selector: selector.
			systemVersion sourceFileAndPosition:
				[:aFile :aPosition |
				systemVersion file: aFile position: aPosition.
				(aChecker equalWithoutComments: self text and: systemVersion text) ifFalse:
					[oldChanges _ aChecker changesAt: self name.
					oldChanges size > 1 ifTrue:
						[oldChanges do: [:c | c isInSystem ifTrue: [^self]]].
					aChecker changesAt: self name add: systemVersion]]]]!

isInSystem
	self sourceFileAndPosition:
		[:aFile :aPosition |
		(file = aFile and: [position = aPosition])
			ifTrue: [^true]].
	^false! !

!MethodDefinitionChange methodsFor: 'fileIn/Out'!

fileIn
	| class |
	class _ self classObject.
	class isNil
		ifTrue: [self error: 'Class ', className, ' does not exist in this system']
		ifFalse:
			[class compile: self text classified: category.
			Transcript show: className , '<' , category , '
']!

fileOutHeaderOn: aStream
	aStream nextPut: $!!;
		nextPutAll: className;
		nextPutAll: ' methodsFor: ';
		store: category asString;
		nextPut: $!!; cr; cr!

fileOutOn: aStream
	self fileOutHeaderOn: aStream.
	aStream nextChunkPut: self text;
		space; nextPut: $!!; cr; cr!

fileOutOn: aStream previous: previousChange next: nextChange
	((previousChange isKindOf: MethodDefinitionChange) and: [previousChange className == className and: [previousChange category == category]])
		ifFalse:
			[self fileOutHeaderOn: aStream].
	aStream nextChunkPut: self text.
	((nextChange isKindOf: MethodDefinitionChange) and: [nextChange className == className and: [nextChange category == category]])
		ifFalse:
			[aStream space; nextPut: $!!].
	aStream cr; cr! !