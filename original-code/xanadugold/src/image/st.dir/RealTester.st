'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:56 pm'!

RegionTester subclass: #RealTester
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Spaces-Basic'!

(RealTester getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!RealTester methodsFor: 'deferred: init'!

{ImmuSet of: XnRegion} initExamples
	| reals {SetAccumulator} result {SetAccumulator} base {ImmuSet} |
	reals := SetAccumulator make.
	reals step: (RealPos make: 0.0).
	reals step: (RealPos make: 1.0).
	reals step: (RealPos make: 2.0).
	result := SetAccumulator make.
	(reals value cast: ScruSet) stepper forEach: [ :real {RealPos} |
		result step: (RealSpace make above: real with: true).
		result step: (RealSpace make above: real with: false).
		result step: (RealSpace make below: real with: true).
		result step: (RealSpace make below: real with: false)].
	base := result value cast: ImmuSet.
	base stepper forEach: [ :r {RealRegion} |
		base stepper forEach: [ :r2 {RealRegion} |
			r hashForEqual < r2 hashForEqual ifTrue:
				[result step: (r unionWith: r2).
				result step: (r intersect: r2)]]].
	^result value cast: ImmuSet! !

!RealTester methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !