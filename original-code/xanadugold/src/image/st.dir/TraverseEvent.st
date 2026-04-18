'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:54 pm'!

UserEvent subclass: #TraverseEvent
	instanceVariableNames: 'startPointInternal {PointPos}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Events'!

(TraverseEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TraverseEvent methodsFor: 'transition testing'!

{BooleanVar}enter: encl{XnRegion} in: aView {Viewer}
	"True if the starting point of this traverse was outside the enclosure, and the 
	end point is inside."
	[Dsp] USES.

	^(encl hasMember: (aView globalDsp inverseOf: self globalPoint))
		and: [(encl hasMember: (aView globalDsp inverseOf: startPointInternal)) not]!

{BooleanVar}exit: encl{XnRegion} in: aView {Viewer}
	"True if the starting point of this traverse was inside the enclosure, and the 
	end point is outside."
	^(encl hasMember: (aView globalDsp inverseOf: self globalPoint)) not
		and: [(encl hasMember: (aView globalDsp inverseOf: startPointInternal))]!

{BooleanVar}traverse
	"This is obviously a traverse event."

	^true! !

!TraverseEvent methodsFor: 'create'!

create: time{TimeVar} with: point{PointPos} with: metaBits{UInt32} with: startPoint{PointPos}
	super create: time with: point with: metaBits.
	startPointInternal _ startPoint! !

!TraverseEvent methodsFor: 'printing'!

{void}printOn: aStream{ostream reference}
	super printOn: aStream.
	aStream   << ' from: ' << startPointInternal! !

!TraverseEvent methodsFor: 'smalltalk: smalltalk accessing unused'!

{Point.X} startPointIn: aView {Viewer}
	^aView globalDsp inverseOf: startPointInternal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TraverseEvent class
	instanceVariableNames: ''!

(TraverseEvent getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TraverseEvent class methodsFor: 'pseudo constructors'!

make: time{TimeVar} with: point{PointPos} with: metaBits{UInt32} with: startPoint{PointPos}
	^ TraverseEvent create: time with: point with: metaBits with: startPoint! !