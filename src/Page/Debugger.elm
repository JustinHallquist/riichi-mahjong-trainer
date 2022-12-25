module Page.Debugger exposing (debugGroup, debugGroups, main)

import Browser
import Group exposing (Group)
import Html exposing (Html, div, input, li, p, table, tbody, td, text, th, thead, tr, ul)
import Html.Attributes exposing (class, placeholder, type_, value)
import Html.Events exposing (onInput)
import I18n
import Shanten
import Suit
import Tile exposing (Tile)
import UI


type alias Model =
    { i18n : I18n.I18n
    , handString : String
    , tiles : List Tile
    , breakdown : Group.GroupsBreakdown
    , groups : List (List Group)
    , shanten : Shanten.ShantenDetail
    }


type Msg
    = HandStr String


main : Program () Model Msg
main =
    Browser.element
        { init = \_ -> init
        , update = update
        , view = \m -> div [ class "container" ] [ view m ]
        , subscriptions = \_ -> Sub.none
        }


init : ( Model, Cmd Msg )
init =
    ( { i18n = I18n.init I18n.En
      , handString = ""
      , tiles = []
      , shanten = Shanten.shanten []
      , groups = []
      , breakdown = Group.breakdownInit
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HandStr handString ->
            let
                tiles =
                    Tile.fromString handString

                groupsBreakdown =
                    Group.findGroups Group.FindPartials tiles

                groups =
                    Group.breakdownCartesianProduct groupsBreakdown
            in
            ( { model
                | handString = handString
                , tiles = tiles
                , shanten = Shanten.shanten tiles
                , groups = groups
                , breakdown = groupsBreakdown
              }
            , Cmd.none
            )


view : Model -> Html Msg
view model =
    div []
        [ input [ class "input", type_ "text", placeholder "Hand", value model.handString, onInput HandStr ] []
        , p [] [ UI.tiles model.i18n True model.tiles ]
        , div [ class "block" ]
            [ p [] [ text ("Shanten: " ++ String.fromInt model.shanten.final.shanten) ]
            , p [] [ text ("Kokushi " ++ String.fromInt model.shanten.kokushi.shanten) ]
            , p [] [ text ("Chiitoitsu " ++ String.fromInt model.shanten.chiitoitsu.shanten) ]
            , debugGroups model.breakdown
            , p [] (List.map (UI.groups model.i18n False (Tile 1 Suit.Man)) model.shanten.final.groups)
            , p [] [ text "--" ]
            , p [] (List.map (UI.groups model.i18n False (Tile 1 Suit.Man)) model.groups)
            ]
        ]


debugGroup : List Group -> Html msg
debugGroup listGroup =
    if List.isEmpty listGroup then
        text "-"

    else
        ul [] (List.map (\g -> li [] [ text (Group.toString g) ]) listGroup)


debugGroups : Group.GroupsBreakdown -> Html msg
debugGroups groups =
    let
        generateTd l =
            List.map (\g -> td [] [ debugGroup g ]) l

        sevenPairsTxt =
            if List.isEmpty groups.chiitoitsu then
                "no"

            else
                "yes"
    in
    table [ class "table is-striped" ]
        [ thead []
            [ tr [] [ th [] [ text "groupsPerSuit" ] ] ]
        , tbody []
            [ tr [] (generateTd groups.perSuit.man)
            , tr [] (generateTd groups.perSuit.pin)
            , tr [] (generateTd groups.perSuit.sou)
            , tr [] (generateTd groups.perSuit.honor)
            , tr [] [ text ("Chiitoisu: " ++ sevenPairsTxt) ]
            ]
        ]
