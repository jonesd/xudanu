'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:02 pm'!

View subclass: #CenteredFormView
	instanceVariableNames: '
		myFormSelector {Symbol}
		myRuleSelector {Symbol}
		myMaskSelector {Symbol}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-Smalltalk version'!



!CenteredFormView methodsFor: 'accessing'!

form
	myFormSelector ~~ nil
		ifTrue: [^model perform: myFormSelector]
		ifFalse: [^nil]!

form: form mask: mask rule: rule
	myFormSelector _ form.
	myMaskSelector _ mask.
	myRuleSelector _ rule.
	insideColor _ Form white!

mask
	myMaskSelector ~~ nil
		ifTrue: [^model perform: myMaskSelector]
		ifFalse: [^Form black]!

rule
	myRuleSelector ~~ nil
		ifTrue: [^model perform: myRuleSelector]
		ifFalse: [^Form over]! !

!CenteredFormView methodsFor: 'updating'!

update: aspect
	(aspect == myFormSelector
		or: [aspect == myRuleSelector
		or: [aspect == myMaskSelector]]) ifTrue: [self display]! !

!CenteredFormView methodsFor: 'displaying'!

displayView 
	super displayView.
	self insideColor == nil ifFalse: [Display fill: self insetDisplayBox mask: self insideColor].
	self form
		displayOn: Display
		at: self insetDisplayBox topLeft
			+ ((self insetDisplayBox extent - self form extent) // 2)
			- self form offset
		clippingBox: self insetDisplayBox
		rule: self rule
		mask: self mask! !

!CenteredFormView methodsFor: 'window access'!

defaultWindow 
	^(Rectangle origin: 0 @ 0 extent: self form extent)
		expandBy: self borderWidth! !

!CenteredFormView methodsFor: 'controller access'!

defaultControllerClass
	"Answer the default class of the receiver."

	^ButtonAndMenuController! !

!CenteredFormView methodsFor: 'printing'!

printOn: aStream
	aStream nextPutAll: self class name;
		nextPut: $(;
		nextPutAll: myFormSelector;
		nextPut: $)! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

CenteredFormView class
	instanceVariableNames: ''!



!CenteredFormView class methodsFor: 'create'!

form: form
	^self new form: form mask: nil rule: nil!

form: form mask: mask
	^self new form: form mask: mask rule: nil!

form: form mask: mask rule: rule
	^self new form: form mask: mask rule: rule!

form: form rule: rule
	^self new form: form mask: nil rule: rule!

on: model with: controller form: form
	^(self new form: form mask: nil rule: nil) model: model; controller: controller; yourself!

on: model with: controller form: form mask: mask
	^(self new form: form mask: mask rule: nil) model: model; controller: controller; yourself!

on: model with: controller form: form rule: rule
	^(self new form: form mask: nil rule: rule) model: model; controller: controller; yourself! !