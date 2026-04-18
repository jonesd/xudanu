'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:18 pm'!

AttributeGroup subclass: #AsciiAttribute
	instanceVariableNames: '
		fontInternal {FMFont}
		selectedInternal {BooleanVar}
		extraInternal {ImmuSet of: Attribute}'
	classVariableNames: ''
	poolDictionaries: 'TextConstants '
	category: 'FM-Text'!

(AsciiAttribute getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!AsciiAttribute methodsFor: 'accessing'!

{FMAlphabet} alphabet
	^FMAlphabet asciiAlphabet.make!

{FMFont} font
	^fontInternal!

{BooleanVar} selected
	^selectedInternal! !

!AsciiAttribute methodsFor: 'create'!

create.cxx: attributes {(ImmuSet unused of: Attribute) | NULL} 
	"All the variables are defined in the pool dictionary named 
	TextConstants. Don't try to understand pool dictionaries. It 
	essentially defines a bunch of useful constants. Clearly this will 
	have to cache things... Iterate through the attributes extracting the 
	ones that affect the font. Compute a fontindex, check for a 
	selected flag, and get the font for the computed index."

	super create.
	fontInternal _ FontObj make.
	selectedInternal _ NULL.
	extraInternal _ NULL!

create: font {FMFont} with: sel {Boolean}
	super create.
	fontInternal _ font.
	selectedInternal _ sel.
	extraInternal _ NULL!

create: font {FMFont} with: sel {BooleanVar} with: extraAttributes {ImmuSet}
	super create.
	fontInternal _ font.
	selectedInternal _ sel.
	extraInternal _ extraAttributes!

create: font {FMFont} with: sel {BooleanVar} with: extraAttributes {ImmuSet} with: alphabet {FMAlphabet unused}
	super create.
	fontInternal _ font.
	selectedInternal _ sel.
	extraInternal _ extraAttributes! !

!AsciiAttribute methodsFor: 'smalltalk: smalltalk create'!

create: attributes {(ImmuSet of: Attribute) | NULL} 
	"All the variables are defined in the pool dictionary named TextConstants. Don't 
	try to understand pool dictionaries. It essentially defines a bunch of useful 
	constants. Clearly this will have to cache things... 
	Iterate through the attributes extracting the ones that affect the font. 
	Compute a fontindex, check for a selected flag, and get the font for the 
	computed index."

	| fontIndex {IntegerVar} reversed {BooleanVar} leftOvers {(MuSet of: Attribute) | NULL} |
	fontIndex _ Basal.
	reversed _ false.
	leftOvers _ NULL.
	attributes ~~ NULL ifTrue: 
		[attributes stepper forEach: [:attr {Attribute} | 
		((Sequence string: 'basal') isEqual: attr) ifTrue: [fontIndex _ fontIndex + Basal]
		ifFalse: [((Sequence string: 'bold') isEqual: attr) ifTrue: [fontIndex _ fontIndex + Bold]
		ifFalse: [((Sequence string: 'italic') isEqual: attr) ifTrue: [fontIndex _ fontIndex + Italic]
		ifFalse: [((Sequence string: 'underlined') isEqual: attr) ifTrue: [fontIndex _ fontIndex + Underlined]
		ifFalse: [((Sequence string: 'superscripted') isEqual: attr) ifTrue: [fontIndex _ fontIndex + Superscripted]
		ifFalse: [((Sequence string: 'subscripted') isEqual: attr) ifTrue: [fontIndex _ fontIndex + Subscripted]
		ifFalse: [((Sequence string: 'overstruck') isEqual: attr) ifTrue: [fontIndex _ fontIndex + OverStruck]
		ifFalse: [((Sequence string: 'reversed') isEqual: attr) ifTrue: [reversed _ true]
		ifFalse: [leftOvers == NULL ifTrue: [leftOvers _ MuSet make].
				leftOvers store: attr]]]]]]]]]].
	fontInternal _ (TextStyle styleNamed: #small) fontAt: fontIndex.
	selectedInternal _ reversed.
	leftOvers == NULL 
		ifTrue: [extraInternal _ NULL] 
		ifFalse: [extraInternal _ ImmuSet make: leftOvers]! !