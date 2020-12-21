---
title: Kubernetes的访问控制
date: 2019-10-10T10:51:55+08:00
draft: true
tags:
- Kubernetes
categories:
- 软件工程

---

Kubernetes 使用 api server 作为系统与外界的交互窗口，所有的操作都以 REST API请求实现。  
用户与API SERVER交互的方式一般有三种情况：
- 使用curl之类的工具之间向API SERVER发送 HTTP请求
- 使用 kubectl 工具向 API SERVER发送HTTP请求。 这个工具实际是封装好的HTTP客户端。
- 在程序中与API SERVER通过HTTP请求交互。

针对每一个HTTP请求，  api server 都会做安全访问的控制。 因此每一个请求的Header中都应该带有`Authorization`字段。  api server 会解析该字段， 并尝试从中获取到如下信息： 
- 用户名
- UID
- Groups
- Extra

然后凭借这四个信息来判断该请求是否是合法的请求， 如果不合法就不予执行。 具体到判断的过程，  api server 关于请求的安全控制分为三部分：
- 认证 ： 验证该请求发送者的身份是否合法。
- 授权 ： 验证该请求发送者是否有权利访问其请求的资源。
- 访问控制 ： 在系统层面决策是否执行请求。

每一步都是一个独立的模块， 可以分别配置。 但是每个请求将依次经过三个模块的验证： 认证通过了才能验证授权， 授权通过了才能验证访问权限， 三个模块都通过了才能进行实际的操作。  

---
 api server  本身不提供用户管理的功能， 因此也就不能提供其他系统常见的“注册”、 “登陆”、 “注销”等操作。  
没有完善的用户管理功能， 请求来了即使能够识别出用户名， 又如何判断其是否合法呢？  为此 api server 提供了几种简陋的认证方式作为替代：  
- X509 客户端证书
- 静态Token文件
- Bootstrap Token
- 静态密码文件
- 服务账号Token
- OIDC Token


服务账号token 方式是提供给kubernets内部的pods使用的， 当pod想要与 api server 交互时使用该方式。  
多种认证方式之间的关系为`或`， 即针对一个请求， 任意一个认证方式通过了， 那么该请求就算通过。
