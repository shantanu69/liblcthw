CFLAGS=-g -O2 -std=c11 -Wall -Wextra -Isrc -rdynamic -DNDEBUG $(OPTFLAGS)
LDLIBS=-lm -ldl -lbsd $(OPTLIBS)
PREFIX?=/usr/local

CC=gcc

SOURCES=$(wildcard src/*/*.c src/*.c)
OBJECTS=$(patsubst %.c,%.o,$(SOURCES))

TEST_SRC=$(wildcard tests/*_test.c)
TESTS=$(patsubst %.c,%,$(TEST_SRC))

PROGRAMS_SRC=$(wildcard bin/*.c)
PROGRAMS=$(patsubst bin/%.c, build/%, $(PROGRAMS_SRC))

NAME=lcthw
TARGET=build/lib$(NAME).a
SO_TARGET=$(patsubst %.a,%.so,$(TARGET))

#The Target Build
all: $(TARGET) $(SO_TARGET) tests $(PROGRAMS)

dev: CFLAGS=-g -Wall -Isrc -Wall -Wextra $(OPTFLAGS)
dev: all

$(TARGET): CFLAGS += -fPIC
$(TARGET): build $(OBJECTS)
	ar rcs $@ $(OBJECTS)
	ranlib $@

$(SO_TARGET): $(TARGET) $(OBJECTS)
	$(CC) -shared -o $@ $(OBJECTS)

$(PROGRAMS): LDLIBS+=$(TARGET)
$(PROGRAMS): CFLAGS+=-D_POSIX_C_SOURCE=200112L -D_BSD_SOURCE
build/%: bin/%.c
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS) $(LDLIBS)

build:
	@mkdir -p build
	@mkdir -p bin
	
#The Unit Tests
.PHONY: tests
tests: LDLIBS := $(TARGET) $(LDLIBS)
tests: $(TESTS)
	sh ./tests/runtests.sh
valgrind:
	VALGRIND="valgrind --log-file=/tmp/valgrind-%p.log" $(MAKE)
	
#The Cleaner
clean:
	rm -rf build $(OBJECTS) $(TESTS) $(PROGRAMS)
	rm -f tests/tests.log
	find . -name "*.gc*" -exec rm {} \;
	rm -rf `find . -name "*.dSYM" -print`
	
#The Install
install: all
	install -d $(DESTDIR)/$(PREFIX)/lib/
	install $(TARGET) $(DESTDIR)/$(PREFIX)/lib/

#The checker
BADFUNCS='[^_.>a-zA-Z0-9](str(n?cpy|n?cat|xfrm|n?dup|str|pbrk|tok|_)|stpn?cpy|a?sn?printf|byte_)'
check:
	@echo Files With potentially dangerous functions.
	@egrep $(BADFUNCS) $(SOURCES) || true


