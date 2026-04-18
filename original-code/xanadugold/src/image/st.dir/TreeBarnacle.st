'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:14 pm'!

Object subclass: #TreeBarnacle
	instanceVariableNames: 'fShip fKids fOffsetFromMama fImage fBox fVertical fBackwards '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tree-Showing'!


!TreeBarnacle methodsFor: 'displaying'!

displayOn: aForm
	self displayOn: aForm at: (0@0)!

displayOn: aForm at: aPoint
	| tPen |
	fImage displayOn: aForm at: aPoint.
	self drawConnectionsOn: aForm offset: aPoint.
	fKids do: [:aKid | aKid displayOn: aForm at: (aPoint + aKid offset)]!

drawConnectionsOn: aForm offset: aPoint
	| tPen cp |
	tPen _ Pen new black; defaultNib: 1; destForm: aForm; clipRect: (aForm boundingBox).
	cp _ self connectionRoot + aPoint.
	fKids do: [ :aBarnie |
		tPen up; goto: cp; down.
		tPen goto: (aBarnie attachPoint + aPoint + aBarnie offset); up ]!

highlight: aClam origin: aPoint
	| tBox | 
	(aClam == self) 
		ifTrue: [ 
			tBox _ fImage relativeRectangle translateBy: aPoint.
			Display reverse: tBox ]
		ifFalse: [ fKids do: [ :aKid |
			(aKid highlight: aClam origin: (aPoint + aKid offset))
				ifTrue: [ ^ true ]]].
	^false! !

!TreeBarnacle methodsFor: 'building'!

buildOn: aShip gettingChildren: childBlock gettingImage: imageBlock at: aLocation vertical: isVert separation: aSep
	| newBarnies | 
	fShip _ aShip.
	fOffsetFromMama _ aLocation.
	fVertical _ isVert.
	fBackwards _ 1.
	fImage _ imageBlock value: aShip.
	fImage offset: (0@0).
	newBarnies _ childBlock value: aShip.
	fKids _ OrderedCollection new: (newBarnies size).
	newBarnies isEmpty not
		ifTrue: [ 
			self positionKids: newBarnies withSep: aSep grands: childBlock image: imageBlock.
			fImage offset: ((self orthoOf: ((self kidsSize center) - (fImage boundingBox center))) max: (0@0)) ].
	fBox _ fKids 
		inject: (fImage relativeRectangle)
		into: [ :aRect :aKit | aRect merge: (aKit boundingBox translateBy: (aKit offset))].
	fBox _ (0@0) extent: ((fBox extent)).
	^ self!

positionKids: newBarnies withSep: aSep grands: childBlock image: imageBlock 
	| nextOrigin originIncrement tKid |
	nextOrigin _ self nonOrthoOf: ((fImage boundingBox extent) + aSep).
	originIncrement _ self orthoOf: aSep.
	newBarnies do: 
		[:aBarnacle | 
		fKids add: (tKid _ self class new
						buildOn: aBarnacle
						gettingChildren: childBlock
						gettingImage: imageBlock
						at: nextOrigin
						vertical: fVertical
						separation: aSep).
		nextOrigin _ nextOrigin + originIncrement + (self orthoOf: (tKid boundingBox extent))]! !

!TreeBarnacle methodsFor: 'enumerating'!

detect: aBlock
	^ self detect: aBlock ifNone: [ self error: 'item not found' ]!

detect: aBlock ifNone: exceptionBlock
	self do: [ :aBarnie | (aBlock value: aBarnie) ifTrue: [ ^ aBarnie ]].
	^ exceptionBlock value!

do: aBlock
	aBlock value: self.
	fKids do: [ :aKid | aKid do: aBlock ]! !

!TreeBarnacle methodsFor: 'testing'!

containingPoint: aPoint
	| tmp |  
	((fImage relativeRectangle) containsPoint: aPoint)
		ifTrue: [ ^ self ]
		ifFalse: [ fKids do: [ :aKid |
			(tmp _ aKid containingPoint: (aPoint - aKid offset)) notNil
				ifTrue: [ ^ tmp ]]].
	^ nil! !

!TreeBarnacle methodsFor: 'accessing'!

attachPoint
	^fBackwards > 0
		ifTrue: [fVertical
				ifTrue: [fImage relativeRectangle topCenter]
				ifFalse: [fImage relativeRectangle leftCenter]]
		ifFalse: [fVertical
				ifTrue: [fImage relativeRectangle bottomCenter]
				ifFalse: [fImage relativeRectangle rightCenter]]!

boundingBox
	^ fBox!

connectionRoot
	^fBackwards > 0
		ifTrue: [fVertical
				ifTrue: [fImage relativeRectangle bottomCenter]
				ifFalse: [fImage relativeRectangle rightCenter]]
		ifFalse: [fVertical
				ifTrue: [fImage relativeRectangle topCenter]
				ifFalse: [fImage relativeRectangle leftCenter]]!

host
	^ fShip!

kidsSize
	| tmp | 
	fKids isEmpty ifTrue: [ ^ fImage relativeRectangle ].
	tmp _ fKids inject: (fKids first relativeRectangle) into: [ :aRect :aKid |
			aRect merge: (aKid relativeRectangle) ].
	^ (0@0) extent: (tmp extent)!

nonOrthoOf: aPoint
	^ fVertical 
		ifTrue: [ 0 @ (aPoint y * fBackwards) ]
		ifFalse: [ (aPoint x * fBackwards) @ 0 ]!

offset
	^ fOffsetFromMama!

orthoOf: aPoint
	^ fVertical 
		ifTrue: [ (aPoint x * fBackwards) @ 0 ]
		ifFalse: [ 0 @ (aPoint y * fBackwards) ]!

relativeRectangle
	^ fBox translateBy: fOffsetFromMama! !