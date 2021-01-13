---
title: Python虚拟环境指南
date: 2019-01-27T23:39:34+08:00
tags: 
- Python
categories: [编程, Python]

---

## 安装`virtualenv`:
```bash
$pip install virtualenv
$virtualenv --version
```

## 安装 `virtualenvwrapper`:
* 如果想要使用 virtualenvwrapper的话， 不必事先手动安装 virtualenv,  pip会自动解决该依赖。
* 在windows环境下,应该安装其对应的windows版本 : `virtualenvwrapper-win`。该版本仅能在 cmd 下工作， 如果在windows上使用
  模拟Linux命令行的工具， 如 git bash , cmder 等， 则可能会造成无法正常工作。

<!--more-->

下载包:
``` bash
$pip install virtualenvwrapper
```
创建虚拟环境目录：
```bash
$mkdir .pythonenv
```
修改`.bashrc`来添加环境变量:
```bash
#!/usr/bin/bash
WORKON_HOME=$HOME/.pythonenv
source /usr/local/bin/virtualenvwrapper.sh
```
ps：如果不创建并指定`WORKON_HOME`目录的话， 加载`virtualenvwrapper.sh`时会默认创建在 `$HOME/.virtualenv`目录。  

验证是否安装成功:
```sh
$virtualenvwrapper

virtualenvwrapper is a set of extensions to Ian Bicking's virtualenv
tool. The extensions include wrappers for creating and deleting
virtual environments and otherwise managing your development workflow,
making it easier to work on more than one project at a time without
introducing conflicts in their dependencies.
···
```
## 在虚拟环境中设置环境变量
使用 **virtualenvwrapper** 时， 会自动生成 `$VIRTUAL_ENV/bin/` 目录，可以利用里面的脚本定义特定于该虚拟环境的动作，例如设定环境变量。
虚拟环境中设置的环境变量不会影响到虚拟环境外部，即使同一用户从其他终端登录并启用了另一个虚拟环境，那么在两边看到的环境变量也不会相互冲突。
对于使用环境变量来管理开发，测试，生产等多个配置的项目来说， 可以使用这种方式来来管理项目配置 —— 甚至可以在同一台服务器上同时部署开发和测试等多个环境！
```bash
$workon app
...
$vim $VIRTUAL_ENV/bin/postactivate
#!/bin/bash
# This hook is sourced after this virtualenv is activated.
export ENV=dev

$vim $VIRTUAL_ENV/bin/postactivate
#!/bin/bash
# This hook is sourced before this virtualenv is deactivated.
unset ENV
```
重新进入虚拟环境进行验证：
```bash
$deactivate
$echo $ENV

$workon app
$echo $ENV
dev
$deactivate
$echo $ENV

$
```
除了每个虚拟环境特定的设置，还可以针对用户级别的全局配置——对于该用户的所有虚拟环境生效。
方法就是编辑 **$WORKON_HOME/** 目录下的一系列脚本文件。
更多详情可见官方文档:
https://virtualenvwrapper.readthedocs.io/en/latest/scripts.html#scripts
