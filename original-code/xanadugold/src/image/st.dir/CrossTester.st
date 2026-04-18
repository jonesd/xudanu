'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:46 pm'!

RegionTester subclass: #CrossTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-cross'!

(CrossTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!CrossTester methodsFor: 'init'!

{ImmuSet of: XnRegion} initExamples

	| result {SetAccumulator} space {CrossSpace}
	  regions {PtrArray of: XnRegion} crosses {PtrArray of: XnRegion} |
	result := SetAccumulator make.
	space := CrossSpace make: ((PrimSpec pointer
		arrayWithThree: IntegerSpace make
		with: IntegerSpace make
		with: IntegerSpace make) cast: PtrArray).
	regions := PtrArray nulls: 3.
	regions at: Int32Zero store: (IntegerRegion make: Int32Zero with: 10).
	regions at: 1 store: (IntegerRegion make: 5 with: 15).
	regions at: 2 store: (IntegerRegion make: 10 with: 20).
	crosses := PtrArray nulls: 3.
	Int32Zero almostTo: 27 do: [ :i {Int32} |
		crosses at: Int32Zero store: (regions fetch: i \\ 3).
		crosses at: 1 store: (regions fetch: i // 3 \\ 3).
		crosses at: 2 store: (regions fetch: i // 9).
		result step: (space crossOfRegions: crosses)].
	^result value cast: ImmuSet! !

!CrossTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !