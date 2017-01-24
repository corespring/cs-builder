name := "play-221"

version := "1.0-SNAPSHOT"

libraryDependencies ++= Seq(
  jdbc,
  anorm,
  cache
)

play.Project.playScalaSettings

import sbt._
import sbt.Keys._
import com.typesafe.sbt.packager.MappingsHelper.directory

topLevelDirectory := None

mappings in Universal += file("Procfile") -> "Procfile"

javacOptions in Compile ++= Seq("-source", "1.7", "-target", "1.7")
