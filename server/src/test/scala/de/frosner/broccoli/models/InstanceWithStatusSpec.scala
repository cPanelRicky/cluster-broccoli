package de.frosner.broccoli.models

import org.specs2.mutable.Specification

class InstanceWithStatusSpec extends Specification {
  "Instance 'anonymization' should" should {

    "remove one secret parameter value" in {
      val originalInstance = InstanceWithStatus(
        instance = Instance(
          id = "i",
          template = Template(
            id = "t",
            template = "{{id}} {{password}}",
            description = "d",
            parameterInfos = Map(
              "password" -> ParameterInfo(
                id = "secret password",
                name = None,
                default = None,
                secret = Some(true)
              )
            )
          ),
          parameterValues = Map(
            "id" -> "i",
            "password" -> "noone knows"
          )
        ),
        status = JobStatus.Unknown,
        services = Seq.empty,
        periodicRuns = Seq.empty
      )
      val expectedInstance = InstanceWithStatus(
        instance = Instance(
          id = "i",
          template = Template(
            id = "t",
            template = "{{id}} {{password}}",
            description = "d",
            parameterInfos = Map(
              "password" -> ParameterInfo(
                id = "secret password",
                name = None,
                default = None,
                secret = Some(true)
              )
            )
          ),
          parameterValues = Map(
            "id" -> "i",
            "password" -> null
          )
        ),
        status = JobStatus.Unknown,
        services = Seq.empty,
        periodicRuns = Seq.empty
      )
      InstanceWithStatus.removeSecretVariables(originalInstance) === expectedInstance
    }

    "remove multiple secret parameter values" in {
      val originalInstance = InstanceWithStatus(
        instance = Instance(
          id = "i",
          template = Template(
            id = "t",
            template = "{{id}} {{password}}",
            description = "d",
            parameterInfos = Map(
              "password" -> ParameterInfo(
                id = "secret password",
                name = None,
                default = None,
                secret = Some(true)
              ),
              "id" -> ParameterInfo(
                id = "secret id",
                name = None,
                default = None,
                secret = Some(true)
              )
            )
          ),
          parameterValues = Map(
            "id" -> "i",
            "password" -> "noone knows"
          )
        ),
        status = JobStatus.Unknown,
        services = Seq.empty,
        periodicRuns = Seq.empty
      )
      val expectedInstance = InstanceWithStatus(
        instance = Instance(
          id = "i",
          template = Template(
            id = "t",
            template = "{{id}} {{password}}",
            description = "d",
            parameterInfos = Map(
              "password" -> ParameterInfo(
                id = "secret password",
                name = None,
                default = None,
                secret = Some(true)
              ),
              "id" -> ParameterInfo(
                id = "secret id",
                name = None,
                default = None,
                secret = Some(true)
              )
            )
          ),
          parameterValues = Map(
            "id" -> null,
            "password" -> null
          )
        ),
        status = JobStatus.Unknown,
        services = Seq.empty,
        periodicRuns = Seq.empty
      )
      InstanceWithStatus.removeSecretVariables(originalInstance) === expectedInstance
    }

  }
}
