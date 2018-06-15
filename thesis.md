# Introduction

**To do**

# Background

## Java Programming Language

The Java programming language was originally developed by Sun Microsystems under 
the name Oak in 1991 [@Oracle2015].
Oak was designed to be processor-independent and should be used in consumer 
electronics such as TV set-top boxes. 
In 1992 the industry had little interest in Oak, so the developers switched to 
bringing the language to the internet. 
The WebRunner browser was released in 1994, being the first browser supporting 
moving objects and dynamic executable content by supporting Oak.
Due to trademark issues Oak was renamed to Java in 1995.
In the same year the developers of the Netscape Navigator browser announced that
they will include Java support. 
The first version of Java was then released in 1996.

Today Java is primarily used in server applications and the mobile operating 
system Android, but can also be used for developing regular desktop 
applications.

The wide adoption of Java can be explained by it being mostly platform 
independent. Java programs does not run directly on hardware, but on a 
*Java Virtual Machine* (JVM), so Java can be run on any platform that has a 
JVM available.

## Java Platform Module System {#sec:jpms}

The Java Platform Module System (JPMS) -- also popular under its working name 
Jigsaw -- was the recent addition to the Java platform in version 9.
JPMS adds *modules*, which are identifiable artifacts containing code, to the 
Java language [@Mac2017].

Modularizing the *Java Development Kit* (JDK) was initially proposed in 2014 
and planned to be released with Java 7 [@Reinhold2017].
The motivation of the proposal was to allow scaling the JDK down to smaller 
devices by making the Java platform configurable to include only required 
modules for applications.

JPMS makes three principles, that before were only best practices, explicit 
[@Mac2017]:

* By using *strong encapsulation* parts of libraries can be hidden from other 
  modules.
  This clearly separates code that is part of a public application programming 
  interface (API) and code that is intended for internal use only.
  Consequently internal code can also change freely without worrying about 
  backwards compatibility.
* Strong encapsulation also leads to *well-defined interfaces*.
  By having to explicitly declare code that is intended for external usage, 
  maintainers of libraries have to handle their API with great care, as changing
  this code can also break modules depending on it.
* Modules also require *explicit declaration of dependencies* to use other 
  modules.
  From this declaration a module graph can be derived, where nodes represent 
  modules and edges represent dependencies.
  A module graph is important for understanding an application and also running 
  it with all necessary modules.
  It also allows for reliable configuration of the modules.

Before Java 9 visibility of code could be restricted to classes not being
visible from different packages and methods and fields of classes not being
visible to different classes.
JPMS now allows to restrict the visibility of entire packages to different 
modules by explicitly declaring the packages that should be accessed by other
modules.
This is done with a so called module descriptor as shown in [@lst:module-desc], 
that is required to be declared in a file called `module-info.java` in the root
package of the module.

```{#lst:module-desc .java caption="Module descriptor"}
module com.company.module {
    exports com.company.module.api;
    exports com.company.module.cli;
    exports com.company.module.gui;

    opens com.company.module.api.feature;

    requires org.thirdparty.module;
    requires transitive org.provider.othermodule;

    uses org.thirdparty.module.Service;

    provides com.company.module.api.Service
        with com.company.module.api.impl.ServiceImpl;
}
```

In this example the module `com.company.module` is declared. It allows access
from other modules to its packages `com.company.module.api`, 
`com.company.module.cli` and `com.company.module.gui`. 
Note however that although Java packages seem to appear hierarchical, they are
treated like regular identifiers, so if access to subpackages of any of the
above packages should be allowed, they would have to be explicitly be exported.
The example module further "opens" the package `com.company.module.api.feature`
to reflective access from other modules.
It then declares its dependencies on `org.thirdparty.module` and 
`org.provider.othermodule`, with the second dependency being declared as
transitive dependency. This means that the module also depends on all 
dependencies of `org.provider.othermodule`.
The last two declarations identify that the module uses a service
`org.thirdparty.module.Service` provided by some other class and implements a
service `com.company.module.api.Service` with the class 
`com.company.module.api.impl.
ServiceImpl` for usage by other modules. This
declaration of services was already a feature of Java before version 9, but
relied on a fragile configuration using text files.

Since such a module descriptor is a feature of Java 9, it also needs to be
compiled with a Java 9 compiler or later. 
However, due to the nature of the Java platform projects can not be run with a 
previous version of Java than they were compiled with.
This is unfavorable especially for developers of libraries, as for them 
upgrading to Java 9 would force all consumers of their library to upgrade to
Java 9.
For such a use-case an alternative method to declare a module is implemented in
JPMS: The attribute `Automatic-Module-Name` can be declared in an Java 
artifact's manifest to set at least a module name.
The module is then used as a so called automatic modules, which depends on all
other available modules and exports all its packages.
If even such an attribute is not provided, JPMS resorts to interpreting the
filename of the artifact as a module name.

