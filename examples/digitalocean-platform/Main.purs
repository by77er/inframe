module Example.DigitalOceanPlatform where

import Prelude

import DigitalOcean.Data.KubernetesVersions as KubernetesVersions
import DigitalOcean.Provider as DigitalOcean
import DigitalOcean.Resource.DatabaseCluster as Database
import DigitalOcean.Resource.KubernetesCluster as Kubernetes
import DigitalOcean.Resource.SpacesBucket as Spaces
import DigitalOcean.Resource.Vpc as Vpc
import Effect (Effect)
import Effect.Console (log)
import Inframe.Builder (Infra, createBeforeDestroy, dataSourceOptions, output, resourceOptions, withProvider)
import Inframe.Core (computed, lit, secretEnv)
import Inframe.Json (renderGraph)

infrastructure :: Infra Unit
infrastructure = do
  provider <- DigitalOcean.configure $
    DigitalOcean.args {}
      # DigitalOcean.token (secretEnv "DIGITALOCEAN_TOKEN")

  versions <- KubernetesVersions.readWith "available" (KubernetesVersions.args {})
    (dataSourceOptions # withProvider provider)
  network <- Vpc.create "platform" $ Vpc.args
    { name: lit "platform"
    , region: lit "nyc3"
    }

  -- Only provider-required node-pool fields belong in the constructor.
  -- Autoscaling is added through composable, type-checked setters.
  let
    workerPool =
      Kubernetes.nodePoolArgs
        { name: lit "workers"
        , size: lit "s-2vcpu-4gb"
        }
        # Kubernetes.nodePoolNodeCount (lit 2.0)
        # Kubernetes.nodePoolAutoScale (lit true)
        # Kubernetes.nodePoolMinNodes (lit 2.0)
        # Kubernetes.nodePoolMaxNodes (lit 6.0)
        # Kubernetes.nodePoolTags (lit [ "platform", "workers" ])

  cluster <- Kubernetes.createWith "platform"
    (Kubernetes.args
      { name: lit "platform"
      , nodePool: [ workerPool ]
      , region: lit "nyc3"
      , version: computed versions.latestVersion
      }
      # Kubernetes.autoUpgrade (lit true)
      # Kubernetes.ha (lit true)
      # Kubernetes.surgeUpgrade (lit true)
      # Kubernetes.vpcUuid (computed network.id))
    ( resourceOptions
        # withProvider provider
        # createBeforeDestroy true
    )

  let
    versioning =
      Spaces.versioningArgs {}
        # Spaces.versioningEnabled (lit true)

  bucket <- Spaces.create "assets" $
    Spaces.args { name: lit "replace-with-a-globally-unique-space-name" }
      # Spaces.region (lit "nyc3")
      # Spaces.versioning [ versioning ]

  let
    storageAutoscale =
      Database.storageAutoscaleArgs { enabled: lit true }
        # Database.storageAutoscaleThresholdPercent (lit 80.0)
        # Database.storageAutoscaleIncrementGib (lit 10.0)

  database <- Database.create "postgres" $
    Database.args
      { engine: lit "pg"
      , name: lit "platform-postgres"
      , nodeCount: lit 1.0
      , region: lit "nyc3"
      , size: lit "db-s-1vcpu-1gb"
      }
      # Database.privateNetworkUuid (computed network.id)
      # Database.storageAutoscale [ storageAutoscale ]
      # Database.version (lit "15")

  output "cluster_endpoint" cluster.endpoint
  output "bucket_endpoint" bucket.endpoint
  output "database_host" database.host

main :: Effect Unit
main = log (renderGraph infrastructure)
