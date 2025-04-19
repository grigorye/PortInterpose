# PortInterpose

A handy tool for hijacking ports used by macOS executables.

## Why

While automating end-to-end tests of [Handsfree](https://github.com/grigorye/Handsfree) for a few dozen supported Garmin models, I have to parallelize the test runs, to speed things up (otherwise it would take ~3 hours for a single iteration).

Technically/in general, test parallelization can be utilized by using multiples of:

-   Threads
-   Processes
-   Users
-   Hosts

With Handsfree, end-to-end tests involve the (watch) app installed in Garmin Connect IQ simulator on one hand and the (companion) app installed on Android emulator on the other.

Therefore, the minimum potential candidate for parallelization is a process.

With Android emulator, we run multiple instances in Docker, what matters is just the port that is used for adb. Overall it's quite well supported, out of box.

With Connect IQ simulator, the situation is complicated because of two things.

First, it's a typical macOS app, and it does not support launching more than once, per user. Hence to parallelize it, we utilize multiple users in a [VM](https://github.com/cirruslabs/orchard).

Second, and that's pretty annoying, even after making sure that each instance works under a dedicated user, it does not work properly, and it results in very weird behavior, like simulator rendering apps launched under a different user. The clue is network ports that are utilized by Simulator for communication. That is 7381 (for communication with Android app through adb) and 1234 (for installation/launching watch apps by monkeydo).

To make it clear, 7381 is the port that is "forwarded" by adb to a port in Android emulator, but the (local) _port_ 7381 itself is something that is get open by Connect IQ simulator. Hence while different port can be utilized per Android emulator, only one connection can be effective, as all instances of Connect IQ simulator use 7381.

The same story is with the port 1234. Only one instance of Connect IQ simulator serves requests to 1234, and hence monkeydo ends up talking to a wrong instance.

Both Connect IQ simulator and monkeydo do not provide a way to override 7381 or 1234.

There comes PortInterpose as a solution for overriding those ports.

## How

Basically we hijack bind/connect calls, substituting the given port instead of the "original" one. Hence each instance of Connect IQ still "believes" that it talks to 7381, while in reality it may be talking to 8381, 8382 or whatever is employed in real life, to segregate communication with each Android emulator.

That is accomplished by utilizing DYLD_ family of environment variables to force loading of the given .dylib together with the given executable.

**Disclaimer**: I'm not expert in (socket) networking/did use ChatGPT a lot to figure out the details. Potentially, some other calls need to be hijacked (particularly, getsockname/getpeername), but for Handsfree/Connect IQ simulator bind/connect was enough, so I leave it as-is for now. There's also an end-to-end (netcat-based) test employed here, that kind of shows that it works as expected.

To utilize it in real life, we need to end up with three things in the environment on launching the executable in question, illustrated below:

-   DYLD_INSERT_LIBRARIES=./.build/arm64-apple-macosx/debug/libPortInterpose.dylib
-   DYLD_FORCE_FLAT_NAMESPACE=1
-   PORT_INTERPOSE_MAP={"7381":"8381", "1234":"2234"} (where 7381 and 1234 are the original ports, while 8381 and 2234 are the "mapped" ones)

What is also important to realize, is that DYLD_ hijacking does not work with executables protected by SIP. Hence, to utilize it with SIP enabled, the executables in question should not be "system ones", nor DYLD_ variables can be defined in a parent process corresponding to SIP-protected executable. Hence this whole solution may be more relevant only for VMs with SIP protection disabled and etc.

