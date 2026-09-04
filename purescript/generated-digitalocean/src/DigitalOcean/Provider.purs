module DigitalOcean.Provider
  ( Args
  , Required
  , args
  , configure
  , configureAs
  , apiEndpoint
  , httpRetryMax
  , httpRetryWaitMax
  , httpRetryWaitMin
  , requestsPerSecond
  , spacesAccessId
  , spacesEndpoint
  , spacesSecretKey
  , token
  ) where

import Prelude (Unit)

import Data.Argonaut.Core (Json)
import Data.Maybe (Maybe(..))
import Foreign.Object as Object
import TofuDag.Builder (Infra, addProvider)
import TofuDag.Core (Input, inputJson)

type Required =
  {
  }

newtype Args = Args (Object.Object Json)

args :: Required -> Args
args _ = Args (Object.fromFoldable
  [
  ])

apiEndpoint :: Input String -> Args -> Args
apiEndpoint value (Args values) = Args (Object.insert "api_endpoint" (inputJson value) values)

httpRetryMax :: Input Number -> Args -> Args
httpRetryMax value (Args values) = Args (Object.insert "http_retry_max" (inputJson value) values)

httpRetryWaitMax :: Input Number -> Args -> Args
httpRetryWaitMax value (Args values) = Args (Object.insert "http_retry_wait_max" (inputJson value) values)

httpRetryWaitMin :: Input Number -> Args -> Args
httpRetryWaitMin value (Args values) = Args (Object.insert "http_retry_wait_min" (inputJson value) values)

requestsPerSecond :: Input Number -> Args -> Args
requestsPerSecond value (Args values) = Args (Object.insert "requests_per_second" (inputJson value) values)

spacesAccessId :: Input String -> Args -> Args
spacesAccessId value (Args values) = Args (Object.insert "spaces_access_id" (inputJson value) values)

spacesEndpoint :: Input String -> Args -> Args
spacesEndpoint value (Args values) = Args (Object.insert "spaces_endpoint" (inputJson value) values)

spacesSecretKey :: Input String -> Args -> Args
spacesSecretKey value (Args values) = Args (Object.insert "spaces_secret_key" (inputJson value) values)

token :: Input String -> Args -> Args
token value (Args values) = Args (Object.insert "token" (inputJson value) values)

configure :: Args -> Infra Unit
configure (Args values) = addProvider "digitalocean" Nothing values

configureAs :: String -> Args -> Infra Unit
configureAs alias (Args values) = addProvider "digitalocean" (Just alias) values
