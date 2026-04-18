'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:51:56 pm'!

Object subclass: #ChangeRecord
	instanceVariableNames: '
		myRecorder {ChangeRecorder}
		myDeleted {BooleanVar}
		myChangesPosition {IntegerVar}
		myLogPosition {IntegerVar}
		myUser {Symbol}
		myLinks {Dictionary}
		myDate {Date}
		myTime {Time}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Change Records'!



!ChangeRecord methodsFor: 'creation'!

create
	| time {OrderedCollection} |
	self passe.
	myRecorder _ ChangeLog.
	myDeleted _ false.
	myChangesPosition _ self recorder changesPosition.
	myLogPosition _ self recorder logPosition.
	myUser _ self recorder user.
	myLinks _ IdentityDictionary new.
	self link: myUser.
	self link: #RECORD.
	time _ Time dateAndTimeNow.
	myDate _ time first.
	myTime _ time last.!

create: recorder {ChangeRecorder}
	| time {OrderedCollection} |
	myRecorder _ recorder.
	myDeleted _ false.
	myChangesPosition _ self recorder changesPosition.
	myLogPosition _ self recorder logPosition.
	myUser _ self recorder user.
	myLinks _ IdentityDictionary new.
	self link: myUser.
	self link: #RECORD.
	time _ Time dateAndTimeNow.
	myDate _ time first.
	myTime _ time last.!

from: input {FileStream}
	"type has already been determined and is implicit in the class of the receiver"
	"log position must have been noted by the sender, and should be set with logPosition:"
	| links {Stream} |
	self passe.
	myRecorder _ ChangeLog.
	myDeleted _ input nextChunk = 'D'.
	myChangesPosition _ Integer readFrom: input nextChunk readStream.
	myUser _ input nextChunk asSymbol.
	links _ ReadStream on: input nextChunk.
	myLinks _ IdentityDictionary new.
	[links atEnd] whileFalse:
		[ | key {Symbol} value {Integer} |
		key _ (String readFrom: links) asSymbol.
		value _ Integer readFrom: links.
		myLinks at: key put: value].
	myDate _ Date readFrom: input nextChunk readStream.
	myTime _ Time readFrom: input nextChunk readStream.!

from: input {FileStream} with: recorder {ChangeRecorder}
	"type has already been determined and is implicit in the class of the receiver"
	"log position must have been noted by the sender, and should be set with logPosition:"
	| links {Stream} |
	myRecorder _ recorder.
	myDeleted _ input nextChunk = 'D'.
	myChangesPosition _ Integer readFrom: input nextChunk readStream.
	myUser _ input nextChunk asSymbol.
	links _ ReadStream on: input nextChunk.
	myLinks _ IdentityDictionary new.
	[links atEnd] whileFalse:
		[ | key {Symbol} value {Integer} |
		key _ (String readFrom: links) asSymbol.
		value _ Integer readFrom: links.
		myLinks at: key put: value].
	myDate _ Date readFrom: input nextChunk readStream.
	myTime _ Time readFrom: input nextChunk readStream.! !

!ChangeRecord methodsFor: 'accessing'!

{Boolean} acceptText: aText from: aController
	^ false!

changesPosition
	^ myChangesPosition!

changesPosition: position {Integer}
	myChangesPosition _ position!

{String} changesString
	"get the corresponding string from the changes file"
	self recorder changes position: myChangesPosition.
	^ self recorder changes nextChunk!

date
	^ myDate!

dateString
	^ myDate printFormat: #(2 1 3 47 1 1)!

deleted
	^ myDeleted!

{String} displayString

	^ (myDeleted ifTrue: ['* '] ifFalse: ['  ']) ,
		myUser , ' ' ,
		self dateString , ' ' ,
		myTime printString!

{Boolean} doesMap
	"whether this record does any mapping of links onto other links"
	^false!

{Integer} follow: link
	"return the position of the previous record along a link chain, or -1 if none"
	| result |
	result _ myLinks at: link ifAbsent: [^ -1]. "yes, this IS supposed to return out of the routine"
	result = -1
		ifTrue: [result := self recorder lastFake: link.
			result abs >= self logPosition ifTrue: [^-1] ifFalse: [^result]]
		ifFalse: [self hack. result = self logPosition ifTrue: [self error: 'Circular link'].
			^ result]!

