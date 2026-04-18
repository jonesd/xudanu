'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:21 pm'!

AttributedTextModel subclass: #WaldoTextModel
	instanceVariableNames: '
		wrappedText {XuText}
		charCache {MuWordArray}
		cacheWaldo {WordArrayWaldo}
		newTyping {MuWordArray}
		typingStart {IntegerVar}
		typingNext {IntegerVar}'
	classVariableNames: 'BadModelPositionSignal {Exception smalltalk} '
	poolDictionaries: ''
	category: 'FM-Text'!

(WaldoTextModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class WaldoTextModel */
friend SPTR(AttributedTextModel) attributedTextModel (XuText *);
friend SPTR(WaldoTextModel)  waldoTextModel (XuText * aText);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WaldoTextModel methodsFor: 'accessing'!

{AttributedTextModel} copy: reg {XnRegion}
	"Return an AttributedTextModel for the specified region."
	^ WaldoTextModel create: ((wrappedText copy: false with: reg with: wrappedText keyMaster) cast: XuText)!

{IntegerVar} count
	"return the number of known elements (characters) in the text"

	^self updatedCache count! !

!WaldoTextModel methodsFor: 'text accessing'!

{MuWordArray} asDataTable
	^self updatedCache!

{Heaper} fetch: pos {Position}

	"Return the object at the specified position"
	
	^ self intFetch: (pos cast: IntegerPos) asIntegerVar!

{Heaper} intFetch: pos {IntegerVar} 
	"Return the object at the specified position"

	^self updatedCache intFetch: pos! !

!WaldoTextModel methodsFor: 'attributes'!

{void} applyAttributes: attrs {AttributeGroup unused}
with: region {XnRegion unused}

	self unimplemented!

{ScruTable of: (Pair of: AttributeGroup and: XnRegion)} attributes
	self unimplemented.
	^NULL!

{AttributeGroup} attributesAtInt: pos {IntegerVar
unused} 
	"return the attributes mapped to their corresponding 
	attribute type (as specified in the creation of this
model) 
	for the specified position."
	^AttributedTextModel noAttributes!

{void} removeAttributes: attr {AttributeGroup unused}
with: reg {XnRegion unused}

	self unimplemented!

{XnRegion} runAtInt: pos {IntegerVar} 
	"Return the object at the specified position"
	^IntegerRegion make: pos with: self count! !

!WaldoTextModel methodsFor: 'testing'!

{BooleanVar} isEqual: other {Heaper} 
	^other isKindOf: WaldoTextModel! !

!WaldoTextModel methodsFor: 'manipulating'!

{void} deflate: reg {XnRegion} 
	"remove the specified region"
	| lReg {IntegerRegion} |
	
	lReg _ reg cast: IntegerRegion.
	(newTyping ~~ NULL and: [lReg stop == typingNext])
		ifTrue: [typingNext _ typingNext - 1.
			typingNext > typingStart
				ifTrue: [newTyping _ (newTyping subTableBetween: IntegerVar0 with: newTyping count - 1) cast: MuWordArray]
				ifFalse: [newTyping _ NULL]]
		ifFalse: 
			[self commitInserts.
			wrappedText deflate: lReg].
	charCache == NULL
		ifFalse: 
			[cacheWaldo == NULL ifTrue: 
				[cacheWaldo _ WordArrayWaldo make: charCache].
			cacheWaldo deflate: lReg.
			charCache _ cacheWaldo table cast: MuWordArray].
	self changed: (DeletionUR make: lReg)!

{void} insert: pos {IntegerVar} with: atm {AttributedTextModel} 
	"insert the string before pos" 

	self insertWordArray: pos with: atm asDataTable!

{void} insertCopy: pos {IntegerVar} with: other {AttributedTextModel} with: reg {XnRegion} 
	"copy a string from the other text (region cut1 to cut2) to the 
	position pos"

	self commitInserts.
	other 
		cast: WaldoTextModel into: [:wtm |
			wrappedText
				vcopy: pos
				with: (wtm waldo cast: XuText)
				with: reg]
		others: [self insert: pos with: (other copy: reg) asDataTable].
	charCache _ NULL.
	cacheWaldo _ NULL.
	self changedRegion: (IntegerRegion integerExtent: pos with: reg count)!

{void} insertWordArray: pos {IntegerVar} with: string
{MuWordArray} 
	"insert the string before pos"

	newTyping == NULL
		ifTrue: 
			[typingStart _ pos.
			typingNext _ pos + string count.
			newTyping _ string]
		ifFalse: [pos == typingNext
				ifTrue: [newTyping introduceAll: string with:
(IntegerMapping make: newTyping count) with: NULL.
					typingNext _ typingNext + string count]
				ifFalse: 
					[self commitInserts.
					typingStart _ pos.
					typingNext _ pos + string count.
					newTyping _ string]].
	charCache == NULL
		ifFalse: 
			[cacheWaldo == NULL ifTrue: 
				[cacheWaldo _ WordArrayWaldo make: charCache].
			cacheWaldo insertAll.IntegerVar: pos with: string.
			charCache _ cacheWaldo table cast: MuWordArray].
	self changed: (InsertionUR make: pos integer with: string
count)!

{void} move: pos {IntegerVar} with: other {AttributedTextModel} with: reg {XnRegion} 
	"move the text in region reg in other to before pos in me. Remove 
	from other. Equivalent to rearrange if other == this"

	self commitInserts.
	other 
		cast: WaldoTextModel into: [:wtm |
			wrappedText
				move: pos
				with: wtm waldo
				with: reg]
		others: [self insert: pos with: (other copy: reg) asDataTable.
			other deflate: reg].
	charCache _ NULL.
	cacheWaldo _ NULL.
	self changedRegion: (IntegerRegion make: pos with: pos + reg count)!

{void} rearrangeRegion: pos {IntegerVar} with: reg {XnRegion}
	"move the text between cut1 and cut2 to before pos in me.  i.e. swap two blocks of text"
	
	| lReg {IntegerRegion} |
	self commitInserts.
	lReg _ reg cast: IntegerRegion.
	lReg isSimple ifFalse: [Heaper BLAST: #NotSimpleRegion].
	wrappedText rearrange: pos with: lReg start with: lReg stop.
	charCache _ NULL.
	cacheWaldo _ NULL.
	self changedRegion: ((IntegerRegion make: pos) simpleUnion: reg)!

{void} replace: reg {XnRegion} with: other {AttributedTextModel} 
	"replaces a region with the the contents of the other model"

	self commitInserts.
	other 
		cast: WaldoTextModel into: [:wtm |
			wrappedText replace: reg
				with: wtm waldo]
		others: 
			[wrappedText replace: reg
				with: (XuText make: wrappedText keyMaster
					with: (other asDataTable asMuTable cast: MuWordArray))].
	charCache _ NULL.
	cacheWaldo _ NULL.
	self changedRegion: (reg simpleUnion: 
		(IntegerRegion integerExtent: (reg cast: IntegerRegion) start
			with: other count))!

{void} replaceWith: text {XuText}
	"entirely replace the text"
	| old {XnRegion} |
	old _ wrappedText domain.
	wrappedText _ text.
	charCache _ NULL.
	cacheWaldo _ NULL.
	newTyping _ NULL.
	typingStart _ typingNext _ IntegerVar0.
	self changedRegion: (old unionWith: wrappedText domain)!

{void} replaceWithWordArray: reg {XnRegion} with: string {MuWordArray} 
	"replaces the given region with the contents of the string."

	self commitInserts.
	wrappedText replace: reg with: (XuText make: wrappedText keyMaster with: string).
	charCache _ NULL.
	cacheWaldo _ NULL.
	self changedRegion: (reg simpleUnion: 
		(IntegerRegion integerExtent: (reg cast: IntegerRegion) start
			with: string count))! !

!WaldoTextModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << 'waldo ('.
	charCache == NULL
		ifTrue: [oo << wrappedText]
		ifFalse: [oo << 'cache ' << 
			(charCache subTable: (IntegerRegion make: IntegerVar0 with: 50))].
	oo << ')'! !

!WaldoTextModel methodsFor: 'protected: protected creation'!

create: newText {XuText}
	super create.
	
	wrappedText _ newText.
	charCache _ NULL.
	cacheWaldo _ NULL.
	newTyping _ NULL.!

{void} destruct
	wrappedText _ NULL.
	charCache _ NULL.
	cacheWaldo _ NULL.
	newTyping _ NULL.	
	super destruct! !

!WaldoTextModel methodsFor: 'private: private'!

{void} changedRegion: reg {XnRegion}

	self changed: (RegionUR make: reg).
	^ VOID!

{void} commitInserts
	newTyping == NULL ifTrue: [^ VOID].
	wrappedText insert: typingStart with: newTyping.
	newTyping _ NULL.
	charCache _ NULL.
	cacheWaldo _ NULL!

{MuWordArray} updatedCache
	charCache == NULL ifTrue:
		[self commitInserts.
		charCache _ wrappedText asDataTable asMuTable cast: MuWordArray].
	^charCache!

{XuText} waldo
	^ wrappedText! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

WaldoTextModel class
	instanceVariableNames: ''!

(WaldoTextModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class WaldoTextModel */
friend SPTR(AttributedTextModel) attributedTextModel (XuText *);
friend SPTR(WaldoTextModel)  waldoTextModel (XuText * aText);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!WaldoTextModel class methodsFor: 'pseudo constructors'!

{AttributedTextModel} attributedTextModel.Text: aText {XuText}

	^ WaldoTextModel create: aText!

make: aText {XuText}
	^ self create: aText! !