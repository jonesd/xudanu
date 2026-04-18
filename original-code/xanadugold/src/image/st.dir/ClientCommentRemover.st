'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:26 pm'!

MethodAction subclass: #ClientCommentRemover
	instanceVariableNames: '
		myCachedSource {String | nil}
		myCachedParse {MethodNode | nil}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Actions'!



!ClientCommentRemover methodsFor: 'protected:'!

{MethodNode} parse: string {String}

	string = myCachedSource
		ifFalse: [myCachedSource _ string copy.
				myCachedParse _ LitParser new 
					parse: myCachedSource 
					class: nil
					notifying: (SilentCompilerErrorHandler new 
									failBlock: [^myCachedParse _ nil])].		
	^myCachedParse!

{Text} theReplacementIn: text {Text} of: span {Interval}
	
	| node {MethodNode} |
	node _ self parse: text asString.
	node comment size >= 2
		ifTrue: [^'""' asText]
		ifFalse: [^'' asText]! !

!ClientCommentRemover methodsFor: 'creation'!

create

	super create.
	myCachedSource _ nil.
	myCachedParse _ nil.! !

!ClientCommentRemover methodsFor: 'accessing'!

{void} emphasizeText: text {Text}
	
	| node {ProgramNode} cc {CommentHolder | nil} src {String} |
	src := text asString.
	node _ self parse: src.
	(node ~~ nil and: [(cc _ node fetchClientComment: src) ~~ nil])
		ifTrue: [cc highlightSelfIn: text]!

{Interval | nil} fetchSelection: text {Text | String} startingAt: index {Integer}

	| node {ProgramNode} cc {CommentHolder | nil} src {String} |
	src := text asString.
	node _ self parse: src.
	(node ~~ nil 
	 and: [(cc _ node fetchClientComment: src) ~~ nil 
	 and: [cc position first >= index]])
	 	ifTrue: [^cc position]
	 	ifFalse: [^nil]!

{BooleanVar} isEditAction

	^true! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ClientCommentRemover class
	instanceVariableNames: ''!



!ClientCommentRemover class methodsFor: 'creation'!

make
	
	^self create! !