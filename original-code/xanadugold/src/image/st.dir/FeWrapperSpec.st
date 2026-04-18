'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:24 pm'!

Heaper subclass: #FeWrapperSpec
	instanceVariableNames: '
		myDef {FeWrapperDef}
		myEndorsements {CrossRegion}
		myFilter {Filter}
		mySuperSpec {FeAbstractWrapperSpec | NULL}'
	classVariableNames: '
		TheWrapperDefs {MuTable of: Tumbler with: FeWrapperDef} 
		TheWrapperEndorsements {MuTable of: Tumbler with: CrossRegion} 
		TheWrappersFromEndorsements {MuTable of: Tuple with: FeWrapperSpec} 
		TheWrapperSpecs {MuTable of: Tumbler with: FeWrapperSpec} '
	poolDictionaries: ''
	category: 'Xanadu-wrapper'!
FeWrapperSpec comment:
'Handles wrapping, certification, and filtering for a wrapper type and its subtypes (if there are any)'!

(FeWrapperSpec getOrMakeCxxClassDescription)
	friends:
'/* friends for class FeWrapperSpec */
friend class FeWrapper;
';
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #EQ; yourself)!

!FeWrapperSpec methodsFor: 'accessing'!

{BooleanVar} certify: edition {FeEdition}
	"Whether the Edition passes the invariants of this type so that it could be certified. Always checks the actual contents and endorses if they are acceptable."
	self subclassResponsibility!

{Filter CLIENT} filter
	"A filter which selects for Editions which have been endorsed as belonging to this type."
	
	myFilter == NULL ifTrue:
		[myFilter := CurrentGrandMap fluidGet endorsementFilterSpace emptyRegion cast: Filter].
	^myFilter!

{BooleanVar} isCertified: edition {FeEdition}
	"Whether an Edition is already endorsed as being of this type. Equivalent to
		this->filter ()->match (edition->endorsements ())"
	^self filter match: edition endorsements!

{Sequence CLIENT} name
	"The name for this type"
	
	^myDef name!

