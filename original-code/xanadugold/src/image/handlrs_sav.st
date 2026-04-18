'From Objectworks for Smalltalk-80(tm), Version 2.5 of 29 July 1989 on 23 March 1995 at 12:31:28 pm'!

((CxxSystemOrganization tree childNamed: #handlrs) ~= nil) ifTrue: [
	(CxxSystemOrganization tree childNamed: #handlrs) destroyFiles]!

Heaper subclass: #RequestHandler
	instanceVariableNames: ''
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!
RequestHandler comment:
'A class for each abstract signature.  Each instance will wrap a pointer to a static member function.'!

(RequestHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!RequestHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}

	self subclassResponsibility! !

!RequestHandler methodsFor: 'smalltalk: printing'!

printOn: oo
	| staticFn |
	staticFn _ self instVarAt: 1.
	oo << staticFn staticClass << '::' << staticFn selector! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

RequestHandler class
	instanceVariableNames: ''!

(RequestHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #DEFERRED; yourself)!

!RequestHandler class methodsFor: 'translate: generated'!

{void} Adminer.U.acceptConnections.U.N2: receiver {FeAdminer} with: arg1 {BooleanVar}
	receiver acceptConnections: arg1!

{Stepper} Adminer.U.activeSessions.U.N1: receiver {FeAdminer}
	^receiver activeSessions!

{void} Adminer.U.execute.U.N2: receiver {FeAdminer} with: arg1 {PrimIntArray}
	receiver execute: arg1!

{FeLockSmith} Adminer.U.gateLockSmith.U.N1: receiver {FeAdminer}
	^receiver gateLockSmith!

{void} Adminer.U.grant.U.N3: receiver {FeAdminer} with: arg1 {ID} with: arg2 {IDRegion}
	receiver grant: arg1 with: arg2!

{TableStepper} Adminer.U.grants.U.N1: receiver {FeAdminer}
	^receiver grants!

{TableStepper} Adminer.U.grants.U.N2: receiver {FeAdminer} with: arg1 {IDRegion}
	^receiver grants: arg1!

{TableStepper} Adminer.U.grants.U.N3: receiver {FeAdminer} with: arg1 {IDRegion} with: arg2 {IDRegion}
	^receiver grants: arg1 with: arg2!

{BooleanVar} Adminer.U.isAcceptingConnections.U.N1: receiver {FeAdminer}
	^receiver isAcceptingConnections!

{FeAdminer} Adminer.U.make.U.N0
	^FeAdminer make!

{void} Adminer.U.setGateLockSmith.U.N2: receiver {FeAdminer} with: arg1 {FeLockSmith}
	receiver setGateLockSmith: arg1!

{FeEdition} Archiver.U.archive.U.N3: receiver {FeArchiver} with: arg1 {FeEdition} with: arg2 {FeEdition}
	^receiver archive: arg1 with: arg2!

{FeArchiver} Archiver.U.make.U.N0
	^FeArchiver make!

{void} Archiver.U.markArchived.U.N2: receiver {FeArchiver} with: arg1 {FeEdition}
	receiver markArchived: arg1!

{FeEdition} Archiver.U.restore.U.N3: receiver {FeArchiver} with: arg1 {FeEdition} with: arg2 {FeEdition}
	^receiver restore: arg1 with: arg2!

{PrimArray} Array.U.copy.U.N1: receiver {PrimArray}
	^receiver copy!

{PrimArray} Array.U.copy.U.N2: receiver {PrimArray} with: arg1 {PrimIntValue}
	^receiver copy: arg1 asInt32!

{PrimArray} Array.U.copy.U.N3: receiver {PrimArray} with: arg1 {PrimIntValue} with: arg2 {PrimIntValue}
	^receiver copy: arg1 asInt32 with: arg2 asInt32!

{PrimArray} Array.U.copy.U.N4: receiver {PrimArray} with: arg1 {PrimIntValue} with: arg2 {PrimIntValue} with: arg3 {PrimIntValue}
	^receiver copy: arg1 asInt32 with: arg2 asInt32 with: arg3 asInt32!

{PrimArray} Array.U.copy.U.N5: receiver {PrimArray} with: arg1 {PrimIntValue} with: arg2 {PrimIntValue} with: arg3 {PrimIntValue} with: arg4 {PrimIntValue}
	^receiver copy: arg1 asInt32 with: arg2 asInt32 with: arg3 asInt32 with: arg4 asInt32!

{PrimIntValue} Array.U.count.U.N1: receiver {PrimArray}
	^PrimIntValue make: (receiver count)!

{Heaper} Array.U.get.U.N2: receiver {PrimArray} with: arg1 {PrimIntValue}
	^receiver getValue: arg1 asInt32!

{void} Array.U.store.U.N3: receiver {PrimArray} with: arg1 {PrimIntValue} with: arg2 {Heaper}
	receiver at: arg1 asInt32 storeValue: arg2!

{void} Array.U.storeAll.U.N1: receiver {PrimArray}
	receiver storeAll!

{void} Array.U.storeAll.U.N2: receiver {PrimArray} with: arg1 {Heaper}
	receiver storeAll: arg1!

{void} Array.U.storeAll.U.N3: receiver {PrimArray} with: arg1 {Heaper} with: arg2 {PrimIntValue}
	receiver storeAll: arg1 with: arg2 asInt32!

{void} Array.U.storeAll.U.N4: receiver {PrimArray} with: arg1 {Heaper} with: arg2 {PrimIntValue} with: arg3 {PrimIntValue}
	receiver storeAll: arg1 with: arg2 asInt32 with: arg3 asInt32!

{void} Array.U.storeMany.U.N3: receiver {PrimArray} with: arg1 {PrimIntValue} with: arg2 {PrimArray}
	receiver at: arg1 asInt32 storeMany: arg2!

{void} Array.U.storeMany.U.N4: receiver {PrimArray} with: arg1 {PrimIntValue} with: arg2 {PrimArray} with: arg3 {PrimIntValue}
	receiver at: arg1 asInt32 storeMany: arg2 with: arg3 asInt32!

{void} Array.U.storeMany.U.N5: receiver {PrimArray} with: arg1 {PrimIntValue} with: arg2 {PrimArray} with: arg3 {PrimIntValue} with: arg4 {PrimIntValue}
	receiver at: arg1 asInt32 storeMany: arg2 with: arg3 asInt32 with: arg4 asInt32!

{PrimArray} ArrayBundle.U.array.U.N1: receiver {FeArrayBundle}
	^receiver array!

{OrderSpec} ArrayBundle.U.ordering.U.N1: receiver {FeArrayBundle}
	^receiver ordering!

{FeKeyMaster} BooLock.U.boo.U.N1: receiver {BooLock}
	^receiver boo!

{FeBooLockSmith} BooLockSmith.U.make.U.N0
	^FeBooLockSmith make!

{XnRegion} Bundle.U.region.U.N1: receiver {FeBundle}
	^receiver region!

{PrimIntArray} ChallengeLock.U.challenge.U.N1: receiver {ChallengeLock}
	^receiver challenge!

{FeKeyMaster} ChallengeLock.U.response.U.N2: receiver {ChallengeLock} with: arg1 {PrimIntArray}
	^receiver response: arg1!

{PrimIntArray} ChallengeLockSmith.U.encrypterName.U.N1: receiver {FeChallengeLockSmith}
	^receiver encrypterName!

{FeChallengeLockSmith} ChallengeLockSmith.U.make.U.N2: arg1 {PrimIntArray} with: arg2 {Sequence}
	^FeChallengeLockSmith make: arg1 with: arg2!

{PrimIntArray} ChallengeLockSmith.U.publicKey.U.N1: receiver {FeChallengeLockSmith}
	^receiver publicKey!

{FeClub} Club.U.make.U.N1: arg1 {FeEdition}
	^FeClub make: arg1!

{void} Club.U.removeSignatureClub.U.N1: receiver {FeClub}
	receiver removeSignatureClub!

{void} Club.U.setSignatureClub.U.N2: receiver {FeClub} with: arg1 {ID}
	receiver setSignatureClub: arg1!

{ID} Club.U.signatureClub.U.N1: receiver {FeClub}
	^receiver signatureClub!

{FeEdition} Club.U.sponsoredWorks.U.N1: receiver {FeClub}
	^receiver sponsoredWorks!

{FeEdition} Club.U.sponsoredWorks.U.N2: receiver {FeClub} with: arg1 {Filter}
	^receiver sponsoredWorks: arg1!

{FeLockSmith} ClubDescription.U.lockSmith.U.N1: receiver {FeClubDescription}
	^receiver lockSmith!

{FeClubDescription} ClubDescription.U.make.U.N2: arg1 {FeSet} with: arg2 {FeLockSmith}
	^FeClubDescription make: arg1 with: arg2!

{FeSet} ClubDescription.U.membership.U.N1: receiver {FeClubDescription}
	^receiver membership!

{FeClubDescription} ClubDescription.U.withLockSmith.U.N2: receiver {FeClubDescription} with: arg1 {FeLockSmith}
	^receiver withLockSmith: arg1!

{FeClubDescription} ClubDescription.U.withMembership.U.N2: receiver {FeClubDescription} with: arg1 {FeSet}
	^receiver withMembership: arg1!

{OrderSpec} CoordinateSpace.U.ascending.U.N1: receiver {CoordinateSpace}
	^receiver ascending!

{Mapping} CoordinateSpace.U.completeMapping.U.N2: receiver {CoordinateSpace} with: arg1 {XnRegion}
	^receiver completeMapping: arg1!

{OrderSpec} CoordinateSpace.U.descending.U.N1: receiver {CoordinateSpace}
	^receiver descending!

{XnRegion} CoordinateSpace.U.emptyRegion.U.N1: receiver {CoordinateSpace}
	^receiver emptyRegion!

{XnRegion} CoordinateSpace.U.fullRegion.U.N1: receiver {CoordinateSpace}
	^receiver fullRegion!

{Mapping} CoordinateSpace.U.identityMapping.U.N1: receiver {CoordinateSpace}
	^receiver identityMapping!

{Mapping} CrossMapping.U.subMapping.U.N2: receiver {CrossMapping} with: arg1 {PrimIntValue}
	^receiver subMapping: arg1 asInt32!

{PtrArray} CrossMapping.U.subMappings.U.N1: receiver {CrossMapping}
	^receiver subMappings!

{PrimIntArray} CrossOrderSpec.U.lexOrder.U.N1: receiver {CrossOrderSpec}
	^receiver lexOrder!

{OrderSpec} CrossOrderSpec.U.subOrder.U.N2: receiver {CrossOrderSpec} with: arg1 {PrimIntValue}
	^receiver subOrder: arg1 asInt32!

{PtrArray} CrossOrderSpec.U.subOrders.U.N1: receiver {CrossOrderSpec}
	^receiver subOrders!

{Stepper} CrossRegion.U.boxes.U.N1: receiver {CrossRegion}
	^receiver boxes!

{BooleanVar} CrossRegion.U.isBox.U.N1: receiver {CrossRegion}
	^receiver isBox!

{XnRegion} CrossRegion.U.projection.U.N2: receiver {CrossRegion} with: arg1 {PrimIntValue}
	^receiver projection: arg1 asInt32!

{PtrArray} CrossRegion.U.projections.U.N1: receiver {CrossRegion}
	^receiver projections!

{PtrArray} CrossSpace.U.axes.U.N1: receiver {CrossSpace}
	^receiver axes!

{CoordinateSpace} CrossSpace.U.axis.U.N2: receiver {CrossSpace} with: arg1 {PrimIntValue}
	^receiver axis: arg1 asInt32!

{PrimIntValue} CrossSpace.U.axisCount.U.N1: receiver {CrossSpace}
	^PrimIntValue make: (receiver axisCount)!

{Mapping} CrossSpace.U.crossOfMappings.U.N1: receiver {CrossSpace}
	^receiver crossOfMappings!

{Mapping} CrossSpace.U.crossOfMappings.U.N2: receiver {CrossSpace} with: arg1 {PtrArray}
	^receiver crossOfMappings: arg1!

{CrossOrderSpec} CrossSpace.U.crossOfOrderSpecs.U.N1: receiver {CrossSpace}
	^receiver crossOfOrderSpecs!

{CrossOrderSpec} CrossSpace.U.crossOfOrderSpecs.U.N2: receiver {CrossSpace} with: arg1 {PtrArray}
	^receiver crossOfOrderSpecs: arg1!

{CrossOrderSpec} CrossSpace.U.crossOfOrderSpecs.U.N3: receiver {CrossSpace} with: arg1 {PtrArray} with: arg2 {PrimIntArray}
	^receiver crossOfOrderSpecs: arg1 with: arg2!

{Tuple} CrossSpace.U.crossOfPositions.U.N2: receiver {CrossSpace} with: arg1 {PtrArray}
	^receiver crossOfPositions: arg1!

{CrossRegion} CrossSpace.U.crossOfRegions.U.N2: receiver {CrossSpace} with: arg1 {PtrArray}
	^receiver crossOfRegions: arg1!

{CrossRegion} CrossSpace.U.extrusion.U.N3: receiver {CrossSpace} with: arg1 {PrimIntValue} with: arg2 {XnRegion}
	^receiver extrusion: arg1 asInt32 with: arg2!

{CrossSpace} CrossSpace.U.make.U.N1: arg1 {PtrArray}
	^CrossSpace make: arg1!

{FeDataHolder} DataHolder.U.make.U.N1: arg1 {PrimValue}
	^FeDataHolder make: arg1!

{PrimValue} DataHolder.U.value.U.N1: receiver {FeDataHolder}
	^receiver value!

{XnRegion} Edition.U.canMakeRangeIdentical.U.N2: receiver {FeEdition} with: arg1 {FeEdition}
	^receiver canMakeRangeIdentical: arg1!

{XnRegion} Edition.U.canMakeRangeIdentical.U.N3: receiver {FeEdition} with: arg1 {FeEdition} with: arg2 {XnRegion}
	^receiver canMakeRangeIdentical: arg1 with: arg2!

{FeEdition} Edition.U.combine.U.N2: receiver {FeEdition} with: arg1 {FeEdition}
	^receiver combine: arg1!

{CoordinateSpace} Edition.U.coordinateSpace.U.N1: receiver {FeEdition}
	^receiver coordinateSpace!

{FeEdition} Edition.U.copy.U.N2: receiver {FeEdition} with: arg1 {XnRegion}
	^receiver copy: arg1!

{PrimIntValue} Edition.U.cost.U.N2: receiver {FeEdition} with: arg1 {PrimIntValue}
	^PrimIntValue make: (receiver cost: arg1 asInt32)!

{PrimIntValue} Edition.U.count.U.N1: receiver {FeEdition}
	^PrimIntValue make: (receiver count)!

{XnRegion} Edition.U.domain.U.N1: receiver {FeEdition}
	^receiver domain!

{FeEdition} Edition.U.empty.U.N1: arg1 {CoordinateSpace}
	^FeEdition empty: arg1!

{void} Edition.U.endorse.U.N2: receiver {FeEdition} with: arg1 {CrossRegion}
	receiver endorse: arg1!

{CrossRegion} Edition.U.endorsements.U.N1: receiver {FeEdition}
	^receiver endorsements!

{FeEdition} Edition.U.fromAll.U.N2: arg1 {XnRegion} with: arg2 {FeRangeElement}
	^FeEdition fromAll: arg1 with: arg2!

{FeEdition} Edition.U.fromArray.U.N1: arg1 {PrimArray}
	^FeEdition fromArray: arg1!

{FeEdition} Edition.U.fromArray.U.N2: arg1 {PrimArray} with: arg2 {XnRegion}
	^FeEdition fromArray: arg1 with: arg2!

{FeEdition} Edition.U.fromArray.U.N3: arg1 {PrimArray} with: arg2 {XnRegion} with: arg3 {OrderSpec}
	^FeEdition fromArray: arg1 with: arg2 with: arg3!

{FeEdition} Edition.U.fromOne.U.N2: arg1 {Position} with: arg2 {FeRangeElement}
	^FeEdition fromOne: arg1 with: arg2!

{FeRangeElement} Edition.U.get.U.N2: receiver {FeEdition} with: arg1 {Position}
	^receiver get: arg1!

{BooleanVar} Edition.U.hasPosition.U.N2: receiver {FeEdition} with: arg1 {Position}
	^receiver hasPosition: arg1!

{BooleanVar} Edition.U.isEmpty.U.N1: receiver {FeEdition}
	^receiver isEmpty!

{BooleanVar} Edition.U.isFinite.U.N1: receiver {FeEdition}
	^receiver isFinite!

{BooleanVar} Edition.U.isRangeIdentical.U.N2: receiver {FeEdition} with: arg1 {FeEdition}
	^receiver isRangeIdentical: arg1!

{FeEdition} Edition.U.makeRangeIdentical.U.N2: receiver {FeEdition} with: arg1 {FeEdition}
	^receiver makeRangeIdentical: arg1!

{FeEdition} Edition.U.makeRangeIdentical.U.N3: receiver {FeEdition} with: arg1 {FeEdition} with: arg2 {XnRegion}
	^receiver makeRangeIdentical: arg1 with: arg2!

{Mapping} Edition.U.mapSharedOnto.U.N2: receiver {FeEdition} with: arg1 {FeEdition}
	^receiver mapSharedOnto: arg1!

{Mapping} Edition.U.mapSharedTo.U.N2: receiver {FeEdition} with: arg1 {FeEdition}
	^receiver mapSharedTo: arg1!

{FeEdition} Edition.U.notSharedWith.U.N2: receiver {FeEdition} with: arg1 {FeEdition}
	^receiver notSharedWith: arg1!

{FeEdition} Edition.U.notSharedWith.U.N3: receiver {FeEdition} with: arg1 {FeEdition} with: arg2 {PrimIntValue}
	^receiver notSharedWith: arg1 with: arg2 asInt32!

{FeEdition} Edition.U.placeHolders.U.N1: arg1 {XnRegion}
	^FeEdition placeHolders: arg1!

{XnRegion} Edition.U.positionsLabelled.U.N2: receiver {FeEdition} with: arg1 {FeLabel}
	^receiver positionsLabelled: arg1!

{XnRegion} Edition.U.positionsOf.U.N2: receiver {FeEdition} with: arg1 {FeRangeElement}
	^receiver positionsOf: arg1!

{IDRegion} Edition.U.rangeOwners.U.N2: receiver {FeEdition} with: arg1 {XnRegion}
	^receiver rangeOwners: arg1!

{FeEdition} Edition.U.rangeTranscluders.U.N1: receiver {FeEdition}
	^receiver rangeTranscluders!

{FeEdition} Edition.U.rangeTranscluders.U.N2: receiver {FeEdition} with: arg1 {XnRegion}
	^receiver rangeTranscluders: arg1!

{FeEdition} Edition.U.rangeTranscluders.U.N3: receiver {FeEdition} with: arg1 {XnRegion} with: arg2 {Filter}
	^receiver rangeTranscluders: arg1 with: arg2!

{FeEdition} Edition.U.rangeTranscluders.U.N4: receiver {FeEdition} with: arg1 {XnRegion} with: arg2 {Filter} with: arg3 {Filter}
	^receiver rangeTranscluders: arg1 with: arg2 with: arg3!

{FeEdition} Edition.U.rangeTranscluders.U.N5: receiver {FeEdition} with: arg1 {XnRegion} with: arg2 {Filter} with: arg3 {Filter} with: arg4 {PrimIntValue}
	^receiver rangeTranscluders: arg1 with: arg2 with: arg3 with: arg4 asInt32!

{FeEdition} Edition.U.rangeTranscluders.U.N6: receiver {FeEdition} with: arg1 {XnRegion} with: arg2 {Filter} with: arg3 {Filter} with: arg4 {PrimIntValue} with: arg5 {FeEdition}
	^receiver rangeTranscluders: arg1 with: arg2 with: arg3 with: arg4 asInt32 with: arg5!

{FeEdition} Edition.U.rangeWorks.U.N1: receiver {FeEdition}
	^receiver rangeWorks!

{FeEdition} Edition.U.rangeWorks.U.N2: receiver {FeEdition} with: arg1 {XnRegion}
	^receiver rangeWorks: arg1!

{FeEdition} Edition.U.rangeWorks.U.N3: receiver {FeEdition} with: arg1 {XnRegion} with: arg2 {Filter}
	^receiver rangeWorks: arg1 with: arg2!

{FeEdition} Edition.U.rangeWorks.U.N4: receiver {FeEdition} with: arg1 {XnRegion} with: arg2 {Filter} with: arg3 {PrimIntValue}
	^receiver rangeWorks: arg1 with: arg2 with: arg3 asInt32!

{FeEdition} Edition.U.rangeWorks.U.N5: receiver {FeEdition} with: arg1 {XnRegion} with: arg2 {Filter} with: arg3 {PrimIntValue} with: arg4 {FeEdition}
	^receiver rangeWorks: arg1 with: arg2 with: arg3 asInt32 with: arg4!

{FeEdition} Edition.U.rebind.U.N3: receiver {FeEdition} with: arg1 {Position} with: arg2 {FeEdition}
	^receiver rebind: arg1 with: arg2!

{FeEdition} Edition.U.replace.U.N2: receiver {FeEdition} with: arg1 {FeEdition}
	^receiver replace: arg1!

{void} Edition.U.retract.U.N2: receiver {FeEdition} with: arg1 {CrossRegion}
	receiver retract: arg1!

{Stepper} Edition.U.retrieve.U.N1: receiver {FeEdition}
	^receiver retrieve!

{Stepper} Edition.U.retrieve.U.N2: receiver {FeEdition} with: arg1 {XnRegion}
	^receiver retrieve: arg1!

{Stepper} Edition.U.retrieve.U.N3: receiver {FeEdition} with: arg1 {XnRegion} with: arg2 {OrderSpec}
	^receiver retrieve: arg1 with: arg2!

{Stepper} Edition.U.retrieve.U.N4: receiver {FeEdition} with: arg1 {XnRegion} with: arg2 {OrderSpec} with: arg3 {PrimIntValue}
	^receiver retrieve: arg1 with: arg2 with: arg3 asInt32!

{FeEdition} Edition.U.setRangeOwners.U.N2: receiver {FeEdition} with: arg1 {ID}
	^receiver setRangeOwners: arg1!

{FeEdition} Edition.U.setRangeOwners.U.N3: receiver {FeEdition} with: arg1 {ID} with: arg2 {XnRegion}
	^receiver setRangeOwners: arg1 with: arg2!

{XnRegion} Edition.U.sharedRegion.U.N2: receiver {FeEdition} with: arg1 {FeEdition}
	^receiver sharedRegion: arg1!

{XnRegion} Edition.U.sharedRegion.U.N3: receiver {FeEdition} with: arg1 {FeEdition} with: arg2 {PrimIntValue}
	^receiver sharedRegion: arg1 with: arg2 asInt32!

{FeEdition} Edition.U.sharedWith.U.N2: receiver {FeEdition} with: arg1 {FeEdition}
	^receiver sharedWith: arg1!

{FeEdition} Edition.U.sharedWith.U.N3: receiver {FeEdition} with: arg1 {FeEdition} with: arg2 {PrimIntValue}
	^receiver sharedWith: arg1 with: arg2 asInt32!

{TableStepper} Edition.U.stepper.U.N1: receiver {FeEdition}
	^receiver stepper!

{TableStepper} Edition.U.stepper.U.N2: receiver {FeEdition} with: arg1 {XnRegion}
	^receiver stepper: arg1!

{TableStepper} Edition.U.stepper.U.N3: receiver {FeEdition} with: arg1 {XnRegion} with: arg2 {OrderSpec}
	^receiver stepper: arg1 with: arg2!

{FeRangeElement} Edition.U.theOne.U.N1: receiver {FeEdition}
	^receiver theOne!

{FeEdition} Edition.U.transformedBy.U.N2: receiver {FeEdition} with: arg1 {Mapping}
	^receiver transformedBy: arg1!

{CrossRegion} Edition.U.visibleEndorsements.U.N1: receiver {FeEdition}
	^receiver visibleEndorsements!

{FeEdition} Edition.U.with.U.N3: receiver {FeEdition} with: arg1 {Position} with: arg2 {FeRangeElement}
	^receiver with: arg1 with: arg2!

{FeEdition} Edition.U.withAll.U.N3: receiver {FeEdition} with: arg1 {XnRegion} with: arg2 {FeRangeElement}
	^receiver withAll: arg1 with: arg2!

{FeEdition} Edition.U.without.U.N2: receiver {FeEdition} with: arg1 {Position}
	^receiver without: arg1!

{FeEdition} Edition.U.withoutAll.U.N2: receiver {FeEdition} with: arg1 {XnRegion}
	^receiver withoutAll: arg1!

{FeRangeElement} ElementBundle.U.element.U.N1: receiver {FeElementBundle}
	^receiver element!

{XnRegion} Filter.U.baseRegion.U.N1: receiver {Filter}
	^receiver baseRegion!

{Stepper} Filter.U.intersectedFilters.U.N1: receiver {Filter}
	^receiver intersectedFilters!

{BooleanVar} Filter.U.isAllFilter.U.N1: receiver {Filter}
	^receiver isAllFilter!

{BooleanVar} Filter.U.isAnyFilter.U.N1: receiver {Filter}
	^receiver isAnyFilter!

{BooleanVar} Filter.U.match.U.N2: receiver {Filter} with: arg1 {XnRegion}
	^receiver match: arg1!

{Stepper} Filter.U.unionedFilters.U.N1: receiver {Filter}
	^receiver unionedFilters!

{XnRegion} FilterPosition.U.baseRegion.U.N1: receiver {FilterPosition}
	^receiver baseRegion!

{Filter} FilterSpace.U.allFilter.U.N2: receiver {FilterSpace} with: arg1 {XnRegion}
	^receiver allFilter: arg1!

{Filter} FilterSpace.U.anyFilter.U.N2: receiver {FilterSpace} with: arg1 {XnRegion}
	^receiver anyFilter: arg1!

{CoordinateSpace} FilterSpace.U.baseSpace.U.N1: receiver {FilterSpace}
	^receiver baseSpace!

{FilterSpace} FilterSpace.U.make.U.N1: arg1 {CoordinateSpace}
	^FilterSpace make: arg1!

{FilterPosition} FilterSpace.U.position.U.N2: receiver {FilterSpace} with: arg1 {XnRegion}
	^receiver position: arg1!

{PrimIntValue} FloatArray.U.bitCount.U.N1: receiver {PrimFloatArray}
	^PrimIntValue make: (receiver bitCount)!

{PrimFloatArray} FloatArray.U.zeros.U.N2: arg1 {PrimIntValue} with: arg2 {PrimIntValue}
	^PrimFloatArray zeros: arg1 asInt32 with: arg2 asInt32!

{PrimIntValue} FloatValue.U.bitCount.U.N1: receiver {PrimFloatValue}
	^PrimIntValue make: (receiver bitCount)!

{IntegerVarArray} HumberArray.U.zeros.U.N1: arg1 {PrimIntValue}
	^IntegerVarArray zeros: arg1 asInt32!

{FeHyperRef} HyperLink.U.endAt.U.N2: receiver {FeHyperLink} with: arg1 {Sequence}
	^receiver endAt: arg1!

{SequenceRegion} HyperLink.U.endNames.U.N1: receiver {FeHyperLink}
	^receiver endNames!

{FeSet} HyperLink.U.linkTypes.U.N1: receiver {FeHyperLink}
	^receiver linkTypes!

{FeHyperLink} HyperLink.U.make.U.N3: arg1 {FeSet} with: arg2 {FeHyperRef} with: arg3 {FeHyperRef}
	^FeHyperLink make: arg1 with: arg2 with: arg3!

{FeHyperLink} HyperLink.U.withEnd.U.N3: receiver {FeHyperLink} with: arg1 {Sequence} with: arg2 {FeHyperRef}
	^receiver withEnd: arg1 with: arg2!

{FeHyperLink} HyperLink.U.withLinkTypes.U.N2: receiver {FeHyperLink} with: arg1 {FeSet}
	^receiver withLinkTypes: arg1!

{FeHyperLink} HyperLink.U.withoutEnd.U.N2: receiver {FeHyperLink} with: arg1 {Sequence}
	^receiver withoutEnd: arg1!

{FeWork} HyperRef.U.originalContext.U.N1: receiver {FeHyperRef}
	^receiver originalContext!

{FePath} HyperRef.U.pathContext.U.N1: receiver {FeHyperRef}
	^receiver pathContext!

{FeHyperRef} HyperRef.U.withOriginalContext.U.N2: receiver {FeHyperRef} with: arg1 {FeWork}
	^receiver withOriginalContext: arg1!

{FeHyperRef} HyperRef.U.withPathContext.U.N2: receiver {FeHyperRef} with: arg1 {FePath}
	^receiver withPathContext: arg1!

{FeHyperRef} HyperRef.U.withWorkContext.U.N2: receiver {FeHyperRef} with: arg1 {FeWork}
	^receiver withWorkContext: arg1!

{FeWork} HyperRef.U.workContext.U.N1: receiver {FeHyperRef}
	^receiver workContext!

{PrimIntArray} ID.U.export.U.N1: receiver {ID}
	^receiver export!

{ID} ID.U.import.U.N1: arg1 {PrimIntArray}
	^ID import: arg1!

{ID} IDHolder.U.iD.U.N1: receiver {FeIDHolder}
	^receiver iD!

{FeIDHolder} IDHolder.U.make.U.N1: arg1 {ID}
	^FeIDHolder make: arg1!

{PrimIntArray} IDRegion.U.export.U.N1: receiver {IDRegion}
	^receiver export!

{IDRegion} IDRegion.U.import.U.N1: arg1 {PrimIntArray}
	^IDRegion import: arg1!

{PrimIntArray} IDSpace.U.export.U.N1: receiver {IDSpace}
	^receiver export!

{IDSpace} IDSpace.U.global.U.N0
	^IDSpace global!

{IDRegion} IDSpace.U.iDsFromServer.U.N2: receiver {IDSpace} with: arg1 {Sequence}
	^receiver iDsFromServer: arg1!

{IDSpace} IDSpace.U.import.U.N1: arg1 {PrimIntArray}
	^IDSpace import: arg1!

{ID} IDSpace.U.newID.U.N1: receiver {IDSpace}
	^receiver newID!

{IDRegion} IDSpace.U.newIDs.U.N2: receiver {IDSpace} with: arg1 {PrimIntValue}
	^receiver newIDs: arg1 asIntegerVar!

{IDSpace} IDSpace.U.unique.U.N0
	^IDSpace unique!

{PrimIntValue} IntArray.U.bitCount.U.N1: receiver {PrimIntArray}
	^PrimIntValue make: (receiver bitCount)!

{PrimIntArray} IntArray.U.zeros.U.N2: arg1 {PrimIntValue} with: arg2 {PrimIntValue}
	^PrimIntArray zeros: arg1 asInt32 with: arg2 asInt32!

{PrimIntValue} Integer.U.value.U.N1: receiver {IntegerPos}
	^PrimIntValue make: (receiver value)!

{PrimIntValue} IntegerMapping.U.translation.U.N1: receiver {IntegerMapping}
	^PrimIntValue make: (receiver translation)!

{Stepper} IntegerRegion.U.intervals.U.N1: receiver {IntegerRegion}
	^receiver intervals!

{Stepper} IntegerRegion.U.intervals.U.N2: receiver {IntegerRegion} with: arg1 {OrderSpec}
	^receiver intervals: arg1!

{BooleanVar} IntegerRegion.U.isBoundedAbove.U.N1: receiver {IntegerRegion}
	^receiver isBoundedAbove!

{BooleanVar} IntegerRegion.U.isBoundedBelow.U.N1: receiver {IntegerRegion}
	^receiver isBoundedBelow!

{BooleanVar} IntegerRegion.U.isInterval.U.N1: receiver {IntegerRegion}
	^receiver isInterval!

{PrimIntValue} IntegerRegion.U.start.U.N1: receiver {IntegerRegion}
	^PrimIntValue make: (receiver start)!

{PrimIntValue} IntegerRegion.U.stop.U.N1: receiver {IntegerRegion}
	^PrimIntValue make: (receiver stop)!

{IntegerRegion} IntegerSpace.U.above.U.N2: arg1 {IntegerPos} with: arg2 {BooleanVar}
	^IntegerSpace implicitReceiver above: arg1 with: arg2!

{IntegerRegion} IntegerSpace.U.below.U.N2: arg1 {IntegerPos} with: arg2 {BooleanVar}
	^IntegerSpace implicitReceiver below: arg1 with: arg2!

{IntegerRegion} IntegerSpace.U.interval.U.N2: arg1 {IntegerPos} with: arg2 {IntegerPos}
	^IntegerSpace implicitReceiver interval: arg1 with: arg2!

{IntegerSpace} IntegerSpace.U.make.U.N0
	^IntegerSpace make!

{IntegerPos} IntegerSpace.U.position.U.N1: arg1 {PrimIntValue}
	^IntegerSpace implicitReceiver position: arg1 asIntegerVar!

{IntegerMapping} IntegerSpace.U.translation.U.N1: arg1 {PrimIntValue}
	^IntegerSpace implicitReceiver translation: arg1 asIntegerVar!

{PrimIntValue} IntValue.U.bitCount.U.N1: receiver {PrimIntValue}
	^PrimIntValue make: (receiver bitCount)!

{PrimIntValue} IntValue.U.bitwiseAnd.U.N2: receiver {PrimIntValue} with: arg1 {PrimIntValue}
	^PrimIntValue make: (receiver bitwiseAnd: arg1)!

{PrimIntValue} IntValue.U.bitwiseOr.U.N2: receiver {PrimIntValue} with: arg1 {PrimIntValue}
	^PrimIntValue make: (receiver bitwiseOr: arg1)!

{PrimIntValue} IntValue.U.bitwiseXor.U.N2: receiver {PrimIntValue} with: arg1 {PrimIntValue}
	^PrimIntValue make: (receiver bitwiseXor: arg1)!

{PrimIntValue} IntValue.U.dividedBy.U.N2: receiver {PrimIntValue} with: arg1 {PrimIntValue}
	^PrimIntValue make: (receiver dividedBy: arg1)!

{BooleanVar} IntValue.U.isGE.U.N2: receiver {PrimIntValue} with: arg1 {PrimIntValue}
	^receiver isGE: arg1!

{PrimIntValue} IntValue.U.leftShift.U.N2: receiver {PrimIntValue} with: arg1 {PrimIntValue}
	^PrimIntValue make: (receiver leftShift: arg1)!

{PrimIntValue} IntValue.U.maximum.U.N2: receiver {PrimIntValue} with: arg1 {PrimIntValue}
	^PrimIntValue make: (receiver maximum: arg1)!

{PrimIntValue} IntValue.U.minimum.U.N2: receiver {PrimIntValue} with: arg1 {PrimIntValue}
	^PrimIntValue make: (receiver minimum: arg1)!

{PrimIntValue} IntValue.U.minus.U.N2: receiver {PrimIntValue} with: arg1 {PrimIntValue}
	^PrimIntValue make: (receiver minus: arg1)!

{PrimIntValue} IntValue.U.mod.U.N2: receiver {PrimIntValue} with: arg1 {PrimIntValue}
	^PrimIntValue make: (receiver mod: arg1)!

{PrimIntValue} IntValue.U.plus.U.N2: receiver {PrimIntValue} with: arg1 {PrimIntValue}
	^PrimIntValue make: (receiver plus: arg1)!

{PrimIntValue} IntValue.U.times.U.N2: receiver {PrimIntValue} with: arg1 {PrimIntValue}
	^PrimIntValue make: (receiver times: arg1)!

{IDRegion} KeyMaster.U.actualAuthority.U.N1: receiver {FeKeyMaster}
	^receiver actualAuthority!

{FeKeyMaster} KeyMaster.U.copy.U.N1: receiver {FeKeyMaster}
	^receiver copy!

{BooleanVar} KeyMaster.U.hasAuthority.U.N2: receiver {FeKeyMaster} with: arg1 {ID}
	^receiver hasAuthority: arg1!

{void} KeyMaster.U.incorporate.U.N2: receiver {FeKeyMaster} with: arg1 {FeKeyMaster}
	receiver incorporate: arg1!

{IDRegion} KeyMaster.U.loginAuthority.U.N1: receiver {FeKeyMaster}
	^receiver loginAuthority!

{void} KeyMaster.U.removeLogins.U.N2: receiver {FeKeyMaster} with: arg1 {IDRegion}
	receiver removeLogins: arg1!

{FeLabel} Label.U.make.U.N0
	^FeLabel make!

{Mapping} Mapping.U.combine.U.N2: receiver {Mapping} with: arg1 {Mapping}
	^receiver combine: arg1!

{XnRegion} Mapping.U.domain.U.N1: receiver {Mapping}
	^receiver domain!

{CoordinateSpace} Mapping.U.domainSpace.U.N1: receiver {Mapping}
	^receiver domainSpace!

{Mapping} Mapping.U.inverse.U.N1: receiver {Mapping}
	^receiver inverse!

{BooleanVar} Mapping.U.isComplete.U.N1: receiver {Mapping}
	^receiver isComplete!

{BooleanVar} Mapping.U.isIdentity.U.N1: receiver {Mapping}
	^receiver isIdentity!

{Position} Mapping.U.of.U.N2: receiver {Mapping} with: arg1 {Position}
	^receiver of: arg1!

{XnRegion} Mapping.U.ofAll.U.N2: receiver {Mapping} with: arg1 {XnRegion}
	^receiver ofAll: arg1!

{XnRegion} Mapping.U.range.U.N1: receiver {Mapping}
	^receiver range!

{CoordinateSpace} Mapping.U.rangeSpace.U.N1: receiver {Mapping}
	^receiver rangeSpace!

{Mapping} Mapping.U.restrict.U.N2: receiver {Mapping} with: arg1 {XnRegion}
	^receiver restrict: arg1!

{Stepper} Mapping.U.simplerMappings.U.N1: receiver {Mapping}
	^receiver simplerMappings!

{Mapping} Mapping.U.unrestricted.U.N1: receiver {Mapping}
	^receiver unrestricted!

{FeKeyMaster} MatchLock.U.encryptedPassword.U.N2: receiver {MatchLock} with: arg1 {PrimIntArray}
	^receiver encryptedPassword: arg1!

{FeMatchLockSmith} MatchLockSmith.U.make.U.N2: arg1 {PrimIntArray} with: arg2 {Sequence}
	^FeMatchLockSmith make: arg1 with: arg2!

{PrimIntArray} MatchLockSmith.U.scrambledPassword.U.N1: receiver {FeMatchLockSmith}
	^receiver scrambledPassword!

{PrimIntArray} MatchLockSmith.U.scramblerName.U.N1: receiver {FeMatchLockSmith}
	^receiver scramblerName!

{Lock} MultiLock.U.lock.U.N2: receiver {MultiLock} with: arg1 {Sequence}
	^receiver lock: arg1!

{SequenceRegion} MultiLock.U.lockNames.U.N1: receiver {MultiLock}
	^receiver lockNames!

{FeLockSmith} MultiLockSmith.U.lockSmith.U.N2: receiver {FeMultiLockSmith} with: arg1 {Sequence}
	^receiver lockSmith: arg1!

{SequenceRegion} MultiLockSmith.U.lockSmithNames.U.N1: receiver {FeMultiLockSmith}
	^receiver lockSmithNames!

{FeMultiLockSmith} MultiLockSmith.U.make.U.N0
	^FeMultiLockSmith make!

{FeMultiLockSmith} MultiLockSmith.U.with.U.N3: receiver {FeMultiLockSmith} with: arg1 {Sequence} with: arg2 {FeLockSmith}
	^receiver with: arg1 with: arg2!

{FeMultiLockSmith} MultiLockSmith.U.without.U.N2: receiver {FeMultiLockSmith} with: arg1 {Sequence}
	^receiver without: arg1!

{FeMultiRef} MultiRef.U.intersect.U.N2: receiver {FeMultiRef} with: arg1 {FeMultiRef}
	^receiver intersect: arg1!

{FeMultiRef} MultiRef.U.make.U.N1: arg1 {PtrArray}
	^FeMultiRef make: arg1!

{FeMultiRef} MultiRef.U.make.U.N2: arg1 {PtrArray} with: arg2 {FeWork}
	^FeMultiRef make: arg1 with: arg2!

{FeMultiRef} MultiRef.U.make.U.N3: arg1 {PtrArray} with: arg2 {FeWork} with: arg3 {FeWork}
	^FeMultiRef make: arg1 with: arg2 with: arg3!

{FeMultiRef} MultiRef.U.make.U.N4: arg1 {PtrArray} with: arg2 {FeWork} with: arg3 {FeWork} with: arg4 {FePath}
	^FeMultiRef make: arg1 with: arg2 with: arg3 with: arg4!

{FeMultiRef} MultiRef.U.minus.U.N2: receiver {FeMultiRef} with: arg1 {FeMultiRef}
	^receiver minus: arg1!

{Stepper} MultiRef.U.refs.U.N1: receiver {FeMultiRef}
	^receiver refs!

{FeMultiRef} MultiRef.U.unionWith.U.N2: receiver {FeMultiRef} with: arg1 {FeMultiRef}
	^receiver unionWith: arg1!

{FeMultiRef} MultiRef.U.with.U.N2: receiver {FeMultiRef} with: arg1 {FeHyperRef}
	^receiver with: arg1!

{FeMultiRef} MultiRef.U.without.U.N2: receiver {FeMultiRef} with: arg1 {FeHyperRef}
	^receiver without: arg1!

{CoordinateSpace} OrderSpec.U.coordinateSpace.U.N1: receiver {OrderSpec}
	^receiver coordinateSpace!

{BooleanVar} OrderSpec.U.follows.U.N3: receiver {OrderSpec} with: arg1 {Position} with: arg2 {Position}
	^receiver follows: arg1 with: arg2!

{OrderSpec} OrderSpec.U.reversed.U.N1: receiver {OrderSpec}
	^receiver reversed!

{FeRangeElement} Path.U.follow.U.N2: receiver {FePath} with: arg1 {FeEdition}
	^receiver follow: arg1!

{FePath} Path.U.make.U.N1: arg1 {PtrArray}
	^FePath make: arg1!

{XnRegion} Position.U.asRegion.U.N1: receiver {Position}
	^receiver asRegion!

{CoordinateSpace} Position.U.coordinateSpace.U.N1: receiver {Position}
	^receiver coordinateSpace!

{PtrArray} PtrArray.U.nulls.U.N1: arg1 {PrimIntValue}
	^PtrArray nulls: arg1 asInt32!

{FeRangeElement} RangeElement.U.again.U.N1: receiver {FeRangeElement}
	^receiver again!

{BooleanVar} RangeElement.U.canMakeIdentical.U.N2: receiver {FeRangeElement} with: arg1 {FeRangeElement}
	^receiver canMakeIdentical: arg1!

{BooleanVar} RangeElement.U.isIdentical.U.N2: receiver {FeRangeElement} with: arg1 {FeRangeElement}
	^receiver isIdentical: arg1!

{FeLabel} RangeElement.U.label.U.N1: receiver {FeRangeElement}
	^receiver label!

{void} RangeElement.U.makeIdentical.U.N2: receiver {FeRangeElement} with: arg1 {FeRangeElement}
	receiver makeIdentical: arg1!

{ID} RangeElement.U.owner.U.N1: receiver {FeRangeElement}
	^receiver owner!

{FeRangeElement} RangeElement.U.placeHolder.U.N0
	^FeRangeElement placeHolder!

{FeRangeElement} RangeElement.U.relabelled.U.N2: receiver {FeRangeElement} with: arg1 {FeLabel}
	^receiver relabelled: arg1!

{void} RangeElement.U.setOwner.U.N2: receiver {FeRangeElement} with: arg1 {ID}
	receiver setOwner: arg1!

{FeEdition} RangeElement.U.transcluders.U.N1: receiver {FeRangeElement}
	^receiver transcluders!

{FeEdition} RangeElement.U.transcluders.U.N2: receiver {FeRangeElement} with: arg1 {Filter}
	^receiver transcluders: arg1!

{FeEdition} RangeElement.U.transcluders.U.N3: receiver {FeRangeElement} with: arg1 {Filter} with: arg2 {Filter}
	^receiver transcluders: arg1 with: arg2!

{FeEdition} RangeElement.U.transcluders.U.N4: receiver {FeRangeElement} with: arg1 {Filter} with: arg2 {Filter} with: arg3 {PrimIntValue}
	^receiver transcluders: arg1 with: arg2 with: arg3 asInt32!

{FeEdition} RangeElement.U.transcluders.U.N5: receiver {FeRangeElement} with: arg1 {Filter} with: arg2 {Filter} with: arg3 {PrimIntValue} with: arg4 {FeEdition}
	^receiver transcluders: arg1 with: arg2 with: arg3 asInt32 with: arg4!

{FeEdition} RangeElement.U.works.U.N1: receiver {FeRangeElement}
	^receiver works!

{FeEdition} RangeElement.U.works.U.N2: receiver {FeRangeElement} with: arg1 {Filter}
	^receiver works: arg1!

{FeEdition} RangeElement.U.works.U.N3: receiver {FeRangeElement} with: arg1 {Filter} with: arg2 {PrimIntValue}
	^receiver works: arg1 with: arg2 asInt32!

{FeEdition} RangeElement.U.works.U.N4: receiver {FeRangeElement} with: arg1 {Filter} with: arg2 {PrimIntValue} with: arg3 {FeEdition}
	^receiver works: arg1 with: arg2 asInt32 with: arg3!

{PrimFloatValue} Real.U.value.U.N1: receiver {RealPos}
	^receiver value!

{Stepper} RealRegion.U.intervals.U.N1: receiver {RealRegion}
	^receiver intervals!

{Stepper} RealRegion.U.intervals.U.N2: receiver {RealRegion} with: arg1 {OrderSpec}
	^receiver intervals: arg1!

{BooleanVar} RealRegion.U.isBoundedAbove.U.N1: receiver {RealRegion}
	^receiver isBoundedAbove!

{BooleanVar} RealRegion.U.isBoundedBelow.U.N1: receiver {RealRegion}
	^receiver isBoundedBelow!

{BooleanVar} RealRegion.U.isInterval.U.N1: receiver {RealRegion}
	^receiver isInterval!

{RealPos} RealRegion.U.lowerBound.U.N1: receiver {RealRegion}
	^receiver lowerBound!

{RealPos} RealRegion.U.upperBound.U.N1: receiver {RealRegion}
	^receiver upperBound!

{RealRegion} RealSpace.U.above.U.N3: receiver {RealSpace} with: arg1 {RealPos} with: arg2 {BooleanVar}
	^receiver above: arg1 with: arg2!

{RealRegion} RealSpace.U.below.U.N3: receiver {RealSpace} with: arg1 {RealPos} with: arg2 {BooleanVar}
	^receiver below: arg1 with: arg2!

{RealRegion} RealSpace.U.interval.U.N3: receiver {RealSpace} with: arg1 {RealPos} with: arg2 {RealPos}
	^receiver interval: arg1 with: arg2!

{RealSpace} RealSpace.U.make.U.N0
	^RealSpace make!

{RealPos} RealSpace.U.position.U.N2: receiver {RealSpace} with: arg1 {PrimFloatValue}
	^receiver position: arg1 asIEEE64!

{XnRegion} Region.U.chooseMany.U.N2: receiver {XnRegion} with: arg1 {PrimIntValue}
	^receiver chooseMany: arg1 asIntegerVar!

{XnRegion} Region.U.chooseMany.U.N3: receiver {XnRegion} with: arg1 {PrimIntValue} with: arg2 {OrderSpec}
	^receiver chooseMany: arg1 asIntegerVar with: arg2!

{Position} Region.U.chooseOne.U.N1: receiver {XnRegion}
	^receiver chooseOne!

{Position} Region.U.chooseOne.U.N2: receiver {XnRegion} with: arg1 {OrderSpec}
	^receiver chooseOne: arg1!

{XnRegion} Region.U.complement.U.N1: receiver {XnRegion}
	^receiver complement!

{CoordinateSpace} Region.U.coordinateSpace.U.N1: receiver {XnRegion}
	^receiver coordinateSpace!

{PrimIntValue} Region.U.count.U.N1: receiver {XnRegion}
	^PrimIntValue make: (receiver count)!

{BooleanVar} Region.U.hasMember.U.N2: receiver {XnRegion} with: arg1 {Position}
	^receiver hasMember: arg1!

{XnRegion} Region.U.intersect.U.N2: receiver {XnRegion} with: arg1 {XnRegion}
	^receiver intersect: arg1!

{BooleanVar} Region.U.intersects.U.N2: receiver {XnRegion} with: arg1 {XnRegion}
	^receiver intersects: arg1!

{BooleanVar} Region.U.isEmpty.U.N1: receiver {XnRegion}
	^receiver isEmpty!

{BooleanVar} Region.U.isFinite.U.N1: receiver {XnRegion}
	^receiver isFinite!

{BooleanVar} Region.U.isFull.U.N1: receiver {XnRegion}
	^receiver isFull!

{BooleanVar} Region.U.isSubsetOf.U.N2: receiver {XnRegion} with: arg1 {XnRegion}
	^receiver isSubsetOf: arg1!

{XnRegion} Region.U.minus.U.N2: receiver {XnRegion} with: arg1 {XnRegion}
	^receiver minus: arg1!

{Stepper} Region.U.stepper.U.N1: receiver {XnRegion}
	^receiver stepper!

{Stepper} Region.U.stepper.U.N2: receiver {XnRegion} with: arg1 {OrderSpec}
	^receiver stepper: arg1!

{Position} Region.U.theOne.U.N1: receiver {XnRegion}
	^receiver theOne!

{XnRegion} Region.U.unionWith.U.N2: receiver {XnRegion} with: arg1 {XnRegion}
	^receiver unionWith: arg1!

{XnRegion} Region.U.with.U.N2: receiver {XnRegion} with: arg1 {Position}
	^receiver with: arg1!

{XnRegion} Region.U.without.U.N2: receiver {XnRegion} with: arg1 {Position}
	^receiver without: arg1!

{PrimIntValue} Sequence.U.firstIndex.U.N1: receiver {Sequence}
	^PrimIntValue make: (receiver firstIndex)!

{PrimIntValue} Sequence.U.integerAt.U.N2: receiver {Sequence} with: arg1 {PrimIntValue}
	^PrimIntValue make: (receiver integerAt: arg1 asIntegerVar)!

{PrimArray} Sequence.U.integers.U.N1: receiver {Sequence}
	^receiver integers!

{BooleanVar} Sequence.U.isZero.U.N1: receiver {Sequence}
	^receiver isZero!

{PrimIntValue} Sequence.U.lastIndex.U.N1: receiver {Sequence}
	^PrimIntValue make: (receiver lastIndex)!

{Sequence} Sequence.U.with.U.N3: receiver {Sequence} with: arg1 {PrimIntValue} with: arg2 {PrimIntValue}
	^receiver with: arg1 asIntegerVar with: arg2 asIntegerVar!

{PrimIntValue} SequenceMapping.U.shift.U.N1: receiver {SequenceMapping}
	^PrimIntValue make: (receiver shift)!

{Sequence} SequenceMapping.U.translation.U.N1: receiver {SequenceMapping}
	^receiver translation!

{Stepper} SequenceRegion.U.intervals.U.N1: receiver {SequenceRegion}
	^receiver intervals!

{Stepper} SequenceRegion.U.intervals.U.N2: receiver {SequenceRegion} with: arg1 {OrderSpec}
	^receiver intervals: arg1!

{BooleanVar} SequenceRegion.U.isBoundedAbove.U.N1: receiver {SequenceRegion}
	^receiver isBoundedAbove!

{BooleanVar} SequenceRegion.U.isBoundedBelow.U.N1: receiver {SequenceRegion}
	^receiver isBoundedBelow!

{BooleanVar} SequenceRegion.U.isInterval.U.N1: receiver {SequenceRegion}
	^receiver isInterval!

{Sequence} SequenceRegion.U.lowerEdge.U.N1: receiver {SequenceRegion}
	^receiver lowerEdge!

{PrimIntValue} SequenceRegion.U.lowerEdgePrefixLimit.U.N1: receiver {SequenceRegion}
	^PrimIntValue make: (receiver lowerEdgePrefixLimit)!

{PrimIntValue} SequenceRegion.U.lowerEdgeType.U.N1: receiver {SequenceRegion}
	^PrimIntValue make: (receiver lowerEdgeType)!

{Sequence} SequenceRegion.U.upperEdge.U.N1: receiver {SequenceRegion}
	^receiver upperEdge!

{PrimIntValue} SequenceRegion.U.upperEdgePrefixLimit.U.N1: receiver {SequenceRegion}
	^PrimIntValue make: (receiver upperEdgePrefixLimit)!

{PrimIntValue} SequenceRegion.U.upperEdgeType.U.N1: receiver {SequenceRegion}
	^PrimIntValue make: (receiver upperEdgeType)!

{SequenceRegion} SequenceSpace.U.above.U.N2: arg1 {Sequence} with: arg2 {BooleanVar}
	^SequenceSpace implicitReceiver above: arg1 with: arg2!

{SequenceRegion} SequenceSpace.U.below.U.N2: arg1 {Sequence} with: arg2 {BooleanVar}
	^SequenceSpace implicitReceiver below: arg1 with: arg2!

{SequenceRegion} SequenceSpace.U.interval.U.N2: arg1 {Sequence} with: arg2 {Sequence}
	^SequenceSpace implicitReceiver interval: arg1 with: arg2!

{SequenceSpace} SequenceSpace.U.make.U.N0
	^SequenceSpace make!

{SequenceMapping} SequenceSpace.U.mapping.U.N1: arg1 {PrimIntValue}
	^SequenceSpace implicitReceiver mapping: arg1 asIntegerVar!

{SequenceMapping} SequenceSpace.U.mapping.U.N2: arg1 {PrimIntValue} with: arg2 {Sequence}
	^SequenceSpace implicitReceiver mapping: arg1 asIntegerVar with: arg2!

{Sequence} SequenceSpace.U.position.U.N1: arg1 {PrimArray}
	^SequenceSpace implicitReceiver position: arg1!

{Sequence} SequenceSpace.U.position.U.N2: arg1 {PrimArray} with: arg2 {PrimIntValue}
	^SequenceSpace implicitReceiver position: arg1 with: arg2 asIntegerVar!

{SequenceRegion} SequenceSpace.U.prefixedBy.U.N2: arg1 {Sequence} with: arg2 {PrimIntValue}
	^SequenceSpace implicitReceiver prefixedBy: arg1 with: arg2 asIntegerVar!

{ID} Server.U.accessClubID.U.N0
	^FeServer accessClubID!

{ID} Server.U.adminClubID.U.N0
	^FeServer adminClubID!

{ID} Server.U.archiveClubID.U.N0
	^FeServer archiveClubID!

{ID} Server.U.assignID.U.N1: arg1 {FeRangeElement}
	^FeServer assignID: arg1!

{ID} Server.U.assignID.U.N2: arg1 {FeRangeElement} with: arg2 {ID}
	^FeServer assignID: arg1 with: arg2!

{ID} Server.U.clubDirectoryID.U.N0
	^FeServer clubDirectoryID!

{PrimIntValue} Server.U.currentTime.U.N0
	^PrimIntValue make: (FeServer currentTime)!

{ID} Server.U.emptyClubID.U.N0
	^FeServer emptyClubID!

{Sequence} Server.U.encrypterName.U.N0
	^FeServer encrypterName!

{FeRangeElement} Server.U.get.U.N1: arg1 {ID}
	^FeServer get: arg1!

{Sequence} Server.U.identifier.U.N0
	^FeServer identifier!

{ID} Server.U.iDOf.U.N1: arg1 {FeRangeElement}
	^FeServer iDOf: arg1!

{IDRegion} Server.U.iDsOf.U.N1: arg1 {FeRangeElement}
	^FeServer iDsOf: arg1!

{IDRegion} Server.U.iDsOfRange.U.N1: arg1 {FeEdition}
	^FeServer iDsOfRange: arg1!

{Lock} Server.U.login.U.N1: arg1 {ID}
	^FeServer login: arg1!

{Lock} Server.U.loginByName.U.N1: arg1 {Sequence}
	^FeServer loginByName: arg1!

{ID} Server.U.publicClubID.U.N0
	^FeServer publicClubID!

{PrimIntArray} Server.U.publicKey.U.N0
	^FeServer publicKey!

{PrimIntValue} Session.U.connectTime.U.N1: receiver {FeSession}
	^PrimIntValue make: (receiver connectTime)!

{FeSession} Session.U.current.U.N0
	^FeSession current!

{void} Session.U.endSession.U.N1: receiver {FeSession}
	receiver endSession!

{void} Session.U.endSession.U.N2: receiver {FeSession} with: arg1 {BooleanVar}
	receiver endSession: arg1!

{ID} Session.U.initialLogin.U.N1: receiver {FeSession}
	^receiver initialLogin!

{BooleanVar} Session.U.isConnected.U.N1: receiver {FeSession}
	^receiver isConnected!

{PrimIntArray} Session.U.port.U.N1: receiver {FeSession}
	^receiver port!

{PrimIntValue} Set.U.count.U.N1: receiver {FeSet}
	^PrimIntValue make: (receiver count)!

{BooleanVar} Set.U.includes.U.N2: receiver {FeSet} with: arg1 {FeRangeElement}
	^receiver includes: arg1!

{FeSet} Set.U.intersect.U.N2: receiver {FeSet} with: arg1 {FeSet}
	^receiver intersect: arg1!

{FeSet} Set.U.make.U.N0
	^FeSet make!

{FeSet} Set.U.make.U.N1: arg1 {PtrArray}
	^FeSet make: arg1!

{FeSet} Set.U.minus.U.N2: receiver {FeSet} with: arg1 {FeSet}
	^receiver minus: arg1!

{FeRangeElement} Set.U.theOne.U.N1: receiver {FeSet}
	^receiver theOne!

{FeSet} Set.U.unionWith.U.N2: receiver {FeSet} with: arg1 {FeSet}
	^receiver unionWith: arg1!

{FeSet} Set.U.with.U.N2: receiver {FeSet} with: arg1 {FeRangeElement}
	^receiver with: arg1!

{FeSet} Set.U.without.U.N2: receiver {FeSet} with: arg1 {FeRangeElement}
	^receiver without: arg1!

{FeEdition} SingleRef.U.excerpt.U.N1: receiver {FeSingleRef}
	^receiver excerpt!

{FeSingleRef} SingleRef.U.make.U.N1: arg1 {FeEdition}
	^FeSingleRef make: arg1!

{FeSingleRef} SingleRef.U.make.U.N2: arg1 {FeEdition} with: arg2 {FeWork}
	^FeSingleRef make: arg1 with: arg2!

{FeSingleRef} SingleRef.U.make.U.N3: arg1 {FeEdition} with: arg2 {FeWork} with: arg3 {FeWork}
	^FeSingleRef make: arg1 with: arg2 with: arg3!

{FeSingleRef} SingleRef.U.make.U.N4: arg1 {FeEdition} with: arg2 {FeWork} with: arg3 {FeWork} with: arg4 {FePath}
	^FeSingleRef make: arg1 with: arg2 with: arg3 with: arg4!

{FeSingleRef} SingleRef.U.withExcerpt.U.N2: receiver {FeSingleRef} with: arg1 {FeEdition}
	^receiver withExcerpt: arg1!

{BooleanVar} Stepper.U.atEnd.U.N1: receiver {Stepper}
	^receiver atEnd!

{Stepper} Stepper.U.copy.U.N1: receiver {Stepper}
	^receiver copy!

{Heaper} Stepper.U.get.U.N1: receiver {Stepper}
	^receiver get!

{void} Stepper.U.step.U.N1: receiver {Stepper}
	receiver step!

{PrimArray} Stepper.U.stepMany.U.N1: receiver {Stepper}
	^receiver stepMany!

{PrimArray} Stepper.U.stepMany.U.N2: receiver {Stepper} with: arg1 {PrimIntValue}
	^receiver stepMany: arg1 asInt32!

{Heaper} Stepper.U.theOne.U.N1: receiver {Stepper}
	^receiver theOne!

{Position} TableStepper.U.position.U.N1: receiver {TableStepper}
	^receiver position!

{PrimArray} TableStepper.U.stepManyPairs.U.N1: receiver {TableStepper}
	^receiver stepManyPairs!

{PrimArray} TableStepper.U.stepManyPairs.U.N2: receiver {TableStepper} with: arg1 {PrimIntValue}
	^receiver stepManyPairs: arg1 asInt32!

{FeEdition} Text.U.contents.U.N1: receiver {FeText}
	^receiver contents!

{PrimIntValue} Text.U.count.U.N1: receiver {FeText}
	^PrimIntValue make: (receiver count)!

{FeText} Text.U.extract.U.N2: receiver {FeText} with: arg1 {IntegerRegion}
	^receiver extract: arg1!

{FeText} Text.U.insert.U.N3: receiver {FeText} with: arg1 {PrimIntValue} with: arg2 {FeText}
	^receiver insert: arg1 asIntegerVar with: arg2!

{FeText} Text.U.make.U.N1: arg1 {PrimArray}
	^FeText make: arg1!

{FeText} Text.U.move.U.N3: receiver {FeText} with: arg1 {PrimIntValue} with: arg2 {IntegerRegion}
	^receiver move: arg1 asIntegerVar with: arg2!

{FeText} Text.U.replace.U.N3: receiver {FeText} with: arg1 {IntegerRegion} with: arg2 {FeText}
	^receiver replace: arg1 with: arg2!

{Position} Tuple.U.coordinate.U.N2: receiver {Tuple} with: arg1 {PrimIntValue}
	^receiver coordinate: arg1 asInt32!

{PtrArray} Tuple.U.coordinates.U.N1: receiver {Tuple}
	^receiver coordinates!

{FeWallLockSmith} WallLockSmith.U.make.U.N0
	^FeWallLockSmith make!

{BooleanVar} Work.U.canRead.U.N1: receiver {FeWork}
	^receiver canRead!

{BooleanVar} Work.U.canRevise.U.N1: receiver {FeWork}
	^receiver canRevise!

{ID} Work.U.editClub.U.N1: receiver {FeWork}
	^receiver editClub!

{FeEdition} Work.U.edition.U.N1: receiver {FeWork}
	^receiver edition!

{void} Work.U.endorse.U.N2: receiver {FeWork} with: arg1 {CrossRegion}
	receiver endorse: arg1!

{CrossRegion} Work.U.endorsements.U.N1: receiver {FeWork}
	^receiver endorsements!

{void} Work.U.grab.U.N1: receiver {FeWork}
	receiver grab!

{ID} Work.U.grabber.U.N1: receiver {FeWork}
	^receiver grabber!

{ID} Work.U.historyClub.U.N1: receiver {FeWork}
	^receiver historyClub!

{ID} Work.U.lastRevisionAuthor.U.N1: receiver {FeWork}
	^receiver lastRevisionAuthor!

{PrimIntValue} Work.U.lastRevisionNumber.U.N1: receiver {FeWork}
	^PrimIntValue make: (receiver lastRevisionNumber)!

{PrimIntValue} Work.U.lastRevisionTime.U.N1: receiver {FeWork}
	^PrimIntValue make: (receiver lastRevisionTime)!

{FeWork} Work.U.make.U.N1: arg1 {FeEdition}
	^FeWork make: arg1!

{ID} Work.U.readClub.U.N1: receiver {FeWork}
	^receiver readClub!

{void} Work.U.release.U.N1: receiver {FeWork}
	receiver release!

{void} Work.U.removeEditClub.U.N1: receiver {FeWork}
	receiver removeEditClub!

{void} Work.U.removeReadClub.U.N1: receiver {FeWork}
	receiver removeReadClub!

{void} Work.U.requestGrab.U.N1: receiver {FeWork}
	receiver requestGrab!

{void} Work.U.retract.U.N2: receiver {FeWork} with: arg1 {CrossRegion}
	receiver retract: arg1!

{void} Work.U.revise.U.N2: receiver {FeWork} with: arg1 {FeEdition}
	receiver revise: arg1!

{FeEdition} Work.U.revisions.U.N1: receiver {FeWork}
	^receiver revisions!

{void} Work.U.setEditClub.U.N2: receiver {FeWork} with: arg1 {ID}
	receiver setEditClub: arg1!

{void} Work.U.setHistoryClub.U.N2: receiver {FeWork} with: arg1 {ID}
	receiver setHistoryClub: arg1!

{void} Work.U.setReadClub.U.N2: receiver {FeWork} with: arg1 {ID}
	receiver setReadClub: arg1!

{void} Work.U.sponsor.U.N2: receiver {FeWork} with: arg1 {IDRegion}
	receiver sponsor: arg1!

{IDRegion} Work.U.sponsors.U.N1: receiver {FeWork}
	^receiver sponsors!

{void} Work.U.unsponsor.U.N2: receiver {FeWork} with: arg1 {IDRegion}
	receiver unsponsor: arg1!

{FeEdition} Wrapper.U.edition.U.N1: receiver {FeWrapper}
	^receiver edition!

{FeWrapper} Wrapper.U.inner.U.N1: receiver {FeWrapper}
	^receiver inner!

{Filter} WrapperSpec.U.filter.U.N1: receiver {FeWrapperSpec}
	^receiver filter!

{FeWrapperSpec} WrapperSpec.U.get.U.N1: arg1 {Sequence}
	^FeWrapperSpec get: arg1!

{Sequence} WrapperSpec.U.name.U.N1: receiver {FeWrapperSpec}
	^receiver name!

{FeWrapper} WrapperSpec.U.wrap.U.N2: receiver {FeWrapperSpec} with: arg1 {FeEdition}
	^receiver wrap: arg1! !RequestHandler subclass: #BHHandler
	instanceVariableNames: '
		myFn {BHFn var}
		myType1 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(BHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	pm noErrors ifTrue:
		[pm respondBooleanVar: (myFn invokeFunction: arg1)]! !

!BHHandler methodsFor: 'creation'!

create: fn {BHFn var} with: type1 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BHHandler class
	instanceVariableNames: ''!

(BHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {BHFn var} with: type1 {Category}
	^self create: fn with: type1! !

!BHHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #BHHHandler
	instanceVariableNames: '
		myFn {BHHFn var}
		myType1 {Category}
		myType2 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(BHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BHHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	pm noErrors ifTrue:
		[pm respondBooleanVar: (myFn invokeFunction: arg1 with: arg2)]! !

!BHHHandler methodsFor: 'creation'!

create: fn {BHHFn var} with: type1 {Category} with: type2 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BHHHandler class
	instanceVariableNames: ''!

(BHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BHHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {BHHFn var} with: type1 {Category} with: type2 {Category}
	^self create: fn with: type1 with: type2! !

!BHHHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #BHHHHandler
	instanceVariableNames: '
		myFn {BHHHFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(BHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BHHHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} arg3 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	arg3 _ pm fetchNonNullHeaper: myType3.
	pm noErrors ifTrue:
		[pm respondBooleanVar: (myFn invokeFunction: arg1 with: arg2 with: arg3)]! !

!BHHHHandler methodsFor: 'creation'!

create: fn {BHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

BHHHHandler class
	instanceVariableNames: ''!

(BHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!BHHHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {BHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	^self create: fn with: type1 with: type2 with: type3! !

!BHHHHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HHandler
	instanceVariableNames: 'myFn {HFn var}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction)]! !

!HHandler methodsFor: 'creation'!

create: fn {HFn var}
	super create.
	myFn _ fn.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHandler class
	instanceVariableNames: ''!

(HHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HFn var}
	^self create: fn! !

!HHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HHBHandler
	instanceVariableNames: '
		myFn {HHBFn var}
		myType1 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHBHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHBHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {BooleanVar} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchBooleanVar.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2)]! !

!HHBHandler methodsFor: 'creation'!

create: fn {HHBFn var} with: type1 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHBHandler class
	instanceVariableNames: ''!

(HHBHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHBHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHBFn var} with: type1 {Category}
	^self create: fn with: type1! !

!HHBHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HHHandler
	instanceVariableNames: '
		myFn {HHFn var}
		myType1 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1)]! !

!HHHandler methodsFor: 'creation'!

create: fn {HHFn var} with: type1 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHHandler class
	instanceVariableNames: ''!

(HHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHFn var} with: type1 {Category}
	^self create: fn with: type1! !

!HHHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HHHBHandler
	instanceVariableNames: '
		myFn {HHHBFn var}
		myType1 {Category}
		myType2 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHHBHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHBHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} arg3 {BooleanVar} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	arg3 _ pm fetchBooleanVar.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3)]! !

!HHHBHandler methodsFor: 'creation'!

create: fn {HHHBFn var} with: type1 {Category} with: type2 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHHBHandler class
	instanceVariableNames: ''!

(HHHBHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHBHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHHBFn var} with: type1 {Category} with: type2 {Category}
	^self create: fn with: type1 with: type2! !

!HHHBHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HHHHandler
	instanceVariableNames: '
		myFn {HHHFn var}
		myType1 {Category}
		myType2 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2)]! !

!HHHHandler methodsFor: 'creation'!

create: fn {HHHFn var} with: type1 {Category} with: type2 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHHHandler class
	instanceVariableNames: ''!

(HHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHHFn var} with: type1 {Category} with: type2 {Category}
	^self create: fn with: type1 with: type2! !

!HHHHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HHHHHandler
	instanceVariableNames: '
		myFn {HHHHFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} arg3 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	arg3 _ pm fetchNonNullHeaper: myType3.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3)]! !

!HHHHHandler methodsFor: 'creation'!

create: fn {HHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHHHHandler class
	instanceVariableNames: ''!

(HHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	^self create: fn with: type1 with: type2 with: type3! !

!HHHHHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HHHHHHandler
	instanceVariableNames: '
		myFn {HHHHHFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}
		myType4 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHHHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} arg3 {Heaper} arg4 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	arg3 _ pm fetchNonNullHeaper: myType3.
	arg4 _ pm fetchNonNullHeaper: myType4.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3 with: arg4)]! !

