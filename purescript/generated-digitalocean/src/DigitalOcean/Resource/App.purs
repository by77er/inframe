module DigitalOcean.Resource.App
  ( Args
  , Required
  , App
  , AppResource
  , args
  , create
  , dedicatedIps
  , deploymentPerPage
  , id
  , projectId
  , spec
  , timeouts
  ) where

import Prelude (bind, pure)

import Data.Argonaut.Core (Json)
import Foreign.Object as Object
import TofuDag.Builder (Infra, addResource)
import TofuDag.Core (Expr, Input, Resource, inputJson, resourceAttr)

data AppResource

type Required =
  {
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args _ = Args (Object.fromFoldable
  [
  ])

dedicatedIps :: Input (Array ({ id :: String, ip :: String, status :: String })) -> Args -> Args
dedicatedIps value (Args values) = Args (Object.insert "dedicated_ips" (inputJson value) values)

deploymentPerPage :: Input Number -> Args -> Args
deploymentPerPage value (Args values) = Args (Object.insert "deployment_per_page" (inputJson value) values)

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

projectId :: Input String -> Args -> Args
projectId value (Args values) = Args (Object.insert "project_id" (inputJson value) values)

spec :: Input (Array ({ alert :: Array ({ destinations :: Array ({ emails :: Array String, slackWebhooks :: Array ({ channel :: String, url :: String }) }), disabled :: Boolean, rule :: String }), database :: Array ({ clusterName :: String, dbName :: String, dbUser :: String, engine :: String, name :: String, production :: Boolean, version :: String }), disableEdgeCache :: Boolean, disableEmailObfuscation :: Boolean, domain :: Array ({ name :: String, type_ :: String, wildcard :: Boolean, zone :: String }), domains :: Array String, egress :: Array ({ type_ :: String }), enhancedThreatControlEnabled :: Boolean, env :: Array ({ key :: String, scope :: String, type_ :: String, value :: String }), features :: Array String, function :: Array ({ alert :: Array ({ destinations :: Array ({ emails :: Array String, slackWebhooks :: Array ({ channel :: String, url :: String }) }), disabled :: Boolean, operator :: String, rule :: String, value :: Number, window :: String }), bitbucket :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), cors :: Array ({ allowCredentials :: Boolean, allowHeaders :: Array String, allowMethods :: Array String, allowOrigins :: Array ({ exact :: String, prefix :: String, regex :: String }), exposeHeaders :: Array String, maxAge :: String }), env :: Array ({ key :: String, scope :: String, type_ :: String, value :: String }), git :: Array ({ branch :: String, repoCloneUrl :: String }), github :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), gitlab :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), logDestination :: Array ({ datadog :: Array ({ apiKey :: String, endpoint :: String }), logtail :: Array ({ token :: String }), name :: String, openSearch :: Array ({ basicAuth :: Array ({ password :: String, user :: String }), clusterName :: String, endpoint :: String, indexName :: String }), papertrail :: Array ({ endpoint :: String }) }), name :: String, routes :: Array ({ path :: String, preservePathPrefix :: Boolean }), sourceDir :: String }), ingress :: Array ({ rule :: Array ({ component :: Array ({ name :: String, preservePathPrefix :: Boolean, rewrite :: String }), cors :: Array ({ allowCredentials :: Boolean, allowHeaders :: Array String, allowMethods :: Array String, allowOrigins :: Array ({ exact :: String, prefix :: String, regex :: String }), exposeHeaders :: Array String, maxAge :: String }), match :: Array ({ authority :: Array ({ exact :: String }), path :: Array ({ prefix :: String }) }), redirect :: Array ({ authority :: String, port :: Number, redirectCode :: Number, scheme :: String, uri :: String }) }), secureHeader :: Array ({ key :: String, value :: String }) }), job :: Array ({ alert :: Array ({ destinations :: Array ({ emails :: Array String, slackWebhooks :: Array ({ channel :: String, url :: String }) }), disabled :: Boolean, operator :: String, rule :: String, value :: Number, window :: String }), bitbucket :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), buildCommand :: String, dockerfilePath :: String, env :: Array ({ key :: String, scope :: String, type_ :: String, value :: String }), environmentSlug :: String, git :: Array ({ branch :: String, repoCloneUrl :: String }), github :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), gitlab :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), image :: Array ({ deployOnPush :: Array ({ enabled :: Boolean }), digest :: String, registry :: String, registryCredentials :: String, registryType :: String, repository :: String, tag :: String }), instanceCount :: Number, instanceSizeSlug :: String, kind_ :: String, logDestination :: Array ({ datadog :: Array ({ apiKey :: String, endpoint :: String }), logtail :: Array ({ token :: String }), name :: String, openSearch :: Array ({ basicAuth :: Array ({ password :: String, user :: String }), clusterName :: String, endpoint :: String, indexName :: String }), papertrail :: Array ({ endpoint :: String }) }), name :: String, runCommand :: String, sourceDir :: String, termination :: Array ({ gracePeriodSeconds :: Number }) }), maintenance :: Array ({ archive :: Boolean, enabled :: Boolean, offlinePageUrl :: String }), name :: String, region :: String, service :: Array ({ alert :: Array ({ destinations :: Array ({ emails :: Array String, slackWebhooks :: Array ({ channel :: String, url :: String }) }), disabled :: Boolean, operator :: String, rule :: String, value :: Number, window :: String }), autoscaling :: Array ({ maxInstanceCount :: Number, metrics :: Array ({ cpu :: Array ({ percent :: Number }) }), minInstanceCount :: Number }), bitbucket :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), buildCommand :: String, cors :: Array ({ allowCredentials :: Boolean, allowHeaders :: Array String, allowMethods :: Array String, allowOrigins :: Array ({ exact :: String, prefix :: String, regex :: String }), exposeHeaders :: Array String, maxAge :: String }), dockerfilePath :: String, env :: Array ({ key :: String, scope :: String, type_ :: String, value :: String }), environmentSlug :: String, git :: Array ({ branch :: String, repoCloneUrl :: String }), github :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), gitlab :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), healthCheck :: Array ({ failureThreshold :: Number, httpPath :: String, initialDelaySeconds :: Number, periodSeconds :: Number, port :: Number, successThreshold :: Number, timeoutSeconds :: Number }), httpPort :: Number, image :: Array ({ deployOnPush :: Array ({ enabled :: Boolean }), digest :: String, registry :: String, registryCredentials :: String, registryType :: String, repository :: String, tag :: String }), instanceCount :: Number, instanceSizeSlug :: String, internalPorts :: Array Number, livenessHealthCheck :: Array ({ failureThreshold :: Number, httpPath :: String, initialDelaySeconds :: Number, periodSeconds :: Number, port :: Number, successThreshold :: Number, timeoutSeconds :: Number }), logDestination :: Array ({ datadog :: Array ({ apiKey :: String, endpoint :: String }), logtail :: Array ({ token :: String }), name :: String, openSearch :: Array ({ basicAuth :: Array ({ password :: String, user :: String }), clusterName :: String, endpoint :: String, indexName :: String }), papertrail :: Array ({ endpoint :: String }) }), name :: String, routes :: Array ({ path :: String, preservePathPrefix :: Boolean }), runCommand :: String, sourceDir :: String, termination :: Array ({ drainSeconds :: Number, gracePeriodSeconds :: Number }) }), staticSite :: Array ({ bitbucket :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), buildCommand :: String, catchallDocument :: String, cors :: Array ({ allowCredentials :: Boolean, allowHeaders :: Array String, allowMethods :: Array String, allowOrigins :: Array ({ exact :: String, prefix :: String, regex :: String }), exposeHeaders :: Array String, maxAge :: String }), dockerfilePath :: String, env :: Array ({ key :: String, scope :: String, type_ :: String, value :: String }), environmentSlug :: String, errorDocument :: String, git :: Array ({ branch :: String, repoCloneUrl :: String }), github :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), gitlab :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), indexDocument :: String, name :: String, outputDir :: String, routes :: Array ({ path :: String, preservePathPrefix :: Boolean }), sourceDir :: String }), vpc :: Array ({ id :: String }), worker :: Array ({ alert :: Array ({ destinations :: Array ({ emails :: Array String, slackWebhooks :: Array ({ channel :: String, url :: String }) }), disabled :: Boolean, operator :: String, rule :: String, value :: Number, window :: String }), autoscaling :: Array ({ maxInstanceCount :: Number, metrics :: Array ({ cpu :: Array ({ percent :: Number }) }), minInstanceCount :: Number }), bitbucket :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), buildCommand :: String, dockerfilePath :: String, env :: Array ({ key :: String, scope :: String, type_ :: String, value :: String }), environmentSlug :: String, git :: Array ({ branch :: String, repoCloneUrl :: String }), github :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), gitlab :: Array ({ branch :: String, deployOnPush :: Boolean, repo :: String }), image :: Array ({ deployOnPush :: Array ({ enabled :: Boolean }), digest :: String, registry :: String, registryCredentials :: String, registryType :: String, repository :: String, tag :: String }), instanceCount :: Number, instanceSizeSlug :: String, livenessHealthCheck :: Array ({ failureThreshold :: Number, httpPath :: String, initialDelaySeconds :: Number, periodSeconds :: Number, port :: Number, successThreshold :: Number, timeoutSeconds :: Number }), logDestination :: Array ({ datadog :: Array ({ apiKey :: String, endpoint :: String }), logtail :: Array ({ token :: String }), name :: String, openSearch :: Array ({ basicAuth :: Array ({ password :: String, user :: String }), clusterName :: String, endpoint :: String, indexName :: String }), papertrail :: Array ({ endpoint :: String }) }), name :: String, runCommand :: String, sourceDir :: String, termination :: Array ({ gracePeriodSeconds :: Number }) }) })) -> Args -> Args
spec value (Args values) = Args (Object.insert "spec" (inputJson value) values)

timeouts :: Input ({ create :: String }) -> Args -> Args
timeouts value (Args values) = Args (Object.insert "timeouts" (inputJson value) values)

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
