'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:08:17 pm'!

ByteShuffler subclass: #NoShuffler
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!
NoShuffler comment:
'No transformation.'!

(NoShuffler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!NoShuffler methodsFor: 'shuffle'!

{void} shuffle16: buffer {void star} with: count {Int32}
	"Do nothing."!

{void} shuffle32: buffer {void star} with: count {Int32}
	"Do nothing."!

{void} shuffle64: buffer {void star} with: count {Int32}
	"Do nothing."! !