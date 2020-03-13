package scripts

import org.apache.spark.sql.{functions, Dataset}
import shared.Spark.sparkSession.implicits._
import shared.{BaseGlueScript, Schema}

import shared.GlueUtils.generateSchema

case class SourceSchema(
  sku: Option[Long],
  productId: Option[Long],
  name: Option[String],
  source: Option[String],
  `type`: Option[String],
  active: Option[Boolean],
  lowPriceGuarantee: Option[Boolean],
  activeUpdateDate: Option[String],
  regularPrice: Option[Double],
  salePrice: Option[Double]
) extends Schema

case class TargetSchema(
  sku: Option[Long],
  productId: Option[Long],
  name: Option[String],
  source: Option[String],
  `type`: Option[String],
  active: Option[Boolean],
  lowPriceGuarantee: Option[Boolean],
  activeUpdateDate: Option[String],
  regularPrice: Option[Double],
  salePrice: Option[Double]
) extends Schema

object ApiScript extends BaseGlueScript[SourceSchema, TargetSchema] {
  override val partitions: Seq[String] = Seq("type")

  override def extract(sourcePath: String): Dataset[SourceSchema] =
    sparkSession.read.schema(generateSchema[SourceSchema]).json(sourcePath).as[SourceSchema].map(identity)

  override def transform(sourceData: Dataset[SourceSchema]): Dataset[TargetSchema] =
    sourceData.as[TargetSchema].map(identity)

  override def load(targetData: Dataset[TargetSchema], s3Bucket: String, partitions: Seq[String]): Unit =
    targetData.write
      .partitionBy(partitions: _*)
      .mode("overwrite")
      .option("compression", "gzip")
      .parquet(s3Bucket)
}