!HHHHHHandler methodsFor: 'creation'!

create: fn {HHHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.
	myType4 _ type4.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHHHHHandler class
	instanceVariableNames: ''!

(HHHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHHHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category}
	^self create: fn with: type1 with: type2 with: type3 with: type4! !

!HHHHHHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HHHHHHHandler
	instanceVariableNames: '
		myFn {HHHHHHFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}
		myType4 {Category}
		myType5 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHHHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHHHHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} arg3 {Heaper} arg4 {Heaper} arg5 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	arg3 _ pm fetchNonNullHeaper: myType3.
	arg4 _ pm fetchNonNullHeaper: myType4.
	arg5 _ pm fetchNonNullHeaper: myType5.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3 with: arg4 with: arg5)]! !

!HHHHHHHandler methodsFor: 'creation'!

create: fn {HHHHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category} with: type5 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.
	myType4 _ type4.
	myType5 _ type5.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHHHHHHandler class
	instanceVariableNames: ''!

(HHHHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHHHHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHHHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category} with: type5 {Category}
	^self create: fn with: type1 with: type2 with: type3 with: type4 with: type5! !

!HHHHHHHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HHHNHandler
	instanceVariableNames: '
		myFn {HHHNFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHHNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHNHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} arg3 {Heaper | NULL} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	arg3 _ pm fetchHeaper: myType3.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3)]! !

