'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:49:04 pm'!

Object subclass: #TextStyle
	instanceVariableNames: 'fontArray lineGrid baseline alignment firstIndent restIndent rightIndent tabsArray marginTabsArray outputMedium '
	classVariableNames: 'TextStyles '
	poolDictionaries: 'TextConstants '
	category: 'Graphics-Support'!
TextStyle comment:
'Class TextStyle is the repository of information which may be shared by a number of paragraphs.  It is used for both display and printing operations.

Instance Variables:
	fontArray
<Array>  A collection of fonts available to the paragraph.  These may be either StrikeFonts or PressFonts.  The emphasis portion of a Text returns a value for indexing the font.

	lineGrid	
<Integer>  The amount to be added to the top of a line to find the top of the next line.  Will frequently be the greatest height in the fonts in fontArray.

	baseline	
<Integer>  The amount to be added to the top of a line to find the baseline of the line.  The baseline is the point from which the ascent of a font should rise.

	alignment
<Integer>  Indicates the mode for first level placement from the margins
	-- 0=left flush, 1=centered, 2=right flush, 3=justified.

	firstIndent
<Integer>  Amount to inset from the left margin for the first line of a paragraph.  Initial value for paragraph associated with this TextStyle.

	restIndent
<Integer>  Amount to inset from the left margin for all but the first line of a paragraph.  Initial value for paragraph associated with this TextStyle.

	rightIndent
<Integer>  Amount to inset from the right margin for all the lines of the paragraph.  Initial value for paragraph associated with this TextStyle.

	tabsArray
<Array>  Tab stops.  Values are relative to the left margin of the paragraph.

	marginTabsArray
<Array>  Each value in the array is a tuple indicating an inset from the left and right margin of this paragraph.  Allows for inset paragraphs.

	outputMedium
<Symbol>  Currently only #Display.  Allows for use of TextStyle in both display and printing mode.

Class Variables:
	TextStyles	<Dictionary> containing the names (dictionary keys) and available text styles (dictionary values)

Pool Dictionary:
	TextConstants	<Dictionary>
'!


!TextStyle methodsFor: 'accessing'!

alignment
	"Answer the code for the current setting of the alignment."

	^alignment!

baseline
	"Answer the distance from the top of the line to the bottom of most 
	of the characters (by convention, bottom of A)."

	^baseline!

baseline: anInteger 
	"Set the distance from the top of the line to the bottom of most of 
	the characters."

	baseline _ anInteger!

defaultFont
	"Answer the first font in the font family."

	^self fontAt: 1!

descent
	"Answer the distance from the bottom of the line to the bottom of 
	most of the characters (by convention, bottom of A)."

	^self lineGrid - self baseline!

firstIndent
	"Answer the horizontal indenting of the first line of a paragraph in 
	the style of the receiver."

	^firstIndent!

firstIndent: anInteger 
	"Set the horizontal indenting of the first line of a paragraph in the 
	style of the receiver to be anInteger."

	firstIndent _ anInteger!

fontAt: index 
	"Answer the font indexed as index in the array of fonts.  Provide
	an error notification if there is no font at this index."

	"This is should be treated as a private message because no object 
	outside TextStyle should depend on the representation of the font 
	family. "

	| fontIndex |
	fontIndex _ index.
	fontIndex > fontArray size
		ifTrue: [fontIndex _ fontArray size].
	fontIndex <= 0
		ifTrue: [fontIndex _ 1].
	((fontArray at: fontIndex) isKindOf: StrikeFont)
		ifTrue: [^fontArray at: fontIndex].
	((fontArray at: 1) isKindOf: StrikeFont)
		ifTrue: [^fontArray at: 1].
	self error: 'No valid fonts in font array'!

fontAt: index put: font 
	"Store the argument font as the index'th font."

	fontArray at: index put: font!

lineGrid
	"Answer the relative space between lines of a paragraph in the style 
	of the receiver."

	^lineGrid!

lineGrid: anInteger 
	"Set the relative space between lines of a paragraph in the style of 
	the receiver to be anInteger."

	lineGrid _ anInteger!

nestingDepth
	"Answer the depth of indenting paragraphs when using this text style."

	^ marginTabsArray size!

outputMedium
	"Answer the outputMedium for this style."

	^outputMedium!

