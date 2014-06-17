typedef void (*thread_entry_point)(void);

void bedrock_spawn(thread_entry_point);
__attribute__((noreturn)) void bedrock_exit();
void bedrock_yield();

typedef unsigned fd_t;

fd_t bedrock_listen(unsigned port);
fd_t bedrock_accept(fd_t listener);
void bedrock_close(fd_t);
unsigned bedrock_read(fd_t, const char *buf, unsigned size);
unsigned bedrock_write(fd_t, char *buf, unsigned size);

fd_t bedrock_connect(const char *address, unsigned size);
// We represent a character string with bytes+length, instead of zero termination.
void bedrock_connected(fd_t);
// Blocks waiting for the connection process to finish.

#define BEDROCK_THREAD(name) __attribute__((noreturn)) void name##_handler()
#define BEDROCK_WRAP(name) __attribute__((noreturn)) void name(); asm(#name ":"); asm("movl %ebx, bedrock_heap + (1024 * 1024 + 50 + 1)*4"); asm("movl bedrock_stack_size, %esp"); asm("shll $2, %esp"); asm("addl %ebx, %esp"); asm("addl $bedrock_heap, %esp"); asm("jmp " #name "_handler");