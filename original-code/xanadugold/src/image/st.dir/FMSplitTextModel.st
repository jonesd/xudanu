'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:48 pm'!

FMSuperTextModel subclass: #FMSplitTextModel
	instanceVariableNames: '
		myKids {MuTable of: FMTextModel}
		myMaxes {IntegerVarArray}
		myOriginCache {IntegerVarArray}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!
FMSplitTextModel comment:
'The FMSplitTextModel performs two main functions.  First, it is the composite text model used for structures such as paragraphs and lines.  It maintains submodels for its components and provides correct access to the AttributedTextModel (text source).  Second, it also provides a recomposition aid to the paragraph director.  It does this by maintaining the maximum number of characters that each submodel could compose, along with how much they actually hold when correctly composed.  This is of interest because a line model (which is also a splitmodel) could compose characters all the way to its margin, but normally stops at a word break.  Because of this, a change in the text between the actual break and the maximum break of a line should cause the line to be recomposed, even though those characters are actually composed into the next line.
	
	This is some text being composed.  This is some text being composed.
	                            ^       ^                          ^   ^
	                            |        |                           |    maximum break line 2
	                            |        |                           actual break line 2
	                            |        maximum break line 1
	                            actual break line 1
(the picture is off a bit because this is not monospace font...)

This shows how the split model may be thought of.  The splitFor: message uses the maximum positions to decide what lines are affected by a particular change.  A change before the maximum position affects the line before, if the change is after the maximum, it cannot affect the previous lines, so recomposition can ignore them.'!

(FMSplitTextModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMSplitTextModel */
friend SPTR(FMSplitTextModel) fMSplitTextModel (FMSuperTextModel * onParent);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMSplitTextModel methodsFor: 'split accessing'!

{void} append: newModel {FMTextModel}

	myKids isEmpty
		ifTrue: [myKids atInt: IntegerVar0 introduce: newModel.
			myMaxes at: IntegerVar0 DOTasInt storeIntegerVar: IntegerVar0.
			myOriginCache at: IntegerVar0 DOTasInt storeIntegerVar: IntegerVar0.
			newModel setIndex: IntegerVar0 DOTasInt]
		ifFalse: [ | nextSpot {IntegerVar} |
			self checkSize: (nextSpot _ (myKids domain cast: IntegerRegion) stop).
			myKids atInt: nextSpot introduce: newModel.
			myMaxes at: nextSpot DOTasInt storeIntegerVar: IntegerVar0.
			myOriginCache at: nextSpot DOTasInt storeIntegerVar: (self calcOriginOf: nextSpot).
			newModel setIndex: nextSpot]!

{IntegerMapping} dspAt: index {IntegerVar}

	^ IntegerMapping make: (self originOf: index)!

{FMTextModel} fetch: index {IntegerVar}

	^ (myKids intFetch: index) cast: FMTextModel!

{FMTextModel} get: index {IntegerVar}

	^ (myKids intGet: index) cast: FMTextModel!

{IntegerVar} splitFor: pos {IntegerVar}
	| split {IntegerVar} curOrigin {IntegerVar} |
	split _ IntegerVar0.
	curOrigin _ IntegerVar0.
	[split >= myKids count or: [pos < (curOrigin + (myMaxes integerVarAt: split DOTasLong))]] whileFalse: [
		curOrigin _ curOrigin + ((myKids intGet: split) cast: FMTextModel) charCount.
		split _ split + 1].
	split <= IntegerVar0 
		ifTrue: [^ IntegerVar0]
		ifFalse: [split > (myKids count - 1) ifTrue: [^ myKids count - 1]].
	^ split!

{void} wipe: index {IntegerVar} 
	self parent deltaCount: self index with: (self lengthOf: index) negated.
	myKids intWipe: index.
	index < myMaxes count 
		ifTrue: [myMaxes at: index DOTasInt storeIntegerVar: IntegerVar0 DOTasInt.
				myOriginCache at: index DOTasInt storeIntegerVar: IntegerVar0  ]! !

!FMSplitTextModel methodsFor: 'line compose setting'!

{void} setMax: aMax {IntegerVar} 
	"This method is used by a line composer to set the maximum length 
	of a line split to the specified value. This information is used to 
	determine which lines are of interest when a specific position is 
	modified"

	self parent setMaxOf: self index with: aMax! !

!FMSplitTextModel methodsFor: 'protected: creation'!

create: withParent {FMSuperTextModel}

	super create: withParent.
	myKids _ MuArray array.
	myMaxes _ IntegerVarArray zeros: 4.
	myOriginCache _ IntegerVarArray zeros: 4.! !

!FMSplitTextModel methodsFor: 'subclass accessing'!

{AttributeGroup} attributesAt: charPos {IntegerVar} with: index {IntegerVar}

	"This method returns the character attributes for the specified position
	relative to the start of the specified child (index)"
	
	^ self parent attributesAt: (charPos + (self originOf: index)) with: (self index)!

{IntegerVar} charLimitOf: index {IntegerVar} 
	"This method is a request from a child to a parent to return the 
	number of characters that the child could possibly be concerned 
	with."
 
	^ self charLimit - (self originOf: index)!

{MuWordArray} charsFor: index {IntegerVar} with: limit {IntegerVar} 
	"This method returns the characters specifically for the specified 
	child. If limit is zero, then return all chars to the end of the run, 
	otherwise restrict the count returned to limit."

	| startIndex {IntegerVar} endIndex {IntegerVar} chars {MuWordArray} tmpDsp{Dsp} |
	startIndex _ self originOf: index.
	limit == IntegerVar0
		ifTrue: [endIndex _ self charLimit]
		ifFalse: [endIndex _ startIndex + limit].
	chars _ self parent charsFor: self index with: endIndex.
	startIndex == IntegerVar0
		ifTrue: [^chars  ]
		ifFalse: [ tmpDsp _ IntegerMapping make: startIndex.
		
		
		^((chars subTableBetween: startIndex with: endIndex )
			transformedBy: (tmpDsp inverse cast: Dsp)) cast: MuWordArray ]!

{void} deltaCount: index {IntegerVar} with: delta {IntegerVar} 
	"This method is used by kids of split models (runs or other splitmodels) 
	to update the origin information in the splitModel."
	index DOTasInt + 1 almostTo: (myKids count DOTasInt) do: [:idx {Int32} | 
		myOriginCache at: idx storeIntegerVar: ((myOriginCache integerVarAt: idx) + delta)].
	self parent deltaCount: self index with: delta!

{IntegerVar} indexOf: child {FMTextModel}

	"This method returns the parents index for the specified child"
	
	^ (myKids backfollowFrom: child) stepper index!

{IntegerRegion} runAt: pos {IntegerVar} with: index {IntegerVar}

	"This method returns the domain of the attribute run containing the position pos"
	
	| reg {IntegerRegion} org {IntegerVar} |
	reg _ self parent runAt: (pos + (org _ self originOf: index)) with: self index.
	reg isEmpty 
		ifTrue: [^ reg]
		ifFalse: [reg isSimple not
			ifTrue: [Heaper BLAST: #AttributesRegionTooComplex]].
	^ IntegerRegion make: (reg start - org) with: (reg stop - org).
	"^ ((self dspAt: index) inverse of: reg) intersect: (IntegerRegion after: IntegerVar0)"! !

!FMSplitTextModel methodsFor: 'private: offsets'!

{IntegerVar} calcOriginOf: index {IntegerVar} 
	index == IntegerVar0 ifTrue: [^IntegerVar0].
	^(myOriginCache integerVarAt: index DOTasInt - 1) + (self lengthOf: index   DOTasInt - 1)!

{void} checkSize: newSpot {IntegerVar}
	myMaxes count > newSpot DOTasInt ifFalse: 
		[myMaxes _ myMaxes copyGrow: newSpot DOTasInt.
		myOriginCache _ myOriginCache copyGrow: newSpot DOTasInt]!

{IntegerVar} lengthOf: index {IntegerVar}

	"brute force for now"
	^ ((myKids intGet: index) cast: FMTextModel) charCount!

{IntegerVar} originOf: index {IntegerVar}

	^ myOriginCache integerVarAt: index DOTasInt! !

!FMSplitTextModel methodsFor: 'accessing'!

{IntegerVar} charCount
	"This methods returns the number of characters in the model."

	| idx {IntegerVar} |
	(idx _ myKids count) == IntegerVar0 ifTrue: [^ IntegerVar0].
	^ (self originOf: (idx _ idx - 1)) + (self lengthOf: idx)
	"res _ IntegerVar0.
	IntegerVar0 almostTo: self splitCount do: [:idx {IntegerVar} | 
		res _ res + (myKids get.IntegerVar: idx) charCount].
	^res"!

{IntegerVar} charLimit
	"This method returns the maximum number of characters that this 
	model can return."

	^ self parent charLimitOf: self index!

{MuWordArray} chars
	"This method returns all of the characters in the model"

	^self parent charsFor: self index with: self charCount!

{IntegerVar} splitCount
	"Return the number of splits I contain"
	
	^ myKids count! !

!FMSplitTextModel methodsFor: 'protected: accessing'!

{void} setMaxOf: index {IntegerVar} with: aMax {IntegerVar} 
	"This method is used by a line composer to set the maximum length 
	of a line split to the specified value. This information is used to 
	determine which lines are of interest when a specific position is 
	modified"

	myMaxes at: index DOTasInt storeIntegerVar: aMax! !

!FMSplitTextModel methodsFor: 'smalltalk: smalltalk debugging'!

kids
^ myKids! !

!FMSplitTextModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 
	oo << self getCategory name << '('.
	myKids isEmpty
		ifTrue: [oo << 'empty']
		ifFalse: [IntegerVar0 almostTo: myKids count do: [:idx {IntegerVar} | 
			oo << ((self originOf: idx) + (self lengthOf: idx)) << ', ']].
	oo << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMSplitTextModel class
	instanceVariableNames: ''!

(FMSplitTextModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMSplitTextModel */
friend SPTR(FMSplitTextModel) fMSplitTextModel (FMSuperTextModel * onParent);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMSplitTextModel class methodsFor: 'pseudoconstructors'!

make: onParent {FMSuperTextModel}

	^ self create: onParent! !