{Integer} followAll: links {Collection of: Symbol}
	"return the position of the previous record that is in all these chains, or -1 if none"
	
	| positions {SortedCollection} |
	links isEmpty ifTrue: [^ -1].
	positions _ SortedCollection sortBlock: [ :a :b | a value >= b value].
	links do: [ :link | | position {Integer} |
		position _ self follow: link.
		position = -1
			ifTrue: [^ -1]
			ifFalse: [positions add: link -> position]].
	[ | record {ChangeRecord} link {Symbol} position {Integer} |
		position _ positions first value.
		position = positions last value
			ifTrue: [self hack. position = self logPosition ifTrue: [self error: 'Circular link'].
				^ position].
		record _ self recorder get: position.
		link _ record map: positions first key.
		position _ record follow: link.
		positions removeFirst.
		position = -1
			ifTrue: [^ -1]
			ifFalse: [positions add: (link -> position)]] repeat.!

{Symbol} identifier
	"the symbol for looking up the latest version of this change"
	^ nil!

{Collection of: Symbol} identifiers
	"the previous record on all of these links is overridden by this one"
	^ #()!

links
	^ myLinks!

logPosition
	^ myLogPosition!

logPosition: position
	"set the log position of a record read from a file"
	
	myLogPosition _ position.!

{Symbol} map: link {Symbol}
	"the link that should be used to continue back from here along the 'same' chain"
	
	^ link!

{Integer} previous
	"return the position of the previous record that this overrides, or -1 if none"
	^self followAll: self identifiers!

{ChangeRecorder} recorder
	"return the change recorder I am recording onto"
	
	^ myRecorder!

{void} recorder: newRecorder {ChangeRecorder}
	"change the change recorder I am recording onto"
	
	myRecorder _ newRecorder!

sourcePosition
	^ myChangesPosition + 1!

summaryString
	"a string containing the user who made the change, date and time"
	^myUser , '    ' , self dateString , '  ' , self time printString!

time
	^ myTime!

{Symbol} type
	"what kind of change record I am"
	
	^ self class name asSymbol!

{Symbol} user
	"the user who made this change"
	^myUser! !

!ChangeRecord methodsFor: 'storing'!

fileOutOn: file {FileStream}
	"file out all changes associated with this record onto another file"
	| changes |
	changes _ self changesString.
	changes isEmpty ifFalse:
		[file cr; cr; nextChunkPut: changes].!

{Boolean} isEssential
	"should this record be filed out even if it is superceded? (e.g. initial class definition)"
	
	^ false!

{Boolean} isPersistent
	"whether this should persist in standard file outs"
	^ true!

link: link {Symbol}
	"add a link along the specified chain"
	
	^ myLinks at: link put: (self recorder link: link)!

mapLinks: map {Dictionary}
	"map all backward links using the supplied table"
	myLinks associationsDo: [ :pair |
		myLinks at: pair key put:
			(map at: pair value ifAbsent: [-1])].!

recordOn: log {FileStream}
	log nextChunkPut: self type printString;
		nextChunkPut: (myDeleted ifTrue: ['D'] ifFalse: [' ']);
		nextChunkPut: myChangesPosition printString;
		nextChunkPut: myUser;
		nextChunkPut: (String streamContents: [ :stream |
			myLinks associationsDo: [ :pair |
				pair key asString storeOn: stream.
				pair value printOn: stream]]);
		nextChunkPut: self dateString;
		nextChunkPut: myTime printString.! !

!ChangeRecord methodsFor: 'comparing'!

= other {ChangeRecord}
	self class = other class
		ifFalse: [^ false].
	(1 to: self class instSize) do: [ :i |
		(((self instVarAt: i) isKindOf: Dictionary)
				or: [(self instVarAt: i) = (other instVarAt: i)])
			ifFalse: [^ false]].
	myLinks size = other links size
		ifFalse: [^ false].
	myLinks keysDo: [ :link |
		(myLinks at: link) = (other links at: link ifAbsent: [^ false])
			ifFalse: [^ false]].
	^ true!

