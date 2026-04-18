'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:41 pm'!

Object subclass: #SmalltalkVTranscriber
	instanceVariableNames: '
		myClass {Class}
		mySelector {Symbol}
		mySource {String}
		myTemporaries {Dictionary of: String and: String}
		myChanges {Set of: (Association of: Interval and: String)}
		myMethodTempStart {Integer}
		hasMethodTemps {Boolean}
		myFirstComment {Integer}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Smalltalk/V-Translating'!
SmalltalkVTranscriber comment:
'Helps in mapping a smalltalk-80/XuTalk method to Smalltalk/V'!



!SmalltalkVTranscriber methodsFor: 'create'!

create: class {Class} with: selector {Selector}

	myClass := class.
	mySelector := selector.
	mySource := class sourceCodeAt: selector.
	myTemporaries := Dictionary new.
	myChanges := SortedCollection sortBlock:
		[ :a :b | a key first < b key first].! !

!SmalltalkVTranscriber methodsFor: 'accessing'!

{void} fileOutOn: stream {WriteStream}
	"Write a Smalltalk/V version of the method source onto the given stream."
	
	| tree last |
	tree := Parser new parse: mySource class: myClass notifying: nil.
	tree do: [ :node | node transcribeSTVOn: self].
	self endTranscription.
	stream cr; nextPut: $!!; nextPutAll: myClass printString; nextPutAll: ' methods!!'; cr.
	stream nextChunkPut: (String streamContents: [ :substream |
		last := 0.
		myChanges do: [ :change |
			last + 1 < change key first ifTrue:
				[substream nextPutAll: (mySource copyFrom: last + 1 to: change key first - 1)].
			substream nextPutAll: change value.
			last := change key last].
		last < mySource size ifTrue:
			[substream nextPutAll: (mySource copyFrom: last + 1 to: mySource size)]]).
	stream cr.!

{String} source

	^mySource! !

!SmalltalkVTranscriber methodsFor: 'transcribing'!

{void} beginBody: start {Integer} temps: hasTemps {Boolean}
	"The start of the statements in the body of the method"
	hasMethodTemps := hasTemps.
	myMethodTempStart := start.!

{void} blockTemporaries: temps {Array of: ParameterNode}
	"Set the method temporaries"
	(temps isEmpty or: [myMethodTempStart > temps first sourcePosition first]) ifFalse:
		[ | tag start end |
		tag := '"[' , myTemporaries count printString , ']" '.
		start := mySource findString: '|' before: temps first sourcePosition first - 1.
		end := mySource findString: '|' startingAt: temps last sourcePosition last + 1.
		self change: (start to: end) to: tag.
		myTemporaries at: tag put: (mySource copyFrom: start + 1 to: end - 1)]!

change: positions {Interval} to: newString {String}

	myChanges add: positions -> newString!

{void} firstComment: pos {Integer}
	"The position of the beginning quote of the first comment, or of the first piece of code if there is no initial comment"
	myFirstComment := pos.! !

!SmalltalkVTranscriber methodsFor: 'private: private'!

{void} endTranscription

	"Do anything that needs to be done after all the parse nodes have been transcribed"
	| comment hadComment |
	hadComment := (mySource at: myFirstComment) = $".
	comment := '"' , (myClass organization categoryOfElement: mySelector) asString , ' - '.
	comment at: 2 put: (comment at: 2) asUppercase.
	hadComment ifFalse: [comment := comment , '"
	' , (String with: (mySource at: myFirstComment))].
	myTemporaries isEmpty ifFalse:
		[self change: myMethodTempStart asInterval
			to: (String streamContents: [ :stream |
				(hadComment not and: [hasMethodTemps not]) ifTrue:
					[stream nextPutAll: comment.
					comment := nil].
				hasMethodTemps
					ifTrue: [stream crtab]
					ifFalse: [stream nextPutAll: '| '].
				myTemporaries associations
					do: [ :assoc |
						stream nextPutAll: assoc key; nextPutAll: assoc value]
					andBetweenDo:
						[stream crtab].
				hasMethodTemps
					ifFalse: [stream nextPut: $|; crtab].
				stream nextPut: (mySource at: myMethodTempStart)])].
	comment ~~ nil ifTrue:
		[self change: myFirstComment asInterval
				to: comment]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SmalltalkVTranscriber class
	instanceVariableNames: ''!



!SmalltalkVTranscriber class methodsFor: 'pseudo constructors'!

make: class with: sel

	^self create: class with: sel! !

!SmalltalkVTranscriber class methodsFor: 'testing'!

{void LEAF} test.IntegerVar: i {IntegerVar}
	with.Bar: foo {Bar}
	"String streamContents: [ :aStream |
		(SmalltalkVTranscriber make: SmalltalkVTranscriber class
				with: #test.IntegerVar:with.Bar:)
			fileOutOn: aStream]"
	
	| a "between a" {IntegerVar} "a int" |
	a "before" _ "after" 3.

	a do: [ :b {Zip} | "in between" | c {Zoom} "c zoom" |
		c _ a.
		b of: c.]!

{void LEAF} test2
	"String streamContents: [ :aStream |
		(SmalltalkVTranscriber make: SmalltalkVTranscriber class
				with: #test2)
			fileOutOn: aStream]"
	| test {Integer} |
	test := 3.
	test count.!

{void LEAF} test2: test {IntegerVar}
	"String streamContents: [ :aStream |
		(SmalltalkVTranscriber make: SmalltalkVTranscriber class
				with: #test2:)
			fileOutOn: aStream]"
	test count.! !