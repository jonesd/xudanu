'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:53 pm'!

MethodFilter subclass: #TooDocumented
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!TooDocumented methodsFor: 'accessing'!

{MethodAction | nil} fetchAction

	^ClientCommentRemover make!

{String} label
	
	^'Redundant Client Comment'!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	| cc {CommentHolder | nil} supCc {CommentHolder | nil} |
	cc _ cls fetchClientComment: sel.
	(cc == nil or: [cc string isEmpty])
		ifTrue: [^false].
	cls allSuperclasses do: [:sup {Behavior} |
		supCc _ sup fetchClientComment: sel.
		(supCc ~~ nil and: [supCc string = cc string])
			ifTrue: [^true]].
	^false! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TooDocumented class
	instanceVariableNames: ''!



!TooDocumented class methodsFor: 'creation'!

make

	^self create! !