---
title: 管理Kubernetes中的对象
date: 2019-09-14T10:51:55+08:00
tags:
- Kubernetes
categories:
- 软件工程

---

## Namespace
Kubernetes 使用命名空间来进行隔离， 每个对象只能属于其中一个命名空间， 不通的命名空间之间相互隔离。  

值得一提的是， 命名空间也会影响到`Service`的行为。 比如说， 当你在Kubernetes中的"Proxy"命名空间中创建了一个名为"Nginx"的服务， 那么此时它的全名将是`Nginx.Proxy.svc.cluster.local`， 如果一个容器仅声明了"Nginx", 那么kubernetes会将其分配在该容器所属的命名空间中。 这样一来， 你在开发，测试，生产环境中就不必一一更改环境配置了。  

然而， Kubernetes命名空间不允许嵌套， 因此这注定只能进行较粗粒度的隔离工作。 官方也不推荐使用命名空间进行细粒度的划分， 如相同应用的不同版本。  

说到底， 命名空间的设计初衷只是在多个团队使用同一个大规模的集群时， 提供一种互不打扰的方式。 而对于同一命名空间中的对象进行更细粒度的划分， Kubernetes官方推荐使用`Label`进行管理。  

## 树形划分 vs 维度划分
分类一直是人类理解处理大量复杂事务的利器。 这其中有两个典型的分类方式： 按树形划分和按维度划分。  

树形划分就如同一棵树一样， 将所有物体分为若干大类， 每个大类内的物体又分为若干小类...一直这样划分下去， 每个类别都有层次， 一个物体在同一层次只能属于一个类别。 整体看来就如同目录一样清晰分明。 科学界对生物的划分就属于这种分类， 界门纲目科属种， 层次分明， 清晰严谨。  

还有一种分类方式则不分层级， 而是给每个物体依据其特点打上不同的标签。 例如， 我们可以对一群人中的每个个体打上标签， 然后就可以通过标签方便的筛选出其中的"父亲"， "女性", "5-10岁"等不同的子集。 这种分类方式弥补了树形分类只能以物体单一属性进行分类的缺陷， 可以关注物体不同的属性，因此我将其称为"按维度划分"。   

## Label
Kubernetes提供的`Label`就是要求用户以维度划分的思想来管理统一命名空间内的多个对象, 乃至跨命名空间的对象。 为什么要用这种方式呢？ 因为设计者认为这种方式更加灵活， 可以从多个角度对目标进行管理， 减少操作次数， 从而简化管理。  

不过我个人认为， 标签虽然强大， 但是对于使用者提出了较高的要求。 如果想要如同理想情况那样管理对象， 团队成员还需要协商一套可以严格执行的标签规范， 以区分各自负责的对象而不会造成混乱 —— 也就是说， 这其实反而加大了管理的负担。 

Kubernetes的标签以键值对的形式存在。 `键`是使用/分割的前缀和键名， 二者都可以随意设定， 且前缀可以省略， 但是支持的字符集仅为[a-z,0-9 A-Z.-_]。 `值`没有前缀，其他要求和键一样。  

一个对象的标签可以在对象的`metadata`属性中指定，就像下面这样。 换句话说， 任何拥有`metadata`属性的Kubernetes对象， 都可以用标签来进行管理。 这几乎囊括了Kubernets中所有的对象。
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    this-is-a-key: this-is-a-value
    another_key:  another_value
```

## Selector
那么为对象设定了标签之后， 要怎样通过它来实现管理呢？ 这就要用到Kubernetes提供的另一个功能：`标签选择器(Label Selector)`。 每当我们要做出一个操作， 都可以在yaml文件中设置标签选择器， Kubernetes只会对那些通过了选择器筛选的对象执行操作。 

选择器也是一个键值对的列表， 每一行都是一个匹配规则， 各个规则之间是`AND`关系。 也即是说，Kubernetes会对该命名空间内所有对象的标签进行匹配， 找出满足了选择器中声明的所有匹配规则的对象。 任何一个规则不匹配， 那么就不会对该对象执行操作。   

在进行匹配时， Kubernetes会选出键相同的对象，然后再比较值。 如果都相等，则算是匹配成功。 而具体到值的指定， 有两种方案：`Equality-based`和`Set-based`, 基于相等的选择器和基于集合的选择器。 基于相等的选择器只能指定一个值， 而基于集合的选择器可以指定多个值组成一个集合， 只要对象的相同的键所对应的值位于该集合中， 就算是匹配成功。 当然， 除了相等之外， 同样也允许反向匹配， 也就是”不等于该值"或"不属于该集合"。 

说实话我个人觉得在设计方面此处的标签匹配功能强大灵活， 但是在语法设计方面有些糟糕。 没必要专门设计两个选择器， 所有的都用集合选择器就好了。 如果需要匹配单个值， 那么只需声明一个单值的集合就好。 而且既然标签不允许特殊字符， 那么使用特殊字符在选择器的值作为分隔符不是更好么而且既然标签不允许特殊字符， 那么使用特殊字符在选择器的值作为分隔符, 以这种形式声明列表不是更好么。
```yaml
selector:
- 0-key: 0-value
- a-key: value1, value2, value3
- b-key: !value
- !c-key
```
等价于:
```yaml
selector:
  matchLabels:
  - 0-key: 0-value
  matchExpressions:
  - key: a-key
    operator: In
    values:
    - value1
    - value2
    - value3
  - key: b-key
    operator: NotIn
    values:
    - value
  - key: c-key
    operator: DoesNotExist
```