!HHHNHandler methodsFor: 'creation'!

create: fn {HHHNFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHHNHandler class
	instanceVariableNames: ''!

(HHHNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHHNHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHHNFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	^self create: fn with: type1 with: type2 with: type3! !

!HHHNHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HHNHandler
	instanceVariableNames: '
		myFn {HHNFn var}
		myType1 {Category}
		myType2 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHNHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper | NULL} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchHeaper: myType2.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2)]! !

!HHNHandler methodsFor: 'creation'!

create: fn {HHNFn var} with: type1 {Category} with: type2 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHNHandler class
	instanceVariableNames: ''!

(HHNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHNHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHNFn var} with: type1 {Category} with: type2 {Category}
	^self create: fn with: type1 with: type2! !

!HHNHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HHNHHandler
	instanceVariableNames: '
		myFn {HHNHFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHNHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHNHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper | NULL} arg3 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchHeaper: myType2.
	arg3 _ pm fetchNonNullHeaper: myType3.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3)]! !

!HHNHHandler methodsFor: 'creation'!

create: fn {HHNHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHNHHandler class
	instanceVariableNames: ''!

(HHNHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHNHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHNHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	^self create: fn with: type1 with: type2 with: type3! !

!HHNHHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HHNHNHandler
	instanceVariableNames: '
		myFn {HHNHNFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}
		myType4 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHNHNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHNHNHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper | NULL} arg3 {Heaper} arg4 {Heaper | NULL} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchHeaper: myType2.
	arg3 _ pm fetchNonNullHeaper: myType3.
	arg4 _ pm fetchHeaper: myType4.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3 with: arg4)]! !

