# Building MicroOS and SLE Micro qcow2 images with packer.io

This directories contains everything required to build MicroOS and
SLE Micro qcow2 images with packer (https://packer.io)

## Prerequisites

### Configuration files

At first, checkout this directory. You need the files or directories:
- http (autoyast profile to install the system)
- scripts (post-install processing and cleanup)
- build.sh (call packer with the right arguments and environment)
- microos.json (the packer template)

### Packer binary

If the `packer` command is not already installed (don't mix this up with the
packer command from cacklib!), download it from
https://www.packer.io/downloads and place it in the current directory with the
other files.

If `packer` is not in the current directory, the environment variable `PACKER`
needs to point to it.

## Build the image

### MicroOS

Just call:

```
# ./build-microos.sh
```

As result, there should be an image `MicroOS-<VERSION>.qcow` in the `images`
directory.

### SLE Micreo

Just call:

```
# ./build-sle-micro.sh
```

As result, there should be an image `SLE-Micro-<VERSION>.qcow` in the `images`
directory.

## Run the image

The easiest way to run the image is to import it into virt-manager, but it can
be run with plain qemu, too.

The default root password is `linux` and you are enforced to change it during
first login.
