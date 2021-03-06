module Controller.Main
    (
        Physics (..),
        v2Len, normalize, average,
        inRect,
        updatePhysics,
        getDirection, opposite
    ) where

import qualified Data.Map as Map

import Linear.V2 (V2(V2))

import Model.Main

import Misc

import System.IO.Unsafe

import Controller.Physics (collide)

average :: Floating a => [a] -> a
average xs = sum xs / (fromIntegral $ length xs)

setAt :: [a] -> Int -> a -> [a]
setAt xs i e = take i xs ++ [e] ++ drop (i + 1) xs

v2Len :: Floating a => V2 a -> a
v2Len (V2 x y) = sqrt $ x^2 + y^2

normalize :: Floating a => V2 a -> V2 a
normalize v = v / (pure $ v2Len v)


opposite U = D
opposite D = U
opposite L = R
opposite R = L

-- Checks which direction the second point is relative to the first
getDirection :: Ord a => V2 a -> V2 a -> Maybe Direction
getDirection (V2 x1 y1) (V2 x2 y2)
    | x1 < x2 = Just R
    | x1 > x2 = Just L
    | y1 < y2 = Just D
    | y1 > y2 = Just U
    | otherwise = Nothing

class Physics o where
    getId :: o -> Int

    doMove :: Double -> o -> o
    handleMove :: Double -> Model -> o -> Model

    getBounds :: o -> Shape

    handleCollisions :: Model -> o -> Model

    handleStep :: Double -> Model -> o -> Model

    checkCollisions :: Physics a => o -> Map.Map k a -> [a]
    checkCollisions self m = filter (collided self) $ Map.elems m

    collided :: Physics a => o -> a -> Bool
    collided a b = collide (getBounds a) (getBounds b)

    doPhysics :: Double -> Model -> o -> Model
    doPhysics dt model self = handleCollisions (handleMove dt model self) (doMove dt self)

updatePhysics :: Physics a => Map.Map Int a -> a -> Map.Map Int a
updatePhysics m self = Map.insert (getId self) self m

