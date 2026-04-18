'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:22 pm'!

XnModel subclass: #LinkEndsModel
	instanceVariableNames: '
		myApplication {TapestryAppModel}
		myEnds {ListModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!
LinkEndsModel comment:
'A list of link ends that keeps track of the last entry. '!

(LinkEndsModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class LinkEndsModel */
friend SPTR(LinkEndsModel) linkEndsModel (IntegerTable * onTable);
friend SPTR(LinkEndsModel) linkEndsModel ();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkEndsModel methodsFor: 'accessing'!

{ListModel of: AttributedTextModel} descriptionList
	| furniture {Accumulator} |
	furniture _ MuArray arrayAccumulator.
	myEnds asTable stepper forEach: [:end {LinkEnd} | | desc
{XuText} |
		desc _ end fetchDescriptor cast: XuText.
		desc == NULL ifTrue: [desc _ end getEndContext cast:
XuText].
		furniture step: (WaldoTextModel
attributedTextModel.Text: desc)].
	^ListModel make.IntegerTable: (furniture value cast:
IntegerTable)!

{LinkEnd} fetch: index {IntegerVar} 
	^ (myEnds fetch: index) cast: LinkEnd!

{AttributedTextModel} fetchDescription: index {IntegerVar} 
	| end {LinkEnd} desc {XuText} |
	end _ (myEnds fetch: index) cast: LinkEnd.
	end == NULL ifTrue: [^NULL].
	desc _ end fetchDescriptor cast: XuText.
	desc == NULL ifTrue: [desc _ end getEndContext cast: XuText].
	^WaldoTextModel attributedTextModel.Text: desc!

{LinkEnd} lastEnd
	"the link end last inserted into the list"
	myEnds count == IntegerVar0
		ifTrue: [Heaper BLAST: #NoLinkEnds].
	^(myEnds get: (myEnds count - 1)) cast: LinkEnd!

{void} store: end {LinkEnd}
	"store a new link end at the end of the list"

	myEnds insert: myEnds count with: end! !

!LinkEndsModel methodsFor: 'manipulating'!

{void} insert: index {IntegerVar} with: insertee {Heaper}

	myEnds insert: index with: (insertee cast: LinkEnd)!

{void} replace: index {IntegerVar} with: insertee {Heaper}

	myEnds replace: index with: (insertee cast: LinkEnd)!

{void} wipe: area {XnRegion}

	myEnds wipe: area! !

!LinkEndsModel methodsFor: 'private: create'!

create

	super create.
	myEnds _ ListModel make.
	myEnds addDependent: self!

create: onTable {IntegerTable}

	super create.
	myEnds _ ListModel make: onTable.
	myEnds addDependent: self!

{void} destruct

	myEnds removeDependent: self.
	myEnds _ NULL.
	super destruct! !

!LinkEndsModel methodsFor: 'updating'!

{void} update: ur {UpdateRecord} from: sender {XnModel}

	sender == (myEnds basicCast: XnModel) ifTrue: [self changed: ur]! !

!LinkEndsModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}
	
	 oo <<  self getCategory name << '(' << '  myApplication' << myApplication << ' myEnds ' <<	myEnds  << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

LinkEndsModel class
	instanceVariableNames: ''!

(LinkEndsModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class LinkEndsModel */
friend SPTR(LinkEndsModel) linkEndsModel (IntegerTable * onTable);
friend SPTR(LinkEndsModel) linkEndsModel ();';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!LinkEndsModel class methodsFor: 'pseudo constructors'!

make
	^self create!

make: onTable {IntegerTable}
	^self create: onTable! !