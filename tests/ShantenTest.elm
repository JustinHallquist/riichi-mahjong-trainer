module ShantenTest exposing (..)

import Expect
import Shanten
import Test exposing (..)
import Tile


suite : Test
suite =
    describe "Shanten module"
        [ describe "Shanten for Kokushi"
            [ testShantenKokushi "13-sided wait" 0 "19m19p19s1234567z"
            , testShantenKokushi "with one pair" 0 "19m119p19s134567z"
            , testShantenKokushi "with two pairs" 1 "19m1199p19s14567z"
            , testShantenKokushi "only one terminal" 12 "1m2223334445556s"
            , testShantenKokushi "14 tiles, yakuman" -1 "19m19p19s12334567z"
            ]
        , describe "Shanten for Chiitoitsu"
            [ testShantenChiitoitsu "6 pairs" 0 "225588m11p88s223z"
            , testShantenChiitoitsu "2 equal pairs" 1 "222288m11p88s223z"
            , testShantenChiitoitsu "14 tiles, 7 pairs" -1 "225588m11p88s2233z"
            ]
        , describe "Standard shanten (5 groups + pair)"
            [ testShantenStandard "2-shanten" 2 "46789m55779p457s"
            , testShantenStandard "tenpai" 0 "456m567p12388s77z"
            , testShantenStandard "chinitsu" -1 "1112245677889p6p"
            , testShantenStandard "6 groups" 1 "3367m11123p1267s3m"
            ]
        , describe "Standard shanten (less tiles)"
            [ testShantenStandard "4-tiles tenpai" 0 "1234m"
            , testShantenStandard "4-tiles tenpai pairs" 0 "7799m"
            , testShantenStandard "4-tiles 1-shanten" 1 "12m3p5s"
            , testShantenStandard "4-tiles 2-shanten" 2 "1m3p5s3z"
            , testShantenStandard "5-tiles tenpai" 0 "6699m1z"
            , testShantenStandard "5-tiles tenpai no pair" 0 "12345m"
            , testShantenStandard "5-tiles complete" -1 "77799m"
            , testShantenStandard "7-tiles tenpai" 0 "7788999m"
            ]
        , describe "Tile acceptance"
            [ testTileAcceptance "2-sided wait 4 tiles" "14m" "1234m" ]
        ]


testShantenKokushi : String -> Int -> String -> Test
testShantenKokushi name shanten hand =
    test name <|
        \_ -> Expect.equal shanten (Shanten.shantenKokushi (Tile.fromString hand) |> .shanten)


testShantenChiitoitsu : String -> Int -> String -> Test
testShantenChiitoitsu name shanten hand =
    test name <|
        \_ -> Expect.equal shanten (Shanten.shantenChiitoitsu (Tile.fromString hand) |> .shanten)


testShantenStandard : String -> Int -> String -> Test
testShantenStandard name shanten hand =
    test name <|
        \_ -> Expect.equal shanten (Shanten.shantenStandard (Tile.fromString hand) |> .shanten)


testTileAcceptance : String -> String -> String -> Test
testTileAcceptance name acceptedTiles hand =
    test name <|
        \_ -> Expect.equal (Shanten.Draw (Tile.fromString acceptedTiles)) (Shanten.tileAcceptance (Tile.fromString hand))
