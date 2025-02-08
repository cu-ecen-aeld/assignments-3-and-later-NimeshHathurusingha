#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>


int main(int argc, char *argv[]){

	openlog("write_program", LOG_PID | LOG_CONS, LOG_USER);

	if(argc != 3){
		printf("Error Argumnet count is %d expected only 2\n", (argc-1));
		syslog(LOG_PERROR, "Error Argumnet count is %d expected only 2\n", (argc-1));
		return 1;
	}
	
	// Get the string and filename from arguments
	char *text_to_write = argv[2];
	char *filename = argv[1];
	
	// Open the file for writing
    	FILE *file = fopen(filename, "w");
	if (file == NULL) {
		syslog(LOG_PERROR, "Error opening file\n");
		return 1;
	}
	
	// Write the string to the file
	fprintf(file, "%s\n", text_to_write);
	syslog(LOG_DEBUG, "Writing \"%s\" to %s", text_to_write, filename);
	syslog(LOG_INFO, "Writing \"%s\" to %s", text_to_write, filename);
	
	//close the file and logs
	fclose(file);
	closelog();
	
	
	return 0;
}
