## xcs (Xcode script) 

### Intro

While building/cleaning Xcode project from command line is trivial task (hint: xcodebuild), managing the project content used to be the hard one. Not any more. xcs provides set of Thor tasks for adding/removing groups/files from xcode project

### Installation

You'll need two gems: [thor](https://github.com/wycats/thor) and [rb-appscript](http://appscript.sourceforge.net/rb-appscript/index.html). And then run 

	thor install http://github.com/gonzoua/xcs/raw/master/xcs.thor

### Tasks

Get full list of tasks using command

    thor xcs:help

*  **xcs:add File [Group]**  Add file to a group. By default adds to "Source"
*  **xcs:help [TASK]**       Describe available tasks or one specific task
*  **xcs:list [--verbose]**    List project contents
*  **xcs:mkgroup Group**   Create new subgroup in root group
*  **xcs:rm Group/File**    Remove file reference from a project
*  **xcs:rmgroup Group**   Remove Group

### Sample usage

Just cd to your project directory and run

    thor xcs:list

You'll get something like this:

    Using /Users/gonzo/Projects/EPUBToolkit/EPUBToolkit.xcodeproj
    EPUBToolkit/
      EPUBFile.h
      EPUBFile.m
      Source/
        main.m
      Documentation/
        EPUBToolkit.1
      Products/
        EPUBToolkit
      Frameworks/
        Foundation.framework
      Other Sources/
        EPUBToolkit-Prefix.pch

Create a file and add it to project, to group FooSources

    echo '#import "Foo.h"' > Foo.m
    thor xcs:mkgroup FooSources
    thor xcs:add Foo.m FooSources

### Limitations

* Only first-level groups are supported
* No targets support


### Ideas

Ideas are welcome. Open issue or drop me a line at gonzo@bluezbox.com  
Pull requests are even more welcome.

### Contributors

[Oleksandr Tymoshenko](http://bluezbox.com)

### License

See LICENSE
