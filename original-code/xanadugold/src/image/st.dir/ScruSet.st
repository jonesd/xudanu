'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:00:36 pm'!

Heaper subclass: #ScruSet
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Collection-Sets'!
ScruSet comment:
'X++ has three basic kinds of collection classes.  Tables, Sets and XuRegions.  XuRegions are not-necessarily-discrete collections of positions, and are documented in the space module.  Sets and Tables are both discrete and finite, and similar in many ways.  Both originate in a three-way type distinction between:
	
	ScruX  --  The protocol for examining one.  I.e., it is *Scru*table
		ImmuX  --  The contract guarantees that the set or table you''re looking at won''t change (though the things it contains may change)
		MuX  --  Additional protocol for changing it.
		
	Concrete classes may be a subclass of any of the above.  It makes sense to have a concrete subclass of ScruX which isn''t a subclass of either MuX or ImmuX when, for example, it represents a tracking, filtered view of some other set which is itself changing.  All kinds of collection can be iterated over when appropriate using Steppers--our basic iteration abstraction (see Stepper).
	
	Immu''s are sort of like Stamps -- they represent a particular state a colection can have.  Mu''s are sort of like Berts -- they represent a continuing collection identity which can change its current state.
	
	Sets are pure collections--their contents are just a set of Heapers.  Sets (as opposed to tables) do not provide any organization of these contents.'!

(ScruSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!ScruSet methodsFor: 'testing'!

{UInt32} actualHashForEqual
	self subclassResponsibility!

{BooleanVar} contentsEqual: other {ScruSet}
	"Returns whether the two ScruSets have exactly the same set of elements at the moment.
	'a->contentsEqual(b)' is equivalent to 
	'a->asImmuSet()->isEqual(b->asImmuSet())'."
	
	other count ~= self count ifTrue: [^false].
	other stepper forEach: [ :each {Heaper} |
		(self hasMember: each) ifFalse: [^false]].
	^true!

{UInt32} contentsHash
	"Has the same relationship to contentsEqual that hashForEqual has to isEqual. 
	I.e., if 'a->contentsEqual (b)', then 'a->contentsHash() == b->contentsHash()'. 
	The same complex caveats apply as to the stability and portability of the 
	hash values as apply for hashForEqual."

	| result {UInt32} |
	result _ UInt32Zero.
	self stepper forEach: [ :each {Heaper} |
		result _ result bitXor: each hashForEqual].
	^result!

{BooleanVar} hasMember: someone {Heaper}
	"Is someone a member of the set now?"
	self subclassResponsibility!

{BooleanVar} intersects: other {ScruSet}
	"tell whether they have any points in common"

	"subclasses can override for efficiency"
	other isEmpty ifTrue: [ ^ false ].
	self count > other count
		ifTrue: [^other intersects: self].
	self stepper forEach: [:mem {Heaper} |
		(other hasMember: mem) ifTrue: [^true]].
	^false!

{BooleanVar} isEmpty
	"Whether it currently has any elements"
	self subclassResponsibility!

{BooleanVar} isEqual: other {Heaper}

	self subclassResponsibility!

{BooleanVar} isSubsetOf: another {ScruSet} 
	"Whether another currently has all my elements"
	self stepper forEach: 
		[:elem {Heaper} | 
		(another hasMember: elem) ifFalse: [^false]].
	^true! !

!ScruSet methodsFor: 'creation'!

{ScruSet} copy
	"A new one whose initial state is my current state, but that doesn't track 
	changes. Note that there is no implication that these can be 'destroy'ed 
	separately, because (for example) an ImmuSet just returns itself"

	self subclassResponsibility! !

!ScruSet methodsFor: 'conversion'!

{PtrArray} asArray
	"The elements in the set in an array, in some random order"
	
	| result {PtrArray} mine {Stepper} |
	self thingToDo. "make this faster"
	result := PtrArray nulls: self count DOTasLong.
	mine := self stepper.
	Int32Zero almostTo: result count do: [ :index {Int32} |
		result at: index store: mine fetch.
		mine step].
	mine destroy.
	^result!

{ImmuSet} asImmuSet
	"Return an immu snapshot of my current state. Should probably be done with a 
	Converter rather than with a message (for the reasons listed in the Converter 
	class comment). In terms of the Stamp/Bert analogy mentioned in the class 
	comment, asImmuSet is like asking for the current Stamp."

	self subclassResponsibility!

{MuSet} asMuSet
	"Return a Mu whose initial state is the same as my current state, but which 
	will now deviate independently of me. In terms of the Stamp/Bert analogy 
	mentioned in the class comment, asMuSet is like asking for a new Bert starting 
	on the current Stamp."

	self subclassResponsibility! !

!ScruSet methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name.
	self
		printOnWithSimpleSyntax: oo
		with: '{'
		with: ', '
		with: '}'!

{void} printOnWithSimpleSyntax: oo {ostream reference} 
	with: open {char star} 
	with: sep {char star} 
	with: close {char star} 
	
	self printOnWithSyntax: oo with: open with: sep with: close with: false!

{void} printOnWithSyntax: oo {ostream reference} 
	with: open {char star} 
	with: sep {char star} 
	with: close {char star}
	with: fullPrint {BooleanVar default: false}
	"For example, if we have the set '{a, b, c}' and we print it with 
	'p->printOnWithSyntax(oo, ""<<"", ""; "", "">>"");', we get '<<a; b; c>>'.  This is a convenient little hack
	for printing with all sorts of separators and brackets."
	
	| dSet {Stepper} elemCount {IntegerVar} printMore {BooleanVar} |
	printMore _ fullPrint not.
	elemCount _ IntegerVar0.
	oo << open.
	self isEmpty
		ifTrue: [oo << 'nullSet']
		ifFalse: 
			[dSet _ self stepper.
			[dSet hasValue and: [printMore]]
				whileTrue: 
					[oo << dSet fetch.
					dSet step.
					dSet hasValue ifTrue: [oo << sep].
					(printMore and: [(elemCount _ elemCount + 1) > 200])
						ifTrue: [printMore _ false]]].
	(printMore not and: [dSet hasValue])
		ifTrue: [oo << 'etc...'].
	oo << close! !

!ScruSet methodsFor: 'enumerating'!

{IntegerVar} count
	"How many elements are currently in the set.  Being a set, if the same element is put into the set twice,
	it is only in the set once.  'Same' above is according to 'isEqual'."
	self subclassResponsibility!

{Stepper} stepper
	"Returns a stepper which will enumerate all the elements of the set in some unspecified order"
	self subclassResponsibility!

{Heaper} theOne
	"Iff I contain exactly one member, return it.  Otherwise BLAST.
	The idea for this message is taken from the THE function of ONTIC
	(reference McAllester)"

	| stepper {Stepper} result {Heaper} |
	self count ~= 1 ifTrue:
		[ Heaper BLAST: #NotOneElement ].
	stepper _ self stepper.
	result _ stepper fetch.
	stepper destroy.
	^ result! !

!ScruSet methodsFor: 'private: smalltalk: private'!

{void} inspect
	^InspectorView open: (Sensor leftShiftDown ifTrue: [Inspector inspect: self] ifFalse: [SetInspector inspect: self])! !

!ScruSet methodsFor: 'smalltalk: conversion'!

asOrderedCollection
	"return all of my elements in an ordered collection for smalltalk MVC hacking"

	| result {OrderedCollection} stomp {Stepper} |
	result _ OrderedCollection new: self count.
	stomp _ self stepper.
	[stomp hasValue]
		whileTrue: [result add: stomp get.
			stomp step].
	^result
	"| result {SortedCollection} stomp {Stepper} |
	result _ SortedCollection new: self count.
	stomp _ self stepper.
	[stomp hasValue]
		whileTrue: [result add: stomp get.
			stomp step].
	^result asOrderedCollection"!

{void} do: aBlock {BlockClosure of: Heaper}

	self stepper forEach: aBlock! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

ScruSet class
	instanceVariableNames: ''!

(ScruSet getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!ScruSet class methodsFor: 'exceptions: exceptions'!

problems.NotInSet
	^self signals: #(NotInSet)! !