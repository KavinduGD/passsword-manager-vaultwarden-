# Container Image

- The persistent data is stored under /data inside the container, so the only requirement for persistent deployment using Docker is to mount a persistent volume. Create a local directory where to map the container's persistent storage:

```bash
mkdir /vw-data
# using Docker:
docker run -d --name vaultwarden -v /vw-data/:/data/  -p 80:80 vaultwarden/server:latest
```

url: https://github.com/dani-garcia/vaultwarden/wiki/Starting-a-Container
