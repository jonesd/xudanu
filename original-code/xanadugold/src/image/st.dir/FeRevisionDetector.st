'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:27 pm'!

FeDetector subclass: #FeRevisionDetector
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-detect'!
FeRevisionDetector comment:
'Client defines subclasses and passes in an instance in order to be notified of revisions to a Work'!

(FeRevisionDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeRevisionDetector methodsFor: 'triggering'!

{void CLIENT} revised: work {FeWork}
	with: contents {FeEdition}
	with: author {ID}
	with: time {IntegerVar}
	with: sequence {IntegerVar}
	"Essential. The Work has been revised. Gives the Work, the current Edition, the author ID who had it grabbed, the sequence number of the revision to the Work, and the clock time on the Server (note that the clock time is only as reliable as the Server's operating system, which is usually not very)."
	
	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeRevisionDetector class
	instanceVariableNames: ''!

(FeRevisionDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeRevisionDetector class methodsFor: 'smalltalk: system'!

info.stProtocol
"{NOWAIT CLIENT} revised: contents {PrEdition} with: author {PrID} with: time {PrInteger} with: sequence {PrInteger}
"! !