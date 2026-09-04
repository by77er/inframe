module DigitalOcean.Data.App
  ( Args
  , Required
  , App
  , AppDataSource
  , args
  , read
  , dedicatedIps
  , id
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Data.Tuple (Tuple(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data AppDataSource

type Required =
  { appId :: Input String
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args required = Args (Object.fromFoldable
  [ Tuple "app_id" (inputJson required.appId)
  ])

dedicatedIps :: Input (Array ({ id :: String, ip :: String, status :: String })) -> Args -> Args
dedicatedIps value (Args values) = Args (Object.insert "dedicated_ips" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

type App =
  { dataSource :: DataSource AppDataSource
  , activeDeploymentId :: Expr String
  , appId :: Expr String
  , createdAt :: Expr String
  , defaultIngress :: Expr String
  , id :: Expr String
  , liveDomain :: Expr String
  , liveUrl :: Expr String
  , projectId :: Expr String
  , spec :: Expr (Array ({ alert :: Array ({ destinations :: Array ({ emails :: Array String, slackWebhooks :: Array ({ channel :: String, url :: String }) }), disabled :: Boolean, rule :: String }), database :: Array ({ clusterName :: String, dbName :: String, dbUser :: String, engine :: String, name :: String, production :: Boolean, version :: String }), disableEdgeCache :: Boolean, disableEmailObfuscation :: Boolean, domain :: Array ({ name :: String, type_ :: String, wildcard :: Boolean, zone :: String }), domains :: Array String, egress :: Array ({ type_ :: String }), enhancedThreatControlEnabled :: Boolean, env :: Array ({ key :: String, scope :: String, type_ :: String, value :: String }), features :: Array String, function :: Array ({ alert :: Array ({ destinations :: Array ({ emails :: Array String, slackWebhooks :: Array ({ channel :: String, url :: String }) }), disabled :: Boolean, operator :: String, rule :: String, value :: Number, window :: String }), bitbucket :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), cors :: Array ({ allowCredentials :: Boolean, allowHeaders :: Array String, allowMethods :: Array String, allowOrigins :: Array ({ exact :: String, prefix :: String, regex :: String }), exposeHeaders :: Array String, maxAge :: String }), env :: Array ({ key :: String, scope :: String, type_ :: String, value :: String }), git :: Array ({ branch :: String, repoCloneUrl :: String }), github :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), gitlab :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), logDestination :: Array ({ datadog :: Array ({ apiKey :: String, endpoint :: String }), logtail :: Array ({ token :: String }), name :: String, openSearch :: Array ({ basicAuth :: Array ({ password :: String, user :: String }), clusterName :: String, endpoint :: String, indexName :: String }), papertrail :: Array ({ endpoint :: String }) }), name :: String, routes :: Array ({ path :: String, preservePathPrefix :: Boolean }), sourceDir :: String }), ingress :: Array ({ rule :: Array ({ component :: Array ({ name :: String, preservePathPrefix :: Boolean, rewrite :: String }), cors :: Array ({ allowCredentials :: Boolean, allowHeaders :: Array String, allowMethods :: Array String, allowOrigins :: Array ({ exact :: String, prefix :: String, regex :: String }), exposeHeaders :: Array String, maxAge :: String }), match :: Array ({ authority :: Array ({ exact :: String }), path :: Array ({ prefix :: String }) }), redirect :: Array ({ authority :: String, port :: Number, redirectCode :: Number, scheme :: String, uri :: String }) }), secureHeader :: Array ({ key :: String, value :: String }) }), job :: Array ({ alert :: Array ({ destinations :: Array ({ emails :: Array String, slackWebhooks :: Array ({ channel :: String, url :: String }) }), disabled :: Boolean, operator :: String, rule :: String, value :: Number, window :: String }), bitbucket :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), buildCommand :: String, dockerfilePath :: String, env :: Array ({ key :: String, scope :: String, type_ :: String, value :: String }), environmentSlug :: String, git :: Array ({ branch :: String, repoCloneUrl :: String }), github :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), gitlab :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), image :: Array ({ deployOnPush :: Array ({ enabled :: Boolean }), digest :: String, registry :: String, registryCredentials :: String, registryType :: String, repository :: String, tag :: String }), instanceCount :: Number, instanceSizeSlug :: String, kind_ :: String, logDestination :: Array ({ datadog :: Array ({ apiKey :: String, endpoint :: String }), logtail :: Array ({ token :: String }), name :: String, openSearch :: Array ({ basicAuth :: Array ({ password :: String, user :: String }), clusterName :: String, endpoint :: String, indexName :: String }), papertrail :: Array ({ endpoint :: String }) }), name :: String, runCommand :: String, sourceDir :: String, termination :: Array ({ gracePeriodSeconds :: Number }) }), maintenance :: Array ({ archive :: Boolean, enabled :: Boolean, offlinePageUrl :: String }), name :: String, region :: String, service :: Array ({ alert :: Array ({ destinations :: Array ({ emails :: Array String, slackWebhooks :: Array ({ channel :: String, url :: String }) }), disabled :: Boolean, operator :: String, rule :: String, value :: Number, window :: String }), autoscaling :: Array ({ maxInstanceCount :: Number, metrics :: Array ({ cpu :: Array ({ percent :: Number }) }), minInstanceCount :: Number }), bitbucket :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), buildCommand :: String, cors :: Array ({ allowCredentials :: Boolean, allowHeaders :: Array String, allowMethods :: Array String, allowOrigins :: Array ({ exact :: String, prefix :: String, regex :: String }), exposeHeaders :: Array String, maxAge :: String }), dockerfilePath :: String, env :: Array ({ key :: String, scope :: String, type_ :: String, value :: String }), environmentSlug :: String, git :: Array ({ branch :: String, repoCloneUrl :: String }), github :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), gitlab :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), healthCheck :: Array ({ failureThreshold :: Number, httpPath :: String, initialDelaySeconds :: Number, periodSeconds :: Number, port :: Number, successThreshold :: Number, timeoutSeconds :: Number }), httpPort :: Number, image :: Array ({ deployOnPush :: Array ({ enabled :: Boolean }), digest :: String, registry :: String, registryCredentials :: String, registryType :: String, repository :: String, tag :: String }), instanceCount :: Number, instanceSizeSlug :: String, internalPorts :: Array Number, livenessHealthCheck :: Array ({ failureThreshold :: Number, httpPath :: String, initialDelaySeconds :: Number, periodSeconds :: Number, port :: Number, successThreshold :: Number, timeoutSeconds :: Number }), logDestination :: Array ({ datadog :: Array ({ apiKey :: String, endpoint :: String }), logtail :: Array ({ token :: String }), name :: String, openSearch :: Array ({ basicAuth :: Array ({ password :: String, user :: String }), clusterName :: String, endpoint :: String, indexName :: String }), papertrail :: Array ({ endpoint :: String }) }), name :: String, routes :: Array ({ path :: String, preservePathPrefix :: Boolean }), runCommand :: String, sourceDir :: String, termination :: Array ({ drainSeconds :: Number, gracePeriodSeconds :: Number }) }), staticSite :: Array ({ bitbucket :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), buildCommand :: String, catchallDocument :: String, cors :: Array ({ allowCredentials :: Boolean, allowHeaders :: Array String, allowMethods :: Array String, allowOrigins :: Array ({ exact :: String, prefix :: String, regex :: String }), exposeHeaders :: Array String, maxAge :: String }), dockerfilePath :: String, env :: Array ({ key :: String, scope :: String, type_ :: String, value :: String }), environmentSlug :: String, errorDocument :: String, git :: Array ({ branch :: String, repoCloneUrl :: String }), github :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), gitlab :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), indexDocument :: String, name :: String, outputDir :: String, routes :: Array ({ path :: String, preservePathPrefix :: Boolean }), sourceDir :: String }), vpc :: Array ({ id :: String }), worker :: Array ({ alert :: Array ({ destinations :: Array ({ emails :: Array String, slackWebhooks :: Array ({ channel :: String, url :: String }) }), disabled :: Boolean, operator :: String, rule :: String, value :: Number, window :: String }), autoscaling :: Array ({ maxInstanceCount :: Number, metrics :: Array ({ cpu :: Array ({ percent :: Number }) }), minInstanceCount :: Number }), bitbucket :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), buildCommand :: String, dockerfilePath :: String, env :: Array ({ key :: String, scope :: String, type_ :: String, value :: String }), environmentSlug :: String, git :: Array ({ branch :: String, repoCloneUrl :: String }), github :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), gitlab :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), image :: Array ({ deployOnPush :: Array ({ enabled :: Boolean }), digest :: String, registry :: String, registryCredentials :: String, registryType :: String, repository :: String, tag :: String }), instanceCount :: Number, instanceSizeSlug :: String, livenessHealthCheck :: Array ({ failureThreshold :: Number, httpPath :: String, initialDelaySeconds :: Number, periodSeconds :: Number, port :: Number, successThreshold :: Number, timeoutSeconds :: Number }), logDestination :: Array ({ datadog :: Array ({ apiKey :: String, endpoint :: String }), logtail :: Array ({ token :: String }), name :: String, openSearch :: Array ({ basicAuth :: Array ({ password :: String, user :: String }), clusterName :: String, endpoint :: String, indexName :: String }), papertrail :: Array ({ endpoint :: String }) }), name :: String, runCommand :: String, sourceDir :: String, termination :: Array ({ gracePeriodSeconds :: Number }) }) }))
  , updatedAt :: Expr String
  , urn :: Expr String
  }

read :: String -> Args -> Infra App
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_app" logicalName values
  pure
    { dataSource: handle
    , activeDeploymentId: dataSourceAttr handle [ "active_deployment_id" ]
    , appId: dataSourceAttr handle [ "app_id" ]
    , createdAt: dataSourceAttr handle [ "created_at" ]
    , defaultIngress: dataSourceAttr handle [ "default_ingress" ]
    , id: dataSourceAttr handle [ "id" ]
    , liveDomain: dataSourceAttr handle [ "live_domain" ]
    , liveUrl: dataSourceAttr handle [ "live_url" ]
    , projectId: dataSourceAttr handle [ "project_id" ]
    , spec: dataSourceAttr handle [ "spec" ]
    , updatedAt: dataSourceAttr handle [ "updated_at" ]
    , urn: dataSourceAttr handle [ "urn" ]
    }
