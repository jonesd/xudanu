'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:27 pm'!

MethodAction subclass: #LexingAction
	instanceVariableNames: 'myToken {String}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Actions'!



!LexingAction methodsFor: 'creation'!

create: token

	super create.
	myToken _ token! !

!LexingAction methodsFor: 'accessing'!

{void} emphasizeText: text {Text}

	| pos {Integer} |
	pos _ 0.
	[(pos _ text asString findToken: myToken startingAt: pos + 1) ~= 0]
		whileTrue: [
			text 
				emphasizeFrom: pos
				to: pos + myToken size - 1
				with: 13]!

{Interval | nil} fetchSelection: text {Text | String} startingAt: index {Integer}

	| pos {Integer} |
	pos _ 0.
	[(pos _ text asString findToken: myToken startingAt: pos + 1) ~= 0]
		whileTrue: [pos >= index
						ifTrue: [^pos to: pos + myToken size - 1]].
	^nil! !