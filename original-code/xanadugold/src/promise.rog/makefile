SUFFIXES = .cxx .o .c .s .S .ln .f .F .l .mod \
	   .sym .def .p .r .y .h .sh .exe .out \
	   .dif .ref .ppout .hxx .rc .cps .exp \
	   .err .cex .cer .sxx .inc .nit
.SUFFIXES: $(SUFFIXES)

GENSOURCE = client.prc client.prl clientp.prl
GENERATED = xanadu.cxx xanadu.hxx xanadu.h xanadu.oxx
LIB_O = compat.o opaque.o scalar.o socket.o xanadu.o xanadup.o print.o

# CXX = crutchCC2 -g
# CXX = /net/entropy/files12/eric/src/cfrontwk/gnatCC2 -g
CXX = /net/xanadu/files1/new-lang/CC-2.1 -g

# DEFINES = -DXU_USE_INLINE1 -DXU_USE_INLINE2 -DXU_PRINTON_VERBOSE -DXU_NON_FATAL_KLUDGE
DEFINES = -DXU_PRINTON_VERBOSE

default: test shutdown

.cxx.o: $(HEADERS)
	$(CXX) $(DEFINES) -c -o $@ $<

.exe.out :
	csh -c "./$< socket 'localhost 65214' >& $@ && true"

.out.dif :
	(diff $*.ref $< > $@) || (sleep 1; touch $<; false)
	touch $@

libs: xulib.o

test: test.exe

shutdown: shutdown.exe

depends : $(GENERATED)
	xmakedep -o depends.mk -I. $(DEFINES) -N -W *.cxx
	xmakedep -o - -I. -N -W `ls *.c` >> depends.mk

xulib.o: $(LIB_O)
	ld -r $(LIB_O) -o $@

$(GENERATED): $(GENSOURCE)
	perl client.prl client.prc

test.exe: test.o xulib.o
	$(CXX) -o $@ test.o xulib.o -Bstatic

shutdown.exe: shutdown.o xulib.o
	$(CXX) -o $@ shutdown.o xulib.o

clean:
	rm -f xanadu.* *.o *.exe core *~ '#*#' depends.mk *.exp *.err *.cex *.cer foo.* *.out *.dif
	touch depends.mk

.cxx.exp:
	$(CXX) $(DEFINES) -E -c $< > $@

.exp.err:
	fgrep -v "#" $< > foo.cxx
	$(CXX) -c foo.cxx

.cxx.cex:
	$(CXX) $(DEFINES) -Fc -c $< > $@

.cex.cer:
	fgrep -v "#" $< > foo.c
	#	indent foo.c -bap -bacc -bad -bbb -ce -cli0.5
	c++filt2 < foo.c > foo.demangle
	$(CXX) -c foo.c

include depends.mk
