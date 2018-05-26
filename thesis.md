# Introduction

**To do**

# Background

## Java Programming Language

The Java programming language was originally developed by Sun Microsystems under the name Oak in 1991 [@Oracle2015].
Oak was designed to be processor-independent and should be used in consumer electronics such as TV set-top boxes. 
In 1992 the industry had little interest in Oak, so the developers switched to bringing the language to the internet. 
The WebRunner browser was released in 1994, being the first browser supporting moving objects and dynamic executable content by supporting Oak.
Due to trademark issues Oak was renamed to Java in 1995.
In the same year the developers of the Netscape Navigator browser announced that they will include Java support. 
The first version of Java was then released in 1996.

Today Java is primarily used in server applications and the mobile operating system Android, but can also be used for developing regular desktop applications [**citation needed**].

The wide adoption of Java can be explained by it being mostly platform independent [**citation needed**]. Java programs does not run directly on hardware, but on a *Java Virtual Machine* (JVM), so Java can be run on any platform that has a JVM available.

## Java Platform Module System

The Java Platform Module System (JPMS) -- also popular under its working name Jigsaw -- was the recent addition to the Java platform in version 9.
JPMS adds *modules*, which are identifiable artifacts containing code, to the Java language [@Mac2017].

Modularizing the *Java Development Kit* (JDK) was initially proposed in 2014 and planned to be released with Java 7 [@Reinhold2017].
The motivation of the proposal was to allow scaling the JDK down to smaller devices by making the Java platform configurable to include only required modules for applications.

JPMS makes three principles, that before were only best practices, explicit [@Mac2017]:

* By using *strong encapsulation* parts of libraries can be hidden from other modules.
  This clearly separates code that is part of a public application programming interface (API) and code that is intended for internal use only.
  Consequently internal code can also change freely without worrying about backwards compatibility.
* Strong encapsulation also leads to *well-defined interfaces*.
  By having to explicitly declare code that is intended for external usage, maintainers of libraries have to handle their API with great care, as changing this code can also break modules depending on it.
* Modules also require *explicit declaration of dependencies* to use other modules.
  From this declaration a module graph can be derived, where nodes represent modules and edges represent dependencies.
  A module graph is important for understanding an application and also running it with all necessary modules.
  It also allows for reliable configuration of the modules.

## JabRef Bibliography Manager

JabRef is an open source bibliography reference manager using the standard LaTeX bibliography format BibTex as its native file format.
The project is hosted on GitHub^[https://github.com/JabRef/jabref] and currently has over 200 contributors and around 140,000 lines of Java code.

**More info on JabRef: Begin of development? Wide adoption. JabRef Survey? etc.**

# Migrating JabRef to Java 9

The following section covers the process of migrating JabRef from Java 8 to Java 9. 
Due to the open source nature of JabRef development of the project continued during the migration phase.
Therefore the migration was done in an iterative approach and changes to the current version were continuously synchronized to the Java 9 version.

## Compile-Time Compatibility

In the first iteration the focus lay on ensuring compile-time compatibility with Java 9.
Incompatible parts of JabRef were temporarily removed.

A number of external libraries were incompatible with Java 9 and also had to be removed.
The incompatibilities of these libraries can be categorized into the following categories:

Libraries with *split packages* are two or more libraries that export the same package.
Split packages across libraries cause errors such as the one shown in [@lst:split-pkg-err].

```{#lst:split-pkg-err caption="Compiler error on split packages"}
error: the unnamed module reads package com.sun.star.security from both unoil and ridl
error: the unnamed module reads package com.sun.star.task from both unoil and ridl
error: the unnamed module reads package com.sun.star.util from both unoil and ridl
error: the unnamed module reads package com.sun.star.script from both unoil and ridl
error: the unnamed module reads package com.sun.star.uno from both jurt and ridl
```

```{#test .java caption="asdf fdsa"}
open module org.jabref {
  requires com.google.common;
}
```

**To do**

# Conclusion

**To do**

# References