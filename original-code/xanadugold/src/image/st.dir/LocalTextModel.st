'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:19 pm'!

AttributedTextModel subclass: #LocalTextModel
	instanceVariableNames: '
		charsInternal {MuWordArray}
		runsInternal {AttributeGroup}
		mangler {WordArrayWaldo}'
	classVariableNames: ''
	poolDictionaries: 'TextConstants '
	category: 'FM-Text'!

(LocalTextModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class LocalTextModel */
friend SPTR(AttributedTextModel) attributedTextModel (XuWordArray *, AttributeGroup * attributes/* = NULL*/);
friend SPTR(AttributedTextModel)  attributedTextModel (char aChar, AttributeGroup * attributes/* = NULL*/);
friend SPTR(LocalTextModel) localTextModel (XuWordArray *, AttributeGroup *);
';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LocalTextModel methodsFor: 'accessing'!

{AttributedTextModel} copy: reg {XnRegion} 
	"Return an AttributedTextModel for the specified region."

	^((charsInternal subTable: reg) convert: AttributedTextModel)
		cast: AttributedTextModel!

{IntegerVar} count
	^charsInternal count! !

!LocalTextModel methodsFor: 'text accessing'!

{MuWordArray} asDataTable
	^(charsInternal copy) cast: MuWordArray!

{Heaper} fetch: index {Position}
	^charsInternal fetch: index!

{Heaper} intFetch: index {IntegerVar}
	^charsInternal intFetch: index! !

!LocalTextModel methodsFor: 'attributes'!

{void} applyAttributes: attrs {AttributeGroup unused} with: region {XnRegion unused}

	self unimplemented!

{ScruTable of: (Pair of: AttributeGroup and: XnRegion)} attributes
	^ MuArray array: AttributeGroup asciiAttributes.make.!

{AttributeGroup} attributesAt: pos {Position} 
	"Get an alphabet object for this run. Ask the it for a new runDescription on the 
	attributes for this run. The runDescription will know how to handle fonts, 
	attributes, and displaying for characters in this run's alphabet."

	^self attributesAtInt: (pos cast: IntegerPos) asIntegerVar!

{AttributeGroup} attributesAtInt: index {IntegerVar unused} 
	"Get an alphabet object for this run. Ask the it for a new runDescription on the 
	attributes for this run. The runDescription will know how to handle fonts, 
	attributes, and displaying for characters in this run's alphabet."
	^AttributedTextModel noAttributes!

{void} removeAttributes: attr {AttributeGroup unused} with: reg {XnRegion unused}

	self unimplemented!

{XnRegion} runAt: key {Position} 
	^self runAtInt: (key quickCast: IntegerPos) asIntegerVar!

{XnRegion} runAtInt: index {IntegerVar unused}
	^ charsInternal domain
	"^ IntegerRegion make: index with: (runsInternal runLengthAt: index)"! !

!LocalTextModel methodsFor: 'manipulating'!

{void} deflate: reg {XnRegion} 
	"remove the specified region"
	self check.
	mangler deflate: reg.
	self changed: (DeletionUR make: (reg cast: IntegerRegion))!

{void} insert: pos {IntegerVar} with: attrText {AttributedTextModel}
	"insert the string before pos"
	 self insertWordArray: pos with: attrText asDataTable.
	 self changed: (InsertionUR make: pos integer with: attrText count)!

{void} insertCopy: pos {IntegerVar} with: other {AttributedTextModel} with: reg {XnRegion} 
	"copy a string from the other text (region cut1 to cut2) to the position pos"

	self insert: pos with: (other copy: reg)!

{void} insertWordArray: pos {IntegerVar} with: chars {MuWordArray}
	"insert the string before pos"
	 self check.
	 mangler insertAll.IntegerVar: pos with: chars!

{void} move: pos {IntegerVar} with: other {AttributedTextModel} with: reg {XnRegion}
	"move the text in region reg in other to before pos in me.  Remove from other.
	Equivalent to rearrange if other == this"
	
	other == self ifTrue: [self rearrangeRegion: pos with: reg].
	self insertCopy: pos with: other with: reg.
	other deflate: reg!

{void} rearrange: pos {IntegerVar unused} with: cut1 {IntegerVar unused} with: cut2 {IntegerVar unused}
	"move the text between cut1 and cut2 to before pos in me.  i.e. swap two blocks of text"
	 self unimplemented!

{void} rearrangeRegion: pos {IntegerVar} with: reg {XnRegion} 
	"move the text between cut1 and cut2 to before pos in me. i.e. swap 
	two blocks of text"

	reg 
		cast: IntegerRegion into: [:ir |
			self
				rearrange: pos
				with: ir start
				with: ir stop]
		others: [self unimplemented]!

{void} replace: reg {XnRegion unused} with: attrText {AttributedTextModel unused}
	"equivalent to
	this->deflate (pos, len);
	this->insert (pos, string)"
	 self unimplemented!

{void} replaceWithWordArray: reg {XnRegion} with: string {MuWordArray}
	"equivalent to
	this->deflate (pos, len);
	this->insert (pos, string)"
	| lr {IntegerRegion} |
	lr _ reg cast: IntegerRegion.
	self deflate: reg.
	self insertWordArray: lr start with: string.! !

!LocalTextModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}

	oo << 'local on ' << charsInternal! !

!LocalTextModel methodsFor: 'private: private'!

{void} check

	mangler == NULL ifTrue: [mangler _ WordArrayWaldo make: charsInternal]! !

!LocalTextModel methodsFor: 'protected: creation'!

create: chars {MuWordArray} with: runs {AttributeGroup default: NULL}
	super create.
	charsInternal _ chars.
	runsInternal _ runs.
	mangler _ NULL!

{void} destruct
	mangler ~~ NULL
		ifTrue: 
			[mangler destroy.
			mangler _ NULL].
	super destruct! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LocalTextModel class
	instanceVariableNames: ''!

(LocalTextModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class LocalTextModel */
friend SPTR(AttributedTextModel) attributedTextModel (XuWordArray *, AttributeGroup * attributes/* = NULL*/);
friend SPTR(AttributedTextModel)  attributedTextModel (char aChar, AttributeGroup * attributes/* = NULL*/);
friend SPTR(LocalTextModel) localTextModel (XuWordArray *, AttributeGroup *);
';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LocalTextModel class methodsFor: 'pseudo constructors'!

make: wordArray {MuWordArray} with: attributes {AttributeGroup default: NULL}

	^ self create: wordArray with: attributes! !

!LocalTextModel class methodsFor: 'smalltalk: smalltalk defaults'!

make: wordArray {MuWordArray}

	^ self create: wordArray with: NULL! !