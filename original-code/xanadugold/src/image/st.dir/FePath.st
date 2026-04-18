'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:33 pm'!

FeWrapper subclass: #FePath
	instanceVariableNames: ''
	classVariableNames: 'ThePathSpec {FeWrapperSpec} '
	poolDictionaries: ''
	category: 'Xanadu-nlinks'!
FePath comment:
'A sequence of Labels, used for context information in a LinkEnd.'!

(FePath getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FePath methodsFor: 'smalltalk: passe'!

{FeLabel} first
	"The first label in the sequence"
	self passe.
	^(self edition get: IntegerZero) cast: FeLabel!

{FeEdition} replace: container {FeEdition}
	with: contained {FeRangeElement}
	with: index {IntegerVar}
	with: count {IntegerVar}
	"Replace what is in the container at my path after index with contained."
	
	| labels {XnRegion} |
	index = count ifTrue: [^contained cast: FeEdition].
	labels := container positionsLabelled: ((self edition get: index integer) cast: FeLabel).
	^container with: labels theOne
		with: (self replace: ((container get: labels theOne) cast: FeEdition)
			with: contained
			with: index + 1
			with: count)!

{FeEdition} replaceIn: container {FeEdition} with: value {FeRangeElement}
	"Replace whatever is at this path in the container with the newValue. Fail if at any point there is not precisely one choice."
	
	self passe.
	^self replace: container with: value with: IntegerVarZero with: self edition count!

{FePath} rest
	"The remaining path after the first label in the sequence"
	self passe.
	^(FePath construct: (self edition
		transformedBy: ((IntegerMapping make: -1)
			restrict: (IntegerRegion after: 1)))) cast: FePath!

{FePath} withFirst: label {FeLabel}
	"Append it to the beginning of the path"
	self passe.
	^(FePath construct: ((self edition
			transformedBy: ((IntegerMapping make: 1)
				restrict: (IntegerRegion after: 1)))
		with: IntegerZero with: label)) cast: FePath!

{FePath} withLast: label {FeLabel}
	"Append it to the end of the path"
	self passe.
	^(FePath construct: (self edition
		with: self edition count with: label)) cast: FePath! !

!FePath methodsFor: 'operations'!

{FeRangeElement CLIENT} follow: edition {FeEdition}
	"Follow a path down into an Edition and return what is at the end of the path. Fail if at any point there is not precisely one choice."
	
	| result {FeRangeElement} label {FeLabel} |
	result := edition.
	IntegerVarZero almostTo: self edition count do: [ :index {IntegerVar} |
		label := (self edition get: index integer) cast: FeLabel.
		result := (result cast: FeEdition) get: ((result cast: FeEdition) positionsLabelled: label) theOne].
	^result! !

!FePath methodsFor: 'private: create'!

create: edition {FeEdition} with: spec {FeWrapperSpec}

	super create: edition with: spec! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FePath class
	instanceVariableNames: ''!

(FePath getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #CONCRETE; yourself)!

!FePath class methodsFor: 'pseudo constructors'!

{FePath CLIENT} make: labels {PtrArray of: FeLabel}

	^(self spec wrap: (FeEdition fromArray: labels)) cast: FePath!

{FeWrapperSpec} spec

	^ThePathSpec! !

!FePath class methodsFor: 'private: wrapping'!

{BooleanVar} check: edition {FeEdition}
	
	Ravi thingToDo. "check that there are only labels here"
	^(edition domain isKindOf: IntegerRegion)
		and: [(edition domain cast: IntegerRegion) isCompacted
		"and: [((edition zoneOf: FeLabel spec) domain
			isEqual: edition domain)]"]!

{FePath} construct: edition {FeEdition}
	
	self spec endorse: edition.
	^(self makeWrapper: edition) cast: FePath!

{FeWrapper} makeWrapper: edition {FeEdition}
	
	^self create: edition with: self spec!

{void} setSpec: wrap {FeWrapperSpec}

	ThePathSpec := wrap.! !

!FePath class methodsFor: 'smalltalk: init'!

initTimeNonInherited

	FeWrapperSpec DIRECTWRAPPER: 'Path'
		with: 'Wrapper'
		with: #FePath.!

linkTimeNonInherited

	ThePathSpec := NULL.! !

!FePath class methodsFor: 'smalltalk: system'!

info.stProtocol
"{FeRangeElement CLIENT} follow: edition {FeEdition}
"! !