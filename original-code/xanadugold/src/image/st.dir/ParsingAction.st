'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:31 pm'!

MethodAction subclass: #ParsingAction
	instanceVariableNames: '
		myCachedSource {String | nil}
		myCachedParse {MethodNode | nil}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Actions'!



!ParsingAction methodsFor: 'creation'!

create

	super create.
	myCachedSource _ nil.
	myCachedParse _ nil.! !

!ParsingAction methodsFor: 'protected:'!

{ProgramNode} fetchNodeIn: text {Text | String} at: span {Interval}

	| tree {ProgramNode} |
	tree _ (self parse: text asString).
	tree == nil
		ifTrue: [^nil].
	self walk: tree do: [:each | 
		((self passes: each) and: [span = (each preferedSelection: text)])
			ifTrue: [^each]].
	^nil!

{MethodNode} parse: string {String}

	string = myCachedSource
		ifFalse: [myCachedSource _ string copy.
				myCachedParse _ LitParser new 
					parse: myCachedSource 
					class: nil
					notifying: (SilentCompilerErrorHandler new 
									failBlock: [^myCachedParse _ nil])].		
	^myCachedParse!

{BooleanVar} passes: node {ProgramNode}

	self subclassResponsibility!

{void} walk: node {ProgramNode} do: aBlock {BlockClosure of: ProgramNode}

	node properDo: aBlock! !

!ParsingAction methodsFor: 'accessing'!

{void} emphasizeText: text {Text}
	
	| node {ProgramNode} |
	node _ self parse: text asString.
	node ~~ nil 
		ifTrue: [self walk: node do: [:each {ProgramNode} | 
			(self passes: each)
				ifTrue: [each highlightSelfIn: text]]]!

{Interval | nil} fetchSelection: text {Text | String} startingAt: index {Integer}

	| node {ProgramNode} result {Interval | nil} |
	node _ self parse: text asString.
	result _ nil.
	node ~~ nil 
		ifTrue: [self walk: node do: [ :each | 
			(self passes: each)
				ifTrue: [ | span {Interval} |
						span _ each preferedSelection: text.
						((result == nil or: [span first < result first]) 
						 and: [span first >= index])
							ifTrue: [result _ span]]]].
	^result! !