'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:48:49 pm'!

DisplayObject subclass: #InfiniteForm
	instanceVariableNames: 'patternForm '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Graphics-Display Objects'!
InfiniteForm comment:
'Class InfiniteForm represents a Form obtained by replicating a pattern form indefinitely in all directions.

Instance Variable:
	patternForm	<Form> the pattern to be replicated '!


!InfiniteForm methodsFor: 'accessing'!

form
	"Answer the form that represents the replicated pattern."
	
	^patternForm!

form: aForm
	"Set the argument aForm to be the repeated pattern."

	patternForm _ aForm!

offset
	"Answer the point that is the offset for displaying the receiver, always 0@0."

	^0 @ 0! !

!InfiniteForm methodsFor: 'displaying'!

displayOn: aDisplayMedium at: aDisplayPoint clippingBox: clipRectangle rule: ruleInteger mask: aForm
	"Display the receiver on the display medium aDisplayMedium positioned at aDisplayPoint within 
	the rectangle clipRectangle and with the rule, ruleInteger, and mask, aForm. "

	| targetBox patternBox |
	(aForm == Form black and: [patternForm extent = (16 @ 16)])
		ifTrue:
			["Use patternForm as a mask for BitBlt"
			aDisplayMedium fill: clipRectangle rule: ruleInteger mask: patternForm]
		ifFalse:
			["Do it iteratively"
			targetBox _ aDisplayMedium boundingBox intersect: clipRectangle.
			patternBox _ patternForm boundingBox.
			(targetBox left truncateTo: patternBox width) to: targetBox right - 1 by: patternBox width do:
				[:x |
				(targetBox top truncateTo: patternBox height) to: targetBox bottom - 1 by: patternBox height do:
					[:y |
					patternForm displayOn: aDisplayMedium
						at: x @ y
						clippingBox: clipRectangle
						rule: ruleInteger
						mask: aForm]]]! !

!InfiniteForm methodsFor: 'display box access'!

computeBoundingBox
	"Answer the largest representation of the enclosing rectangle around the image."

	^0 @ 0 corner: SmallInteger maxVal @ SmallInteger maxVal! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

InfiniteForm class
	instanceVariableNames: ''!


!InfiniteForm class methodsFor: 'instance creation'!

with: aForm
	"Answer a new instance of the receiver whose pattern to be
	replicated is the argument aForm."

	^self new form: aForm! !