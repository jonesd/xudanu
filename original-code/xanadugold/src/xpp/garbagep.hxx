/* $Id: garbagep.hxx,v 2.7 1992/12/19 00:53:12 ravi Exp $ */

#include "tofux.hxx"
#include "thunkx.hxx"
#include "bibopx.hxx"
#include "gchooksx.hxx"

class GCMaxInterval : public Thunk {
    CONCRETE(GCMaxInterval)
    NO_GC(GCMaxInterval)
    COPY(GCMaxInterval,BootCuisine)
    NOT_A_TYPE(GCMaxInternal)
 public:
    void execute ();
 private:
    Int32 interval;
};

class GCMinInterval : public Thunk {
    CONCRETE(GCMinInterval)
    NO_GC(GCMinInterval)
    COPY(GCMinInterval,BootCuisine)
    NOT_A_TYPE(GCMinInternal)
 public:
    void execute ();
 private:
    Int32 interval;
};

class GCOpportunity : public ExhaustionHook {

 public:
    void bibopExhaustionEvent() {
	gcOpportunity (-1);
    }
};

class GCNecessity : public RepairEngineer {
    CONCRETE(GCNecessity)
    NO_GC(GCNecessity)
	NOT_A_TYPE(GCNecessity)
 public:

    void repair ();

    void mustRepair ();

    GCNecessity ();

 private:
    BooleanVar hasToRepair;
};
