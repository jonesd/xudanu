
default: all

include $(MAKELIB)/xu-$(PLATFORM).mk

PARSERTOP=../..
include $(PARSERTOP)/$(PLATFORM)/tools.mk

OBJECTS= \
	tofux.o hsboxx.o fhashx.o


## Xanadu Makefile targets:

all: $(OBJECTS)

install: all

toolinstall: all

clean :
	-rm -f $(JUNK) *.out *.dif

clobber : clean
	-rm -f bombt.exe

test: bomb.dif

## Dependencies:

tofux.o : ../tofux.cxx ../tofux.hxx ../bombx.hxx ../bombx.ixx ../bombc.h ../xcompatx.hxx \
	 ../ccompatc.h
bombx.o : ../bombx.cxx ../bombx.hxx ../bombx.ixx ../bombc.h ../xcompatx.hxx ../ccompatc.h

bomb.exe : bombt.o bombx.o
	$(LINK.cxx) -o $@ bombt.o bombx.o $(LDLIBSXX)
