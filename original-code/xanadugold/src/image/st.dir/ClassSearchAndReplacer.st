'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:26 pm'!

BrowserGenerator subclass: #ClassSearchAndReplacer
	instanceVariableNames: '
		myChangeTable {IdentityDictionary of: Symbol with: Symbol}
		myNextStage {Symbol}'
	classVariableNames: 'TheClassSearchAndReplacer {ClassSearchAndReplacer} '
	poolDictionaries: ''
	category: 'Tools-Browser-Actions'!



!ClassSearchAndReplacer methodsFor: 'creation'!

create: changes {IdentityDictionary of: Symbol with: Symbol}

	super create.
	myChangeTable _ changes.
	myNextStage _ #renameClasses.!

create: changes {IdentityDictionary of: Symbol with: Symbol} with: nextStage

	super create.
	myChangeTable _ changes.
	myNextStage _ nextStage.! !

!ClassSearchAndReplacer methodsFor: 'protected: testing'!

{Collection of: Symbol} definedRange
	"That part of the range which already seem to exist in the system"

	^myChangeTable asOrderedCollection select: [:rangeEl {Symbol} |
		Smalltalk includesKey: rangeEl]!

{Collection of: Symbol} domainRangeConflicts

	^myChangeTable asOrderedCollection select: [:rangeEl {Symbol} |
		myChangeTable includesKey: rangeEl]!

{Collection of: Symbol} undefinedDomain
	"That part of the domain which isn't a class name"

	^myChangeTable keys select: [:domEl {Symbol} |
		(Smalltalk includesKey: domEl) not 
		 or: [((Smalltalk at: domEl) isKindOf: Class) not
		 or: [(Smalltalk at: domEl) name ~~ domEl]]]! !

!ClassSearchAndReplacer methodsFor: 'accessing'!

{String} changeDesc
	"ClassSearchAndReplacer shared changeDesc"

	^String streamContents: [ :oo |
		oo << 'ClassSearchAndReplacer shared changeFromDesc: #('; crtab.
		myChangeTable keys asSortedCollection do: [:k |
			oo << '(' << k << ' ' << (myChangeTable at: k) << ')'.
			oo crtab].
		oo cr; << ')'; cr].!

{String} changeFromAttr: attr {Symbol}
	"ClassSearchAndReplacer shared changeFromAttr: #ON.CLIENT"

	Smalltalk allClassesDo: [:cls {Class} |
		| cxc {CxxClassDescription | nil} |
		cxc := cls fetchCxxClassDescription.
		(cxc ~~ nil and: [cxc includesAttribute: attr]) ifTrue:
			[myChangeTable at: cls name put: cls name]]!

{String} changeFromDesc: desc {Array of: (Array of: Symbol with: Symbol)}
	
	myChangeTable := Dictionary new.
	desc do: [:ass {Array of: Symbol with: Symbol} |
		myChangeTable at: (ass at: 1) put: (ass at: 2)]!

{String} changeFromPattern: pattern {String}
	"ClassSearchAndReplacer shared changeFromPattern: 'Xu*'"

	Smalltalk allClassesDo: [:cls {Class} |
		(pattern match: cls name) ifTrue:
			[myChangeTable at: cls name put: cls name]]!

{IdentityDictionary of: Symbol with: Symbol} changes
	"Note: it is *intended* that clients be able to modify this in place"

	^myChangeTable!

{BooleanVar} hasNextBrowser

	^myNextStage ~~ nil! !

!ClassSearchAndReplacer methodsFor: 'testing'!

{void} check

	self domainRangeConflicts isEmpty assert.
	self definedRange isEmpty assert. 
	self undefinedDomain isEmpty assert.! !

!ClassSearchAndReplacer methodsFor: 'protected: action'!

{void} renameClasses
	"ClassSearchAndReplacer shared renameClasses"
	"ActualOrglRoot getCxxClassDescription changeTypeRefs: ClassSearchAndReplacer shared changes"
	
	self check.
	(self confirm: 'Rename the classes?') ifTrue:
		[myChangeTable keyValuesDo: [:k :v |
			(Smalltalk at: k) rename: v]].
	Smalltalk flushClassNameCache.
	(self confirm: 'Change the inst/class/class-inst var declarations?') ifTrue:
		[Smalltalk allClassesDo: [:cls {Class} |
			| cxc {CxxClassDescription | nil} |
			cxc := cls fetchCxxClassDescription.
			cxc ~~ nil ifTrue:
				[cxc changeTypeRefs: myChangeTable]]].
	myNextStage := nil.
	(self confirm: 'change the methods?') ifTrue:
		[(BatchTokenFilter make: myChangeTable) browse]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ClassSearchAndReplacer class
	instanceVariableNames: ''!



!ClassSearchAndReplacer class methodsFor: 'protected:'!

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

!ClassSearchAndReplacer class methodsFor: 'creation'!

shared
	"ClassSearchAndReplacer shared"
	
	TheClassSearchAndReplacer == nil
		ifTrue: [TheClassSearchAndReplacer _ self create: Dictionary new].
	^TheClassSearchAndReplacer!

shared: sAndR
	"ClassSearchAndReplacer shared: nil"

	TheClassSearchAndReplacer _ sAndR! !