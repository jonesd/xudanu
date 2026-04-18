'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:04:40 pm'!

CompareFragment subclass: #TextFragment
	instanceVariableNames: 'myText {AttributedTextModel}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Comparison/Merge'!

(TextFragment getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TextFragment methodsFor: 'printing'!

{void} printOn: stream {ostream reference}

	stream << 'prim[' << myText << ']'.! !

!TextFragment methodsFor: 'creation'!

create: aText {AttributedTextModel}
	super create: aText count.
	myText _ aText.! !

!TextFragment methodsFor: 'testing'!

{BooleanVar} isShared
	"Does this fragment occur in both the source and the destination?"
	^false! !

!TextFragment methodsFor: 'smalltalk: printing'!

text
	^myText! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

TextFragment class
	instanceVariableNames: ''!

(TextFragment getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TextFragment class methodsFor: 'p-constructor'!

{CompareFragment} make: aText {AttributedTextModel}
	^TextFragment create: aText!

{CompareFragment} make: s with: d with: aText {AttributedTextModel}
	^TextFragment create: s with: d with: aText! !