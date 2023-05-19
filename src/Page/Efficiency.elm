module Page.Efficiency exposing (Model, Msg, init, update, view)

import Html exposing (Html, a, button, div, li, text, ul)
import Html.Attributes exposing (class, classList, href, target)
import Html.Events exposing (onClick)
import I18n
import List.Extra
import Random
import Random.List
import Shanten
import Tile exposing (Tile)
import UI


type alias Model =
    { i18n : I18n.I18n
    , numberedTiles : Bool
    , numberOfTiles : Int
    , tiles : List Tile
    , availableTiles : List Tile
    , discardedTiles : List Tile
    , shanten : Shanten.ShantenDetail
    , tileAcceptance : Shanten.TileAcceptance
    , lastDiscardTileAcceptance : List ( Tile, Shanten.TileAcceptanceDetail )
    , currentTab : Tab
    }


type Tab
    = CurrentHandAnalysisTab
    | LastMoveAnalysisTab


type Msg
    = GenerateTiles
    | TilesGenerated ( List Tile, List Tile )
    | SetNumberOfTiles Int
    | DiscardTile Tile
    | DrawTile ( Maybe Tile, List Tile )
    | SetTab Tab
    | ShowHand ( Tile, List Tile )


init : I18n.I18n -> ( Model, Cmd Msg )
init i18n =
    ( { i18n = i18n
      , numberedTiles = False
      , numberOfTiles = 14
      , tiles = []
      , availableTiles = []
      , discardedTiles = []
      , shanten = Shanten.init
      , tileAcceptance = Shanten.Draw Shanten.emptyTileAcceptanceDetail
      , lastDiscardTileAcceptance = []
      , currentTab = CurrentHandAnalysisTab
      }
    , cmdGenerateTiles 14
    )


cmdGenerateTiles : Int -> Cmd Msg
cmdGenerateTiles numTiles =
    Random.generate TilesGenerated (Tile.randomList numTiles)


recalculateShanten : Model -> Model
recalculateShanten model =
    { model | shanten = Shanten.shanten model.tiles, tileAcceptance = Shanten.tileAcceptance model.discardedTiles model.tiles }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GenerateTiles ->
            ( model, cmdGenerateTiles model.numberOfTiles )

        TilesGenerated ( tiles, remainingTiles ) ->
            ( recalculateShanten
                { model
                    | tiles = Tile.sort tiles
                    , availableTiles = remainingTiles
                    , discardedTiles = []
                    , lastDiscardTileAcceptance = []
                }
            , Cmd.none
            )

        SetNumberOfTiles numTiles ->
            update GenerateTiles { model | numberOfTiles = numTiles }

        DiscardTile tile ->
            if List.member tile model.tiles then
                let
                    lastDiscardAcceptance =
                        case model.tileAcceptance of
                            Shanten.DiscardAndDraw tileAcceptanceList ->
                                tileAcceptanceList

                            _ ->
                                []
                in
                ( { model
                    | tiles = List.Extra.remove tile model.tiles |> Tile.sort
                    , discardedTiles = model.discardedTiles ++ [ tile ]
                    , lastDiscardTileAcceptance = lastDiscardAcceptance
                  }
                , Random.generate DrawTile (Random.List.choose model.availableTiles)
                )

            else
                ( model, Cmd.none )

        DrawTile ( possibleTile, availableTiles ) ->
            case possibleTile of
                Just tile ->
                    ( recalculateShanten { model | tiles = model.tiles ++ [ tile ], availableTiles = availableTiles }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        SetTab tab ->
            ( { model | currentTab = tab }, Cmd.none )

        ShowHand ( tiles, drawnTile ) ->
            -- TODO complete
            ( model, Cmd.none )


view : Model -> Html Msg
view model =
    let
        tilesString =
            Tile.listToString model.tiles

        uiMap uiMsg =
            case uiMsg of
                UI.TileOnClick tile ->
                    DiscardTile tile

        tabs =
            div [ class "tabs is-boxed" ]
                [ ul []
                    [ li
                        [ classList [ ( "is-active", model.currentTab == CurrentHandAnalysisTab ) ], onClick (SetTab CurrentHandAnalysisTab) ]
                        [ a [] [ text "Hand" ] ]
                    , li
                        [ classList [ ( "is-active", model.currentTab == LastMoveAnalysisTab ) ], onClick (SetTab LastMoveAnalysisTab) ]
                        [ a [] [ text "Last move" ] ]
                    ]
                ]
    in
    div []
        [ div [ class "block" ]
            [ UI.label (I18n.numTilesSelectorTitle model.i18n) (numberTilesSelector model)
            ]
        , div [ class "block" ] [ UI.tilesDivWithOnClick model.i18n model.numberedTiles model.tiles |> Html.map uiMap ]
        , button [ class "button", onClick GenerateTiles ] [ text (I18n.newHandButton model.i18n) ]
        , tabs
        , div [ classList [ ( "is-hidden", model.currentTab /= CurrentHandAnalysisTab ) ] ]
            [ tenhouLink model tilesString
            , div [] (List.map (\lg -> UI.groupsSimple model.i18n model.numberedTiles lg) model.shanten.final.groups)
            , text "Tile acceptance"
            , tileAcceptance model
            ]
        , div [ classList [ ( "is-hidden", model.currentTab /= LastMoveAnalysisTab ) ] ]
            [ tenhouLink model tilesString
            , text "Discard"
            , div []
                (List.map
                    (tileAcceptanceDiscardTile model)
                    model.lastDiscardTileAcceptance
                )
            ]
        ]


tenhouLink : Model -> String -> Html Msg
tenhouLink model tilesString =
    div []
        [ text (String.fromInt model.shanten.final.shanten)
        , text "-shanten -> "
        , a [ href ("https://tenhou.net/2/?q=" ++ tilesString), target "_blank" ] [ text "Tenhou" ]
        ]


numberTilesSelector : Model -> Html Msg
numberTilesSelector model =
    let
        buttonUI txt numberOfTiles =
            button
                [ classList
                    [ ( "button", True )
                    , ( "is-primary", model.numberOfTiles == numberOfTiles )
                    , ( "is-selected", model.numberOfTiles == numberOfTiles )
                    ]
                , onClick (SetNumberOfTiles numberOfTiles)
                ]
                [ text txt ]
    in
    div [ class "buttons has-addons" ]
        [ buttonUI "5" 5
        , buttonUI "8" 8
        , buttonUI "11" 11
        , buttonUI "14" 14
        ]


tileAcceptance : Model -> Html Msg
tileAcceptance model =
    case model.tileAcceptance of
        Shanten.Draw _ ->
            div [] []

        Shanten.DiscardAndDraw listAcceptance ->
            div []
                (List.map
                    (tileAcceptanceDiscardTile model)
                    listAcceptance
                )


tileAcceptanceDiscardTile : Model -> ( Tile, Shanten.TileAcceptanceDetail ) -> Html Msg
tileAcceptanceDiscardTile model ( tile, detail ) =
    let
        uiMap : UI.UIMsg -> Msg
        uiMap uiMsg =
            case uiMsg of
                UI.TileOnClick clickedTile ->
                    -- TODO prev turn tiles
                    ShowHand ( clickedTile, model.tiles )
    in
    div UI.tilesDivAttrs
        ([ UI.tileSimple model.i18n model.numberedTiles tile
         , text "->"
         ]
            ++ (UI.tilesListWithOnClick model.i18n model.numberedTiles detail.tiles |> List.map (Html.map uiMap))
            ++ [ text (String.fromInt detail.numTiles)
               ]
        )
