CC=gcc
SOURCES=glad.c glrt.c
OBJECTS=$(SOURCES:.c=.o)

CFLAGS=-c -std=gnu99 -Wall -Wextra -Og -g -Wpedantic -I. -fstack-protector-all -DSDL_MAIN_HANDLED

LDFLAGS=-Og -g -lSDL2 -ldl

all: $(OBJECTS)
	$(CC) *.o -o glrt $(LDFLAGS)

.c.o:
	$(CC) $(CFLAGS) $< -o $@

clean:
	rm $(OBJECTS)


