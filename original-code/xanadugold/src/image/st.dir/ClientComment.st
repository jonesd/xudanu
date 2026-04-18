'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:36 pm'!

MethodFilter subclass: #ClientComment
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Methods'!



!ClientComment methodsFor: 'accessing'!

{MethodAction | nil} fetchAction

	^ClientCommentRemover make!

{String} label
	
	^'Client Comment'!

{BooleanVar} passes: cls {Behavior} with: sel {Symbol} with: code {CompiledMethod}
	
	| cc {CommentHolder | nil} |
	cc _ cls fetchClientComment: sel.
	^cc ~~ nil and: [cc string isEmpty not]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ClientComment class
	instanceVariableNames: ''!



!ClientComment class methodsFor: 'creation'!

make

	^self create! !