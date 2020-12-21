---
title: Kubernetes中的容器配置管理：ConfigMap
date: 2019-09-16T10:51:55+08:00
tags:
- Kubernetes
categories:
- 软件工程

---

## 什么是ConfigMap
ConfigMap ，即配置字典， 是Kubernetes提供的用于管理容器中程序运行所需配置的解决方案。 它是一种持久化的机制， 不会随着容器的创建销毁而变化。 容器启动时从ConfigMap中读取配置， 并且多个容器可以共享同一个ConfigMap。  

## 软件配置常见的几种形式:
- 环境变量  
比如许多运行在Java虚拟机上的程序在启动时会读取`JAVA_HOME`环境变量， 配置不同的环境变量值， 也就使用了不同的Java虚拟机。  
再比如许多项目会使用环境变量来区分当前环境是`product`,`develop`,`test`。  

- 配置文件  
配置文件是最普及，最常用的一类配置形式。 无论是服务端程序还是客户端程序， 都会使用这种形式。  
常见的配置文件格式有 `*.ini`, `*.json`, `*.xml`, `*.conf`, `*.yaml`, `*.toml`等。

- 命令行参数  
这种形式用于命令行启动的程序， 并且常常会和配置文件，环境变量等形式搭配使用。 其优点在于灵活， 可以方便地对每次程序运行时指定不同的配置项， 因此很适合执行时间较短的程序， 例如压缩解压， 缺点在于总是会让整条命令变得又长又臭。  

- 远程配置中心  
随着微服务架构的盛行， 配置不再需要存储在本地了， 程序启动之后会到远程的服务去读取配置， 用户启动时只需要“告诉”程序去哪里读取配置。  这种配置方式极大地简化了本地部署的步骤， 适用于在多台服务器上大量部署的程序， 是未来的发展趋势。  

- 插件  
严格来说， 插件并不能算是一种配置形式。 因为它不像其他几种形式， 必须在程序刚刚启动时读取， 也不像其他几种形式， 通过用户编辑其内容来改变程序的行为。 插件更多的是在程序运行时根据需要或配置进行加载， 用以扩充程序的功能。  

## 创建配置字典的几种形式
配置字典是一个键值对形式Map。 键是由用户随意指定的， 而值才是Pod中的进程期望读取的配置。 很多应用的配置格式本身就是键值对形式的， 比如Java提供的`*.properties`文件就是键值对的列表。 在使用配置文件时应该将这个文件的内容整个作为配置字典中的`值`, 而不是每个配置文件中的键值对对应一个配置字典中的键值对。  

### 在命令行直接通过键值对创建  
  可以直接在命令行中指定键值对， 每个键值对都是一项配置。 就像这样:
  ```sh
  kubectl create configmap My-Config 
      --from-literal=key1=value1 
      --from-literal=loglevel='INFO, stdout' 
      --from-literal=java_home_env=/usr/lib/jre_1.8.0
  ```

### 通过单个配置文件创建  
  也可以将一个本地的配置文件上传形成一个配置字典。 指定文件可以使用绝对路径， 也可以使用相对路径。  
  `--from-file`参数的key是可选的， 如果不指定的话， 默认使用文件名作为key。  
  ```sh
  kubectl create configmap My-File-Config 
    --from-file=/home/app/config.properties 
    --from-file=config=/home/app/config.properties
  ```

### 通过目录创建
  很多应用都会同时使用多个配置文件， 而这些配置文件常常在同一个目录下。 因此当然也可以把一整个目录都创建成配置字典。  
  > 从目录创建配置字典实际上是针对目录内的每个文件， 创建以文件名为key的配置项。 因此这种用法有两个注意点：  
  > 1. 可以在一个配置字典中指定多个目录， 但是要保证所有这些目录中不能存在重名的文件。  
  > 2. 不能指定key, 此时key只能是文件名。  

  ```sh
  kubectl create configmap My-Dir-Config 
    --from-file=/home/app 
    --from-file=config=/home/anothor
  ```

### 通过二进制文件创建
  二进制文件同样也可以用来创建配置字典。 不过并不是直接存储在配置字典中， 而是先对文件进行base64编码， 再把编码后的字符串存储在配置字典中。  
  这是一种非常规用法， 一般不推荐。 如果文件太大的话， 会对k8s集群内的etcd造成压力。 另外上传时还可能会因为超时而中断请求。 仅适用于个别奇葩应用使用非文本形式的配置文件，或者一些程序会使用`.so`或`.dill`文件作为插件时使用。  
  ```sh
  kubectl create configmap My-Binary-Config 
    --from-file=/home/app/config.tar 
    --from-file=/home/app/plugin.so
  ```

