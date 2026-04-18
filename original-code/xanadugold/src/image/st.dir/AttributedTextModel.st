'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:18 pm'!

XnModel subclass: #AttributedTextModel
	instanceVariableNames: ''
	classVariableNames: '
		NoAttributes {AttributeGroup} 
		NotSimpleRegionSignal {Signal smalltalk} 
		ReversedAttributes {AttributeGroup} '
	poolDictionaries: ''
	category: 'FM-Text'!
AttributedTextModel comment:
'The AttributedTextModel used to maintain text for the various text editors.  It can be viewed as the convergence of the actual text data with the desired text attributes.  This model is a abstract model type that is designed to be independent of where and how the data is stored.  The model supports protocol to allow various concrete models to exchange sufficient information to allow specialized data handling (such as in Xanadu waldos which perform move, copy, and replace operations in special ways when all of the information is on the backend).

	The model supports the following groups of protocol:
	
	accessing:
		This protocol allows access the basic data in the model (that is, the text).

	attributes:
		This protocol allows the accessing of the attributes on the text. The model uses an abstract type to describe the particular attributes for a (simple) region of the text. The concrete attributes descriptions are system dependent. 
	
	manipulating:
		This protocol is used to modify (side effect) the data referenced by the model.  These operations perform all of the basic text manipulation operations.
'!

(AttributedTextModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class AttributedTextModel */
';
	attributes: ((Set new) add: #DEFERRED; yourself)!

!AttributedTextModel methodsFor: 'accessing'!

{AttributedTextModel} copy: reg {XnRegion}
	"Return an AttributedTextModel for the specified region."
	self subclassResponsibility!

{IntegerVar} count
	"return the number of known elements (characters) in the text"

	self subclassResponsibility! !

!AttributedTextModel methodsFor: 'text accessing'!

{MuWordArray} asDataTable
	self subclassResponsibility!

{void} commitInserts
	"This is a null routine which is to be overridden by subclasses that must
	perform some action to ensure that recent changes are committed."!

{Heaper} fetch: pos {Position}
	self subclassResponsibility!

{Heaper} intFetch: pos {IntegerVar}
	self subclassResponsibility! !

!AttributedTextModel methodsFor: 'attributes'!

{void} applyAttributes: attr {AttributeGroup} with: reg {XnRegion}

	self subclassResponsibility!

{ScruTable of: (Pair of: AttributeGroup and: XnRegion)} attributes
	self subclassResponsibility!

{AttributeGroup} attributesAt: pos {Position} 
	"return the attribute link types mapped to their corresponding 
	attribute type (as specified in the creation of this model) 
	for the specified position"

	^self attributesAtInt: (pos cast: IntegerPos) asIntegerVar!

{AttributeGroup} attributesAtInt: pos {IntegerVar} 
	"return the attribute link types mapped to their corresponding 
	attribute type (as specified in the creation of this model) 
	for the specified position"

	self subclassResponsibility!

{void} removeAttributes: attr {AttributeGroup} with: reg {XnRegion}

	self subclassResponsibility!

{XnRegion} runAt: pos {Position}

	"Return the object at the specified position"
	
	^ self runAtInt: (pos cast: IntegerPos) asIntegerVar!

{XnRegion} runAtInt: pos {IntegerVar}

	self subclassResponsibility! !

!AttributedTextModel methodsFor: 'manipulating'!

{void} deflate: reg {XnRegion} 
	"remove the specified region"

	self subclassResponsibility!

{void} insert: pos {IntegerVar} with: attrText {AttributedTextModel}
	"insert the string before pos"
	self subclassResponsibility!

{void} insertCopy: pos {IntegerVar} with: other {AttributedTextModel} with: reg {XnRegion} 
	"copy a string from the other text (region cut1 to cut2) to the position pos"

	self subclassResponsibility!

{void} insertWordArray: pos {IntegerVar} with: chars {MuWordArray}
	"insert the string before pos"
	self subclassResponsibility!

{void} move: pos {IntegerVar} with: other {AttributedTextModel} with: reg {XnRegion}
	"move the text in region reg in other to before pos in me.  Remove from other.  Equivalent to
	rearrange if other == this"
	
	self subclassResponsibility!

{void} rearrangeRegion: pos {IntegerVar} with: reg {XnRegion}
	"move the text between cut1 and cut2 to before pos in me.  i.e. swap two blocks of text"
	
	self subclassResponsibility!

{void} replace: reg {XnRegion} with: attrText {AttributedTextModel}
	"equivalent to
	this->deflate (pos, len);
	this->insert (pos, string)"
	
	self subclassResponsibility!

{void} replaceWithWordArray: reg {XnRegion} with: string {MuWordArray}
	"equivalent to
	this->deflate (pos, len);
	this->insert (pos, string)"
	
	self subclassResponsibility! !

!AttributedTextModel methodsFor: 'testing'!

{UInt32} hashForEqual
	^self asOop!

{BooleanVar} isEqual: other {Heaper} 
	^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

AttributedTextModel class
	instanceVariableNames: ''!

(AttributedTextModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class AttributedTextModel */
';
	attributes: ((Set new) add: #DEFERRED; yourself)!

!AttributedTextModel class methodsFor: 'pseudo constructors'!

make.char: aChar {Character var} with: attributes {AttributeGroup default: NULL}

	| words {MuWordArray} |
	self hack.
	words _ MuWordArray make.IntegerVar: 1.
	words atInt: IntegerVar0 store: (Sequence one: aChar).
	^LocalTextModel create: words with: attributes!

make.WordArray: chars {MuWordArray} with: attributes {AttributeGroup default: NULL}

	^ LocalTextModel create: chars with: attributes! !

!AttributedTextModel class methodsFor: 'smalltalk: creation'!

make.char: aChar {Character var}

	| words {MuWordArray} |
	self hack.
	words _ MuWordArray make.IntegerVar: 1.
	words atInt: IntegerVar0 introduce: (Sequence one: aChar).
	^ LocalTextModel create: words with: NULL!

make.WordArray: chars {MuWordArray}

	^ LocalTextModel create: chars with: NULL!

make: aText {Text.X} with: mappings {HashTable}
self passe.
	^ self create: aText with: mappings! !

!AttributedTextModel class methodsFor: 'smalltalk: initialization'!

{void} cleanupGarbage
	self linkTimeNonInherited!

{void} initTimeNonInherited
	| alphabet {FMAlphabet} |
	self REQUIRES: FMAlphabet.
	self REQUIRES: ImmuSet.
	self REQUIRES: Stepper.
	self REQUIRES: Sequence.
	alphabet _ FMAlphabet asciiAlphabet.make.
	NoAttributes _ alphabet makeRunDescription: ImmuSet make.
	ReversedAttributes _ alphabet makeRunDescription: (ImmuSet make with: (Sequence string: 'reversed'))!

{void} linkTimeNonInherited
	"AttributedTextModel cleanupGarbage"
	NoAttributes _ NULL.
	ReversedAttributes _ NULL! !

!AttributedTextModel class methodsFor: 'protected: accessing'!

{AttributeGroup} noAttributes
	^NoAttributes!

{AttributeGroup} reversedAttributes
	^ReversedAttributes! !