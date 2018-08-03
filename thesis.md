# Introduction

In average 36% of development time of software systems is used on repaying 
technical debt -- suboptimal decisions hindering software evolution and 
maintenance [@Besker2017].
This is especially problematic for open source projects or software platforms, 
where compatibility with previous versions is usually highly valued to not
frighten off users with the effort required to adapt to new versions of the 
system [@Brito2018].
However, suboptimal decisions often become clear only later in the lifecycle of 
a software system and in order to simplify future development require to break
backwards compatibility.

Recently, such a decision to break backwards compatibility in order to stay 
relevant was made by the developers of the Java language environment. 
With the release of Java 9 the fundamental way how code artifacts are organized 
changed with the introduction of a module system.
Although several ways of migrating stepwise to the new system and utilizing the
new features only partly, the new version of the language presents developers of
the large ecosystem of Java libraries and applications wanting to migrate with 
problems.

While the topic of software maintenance and especially software migration is 
well studied [@Besker2017; @Chapin2001; @Malton2001; @Mancl2001; @Mayrhauser1995]
and also the migration of applications to different programming languages is
covered [@Martin2002], not much literature exists on the topic of migrating 
applications to newer versions of the same language.
There are also several studies on the topic of +API stability [@Brito2018; @Dig2006],
which is a big factor for backwards compatibility.
Migration to Java 9 is mainly described in online documentation [@Oracle2017],
text books [@Inden2018; @Kothagal2017; @Mac2017] and online experience
reports [@Parlog2017].

The goal of this thesis is to assess the difficulties that developers encounter
when migrating applications from Java 8 to Java 9.
To achieve this, the migration was performed exemplarily on the open source
bibliography manager JabRef.
In [@sec:background], first the topic of software migration in general is 
examined, then the advantages of and the way Java implements modules are 
analyzed, and the software JabRef is presented.
[@sec:approach] describes the iterative approach of the migration process 
applied to JabRef and the encountered problems.
Then the software was also divided into several smaller modules, which is
explained in [@sec:modularization].
Finally, the thesis concludes in [@sec:conclusion].

# Background {#sec:background}

## Software Migration {#sec:migration}

Software migration is a part of software maintenance [@Dig2006]. 
In general software maintenance can be classified as adaptive, corrective, 
perfective, and preventive maintenance tasks [@Malton2001]. 
Within this classification, software migration is an adaptive maintenance task: 
Adapting existing software to a new environment or platform.

The need to perform a software migration usually arises, because the current 
platform or environment is obsolete or poorly supported, or from features 
available only in newer versions of a platform [@Malton2001].

Software migration tasks can be grouped into three general classes:

* **Dialect conversion** is required when the underlying compiler technology
  changes to a new version of the compiler or a new compiler family 
  [@Malton2001]. Usually successive versions of compilers aim at being backwards
  compatible, even when new features were added, in large code bases, however,
  additional effort is required to use new versions of compilers.

* **+API migration** is the process of changing a dependency on an external
  +API to another one or a different version [@Malton2001].

  Similar to other software, libraries that provide an +API evolve over time, to
  introduce new features, fix bugs, and refactor source code [@Xavier2017].
  ++API establish a contract with the clients, that rely on them, hence ++API
  should have a high stability to minimize effort for clients when updating to
  a newer version.
  However, not all changes in ++API are breaking the previously established
  contract, changes that do are referred to as *breaking changes*.

  Breaking changes mainly are modification or removal of existing +API
  elements [@Brito2018]. Adding new +API elements are rarely braking changes.

  Usually libraries also contain code that is intended only for implementing the
  services offered by an +API, but not for public consumption [@Dig2006].
  Many languages do not provide features to explicitly mark such elements as
  internal, but library authors rely solely on naming conventions, e.g. placing
  code in an `internal` namespace. 

* **Language migration** is the decision to convert an existing program to a new
  language [@Malton2001]. This is a risky type of migration, as it requires much
  effort to re-express source code in a different language.

