'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 8:55:27 pm'!

Object subclass: #Cell
	instanceVariableNames: 'getBlock setBlock '
	classVariableNames: ''
	poolDictionaries: ''
	category: 'X++ Translator'!
Cell comment:
'Instances of this class are used to pass pointers to cells into the c++ equivalent 
of Blocks.  The creation of one of these translates to just taking the address of 
the argument.  The access messages translate to fetch and assignment indirectly 
through Cell.
Creting a Cell requires supplying a block with which to fetch the value and a block 
with which to set the value.  These MUST only fetch and store a single variable, 
because complex stuff won''t transalte at all.'!


!Cell methodsFor: 'accessing'!

refAssign: val
	setBlock value: val!

refValue
	^getBlock value! !

!Cell methodsFor: 'instance creation'!

create: getBl with: setBl
	getBlock _ getBl.
	setBlock _ setBl! !