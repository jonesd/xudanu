'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:58 pm'!

Heaper subclass: #Orientation
	instanceVariableNames: ''
	classVariableNames: '
		XAxis {Orientation star} 
		YAxis {Orientation star} '
	poolDictionaries: ''
	category: 'FM-Layout'!

(Orientation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Orientation methodsFor: 'deferred accessing'!

{PointTranslateDsp}orientDsp: aDsp {PointTranslateDsp}
	"The dsp supplied has x as its primary axis and y as its secondary axis.  
	Orient it according to this axis."

	self subclassResponsibility!

{PointPos}orientPoint: aPoint {PointPos}
	"The point supplied has x as its primary axis and y as its secondary axis.  
	Orient it according to this axis."

	self subclassResponsibility!

{Dsp} primaryOfDsp: aDsp {PointTranslateDsp} 
	"Return the dsp along the the axis that I represent."

	self subclassResponsibility!

{IntegerVar} primaryOfPoint: aPoint{PointPos}
	"Return the dimension of the point along the axis that I represent."

	self subclassResponsibility!

{PointRegion} project: region {IntegerRegion}
	"project a region of the primary along the entire secondary axis"
	self subclassResponsibility!

{Dsp} secondaryOfDsp: aDsp {PointTranslateDsp} 
	"Return the dsp orthogonal to the the axis that I represent."

	self subclassResponsibility!

{IntegerVar}secondaryOfPoint: aPoint{PointPos}
	"Return the dimension of the point orthogonal to the axis that I represent."

	self subclassResponsibility!

{Orientation}transpose
	"Return an object that represent the orthogonal axis."

	self subclassResponsibility! !

!Orientation methodsFor: 'testing'!

{BooleanVar} isEqual: other {Heaper}
	^ other == self! !

!Orientation methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	self == (XAxis cast: Orientation)
		ifTrue: [oo << 'X Axis']
		ifFalse: [oo << 'Y Axis']! !

!Orientation methodsFor: 'smalltalk: passe'!

orient: thing
	
	self passe!

primary: thing
	
	self passe!

secondary: thing
	
	self passe! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Orientation class
	instanceVariableNames: ''!

(Orientation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!Orientation class methodsFor: 'smalltalk: smalltalk initialization'!

initialize
	"Orientation initialize."

	Smalltalk at: #XAxis put: XOrientation create.
	Smalltalk at: #YAxis put: YOrientation create!

initTimeNonInherited
	XAxis _ XOrientation create.
	YAxis _ YOrientation create!

linkTimeNonInherited
	XAxis _ NULL.
	YAxis _ NULL! !

!Orientation class methodsFor: 'pseudo constructors'!

{Orientation} xAxis
	^XAxis!

{Orientation} yAxis
	^YAxis! !

Orientation initialize!
