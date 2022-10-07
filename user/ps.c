#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

// A xv6-riscv syscall can take up to six arguments.
#define max_args 6

enum procstate { UNUSED, USED, SLEEPING, RUNNABLE, RUNNING, ZOMBIE };
// Print a help message.
void print_help(int argc, char **argv) {
	fprintf(2, "%s <options: pid or S/R/X/Z>%s\n",
			argv[0], argc > 7 ? ": too many args" : "");
}

int main(int argc, char **argv) {
	// Print a help message.
	if(argc > 7) { print_help(argc, argv); exit(1); }

	// Argument vector
	int args[max_args];
	memset(args, 0, max_args * sizeof(int));

	/* Assignment 1: Process and System Call
	   Convert char inputs of argv[] into appropriate integers in args[].
	   In this skeleton code, args[] is initialized to zeros,
	   so technically no arguments are passed to the ps() syscall. */
	//  for (int i = 0; i < argc; ++i) {
	//	args[i] = (int)argv[i];
	//  }

	// Call the ps() syscall.
	//  for (int i = 0; i < argc; ++i) {
	//	fprintf(2, "%d\n", atoi(argv[i]));
	//    args[i] = atoi(argv[i]));
	//  }


	for (unsigned int i = 1; i < argc; ++i) {
		int pred = atoi(argv[i]);
		if (pred == 0) {
			//If argv[i] is letters, not numbers, atoi(argv[i]) value is 0.
			//Even if '0' is fetched as argument, minimum value of PID is 1, so '0' is wrong argument and there's no problem.
			if (strlen(argv[i]) > 1) { //exception handling for case such as "RS"
				print_help(argc, argv);
				exit(1);
			}
			switch ((int)(*argv[i]) - '0') {
				case 'R'-'0'://'R'-'0' = 34
					args[i-1] = (-1) * RUNNABLE;
					break;
				case 'S'-'0'://'S'-'0' = 35
					args[i-1] = (-1) * SLEEPING;
					break;
				case 'X'-'0'://'X'-'0' = 40
					args[i-1] = (-1) * RUNNING;
					break;
				case 'Z'-'0'://'Z'-'0' = 42
					args[i-1] = (-1) * ZOMBIE;
					break;
				default:
					print_help(argc, argv);
					exit(1);
					break;
			}
		} else {
			for (unsigned int j = 0; j < strlen(argv[i]); ++j) { //When first character of argument is number
				if (argv[i][j] > '9' || argv[i][j] < '0') {//exception handling for case such as "1+2"
					print_help(argc, argv);
					exit(1);
				}
			}
			args[i-1] = pred;
		}
	}

	int ret = ps(args[0], args[1], args[2], args[3], args[4], args[5]);
	if(ret) { fprintf(2, "ps failed\n"); exit(1); }

	exit(0);
}
