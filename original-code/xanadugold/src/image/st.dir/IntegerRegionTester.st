'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:17 pm'!

RegionTester subclass: #IntegerRegionTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Integers'!

(IntegerRegionTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!IntegerRegionTester methodsFor: 'init'!

{ImmuSet of: XnRegion} initExamples
	"IntegerRegionTester runTest"
	| acc {SetAccumulator of: XnRegion} |
	acc _ SetAccumulator make.
	acc step: IntegerRegion make.
	acc step: IntegerRegion make complement.
	acc step: (IntegerRegion make: 3 with: 7).
	acc step: (IntegerRegion make: 3 with: 7) complement.
	acc step: (IntegerRegion after: 5).
	acc step: (IntegerRegion before: 5).
	^acc value cast: ImmuSet! !

!IntegerRegionTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !