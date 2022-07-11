#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>

#define ADD(a,b) {a + b}

int main() {
	// create a socket
	int network_socket = socket(AF_INET, SOCK_STREAM, 0);

	// specify an address for the socket
	struct sockaddr_in server_address;
	server_address.sin_family = AF_INET;
	server_address.sin_port = htons(9002);
	server_address.sin_addr.s_addr = INADDR_ANY;


	int conn_status = connect(network_socket, (struct sockaddr *) &server_address, sizeof(server_address));
	// check for error with the connection
	if (conn_status == -1) {
		printf("error making connection");
	}

	char server_resp[256];

	int s = recv(network_socket, &server_resp, sizeof(server_resp), MSG_WAITALL);


	// print out data we got back
	printf("The server sent the data:  %s\n", server_resp);
	printf("recv:  %d", s);

	//close the socket
	close(network_socket);

	return 0;
}
