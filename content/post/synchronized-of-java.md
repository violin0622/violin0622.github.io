---
title: Java的Synchronized关键字
date: 2021-01-08T15:00:10+08:00
tags: [并发编程, Java]
categories: [编程, Java]
type: 文档

---
[toc]

Synchronized 关键字是 Java 中进行并发控制的基础。通过 Synchronized 修饰一段代码块，从而将这段代码标记为临界区，以便控制其中代码互斥地执行。

Synchronized 关键字的用法很多，既可以用来修饰一个函数，也可以单独修饰一段代码块；既可以在静态函数中使用，也可以在普通函数中使用。 但是无论怎么使用，其机制却都是一样的。理解 synchronized 作用的重点是要知道它需要指定一个对象作为锁，使用相同对象作为锁的所有 synchronized 代码，都会互斥地执行，使用不同对象的作为锁的 synchronized 代码，可以并发地执行。

## 基本用法
Synchronized 最基本的用法是这样：
![[basic-java-synchronized-usage]]
```java
public class SyncDemo{
  private Object lock = new Object(); 
  void foo(){
    synchronized(lock){
      System.out.println("Hello world");
    }
  }
}
```
synchronized 通过括号指定一个对象作为锁，将内部的代码块锁定，不能被多个线程同时执行。  

## synchronized 使用对象作为锁
要注意， synchronized 关键字后跟的括号内，必须是一个已经初始化的对象，相当于将这个对象当作是一个锁。 如果多个不同的代码块关联到同一个对象上， 那么这多个代码块共享一个锁，也就是多个代码块不能同时执行，同一时刻只能执行其中一段，直到这段代码退出，其他线程才能再次执行相同的代码块或其他使用相同对象锁定的代码块。  
看这个例子： 
```java
// 使用 java 11 编写。
// 两个线程分别执行 foo bar，而这两个函数都
// 用 synchronized 关键字关联到同一个 lock 对象。
public class SyncDemo {
  private static Object lock = new Object();

  static void foo(){
    System.out.println("Foo started.");
    synchronized(lock){
      System.out.println("Foo in");
      try{
        Thread.sleep(1000);
      }catch(InterruptedException e){
          e.printStackTrace();
      }
      System.out.println("Foo out");
    }
  }

  static void bar() {
    System.out.println("Bar started.");
    synchronized(lock){
      System.out.println("Bar in");
      try{
        Thread.sleep(1000);
      }catch(InterruptedException e){
          e.printStackTrace();
      }
      System.out.println("Boo out");
    }
  }

  public static void main(String[] args){
    var t1 = new Thread(SyncDemo::foo);
    var t2 = new Thread(SyncDemo::bar);
    t1.start();
    t2.start();

    while(t1.isAlive() || t2.isAlive());
  }
}

```

执行会产生如下结果:  
```shell session
$java SyncDemo.java
Foo started.
Foo in
Bar started.
Foo out
Bar in
Boo out      
```
可见 Foo，Bar 在两个线程中近乎同时启动，Foo 抢到了锁，先执行同步代码块， 而 Bar 只能等 Foo 执行完了之后再执行。 可见虽然是不同的代码块，但因为 synchronized 关联到同一个对象作为锁，因此也只能串行执行。


## 使用当前对象作为锁
有时候，synchronized 关键字可以直接以对象自身作为锁：  
```java
public class SyncDemo{
  void foo(){
    synchronized(this) {
      System.out.println("Hello world");
    }
  }
}
```
不用专门创建一个对象作为锁，看起来方便了很多。不过要注意的是，这样的方式声明的 foo 函数并不是全局同步的，而是每个 SyncDemo 对象各自同步。如果有两个 SyncDemo 分别在两个线程中调用 foo，那么不会发生互斥，而是会各自执行。
比如下面的代码:  
```java
public class SyncDemo{
  void foo(){
    synchronized(this){
      System.out.println("sleep: " + Thread.currentThread().getName());
      try{
        Thread.sleep(1000);
      }catch(InterruptedException e){
        e.printStackTrace();
      }
      System.out.println("awake: " + Thread.currentThread().getName());
    }
  }
  public static void main(String[] args){
    var sd1 = new SyncDemo();
    var sd2 = new SyncDemo();
    var t1 = new Thread(sd1::foo, "t1");
    var t2 = new Thread(sd2::foo, "t2");
    t1.start();
    t2.start();

    while(t1.isAlive() || t2.isAlive());
  }
}
```
执行结果是这样：  
```shell session
sleep: t1
sleep: t2
awake: t1
awake: t2
```
两个线程 t1 t2 是同时陷入休眠，同时苏醒，说明两个线程的 foo 是并发执行的。

## 使用类对象作为锁
如果想要全局同步的话，可以这样写:  
```java
public class SyncDemo{
  void foo(){
    synchronized(SyncDemo.class) {
      System.out.println("Hello world");
  }
}
```
JVM 在加载 SyncDemo 类的时候，会为这个类创建一个 java.lang.Class 的对象，我们假设该对象名为 SyncDemoClassObject（实际上不是）。SyncDemoClassObject 可以通过 SyncDemo 类型的 `.class` 属性，或者将 SyncDemo 类实例化之后通过实例对象的 `.getClass()`方法访问。这样以来， `synchronized(SyncDemo.class)` 实际上是以 SyncDemoClassObject 作为锁。 SyncDemoClassObject 是全局唯一的， 从而以此为锁的 foo() 方法也可以做到全局互斥。


