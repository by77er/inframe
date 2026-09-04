module DigitalOcean.Resource.App
  ( Args
  , Required
  , App
  , AppResource
  , args
  , create
  , DedicatedIps
  , DedicatedIpsRequired
  , dedicatedIpsArgs
  , dedicatedIpsId
  , dedicatedIpsIp
  , dedicatedIpsStatus
  , Spec
  , SpecRequired
  , specArgs
  , specAlert
  , specDatabase
  , specDisableEdgeCache
  , specDisableEmailObfuscation
  , specDomain
  , specDomains
  , specEgress
  , specEnhancedThreatControlEnabled
  , specEnv
  , specFeatures
  , specFunction
  , specIngress
  , specJob
  , specMaintenance
  , specRegion
  , specService
  , specStaticSite
  , specVpc
  , specWorker
  , SpecAlert
  , SpecAlertRequired
  , specAlertArgs
  , specAlertDestinations
  , specAlertDisabled
  , SpecAlertDestinations
  , SpecAlertDestinationsRequired
  , specAlertDestinationsArgs
  , specAlertDestinationsEmails
  , specAlertDestinationsSlackWebhooks
  , SpecAlertDestinationsSlackWebhooks
  , SpecAlertDestinationsSlackWebhooksRequired
  , specAlertDestinationsSlackWebhooksArgs
  , SpecDatabase
  , SpecDatabaseRequired
  , specDatabaseArgs
  , specDatabaseClusterName
  , specDatabaseDbName
  , specDatabaseDbUser
  , specDatabaseEngine
  , specDatabaseName
  , specDatabaseProduction
  , specDatabaseVersion
  , SpecDomain
  , SpecDomainRequired
  , specDomainArgs
  , specDomainType
  , specDomainWildcard
  , specDomainZone
  , SpecEgress
  , SpecEgressRequired
  , specEgressArgs
  , specEgressType
  , SpecEnv
  , SpecEnvRequired
  , specEnvArgs
  , specEnvKey
  , specEnvScope
  , specEnvType
  , specEnvValue
  , SpecFunction
  , SpecFunctionRequired
  , specFunctionArgs
  , specFunctionAlert
  , specFunctionBitbucket
  , specFunctionCors
  , specFunctionEnv
  , specFunctionGit
  , specFunctionGithub
  , specFunctionGitlab
  , specFunctionLogDestination
  , specFunctionRoutes
  , specFunctionSourceDir
  , SpecFunctionAlert
  , SpecFunctionAlertRequired
  , specFunctionAlertArgs
  , specFunctionAlertDestinations
  , specFunctionAlertDisabled
  , SpecFunctionAlertDestinations
  , SpecFunctionAlertDestinationsRequired
  , specFunctionAlertDestinationsArgs
  , specFunctionAlertDestinationsEmails
  , specFunctionAlertDestinationsSlackWebhooks
  , SpecFunctionAlertDestinationsSlackWebhooks
  , SpecFunctionAlertDestinationsSlackWebhooksRequired
  , specFunctionAlertDestinationsSlackWebhooksArgs
  , SpecFunctionBitbucket
  , SpecFunctionBitbucketRequired
  , specFunctionBitbucketArgs
  , specFunctionBitbucketBranch
  , specFunctionBitbucketDeployOnPush
  , specFunctionBitbucketRepo
  , SpecFunctionCors
  , SpecFunctionCorsRequired
  , specFunctionCorsArgs
  , specFunctionCorsAllowCredentials
  , specFunctionCorsAllowHeaders
  , specFunctionCorsAllowMethods
  , specFunctionCorsAllowOrigins
  , specFunctionCorsExposeHeaders
  , specFunctionCorsMaxAge
  , SpecFunctionCorsAllowOrigins
  , SpecFunctionCorsAllowOriginsRequired
  , specFunctionCorsAllowOriginsArgs
  , specFunctionCorsAllowOriginsExact
  , specFunctionCorsAllowOriginsPrefix
  , specFunctionCorsAllowOriginsRegex
  , SpecFunctionEnv
  , SpecFunctionEnvRequired
  , specFunctionEnvArgs
  , specFunctionEnvKey
  , specFunctionEnvScope
  , specFunctionEnvType
  , specFunctionEnvValue
  , SpecFunctionGit
  , SpecFunctionGitRequired
  , specFunctionGitArgs
  , specFunctionGitBranch
  , specFunctionGitRepoCloneUrl
  , SpecFunctionGithub
  , SpecFunctionGithubRequired
  , specFunctionGithubArgs
  , specFunctionGithubBranch
  , specFunctionGithubDeployOnPush
  , specFunctionGithubRepo
  , SpecFunctionGitlab
  , SpecFunctionGitlabRequired
  , specFunctionGitlabArgs
  , specFunctionGitlabBranch
  , specFunctionGitlabDeployOnPush
  , specFunctionGitlabRepo
  , SpecFunctionLogDestination
  , SpecFunctionLogDestinationRequired
  , specFunctionLogDestinationArgs
  , specFunctionLogDestinationDatadog
  , specFunctionLogDestinationLogtail
  , specFunctionLogDestinationOpenSearch
  , specFunctionLogDestinationPapertrail
  , SpecFunctionLogDestinationDatadog
  , SpecFunctionLogDestinationDatadogRequired
  , specFunctionLogDestinationDatadogArgs
  , specFunctionLogDestinationDatadogEndpoint
  , SpecFunctionLogDestinationLogtail
  , SpecFunctionLogDestinationLogtailRequired
  , specFunctionLogDestinationLogtailArgs
  , SpecFunctionLogDestinationOpenSearch
  , SpecFunctionLogDestinationOpenSearchRequired
  , specFunctionLogDestinationOpenSearchArgs
  , specFunctionLogDestinationOpenSearchClusterName
  , specFunctionLogDestinationOpenSearchEndpoint
  , specFunctionLogDestinationOpenSearchIndexName
  , SpecFunctionLogDestinationOpenSearchBasicAuth
  , SpecFunctionLogDestinationOpenSearchBasicAuthRequired
  , specFunctionLogDestinationOpenSearchBasicAuthArgs
  , specFunctionLogDestinationOpenSearchBasicAuthPassword
  , specFunctionLogDestinationOpenSearchBasicAuthUser
  , SpecFunctionLogDestinationPapertrail
  , SpecFunctionLogDestinationPapertrailRequired
  , specFunctionLogDestinationPapertrailArgs
  , SpecFunctionRoutes
  , SpecFunctionRoutesRequired
  , specFunctionRoutesArgs
  , specFunctionRoutesPath
  , specFunctionRoutesPreservePathPrefix
  , SpecIngress
  , SpecIngressRequired
  , specIngressArgs
  , specIngressRule
  , specIngressSecureHeader
  , SpecIngressRule
  , SpecIngressRuleRequired
  , specIngressRuleArgs
  , specIngressRuleComponent
  , specIngressRuleCors
  , specIngressRuleMatch
  , specIngressRuleRedirect
  , SpecIngressRuleComponent
  , SpecIngressRuleComponentRequired
  , specIngressRuleComponentArgs
  , specIngressRuleComponentName
  , specIngressRuleComponentPreservePathPrefix
  , specIngressRuleComponentRewrite
  , SpecIngressRuleCors
  , SpecIngressRuleCorsRequired
  , specIngressRuleCorsArgs
  , specIngressRuleCorsAllowCredentials
  , specIngressRuleCorsAllowHeaders
  , specIngressRuleCorsAllowMethods
  , specIngressRuleCorsAllowOrigins
  , specIngressRuleCorsExposeHeaders
  , specIngressRuleCorsMaxAge
  , SpecIngressRuleCorsAllowOrigins
  , SpecIngressRuleCorsAllowOriginsRequired
  , specIngressRuleCorsAllowOriginsArgs
  , specIngressRuleCorsAllowOriginsExact
  , specIngressRuleCorsAllowOriginsPrefix
  , specIngressRuleCorsAllowOriginsRegex
  , SpecIngressRuleMatch
  , SpecIngressRuleMatchRequired
  , specIngressRuleMatchArgs
  , specIngressRuleMatchAuthority
  , specIngressRuleMatchPath
  , SpecIngressRuleMatchAuthority
  , SpecIngressRuleMatchAuthorityRequired
  , specIngressRuleMatchAuthorityArgs
  , specIngressRuleMatchAuthorityExact
  , SpecIngressRuleMatchPath
  , SpecIngressRuleMatchPathRequired
  , specIngressRuleMatchPathArgs
  , specIngressRuleMatchPathPrefix
  , SpecIngressRuleRedirect
  , SpecIngressRuleRedirectRequired
  , specIngressRuleRedirectArgs
  , specIngressRuleRedirectAuthority
  , specIngressRuleRedirectPort
  , specIngressRuleRedirectRedirectCode
  , specIngressRuleRedirectScheme
  , specIngressRuleRedirectUri
  , SpecIngressSecureHeader
  , SpecIngressSecureHeaderRequired
  , specIngressSecureHeaderArgs
  , specIngressSecureHeaderKey
  , specIngressSecureHeaderValue
  , SpecJob
  , SpecJobRequired
  , specJobArgs
  , specJobAlert
  , specJobBitbucket
  , specJobBuildCommand
  , specJobDockerfilePath
  , specJobEnv
  , specJobEnvironmentSlug
  , specJobGit
  , specJobGithub
  , specJobGitlab
  , specJobImage
  , specJobInstanceCount
  , specJobInstanceSizeSlug
  , specJobKind
  , specJobLogDestination
  , specJobRunCommand
  , specJobSourceDir
  , specJobTermination
  , SpecJobAlert
  , SpecJobAlertRequired
  , specJobAlertArgs
  , specJobAlertDestinations
  , specJobAlertDisabled
  , SpecJobAlertDestinations
  , SpecJobAlertDestinationsRequired
  , specJobAlertDestinationsArgs
  , specJobAlertDestinationsEmails
  , specJobAlertDestinationsSlackWebhooks
  , SpecJobAlertDestinationsSlackWebhooks
  , SpecJobAlertDestinationsSlackWebhooksRequired
  , specJobAlertDestinationsSlackWebhooksArgs
  , SpecJobBitbucket
  , SpecJobBitbucketRequired
  , specJobBitbucketArgs
  , specJobBitbucketBranch
  , specJobBitbucketDeployOnPush
  , specJobBitbucketRepo
  , SpecJobEnv
  , SpecJobEnvRequired
  , specJobEnvArgs
  , specJobEnvKey
  , specJobEnvScope
  , specJobEnvType
  , specJobEnvValue
  , SpecJobGit
  , SpecJobGitRequired
  , specJobGitArgs
  , specJobGitBranch
  , specJobGitRepoCloneUrl
  , SpecJobGithub
  , SpecJobGithubRequired
  , specJobGithubArgs
  , specJobGithubBranch
  , specJobGithubDeployOnPush
  , specJobGithubRepo
  , SpecJobGitlab
  , SpecJobGitlabRequired
  , specJobGitlabArgs
  , specJobGitlabBranch
  , specJobGitlabDeployOnPush
  , specJobGitlabRepo
  , SpecJobImage
  , SpecJobImageRequired
  , specJobImageArgs
  , specJobImageDeployOnPush
  , specJobImageDigest
  , specJobImageRegistry
  , specJobImageRegistryCredentials
  , specJobImageTag
  , SpecJobImageDeployOnPush
  , SpecJobImageDeployOnPushRequired
  , specJobImageDeployOnPushArgs
  , specJobImageDeployOnPushEnabled
  , SpecJobLogDestination
  , SpecJobLogDestinationRequired
  , specJobLogDestinationArgs
  , specJobLogDestinationDatadog
  , specJobLogDestinationLogtail
  , specJobLogDestinationOpenSearch
  , specJobLogDestinationPapertrail
  , SpecJobLogDestinationDatadog
  , SpecJobLogDestinationDatadogRequired
  , specJobLogDestinationDatadogArgs
  , specJobLogDestinationDatadogEndpoint
  , SpecJobLogDestinationLogtail
  , SpecJobLogDestinationLogtailRequired
  , specJobLogDestinationLogtailArgs
  , SpecJobLogDestinationOpenSearch
  , SpecJobLogDestinationOpenSearchRequired
  , specJobLogDestinationOpenSearchArgs
  , specJobLogDestinationOpenSearchClusterName
  , specJobLogDestinationOpenSearchEndpoint
  , specJobLogDestinationOpenSearchIndexName
  , SpecJobLogDestinationOpenSearchBasicAuth
  , SpecJobLogDestinationOpenSearchBasicAuthRequired
  , specJobLogDestinationOpenSearchBasicAuthArgs
  , specJobLogDestinationOpenSearchBasicAuthPassword
  , specJobLogDestinationOpenSearchBasicAuthUser
  , SpecJobLogDestinationPapertrail
  , SpecJobLogDestinationPapertrailRequired
  , specJobLogDestinationPapertrailArgs
  , SpecJobTermination
  , SpecJobTerminationRequired
  , specJobTerminationArgs
  , specJobTerminationGracePeriodSeconds
  , SpecMaintenance
  , SpecMaintenanceRequired
  , specMaintenanceArgs
  , specMaintenanceArchive
  , specMaintenanceEnabled
  , specMaintenanceOfflinePageUrl
  , SpecService
  , SpecServiceRequired
  , specServiceArgs
  , specServiceAlert
  , specServiceAutoscaling
  , specServiceBitbucket
  , specServiceBuildCommand
  , specServiceCors
  , specServiceDockerfilePath
  , specServiceEnv
  , specServiceEnvironmentSlug
  , specServiceGit
  , specServiceGithub
  , specServiceGitlab
  , specServiceHealthCheck
  , specServiceHttpPort
  , specServiceImage
  , specServiceInstanceCount
  , specServiceInstanceSizeSlug
  , specServiceInternalPorts
  , specServiceLivenessHealthCheck
  , specServiceLogDestination
  , specServiceRoutes
  , specServiceRunCommand
  , specServiceSourceDir
  , specServiceTermination
  , SpecServiceAlert
  , SpecServiceAlertRequired
  , specServiceAlertArgs
  , specServiceAlertDestinations
  , specServiceAlertDisabled
  , SpecServiceAlertDestinations
  , SpecServiceAlertDestinationsRequired
  , specServiceAlertDestinationsArgs
  , specServiceAlertDestinationsEmails
  , specServiceAlertDestinationsSlackWebhooks
  , SpecServiceAlertDestinationsSlackWebhooks
  , SpecServiceAlertDestinationsSlackWebhooksRequired
  , specServiceAlertDestinationsSlackWebhooksArgs
  , SpecServiceAutoscaling
  , SpecServiceAutoscalingRequired
  , specServiceAutoscalingArgs
  , SpecServiceAutoscalingMetrics
  , SpecServiceAutoscalingMetricsRequired
  , specServiceAutoscalingMetricsArgs
  , specServiceAutoscalingMetricsCpu
  , SpecServiceAutoscalingMetricsCpu
  , SpecServiceAutoscalingMetricsCpuRequired
  , specServiceAutoscalingMetricsCpuArgs
  , SpecServiceBitbucket
  , SpecServiceBitbucketRequired
  , specServiceBitbucketArgs
  , specServiceBitbucketBranch
  , specServiceBitbucketDeployOnPush
  , specServiceBitbucketRepo
  , SpecServiceCors
  , SpecServiceCorsRequired
  , specServiceCorsArgs
  , specServiceCorsAllowCredentials
  , specServiceCorsAllowHeaders
  , specServiceCorsAllowMethods
  , specServiceCorsAllowOrigins
  , specServiceCorsExposeHeaders
  , specServiceCorsMaxAge
  , SpecServiceCorsAllowOrigins
  , SpecServiceCorsAllowOriginsRequired
  , specServiceCorsAllowOriginsArgs
  , specServiceCorsAllowOriginsExact
  , specServiceCorsAllowOriginsPrefix
  , specServiceCorsAllowOriginsRegex
  , SpecServiceEnv
  , SpecServiceEnvRequired
  , specServiceEnvArgs
  , specServiceEnvKey
  , specServiceEnvScope
  , specServiceEnvType
  , specServiceEnvValue
  , SpecServiceGit
  , SpecServiceGitRequired
  , specServiceGitArgs
  , specServiceGitBranch
  , specServiceGitRepoCloneUrl
  , SpecServiceGithub
  , SpecServiceGithubRequired
  , specServiceGithubArgs
  , specServiceGithubBranch
  , specServiceGithubDeployOnPush
  , specServiceGithubRepo
  , SpecServiceGitlab
  , SpecServiceGitlabRequired
  , specServiceGitlabArgs
  , specServiceGitlabBranch
  , specServiceGitlabDeployOnPush
  , specServiceGitlabRepo
  , SpecServiceHealthCheck
  , SpecServiceHealthCheckRequired
  , specServiceHealthCheckArgs
  , specServiceHealthCheckFailureThreshold
  , specServiceHealthCheckHttpPath
  , specServiceHealthCheckInitialDelaySeconds
  , specServiceHealthCheckPeriodSeconds
  , specServiceHealthCheckPort
  , specServiceHealthCheckSuccessThreshold
  , specServiceHealthCheckTimeoutSeconds
  , SpecServiceImage
  , SpecServiceImageRequired
  , specServiceImageArgs
  , specServiceImageDeployOnPush
  , specServiceImageDigest
  , specServiceImageRegistry
  , specServiceImageRegistryCredentials
  , specServiceImageTag
  , SpecServiceImageDeployOnPush
  , SpecServiceImageDeployOnPushRequired
  , specServiceImageDeployOnPushArgs
  , specServiceImageDeployOnPushEnabled
  , SpecServiceLivenessHealthCheck
  , SpecServiceLivenessHealthCheckRequired
  , specServiceLivenessHealthCheckArgs
  , specServiceLivenessHealthCheckFailureThreshold
  , specServiceLivenessHealthCheckHttpPath
  , specServiceLivenessHealthCheckInitialDelaySeconds
  , specServiceLivenessHealthCheckPeriodSeconds
  , specServiceLivenessHealthCheckPort
  , specServiceLivenessHealthCheckSuccessThreshold
  , specServiceLivenessHealthCheckTimeoutSeconds
  , SpecServiceLogDestination
  , SpecServiceLogDestinationRequired
  , specServiceLogDestinationArgs
  , specServiceLogDestinationDatadog
  , specServiceLogDestinationLogtail
  , specServiceLogDestinationOpenSearch
  , specServiceLogDestinationPapertrail
  , SpecServiceLogDestinationDatadog
  , SpecServiceLogDestinationDatadogRequired
  , specServiceLogDestinationDatadogArgs
  , specServiceLogDestinationDatadogEndpoint
  , SpecServiceLogDestinationLogtail
  , SpecServiceLogDestinationLogtailRequired
  , specServiceLogDestinationLogtailArgs
  , SpecServiceLogDestinationOpenSearch
  , SpecServiceLogDestinationOpenSearchRequired
  , specServiceLogDestinationOpenSearchArgs
  , specServiceLogDestinationOpenSearchClusterName
  , specServiceLogDestinationOpenSearchEndpoint
  , specServiceLogDestinationOpenSearchIndexName
  , SpecServiceLogDestinationOpenSearchBasicAuth
  , SpecServiceLogDestinationOpenSearchBasicAuthRequired
  , specServiceLogDestinationOpenSearchBasicAuthArgs
  , specServiceLogDestinationOpenSearchBasicAuthPassword
  , specServiceLogDestinationOpenSearchBasicAuthUser
  , SpecServiceLogDestinationPapertrail
  , SpecServiceLogDestinationPapertrailRequired
  , specServiceLogDestinationPapertrailArgs
  , SpecServiceRoutes
  , SpecServiceRoutesRequired
  , specServiceRoutesArgs
  , specServiceRoutesPath
  , specServiceRoutesPreservePathPrefix
  , SpecServiceTermination
  , SpecServiceTerminationRequired
  , specServiceTerminationArgs
  , specServiceTerminationDrainSeconds
  , specServiceTerminationGracePeriodSeconds
  , SpecStaticSite
  , SpecStaticSiteRequired
  , specStaticSiteArgs
  , specStaticSiteBitbucket
  , specStaticSiteBuildCommand
  , specStaticSiteCatchallDocument
  , specStaticSiteCors
  , specStaticSiteDockerfilePath
  , specStaticSiteEnv
  , specStaticSiteEnvironmentSlug
  , specStaticSiteErrorDocument
  , specStaticSiteGit
  , specStaticSiteGithub
  , specStaticSiteGitlab
  , specStaticSiteIndexDocument
  , specStaticSiteOutputDir
  , specStaticSiteRoutes
  , specStaticSiteSourceDir
  , SpecStaticSiteBitbucket
  , SpecStaticSiteBitbucketRequired
  , specStaticSiteBitbucketArgs
  , specStaticSiteBitbucketBranch
  , specStaticSiteBitbucketDeployOnPush
  , specStaticSiteBitbucketRepo
  , SpecStaticSiteCors
  , SpecStaticSiteCorsRequired
  , specStaticSiteCorsArgs
  , specStaticSiteCorsAllowCredentials
  , specStaticSiteCorsAllowHeaders
  , specStaticSiteCorsAllowMethods
  , specStaticSiteCorsAllowOrigins
  , specStaticSiteCorsExposeHeaders
  , specStaticSiteCorsMaxAge
  , SpecStaticSiteCorsAllowOrigins
  , SpecStaticSiteCorsAllowOriginsRequired
  , specStaticSiteCorsAllowOriginsArgs
  , specStaticSiteCorsAllowOriginsExact
  , specStaticSiteCorsAllowOriginsPrefix
  , specStaticSiteCorsAllowOriginsRegex
  , SpecStaticSiteEnv
  , SpecStaticSiteEnvRequired
  , specStaticSiteEnvArgs
  , specStaticSiteEnvKey
  , specStaticSiteEnvScope
  , specStaticSiteEnvType
  , specStaticSiteEnvValue
  , SpecStaticSiteGit
  , SpecStaticSiteGitRequired
  , specStaticSiteGitArgs
  , specStaticSiteGitBranch
  , specStaticSiteGitRepoCloneUrl
  , SpecStaticSiteGithub
  , SpecStaticSiteGithubRequired
  , specStaticSiteGithubArgs
  , specStaticSiteGithubBranch
  , specStaticSiteGithubDeployOnPush
  , specStaticSiteGithubRepo
  , SpecStaticSiteGitlab
  , SpecStaticSiteGitlabRequired
  , specStaticSiteGitlabArgs
  , specStaticSiteGitlabBranch
  , specStaticSiteGitlabDeployOnPush
  , specStaticSiteGitlabRepo
  , SpecStaticSiteRoutes
  , SpecStaticSiteRoutesRequired
  , specStaticSiteRoutesArgs
  , specStaticSiteRoutesPath
  , specStaticSiteRoutesPreservePathPrefix
  , SpecVpc
  , SpecVpcRequired
  , specVpcArgs
  , SpecWorker
  , SpecWorkerRequired
  , specWorkerArgs
  , specWorkerAlert
  , specWorkerAutoscaling
  , specWorkerBitbucket
  , specWorkerBuildCommand
  , specWorkerDockerfilePath
  , specWorkerEnv
  , specWorkerEnvironmentSlug
  , specWorkerGit
  , specWorkerGithub
  , specWorkerGitlab
  , specWorkerImage
  , specWorkerInstanceCount
  , specWorkerInstanceSizeSlug
  , specWorkerLivenessHealthCheck
  , specWorkerLogDestination
  , specWorkerRunCommand
  , specWorkerSourceDir
  , specWorkerTermination
  , SpecWorkerAlert
  , SpecWorkerAlertRequired
  , specWorkerAlertArgs
  , specWorkerAlertDestinations
  , specWorkerAlertDisabled
  , SpecWorkerAlertDestinations
  , SpecWorkerAlertDestinationsRequired
  , specWorkerAlertDestinationsArgs
  , specWorkerAlertDestinationsEmails
  , specWorkerAlertDestinationsSlackWebhooks
  , SpecWorkerAlertDestinationsSlackWebhooks
  , SpecWorkerAlertDestinationsSlackWebhooksRequired
  , specWorkerAlertDestinationsSlackWebhooksArgs
  , SpecWorkerAutoscaling
  , SpecWorkerAutoscalingRequired
  , specWorkerAutoscalingArgs
  , SpecWorkerAutoscalingMetrics
  , SpecWorkerAutoscalingMetricsRequired
  , specWorkerAutoscalingMetricsArgs
  , specWorkerAutoscalingMetricsCpu
  , SpecWorkerAutoscalingMetricsCpu
  , SpecWorkerAutoscalingMetricsCpuRequired
  , specWorkerAutoscalingMetricsCpuArgs
  , SpecWorkerBitbucket
  , SpecWorkerBitbucketRequired
  , specWorkerBitbucketArgs
  , specWorkerBitbucketBranch
  , specWorkerBitbucketDeployOnPush
  , specWorkerBitbucketRepo
  , SpecWorkerEnv
  , SpecWorkerEnvRequired
  , specWorkerEnvArgs
  , specWorkerEnvKey
  , specWorkerEnvScope
  , specWorkerEnvType
  , specWorkerEnvValue
  , SpecWorkerGit
  , SpecWorkerGitRequired
  , specWorkerGitArgs
  , specWorkerGitBranch
  , specWorkerGitRepoCloneUrl
  , SpecWorkerGithub
  , SpecWorkerGithubRequired
  , specWorkerGithubArgs
  , specWorkerGithubBranch
  , specWorkerGithubDeployOnPush
  , specWorkerGithubRepo
  , SpecWorkerGitlab
  , SpecWorkerGitlabRequired
  , specWorkerGitlabArgs
  , specWorkerGitlabBranch
  , specWorkerGitlabDeployOnPush
  , specWorkerGitlabRepo
  , SpecWorkerImage
  , SpecWorkerImageRequired
  , specWorkerImageArgs
  , specWorkerImageDeployOnPush
  , specWorkerImageDigest
  , specWorkerImageRegistry
  , specWorkerImageRegistryCredentials
  , specWorkerImageTag
  , SpecWorkerImageDeployOnPush
  , SpecWorkerImageDeployOnPushRequired
  , specWorkerImageDeployOnPushArgs
  , specWorkerImageDeployOnPushEnabled
  , SpecWorkerLivenessHealthCheck
  , SpecWorkerLivenessHealthCheckRequired
  , specWorkerLivenessHealthCheckArgs
  , specWorkerLivenessHealthCheckFailureThreshold
  , specWorkerLivenessHealthCheckHttpPath
  , specWorkerLivenessHealthCheckInitialDelaySeconds
  , specWorkerLivenessHealthCheckPeriodSeconds
  , specWorkerLivenessHealthCheckPort
  , specWorkerLivenessHealthCheckSuccessThreshold
  , specWorkerLivenessHealthCheckTimeoutSeconds
  , SpecWorkerLogDestination
  , SpecWorkerLogDestinationRequired
  , specWorkerLogDestinationArgs
  , specWorkerLogDestinationDatadog
  , specWorkerLogDestinationLogtail
  , specWorkerLogDestinationOpenSearch
  , specWorkerLogDestinationPapertrail
  , SpecWorkerLogDestinationDatadog
  , SpecWorkerLogDestinationDatadogRequired
  , specWorkerLogDestinationDatadogArgs
  , specWorkerLogDestinationDatadogEndpoint
  , SpecWorkerLogDestinationLogtail
  , SpecWorkerLogDestinationLogtailRequired
  , specWorkerLogDestinationLogtailArgs
  , SpecWorkerLogDestinationOpenSearch
  , SpecWorkerLogDestinationOpenSearchRequired
  , specWorkerLogDestinationOpenSearchArgs
  , specWorkerLogDestinationOpenSearchClusterName
  , specWorkerLogDestinationOpenSearchEndpoint
  , specWorkerLogDestinationOpenSearchIndexName
  , SpecWorkerLogDestinationOpenSearchBasicAuth
  , SpecWorkerLogDestinationOpenSearchBasicAuthRequired
  , specWorkerLogDestinationOpenSearchBasicAuthArgs
  , specWorkerLogDestinationOpenSearchBasicAuthPassword
  , specWorkerLogDestinationOpenSearchBasicAuthUser
  , SpecWorkerLogDestinationPapertrail
  , SpecWorkerLogDestinationPapertrailRequired
  , specWorkerLogDestinationPapertrailArgs
  , SpecWorkerTermination
  , SpecWorkerTerminationRequired
  , specWorkerTerminationArgs
  , specWorkerTerminationGracePeriodSeconds
  , Timeouts
  , TimeoutsRequired
  , timeoutsArgs
  , timeoutsCreate
  , dedicatedIps
  , deploymentPerPage
  , id
  , projectId
  , spec
  , timeouts
  ) where

