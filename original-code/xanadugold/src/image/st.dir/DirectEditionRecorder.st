'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:59:32 pm'!

EditionRecorder subclass: #DirectEditionRecorder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-backrec'!
DirectEditionRecorder comment:
'Represents the a persistent transcluders or rangeTranscluders query with directContainersOnly flag on'!

(DirectEditionRecorder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!DirectEditionRecorder methodsFor: 'accessing'!

{BooleanVar} isDirectOnly
	
	^true! !

!DirectEditionRecorder methodsFor: 'create'!

create: directFilter {Filter}
	with: indirectFilter {Filter}
	with: trailBlazer {TrailBlazer}
	
	super create: directFilter
		with: indirectFilter
		with: trailBlazer! !