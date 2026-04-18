'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:56 pm'!

Dsp subclass: #SequenceMapping
	instanceVariableNames: '
		myShift {IntegerVar}
		myTranslation {Sequence}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-tumbler'!
SequenceMapping comment:
'Transforms a Sequence by shifting some amount, and then adding another Sequence to it.'!

(SequenceMapping getOrMakeCxxClassDescription)
	friends:
'/* friends for class SequenceDsp */
friend class SequenceSpace;
';
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #COPY; yourself)!

!SequenceMapping methodsFor: 'accessing'!

{CoordinateSpace INLINE} coordinateSpace

	^SequenceSpace make!

{BooleanVar} isIdentity

	^myShift == IntegerVarZero and: [myTranslation isZero]!

{IntegerVar CLIENT INLINE} shift
	"The amount by which it shifts a sequence"
	
	^myShift!

{Sequence CLIENT INLINE} translation
	"What it adds to a sequence after shifting it"
	
	^myTranslation! !

!SequenceMapping methodsFor: 'transforming'!

{Position} inverseOf: position {Position}

	position cast: Sequence into: [ :sequence |
		^(sequence minus: myTranslation) shift: myShift negated].
	^ NULL "compiler fodder"!

{XnRegion} inverseOfAll: reg {XnRegion}

	Ravi thingToDo. "make this more efficient"
	^self inverse ofAll: reg!

{Position} of: position {Position}

	position cast: Sequence into: [ :sequence |
		^(sequence shift: myShift) plus: myTranslation].
	^ NULL "compiler fodder"!

{XnRegion} ofAll: reg {XnRegion}

	reg cast: SequenceRegion into: [ :seq |
		| edges {PtrArray of: SequenceEdge} newEdges {PtrArray of: SequenceEdge} |
		edges := seq secretTransitions.
		newEdges := PtrArray nulls: edges count.
		Int32Zero almostTo: edges count do: [ :i {Int32} |
			newEdges at: i store: (((edges fetch: i) cast: SequenceEdge) transformedBy: self)].
		^SequenceRegion using: seq startsInside with: newEdges].
	^NULL "fodder"! !

!SequenceMapping methodsFor: 'combining'!

{Dsp} compose: dsp {Dsp}
	"Return the composition of the two Dsps. Two Dsps of the same space are always composable.
	(a->compose(b) ->minus(b))->isEqual (a)
	(a->compose(b) ->of(pos))->isEqual (a->of (b->of (pos))"

	dsp cast: SequenceMapping into: [ :other {SequenceMapping} |
		^SequenceMapping make: myShift + other shift
			with: ((self of: other translation) cast: Sequence)].
	^ NULL "compiler fodder"!

{Mapping} inverse

	^SequenceMapping make: myShift negated
		with: ((Sequence zero minus: myTranslation) shift: myShift)!

{Dsp} inverseCompose: dsp {Dsp}

	dsp cast: SequenceMapping into: [ :other |
		^SequenceMapping make: myShift - other shift
			with: ((self inverseOf: other translation) cast: Sequence)].
	^ NULL "compiler fodder"!

{Dsp} minus: dsp {Dsp}

	dsp cast: SequenceMapping into: [ :other |
		^SequenceMapping make: myShift - other shift
			with: ((self inverseOf: other translation) cast: Sequence)].
	^ NULL "compiler fodder"! !

!SequenceMapping methodsFor: 'private: create'!

create: shift {IntegerVar} with: translation {Sequence}

	super create.
	myShift := shift.
	myTranslation := translation.! !

!SequenceMapping methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myShift _ receiver receiveIntegerVar.
	myTranslation _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendIntegerVar: myShift.
	xmtr sendHeaper: myTranslation.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SequenceMapping class
	instanceVariableNames: ''!

(SequenceMapping getOrMakeCxxClassDescription)
	friends:
'/* friends for class SequenceDsp */
friend class SequenceSpace;
';
	attributes: ((Set new) add: #CONCRETE; add: #ON.CLIENT; add: #COPY; yourself)!

!SequenceMapping class methodsFor: 'private: pseudo constructors'!

make: shift {IntegerVar} with: translation {Sequence}

	^self create: shift with: translation! !

!SequenceMapping class methodsFor: 'smalltalk: system'!

info.stProtocol
"{IntegerVar CLIENT} shift
{Sequence CLIENT} translation
"! !