import Prelude (bind, map, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import TofuDag.Builder (Infra, addResource, InputObject, inputObject, insertInputField, inputObjectJson)
import TofuDag.Core (Expr, Input, inputJson, arrayExprJson, Resource, resourceAttr)

data AppResource

newtype DedicatedIps = DedicatedIps InputObject

type DedicatedIpsRequired =
  {
  }

dedicatedIpsArgs :: DedicatedIpsRequired -> DedicatedIps
dedicatedIpsArgs _ = DedicatedIps (inputObject
  [
  ])

dedicatedIpsId :: Input String -> DedicatedIps -> DedicatedIps
dedicatedIpsId value (DedicatedIps values) = DedicatedIps (insertInputField "id" (inputJson value) values)

dedicatedIpsIp :: Input String -> DedicatedIps -> DedicatedIps
dedicatedIpsIp value (DedicatedIps values) = DedicatedIps (insertInputField "ip" (inputJson value) values)

dedicatedIpsStatus :: Input String -> DedicatedIps -> DedicatedIps
dedicatedIpsStatus value (DedicatedIps values) = DedicatedIps (insertInputField "status" (inputJson value) values)

dedicatedIpsJson :: DedicatedIps -> Json
dedicatedIpsJson (DedicatedIps values) = inputObjectJson values

newtype Spec = Spec InputObject

type SpecRequired =
  { name :: Input String
  }

specArgs :: SpecRequired -> Spec
specArgs required = Spec (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

specAlert :: Array SpecAlert -> Spec -> Spec
specAlert value (Spec values) = Spec (insertInputField "alert" (arrayExprJson (map specAlertJson value)) values)

specDatabase :: Array SpecDatabase -> Spec -> Spec
specDatabase value (Spec values) = Spec (insertInputField "database" (arrayExprJson (map specDatabaseJson value)) values)

specDisableEdgeCache :: Input Boolean -> Spec -> Spec
specDisableEdgeCache value (Spec values) = Spec (insertInputField "disable_edge_cache" (inputJson value) values)

specDisableEmailObfuscation :: Input Boolean -> Spec -> Spec
specDisableEmailObfuscation value (Spec values) = Spec (insertInputField "disable_email_obfuscation" (inputJson value) values)

specDomain :: Array SpecDomain -> Spec -> Spec
specDomain value (Spec values) = Spec (insertInputField "domain" (arrayExprJson (map specDomainJson value)) values)

specDomains :: Input (Array String) -> Spec -> Spec
specDomains value (Spec values) = Spec (insertInputField "domains" (inputJson value) values)

specEgress :: Array SpecEgress -> Spec -> Spec
specEgress value (Spec values) = Spec (insertInputField "egress" (arrayExprJson (map specEgressJson value)) values)

specEnhancedThreatControlEnabled :: Input Boolean -> Spec -> Spec
specEnhancedThreatControlEnabled value (Spec values) = Spec (insertInputField "enhanced_threat_control_enabled" (inputJson value) values)

specEnv :: Array SpecEnv -> Spec -> Spec
specEnv value (Spec values) = Spec (insertInputField "env" (arrayExprJson (map specEnvJson value)) values)

specFeatures :: Input (Array String) -> Spec -> Spec
specFeatures value (Spec values) = Spec (insertInputField "features" (inputJson value) values)

specFunction :: Array SpecFunction -> Spec -> Spec
specFunction value (Spec values) = Spec (insertInputField "function" (arrayExprJson (map specFunctionJson value)) values)

specIngress :: Array SpecIngress -> Spec -> Spec
specIngress value (Spec values) = Spec (insertInputField "ingress" (arrayExprJson (map specIngressJson value)) values)

specJob :: Array SpecJob -> Spec -> Spec
specJob value (Spec values) = Spec (insertInputField "job" (arrayExprJson (map specJobJson value)) values)

specMaintenance :: Array SpecMaintenance -> Spec -> Spec
specMaintenance value (Spec values) = Spec (insertInputField "maintenance" (arrayExprJson (map specMaintenanceJson value)) values)

specRegion :: Input String -> Spec -> Spec
specRegion value (Spec values) = Spec (insertInputField "region" (inputJson value) values)

specService :: Array SpecService -> Spec -> Spec
specService value (Spec values) = Spec (insertInputField "service" (arrayExprJson (map specServiceJson value)) values)

specStaticSite :: Array SpecStaticSite -> Spec -> Spec
specStaticSite value (Spec values) = Spec (insertInputField "static_site" (arrayExprJson (map specStaticSiteJson value)) values)

specVpc :: Array SpecVpc -> Spec -> Spec
specVpc value (Spec values) = Spec (insertInputField "vpc" (arrayExprJson (map specVpcJson value)) values)

specWorker :: Array SpecWorker -> Spec -> Spec
specWorker value (Spec values) = Spec (insertInputField "worker" (arrayExprJson (map specWorkerJson value)) values)

specJson :: Spec -> Json
specJson (Spec values) = inputObjectJson values

newtype SpecAlert = SpecAlert InputObject

type SpecAlertRequired =
  { rule :: Input String
  }

specAlertArgs :: SpecAlertRequired -> SpecAlert
specAlertArgs required = SpecAlert (inputObject
  [ Tuple "rule" (inputJson required.rule)
  ])

specAlertDestinations :: Array SpecAlertDestinations -> SpecAlert -> SpecAlert
specAlertDestinations value (SpecAlert values) = SpecAlert (insertInputField "destinations" (arrayExprJson (map specAlertDestinationsJson value)) values)

specAlertDisabled :: Input Boolean -> SpecAlert -> SpecAlert
specAlertDisabled value (SpecAlert values) = SpecAlert (insertInputField "disabled" (inputJson value) values)

specAlertJson :: SpecAlert -> Json
specAlertJson (SpecAlert values) = inputObjectJson values

newtype SpecAlertDestinations = SpecAlertDestinations InputObject

type SpecAlertDestinationsRequired =
  {
  }

specAlertDestinationsArgs :: SpecAlertDestinationsRequired -> SpecAlertDestinations
specAlertDestinationsArgs _ = SpecAlertDestinations (inputObject
  [
  ])

specAlertDestinationsEmails :: Input (Array String) -> SpecAlertDestinations -> SpecAlertDestinations
specAlertDestinationsEmails value (SpecAlertDestinations values) = SpecAlertDestinations (insertInputField "emails" (inputJson value) values)

specAlertDestinationsSlackWebhooks :: Array SpecAlertDestinationsSlackWebhooks -> SpecAlertDestinations -> SpecAlertDestinations
specAlertDestinationsSlackWebhooks value (SpecAlertDestinations values) = SpecAlertDestinations (insertInputField "slack_webhooks" (arrayExprJson (map specAlertDestinationsSlackWebhooksJson value)) values)

specAlertDestinationsJson :: SpecAlertDestinations -> Json
specAlertDestinationsJson (SpecAlertDestinations values) = inputObjectJson values

newtype SpecAlertDestinationsSlackWebhooks = SpecAlertDestinationsSlackWebhooks InputObject

type SpecAlertDestinationsSlackWebhooksRequired =
  { channel :: Input String
  , url :: Input String
  }

specAlertDestinationsSlackWebhooksArgs :: SpecAlertDestinationsSlackWebhooksRequired -> SpecAlertDestinationsSlackWebhooks
specAlertDestinationsSlackWebhooksArgs required = SpecAlertDestinationsSlackWebhooks (inputObject
  [ Tuple "channel" (inputJson required.channel)
  , Tuple "url" (inputJson required.url)
  ])

specAlertDestinationsSlackWebhooksJson :: SpecAlertDestinationsSlackWebhooks -> Json
specAlertDestinationsSlackWebhooksJson (SpecAlertDestinationsSlackWebhooks values) = inputObjectJson values

newtype SpecDatabase = SpecDatabase InputObject

type SpecDatabaseRequired =
  {
  }

specDatabaseArgs :: SpecDatabaseRequired -> SpecDatabase
specDatabaseArgs _ = SpecDatabase (inputObject
  [
  ])

specDatabaseClusterName :: Input String -> SpecDatabase -> SpecDatabase
specDatabaseClusterName value (SpecDatabase values) = SpecDatabase (insertInputField "cluster_name" (inputJson value) values)

specDatabaseDbName :: Input String -> SpecDatabase -> SpecDatabase
specDatabaseDbName value (SpecDatabase values) = SpecDatabase (insertInputField "db_name" (inputJson value) values)

specDatabaseDbUser :: Input String -> SpecDatabase -> SpecDatabase
specDatabaseDbUser value (SpecDatabase values) = SpecDatabase (insertInputField "db_user" (inputJson value) values)

specDatabaseEngine :: Input String -> SpecDatabase -> SpecDatabase
specDatabaseEngine value (SpecDatabase values) = SpecDatabase (insertInputField "engine" (inputJson value) values)

specDatabaseName :: Input String -> SpecDatabase -> SpecDatabase
specDatabaseName value (SpecDatabase values) = SpecDatabase (insertInputField "name" (inputJson value) values)

specDatabaseProduction :: Input Boolean -> SpecDatabase -> SpecDatabase
specDatabaseProduction value (SpecDatabase values) = SpecDatabase (insertInputField "production" (inputJson value) values)

specDatabaseVersion :: Input String -> SpecDatabase -> SpecDatabase
specDatabaseVersion value (SpecDatabase values) = SpecDatabase (insertInputField "version" (inputJson value) values)

specDatabaseJson :: SpecDatabase -> Json
specDatabaseJson (SpecDatabase values) = inputObjectJson values

newtype SpecDomain = SpecDomain InputObject

type SpecDomainRequired =
  { name :: Input String
  }

specDomainArgs :: SpecDomainRequired -> SpecDomain
specDomainArgs required = SpecDomain (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

specDomainType :: Input String -> SpecDomain -> SpecDomain
specDomainType value (SpecDomain values) = SpecDomain (insertInputField "type" (inputJson value) values)

specDomainWildcard :: Input Boolean -> SpecDomain -> SpecDomain
specDomainWildcard value (SpecDomain values) = SpecDomain (insertInputField "wildcard" (inputJson value) values)

specDomainZone :: Input String -> SpecDomain -> SpecDomain
specDomainZone value (SpecDomain values) = SpecDomain (insertInputField "zone" (inputJson value) values)

specDomainJson :: SpecDomain -> Json
specDomainJson (SpecDomain values) = inputObjectJson values

newtype SpecEgress = SpecEgress InputObject

type SpecEgressRequired =
  {
  }

specEgressArgs :: SpecEgressRequired -> SpecEgress
specEgressArgs _ = SpecEgress (inputObject
  [
  ])

specEgressType :: Input String -> SpecEgress -> SpecEgress
specEgressType value (SpecEgress values) = SpecEgress (insertInputField "type" (inputJson value) values)

specEgressJson :: SpecEgress -> Json
specEgressJson (SpecEgress values) = inputObjectJson values

newtype SpecEnv = SpecEnv InputObject

type SpecEnvRequired =
  {
  }

specEnvArgs :: SpecEnvRequired -> SpecEnv
specEnvArgs _ = SpecEnv (inputObject
  [
  ])

specEnvKey :: Input String -> SpecEnv -> SpecEnv
specEnvKey value (SpecEnv values) = SpecEnv (insertInputField "key" (inputJson value) values)

specEnvScope :: Input String -> SpecEnv -> SpecEnv
specEnvScope value (SpecEnv values) = SpecEnv (insertInputField "scope" (inputJson value) values)

specEnvType :: Input String -> SpecEnv -> SpecEnv
specEnvType value (SpecEnv values) = SpecEnv (insertInputField "type" (inputJson value) values)

specEnvValue :: Input String -> SpecEnv -> SpecEnv
specEnvValue value (SpecEnv values) = SpecEnv (insertInputField "value" (inputJson value) values)

specEnvJson :: SpecEnv -> Json
specEnvJson (SpecEnv values) = inputObjectJson values

newtype SpecFunction = SpecFunction InputObject

type SpecFunctionRequired =
  { name :: Input String
  }

specFunctionArgs :: SpecFunctionRequired -> SpecFunction
specFunctionArgs required = SpecFunction (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

specFunctionAlert :: Array SpecFunctionAlert -> SpecFunction -> SpecFunction
specFunctionAlert value (SpecFunction values) = SpecFunction (insertInputField "alert" (arrayExprJson (map specFunctionAlertJson value)) values)

specFunctionBitbucket :: Array SpecFunctionBitbucket -> SpecFunction -> SpecFunction
specFunctionBitbucket value (SpecFunction values) = SpecFunction (insertInputField "bitbucket" (arrayExprJson (map specFunctionBitbucketJson value)) values)

specFunctionCors :: Array SpecFunctionCors -> SpecFunction -> SpecFunction
specFunctionCors value (SpecFunction values) = SpecFunction (insertInputField "cors" (arrayExprJson (map specFunctionCorsJson value)) values)

specFunctionEnv :: Array SpecFunctionEnv -> SpecFunction -> SpecFunction
specFunctionEnv value (SpecFunction values) = SpecFunction (insertInputField "env" (arrayExprJson (map specFunctionEnvJson value)) values)

specFunctionGit :: Array SpecFunctionGit -> SpecFunction -> SpecFunction
specFunctionGit value (SpecFunction values) = SpecFunction (insertInputField "git" (arrayExprJson (map specFunctionGitJson value)) values)

specFunctionGithub :: Array SpecFunctionGithub -> SpecFunction -> SpecFunction
specFunctionGithub value (SpecFunction values) = SpecFunction (insertInputField "github" (arrayExprJson (map specFunctionGithubJson value)) values)

specFunctionGitlab :: Array SpecFunctionGitlab -> SpecFunction -> SpecFunction
specFunctionGitlab value (SpecFunction values) = SpecFunction (insertInputField "gitlab" (arrayExprJson (map specFunctionGitlabJson value)) values)

specFunctionLogDestination :: Array SpecFunctionLogDestination -> SpecFunction -> SpecFunction
specFunctionLogDestination value (SpecFunction values) = SpecFunction (insertInputField "log_destination" (arrayExprJson (map specFunctionLogDestinationJson value)) values)

specFunctionRoutes :: Array SpecFunctionRoutes -> SpecFunction -> SpecFunction
specFunctionRoutes value (SpecFunction values) = SpecFunction (insertInputField "routes" (arrayExprJson (map specFunctionRoutesJson value)) values)

specFunctionSourceDir :: Input String -> SpecFunction -> SpecFunction
specFunctionSourceDir value (SpecFunction values) = SpecFunction (insertInputField "source_dir" (inputJson value) values)

specFunctionJson :: SpecFunction -> Json
specFunctionJson (SpecFunction values) = inputObjectJson values

newtype SpecFunctionAlert = SpecFunctionAlert InputObject

type SpecFunctionAlertRequired =
  { operator :: Input String
  , rule :: Input String
  , value :: Input Number
  , window :: Input String
  }

specFunctionAlertArgs :: SpecFunctionAlertRequired -> SpecFunctionAlert
specFunctionAlertArgs required = SpecFunctionAlert (inputObject
  [ Tuple "operator" (inputJson required.operator)
  , Tuple "rule" (inputJson required.rule)
  , Tuple "value" (inputJson required.value)
  , Tuple "window" (inputJson required.window)
  ])

specFunctionAlertDestinations :: Array SpecFunctionAlertDestinations -> SpecFunctionAlert -> SpecFunctionAlert
specFunctionAlertDestinations value (SpecFunctionAlert values) = SpecFunctionAlert (insertInputField "destinations" (arrayExprJson (map specFunctionAlertDestinationsJson value)) values)

specFunctionAlertDisabled :: Input Boolean -> SpecFunctionAlert -> SpecFunctionAlert
specFunctionAlertDisabled value (SpecFunctionAlert values) = SpecFunctionAlert (insertInputField "disabled" (inputJson value) values)

specFunctionAlertJson :: SpecFunctionAlert -> Json
specFunctionAlertJson (SpecFunctionAlert values) = inputObjectJson values

newtype SpecFunctionAlertDestinations = SpecFunctionAlertDestinations InputObject

type SpecFunctionAlertDestinationsRequired =
  {
  }

specFunctionAlertDestinationsArgs :: SpecFunctionAlertDestinationsRequired -> SpecFunctionAlertDestinations
specFunctionAlertDestinationsArgs _ = SpecFunctionAlertDestinations (inputObject
  [
  ])

specFunctionAlertDestinationsEmails :: Input (Array String) -> SpecFunctionAlertDestinations -> SpecFunctionAlertDestinations
specFunctionAlertDestinationsEmails value (SpecFunctionAlertDestinations values) = SpecFunctionAlertDestinations (insertInputField "emails" (inputJson value) values)

specFunctionAlertDestinationsSlackWebhooks :: Array SpecFunctionAlertDestinationsSlackWebhooks -> SpecFunctionAlertDestinations -> SpecFunctionAlertDestinations
specFunctionAlertDestinationsSlackWebhooks value (SpecFunctionAlertDestinations values) = SpecFunctionAlertDestinations (insertInputField "slack_webhooks" (arrayExprJson (map specFunctionAlertDestinationsSlackWebhooksJson value)) values)

specFunctionAlertDestinationsJson :: SpecFunctionAlertDestinations -> Json
specFunctionAlertDestinationsJson (SpecFunctionAlertDestinations values) = inputObjectJson values

newtype SpecFunctionAlertDestinationsSlackWebhooks = SpecFunctionAlertDestinationsSlackWebhooks InputObject

type SpecFunctionAlertDestinationsSlackWebhooksRequired =
  { channel :: Input String
  , url :: Input String
  }

specFunctionAlertDestinationsSlackWebhooksArgs :: SpecFunctionAlertDestinationsSlackWebhooksRequired -> SpecFunctionAlertDestinationsSlackWebhooks
specFunctionAlertDestinationsSlackWebhooksArgs required = SpecFunctionAlertDestinationsSlackWebhooks (inputObject
  [ Tuple "channel" (inputJson required.channel)
  , Tuple "url" (inputJson required.url)
  ])

specFunctionAlertDestinationsSlackWebhooksJson :: SpecFunctionAlertDestinationsSlackWebhooks -> Json
specFunctionAlertDestinationsSlackWebhooksJson (SpecFunctionAlertDestinationsSlackWebhooks values) = inputObjectJson values

newtype SpecFunctionBitbucket = SpecFunctionBitbucket InputObject

type SpecFunctionBitbucketRequired =
  {
  }

specFunctionBitbucketArgs :: SpecFunctionBitbucketRequired -> SpecFunctionBitbucket
specFunctionBitbucketArgs _ = SpecFunctionBitbucket (inputObject
  [
  ])

specFunctionBitbucketBranch :: Input String -> SpecFunctionBitbucket -> SpecFunctionBitbucket
specFunctionBitbucketBranch value (SpecFunctionBitbucket values) = SpecFunctionBitbucket (insertInputField "branch" (inputJson value) values)

specFunctionBitbucketDeployOnPush :: Input Boolean -> SpecFunctionBitbucket -> SpecFunctionBitbucket
specFunctionBitbucketDeployOnPush value (SpecFunctionBitbucket values) = SpecFunctionBitbucket (insertInputField "deploy_on_push" (inputJson value) values)

specFunctionBitbucketRepo :: Input String -> SpecFunctionBitbucket -> SpecFunctionBitbucket
specFunctionBitbucketRepo value (SpecFunctionBitbucket values) = SpecFunctionBitbucket (insertInputField "repo" (inputJson value) values)

specFunctionBitbucketJson :: SpecFunctionBitbucket -> Json
specFunctionBitbucketJson (SpecFunctionBitbucket values) = inputObjectJson values

newtype SpecFunctionCors = SpecFunctionCors InputObject

type SpecFunctionCorsRequired =
  {
  }

specFunctionCorsArgs :: SpecFunctionCorsRequired -> SpecFunctionCors
specFunctionCorsArgs _ = SpecFunctionCors (inputObject
  [
  ])

specFunctionCorsAllowCredentials :: Input Boolean -> SpecFunctionCors -> SpecFunctionCors
specFunctionCorsAllowCredentials value (SpecFunctionCors values) = SpecFunctionCors (insertInputField "allow_credentials" (inputJson value) values)

specFunctionCorsAllowHeaders :: Input (Array String) -> SpecFunctionCors -> SpecFunctionCors
specFunctionCorsAllowHeaders value (SpecFunctionCors values) = SpecFunctionCors (insertInputField "allow_headers" (inputJson value) values)

specFunctionCorsAllowMethods :: Input (Array String) -> SpecFunctionCors -> SpecFunctionCors
specFunctionCorsAllowMethods value (SpecFunctionCors values) = SpecFunctionCors (insertInputField "allow_methods" (inputJson value) values)

specFunctionCorsAllowOrigins :: Array SpecFunctionCorsAllowOrigins -> SpecFunctionCors -> SpecFunctionCors
specFunctionCorsAllowOrigins value (SpecFunctionCors values) = SpecFunctionCors (insertInputField "allow_origins" (arrayExprJson (map specFunctionCorsAllowOriginsJson value)) values)

specFunctionCorsExposeHeaders :: Input (Array String) -> SpecFunctionCors -> SpecFunctionCors
specFunctionCorsExposeHeaders value (SpecFunctionCors values) = SpecFunctionCors (insertInputField "expose_headers" (inputJson value) values)

specFunctionCorsMaxAge :: Input String -> SpecFunctionCors -> SpecFunctionCors
specFunctionCorsMaxAge value (SpecFunctionCors values) = SpecFunctionCors (insertInputField "max_age" (inputJson value) values)

specFunctionCorsJson :: SpecFunctionCors -> Json
specFunctionCorsJson (SpecFunctionCors values) = inputObjectJson values

newtype SpecFunctionCorsAllowOrigins = SpecFunctionCorsAllowOrigins InputObject

type SpecFunctionCorsAllowOriginsRequired =
  {
  }

specFunctionCorsAllowOriginsArgs :: SpecFunctionCorsAllowOriginsRequired -> SpecFunctionCorsAllowOrigins
specFunctionCorsAllowOriginsArgs _ = SpecFunctionCorsAllowOrigins (inputObject
  [
  ])

specFunctionCorsAllowOriginsExact :: Input String -> SpecFunctionCorsAllowOrigins -> SpecFunctionCorsAllowOrigins
specFunctionCorsAllowOriginsExact value (SpecFunctionCorsAllowOrigins values) = SpecFunctionCorsAllowOrigins (insertInputField "exact" (inputJson value) values)

specFunctionCorsAllowOriginsPrefix :: Input String -> SpecFunctionCorsAllowOrigins -> SpecFunctionCorsAllowOrigins
specFunctionCorsAllowOriginsPrefix value (SpecFunctionCorsAllowOrigins values) = SpecFunctionCorsAllowOrigins (insertInputField "prefix" (inputJson value) values)

specFunctionCorsAllowOriginsRegex :: Input String -> SpecFunctionCorsAllowOrigins -> SpecFunctionCorsAllowOrigins
specFunctionCorsAllowOriginsRegex value (SpecFunctionCorsAllowOrigins values) = SpecFunctionCorsAllowOrigins (insertInputField "regex" (inputJson value) values)

specFunctionCorsAllowOriginsJson :: SpecFunctionCorsAllowOrigins -> Json
specFunctionCorsAllowOriginsJson (SpecFunctionCorsAllowOrigins values) = inputObjectJson values

newtype SpecFunctionEnv = SpecFunctionEnv InputObject

type SpecFunctionEnvRequired =
  {
  }

specFunctionEnvArgs :: SpecFunctionEnvRequired -> SpecFunctionEnv
specFunctionEnvArgs _ = SpecFunctionEnv (inputObject
  [
  ])

specFunctionEnvKey :: Input String -> SpecFunctionEnv -> SpecFunctionEnv
specFunctionEnvKey value (SpecFunctionEnv values) = SpecFunctionEnv (insertInputField "key" (inputJson value) values)

specFunctionEnvScope :: Input String -> SpecFunctionEnv -> SpecFunctionEnv
specFunctionEnvScope value (SpecFunctionEnv values) = SpecFunctionEnv (insertInputField "scope" (inputJson value) values)

specFunctionEnvType :: Input String -> SpecFunctionEnv -> SpecFunctionEnv
specFunctionEnvType value (SpecFunctionEnv values) = SpecFunctionEnv (insertInputField "type" (inputJson value) values)

specFunctionEnvValue :: Input String -> SpecFunctionEnv -> SpecFunctionEnv
specFunctionEnvValue value (SpecFunctionEnv values) = SpecFunctionEnv (insertInputField "value" (inputJson value) values)

specFunctionEnvJson :: SpecFunctionEnv -> Json
specFunctionEnvJson (SpecFunctionEnv values) = inputObjectJson values

newtype SpecFunctionGit = SpecFunctionGit InputObject

type SpecFunctionGitRequired =
  {
  }

specFunctionGitArgs :: SpecFunctionGitRequired -> SpecFunctionGit
specFunctionGitArgs _ = SpecFunctionGit (inputObject
  [
  ])

specFunctionGitBranch :: Input String -> SpecFunctionGit -> SpecFunctionGit
specFunctionGitBranch value (SpecFunctionGit values) = SpecFunctionGit (insertInputField "branch" (inputJson value) values)

specFunctionGitRepoCloneUrl :: Input String -> SpecFunctionGit -> SpecFunctionGit
specFunctionGitRepoCloneUrl value (SpecFunctionGit values) = SpecFunctionGit (insertInputField "repo_clone_url" (inputJson value) values)

specFunctionGitJson :: SpecFunctionGit -> Json
specFunctionGitJson (SpecFunctionGit values) = inputObjectJson values

newtype SpecFunctionGithub = SpecFunctionGithub InputObject

type SpecFunctionGithubRequired =
  {
  }

specFunctionGithubArgs :: SpecFunctionGithubRequired -> SpecFunctionGithub
specFunctionGithubArgs _ = SpecFunctionGithub (inputObject
  [
  ])

specFunctionGithubBranch :: Input String -> SpecFunctionGithub -> SpecFunctionGithub
specFunctionGithubBranch value (SpecFunctionGithub values) = SpecFunctionGithub (insertInputField "branch" (inputJson value) values)

specFunctionGithubDeployOnPush :: Input Boolean -> SpecFunctionGithub -> SpecFunctionGithub
specFunctionGithubDeployOnPush value (SpecFunctionGithub values) = SpecFunctionGithub (insertInputField "deploy_on_push" (inputJson value) values)

specFunctionGithubRepo :: Input String -> SpecFunctionGithub -> SpecFunctionGithub
specFunctionGithubRepo value (SpecFunctionGithub values) = SpecFunctionGithub (insertInputField "repo" (inputJson value) values)

specFunctionGithubJson :: SpecFunctionGithub -> Json
specFunctionGithubJson (SpecFunctionGithub values) = inputObjectJson values

newtype SpecFunctionGitlab = SpecFunctionGitlab InputObject

type SpecFunctionGitlabRequired =
  {
  }

specFunctionGitlabArgs :: SpecFunctionGitlabRequired -> SpecFunctionGitlab
specFunctionGitlabArgs _ = SpecFunctionGitlab (inputObject
  [
  ])

specFunctionGitlabBranch :: Input String -> SpecFunctionGitlab -> SpecFunctionGitlab
specFunctionGitlabBranch value (SpecFunctionGitlab values) = SpecFunctionGitlab (insertInputField "branch" (inputJson value) values)

specFunctionGitlabDeployOnPush :: Input Boolean -> SpecFunctionGitlab -> SpecFunctionGitlab
specFunctionGitlabDeployOnPush value (SpecFunctionGitlab values) = SpecFunctionGitlab (insertInputField "deploy_on_push" (inputJson value) values)

specFunctionGitlabRepo :: Input String -> SpecFunctionGitlab -> SpecFunctionGitlab
specFunctionGitlabRepo value (SpecFunctionGitlab values) = SpecFunctionGitlab (insertInputField "repo" (inputJson value) values)

specFunctionGitlabJson :: SpecFunctionGitlab -> Json
specFunctionGitlabJson (SpecFunctionGitlab values) = inputObjectJson values

newtype SpecFunctionLogDestination = SpecFunctionLogDestination InputObject

type SpecFunctionLogDestinationRequired =
  { name :: Input String
  }

specFunctionLogDestinationArgs :: SpecFunctionLogDestinationRequired -> SpecFunctionLogDestination
specFunctionLogDestinationArgs required = SpecFunctionLogDestination (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

specFunctionLogDestinationDatadog :: Array SpecFunctionLogDestinationDatadog -> SpecFunctionLogDestination -> SpecFunctionLogDestination
specFunctionLogDestinationDatadog value (SpecFunctionLogDestination values) = SpecFunctionLogDestination (insertInputField "datadog" (arrayExprJson (map specFunctionLogDestinationDatadogJson value)) values)

specFunctionLogDestinationLogtail :: Array SpecFunctionLogDestinationLogtail -> SpecFunctionLogDestination -> SpecFunctionLogDestination
specFunctionLogDestinationLogtail value (SpecFunctionLogDestination values) = SpecFunctionLogDestination (insertInputField "logtail" (arrayExprJson (map specFunctionLogDestinationLogtailJson value)) values)

specFunctionLogDestinationOpenSearch :: Array SpecFunctionLogDestinationOpenSearch -> SpecFunctionLogDestination -> SpecFunctionLogDestination
specFunctionLogDestinationOpenSearch value (SpecFunctionLogDestination values) = SpecFunctionLogDestination (insertInputField "open_search" (arrayExprJson (map specFunctionLogDestinationOpenSearchJson value)) values)

specFunctionLogDestinationPapertrail :: Array SpecFunctionLogDestinationPapertrail -> SpecFunctionLogDestination -> SpecFunctionLogDestination
specFunctionLogDestinationPapertrail value (SpecFunctionLogDestination values) = SpecFunctionLogDestination (insertInputField "papertrail" (arrayExprJson (map specFunctionLogDestinationPapertrailJson value)) values)

specFunctionLogDestinationJson :: SpecFunctionLogDestination -> Json
specFunctionLogDestinationJson (SpecFunctionLogDestination values) = inputObjectJson values

newtype SpecFunctionLogDestinationDatadog = SpecFunctionLogDestinationDatadog InputObject

type SpecFunctionLogDestinationDatadogRequired =
  { apiKey :: Input String
  }

specFunctionLogDestinationDatadogArgs :: SpecFunctionLogDestinationDatadogRequired -> SpecFunctionLogDestinationDatadog
specFunctionLogDestinationDatadogArgs required = SpecFunctionLogDestinationDatadog (inputObject
  [ Tuple "api_key" (inputJson required.apiKey)
  ])

specFunctionLogDestinationDatadogEndpoint :: Input String -> SpecFunctionLogDestinationDatadog -> SpecFunctionLogDestinationDatadog
specFunctionLogDestinationDatadogEndpoint value (SpecFunctionLogDestinationDatadog values) = SpecFunctionLogDestinationDatadog (insertInputField "endpoint" (inputJson value) values)

specFunctionLogDestinationDatadogJson :: SpecFunctionLogDestinationDatadog -> Json
specFunctionLogDestinationDatadogJson (SpecFunctionLogDestinationDatadog values) = inputObjectJson values

newtype SpecFunctionLogDestinationLogtail = SpecFunctionLogDestinationLogtail InputObject

type SpecFunctionLogDestinationLogtailRequired =
  { token :: Input String
  }

specFunctionLogDestinationLogtailArgs :: SpecFunctionLogDestinationLogtailRequired -> SpecFunctionLogDestinationLogtail
specFunctionLogDestinationLogtailArgs required = SpecFunctionLogDestinationLogtail (inputObject
  [ Tuple "token" (inputJson required.token)
  ])

specFunctionLogDestinationLogtailJson :: SpecFunctionLogDestinationLogtail -> Json
specFunctionLogDestinationLogtailJson (SpecFunctionLogDestinationLogtail values) = inputObjectJson values

newtype SpecFunctionLogDestinationOpenSearch = SpecFunctionLogDestinationOpenSearch InputObject

type SpecFunctionLogDestinationOpenSearchRequired =
  { basicAuth :: Array SpecFunctionLogDestinationOpenSearchBasicAuth
  }

specFunctionLogDestinationOpenSearchArgs :: SpecFunctionLogDestinationOpenSearchRequired -> SpecFunctionLogDestinationOpenSearch
specFunctionLogDestinationOpenSearchArgs required = SpecFunctionLogDestinationOpenSearch (inputObject
  [ Tuple "basic_auth" (arrayExprJson (map specFunctionLogDestinationOpenSearchBasicAuthJson required.basicAuth))
  ])

specFunctionLogDestinationOpenSearchClusterName :: Input String -> SpecFunctionLogDestinationOpenSearch -> SpecFunctionLogDestinationOpenSearch
specFunctionLogDestinationOpenSearchClusterName value (SpecFunctionLogDestinationOpenSearch values) = SpecFunctionLogDestinationOpenSearch (insertInputField "cluster_name" (inputJson value) values)

specFunctionLogDestinationOpenSearchEndpoint :: Input String -> SpecFunctionLogDestinationOpenSearch -> SpecFunctionLogDestinationOpenSearch
specFunctionLogDestinationOpenSearchEndpoint value (SpecFunctionLogDestinationOpenSearch values) = SpecFunctionLogDestinationOpenSearch (insertInputField "endpoint" (inputJson value) values)

specFunctionLogDestinationOpenSearchIndexName :: Input String -> SpecFunctionLogDestinationOpenSearch -> SpecFunctionLogDestinationOpenSearch
specFunctionLogDestinationOpenSearchIndexName value (SpecFunctionLogDestinationOpenSearch values) = SpecFunctionLogDestinationOpenSearch (insertInputField "index_name" (inputJson value) values)

specFunctionLogDestinationOpenSearchJson :: SpecFunctionLogDestinationOpenSearch -> Json
specFunctionLogDestinationOpenSearchJson (SpecFunctionLogDestinationOpenSearch values) = inputObjectJson values

newtype SpecFunctionLogDestinationOpenSearchBasicAuth = SpecFunctionLogDestinationOpenSearchBasicAuth InputObject

type SpecFunctionLogDestinationOpenSearchBasicAuthRequired =
  {
  }

specFunctionLogDestinationOpenSearchBasicAuthArgs :: SpecFunctionLogDestinationOpenSearchBasicAuthRequired -> SpecFunctionLogDestinationOpenSearchBasicAuth
specFunctionLogDestinationOpenSearchBasicAuthArgs _ = SpecFunctionLogDestinationOpenSearchBasicAuth (inputObject
  [
  ])

specFunctionLogDestinationOpenSearchBasicAuthPassword :: Input String -> SpecFunctionLogDestinationOpenSearchBasicAuth -> SpecFunctionLogDestinationOpenSearchBasicAuth
specFunctionLogDestinationOpenSearchBasicAuthPassword value (SpecFunctionLogDestinationOpenSearchBasicAuth values) = SpecFunctionLogDestinationOpenSearchBasicAuth (insertInputField "password" (inputJson value) values)

specFunctionLogDestinationOpenSearchBasicAuthUser :: Input String -> SpecFunctionLogDestinationOpenSearchBasicAuth -> SpecFunctionLogDestinationOpenSearchBasicAuth
specFunctionLogDestinationOpenSearchBasicAuthUser value (SpecFunctionLogDestinationOpenSearchBasicAuth values) = SpecFunctionLogDestinationOpenSearchBasicAuth (insertInputField "user" (inputJson value) values)

specFunctionLogDestinationOpenSearchBasicAuthJson :: SpecFunctionLogDestinationOpenSearchBasicAuth -> Json
specFunctionLogDestinationOpenSearchBasicAuthJson (SpecFunctionLogDestinationOpenSearchBasicAuth values) = inputObjectJson values

newtype SpecFunctionLogDestinationPapertrail = SpecFunctionLogDestinationPapertrail InputObject

type SpecFunctionLogDestinationPapertrailRequired =
  { endpoint :: Input String
  }

specFunctionLogDestinationPapertrailArgs :: SpecFunctionLogDestinationPapertrailRequired -> SpecFunctionLogDestinationPapertrail
specFunctionLogDestinationPapertrailArgs required = SpecFunctionLogDestinationPapertrail (inputObject
  [ Tuple "endpoint" (inputJson required.endpoint)
  ])

specFunctionLogDestinationPapertrailJson :: SpecFunctionLogDestinationPapertrail -> Json
specFunctionLogDestinationPapertrailJson (SpecFunctionLogDestinationPapertrail values) = inputObjectJson values

newtype SpecFunctionRoutes = SpecFunctionRoutes InputObject

type SpecFunctionRoutesRequired =
  {
  }

specFunctionRoutesArgs :: SpecFunctionRoutesRequired -> SpecFunctionRoutes
specFunctionRoutesArgs _ = SpecFunctionRoutes (inputObject
  [
  ])

specFunctionRoutesPath :: Input String -> SpecFunctionRoutes -> SpecFunctionRoutes
specFunctionRoutesPath value (SpecFunctionRoutes values) = SpecFunctionRoutes (insertInputField "path" (inputJson value) values)

specFunctionRoutesPreservePathPrefix :: Input Boolean -> SpecFunctionRoutes -> SpecFunctionRoutes
specFunctionRoutesPreservePathPrefix value (SpecFunctionRoutes values) = SpecFunctionRoutes (insertInputField "preserve_path_prefix" (inputJson value) values)

specFunctionRoutesJson :: SpecFunctionRoutes -> Json
specFunctionRoutesJson (SpecFunctionRoutes values) = inputObjectJson values

newtype SpecIngress = SpecIngress InputObject

type SpecIngressRequired =
  {
  }

specIngressArgs :: SpecIngressRequired -> SpecIngress
specIngressArgs _ = SpecIngress (inputObject
  [
  ])

specIngressRule :: Array SpecIngressRule -> SpecIngress -> SpecIngress
specIngressRule value (SpecIngress values) = SpecIngress (insertInputField "rule" (arrayExprJson (map specIngressRuleJson value)) values)

specIngressSecureHeader :: Array SpecIngressSecureHeader -> SpecIngress -> SpecIngress
specIngressSecureHeader value (SpecIngress values) = SpecIngress (insertInputField "secure_header" (arrayExprJson (map specIngressSecureHeaderJson value)) values)

specIngressJson :: SpecIngress -> Json
specIngressJson (SpecIngress values) = inputObjectJson values

newtype SpecIngressRule = SpecIngressRule InputObject

type SpecIngressRuleRequired =
  {
  }

specIngressRuleArgs :: SpecIngressRuleRequired -> SpecIngressRule
specIngressRuleArgs _ = SpecIngressRule (inputObject
  [
  ])

specIngressRuleComponent :: Array SpecIngressRuleComponent -> SpecIngressRule -> SpecIngressRule
specIngressRuleComponent value (SpecIngressRule values) = SpecIngressRule (insertInputField "component" (arrayExprJson (map specIngressRuleComponentJson value)) values)

specIngressRuleCors :: Array SpecIngressRuleCors -> SpecIngressRule -> SpecIngressRule
specIngressRuleCors value (SpecIngressRule values) = SpecIngressRule (insertInputField "cors" (arrayExprJson (map specIngressRuleCorsJson value)) values)

specIngressRuleMatch :: Array SpecIngressRuleMatch -> SpecIngressRule -> SpecIngressRule
specIngressRuleMatch value (SpecIngressRule values) = SpecIngressRule (insertInputField "match" (arrayExprJson (map specIngressRuleMatchJson value)) values)

specIngressRuleRedirect :: Array SpecIngressRuleRedirect -> SpecIngressRule -> SpecIngressRule
specIngressRuleRedirect value (SpecIngressRule values) = SpecIngressRule (insertInputField "redirect" (arrayExprJson (map specIngressRuleRedirectJson value)) values)

specIngressRuleJson :: SpecIngressRule -> Json
specIngressRuleJson (SpecIngressRule values) = inputObjectJson values

newtype SpecIngressRuleComponent = SpecIngressRuleComponent InputObject

type SpecIngressRuleComponentRequired =
  {
  }

specIngressRuleComponentArgs :: SpecIngressRuleComponentRequired -> SpecIngressRuleComponent
specIngressRuleComponentArgs _ = SpecIngressRuleComponent (inputObject
  [
  ])

specIngressRuleComponentName :: Input String -> SpecIngressRuleComponent -> SpecIngressRuleComponent
specIngressRuleComponentName value (SpecIngressRuleComponent values) = SpecIngressRuleComponent (insertInputField "name" (inputJson value) values)

specIngressRuleComponentPreservePathPrefix :: Input Boolean -> SpecIngressRuleComponent -> SpecIngressRuleComponent
specIngressRuleComponentPreservePathPrefix value (SpecIngressRuleComponent values) = SpecIngressRuleComponent (insertInputField "preserve_path_prefix" (inputJson value) values)

specIngressRuleComponentRewrite :: Input String -> SpecIngressRuleComponent -> SpecIngressRuleComponent
specIngressRuleComponentRewrite value (SpecIngressRuleComponent values) = SpecIngressRuleComponent (insertInputField "rewrite" (inputJson value) values)

specIngressRuleComponentJson :: SpecIngressRuleComponent -> Json
specIngressRuleComponentJson (SpecIngressRuleComponent values) = inputObjectJson values

newtype SpecIngressRuleCors = SpecIngressRuleCors InputObject

type SpecIngressRuleCorsRequired =
  {
  }

specIngressRuleCorsArgs :: SpecIngressRuleCorsRequired -> SpecIngressRuleCors
specIngressRuleCorsArgs _ = SpecIngressRuleCors (inputObject
  [
  ])

specIngressRuleCorsAllowCredentials :: Input Boolean -> SpecIngressRuleCors -> SpecIngressRuleCors
specIngressRuleCorsAllowCredentials value (SpecIngressRuleCors values) = SpecIngressRuleCors (insertInputField "allow_credentials" (inputJson value) values)

specIngressRuleCorsAllowHeaders :: Input (Array String) -> SpecIngressRuleCors -> SpecIngressRuleCors
specIngressRuleCorsAllowHeaders value (SpecIngressRuleCors values) = SpecIngressRuleCors (insertInputField "allow_headers" (inputJson value) values)

specIngressRuleCorsAllowMethods :: Input (Array String) -> SpecIngressRuleCors -> SpecIngressRuleCors
specIngressRuleCorsAllowMethods value (SpecIngressRuleCors values) = SpecIngressRuleCors (insertInputField "allow_methods" (inputJson value) values)

specIngressRuleCorsAllowOrigins :: Array SpecIngressRuleCorsAllowOrigins -> SpecIngressRuleCors -> SpecIngressRuleCors
specIngressRuleCorsAllowOrigins value (SpecIngressRuleCors values) = SpecIngressRuleCors (insertInputField "allow_origins" (arrayExprJson (map specIngressRuleCorsAllowOriginsJson value)) values)

specIngressRuleCorsExposeHeaders :: Input (Array String) -> SpecIngressRuleCors -> SpecIngressRuleCors
specIngressRuleCorsExposeHeaders value (SpecIngressRuleCors values) = SpecIngressRuleCors (insertInputField "expose_headers" (inputJson value) values)

specIngressRuleCorsMaxAge :: Input String -> SpecIngressRuleCors -> SpecIngressRuleCors
specIngressRuleCorsMaxAge value (SpecIngressRuleCors values) = SpecIngressRuleCors (insertInputField "max_age" (inputJson value) values)

specIngressRuleCorsJson :: SpecIngressRuleCors -> Json
specIngressRuleCorsJson (SpecIngressRuleCors values) = inputObjectJson values

newtype SpecIngressRuleCorsAllowOrigins = SpecIngressRuleCorsAllowOrigins InputObject

type SpecIngressRuleCorsAllowOriginsRequired =
  {
  }

specIngressRuleCorsAllowOriginsArgs :: SpecIngressRuleCorsAllowOriginsRequired -> SpecIngressRuleCorsAllowOrigins
specIngressRuleCorsAllowOriginsArgs _ = SpecIngressRuleCorsAllowOrigins (inputObject
  [
  ])

specIngressRuleCorsAllowOriginsExact :: Input String -> SpecIngressRuleCorsAllowOrigins -> SpecIngressRuleCorsAllowOrigins
specIngressRuleCorsAllowOriginsExact value (SpecIngressRuleCorsAllowOrigins values) = SpecIngressRuleCorsAllowOrigins (insertInputField "exact" (inputJson value) values)

specIngressRuleCorsAllowOriginsPrefix :: Input String -> SpecIngressRuleCorsAllowOrigins -> SpecIngressRuleCorsAllowOrigins
specIngressRuleCorsAllowOriginsPrefix value (SpecIngressRuleCorsAllowOrigins values) = SpecIngressRuleCorsAllowOrigins (insertInputField "prefix" (inputJson value) values)

specIngressRuleCorsAllowOriginsRegex :: Input String -> SpecIngressRuleCorsAllowOrigins -> SpecIngressRuleCorsAllowOrigins
specIngressRuleCorsAllowOriginsRegex value (SpecIngressRuleCorsAllowOrigins values) = SpecIngressRuleCorsAllowOrigins (insertInputField "regex" (inputJson value) values)

specIngressRuleCorsAllowOriginsJson :: SpecIngressRuleCorsAllowOrigins -> Json
specIngressRuleCorsAllowOriginsJson (SpecIngressRuleCorsAllowOrigins values) = inputObjectJson values

newtype SpecIngressRuleMatch = SpecIngressRuleMatch InputObject

type SpecIngressRuleMatchRequired =
  {
  }

specIngressRuleMatchArgs :: SpecIngressRuleMatchRequired -> SpecIngressRuleMatch
specIngressRuleMatchArgs _ = SpecIngressRuleMatch (inputObject
  [
  ])

specIngressRuleMatchAuthority :: Array SpecIngressRuleMatchAuthority -> SpecIngressRuleMatch -> SpecIngressRuleMatch
specIngressRuleMatchAuthority value (SpecIngressRuleMatch values) = SpecIngressRuleMatch (insertInputField "authority" (arrayExprJson (map specIngressRuleMatchAuthorityJson value)) values)

specIngressRuleMatchPath :: Array SpecIngressRuleMatchPath -> SpecIngressRuleMatch -> SpecIngressRuleMatch
specIngressRuleMatchPath value (SpecIngressRuleMatch values) = SpecIngressRuleMatch (insertInputField "path" (arrayExprJson (map specIngressRuleMatchPathJson value)) values)

specIngressRuleMatchJson :: SpecIngressRuleMatch -> Json
specIngressRuleMatchJson (SpecIngressRuleMatch values) = inputObjectJson values

newtype SpecIngressRuleMatchAuthority = SpecIngressRuleMatchAuthority InputObject

type SpecIngressRuleMatchAuthorityRequired =
  {
  }

specIngressRuleMatchAuthorityArgs :: SpecIngressRuleMatchAuthorityRequired -> SpecIngressRuleMatchAuthority
specIngressRuleMatchAuthorityArgs _ = SpecIngressRuleMatchAuthority (inputObject
  [
  ])

specIngressRuleMatchAuthorityExact :: Input String -> SpecIngressRuleMatchAuthority -> SpecIngressRuleMatchAuthority
specIngressRuleMatchAuthorityExact value (SpecIngressRuleMatchAuthority values) = SpecIngressRuleMatchAuthority (insertInputField "exact" (inputJson value) values)

specIngressRuleMatchAuthorityJson :: SpecIngressRuleMatchAuthority -> Json
specIngressRuleMatchAuthorityJson (SpecIngressRuleMatchAuthority values) = inputObjectJson values

newtype SpecIngressRuleMatchPath = SpecIngressRuleMatchPath InputObject

type SpecIngressRuleMatchPathRequired =
  {
  }

specIngressRuleMatchPathArgs :: SpecIngressRuleMatchPathRequired -> SpecIngressRuleMatchPath
specIngressRuleMatchPathArgs _ = SpecIngressRuleMatchPath (inputObject
  [
  ])

specIngressRuleMatchPathPrefix :: Input String -> SpecIngressRuleMatchPath -> SpecIngressRuleMatchPath
specIngressRuleMatchPathPrefix value (SpecIngressRuleMatchPath values) = SpecIngressRuleMatchPath (insertInputField "prefix" (inputJson value) values)

specIngressRuleMatchPathJson :: SpecIngressRuleMatchPath -> Json
specIngressRuleMatchPathJson (SpecIngressRuleMatchPath values) = inputObjectJson values

newtype SpecIngressRuleRedirect = SpecIngressRuleRedirect InputObject

type SpecIngressRuleRedirectRequired =
  {
  }

specIngressRuleRedirectArgs :: SpecIngressRuleRedirectRequired -> SpecIngressRuleRedirect
specIngressRuleRedirectArgs _ = SpecIngressRuleRedirect (inputObject
  [
  ])

specIngressRuleRedirectAuthority :: Input String -> SpecIngressRuleRedirect -> SpecIngressRuleRedirect
specIngressRuleRedirectAuthority value (SpecIngressRuleRedirect values) = SpecIngressRuleRedirect (insertInputField "authority" (inputJson value) values)

specIngressRuleRedirectPort :: Input Number -> SpecIngressRuleRedirect -> SpecIngressRuleRedirect
specIngressRuleRedirectPort value (SpecIngressRuleRedirect values) = SpecIngressRuleRedirect (insertInputField "port" (inputJson value) values)

specIngressRuleRedirectRedirectCode :: Input Number -> SpecIngressRuleRedirect -> SpecIngressRuleRedirect
specIngressRuleRedirectRedirectCode value (SpecIngressRuleRedirect values) = SpecIngressRuleRedirect (insertInputField "redirect_code" (inputJson value) values)

specIngressRuleRedirectScheme :: Input String -> SpecIngressRuleRedirect -> SpecIngressRuleRedirect
specIngressRuleRedirectScheme value (SpecIngressRuleRedirect values) = SpecIngressRuleRedirect (insertInputField "scheme" (inputJson value) values)

specIngressRuleRedirectUri :: Input String -> SpecIngressRuleRedirect -> SpecIngressRuleRedirect
specIngressRuleRedirectUri value (SpecIngressRuleRedirect values) = SpecIngressRuleRedirect (insertInputField "uri" (inputJson value) values)

specIngressRuleRedirectJson :: SpecIngressRuleRedirect -> Json
specIngressRuleRedirectJson (SpecIngressRuleRedirect values) = inputObjectJson values

newtype SpecIngressSecureHeader = SpecIngressSecureHeader InputObject

type SpecIngressSecureHeaderRequired =
  {
  }

specIngressSecureHeaderArgs :: SpecIngressSecureHeaderRequired -> SpecIngressSecureHeader
specIngressSecureHeaderArgs _ = SpecIngressSecureHeader (inputObject
  [
  ])

specIngressSecureHeaderKey :: Input String -> SpecIngressSecureHeader -> SpecIngressSecureHeader
specIngressSecureHeaderKey value (SpecIngressSecureHeader values) = SpecIngressSecureHeader (insertInputField "key" (inputJson value) values)

specIngressSecureHeaderValue :: Input String -> SpecIngressSecureHeader -> SpecIngressSecureHeader
specIngressSecureHeaderValue value (SpecIngressSecureHeader values) = SpecIngressSecureHeader (insertInputField "value" (inputJson value) values)

specIngressSecureHeaderJson :: SpecIngressSecureHeader -> Json
specIngressSecureHeaderJson (SpecIngressSecureHeader values) = inputObjectJson values

newtype SpecJob = SpecJob InputObject

type SpecJobRequired =
  { name :: Input String
  }

specJobArgs :: SpecJobRequired -> SpecJob
specJobArgs required = SpecJob (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

specJobAlert :: Array SpecJobAlert -> SpecJob -> SpecJob
specJobAlert value (SpecJob values) = SpecJob (insertInputField "alert" (arrayExprJson (map specJobAlertJson value)) values)

specJobBitbucket :: Array SpecJobBitbucket -> SpecJob -> SpecJob
specJobBitbucket value (SpecJob values) = SpecJob (insertInputField "bitbucket" (arrayExprJson (map specJobBitbucketJson value)) values)

specJobBuildCommand :: Input String -> SpecJob -> SpecJob
specJobBuildCommand value (SpecJob values) = SpecJob (insertInputField "build_command" (inputJson value) values)

specJobDockerfilePath :: Input String -> SpecJob -> SpecJob
specJobDockerfilePath value (SpecJob values) = SpecJob (insertInputField "dockerfile_path" (inputJson value) values)

specJobEnv :: Array SpecJobEnv -> SpecJob -> SpecJob
specJobEnv value (SpecJob values) = SpecJob (insertInputField "env" (arrayExprJson (map specJobEnvJson value)) values)

specJobEnvironmentSlug :: Input String -> SpecJob -> SpecJob
specJobEnvironmentSlug value (SpecJob values) = SpecJob (insertInputField "environment_slug" (inputJson value) values)

specJobGit :: Array SpecJobGit -> SpecJob -> SpecJob
specJobGit value (SpecJob values) = SpecJob (insertInputField "git" (arrayExprJson (map specJobGitJson value)) values)

specJobGithub :: Array SpecJobGithub -> SpecJob -> SpecJob
specJobGithub value (SpecJob values) = SpecJob (insertInputField "github" (arrayExprJson (map specJobGithubJson value)) values)

specJobGitlab :: Array SpecJobGitlab -> SpecJob -> SpecJob
specJobGitlab value (SpecJob values) = SpecJob (insertInputField "gitlab" (arrayExprJson (map specJobGitlabJson value)) values)

specJobImage :: Array SpecJobImage -> SpecJob -> SpecJob
specJobImage value (SpecJob values) = SpecJob (insertInputField "image" (arrayExprJson (map specJobImageJson value)) values)

specJobInstanceCount :: Input Number -> SpecJob -> SpecJob
specJobInstanceCount value (SpecJob values) = SpecJob (insertInputField "instance_count" (inputJson value) values)

specJobInstanceSizeSlug :: Input String -> SpecJob -> SpecJob
specJobInstanceSizeSlug value (SpecJob values) = SpecJob (insertInputField "instance_size_slug" (inputJson value) values)

specJobKind :: Input String -> SpecJob -> SpecJob
specJobKind value (SpecJob values) = SpecJob (insertInputField "kind" (inputJson value) values)

specJobLogDestination :: Array SpecJobLogDestination -> SpecJob -> SpecJob
specJobLogDestination value (SpecJob values) = SpecJob (insertInputField "log_destination" (arrayExprJson (map specJobLogDestinationJson value)) values)

specJobRunCommand :: Input String -> SpecJob -> SpecJob
specJobRunCommand value (SpecJob values) = SpecJob (insertInputField "run_command" (inputJson value) values)

specJobSourceDir :: Input String -> SpecJob -> SpecJob
specJobSourceDir value (SpecJob values) = SpecJob (insertInputField "source_dir" (inputJson value) values)

specJobTermination :: Array SpecJobTermination -> SpecJob -> SpecJob
specJobTermination value (SpecJob values) = SpecJob (insertInputField "termination" (arrayExprJson (map specJobTerminationJson value)) values)

specJobJson :: SpecJob -> Json
specJobJson (SpecJob values) = inputObjectJson values

newtype SpecJobAlert = SpecJobAlert InputObject

type SpecJobAlertRequired =
  { operator :: Input String
  , rule :: Input String
  , value :: Input Number
  , window :: Input String
  }

specJobAlertArgs :: SpecJobAlertRequired -> SpecJobAlert
specJobAlertArgs required = SpecJobAlert (inputObject
  [ Tuple "operator" (inputJson required.operator)
  , Tuple "rule" (inputJson required.rule)
  , Tuple "value" (inputJson required.value)
  , Tuple "window" (inputJson required.window)
  ])

specJobAlertDestinations :: Array SpecJobAlertDestinations -> SpecJobAlert -> SpecJobAlert
specJobAlertDestinations value (SpecJobAlert values) = SpecJobAlert (insertInputField "destinations" (arrayExprJson (map specJobAlertDestinationsJson value)) values)

specJobAlertDisabled :: Input Boolean -> SpecJobAlert -> SpecJobAlert
specJobAlertDisabled value (SpecJobAlert values) = SpecJobAlert (insertInputField "disabled" (inputJson value) values)

specJobAlertJson :: SpecJobAlert -> Json
specJobAlertJson (SpecJobAlert values) = inputObjectJson values

newtype SpecJobAlertDestinations = SpecJobAlertDestinations InputObject

type SpecJobAlertDestinationsRequired =
  {
  }

specJobAlertDestinationsArgs :: SpecJobAlertDestinationsRequired -> SpecJobAlertDestinations
specJobAlertDestinationsArgs _ = SpecJobAlertDestinations (inputObject
  [
  ])

specJobAlertDestinationsEmails :: Input (Array String) -> SpecJobAlertDestinations -> SpecJobAlertDestinations
specJobAlertDestinationsEmails value (SpecJobAlertDestinations values) = SpecJobAlertDestinations (insertInputField "emails" (inputJson value) values)

specJobAlertDestinationsSlackWebhooks :: Array SpecJobAlertDestinationsSlackWebhooks -> SpecJobAlertDestinations -> SpecJobAlertDestinations
specJobAlertDestinationsSlackWebhooks value (SpecJobAlertDestinations values) = SpecJobAlertDestinations (insertInputField "slack_webhooks" (arrayExprJson (map specJobAlertDestinationsSlackWebhooksJson value)) values)

specJobAlertDestinationsJson :: SpecJobAlertDestinations -> Json
specJobAlertDestinationsJson (SpecJobAlertDestinations values) = inputObjectJson values

newtype SpecJobAlertDestinationsSlackWebhooks = SpecJobAlertDestinationsSlackWebhooks InputObject

type SpecJobAlertDestinationsSlackWebhooksRequired =
  { channel :: Input String
  , url :: Input String
  }

specJobAlertDestinationsSlackWebhooksArgs :: SpecJobAlertDestinationsSlackWebhooksRequired -> SpecJobAlertDestinationsSlackWebhooks
specJobAlertDestinationsSlackWebhooksArgs required = SpecJobAlertDestinationsSlackWebhooks (inputObject
  [ Tuple "channel" (inputJson required.channel)
  , Tuple "url" (inputJson required.url)
  ])

specJobAlertDestinationsSlackWebhooksJson :: SpecJobAlertDestinationsSlackWebhooks -> Json
specJobAlertDestinationsSlackWebhooksJson (SpecJobAlertDestinationsSlackWebhooks values) = inputObjectJson values

newtype SpecJobBitbucket = SpecJobBitbucket InputObject

type SpecJobBitbucketRequired =
  {
  }

specJobBitbucketArgs :: SpecJobBitbucketRequired -> SpecJobBitbucket
specJobBitbucketArgs _ = SpecJobBitbucket (inputObject
  [
  ])

specJobBitbucketBranch :: Input String -> SpecJobBitbucket -> SpecJobBitbucket
specJobBitbucketBranch value (SpecJobBitbucket values) = SpecJobBitbucket (insertInputField "branch" (inputJson value) values)

specJobBitbucketDeployOnPush :: Input Boolean -> SpecJobBitbucket -> SpecJobBitbucket
specJobBitbucketDeployOnPush value (SpecJobBitbucket values) = SpecJobBitbucket (insertInputField "deploy_on_push" (inputJson value) values)

specJobBitbucketRepo :: Input String -> SpecJobBitbucket -> SpecJobBitbucket
specJobBitbucketRepo value (SpecJobBitbucket values) = SpecJobBitbucket (insertInputField "repo" (inputJson value) values)

specJobBitbucketJson :: SpecJobBitbucket -> Json
specJobBitbucketJson (SpecJobBitbucket values) = inputObjectJson values

newtype SpecJobEnv = SpecJobEnv InputObject

type SpecJobEnvRequired =
  {
  }

specJobEnvArgs :: SpecJobEnvRequired -> SpecJobEnv
specJobEnvArgs _ = SpecJobEnv (inputObject
  [
  ])

specJobEnvKey :: Input String -> SpecJobEnv -> SpecJobEnv
specJobEnvKey value (SpecJobEnv values) = SpecJobEnv (insertInputField "key" (inputJson value) values)

specJobEnvScope :: Input String -> SpecJobEnv -> SpecJobEnv
specJobEnvScope value (SpecJobEnv values) = SpecJobEnv (insertInputField "scope" (inputJson value) values)

specJobEnvType :: Input String -> SpecJobEnv -> SpecJobEnv
specJobEnvType value (SpecJobEnv values) = SpecJobEnv (insertInputField "type" (inputJson value) values)

specJobEnvValue :: Input String -> SpecJobEnv -> SpecJobEnv
specJobEnvValue value (SpecJobEnv values) = SpecJobEnv (insertInputField "value" (inputJson value) values)

specJobEnvJson :: SpecJobEnv -> Json
specJobEnvJson (SpecJobEnv values) = inputObjectJson values

newtype SpecJobGit = SpecJobGit InputObject

type SpecJobGitRequired =
  {
  }

specJobGitArgs :: SpecJobGitRequired -> SpecJobGit
specJobGitArgs _ = SpecJobGit (inputObject
  [
  ])

specJobGitBranch :: Input String -> SpecJobGit -> SpecJobGit
specJobGitBranch value (SpecJobGit values) = SpecJobGit (insertInputField "branch" (inputJson value) values)

specJobGitRepoCloneUrl :: Input String -> SpecJobGit -> SpecJobGit
specJobGitRepoCloneUrl value (SpecJobGit values) = SpecJobGit (insertInputField "repo_clone_url" (inputJson value) values)

specJobGitJson :: SpecJobGit -> Json
specJobGitJson (SpecJobGit values) = inputObjectJson values

newtype SpecJobGithub = SpecJobGithub InputObject

type SpecJobGithubRequired =
  {
  }

specJobGithubArgs :: SpecJobGithubRequired -> SpecJobGithub
specJobGithubArgs _ = SpecJobGithub (inputObject
  [
  ])

specJobGithubBranch :: Input String -> SpecJobGithub -> SpecJobGithub
specJobGithubBranch value (SpecJobGithub values) = SpecJobGithub (insertInputField "branch" (inputJson value) values)

specJobGithubDeployOnPush :: Input Boolean -> SpecJobGithub -> SpecJobGithub
specJobGithubDeployOnPush value (SpecJobGithub values) = SpecJobGithub (insertInputField "deploy_on_push" (inputJson value) values)

specJobGithubRepo :: Input String -> SpecJobGithub -> SpecJobGithub
specJobGithubRepo value (SpecJobGithub values) = SpecJobGithub (insertInputField "repo" (inputJson value) values)

specJobGithubJson :: SpecJobGithub -> Json
specJobGithubJson (SpecJobGithub values) = inputObjectJson values

newtype SpecJobGitlab = SpecJobGitlab InputObject

type SpecJobGitlabRequired =
  {
  }

specJobGitlabArgs :: SpecJobGitlabRequired -> SpecJobGitlab
specJobGitlabArgs _ = SpecJobGitlab (inputObject
  [
  ])

specJobGitlabBranch :: Input String -> SpecJobGitlab -> SpecJobGitlab
specJobGitlabBranch value (SpecJobGitlab values) = SpecJobGitlab (insertInputField "branch" (inputJson value) values)

specJobGitlabDeployOnPush :: Input Boolean -> SpecJobGitlab -> SpecJobGitlab
specJobGitlabDeployOnPush value (SpecJobGitlab values) = SpecJobGitlab (insertInputField "deploy_on_push" (inputJson value) values)

specJobGitlabRepo :: Input String -> SpecJobGitlab -> SpecJobGitlab
specJobGitlabRepo value (SpecJobGitlab values) = SpecJobGitlab (insertInputField "repo" (inputJson value) values)

specJobGitlabJson :: SpecJobGitlab -> Json
specJobGitlabJson (SpecJobGitlab values) = inputObjectJson values

newtype SpecJobImage = SpecJobImage InputObject

type SpecJobImageRequired =
  { registryType :: Input String
  , repository :: Input String
  }

specJobImageArgs :: SpecJobImageRequired -> SpecJobImage
specJobImageArgs required = SpecJobImage (inputObject
  [ Tuple "registry_type" (inputJson required.registryType)
  , Tuple "repository" (inputJson required.repository)
  ])

specJobImageDeployOnPush :: Array SpecJobImageDeployOnPush -> SpecJobImage -> SpecJobImage
specJobImageDeployOnPush value (SpecJobImage values) = SpecJobImage (insertInputField "deploy_on_push" (arrayExprJson (map specJobImageDeployOnPushJson value)) values)

specJobImageDigest :: Input String -> SpecJobImage -> SpecJobImage
specJobImageDigest value (SpecJobImage values) = SpecJobImage (insertInputField "digest" (inputJson value) values)

specJobImageRegistry :: Input String -> SpecJobImage -> SpecJobImage
specJobImageRegistry value (SpecJobImage values) = SpecJobImage (insertInputField "registry" (inputJson value) values)

specJobImageRegistryCredentials :: Input String -> SpecJobImage -> SpecJobImage
specJobImageRegistryCredentials value (SpecJobImage values) = SpecJobImage (insertInputField "registry_credentials" (inputJson value) values)

specJobImageTag :: Input String -> SpecJobImage -> SpecJobImage
specJobImageTag value (SpecJobImage values) = SpecJobImage (insertInputField "tag" (inputJson value) values)

specJobImageJson :: SpecJobImage -> Json
specJobImageJson (SpecJobImage values) = inputObjectJson values

newtype SpecJobImageDeployOnPush = SpecJobImageDeployOnPush InputObject

type SpecJobImageDeployOnPushRequired =
  {
  }

specJobImageDeployOnPushArgs :: SpecJobImageDeployOnPushRequired -> SpecJobImageDeployOnPush
specJobImageDeployOnPushArgs _ = SpecJobImageDeployOnPush (inputObject
  [
  ])

specJobImageDeployOnPushEnabled :: Input Boolean -> SpecJobImageDeployOnPush -> SpecJobImageDeployOnPush
specJobImageDeployOnPushEnabled value (SpecJobImageDeployOnPush values) = SpecJobImageDeployOnPush (insertInputField "enabled" (inputJson value) values)

specJobImageDeployOnPushJson :: SpecJobImageDeployOnPush -> Json
specJobImageDeployOnPushJson (SpecJobImageDeployOnPush values) = inputObjectJson values

newtype SpecJobLogDestination = SpecJobLogDestination InputObject

type SpecJobLogDestinationRequired =
  { name :: Input String
  }

specJobLogDestinationArgs :: SpecJobLogDestinationRequired -> SpecJobLogDestination
specJobLogDestinationArgs required = SpecJobLogDestination (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

specJobLogDestinationDatadog :: Array SpecJobLogDestinationDatadog -> SpecJobLogDestination -> SpecJobLogDestination
specJobLogDestinationDatadog value (SpecJobLogDestination values) = SpecJobLogDestination (insertInputField "datadog" (arrayExprJson (map specJobLogDestinationDatadogJson value)) values)

specJobLogDestinationLogtail :: Array SpecJobLogDestinationLogtail -> SpecJobLogDestination -> SpecJobLogDestination
specJobLogDestinationLogtail value (SpecJobLogDestination values) = SpecJobLogDestination (insertInputField "logtail" (arrayExprJson (map specJobLogDestinationLogtailJson value)) values)

specJobLogDestinationOpenSearch :: Array SpecJobLogDestinationOpenSearch -> SpecJobLogDestination -> SpecJobLogDestination
specJobLogDestinationOpenSearch value (SpecJobLogDestination values) = SpecJobLogDestination (insertInputField "open_search" (arrayExprJson (map specJobLogDestinationOpenSearchJson value)) values)

specJobLogDestinationPapertrail :: Array SpecJobLogDestinationPapertrail -> SpecJobLogDestination -> SpecJobLogDestination
specJobLogDestinationPapertrail value (SpecJobLogDestination values) = SpecJobLogDestination (insertInputField "papertrail" (arrayExprJson (map specJobLogDestinationPapertrailJson value)) values)

specJobLogDestinationJson :: SpecJobLogDestination -> Json
specJobLogDestinationJson (SpecJobLogDestination values) = inputObjectJson values

newtype SpecJobLogDestinationDatadog = SpecJobLogDestinationDatadog InputObject

type SpecJobLogDestinationDatadogRequired =
  { apiKey :: Input String
  }

specJobLogDestinationDatadogArgs :: SpecJobLogDestinationDatadogRequired -> SpecJobLogDestinationDatadog
specJobLogDestinationDatadogArgs required = SpecJobLogDestinationDatadog (inputObject
  [ Tuple "api_key" (inputJson required.apiKey)
  ])

specJobLogDestinationDatadogEndpoint :: Input String -> SpecJobLogDestinationDatadog -> SpecJobLogDestinationDatadog
specJobLogDestinationDatadogEndpoint value (SpecJobLogDestinationDatadog values) = SpecJobLogDestinationDatadog (insertInputField "endpoint" (inputJson value) values)

specJobLogDestinationDatadogJson :: SpecJobLogDestinationDatadog -> Json
specJobLogDestinationDatadogJson (SpecJobLogDestinationDatadog values) = inputObjectJson values

newtype SpecJobLogDestinationLogtail = SpecJobLogDestinationLogtail InputObject

type SpecJobLogDestinationLogtailRequired =
  { token :: Input String
  }

specJobLogDestinationLogtailArgs :: SpecJobLogDestinationLogtailRequired -> SpecJobLogDestinationLogtail
specJobLogDestinationLogtailArgs required = SpecJobLogDestinationLogtail (inputObject
  [ Tuple "token" (inputJson required.token)
  ])

specJobLogDestinationLogtailJson :: SpecJobLogDestinationLogtail -> Json
specJobLogDestinationLogtailJson (SpecJobLogDestinationLogtail values) = inputObjectJson values

newtype SpecJobLogDestinationOpenSearch = SpecJobLogDestinationOpenSearch InputObject

type SpecJobLogDestinationOpenSearchRequired =
  { basicAuth :: Array SpecJobLogDestinationOpenSearchBasicAuth
  }

specJobLogDestinationOpenSearchArgs :: SpecJobLogDestinationOpenSearchRequired -> SpecJobLogDestinationOpenSearch
specJobLogDestinationOpenSearchArgs required = SpecJobLogDestinationOpenSearch (inputObject
  [ Tuple "basic_auth" (arrayExprJson (map specJobLogDestinationOpenSearchBasicAuthJson required.basicAuth))
  ])

specJobLogDestinationOpenSearchClusterName :: Input String -> SpecJobLogDestinationOpenSearch -> SpecJobLogDestinationOpenSearch
specJobLogDestinationOpenSearchClusterName value (SpecJobLogDestinationOpenSearch values) = SpecJobLogDestinationOpenSearch (insertInputField "cluster_name" (inputJson value) values)

specJobLogDestinationOpenSearchEndpoint :: Input String -> SpecJobLogDestinationOpenSearch -> SpecJobLogDestinationOpenSearch
specJobLogDestinationOpenSearchEndpoint value (SpecJobLogDestinationOpenSearch values) = SpecJobLogDestinationOpenSearch (insertInputField "endpoint" (inputJson value) values)

specJobLogDestinationOpenSearchIndexName :: Input String -> SpecJobLogDestinationOpenSearch -> SpecJobLogDestinationOpenSearch
specJobLogDestinationOpenSearchIndexName value (SpecJobLogDestinationOpenSearch values) = SpecJobLogDestinationOpenSearch (insertInputField "index_name" (inputJson value) values)

specJobLogDestinationOpenSearchJson :: SpecJobLogDestinationOpenSearch -> Json
specJobLogDestinationOpenSearchJson (SpecJobLogDestinationOpenSearch values) = inputObjectJson values

newtype SpecJobLogDestinationOpenSearchBasicAuth = SpecJobLogDestinationOpenSearchBasicAuth InputObject

type SpecJobLogDestinationOpenSearchBasicAuthRequired =
  {
  }

specJobLogDestinationOpenSearchBasicAuthArgs :: SpecJobLogDestinationOpenSearchBasicAuthRequired -> SpecJobLogDestinationOpenSearchBasicAuth
specJobLogDestinationOpenSearchBasicAuthArgs _ = SpecJobLogDestinationOpenSearchBasicAuth (inputObject
  [
  ])

specJobLogDestinationOpenSearchBasicAuthPassword :: Input String -> SpecJobLogDestinationOpenSearchBasicAuth -> SpecJobLogDestinationOpenSearchBasicAuth
specJobLogDestinationOpenSearchBasicAuthPassword value (SpecJobLogDestinationOpenSearchBasicAuth values) = SpecJobLogDestinationOpenSearchBasicAuth (insertInputField "password" (inputJson value) values)

specJobLogDestinationOpenSearchBasicAuthUser :: Input String -> SpecJobLogDestinationOpenSearchBasicAuth -> SpecJobLogDestinationOpenSearchBasicAuth
specJobLogDestinationOpenSearchBasicAuthUser value (SpecJobLogDestinationOpenSearchBasicAuth values) = SpecJobLogDestinationOpenSearchBasicAuth (insertInputField "user" (inputJson value) values)

specJobLogDestinationOpenSearchBasicAuthJson :: SpecJobLogDestinationOpenSearchBasicAuth -> Json
specJobLogDestinationOpenSearchBasicAuthJson (SpecJobLogDestinationOpenSearchBasicAuth values) = inputObjectJson values

newtype SpecJobLogDestinationPapertrail = SpecJobLogDestinationPapertrail InputObject

type SpecJobLogDestinationPapertrailRequired =
  { endpoint :: Input String
  }

specJobLogDestinationPapertrailArgs :: SpecJobLogDestinationPapertrailRequired -> SpecJobLogDestinationPapertrail
specJobLogDestinationPapertrailArgs required = SpecJobLogDestinationPapertrail (inputObject
  [ Tuple "endpoint" (inputJson required.endpoint)
  ])

specJobLogDestinationPapertrailJson :: SpecJobLogDestinationPapertrail -> Json
specJobLogDestinationPapertrailJson (SpecJobLogDestinationPapertrail values) = inputObjectJson values

newtype SpecJobTermination = SpecJobTermination InputObject

type SpecJobTerminationRequired =
  {
  }

specJobTerminationArgs :: SpecJobTerminationRequired -> SpecJobTermination
specJobTerminationArgs _ = SpecJobTermination (inputObject
  [
  ])

specJobTerminationGracePeriodSeconds :: Input Number -> SpecJobTermination -> SpecJobTermination
specJobTerminationGracePeriodSeconds value (SpecJobTermination values) = SpecJobTermination (insertInputField "grace_period_seconds" (inputJson value) values)

specJobTerminationJson :: SpecJobTermination -> Json
specJobTerminationJson (SpecJobTermination values) = inputObjectJson values

newtype SpecMaintenance = SpecMaintenance InputObject

type SpecMaintenanceRequired =
  {
  }

specMaintenanceArgs :: SpecMaintenanceRequired -> SpecMaintenance
specMaintenanceArgs _ = SpecMaintenance (inputObject
  [
  ])

specMaintenanceArchive :: Input Boolean -> SpecMaintenance -> SpecMaintenance
specMaintenanceArchive value (SpecMaintenance values) = SpecMaintenance (insertInputField "archive" (inputJson value) values)

specMaintenanceEnabled :: Input Boolean -> SpecMaintenance -> SpecMaintenance
specMaintenanceEnabled value (SpecMaintenance values) = SpecMaintenance (insertInputField "enabled" (inputJson value) values)

specMaintenanceOfflinePageUrl :: Input String -> SpecMaintenance -> SpecMaintenance
specMaintenanceOfflinePageUrl value (SpecMaintenance values) = SpecMaintenance (insertInputField "offline_page_url" (inputJson value) values)

specMaintenanceJson :: SpecMaintenance -> Json
specMaintenanceJson (SpecMaintenance values) = inputObjectJson values

newtype SpecService = SpecService InputObject

type SpecServiceRequired =
  { name :: Input String
  }

specServiceArgs :: SpecServiceRequired -> SpecService
specServiceArgs required = SpecService (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

specServiceAlert :: Array SpecServiceAlert -> SpecService -> SpecService
specServiceAlert value (SpecService values) = SpecService (insertInputField "alert" (arrayExprJson (map specServiceAlertJson value)) values)

specServiceAutoscaling :: Array SpecServiceAutoscaling -> SpecService -> SpecService
specServiceAutoscaling value (SpecService values) = SpecService (insertInputField "autoscaling" (arrayExprJson (map specServiceAutoscalingJson value)) values)

specServiceBitbucket :: Array SpecServiceBitbucket -> SpecService -> SpecService
specServiceBitbucket value (SpecService values) = SpecService (insertInputField "bitbucket" (arrayExprJson (map specServiceBitbucketJson value)) values)

specServiceBuildCommand :: Input String -> SpecService -> SpecService
specServiceBuildCommand value (SpecService values) = SpecService (insertInputField "build_command" (inputJson value) values)

specServiceCors :: Array SpecServiceCors -> SpecService -> SpecService
specServiceCors value (SpecService values) = SpecService (insertInputField "cors" (arrayExprJson (map specServiceCorsJson value)) values)

specServiceDockerfilePath :: Input String -> SpecService -> SpecService
specServiceDockerfilePath value (SpecService values) = SpecService (insertInputField "dockerfile_path" (inputJson value) values)

specServiceEnv :: Array SpecServiceEnv -> SpecService -> SpecService
specServiceEnv value (SpecService values) = SpecService (insertInputField "env" (arrayExprJson (map specServiceEnvJson value)) values)

specServiceEnvironmentSlug :: Input String -> SpecService -> SpecService
specServiceEnvironmentSlug value (SpecService values) = SpecService (insertInputField "environment_slug" (inputJson value) values)

specServiceGit :: Array SpecServiceGit -> SpecService -> SpecService
specServiceGit value (SpecService values) = SpecService (insertInputField "git" (arrayExprJson (map specServiceGitJson value)) values)

specServiceGithub :: Array SpecServiceGithub -> SpecService -> SpecService
specServiceGithub value (SpecService values) = SpecService (insertInputField "github" (arrayExprJson (map specServiceGithubJson value)) values)

specServiceGitlab :: Array SpecServiceGitlab -> SpecService -> SpecService
specServiceGitlab value (SpecService values) = SpecService (insertInputField "gitlab" (arrayExprJson (map specServiceGitlabJson value)) values)

specServiceHealthCheck :: Array SpecServiceHealthCheck -> SpecService -> SpecService
specServiceHealthCheck value (SpecService values) = SpecService (insertInputField "health_check" (arrayExprJson (map specServiceHealthCheckJson value)) values)

specServiceHttpPort :: Input Number -> SpecService -> SpecService
specServiceHttpPort value (SpecService values) = SpecService (insertInputField "http_port" (inputJson value) values)

specServiceImage :: Array SpecServiceImage -> SpecService -> SpecService
specServiceImage value (SpecService values) = SpecService (insertInputField "image" (arrayExprJson (map specServiceImageJson value)) values)

specServiceInstanceCount :: Input Number -> SpecService -> SpecService
specServiceInstanceCount value (SpecService values) = SpecService (insertInputField "instance_count" (inputJson value) values)

specServiceInstanceSizeSlug :: Input String -> SpecService -> SpecService
specServiceInstanceSizeSlug value (SpecService values) = SpecService (insertInputField "instance_size_slug" (inputJson value) values)

specServiceInternalPorts :: Input (Array Number) -> SpecService -> SpecService
specServiceInternalPorts value (SpecService values) = SpecService (insertInputField "internal_ports" (inputJson value) values)

specServiceLivenessHealthCheck :: Array SpecServiceLivenessHealthCheck -> SpecService -> SpecService
specServiceLivenessHealthCheck value (SpecService values) = SpecService (insertInputField "liveness_health_check" (arrayExprJson (map specServiceLivenessHealthCheckJson value)) values)

specServiceLogDestination :: Array SpecServiceLogDestination -> SpecService -> SpecService
specServiceLogDestination value (SpecService values) = SpecService (insertInputField "log_destination" (arrayExprJson (map specServiceLogDestinationJson value)) values)

specServiceRoutes :: Array SpecServiceRoutes -> SpecService -> SpecService
specServiceRoutes value (SpecService values) = SpecService (insertInputField "routes" (arrayExprJson (map specServiceRoutesJson value)) values)

specServiceRunCommand :: Input String -> SpecService -> SpecService
specServiceRunCommand value (SpecService values) = SpecService (insertInputField "run_command" (inputJson value) values)

specServiceSourceDir :: Input String -> SpecService -> SpecService
specServiceSourceDir value (SpecService values) = SpecService (insertInputField "source_dir" (inputJson value) values)

specServiceTermination :: Array SpecServiceTermination -> SpecService -> SpecService
specServiceTermination value (SpecService values) = SpecService (insertInputField "termination" (arrayExprJson (map specServiceTerminationJson value)) values)

specServiceJson :: SpecService -> Json
specServiceJson (SpecService values) = inputObjectJson values

newtype SpecServiceAlert = SpecServiceAlert InputObject

type SpecServiceAlertRequired =
  { operator :: Input String
  , rule :: Input String
  , value :: Input Number
  , window :: Input String
  }

specServiceAlertArgs :: SpecServiceAlertRequired -> SpecServiceAlert
specServiceAlertArgs required = SpecServiceAlert (inputObject
  [ Tuple "operator" (inputJson required.operator)
  , Tuple "rule" (inputJson required.rule)
  , Tuple "value" (inputJson required.value)
  , Tuple "window" (inputJson required.window)
  ])

specServiceAlertDestinations :: Array SpecServiceAlertDestinations -> SpecServiceAlert -> SpecServiceAlert
specServiceAlertDestinations value (SpecServiceAlert values) = SpecServiceAlert (insertInputField "destinations" (arrayExprJson (map specServiceAlertDestinationsJson value)) values)

specServiceAlertDisabled :: Input Boolean -> SpecServiceAlert -> SpecServiceAlert
specServiceAlertDisabled value (SpecServiceAlert values) = SpecServiceAlert (insertInputField "disabled" (inputJson value) values)

specServiceAlertJson :: SpecServiceAlert -> Json
specServiceAlertJson (SpecServiceAlert values) = inputObjectJson values

newtype SpecServiceAlertDestinations = SpecServiceAlertDestinations InputObject

type SpecServiceAlertDestinationsRequired =
  {
  }

specServiceAlertDestinationsArgs :: SpecServiceAlertDestinationsRequired -> SpecServiceAlertDestinations
specServiceAlertDestinationsArgs _ = SpecServiceAlertDestinations (inputObject
  [
  ])

specServiceAlertDestinationsEmails :: Input (Array String) -> SpecServiceAlertDestinations -> SpecServiceAlertDestinations
specServiceAlertDestinationsEmails value (SpecServiceAlertDestinations values) = SpecServiceAlertDestinations (insertInputField "emails" (inputJson value) values)

specServiceAlertDestinationsSlackWebhooks :: Array SpecServiceAlertDestinationsSlackWebhooks -> SpecServiceAlertDestinations -> SpecServiceAlertDestinations
specServiceAlertDestinationsSlackWebhooks value (SpecServiceAlertDestinations values) = SpecServiceAlertDestinations (insertInputField "slack_webhooks" (arrayExprJson (map specServiceAlertDestinationsSlackWebhooksJson value)) values)

specServiceAlertDestinationsJson :: SpecServiceAlertDestinations -> Json
specServiceAlertDestinationsJson (SpecServiceAlertDestinations values) = inputObjectJson values

newtype SpecServiceAlertDestinationsSlackWebhooks = SpecServiceAlertDestinationsSlackWebhooks InputObject

type SpecServiceAlertDestinationsSlackWebhooksRequired =
  { channel :: Input String
  , url :: Input String
  }

specServiceAlertDestinationsSlackWebhooksArgs :: SpecServiceAlertDestinationsSlackWebhooksRequired -> SpecServiceAlertDestinationsSlackWebhooks
specServiceAlertDestinationsSlackWebhooksArgs required = SpecServiceAlertDestinationsSlackWebhooks (inputObject
  [ Tuple "channel" (inputJson required.channel)
  , Tuple "url" (inputJson required.url)
  ])

specServiceAlertDestinationsSlackWebhooksJson :: SpecServiceAlertDestinationsSlackWebhooks -> Json
specServiceAlertDestinationsSlackWebhooksJson (SpecServiceAlertDestinationsSlackWebhooks values) = inputObjectJson values

newtype SpecServiceAutoscaling = SpecServiceAutoscaling InputObject

type SpecServiceAutoscalingRequired =
  { maxInstanceCount :: Input Number
  , metrics :: Array SpecServiceAutoscalingMetrics
  , minInstanceCount :: Input Number
  }

specServiceAutoscalingArgs :: SpecServiceAutoscalingRequired -> SpecServiceAutoscaling
specServiceAutoscalingArgs required = SpecServiceAutoscaling (inputObject
  [ Tuple "max_instance_count" (inputJson required.maxInstanceCount)
  , Tuple "metrics" (arrayExprJson (map specServiceAutoscalingMetricsJson required.metrics))
  , Tuple "min_instance_count" (inputJson required.minInstanceCount)
  ])

specServiceAutoscalingJson :: SpecServiceAutoscaling -> Json
specServiceAutoscalingJson (SpecServiceAutoscaling values) = inputObjectJson values

newtype SpecServiceAutoscalingMetrics = SpecServiceAutoscalingMetrics InputObject

type SpecServiceAutoscalingMetricsRequired =
  {
  }

specServiceAutoscalingMetricsArgs :: SpecServiceAutoscalingMetricsRequired -> SpecServiceAutoscalingMetrics
specServiceAutoscalingMetricsArgs _ = SpecServiceAutoscalingMetrics (inputObject
  [
  ])

specServiceAutoscalingMetricsCpu :: Array SpecServiceAutoscalingMetricsCpu -> SpecServiceAutoscalingMetrics -> SpecServiceAutoscalingMetrics
specServiceAutoscalingMetricsCpu value (SpecServiceAutoscalingMetrics values) = SpecServiceAutoscalingMetrics (insertInputField "cpu" (arrayExprJson (map specServiceAutoscalingMetricsCpuJson value)) values)

specServiceAutoscalingMetricsJson :: SpecServiceAutoscalingMetrics -> Json
specServiceAutoscalingMetricsJson (SpecServiceAutoscalingMetrics values) = inputObjectJson values

newtype SpecServiceAutoscalingMetricsCpu = SpecServiceAutoscalingMetricsCpu InputObject

type SpecServiceAutoscalingMetricsCpuRequired =
  { percent :: Input Number
  }

specServiceAutoscalingMetricsCpuArgs :: SpecServiceAutoscalingMetricsCpuRequired -> SpecServiceAutoscalingMetricsCpu
specServiceAutoscalingMetricsCpuArgs required = SpecServiceAutoscalingMetricsCpu (inputObject
  [ Tuple "percent" (inputJson required.percent)
  ])

specServiceAutoscalingMetricsCpuJson :: SpecServiceAutoscalingMetricsCpu -> Json
specServiceAutoscalingMetricsCpuJson (SpecServiceAutoscalingMetricsCpu values) = inputObjectJson values

newtype SpecServiceBitbucket = SpecServiceBitbucket InputObject

type SpecServiceBitbucketRequired =
  {
  }

specServiceBitbucketArgs :: SpecServiceBitbucketRequired -> SpecServiceBitbucket
specServiceBitbucketArgs _ = SpecServiceBitbucket (inputObject
  [
  ])

specServiceBitbucketBranch :: Input String -> SpecServiceBitbucket -> SpecServiceBitbucket
specServiceBitbucketBranch value (SpecServiceBitbucket values) = SpecServiceBitbucket (insertInputField "branch" (inputJson value) values)

specServiceBitbucketDeployOnPush :: Input Boolean -> SpecServiceBitbucket -> SpecServiceBitbucket
specServiceBitbucketDeployOnPush value (SpecServiceBitbucket values) = SpecServiceBitbucket (insertInputField "deploy_on_push" (inputJson value) values)

specServiceBitbucketRepo :: Input String -> SpecServiceBitbucket -> SpecServiceBitbucket
specServiceBitbucketRepo value (SpecServiceBitbucket values) = SpecServiceBitbucket (insertInputField "repo" (inputJson value) values)

specServiceBitbucketJson :: SpecServiceBitbucket -> Json
specServiceBitbucketJson (SpecServiceBitbucket values) = inputObjectJson values

newtype SpecServiceCors = SpecServiceCors InputObject

type SpecServiceCorsRequired =
  {
  }

specServiceCorsArgs :: SpecServiceCorsRequired -> SpecServiceCors
specServiceCorsArgs _ = SpecServiceCors (inputObject
  [
  ])

specServiceCorsAllowCredentials :: Input Boolean -> SpecServiceCors -> SpecServiceCors
specServiceCorsAllowCredentials value (SpecServiceCors values) = SpecServiceCors (insertInputField "allow_credentials" (inputJson value) values)

specServiceCorsAllowHeaders :: Input (Array String) -> SpecServiceCors -> SpecServiceCors
specServiceCorsAllowHeaders value (SpecServiceCors values) = SpecServiceCors (insertInputField "allow_headers" (inputJson value) values)

specServiceCorsAllowMethods :: Input (Array String) -> SpecServiceCors -> SpecServiceCors
specServiceCorsAllowMethods value (SpecServiceCors values) = SpecServiceCors (insertInputField "allow_methods" (inputJson value) values)

specServiceCorsAllowOrigins :: Array SpecServiceCorsAllowOrigins -> SpecServiceCors -> SpecServiceCors
specServiceCorsAllowOrigins value (SpecServiceCors values) = SpecServiceCors (insertInputField "allow_origins" (arrayExprJson (map specServiceCorsAllowOriginsJson value)) values)

specServiceCorsExposeHeaders :: Input (Array String) -> SpecServiceCors -> SpecServiceCors
specServiceCorsExposeHeaders value (SpecServiceCors values) = SpecServiceCors (insertInputField "expose_headers" (inputJson value) values)

specServiceCorsMaxAge :: Input String -> SpecServiceCors -> SpecServiceCors
specServiceCorsMaxAge value (SpecServiceCors values) = SpecServiceCors (insertInputField "max_age" (inputJson value) values)

specServiceCorsJson :: SpecServiceCors -> Json
specServiceCorsJson (SpecServiceCors values) = inputObjectJson values

newtype SpecServiceCorsAllowOrigins = SpecServiceCorsAllowOrigins InputObject

type SpecServiceCorsAllowOriginsRequired =
  {
  }

specServiceCorsAllowOriginsArgs :: SpecServiceCorsAllowOriginsRequired -> SpecServiceCorsAllowOrigins
specServiceCorsAllowOriginsArgs _ = SpecServiceCorsAllowOrigins (inputObject
  [
  ])

specServiceCorsAllowOriginsExact :: Input String -> SpecServiceCorsAllowOrigins -> SpecServiceCorsAllowOrigins
specServiceCorsAllowOriginsExact value (SpecServiceCorsAllowOrigins values) = SpecServiceCorsAllowOrigins (insertInputField "exact" (inputJson value) values)

specServiceCorsAllowOriginsPrefix :: Input String -> SpecServiceCorsAllowOrigins -> SpecServiceCorsAllowOrigins
specServiceCorsAllowOriginsPrefix value (SpecServiceCorsAllowOrigins values) = SpecServiceCorsAllowOrigins (insertInputField "prefix" (inputJson value) values)

specServiceCorsAllowOriginsRegex :: Input String -> SpecServiceCorsAllowOrigins -> SpecServiceCorsAllowOrigins
specServiceCorsAllowOriginsRegex value (SpecServiceCorsAllowOrigins values) = SpecServiceCorsAllowOrigins (insertInputField "regex" (inputJson value) values)

specServiceCorsAllowOriginsJson :: SpecServiceCorsAllowOrigins -> Json
specServiceCorsAllowOriginsJson (SpecServiceCorsAllowOrigins values) = inputObjectJson values

newtype SpecServiceEnv = SpecServiceEnv InputObject

type SpecServiceEnvRequired =
  {
  }

specServiceEnvArgs :: SpecServiceEnvRequired -> SpecServiceEnv
specServiceEnvArgs _ = SpecServiceEnv (inputObject
  [
  ])

specServiceEnvKey :: Input String -> SpecServiceEnv -> SpecServiceEnv
specServiceEnvKey value (SpecServiceEnv values) = SpecServiceEnv (insertInputField "key" (inputJson value) values)

specServiceEnvScope :: Input String -> SpecServiceEnv -> SpecServiceEnv
specServiceEnvScope value (SpecServiceEnv values) = SpecServiceEnv (insertInputField "scope" (inputJson value) values)

specServiceEnvType :: Input String -> SpecServiceEnv -> SpecServiceEnv
specServiceEnvType value (SpecServiceEnv values) = SpecServiceEnv (insertInputField "type" (inputJson value) values)

specServiceEnvValue :: Input String -> SpecServiceEnv -> SpecServiceEnv
specServiceEnvValue value (SpecServiceEnv values) = SpecServiceEnv (insertInputField "value" (inputJson value) values)

specServiceEnvJson :: SpecServiceEnv -> Json
specServiceEnvJson (SpecServiceEnv values) = inputObjectJson values

newtype SpecServiceGit = SpecServiceGit InputObject

type SpecServiceGitRequired =
  {
  }

specServiceGitArgs :: SpecServiceGitRequired -> SpecServiceGit
specServiceGitArgs _ = SpecServiceGit (inputObject
  [
  ])

specServiceGitBranch :: Input String -> SpecServiceGit -> SpecServiceGit
specServiceGitBranch value (SpecServiceGit values) = SpecServiceGit (insertInputField "branch" (inputJson value) values)

specServiceGitRepoCloneUrl :: Input String -> SpecServiceGit -> SpecServiceGit
specServiceGitRepoCloneUrl value (SpecServiceGit values) = SpecServiceGit (insertInputField "repo_clone_url" (inputJson value) values)

specServiceGitJson :: SpecServiceGit -> Json
specServiceGitJson (SpecServiceGit values) = inputObjectJson values

newtype SpecServiceGithub = SpecServiceGithub InputObject

type SpecServiceGithubRequired =
  {
  }

specServiceGithubArgs :: SpecServiceGithubRequired -> SpecServiceGithub
specServiceGithubArgs _ = SpecServiceGithub (inputObject
  [
  ])

specServiceGithubBranch :: Input String -> SpecServiceGithub -> SpecServiceGithub
specServiceGithubBranch value (SpecServiceGithub values) = SpecServiceGithub (insertInputField "branch" (inputJson value) values)

specServiceGithubDeployOnPush :: Input Boolean -> SpecServiceGithub -> SpecServiceGithub
specServiceGithubDeployOnPush value (SpecServiceGithub values) = SpecServiceGithub (insertInputField "deploy_on_push" (inputJson value) values)

specServiceGithubRepo :: Input String -> SpecServiceGithub -> SpecServiceGithub
specServiceGithubRepo value (SpecServiceGithub values) = SpecServiceGithub (insertInputField "repo" (inputJson value) values)

specServiceGithubJson :: SpecServiceGithub -> Json
specServiceGithubJson (SpecServiceGithub values) = inputObjectJson values

newtype SpecServiceGitlab = SpecServiceGitlab InputObject

type SpecServiceGitlabRequired =
  {
  }

specServiceGitlabArgs :: SpecServiceGitlabRequired -> SpecServiceGitlab
specServiceGitlabArgs _ = SpecServiceGitlab (inputObject
  [
  ])

specServiceGitlabBranch :: Input String -> SpecServiceGitlab -> SpecServiceGitlab
specServiceGitlabBranch value (SpecServiceGitlab values) = SpecServiceGitlab (insertInputField "branch" (inputJson value) values)

specServiceGitlabDeployOnPush :: Input Boolean -> SpecServiceGitlab -> SpecServiceGitlab
specServiceGitlabDeployOnPush value (SpecServiceGitlab values) = SpecServiceGitlab (insertInputField "deploy_on_push" (inputJson value) values)

specServiceGitlabRepo :: Input String -> SpecServiceGitlab -> SpecServiceGitlab
specServiceGitlabRepo value (SpecServiceGitlab values) = SpecServiceGitlab (insertInputField "repo" (inputJson value) values)

specServiceGitlabJson :: SpecServiceGitlab -> Json
specServiceGitlabJson (SpecServiceGitlab values) = inputObjectJson values

newtype SpecServiceHealthCheck = SpecServiceHealthCheck InputObject

type SpecServiceHealthCheckRequired =
  {
  }

specServiceHealthCheckArgs :: SpecServiceHealthCheckRequired -> SpecServiceHealthCheck
specServiceHealthCheckArgs _ = SpecServiceHealthCheck (inputObject
  [
  ])

specServiceHealthCheckFailureThreshold :: Input Number -> SpecServiceHealthCheck -> SpecServiceHealthCheck
specServiceHealthCheckFailureThreshold value (SpecServiceHealthCheck values) = SpecServiceHealthCheck (insertInputField "failure_threshold" (inputJson value) values)

specServiceHealthCheckHttpPath :: Input String -> SpecServiceHealthCheck -> SpecServiceHealthCheck
specServiceHealthCheckHttpPath value (SpecServiceHealthCheck values) = SpecServiceHealthCheck (insertInputField "http_path" (inputJson value) values)

specServiceHealthCheckInitialDelaySeconds :: Input Number -> SpecServiceHealthCheck -> SpecServiceHealthCheck
specServiceHealthCheckInitialDelaySeconds value (SpecServiceHealthCheck values) = SpecServiceHealthCheck (insertInputField "initial_delay_seconds" (inputJson value) values)

specServiceHealthCheckPeriodSeconds :: Input Number -> SpecServiceHealthCheck -> SpecServiceHealthCheck
specServiceHealthCheckPeriodSeconds value (SpecServiceHealthCheck values) = SpecServiceHealthCheck (insertInputField "period_seconds" (inputJson value) values)

specServiceHealthCheckPort :: Input Number -> SpecServiceHealthCheck -> SpecServiceHealthCheck
specServiceHealthCheckPort value (SpecServiceHealthCheck values) = SpecServiceHealthCheck (insertInputField "port" (inputJson value) values)

specServiceHealthCheckSuccessThreshold :: Input Number -> SpecServiceHealthCheck -> SpecServiceHealthCheck
specServiceHealthCheckSuccessThreshold value (SpecServiceHealthCheck values) = SpecServiceHealthCheck (insertInputField "success_threshold" (inputJson value) values)

specServiceHealthCheckTimeoutSeconds :: Input Number -> SpecServiceHealthCheck -> SpecServiceHealthCheck
specServiceHealthCheckTimeoutSeconds value (SpecServiceHealthCheck values) = SpecServiceHealthCheck (insertInputField "timeout_seconds" (inputJson value) values)

specServiceHealthCheckJson :: SpecServiceHealthCheck -> Json
specServiceHealthCheckJson (SpecServiceHealthCheck values) = inputObjectJson values

newtype SpecServiceImage = SpecServiceImage InputObject

type SpecServiceImageRequired =
  { registryType :: Input String
  , repository :: Input String
  }

specServiceImageArgs :: SpecServiceImageRequired -> SpecServiceImage
specServiceImageArgs required = SpecServiceImage (inputObject
  [ Tuple "registry_type" (inputJson required.registryType)
  , Tuple "repository" (inputJson required.repository)
  ])

specServiceImageDeployOnPush :: Array SpecServiceImageDeployOnPush -> SpecServiceImage -> SpecServiceImage
specServiceImageDeployOnPush value (SpecServiceImage values) = SpecServiceImage (insertInputField "deploy_on_push" (arrayExprJson (map specServiceImageDeployOnPushJson value)) values)

specServiceImageDigest :: Input String -> SpecServiceImage -> SpecServiceImage
specServiceImageDigest value (SpecServiceImage values) = SpecServiceImage (insertInputField "digest" (inputJson value) values)

specServiceImageRegistry :: Input String -> SpecServiceImage -> SpecServiceImage
specServiceImageRegistry value (SpecServiceImage values) = SpecServiceImage (insertInputField "registry" (inputJson value) values)

specServiceImageRegistryCredentials :: Input String -> SpecServiceImage -> SpecServiceImage
specServiceImageRegistryCredentials value (SpecServiceImage values) = SpecServiceImage (insertInputField "registry_credentials" (inputJson value) values)

specServiceImageTag :: Input String -> SpecServiceImage -> SpecServiceImage
specServiceImageTag value (SpecServiceImage values) = SpecServiceImage (insertInputField "tag" (inputJson value) values)

specServiceImageJson :: SpecServiceImage -> Json
specServiceImageJson (SpecServiceImage values) = inputObjectJson values

newtype SpecServiceImageDeployOnPush = SpecServiceImageDeployOnPush InputObject

type SpecServiceImageDeployOnPushRequired =
  {
  }

specServiceImageDeployOnPushArgs :: SpecServiceImageDeployOnPushRequired -> SpecServiceImageDeployOnPush
specServiceImageDeployOnPushArgs _ = SpecServiceImageDeployOnPush (inputObject
  [
  ])

specServiceImageDeployOnPushEnabled :: Input Boolean -> SpecServiceImageDeployOnPush -> SpecServiceImageDeployOnPush
specServiceImageDeployOnPushEnabled value (SpecServiceImageDeployOnPush values) = SpecServiceImageDeployOnPush (insertInputField "enabled" (inputJson value) values)

specServiceImageDeployOnPushJson :: SpecServiceImageDeployOnPush -> Json
specServiceImageDeployOnPushJson (SpecServiceImageDeployOnPush values) = inputObjectJson values

newtype SpecServiceLivenessHealthCheck = SpecServiceLivenessHealthCheck InputObject

type SpecServiceLivenessHealthCheckRequired =
  {
  }

specServiceLivenessHealthCheckArgs :: SpecServiceLivenessHealthCheckRequired -> SpecServiceLivenessHealthCheck
specServiceLivenessHealthCheckArgs _ = SpecServiceLivenessHealthCheck (inputObject
  [
  ])

specServiceLivenessHealthCheckFailureThreshold :: Input Number -> SpecServiceLivenessHealthCheck -> SpecServiceLivenessHealthCheck
specServiceLivenessHealthCheckFailureThreshold value (SpecServiceLivenessHealthCheck values) = SpecServiceLivenessHealthCheck (insertInputField "failure_threshold" (inputJson value) values)

specServiceLivenessHealthCheckHttpPath :: Input String -> SpecServiceLivenessHealthCheck -> SpecServiceLivenessHealthCheck
specServiceLivenessHealthCheckHttpPath value (SpecServiceLivenessHealthCheck values) = SpecServiceLivenessHealthCheck (insertInputField "http_path" (inputJson value) values)

specServiceLivenessHealthCheckInitialDelaySeconds :: Input Number -> SpecServiceLivenessHealthCheck -> SpecServiceLivenessHealthCheck
specServiceLivenessHealthCheckInitialDelaySeconds value (SpecServiceLivenessHealthCheck values) = SpecServiceLivenessHealthCheck (insertInputField "initial_delay_seconds" (inputJson value) values)

specServiceLivenessHealthCheckPeriodSeconds :: Input Number -> SpecServiceLivenessHealthCheck -> SpecServiceLivenessHealthCheck
specServiceLivenessHealthCheckPeriodSeconds value (SpecServiceLivenessHealthCheck values) = SpecServiceLivenessHealthCheck (insertInputField "period_seconds" (inputJson value) values)

specServiceLivenessHealthCheckPort :: Input Number -> SpecServiceLivenessHealthCheck -> SpecServiceLivenessHealthCheck
specServiceLivenessHealthCheckPort value (SpecServiceLivenessHealthCheck values) = SpecServiceLivenessHealthCheck (insertInputField "port" (inputJson value) values)

specServiceLivenessHealthCheckSuccessThreshold :: Input Number -> SpecServiceLivenessHealthCheck -> SpecServiceLivenessHealthCheck
specServiceLivenessHealthCheckSuccessThreshold value (SpecServiceLivenessHealthCheck values) = SpecServiceLivenessHealthCheck (insertInputField "success_threshold" (inputJson value) values)

specServiceLivenessHealthCheckTimeoutSeconds :: Input Number -> SpecServiceLivenessHealthCheck -> SpecServiceLivenessHealthCheck
specServiceLivenessHealthCheckTimeoutSeconds value (SpecServiceLivenessHealthCheck values) = SpecServiceLivenessHealthCheck (insertInputField "timeout_seconds" (inputJson value) values)

specServiceLivenessHealthCheckJson :: SpecServiceLivenessHealthCheck -> Json
specServiceLivenessHealthCheckJson (SpecServiceLivenessHealthCheck values) = inputObjectJson values

newtype SpecServiceLogDestination = SpecServiceLogDestination InputObject

type SpecServiceLogDestinationRequired =
  { name :: Input String
  }

specServiceLogDestinationArgs :: SpecServiceLogDestinationRequired -> SpecServiceLogDestination
specServiceLogDestinationArgs required = SpecServiceLogDestination (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

specServiceLogDestinationDatadog :: Array SpecServiceLogDestinationDatadog -> SpecServiceLogDestination -> SpecServiceLogDestination
specServiceLogDestinationDatadog value (SpecServiceLogDestination values) = SpecServiceLogDestination (insertInputField "datadog" (arrayExprJson (map specServiceLogDestinationDatadogJson value)) values)

specServiceLogDestinationLogtail :: Array SpecServiceLogDestinationLogtail -> SpecServiceLogDestination -> SpecServiceLogDestination
specServiceLogDestinationLogtail value (SpecServiceLogDestination values) = SpecServiceLogDestination (insertInputField "logtail" (arrayExprJson (map specServiceLogDestinationLogtailJson value)) values)

specServiceLogDestinationOpenSearch :: Array SpecServiceLogDestinationOpenSearch -> SpecServiceLogDestination -> SpecServiceLogDestination
specServiceLogDestinationOpenSearch value (SpecServiceLogDestination values) = SpecServiceLogDestination (insertInputField "open_search" (arrayExprJson (map specServiceLogDestinationOpenSearchJson value)) values)

specServiceLogDestinationPapertrail :: Array SpecServiceLogDestinationPapertrail -> SpecServiceLogDestination -> SpecServiceLogDestination
specServiceLogDestinationPapertrail value (SpecServiceLogDestination values) = SpecServiceLogDestination (insertInputField "papertrail" (arrayExprJson (map specServiceLogDestinationPapertrailJson value)) values)

specServiceLogDestinationJson :: SpecServiceLogDestination -> Json
specServiceLogDestinationJson (SpecServiceLogDestination values) = inputObjectJson values

newtype SpecServiceLogDestinationDatadog = SpecServiceLogDestinationDatadog InputObject

type SpecServiceLogDestinationDatadogRequired =
  { apiKey :: Input String
  }

specServiceLogDestinationDatadogArgs :: SpecServiceLogDestinationDatadogRequired -> SpecServiceLogDestinationDatadog
specServiceLogDestinationDatadogArgs required = SpecServiceLogDestinationDatadog (inputObject
  [ Tuple "api_key" (inputJson required.apiKey)
  ])

specServiceLogDestinationDatadogEndpoint :: Input String -> SpecServiceLogDestinationDatadog -> SpecServiceLogDestinationDatadog
specServiceLogDestinationDatadogEndpoint value (SpecServiceLogDestinationDatadog values) = SpecServiceLogDestinationDatadog (insertInputField "endpoint" (inputJson value) values)

specServiceLogDestinationDatadogJson :: SpecServiceLogDestinationDatadog -> Json
specServiceLogDestinationDatadogJson (SpecServiceLogDestinationDatadog values) = inputObjectJson values

newtype SpecServiceLogDestinationLogtail = SpecServiceLogDestinationLogtail InputObject

type SpecServiceLogDestinationLogtailRequired =
  { token :: Input String
  }

specServiceLogDestinationLogtailArgs :: SpecServiceLogDestinationLogtailRequired -> SpecServiceLogDestinationLogtail
specServiceLogDestinationLogtailArgs required = SpecServiceLogDestinationLogtail (inputObject
  [ Tuple "token" (inputJson required.token)
  ])

specServiceLogDestinationLogtailJson :: SpecServiceLogDestinationLogtail -> Json
specServiceLogDestinationLogtailJson (SpecServiceLogDestinationLogtail values) = inputObjectJson values

newtype SpecServiceLogDestinationOpenSearch = SpecServiceLogDestinationOpenSearch InputObject

type SpecServiceLogDestinationOpenSearchRequired =
  { basicAuth :: Array SpecServiceLogDestinationOpenSearchBasicAuth
  }

specServiceLogDestinationOpenSearchArgs :: SpecServiceLogDestinationOpenSearchRequired -> SpecServiceLogDestinationOpenSearch
specServiceLogDestinationOpenSearchArgs required = SpecServiceLogDestinationOpenSearch (inputObject
  [ Tuple "basic_auth" (arrayExprJson (map specServiceLogDestinationOpenSearchBasicAuthJson required.basicAuth))
  ])

specServiceLogDestinationOpenSearchClusterName :: Input String -> SpecServiceLogDestinationOpenSearch -> SpecServiceLogDestinationOpenSearch
specServiceLogDestinationOpenSearchClusterName value (SpecServiceLogDestinationOpenSearch values) = SpecServiceLogDestinationOpenSearch (insertInputField "cluster_name" (inputJson value) values)

specServiceLogDestinationOpenSearchEndpoint :: Input String -> SpecServiceLogDestinationOpenSearch -> SpecServiceLogDestinationOpenSearch
specServiceLogDestinationOpenSearchEndpoint value (SpecServiceLogDestinationOpenSearch values) = SpecServiceLogDestinationOpenSearch (insertInputField "endpoint" (inputJson value) values)

specServiceLogDestinationOpenSearchIndexName :: Input String -> SpecServiceLogDestinationOpenSearch -> SpecServiceLogDestinationOpenSearch
specServiceLogDestinationOpenSearchIndexName value (SpecServiceLogDestinationOpenSearch values) = SpecServiceLogDestinationOpenSearch (insertInputField "index_name" (inputJson value) values)

specServiceLogDestinationOpenSearchJson :: SpecServiceLogDestinationOpenSearch -> Json
specServiceLogDestinationOpenSearchJson (SpecServiceLogDestinationOpenSearch values) = inputObjectJson values

newtype SpecServiceLogDestinationOpenSearchBasicAuth = SpecServiceLogDestinationOpenSearchBasicAuth InputObject

type SpecServiceLogDestinationOpenSearchBasicAuthRequired =
  {
  }

specServiceLogDestinationOpenSearchBasicAuthArgs :: SpecServiceLogDestinationOpenSearchBasicAuthRequired -> SpecServiceLogDestinationOpenSearchBasicAuth
specServiceLogDestinationOpenSearchBasicAuthArgs _ = SpecServiceLogDestinationOpenSearchBasicAuth (inputObject
  [
  ])

specServiceLogDestinationOpenSearchBasicAuthPassword :: Input String -> SpecServiceLogDestinationOpenSearchBasicAuth -> SpecServiceLogDestinationOpenSearchBasicAuth
specServiceLogDestinationOpenSearchBasicAuthPassword value (SpecServiceLogDestinationOpenSearchBasicAuth values) = SpecServiceLogDestinationOpenSearchBasicAuth (insertInputField "password" (inputJson value) values)

specServiceLogDestinationOpenSearchBasicAuthUser :: Input String -> SpecServiceLogDestinationOpenSearchBasicAuth -> SpecServiceLogDestinationOpenSearchBasicAuth
specServiceLogDestinationOpenSearchBasicAuthUser value (SpecServiceLogDestinationOpenSearchBasicAuth values) = SpecServiceLogDestinationOpenSearchBasicAuth (insertInputField "user" (inputJson value) values)

specServiceLogDestinationOpenSearchBasicAuthJson :: SpecServiceLogDestinationOpenSearchBasicAuth -> Json
specServiceLogDestinationOpenSearchBasicAuthJson (SpecServiceLogDestinationOpenSearchBasicAuth values) = inputObjectJson values

newtype SpecServiceLogDestinationPapertrail = SpecServiceLogDestinationPapertrail InputObject

type SpecServiceLogDestinationPapertrailRequired =
  { endpoint :: Input String
  }

specServiceLogDestinationPapertrailArgs :: SpecServiceLogDestinationPapertrailRequired -> SpecServiceLogDestinationPapertrail
specServiceLogDestinationPapertrailArgs required = SpecServiceLogDestinationPapertrail (inputObject
  [ Tuple "endpoint" (inputJson required.endpoint)
  ])

specServiceLogDestinationPapertrailJson :: SpecServiceLogDestinationPapertrail -> Json
specServiceLogDestinationPapertrailJson (SpecServiceLogDestinationPapertrail values) = inputObjectJson values

newtype SpecServiceRoutes = SpecServiceRoutes InputObject

type SpecServiceRoutesRequired =
  {
  }

specServiceRoutesArgs :: SpecServiceRoutesRequired -> SpecServiceRoutes
specServiceRoutesArgs _ = SpecServiceRoutes (inputObject
  [
  ])

specServiceRoutesPath :: Input String -> SpecServiceRoutes -> SpecServiceRoutes
specServiceRoutesPath value (SpecServiceRoutes values) = SpecServiceRoutes (insertInputField "path" (inputJson value) values)

specServiceRoutesPreservePathPrefix :: Input Boolean -> SpecServiceRoutes -> SpecServiceRoutes
specServiceRoutesPreservePathPrefix value (SpecServiceRoutes values) = SpecServiceRoutes (insertInputField "preserve_path_prefix" (inputJson value) values)

specServiceRoutesJson :: SpecServiceRoutes -> Json
specServiceRoutesJson (SpecServiceRoutes values) = inputObjectJson values

newtype SpecServiceTermination = SpecServiceTermination InputObject

type SpecServiceTerminationRequired =
  {
  }

specServiceTerminationArgs :: SpecServiceTerminationRequired -> SpecServiceTermination
specServiceTerminationArgs _ = SpecServiceTermination (inputObject
  [
  ])

specServiceTerminationDrainSeconds :: Input Number -> SpecServiceTermination -> SpecServiceTermination
specServiceTerminationDrainSeconds value (SpecServiceTermination values) = SpecServiceTermination (insertInputField "drain_seconds" (inputJson value) values)

specServiceTerminationGracePeriodSeconds :: Input Number -> SpecServiceTermination -> SpecServiceTermination
specServiceTerminationGracePeriodSeconds value (SpecServiceTermination values) = SpecServiceTermination (insertInputField "grace_period_seconds" (inputJson value) values)

specServiceTerminationJson :: SpecServiceTermination -> Json
specServiceTerminationJson (SpecServiceTermination values) = inputObjectJson values

newtype SpecStaticSite = SpecStaticSite InputObject

type SpecStaticSiteRequired =
  { name :: Input String
  }

specStaticSiteArgs :: SpecStaticSiteRequired -> SpecStaticSite
specStaticSiteArgs required = SpecStaticSite (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

specStaticSiteBitbucket :: Array SpecStaticSiteBitbucket -> SpecStaticSite -> SpecStaticSite
specStaticSiteBitbucket value (SpecStaticSite values) = SpecStaticSite (insertInputField "bitbucket" (arrayExprJson (map specStaticSiteBitbucketJson value)) values)

specStaticSiteBuildCommand :: Input String -> SpecStaticSite -> SpecStaticSite
specStaticSiteBuildCommand value (SpecStaticSite values) = SpecStaticSite (insertInputField "build_command" (inputJson value) values)

specStaticSiteCatchallDocument :: Input String -> SpecStaticSite -> SpecStaticSite
specStaticSiteCatchallDocument value (SpecStaticSite values) = SpecStaticSite (insertInputField "catchall_document" (inputJson value) values)

specStaticSiteCors :: Array SpecStaticSiteCors -> SpecStaticSite -> SpecStaticSite
specStaticSiteCors value (SpecStaticSite values) = SpecStaticSite (insertInputField "cors" (arrayExprJson (map specStaticSiteCorsJson value)) values)

specStaticSiteDockerfilePath :: Input String -> SpecStaticSite -> SpecStaticSite
specStaticSiteDockerfilePath value (SpecStaticSite values) = SpecStaticSite (insertInputField "dockerfile_path" (inputJson value) values)

specStaticSiteEnv :: Array SpecStaticSiteEnv -> SpecStaticSite -> SpecStaticSite
specStaticSiteEnv value (SpecStaticSite values) = SpecStaticSite (insertInputField "env" (arrayExprJson (map specStaticSiteEnvJson value)) values)

specStaticSiteEnvironmentSlug :: Input String -> SpecStaticSite -> SpecStaticSite
specStaticSiteEnvironmentSlug value (SpecStaticSite values) = SpecStaticSite (insertInputField "environment_slug" (inputJson value) values)

specStaticSiteErrorDocument :: Input String -> SpecStaticSite -> SpecStaticSite
specStaticSiteErrorDocument value (SpecStaticSite values) = SpecStaticSite (insertInputField "error_document" (inputJson value) values)

specStaticSiteGit :: Array SpecStaticSiteGit -> SpecStaticSite -> SpecStaticSite
specStaticSiteGit value (SpecStaticSite values) = SpecStaticSite (insertInputField "git" (arrayExprJson (map specStaticSiteGitJson value)) values)

specStaticSiteGithub :: Array SpecStaticSiteGithub -> SpecStaticSite -> SpecStaticSite
specStaticSiteGithub value (SpecStaticSite values) = SpecStaticSite (insertInputField "github" (arrayExprJson (map specStaticSiteGithubJson value)) values)

specStaticSiteGitlab :: Array SpecStaticSiteGitlab -> SpecStaticSite -> SpecStaticSite
specStaticSiteGitlab value (SpecStaticSite values) = SpecStaticSite (insertInputField "gitlab" (arrayExprJson (map specStaticSiteGitlabJson value)) values)

specStaticSiteIndexDocument :: Input String -> SpecStaticSite -> SpecStaticSite
specStaticSiteIndexDocument value (SpecStaticSite values) = SpecStaticSite (insertInputField "index_document" (inputJson value) values)

specStaticSiteOutputDir :: Input String -> SpecStaticSite -> SpecStaticSite
specStaticSiteOutputDir value (SpecStaticSite values) = SpecStaticSite (insertInputField "output_dir" (inputJson value) values)

specStaticSiteRoutes :: Array SpecStaticSiteRoutes -> SpecStaticSite -> SpecStaticSite
specStaticSiteRoutes value (SpecStaticSite values) = SpecStaticSite (insertInputField "routes" (arrayExprJson (map specStaticSiteRoutesJson value)) values)

specStaticSiteSourceDir :: Input String -> SpecStaticSite -> SpecStaticSite
specStaticSiteSourceDir value (SpecStaticSite values) = SpecStaticSite (insertInputField "source_dir" (inputJson value) values)

specStaticSiteJson :: SpecStaticSite -> Json
specStaticSiteJson (SpecStaticSite values) = inputObjectJson values

newtype SpecStaticSiteBitbucket = SpecStaticSiteBitbucket InputObject

type SpecStaticSiteBitbucketRequired =
  {
  }

specStaticSiteBitbucketArgs :: SpecStaticSiteBitbucketRequired -> SpecStaticSiteBitbucket
specStaticSiteBitbucketArgs _ = SpecStaticSiteBitbucket (inputObject
  [
  ])

specStaticSiteBitbucketBranch :: Input String -> SpecStaticSiteBitbucket -> SpecStaticSiteBitbucket
specStaticSiteBitbucketBranch value (SpecStaticSiteBitbucket values) = SpecStaticSiteBitbucket (insertInputField "branch" (inputJson value) values)

specStaticSiteBitbucketDeployOnPush :: Input Boolean -> SpecStaticSiteBitbucket -> SpecStaticSiteBitbucket
specStaticSiteBitbucketDeployOnPush value (SpecStaticSiteBitbucket values) = SpecStaticSiteBitbucket (insertInputField "deploy_on_push" (inputJson value) values)

specStaticSiteBitbucketRepo :: Input String -> SpecStaticSiteBitbucket -> SpecStaticSiteBitbucket
specStaticSiteBitbucketRepo value (SpecStaticSiteBitbucket values) = SpecStaticSiteBitbucket (insertInputField "repo" (inputJson value) values)

specStaticSiteBitbucketJson :: SpecStaticSiteBitbucket -> Json
specStaticSiteBitbucketJson (SpecStaticSiteBitbucket values) = inputObjectJson values

newtype SpecStaticSiteCors = SpecStaticSiteCors InputObject

type SpecStaticSiteCorsRequired =
  {
  }

specStaticSiteCorsArgs :: SpecStaticSiteCorsRequired -> SpecStaticSiteCors
specStaticSiteCorsArgs _ = SpecStaticSiteCors (inputObject
  [
  ])

specStaticSiteCorsAllowCredentials :: Input Boolean -> SpecStaticSiteCors -> SpecStaticSiteCors
specStaticSiteCorsAllowCredentials value (SpecStaticSiteCors values) = SpecStaticSiteCors (insertInputField "allow_credentials" (inputJson value) values)

specStaticSiteCorsAllowHeaders :: Input (Array String) -> SpecStaticSiteCors -> SpecStaticSiteCors
specStaticSiteCorsAllowHeaders value (SpecStaticSiteCors values) = SpecStaticSiteCors (insertInputField "allow_headers" (inputJson value) values)

specStaticSiteCorsAllowMethods :: Input (Array String) -> SpecStaticSiteCors -> SpecStaticSiteCors
specStaticSiteCorsAllowMethods value (SpecStaticSiteCors values) = SpecStaticSiteCors (insertInputField "allow_methods" (inputJson value) values)

specStaticSiteCorsAllowOrigins :: Array SpecStaticSiteCorsAllowOrigins -> SpecStaticSiteCors -> SpecStaticSiteCors
specStaticSiteCorsAllowOrigins value (SpecStaticSiteCors values) = SpecStaticSiteCors (insertInputField "allow_origins" (arrayExprJson (map specStaticSiteCorsAllowOriginsJson value)) values)

specStaticSiteCorsExposeHeaders :: Input (Array String) -> SpecStaticSiteCors -> SpecStaticSiteCors
specStaticSiteCorsExposeHeaders value (SpecStaticSiteCors values) = SpecStaticSiteCors (insertInputField "expose_headers" (inputJson value) values)

specStaticSiteCorsMaxAge :: Input String -> SpecStaticSiteCors -> SpecStaticSiteCors
specStaticSiteCorsMaxAge value (SpecStaticSiteCors values) = SpecStaticSiteCors (insertInputField "max_age" (inputJson value) values)

specStaticSiteCorsJson :: SpecStaticSiteCors -> Json
specStaticSiteCorsJson (SpecStaticSiteCors values) = inputObjectJson values

newtype SpecStaticSiteCorsAllowOrigins = SpecStaticSiteCorsAllowOrigins InputObject

type SpecStaticSiteCorsAllowOriginsRequired =
  {
  }

specStaticSiteCorsAllowOriginsArgs :: SpecStaticSiteCorsAllowOriginsRequired -> SpecStaticSiteCorsAllowOrigins
specStaticSiteCorsAllowOriginsArgs _ = SpecStaticSiteCorsAllowOrigins (inputObject
  [
  ])

specStaticSiteCorsAllowOriginsExact :: Input String -> SpecStaticSiteCorsAllowOrigins -> SpecStaticSiteCorsAllowOrigins
specStaticSiteCorsAllowOriginsExact value (SpecStaticSiteCorsAllowOrigins values) = SpecStaticSiteCorsAllowOrigins (insertInputField "exact" (inputJson value) values)

specStaticSiteCorsAllowOriginsPrefix :: Input String -> SpecStaticSiteCorsAllowOrigins -> SpecStaticSiteCorsAllowOrigins
specStaticSiteCorsAllowOriginsPrefix value (SpecStaticSiteCorsAllowOrigins values) = SpecStaticSiteCorsAllowOrigins (insertInputField "prefix" (inputJson value) values)

specStaticSiteCorsAllowOriginsRegex :: Input String -> SpecStaticSiteCorsAllowOrigins -> SpecStaticSiteCorsAllowOrigins
specStaticSiteCorsAllowOriginsRegex value (SpecStaticSiteCorsAllowOrigins values) = SpecStaticSiteCorsAllowOrigins (insertInputField "regex" (inputJson value) values)

specStaticSiteCorsAllowOriginsJson :: SpecStaticSiteCorsAllowOrigins -> Json
specStaticSiteCorsAllowOriginsJson (SpecStaticSiteCorsAllowOrigins values) = inputObjectJson values

newtype SpecStaticSiteEnv = SpecStaticSiteEnv InputObject

type SpecStaticSiteEnvRequired =
  {
  }

specStaticSiteEnvArgs :: SpecStaticSiteEnvRequired -> SpecStaticSiteEnv
specStaticSiteEnvArgs _ = SpecStaticSiteEnv (inputObject
  [
  ])

specStaticSiteEnvKey :: Input String -> SpecStaticSiteEnv -> SpecStaticSiteEnv
specStaticSiteEnvKey value (SpecStaticSiteEnv values) = SpecStaticSiteEnv (insertInputField "key" (inputJson value) values)

specStaticSiteEnvScope :: Input String -> SpecStaticSiteEnv -> SpecStaticSiteEnv
specStaticSiteEnvScope value (SpecStaticSiteEnv values) = SpecStaticSiteEnv (insertInputField "scope" (inputJson value) values)

specStaticSiteEnvType :: Input String -> SpecStaticSiteEnv -> SpecStaticSiteEnv
specStaticSiteEnvType value (SpecStaticSiteEnv values) = SpecStaticSiteEnv (insertInputField "type" (inputJson value) values)

specStaticSiteEnvValue :: Input String -> SpecStaticSiteEnv -> SpecStaticSiteEnv
specStaticSiteEnvValue value (SpecStaticSiteEnv values) = SpecStaticSiteEnv (insertInputField "value" (inputJson value) values)

specStaticSiteEnvJson :: SpecStaticSiteEnv -> Json
specStaticSiteEnvJson (SpecStaticSiteEnv values) = inputObjectJson values

newtype SpecStaticSiteGit = SpecStaticSiteGit InputObject

type SpecStaticSiteGitRequired =
  {
  }

specStaticSiteGitArgs :: SpecStaticSiteGitRequired -> SpecStaticSiteGit
specStaticSiteGitArgs _ = SpecStaticSiteGit (inputObject
  [
  ])

specStaticSiteGitBranch :: Input String -> SpecStaticSiteGit -> SpecStaticSiteGit
specStaticSiteGitBranch value (SpecStaticSiteGit values) = SpecStaticSiteGit (insertInputField "branch" (inputJson value) values)

specStaticSiteGitRepoCloneUrl :: Input String -> SpecStaticSiteGit -> SpecStaticSiteGit
specStaticSiteGitRepoCloneUrl value (SpecStaticSiteGit values) = SpecStaticSiteGit (insertInputField "repo_clone_url" (inputJson value) values)

specStaticSiteGitJson :: SpecStaticSiteGit -> Json
specStaticSiteGitJson (SpecStaticSiteGit values) = inputObjectJson values

newtype SpecStaticSiteGithub = SpecStaticSiteGithub InputObject

type SpecStaticSiteGithubRequired =
  {
  }

specStaticSiteGithubArgs :: SpecStaticSiteGithubRequired -> SpecStaticSiteGithub
specStaticSiteGithubArgs _ = SpecStaticSiteGithub (inputObject
  [
  ])

specStaticSiteGithubBranch :: Input String -> SpecStaticSiteGithub -> SpecStaticSiteGithub
specStaticSiteGithubBranch value (SpecStaticSiteGithub values) = SpecStaticSiteGithub (insertInputField "branch" (inputJson value) values)

specStaticSiteGithubDeployOnPush :: Input Boolean -> SpecStaticSiteGithub -> SpecStaticSiteGithub
specStaticSiteGithubDeployOnPush value (SpecStaticSiteGithub values) = SpecStaticSiteGithub (insertInputField "deploy_on_push" (inputJson value) values)

specStaticSiteGithubRepo :: Input String -> SpecStaticSiteGithub -> SpecStaticSiteGithub
specStaticSiteGithubRepo value (SpecStaticSiteGithub values) = SpecStaticSiteGithub (insertInputField "repo" (inputJson value) values)

specStaticSiteGithubJson :: SpecStaticSiteGithub -> Json
specStaticSiteGithubJson (SpecStaticSiteGithub values) = inputObjectJson values

newtype SpecStaticSiteGitlab = SpecStaticSiteGitlab InputObject

type SpecStaticSiteGitlabRequired =
  {
  }

specStaticSiteGitlabArgs :: SpecStaticSiteGitlabRequired -> SpecStaticSiteGitlab
specStaticSiteGitlabArgs _ = SpecStaticSiteGitlab (inputObject
  [
  ])

specStaticSiteGitlabBranch :: Input String -> SpecStaticSiteGitlab -> SpecStaticSiteGitlab
specStaticSiteGitlabBranch value (SpecStaticSiteGitlab values) = SpecStaticSiteGitlab (insertInputField "branch" (inputJson value) values)

specStaticSiteGitlabDeployOnPush :: Input Boolean -> SpecStaticSiteGitlab -> SpecStaticSiteGitlab
specStaticSiteGitlabDeployOnPush value (SpecStaticSiteGitlab values) = SpecStaticSiteGitlab (insertInputField "deploy_on_push" (inputJson value) values)

specStaticSiteGitlabRepo :: Input String -> SpecStaticSiteGitlab -> SpecStaticSiteGitlab
specStaticSiteGitlabRepo value (SpecStaticSiteGitlab values) = SpecStaticSiteGitlab (insertInputField "repo" (inputJson value) values)

specStaticSiteGitlabJson :: SpecStaticSiteGitlab -> Json
specStaticSiteGitlabJson (SpecStaticSiteGitlab values) = inputObjectJson values

newtype SpecStaticSiteRoutes = SpecStaticSiteRoutes InputObject

type SpecStaticSiteRoutesRequired =
  {
  }

specStaticSiteRoutesArgs :: SpecStaticSiteRoutesRequired -> SpecStaticSiteRoutes
specStaticSiteRoutesArgs _ = SpecStaticSiteRoutes (inputObject
  [
  ])

specStaticSiteRoutesPath :: Input String -> SpecStaticSiteRoutes -> SpecStaticSiteRoutes
specStaticSiteRoutesPath value (SpecStaticSiteRoutes values) = SpecStaticSiteRoutes (insertInputField "path" (inputJson value) values)

specStaticSiteRoutesPreservePathPrefix :: Input Boolean -> SpecStaticSiteRoutes -> SpecStaticSiteRoutes
specStaticSiteRoutesPreservePathPrefix value (SpecStaticSiteRoutes values) = SpecStaticSiteRoutes (insertInputField "preserve_path_prefix" (inputJson value) values)

specStaticSiteRoutesJson :: SpecStaticSiteRoutes -> Json
specStaticSiteRoutesJson (SpecStaticSiteRoutes values) = inputObjectJson values

newtype SpecVpc = SpecVpc InputObject

type SpecVpcRequired =
  { id :: Input String
  }

specVpcArgs :: SpecVpcRequired -> SpecVpc
specVpcArgs required = SpecVpc (inputObject
  [ Tuple "id" (inputJson required.id)
  ])

specVpcJson :: SpecVpc -> Json
specVpcJson (SpecVpc values) = inputObjectJson values

newtype SpecWorker = SpecWorker InputObject

type SpecWorkerRequired =
  { name :: Input String
  }

specWorkerArgs :: SpecWorkerRequired -> SpecWorker
specWorkerArgs required = SpecWorker (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

specWorkerAlert :: Array SpecWorkerAlert -> SpecWorker -> SpecWorker
specWorkerAlert value (SpecWorker values) = SpecWorker (insertInputField "alert" (arrayExprJson (map specWorkerAlertJson value)) values)

specWorkerAutoscaling :: Array SpecWorkerAutoscaling -> SpecWorker -> SpecWorker
specWorkerAutoscaling value (SpecWorker values) = SpecWorker (insertInputField "autoscaling" (arrayExprJson (map specWorkerAutoscalingJson value)) values)

specWorkerBitbucket :: Array SpecWorkerBitbucket -> SpecWorker -> SpecWorker
specWorkerBitbucket value (SpecWorker values) = SpecWorker (insertInputField "bitbucket" (arrayExprJson (map specWorkerBitbucketJson value)) values)

specWorkerBuildCommand :: Input String -> SpecWorker -> SpecWorker
specWorkerBuildCommand value (SpecWorker values) = SpecWorker (insertInputField "build_command" (inputJson value) values)

specWorkerDockerfilePath :: Input String -> SpecWorker -> SpecWorker
specWorkerDockerfilePath value (SpecWorker values) = SpecWorker (insertInputField "dockerfile_path" (inputJson value) values)

specWorkerEnv :: Array SpecWorkerEnv -> SpecWorker -> SpecWorker
specWorkerEnv value (SpecWorker values) = SpecWorker (insertInputField "env" (arrayExprJson (map specWorkerEnvJson value)) values)

specWorkerEnvironmentSlug :: Input String -> SpecWorker -> SpecWorker
specWorkerEnvironmentSlug value (SpecWorker values) = SpecWorker (insertInputField "environment_slug" (inputJson value) values)

specWorkerGit :: Array SpecWorkerGit -> SpecWorker -> SpecWorker
specWorkerGit value (SpecWorker values) = SpecWorker (insertInputField "git" (arrayExprJson (map specWorkerGitJson value)) values)

specWorkerGithub :: Array SpecWorkerGithub -> SpecWorker -> SpecWorker
specWorkerGithub value (SpecWorker values) = SpecWorker (insertInputField "github" (arrayExprJson (map specWorkerGithubJson value)) values)

specWorkerGitlab :: Array SpecWorkerGitlab -> SpecWorker -> SpecWorker
specWorkerGitlab value (SpecWorker values) = SpecWorker (insertInputField "gitlab" (arrayExprJson (map specWorkerGitlabJson value)) values)

specWorkerImage :: Array SpecWorkerImage -> SpecWorker -> SpecWorker
specWorkerImage value (SpecWorker values) = SpecWorker (insertInputField "image" (arrayExprJson (map specWorkerImageJson value)) values)

specWorkerInstanceCount :: Input Number -> SpecWorker -> SpecWorker
specWorkerInstanceCount value (SpecWorker values) = SpecWorker (insertInputField "instance_count" (inputJson value) values)

specWorkerInstanceSizeSlug :: Input String -> SpecWorker -> SpecWorker
specWorkerInstanceSizeSlug value (SpecWorker values) = SpecWorker (insertInputField "instance_size_slug" (inputJson value) values)

specWorkerLivenessHealthCheck :: Array SpecWorkerLivenessHealthCheck -> SpecWorker -> SpecWorker
specWorkerLivenessHealthCheck value (SpecWorker values) = SpecWorker (insertInputField "liveness_health_check" (arrayExprJson (map specWorkerLivenessHealthCheckJson value)) values)

specWorkerLogDestination :: Array SpecWorkerLogDestination -> SpecWorker -> SpecWorker
specWorkerLogDestination value (SpecWorker values) = SpecWorker (insertInputField "log_destination" (arrayExprJson (map specWorkerLogDestinationJson value)) values)

specWorkerRunCommand :: Input String -> SpecWorker -> SpecWorker
specWorkerRunCommand value (SpecWorker values) = SpecWorker (insertInputField "run_command" (inputJson value) values)

specWorkerSourceDir :: Input String -> SpecWorker -> SpecWorker
specWorkerSourceDir value (SpecWorker values) = SpecWorker (insertInputField "source_dir" (inputJson value) values)

specWorkerTermination :: Array SpecWorkerTermination -> SpecWorker -> SpecWorker
specWorkerTermination value (SpecWorker values) = SpecWorker (insertInputField "termination" (arrayExprJson (map specWorkerTerminationJson value)) values)

specWorkerJson :: SpecWorker -> Json
specWorkerJson (SpecWorker values) = inputObjectJson values

newtype SpecWorkerAlert = SpecWorkerAlert InputObject

type SpecWorkerAlertRequired =
  { operator :: Input String
  , rule :: Input String
  , value :: Input Number
  , window :: Input String
  }

specWorkerAlertArgs :: SpecWorkerAlertRequired -> SpecWorkerAlert
specWorkerAlertArgs required = SpecWorkerAlert (inputObject
  [ Tuple "operator" (inputJson required.operator)
  , Tuple "rule" (inputJson required.rule)
  , Tuple "value" (inputJson required.value)
  , Tuple "window" (inputJson required.window)
  ])

specWorkerAlertDestinations :: Array SpecWorkerAlertDestinations -> SpecWorkerAlert -> SpecWorkerAlert
specWorkerAlertDestinations value (SpecWorkerAlert values) = SpecWorkerAlert (insertInputField "destinations" (arrayExprJson (map specWorkerAlertDestinationsJson value)) values)

specWorkerAlertDisabled :: Input Boolean -> SpecWorkerAlert -> SpecWorkerAlert
specWorkerAlertDisabled value (SpecWorkerAlert values) = SpecWorkerAlert (insertInputField "disabled" (inputJson value) values)

specWorkerAlertJson :: SpecWorkerAlert -> Json
specWorkerAlertJson (SpecWorkerAlert values) = inputObjectJson values

newtype SpecWorkerAlertDestinations = SpecWorkerAlertDestinations InputObject

type SpecWorkerAlertDestinationsRequired =
  {
  }

specWorkerAlertDestinationsArgs :: SpecWorkerAlertDestinationsRequired -> SpecWorkerAlertDestinations
specWorkerAlertDestinationsArgs _ = SpecWorkerAlertDestinations (inputObject
  [
  ])

specWorkerAlertDestinationsEmails :: Input (Array String) -> SpecWorkerAlertDestinations -> SpecWorkerAlertDestinations
specWorkerAlertDestinationsEmails value (SpecWorkerAlertDestinations values) = SpecWorkerAlertDestinations (insertInputField "emails" (inputJson value) values)

specWorkerAlertDestinationsSlackWebhooks :: Array SpecWorkerAlertDestinationsSlackWebhooks -> SpecWorkerAlertDestinations -> SpecWorkerAlertDestinations
specWorkerAlertDestinationsSlackWebhooks value (SpecWorkerAlertDestinations values) = SpecWorkerAlertDestinations (insertInputField "slack_webhooks" (arrayExprJson (map specWorkerAlertDestinationsSlackWebhooksJson value)) values)

specWorkerAlertDestinationsJson :: SpecWorkerAlertDestinations -> Json
specWorkerAlertDestinationsJson (SpecWorkerAlertDestinations values) = inputObjectJson values

newtype SpecWorkerAlertDestinationsSlackWebhooks = SpecWorkerAlertDestinationsSlackWebhooks InputObject

type SpecWorkerAlertDestinationsSlackWebhooksRequired =
  { channel :: Input String
  , url :: Input String
  }

specWorkerAlertDestinationsSlackWebhooksArgs :: SpecWorkerAlertDestinationsSlackWebhooksRequired -> SpecWorkerAlertDestinationsSlackWebhooks
specWorkerAlertDestinationsSlackWebhooksArgs required = SpecWorkerAlertDestinationsSlackWebhooks (inputObject
  [ Tuple "channel" (inputJson required.channel)
  , Tuple "url" (inputJson required.url)
  ])

specWorkerAlertDestinationsSlackWebhooksJson :: SpecWorkerAlertDestinationsSlackWebhooks -> Json
specWorkerAlertDestinationsSlackWebhooksJson (SpecWorkerAlertDestinationsSlackWebhooks values) = inputObjectJson values

newtype SpecWorkerAutoscaling = SpecWorkerAutoscaling InputObject

type SpecWorkerAutoscalingRequired =
  { maxInstanceCount :: Input Number
  , metrics :: Array SpecWorkerAutoscalingMetrics
  , minInstanceCount :: Input Number
  }

specWorkerAutoscalingArgs :: SpecWorkerAutoscalingRequired -> SpecWorkerAutoscaling
specWorkerAutoscalingArgs required = SpecWorkerAutoscaling (inputObject
  [ Tuple "max_instance_count" (inputJson required.maxInstanceCount)
  , Tuple "metrics" (arrayExprJson (map specWorkerAutoscalingMetricsJson required.metrics))
  , Tuple "min_instance_count" (inputJson required.minInstanceCount)
  ])

specWorkerAutoscalingJson :: SpecWorkerAutoscaling -> Json
specWorkerAutoscalingJson (SpecWorkerAutoscaling values) = inputObjectJson values

newtype SpecWorkerAutoscalingMetrics = SpecWorkerAutoscalingMetrics InputObject

type SpecWorkerAutoscalingMetricsRequired =
  {
  }

specWorkerAutoscalingMetricsArgs :: SpecWorkerAutoscalingMetricsRequired -> SpecWorkerAutoscalingMetrics
specWorkerAutoscalingMetricsArgs _ = SpecWorkerAutoscalingMetrics (inputObject
  [
  ])

specWorkerAutoscalingMetricsCpu :: Array SpecWorkerAutoscalingMetricsCpu -> SpecWorkerAutoscalingMetrics -> SpecWorkerAutoscalingMetrics
specWorkerAutoscalingMetricsCpu value (SpecWorkerAutoscalingMetrics values) = SpecWorkerAutoscalingMetrics (insertInputField "cpu" (arrayExprJson (map specWorkerAutoscalingMetricsCpuJson value)) values)

specWorkerAutoscalingMetricsJson :: SpecWorkerAutoscalingMetrics -> Json
specWorkerAutoscalingMetricsJson (SpecWorkerAutoscalingMetrics values) = inputObjectJson values

newtype SpecWorkerAutoscalingMetricsCpu = SpecWorkerAutoscalingMetricsCpu InputObject

type SpecWorkerAutoscalingMetricsCpuRequired =
  { percent :: Input Number
  }

specWorkerAutoscalingMetricsCpuArgs :: SpecWorkerAutoscalingMetricsCpuRequired -> SpecWorkerAutoscalingMetricsCpu
specWorkerAutoscalingMetricsCpuArgs required = SpecWorkerAutoscalingMetricsCpu (inputObject
  [ Tuple "percent" (inputJson required.percent)
  ])

specWorkerAutoscalingMetricsCpuJson :: SpecWorkerAutoscalingMetricsCpu -> Json
specWorkerAutoscalingMetricsCpuJson (SpecWorkerAutoscalingMetricsCpu values) = inputObjectJson values

newtype SpecWorkerBitbucket = SpecWorkerBitbucket InputObject

type SpecWorkerBitbucketRequired =
  {
  }

specWorkerBitbucketArgs :: SpecWorkerBitbucketRequired -> SpecWorkerBitbucket
specWorkerBitbucketArgs _ = SpecWorkerBitbucket (inputObject
  [
  ])

specWorkerBitbucketBranch :: Input String -> SpecWorkerBitbucket -> SpecWorkerBitbucket
specWorkerBitbucketBranch value (SpecWorkerBitbucket values) = SpecWorkerBitbucket (insertInputField "branch" (inputJson value) values)

specWorkerBitbucketDeployOnPush :: Input Boolean -> SpecWorkerBitbucket -> SpecWorkerBitbucket
specWorkerBitbucketDeployOnPush value (SpecWorkerBitbucket values) = SpecWorkerBitbucket (insertInputField "deploy_on_push" (inputJson value) values)

specWorkerBitbucketRepo :: Input String -> SpecWorkerBitbucket -> SpecWorkerBitbucket
specWorkerBitbucketRepo value (SpecWorkerBitbucket values) = SpecWorkerBitbucket (insertInputField "repo" (inputJson value) values)

specWorkerBitbucketJson :: SpecWorkerBitbucket -> Json
specWorkerBitbucketJson (SpecWorkerBitbucket values) = inputObjectJson values

newtype SpecWorkerEnv = SpecWorkerEnv InputObject

type SpecWorkerEnvRequired =
  {
  }

specWorkerEnvArgs :: SpecWorkerEnvRequired -> SpecWorkerEnv
specWorkerEnvArgs _ = SpecWorkerEnv (inputObject
  [
  ])

specWorkerEnvKey :: Input String -> SpecWorkerEnv -> SpecWorkerEnv
specWorkerEnvKey value (SpecWorkerEnv values) = SpecWorkerEnv (insertInputField "key" (inputJson value) values)

specWorkerEnvScope :: Input String -> SpecWorkerEnv -> SpecWorkerEnv
specWorkerEnvScope value (SpecWorkerEnv values) = SpecWorkerEnv (insertInputField "scope" (inputJson value) values)

specWorkerEnvType :: Input String -> SpecWorkerEnv -> SpecWorkerEnv
specWorkerEnvType value (SpecWorkerEnv values) = SpecWorkerEnv (insertInputField "type" (inputJson value) values)

specWorkerEnvValue :: Input String -> SpecWorkerEnv -> SpecWorkerEnv
specWorkerEnvValue value (SpecWorkerEnv values) = SpecWorkerEnv (insertInputField "value" (inputJson value) values)

specWorkerEnvJson :: SpecWorkerEnv -> Json
specWorkerEnvJson (SpecWorkerEnv values) = inputObjectJson values

newtype SpecWorkerGit = SpecWorkerGit InputObject

type SpecWorkerGitRequired =
  {
  }

specWorkerGitArgs :: SpecWorkerGitRequired -> SpecWorkerGit
specWorkerGitArgs _ = SpecWorkerGit (inputObject
  [
  ])

specWorkerGitBranch :: Input String -> SpecWorkerGit -> SpecWorkerGit
specWorkerGitBranch value (SpecWorkerGit values) = SpecWorkerGit (insertInputField "branch" (inputJson value) values)

specWorkerGitRepoCloneUrl :: Input String -> SpecWorkerGit -> SpecWorkerGit
specWorkerGitRepoCloneUrl value (SpecWorkerGit values) = SpecWorkerGit (insertInputField "repo_clone_url" (inputJson value) values)

specWorkerGitJson :: SpecWorkerGit -> Json
specWorkerGitJson (SpecWorkerGit values) = inputObjectJson values

newtype SpecWorkerGithub = SpecWorkerGithub InputObject

type SpecWorkerGithubRequired =
  {
  }

specWorkerGithubArgs :: SpecWorkerGithubRequired -> SpecWorkerGithub
specWorkerGithubArgs _ = SpecWorkerGithub (inputObject
  [
  ])

specWorkerGithubBranch :: Input String -> SpecWorkerGithub -> SpecWorkerGithub
specWorkerGithubBranch value (SpecWorkerGithub values) = SpecWorkerGithub (insertInputField "branch" (inputJson value) values)

specWorkerGithubDeployOnPush :: Input Boolean -> SpecWorkerGithub -> SpecWorkerGithub
specWorkerGithubDeployOnPush value (SpecWorkerGithub values) = SpecWorkerGithub (insertInputField "deploy_on_push" (inputJson value) values)

specWorkerGithubRepo :: Input String -> SpecWorkerGithub -> SpecWorkerGithub
specWorkerGithubRepo value (SpecWorkerGithub values) = SpecWorkerGithub (insertInputField "repo" (inputJson value) values)

specWorkerGithubJson :: SpecWorkerGithub -> Json
specWorkerGithubJson (SpecWorkerGithub values) = inputObjectJson values

newtype SpecWorkerGitlab = SpecWorkerGitlab InputObject

type SpecWorkerGitlabRequired =
  {
  }

specWorkerGitlabArgs :: SpecWorkerGitlabRequired -> SpecWorkerGitlab
specWorkerGitlabArgs _ = SpecWorkerGitlab (inputObject
  [
  ])

specWorkerGitlabBranch :: Input String -> SpecWorkerGitlab -> SpecWorkerGitlab
specWorkerGitlabBranch value (SpecWorkerGitlab values) = SpecWorkerGitlab (insertInputField "branch" (inputJson value) values)

specWorkerGitlabDeployOnPush :: Input Boolean -> SpecWorkerGitlab -> SpecWorkerGitlab
specWorkerGitlabDeployOnPush value (SpecWorkerGitlab values) = SpecWorkerGitlab (insertInputField "deploy_on_push" (inputJson value) values)

specWorkerGitlabRepo :: Input String -> SpecWorkerGitlab -> SpecWorkerGitlab
specWorkerGitlabRepo value (SpecWorkerGitlab values) = SpecWorkerGitlab (insertInputField "repo" (inputJson value) values)

specWorkerGitlabJson :: SpecWorkerGitlab -> Json
specWorkerGitlabJson (SpecWorkerGitlab values) = inputObjectJson values

newtype SpecWorkerImage = SpecWorkerImage InputObject

type SpecWorkerImageRequired =
  { registryType :: Input String
  , repository :: Input String
  }

specWorkerImageArgs :: SpecWorkerImageRequired -> SpecWorkerImage
specWorkerImageArgs required = SpecWorkerImage (inputObject
  [ Tuple "registry_type" (inputJson required.registryType)
  , Tuple "repository" (inputJson required.repository)
  ])

specWorkerImageDeployOnPush :: Array SpecWorkerImageDeployOnPush -> SpecWorkerImage -> SpecWorkerImage
specWorkerImageDeployOnPush value (SpecWorkerImage values) = SpecWorkerImage (insertInputField "deploy_on_push" (arrayExprJson (map specWorkerImageDeployOnPushJson value)) values)

specWorkerImageDigest :: Input String -> SpecWorkerImage -> SpecWorkerImage
specWorkerImageDigest value (SpecWorkerImage values) = SpecWorkerImage (insertInputField "digest" (inputJson value) values)

specWorkerImageRegistry :: Input String -> SpecWorkerImage -> SpecWorkerImage
specWorkerImageRegistry value (SpecWorkerImage values) = SpecWorkerImage (insertInputField "registry" (inputJson value) values)

specWorkerImageRegistryCredentials :: Input String -> SpecWorkerImage -> SpecWorkerImage
specWorkerImageRegistryCredentials value (SpecWorkerImage values) = SpecWorkerImage (insertInputField "registry_credentials" (inputJson value) values)

specWorkerImageTag :: Input String -> SpecWorkerImage -> SpecWorkerImage
specWorkerImageTag value (SpecWorkerImage values) = SpecWorkerImage (insertInputField "tag" (inputJson value) values)

specWorkerImageJson :: SpecWorkerImage -> Json
specWorkerImageJson (SpecWorkerImage values) = inputObjectJson values

newtype SpecWorkerImageDeployOnPush = SpecWorkerImageDeployOnPush InputObject

type SpecWorkerImageDeployOnPushRequired =
  {
  }

specWorkerImageDeployOnPushArgs :: SpecWorkerImageDeployOnPushRequired -> SpecWorkerImageDeployOnPush
specWorkerImageDeployOnPushArgs _ = SpecWorkerImageDeployOnPush (inputObject
  [
  ])

specWorkerImageDeployOnPushEnabled :: Input Boolean -> SpecWorkerImageDeployOnPush -> SpecWorkerImageDeployOnPush
specWorkerImageDeployOnPushEnabled value (SpecWorkerImageDeployOnPush values) = SpecWorkerImageDeployOnPush (insertInputField "enabled" (inputJson value) values)

specWorkerImageDeployOnPushJson :: SpecWorkerImageDeployOnPush -> Json
specWorkerImageDeployOnPushJson (SpecWorkerImageDeployOnPush values) = inputObjectJson values

newtype SpecWorkerLivenessHealthCheck = SpecWorkerLivenessHealthCheck InputObject

type SpecWorkerLivenessHealthCheckRequired =
  {
  }

specWorkerLivenessHealthCheckArgs :: SpecWorkerLivenessHealthCheckRequired -> SpecWorkerLivenessHealthCheck
specWorkerLivenessHealthCheckArgs _ = SpecWorkerLivenessHealthCheck (inputObject
  [
  ])

specWorkerLivenessHealthCheckFailureThreshold :: Input Number -> SpecWorkerLivenessHealthCheck -> SpecWorkerLivenessHealthCheck
specWorkerLivenessHealthCheckFailureThreshold value (SpecWorkerLivenessHealthCheck values) = SpecWorkerLivenessHealthCheck (insertInputField "failure_threshold" (inputJson value) values)

specWorkerLivenessHealthCheckHttpPath :: Input String -> SpecWorkerLivenessHealthCheck -> SpecWorkerLivenessHealthCheck
specWorkerLivenessHealthCheckHttpPath value (SpecWorkerLivenessHealthCheck values) = SpecWorkerLivenessHealthCheck (insertInputField "http_path" (inputJson value) values)

specWorkerLivenessHealthCheckInitialDelaySeconds :: Input Number -> SpecWorkerLivenessHealthCheck -> SpecWorkerLivenessHealthCheck
specWorkerLivenessHealthCheckInitialDelaySeconds value (SpecWorkerLivenessHealthCheck values) = SpecWorkerLivenessHealthCheck (insertInputField "initial_delay_seconds" (inputJson value) values)

specWorkerLivenessHealthCheckPeriodSeconds :: Input Number -> SpecWorkerLivenessHealthCheck -> SpecWorkerLivenessHealthCheck
specWorkerLivenessHealthCheckPeriodSeconds value (SpecWorkerLivenessHealthCheck values) = SpecWorkerLivenessHealthCheck (insertInputField "period_seconds" (inputJson value) values)

specWorkerLivenessHealthCheckPort :: Input Number -> SpecWorkerLivenessHealthCheck -> SpecWorkerLivenessHealthCheck
specWorkerLivenessHealthCheckPort value (SpecWorkerLivenessHealthCheck values) = SpecWorkerLivenessHealthCheck (insertInputField "port" (inputJson value) values)

specWorkerLivenessHealthCheckSuccessThreshold :: Input Number -> SpecWorkerLivenessHealthCheck -> SpecWorkerLivenessHealthCheck
specWorkerLivenessHealthCheckSuccessThreshold value (SpecWorkerLivenessHealthCheck values) = SpecWorkerLivenessHealthCheck (insertInputField "success_threshold" (inputJson value) values)

specWorkerLivenessHealthCheckTimeoutSeconds :: Input Number -> SpecWorkerLivenessHealthCheck -> SpecWorkerLivenessHealthCheck
specWorkerLivenessHealthCheckTimeoutSeconds value (SpecWorkerLivenessHealthCheck values) = SpecWorkerLivenessHealthCheck (insertInputField "timeout_seconds" (inputJson value) values)

specWorkerLivenessHealthCheckJson :: SpecWorkerLivenessHealthCheck -> Json
specWorkerLivenessHealthCheckJson (SpecWorkerLivenessHealthCheck values) = inputObjectJson values

newtype SpecWorkerLogDestination = SpecWorkerLogDestination InputObject

type SpecWorkerLogDestinationRequired =
  { name :: Input String
  }

specWorkerLogDestinationArgs :: SpecWorkerLogDestinationRequired -> SpecWorkerLogDestination
specWorkerLogDestinationArgs required = SpecWorkerLogDestination (inputObject
  [ Tuple "name" (inputJson required.name)
  ])

specWorkerLogDestinationDatadog :: Array SpecWorkerLogDestinationDatadog -> SpecWorkerLogDestination -> SpecWorkerLogDestination
specWorkerLogDestinationDatadog value (SpecWorkerLogDestination values) = SpecWorkerLogDestination (insertInputField "datadog" (arrayExprJson (map specWorkerLogDestinationDatadogJson value)) values)

specWorkerLogDestinationLogtail :: Array SpecWorkerLogDestinationLogtail -> SpecWorkerLogDestination -> SpecWorkerLogDestination
specWorkerLogDestinationLogtail value (SpecWorkerLogDestination values) = SpecWorkerLogDestination (insertInputField "logtail" (arrayExprJson (map specWorkerLogDestinationLogtailJson value)) values)

specWorkerLogDestinationOpenSearch :: Array SpecWorkerLogDestinationOpenSearch -> SpecWorkerLogDestination -> SpecWorkerLogDestination
specWorkerLogDestinationOpenSearch value (SpecWorkerLogDestination values) = SpecWorkerLogDestination (insertInputField "open_search" (arrayExprJson (map specWorkerLogDestinationOpenSearchJson value)) values)

specWorkerLogDestinationPapertrail :: Array SpecWorkerLogDestinationPapertrail -> SpecWorkerLogDestination -> SpecWorkerLogDestination
specWorkerLogDestinationPapertrail value (SpecWorkerLogDestination values) = SpecWorkerLogDestination (insertInputField "papertrail" (arrayExprJson (map specWorkerLogDestinationPapertrailJson value)) values)

specWorkerLogDestinationJson :: SpecWorkerLogDestination -> Json
specWorkerLogDestinationJson (SpecWorkerLogDestination values) = inputObjectJson values

newtype SpecWorkerLogDestinationDatadog = SpecWorkerLogDestinationDatadog InputObject

type SpecWorkerLogDestinationDatadogRequired =
  { apiKey :: Input String
  }

specWorkerLogDestinationDatadogArgs :: SpecWorkerLogDestinationDatadogRequired -> SpecWorkerLogDestinationDatadog
specWorkerLogDestinationDatadogArgs required = SpecWorkerLogDestinationDatadog (inputObject
  [ Tuple "api_key" (inputJson required.apiKey)
  ])

specWorkerLogDestinationDatadogEndpoint :: Input String -> SpecWorkerLogDestinationDatadog -> SpecWorkerLogDestinationDatadog
specWorkerLogDestinationDatadogEndpoint value (SpecWorkerLogDestinationDatadog values) = SpecWorkerLogDestinationDatadog (insertInputField "endpoint" (inputJson value) values)

specWorkerLogDestinationDatadogJson :: SpecWorkerLogDestinationDatadog -> Json
specWorkerLogDestinationDatadogJson (SpecWorkerLogDestinationDatadog values) = inputObjectJson values

newtype SpecWorkerLogDestinationLogtail = SpecWorkerLogDestinationLogtail InputObject

type SpecWorkerLogDestinationLogtailRequired =
  { token :: Input String
  }

specWorkerLogDestinationLogtailArgs :: SpecWorkerLogDestinationLogtailRequired -> SpecWorkerLogDestinationLogtail
specWorkerLogDestinationLogtailArgs required = SpecWorkerLogDestinationLogtail (inputObject
  [ Tuple "token" (inputJson required.token)
  ])

specWorkerLogDestinationLogtailJson :: SpecWorkerLogDestinationLogtail -> Json
specWorkerLogDestinationLogtailJson (SpecWorkerLogDestinationLogtail values) = inputObjectJson values

newtype SpecWorkerLogDestinationOpenSearch = SpecWorkerLogDestinationOpenSearch InputObject

type SpecWorkerLogDestinationOpenSearchRequired =
  { basicAuth :: Array SpecWorkerLogDestinationOpenSearchBasicAuth
  }

specWorkerLogDestinationOpenSearchArgs :: SpecWorkerLogDestinationOpenSearchRequired -> SpecWorkerLogDestinationOpenSearch
specWorkerLogDestinationOpenSearchArgs required = SpecWorkerLogDestinationOpenSearch (inputObject
  [ Tuple "basic_auth" (arrayExprJson (map specWorkerLogDestinationOpenSearchBasicAuthJson required.basicAuth))
  ])

specWorkerLogDestinationOpenSearchClusterName :: Input String -> SpecWorkerLogDestinationOpenSearch -> SpecWorkerLogDestinationOpenSearch
specWorkerLogDestinationOpenSearchClusterName value (SpecWorkerLogDestinationOpenSearch values) = SpecWorkerLogDestinationOpenSearch (insertInputField "cluster_name" (inputJson value) values)

specWorkerLogDestinationOpenSearchEndpoint :: Input String -> SpecWorkerLogDestinationOpenSearch -> SpecWorkerLogDestinationOpenSearch
specWorkerLogDestinationOpenSearchEndpoint value (SpecWorkerLogDestinationOpenSearch values) = SpecWorkerLogDestinationOpenSearch (insertInputField "endpoint" (inputJson value) values)

specWorkerLogDestinationOpenSearchIndexName :: Input String -> SpecWorkerLogDestinationOpenSearch -> SpecWorkerLogDestinationOpenSearch
specWorkerLogDestinationOpenSearchIndexName value (SpecWorkerLogDestinationOpenSearch values) = SpecWorkerLogDestinationOpenSearch (insertInputField "index_name" (inputJson value) values)

specWorkerLogDestinationOpenSearchJson :: SpecWorkerLogDestinationOpenSearch -> Json
specWorkerLogDestinationOpenSearchJson (SpecWorkerLogDestinationOpenSearch values) = inputObjectJson values

newtype SpecWorkerLogDestinationOpenSearchBasicAuth = SpecWorkerLogDestinationOpenSearchBasicAuth InputObject

type SpecWorkerLogDestinationOpenSearchBasicAuthRequired =
  {
  }

specWorkerLogDestinationOpenSearchBasicAuthArgs :: SpecWorkerLogDestinationOpenSearchBasicAuthRequired -> SpecWorkerLogDestinationOpenSearchBasicAuth
specWorkerLogDestinationOpenSearchBasicAuthArgs _ = SpecWorkerLogDestinationOpenSearchBasicAuth (inputObject
  [
  ])

specWorkerLogDestinationOpenSearchBasicAuthPassword :: Input String -> SpecWorkerLogDestinationOpenSearchBasicAuth -> SpecWorkerLogDestinationOpenSearchBasicAuth
specWorkerLogDestinationOpenSearchBasicAuthPassword value (SpecWorkerLogDestinationOpenSearchBasicAuth values) = SpecWorkerLogDestinationOpenSearchBasicAuth (insertInputField "password" (inputJson value) values)

specWorkerLogDestinationOpenSearchBasicAuthUser :: Input String -> SpecWorkerLogDestinationOpenSearchBasicAuth -> SpecWorkerLogDestinationOpenSearchBasicAuth
specWorkerLogDestinationOpenSearchBasicAuthUser value (SpecWorkerLogDestinationOpenSearchBasicAuth values) = SpecWorkerLogDestinationOpenSearchBasicAuth (insertInputField "user" (inputJson value) values)

specWorkerLogDestinationOpenSearchBasicAuthJson :: SpecWorkerLogDestinationOpenSearchBasicAuth -> Json
specWorkerLogDestinationOpenSearchBasicAuthJson (SpecWorkerLogDestinationOpenSearchBasicAuth values) = inputObjectJson values

newtype SpecWorkerLogDestinationPapertrail = SpecWorkerLogDestinationPapertrail InputObject

type SpecWorkerLogDestinationPapertrailRequired =
  { endpoint :: Input String
  }

specWorkerLogDestinationPapertrailArgs :: SpecWorkerLogDestinationPapertrailRequired -> SpecWorkerLogDestinationPapertrail
specWorkerLogDestinationPapertrailArgs required = SpecWorkerLogDestinationPapertrail (inputObject
  [ Tuple "endpoint" (inputJson required.endpoint)
  ])

specWorkerLogDestinationPapertrailJson :: SpecWorkerLogDestinationPapertrail -> Json
specWorkerLogDestinationPapertrailJson (SpecWorkerLogDestinationPapertrail values) = inputObjectJson values

newtype SpecWorkerTermination = SpecWorkerTermination InputObject

type SpecWorkerTerminationRequired =
  {
  }

specWorkerTerminationArgs :: SpecWorkerTerminationRequired -> SpecWorkerTermination
specWorkerTerminationArgs _ = SpecWorkerTermination (inputObject
  [
  ])

specWorkerTerminationGracePeriodSeconds :: Input Number -> SpecWorkerTermination -> SpecWorkerTermination
specWorkerTerminationGracePeriodSeconds value (SpecWorkerTermination values) = SpecWorkerTermination (insertInputField "grace_period_seconds" (inputJson value) values)

specWorkerTerminationJson :: SpecWorkerTermination -> Json
specWorkerTerminationJson (SpecWorkerTermination values) = inputObjectJson values

newtype Timeouts = Timeouts InputObject

type TimeoutsRequired =
  {
  }

timeoutsArgs :: TimeoutsRequired -> Timeouts
timeoutsArgs _ = Timeouts (inputObject
  [
  ])

timeoutsCreate :: Input String -> Timeouts -> Timeouts
timeoutsCreate value (Timeouts values) = Timeouts (insertInputField "create" (inputJson value) values)

timeoutsJson :: Timeouts -> Json
timeoutsJson (Timeouts values) = inputObjectJson values

type Required =
  {
  }

newtype Args = Args InputObject

args :: Required -> Args
args _ = Args (inputObject
  [
  ])

dedicatedIps :: Array DedicatedIps -> Args -> Args
dedicatedIps value (Args values) = Args (insertInputField "dedicated_ips" (arrayExprJson (map dedicatedIpsJson value)) values)

deploymentPerPage :: Input Number -> Args -> Args
deploymentPerPage value (Args values) = Args (insertInputField "deployment_per_page" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

projectId :: Input String -> Args -> Args
projectId value (Args values) = Args (insertInputField "project_id" (inputJson value) values)

spec :: Array Spec -> Args -> Args
spec value (Args values) = Args (insertInputField "spec" (arrayExprJson (map specJson value)) values)

timeouts :: Timeouts -> Args -> Args
timeouts value (Args values) = Args (insertInputField "timeouts" (timeoutsJson value) values)

type App =
  { resource :: Resource AppResource
  , activeDeploymentId :: Expr String
  , createdAt :: Expr String
  , defaultIngress :: Expr String
  , deploymentPerPage :: Expr Number
  , id :: Expr String
  , liveDomain :: Expr String
  , liveUrl :: Expr String
  , projectId :: Expr String
  , updatedAt :: Expr String
  , urn :: Expr String
  }

create :: String -> Args -> Infra App
create logicalName (Args values) = do
  handle <- addResource "digitalocean_app" logicalName values
  pure
    { resource: handle
    , activeDeploymentId: resourceAttr handle [ "active_deployment_id" ]
    , createdAt: resourceAttr handle [ "created_at" ]
    , defaultIngress: resourceAttr handle [ "default_ingress" ]
    , deploymentPerPage: resourceAttr handle [ "deployment_per_page" ]
    , id: resourceAttr handle [ "id" ]
    , liveDomain: resourceAttr handle [ "live_domain" ]
    , liveUrl: resourceAttr handle [ "live_url" ]
    , projectId: resourceAttr handle [ "project_id" ]
    , updatedAt: resourceAttr handle [ "updated_at" ]
    , urn: resourceAttr handle [ "urn" ]
    }
