OPENCL_LIB ?= /usr/local/cuda-9.1/lib64
OPENJDK_PATH ?= $(shell readlink -f /usr/bin/javac | sed "s:bin/javac::")
SRC ?= ./src
OUT ?= ./build
DISABLE_GPU ?= 1
DISABLE_JNI ?= 1

CFLAGS = -Os -fPIC -g
LDFLAGS = -lpthread
PYFLAGS = --gpu_enable

# FIXME: avoid hardcoded architecture flags. We might support advanced SIMD
# instructions for Intel and Arm later.
CFLAGS += -msse2

ifneq ("$(DISABLE_GPU)","1")
CFLAGS += \
	-DENABLE_OPENCL \
	-I$(OPENCL_PATH)/include
LDFLAGS += -L$(OPENCL_LIB) -lOpenCL
PYFLAGS += 1
else
PYFLAGS += 0
endif

ifneq ("$(DISABLE_JNI)","1")
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
JAVA_HOME := $(shell /usr/libexec/java_home)
CFLAGS_JNI = \
	-I$(JAVA_HOME)/include \
	-I$(JAVA_HOME)/include/darwin
else
# Default to Linux
CFLAGS_JNI = \
	-I$(OPENJDK_PATH)/include \
	-I$(OPENJDK_PATH)/include/linux
endif
endif

TESTS = \
	mpool \
	trinary \
	curl \
	pow_sse

ifneq ("$(DISABLE_GPU)","1")
TESTS += \
	pow_cl
endif

TESTS := $(addprefix $(OUT)/test_, $(TESTS))

LIBS = libdcurl.so
LIBS := $(addprefix $(OUT)/, $(LIBS))

all: $(TESTS) $(LIBS)

OBJS = \
	mpool.o \
	hash/curl.o \
	constants.o \
	trinary/trinary.o \
	dcurl.o \
	pow_sse.o

ifneq ("$(DISABLE_GPU)","1")
OBJS += \
	pow_cl.o \
	clcontext.o
endif

ifneq ("$(DISABLE_JNI)","1")
OBJS += \
	jni/iri-pearldiver-exlib.o
endif

OBJS := $(addprefix $(OUT)/, $(OBJS))
deps := $(OBJS:%.o=%.o.d)

SUBDIRS = \
	hash \
	trinary \
	jni
SHELL_HACK := $(shell mkdir -p $(OUT))
SHELL_HACK := $(shell mkdir -p $(addprefix $(OUT)/,$(SUBDIRS)))

$(OUT)/test_%.o: test/test_%.c
	$(VECHO) "  CC\t$@\n"
	$(Q)$(CC) -o $@ $(CFLAGS) -c -MMD -MF $@.d $<

$(OUT)/jni/%.o: jni/%.c
	$(VECHO) "  CC\t$@\n"
	$(Q)$(CC) -o $@ $(CFLAGS) $(CFLAGS_JNI) -c -MMD -MF $@.d $<

$(OUT)/trinary/%.o: $(SRC)/trinary/%.c
$(OUT)/hash/%.o: $(SRC)/hash/%.c
$(OUT)/%.o: $(SRC)/%.c
	$(VECHO) "  CC\t$@\n"
	$(Q)$(CC) -o $@ $(CFLAGS) -c -MMD -MF $@.d $<

$(OUT)/test_%: $(OUT)/test_%.o $(OBJS)
	$(VECHO) "  LD\t$@\n"
	$(Q)$(CC) -o $@ $^ $(LDFLAGS)

$(OUT)/libdcurl.so: $(OBJS)
	$(VECHO) "  LD\t$@\n"
	$(Q)$(CC) -shared -o $@ $^ $(LDFLAGS)

test_multi_pow: test/test_multi_pow.py $(OUT)/libdcurl.so
	$(Q)$(PRINTF) "*** Validating $< ***\n"
	$(Q)python3 $< $(PYFLAGS) && $(PRINTF) "\t$(PASS_COLOR)[ Verified ]$(NO_COLOR)\n"

$(OUT)/test_%.done: $(OUT)/test_%
	$(Q)$(PRINTF) "*** Validating $< ***\n"
	$(Q)./$< && $(PRINTF) "\t$(PASS_COLOR)[ Verified ]$(NO_COLOR)\n"
check: $(addsuffix .done, $(TESTS)) test_multi_pow

clean:
	$(RM) -r $(OUT)

include mk/common.mk
-include $(deps)