!HHNHNHandler methodsFor: 'creation'!

create: fn {HHNHNFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.
	myType4 _ type4.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHNHNHandler class
	instanceVariableNames: ''!

(HHNHNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHNHNHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHNHNFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category}
	^self create: fn with: type1 with: type2 with: type3 with: type4! !

!HHNHNHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HHNNHandler
	instanceVariableNames: '
		myFn {HHNNFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHNNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHNNHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper | NULL} arg3 {Heaper | NULL} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchHeaper: myType2.
	arg3 _ pm fetchHeaper: myType3.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3)]! !

!HHNNHandler methodsFor: 'creation'!

create: fn {HHNNFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHNNHandler class
	instanceVariableNames: ''!

(HHNNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHNNHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHNNFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	^self create: fn with: type1 with: type2 with: type3! !

!HHNNHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HHNNHHandler
	instanceVariableNames: '
		myFn {HHNNHFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}
		myType4 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHNNHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHNNHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper | NULL} arg3 {Heaper | NULL} arg4 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchHeaper: myType2.
	arg3 _ pm fetchHeaper: myType3.
	arg4 _ pm fetchNonNullHeaper: myType4.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3 with: arg4)]! !

!HHNNHHandler methodsFor: 'creation'!

create: fn {HHNNHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.
	myType4 _ type4.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHNNHHandler class
	instanceVariableNames: ''!

(HHNNHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHNNHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHNNHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category}
	^self create: fn with: type1 with: type2 with: type3 with: type4! !

!HHNNHHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HHNNHNHandler
	instanceVariableNames: '
		myFn {HHNNHNFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}
		myType4 {Category}
		myType5 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHNNHNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHNNHNHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper | NULL} arg3 {Heaper | NULL} arg4 {Heaper} arg5 {Heaper | NULL} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchHeaper: myType2.
	arg3 _ pm fetchHeaper: myType3.
	arg4 _ pm fetchNonNullHeaper: myType4.
	arg5 _ pm fetchHeaper: myType5.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3 with: arg4 with: arg5)]! !

