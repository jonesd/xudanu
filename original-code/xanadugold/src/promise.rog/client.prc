class 1 Promise Root {
response 0 ack(Special args)
response 1 error(Special args)
response 2 excused(Special args)
response 3 humber(Special args)
response 4 iEEE(Special args)
response 5 humberData(Special args)
response 6 intData(Special args)
response 7 iEEEData(Special args)
response 8 ptrData(Special args)
response 15 terminated()
function 253 NOACK waiveMany(Special args) login
message 1 Promise cast(Special args) login
message 2 BooleanValue equals(Promise other) login
message 3 IntValue hash() login
message 4 BooleanValue isKindOf(Special args) login
message 5 NOACK waive() login
}
class 2 Adminer Promise {
function 408 Adminer make()
message 409 Void acceptConnections(BooleanValue open)
message 410 Stepper activeSessions()
message 411 Void execute(IntArray filename)
message 412 LockSmith gateLockSmith()
message 413 Void grant(ID clubID, IDRegion globalIDs)
message 414 TableStepper grants()
message 415 TableStepper grants(IDRegion clubIDs)
message 416 TableStepper grants(IDRegion clubIDs, IDRegion globalIDs)
message 417 BooleanValue isAcceptingConnections()
message 418 Void setGateLockSmith(LockSmith lockSmith)
message 419 Special shutdown()
}
class 3 Archiver Promise {
function 420 Archiver make()
message 421 Edition archive(Edition works, Edition medium)
message 422 Void markArchived(Edition edition)
message 423 Edition restore(Edition works, Edition medium)
}
class 4 Array Promise {
message 468 Array copy() login
message 469 Array copy(IntValue count) login
message 255 Array copy(IntValue count, IntValue start) login
message 424 Array copy(IntValue count, IntValue start, IntValue before) login
message 425 Array copy(IntValue count, IntValue start, IntValue before, IntValue after) login
message 6 IntValue count() login
message 7 Special export() login
message 256 Special export(IntValue count) login
message 257 Special export(IntValue count, IntValue start) login
message 8 Promise get(IntValue index) login
message 9 Void store(IntValue index, Promise value) login
message 258 Void storeAll() login
message 259 Void storeAll(Promise value) login
message 260 Void storeAll(Promise value, IntValue count) login
message 261 Void storeAll(Promise value, IntValue count, IntValue start) login
message 262 Void storeMany(IntValue to, Array other) login
message 263 Void storeMany(IntValue to, Array other, IntValue count) login
message 264 Void storeMany(IntValue to, Array source, IntValue count, IntValue from) login
}
class 5 FloatArray Array {
function 265 FloatArray import(Special args)
function 266 FloatArray zeros(IntValue bitCount, IntValue count)
message 267 IntValue bitCount()
}
class 6 HumberArray Array {
function 268 HumberArray import(Special args) login
function 269 HumberArray zeros(IntValue count) login
}
class 7 IntArray Array {
function 10 IntArray import(Special args) login
function 11 IntArray zeros(IntValue bitCount, IntValue count) login
message 12 IntValue bitCount()
}
class 8 PtrArray Array {
function 270 PtrArray import(Special args)
function 271 PtrArray nulls(IntValue count)
}
class 9 Bundle Promise {
message 13 Region region()
}
class 10 ArrayBundle Bundle {
message 14 Array array()
message 15 OrderSpec ordering()
}
class 11 ElementBundle Bundle {
message 16 RangeElement element()
}
class 12 PlaceHolderBundle Bundle {
}
class 13 CoordinateSpace Promise {
message 272 OrderSpec ascending()
message 273 Mapping completeMapping(Region range)
message 274 OrderSpec descending()
message 17 Region emptyRegion()
message 18 Region fullRegion()
message 19 Mapping identityMapping()
}
class 14 CrossSpace CoordinateSpace {
function 20 CrossSpace make(PtrArray subSpaces)
message 275 PtrArray axes()
message 276 CoordinateSpace axis(IntValue dimension)
message 277 IntValue axisCount()
message 278 Mapping crossOfMappings()
message 279 Mapping crossOfMappings(PtrArray subMappings)
message 426 CrossOrderSpec crossOfOrderSpecs()
message 427 CrossOrderSpec crossOfOrderSpecs(PtrArray subOrderings)
message 428 CrossOrderSpec crossOfOrderSpecs(PtrArray subOrderings, IntArray subSpaceOrdering)
message 21 Tuple crossOfPositions(PtrArray coordinates)
message 22 CrossRegion crossOfRegions(PtrArray subRegions)
message 23 CrossRegion extrusion(IntValue dimension, Region subRegion)
}
class 15 FilterSpace CoordinateSpace {
function 280 FilterSpace make(CoordinateSpace base)
message 24 Filter allFilter(Region region)
message 25 Filter anyFilter(Region region)
message 281 CoordinateSpace baseSpace()
message 429 FilterPosition position(Region region)
}
class 16 IDSpace CoordinateSpace {
function 26 IDSpace global()
function 282 IDSpace import(IntArray data)
function 27 IDSpace unique()
message 283 IntArray export()
message 430 IDRegion iDsFromServer(Sequence identifier)
message 28 ID newID()
message 29 IDRegion newIDs(IntValue count)
}
class 17 IntegerSpace CoordinateSpace implicit {
function 30 IntegerSpace make()
message 31 IntegerRegion above(Integer start, BooleanValue inclusive)
message 32 IntegerRegion below(Integer stop, BooleanValue inclusive)
message 33 IntegerRegion interval(Integer start, Integer stop)
message 34 Integer position(IntValue value)
message 35 IntegerMapping translation(IntValue value)
}
class 18 RealSpace CoordinateSpace {
function 284 RealSpace make()
message 36 RealRegion above(Real val, BooleanValue inclusive)
message 37 RealRegion below(Real val, BooleanValue inclusive)
message 38 RealRegion interval(Real start, Real stop)
message 39 Real position(FloatValue val)
}
class 19 SequenceSpace CoordinateSpace implicit {
function 40 SequenceSpace make() login
message 41 SequenceRegion above(Sequence sequence, BooleanValue inclusive)
message 42 SequenceRegion below(Sequence sequence, BooleanValue inclusive)
message 43 SequenceRegion interval(Sequence start, Sequence stop)
message 285 SequenceMapping mapping(IntValue shift)
message 286 SequenceMapping mapping(IntValue shift, Sequence translation)
message 44 Sequence position(Array numbers) login
message 45 Sequence position(Array numbers, IntValue shift) login
message 287 SequenceRegion prefixedBy(Sequence sequence, IntValue limit)
}
class 20 FillRangeDetector Promise {
event 9 rangeFilled(Edition newIdentities)
}
class 21 FillDetector Promise {
event 10 filled(RangeElement newIdentity)
}
class 22 KeyMaster Promise {
message 288 IDRegion actualAuthority()
message 289 KeyMaster copy()
message 290 BooleanValue hasAuthority(ID clubID)
message 291 Void incorporate(KeyMaster other)
message 292 IDRegion loginAuthority()
message 293 Void removeLogins(IDRegion oldLogins)
}
class 23 Lock Promise {
}
class 24 BooLock Lock {
message 431 KeyMaster boo() login
}
class 25 ChallengeLock Lock {
message 432 IntArray challenge() login
message 433 KeyMaster response(IntArray signedChallenge) login
}
class 26 MatchLock Lock {
message 434 KeyMaster encryptedPassword(IntArray encrypted) login
}
class 27 MultiLock Lock {
message 435 Lock lock(Sequence name) login
message 436 SequenceRegion lockNames() login
}
class 28 WallLock Lock {
}
class 29 Mapping Promise {
message 46 Mapping combine(Mapping other)
message 47 Region domain()
message 294 CoordinateSpace domainSpace()
message 48 Mapping inverse()
message 49 BooleanValue isComplete()
message 50 BooleanValue isIdentity()
message 51 Position of(Position before)
message 52 Region ofAll(Region before)
message 295 Region range()
message 296 CoordinateSpace rangeSpace()
message 53 Mapping restrict(Region region)
message 54 Stepper simplerMappings()
message 55 Mapping unrestricted()
}
class 30 CrossMapping Mapping {
message 297 Mapping subMapping(IntValue index)
message 298 PtrArray subMappings()
}
class 31 IntegerMapping Mapping {
message 56 IntValue translation()
}
class 32 SequenceMapping Mapping {
message 57 IntValue shift()
message 58 Sequence translation()
}
class 33 OrderSpec Promise {
message 299 CoordinateSpace coordinateSpace()
message 59 BooleanValue follows(Position x, Position y)
message 300 OrderSpec reversed()
}
class 34 CrossOrderSpec OrderSpec {
message 301 IntArray lexOrder()
message 302 OrderSpec subOrder(IntValue i)
message 303 PtrArray subOrders()
}
class 35 Position Promise {
message 60 Region asRegion()
message 304 CoordinateSpace coordinateSpace()
}
class 36 FilterPosition Position {
message 437 Region baseRegion()
}
class 37 ID Position {
function 305 ID import(IntArray data) login
message 306 IntArray export()
}
class 38 Sequence Position {
message 61 IntValue firstIndex()
message 307 IntValue integerAt(IntValue index)
message 62 Array integers()
message 63 BooleanValue isZero()
message 308 IntValue lastIndex()
message 309 Sequence with(IntValue index, IntValue number)
}
class 39 Tuple Position {
message 64 Position coordinate(IntValue index)
message 65 PtrArray coordinates()
}
class 40 Integer Position {
message 66 IntValue value()
}
class 41 Real Position {
message 67 FloatValue value()
}
flags TransclusionFlags {
constant 1 LOCAL_PRESENT_ONLY
constant 2 DIRECT_CONTAINERS_ONLY
constant 4 FROM_TRANSITIVE_CONTENTS
}
class 42 RangeElement Promise {
function 68 RangeElement placeHolder()
message 310 RangeElement again()
message 311 BooleanValue canMakeIdentical(RangeElement newIdentity)
message 312 FillDetector fillDetector()
message 69 BooleanValue isIdentical(RangeElement other)
message 70 Label label()
message 313 Void makeIdentical(RangeElement newIdentity)
message 314 ID owner()
message 71 RangeElement relabelled(Label label)
message 315 Void setOwner(ID clubID)
message 72 Edition transcluders()
message 73 Edition transcluders(Filter directFilter)
message 74 Edition transcluders(Filter directFilter, Filter indirectFilter)
message 75 Edition transcluders(Filter directFilter, Filter indirectFilter, IntValue transclusionFlags)
message 316 Edition transcluders(Filter directFilter, Filter indirectFilter, IntValue transclusionFlags, Edition otherTranscluders)
message 76 Edition works()
message 77 Edition works(Filter filter)
message 78 Edition works(Filter filter, IntValue transclusionFlags)
message 317 Edition works(Filter filter, IntValue transclusionFlags, Edition otherTranscluders)
}
class 43 DataHolder RangeElement {
function 79 DataHolder make(Value value)
message 80 Value value()
}
flags SharingFlags {
constant 1 THIS_TRANSITIVE_CONTENTS
constant 2 OTHER_TRANSITIVE_CONTENTS
}
flags RetrieveFlags {
constant 1 IGNORE_TOTAL_ORDERING
constant 2 IGNORE_ARRAY_ORDERING
constant 4 SEPARATE_OWNERS
}
enum CostEnum {
constant 1 OMIT_SHARED
constant 2 PRORATE_SHARED
constant 3 TOTAL_SHARED
}
class 44 Edition RangeElement {
function 81 Edition empty(CoordinateSpace keySpace)
function 82 Edition fromAll(Region keys, RangeElement value)
function 83 Edition fromArray(Array values)
function 84 Edition fromArray(Array values, Region keys)
function 318 Edition fromArray(Array values, Region keys, OrderSpec ordering)
function 85 Edition fromOne(Position key, RangeElement value)
function 86 Edition placeHolders(Region keys)
message 319 Region canMakeRangeIdentical(Edition newIdentities)
message 320 Region canMakeRangeIdentical(Edition newIdentities, Region positions)
message 87 Edition combine(Edition other)
message 88 CoordinateSpace coordinateSpace()
message 89 Edition copy(Region positions)
message 321 IntValue cost(IntValue costEnum)
message 90 IntValue count()
message 91 Region domain()
message 92 Void endorse(CrossRegion additionalEndorsements)
message 93 CrossRegion endorsements()
message 322 FillRangeDetector fillRangeDetector()
message 94 RangeElement get(Position position)
message 95 BooleanValue hasPosition(Position position)
message 96 BooleanValue isEmpty()
message 97 BooleanValue isFinite()
message 323 BooleanValue isRangeIdentical(Edition other)
message 324 Edition makeRangeIdentical(Edition newIdentities)
message 325 Edition makeRangeIdentical(Edition newIdentities, Region positions)
message 98 Mapping mapSharedOnto(Edition other)
message 326 Mapping mapSharedTo(Edition other)
message 99 Edition notSharedWith(Edition other)
message 100 Edition notSharedWith(Edition other, IntValue sharingFlags)
message 101 Region positionsLabelled(Label label)
message 102 Region positionsOf(RangeElement value)
message 327 IDRegion rangeOwners(Region positions)
message 103 Edition rangeTranscluders()
message 104 Edition rangeTranscluders(Region positions)
message 105 Edition rangeTranscluders(Region positions, Filter directFilter)
message 106 Edition rangeTranscluders(Region positions, Filter directFilter, Filter indirectFilter)
message 107 Edition rangeTranscluders(Region positions, Filter directFilter, Filter indirectFilter, IntValue transclusionFlags)
message 328 Edition rangeTranscluders(Region positions, Filter directFilter, Filter indirectFilter, IntValue transclusionFlags, Edition otherTranscluders)
message 329 Edition rangeWorks()
message 330 Edition rangeWorks(Region positions)
message 331 Edition rangeWorks(Region positions, Filter filter)
message 332 Edition rangeWorks(Region positions, Filter filter, IntValue transclusionFlags)
message 333 Edition rangeWorks(Region positions, Filter filter, IntValue transclusionFlags, Edition otherTrail)
message 108 Edition rebind(Position position, Edition edition)
message 109 Edition replace(Edition other)
message 334 Void retract(CrossRegion endorsements)
message 110 Stepper retrieve()
message 111 Stepper retrieve(Region positions)
message 112 Stepper retrieve(Region positions, OrderSpec order)
message 113 Stepper retrieve(Region positions, OrderSpec order, IntValue retrieveFlags)
message 335 Edition setRangeOwners(ID newOwner)
message 336 Edition setRangeOwners(ID newOwner, Region region)
message 114 Region sharedRegion(Edition other)
message 115 Region sharedRegion(Edition other, IntValue sharingFlags)
message 116 Edition sharedWith(Edition other)
message 117 Edition sharedWith(Edition other, IntValue sharingFlags)
message 118 TableStepper stepper()
message 119 TableStepper stepper(Region region)
message 337 TableStepper stepper(Region region, OrderSpec ordering)
message 120 RangeElement theOne()
message 121 Edition transformedBy(Mapping mapping)
message 122 CrossRegion visibleEndorsements()
message 123 Edition with(Position position, RangeElement value)
message 124 Edition withAll(Region positions, RangeElement value)
message 125 Edition without(Position position)
message 126 Edition withoutAll(Region positions)
}
class 45 IDHolder RangeElement {
function 338 IDHolder make(ID iD)
message 339 ID iD()
}
class 46 Label RangeElement {
function 340 Label make()
}
class 47 Work RangeElement {
function 127 Work make(Edition contents)
message 128 BooleanValue canRead()
message 129 BooleanValue canRevise()
message 130 ID editClub()
message 131 Edition edition()
message 341 Void endorse(CrossRegion additionalEndorsements)
message 132 CrossRegion endorsements()
message 133 Void grab()
message 342 ID grabber()
message 343 ID historyClub()
message 134 ID lastRevisionAuthor()
message 344 IntValue lastRevisionNumber()
message 135 IntValue lastRevisionTime()
message 136 ID readClub()
message 137 Void release()
message 345 Void removeEditClub()
message 346 Void removeReadClub()
message 138 Void requestGrab()
message 347 Void retract(CrossRegion removedEndorsements)
message 139 Void revise(Edition newEdition)
message 348 RevisionDetector revisionDetector()
message 349 Edition revisions()
message 350 Void setEditClub(ID club)
message 351 Void setHistoryClub(ID club)
message 352 Void setReadClub(ID club)
message 353 Void sponsor(IDRegion clubs)
message 354 IDRegion sponsors()
message 355 StatusDetector statusDetector()
message 356 Void unsponsor(IDRegion clubs)
}
class 48 Club Work {
function 357 Club make(Edition status)
message 358 Void removeSignatureClub()
message 359 Void setSignatureClub(ID club)
message 360 ID signatureClub()
message 361 Edition sponsoredWorks()
message 362 Edition sponsoredWorks(Filter filter)
}
class 49 RevisionDetector Promise {
event 11 revised(Work work, Edition contents, ID author, IntValue time, IntValue sequence)
}
class 50 Server Promise implicit {
function 438 ID accessClubID()
function 439 ID adminClubID()
function 440 ID archiveClubID()
function 363 ID assignID(RangeElement range)
function 364 ID assignID(RangeElement range, ID iD)
function 441 ID clubDirectoryID()
function 365 IntValue currentTime()
function 442 Sequence encrypterName() login
function 140 NOACK force() login
function 141 RangeElement get(ID iD)
function 443 Sequence identifier()
function 142 ID iDOf(RangeElement value)
function 143 IDRegion iDsOf(RangeElement value)
function 144 IDRegion iDsOfRange(Edition edition)
function 444 Lock login(ID clubID) login
function 445 Lock loginByName(Sequence clubName) login
function 446 ID emptyClubID()
function 447 ID publicClubID()
function 448 IntArray publicKey() login
function 145 NOACK setCurrentAuthor(ID iD)
function 146 NOACK setCurrentKeyMaster(KeyMaster km)
function 147 NOACK setInitialEditClub(ID iD)
function 148 NOACK setInitialOwner(ID iD)
function 149 NOACK setInitialReadClub(ID iD)
function 150 NOACK setInitialSponsor(ID iD)
function 366 WaitDetector waitForConsequences()
function 367 WaitDetector waitForWrite()
}
class 51 Session Promise {
function 449 Session current()
message 450 IntValue connectTime()
message 451 Void endSession()
message 452 Void endSession(BooleanValue withPrejudice)
message 453 ID initialLogin()
message 454 IntArray port()
message 470 BooleanValue isConnected()
}
class 52 StatusDetector Promise {
event 12 grabbed(Work work, ID author, IntValue reason)
event 13 released(Work work, IntValue reason)
}
class 53 Stepper Promise {
message 151 BooleanValue atEnd()
message 254 Stepper copy()
message 152 Promise get()
message 153 Void step()
message 154 Array stepMany()
message 155 Array stepMany(IntValue count)
message 156 Promise theOne()
}
class 54 TableStepper Stepper {
message 157 Position position()
message 158 Array stepManyPairs()
message 159 Array stepManyPairs(IntValue count)
}
class 82 Void Promise {
}
class 55 WaitDetector Promise {
event 14 done()
}
class 56 Wrapper Promise {
message 160 Edition edition()
message 368 Wrapper inner()
}
class 57 ClubDescription Wrapper {
function 369 ClubDescription make(Set members, LockSmith lockSmith)
message 370 LockSmith lockSmith()
message 371 Set membership()
message 372 ClubDescription withLockSmith(LockSmith lockSmith)
message 373 ClubDescription withMembership(Set members)
}
class 58 HyperLink Wrapper {
function 161 HyperLink make(Set types, HyperRef leftEnd, HyperRef rightEnd)
message 162 HyperRef endAt(Sequence key)
message 163 SequenceRegion endNames()
message 164 Set linkTypes()
message 165 HyperLink withEnd(Sequence key, HyperRef linkEnd)
message 374 HyperLink withLinkTypes(Set types)
message 375 HyperLink withoutEnd(Sequence key)
}
class 59 HyperRef Wrapper {
message 166 Work originalContext()
message 167 Path pathContext()
message 376 HyperRef withOriginalContext(Work work)
message 377 HyperRef withPathContext(Path path)
message 378 HyperRef withWorkContext(Work work)
message 168 Work workContext()
}
class 60 MultiRef HyperRef {
function 169 MultiRef make(PtrArray refs)
function 170 MultiRef make(PtrArray refs, Work workContext)
function 171 MultiRef make(PtrArray refs, Work workContext, Work originalContext)
function 172 MultiRef make(PtrArray refs, Work workContext, Work originalContext, Path pathContext)
message 379 MultiRef intersect(MultiRef other)
message 380 MultiRef minus(MultiRef other)
message 173 Stepper refs()
message 381 MultiRef unionWith(MultiRef other)
message 382 MultiRef with(HyperRef ref)
message 383 MultiRef without(HyperRef ref)
}
class 61 SingleRef HyperRef {
function 174 SingleRef make(Edition material)
function 175 SingleRef make(Edition material, Work workContext)
function 176 SingleRef make(Edition material, Work workContext, Work originalContext)
function 177 SingleRef make(Edition material, Work workContext, Work originalContext, Path pathContext)
message 178 Edition excerpt()
message 384 SingleRef withExcerpt(Edition excerpt)
}
class 62 LockSmith Wrapper {
}
class 63 BooLockSmith LockSmith {
function 455 BooLockSmith make()
}
class 64 ChallengeLockSmith LockSmith {
function 456 ChallengeLockSmith make(IntArray publicKey, Sequence encrypterName)
message 457 IntArray encrypterName()
message 458 IntArray publicKey()
}
class 65 MatchLockSmith LockSmith {
function 459 MatchLockSmith make(IntArray scrambledPassword, Sequence scramblerName)
message 460 IntArray scrambledPassword()
message 461 IntArray scramblerName()
}
class 66 MultiLockSmith LockSmith {
function 462 MultiLockSmith make()
message 463 LockSmith lockSmith(Sequence name)
message 464 SequenceRegion lockSmithNames()
message 465 MultiLockSmith with(Sequence name, LockSmith smith)
message 466 MultiLockSmith without(Sequence name)
}
class 67 WallLockSmith LockSmith {
function 467 WallLockSmith make()
}
class 68 Path Wrapper {
function 179 Path make(PtrArray labels)
message 180 RangeElement follow(Edition edition)
}
class 69 Set Wrapper {
function 181 Set make()
function 182 Set make(PtrArray works)
message 183 IntValue count()
message 184 BooleanValue includes(RangeElement value)
message 385 Set intersect(Set other)
message 386 Set minus(Set other)
message 185 RangeElement theOne()
message 387 Set unionWith(Set other)
message 388 Set with(RangeElement value)
message 389 Set without(RangeElement value)
}
class 70 Text Wrapper {
function 186 Text make(Array data)
message 187 Edition contents()
message 188 IntValue count()
message 189 Text extract(IntegerRegion region)
message 190 Text insert(IntValue position, Text text)
message 191 Text move(IntValue pos, IntegerRegion region)
message 192 Text replace(IntegerRegion dest, Text other)
}
class 71 WrapperSpec Promise {
function 193 WrapperSpec get(Sequence identifier)
message 194 Filter filter()
message 390 Sequence name()
message 195 Wrapper wrap(Edition edition)
}
class 72 Region Promise {
message 196 Region chooseMany(IntValue n)
message 197 Region chooseMany(IntValue n, OrderSpec order)
message 198 Position chooseOne()
message 199 Position chooseOne(OrderSpec order)
message 200 Region complement()
message 201 CoordinateSpace coordinateSpace()
message 202 IntValue count()
message 203 BooleanValue hasMember(Position atPos)
message 204 Region intersect(Region other)
message 205 BooleanValue intersects(Region other)
message 206 BooleanValue isEmpty()
message 207 BooleanValue isFinite()
message 208 BooleanValue isFull()
message 209 BooleanValue isSubsetOf(Region other)
message 210 Region minus(Region other)
message 211 Stepper stepper()
message 212 Stepper stepper(OrderSpec order)
message 213 Position theOne()
message 214 Region unionWith(Region other)
message 215 Region with(Position pos)
message 216 Region without(Position pos)
}
class 73 CrossRegion Region {
message 217 Stepper boxes()
message 218 BooleanValue isBox()
message 219 Region projection(IntValue index)
message 220 PtrArray projections()
}
class 74 Filter Region {
message 391 Region baseRegion()
message 392 Stepper intersectedFilters()
message 393 BooleanValue isAllFilter()
message 394 BooleanValue isAnyFilter()
message 221 BooleanValue match(Region region)
message 395 Stepper unionedFilters()
}
class 75 IDRegion Region {
function 396 IDRegion import(IntArray data)
message 397 IntArray export()
}
class 76 IntegerRegion Region {
message 222 Stepper intervals()
message 398 Stepper intervals(OrderSpec order)
message 223 BooleanValue isBoundedAbove()
message 224 BooleanValue isBoundedBelow()
message 225 BooleanValue isInterval()
message 226 IntValue start()
message 227 IntValue stop()
}
class 77 RealRegion Region {
message 228 Stepper intervals()
message 399 Stepper intervals(OrderSpec order)
message 229 BooleanValue isBoundedAbove()
message 230 BooleanValue isBoundedBelow()
message 231 BooleanValue isInterval()
message 232 Real lowerBound()
message 233 Real upperBound()
}
enum EdgeTypeEnum {
constant 1 INCLUSIVE
constant 2 EXCLUSIVE
constant 3 PREFIX
}
class 78 SequenceRegion Region {
message 234 Stepper intervals()
message 400 Stepper intervals(OrderSpec order)
message 235 BooleanValue isBoundedAbove()
message 236 BooleanValue isBoundedBelow()
message 237 BooleanValue isInterval()
message 238 Sequence lowerEdge()
message 239 IntValue lowerEdgePrefixLimit()
message 240 IntValue lowerEdgeType()
message 241 Sequence upperEdge()
message 242 IntValue upperEdgePrefixLimit()
message 243 IntValue upperEdgeType()
}
class 79 Value Promise {
}
class 80 FloatValue Value {
function 244 FloatValue import(Special args)
message 401 IntValue bitCount()
}
class 81 IntValue Value {
function 245 IntValue import(Special args) login
message 402 IntValue bitwiseAnd(IntValue another) login
message 403 IntValue bitwiseOr(IntValue another) login
message 404 IntValue bitwiseXor(IntValue another) login
message 246 IntValue dividedBy(IntValue another) login
message 247 BooleanValue isGE(IntValue another) login
message 405 IntValue leftShift(IntValue another) login
message 248 IntValue maximum(IntValue another) login
message 249 IntValue minimum(IntValue another) login
message 250 IntValue minus(IntValue another) login
message 406 IntValue mod(IntValue another) login
message 251 IntValue plus(IntValue another) login
message 407 IntValue bitCount() login
message 252 IntValue times(IntValue another) login
}