## 直接作为函数修饰符
有时候，如果整个函数都需要互斥执行，那么可以这样写:  
```java
public class SyncDemo{
  synchronized void foo(){
    System.out.println("Hello world");
  }
}
```
这实际上算是一种语法糖，此时该函数会以对象本身作为锁。也就是和下面的代码等价:  
```java
public class SyncDemo{
  void foo(){
    synchronized(this) {
      System.out.println("Hello world");
    }
  }
}
```

## 与 static 关键字配合使用
synchronized 与 static 关键字可以配合使用，并且其机制依然不变：一定需要关联一个实例对象作为锁。
当 synchronized 修饰静态函数时，由于类尚未实例化，this指针没有指向具体对象，因此不会使用 this 作为锁，而是转而使用 SyncDemoClassObject 作为锁。此时全局的 foo 函数都互斥执行。
```java
public class SyncDemo{
  static synchronized void foo(){
    System.out.println("Hello world");
  }
  // foo bar 两种方式是等价的
  static void bar(){
    synchronized(SyncDemo.class){
      System.out.println("Hello world");
    }
  }
}
```

## 不要将 synchronized 绑定在基础类型上
鉴于 JVM 对于基础类型的实现方式，不同基础类型的对象如果其值相同，那么很有可能指向相同的内存对象。因此看起来互不相关的两段同步代码，可能会使用同一个对象而互斥执行，进而影响其性能。
例如下面的代码：  
```java
import static com.pivovarit.function.ThrowingRunnable.unchecked;

public class SyncDemo {
  Integer i1 = Integer.valueOf(1);
  Integer i2 = Integer.valueOf(1);
  void foo() throws InterruptedException{
    synchronized(i1) {
      System.out.println("sleep: " + Thread.currentThread().getName());
      Thread.sleep(1000);
      System.out.println("awake: " + Thread.currentThread().getName());
    }
  }
  void bar() throws InterruptedException{
    synchronized(i2){
    System.out.println("sleep: " + Thread.currentThread().getName());
    Thread.sleep(1000);
    System.out.println("awake: " + Thread.currentThread().getName());
    }
  }

  public static void main(String[] args){
    var sd1 = new SyncDemo();
    var sd2 = new SyncDemo();
    var t1 = new Thread(unchecked(sd1::foo), "t1");
    var t2 = new Thread(unchecked(sd2::foo), "t2");
    t1.start();
    t2.start();

    while(t1.isAlive() || t2.isAlive());
  }
}
```
执行后的结果是：  
```shell session
$java -cp ./throwing-function-1.5.1.jar SyncDemo.java
sleep: t1
awake: t1
sleep: t2
awake: t2
```
可以看到两个线程实际是串行执行的。 这是因为 i1 和 i2 因为其值相同， 而指向了相同的对象。有这种情况的还有其他基本类型的封装类型，以及String类型。 

## synchronized 是可重入锁
可重入锁的含义是当一个线程内的调用链上有多个函数尝试获取同一把锁时， 可以不用再次抢占。最典型的应用场景是在递归函数中，如果不用重入锁，当父函数获取了锁并调用子函数，子函数再次尝试获取锁，于是造成死锁。 而 Java 的 synchronized 关键字修饰的代码块使用重入锁，从而避免了死锁。 
```java
import static com.pivovarit.function.ThrowingRunnable.unchecked;

public class SyncDemo {
  void foo() throws InterruptedException{
    var name = Thread.currentThread().getName();
    synchronized(SyncDemo.class) {
      System.out.println("sleep: foo " + name); 
      Thread.sleep(1000);
      bar();
      System.out.println("awake: foo " + name);
    }
  }

  void bar() throws InterruptedException{
    var name = Thread.currentThread().getName();
    synchronized(SyncDemo.class){
      System.out.println("sleep: bar " + name);
      Thread.sleep(1000);
      System.out.println("awake: bar " + name);
    }
  }

  public static void main(String[] args){
    var sd1 = new SyncDemo();
    var sd2 = new SyncDemo();
    var t1 = new Thread(unchecked(sd1::foo), "t1");
    var t2 = new Thread(unchecked(sd2::bar), "t2");
    t1.start();
    t2.start();

    unchecked(t1::join);
    unchecked(t2::join);
  }
}
```
执行结果如下:  
```shell session
$java -cp ./throwing-function-1.5.1.jar SyncDemo.java
sleep: foo t1
sleep: bar t1
awake: bar t1
awake: foo t1
sleep: bar t2
awake: bar t2
```
可以看出 t1 内的 foo 函数先抢占了锁，然后调用 bar ，由于在同一个线程内， bar 可以直接执行，此时相当于 t1 内的 foo 和 bar 都持有该锁。不过由于两个函数在同一个线程内，线程内的代码串行执行，因此不会出现「竞态条件」。 当 t1 的 bar 执行完成后返回， t1 内的 foo 继续执行到结束退出。 直到此时 t1 才释放了锁，从而 t2 开始执行 bar。
