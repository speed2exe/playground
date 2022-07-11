#include <stdint.h>
#include <sys/eventfd.h>
#include <sys/syscall.h>
#include <pthread.h>
#include <unistd.h>

typedef struct {
	int a;
	int b;
} MyStruct;


int main() {
	MyStruct a;

	pthread_t t1, t2;
	sleep(9);
	pthread_barrier_wait

}