!HHNNHNHandler methodsFor: 'creation'!

create: fn {HHNNHNFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category} with: type5 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.
	myType4 _ type4.
	myType5 _ type5.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHNNHNHandler class
	instanceVariableNames: ''!

(HHNNHNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHNNHNHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHNNHNFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category} with: type5 {Category}
	^self create: fn with: type1 with: type2 with: type3 with: type4 with: type5! !

!HHNNHNHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HHNNNHandler
	instanceVariableNames: '
		myFn {HHNNNFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}
		myType4 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHNNNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHNNNHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper | NULL} arg3 {Heaper | NULL} arg4 {Heaper | NULL} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchHeaper: myType2.
	arg3 _ pm fetchHeaper: myType3.
	arg4 _ pm fetchHeaper: myType4.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3 with: arg4)]! !

!HHNNNHandler methodsFor: 'creation'!

create: fn {HHNNNFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.
	myType4 _ type4.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHNNNHandler class
	instanceVariableNames: ''!

(HHNNNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHNNNHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHNNNFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category}
	^self create: fn with: type1 with: type2 with: type3 with: type4! !

!HHNNNHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HHNNNHHandler
	instanceVariableNames: '
		myFn {HHNNNHFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}
		myType4 {Category}
		myType5 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHNNNHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHNNNHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper | NULL} arg3 {Heaper | NULL} arg4 {Heaper | NULL} arg5 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchHeaper: myType2.
	arg3 _ pm fetchHeaper: myType3.
	arg4 _ pm fetchHeaper: myType4.
	arg5 _ pm fetchNonNullHeaper: myType5.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3 with: arg4 with: arg5)]! !

