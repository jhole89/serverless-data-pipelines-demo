package shared

import com.amazonaws.services.glue.util.GlueArgParser
import org.apache.spark.sql.catalyst.ScalaReflection.schemaFor
import org.apache.spark.sql.types.StructType
import scala.reflect.runtime.universe._

object GlueUtils {
// Parses Args from Glue parameters, add additional args to the Sequence.
  def parseArgs(sysArgs: Array[String]): Map[String, String] =
    GlueArgParser
      .getResolvedOptions(sysArgs, Seq("JOB_NAME", "sourcePath", "outputPath").toArray)

  def generateSchema[A](implicit tag: TypeTag[A]): StructType = schemaFor[A].dataType.asInstanceOf[StructType]
}
