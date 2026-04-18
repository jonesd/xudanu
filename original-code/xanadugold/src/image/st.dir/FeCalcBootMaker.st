'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:49 pm'!

BootMaker subclass: #FeCalcBootMaker
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-calc'!

(FeCalcBootMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); yourself)!

!FeCalcBootMaker methodsFor: 'accessing'!

{Category} bootCategory
	^FeCalcCreator! !

!FeCalcBootMaker methodsFor: 'protected:'!

{Heaper} bootHeaper
	^FeCalcCreator make.! !

!FeCalcBootMaker methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !