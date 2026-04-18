'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 22 March 1995 at 9:07:02 pm'!

Heaper subclass: #FeRangeElement
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-nkernel'!
FeRangeElement comment:
'The kinds of objects which can be in the range of Editions.'!

(FeRangeElement getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #EQ; yourself)!

!FeRangeElement methodsFor: 'smalltalk: defaults'!

{FeEdition CLIENT} works
	
	^self works: NULL with: 0 with: NULL!

{FeEdition CLIENT} works: filter {Filter default: NULL}
	
	^self works: filter with: 0 with: NULL!

{FeEdition CLIENT} works: filter {Filter default: NULL}
	with: flags {Int32 default: Int32Zero}
	
	^self works: filter with: flags with: NULL! !

!FeRangeElement methodsFor: 'accessing'!

{void} addFillDetector: detector {FeFillDetector}
	"Essential.  When this PlaceHolder becomes any other kind of RangeElement, then the Detector will be triggered with the new RangeElement. If this is already not a PlaceHolder, then the Detector is triggered immediately with this RangeElement.
	See FillRangeDetector::filled (RangeElement * newIdentity)."
	
	detector filled: self. "default will be overridden in FePlaceHolder"!

{FeRangeElement CLIENT} again
	"Essential.  An object reflecting the current identity of this object, in case it is a PlaceHolder that has become something else since it was received from the Server."
	
	self subclassResponsibility!

{BooleanVar CLIENT} canMakeIdentical: newIdentity {FeRangeElement}
	"Essential.  Whether the identity of this object could be changed to the other.
	Does not check whether the CurrentKeyMaster has authority to do it.
	The restrictions on this operation depend on which subclass this is, but in general (except for PlaceHolders) an object can only become another of the same type with the same content."
	
	RaviNow shouldImplement.
	^false "fodder"!

{FeFillDetector CLIENT} fillDetector
	"Essential.  Return a FillDetector that will be triggered when this RangeElement becomes something other than a PlaceHolder, or immeditely if this RangeElement is not currently a PlaceHolder.
	See FillRangeDetector::filled (RangeElement * newIdentity)."
	
	Dean shouldImplement.
	self addFillDetector: NULL.
	^NULL "fodder"!

{BooleanVar CLIENT} isIdentical: other {FeRangeElement}
	"Essential.  Return whether two objects have the same identity on the Server.  Note that this can change over time, if makeIdentical is used.  However, for a given pair of FeRangeElements, it can only change from not being the same to being the same while you are holding onto them."
	
	other cast: FeVirtualDataHolder into: [ :vd |
		^vd isIdentical: self]
	cast: FeVirtualPlaceHolder into: [ :vp |
		^vp isIdentical: self]
	others:
		["This should be OK, since virtual subclasses override this anyway"
		^self getOrMakeBe isEqual: other getOrMakeBe].
	^false "fodder"!

{void CLIENT} makeIdentical: newIdentity {FeRangeElement}
	"Essential.  Change the identity of this object to the other. BLAST if unsuccessful.
	Requires authority of the current owner; if the operation is successful, the owner will appear to change to that of the other object.
	Also requires enough permission on newIdentity to determine, by comparing content, whether the operation would succeed.
	The restrictions on this operation depend on which subclass this is, but in general (except for PlaceHolders) an object can only become another of the same type with the same content."
	
	self subclassResponsibility!

{ID CLIENT} owner
	"Essential.  The Club which owns this RangeElement, and has the authority to make it become something else, and to transfer ownership to someone else."
	
	^self getOrMakeBe owner "virtuals should override"!

{void} removeFillDetector: detector {FeFillDetector}
	"Essential.  Remove a Detector which had been added to this RangeElement. You should remove every Detector you add, although they will go away automatically when a client session terminates."
	
	||
	"Do nothing. PlaceHolder overrides"!

{void CLIENT} setOwner: clubID {ID}
	"Essential.  Change the owner; must have the authority of the current owner."
	
	(CurrentKeyMaster fluidGet hasAuthority: self owner) ifFalse:
		[Heaper BLAST: #MustBeOwner].
	"Need to make it into a reified range element in order to have distinct ownership"
	
	CurrentGrandMap fluidGet getClub: clubID.  "Checks that it is a club."
	self getOrMakeBe setOwner: clubID!

{FeEdition CLIENT} transcluders: directFilter {Filter default: NULL}
	with: indirectFilter {Filter default: NULL}
	with: flags {Int32 default: Int32Zero}
	with: otherTranscluders {FeEdition default: NULL}
	"All Editions which the CurrentKeyMaster can see, which transclude this RangeElement.
	If a directFilter is given, then the visibleEndorsements on a Edition must match the filter.
	If an indirectFilter is given, then a resulting Edition must be contained in some readable Edition whose visibleEndorsements match the filter.
	If the directContainersOnly flag is set, then a resulting Edition must contain this directly as a RangeElement; otherwise, indirect containment through Editions is allowed.
	If the localPresentOnly flag is set, then only Editions currently known to this Server are guaranteed to end up in the result; otherwise, Editions which come to satisfy the conditions in the future, and those on other Servers, may also be found.
	Equivalent to
		FeServer::current ()->newEditionWith (<any position>, this)
			->rangeTranscluders (NULL, directFilter, indirectFilter, flags, otherTranscluders)."
	
	^(FeEdition fromOne: IntegerVarZero integer with: self)
		rangeTranscluders: NULL with: directFilter with: indirectFilter with: flags with: otherTranscluders!

{FeEdition CLIENT} works: filter {Filter default: NULL}
	with: flags {Int32 default: Int32Zero}
	with: otherTranscluders {FeEdition default: NULL}
	"Essential.  Works which contain this RangeElement and can be read by the CurrentKeyMaster. Returns an IDSpace Edition full of PlaceHolders, which will be filled with Works as results come in.
	If a filter is given, then only Works whose endorsements pass the Filter are returned.
	If localPresentOnly flag is set, then only Works currently known to this Server are returned; otherwise, as new Works come to be known to the Server, they are filled into the resulting Edition.
	If directContainersOnly is set, and this is an Edition, then only Works which are directly on this Edition are returned (and not Works which are on Editions which have this one as sub-Editions).
	{ <k,l,w> | w's contains self, w passes filter}"
	
	| theFilter {Filter} |
	filter == NULL
		ifTrue: [theFilter := CurrentGrandMap fluidGet endorsementFilterSpace fullRegion cast: Filter]
		ifFalse: [theFilter := filter].
	Dean thingToDo. "avoid reifying"
	^FeEdition on: (self getOrMakeBe
		works: CurrentKeyMaster fluidGet actualAuthority
		with: theFilter
		with: flags)! !

!FeRangeElement methodsFor: 'server accessing'!

{BeCarrier} carrier
	"Return an object that wraps up any run-time state that might be needed inside the Be system.  Right now that means labels."
	
	^BeCarrier make: self getOrMakeBe!

{BeRangeElement | NULL} fetchBe
	"If this has a reified Be object, then return it, else NULL"
	
	self subclassResponsibility!

{BeRangeElement} getOrMakeBe
	"An individual BeRangeElement for this identity. If the object is virtualized, then de-virtualizes it."
	
	self subclassResponsibility! !

!FeRangeElement methodsFor: 'smalltalk:'!

inspect
	"Sensor leftShiftDown" true
		ifTrue: [self basicInspect]
		ifFalse: [EntView openOn: (TreeBarnacle new
					buildOn: self
					gettingChildren: [:elem | (elem respondsTo: #inspectPieces)
							ifTrue: [elem inspectPieces]
							ifFalse: [#()]]
					gettingImage: [:me | DisplayText text: me displayString asText textStyle: (TextStyle styleNamed: #small)]
					at: 0 @ 0
					vertical: true
					separation: 5 @ 10)]!

{FeEdition CLIENT} transcluders
	^self transcluders: NULL with: NULL with: Int32Zero with: NULL!

{FeEdition CLIENT} transcluders: directFilter {Filter default: NULL}
	
	^self transcluders: directFilter with: NULL with: Int32Zero with: NULL!

{FeEdition CLIENT} transcluders: directFilter {Filter default: NULL}
	with: indirectFilter {Filter default: NULL}
	
	^self transcluders: directFilter with: indirectFilter with: Int32Zero with: NULL!

{FeEdition CLIENT} transcluders: directFilter {Filter default: NULL}
	with: indirectFilter {Filter default: NULL}
	with: flags {Int32 default: Int32Zero}
	
	^self transcluders: directFilter with: indirectFilter with: flags with: NULL! !

!FeRangeElement methodsFor: 'labelling'!

{FeLabel CLIENT} label
	"Essential. Return the label attached to this FeRangeElement. (An FeRangeElement holds a BeRangeElement and a label.)  All FeRangeElements have a label attached to them when they are created (in the various Server::newRangeElement operations).  Derived Editions have the same the label as the Edition they were derived from (e.g. the receiver of copy, combine, replace, transformedBy, etc.)  Labels may be available only on Editions in 1.0.  (While this is in force, label() will blast if sent to other kinds of FeEditions.)"
	
	self unimplemented. "default"
	^NULL!

{FeRangeElement CLIENT} relabelled: label {FeLabel}
	"Essential. Return a new FeRangeElement with the same identity and contents (i.e. holding the same BeRangeElement), but with a different label.  (Get new labels from FeServer::newLabel())"
	
	self unimplemented. "default"
	^NULL! !

!FeRangeElement methodsFor: 'smalltalk: passe'!

{BooleanVar} becomeOther: newIdentity {FeRangeElement}

	self passe.	"renamed makeIdentical:"!

{BooleanVar} isSameAs: other {FeRangeElement}

	self passe "isIdentical"! !

!FeRangeElement methodsFor: 'generated:'!

actualHashForEqual ^self asOop!

isEqual: other ^self == other! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

FeRangeElement class
	instanceVariableNames: ''!

(FeRangeElement getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #ON.CLIENT; add: #DEFERRED; add: #EQ; yourself)!

!FeRangeElement class methodsFor: 'protected:'!

{void} validateEndorsement: endorsements {CrossRegion} with: km {FeKeyMaster} 
	"Check whether the endorsements are valid and authorized.
	 Blast appropriately if not."

	endorsements isFinite ifFalse: [Heaper BLAST: #EndorsementMustBeFinite].
	self validateSignature: ((endorsements projection: Int32Zero) cast: IDRegion)
		with: km!

{void} validateSignature: clubs {IDRegion} with: km {FeKeyMaster} 
	"Check whether the signatures are valid and authorized.
	 Blast appropriately if not."

	clubs isFinite ifFalse: [Heaper BLAST: #MustHaveSignatureAuthority].
	clubs stepper forEach: [ :clubID {ID} |
		(km hasSignatureAuthority: clubID)
			ifFalse: [Heaper BLAST: #MustHaveSignatureAuthority]]! !

!FeRangeElement class methodsFor: 'smalltalk: system'!

info.stProtocol
"{void CLIENT} addFillDetector: detector {PrFillDetector}
{FeRangeElement CLIENT} again
{BooleanVar CLIENT} canMakeIdentical: newIdentity {FeRangeElement}
{BooleanVar CLIENT} isIdentical: other {FeRangeElement}
{FeLabel CLIENT} label
{void CLIENT} makeIdentical: newIdentity {FeRangeElement}
{ID CLIENT} owner
{FeRangeElement CLIENT} relabelled: label {FeLabel}
{void CLIENT} removeFillDetector: detector {PrFillDetector}
{void CLIENT} setOwner: clubID {ID}
{FeEdition CLIENT} transcluders
{FeEdition CLIENT} transcluders: directFilter {Filter default: NULL}
{FeEdition CLIENT} transcluders: directFilter {Filter default: NULL} with: indirectFilter {Filter default: NULL}
{FeEdition CLIENT} transcluders: directFilter {Filter default: NULL} with: indirectFilter {Filter default: NULL} with: flags {Int32 default: Int32Zero}
{FeEdition CLIENT} transcluders: directFilter {Filter default: NULL} with: indirectFilter {Filter default: NULL} with: flags {Int32 default: Int32Zero} with: otherTrail {FeEdition default: NULL}
{FeEdition CLIENT} works: filter {Filter default: NULL} with: flags {Int32 default: Int32Zero} with: otherTrail {FeEdition default: NULL}
"! !

!FeRangeElement class methodsFor: 'creation'!

{FeRangeElement CLIENT} placeHolder
	"Make a single PlaceHolder."
	
	^FePlaceHolder on: CurrentGrandMap fluidGet newPlaceHolder! !