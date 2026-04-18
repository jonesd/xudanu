'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:24 pm'!

DocumentModel subclass: #PassageModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(PassageModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PassageModel methodsFor: 'accessing'!

{Int32} compare: a {XnRegion} with: b {XnRegion}
	"compare the two regions according to where they are in the document,
	returning -1, 0, or 1 if a < b, a = b, or a > b respectively"
	| x {IntegerRegion} y {IntegerRegion} |
	x _ a quickCast: IntegerRegion.
	y _ b quickCast: IntegerRegion.
	x isEmpty ifTrue:
		[y isEmpty ifTrue: [^ Int0] ifFalse: [^ -1]].
	y isEmpty ifTrue: [^1].
	x isBoundedBelow
		ifTrue: [y isBoundedBelow
			ifTrue: [x start < y start
				ifTrue: [^-1]
				ifFalse: [x start = y start
					ifTrue: [^Int0]
					ifFalse: [^1]]]
			ifFalse: [^1]]
		ifFalse: [y isBoundedBelow
			ifTrue: [^-1]
			ifFalse: [^Int0]]!

{Waldo} contentsWaldo
	"the sub waldo that holds the document contents
	-- DO NOT MODIFY -- USE MODEL INSTEAD --"
	^self xuText!

{LinkEnd} createLinkEnd: selection {SelectionObject default: NULL}
	"create a new link end on the selected stuff"
	| region {XnRegion} |
	(selection == NULL or: [(region _ selection selection) isEmpty])
		ifTrue: [^LinkEnd make: self xuText keyMaster with: self xuText]
		ifFalse: [^LinkEnd make: self xuText keyMaster with: region with: self xuText]!

{void} setWaldo: id {ID}
		with: workType {PackOBits default: NULL}
		with: phantom {BooleanVar default: true}
		with: km {KeyMaster default: NULL}
	super setWaldo: id with: workType with: phantom with: km.
	self fetchContents ~~ NULL ifTrue: [self fetchContents destroy].
	self setContents: (WaldoTextModel attributedTextModel.Text: self xuText)!

{XuText} xuText
	^self waldo cast: XuText! !

!PassageModel methodsFor: 'create'!

create: doc {XuText}
	| contents {WaldoTextModel} |
	super create: doc.
	contents _ (WaldoTextModel attributedTextModel.Text: doc) cast: WaldoTextModel.
	self setContents: contents.! !

!PassageModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
oo<<  self getCategory name << '()'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

PassageModel class
	instanceVariableNames: ''!

(PassageModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!PassageModel class methodsFor: 'make'!

make: doc {XuText}
	^self create: doc! !