'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:19 pm'!

FeWrapperSpec subclass: #FeAbstractWrapperSpec
	instanceVariableNames: 'myConcreteSpecs {PtrArray of: FeConcreteWrapperSpec}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-wrapper'!

(FeAbstractWrapperSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FeAbstractWrapperSpec methodsFor: 'accessing'!

{BooleanVar} certify: edition {FeEdition}

	Int32Zero almostTo: myConcreteSpecs count do: [ :i {Int32} |
		(((myConcreteSpecs fetch: i) cast: FeConcreteWrapperSpec)
				certify: edition) ifTrue:
			[^true]].
	^false!

{void} setupConcreteSubSpec: spec {FeConcreteWrapperSpec}
	"Add a new concrete spec to the list, keeping it topologically sorted so that if A wraps B, A precedes B"
	
	| pos {Int32} copy {PtrArray of: FeConcreteWrapperSpec} |
	"remember its endorsements"
	self addToFilter: spec endorsements.
	"Look for the last wrapper in the array that can wrap this one"
	pos := myConcreteSpecs count.
	[(pos <= Int32Zero or: [((myConcreteSpecs fetch: pos - 1) cast: FeConcreteWrapperSpec) wraps: spec]) not]
		whileTrue:
			[pos := pos - 1].
	"Make a copy and insert it just after that one"
	copy := (myConcreteSpecs copyGrow:1) cast: PtrArray.
	copy count - 1 downTo: pos + 1 do: [ :j {Int32} |
		copy at: j store: (copy fetch: j - 1)].
	copy at: pos store: spec.
	myConcreteSpecs := copy.
	"Recur upwards to add the spec to my parent"
	self setup.
	self fetchSuperSpec ~~ NULL ifTrue:
		[self fetchSuperSpec setupConcreteSubSpec: spec]! !

!FeAbstractWrapperSpec methodsFor: 'create'!

create: def {FeAbstractWrapperDef}
	super create: def.
	myConcreteSpecs := PtrArray empty! !

!FeAbstractWrapperSpec methodsFor: 'for wrappers only'!

{void} endorse: edition {FeEdition unused}

	Heaper BLAST: #MustBeConcreteWrapperSpec! !

!FeAbstractWrapperSpec methodsFor: 'vulnerable'!

{FeWrapper | NULL} fetchWrap: edition {FeEdition}

	| sub {FeConcreteWrapperSpec} result {FeWrapper} |
	Ravi thingToDo. "BLAST if there is an ambiguity; right now the only possible one is between an empty Path and and an empty Text"
	"If there are any endorsements that match mine, pick a concrete type that isn't wrapped by anything else"
	sub := NULL.
	(edition endorsements intersect: self endorsements) stepper forEach:
		[ :end {Tuple} | | other {FeConcreteWrapperSpec} | 
		other := (FeWrapperSpec getFromEndorsement: end) cast: FeConcreteWrapperSpec.
		(sub == NULL or: [other wraps: sub]) ifTrue:
			[sub := other]].
	sub ~~ NULL ifTrue:
		[^sub fetchWrap: edition].
	"There are no endorsements. Just walk through the topological sort until you hit one which works"
	Int32Zero almostTo: myConcreteSpecs count do: [ :i {Int32} |
		(myConcreteSpecs fetch: i) cast: FeConcreteWrapperSpec into: [ :spec |
			result := spec fetchWrap: edition.
			result ~~ NULL ifTrue:
				[^result]]].
	^NULL! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeAbstractWrapperSpec class
	instanceVariableNames: ''!

(FeAbstractWrapperSpec getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FeAbstractWrapperSpec class methodsFor: 'pseudo constructors'!

make: def {FeAbstractWrapperDef}

	^self create: def! !