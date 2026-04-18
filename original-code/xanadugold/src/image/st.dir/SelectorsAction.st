'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:50:31 pm'!

ParsingAction subclass: #SelectorsAction
	instanceVariableNames: 'myChangeTable {IdentityDictionary of: Symbol with: Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tools-Browser-Actions'!



!SelectorsAction methodsFor: 'create:'!

create: changes {IdentityDictionary of: Symbol with: Symbol}

	super create.
	myChangeTable _ changes! !

!SelectorsAction methodsFor: 'accessing'!

{BooleanVar} isEditAction

	super isEditAction
		ifTrue: [^true].
		
	myChangeTable keyValuesDo: [:k :v |
		k ~~ v
			ifTrue: [^true]].
	^false!

{SequenceableCollection of: Text} replacementsIn: text {Text} of: span {Interval}
	
	| node {ProgramNode} result sel rep |
	node _ self fetchNodeIn: text at: span.
	node == nil
		ifTrue: [^#()].
	sel _ myChangeTable at: node selector.
	sel == node selector
		ifTrue: [result _ #()]
		ifFalse: [result _ Array with: (self theReplacementIn: text of: span using: sel)].
	
	(myReplacement ~~ nil 
	 and: [(rep _ myReplacement asSymbol) ~~ node selector
	 and: [rep numArgs = node selector numArgs]])
	 	ifTrue: [result _ result, (Array with: (self theReplacementIn: text of: span using: rep))].
	^result! !

!SelectorsAction methodsFor: 'protected:'!

{Text} theReplacementIn: text {Text} of: span {Interval} using: sel {Symbol}

	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SelectorsAction class
	instanceVariableNames: ''!



!SelectorsAction class methodsFor: 'metamorphic creation'!

make.IdentityDictionary: changes {IdentityDictionary of: Symbol with: Symbol}

	^self create: changes!

make.SequenceableCollection: coll {SequenceableCollection of: (Array of: Symbol with: Symbol)}
	
	| changes {IdentityDictionary of: Symbol with: Symbol} |
	changes _ IdentityDictionary new.
	coll do: [:array {Array of: Symbol with: Symbol} |
		(changes includesKey: (array at: 1))
			ifTrue: [self error: 'conflict'].
		changes at: (array at: 1) put: (array at: 2)].
	^self make.IdentityDictionary: changes! !

!SelectorsAction class methodsFor: 'smalltalk: metamorphic defaults'!

make: t

	(t isKindOf: IdentityDictionary)
		ifTrue: [^self make.IdentityDictionary: t].
	^self make.SequenceableCollection: (t cast: SequenceableCollection)! !