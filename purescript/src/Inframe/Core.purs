module Inframe.Core (module Public) where

-- Generated adapters use Inframe.Internal.Core for graph-construction
-- primitives. This module exposes only typed combinators and explicitly unsafe
-- escape hatches.
import Inframe.Internal.Core
  ( DataSource
  , Expr
  , ExprNode(..)
  , Input
  , Provider
  , Resource
  , TemplatePart
  , UnsafeArgument
  , array
  , computed
  , ifThenElse
  , index
  , interpolate
  , lit
  , lookup
  , object
  , secretEnv
  , template
  , text
  , unsafeArgument
  , unsafeCall
  ) as Public
