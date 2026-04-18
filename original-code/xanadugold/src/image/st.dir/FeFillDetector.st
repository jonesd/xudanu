'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:27 pm'!

FeDetector subclass: #FeFillDetector
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-detect'!
FeFillDetector comment:
'Client defines subclasses and passes in an instance in order to be notified of new results from Edition::rangeTranscluders () or RangeElement::transcluders (). If passed to Edition::addFillRangeDetector, this subclass merely passes in the Editions in the range one by one, though they may appear in the result in batches.'!

(FeFillDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeFillDetector methodsFor: 'triggering'!

{void CLIENT} filled: newIdentity {FeRangeElement}
	"A single PlaceHolder has been filled to become another kind of RangeElement"
	
	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeFillDetector class
	instanceVariableNames: ''!

(FeFillDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeFillDetector class methodsFor: 'smalltalk: system'!

info.stProtocol
"{NOWAIT CLIENT} filled: newIdentity {PrRangeElement}
"! !