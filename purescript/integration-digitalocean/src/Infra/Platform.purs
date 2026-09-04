module Infra.Platform where

import Prelude

import DigitalOcean.Data.KubernetesVersions as KubernetesVersions
import DigitalOcean.Provider as DigitalOcean
import DigitalOcean.Resource.DatabaseCluster as Database
import DigitalOcean.Resource.KubernetesCluster as Kubernetes
import DigitalOcean.Resource.SpacesBucket as Spaces
import DigitalOcean.Resource.Vpc as Vpc
import Effect (Effect)
import Effect.Console (log)
import TofuDag.Builder (Infra, output, requireProvider)
import TofuDag.Core (computed, lit)
import TofuDag.Json (renderGraph)

infrastructure :: Infra Unit
infrastructure = do
  requireProvider "digitalocean" "digitalocean/digitalocean" "= 2.100.0"
  DigitalOcean.configure (DigitalOcean.args {})

  versions <- KubernetesVersions.read "available" (KubernetesVersions.args {})
  network <- Vpc.create "platform" $ Vpc.args
    { name: lit "platform"
    , region: lit "nyc3"
    }

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

  cluster <- Kubernetes.create "platform" $
    Kubernetes.args
      { name: lit "platform"
      , nodePool: [ workerPool ]
      , region: lit "nyc3"
      , version: computed versions.latestVersion
      }
      # Kubernetes.autoUpgrade (lit true)
      # Kubernetes.ha (lit true)
      # Kubernetes.surgeUpgrade (lit true)
      # Kubernetes.vpcUuid (computed network.id)

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

  output "cluster_endpoint" cluster.endpoint
  output "bucket_endpoint" bucket.endpoint
  output "database_host" database.host

main :: Effect Unit
main = log (renderGraph infrastructure)
