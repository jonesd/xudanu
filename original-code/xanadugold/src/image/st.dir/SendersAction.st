'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:31 pm'!

SelectorsAction subclass: #SendersAction
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Actions'!



!SendersAction methodsFor: 'protected:'!

{BooleanVar} passes: node {ProgramNode}

	^(node isKindOf: SimpleMessageNode) and: [myChangeTable includesKey: node selector]!

{Text} theReplacementIn: text {Text} of: span {Interval} using: sel {Symbol}

	| node {SimpleMessageNode} 
	  result {Text} 
	  place {Integer} 
	  newParts {SequenceableCollection of: Symbol}
	  partNum {Integer} |
	  
	node _ self fetchNodeIn: text at: span.
	result _ Text new.
	place _ span first.
	newParts _ sel keywords.
	partNum _ 1.
	node keywordSpansIn: text do: [:subSpan {Interval} :part {Symbol} |
		result _ result, (text copyFrom: place to: subSpan first -1), 
			(newParts at: partNum) asText allBold.
		partNum _ partNum +1.
		place _ subSpan last +1].
	result _ result, (text copyFrom: place to: span last).
	^result! !