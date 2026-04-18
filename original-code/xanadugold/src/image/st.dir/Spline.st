'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:54 pm'!

Path subclass: #Spline
	instanceVariableNames: 'derivatives '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Paths'!
Spline comment:
'Class Spline is a subclass of Path representing a collection of Points through which a cubic spline curve is fitted.

Instance Variables:
	derivatives	<Array of: Points>'!


!Spline methodsFor: 'accessing'!

derivativePointsAt: knot
	"Answer an Array of three points around the element of the path knot."

	^Array	with: ((derivatives at: 1) at: knot)
			with: ((derivatives at: 2) at: knot)
			with: ((derivatives at: 3) at: knot)!

isCyclic
	"Answer whether the receiver is cyclic, i.e., folds back on itself."

	^self size > 3 and: [self first = self last]! !

!Spline methodsFor: 'displaying'!

displayOn: aDisplayMedium at: aPoint clippingBox: clipRect rule: anInteger mask: aForm 
	"Method for display of a Spline curve approximated by straight line segments."

	| steps a b c d t myBlt begin end endX endY |
	myBlt _ BitBlt
		destForm: aDisplayMedium
		sourceForm: self form
		halftoneForm: aForm
		combinationRule: anInteger
		destOrigin: aPoint
		sourceOrigin: 0 @ 0
		extent: Display extent
		clipRect: clipRect.
	begin _ self first.
	1 to: self size-1 do:		"for each knot"
		[:k | 
			"taylor series coefficients"
		d _ self at: k.
		c _ (derivatives at: 1) at: k.
		b _ ((derivatives at: 2) at: k) / 2.0.
		a _ ((derivatives at: 3) at: k) / 6.0.
			"guess stepping parameter"
		steps _ ((derivatives at: 2) at: k) abs + ((derivatives at: 2) at: k+1) abs.
		steps _ 5 max: (steps x + steps y) // 100.
		1 to: steps do: 
			[:j | 
			t _ j asFloat / steps asFloat.
			endX _ a x * t + b x * t + c x * t + d x.
			endY _ a y * t + b y * t + c y * t + d y.
			end _ endX @ endY.
			myBlt drawFrom: begin rounded to: end rounded.
			begin _ end].
		end _ (self at: k+1).
		myBlt drawFrom: begin rounded to: end rounded.
		]! !

!Spline methodsFor: 'private: private'!

computeCurve
	"Compute an array for the derivatives at each knot."

	| size extras values |
	size _ self size.
	self isCyclic
		ifTrue:	"for cyclic curves"
			[extras _ 2.		"add 2 extra points to each end."
			values _ Array new: 2*extras + size.
			1 to: extras do:
				[:i |
				values at: i put: (self at: size-extras+i-1).
				values at: size+extras+i put: (self at: i+1)].
			values replaceFrom: extras+1 to: extras+size with: collectionOfPoints]
		ifFalse: [extras _ 0.
				values _ collectionOfPoints].

	derivatives _ Array new: 3.
	1 to: 3 do: [:i | derivatives at: i put: (Array new: values size)].
	self derivs: values
		first: (derivatives at: 1)
		second: (derivatives at: 2)
		third: (derivatives at: 3).

	extras > 0 ifTrue:		"remove extra points"
		[1 to: 3 do: 
			[:i | derivatives at: i put: ((derivatives at: i) copyFrom: extras+1 to: extras+size)]]!

derivs: values first: first second: second third: third
	"Compute the first, second and third derivitives at each point in the array values."

	| size v b | 
	size _ values size.
	size > 2 ifTrue:
		[v _ Array new: size.
		v at: 1 put: 4.0.
		b _ Array new: size.
		b at: 1 put: 6.0*(values first-((values at: 2)*2.0)+(values at: 3)).
		2 to: size-2 do:
			[:i |
			v at: i put: 4.0-(1.0/(v at: i-1)).
			b at: i put: 6.0*((values at: i)-((values at: i+1)*2.0)
				+(values at: i+2))-((b at: i-1)/(v at: i-1))].
		second at: size-1 put: (b at: size-2)/(v at: size-2).
		size-2 to: 2 by: -1 do: 
			[:i | 
			second at: i put: (b at: i-1)-(second at: i+1)/(v at: i-1)]].

	second at: 1 put: 0.0 asPoint.
	second at: size put: 0.0 asPoint.

	1 to: size-1 do:
		[:i |
		first at: i put: (values at: i+1)-(values at: i)-((second at: i)*2.0
			+(second at: i+1)/6.0).
		third at: i put: (second at: i+1)-(second at: i)].! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Spline class
	instanceVariableNames: ''!


!Spline class methodsFor: 'examples'!

randomSplineSample
	"Display a curve that spells ParcPlace that can be used as a screen saver."

	"Spline randomSplineSample"

	| path drawForm rand scaleX scaleY points coords |
	Display black.
	drawForm _ Form new extent: 1 @ 1.
	drawForm white.
	points _ OrderedCollection new.
	coords _ #(242 261 243 139 321 69 351 135 265 157 244 168 242 262 280 262 323 232 363 212 347 212 326 231 330 263 354 271 366 245 368 217 365 237 369 265 375 273 387 269 397 257 411 231 407 213 409 211 431 217 455 215 443 239 451 267 471 275 491 251 503 229 523 221 531 233 528 231 516 219 498 235 494 271 504 277 528 279 534 279 580 257 584 229 588 197 592 139 604 93 646 69 660 127 648 141 612 157 592 175 582 215 586 261 594 285 656 261 674 227 700 155 698 133 668 137 664 165 658 239 666 265 690 275 708 249 740 229 740 229 710 245 706 277 740 289 754 259 756 229 751 257 761 277 773 249 789 233 811 225 818 229 798 228 776 258 784 292 824 294 852 282 868 256 866 226 842 220 830 250 838 278 856 288 902 280 926 266 944 246 ) collect: [:e | e * (Display width min: Display height) / 808].
	1 to: coords size by: 2 do:
		[ :i | points add: (coords at: i)
					@ (coords at: i + 1)].
	rand _ Random new.
	path _ Spline new.
	path form: drawForm.
	scaleX _ Display extent x - 100.
	scaleY _ Display extent y - 100.
	rand next > 0.5
		ifTrue: [points do: [:p | path add: p]]
		ifFalse: [(rand next * 50 + 3) rounded
				timesRepeat: 
					[path add: (rand next * scaleX + 50) rounded @ (rand next * scaleY + 50) rounded.
					drawForm displayOn: Display at: path last]].
	path computeCurve.
	path isEmpty ifFalse: [path displayOn: Display].
	drawForm black.
	path form: drawForm.
	path isEmpty ifFalse: [path displayOn: Display].
	^path!

splineSample
	"Designate points on the Path by clicking the red button.  Terminate 
	by pressing any other button.  A curve will be displayed, through the 
	selected points, using a square black form."

	"Spline splineSample."

	| splineCurve aForm flag|
	aForm _ Form new extent: 3@3.
	aForm black.
	splineCurve _ Spline new.
	splineCurve form: aForm.
	flag _ true.
	[flag] whileTrue:
		[Sensor waitButton.
		 Sensor redButtonPressed
			ifTrue: 
				[splineCurve add: Sensor waitButton. 
				 Sensor waitNoButton.
				 aForm displayOn: Display at: splineCurve last]
			ifFalse: [flag_false]].
	splineCurve computeCurve.
	splineCurve isEmpty 
		ifFalse: [splineCurve displayOn: Display.
				Sensor waitNoButton].
 	^splineCurve! !