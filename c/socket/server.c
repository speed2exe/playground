#include <stdio.h>
#include <stdlib.h>

#include <sys/select.h>
#include <sys/types.h>
#include <sys/socket.h>

#include <netinet/in.h>
#include <unistd.h>
#include <pthread.h>

int main() {
	char server_message[256] = "this is resp from the server hahahaha!";
	
	// create server socket
	int server_socket = socket(AF_INET, SOCK_STREAM, 0);

	//define the server address
	struct sockaddr_in server_address;
	server_address.sin_family = AF_INET;
	server_address.sin_port = htons(9002);
	server_address.sin_addr.s_addr = INADDR_ANY;

	// bind the socket to our specified IP and port
	int len = bind(server_socket, (struct sockaddr *) &server_address, sizeof(server_address));
	printf("len is %d", len);

	listen(server_socket, 5);

	//TODO: make this non_blocking
	int client_socket;
	client_socket = accept(server_socket, NULL, NULL);

	send(client_socket, server_message, sizeof(server_message), 0);
	return 0;
}

