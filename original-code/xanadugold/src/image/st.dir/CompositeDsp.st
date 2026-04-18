'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:02 pm'!

Dsp subclass: #CompositeDsp
	instanceVariableNames: 'myCS {CoordinateSpace}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Composite'!

(CompositeDsp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; yourself)!

!CompositeDsp methodsFor: 'creation'!

create: cs {CoordinateSpace}
	super create.
	myCS _ cs.! !

!CompositeDsp methodsFor: 'deferred combining'!

{Dsp} compose: other {Dsp}

	self subclassResponsibility!

{Mapping} inverse

	self subclassResponsibility!

{Dsp} inverseCompose: other {Dsp}

	self subclassResponsibility!

{Dsp} minus: other {Dsp}

	self subclassResponsibility! !

!CompositeDsp methodsFor: 'transforming'!

{Position} inverseOf: something {Position}

	self subclassResponsibility!

{XnRegion} inverseOfAll: something {XnRegion}

	self subclassResponsibility!

{Position} of: something {Position}

	self subclassResponsibility!

{XnRegion} ofAll: something {XnRegion}

	self subclassResponsibility! !

!CompositeDsp methodsFor: 'accessing'!

{CoordinateSpace} coordinateSpace

	^myCS!

{BooleanVar} isIdentity
	self subclassResponsibility!

{Dsp} subDsp: key {Position}
	"the Dsp in a subspace"
	self subclassResponsibility! !

!CompositeDsp methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myCS _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myCS.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CompositeDsp class
	instanceVariableNames: ''!

(CompositeDsp getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #COPY; yourself)!

!CompositeDsp class methodsFor: 'pseudo constructors'!

make.CoordinateSpace: cs {CoordinateSpace}
	^CompositeIdentityDsp create: cs! !