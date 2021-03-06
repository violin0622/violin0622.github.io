---
title: <译>并发模型
date: 2019-03-02T19:23:36+08:00
tags:
- 翻译
- 并发编程
categories: [编程]

---

> 本文翻译自 http://tutorials.jenkov.com/java-concurrency/index.html

并发系统可以使用不同的并发模型来实现。`并发模型`阐述了系统中的多个线程怎样合作来完成给定的任务。不同的并发模型把任务按照不同的方式拆分，且线程之间或许通过不同的方式来通信和协作。这篇文章比较深入地介绍了截至当前(2015年)最流行的几个并发模型。

## 并发模型和分布式系统的相似性
这篇文章中介绍的几种并发模型和不同的分布式系统架构十分相似。在一个并发的操作系统中，不同的线程之间会互相通信；在分布式系统中，不同的进程会互相通信(或许它们位于不同的计算机):进程和线程实际上非常相似。这就是不同的并发模型看起来和不同的分布式系统架构十分相似的原因。

当然，分布式系统还会面临更多额外的挑战比如网络失败，或者远端计算机宕机等。不过运行在大型服务器上的并发操作系统也有可能会面临相似的问题，比如某个CPU、网卡、磁盘挂掉了之类的。遇到这种事的可能性会很低，但在理论上依然会发生。(译注:现在的服务器上确实会配备多个CPU，网卡及磁盘。这样的设计一方面是为了提高服务器性能，另一方面也是出于可用性考虑。也就是说，某个硬件坏掉并不只是理论上的可能，它确实会发生。)

正因为并发模型和分布式系统架构如此相似，它们经常可以互相借鉴经验。例如，在多个线程之间分派任务的模型通常与分布式系统的负载均衡模型相似。还有错误处理技术如日志，故障切换(fail-over), 幂等也都相同。

