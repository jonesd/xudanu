'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:23 pm'!

FeWrapper subclass: #FeText
	instanceVariableNames: ''
	classVariableNames: 'TheTextSpec {FeWrapperSpec} '
	poolDictionaries: ''
	category: 'Xanadu-wrapper'!
FeText comment:
'Handles a integer-indexed, contiguous, zero-based Edition of RangeElements'!

(FeText getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeText methodsFor: 'text manipulation'!

{FeEdition CLIENT} contents
	"The Edition of the actual contents, without any style information. You should use this instead of edition() when you want to get the Edition for comparisons, queries, etc. Future styled text implementations will not store the contents as directly as we do now."
	
	^self edition!

{IntegerVar CLIENT} count
	"The number of elements in the string"
	
	^self edition count!

{FeText CLIENT} extract: region {IntegerRegion}
	"All the text lying within the region, with the gaps compressed out."
	
	^FeText construct: (self edition
		transformedBy: ((region intersect: self edition domain) cast: IntegerRegion) compactor)!

{FeText CLIENT} insert: position {IntegerVar} with: text {FeText}
	"Insert new information into the Edition at the given point, pushing everything after it forward."
	
	self validate: position.
	^FeText construct: ((text edition
			transformedBy: (IntegerMapping make: position))
		combine: (self edition
			transformedBy: ((IntegerMapping make
					restrict: (IntegerRegion before: position))
				combine: ((IntegerMapping make: text count)
					restrict: (IntegerRegion after: position)))))!

{FeText CLIENT} move: pos {IntegerVar} with: region {IntegerRegion}
	"Insert a virtual copy of the region of text before the given position, and remove it from its current location. If the position is one past the last character, then it will be inserted after the end. If the region is discontiguous, then the contiguous pieces are concatenated together, in sequence, and inserted."

	| moved {IntegerRegion} left {IntegerRegion} |
	self validate: pos.
	moved := (self edition domain intersect: region) cast: IntegerRegion.
	left := (self edition domain minus: region) cast: IntegerRegion.
	^FeText construct: (self edition
			transformedBy: ((((left intersect: (IntegerRegion before: pos)) cast: IntegerRegion)
					compactor
				combine: (moved compactor transformedBy: (IntegerMapping make: pos)))
				combine: (((left intersect: (IntegerRegion after: pos)) cast: IntegerRegion)
						compactor
					transformedBy: (IntegerMapping make: (moved
							unionWith: (IntegerRegion make: IntegerVar0 with: pos))
						count))))!

{FeText CLIENT} replace: dest {IntegerRegion} with: other {FeText}
	"Replaces a region of text with a virtual copy of text from another document.
	If the destination region lies to the left of the domain, inserts before the beginning; if it intersects the domain, insert at the first common position; if it lies after the end, insert after the end. Fails with
		BLAST(AmbiguousReplacement) if the region is empty.
	May be used to copy information within a single document.
	This operation may not be particularly useful with non-simple destination regions."	
	
	| to {IntegerVar} |
	((IntegerRegion before: IntegerVar0) intersects: dest) ifTrue:
		[to := IntegerVar0]
	ifFalse: [(dest intersects: self edition domain) ifTrue:
		[to := ((dest intersect: self edition domain) cast: IntegerRegion) start]
	ifFalse: [((IntegerRegion after: self count) intersects: dest) ifTrue:
		[to := self count]
	ifFalse:
		[Heaper BLAST: #AmbiguousReplacement]]].
	
	self thingToDo. "Do this all in one step"
	^(self extract: (dest complement cast: IntegerRegion)) insert: to with: other! !

!FeText methodsFor: 'private:'!

{void} validate: pos {IntegerVar}
	"Check that information can be inserted at the position. Blast if not."

	(IntegerVar0 <= pos and: [pos <= self count]) ifFalse:
		[Heaper BLAST: #InvalidTextPosition]! !

!FeText methodsFor: 'protected: create'!

create: edition {FeEdition} with: spec {FeWrapperSpec}

	super create: edition with: spec! !

!FeText methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << self getCategory name << '('.
	"(self edition copy: (IntegerRegion before: 100)) retrieve forEach: [ :bundle {FeBundle} |
		bundle cast: FeArrayBundle into: [ :array |
			array array cast: UInt8Array into: [ :chars |
				oo << chars]
			others:
				[UInt32Zero almostTo: array array count do: [ :i {UInt32} |
					oo << (array get: i)]]]
		cast: FeElementBundle into: [ :element |
			]
		cast: FePlaceHolderBundle into: [ :places |
			]].
	(self edition isFinite not or: [self edition count > 100]) ifTrue:
		[oo << '...']."
	oo << self edition. "for now"
	oo << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeText class
	instanceVariableNames: ''!

(FeText getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FeText class methodsFor: 'private: wrapping'!

{BooleanVar} check: edition {FeEdition}

	^(IntegerSpace make isEqual: edition coordinateSpace)
		and: [(edition domain cast: IntegerRegion) isCompacted]!

{FeText} construct: edition {FeEdition}
	"Called from internal code to create and endorse new Editions. Does not check the contents; assumes that it will only be called by trusted code."
	
	self spec endorse: edition.
	^(self makeWrapper: edition) cast: FeText!

{FeWrapper} makeWrapper: edition {FeEdition}
	^self create: edition with: self spec!

{void} setSpec: wrap {FeWrapperSpec}

	TheTextSpec := wrap.! !

!FeText class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	FeWrapperSpec DIRECTWRAPPER: 'Text' with: 'Wrapper' with: #FeText!

linkTimeNonInherited

	TheTextSpec := NULL.! !

!FeText class methodsFor: 'pseudo constructors'!

{FeText CLIENT} make: data {PrimArray default: NULL}

	data == NULL
		ifTrue: [^self construct: (FeEdition empty: IntegerSpace make)]
		ifFalse: [^self construct: (FeEdition fromArray: data)]!

{FeWrapperSpec} spec

	^TheTextSpec! !

!FeText class methodsFor: 'smalltalk: system'!

info.stProtocol
"{FeEdition CLIENT} contents
{IntegerVar CLIENT} count
{FeText CLIENT} extract: region {IntegerRegion}
{FeText CLIENT} insert: position {IntegerVar} with: text {FeText}
{FeText CLIENT} move: pos {IntegerVar} with: region {IntegerRegion}
{FeText CLIENT} replace: dest {IntegerRegion} with: other {FeText}
"! !