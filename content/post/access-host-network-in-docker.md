---
title: Docker容器中访问宿主机网络
date: 2020-04-08T14:41:12+08:00
tags: [docker]
categories: [软件工程]

---

## Docker容器监听宿主机端口
### 使用端口映射
现在假设有一个Docker容器nginx， 它运行时将监听docker内的80端口， 此时宿主机的80端口并没有被占用， 也无法将请求传入容器中。  
如果需要容器监听宿主机的80端口， 那么需要在启动容器时进行端口映射。 
```sh
# 由于映射了宿主机的80和443端口， 低于1024， 因此需要使用root用户启动docker. 
docker run -d \
    --name nginx \
    -p 80:80 -p 443:443 \
    nginx:latest
```
`-p`选项接收`{宿主机端口}:{容器端口}`格式的参数， 可以多次指定以指定多个端口映射。  

### 使用host网络模式
Docker容器启动时有`host`, `bridge`, `none` 三种网络模式， 默认是使用`bridge`桥接模式， 这种模式下可以使用端口映射的方式监听宿主机端口。
不过也可以使用`--network`选项指定`host`模式， 这种模式下容器与宿主机共享网络， 因此可以直接监听与请求宿主机上的网络端口。 
```sh
# 使用host模式可以直接监听宿主机网络端口，不必使用-p进行端口映射。 
docker run -d \
    --network host \
    --name nginx-docker \
    nginx:latest

# 也可以直接访问宿主机端口。  
docker run --rm \
    --network host \
    --name curl-docker \
    alpine curl localhost:80 
```


## Docker容器访问宿主机端口
从Docker容器中访问宿主机的端口有两种方式

### 指定宿主机IP (Linux)
在安装Docker的时候，会在宿主机安装一个虚拟网卡docker0, docker0对应的地址就是容器访问宿主机的地址。  
```sh
$ ip addr show docker0
4: docker0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default
    link/ether 02:42:73:74:56:03 brd ff:ff:ff:ff:ff:ff
    inet 172.17.0.1/16 brd 172.17.255.255 scope global docker0
       valid_lft forever preferred_lft forever
    inet6 fe80::42:73ff:fe74:5603/64 scope link
       valid_lft forever preferred_lft forever
```
可以看到docker0对应的地址为 `172.17.0.1`, 那么启动docker时可以这样:  
```sh
docker run --rm \
    --name curl-docker \
    alpine curl 172.17.0.1:80
```

### 指定宿主机IP (mac)
macOS的情况与Linux系统不同， Docker原生不支持macOS， mac上安装的Docker程序实质上是一个带着Docker的Linux虚拟机,  因此macOS上不会有 docker0 网卡。  
不过这种情况也有专门的解决方案， 那就是使用特殊的地址 `docker.for.mac.localhost` 代替。  
```sh
docker run --rm \
    --name curl-docker \
    alpine curl docker.for.mac.localhost:80
```