hash
	^ self class instSize + (self instVarAt: 1) hash + (self instVarAt: self class instSize) hash! !

!ChangeRecord methodsFor: 'printing'!

printOn: output {Stream}

	output nextPutAll: self displayString.
	"| class classes names |
	classes _ ReadWriteStream on: (Array new: 10).
	output nextPutAll: self class name.
	class _ self class.
	[class ~~ Object] whileTrue:
		[classes nextPut: class.
		class _ class superclass].
	names _ ReadWriteStream on: (Array new: 20).
	classes contents reverseDo: [ :c |
		names nextPutAll: c instVarNames].
	names reset.
	(1 to: self class instSize) do: [ :i |
		output nextPutAll: ' ';
			nextPutAll: names next;
			nextPutAll: ': ';
			nextPutAll: (self instVarAt: i) printString]."! !

!ChangeRecord methodsFor: 'protected: creation'!

delete
	"mark as deleted in the file"
	self recorder log
		position: myLogPosition;
		nextChunk;
		nextChunkPut: 'D';
		setToEnd;
		commit.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ChangeRecord class
	instanceVariableNames: ''!



!ChangeRecord class methodsFor: 'creation'!

{ChangeRecord | nil} make: input {PeekableStream}
	| position {Integer} class {String} result {ChangeRecord} |
	self passe.
	position _ input position.
	class _ input nextChunk.
	result _ (Smalltalk at: class asSymbol ifAbsent:
			[Transcript cr; show: 'Bad change record(' , position printString , '): ';
				show: (input upTo: Character cr).
			^nil])
		new from: input.
	result logPosition: position.
	^result!

{ChangeRecord | nil} make: input {PeekableStream} with: recorder {ChangeRecorder}
	| position {Integer} class {String} result {ChangeRecord} |
	position _ input position.
	class _ input nextChunk.
	result _ (Smalltalk at: class asSymbol ifAbsent:
			[Transcript cr; show: 'Bad change record(' , position printString , '): ';
				show: (input upTo: Character cr).
			^nil])
		new from: input with: recorder.
	result logPosition: position.
	^result! !

!ChangeRecord class methodsFor: 'identifiers'!

{Symbol} class: class {Symbol}
 
	^ (class , '>') asSymbol!

{Symbol} class: class {Symbol} meta: meta {Boolean}
 
	^ (class , (meta ifTrue: [' class>'] ifFalse: ['>'])) asSymbol!

{Collection of: Symbol} class: class {Symbol} meta: meta {Boolean} selector: selector {Symbol}

	^ Array with: class with: (self meta: meta selector: selector)!

{Symbol} class: class {ClassDescription} selector: selector {Symbol}

	^ (class name , '>' , selector) asSymbol!

{Collection of: Symbol} leaf: leaf {Symbol} visibility: vis {Symbol} field: field {Symbol}
	^ Array with: leaf with: (self visibility: vis field: field)!

{Symbol} meta: meta {Boolean} selector: selector {Symbol}

	meta ifTrue: [^ ('class ' , selector) asSymbol]
		ifFalse: [^ selector]!

{Symbol} pathLeaf: path {OrderedCollection of: Symbol}
	^(path last , ' ') asSymbol!

visibility 
	^ #>!

visibility: vis 
	vis == #public ifTrue:
		[^ #x].
	vis == #protected ifTrue:
		[^ #r].
	vis == #private ifTrue:
		[^ #p].
	vis == #test ifTrue:
		[^ #t].
	vis == self visibility ifTrue:
		[^ vis].
	self error: 'Bad visibility symbol ' , vis storeString!

{Symbol} visibility: vis {Symbol} field: field {Symbol}
	^ ((self visibility: vis) , ':' , field) asSymbol!

{Symbol} visibilityFrom: ch {Character}

	ch == $x ifTrue: [^ #public].
	ch == $r ifTrue: [^ #protected].
	ch == $p ifTrue: [^ #private].
	ch == $t ifTrue: [^ #test].
	ch == self visibility first ifTrue: [^ self visibility].
	self error: 'Bad visibility symbol ' , ch storeString! !