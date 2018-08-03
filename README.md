# docker-rpi-homeassistant

Docker image to run Home Assistant in a Raspberry Pi


### Develop and test builds

Probably you want to initialize the upstream git submodules:

```
git submodule init
git submodule update
```

Submodules are not needed to build the Docker image, is just to
make it easy to track changes.

And then go to  `docker` folder and type:

```
docker build . -t homeassistant
```

### Create final release and publish to Docker Hub

```
create-release.sh
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
