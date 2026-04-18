'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:58 pm'!

ClassRelatedCR subclass: #ClassRenameCR
	instanceVariableNames: 'myOldName {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!ClassRenameCR methodsFor: 'creation'!

create: recorder {ChangeRecorder} with: path {Collection} with: vis {Symbol} with: class {Symbol} with: old {Symbol} 
	super create: recorder with: path with: vis with: class.
	self initialize: old.!

from: input {FileStream}

	super from: input.
	myOldName _ input nextChunk asSymbol.!

from: input {FileStream} with: recorder {ChangeRecorder}

	super from: input with: recorder.
	myOldName _ input nextChunk asSymbol.!

initialize: old {Symbol} 

	myOldName _ old.
	self link: old.! !

!ClassRenameCR methodsFor: 'storing'!

recordOn: logFile
	super recordOn: logFile.
	logFile nextChunkPut: myOldName.! !

!ClassRenameCR methodsFor: 'accessing'!

{String} displayString

	^ super displayString , ' was ' , myOldName!

{Boolean} doesMap
	"whether this record does any mapping of links onto other links"
	^true!

{Symbol} map: link {Symbol}
	"the link that should be used to continue back from here along the 'same' chain"
	
	link = myClassName
		ifTrue: [^ myOldName]
		ifFalse: [^ super map: link]!

oldName
	^ myOldName!

{Symbol} unmap: link {Symbol}
	"the link that should be used to continue forward from here along the 'same' chain"
	
	link = myOldName
		ifTrue: [^ myClassName]
		ifFalse: [^ super map: link]! !