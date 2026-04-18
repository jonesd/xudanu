'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:03 pm'!

CompositeDsp subclass: #CompositeIdentityDsp
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Composite'!

(CompositeIdentityDsp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!CompositeIdentityDsp methodsFor: 'combining'!

{Dsp} compose: other {Dsp}

	^other!

{Mapping} inverse

	^self!

{Dsp} inverseCompose: other {Dsp}

	^other!

{Dsp} minus: other {Dsp}

	^(other inverse cast: Dsp)! !

!CompositeIdentityDsp methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	oo << self getCategory name << '(' << myCS << ')'! !

!CompositeIdentityDsp methodsFor: 'transforming'!

{Position} inverseOf: something {Position}

	^something!

{XnRegion} inverseOfAll: something {XnRegion}

	^something!

{Position} of: something {Position}

	^something!

{XnRegion} ofAll: something {XnRegion}

	^something! !

!CompositeIdentityDsp methodsFor: 'accessing'!

{BooleanVar} isIdentity
	^true!

{Dsp} subDsp: key {Position}
	"the Dsp in a subspace"
	^((myCS cast: CompositeSpace) subSpace: key) identityDsp! !

!CompositeIdentityDsp methodsFor: 'creation'!

create: cs {CoordinateSpace}
	super create: cs! !