!HHNNNHHandler methodsFor: 'creation'!

create: fn {HHNNNHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category} with: type5 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.
	myType4 _ type4.
	myType5 _ type5.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHNNNHHandler class
	instanceVariableNames: ''!

(HHNNNHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHNNNHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHNNNHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category} with: type5 {Category}
	^self create: fn with: type1 with: type2 with: type3 with: type4 with: type5! !

!HHNNNHHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HHNNNHNHandler
	instanceVariableNames: '
		myFn {HHNNNHNFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}
		myType4 {Category}
		myType5 {Category}
		myType6 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HHNNNHNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHNNNHNHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper | NULL} arg3 {Heaper | NULL} arg4 {Heaper | NULL} arg5 {Heaper} arg6 {Heaper | NULL} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchHeaper: myType2.
	arg3 _ pm fetchHeaper: myType3.
	arg4 _ pm fetchHeaper: myType4.
	arg5 _ pm fetchNonNullHeaper: myType5.
	arg6 _ pm fetchHeaper: myType6.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3 with: arg4 with: arg5 with: arg6)]! !

!HHNNNHNHandler methodsFor: 'creation'!

create: fn {HHNNNHNFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category} with: type5 {Category} with: type6 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.
	myType4 _ type4.
	myType5 _ type5.
	myType6 _ type6.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HHNNNHNHandler class
	instanceVariableNames: ''!

(HHNNNHNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HHNNNHNHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HHNNNHNFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category} with: type5 {Category} with: type6 {Category}
	^self create: fn with: type1 with: type2 with: type3 with: type4 with: type5 with: type6! !

!HHNNNHNHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HNHandler
	instanceVariableNames: '
		myFn {HNFn var}
		myType1 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HNHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper | NULL} |
	arg1 _ pm fetchHeaper: myType1.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1)]! !

!HNHandler methodsFor: 'creation'!

create: fn {HNFn var} with: type1 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HNHandler class
	instanceVariableNames: ''!

(HNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HNHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HNFn var} with: type1 {Category}
	^self create: fn with: type1! !

!HNHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HNNHandler
	instanceVariableNames: '
		myFn {HNNFn var}
		myType1 {Category}
		myType2 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HNNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HNNHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper | NULL} arg2 {Heaper | NULL} |
	arg1 _ pm fetchHeaper: myType1.
	arg2 _ pm fetchHeaper: myType2.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2)]! !

!HNNHandler methodsFor: 'creation'!

create: fn {HNNFn var} with: type1 {Category} with: type2 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HNNHandler class
	instanceVariableNames: ''!

(HNNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HNNHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HNNFn var} with: type1 {Category} with: type2 {Category}
	^self create: fn with: type1 with: type2! !

!HNNHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HNNNHandler
	instanceVariableNames: '
		myFn {HNNNFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HNNNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HNNNHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper | NULL} arg2 {Heaper | NULL} arg3 {Heaper | NULL} |
	arg1 _ pm fetchHeaper: myType1.
	arg2 _ pm fetchHeaper: myType2.
	arg3 _ pm fetchHeaper: myType3.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3)]! !

!HNNNHandler methodsFor: 'creation'!

