'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:02:50 pm'!

FMTextModel subclass: #FMTextRunModel
	instanceVariableNames: 'myLength {IntegerVar}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-txtview'!
FMTextRunModel comment:
'The FMTextRunModel represents a single run of text (composed and not).  A run will always break at a change in attributes in the AttributedTextModel, so a run will always have only a single set of attributes.  A run does not necessarily cover a complete run in the original model, because it may be split arbitrarily by the composition process.'!

(FMTextRunModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMTextRunModel */
friend SPTR(FMTextRunModel)  fMTextRunModel (FMSuperTextModel * onParent);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMTextRunModel methodsFor: 'accessing'!

{AttributeGroup} attributes

	^ self parent attributesAt: IntegerVar0 with: (self index)!

{IntegerVar} charCount
	"This methods returns the number of characters in the model."
	
	^ myLength!

{IntegerVar} charLimit

	^ (self parent runAt: IntegerVar0 with: self index) stop!

{MuWordArray} chars
	"This method returns all of the characters in the run (ignoring my 
	length).  This method is used to get the uncomposed run for the purpose of 
	composing it!! "

	^ (self parent charsFor: self index with: self charLimit) cast: MuWordArray.!

{MuWordArray} composedChars

	"This method returns the characters in the model, up to myLength"
	
	^ (self parent charsFor: self index with: myLength) quickCast: MuWordArray! !

!FMTextRunModel methodsFor: 'line compose setting'!

{void} setCharCount: toCount {IntegerVar} 
        "This method is used by composers to set the current length of this 
        run model."

        | oldCount {IntegerVar} |
        oldCount _ myLength.
        myLength _ toCount.
        self parent deltaCount: self index with: toCount - oldCount!

{void} setMax: aMax {IntegerVar}

	self parent setMaxOf: self index with: aMax! !

!FMTextRunModel methodsFor: 'protected: creation'!

create: withParent {FMSuperTextModel} 
	super create: withParent.
	myLength _ IntegerVar0! !

!FMTextRunModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference} 

	oo << self getCategory name << '('.
	oo << self charCount << ')'! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FMTextRunModel class
	instanceVariableNames: ''!

(FMTextRunModel getOrMakeCxxClassDescription)
	friends:
'/* friends for class FMTextRunModel */
friend SPTR(FMTextRunModel)  fMTextRunModel (FMSuperTextModel * onParent);';
	attributes: ((Set new) add: #CONCRETE; yourself)!

!FMTextRunModel class methodsFor: 'pseudoconstructors'!

make: onParent {FMSuperTextModel}
	^ self create: onParent! !