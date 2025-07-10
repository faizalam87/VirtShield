# ---------- Kernel Module ----------
obj-m := kernel_space.o
KDIR := /lib/modules/$(shell uname -r)/build
PWD  := $(shell pwd)

# ---------- User Space ----------
USER_OBJS := main.o packet_queue.o
USER_TARGET := packet_sniffer
USER_CFLAGS := -Wall -Wextra
USER_LDFLAGS := -lpcap

# ---------- Targets ----------

.PHONY: all user kernel clean

all: user kernel

user: $(USER_OBJS)
	$(CC) $(USER_CFLAGS) -o $(USER_TARGET) $(USER_OBJS) $(USER_LDFLAGS)

kernel:
	$(MAKE) -C $(KDIR) M=$(PWD) modules

clean:
	$(MAKE) -C $(KDIR) M=$(PWD) clean
	$(RM) -f $(USER_OBJS) $(USER_TARGET)
