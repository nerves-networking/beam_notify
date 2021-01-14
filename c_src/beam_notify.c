#include <ctype.h>
#include <err.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <unistd.h>

#include <ei.h>

#define MIN_SEND_SIZE 8192

extern char **environ;

static void encode_string(ei_x_buff *buff, const char *str)
{
    // Encode strings as binaries so that we get Elixir strings
    // NOTE: the strings that we encounter here are expected to be ASCII to
    //       my knowledge
    ei_x_encode_binary(buff, str, strlen(str));
}

static int should_encode(const char *kv)
{
    if (strncmp(kv, "BEAM_NOTIFY=", 12) == 0 ||
        strncmp(kv, "BEAM_NOTIFY_OPTIONS=", 20) == 0)
        return 0;
    else
        return 1;
}

static int count_environ_to_encode()
{
    char **p = environ;
    int n = 0;

    while (*p != NULL) {
        if (should_encode(*p))
            n++;

        p++;
    }

    return n;
}

static void encode_env_kv(ei_x_buff *buff, const char *kv)
{
    char key[32];

    const char *equal = strchr(kv, '=');
    if (equal == NULL)
        return;

    size_t keylen = equal - kv;
    if (keylen >= sizeof(key))
        keylen = sizeof(key) - 1;
    memcpy(key, kv, keylen);
    key[keylen] = '\0';

    const char *value = equal + 1;

    encode_string(buff, key);
    encode_string(buff, value);
}

static void encode_environ(ei_x_buff *buff)
{
    int kv_to_encode = count_environ_to_encode();
    ei_x_encode_map_header(buff, kv_to_encode);

    char **p = environ;
    while (*p != NULL) {
        const char *kv = *p;

        if (should_encode(kv))
            encode_env_kv(buff, kv);

        p++;
    }
}

static void encode_args(ei_x_buff *buff, int argc, char *argv[])
{
    ei_x_encode_list_header(buff, argc - 1);

    if (argc > 1) {
        int i;
        for (i = 1; i < argc; i++)
            encode_string(buff, argv[i]);

        ei_x_encode_empty_list(buff);
    }
}

int main(int argc, char *argv[])
{
    char *options = getenv("BEAM_NOTIFY_OPTIONS");
    if (options == NULL)
        errx(EXIT_FAILURE, "BEAM_NOTIFY_OPTIONS must be set");

    int fd = socket(AF_UNIX, SOCK_DGRAM, 0);
    if (fd < 0)
        err(EXIT_FAILURE, "socket");

    struct sockaddr_un addr;
    memset(&addr, 0, sizeof(addr));
    addr.sun_family = AF_UNIX;
    strncpy(addr.sun_path, options, sizeof(addr.sun_path) - 1);

    if (connect(fd, (struct sockaddr *)&addr, sizeof(addr)) == -1)
        err(EXIT_FAILURE, "connect");

    // Increase the send buffer if it's really small
    int send_size;
    socklen_t optlen = sizeof(send_size);
    int res = getsockopt(fd, SOL_SOCKET, SO_SNDBUF, &send_size, &optlen);
    if (res >= 0 && send_size < MIN_SEND_SIZE) {
        // Set buffer size
        send_size = MIN_SEND_SIZE;

        res = setsockopt(fd, SOL_SOCKET, SO_SNDBUF, &send_size, sizeof(send_size));
        if (res < 0)
            warn("Couldn't increase buffer size to %d", send_size);
    }

    ei_x_buff buff;
    if (ei_x_new_with_version(&buff) < 0)
        err(EXIT_FAILURE, "ei_x_new_with_version");


    ei_x_encode_tuple_header(&buff, 2);

    encode_args(&buff, argc, argv);
    encode_environ(&buff);

    ssize_t rc = write(fd, buff.buff, buff.index);
    if (rc < 0)
        err(EXIT_FAILURE, "write");

    if (rc != buff.index)
        errx(EXIT_FAILURE, "write wasn't able to send %d chars all at once!", buff.index);

    close(fd);
    return 0;
}
