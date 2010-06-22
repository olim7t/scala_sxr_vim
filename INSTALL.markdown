# 1. Getting scala_sxr.vim

Go to [the downloads section](http://github.com/olim7t/scala_sxr_vim/downloads) and grab the latest version.

# 2. Installing scala_sxr.vim

The most straightforward way is to copy the contents of the `vim` directory to `$HOME/.vim` (this will give you `$HOME/.vim/ftplugin`, etc.).

Then edit `$HOME/.vimrc` and make sure it contains the following line:

	filetype plugin on

_Note:_ if you're already using Vim to edit Scala files, you probably have the indent and syntax files installed (see [here](http://www.scala-lang.org/node/91#tool_support)). In that case, `ftdetect/scala.vim` already exists; you don't need to overwrite it.

If things are not working, here are a few commands you can run from Vim:

* `:version` tells you which vimrc files are used;
* `:set runtimepath` shows the directories that are scanned for scripts. The directory you copied your files to should appear in the list;
* `:scriptnames` shows sourced scripts. When editing a Scala file, `scala_sxr.vim` should appear in the list.

More complex setups (like installing for all users) are not covered here; if you're into that situation, you probably know what you're doing anyway.

# 3. Getting sxr

scala_sxr.vim needs sxr version 0.2.5 or higher.

If you're going to use sbt with `AutoCompilerPlugins` (see 4.1), you don't need to download sxr manually; skip part 3.

## 3.1. Getting from the scala-tools repository

Go to [the scala-tools repository](http://scala-tools.org/repo-releases/org/scala-tools/sxr) and download the file corresponding to your Scala version.

## 3.2. Building from source

Go to [the sxr site](http://github.com/harrah/browse) and follow the instructions in `README`.


# 4. Configuring sxr for your Scala project

The `test_project` directory contains a dummy project configured for both sbt and Maven.

## 4.1. Using sbt

See [TestProject.scala](http://github.com/olim7t/scala_sxr_vim/blob/master/test_project/project/build/TestProject.scala). There are two ways to configure sxr with sbt (both are showed in the example, one being commented):

* have your project class mix in `AutoCompilerPlugins` to retrieve the sxr dependency from a repository (if sbt is giving you `bad option` errors, try running the `update` action);
* manually set the `-Xplugin:` compiler option to use a local copy of sxr.

If you have a multi-module project and wish to run sxr on all sources at once, see [this example](http://github.com/harrah/xsbt/blob/master/project/build/Sxr.scala).

## 4.2. Using Maven

See [pom.xml](http://github.com/olim7t/scala_sxr_vim/blob/master/test_project/pom.xml).

_For now, the only option is to use a local copy of sxr. I have yet to investigate retrieving the dependency from a repository and multi-module builds._

## 4.3. Generating the HTML report

sxr can also generate an HTML cross-reference of your Scala source files (actually, this is what sxr was initially written for). To enable it, edit your sbt project class or Maven POM and update this option:

	-P:sxr:output-formats:html+vim

# 5. Using scala_sxr.vim

cd to `test_project` and run `sbt clean compile` or `mvn clean compile`. This should create a `target` directory containing a `classes.sxr` subdirectory (with sbt, it will be in `target/scala_<version>`). This is where sxr stores the data that scala_sxr.vim uses.

## 5.1. Basic workflow

* edit your Scala files;
* compile (this will invoke sxr which will update its data files). This can be done automatically by enabling continuous compilation (`~compile` from the sbt prompt, or `mvn scala:cc`);
* use the Vim shortcuts to get type information or navigate between files.

## 5.2. Directory detection

When scala_sxr.vim is invoked, it needs to know two directories:

* the root source directory of the current Scala file;
* the directory containing sxr output.

This is used to find the data file corresponding to the Scala file. For instance, if we are editing `src/main/scala/some/dir/Foo.scala` and sxr outputs its files in `target/classes.sxr`, the data file we are looking for is `target/classes.sxr/some/dir/Foo.scala.txt`.

There are two ways to configure these directories:

### 5.2.1. Automatic

This is on by default. scala_sxr.vim will look for an `src` directory somewhere above the current file. Then it will look for a `scala` directory below `src`, and assume it is the base source directory. Then for a `classes.sxr` directory below `src/..`, and assume it is the output directory.

This works for standard sbt and Maven directory structures (`src/main/scala`, `src/test/scala`, `target/classes.sxr` or `target/scala_<version>/classes.sxr`). 

### 5.2.2. Manual

Manual mode is configured with three global variables (you would most likely do
this in `$HOME/.vimrc`):

	let sxr_disable_autodetect = 1 " Any value will do
	let sxr_scala_dir = /absolute/path/to/source
	let sxr_output_dir = /absolute/path/to/classes.sxr

Note that this only works with a single source directory.

## 5.3. About the tags

The "jump to declaration" feature (`Ctrl-]`) delegates to the standard Vim tag mechanism. Therefore, you can also use other tag commands, for instance `:tselect` to find a tag by name (run `:help tags` for the complete list of commands).

sxr generates two kinds of tags:

* "private" tags, which are unique numbers. These are used to link to declarations within the same file, or between files compiled in the same run. Normally, you don't have to care about these tags;
* "public" tags, which are a human-readable string. This is most likely the ones you will be using.

For instance, assuming you are editing a file from `test_project` and wonder about members called `message`, you could type `:ts /message` to get something along the lines of:

	# pri kind tag                     file
	1 F        term Resources.message  /.../Resources.scala
	             :goto 26
	2 F        term Resources.message(e30a80d2b4700276248ce5925d94ebb97783d05d) / .../Resources.scala
	             :goto 26

Which brings out two remarks about public tags:

* the Scala compiler will sometimes generate various symbols for the same element. For instance, `Resources.message` defines both a field and a method. This results in two tags pointing to the same offset;
* when generating the tag name of a method, sxr uses a hash of the parameters (listing all parameters with their complete path could lead to a very long signature).

_Note:_ the tag files are only loaded by the first scala_sxr.vim specific command. Therefore, `:ts` won't work until after the first time you use `F2` or `Ctrl-]`.

# 6. Customizing scala_sxr.vim

## 6.1. Disabling completely

You will need this if you're using a shared Vim installation that has scala_sxr.vim configured, and you don't want to use the plugin.

Create your own `$HOME/.vim/ftplugin/scala_sxr.vim`, with only the following line:

	let b:did_ftplugin = 1

See `:help ftplugin` for more information.

## 6.2. Disabling the shortcuts

If for some reason you don't want the plugin shortcuts, you can define one of the following global variables in `$HOME/.vimrc`:

	let no_plugin_maps = 1   "Disable all shortcuts for all plugins
	let no_scala_maps = 1    "Disable shortcuts only for scala_sxr.vim

## 6.3. Remapping the shortcuts

If you don't like the default shortcuts, you can redefine them in `$HOME/.vimrc`:

	map <F3> <Plug>Annotate   " Remap type annotation to F3
	map <C-L> <Plug>JumpTo    " Remap jump to declaration to Ctrl-L

See `:help map-which-keys` for help on how to choose key combinations.
