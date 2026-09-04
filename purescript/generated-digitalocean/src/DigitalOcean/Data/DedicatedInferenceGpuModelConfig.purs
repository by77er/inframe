module DigitalOcean.Data.DedicatedInferenceGpuModelConfig
  ( Args
  , Required
  , DedicatedInferenceGpuModelConfig
  , DedicatedInferenceGpuModelConfigDataSource
  , args
  , read
  , id
  ) where

import Prelude (bind, pure)

import TofuDag.Builder (Infra, addDataSource, InputObject, inputObject, insertInputField)
import TofuDag.Core (Expr, Input, inputJson, DataSource, dataSourceAttr)

data DedicatedInferenceGpuModelConfigDataSource

type Required =
  {
  }

newtype Args = Args InputObject

args :: Required -> Args
args _ = Args (inputObject
  [
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (insertInputField "id" (inputJson value) values)

type DedicatedInferenceGpuModelConfig =
  { dataSource :: DataSource DedicatedInferenceGpuModelConfigDataSource
  , gpuModelConfigs :: Expr (Array ({ gpuSlugs :: Array String, isModelGated :: Boolean, modelName :: String, modelSlug :: String }))
  , id :: Expr String
  }

read :: String -> Args -> Infra DedicatedInferenceGpuModelConfig
read logicalName (Args values) = do
  handle <- addDataSource "digitalocean_dedicated_inference_gpu_model_config" logicalName values
  pure
    { dataSource: handle
    , gpuModelConfigs: dataSourceAttr handle [ "gpu_model_configs" ]
    , id: dataSourceAttr handle [ "id" ]
    }
