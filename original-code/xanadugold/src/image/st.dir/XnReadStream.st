'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:05:41 pm'!

Heaper subclass: #XnReadStream
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-Xcvr'!

(XnReadStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!XnReadStream methodsFor: 'accessing'!

{UInt8} getByte
	self subclassResponsibility!

{void} getBytes: buffer {void star} with: count {Int32} with: start {Int32 default: Int32Zero}
	"Pour data directly into a buffer."
	
	start almostTo: start + count do: [:i {Int32} |
		(buffer basicCast: Character star) at: i put: self getByte]!

{void} putBack: c {UInt8}
	self subclassResponsibility!

{void} refill
	self subclassResponsibility! !

!XnReadStream methodsFor: 'smalltalk: defaults'!

{void} getBytes: buffer {void star} with: count {Int32}
	"Pour data directly into a buffer."
	
	self getBytes: buffer with: count with: Int32Zero! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

XnReadStream class
	instanceVariableNames: ''!

(XnReadStream getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!XnReadStream class methodsFor: 'creation'!

make: collection {UInt8Array}
	^ReadArrayStream create: collection.!

make: dataP {UInt8 star} with: start {Int32} with: count {Int32}
	^ReadMemStream make: dataP with: start with: count! !