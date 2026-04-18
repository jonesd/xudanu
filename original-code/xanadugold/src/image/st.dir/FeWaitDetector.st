'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:28 pm'!

FeDetector subclass: #FeWaitDetector
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-detect'!
FeWaitDetector comment:
'Will get sent a single message, once, with no parameters, when something happens. It can be passed in to Server::waitForConsequences and Server::waitForWrite.BY.PROXY '!

(FeWaitDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeWaitDetector methodsFor: 'triggering'!

{void CLIENT} done
	"Essential.  Whatever I was waiting for has happened"
	
	self subclassResponsibility! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeWaitDetector class
	instanceVariableNames: ''!

(FeWaitDetector getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; yourself)!

!FeWaitDetector class methodsFor: 'smalltalk: system'!

info.stProtocol
"{NOWAIT CLIENT} done
"! !