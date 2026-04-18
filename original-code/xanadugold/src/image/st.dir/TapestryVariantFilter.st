'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:19 pm'!

TapestryFilter subclass: #TapestryVariantFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-filters'!

(TapestryVariantFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TapestryVariantFilter methodsFor: 'accessing'!

{void} watchReferences: document {DocumentModel} 
	with: references {SetModel of: Reference} 
	with: destroy {XnModel default: NULL}
	"Put all current variants of the document into the set, then create sensors to put new variants in there.
	A NewContentsUpdate to the destroy model should get rid of the sensors."
	
	| map {IndirectRecord} sensor {VariantReferenceSensor}
	  result {MuSet of: Reference} |
	map := self findReferences: document with: self filter.
	sensor := VariantReferenceSensor make: document
		with: references with: map with: destroy.
	map wait: sensor.
	self hack. "synchronization -- what if sensor rings now?"
	result := MuSet make.
	map usedDomain stepper forEach: [ :each {ID} |
		result storeAll: (Reference variantReferences: ((map indirectGet: each) cast: Waldo))].
	references replaceWith: result! !

!TapestryVariantFilter methodsFor: 'create'!

create: filter {ReferenceFilter}
	super create: filter! !