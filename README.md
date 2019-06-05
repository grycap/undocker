# undocker - Running Docker containers from unprivileged users
There are many tools for running containers (e.g. LXC, Singularity, udocker, etc.) but Docker is probably the most popular of them.

But some sysadmins do not want to let their users to run Docker containers because of _security concerns_.

The objective of **`undocker`** is to enable sysadmins to let the users run Docker containers using their user credentials (i.e. the containers will be processes owned by the user and not by root).

## Installation

### From sources

In this case you need to install the runtime `bashc`, that can be obtained [from here](https://github.com/dealfonso/bashc).

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

## Usage



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
