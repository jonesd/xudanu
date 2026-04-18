'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:26 pm'!

Heaper subclass: #FeDetector
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-detect'!
FeDetector comment:
'This generic superclass for detectors is so the comm system can tell what things are detectors.'!

(FeDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #EQ; yourself)!

!FeDetector methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !