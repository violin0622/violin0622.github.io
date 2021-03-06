---
title: 网络安全基本概念
date: 2020-08-12T16:30:09+08:00
tags: [Security]
categories: [软件工程]

---

## 对称加密
对称加密很简单， 就是消息传递的双方共享同一个密码。 消息发送人用密码对消息进行加密， 然后将密文发给给消息接收人， 消息接受人使用此密码对密文进行解密， 然后阅读。  
优点： 计算量小， 加密效率高。  
缺点： 密码安全系数并不是特别高 （知道密码的人比较多）。  

## 非对称加密
非对称加密是指消息传递双发使用不同的密码， 两个密码分别被称为私钥和公钥。 私钥和公钥之间具备一定的数学关系： 私钥加密的内容只有对应的公钥才能解密， 公钥加密的内容只有对应的私钥才能解密。  
需要使用此加密方式的人会具备私钥和公钥， 私钥只有自己知道， 公钥则对特定群体或者所有人公开。  
优点： 安全， 私钥只有自己一个人知道， 不用担心被窃听。  
缺点： 计算量较大， 效率低， 不适合对大量内容进行加密。  

## 消息摘要(简称摘要)
使用单向哈希算法， 以任意长度的报文计算得到的固定长度的哈希值。 所谓单向是指改算法是不可逆的， 根据消息摘要无法计算出输入报文。  
消息摘要的另一个特点是： 对输入报文的任何改动， 都会导致最终的计算结果 （也就是消息摘要本身） 发生巨大的变化。 因此，消息摘要可以认为是数字信息的指纹。  
> 常见的消息摘要算法有SHA， MD5等。  

## 数字签名(简称签名)
数字签名与在纸上的物理签名效果类似——保证消息的真实性与不可伪造。 签名过程通常是消息的发送方首先生成消息报文的消息摘要， 然后使用自己的私钥对消息摘要进行加密， 加密之后的消息摘要就是消息报文的签名， 将和消息报文一起发送给消息接收方。  
如果消息接受方需要验证真伪， 首先使用消息发送方的公钥对数字签名进行解密从而得到报文消息摘要 （如果解密失败，则签名肯定有问题）。 然后使用相同的消息摘要算法重新计算接受到的消息报文的消息摘要， 如果计算得到的消息摘要与解密得到的消息摘要不一致， 则消息报文被人篡改。  

## 数字证书(简称证书)
数字证书类似网上身份证， 由第三方权威机构签发， 用于鉴别证书持有人的身份的真实性。 数字证书上包含了证书持有人的基本信息 （如：网站域名、 邮箱地址等）、 证书持有人的公钥、 证书颁发机构信息、 证书颁发机构的数字签名以及证书有效期。  
数字证书的申请过程通常是： 证书申请人向证书签发机构提交申请， 申请中包含申请人身份的基本信息以及申请人公钥。 证书签发机构通过各种手段核实申请来源以及申请信息的真实性。 核实通过之后， 真实签发机构向申请人签发数字证书。  
证书签发机构也有一个证书， 其中包含了证书签发机构的公钥。 任何人都可以获得该证书， 并使用此证书来验证该机构签发的所有证书的真伪。 默认情况下， 大多数操作系统内已经内置了全球知名证书签发单位的根证书。  
