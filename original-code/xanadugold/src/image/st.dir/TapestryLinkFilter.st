'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:06:18 pm'!

TapestryFilter subclass: #TapestryLinkFilter
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Tapestry-filters'!

(TapestryLinkFilter getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; yourself)!

!TapestryLinkFilter methodsFor: 'create'!

create: filter {ReferenceFilter}
	super create: filter! !

!TapestryLinkFilter methodsFor: 'accessing'!

{void} watchReferences: document {DocumentModel} 
        with: references {SetModel of: Reference} 
        with: destroy {XnModel default: NULL}
        "put all current references from the document into the set,
        then create sensors to put new references in there
        a NewContentsUpdate to the destroy model should get rid of the sensors"
        
        | map {IndirectRecord} sensor {LinkReferenceSensor} result {MuSet of: Reference} |
        map _ (self findReferences: document
                	with: ((self filter intersect: 
                		(XuServer currentServer waldoFilter: (Sequence string: 'XuLink'))) cast: Filter)) 
                cast: IndirectRecord.
        sensor _ LinkReferenceSensor make: document with: references with: map with: destroy.
        map wait: sensor.
        self hack. "synchronization -- what if sensor rings now?"
        result _ MuSet make.
        map usedDomain stepper forEach: [ :link {ID} |
                (Reference linkReferences: ((map get: link) cast: XuLink) with: document) stepper
                        forEach: [ :ref {Reference} |
                                result store: ref]].
        references replaceWith: result! !