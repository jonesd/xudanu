'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:45 pm'!

Dsp subclass: #CrossMapping
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cross'!
CrossMapping comment:
'All other crossed mappings must be gotten by factoring the non-dsp aspects out into the generic non-dsp mapping objects.  This class represents what remains after the factoring.'!

(CrossMapping getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!CrossMapping methodsFor: 'transforming'!

{XnRegion} ofAll: reg {XnRegion}
	
	self subclassResponsibility! !

!CrossMapping methodsFor: 'combining'!

{Dsp} compose: other {Dsp}
	
	self subclassResponsibility!

{Mapping} inverse

	self subclassResponsibility!

{Dsp} minus: other {Dsp}

	self subclassResponsibility! !

!CrossMapping methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace
	
	self subclassResponsibility!

{BooleanVar} isIdentity
	
	self subclassResponsibility!

{Dsp CLIENT} subMapping: index {Int32}
	"The Dsp applied to Positions in the given subspace."
	
	self subclassResponsibility!

{PtrArray CLIENT of: Dsp} subMappings
	"The Mappings applied to Positions in each of the subspaces. Each of these is already simple enough that it is either the identityMapping or a visible subclass like IntegerMapping."
	
	self subclassResponsibility! !

!CrossMapping methodsFor: 'smalltalk: passe'!

{Dsp} subDsp: index {Int32}

	self passe!

{PtrArray of: Dsp} subDsps

	self passe "subMappings"! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CrossMapping class
	instanceVariableNames: ''!

(CrossMapping getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!CrossMapping class methodsFor: 'pseudoconstructors'!

make: space {CrossSpace} with: subDsps {(PtrArray of: Dsp | NULL) default: NULL}

	| subDs {PtrArray of: Dsp} |
	subDs := PtrArray nulls: space axisCount.
	Int32Zero almostTo: subDs count do: [:i {Int32} |
		subDs at: i store: (space axis: i) identityDsp].
	
	subDsps ~~ NULL ifTrue:
		[Int32Zero almostTo: subDs count do: [:i {Int32} |
			| subDsp {Dsp | NULL} |
			(subDsp := (subDsps fetch: i) cast: Dsp) ~~ NULL ifTrue:
				[subDs at: i store: subDsp]]].
	
	^GenericCrossDsp create: space with: subDs! !

!CrossMapping class methodsFor: 'smalltalk: defaults'!

make: space

	^self make: space with: NULL! !

!CrossMapping class methodsFor: 'smalltalk: system'!

info.stProtocol
"{Dsp CLIENT} subMapping: index {Int32}
{PtrArray CLIENT of: Dsp} subMappings
"! !