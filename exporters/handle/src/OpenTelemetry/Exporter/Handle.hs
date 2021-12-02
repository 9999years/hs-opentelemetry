{-# LANGUAGE DuplicateRecordFields #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RecordWildCards #-}
module OpenTelemetry.Exporter.Handle
  ( makeHandleExporter
  -- $ Typical handle exporters
  , stdoutExporter
  , stderrExporter
  -- $ Formatters
  , defaultFormatter
  ) where

import Data.IORef
import qualified Data.Text.Lazy as L
import OpenTelemetry.Exporter
import OpenTelemetry.Trace.Core
import qualified Data.Text.Lazy.IO as L
import System.IO (Handle, hFlush, stdout, stderr)

makeHandleExporter :: Handle -> (ImmutableSpan -> L.Text) -> Exporter
makeHandleExporter h f = Exporter
  { exporterExport = \fs -> do
      mapM_ (mapM_ (\s -> L.hPutStrLn h (f s) >> hFlush h)) fs 
      pure Success
  , exporterShutdown = hFlush h
  }

stdoutExporter :: (ImmutableSpan -> L.Text) -> Exporter
stdoutExporter = makeHandleExporter stdout

stderrExporter :: (ImmutableSpan -> L.Text) -> Exporter
stderrExporter = makeHandleExporter stderr

defaultFormatter :: ImmutableSpan -> L.Text
defaultFormatter ImmutableSpan{..} = L.intercalate " "
  [ L.pack $ show $ traceId spanContext
  , L.pack $ show $ spanId spanContext
  , L.pack $ show spanStart
  , L.fromStrict spanName
  ]