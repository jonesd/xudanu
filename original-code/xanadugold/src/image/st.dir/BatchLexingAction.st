'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:25 pm'!

MethodAction subclass: #BatchLexingAction
	instanceVariableNames: 'myChangeTable {Dictionary of: Symbol with: Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Actions'!



!BatchLexingAction methodsFor: 'creation'!

create: renames {Dictionary of: Symbol with: Symbol}

	super create.
	myChangeTable := renames! !

!BatchLexingAction methodsFor: 'accessing'!

{void} emphasizeText: text {Text}

	| pos {Integer} len {Integer} |
	pos _ 0.
	[pos _ text asString 
		findToken: [:tok {String} |
			len := tok size.
			myChangeTable includesKey: tok asSymbol] 
		separators: String defaultTokenTable
		starting: pos + 1.
	pos ~= 0]
		whileTrue: [
			text 
				emphasizeFrom: pos
				to: pos + len - 1
				with: 13]!

{Interval | nil} fetchSelection: text {Text | String} startingAt: index {Integer}

	| pos {Integer} len {Integer} |
	pos _ 0.
	[pos _ text asString 
		findToken: [:tok {String} |
			 len := tok size.
			 myChangeTable includesKey: tok asSymbol]
		separators: String defaultTokenTable
		starting: pos + 1.
	pos ~= 0]
		whileTrue: [pos >= index
						ifTrue: [^pos to: pos + len - 1]].
	^nil!

{BooleanVar} isEditAction

	super isEditAction
		ifTrue: [^true].
		
	myChangeTable keyValuesDo: [:k :v |
		k ~~ v
			ifTrue: [^true]].
	^false! !

!BatchLexingAction methodsFor: 'protected:'!

{Text} theReplacementIn: text {Text} of: span {Interval}
	
	^(myChangeTable at: (text asString copyFrom: span first to: span last) asSymbol) asText allBold! !