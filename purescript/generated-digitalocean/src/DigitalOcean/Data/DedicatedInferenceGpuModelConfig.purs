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

import Data.Argonaut.Core (Json)
import Foreign.Object as Object
import TofuDag.Builder (Infra, addDataSource)
import TofuDag.Core (Expr, Input, DataSource, inputJson, dataSourceAttr)

data DedicatedInferenceGpuModelConfigDataSource

type Required =
  {
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args _ = Args (Object.fromFoldable
  [
  ])

id :: Input String -> Args -> Args
id value (Args values) = Args (Object.insert "id" (inputJson value) values)

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
