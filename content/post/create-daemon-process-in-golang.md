---
title: 使用Golang创建守护进程
date: 2020-08-13T15:07:00+08:00
tags: [Golang]
categories: [编程]

---

```golang
package main
 
import (
    "os"
    "fmt"
    "os/signal"
    "syscall"
    "time"
    "log"
    "os/exec"
)
func init() {
    // 如果本进程的父进程不是init进程, 则
    // 创建与本进程相同的子进程, 然后退出, 使
    // 子进程被init进程接管, 从而创建了守护进程. 
    if os.Getppid() != 1{
        cmd := exec.Command(os.Args[0], os.Args[1:]...)
        cmd.Start()
        os.Exit(0)
    }
 
    // 监听系统信号
    go func() {
        _c := make(chan os.Signal, 1)
        signal.Notify(_c, 
            os.Interrupt, 
            syscall.SIGHUP, 
            syscall.SIGINT, 
            syscall.SIGTERM, 
            syscall.SIGQUIT, 
            syscall.SIGKILL, 
            syscall.SIGTSTP
        )
        msg := <- _c
        log.Println(msg)
        os.Exit(0)
    }()
}
 
func main()  {
 
    go func(){
        fp, _ := os.OpenFile("log", os.O_WRONLY|os.O_CREATE|os.O_APPEND, 0644)
        log.SetOutput(fp)
        for{
            log.Println(fmt.Sprint("hello ", os.Getpid()))
            time.Sleep(time.Second * 5)
        }
    }()
    
    for{
        time.Sleep(time.Second * 1000)
    }
}
```
