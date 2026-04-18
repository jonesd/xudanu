'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:28 pm'!

MethodAction subclass: #MatchingAction
	instanceVariableNames: 'myPattern {String}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Actions'!



!MatchingAction methodsFor: 'creation'!

create: pattern

	super create.
	myPattern _ pattern! !

!MatchingAction methodsFor: 'accessing'!

{void} emphasizeText: text {Text}
	
	| pos {Integer} 
	  match {(OrderedCollection of: (Array with: Integer with: Integer)) | nil} |
	pos _ 1.
	[match _ '*', myPattern, '*' fetchMatch: text startingAt: pos ignoreCase: false.
	match ~~ nil]
		whileTrue: [
			2 to: match size do: [:i |
				| pi ti lastPi lastTi tMatch |
				pi _ (match at: i) at: 1.
				ti _ (match at: i) at: 2.
				lastPi _ (match at: i -1) at: 1.
				lastTi _ (match at: i -1) at: 2.
				tMatch _ ti - (pi - lastPi - 1).
				i > 2
					ifTrue: [text emphasizeFrom: lastTi to: tMatch -1 with: 3].
				text emphasizeFrom: tMatch to: ti -1 with: 15].
			pos _ match last at: 2]!

{Interval | nil} fetchSelection: text {Text | String} startingAt: index {Integer}
	
	| resultStart {Integer}
	  pos {Integer} 
	  match {(OrderedCollection of: (Array with: Integer with: Integer)) | nil} |
	resultStart _ nil.
	pos _ index.
	[match _ '*', myPattern, '*' fetchMatch: text startingAt: pos ignoreCase: false.
	match ~~ nil]
		whileTrue: [
			2 to: match size do: [:i |
				| pi ti lastPi tMatch |
				pi _ (match at: i) at: 1.
				ti _ (match at: i) at: 2.
				lastPi _ (match at: i -1) at: 1.
				(match at: i -1) at: 2.
				tMatch _ ti - (pi - lastPi - 1).
				resultStart == nil
					ifTrue: [resultStart _ tMatch]].
			pos _ match last at: 2.
			(resultStart ~~ nil and: [resultStart >= index])
				ifTrue: [^resultStart to: pos -1]
				ifFalse: [resultStart _ nil]].
	^nil! !

!MatchingAction methodsFor: 'protected:'!

{Text} theReplacementIn: text {Text} of: span {Interval}
	
	^'*', myPattern, '*' 
		matchAndReplace: (text copyFrom: span first to: span last)
		with: ('*', myReplacement, '*') asText allBold
		startingAt: 1
		ignoreCase: false! !