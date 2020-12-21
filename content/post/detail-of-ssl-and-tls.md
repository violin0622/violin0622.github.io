---
title: SSL/TLS的工作原理
date: 2020-08-13T15:26:47+08:00
tags: [SSL/TLS]
categories: [软件工程]
Mermaid: true

---

## 网络通信过程中可能遇到的风险与应对
网络通信过程中的数据安全将要面临三个风险:
1. 窃听风险(eavesdropping)
2. 篡改风险(tampering)
3. 冒充风险(pretending)

为了应对这三个风险， SSL/TLS 协议包含如下机制：
### 1. 信息使用密钥加密， 使第三方无法窃听。  
但是通信双方加密传播数据， 就需要在通信之前先交换密钥， 而交换密钥的过程如果使用明文， 则密钥本身有可能被窃听， 从而导致通信数据也有了被窃听的风险。  

解决方案是借助非对称加密来交换通信密钥。 令服务器拥有私钥和公钥， 服务器把自己公钥明文地发给客户端， 客户端接着生成一个密钥， 然后拿公钥加密这个密钥， 将加密后的密钥返回给服务器， 此时该密钥只有服务器端的私钥能够解密，从而完成了通信密钥的加密传输。  公钥一般放在证书中。  

在实际应用中， 通常是在TLS握手阶段由客户端和服务端共同生成并交换两个明文的随机数， 再由客户端生成一个密文随机数并使用公钥加密传递给服务端， 最后双方使用相同的摘要算法对三个数计算出真正的通信密钥。  

### 2. 具有校验机制， 第三方无法篡改， 或已经篡改立刻发现。 
一般来说， 通过在发送数据时附带摘要， 即可令接收方辨别数据被篡改。  

但是摘要本身也是可以被篡改的， 因此摘要本身也需要被加密， 可以将摘要附在数据的后面一起被加密， 接收端解密之后再次将数据计算摘要并与发送端附带的摘要进行比对， 即可知道数据是否被篡改过。  

### 3. 身份验证， 第三方无法冒充。 
身份验证使用的就是证书机制， 而颁发证书的机构就是CA机构。  
证书的工作机制比较复杂， 基本思想是引入一个权威的第三方为通信双方的身份做担保。（这个第三方不是指窃听数据的第三方。）  
如果客户端需要保证服务器没有被冒充， 那么服务器需要向客户端提供证书以供其验证， 这种模式叫做单向验证； 如果通信双方都需要保证对方没有被冒充， 则需要互换证书各自验证， 称为双向验证。  
证书中有几个基本信息:  
- 颁发者。 也就是上一级CA
- 受发者。 也就是申请证书的人， 通常是一个域名或通配符域名。 
- 有效期。 
- 公钥。 公钥是服务端密钥对的其中之一， 客户端收到证书并验证成功后， 用此公钥加密`第三个随机数`以交换通信密钥。 
- 摘要算法。 用于指示证书签名使用的摘要算法。  

#### 申请证书
假设有一个权威的认证机构CA， 服务端想要让客户端认证自己的身份， 需要将自己的证书名和公钥提交给CA供其审核。 CA自身带有一对公钥和私钥， 审核通过后， 会使用自身的私钥加密服务端提交证书的摘要（称为`签名`）， 将签过名的证书发还给服务端。  

#### 交换、验证证书
既然CA是权威的， 那么客户端可以信任该CA， 并保存CA的公钥(例如， 浏览器会内置很多可信的CA机构的证书)。 在TLS握手阶段， 服务端会将证书发送给客户端， 客户端拿到证书检查颁发人， 找出本地保存的对应CA的公钥， 使用该公钥对证书的签名进行解密， 比对证书的明文内容和签名解密出的摘要是否一致。 如果一致则认为验证通过。 如果是双向认证， 则客户端也会将自身证书发向服务端， 服务端执行同样的验证。   

#### 证书链
世界公认权威的CA（根证书的拥有者）是有限的， 而需要验证的客户端是无限的， 如果要一一审核太慢了。 因此基于“我信任你， 你信任他， 因此我信任他”的信任传递原则， 有了证书链机制。 

