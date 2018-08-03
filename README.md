# docker-rpi-homeassistant

Docker image to run Home Assistant in a Raspberry Pi


### Build

```
docker build . -t homeassistant
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
