'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:28 pm'!

Object subclass: #MethodAction
	instanceVariableNames: 'myReplacement {String | nil}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Actions'!



!MethodAction methodsFor: 'accessing'!

{void} advanceSelection: controller {CodeController}

	| span {Interval} |
	span _ self 
		fetchSelection: controller text 
		startingAt: (controller selectionStarts min: controller properSelectionEnds) + 1.
	span ~~ nil
		ifTrue: [controller selectAndScrollFrom: span first to: span last]
		ifFalse: [controller selectAndScrollFrom: controller text size + 1 to: controller text size]!

{void} emphasizeText: text {Text}
	"Emphasize text as desired"
	
	self subclassResponsibility!

{MethodFilter} fetchNextFilter

	^nil!

{String} fetchReplacement

	^myReplacement!

{Interval | nil} fetchSelection: text {Text | String} startingAt: index {Integer}
	"Returns the interval which should be selected."
	
	self subclassResponsibility!

{Text | nil} fetchUniqueReplacementFor: originalText {Text} 
	
	| replacements {OrderedCollection of: Text}
	  result {Text} 
	  index {Integer} 
	  lastIndex {Integer}
	  span {Interval | nil} 
	  rep {Text} |
	  
	result _ originalText.
	index _ 1.
	lastIndex _ 0.
	
	[span _ self fetchSelection: result startingAt: index.
	span ~~ nil]
		whileTrue:
			[span first <= lastIndex
				ifTrue: [^nil].
			replacements _ self replacementListIn: result of: span.
			replacements size ~= 1
				ifTrue: [^nil].
			rep _ replacements theOne.
			result _ result copyReplaceFrom: span first to: span last with: rep.
			index _ span first + 1.
			lastIndex _ span last + (rep size - (span last - span first +1))].
	^result!

{BooleanVar} isEditAction

	^myReplacement ~~ nil!

{void} nextAction: text {Text} 
	with: controller {CodeController} 
	with: auto {BooleanVar default: false}
	"This method should be reorganized"
	
	| replacements {OrderedCollection of: Text} menuDesc sel pos |
	replacements _ self 
		replacementListIn: text 
		of: (controller selectionStarts to: controller properSelectionEnds).
	
	replacements isEmpty 
		ifTrue: [self advanceSelection: controller.
				^VOID].
	(auto and: [replacements size = 1])
		ifTrue: [controller performPasteAction: (replacements theOne).
				pos _ controller properSelectionEnds.
				self advanceSelection: controller.
				self nextAction: text with: controller with: (controller selectionStarts > pos).
				^VOID].
	menuDesc _ replacements collect: [:rep {Text} |
			Array 
				with: (rep withoutCRs contractTo: 100) 
				with: rep 
				with: 'Xu: Replace the selection with this, and advance to the next selection'].
	menuDesc _ menuDesc, #(
		-
		('skip'			skip			'Xu: Don''t replace, advance to next selection')
		('abort'		abort			'Xu: Don''t replace')).
	replacements size = 1 ifTrue: [menuDesc _ menuDesc, #(
		('replace all'	replaceAll		'Xu: Do this and all later replacements'))].
	sel _ (PopUpTextMenu parseFromArray: menuDesc) startUpWithHeading: ' Replace the selection? '.
	(sel isKindOf: Text)
		ifTrue: [controller performPasteAction: sel.
				self advanceSelection: controller.
				self nextAction: text with: controller with: false.
				^VOID].
	(sel = 0 or: [sel == nil or: [sel == #abort]])
		ifTrue: [^VOID].
	sel == #skip
		ifTrue: [self advanceSelection: controller.
				self nextAction: text with: controller with: false.
				^VOID].
	sel == #replaceAll
		ifTrue: [controller performPasteAction: (replacements at: 1).
				pos _ controller properSelectionEnds.
				self advanceSelection: controller.
				self nextAction: text with: controller with: (controller selectionStarts > pos).
				^VOID]!

{void} replacement: replacement {String}

	myReplacement _ replacement!

{OrderedCollection of: Text} replacementListIn: text {Text} of: span {Interval}
	
	| result {OrderedCollection of: Text} |
	result _ OrderedCollection new.
	(self replacementsIn: text of: span) do: [:rep {Text} |
		(result includes: rep)
			ifFalse: [result addLast: rep]].
	^result!

{SequenceableCollection of: Text} replacementsIn: text {Text} of: span {Interval}
	
	self isEditAction
		ifFalse: [^#()].
	span ~= (self fetchSelection: text startingAt: span first)
		ifTrue: [^#()].
	^Array with: (self theReplacementIn: text of: span)! !

!MethodAction methodsFor: 'creation'!

create

	myReplacement _ nil! !

!MethodAction methodsFor: 'protected:'!

{Text} theReplacementIn: text {Text} of: span {Interval}
	
	^myReplacement asText allBold! !

!MethodAction methodsFor: 'smalltalk: defaults'!

{void} nextAction: text {Text} with: controller {CodeController}

	^self nextAction: text with: controller with: false! !

!MethodAction methodsFor: 'smalltalk: passe'!

{Text | nil} fetchReplacementIn: text {Text} of: span {Interval}
	
	self passe! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MethodAction class
	instanceVariableNames: ''!



!MethodAction class methodsFor: 'creation'!

{MethodAction | nil} combine: a {MethodAction | nil} with: b {MethodAction | nil}

	a == nil
		ifTrue: [^b].
	b == nil
		ifTrue: [^a].
	^BothAction create: a with: b.! !