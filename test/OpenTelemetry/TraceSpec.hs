module OpenTelemetry.TraceSpec where

import Control.Monad
import Data.Int
import Data.IORef
import Data.Text (Text)
import qualified OpenTelemetry.Context as Context
import OpenTelemetry.Trace
import OpenTelemetry.Trace.Types (TracerProvider, SpanContext(..), TraceId(..), SpanId(..))
import qualified OpenTelemetry.Trace.Types as Types
import Test.Hspec
import System.Clock

asIO :: IO a -> IO a
asIO = id

spec :: Spec
spec = describe "Trace" $ do

  describe "TracerProvider" $ do
    specify "Create TracerProvider" $ do
      void (createTracerProvider [] emptyTracerProviderOptions :: IO TracerProvider)
    specify "Get a Tracer" $ asIO $ do
      p <- getGlobalTracerProvider
      void $ getTracer p "woo" tracerOptions
    specify "Get a Tracer with schema_url" $ asIO $ do
      p <- getGlobalTracerProvider
      void $ getTracer p "woo" (tracerOptions { tracerSchema = Just "https://woo.com" })
    specify "Safe for concurrent calls" pending
    specify "Shutdown" pending
    specify "ForceFlush" pending

  describe "Trace / Context interaction" $ do
    specify "Set active span, Get active span" $ do
      p <- getGlobalTracerProvider
      t <- getTracer p "woo" tracerOptions
      s <- createSpan t Nothing "create_root_span" emptySpanArguments
      spanContext1 <- spanContext s
      let ctxt = Context.insertSpan s mempty
      let Just s' = Context.lookupSpan ctxt
      spanContext2 <- spanContext s'
      spanContext1 `shouldBe` spanContext2

  describe "Tracer" $ do
    specify "Create a new span" $ asIO $ do
      p <- getGlobalTracerProvider
      t <- getTracer p "woo" tracerOptions
      void $ createSpan t Nothing "create_root_span" emptySpanArguments
    specify "Get active new span" pending
    specify "Mark Span active" pending
    specify "Safe for concurrent calls" pending
  describe "SpanContext" $ do
    specify "IsValid" $ do
      let validSpan = SpanContext
            { traceFlags = 0
            , isRemote = False
            , traceState = []
            , spanId = SpanId "1"
            , traceId = TraceId "1"
            }
      validSpan `shouldSatisfy` isValid
      (validSpan { spanId = SpanId "\0", traceId = TraceId "\0" }) `shouldSatisfy` (not . isValid)
    specify "IsRemote" pending
    specify "Conforms to the W3C TraceContext spec" pending
  describe "Span" $ do
    specify "Create root span" $ asIO $ do
      p <- getGlobalTracerProvider
      t <- getTracer p "woo" tracerOptions
      void $ createSpan t Nothing "create_root_span" emptySpanArguments
    specify "Create with default parent (active span)" pending
    specify "Create with parent from Context" pending
    -- specify "No explict parent from Span/SpanContext allowed" pending
    specify "SpanProcessor.OnStart receives parent Context" pending
    specify "UpdateName" $ asIO $ do
      p <- getGlobalTracerProvider
      t <- getTracer p "woo" tracerOptions
      s <- createSpan t Nothing "create_root_span" emptySpanArguments
      updateName s "renamed_span"
    specify "User-defined start timestamp" pending
    specify "End" $ asIO $ do
      p <- getGlobalTracerProvider
      t <- getTracer p "woo" tracerOptions
      s <- createSpan t Nothing "create_root_span" emptySpanArguments
      endSpan s Nothing
    specify "End with timestamp" $ asIO $ do
      p <- getGlobalTracerProvider
      t <- getTracer p "woo" tracerOptions
      ts <- getTime Realtime
      s <- createSpan t Nothing "create_root_span" emptySpanArguments
      endSpan s (Just ts)
    specify "IsRecording" $ asIO $ do
      p <- getGlobalTracerProvider
      t <- getTracer p "woo" tracerOptions
      ts <- getTime Realtime
      s <- createSpan t Nothing "create_root_span" emptySpanArguments
      recording <- isRecording s
      recording `shouldBe` True

    specify "IsRecording becomes false after End" $ do
      p <- getGlobalTracerProvider
      t <- getTracer p "woo" tracerOptions
      ts <- getTime Realtime
      s <- createSpan t Nothing "create_root_span" emptySpanArguments
      endSpan s Nothing
      recording <- isRecording s
      recording `shouldBe` False

    specify "Set status with StatusCode (Unset, Ok, Error)" $ do
      p <- getGlobalTracerProvider
      t <- getTracer p "woo" tracerOptions
      ts <- getTime Realtime
      s@(Types.Span r) <- createSpan t Nothing "create_root_span" emptySpanArguments
      setStatus s $ Types.Error "woo"
      do
        i <- readIORef r
        Types.spanStatus i `shouldBe` Types.Error "woo"
      setStatus s $ Types.Ok
      do
        i <- readIORef r
        Types.spanStatus i `shouldBe` Types.Ok
      setStatus s $ Types.Error "woo"
      do
        i <- readIORef r
        Types.spanStatus i `shouldBe` Types.Ok


    specify "Safe for concurrent calls" pending
    specify "events collection size limit" pending
    specify "attribute collection size limit" pending
    specify "links collection size limit" pending

  describe "Span attributes" $ do
    specify "SetAttribute" $ asIO $ do
      p <- getGlobalTracerProvider
      t <- getTracer p "woo" tracerOptions
      s <- createSpan t Nothing "create_root_span" emptySpanArguments
      insertAttribute s "attr" (1.0 :: Double)
      
    specify "Set order preserved" pending
    specify "String type" $ asIO $ do
      p <- getGlobalTracerProvider
      t <- getTracer p "woo" tracerOptions
      s <- createSpan t Nothing "create_root_span" emptySpanArguments
      insertAttribute s "string_type" ("" :: Text)

    specify "Boolean type" $ asIO $ do
      p <- getGlobalTracerProvider
      t <- getTracer p "woo" tracerOptions
      s <- createSpan t Nothing "create_root_span" emptySpanArguments
      insertAttribute s "bool_type" True

    specify "Double floating-point type" $ asIO $ do
      p <- getGlobalTracerProvider
      t <- getTracer p "woo" tracerOptions
      s <- createSpan t Nothing "create_root_span" emptySpanArguments
      insertAttribute s "attr" (1.0 :: Double)

    specify "Signed int64 type" $ asIO $ do
      p <- getGlobalTracerProvider
      t <- getTracer p "woo" tracerOptions
      s <- createSpan t Nothing "create_root_span" emptySpanArguments
      insertAttribute s "attr" (1 :: Int64)

    specify "Array of primitives (homegeneous)" $ asIO $ do
      p <- getGlobalTracerProvider
      t <- getTracer p "woo" tracerOptions
      s <- createSpan t Nothing "create_root_span" emptySpanArguments
      insertAttribute s "attr" [(1 :: Int64)..10]

    specify "Unicode support for keys and string values" $ asIO $ do
      p <- getGlobalTracerProvider
      t <- getTracer p "woo" tracerOptions
      s <- createSpan t Nothing "create_root_span" emptySpanArguments
      insertAttribute s "🚀" ("🚀" :: Text)
      -- TODO actually get attributes out


  describe "Span events" $ do
    specify "AddEvent" $ do
      p <- getGlobalTracerProvider
      t <- getTracer p "woo" tracerOptions
      s <- createSpan t Nothing "create_root_span" emptySpanArguments
      addEvent s $ NewEvent
        { newEventName = "EVENT"
        , newEventAttributes = []
        , newEventTimestamp = Nothing
        }
    specify "Add order preserved" pending
    specify "Safe for concurrent calls" pending

  describe "Span exceptions" $ do
    specify "RecordException" pending
    specify "RecordException with extra parameters" pending

  describe "Sampling" $ do
    specify "Allow samplers to modify tracestate" pending
    specify "ShouldSample gets full parent Context" pending
    specify "ShouldSample gets InstrumentationLibrary" pending

  specify "New Span ID created also for non-recording spans" pending
  specify "IdGenerators" pending
  specify "SpanLimits" pending
  specify "Built-in SpanProcessors implement ForceFlush spec" pending
  specify "Attribute Limits" pending