outputMedium: aSymbol
	"Set the outputMedium for this style -- currently only Display."

	outputMedium _ aSymbol.
	outputMedium = #Display
		ifTrue:	[lineGrid _ DefaultLineGrid.
				baseline _ DefaultBaseline]
		ifFalse:	[self outputMedium: #Display].!

restIndent
	"Answer the indent for all but the first line of a paragraph in the 
	style of the receiver."

	^restIndent!

restIndent: anInteger 
	"Set the indent for all but the first line of a paragraph in the style of 
	the receiver to be anInteger."

	restIndent _ anInteger!

rightIndent
	"Answer the right margin indent for the lines of a paragraph in the 
	style of the receiver."

	^rightIndent!

rightIndent: anInteger 
	"Answer the right margin indent for the lines of a paragraph in the 
	style of the receiver to be anInteger."

	rightIndent _ anInteger!

setAlignment: anInteger 
	"Set the current setting of the alignment to be anInteger--
	0=left flush, 1=right flush, 2=centered, 3=justified."

	alignment _ anInteger \\ (Justified + 1)! !

!TextStyle methodsFor: 'tabs and margins'!

clearIndents
	"Reset all the margin settings to be 0."

	self firstIndent: 0.
	self restIndent: 0.
	self rightIndent: 0!

leftMarginTabAt: marginIndex 
	"Set the 'nesting' level of left margin indents of the paragraph in the 
	style of the receiver to be marginIndex."

	"The marginTabsArray is an Array of tuples.  The Array is indexed 
	according to the marginIndex, the 'nesting' level of the requestor."

	^self marginTabAt: marginIndex side: 1			"1= leftSide, 2 = rightSide"!

nextTabXFrom: anX leftMargin: leftMargin rightMargin: rightMargin 
	"Tab stops are distances from the leftMargin.  Set the distance into 
	anX normalized for the paragraph's left margin.  Scale makes the 
	routine usable for printing.  On the display the scale is 1."

	| normalizedX tabX scale |
	scale _ 1.
	normalizedX _ anX - leftMargin.
	1 to: tabsArray size 
	  do: [:i | (tabX _ ((tabsArray at: i) * scale) asInteger) > normalizedX
				ifTrue: [^leftMargin + tabX min: rightMargin]].
	^rightMargin!

rightMarginTabAt: marginIndex 
	"Set the 'nesting' level of right margin indents of the paragraph in the 
	style of the receiver to be marginIndex."

	"The marginTabsArray is an Array of tuples.  The Array is indexed 
	according to the marginIndex, the 'nesting' level of the requestor."

	^self marginTabAt: marginIndex side: 2		"1= leftSide, 2 = rightSide"!

tabWidth
	"Answer the width of standard tab."

	^ DefaultTab!

useTabs: newTabsArray
	"Change the tab stops used by this text style."

	| nextTab | 
	tabsArray _ Array new: tabsArray size.
	1 to: newTabsArray size
		do: [ :i | tabsArray at: i put: (newTabsArray at: i)].
	nextTab _ newTabsArray last + self tabWidth.
	newTabsArray size+1 to: tabsArray size
		do: [ :i | tabsArray at: i put: nextTab.
				 nextTab _ nextTab + self tabWidth]! !

!TextStyle methodsFor: 'fonts and font indexes'!

flushFonts
	"Clean out the fonts, an aid when snapshotting claims too many are holding onto Display."

	"TextStyle default flushFonts."

	BinaryChoice
		message: 
'This is very dangerous and should only be used if you know what
you are doing and understand the system integrity issue.' 
		displayAt: Display boundingBox center
		ifTrue: [1 to: fontArray size do: [:index | fontArray at: index put: nil]]
		ifFalse: [Transcript cr; show: 'flushFonts cancelled']! !

!TextStyle methodsFor: 'fileIn/Out'!

storeBinaryOn: stream

	| name |
	name _ self findStoreName.
	name notNil
		ifTrue:
			[stream storeRecordOfClass: self class.
			stream nextPut: name]
		ifFalse: [super storeBinaryOn: stream]! !

!TextStyle methodsFor: 'private: private'!

basalFontFor: fontIndex
	^self fontFor: fontIndex face: Basal!

boldFontFor: fontIndex
	^self fontFor: fontIndex face: Bold!

boldItalicFontFor: fontIndex
	^self fontFor: fontIndex face: BoldItalic!

findStoreName

	TextStyles associationsDo:
		[:assoc |
		fontArray == assoc value fontArray
			ifTrue: [^assoc key]].
	^nil!

fontArray
	^fontArray!

fontFor: fontIndex face: face
	| currentFont currentFamilySizeFace family size emphasis newFamilySizeFace |
	currentFamilySizeFace _ (currentFont _ fontArray at: fontIndex) familySizeFace.
	family _ currentFamilySizeFace at: FamilyName.
	size _ currentFamilySizeFace at: PointSize.
	emphasis _ currentFont emphasis.
	(1 to: fontArray size)
		do:	[:faceFontIndex |
			newFamilySizeFace _ (currentFont _ fontArray at: faceFontIndex) familySizeFace.
			((((family = (newFamilySizeFace at: FamilyName))
				and: [size = (newFamilySizeFace at: PointSize)])
					and: [face = (newFamilySizeFace at: Face)])
						and: [(emphasis bitAnd: NonFaceEmphasisMask) =
								(currentFont emphasis bitAnd: NonFaceEmphasisMask)])
				ifTrue:	[^faceFontIndex]].
	^ fontIndex!

fontNamed: aString
	(1 to: fontArray size)
		do:	[:faceFontIndex |
			aString = (fontArray at: faceFontIndex) name
			ifTrue:	[^faceFontIndex]].
	^ self basalFontFor: 1!

gridForFont: fontIndex withLead: leadInteger 
	"Force whole style to suit one of its fonts. Assumes only one font referred to by runs. "

	| font |
	font _ self fontAt: fontIndex.
	self lineGrid: font height + leadInteger.
	self baseline: font ascent!

isFontBold: fontIndex
	
	 ^ ((fontArray at: fontIndex) familySizeFace at: Face) = Bold!

isFontBoldItalic: fontIndex
	
	 ^ ((fontArray at: fontIndex) familySizeFace at: Face) = BoldItalic!

isFontItalic: fontIndex
	
	 ^ ((fontArray at: fontIndex) familySizeFace at: Face) = Italic!

isFontSubscripted: fontIndex

	^ (((self fontAt: fontIndex) emphasis) bitAt: SubscriptedBit) = 1!

isFontSuperscripted: fontIndex

	^ (((self fontAt: fontIndex) emphasis) bitAt: SuperscriptedBit) = 1!

isFontUnderlined: fontIndex

	^ (((self fontAt: fontIndex) emphasis) bitAt: UnderlinedBit) = 1!

italicFontFor: fontIndex
	^self fontFor: fontIndex face: Italic!

marginTabAt: marginIndex side: sideIndex 
	"The marginTabsArray is an Array of tuples.  The Array is indexed 
	according to the marginIndex, the 'nesting' level of the requestor. 
	sideIndex is 1 for left, 2 for right"

	| scale |
	scale _ 1.
	(marginIndex > 0 and: [marginIndex < marginTabsArray size])
		ifTrue: [^((marginTabsArray at: marginIndex) at: sideIndex) * scale]
		ifFalse: [^0]!

newFontArray: anArray
	fontArray _ anArray.
	lineGrid _ DefaultLineGrid.
	baseline _ DefaultBaseline.
	alignment _ 0.
	firstIndent _ 0.
	restIndent _ 0.
	rightIndent _ 0.
	outputMedium _ #Display.
	tabsArray _ DefaultTabsArray.
	marginTabsArray _ DefaultMarginTabsArray

	"Currently there is no supporting protocol for changing these arrays.  If an editor wishes to implement margin setting, then a copy of the default should be stored as these instance variables."!

subscriptedFontFor: fontIndex
	| name thisFont subscriptedFont |
	name _ (thisFont _ fontArray at: fontIndex) name.
	1 to: fontArray size
		do:	[:subscriptedFontIndex |
			(subscriptedFont _
				fontArray at: subscriptedFontIndex) name = name
				ifTrue:	[(((subscriptedFont emphasis bitAt: SubscriptedBit) = 1)
							and: [(thisFont emphasis bitAt: Underlined) =
									(subscriptedFont emphasis bitAt: Underlined)])
							ifTrue:	[^subscriptedFontIndex]]].
	^ fontIndex!

superscriptedFontFor: fontIndex
	| name thisFont superscriptedFont |
	name _ (thisFont _ fontArray at: fontIndex) name.
	1 to: fontArray size
		do:	[:superscriptedFontIndex |
			(superscriptedFont _
				fontArray at: superscriptedFontIndex) name = name
				ifTrue:	[(((superscriptedFont emphasis bitAt: SuperscriptedBit) = 1)
							and: [(thisFont emphasis bitAt: Underlined) =
									(superscriptedFont emphasis bitAt: Underlined)])
							ifTrue:	[^superscriptedFontIndex]]].
	^ fontIndex!

underlinedFontFor: fontIndex
	| name thisFont underlinedFont |
	name _ (thisFont _ fontArray at: fontIndex) name.
	1 to: fontArray size
		do:	[:underlinedFontIndex |
			(underlinedFont _
				fontArray at: underlinedFontIndex) name = name
				ifTrue:	[(((underlinedFont emphasis bitAt: UnderlinedBit) = 1)
							and: [(thisFont emphasis bitAnd: SubSuperscriptMask) =
									(underlinedFont emphasis bitAnd: SubSuperscriptMask)])
							ifTrue:	[^underlinedFontIndex]]].
	^ fontIndex!

unSubscriptedFontFor: fontIndex
	| name thisFont unSubscriptedFont |
	name _ (thisFont _ fontArray at: fontIndex) name.
	1 to: fontArray size
		do:	[:unSubscriptedFontIndex |
			(unSubscriptedFont _
				fontArray at: unSubscriptedFontIndex) name = name
				ifTrue:	[(((unSubscriptedFont emphasis bitAt: SubscriptedBit) = 0)
							and: [(thisFont emphasis bitAt: Underlined) =
									(unSubscriptedFont emphasis bitAt: Underlined)])
							ifTrue:	[^unSubscriptedFontIndex]]].
	^ fontIndex!

unSuperscriptedFontFor: fontIndex
	| name thisFont unSuperscriptedFont |
	name _ (thisFont _ fontArray at: fontIndex) name.
	1 to: fontArray size
		do:	[:unSuperscriptedFontIndex |
			(unSuperscriptedFont _
				fontArray at: unSuperscriptedFontIndex) name = name
				ifTrue:	[(((unSuperscriptedFont emphasis bitAt: SuperscriptedBit) = 0)
							and: [(thisFont emphasis bitAt: Underlined) =
									(unSuperscriptedFont emphasis bitAt: Underlined)])
							ifTrue:	[^unSuperscriptedFontIndex]]].
	^ fontIndex!

unUnderlinedFontFor: fontIndex
	| name thisFont unUnderlinedFont |
	name _ (thisFont _ fontArray at: fontIndex) name.
	1 to: fontArray size
		do:	[:unUnderlinedFontIndex |
			(unUnderlinedFont _
				fontArray at: unUnderlinedFontIndex) name = name
				ifTrue:	[(((unUnderlinedFont emphasis bitAt: UnderlinedBit) = 0)
							and: [(thisFont emphasis bitAnd: SubSuperscriptMask) =
									(unUnderlinedFont emphasis bitAnd: SubSuperscriptMask)])
							ifTrue:	[^unUnderlinedFontIndex]]].
	^ fontIndex! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextStyle class
	instanceVariableNames: ''!


!TextStyle class methodsFor: 'class initialization'!

initialize
	"Initialize TextStyles constant dictionary."

	"TextStyle initialize"

	TextStyles _ Dictionary new.
	TextStyles at: #default put: DefaultTextStyle.! !

!TextStyle class methodsFor: 'instance creation'!

fontArray: anArray 
	"Answer an instance of the receiver with fonts those in anArray."

	^self new newFontArray: anArray! !

!TextStyle class methodsFor: 'constants'!

default
	"Answer the system default text style."

	^DefaultTextStyle copy!

resetViews
	"reset the world after changing the default textStyle"
	"TextStyle setDefaultTo: #small.
	 TextStyle resetViews"

	Smalltalk garbageCollect.
	BitEditor initialize.
	ChangeListController initialize.
	FormEditor initialize.
	IconController initialize.
	NotifierController initialize.
	ParagraphEditor initialize.
	TextList initialize.
	ScreenController initialize.
	StringHolderController initialize.
	StandardSystemController initialize.
	
	PopUpMenu flushMenus.
	StandardSystemView withAllSubclasses do:
		[:ssv | ssv allInstances do: [:v | v newLabel: v label]].
	TextCompositor allInstances do:
		[:v | v textStyle: TextStyle default].
	TextList allInstances do:
	[:v | v textStyle: TextStyle default].
	SelectionInListView allInstances do: [:view | view list: view getList].
	ScheduledControllers restore.!

setDefaultTo: aTextStyleSymbol
	"Set the default text style to be aTextStyleSymbol."

	"TextStyle setDefaultTo: #default"

	^DefaultTextStyle _ TextStyles at: aTextStyleSymbol!

styleNamed: aSymbol
	"Answer the style named aSymbol from the text style dictionary."

	^(TextStyles at: aSymbol) copy!

styleNamed: aSymbol ifAbsent: aBlock
	"Answer the style named aSymbol from the text style dictionary.
	If the style is not in the dictionary, answer the result of
	evaluating aBlock."

	^(TextStyles at: aSymbol ifAbsent: aBlock) copy!

styleNamed: aSymbol put: aTextStyle
	"Store the text style aTextStyle in the text style dictionary,
	naming it aSymbol."

	TextStyles at: aSymbol put: aTextStyle!

styles
	"Answer a set of names of all the text styles."

	^TextStyles keys! !

!TextStyle class methodsFor: 'fileIn/Out'!

findFont: fontName
	" If a StrikeFont with the given fontName
	exists in any named style, answer the
	StrikeFont, otherwise answer nil. "

	TextStyles do: [:style |
		style fontArray do: [:font |
			((font isKindOf: StrikeFont) and:
			 [font name = fontName])
				ifTrue: [^font]]].
	^nil!

readBinaryFrom: stream tag: tag

	| styleName obj style |
	obj _ String new: 0.  "place-holder"
	stream register: obj id: tag.
	styleName _ stream next.
	style _ TextStyle styleNamed: styleName.
	obj become: style.
	^obj! !

TextStyle initialize!
