'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:53:04 pm'!

Document subclass: #IndexedDocument
	instanceVariableNames: 'currentLabel {UNKNOWN}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'System-Printing'!
IndexedDocument comment:
'This class produces hardcopies with final index page(s) based on the labels from given Text
if the Text uses a LabelledRunArray.'!



!IndexedDocument methodsFor: 'private:'!

stringsIndexesAndLabelsFor: aText do: aBlock 
	"Send string and strike font index to aBlock for a text."

	| fontruns values labels str index string|
	string _ aText string.
	index _ 1.
	fontruns _ aText runs runs.
	values _ aText runs values.
	labels _ aText runs labels.
	1 to: fontruns size do: 
		[:i | 
		str _ string copyFrom: index to: (fontruns at: i) + index - 1.
		aBlock value: str value: (values at: i) value: (labels at: i).
		index _ index + str size]! !

!IndexedDocument methodsFor: 'Smalltalk compatibility'!

addText: aText under: aTextStyle 
	"Add a formatted Text (strings and runs) to the document,    
	using a specified text style."

	| fontChanged familySizeFace size face familyName underlined |
	fontChanged _ false.
	self stringsIndexesAndLabelsFor: aText do: 
		[:string :index :label | 
		familySizeFace _ (aTextStyle fontAt: index) familySizeFace.
		underlined _ aTextStyle isFontUnderlined: index.
		familyName _ self getFontLike: familySizeFace.
		size _ familySizeFace at: 2.
		face _ familySizeFace at: 3.
		face _ #(Default Bold Italic BoldItalic ) at: face + 1.
		familyName ~= currentFontStyle currentFamily
			ifTrue: 
				[currentFontStyle setFamily: familyName.
				fontChanged _ true].
		size ~= currentFontStyle currentSize
			ifTrue: 
				[currentFontStyle setSize: size.
				fontChanged _ true].
		face ~= currentFontStyle currentFace
			ifTrue: 
				[currentFontStyle setFace: face.
				fontChanged _ true].
		underlined
			ifTrue: 
				[self startUnderlining.
				fontChanged _ true].
		fontChanged
			ifTrue: 
				[self fontStyleChanged].
		(label == nil or: [label sameAs: currentLabel]) ifFalse:
			[self labelChanged.
			currentLabel _ label].
		self addString: string.
		underlined ifTrue: [self stopUnderlining]]! !

!IndexedDocument methodsFor: 'adding entities'!

labelChanged
	"Something stylistic has changed,  so copy all the font style stuff  
	into the list of entities."

	entities add: (Association key: #label: value: currentLabel)! !

!IndexedDocument methodsFor: 'initialize-release'!

close
	"Close out the current document."

	currentLabel _ ''.
	super close!

initialize
	"Set up defaults,  and create an ordered collection to hold the 
	intermediate representation of the document."

	currentLabel _ ''.
	super initialize.! !