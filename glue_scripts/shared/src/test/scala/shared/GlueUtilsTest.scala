package shared

import org.scalatest.{FlatSpec, Matchers}

class GlueUtilsTest extends FlatSpec with Matchers {
  "parseArgs" should "resolve system arguments from Glue to a map of key value pairs" in {
    val args: Array[String] = Array("JOB_NAME", "--sourcePath", "arg2", "--outputPath", "arg3")

    val parsedArgs: Map[String, String] = GlueUtils.parseArgs(args)

    parsedArgs("JOB_NAME") shouldBe null
    parsedArgs("sourcePath") shouldBe "arg2"
    parsedArgs("outputPath") shouldBe "arg3"
  }
}
