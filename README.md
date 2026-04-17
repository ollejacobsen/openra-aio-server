# OpenRA All In One - Dedicated Server

This project provides a Dockerized environment for running OpenRA-based game servers (such as Red Alert, Tiberian Dawn, Dune 2000, Tiberian Dawn HD, Combined Arms and Hard Vacuum). 

The Docker image installs necessary dependencies, sets up directories for downloads and support data, and runs as a non-root user for security. The entrypoint script dynamically determines the correct game version and download URL¹, prepares the environment, and launches the appropriate game server as specified by environment variables. This setup allows for easy deployment and management of multiple OpenRA game servers in a consistent, isolated container.

_¹ Pre-built AppImages downloaded directly from each project's GitHub releases._

## Minimal recommended example
Stores downloaded versions in the `./downloads` directory on the host.

Before first `docker run ...`
__Tip:__ Read up on [Mounting/volumes (optional)](#mountingvolumes-optional) below.
```bash
$ mkdir -p downloads
$ sudo chmod -R 777 downloads
``` 

Then on every `docker run ...`
```bash
$ docker run -d -p 1234:1234 \
    -e GAME="RedAlert" \
    -e RELEASE_VERSION="latest" \
    -e Name="OpenRA AIO - RedAlert in Docker" \
    -v ./downloads:/downloads \
    --name openra-aio-ra \
    ollebulle/openra-aio-server:latest
```

# Docker environment variables
| Name  | Default value | Type |
| ------------- | ------------- |  ------------- | 
| GAME  | `RedAlert`  | `string:RedAlert\|Dune2000\|TiberianDawn\|TiberianDawnHD\|CombinedArms\|HardVacuum` |
| RELEASE_VERSION  | `latest`  | `string:latest\|release-20250330\|playtest-20260222\|<github-release-tag>` |
| MOTD  | `Welcome, have fun and good luck!`  | `string` |
|  |  |   | 
| Name  | `Dedicated AIO Server`  | `string` |
| ~~Map~~ | ~~`<empty>`~~  | ~~`UID:ca84655d5597511d74c87d2c298bbea865a577ee`~~ |
| ListenPort  | `1234`  | `integer:1234` |
| AdvertiseOnline  | `True` | `boolean:True\|False` |
| Password  | `<empty>`  | `string` |
| RecordReplays  | `False`  | `boolean:True\|False` |
| RequireAuthentication  | `False`  | `boolean:True\|False` |
| ProfileIDBlacklist  | `<empty>`  | `string:ip1,ip2,ip3` |
| ProfileIDWhitelist  | `<empty>`  | `string:ip1,ip2,ip3` |
| EnableSingleplayer  | `False`  | `boolean:True\|False` |
| EnableSyncReports  | `False`  | `boolean:True\|False` |
| EnableGeoIP  | `False`  | `boolean:True\|False` |
| EnableLintChecks  | `True`  | `boolean:True\|False` |
| ShareAnonymizedIPs  | `True`  | `boolean:True\|False` |
| FloodLimitJoinCooldown  | `5000`  | `integer:5000` |

~~strikethrough~~ = not supported

## Mounting/volumes (optional)
Regarding Docker mounts for  `/downloads` and `/support_dir`.

- `/downloads` stores all downloaded .AppImages. 
<br />Filename pattern: `{GAME}-{RELEASE_VERSION}_x86_64.AppImage`

- `/support_dir` is the OpenRA directory for logs, maps, replays, etc.
<br />A subdirectory will be created for each GAME.

__Volume mount__ e.g., `docker run -v my_downloads:/downloads ...`
<br />_Mounts a Docker-managed volume_

__Bind mount__ e.g., `docker run -v "$PWD/downloaded:/downloads" ...`
<br />_Mounts a host directory_

#### Important! File permissions for bind mounts
Create the directory on the host first, then run `sudo chmod -R 777 <directory-name>`

### Multiple containers in parallel with the same mount/volume
It's recommended to use the same mount over multiple instances of this container.
```bash
#RedAlert
$ docker run -d -p 1234:1234 \
  -e RELEASE_VERSION=latest \
  -v ./downloads:/downloads \
  --name openra-aio-ra
  ollebulle/openra-aio-server:latest

$ docker run -d -p 1235:1234 \
  -e RELEASE_VERSION=playtest-20260222 \
  -v ./downloads:/downloads \
  --name openra-aio-ra-playtest
  ollebulle/openra-aio-server:latest

#Dune2000
$ docker run -d -p 1236:1234  \
  -e GAME=Dune2000 -e RELEASE_VERSION=release-20250330 \
  -v ./downloads:/downloads \
  --name openra-aio-d2k
  ollebulle/openra-aio-server:latest

#TiberianDawnHD
$ docker run -d -p 1237:1234 \
  -e GAME=TiberianDawnHD -e RELEASE_VERSION=playtest-20260222 \
  -v ./downloads:/downloads \
  --name openra-aio-tdhd
  ollebulle/openra-aio-server:latest

#CombinedArms
docker run -d -p 1238:1234 \
  -e GAME=CombinedArms -e RELEASE_VERSION=1.08.2 \
  -v ./downloads:/downloads \
  --name openra-aio-ca
  ollebulle/openra-aio-server:latest

#HardVacuum
docker run -d -p 1239:1234 \
  -e GAME=HardVacuum -e RELEASE_VERSION=latest \
  -v ./downloads:/downloads \
  --name openra-aio-hv
  ollebulle/openra-aio-server:latest
``` 

## Example: Multiple AIO containers and AdvertiseOnline=True
When running multiple aio containers you need to match port with listen port otherwise the game will not be listed. But you can still connect with `ip:port`

```bash
#RedAlert, latest release
$ docker run -d -p 1234:1234 \
  -e RELEASE_VERSION=latest \
  -e ListenPort="1234" \
  -e AdvertiseOnline=True \
  --name openra-aio-ra
  ollebulle/openra-aio-server:latest

#RedAlert, playtest (note: port 1235 - all the way)
$ docker run -d -p 1235:1235 \
  -e RELEASE_VERSION=playtest-20260222 \
  -e ListenPort="1235" \
  -e AdvertiseOnline=True \
  --name openra-aio-ra-playtest
  ollebulle/openra-aio-server:latest
```

## More vars and mapping of the support-dir
```bash
$ docker run -d -p 1234:1234 \
    -e GAME="RedAlert" \
    -e RELEASE_VERSION="release-20250330" \
    -e Name="AIO OpenRa, RedAlert in Docker" \
    -e ListenPort="1234" \
    -e AdvertiseOnline=False \
    -e EnableSingleplayer=True \
    -e Password="abc" \
    -e RecordReplays=True \
    -v ./downloads:/downloads \
    -v ./data:/support_dir \
    --name openra-aio-ra \
    ollebulle/openra-aio-server:latest
```