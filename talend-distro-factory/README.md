# Talend Distro

Docker images for downloading Talend subscription binaries from Talend web site.

### Interface

**build** - builds a docker image to download Talend binaries.  Default image name is talend-distro:<talend-version>.
The talend-distro image is a data container so it is derived from the scratch image and cannont be run, only created.

**create** - create an instance of the talend-distro image.  Default name is talend-distro-<talend-version>.

**test** - creates a temporary container to test the talend-distro container.  Attaches the talend-distro container with --volumes-from.

### Configuration

dockerfile - specification of the data container to be built.  Multi-stage docker build.

talend-manifest.txt - list of urls to download

talend.credentials - talend userid and password.
This is a property file and the properties must occur in the order specified.  The equals sign is the separator.
No whitespace, comments, or blank lines are allowed.