<!-- more -->
## 并行执行模型
第一个并发模型被称为`并行执行`。输入的任务被分派给不同的执行者。如下图所示:
![image](https://s2.ax1x.com/2019/03/02/kq1Uzj.png)
在并行执行模型中，分派者把任务拆分并分派给不同的执行者。每个执行者都可以完成分派下来的整个任务。所有的执行者在不同的线程中并行地执行，这些线程或许是在不同的CPU上。

想象一家汽车厂实现了并行工作模型，每个执行者都将会生产一辆汽车。单个执行者将会从头到尾地生产分派给他的那辆特定的汽车。

并行执行模型是在Java应用中最常用的并发模型(尽管现在正渐渐改变)。`Java.util.concurrent` 包中有许多并发工具都是为了这个模型准备的。

## 并行执行的优点
并行执行模型的优点就是易于理解。如果要提高并发程度，只需要增加执行者的数量就可以了。

例如，你要实现实现一个网络爬虫，你可以利用不同数量的执行者线程来爬取相同总数量的页面，然后比较使用多少执行者可以在最短时间内完成任务(也就是性能最高)。因为网络爬虫是一个对IO敏感的任务，因此或许你会发现每个CPU执行少量线程是个最好的选择。每个CPU一个线程就太少了，因为这将会花费大量的时间在等待数据下载。

## 并行执行的缺点
在简单易于理解的外表下，并行执行模型也有一些缺点，下面将介绍其中最显著的几个。

### 分享状态会带来复杂度
在现实中并行执行模型比上面阐述的要复杂一些。每个执行者常常需要访问一些公共的数据，可能在内存，也可能在数据库。如下图所示:
![image](https://s2.ax1x.com/2019/03/02/kq1NWQ.png)
这些状态有时候通过一些通信机制来共享，如任务队列。但有些状态是业务数据，数据缓存，数据库连接池等等。

一旦引入了共享的状态，那么事情就变得复杂了。线程之间需要一种机制来保证某一个线程对共享数据做出的变更对于其他线程来说是可见的(需要将新的数据直接推到主存中而不是缓存在某个CPU自己的cache中)。线程之间要避免竞态条件，死锁，以及其他许多共享状态的并发问题。

另外，当线程在访问共享数据时的互相等待行为也会造成并发性的丢失。许多并发的数据结构是阻塞性的，意味着任何时间只能由一个或一小部分线程能同时访问它们，这将导致在访问这类数据结构时会发生竞争。激烈的竞争将导致访问这类数据结构的那部分代码在一定程度上变成串行执行的。

现代的`非阻塞并发算法`在一定程度上可以降低竞争以提升性能，但非阻塞算法的实现非常复杂。

另一个选择是使用持久数据结构。它在修改时始终保留自身的先前版本。这样一来，如果多个线程指向了同一个持久数据结构并且其中某个线程修改了数据，这个线程将获取一个指向新数据结构的引用。所有其他的线程依然持有指向旧版本数据结构的引用。Scala语言包含了几个这样的持久数据结构。

持久数据结构是并发修改状态的一个优雅的解决方案，但也不是万能的。

例如，一个持久的链表会将所有的新节点插入链表头部，并返回一个指向新节点的引用。当一个线程插入新数据之后，所有其他线程仍将持有指向前一个版本的头节点的引用，然而如今那已经是事实上的第二个节点了。也就是对于其他线程来说，这个链表的变更是不可见的。

持久链表的底层实现是链表，然而链表在现代硬件上的性能并不太好。链表中的每个元素都是分离开的，这些元素的分布甚至可能跨越整个内存区域。现代CPU在顺序访问数据的时候是非常快的，所以在现代的硬件上用数组的性能比用链表快得多，因为数组就是按顺序存放数据的。CPU缓存可以一次载入数组中的一大块数据，然后这部分数据就可以直接在CPU缓存中读取了。同样的事在使用链表存放数据时几乎不可能发生。

### 无状态执行者
共享的状态或许会被操作系统中的其他线程更改，因此每次需要该状态的时候都不得不重新读入，以此来保证自己持有的状态是最新的。无论共享的状态是在内存中，还是数据库中都必须如此。一个本身不持有状态，但是每次需要都重新去读取状态的执行者，被称为`无状态的`。

每次都重新读取状态信息是很慢的，尤其是状态被存储在外部数据库的时候。

### 任务的执行顺序是不确定的
并行执行模型的另一个缺陷是任务的执行顺序是不可知的。没有什么手段可以保证哪个任务先执行，哪个任务后执行。

非确定的执行顺序带来的后果就是很难确定某一个时间点整个系统的状态。同样也很难保证一个特定任务在另一特定任务之前执行。

## 流水线
第二个并发模型我将其称为`流水线模型`。其他开发者根据其社区或平台的不同会使用不同的名称(例如交互式系统/事件驱动系统)。下图解释了流水线模型的模式。
![image](https://s2.ax1x.com/2019/03/10/A9pcG9.png)

多个执行者的组织方式就像是工厂里面流水线旁边的工人们一样。每个执行者仅仅处理自己的一部分任务。这一个执行者做完了，下一个执行者接上。

每个执行者都是一个单独的线程，且每个执行者之间没有共享的状态。因此有时该模型也被称为`无共享并发模型`。

使用流水线模型的系统通常是被设计用来*无阻塞*地进行IO。无阻塞地IO的意思是当一个执行者开始一个IO操作的时候(例如从网络中读取一个文件或一些数据)，这个执行者不必阻塞地等待这个IO操作结束。IO操作是很耗时的，所以阻塞地等待IO操作是对于CPU资源的浪费。CPU这个时候可以分配给其他的 执行者，当IO操作完成的时候，操作结果(例如读取到的数据或文件)再传递给那个执行者。

得益于无阻塞IO的特性，可以将IO操作作为多个执行者之间切换的边界。一个执行者可以尽情地占用CPU资源来执行任务，直到它不得不开始一次IO操作，此时它将交出CPU资源。当IO操作完成之后，流水线上的下一个执行者将继续工作，直到它也遇到了一次IO操作。
![image](https://s2.ax1x.com/2019/03/10/A9CRHK.png)

事实上，整个任务或许不会仅仅由一条流水线组成。大多数系统都可以同时运行多个任务，从执行者到执行者之间的任务流取决于任务本身。事实上，一个任务或许会同时有多个不同的虚拟流水线。因此看起来将是下面这样:
![image](https://s2.ax1x.com/2019/03/10/A9Pwrt.png)

一个任务甚至可以传递给多个执行者来并发的进行处理。例如，一个任务可以同时传递给给一个excutor和一个Logger。下图展示了三条流水线将它们的任务传递给同一个执行者来结束各自的任务:
![image](https://s2.ax1x.com/2019/03/10/A9PIaT.png)
当然流水线模型可以做得比这复杂得多。

### 交互与事件驱动的系统
使用流水线模型的系统有时也被称为交互式系统或事件驱动的系统。系统内的执行者们对于系统内发生的事件做出响应，无论是事件是来自系统之外还是来自于系统内其他的执行者。所谓事件的典型例子是HTTP请求，或者将一个文件载入内存完成。

在写这篇文章时已经有一些有趣的交互式/事件驱动的平台，未来还会有更多。这些平台包括:
- Vert.x
- Akka
- Node.Js

### Actors vs. Channels
`Actors模型`和`Channels模型`是流水线模型的两个相似的案例。

在`Actors模型`中每个执行者被叫做`Actor`。Actor相互之间可以直接发送消息。这些消息会被异步地发送和处理。Actor可以用来实现一个或多个上面讨论的流水线,如下图所示。
![image](https://s2.ax1x.com/2019/03/10/A91xcq.png)

在`Channel模型`中，执行者之间不会直接通信。相反他们会通过不同的channel来发布消息(或事件)，而不关心谁会订阅到这些消息；其他执行者可以订阅这些channel来接收消息，也不关心是谁发布了这些消息。该模型如下图所示。
![image](https://s2.ax1x.com/2019/03/10/A93B5Q.png)

一个执行者不必知道哪一个执行者接下来会继续执行任务。它只需要关心应该将任务或消息传递给哪个channel。接收消息的执行者可以订阅或取消订阅channels而不会对发布者造成任何影响。这可以降低执行者之间的耦合度。

## 流水线模型的优势
与并行执行模型相比，流水线模型有如下几个优势。

### 没有共享的状态
各个执行者之间没有共享的状态，这意味着实现每个执行者的时候，不需要考虑那些在并行执行模型中很常见的并发问题。这使得实现更加简洁，你实现一个执行者的时候可以假装它就是一个唯一的线程。

### 有状态的执行
既然每个执行者都确认不会有其他执行者来修改它自己的数据，那么一个执行者就可以是有状态的了。在这里"有状态"的意思是一个执行者可以在内存中持有它需要的数据，只把修改了的部分写回外部存储之中。因此一个有状态的执行者比无状态的执行者的执行效率要高一些。

### 更好的硬件适配性
单线程的代码还有个优势就是它通常更适配底层硬件的工作方式。

首先，当你确认代码在单线程环境下工作室，你通常可以设计更强大的数据结构和算法。

其次，单线程的有状态执行者可以向上面提到的那样在内存中持有数据。如果一段数据保存在内存中，那么同样很有可能会缓存在CPU的cache中。这可以进一步提高访问数据的速度。

我将这种更适应底层硬件工作机制的代码组织方式称为`硬件适配性`(hardware confirmity)。有些开发者将其称为`mechanical sympathy`。我更喜欢前者因为计算机很少有固定的部分，并且"sympathy"这个词在这里所暗示的"更加匹配"的意思，我觉得使用"confirm"这个词会表达地更加贴切。好吧，这都不重要，随你喜欢用哪个都行。

### 安排任务顺序是可行的
在使用流水线模型的并发系统中安排每个执行者的先后顺序是可行的。执行顺序可以确定，那么在任意时间点确认整个系统的状态也就成为了可能。此外，你可以把所有的任务都记下日志。而这份日志可以在日后系统崩溃时用于重建整个系统的状态。所有任务以一种确定的顺序写入日志，这也就是执行者顺序的保证。

保证任务的执行顺序不是一件容易的事，但是却经常会有这样的需求。如果可以，这能够大幅简化类似备份，数据恢复，数据主从复制之类的任务——所有这些同可以通过日志实现。

## 流水线模型的缺陷
流水线模型的一个缺陷在于，一个任务经常会在项目中的多个执行者以及类之间传播，因此对于一个给定的任务，很难去观察当前正在执行的究竟是哪段代码。

另外写代码或许也会更难。执行者的代码有时候会被写成回调(callback handler)形式。多层嵌套的回调被开发者们称为`回调深渊`。回调深渊很直白地说明横跨整个回调流程去追踪代码的执行位置是极其困难的。确认是否每个回调流程代码都访问了它需要的数据同样是极难的。

在并发执行模型中，做到这一点或许还简单点。你可以找到执行者的代码，从头到尾读下来。当然，并行执行模型的代码同样会使任务横跨许多不同的类，但是通常顺序执行的代码可读性更高一些。

## 函数式编程
函数式并行是近几年(2015)经常被讨论的并发模型。

该模型的基本思路是你可以通过函数调用的方式来实现程序。函数可以视为可以互相发送消息的"代理(agents)"或"参与者(actors)",就像是流水线模型中的那样。当一个函数调用其它函数时，就如同发送了一个消息一样。

传递给函数的所有参数都是拷贝值，所以一个函数无法修改该函数之外的实体的数据。这种必要的拷贝可以避免共享数据上的竞态条件。这使得函数式的执行过程就像是原子操作一样。每个函数调用相互之间都是相互独立的。

既然每次函数调用之间是互相独立的，那么它们当然可以分配给不同的CPU来并行地执行。这意味着如果一个算法是用函数式的方式实现的，那么它就可以同时在多个CPU上并行地执行。

在Java7的`java.util.concurrent`包中有一个`ForkAndJoinPool`可以帮你实现类似于函数式编程的机制。而在Java8中我们有了`streams`机制可以帮助你并行地迭代大的集合。要注意有些开发者对于`ForkAndJoinPool`持批评的态度。

函数式编程并行的难点在于确定将哪个函数并行地执行。跨多个CPU进行合作的函数会带来开销。并行执行的函数所完成的那部分任务量应该值得花费这些开销。如果一个函数很小，尝试将它们并行或许反而会比单线程单CPU执行更慢。

按照我的理解，如果你可以用函数式编程实现一个算法，那么同样也可以用流水线模型来相似的实现。使用事件驱动模型，你可以更多地控制哪些需要并行，需要什么程度的并行。

另外，只有当将被拆分的任务是程序中当前正在执行的唯一一个任务时，考虑将任务拆分并分派到多个CPU并行执行才有意义。而如果系统此时正在执行多个不同的任务(例如Web服务器，数据库服务以及其他各种任务),将一个任务拆分成并行执行是没有意义的。因为计算机内的其他CPU此时正忙于处理系统内其他的任务，所以没有理由将任务分布式的方式更低效地执行。此时你更应该考虑用流水线模型来处理，因为它的开销更小(在单线程环境下顺序地执行)并且有更好的硬件适配性。

## 哪个并发模型最好？
那么，哪个并发模型是最好的呢？

通常来说，这取决于你希望用你的系统做什么。如果你的任务天然就是并行的，每一部分都是独立的且没有共享状态，那么你或许可以使用并行执行模型。

许多任务并不是天然并行和独立的。在这种情况下我认为相比于并行模型，流水线模型可能更合适。

你不需要从底层实现流水线模型，许多现代的平台比如`Vert.x`已经帮你做了很多。