### 使用命令行创建配置字典的缺陷
  使用命令行直接创建配置字典的优点是方便直接。 但是缺点也有：
  - 除非使用 --namespace 指定， 或者.kube/config文件中指定了命名空间， 否则该配置字典会在default命名空间内。   
  - 能够指定配置字典的名称， 但是不能指定配置字典的Label(当然可以在创建之后再用 kubectl lable命令添加)。  
  - 对于大量的配置， 使用命令行显然不方便。 好在--from-file选项弥补了这一点。   
  - 这是前面说到的"又长又臭的命令"的完美诠释。  

  如果想要添加配置字典的Label， 需要两条命令。 首先创建一个配置字典， 然后使用
  ```sh
  kubectl lable configmap My-ConfigMap key=value key2=value2
  ```

### 使用yaml文件创建配置字典
其实就是把想要配置的内容一股脑写到`data`字段下面就好啦。 示例：  
```yaml
apiVersion:  v1
kind: ConfigMap
metadata:
  labels:
    app: flume
  namespace: flume-namespace
  name: flume-config
data:
  flume.properties: |
    agent.sources = a1
    agent.channels = a1
    agent.sinks = a1
  log4j.properties: |
    flume.root.logger=INFO,console
    log4j.rootLogger=${flume.root.logger}
  java_home_env:
    /usr/lib/jre_1.8.0
```
事实上， 当想要在命令行查看已创建的配置字典内容， 使用`kubectl get config flume-config -o yaml`时， 看到的也是上面的形式。


## 在Pod内使用ConfigMap的几种方式
### 用于容器内的环境变量
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: java
spec:
  containers:
  - name: test-container
    image: alpine
    command: [ "/bin/sh", "-c", "echo $JAVA_HOME" ]
    env:
    - name: JAVA_HOME
      valueFrom:
        configMapKeyRef:
          name: My-Config
          key: java_home_env
```

### 用于容器内的目录
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
    - name: test-container
      image: k8s.gcr.io/busybox
      command: [ "/bin/sh", "-c", "ls /etc/config/" ]
      volumeMounts:
      - name: configDir
        mountPath: /etc/config
  volumes:
    - name: configDir
      configMap:
        # Provide the name of the ConfigMap containing the files you want
        # to add to the container
        name: My-Dir-ConfigMap
```

### 用于容器内的文件
要注意， 当使用配置字典作为容器内的配置文件时， 会将目标目录整个覆盖， 只保留配置字典中存在的"key", 也就是对应的配置文件。  
这样造成的后果就是不能够仅更新某个目录下面的单个文件。 例如如果想要用配置字典更新 `/etc/hosts`文件， 那么会导致 `/etc` 目录下的其他文件都被抹除。 因此使用时一定要小心。  
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: dapi-test-pod
spec:
  containers:
  - name: test-container
    image: k8s.gcr.io/busybox
    command: [ "/bin/sh","-c","cat /etc/config/keys" ]
    volumeMounts:
    - name: config-volume
      mountPath: /etc/config
  volumes:
  - name: config-volume
    configMap:
      name: special-config
      items:
      - key: SPECIAL_LEVEL
        path: keys
```

### 用于容器内的命令行
配置字典对于命令行形式的配置没有直接的支持， 不过可以通过设置环境变量， 然后在命令行中使用环境变量来间接地实现。 

### 用于容器内的插件
配置字典用作容器内的文件时， 会将base64编码还原， 因此容器内进程看到的是一个完整的二进制文件， 而不是奇怪的编码。

## 配置字典的更新
当Pod已经运行， 此时再更新其挂载的配置字典， 那么容器内是否能够感知到配置的变更呢？ 这要取决于Pod使用配置字典的方式：
1. 如果是使用配置文件或者配置目录的形式， 那么当k8s集群的配置字典更新， 容器内挂载的文件也会同步更新。 因此对于一些能够监听配置文件变更并自动加载新配置的程序(如Apache Flume)来说， 不需要重启Pod就可以立刻应用新的配置。  
2. 如果是使用命令行参数或环境变量的方式进行配置的， 由于环境变量是在创建容器的时候指定的， 因此无法随着配置字典的变更而变更。  