## JabRef Bibliography Manager

JabRef is an open source bibliography reference manager using the standard LaTeX
bibliography format BibTex as its native file format.
The project is hosted on GitHub^[https://github.com/JabRef/jabref] and currently
has over 200 contributors and around 140,000 lines of Java code.

**More info on JabRef: Begin of development? Wide adoption. JabRef Survey? etc.**

# Migrating JabRef to Java 9

The following section covers the process of migrating JabRef from Java 8 to 
Java 9. 
Due to the open source nature of JabRef development of the project continued 
during the migration phase.
Therefore the migration was done in an iterative approach and changes to the
current version were continuously synchronized to the Java 9 version.

## Compile-Time Compatibility

In the first iteration the focus lay on ensuring compile-time compatibility with
Java 9.
Incompatible parts of JabRef were temporarily removed.

A number of external libraries were incompatible with Java 9 and also had to be 
removed.
The incompatibilities of these libraries can be categorized into the following 
categories.

### Split Packages

Libraries with *split packages* are two or more libraries that export the same 
package as shown in [@fig:split_packages].
Here, both modules export the packages `splitpackage` and 
`splitpackage.internal`. 

![Two modules containing the same packages but different classes [@Mac2017]](images/split_packages.svg){#fig:split_packages}

JPMS allows only one module to export a given package to another module 
[@Mac2017].
If split packages were allowed, this would lead to inconsistencies in the
encapsulation, as Java has a special visibility level for classes in the same
package.
It also could become unclear which class should be used, if two modules contain
classes with the exact same fully qualified name.

Split packages across libraries cause runtime or compile-time errors such as the 
one shown in [@lst:split-pkg-err].

```{#lst:split-pkg-err .c caption="Compiler error on split packages"}
error: the unnamed module reads package splitpackage from both module.one 
and module.two
error: the unnamed module reads package splitpackage.internal from both
module.one and module.two
```

The solution for the first iteration of the migration was to simply remove the
dependencies with split packages and disable the features of JabRef using them.

### Internal API Access

Java's JDK consists of the public API but also some internal parts that should
only be used by the JDK itself [@Clark2017].
Oracle has warned developers repeatedly that no guarantee is given that the
internal parts of the JDK stay available in future versions and can change 
without further announcement.

With Java 9 this announcement is now implemented, as the modules of the JDK now
simply only export the publicly available API and not the internal APIs.
While Java 9 still provides the possibility to explicitly make the internal APIs
available with command line switches like `--add-exports`, the only long-term
solution is to move away from those APIs and find supported replacement 
solutions.

JPMS also requires modules to explicitly declare "open" packages that can be 
used with Java's reflection mechanism. 
This behavior can also be circumvented with the appropriate `--add-opens` 
command line flag.

JabRef did only make use of internal APIs at few occurrences, but uses third
party libraries such as Google's Guava that make extensive use of reflection
into other modules.
Some of the used libraries also depended on JDK APIs that are no longer 
publicly accessible.

For the first iteration the access to internal APIs from third party libraries
was allowed using the available command line switches.
The problem of other modules using reflection to access JabRef was solved by
declaring the newly added `org.jabref` module as an *open module* 
(see [@sec:module-descriptor]). 
This allows all reflective access into JabRef from any module.

### Module Names

As mentioned in [@sec:jpms] if no module descriptor and no 
`Automatic-Module-Name` is declared, JPMS tries to derive a module name from the
filename of the artifact.
However, JPMS also places some restrictions on module names, so they have to be
a valid Java identifier and thus can only contain letters, numbers, underscores
and the dollar sign in addition to dots, but may not start with numbers after a
dot.
JPMS replaces dashes and underscores with dots in the name.

JabRef uses several Scala dependencies, which follow the default Scala naming
scheme consisting of the name of the project followed by an underscore followed
by the Scala version.
So an artifact with the name `latex2unicode` for Scala 2.11 results in an 
artifact with the name `latex2unicode_2.12`. 
As a module with no module descriptor and no automatic module name, its name is 
interpreted to be `latex2unicode.2.12`, which is invalid as the 2 directly 
follows a dot.

The Scala dependencies were also temporarily removed for the first iteration.

### Module Descriptor {#sec:module-descriptor}

**To do**

```{#lst:jabref-module .java caption="JabRef module"}
open module org.jabref {
    requires com.google.common;
}
```

### Java Generics

**To do**

## Upgrading Libraries

**To do**

# Modularizing JabRef

**To do**

# Conclusion

**To do**

# References