
default: all

include $(MAKELIB)/xu-$(PLATFORM).mk

PARSERTOP=../..
include $(PARSERTOP)/$(PLATFORM)/tools.mk

OBJECTS	= \
	parserx.o \
	segx.o \
	parser.tab.o \
	lex.yy.o \
	declx.o \
	fcallx.o \
	exprx.o \
	syntaxcx.o \
	$(XPP_O_DIR)/tofux.o \
	$(XPP_O_DIR)/hsboxx.o \
	$(XPP_O_DIR)/fhashx.o \
	$(GMON_O_DIR)/gmonx.o \
	$(STRING_O_DIR)/strobjx.o


## Xanadu Makefile targets:

all: parse.o

install: all

toolinstall: all

clean:
	-rm -f $(JUNK) parser.tab.c parser.tab.h

clobber: clean
	-rm -f partest

test:

partest: partest.o parse.o
	$(LINK.cxx) -o $@ partest.o parse.o  $(LDLIBSXX)

## Dependencies:

$(GMON_O_DIR)/gmonx.o :
	cd $(GMON_O_DIR); xumake gmonx.o

$(XPP_O_DIR)/tofux.o :
	cd $(XPP_O_DIR); xumake tofux.o

$(STRING_O_DIR)/strobjx.o :
	cd $(STRING_O_DIR); xumake strobjx.o

parse.o : $(OBJECTS)
	ld -r -o parse.o $(OBJECTS)

parser.tab.o: parser.tab.c

parser.tab.c: ../parser.y
	bison -d ../parser.y
	mv ../parser.tab.[ch] .

#parser.tab.c: parser.y
#	yacc -d parser.y
#	mv y.tab.c parser.tab.c
#	mv y.tab.h parser.tab.h

lex.yy.o: lex.yy.c

lex.yy.c : ../lexer.l
	lex ../lexer.l
