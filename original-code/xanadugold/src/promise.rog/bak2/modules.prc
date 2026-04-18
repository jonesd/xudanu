module promise {
class Promise
class Value
class IntValue
class FloatValue
class Array
class IntArray
class HumberArray
class FloatArray
class PtrArray
class Stepper
class Void
}
module space {
include promise.hxx
class TableStepper
class CoordinateSpace
class Position
class Region
class Mapping
class OrderSpec
class IntegerSpace
class Integer
class IntegerRegion
class IntegerMapping
class RealSpace
class Real
class RealRegion
class SequenceSpace
class Sequence
enum EdgeTypeEnum
class SequenceRegion
class SequenceMapping
class IDSpace
class ID
class IDRegion
}
module composed {
include promise.hxx
include space.hxx
class CrossSpace
class Tuple
class CrossRegion
class CrossMapping
class CrossOrderSpec
class FilterSpace
class FilterPosition
class Filter
}
module kernel {
include promise.hxx
include space.oxx
include composed.oxx
include trust.oxx
flags TransclusionFlags
class RangeElement
class Work
class Club
class Edition
flags SharingFlags
flags RetrieveFlags
enum CostEnum
class DataHolder
class IDHolder
class Label
class Bundle
class ArrayBundle
class ElementBundle
class PlaceHolderBundle
class Server
class FillDetector
class FillRangeDetector
class RevisionDetector
class StatusDetector
class WaitDetector
}
module trust {
include promise.hxx
include kernel.oxx
include wrapper.hxx
include space.oxx
include composed.oxx
class KeyMaster
class Lock
class BooLock
class WallLock
class ChallengeLock
class MatchLock
class MultiLock
class LockSmith
class BooLockSmith
class WallLockSmith
class ChallengeLockSmith
class MatchLockSmith
class MultiLockSmith
class ClubDescription
}
module wrapper {
include promise.hxx
include kernel.oxx
include space.oxx
include composed.oxx
class WrapperSpec
class Wrapper
class HyperLink
class HyperRef
class SingleRef
class MultiRef
class Path
class Set
class Text
}
module admin {
include promise.hxx
include kernel.oxx
include trust.oxx
include space.oxx
include composed.oxx
class Adminer
class Archiver
class Session
}
module xanadu {
include promise.hxx
include space.hxx
include composed.hxx
include kernel.hxx
include trust.hxx
include wrapper.hxx
include admin.hxx
}
