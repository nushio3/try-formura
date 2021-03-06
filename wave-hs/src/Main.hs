module Main where

import Control.Monad (unless)
import Data.List (intersperse)
import Data.Vector (Vector, generate, (!))
import qualified Data.Vector as V
import System.Exit (die)
import System.Environment (getArgs)

main :: IO ()
main = do
  as <- getArgs
  unless (length as == 2) $ die "Need two arguments"
  let [scheme, nu] = as
      output = "data/" ++ scheme ++ "-" ++ nu ++ ".dat"
      xs0 = buildInitialState 30
      res = take 10 $ iterate (step scheme $ read nu) xs0
  writeFile output $ format res

type State = Vector (Int, Double)

buildInitialState :: Int -> State
buildInitialState x0 = generate 100 (\n -> if n < x0 then (n,1) else (n,0))

step :: String -> Double -> State -> State
step "ftcs" = ftcs
step "lax" = lax
step "lax-wendroff" = laxWendroff
step "upwind" = upwind
step _ = error "No scheme"

ftcs :: Double -> State -> State
ftcs nu xs = V.map (\(i,u) -> (i, u - nu*(uR i - uL i)/2)) xs
    where
        uR 99 = 0
        uR i = snd $ xs ! (i+1)
        uL 0 = 1
        uL i = snd $ xs ! (i-1)

lax :: Double -> State -> State
lax nu xs = V.map (\(i,u) -> (i, (uL i + uR i)/2 - nu*(uR i - uL i)/2)) xs
    where
        uR 99 = 0
        uR i = snd $ xs ! (i+1)
        uL 0 = 1
        uL i = snd $ xs ! (i-1)

laxWendroff :: Double -> State -> State
laxWendroff nu xs = V.map (\(i,u) -> (i, u - nu*(uR i - uL i)/2 + nu*nu*(uR i - 2*u + uL i)/2)) xs
    where
        uR 99 = 0
        uR i = snd $ xs ! (i+1)
        uL 0 = 1
        uL i = snd $ xs ! (i-1)

upwind :: Double -> State -> State
upwind nu xs = V.map (\(i,u) -> (i, u - nu*(u - uL i))) xs
    where
        uL 0 = 1
        uL i = snd $ xs ! (i-1)

format :: [State] -> String
format = unlines . intersperse "" . map (unlines . map (\(i,u) -> show i ++ " " ++ show u) . V.toList)
