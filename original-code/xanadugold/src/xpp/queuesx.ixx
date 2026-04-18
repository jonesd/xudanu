#ifndef QUEUESX_IXX
#define QUEUESX_IXX

VERSION_ID(queuesx_ixx,
	   "$Id: queuesx.ixx,v 2.4 1992/08/14 22:10:49 shap Exp $")

inline Queue::Queue () {
  /* This must do nothing or else the allocator will break when its static */
  /* constructors are called.  I expect the nature of the breakage to be */
  /* a one-time memory leak of just under ALLOCSIZE bytes */
  /* This means that all Queue clients must explicitly call init() */
}

inline void Queue::init () {
  nextP = prevP = this;
}

inline BooleanVar Queue::isEmpty () {
  return this->nextP == this;
}

inline BooleanVar Queue::isSane () {
  return this->nextP && this->nextP->prevP == this
    &&   this->prevP && this->prevP->nextP == this;
}

inline void Queue::insert (Queue* item) {
  item->nextP = this;
  item->prevP = this->prevP;
  prevP->nextP = item;
  this->prevP = item;
}

inline void Queue::push (Queue* item) {
  item->prevP = this;
  item->nextP = this->nextP;
  nextP->prevP = item;
  this->nextP = item;
}

inline Queue* Queue::wipe () {
  Queue* item = this->nextP;
  if (item == this) {
    return NULL;
  } else {
    this->nextP = item->nextP;
    nextP->prevP = this;
    return item;
  }
}

inline Queue* Queue::next (Queue* current) {
  Queue* item = current->nextP;
  if (item == this) {
    return NULL;
  } else {
    return item;
  }
}

inline Queue* Queue::getNextP () {
    return nextP;
}

inline void Queue::dechain () {
  Queue* prev = this->prevP;
  prev->nextP = this->nextP;
  nextP->prevP = prev;
}

inline void Queue::replaceWith (Queue* newItem) {
  newItem->nextP = this->nextP;
  newItem->nextP->prevP = newItem;
  newItem->prevP = this->prevP;
  newItem->prevP->nextP = newItem;
  
  this->nextP = this->prevP = this;
}

#endif /* QUEUESX_IXX */
