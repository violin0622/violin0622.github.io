---
title: "JVM的JMX机制"
date: 2021-05-14T17:14:19+08:00
tags: [JVM]
categories: [软件工程]

---

[toc]

# 什么是 JMX 
JMX 全称是 The Java Management Extensions ，是一种继承到 JVM 中的标准化功能。

JMX 的作用是在 JVM 运行过程中，实现对进程内变量的访问与控制。
这个「进程内变量」，既可以是 JVM 的运行参数，也可以是用户程序自定义的变量。  

由于 JMX 的灵活性， 因此该技术经常被用于在运行时修改 JVM 运行参数、不停机修改应用的配置、监控指标导出等功能。  

更方便的是， JMX 支持一些远程访问协议，典型的如 RMI 与 HTTP 协议。
因此不必登陆到 JVM 进程所在的服务器，即可实现对进程的访问。 


JMX 整体的架构如下：  
```ascii
                  ┌─────────┐  ┌─────────┐                  
                  │jconsole │  │   Web   │              
                  └─────────┘  └─────────┘              
              	      rmi          http              
                       │            │              
              ┌────────│────────────│────────┐              
              │JVM     ▼            ▼        │              
              │   ┌─────────┐  ┌─────────┐   │              
              │ ┌─┤Connector├──┤ Adaptor ├─┐ │              
              │ │ └─────────┘  └─────────┘ │ │              
              │ │       MBeanServer        │ │              
              │ │ ┌──────┐┌──────┐┌──────┐ │ │              
              │ │ │MBean1││MBean2││MBean3│ │ │              
              │ │ └──────┘└──────┘└──────┘ │ │                 
              │ └──────────────────────────┘ │   
              └──────────────────────────────┘              
```

JMX 的主体是与 JVM 嵌合在一起的 MBeanServer， 对于需要管理访问的数据，通过 MBean 的方式注册到 MBeanServer 中。 
另外，MBeanServer 通过各种接口供外部访问。

# 使用 JMX
如果想要通过 JMX 技术在进程外部对进程数据进行访问，那么必须要将该数据封装在 MBean 中，并将 MBean 注册给 MBeanServer 。

MBean 是一种遵循 JMX 要求而设计的类和对象 ，不过本质上和普通的对象并没有什么区别。 
当通过 JMX 访问一个 MBean 时， MBean 将暴露三类信息：
1. 一些属性
2. 一些方法
3. 自述信息

## 定义 MBean 接口
要注意， MBean 的接口名称必须要以 `MBean` 结尾。   
在 MBean 接口 中，需要读写的属性将以 getter/setter 的方式定义。  

```java
package com.example; 
 
public interface HelloMBean { 
 
    public void sayHello(); 
    public int add(int x, int y); 
    
    public String getName(); 
     
    public int getCacheSize(); 
    public void setCacheSize(int size); 
}
```


## 实现 MBean 接口
```java
package com.example; 
 
public class Hello implements HelloMBean { 
    public void sayHello() { 
        System.out.println("hello, world"); 
    } 
     
    public int add(int x, int y) { 
        return x + y; 
    } 
     
    public String getName() { 
        return this.name; 
    }  
     
    public int getCacheSize() { 
        return this.cacheSize; 
    } 
     
    public synchronized void setCacheSize(int size) {
        this.cacheSize = size; 
        System.out.println("Cache size now " + this.cacheSize); 
    } 
     
    private final String name = "Reginald"; 
    private int cacheSize = DEFAULT_CACHE_SIZE; 
    private static final int DEFAULT_CACHE_SIZE = 200; 
}
```


## 注册 MBean 对象
在注册 MBean 到 MBeanServer 时， 需要为每个 MBean 对象指定一个名称。  
名称必须是 `javax.management.ObjectName` 类型，并且名称必须按照 ObjectName 类规定的格式。  

简单来说，ObjectName 规定的 MBean 的名称分成两部分， 中间由冒号分割:
- 一个域名
- 一组键值对

```java
package com.example; 
import java.lang.management.*; 
import javax.management.*; 
 
public class Main { 
    public static void main(String[] args)  throws Exception { 
     
        MBeanServer mbs = ManagementFactory.getPlatformMBeanServer(); 
        ObjectName name = new ObjectName("com.example:type=Hello"); 
        Hello mbean = new Hello(); 
        mbs.registerMBean(mbean, name); 
          
     
        System.out.println("Waiting forever..."); 
        Thread.sleep(Long.MAX_VALUE); 
    } 
}
```

# 启用 JMX 
在启动 JVM 进程时，添加如下参数以启用 JMX :

```shell
java \
  -Dcom.sun.management.jmxremote \  
  -Dcom.sun.management.jmxremote.port=9999
  -Dcom.sun.management.jmxremote.authenticate=false \  
  -Dcom.sun.management.jmxremote.ssl=false \  
  -jar App.jar
```

这样便让 JVM 进程监听了 9999 端口作为 JMX 的入口。 

上面的例子没有开启 TLS 验证与通信加密，如果需要开启的话，只需修改对应的
`com.sun.management.jmxremote.authenticate`和`com.sun.management.jmxremote.ssl`参数即可。

启动进程之后会发现， JVM 除了监听指定的 JMX 端口之外，还额外监听了两个随机端口。 这两个端口一个是供 RMI 使用的， 一个是供 Jconsole 等监控工具访问本地 JVM 进程时使用的。 

对于部分应用环境中， 通过防火墙限制了端口访问的范围， 那么还需要额外添加两个参数，以使 RMI 通信的端口复用 JMX 端口：
```shell
java \
  -Dcom.sun.management.jmxremote \  
  -Dcom.sun.management.jmxremote.port=9999
  -Dcom.sun.management.jmxremote.authenticate=false \  
  -Dcom.sun.management.jmxremote.ssl=false \  
  -Dcom.sun.management.jmxremote.rmi.port=9999
  -Djava.rmi.server.hostname=$(ip route get 8.8.8.8 | awk '{print $NF; exit}') \  
  -jar App.jar
```

如果想要关闭最后一个监听的随机端口， 那么只需在启动参数中加上这一项:
`-XX:+DisableAttachMechanism`


# 访问 JMX
在 JDK 中自带了一个 GUI 工具用以通过 JMX 访问进程， 也就是上面提到的 `Jconsole`。

不过这是一个 GUI 工具，在 CLI 环境中无法使用。 如果想要在命令行中访问 JMX 的话， 那么 [Jmxterm](https://docs.cyclopsgroup.org/jmxterm) 是一个不错的选择。 


## JMX 与监控
JMX 需要通过 RMI 协议去访问， 如果想要通过 JMX 暴露一些监控指标到 Prometheus 的话， 那么还需要搭配 [JMX Exporter](https://github.com/prometheus/jmx_exporter)，在启动 JVM 时添加 java agent，并指定 HTTP 端口和指标转换配置文件。 
```
java \
  -javaagent:./jmx_prometheus_javaagent-0.15.0.jar=8080:config.yaml \
  -jar App.jar
```

## JMX 性能调优
有一个强大的 JVM 分析工具， [VisualVM](https://visualvm.github.io/)， 可用通过 JMX 方式查看进程的运行状态， 堪称性能调优利器 ！


# 参考
- 官方对于 JMX 技术的介绍: 
[ Overview of the JMX Technology ](https://docs.oracle.com/javase/tutorial/jmx/overview/index.html)  
- StackOverflow 上关于 JMX 端口的讨论: 
[Why Java opens 3 ports when JMX is configured? ](https://stackoverflow.com/questions/20884353/why-java-opens-3-ports-when-jmx-is-configured/21552812#21552812)
