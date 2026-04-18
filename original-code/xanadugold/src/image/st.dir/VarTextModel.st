'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:57:20 pm'!

AttributedTextModel subclass: #VarTextModel
	instanceVariableNames: '
		myVarATM {VariableModel of: AttributedTextModel}
		myWorkingATM {AttributedTextModel}
		myEditing {BooleanVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'FM-Text'!

(VarTextModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class VarTextModel */
friend SPTR(VarTextModel)  varTextModel (VariableModel OF1(AttributedTextModel) * onVarM);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!VarTextModel methodsFor: 'accessing'!

{AttributedTextModel} copy: reg {XnRegion}
	"Return an AttributedTextModel for the specified region."
	^ myWorkingATM copy: reg!

{IntegerVar} count
	"return the number of known elements (characters) in the text"

	^ myWorkingATM count! !

!VarTextModel methodsFor: 'attributes'!

{void} applyAttributes: attr {AttributeGroup} with: reg {XnRegion}

	myEditing ifTrue: [myWorkingATM applyAttributes: attr with: reg]!

{ScruTable of: (Pair of: AttributeGroup and: XnRegion)} attributes
	^ myWorkingATM attributes!

{AttributeGroup} attributesAtInt: pos {IntegerVar} 
	"return the attribute link types mapped to their corresponding 
	attribute type (as specified in the creation of this model) 
	for the specified position"

	^ myWorkingATM attributesAtInt: pos!

{void} removeAttributes: attr {AttributeGroup} with: reg {XnRegion}

	myEditing ifTrue: [myWorkingATM removeAttributes: attr with: reg]!

{XnRegion} runAtInt: pos {IntegerVar}

	^ myWorkingATM runAtInt: pos! !

!VarTextModel methodsFor: 'manipulating'!

{void} deflate: reg {XnRegion} 
	"remove the specified region"

	myEditing ifTrue: [myWorkingATM deflate: reg]!

{void} insert: pos {IntegerVar} with: attrText {AttributedTextModel}
	"insert the string before pos"
	myEditing ifTrue: [myWorkingATM insert: pos with: attrText]!

{void} insertCopy: pos {IntegerVar} with: other {AttributedTextModel} with: reg {XnRegion} 
	"copy a string from the other text (region cut1 to cut2) to the position pos"

	myWorkingATM insertCopy: pos with: other with: reg!

{void} insertWordArray: pos {IntegerVar} with: chars {MuWordArray}
	"insert the string before pos"
	myEditing ifTrue: [myWorkingATM insertWordArray: pos with: chars]!

{void} move: pos {IntegerVar} with: other {AttributedTextModel} with: reg {XnRegion}
	"move the text in region reg in other to before pos in me.  Remove from other.  Equivalent to
	rearrange if other == this"
	
	myEditing ifTrue: [myWorkingATM move: pos with: other with: reg]!

{void} rearrangeRegion: pos {IntegerVar} with: reg {XnRegion}
	"move the text between cut1 and cut2 to before pos in me.  i.e. swap two blocks of text"
	
	myEditing ifTrue: [myWorkingATM rearrangeRegion: pos with: reg]!

{void} replace: reg {XnRegion} with: attrText {AttributedTextModel}
	"equivalent to
	this->deflate (pos, len);
	this->insert (pos, string)"
	
	myEditing ifTrue: [myWorkingATM replace: reg with: attrText]!

{void} replaceWithWordArray: reg {XnRegion} with: string {MuWordArray}
	"equivalent to
	this->deflate (pos, len);
	this->insert (pos, string)"
	
	myEditing ifTrue: [myWorkingATM replaceWithWordArray: reg with: string]! !

!VarTextModel methodsFor: 'text accessing'!

{MuWordArray} asDataTable
	^ myWorkingATM asDataTable!

{void} commitInserts
	"This is a null routine which is to be overridden by subclasses that must
	perform some action to ensure that recent changes are committed."
	myEditing ifTrue: [myWorkingATM commitInserts]!

{Heaper} fetch: pos {Position}
	^ myWorkingATM fetch: pos!

{Heaper} intFetch: pos {IntegerVar}
	^ myWorkingATM intFetch: pos! !

!VarTextModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name.
	myEditing
		ifTrue: [oo << ' on ' << myWorkingATM]
		ifFalse: [oo << ' empty']! !

!VarTextModel methodsFor: 'private: creation'!

create: onVar {VariableModel of: AttributedTextModel}

	super create.
	myVarATM _ onVar.
	myVarATM addDependent: self.
	myWorkingATM _ NULL.
	myEditing _ false.
	self updateWorking.! !

!VarTextModel methodsFor: 'private: updating'!

{void} updateWorking
	| oldReg {XnRegion} nuReg {XnRegion} |
	myEditing
		ifTrue: [oldReg _ myWorkingATM asDataTable domain.
			myWorkingATM removeDependent: self]
		ifFalse: [oldReg _ IntegerRegion make].
	myVarATM fetchValue == NULL
		ifTrue: [self unimplemented.
			"myWorkingATM _ XuWordArray make convert: AttributedTextModel.
			myEditing _ false"]
		ifFalse: [myWorkingATM _ myVarATM getValue cast: AttributedTextModel.
			myEditing _ true].
	myEditing
		ifTrue: [nuReg _ myWorkingATM asDataTable domain.
			myWorkingATM addDependent: self]
		ifFalse: [nuReg _ IntegerRegion make].
	self changed: (RegionUR make: (nuReg simpleUnion: oldReg))! !

!VarTextModel methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel}

	(sender == (myWorkingATM basicCast: XnModel))
		ifTrue: [self changed: ur]
		ifFalse: [self updateWorking]! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VarTextModel class
	instanceVariableNames: ''!

(VarTextModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class VarTextModel */
friend SPTR(VarTextModel)  varTextModel (VariableModel OF1(AttributedTextModel) * onVarM);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!VarTextModel class methodsFor: 'make'!

make: onVarM {VariableModel of: AttributedTextModel}

	^ self create: onVarM! !