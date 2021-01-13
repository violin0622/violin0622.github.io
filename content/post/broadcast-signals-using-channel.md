---
title: 通过channel模拟信号
date: 2019-01-29T12:52:36+08:00
tags: [Golang]
categories: [编程, Golang]

---

众所周知，在Golang中创建多个goroutine后，可以使用`sync.WaitGroup`来等待多个协程全部完成。  
那么是否有一种方法，不使用这个组件也能完成相同的功能呢？  
有，那就是使用无缓存的`channel`。  

`channel`有一个特点就是，当关闭之后，不能再向内写入数据，否则会造成panic,但是依然可以从中读出数据，此时读出的数据是`channel`类型的默认值。比如`chan int`读出的就是0， `chan bool` 读出的就是false。
```go
func main(){
    chInt := make(chan int)
    chBool := make(chan bool)
    close(chInt)
    close(chBool)
    fmt.Println(<-chInt, <-chBool)
}
```
运行结果
> 0 false

<!-- more -->

注意，如果声明的是有缓存的channel，那么关闭之后会首先读出缓存里面的数据，然后才是该类型的默认值
```go
func main(){
    chInt := make(chan int, 5)
    chInt <- 1
    chInt <- 2
    close(chInt)
    fmt.Println(<-chInt, <-chInt, <-chInt)
}
```
运行结果:
> 1 2 0


既然如此，那么我们可以想到使用无缓存的`channel`来同步地控制多个协程共同启动：
```go
func main(){
    start := make(chan int)
    
    for i:=0; i<10; i++{
        go func(){
            <-start:
                fmt.Println("do something concurrently !")
        }()
    }
    
    close(start)
    time.Sleep(time.Second)
}
```
运行结果，多个协程是共同启动的:
> do something concurrently !  
do something concurrently !  
do something concurrently !  
do something concurrently !  
do something concurrently !  
do something concurrently !  
do something concurrently !  
do something concurrently !  
do something concurrently !  
do something concurrently !  
> 

当然，并不只是启动信号，也可以利用这个特性发送任何你想要广播的信号，比如休眠，退出，等等。  
另外，这个channel也可以用来作数据传输。那么如何区分读出来的是数据还是关闭信号呢？ 答案是在读出的时候判断一下第二个返回值。
```go
func main(){
   ch := make(chan int)
    for i:=0; i<10; i++{
        go func(){
            for{
                select{
                case n, ok:=<-ch:
                    if ok{
                        fmt.Println("data", n)
                    }else{
                        fmt.Println("signal",n)
                        return
                    }
                }
            }
        }()
    }
    
    ch<-0
    ch<-1
    ch<-2
    time.Sleep(time.Second)
}
```
运行结果，打印顺序是乱序的，但可以看到协程能够区分“信号”和“数据” 的区别：
> data 0  
signal 0   
signal 0  
signal 0  
signal 0  
signal 0  
data 1    
signal 0  
signal 0  
data 2   
signal 0  
signal 0  
signal 0  
>

<br/>

当然，这个特性也并不是万能的，主要的缺陷在于，
- 只能发送一个特定的信号。如果想要发送多个信号，需要使用多个`channel`。
- 只能以类似广播的方式发送信号，一次close，所有监听的goroutine都会响应。  
  例如，你创建了十个阻塞的goroutine,而只想启动其中的三个（无论是特定的三个还是任意三个），这是无法实现的。