{FeWrapper CLIENT} wrap: edition {FeEdition}
	"The Edition wrapped with my type of Wrapper. If it does not have endorsements, will attempt to certify. Blasts if there is more than one valid wrapping."
	
	| result {FeWrapper} |
	result := self fetchWrap: edition.
	result == NULL ifTrue:
		[Heaper BLAST: #CannotWrap].
	^result! !

!FeWrapperSpec methodsFor: 'vulnerable'!

{FeWrapper | NULL} fetchWrap: edition {FeEdition}

	self subclassResponsibility!

{BooleanVar} isSubSpecOf: other {FeWrapperSpec}
	"Whether this is the same as or a kind of the other spec"
	^self == other
		or: [(other isKindOf: FeAbstractWrapperSpec)
			and: [self fetchSuperSpec ~~ NULL
			and: [self fetchSuperSpec isSubSpecOf: other]]]! !

!FeWrapperSpec methodsFor: 'protected:'!

{void} addToFilter: endorsements {CrossRegion}
	"Add some more endorsements to filter for"
	
	myFilter := (self filter
		unionWith: (CurrentGrandMap fluidGet endorsementFilterSpace
			anyFilter: endorsements)) cast: Filter!

{FeWrapperDef} def
	^myDef!

{FeAbstractWrapperSpec | NULL} fetchSuperSpec
	"The immediate supertype, or NULL if this is the generic Wrapper type"
	^mySuperSpec!

{void} setup
	"Do the required setup for this spec in the context of a table of all known specs"
	
	(mySuperSpec == NULL and: [myDef fetchSuperDefName ~~ NULL]) ifTrue:
		[ | end {CrossRegion} |
		mySuperSpec := (FeWrapperSpec get: myDef fetchSuperDefName)
			cast: FeAbstractWrapperSpec.
		myDef setSpec: self.
		end := FeWrapperSpec getEndorsements: self name.
		myEndorsements := (self endorsements unionWith: end) cast: CrossRegion.
		self addToFilter: end].! !

!FeWrapperSpec methodsFor: 'create'!

create: def {FeWrapperDef}
	super create.
	myDef := def.
	myEndorsements := NULL.
	myFilter := NULL.
	mySuperSpec := NULL.! !

!FeWrapperSpec methodsFor: 'for wrappers only'!

{void} endorse: edition {FeEdition}
	"Endorse the Edition as being of this type. Blasts if this is an abstract type.
	Should only be called from the code implementing the type, or code which it trusts. We may eventually add a system to enforce this."
	self subclassResponsibility!

{CrossRegion} endorsements

	myEndorsements == NULL ifTrue:
		[myEndorsements := CurrentGrandMap fluidGet endorsementSpace emptyRegion cast: CrossRegion].
	^myEndorsements! !

!FeWrapperSpec methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeWrapperSpec class
	instanceVariableNames: ''!

(FeWrapperSpec getOrMakeCxxClassDescription)
	friends:
'/* friends for class FeWrapperSpec */
friend class FeWrapper;
';
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #EQ; yourself)!

!FeWrapperSpec class methodsFor: 'smalltalk: macros:'!

ABSTRACTWRAPPER: wrapperName {char star} with: superName {char star | NULL} with: className {Symbol}
	"From a dynamic initializer, register an abstract Wrapper type"
	self REQUIRES: Sequence.
	self REQUIRES: FeWrapperSpec.
	FeWrapperSpec registerAbstract: wrapperName
		with: superName
		with: ((Smalltalk at: className) pointerToStaticMember: #setSpec:)!

DIRECTWRAPPER: wrapperName {char star} with: superName {char star} with: className {Symbol}
	"From a dynamic initializer, register an abstract Wrapper type"
	self REQUIRES: Sequence.
	self REQUIRES: FeWrapperSpec.
	FeWrapperSpec registerDirect: wrapperName
		with: superName
		with: ((Smalltalk at: className) pointerToStaticMember: #makeWrapper:)
		with: ((Smalltalk at: className) pointerToStaticMember: #check:)
		with: ((Smalltalk at: className) pointerToStaticMember: #setSpec:)!

INDIRECTWRAPPER: wrapperName {char star}
	with: superName {char star | NULL}
	with: innerName {char star | NULL}
	with: className {Symbol}
	"From a dynamic initializer, register an abstract Wrapper type"
	self REQUIRES: Sequence.
	self REQUIRES: FeWrapperSpec.
	FeWrapperSpec registerIndirect: wrapperName
		with: superName
		with: innerName
		with: ((Smalltalk at: className) pointerToStaticMember: #makeWrapper:)
		with: ((Smalltalk at: className) pointerToStaticMember: #check:)
		with: ((Smalltalk at: className) pointerToStaticMember: #setSpec:)! !

!FeWrapperSpec class methodsFor: 'registering wrappers'!

{void} registerAbstract: wrapperName {char star}
	with: superName {char star | NULL}
	with: holder {FeWrapperSpecHolder var | NULL}
	
	| wrapper {Sequence} superWrapper {Sequence} |
	wrapper := Sequence string: wrapperName.
	superName == NULL
		ifTrue: [superWrapper := NULL]
		ifFalse: [superWrapper := Sequence string: superName].
	TheWrapperDefs at: wrapper introduce: (FeWrapperDef
		abstract: wrapper with: superWrapper with: holder).!

{void} registerDirect: wrapperName {char star}
	with: superName {char star | NULL}
	with: maker {FeDirectWrapperMaker var}
	with: checker {FeDirectWrapperChecker var}
	with: holder {FeWrapperSpecHolder var}
	
	| wrapper {Sequence} superWrapper {Sequence} |
	wrapper := Sequence string: wrapperName.
	superName == NULL
		ifTrue: [superWrapper := NULL]
		ifFalse: [superWrapper := Sequence string: superName].
	TheWrapperDefs at: wrapper introduce: (FeWrapperDef
		makeDirect: wrapper
		with: superWrapper
		with: holder
		with: maker
		with: checker).!

{void} registerIndirect: wrapperName {char star}
	with: superName {char star | NULL}
	with: innerName {char star | NULL}
	with: maker {FeIndirectWrapperMaker var}
	with: checker {FeIndirectWrapperChecker var}
	with: holder {FeWrapperSpecHolder var}
	
	| wrapper {Sequence} superWrapper {Sequence} innerWrapper {Sequence} |
	wrapper := Sequence string: wrapperName.
	superName == NULL
		ifTrue: [superWrapper := NULL]
		ifFalse: [superWrapper := Sequence string: superName].
	innerName == NULL
		ifTrue: [innerWrapper := NULL]
		ifFalse: [innerWrapper := Sequence string: innerName].
	TheWrapperDefs at: wrapper introduce: (FeWrapperDef
		makeIndirect: wrapper
		with: superWrapper
		with: holder
		with: innerWrapper
		with: maker
		with: checker).! !

!FeWrapperSpec class methodsFor: 'exceptions: exceptions'!

problems.WrapFailure

	^self signals: #(CannotWrap)! !

!FeWrapperSpec class methodsFor: 'smalltalk: init'!

initTimeNonInherited
	
	self REQUIRES: SequenceSpace.
	self REQUIRES: MuTable.
	TheWrapperDefs := MuTable make: SequenceSpace make.!

linkTimeNonInherited
	
	TheWrapperDefs := NULL.
	TheWrapperSpecs := NULL.
	TheWrapperEndorsements := NULL.
	TheWrappersFromEndorsements := NULL.! !

!FeWrapperSpec class methodsFor: 'private:'!

{void} mustSetup
	[BeGrandMap] USES.
	TheWrapperEndorsements == NULL ifTrue:
		[self setWrapperEndorsements: CurrentGrandMap fluidGet wrapperEndorsements].! !

!FeWrapperSpec class methodsFor: 'accessing'!

{FeWrapperSpec | NULL} fetch: identifier {Sequence}
	"Get the local Wrapper spec with the given identifier, or NULL if there is none"
	
	self mustSetup.
	^(TheWrapperSpecs fetch: identifier) cast: FeWrapperSpec!

{FeWrapperSpec CLIENT} get: identifier {Sequence}
	"Get the local Wrapper spec with the given identifier, or blast if there is none"
	
	| result {FeWrapperSpec} |
	result := self fetch: identifier.
	result == NULL ifTrue:
		[Heaper BLAST: #NotInTable].
	^result!

{CrossRegion} getEndorsements: identifier {Sequence}
	"Get the endorsements for the named wrapper space"
	
	self mustSetup.
	^(TheWrapperEndorsements get: identifier) cast: CrossRegion!

{FeWrapperSpec} getFromEndorsement: endorsement {Tuple}
	"Get the wrapper spec corresponding to the given endorsement"
	
	self mustSetup.
	^(TheWrappersFromEndorsements get: endorsement) cast: FeWrapperSpec!

{XnRegion of: Sequence} knownWrappers
	"The names of all of the known wrappers"
	
	^TheWrapperDefs domain!

{void} setupWrapperSpecs
	"Get the local Wrapper spec with the given identifier, or NULL if there is none"
	
	TheWrapperSpecs := MuTable make: SequenceSpace make.
	TheWrapperDefs stepper forEach: [ :def {FeWrapperDef} |
		TheWrapperSpecs at: def name introduce: def makeSpec].
	TheWrapperSpecs stepper forEach: [ :spec {FeWrapperSpec} |
		spec setup].!

{void} setWrapperEndorsements: endorsements {ScruTable of: Sequence with: CrossRegion}
	"A table mapping from wrapper names to endorsements"
	
	TheWrapperEndorsements := endorsements asMuTable.
	self setupWrapperSpecs.
	TheWrappersFromEndorsements := MuTable make: CurrentGrandMap fluidGet endorsementSpace.
	endorsements stepper forPositions: [ :seq {Sequence} :endorses {CrossRegion} |
		endorses isFinite ifFalse: [Heaper BLAST: #FatalError].
		Ravi thingToDo. "implement stepper so that endorsements are allowed to be regions"
		TheWrappersFromEndorsements at: endorses theOne
			introduce: (self get: seq)
		"endorses stepper forEach: [ :endorse {Tuple} |
			TheWrappersFromEndorsements at: endorse
				introduce: (self get: seq)]"].! !

!FeWrapperSpec class methodsFor: 'smalltalk: system'!

info.stProtocol
"{Filter CLIENT} filter
{Sequence CLIENT} name
{FeWrapper CLIENT} wrap: edition {FeEdition}
"! !