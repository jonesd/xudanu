'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:29 pm'!

BrowserGenerator subclass: #MethodSearchAndReplacer
	instanceVariableNames: '
		myChangeTable {IdentityDictionary of: Symbol with: Symbol}
		myNextStage {Symbol}'
	classVariableNames: 'TheMethodSearchAndReplacer {MethodSearchAndReplacer} '
	poolDictionaries: ''
	category: 'Tools-Browser-Actions'!



!MethodSearchAndReplacer methodsFor: 'protected: action'!

{void} changeLiteralsInNew: aBrowser {MethodSetBrowser}
	"In a browser for changing old senders in new methods"
	
	| filter |
	myNextStage _ nil.
	filter _ Replacer 
		make: ((MultiSendersFilter make: myChangeTable keys)
					intersect: (MultiImplementorsFilter make: myChangeTable asSet))
		with: [LiteralsAction make: myChangeTable]
		with: 'Replacing literals of old selectors in implementors of new selectors'.
	filter
		browse: aBrowser methodName 
		with: (filter copiedFilteredList: aBrowser fullMethodList)
		with: (MethodSearchAndReplacer create: myChangeTable with: nil)!

{void} changeLiteralsInOthers: aBrowser {MethodSetBrowser}
	"In a browser for changing old senders in non-new methods"
	
	| filter |
	myNextStage _ nil.
	filter _ Replacer 
		make: ((MultiSendersFilter make: myChangeTable keys)
					intersect: (MultiImplementorsFilter 
									make: (myChangeTable asSet unionWith: myChangeTable keys)) not)
		with: [LiteralsAction make: myChangeTable]
		with: 'Replacing literals of old selectors in other methods'.
	filter
		browse: aBrowser methodName 
		with: (filter copiedFilteredList: aBrowser fullMethodList)
		with: (MethodSearchAndReplacer create: myChangeTable with: nil)!

{void} changePatterns: aBrowser {MethodSetBrowser}
	"In a Browser for making new implementors, 
	after already changing senders & literals and removing the old implementors"
	
	| filter {MethodFilter} pattRepl {MethodFilter} |
	filter _ AllMethods make not.
	myChangeTable keyValuesDo: [:k :v |
		pattRepl _ (StringMatchFilter make: (self class patternFor: k)) 
			withReplacement: (self class patternFor: v).
		filter _ filter unionWith: pattRepl].
	filter browse.!

