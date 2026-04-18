'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:58 pm'!

CxxRelatedCR subclass: #ClassRelatedCR
	instanceVariableNames: 'myClassName {Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!ClassRelatedCR methodsFor: 'storing'!

recordOn: logFile
	super recordOn: logFile.
	logFile nextChunkPut: myClassName.! !

!ClassRelatedCR methodsFor: 'creation'!

ClassRelatedCR.initialize: class {Symbol}
	myClassName _ class.
	self link: class.!

create: recorder {ChangeRecorder} with: path {Collection} with: vis {Symbol} with: class {Symbol}
	super create: recorder with: path with: vis.
	self ClassRelatedCR.initialize: class.!

from: input {FileStream}

	super from: input.
	myClassName _ input nextChunk asSymbol.!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myClassName _ input nextChunk asSymbol.! !

!ClassRelatedCR methodsFor: 'accessing'!

className
	^ myClassName!

{String} displayString

	^ super displayString , ' - ' , myClassName! !