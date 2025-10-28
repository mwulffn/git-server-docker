# git-server-docker
A lightweight Git Server Docker image built with Alpine Linux. Available on [GitHub](https://github.com/mwulffn/git-server-docker) and [GitHub Container Registry](https://github.com/mwulffn/git-server-docker/pkgs/container/git-server-docker)

!["image git server docker" "git server docker"](https://raw.githubusercontent.com/jkarlosb/git-server-docker/master/git-server-docker.jpg)

## Features

- **Multi-Architecture Support**: Supports both `linux/amd64` and `linux/arm64` platforms
- **Configurable UID/GID**: Use `PUID` and `PGID` environment variables to match your host user (default: 1000)
- **Automated Builds**: GitHub Actions automatically builds and pushes multi-arch images on every commit and tag
- **Alpine Linux**: Lightweight and secure base image

### Basic Usage

How to run the container in port 2222 with two volumes: keys volume for public keys and repos volume for git repositories:

	$ docker run -d -p 2222:22 -v ~/git-server/keys:/git-server/keys -v ~/git-server/repos:/git-server/repos ghcr.io/mwulffn/git-server-docker:latest

#### With Custom UID/GID

To avoid permission issues with mounted volumes, match the container's git user UID/GID with your host user:

	$ docker run -d -p 2222:22 \
	  -e PUID=1001 \
	  -e PGID=1001 \
	  -v ~/git-server/keys:/git-server/keys \
	  -v ~/git-server/repos:/git-server/repos \
	  ghcr.io/mwulffn/git-server-docker:latest

Find your host UID/GID with: `id -u` and `id -g`

How to use a public key:

    Copy them to keys folder: 
	- From host: $ cp ~/.ssh/id_rsa.pub ~/git-server/keys
	- From remote: $ scp ~/.ssh/id_rsa.pub user@host:~/git-server/keys
	You need restart the container when keys are updated:
	$ docker restart <container-id>
	
How to check that container works (you must to have a key):

	$ ssh git@<ip-docker-server> -p 2222
	...
	Welcome to git-server-docker!
	You've successfully authenticated, but I do not
	provide interactive shell access.
	...

How to create a new repo:

	$ cd myrepo
	$ git init --shared=true
	$ git add .
	$ git commit -m "my first commit"
	$ cd ..
	$ git clone --bare myrepo myrepo.git

How to upload a repo:

	From host:
	$ mv myrepo.git ~/git-server/repos
	From remote:
	$ scp -r myrepo.git user@host:~/git-server/repos

How clone a repository:

	$ git clone ssh://git@<ip-docker-server>:2222/git-server/repos/myrepo.git

### Arguments

* **Expose ports**: 22
* **Volumes**:
 * */git-server/keys*: Volume to store the users public keys
 * */git-server/repos*: Volume to store the repositories
* **Environment Variables**:
 * `PUID`: User ID for the git user (default: 1000)
 * `PGID`: Group ID for the git user (default: 1000)

### SSH Keys

How generate a pair keys in client machine:

	$ ssh-keygen -t rsa

How upload quickly a public key to host volume:

	$ scp ~/.ssh/id_rsa.pub user@host:~/git-server/keys

### Build Image

#### Local Build (Single Architecture)

	$ docker build -t git-server-docker .

#### Multi-Architecture Build

To build for multiple architectures (amd64 and arm64):

	# Create buildx builder (first time only)
	$ docker buildx create --name multiarch --use

	# Build and push multi-arch image
	$ docker buildx build --platform linux/amd64,linux/arm64 \
	  -t ghcr.io/mwulffn/git-server-docker:latest \
	  --push .

#### Automated Builds

This repository uses GitHub Actions to automatically build and push multi-arch images:
- **On push to master**: Builds and pushes with `latest` tag
- **On version tags** (e.g., `v1.0.0`): Builds and pushes with version tags

To trigger a new build, simply push to master or create a new tag:

	$ git tag v1.0.0
	$ git push origin v1.0.0
	
### Docker-Compose

You can edit docker-compose.yml and run this container with docker-compose. The compose file includes PUID/PGID configuration:

	$ docker-compose up -d

The docker-compose.yml file includes environment variables for PUID/PGID. Uncomment and adjust them to match your host user to avoid permission issues with mounted volumes
