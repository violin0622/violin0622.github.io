---
title: Golang使用私有仓库
date: 2020-08-31T14:51:20+08:00
tags: [go mod]
categories: [编程, Golang]

---

本文基于`go 1.13`即以上进行演示。  
将go代码推送到私有仓库之后， 如果想要在其他项目引用， 需要做以下设置。  

## 设置go env
```sh  
# 设置代理， 多个用逗号分隔， 最后direct是直接从项目地址拉取。 
# 这一步不是使用私有仓库必须设置的. 但是考虑到国内的网络情况, 应该大部分gopher都设置了该项吧. 
go env -w GOPROXY="https://goproxy.cn,direct"

# 设置不使用代理的域名, 用逗号分开多个。 可以设置通配符*，或者指定路径
go env -w GOPRIVATE="*.gitlab.com,private.gitlab.com/myrepo"

```

## 设置git token
只设置了 go env 还不够。 无论 go mod 也好， go get 也好， 都是依赖git来拉取项目代码的， 如果git没有访问仓库的权限依然不能正确拉取。  
以 Gitlab 为例， 需要创建一个访问Token， go 控制 git 拉取代码时使用该token进行认证， 才可以拉取代码。  
![申请token](/post/resources/_gen/images/申请gitlab的token.png)

创建token之后， 对git进行全局设置:
```sh
git config --global url."https://{username}:{token}@private.gitlab.com/myrepo".insteadOf "https://private.gitlab.com/myrepo"
```

然后就可以正常拉取私有仓库的代码了。 

`note` Coding的设置和Gitlab不太一样。 首先Coding的代码仓库网页URI和Git地址并不一样。  
例如我的项目访问网页时地址是`https://mlt.coding.net/p/riverrun/gogfapi`， 而git地址是`https://e.coding.net/mlt/riverrun/gogfapi.git`。  
在设置GOPRIVATE和git时， 应使用git地址， 且最后需要附带`.git`。 在项目中引用模块时， `import` 语句也需要写git地址， 同样需要带着`.git`后缀。  
