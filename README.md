# undocker - Running Docker containers from unprivileged users
There are many tools for running containers (e.g. LXC, Singularity, udocker, etc.) but docker is probably the most popular of them.

But some sysadmins do not want to let their users to run Docker containers because of _security concerns_.

The objective of **`undocker`** is to enable sysadmins to let the users run Docker containers using their user credentials (i.e. the containers will be processes owned by the user and not by root).

undocker inspects the parameters to docker, **removes the dangerous parameters** and **adds some parameters** that should be included depending on the user. It also enables to **limit the docker images** that each user may use.

## Installation

### From sources

In this case you need to install the runtime `bashc`, that can be obtained [from here](https://github.com/dealfonso/bashc).

In this case you will need to install the dependencies of `undocker`.

```shell
$ git clone https://github.com/dealfonso/undocker
$ cd undocker
$ make
$ DESTDIR=/ make install
```

### From packages

Get the appropriate package from [the releases page](https://github.com/dealfonso/undocker/releases) and follow the instructions.

**CentOS**

```shell
$ yum install ./undocker.rpm
```

**Ubuntu**

```shell
$ dpkg -i ./undocker.deb
$ apt update
$ apt install -f
```

### From ppa

```shell
$ apt-add-repository ppa:grycap/apps
$ apt update
$ apt install undocker
```

## Features

Once **undocker** is installed, any user can call **undocker** to try to call docker. How the users can interact with **undocker** is configured in the file `/etc/undocker.conf` (that must be readonly for any user).

The configuration file describes the commandlines that the users are allowed to run. It is possible to specify specific permissions depending on linux groups or users. 

### Description of fine tune features

Let's use this configuration (taken from the distributed `.conf` file) as an example:

```conf
[command:run]
WHITELIST=--help,-i|--interactive,-t|--tty,-d|--detach,--rm,-e|--env list,-v|--volume list,-w|--workdir string,--name string
FORCED=-u $U_UID:$U_GID -v '$PWD:$PWD' -w '$PWD'
ALLOWEDIMAGES=alpine:.* ubuntu:.*

[command:run group:users]
RESTRICTEDIMAGES=ubuntu:14.04

[command:exec]
WHITELIST=--help,-i|--interactive,-t|--tty,-v|--volume list
FORCED=-u $U_UID:$U_GID -v '$PWD:$PWD' -w '$PWD'
UIDMUSTMATCH=true
```

#### allowed commands

If a section `[command:<command name>]` appears, then the command is allowed to be run by the users, with the restrictions that are defined in that sections.

> i.e. if a section (e.g) `[command:exec]` does not appear in the configuration file, the users won't be able to issue `undocker exec ...` commands.

#### allowed parameters

Then the allowed flags must be defined in the `WHITELIST` variable. The flags may use a _pipe separation_ to explain that the flags are equivalent (e.g. `-t|--tty`). If the flag has parameters, they must be included in the definition (e.g. `-w|--wordir string`). 

> The list of parameters can be obtained from the `docker --help`

In the case of `[command:run]`, we are allowing to use a set of parameters (e.g. `-i`, `-d`), but not other that we consider dangerous (e.g. `--privileged`).

#### forced parameters

A variable `FORCE` is also enabled, that **forces** a set of parameters to appear in the final call. In our case, `-u $U_UID:$U_GID -v '$PWD:$PWD' -w '$PWD'`. That means that the docker call will include the credentials of the user that is calling undocker (and not root), and the container will have the current folder mapped into the container (and it will be the working folder in the container).

The parameters in variable `FORCE` appear just after those parameters used by the user. So they have more priority (that means that (e.g.) if the user included other `-w` option, the one valid is the forced one).

#### permitted images

It is possible to limit the images that the users are able to use, by using variables `ALLOWEDIMAGES` and `RESTRICTEDIMAGES`. These variables may include a list of space separated names of docker images (it is possible to use regular expressions).

In the case of `[command:run]` we are allowing any alpine standard image, along with any ubuntu standard image.

#### specific permissions for groups and users

It is possible to specify options for a group of users or a individual user, by including sections with the form `[command:<command name> group:<group name>]` or `[command:<command name> user:<user name>]`.

Each section that begins with `[command:<command name>]` is accumulated to create the final permission set. The order of preference is `[command:<command name>]`, `[command:<command name> group:<group name>]` and `[command:<command name> user:<username>]`. That means that the specific setting for an individual user have more preference.

The final `WHITELIST` is the accumulation of `WHITELIST`. The same applies for `BLACKLIST`, `ALLOWEDIMAGES` and `RESTRICTEDIMAGES`.

In our example, if a user belongs to group `users`, he will be able to use any `alpine` image and any `ubuntu` image, except from `ubuntu:14.04`.

#### preventing the usage from other's containers

Each command that accepts a container name as a parameter can be forced to be used only if the referred container was started by the user.

That is made by setting the variable `UIDMUSTMATCH` to `true`. In our example, a user can make a `docker exec` call to a container (e.g. `docker exec -it <conainername> bash`) if he started the container (i.e. the container has his credentials).

## How undocker works

**undocker** is based in the existence of the application `/usr/bin/undocker-rt`. This application creates the safely constructed commandline and calls `docker`.

In order to make the final call to `docker`, needs to raise permissions to be able to make a final call to docker. It can be made in two ways: _using `sudo`_ or a _setuid application_.

In any case, the application `/usr/bin/undocker-rt` must be readonly for any user except from root, to prevent users from unauthorized modifications.

### SUDO mode (preferred).

A sudo configuration is needed. The distribution of undocker includes the proper configuration, that enables any user to `sudo` the application `/usr/bin/undocker-rt`.

The content of `/etc/sudoers.d/undocker` is the next:

```bash
ALL ALL=NOPASSWD:/usr/bin/undocker-rt
```

### SETUID mode

An application with u+s permissions and owned by root has to be installed in `/usr/bin/undocker-rts`. That application simply calls `/usr/bin/undocker-rt`, but having "root" permissions. In this way, it is avoided the usage of sudo.

The permissions for file `/usr/bin/undocker-rts` look like this:

```shell
$ ls -l /usr/bin/undocker-rts
-rwsr-xr-x 1 root root 8880 jun  6 17:46 /usr/bin/undocker-rts
```

## On container runtimes security

While most of other container runtimes are limited to _run containers using the user's credentials_ by default (e.g. Singularity has that way of working, or LXC that uses user-namespace remapping, using `subuid` and `subgid`), Docker does not work like that.

While Docker can also [remap users](https://docs.docker.com/engine/security/userns-remap/) to make it more secure. Its default working mode is to _run a daemon under **root credentials** and thus run the containers using that credentials_.

**root credentials** are needed for running most of containers (otherwise they will probably be a simple `chroot`). And the other runtimes also use them:
- **LXC**: runs the **daemon as root**, but starts give the containers other uid.
- **Singularity**: uses a **setuid** application that gives **root privileges** to the singularity runtime (* singularity can work without that setuid mode, but they recognise that most of the functionality won't work).
- **udocker**: the containers are **not full featured containers**, as it aims at being (more or less) a simple chroot on a Docker container filesystem to take profit from the installed applications.

## How to secure Docker containers

One of my premises on Docker security is...

> The best way to let the users run Docker containers is _not to let the users run Docker containers_

But I can rewrite the prase to 

> The best way to let the users run Docker containers is _not to let the users run __arbitrary__ Docker containers_

And this is the key work: __arbitraty__.

A security aware sysadmin should not let arbitraty users to run arbitrary Docker containers under root credentials. 

E.g. 

Don't allow

  `$ docker run --privileged -it alpine ash`

But allow    

  `$ docker run -it alpine ash`

or better

  `$ docker run -u $(id -u):$(id -g) -it alpine ash`

And that is **how undocker works**. It analyzes the commands issued by  the user and removes the prohibited ones (e.g. `--privileged` or `--dev`) and forces some other (e.g. `-u $(id -u):$id -g)`).
