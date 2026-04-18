'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:01:19 pm'!

Heaper subclass: #Recorder
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-hoprec'!
Recorder comment:
'This class put in in the hope that some aspects of different recorders can be abstracted out & made polymorphic, to allow other tools to be more reusable.  The particular failed but motivating example was to make "record" polymorphic between HopRecorder and BackfollowRecorder so that RecorderTrigger could be applied to either.  This should probably still be done.'!

(Recorder getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; add: #OBSOLETE; yourself)!

!Recorder methodsFor: 'creation'!

create: wrapped {Manipulator} with: holder {Manipulator default: NULL}
	super create: wrapped with: holder.! !