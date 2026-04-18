'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:27 pm'!

FeDetector subclass: #FeFillRangeDetector
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-detect'!
FeFillRangeDetector comment:
'Client defines a subclass and passes it in to Edition::addFillRangeDetector, to be notified whenever PlaceHolders become any other kind of RangeElement.'!

(FeFillRangeDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeFillRangeDetector methodsFor: 'triggering'!

{void CLIENT} rangeFilled: newIdentities {FeEdition}
	"Essential.  Some of the PlaceHolders in the Edition on which I was placed have become something else. The Edition has their new identies as its RangeElements, though the keys may bear no relationship to those in the original Edition."
	
	self subclassResponsibility! !

!FeFillRangeDetector methodsFor: 'smalltalk: passe'!

{void} allFilled: newIdentities {FeEdition}

	self passe "rangeFilled"! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeFillRangeDetector class
	instanceVariableNames: ''!

(FeFillRangeDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeFillRangeDetector class methodsFor: 'smalltalk: system'!

info.stProtocol
"{NOWAIT CLIENT} rangeFilled: newIdentities {PrEdition}
"! !