create: fn {HNNNFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HNNNHandler class
	instanceVariableNames: ''!

(HNNNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HNNNHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HNNNFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	^self create: fn with: type1 with: type2 with: type3! !

!HNNNHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #HNNNNHandler
	instanceVariableNames: '
		myFn {HNNNNFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}
		myType4 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(HNNNNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HNNNNHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper | NULL} arg2 {Heaper | NULL} arg3 {Heaper | NULL} arg4 {Heaper | NULL} |
	arg1 _ pm fetchHeaper: myType1.
	arg2 _ pm fetchHeaper: myType2.
	arg3 _ pm fetchHeaper: myType3.
	arg4 _ pm fetchHeaper: myType4.
	pm noErrors ifTrue:
		[pm respondHeaper: (myFn invokeFunction: arg1 with: arg2 with: arg3 with: arg4)]! !

!HNNNNHandler methodsFor: 'creation'!

create: fn {HNNNNFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.
	myType4 _ type4.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

HNNNNHandler class
	instanceVariableNames: ''!

(HNNNNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!HNNNNHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {HNNNNFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category}
	^self create: fn with: type1 with: type2 with: type3 with: type4! !

!HNNNNHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #VHBHandler
	instanceVariableNames: '
		myFn {VHBFn var}
		myType1 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(VHBHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHBHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {BooleanVar} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchBooleanVar.
	pm noErrors ifTrue:
		[(myFn invokeFunction: arg1 with: arg2).
		pm respondVoid]! !

!VHBHandler methodsFor: 'creation'!

create: fn {VHBFn var} with: type1 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VHBHandler class
	instanceVariableNames: ''!

(VHBHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHBHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {VHBFn var} with: type1 {Category}
	^self create: fn with: type1! !

!VHBHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #VHHandler
	instanceVariableNames: '
		myFn {VHFn var}
		myType1 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(VHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	pm noErrors ifTrue:
		[(myFn invokeFunction: arg1).
		pm respondVoid]! !

!VHHandler methodsFor: 'creation'!

create: fn {VHFn var} with: type1 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VHHandler class
	instanceVariableNames: ''!

(VHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {VHFn var} with: type1 {Category}
	^self create: fn with: type1! !

!VHHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #VHHHandler
	instanceVariableNames: '
		myFn {VHHFn var}
		myType1 {Category}
		myType2 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(VHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	pm noErrors ifTrue:
		[(myFn invokeFunction: arg1 with: arg2).
		pm respondVoid]! !

!VHHHandler methodsFor: 'creation'!

create: fn {VHHFn var} with: type1 {Category} with: type2 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VHHHandler class
	instanceVariableNames: ''!

(VHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {VHHFn var} with: type1 {Category} with: type2 {Category}
	^self create: fn with: type1 with: type2! !

!VHHHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #VHHHHandler
	instanceVariableNames: '
		myFn {VHHHFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(VHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHHHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} arg3 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	arg3 _ pm fetchNonNullHeaper: myType3.
	pm noErrors ifTrue:
		[(myFn invokeFunction: arg1 with: arg2 with: arg3).
		pm respondVoid]! !

!VHHHHandler methodsFor: 'creation'!

create: fn {VHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VHHHHandler class
	instanceVariableNames: ''!

(VHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHHHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {VHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	^self create: fn with: type1 with: type2 with: type3! !

!VHHHHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #VHHHHHandler
	instanceVariableNames: '
		myFn {VHHHHFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}
		myType4 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(VHHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHHHHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} arg3 {Heaper} arg4 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	arg3 _ pm fetchNonNullHeaper: myType3.
	arg4 _ pm fetchNonNullHeaper: myType4.
	pm noErrors ifTrue:
		[(myFn invokeFunction: arg1 with: arg2 with: arg3 with: arg4).
		pm respondVoid]! !

!VHHHHHandler methodsFor: 'creation'!

create: fn {VHHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.
	myType4 _ type4.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VHHHHHandler class
	instanceVariableNames: ''!

(VHHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHHHHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {VHHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category}
	^self create: fn with: type1 with: type2 with: type3 with: type4! !

!VHHHHHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #VHHHHHHandler
	instanceVariableNames: '
		myFn {VHHHHHFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}
		myType4 {Category}
		myType5 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(VHHHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHHHHHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} arg3 {Heaper} arg4 {Heaper} arg5 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	arg3 _ pm fetchNonNullHeaper: myType3.
	arg4 _ pm fetchNonNullHeaper: myType4.
	arg5 _ pm fetchNonNullHeaper: myType5.
	pm noErrors ifTrue:
		[(myFn invokeFunction: arg1 with: arg2 with: arg3 with: arg4 with: arg5).
		pm respondVoid]! !

!VHHHHHHandler methodsFor: 'creation'!

create: fn {VHHHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category} with: type5 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.
	myType4 _ type4.
	myType5 _ type5.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VHHHHHHandler class
	instanceVariableNames: ''!

(VHHHHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHHHHHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {VHHHHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category} with: type5 {Category}
	^self create: fn with: type1 with: type2 with: type3 with: type4 with: type5! !

!VHHHHHHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #VHHNHandler
	instanceVariableNames: '
		myFn {VHHNFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(VHHNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHHNHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper} arg3 {Heaper | NULL} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchNonNullHeaper: myType2.
	arg3 _ pm fetchHeaper: myType3.
	pm noErrors ifTrue:
		[(myFn invokeFunction: arg1 with: arg2 with: arg3).
		pm respondVoid]! !

!VHHNHandler methodsFor: 'creation'!

create: fn {VHHNFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VHHNHandler class
	instanceVariableNames: ''!

(VHHNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHHNHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {VHHNFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	^self create: fn with: type1 with: type2 with: type3! !

!VHHNHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #VHNHandler
	instanceVariableNames: '
		myFn {VHNFn var}
		myType1 {Category}
		myType2 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(VHNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHNHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper | NULL} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchHeaper: myType2.
	pm noErrors ifTrue:
		[(myFn invokeFunction: arg1 with: arg2).
		pm respondVoid]! !

!VHNHandler methodsFor: 'creation'!

create: fn {VHNFn var} with: type1 {Category} with: type2 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VHNHandler class
	instanceVariableNames: ''!

(VHNHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHNHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {VHNFn var} with: type1 {Category} with: type2 {Category}
	^self create: fn with: type1 with: type2! !

!VHNHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #VHNHHandler
	instanceVariableNames: '
		myFn {VHNHFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(VHNHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHNHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper | NULL} arg3 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchHeaper: myType2.
	arg3 _ pm fetchNonNullHeaper: myType3.
	pm noErrors ifTrue:
		[(myFn invokeFunction: arg1 with: arg2 with: arg3).
		pm respondVoid]! !

!VHNHHandler methodsFor: 'creation'!

create: fn {VHNHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VHNHHandler class
	instanceVariableNames: ''!

(VHNHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHNHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {VHNHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category}
	^self create: fn with: type1 with: type2 with: type3! !

!VHNHHandler class methodsFor: 'generated:'!

isGenerated ^true! !RequestHandler subclass: #VHNHHHandler
	instanceVariableNames: '
		myFn {VHNHHFn var}
		myType1 {Category}
		myType2 {Category}
		myType3 {Category}
		myType4 {Category}'
	classVariableNames: ''
	poolDictionaries: ''
	category: 'Xanadu-proman'!

(VHNHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHNHHHandler methodsFor: 'request handling'!

{void} handleRequest: pm {PromiseManager}
	
	| arg1 {Heaper} arg2 {Heaper | NULL} arg3 {Heaper} arg4 {Heaper} |
	arg1 _ pm fetchNonNullHeaper: myType1.
	arg2 _ pm fetchHeaper: myType2.
	arg3 _ pm fetchNonNullHeaper: myType3.
	arg4 _ pm fetchNonNullHeaper: myType4.
	pm noErrors ifTrue:
		[(myFn invokeFunction: arg1 with: arg2 with: arg3 with: arg4).
		pm respondVoid]! !

!VHNHHHandler methodsFor: 'creation'!

create: fn {VHNHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category}
	super create.
	myFn _ fn.
	myType1 _ type1.
	myType2 _ type2.
	myType3 _ type3.
	myType4 _ type4.! !
"-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- "!

VHNHHHandler class
	instanceVariableNames: ''!

(VHNHHHandler getOrMakeCxxClassDescription)
	attributes: ((Set new) add: #CONCRETE; add: #NOT.A.TYPE; yourself)!

!VHNHHHandler class methodsFor: 'creation'!

{RequestHandler} make: fn {VHNHHFn var} with: type1 {Category} with: type2 {Category} with: type3 {Category} with: type4 {Category}
	^self create: fn with: type1 with: type2 with: type3 with: type4! !

!VHNHHHandler class methodsFor: 'generated:'!

isGenerated ^true! !
(CxxSystemOrganization fileNamed: 'handlrs')
	comment: ''!

(CxxSystemOrganization getOrMakeFileNamed: 'handlrs')
	hxxHeader: 'typedef SPTR(Heaper) (*HHNFn) (APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HHNNFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HHNNHNFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HHNHNFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HHHNFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HHNNNFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HHNNNHNFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef void (*VHHFn) (APTR(Heaper), APTR(Heaper));
typedef void (*VHHHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef void (*VHFn) (APTR(Heaper));
typedef void (*VHNHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef void (*VHNHHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef void (*VHHHHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef void (*VHHHHHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef void (*VHBFn) (APTR(Heaper), BooleanVar);
typedef SPTR(Heaper) (*HNNFn) (APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HNFn) (APTR(Heaper));
typedef SPTR(Heaper) (*HNNNFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HNNNNFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef void (*VHHNFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef void (*VHNFn) (APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HFn) ();
typedef SPTR(Heaper) (*HHFn) (APTR(Heaper));
typedef SPTR(Heaper) (*HHHFn) (APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HHHHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HHNHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HHHHHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HHHHHHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HHNNHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef SPTR(Heaper) (*HHNNNHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper), APTR(Heaper));
typedef BooleanVar (*BHHFn) (APTR(Heaper), APTR(Heaper));
typedef BooleanVar (*BHFn) (APTR(Heaper));
typedef SPTR(Heaper) (*HHBFn) (APTR(Heaper), BooleanVar);
typedef SPTR(Heaper) (*HHHBFn) (APTR(Heaper), APTR(Heaper), BooleanVar);
typedef BooleanVar (*BHHHFn) (APTR(Heaper), APTR(Heaper), APTR(Heaper));
' in: #public!

(CxxSystemOrganization getOrMakeFileNamed: 'handlrs')
	addClass: RequestHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HHHNHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HNHandler
getOrMakeCxxClassDescription in: #public;
	addClass: VHHHHHandler
getOrMakeCxxClassDescription in: #public;
	addClass: VHBHandler
getOrMakeCxxClassDescription in: #public;
	addClass: VHHHHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HHNNHNHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HHHandler
getOrMakeCxxClassDescription in: #public;
	addClass: VHHHandler
getOrMakeCxxClassDescription in: #public;
	addClass: VHHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HNNHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HHHHHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HHNHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HHNNNHNHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HHNNHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HHNHNHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HHHHandler
getOrMakeCxxClassDescription in: #public;
	addClass: VHNHHandler
getOrMakeCxxClassDescription in: #public;
	addClass: BHHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HHNNNHandler
getOrMakeCxxClassDescription in: #public;
	addClass: VHNHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HHHHHHHandler
getOrMakeCxxClassDescription in: #public;
	addClass: VHNHHHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HNNNHandler
getOrMakeCxxClassDescription in: #public;
	addClass: BHHHandler
getOrMakeCxxClassDescription in: #public;
	addClass: VHHHHHHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HHBHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HHNNHHandler
getOrMakeCxxClassDescription in: #public;
	addClass: VHHNHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HHHHHHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HNNNNHandler
getOrMakeCxxClassDescription in: #public;
	addClass: BHHHHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HHNNNHHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HHNHHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HHandler
getOrMakeCxxClassDescription in: #public;
	addClass: HHHBHandler
getOrMakeCxxClassDescription in: #public!

CxxSystemOrganization tree: (CxxSystemOrganization tree addChild:
	((CxxTreeAssociation key: #handlrs value: #file) yourself))!