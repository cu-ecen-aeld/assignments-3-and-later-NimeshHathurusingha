
CC = gcc
CFLAGS = -Wall -g


CROSS_COMPILE ?=


TARGET = writer
SRCS = write.c
OBJS = $(SRCS:.c=.o)


all: $(TARGET)


$(TARGET): $(OBJS)
	$(CROSS_COMPILE)$(CC) $(OBJS) -o $(TARGET)


%.o: %.c
	$(CROSS_COMPILE)$(CC) $(CFLAGS) -c $< -o $@
	
clean:
	rm -f $(TARGET) $(OBJS)
