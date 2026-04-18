'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:20 pm'!

AttributedTextModel subclass: #SelectedTextModel
	instanceVariableNames: '
		myText {AttributedTextModel}
		mySelection {SelectionRange}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Text'!

(SelectedTextModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class SelectedTextModel */
friend SPTR(SelectedTextModel)  selectedTextModel (AttributedTextModel * text, SelectionRange * selection);
friend SPTR(SelectedTextModel)  selectedTextModel (AttributedTextModel * text);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SelectedTextModel methodsFor: 'attributes'!

{void} applyAttributes: attr {AttributeGroup} with: reg {XnRegion}

	myText applyAttributes: attr with: reg!

{ScruTable of: (Pair of: AttributeGroup and: XnRegion)} attributes
	self unimplemented.
	^NULL!

{AttributeGroup} attributesAt: pos {Position} 
	"return the attribute link types mapped to their corresponding 
	attribute type (as specified in the creation of this model) 
	for the specified position"
	^self attributesAtInt: (pos quickCast: IntegerPos) asIntegerVar!

{AttributeGroup} attributesAtInt: pos {IntegerVar} 
	"return the attribute link types mapped to their corresponding 
	attribute type (as specified in the creation of this model) 
	for the specified position"
	| sub {AttributeGroup} |
	sub _ myText attributesAtInt: pos.
	(mySelection ~~ NULL and: 
			[(mySelection selection cast: IntegerRegion) hasIntMember: pos])
		ifTrue: [sub == NoAttributes
			ifTrue: [^ReversedAttributes]
			ifFalse: [self unimplemented. ^NULL]]
		ifFalse: [^sub]!

{void} removeAttributes: attr {AttributeGroup unused} with: reg {XnRegion unused}

	self unimplemented!

{XnRegion} runAtInt: pos {IntegerVar} 
	| dRun {XnRegion} sel {IntegerRegion} |
	dRun _ myText runAtInt: pos.
	sel _ mySelection selection quickCast: IntegerRegion.
	sel isEmpty
		ifTrue: [^dRun]
		ifFalse: [^dRun intersect: (sel runAt: pos)]! !

!SelectedTextModel methodsFor: 'accessing'!

{AttributedTextModel} copy: reg {XnRegion}
	"Return an AttributedTextModel for the specified region."
	^SelectedTextModel make: (myText copy: reg)!

{IntegerVar} count
	"return the number of known elements (characters) in the text"
	^myText count!

{SelectionRange} selection
	^mySelection! !

!SelectedTextModel methodsFor: 'text accessing'!

{MuWordArray} asDataTable
	^myText asDataTable!

{void} commitInserts
	myText commitInserts!

{Heaper} fetch: pos {Position}
	^myText fetch: pos!

{Heaper} intFetch: pos {IntegerVar}
	^myText intFetch: pos! !

!SelectedTextModel methodsFor: 'manipulating'!

{void} deflate: region {XnRegion} 
	"remove the specified region. 
	heh 7 October 1990 
	Note that the selection region is updated first. This is due to a 
	requirement of the recomposition code. The deflate: region message 
	here causes an update to occur, which is passed by this model onto 
	its dependents. i.e. the recomposition objects. Since the message 
	causes recomposition to occur, the selection must match the text at 
	the time of the recomposition for it to be correct. Therefore, the 
	selection is updated first (also possibly causing a recomposition) so 
	that it will be in synch with the altered text when the 
	recomposition actually happens. The possible recomposition caused 
	by the changing of the selection is not as much of a problem, 
	because it is essentially the removal of the selected attributes from 
	the model. This has little effect, where recomposing the text with 
	an incorrect selection has a large effect."

	| span {IntegerRegion} |
	span _ region quickCast: IntegerRegion.
	span isBoundedAbove
		ifTrue: [mySelection setSelectionPosition: (((span complement quickCast: IntegerRegion) compactor ofInt: span stop)
					min: myText count - region count)]
		ifFalse: [mySelection setSelectionPosition: myText count - region count].
	myText deflate: region!

{void} insert: pos {IntegerVar} with: attrText {AttributedTextModel}
	"insert the string before pos"
	myText insert: pos with: attrText.
	mySelection setSelectionPosition: pos!

{void} insertCopy: pos {IntegerVar} with: other {AttributedTextModel} with: reg {XnRegion} 
	"copy a string from the other text (region cut1 to cut2) to the position pos"

	myText insertCopy: pos with: other with: reg!

{void} insertWordArray: pos {IntegerVar} with: chars {MuWordArray}
	"insert the string before pos"
	myText insertWordArray: pos with: chars.
	mySelection setSelectionPosition: pos!

{void} move: pos {IntegerVar} with: other {AttributedTextModel} with: reg {XnRegion}
	"move the text in region reg in other to before pos in me.  Remove from other.  Equivalent to
	rearrange if other == this"
	myText move: pos with: other with: reg!

{void} rearrangeRegion: pos {IntegerVar} with: reg {XnRegion}
	"move the text between cut1 and cut2 to before pos in me.  i.e. swap two blocks of text"
	myText rearrangeRegion: pos with: reg!

{void} replace: reg {XnRegion} with: attrText {AttributedTextModel}
	"equivalent to
	this->deflate (pos, len);
	this->insert (pos, string)"
	myText replace: reg with: attrText!

{void} replaceWithWordArray: reg {XnRegion} with: string {MuWordArray}
	"equivalent to
	this->deflate (pos, len);
	this->insert (pos, string)"
	myText replaceWithWordArray: reg with: string! !

!SelectedTextModel methodsFor: 'updating'!

{void} update: update {UpdateRecord} from: sender {XnModel} 
	"The strange double cast on the next line is due to an  X++ 
	deficiency about SP2<->CP2"
	"conversions."

	((myText basicCast: XnModel) == sender or: [(mySelection basicCast: XnModel) == sender])
		ifTrue: [self changed: update]! !

!SelectedTextModel methodsFor: 'protected: creation'!

create: text {AttributedTextModel} with: selection {SelectionRange}
	super create.
	myText _ text.
	myText addDependent: self.
	mySelection _ selection.
	mySelection addDependent: self!

{void} destruct
	mySelection removeDependent: self.
	mySelection _ NULL.
	myText removeDependent: self.
	myText _ NULL.
	super destruct! !

!SelectedTextModel methodsFor: 'printing'!

{void} printOn: aStream {ostream reference} 
	aStream << self getCategory name << ' on (' << myText << ' selecting ' << mySelection << ') '! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

SelectedTextModel class
	instanceVariableNames: ''!

(SelectedTextModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class SelectedTextModel */
friend SPTR(SelectedTextModel)  selectedTextModel (AttributedTextModel * text, SelectionRange * selection);
friend SPTR(SelectedTextModel)  selectedTextModel (AttributedTextModel * text);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!SelectedTextModel class methodsFor: 'pseudo constructors'!

make: text {AttributedTextModel} 
	| aSelect {SelectionRange} |
	aSelect _ SelectionRange make.
	^self create: text with: aSelect!

make: text {AttributedTextModel} with: selection {SelectionRange}
	^self create: text with: selection! !