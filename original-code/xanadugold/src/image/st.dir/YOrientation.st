'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:56:59 pm'!

Orientation subclass: #YOrientation
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Layout'!
YOrientation comment:
'All the protocol is in the class object because this objects are unique and contain no state.  This represents the abstract Y axis.  The protocol allow manipulation of points with respect to this axis.'!

(YOrientation getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!YOrientation methodsFor: 'accessing'!

{PointTranslateDsp} orientDsp: aDsp {PointTranslateDsp}
	"The dsp supplied has x as its primary axis and y as its secondary axis.  
	Orient it according to this axis." 

	^PointTranslateDsp make: aDsp y with: aDsp x!

{PointPos} orientPoint: aPoint {PointPos}
	"The point supplied has x as its primary axis and y as its secondary axis.  
	Orient it according to this axis." 

	^PointPos make: aPoint y with: aPoint x!

{Dsp} primaryOfDsp: aDsp {PointTranslateDsp} 
	"Return the dsp along the the axis that I represent." 

	^IntegerMapping make: aDsp y!

{IntegerVar}primaryOfPoint: aPoint{PointPos} 
	"Return the dimension of the point along the axis that I represent."

	^aPoint y!

{PointRegion} project: region {IntegerRegion}
	"project a region of the primary along the entire secondary axis"
	self hack. "the restricted slice built here should be obtained from some display thing"
	^PointRegion make: -32768 with: region start with: 32768 with: region stop!

{Dsp} secondaryOfDsp: aDsp {PointTranslateDsp} 
	"Return the dsp orthogonal to the the axis that I represent." 

	^IntegerMapping make: aDsp x!

{IntegerVar} secondaryOfPoint: aPoint {PointPos}
	"Return the dimension of the point orthogonal to the axis 
	that I represent."

	^aPoint x!

{Orientation}transpose
	"Return an object that represent the orthogonal axis."

	^Orientation xAxis! !