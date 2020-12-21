---
title: Kubernetes内部服务地址的组织
date: 2019-09-17T10:51:55+08:00
draft: true
tags:
- Kubernetes
categories:
- 软件工程

---

K8S内部使用虚拟网络， 其内部的所有IP和端口， 在没有显式绑定的情况下， 均不会和节点的IP和端口关联。 
在K8S内部建立的Pod都会被分配一个IP地址。 但是这个IP地址是K8S内部使用的私有地址， 或者可以理解为"内网地址"。 在K8S内部的其他Pod可以在网络上查找到它， 但是K8S集群外面的其他服务是无法找到它的。 如果想要把一个K8S的服务暴露给集群外面， 那么就需要使用Service。

## 什么是Service
笼统地来说， Service是Kubernetes提供的管理服务地址的解决方案, 可以用它来解决负载均衡， 服务发现等问题。 而且如果K8S集群内的Pod需要与集群外的服务交互(发送和接收请求)，  也需要使用Service来实现。  

## 如何使用Service
截止1.15版本， Service 的种类有以下几种 :
- ClusterIP (default)  
在K8S集群内部申请一个IP地址作为服务地址。 也就是说， 这个地址仅限K8S内部使用， 对于集群外部不可见。 
- ExternalName  
用于抽象一个K8S外部的服务。
- NodePort  
在ClusterIP类型的Service的基础上建立。 这种类型的Service会在集群的每个节点上申请一个端口， 并将这个端口的请求转发给ClusterIP类型的Service。  
- LoadBalancer  
在ClusterIP类型的Service基础上构建。 这种Service会在K8S集群之外创建一个负载均衡器， 并将所有请求依次转发到每个节点的对应端口。 


## Service API 的规范
serviceSpec中有许多字段， 其中必填字段和非必填字段根据类型的不同而不同。 
`clusterIP` 这个service使用的集群内部IP。 通常是由集群自行分配的，所以不需要指定。 但也可以手动分配， 此时需要填写该字段。 如果填写了已经占用的IP地址， 会返回错误。  
`externalIPs` 如果一个服务既有容器内的Pod， 又有容器外的进程， 那么容器外的那部分可以填写到这个字段中。 这是一种混合云的解决方案。  
> 所以一个服务如果想要对外暴露， 就需要先创建一个ClusterIP,  再创建一个NodePort, 再创建一个LoadBalancer。 我的天...而且， 这岂不是说一个K8S集群最多只能暴露60000个左右的服务...
> 并不用。 只需要创建一个NodePort就可以了。
