{-# LANGUAGE RecordWildCards #-}
{-# LANGUAGE NamedFieldPuns #-}

module Main where

import Linear.V2 (V2(V2))

import Helm
import Helm.Color
import Helm.Engine.SDL (SDLEngine)
import Helm.Graphics2D

import qualified Helm.Cmd as Cmd
import qualified Helm.Mouse as Mouse
import qualified Helm.Engine.SDL as SDL
import qualified Helm.Graphics2D.Text as Text
import qualified Helm.Keyboard as Keyboard
import qualified Helm.Sub as Sub
import qualified Helm.Time as Time

import qualified Data.Map as Map

import System.Random

-- All of the types and actual game functions are defined in here/sub libraries.
import Lib

import Model.Main
import qualified Model.Part as Part
import qualified Model.Ship as Ship
import qualified Model.Shot as Shot

import Controller.Main
import qualified Controller.Part as Part
import qualified Controller.Ship as Ship
import qualified Controller.Shot as Shot

import Ships -- Contains ships definitions

initial :: (Model, Cmd SDLEngine Action)
initial = (model, Cmd.execute (getStdRandom random >>= (return . mkStdGen)) InitRandom) -- Command is to set up the initial random generator.
    where shipList = [kiraara, vijossk, videre, hija, davanja, pischki]
          model = foldl Part.buildShip initModel shipList
          initModel = 
             Model 
             {
                currentShip = -1,
                ships = Map.empty,
                parts = Map.empty,
                shots = Map.empty,
                nShips = 1,
                nShots = 1,
                nParts = 1,
                gen = mkStdGen 1,
                worldSize = V2 1600 800
             }

update :: Model -> Action -> (Model, Cmd SDLEngine Action)
update model (InitRandom gen) = (model {gen = gen}, Cmd.none)

-- Change the current ship when we right click
update model@(Model {..}) (RClick pos) =
    case Ship.findAt pos ships of
        Just shipId -> (model {currentShip = shipId}, Cmd.none)
        Nothing -> (model {currentShip = (-1)}, Cmd.none)

-- Shoot a shot from our ship if we can at the place we clicked on
update model@(Model {..}) (LClick pos) = (model, Cmd.none)

update model (Step dt) = (doStep dt $ Ship.checkDestroyed $ handlePhysics model, Cmd.none)
update model None = (model, Cmd.none)

subscriptions :: Sub SDLEngine Action
subscriptions = Sub.batch [Mouse.clicks handleClick,
                           Time.fps gameFPS Step]
    where handleClick Mouse.LeftButton (V2 x y) = LClick (V2 (fromIntegral x) (fromIntegral y))
          handleClick Mouse.RightButton (V2 x y) = RClick (V2 (fromIntegral x) (fromIntegral y))
          handleClick _ _ = None

view :: Model -> Graphics SDLEngine
view model@(Model {..}) = Graphics2D $ collage (map showShip (Map.elems ships) ++ map showShot (Map.elems shots))
    where showShip ship@Ship.Ship{Ship.color=color@(r,g,b)} = 
                group $ (map (showPart color) $ Map.elems $ Part.getParts model ship) ++ [name]
                -- we want it to be just slightly above the highest piece.
                where name = case Part.getFarthest U model ship of
                                Just part@Part.Part{Part.pos = V2 x y} -> 
                                    move (V2 x (y - 20 / 2 - 10)) $ text $ Text.height 12 $ Text.color (rgb r g b) $ Text.toText $ Ship.name ship
                                Nothing -> text $ Text.toText ""
          showPart (r,g,b) (Part.Part {..}) = move pos $ filled (rgb r g b) $ square size
          showShot (Shot.Shot {..}) = 
            case Map.lookup launchId ships of
                Just Ship.Ship{Ship.color=(r,g,b)} -> move pos $ filled (rgb r g b) $ square size
                Nothing -> blank

main :: IO ()
main = do
    engine <- SDL.startupWith $ SDL.defaultConfig
                { SDL.windowIsResizable = False,
                  SDL.windowDimensions = floor <$> (worldSize $ fst initial) }

    run engine GameConfig
     {
        initialFn = initial,
        updateFn = update,
        subscriptionsFn = subscriptions,
        viewFn = view
     }
