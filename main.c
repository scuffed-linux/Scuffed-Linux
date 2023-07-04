#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <linux/kd.h>
#include <errno.h>
#include <sys/mount.h>
#include <sys/types.h>

#define TTY0_PATH "/dev/tty0"
#define WAIT_INTERVAL 1 // seconds

static inline unsigned int makedev(unsigned int major, unsigned int minor) {
    return (major << 8) | minor;
}

int main() {
    // mount /dev
    mount("", "/dev", "devtmpfs", 0, NULL);

    // Wait for /dev/tty0 to become available or create it
    while (access(TTY0_PATH, F_OK) != 0) {
        if (mknod(TTY0_PATH, 0020000 | 0600, makedev(4, 0)) != 0) {
            if (errno == EEXIST) {
                break; // Another process created it
            } else {
                perror("Error creating /dev/tty0");
                return 1;
            }
        }
        sleep(WAIT_INTERVAL);
    }

    int tty0 = open(TTY0_PATH, O_RDWR);
    if (tty0 < 0) {
        perror("Error opening /dev/tty0");
        return 1;
    }

    // Set /dev/tty0 as the console
    if (ioctl(tty0, KDSETMODE, KD_TEXT) != 0) {
        perror("Error setting console mode");
        return 1;
    }

    // Redirect stdout, stderr, and stdin to /dev/tty0
    if (dup2(tty0, STDOUT_FILENO) == -1) {
        perror("Error redirecting stdout");
        return 1;
    }
    if (dup2(tty0, STDERR_FILENO) == -1) {
        perror("Error redirecting stderr");
        return 1;
    }
    if (dup2(tty0, STDIN_FILENO) == -1) {
        perror("Error redirecting stdin");
        return 1;
    }

    while (1)
    {
        system("/bin/bash");
    }    
}