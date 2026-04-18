'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:51 pm'!

AgendaItem subclass: #Matcher
	instanceVariableNames: '
		myOrglRoot {OrglRoot | NULL}
		myFinder {PropFinder}
		myFossil {RecorderFossil}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-turtle'!
Matcher comment:
'This is a one-shot agenda item.

When doing a delayed backFollow, after the future is taken care of (by posting recorders in the Sensor Canopy), the past needs to be checked (by walking the HTree northwards filtered by the Bert Canopy).  This AgendaItem is a one-shot used to remember to backFollow thru the past.  (myOrglRoot == NULL when the shot has been done.)'!

(Matcher getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!Matcher methodsFor: 'accessing'!

{BooleanVar} step
	| |

	"If myStamp is NULL
		We've already shot once.  Do nothing.
	walk the HTree northwards filtered by the Bert Canopy, scheduling RecorderTriggers to record already-existing matching stamps.  ('past' part of backfollow)
		Remember that we're done."
		
	
	myOrglRoot == NULL
		ifTrue: [^false].
	myFossil reanimate: [ :recorder {ResultRecorder} |
		myOrglRoot delayedFindMatching: myFinder
			with: myFossil
			with: recorder].
	DiskManager consistent: 1 with:
		[myOrglRoot _ NULL.
		self thingToDo. "stop making sure the stamp sticks around"
		self diskUpdate.
		^false]! !

!Matcher methodsFor: 'creation'!

create: oroot {OrglRoot} 
	with: finder {PropFinder} 
	with: fossil {RecorderFossil}
	
	super create.
	myOrglRoot _ oroot.
	self thingToDo. "make sure the stamp sticks around.  Do something like what's being done with myFossil>>addItem"
	myFinder _ finder.
	myFossil _ fossil.
	myFossil addItem: self.	"bump refcount on myFossil"
	self newShepherd.!

{void} dismantle
	
	DiskManager consistent: 3 with:
		[myFossil removeItem: self.	"Unbump refcount on myFossil."
		self thingToDo. "stop making sure the OrglRoot sticks around.  AgendaItems may be aborted by the enclosing algorithm, so can't assume I dropped my reference by stepping."
		super dismantle]! !

!Matcher methodsFor: 'generated:'!

create.Rcvr: receiver {Rcvr}
	super create.Rcvr: receiver.
	myOrglRoot _ receiver receiveHeaper.
	myFinder _ receiver receiveHeaper.
	myFossil _ receiver receiveHeaper.!

{void} sendSelfTo: xmtr {Xmtr}
	super sendSelfTo: xmtr.
	xmtr sendHeaper: myOrglRoot.
	xmtr sendHeaper: myFinder.
	xmtr sendHeaper: myFossil.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

Matcher class
	instanceVariableNames: ''!

(Matcher getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #LOCKED; add: #COPY; add: #SHEPHERD.PATRIARCH; add: #CONCRETE; yourself)!

!Matcher class methodsFor: 'creation'!

make: oroot {OrglRoot} 
	with: finder {PropFinder} 
	with: fossil {RecorderFossil}
	
	DiskManager consistent: 2 with:
		[^self create: oroot with: finder with: fossil]! !