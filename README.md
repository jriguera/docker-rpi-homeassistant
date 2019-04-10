# docker-rpi-homeassistant

Docker image to run Home Assistant in a Raspberry Pi


### Develop and test builds

Probably you want to initialize the upstream git submodules:

```
git submodule init
git submodule update
```

Submodules are not needed to build the Docker image, is just to make it easy to track changes and python requirements.

And then go to  `docker` folder and type:

```
docker build . -t homeassistant
# or run `./docker-build.sh`
```

### Update HA version

1. Update submodule to the proper tag `cd home-assistant && git checkout tags/<VERSION>`
2. Update `docker/Dockerfile` version argument
3. Manage requirements and check errors: `./manage-components.sh | grep -i "error"`
4. Update `docker/requirements.txt`: `./manage-components.sh > docker/requirements.txt`
5. Commit the cahnges: `git add home-assistant docker/Dockerfile docker/requirements.txt && git commit -m "Updated HA submodule to <version>`
6. Build new docker image: `./docker-build.sh`
7. Publish new docker image in DockerHub and GitHub: `create-publish-release.sh`


### Create final release and publish to Docker Hub and Github

```
create-publish-release.sh
```

### Run

Test
```
docker run -it -p 8123:8123  homeassistant
```

Production

```
docker run --name ha -p 8123:8123  -v $(pwd)/config:/config -d homeassistant
```


# Author

Jose Riguera `<jriguera@gmail.com>`
