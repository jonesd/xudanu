'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:47 pm'!

TextEditor subclass: #TextController
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Interface-Text'!
TextController comment:
'As a subclass of the paragraphEditor, class TextController uses actionMenus for model control protocol.  It also makes a stab (localMenuItem:) at the problem of distinguishing user control directed at the model from that directed at the view/controller. This controller is more tightly connected to its view (for example it asks it for its yellowButtonMenu), because the view is the current site for "pluggable" parameterization.'!


!TextController methodsFor: 'menu messages'!

accept
	(self textHasChanged and: [model changeRequestFrom: view])
		ifFalse: [^view flash].
	self controlTerminate.
	(view accept: self text from: self)
		ifTrue: [super accept]
		ifFalse: [view flash].
	self controlInitialize!

localMenuItem: selector
	^ #(cut paste copySelection again undo cancel accept changeTextStyle changeFont hardcopy) includes: selector! !

!TextController methodsFor: 'editing'!

insertAndSelect: aString at: anInteger 
	self selectAt: anInteger. 
	self deselect.
	self replaceSelectionWith: ' ' asText , aString asText.
	self selectAndScroll! !

!TextController methodsFor: 'accessing'!

paragraph
	"Answer the paragraph model of the receiver."

	^ paragraph!

textHasChanged
	"Answer whether the current text is the same as the initial text."

	^ self text ~= initialText! !

!TextController methodsFor: 'control activity'!

yellowButtonActivity
	| index menu selector |
	menu _ view yellowButtonMenu.
	menu == nil
		ifTrue:
			[view flash.
			super controlActivity]
		ifFalse: 
			[index _ menu startUpYellowButton.
			index ~= 0 
				ifTrue:
					[selector _ menu selectorAt: index.  "editing to self, rest to model"
					(self localMenuItem: selector)
						ifTrue: [self perform: selector]
						ifFalse: [self controlTerminate.
								selector numArgs = 2
									ifTrue: [model perform: selector with: self text with: self]
									ifFalse: [model perform: selector].
								self controlInitialize]]]! !

!TextController methodsFor: 'composition'!

wrappingBox: wrapRectangle clippingBox: clipRectangle
	"Set the display area for the receiver."

	| translation|
	clipRectangle extent = paragraph clippingRectangle extent
		ifTrue: [translation _  clipRectangle origin - paragraph clippingRectangle origin.
				paragraph clippingRectangle: clipRectangle.
				paragraph setCompositionRectangle: (paragraph compositionRectangle translateBy: translation)]
		ifFalse: [paragraph recomposeIn: wrapRectangle clippingBox: clipRectangle]! !