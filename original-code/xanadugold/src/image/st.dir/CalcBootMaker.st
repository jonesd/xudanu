'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:48 pm'!

BootMaker subclass: #CalcBootMaker
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-calc'!

(CalcBootMaker getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #(COPY boot ); add: #NOT.A.TYPE; yourself)!

!CalcBootMaker methodsFor: 'accessing'!

{Category} bootCategory
	^CalcCreator! !

!CalcBootMaker methodsFor: 'protected:'!

{Heaper} bootHeaper
	^ActualCalcCreator make.! !

!CalcBootMaker methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.! !