---
title: 'Flume: 日志收集、聚合、归档工具'
date: 2019-03-24T16:24:47+08:00
tags:
- Flume
- Big Data
categories:
- middleware

---

在大数据时代， 计算机技术已经不是阻碍各大互联网公司发展的壁垒——在开源浪潮下， 所有的技术都是共享的。 甚至初创公司的技术栈会比大公司的更新更先进。 在这样的背景下， 只有数据是最珍贵的， 所有的公司都将自己搜集到的用户数据视若珍宝， 从中进行大数据分析以更好的抓住用户。   

那么数据是从哪里来的呢？毫无疑问日志是用户数据最好的来源。 以前的日志只是用来记录服务本身的运行状态， 只要服务不出问题， 那么没有人会去查看日志， 最多为了避免单个文件过大难以查阅， 写个定时任务将日志拆分成多个小文件。 即便服务出了故障， 查看一个月以前的日志也没什么帮助(除了少数特殊情况)， 因此 为了避免日志无限堆积占用磁盘空间， 通常还会有另一个定时任务负责把太久远的日志文件删除。   
 
然而自从各大互联网公司发现了用户数据的价值之后， 一切都变了：日志不再单纯记录服务本身的信息， 也开始记录用户的基本信息与行为记录， 服务器接受的每一次请求都将记录下至少一条信息， 虽然通常这两类日志不会记录到同一个文件里， 但依然无法阻挡后一种日志文件的容量增长急速上升；为了应对增长更快的文件尺寸， 也为了能更快地分析即时用户数据， 日志文件拆分的频率越来越高， 从每周， 每天， 到每小时甚至每分钟；而那些从前的日志文件也不能随便删除了：那可都是有价值的用户数据呢！可是面对这样大量的数据， 不能把他们一直存在服务器上吧， 这样既会给服务器带来巨大的负担， 而且也难以访问从而分析这些数据。 因此， OLAP出现了， Hadoop出现了， 这些分析专用的系统正是为了存储分析大量日志及用户数据而设计的。   

但是随之而来了新的问题：怎样将日志数据存储到这些分析数据库呢？  

Flume， 一个专为转运日志数据的系统应运而生。 Flume是一个用于收集、过滤、聚合、转运大量日志数据的工具， 其具有分布式， 高可靠， 高可用等特点。  而其运行却可以不依赖任何第三方服务， 只要有 JRE1.8 以上的Java运行环境即可。 整体可以说是简洁轻便， 灵活轻量。   

配置方面， 为了易于理解， 它使用一个简洁的数据模型来定义线上服务的配置：  
![image](https://flume.apache.org/_images/DevGuide_image00.png)  
其中一些基本概念如下：  
- **Source**： 收集数据——从数据源处读取数据， 封装成一个个的Events后发送到Channel。   
- **Channel**： 传输数据——负责以Event形式暂存数据。 之所以存在Channel而不是直接由Source端向Sink端发送数据是因为Source端读取数据的速度通常不是恒定的， 毕竟日志数据产生的快慢谁也无法掌握， 所以将数据存入Channel用于做个缓冲， 起到削峰填谷的作用。   
- **Sink**： 存储数据——数据的写入端。 负责从Channel端取出Event， 解封成原始数据， 存入目标位置。   
- **Agent**： 一个完整的Flume配置的最小单位。 一个Agent代表把数据从原始位置转移至目标位置的过程。 一个典型的Agent包含一个Source, 一个Channel， 一个Sink。 不过这并不是说想要启动一个Flume进程就必须凑齐这三个组件， 其实Source， Sink， Channel三部分可以部署在不同的服务器上， 例如在生成日志的服务器上配置一个Source用于收集日志， 然后配置一个远程服务如Kafka作为Channel， 以无Sink的形式启动一个Flume进程， 而在数据库服务器上， 同样配置一个Kafka Channel用于接收Kafka中的日志数据， 然后配置一个SQL Sink用于将日志存入数据库， 从而实现分布式配置。   
- **Event**：以字节形式按行封装数据， 除此之外每个Event还包含一个数据头， 可以以Key-Value形式存储了一些用户自定义的元数据。   
