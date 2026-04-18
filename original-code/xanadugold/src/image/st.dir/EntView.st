'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:13 pm'!

View subclass: #EntView
	instanceVariableNames: 'selectedClam '
	classVariableNames: 'TextMenu '
	poolDictionaries: ''
	category: 'Tree-Showing'!


!EntView methodsFor: 'hardcopy'!

hardcopyView
	"Print the ent."

	| dForm document |
	dForm _ Form extent: (model boundingBox extent).
	model displayOn: dForm.
	Cursor wait
		showWhile:
			[document _ Document new.
			document addImage: dForm.
			document close.
			document toPrinter]! !

!EntView methodsFor: 'displaying'!

displayView
	"Display the ent in the view."

	| dForm |
	dForm _ Form extent: (self insetDisplayBox extent).
	model displayOn: dForm.
	dForm
		displayOn: Display
		at: self insetDisplayBox origin
		clippingBox: self insetDisplayBox.
	selectedClam notNil ifTrue: [ model highlight: selectedClam origin: (self insetDisplayBox origin) ]!

update: aParameter
	self display! !

!EntView methodsFor: 'initialization'!

initialize
	super initialize.
	selectedClam _ nil.! !

!EntView methodsFor: 'accessing'!

defaultControllerClass
	^EntController!

selection
	^ selectedClam!

selection: aClam
	selectedClam _ aClam.
	self changed: #text.
	^aClam! !

!EntView methodsFor: 'text'!

text
	^selectedClam == nil
		ifTrue: [Text new]
		ifFalse: 
			[| oo |
			oo _ WriteStream on: (Text new: 40).
			selectedClam host showOn: oo.
			oo contents]!

textMenu
	self hack. "what about 'accept'"
	^PopUpMenu standardTextMenu.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

EntView class
	instanceVariableNames: ''!


!EntView class methodsFor: 'instance creation'!

{EntView} make: root {Object} 
	^EntView
		make: root
		gettingChildren: [:elem | (elem respondsTo: #inspectPieces)
				ifTrue: [elem inspectPieces]
				ifFalse: [#()]]
		gettingImage: 
			[:elem | | oo |
			oo _ WriteStream on: (Text new: 40).
			elem showOn: oo.
			oo contents asDisplayText]
		at: 0 @ 0
		vertical: false
		separation: 10 @ 10!

{EntView} make: root {Object} gettingChildren: childBlock {BlockClosure} gettingImage: imageBlock {BlockClosure} at: pos {Point} vertical: vert {BooleanVar} separation: sep {Point} 
	| seen |
	seen _ Set new.
	^EntView openOn: (TreeBarnacle new
			buildOn: root
			gettingChildren: [:elem {Object} | (seen includes: elem)
					ifTrue: [#('*again*' )]
					ifFalse: [seen add: elem.
						childBlock value: elem]]
			gettingImage: imageBlock
			at: pos
			vertical: vert
			separation: sep)!

openOn: aBarnacle 
	"Open a view for displaying an Ent"
	"EntView open."

	| extent topView entView |
	extent _ (aBarnacle boundingBox extent * (1@1.5) max: 40@40) + (20@20) min: Display extent.
	topView _ (InspectorView new) label: 'Tree View from: ' , aBarnacle host class name; 
		borderWidth: 1;
		minimumSize: extent
		"; maximumSize: extent".
	topView
		addSubView: (entView _ self new model: aBarnacle;
			insideColor: Form white;
			translateBy: aBarnacle boundingBox extent negated;
			scaleBy: 1 @ -1)
		in: (0.0 @ 0.0 corner: 1.0 @ 0.8)
		borderWidth: 1.
	topView
		addSubView: (TextView
				on: entView
				aspect: #text
				change: #acceptText:from:
				menu: #textMenu)
		in: (0.0 @ 0.8 corner: 1.0 @ 1.0)
		borderWidth: 1.
	^topView controller open! !