{void} changeSendsInNew: aBrowser {MethodSetBrowser}
	"In a Browser for making new implementors"
	
	| filter |
	myNextStage _ #changeSendsInOthers:.
	filter _ Replacer 
		make: ((MultiSendersFilter make: myChangeTable keys)
					intersect: (MultiImplementorsFilter make: myChangeTable asSet))
		with: [SendersAction make: myChangeTable]
		with: 'Replacing senders of old selectors in implementors of new selectors'.
	filter
		browse: aBrowser methodName 
		with: (filter copiedFilteredList: aBrowser alternatives) 
		with: (MethodSearchAndReplacer create: myChangeTable with: #changeLiteralsInNew:)!

{void} changeSendsInOthers: aBrowser {MethodSetBrowser}
	"In a Browser for making new implementors, 
	after already changing senders & literals in those new implementors"
	
	| filter |
	myNextStage _ #getSetToRemove:.
	filter _ Replacer 
		make: ((MultiSendersFilter make: myChangeTable keys)
					intersect: (MultiImplementorsFilter 
									make: (myChangeTable asSet unionWith: myChangeTable keys)) not)
		with: [SendersAction make: myChangeTable]
		with: 'Replacing senders of old selectors in other methods'.
	filter
		browse: aBrowser methodName 
		with: nil
		with: (MethodSearchAndReplacer create: myChangeTable with: #changeLiteralsInOthers:)!

{void} getSetToRemove: aBrowser {MethodSetBrowser}
	"In a Browser for making new implementors, 
	after already changing senders & literals"
	
	myNextStage _ #changePatterns:.
	
	(MultiImplementorsFilter make: myChangeTable keys)
		browse: aBrowser methodName
		with: (aBrowser fullMethodList collect: [:rep | rep copy])
		with: (MethodSearchAndReplacer create: myChangeTable with: #removeOldImplementors:)!

{void} makeNewImplementors: aBrowser {MethodSetBrowser default: nil}
	"In some initial browser or nil"
	
	(self confirm: 'Recompute message usage? (what''s sent & implemented)')
		ifTrue: [MessageUsage fresh].
	self staleCheck.
	myNextStage _ nil.
	(MultiImplementorsFilter make: myChangeTable) 
		browse: (aBrowser == nil ifTrue: [nil] ifFalse: [aBrowser methodName])
		with: nil 
		with: (MethodSearchAndReplacer create: myChangeTable with: #changeSendsInNew:)!

{void} removeOldImplementors: aBrowser {MethodSetBrowser}
	"In a Browser for making new implementors, 
	after already changing senders & literals"
	
	aBrowser methodName: aBrowser methodList first.
	(self confirm: 'Remove all implementors of old selectors?')
		ifFalse: [^VOID].
		 
	[aBrowser methodName ~~ nil] 
		whileTrue: [aBrowser removeMethodSilently].
	
	myNextStage _ nil! !

!MethodSearchAndReplacer methodsFor: 'testing'!

{void} staleCheck

	self arityConflicts isEmpty assert.
	self domainRangeConflicts isEmpty assert.
	self staleMentionedRange isEmpty assert. 
	self staleUnmentionedDomain isEmpty assert.! !

!MethodSearchAndReplacer methodsFor: 'creation'!

create: changes {IdentityDictionary of: Symbol with: Symbol}

	super create.
	myChangeTable _ changes.
	myNextStage _ #makeNewImplementors:.!

create: changes {IdentityDictionary of: Symbol with: Symbol} with: nextStage

	super create.
	myChangeTable _ changes.
	myNextStage _ nextStage.! !

!MethodSearchAndReplacer methodsFor: 'protected: testing'!

{Collection of: (Array of: Symbol with: Symbol)} arityConflicts

	| result {OrderedCollection of: Symbol} |
	result _ OrderedCollection new.
	myChangeTable keyValuesDo: [:domEl {Symbol} :rangeEl {Symbol} |
		(domEl numArgs ~= rangeEl numArgs)
			ifTrue: [result add: (Array with: domEl with: rangeEl)]].
	^result!

{Collection of: Symbol} domainRangeConflicts

	^myChangeTable asOrderedCollection select: [:rangeEl {Symbol} |
		myChangeTable includesKey: rangeEl]!

{Collection of: Symbol} staleMentionedRange
	"That part of the range which already seem to exist in the system"

	| mu {MessageUsage} |
	mu _ MessageUsage stale.
	^myChangeTable asOrderedCollection select: [:rangeEl {Symbol} |
		mu isMentioned: rangeEl]!

{Collection of: Symbol} staleUnmentionedDomain
	"That part of the domain which doesn't seem to exist in the system"

	| mu {MessageUsage} |
	mu _ MessageUsage stale.
	^myChangeTable keys select: [:domEl {Symbol} |
		(mu isMentioned: domEl) not]! !

!MethodSearchAndReplacer methodsFor: 'accessing'!

{NOWAIT} browse

	self makeNewImplementors: nil!

{IdentityDictionary of: Symbol with: Symbol} changes
	"Note: it is *intended* that clients be able to modify this in place"

	^myChangeTable!

{BooleanVar} hasNextBrowser

	^myNextStage ~~ nil!

{NOWAIT} nextBrowserFrom: aBrowser {MethodSetBrowser}

	self perform: myNextStage with: aBrowser! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

MethodSearchAndReplacer class
	instanceVariableNames: ''!



!MethodSearchAndReplacer class methodsFor: 'creation'!

shared
	"MethodSearchAndReplacer shared"
	
	TheMethodSearchAndReplacer == nil
		ifTrue: [TheMethodSearchAndReplacer _ self create: #()].
	^TheMethodSearchAndReplacer!

shared: sAndR

	TheMethodSearchAndReplacer _ sAndR! !

!MethodSearchAndReplacer class methodsFor: 'protected:'!

{String} patternFor: sel {Symbol}
	"SearchAndReplacer patternFor: #at:put:"
	"SearchAndReplacer patternFor: #at:"
	"SearchAndReplacer patternFor: #foo"
	"SearchAndReplacer patternFor: #+"

	| result {String} |
	result _ ''.
	sel keywords 
		do: [:part |
				result _ result, part]
		andBetweenDo: [result _ result, '*'].
	^result! !