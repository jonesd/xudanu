'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:27 pm'!

Converter subclass: #TextDoc2PassageModel
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-appmods'!

(TextDoc2PassageModel getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!TextDoc2PassageModel methodsFor: 'accessing'!

{Heaper} convert: value {Heaper}
	^PassageModel make: (value quickCast: XuText)! !

!TextDoc2PassageModel methodsFor: 'creation'!

create
	"super create: XuText with: DocumentModel"! !

!TextDoc2PassageModel methodsFor: 'printing'!

{void} printOn: oo {ostream reference}oo <<  self getCategory name! !