![浏览器中的证书链](/image/posts/证书链.png)
<center style="font-size:14px;color:#C0C0C0;text-decoration:underline">本站的证书链</center> 
  
假设客户端添加了权威CA的根证书， 权威CA签发了二级CA， 二级CA签发了三级网站。 客户端与服务端网站通信时， 如果服务端只发送自身的网站证书， 则客户端只能找到颁发者二级CA， 而由于其没有信任二级CA（没有保存二级CA的公钥）， 从而无法完成验证。 因此客户端需要发送自身的证书， 以及签发者二级CA的证书。 客户端先验证网站证书是否由二级CA签发， 再验证二级CA的签发人， 直到发现某一级证书的签发人是自己信任的， 从而完成了证书验证。 如果走完证书链也没有发现可信任的签发人， 则认为该证书是不可信的[^1]。 

- 防伪造： 未经过CA验证的不法网站可以使用假的证书， 但由于客户端没有信任假证书的CA， 因此无法通过验证。 
- 防篡改： 签名比对机制杜绝了证书交换过程中被第三方篡改。 
- 防冒充： 钓鱼网站可以使用服务端公开的证书冒名顶替， 但是因为没有私钥， 因此无法解密客户端发送的数据。 

## SSL/TLS 基本的运行过程
在建立链接阶段总体的流程如下：  
1. 客户端向服务器索要并验证公钥
2. 双方协商生成“对话密钥”
3. 双方采用“对话密钥”进行加密通信

TLS 报文的格式
TLS报文自身分为两层: `Record层`和`负载层`. Record层的结构比较简单, 就是TVL格式:
- Content Type: 用于声明负载层的类型. 对于握手报文, 就是`Handshake(22)`, 对于数据报文, 就是`Application Data(23)`, 对于加密变更声明, 就是`Change Cipher Spec(20)`, 对于报警, 就是`Alert(21)`.
- Version: 协议的版本, 现在比较常用的就是 `TLS 1.0`, `TLS 1.1`, `TLS 1.2`, `TLS 1.3`.
- Length: 负载层的长度, 字节为单位.

对于一个典型的TLS握手过程, 双方总共会按顺序通信如下请求:

1. Client Hello
1. Server Hello
1. Server Certificate
1. Server Key Exchange
1. Certificate Request
1. Server Hello Done
1. Client Certificate
1. Client Key Exchange
1. Change Cipher Spec
1. Encrypted Handshake Message
1. Change Cipher Spec
1. Encrypted Handshake Message
1. Application Data

在没有回话复用, 单TCP包仅承载单个TLS请求的情况下, 双方的通信过程是这样的:


{{< mermaid >}}

sequenceDiagram
  participant client
  participant server

  client ->> + server: Client Hello
  server -->> - client: TCP Ack
  server ->> + client: Server Hello
  client -->> - server: TCP Ack
  server ->> + client: Server Certificate
  client -->> - server: TCP Ack
  opt RSA/DN/ECHD/ 等算法不会发送
    server ->> + client: Server Key Exchange
    client -->> - server: Tcp Ack
  end
  client ->> client: 验证服务端的证书/证书链
  alt 双向认证
    server ->> + client: Certificate Request
    client -->> - server: Tcp Ack
    server ->> + client: Server Hello Done
    client -->> - server: Tcp Ack
    client ->> + server: Client Certificate
    server -->> - client: TCP Ack
    server ->> server: 验证客户端的证书/证书链
  else 单向认证
    server ->> + client: Server Hello Done
    client -->> - server: Tcp Ack
  end
  client ->> + server: Client Key Exchange
  server -->> - client: TCP Ack
  client ->> + server: Change Cipher Message
  server -->> - client: TCP Ack
  client ->> + server: Encrypted Handshake Message
  server -->> - client: TCP Ack
  server ->> + client: Change Cipher Message
  client -->> - server: TCP Ack
  server ->> + client: Encrypted Handshake Message
  client -->> - server: TCP Ack

  loop 开始传输数据
    server ->> + client: Application Data
    client -->> - server: TCP Ack
  end

{{< /mermaid >}}

