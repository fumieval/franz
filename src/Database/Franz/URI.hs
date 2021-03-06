{-# LANGUAGE OverloadedStrings #-}
module Database.Franz.URI
  ( FranzPath(..)
  , toFranzPath
  , fromFranzPath
  ) where

import qualified Data.ByteString as B
import Data.List (stripPrefix)
import Data.String
import Network.Socket (HostName, PortNumber)
import qualified Data.Text as T
import qualified Data.Text.Encoding as T
import Text.Read (readMaybe)

data FranzPath = FranzPath
  { franzHost :: !HostName
  , franzPort :: !PortNumber
  , franzPrefix :: !B.ByteString
  -- ^ Prefix of franz directories
  }

-- | Parse a franz URI (franz://host:port/path).
toFranzPath :: String -> Either String FranzPath
toFranzPath uri = do
  hostnamePath <- maybe (Left "Expecting franz://") Right $ stripPrefix "franz://" uri
  (host, path) <- case break (== '/') hostnamePath of
    (h, '/' : p) -> Right (h, p)
    _ -> Left "Expecting /"
  let path' = T.encodeUtf8 $ T.pack path
  case break (== ':') host of
    (hostname, ':' : portStr)
        | Just p <- readMaybe portStr -> Right $ FranzPath hostname p path'
        | otherwise -> Left "Failed to parse the port number"
    _ -> Right $ FranzPath host 1886 path'

-- | Render 'FranzPath' as a franz URI.
fromFranzPath :: (Monoid a, IsString a) => FranzPath -> a
fromFranzPath (FranzPath host port path) = mconcat
  [ "franz://"
  , fromString host
  , ":"
  , fromString (show port)
  , "/"
  , fromString $ T.unpack $ T.decodeUtf8 path
  ]
