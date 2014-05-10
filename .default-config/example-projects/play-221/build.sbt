name := "play-221"

version := "1.0-SNAPSHOT"

libraryDependencies ++= Seq(
  jdbc,
  anorm,
  cache
)

play.Project.playScalaSettings

//javacOptions in Compile ++= Seq("-source", "1.7", "-target", "1.7")
