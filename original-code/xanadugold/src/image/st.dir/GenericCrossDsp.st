'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:46 pm'!

CrossMapping subclass: #GenericCrossDsp
	instanceVariableNames: '
		mySpace {CrossSpace}
		mySubDsps {PtrArray of: Dsp}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cross'!
GenericCrossDsp comment:
' Was NOT.A.TYPE but that obstructed compilation.'!

(GenericCrossDsp getOrMakeCxxClassDescription)
	friends:
'friend class GenericCrossSpace;
';
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!GenericCrossDsp methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	
	^mySpace!

{BooleanVar} isIdentity
	
	Int32Zero almostTo: mySubDsps count do: [:i {Int32} |
		(self subMapping: i) isIdentity ifFalse:
			[^false]].
	^true!

{Dsp} subMapping: index {Int32}

	^(mySubDsps fetch: index) cast: Dsp!

{PtrArray of: Dsp} subMappings

	^mySubDsps copy cast: PtrArray! !

!GenericCrossDsp methodsFor: 'private: creation'!

create: space {CrossSpace} with: subDsps {PtrArray of: Dsp}
	
	super create.
	mySpace := space.
	mySubDsps := subDsps! !

!GenericCrossDsp methodsFor: 'transforming'!

{Position} inverseOf: position {Position}

	position cast: ActualTuple into: [ :tuple | | result {PtrArray of: Position} |
		result := PtrArray nulls: tuple count.
		Int32Zero almostTo: tuple count do: [ :dimension {Int32} |
			result at: dimension
				store: ((self subMapping: dimension) inverseOf: (tuple positionAt: dimension))].
		^ActualTuple make: result].
	^ NULL "compiler fodder"!

{XnRegion} inverseOfAll: region {XnRegion}
	
	region cast: GenericCrossRegion into:
		[ :cross | | result {BoxAccumulator} boxes {BoxStepper} |
		result := BoxAccumulator make: mySpace with: cross boxCount.
		boxes := cross boxStepper.
		[boxes hasValue] whileTrue:
			[result addInverseTransformedBox: boxes with: self.
			boxes step].
		^result region].
	^ NULL "compiler fodder"!

{Position} of: position {Position}

	position cast: ActualTuple into: [ :tuple | | result {PtrArray of: Position} |
		result := PtrArray nulls: tuple count.
		Int32Zero almostTo: tuple count do: [ :dimension {Int32} |
			result at: dimension
				store: ((self subMapping: dimension) of: (tuple positionAt: dimension))].
		^ActualTuple make: result].
	^ NULL "compiler fodder"!

{XnRegion} ofAll: region {XnRegion}
	
	region cast: GenericCrossRegion into:
		[ :cross | | result {BoxAccumulator} boxes {BoxStepper} |
		result := BoxAccumulator make: mySpace with: cross boxCount.
		boxes := cross boxStepper.
		[boxes hasValue] whileTrue:
			[result addTransformedBox: boxes with: self.
			boxes step].
		^result region].
	^ NULL "compiler fodder"! !

!GenericCrossDsp methodsFor: 'combining'!

{Dsp} compose: other {Dsp}
	
	| newSubDsps {PtrArray of: Dsp} |
	newSubDsps := PtrArray nulls: mySubDsps count.
	other cast: CrossMapping into: [ :cross |
		Int32Zero almostTo: newSubDsps count do: [ :dimension {Int32} |
			newSubDsps at: dimension
				store: ((self subMapping: dimension) compose: (cross subMapping: dimension))].
		^GenericCrossDsp make: mySpace with: newSubDsps].
	^ NULL "compiler fodder"!

{Mapping} inverse
	
	| newSubDsps {PtrArray of: Dsp} |
	newSubDsps := PtrArray nulls: mySubDsps count.
	Int32Zero almostTo: newSubDsps count do: [ :dimension {Int32} |
		newSubDsps at: dimension
			store: ((self subMapping: dimension) inverse cast: Dsp)].
	^GenericCrossDsp create: mySpace with: newSubDsps!

{Dsp} inverseCompose: other {Dsp}
	
	| newSubDsps {PtrArray of: Dsp} |
	newSubDsps := PtrArray nulls: mySubDsps count.
	other cast: CrossMapping into: [ :cross |
		Int32Zero almostTo: newSubDsps count do: [ :dimension {Int32} |
			newSubDsps at: dimension
				store: ((self subMapping: dimension) inverseCompose: (cross subMapping: dimension))].
		^GenericCrossDsp make: mySpace with: newSubDsps].
	^ NULL "compiler fodder"!

{Dsp} minus: other {Dsp}
	
	| newSubDsps {PtrArray of: Dsp} |
	newSubDsps := PtrArray nulls: mySubDsps count.
	other cast: CrossMapping into: [ :cross |
		Int32Zero almostTo: newSubDsps count do: [ :dimension {Int32} |
			newSubDsps at: dimension
				store: ((self subMapping: dimension) minus: (cross subMapping: dimension))].
		^GenericCrossDsp make: mySpace with: newSubDsps].
	^ NULL "compiler fodder"! !

!GenericCrossDsp methodsFor: 'private: accessing'!

{PtrArray of: Dsp} secretSubDsps
	"The actual array of sub Dsps. DO NOT MODIFY"
	
	^mySubDsps! !

!GenericCrossDsp methodsFor: 'testing'!

{UInt32} actualHashForEqual

	^(mySpace hashForEqual
		bitXor: mySubDsps contentsHash)
		bitXor: self getCategory hashForEqual!

{BooleanVar} isEqual: other {Heaper}

	other cast: GenericCrossDsp into: [ :cross |
		^mySubDsps contentsEqual: cross secretSubDsps]
	others:
		[^false].
	^ false "compiler fodder"! !

!GenericCrossDsp methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	mySpace _ receiver receiveHeaper.
	mySubDsps _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: mySpace.
	xmtr sendHeaper: mySubDsps.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

GenericCrossDsp class
	instanceVariableNames: ''!

(GenericCrossDsp getOrMakeCxxClassDescription)
	friends:
'friend class GenericCrossSpace;
';
	attributes: ((Set new) add: #CONCRETE; add: #COPY; yourself)!

!GenericCrossDsp class methodsFor: 'smalltalk: defaults'!

make: space

	^self make: space with: NULL! !

!GenericCrossDsp class methodsFor: 'private: pseudoconstructors'!

{GenericCrossDsp} identity: space {GenericCrossSpace}
	with: subSpaces {PtrArray of: CoordinateSpace}
	"Only used during construction; must pass the array in explicitly since the space isnt initialized yet"

	| result {PtrArray of: Dsp} |
	result := PtrArray nulls: subSpaces count.
	Int32Zero almostTo: result count do: [ :dimension {Int32} |
		result at: dimension store: ((subSpaces fetch: dimension) cast: CoordinateSpace) identityDsp].
	^self create: space with: result! !