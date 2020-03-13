package shared

import com.amazonaws.services.glue.GlueContext
import com.amazonaws.services.glue.util.Job
import org.apache.spark.sql.{Dataset, SparkSession}

import scala.collection.JavaConverters._

abstract class BaseGlueScript[S <: Schema, T <: Schema] {
  implicit val sparkSession: SparkSession = Spark.sparkSession
  implicit val glueCtx: GlueContext = Spark.glueCtx

  protected def main(sysArgs: Array[String]): Unit = {
    val args: Map[String, String] = GlueUtils.parseArgs(sysArgs)

    Job.init(args("JOB_NAME"), glueCtx, args.asJava)
    run(args("sourcePath"), args("outputPath"))
    Job.commit()
  }

  def run(sourcePath: String, outputPath: String): Unit =
    load(transform(extract(sourcePath)), outputPath, partitions)

  protected val partitions: Seq[String]
  protected def extract(sourcePath: String): Dataset[S]
  protected def transform(sourceData: Dataset[S]): Dataset[T]
  protected def load(targetData: Dataset[T], s3Bucket: String, partitions: Seq[String]): Unit
}