实际上, TLS握手的时候, 客户端与服务端双方会根据情况将多个TLS报文压缩到一个TCP数据包中, 因此在使用Wireshark抓包时经常看到一个数据包中有多个TLS报文.  

### Client Hello
客户端向服务端发送加密通信的请求，称作 `ClientHello请求` 。该请求使用明文传输。  
ClientHello请求将向服务端提供以下信息：  
- Version:  
  客户端支持的最高加密协议版本
- Random:  
  客户端生成的随机数random_C， 用作`对话密钥`.
- Session Id & Session Length:
  会话ID. 会话ID由服务端生成, 并在Server Hello中告知客户端. 如果是第一次建立链接, 会话ID为0; 如果是短时间内再次建立连接, 会使用上次的会话ID. 
- Cipher Suites & Cipher Suites Length:  
  客户端支持的加密套件列表, 服务端会从中选出一个用于之后协商过程使用的套件. 
- Compression Methods & Compression Methods Length:  
  客户端支持的压缩方法. 目前没有用上, 一般留作空.  
- Extention & Extentions Length:  
  扩展字段. 包括会话复用在内的很多TLS的高级功能通过扩展字段来实现.  Extentions Length 是倒数第二个字段, 标识了扩展字段列表的长度(字节). 然后就是连续若干项Extention字段的列表.  

客户端发送的信息之中不包括服务器的域名。 也就是说， 理论上服务器只能包含一个网站， 否则会分不清应该向客户端提供哪一个网站的数字证书。 这就是为什么通常一台服务器只能有一张数字证书的原因。

### Server Hello
服务端使用明文向客户端发送请求，内容包括:  
- Version:  
  服务端选择的双方协商使用的加密协议版本. 一般会选择客户端服务端都支持的最高的版本.
- Random:  
  服务端生成的随机数 random_S, 用于生成`对话密钥`. 
- Session ID & Session ID Length:  
  服务端生成的会话ID, 或上一次链接时使用的会话ID.  
- Cipher Suite:  
  服务端从客户端提供的加密套件列表中选择一个, 告知客户端.  
- Compression Method:  
  服务端从客户端提供的压缩算法中选择一个告知客户端. 不过现在客户端一般留空, 服务端没得选, 也只能返回空.  
- Extention & Extention Length:  
  具体作用未知.

### Server Certificate
服务端向客户端发送自身的证书, 明文传输.
- Certificate Length:  
  证书长度(字节).
- Certificates:  
  证书链.  

### Server Hello Done
没有信息, 负载为空

### Client Key Exchange
客户端收到证书后会验证证书。 如果证书不是可信机构颁布、 或者证书中的域名与实际域名不一致、 或者证书已经过期， 就会向访问者显示一个警告， 由其选择是否还要继续通信。
如果证书没有问题， 客户端就会从证书中取出服务器的公钥。 然后， 向服务器发送Client Key Exchange. 这个请求使用单独的类型, Content-Type是`Client Key Exchange(16)` 

- PubKey:  
  随机数 Pre-Master. 这个数字是使用服务端的公钥加密过的. 是协商密钥过程中唯一真正加密通信的数据.

客户端会根据通信过程中双方生成的三个随机数， 使用约定的加密方法生成真正的会话密钥。 
服务端收到报文后, 通过之前通信过程中生成的三个随机数 random_C, random_S, Pre-Master, 生成真正的会话密钥。 

### Encrypted Handshake Message & Change Cipher Spec
服务端和客户端在各自计算出真正的会话密钥后, 会向对方发送一个 Change Cipher Spec 报文, 该报文没有负载信息, 只是告知对方自己接下来要发送的报文都将使用密钥加密.  
然后再向对方发送一个 Encrypted Handshake Message, 里面的负载是之前双方协商过的信息的哈希值, 但此次使用密钥加密负载. 双方收到对方发来的加密报文后, 解密并比对自身数据作为最后验证. 如果比对不一致则报错停止此次握手, 如果一致则TLS链接成功建立.  

### Application Data
TLS链接建立后双方通信的TLS报文都是Application Data.

--- 
[^1]: 参考 [https://blog.csdn.net/mrpre/article/details/77867063](https://blog.csdn.net/mrpre/article/details/77867063)
 
