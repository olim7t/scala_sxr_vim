import sbt._
import FileUtilities.{appendStream, clean => delete, readStream, transfer}

class TestProject(info: ProjectInfo) extends DefaultProject(info) with AutoCompilerPlugins {
  // Configuration to get sxr from the scala-tools repository
  val sxr = compilerPlugin("org.scala-tools.sxr" %% "sxr" % "0.2.5")
  override def compileOptions =
    CompileOption("-P:sxr:base-directory:" + mainScalaSourcePath.absolutePath) ::
    CompileOption("-P:sxr:output-formats:vim") ::
    super.compileOptions.toList

  // Configuration to use a local copy of sxr
  /*
  val sxrPath = "/path/to/sxr_2.8.0.RC6-0.2.5.jar"

  override def compileOptions =
    CompileOption("-Xplugin:" + sxrPath) ::
    CompileOption("-P:sxr:base-directory:" + mainScalaSourcePath.absolutePath) ::
    CompileOption("-P:sxr:output-formats:vim") ::
    super.compileOptions.toList
  */
}
