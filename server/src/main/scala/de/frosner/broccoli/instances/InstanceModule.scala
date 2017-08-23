package de.frosner.broccoli.instances

import java.nio.file.FileSystems
import javax.inject.Singleton

import com.google.inject.{AbstractModule, Provides}
import de.frosner.broccoli.instances.conf.InstanceConfiguration
import net.codingwell.scalaguice.ScalaModule
import play.api.{Configuration, Logger}
import play.api.inject.ApplicationLifecycle
import play.api.libs.ws.WSClient

import scala.concurrent.Future
import scala.util.{Failure, Success, Try}

/**
  * Provide Instance and InstanceStorage configuration from the Play configuration
  */
class InstanceModule extends AbstractModule with ScalaModule {
  private val log = Logger(getClass)

  override def configure(): Unit = {}

  @Provides
  @Singleton
  def provideInstanceConfiguration(config: Configuration): InstanceConfiguration =
    InstanceConfiguration.fromConfig(config.underlying.getConfig("broccoli.instances"))

  @Provides
  @Singleton
  def provideInstanceStorage(instanceConfig: InstanceConfiguration,
                             ws: WSClient,
                             applicationLifecycle: ApplicationLifecycle): InstanceStorage = {
    val instanceStorage = instanceConfig.storageConfiguration.storageType match {
      case StorageType.FileSystem => {
        val config = instanceConfig.storageConfiguration.fsConfig
        val path = FileSystems.getDefault.getPath(config.url).toAbsolutePath
        FileSystemInstanceStorage(path.toFile)
      }
      case StorageType.CouchDB => {
        val config = instanceConfig.storageConfiguration.couchDBConfig
        CouchDBInstanceStorage(config.url, config.dbName, ws)
      }
    }

    applicationLifecycle.addStopHook(() => {
      log.info("Closing instanceStorage (stop hook)")
      if (!instanceStorage.isClosed) {
        instanceStorage.close()
      }
      Future.successful({})
    })
    instanceStorage
  }

}