The general approach for adaptive software maintenance consists of a sequence of
steps as shown in [@fig:adaptive_maintenance].

![Activities of Adaptive Software Maintenance [@Mayrhauser1995]](images/adaptive_approach.svg){#fig:adaptive_maintenance}

Applied to a migration process, the sequence of steps consists of first
understanding the system. Then the changes in the new environment or platform 
need to be understood in order to understand the new requirements to the system.
The next step is to develop a plan of how the new requirements can be 
implemented in the system. Next, the planned changes can be implemented, which
may require debugging. Lastly, regression tests should be ran, to ensure that
the system is still completely functional in the new environment.

## Java 9 {#sec:j9}

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
In 2009 Oracle acquired Sun and since then is the maintainer of the language
[@Oracle2015].

Since its origin, Java has a very good history of being backwards compatible with previous 
releases [@Marx2016; @Oracle2018d; @Oracle2018f; @Oracle2018; @Oracle2018a; @Oracle2018b; @Oracle2018c; @Oracle2018e].
According to Oracle, incompatibilities usually occur only in rarely used edge-
cases, or when new keywords were introduced in the language, such as `strictfp`
in Java 2, `assert` in Java 4 and `enum` in Java 5, which subsequently can no
longer be used as identifiers.

With Java 9 the *Java Platform Module System* (+JPMS) -- also popular under its
working name *Jigsaw* -- was introduced the the Java platform among other minor
changes. 
+JPMS adds *modules*, which are identifiable artifacts containing code, to the 
Java language [@Mac2017].
The monolithic +JDK itself was also split into smaller modules [@Clark2017].

Since Java 9 the release cycle has also adapted to a faster pace [@Reinhold2018].
Beginning with Java 9, a feature release will be published every six months and
long term support (+LTS) releases will be released every three years. Because of 
this, Java 9 is already superseded by Java 10 as of writing, and Java 11, the 
next +LTS release, is expected to be released in September 2018.

### Advantages of Modules {#sec:j9_adv}

Before Java 9, artifacts were usually distributed as *Java archives* (++JAR)
[@Kothagal2017]. Java has a concept of a classpath, which is a path in the
file system Java searches for compiled code required at runtime or compilation.
[@fig:classpath] shows a schematic image of a classpath as it would be specified
to Java. This classpath has 4 +JAR files on it, each containing several packages.
The white rectangles symbolize classes in the packages.

![Unresolved Classpath before Java 9 [@Kothagal2017]](images/classpath.svg){#fig:classpath}

Before Java 9, the information of how packages and classes are organized was
ignored by Java [@Kothagal2017]. Java resolves classes on demand when they are
first required. [@fig:classpath_resolved] shows the information that is 
available to Java. All contents of the ++JAR on the classpath are seen as if it
were only one artifact.

![Resolved Classpath before Java 9 [@Kothagal2017]](images/classpath_resolved.svg){#fig:classpath_resolved}

This way of handing loading of classes led to several problems: The first one
being accessibility [@Kothagal2017]. Every code artifact can essentially use
code of every other artifacts, as long as classes or members are not restricted
with the existing access modifiers (see [@tbl:access]). This can make dependency
relations unclear for large code bases and violates strong encapsulation 
principles.

This becomes even more problematic with the second problem: If more than one 
type exists with the same fully qualified name, i.e. the package name and the 
type name is the same, the first one found is used [@Kothagal2017]. This problem 
most often occurs when different versions of the same libraries are put on the 
classpath and is referred to as *+JAR hell*. As classes are loaded lazily this
problems might not even be noticed on startup of an application, but only when
it was running for some time and a class is used for the first time. Thus
reliable configuration of the classpath is difficult and explains the rise of
tools like Maven or Gradle, that standardize the process of obtaining 
dependencies and configuring Java to use them [@Kothagal2017].

Access modifier | Class    | Package  | Subclass | Unrestricted
----------------|----------|----------|----------|--------------
`public`        | \checked | \checked | \checked | \checked
`protected`     | \checked | \checked | \checked |
- *(default)*   | \checked | \checked |          |
`private`       | \checked |          |          |

: Access modifiers and their associated scopes [@Mac2017] {#tbl:access}

+JPMS aims at exactly these needs of large Java applications: reliable 
configuration and strong encapsulation [@Clark2017].

Modules have to explicitly declare which packages they make available to other
modules and which modules they are dependent on [@Mac2017].
Packages that are not exported by a module can not be used in other modules.
This clearly separates public +API from code that is intended for internal use 
only. Consequently internal code can also change freely without worrying about 
introducing breaking changes.

From the declaration of dependencies a so-called module graph 
([@fig:module_graph]) can be derived to identify dependencies of modules.
The nodes of the graph represent the modules of the application, the dark blue
edges represent the explicitly declared dependencies, while the light blue 
edges represent the implicit dependency of every module on the Java base module 
`java.base` [@Reinhold2016].

![Module Graph [@Reinhold2016]](images/module_graph.png){#fig:module_graph}

Java 9 resolves modules every time before an application is compiled or executed 
[@Kothagal2017]. Thus, it is possible to catch configuration errors like 
missing modules or multiple modules with the same name directly at startup.

Additionally due to the smaller modules, instead of one big runtime environment,
Java 9 is better equipped to be run on devices for the Internet of Things (IoT)
[@Inden2018]. Those devices often have heavy restrictions on storage space and
now do no longer have to store the full runtime environments, but only those 
parts that are required to run the respective application.

### Implementation of Modules {#sec:j9_impl}

To make use of +JPMS in Java 9 a module has to declare its public packages and
its dependencies as mentioned in [@sec:j9_adv]. This is done using a module
descriptor, a file called `module-info.java` in the root package, that will be
compiled as classes to a file called `module-info.class` [@Mac2017]. 
[@lst:module-desc] shows an example of such a module descriptor.

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
above packages should be allowed, they would have to be explicitly be exported 
[@Mac2017].

The example module further "opens" the package `com.company.module.api.feature`
to reflective access from other modules. Reflective access is not granted by
default, even if a package is exported [@Mac2017]. If a module relies heavily on
reflection, it may also be declared as an `open module` to allow reflection into
all its packages.

The module then declares its dependencies on `org.thirdparty.module` and 
`org.provider.othermodule`, with the second dependency being declared as
transitive dependency. This means that the module also depends on all 
dependencies of `org.provider.othermodule`.

The last two declarations identify that the module uses a service
`org.thirdparty.module.Service` provided by some other class and implements a
service `com.company.module.api.Service` with the class 
`com.company.module.api.impl.ServiceImpl` for usage by other modules. This
declaration of services was already a feature of Java before version 9, but
relied on a configuration using text files. The declaration of provided and used
services is +JPMS form of dependency injection, also known as the principle
*Inversion of Control* (+IoC) that allows hiding of implementation details 
[@Mac2017].

As an alternative to the explicit declaration of a module descriptor, Java 9
also allows the usage of so called *automatic modules* [@Mac2017]. Automatic
Modules do not have a module descriptor, their name is derived from the 
attribute `Automatic-Module-Name` in the +JAR manifest `META-INF/MANIFEST.MF` or
from the name of the +JAR file if that attribute is not present.
An automatic module has some special characteristics: It `requires transitive`
all other resolved modules, exports all its packages and reads the classpath.
This version of module declaration is favorable if the module has to maintain
backwards compatibility with previous Java versions. Especially library 
maintainers are often hesitant to migrate to the latest Java version to not
lose their consumers using older versions.

The third variant of modules is the so-called *unnamed module* [@Inden2018]. In
contrast to explicit modules and automatic modules, which are put on the 
*modulepath*, the unnamed module consists of all code that is put on the
classpath. The unnamed module is treated like code before Java 9. Automatic
modules can access code in the unnamed module, while explicit modules cannot.

### Migrating to Modular Code {#sec:j9_mig}

Oracle claims, that code that uses only official Java ++API should work without
changes, but some third-party libraries may need to be upgraded [@Oracle2018g].
However, in reality there are some more constraints of the module system that 
need consideration.

Firstly, due to the modularization of the +JDK itself, internal ++API became
unavailable [@Mac2017]. Those classes were always meant to be used only 
internally by the +JDK, but due to the missing access restrictions and missing
alternatives, they have become adopted by some developers.

For widely used internal classes the module `jdk.unsupported` is provided,
so that backwards compatibility for applications depending on them is ensured,
however it is planned that those classes are replaced with supported 
alternatives in a future Java version [@Mac2017].

While Java 9 still provides the possibility to explicitly make the internal ++API
available with command line switches like `--add-exports`, the only long-term
solution is to move away from those ++API and find supported replacement 
solutions [@Inden2018]. Corresponding to that, the switch `--add-opens` exists
for allowing reflection into packages of modules, that do not explicitly open
packages.

The second restriction is that modules are no longer allowed to have split
packages [@Mac2017]. Split packages are packages with the same name, that are
contained in two or more modules.
[@fig:split_packages] shows two modules where both contain the packages 
`splitpackage` and `splitpackage.internal`. 

![Split Packages across several Modules](images/split_packages.svg){#fig:split_packages}

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

## JabRef Bibliography Manager {#sec:jabref}

JabRef is an open source bibliography reference manager using the standard LaTeX
bibliography format BibTeX as its native file format.
The project is hosted on 
GitHub^[[https://github.com/JabRef/jabref](https://github.com/JabRef/jabref)] 
and currently has over 200 contributors and around 140,000 lines of Java code.

According to a survey carried out in 2015 across its users, JabRef is most 
commonly used by German, English and French speakers [@JabRefDevelopers2015]. It 
is most commonly used in professional work, such as engineering and medicine and
for studies, mostly from the field of natural sciences and formal sciences.

JabRef is built using a layered architecture as shown in [@fig:architecture] 
[@JabRefDevelopers2017]. The shown components only depend on components lower in 
the figure. The base of the architecture is the *Model* component, that 
encapsulates the entities used in the application. Building on top of that 
component is the *Logic* component, that contains all business logic. The 
*Preferences* component provides the functionality to load and store user 
defined settings. JabRef's command line interface is encapsulated in the *+CLI* 
component and the top layer is constituted by the graphical user interface in 
the *+GUI* component. Additionally, there exist some additional global classes, 
that may be used anywhere in the application.

![High-Level Architecture of JabRef](images/jabref_architecture.svg){#fig:architecture}

The communication between the components of JabRef is implemented using an event 
bus, that allows publishing events and registering listeners for events. This 
allows to react upon changes in the core and still react in the upper layers, 
while keeping the components clearly separated.

The source code of JabRef is build using the tool Gradle. Gradle automates
repeated tasks such as compilation of the source code, building release 
distributions, resolving correct versions of dependencies, running tests and 
generation of source code with parser generators.

# Migrating JabRef to Java 9 {#sec:approach}

The following section covers the process of migrating JabRef from Java 8 to 
Java 9. 
Due to the open source nature of JabRef development of the project continued 
during the migration phase.
Therefore the migration technique as shown in [@sec:migration] was applied in an 
iterative approach and changes to the current version were continuously 
synchronized to the Java 9 version.

[@fig:approach] shows the general approach of the migration. The approach is
substantially different depending on whether an issue is located in an external
dependency or in JabRef's codebase. When the issues were fixed in a future
version of a third-party library, the solution simply consists of upgrading said 
dependency, otherwise the issues were reported to the maintainers of the 
respective libraries or a code contribution to their projects was created.

![General Approach of the Migration](images/approach.svg){#fig:approach}

Issues in JabRef internal code can be classified into access to now internal +API
and changes in the Java compiler. The only sustainable solution to those 
problems is migrating away from the +API and finding a supported replacement.
Changes in the compiler are usually only minor, but require adaption of the 
code.

## Compile-Time Compatibility {#sec:jr_mig}

In the first iteration the focus lay on ensuring compile-time compatibility with
Java 9.
Incompatible parts of JabRef were temporarily removed.

A number of external libraries were incompatible with Java 9 and also had to be 
removed.
The incompatibilities of these libraries can be categorized into the following 
categories.

First, four libraries exported the same packages, resulting in a split package
as explained in [@sec:j9_mig]. These libraries were the popular utility library
*Google Guava*, the +SDK of the office suite *LibreOffice*, Microsoft's 
monitoring service *ApplicationInsights* and *ArchUnit*, a test framework to
check for architecture constraints.

While Google Guava did not actually contain a split package, it had a 
dependency on an unofficial implementation of Java annotations as specified by
the Java Specification Request (+JSR) 305, that aims at assisting tools to find
software defects by providing annotations such as `@NonNull` [@Pugh2006]. 
However, this dependency was optional and thus not required at runtime, so the 
solution was to explicitly exclude it in the Gradle build script as shown in
[@lst:jsr-exclusion]. 

```{#lst:jsr-exclusion .java caption="Exclusion of the +JSR 305 dependency"}
configurations {
    // [...]

    compile {
        exclude group: 'com.google.code.findbugs', module: 'jsr305'
    }
}
```

For ArchUnit a development version was already available, so it could simply be
updated.
The LibreOffice +SDK and Microsoft ApplicationInsights were incompatible with
Java 9, so for the first iteration, they were temporarily removed and the 
features of JabRef depending on them disabled.

Second, the +GUI libraries *Spin* and *ControlsFX* and JabRef itself used internal
++API in the +JDK, that were no longer accessible. For the first iteration, the
solution was to simply use the flags mentioned in [@sec:j9_mig] to allow the
access to those libraries.
[@lst:jr-args] shows the command line arguments required to run JabRef in the 
first iteration.

```{#lst:jr-args .bash caption="Command Line Arguments Required to Run JabRef in Iteration 1"}
java \
    --illegal-access=debug \
    --add-opens javafx.swing/javafx.embed.swing=org.jabref \
    --add-opens java.desktop/java.awt=spin \
    --add-opens javafx.controls/javafx.scene.control=org.jabref \
    --add-exports javafx.base/com.sun.javafx.runtime=controlsfx \
    -p . \
    -m org.jabref/org.jabref.JabRefMain
```

The third problem for compile-time compatibility were the module names of some
dependencies. As mentioned in [@sec:j9_mig] Java first searches for a module
descriptor, if it can not be found the `Automatic-Module-Name` attribute in the
+JAR manifest is consulted and if that is not present, Java derives a module name
from the file name of the +JAR file.
However, module names underlie the same restrictions as Java packages, so they
may contain dots, but each segment between two dots must be a valid Java 
identifier.

This was a problem for Scala dependencies that follow the default Scala naming
scheme consisting of the name of the project followed by an underscore followed
by the Scala version.
So an artifact with the name `latex2unicode` for Scala 2.11 results in an 
artifact with the name `latex2unicode_2.12.jar`. 
For this, Java 9 derives the module name `latex2unicode.2.12`, which is an 
invalid module name as the 2 directly follows a dot.
For the first iteration the Scala dependency *latex2unicode*, which JabRef uses
to resolve LaTeX commands to plain text, that had again dependencies on the 
Scala libraries *fastparse* and *Sourcecode*, was temporarily removed.

Fourth, there were minor incompatibilities with the new compiler regarding the
use of Java generics. The method `children()` in [@lst:compiler-before] returns
an object of the type `Enumeration<TreeNode>`, before Java 9 however, it could
be assigned to a variable of the type `Enumeration<CheckableTreeNode>` where
`CheckableTreeNode` inherits `TreeNode`.

```{#lst:compiler-before .java caption="Use of Generics before Java 9"}
Enumeration<CheckableTreeNode> tmpChildren = this.children();
for (CheckableTreeNode child : Collections.list(tmpChildren)) {
    child.setSelected(bSelected);
}
```

This direct conversion is no longer possible in Java 9. The returned object of
`children()` is assigned to a variable of the correct type 
`Enumeration<TreeNode>` in [@lst:compiler-after] and cast to the type 
`CheckableTreeNode` on usage.

```{#lst:compiler-after .java caption="Use of Generics after Java 9"}
Enumeration<TreeNode> tmpChildren = this.children();
for (TreeNode child : Collections.list(tmpChildren)) {
    ((CheckableTreeNode) child).setSelected(bSelected);
}
```

Several instances of that problem were found throughout JabRef's source code,
however no documentation could be found that explains this change in the
Java language.

Lastly, as a result of the first iteration also a module descriptor was created 
for JabRef (see [@sec:j9_impl]).
While it would have been possible to make JabRef an automatic module, instead of
an explicit one, there were already efforts for creating a descriptor due to the
open source nature of JabRef.

[@lst:jabref-module] shows an excerpt from the module descriptor. 
The module was declared as open module to allow all internal access into JabRef,
because the architecture of JabRef (see [@sec:jabref]) is based around an 
event bus provided by the Google Guava library, which makes extensive use of
reflection.

```{#lst:jabref-module .java caption="JabRef module"}
open module org.jabref {
    exports org.jabref;

    exports org.jabref.gui;
    // [...]

    // SQL
    requires java.sql;
    requires postgresql;

    // JavaFX
    requires javafx.graphics;
    requires javafx.swing;

    // [...]

    provides com.airhacks.afterburner.views.ResourceLocator
        with org.jabref.gui.util.JabRefResourceLocator;
    
    provides com.airhacks.afterburner.injection.PresenterFactory
        with org.jabref.gui.DefaultInjector;

    // [...]
}
```

## Upgrading Libraries

In the second iteration the focus lay on updating the libraries removed in
iteration one to versions that are compatible with Java 9.
Not much work was done on JabRef itself, but getting in contact with library 
maintainers and participation in their open source projects was the main
objective.

### LibreOffice

JabRef uses the LibreOffice +SDK to insert citations and references into 
LibreOffice documents.
However, the +SDK consists of multiple artifacts all exporting the same package
`com.sun.star`, so they are incompatible with +JPMS due to a split package
(see [@sec:jr_mig]). 
Thus the complete +SDK and JabRef's functionality to interface with LibreOffice
was temporarily removed.

Possible long-term solutions include bundling all artifacts as one artifact, so
the LibreOffice +SDK is no longer modular, but requires consumers to load all of
it. 
The problem of the split package however would be solved, as the +SDK is then
only one module to export the package.
Another solution could be to rename the packages contained in each artifact,
this however would break backwards-compatibility of the +SDK.

The issue was reported to the Document Foundation, the maintainer of LibreOffice^[[https://bugs.documentfoundation.org//show_bug.cgi?id=117331](https://bugs.documentfoundation.org//show_bug.cgi?id=117331)].
[@tbl:lo-split] shows the development on the bug report.

| Date          | Action                                                       |
| ------------- | ------------------------------------------------------------ |
| 2018-04-29    | Bug Report Created                                           |
| 2018-06-07    | Bug Confirmed by another user                                |

: Timeline of the bug report of the split package in LibreOffice {#tbl:lo-split}

As the developers of LibreOffice were unresponsive to the bug report as of 
writing, a possible workaround to the problem would be to manually repackage the 
artifacts to a single one as proposed above. However, doing this without support 
of the original developers would complicate the build process of JabRef, because 
the patched artifact would need to be shipped with the source code instead of
downloading the dependencies from a central Maven repository as it is done for
other dependencies.

### Latex2Unicode

Latex2Unicode is written in Scala and has dependencies on three other Scala
libraries.
As briefly shown in [@sec:jr_mig] Scala's default naming scheme generates
invalid automatic module names, so latex2unicode had to be temporarily removed
in iteration one.

Since Scala does not yet support +JPMS, the solution of this problem is to
explicitly provide an `Automatic-Module-Name` attribute in the libraries
manifest (see [@sec:j9_impl]).
This was proposed to the library maintainer of 
latex2unicode^[[https://github.com/tomtung/latex2unicode/pull/11](https://github.com/tomtung/latex2unicode/pull/11)]
and to the maintainers of the dependent libraries 
fastparse^[[https://github.com/lihaoyi/fastparse/pull/185](https://github.com/lihaoyi/fastparse/pull/185)]
and sourcecode^[[https://github.com/lihaoyi/sourcecode/pull/49](https://github.com/lihaoyi/sourcecode/pull/49)]
in the form of code contributions -- so called pull requests -- to their 
libraries.

[@tbl:l2u-split] shows the timeline of the bug report for latex2unicode.

| Date          | Action                                                       |
| ------------- | ------------------------------------------------------------ |
| 2018-04-28    | Bug report created                                           |
| 2018-05-18    | Code contribution provided                                   |
| 2018-05-29    | Proposed fix accepted by library maintainer                  |
| 2018-xx-xx    | Version including fix published                              |

: Timeline of the bug report for latex2unicode {#tbl:l2u-split}

The maintainer of the dependencies fastparse and sourcecode remained 
unresponsive to the proposed fixes both provided on 2018-05-18 as of writing.
Possible solutions to work around the problem include providing a manually 
patched version of the libraries or using a service such as 
Jitpack^[[https://jitpack.io](https://jitpack.io)] to build the versions 
including provided code contribution. Jitpack allows developers to publish
versions of their libraries directly from a Git repository without additional
configuration.

### Microsoft ApplicationInsights

ApplicationInsights follows the practice to distribute so called fat ++JAR --
Java artifacts including all required dependencies -- but additionally relocate
the packages of dependencies under their own package prefix.
So their dependency on Google Guava using the package `com.google.common` is
distributed in ApplicationInsights as 
`com.microsoft.applicationinsights.core.dependencies.googlecommon`.

However, Guava also exports the package `com.google.thirdparty`.
This package was not correctly relocated in ApplicationInsights, causing a 
split package conflict with JabRef's dependency on Google Guava.

The problem was reported to the library maintainers of ApplicationInsights^[[https://github.com/Microsoft/ApplicationInsights-Java/issues/661](https://github.com/Microsoft/ApplicationInsights-Java/issues/661)].
[@tbl:ai-split] shows the timeline of the bug report.

| Date          | Action                                                       |
| ------------- | ------------------------------------------------------------ |
| 2018-05-05    | Bug Report Created                                           |
| 2018-06-08    | Bug fixed by maintainers of the library                      |
| 2018-xx-xx    | Version including fix published                              |

: Timeline of the bug report of missed package relocation in Google Guava {#tbl:ai-split}

### JavaFxSVG

JavaFxSVG is a library that allows the +GUI framework JavaFX to display SVG
graphics.
The library exports the package `org.w3c.dom` which conflicts with ++API provided
directly from the +JDK.
However, this functionality was used at only one occasion -- to display the 
JabRef logo in an About dialog -- so in agreement with the JabRef developers the 
library was removed and replaced with JavaFX's native capabilities.

![JabRef logo](images/jabref.svg){#fig:jabref width=100px height=100px}

JavaFX does not support the full set of features of the SVG definition, but it
has support for its so called paths specifying vertices of geometric shapes.
JabRef's logo consists of six such paths as shown in [@fig:jabref]. The solution
was to overlay the paths in order to recreate the complete image (see [@lst:logo-fxml]).

```{#lst:logo-fxml .xml caption="Rendering of JabRef logo with JavaFX"}
<StackPane onMouseClicked="#openJabrefWebsite" scaleX="0.6" scaleY="0.6" 
    prefWidth="140" prefHeight="140" BorderPane.alignment="CENTER">
    <!-- SVGPaths need to be wrapped in a Pane to get them to the same 
    size -->
    <Pane prefHeight="350" prefWidth="350" styleClass="logo-pane">
        <SVGPath content="M97.2 87.1C93.2 33.8 18.4 14.6 18.2 ..." />
    </Pane>
    <Pane prefHeight="350" prefWidth="350" styleClass="logo-pane">
        <SVGPath content="M96.2 61.2C92.8 19.2 35.1 0.4 35 ..." />
    </Pane>
    <!-- ... -->
</StackPane>
```

## Reworking JabRef's Threading Model

The third iteration of migrating JabRef to Java 9 consisted in reworking parts
of its threading model. The rework was required because JabRef used the library
"Spin" to simplify interaction of the +GUI with long-running background tasks.
Spin provides utilities to load off time-intensive operations to a separate
thread, so that the +GUI stays responsive to user input.

This is done by creating proxy objects that run their operations on a separate
thread, but wait until their execution has finished, while keeping the +GUI 
thread responsive (see [@fig:spin]).

![Model of Spin [@Meier2007]](images/spin.svg){#fig:spin}

However, the JabRef developers are in the process of migrating from the Swing
+GUI framework, that Spin was written for, to the newer +GUI framework JavaFX.
This migration process already lead to some threading issues, because often +GUI
frameworks restrict programmatic interactions with +GUI components to be only
allowed on the +GUI thread -- sometimes also called event dispatch thread (+EDT). 
This migration process made the usage of Spin obsolete, as it does not work with 
JavaFX.

The solution to this problem was to adapt the approach of JabRef, that was 
already employed in parts of the application. JabRef uses an callback based
approach partly provided by the JavaFX framework itself.
This approach provides a class `BackgroundTask` that wraps time consuming 
operations and provides means to specify callbacks that are executed on the +GUI
thread once the operations succeeds, fails or either of the two.

```{#lst:background_task .java caption="Usage of background tasks"}
BackgroundTask.wrap(this::verifyDuplicates)
              .onSuccess(this::handleDuplicates)
              .executeWith(Globals.TASK_EXECUTOR);
```

[@lst:background_task] shows how background tasks are used in JabRef. The
method `verifyDuplicates` is executed on a thread of the `Globals.TASK_EXECUTOR`
executor service. When the verification of duplicates succeeds the method
`handleDuplicates` is called on the JavaFX +GUI thread, failures are not handled
in this case.

# Modularizing JabRef {#sec:modularization}

After JabRef was running with Java 9, the next goal was to modularize the 
application in order to reinforce the architectural rules as shown in 
[@sec:jabref], but also to extract useful libraries for other applications. In
the past there already efforts to extract libraries from JabRef using the build
tool Gradle's support for modules^[[https://github.com/JabRef/jabref/pull/3704](https://github.com/JabRef/jabref/pull/3704)].
Using this approach JabRef would not produce one monolithic +JAR artifact, but
several smaller +JAR artifacts depending on each other. The problems that +JPMS 
addresses (see [@sec:j9_adv]), however, would not be addressed using this 
approach. The changes were discarded due to the release of Java 9.

In order modularize the application with +JPMS, an approach as shown in 
[@fig:approach_mod] was applied iteratively.

![Approach of Modularizing an Application with +JPMS](images/approach_mod.svg){#fig:approach_mod}

First a component was chosen and an empty module was created for it. Then the
dependencies were added according to the planned architecture. Then the packages
where the component resides in was moved to the new module. In order to find
missing dependencies, the new module was repeatedly compiled. By analyzing the
compiler errors, missing dependencies could be found. Dependencies on external
libraries could easily be added to the build script and the module descriptor.
Internal conflicts required appropriate refactoring according to the problems
at hand. Once the new module compiles without errors, the packages that should
be exported could be declared. Lastly, the application with the extracted module
was ran to ensure the functionality of the application.

The modularization was performed with a bottom-up approach. First the components
with no dependencies on other components were extracted, then the components
with only dependencies on already modularized components were extracted and so
forth. This was done to avoid circular dependencies, which are disallowed by 
+JPMS [@Mac2017].

## Extracting the Model Module

The first step of performing the modularization of JabRef was to extract the
model component, as it has no dependencies on other components, but almost all
components depend on it.

**To do**

# Conclusion {#sec:conclusion}

**To do**

# References
