#include <sys/socket.h>
#include <netinet/in.h>

extern int my_connect(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
extern int my_bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);

__attribute__((used)) static struct {
    const void *replacement;
    const void *original;
} interposers[] __attribute__((section("__DATA,__interpose"))) = {
    { (const void *)my_connect, (const void *)connect },
    { (const void *)my_bind, (const void *)bind },
};
