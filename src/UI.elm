module UI exposing
    ( breakpoints
    , drawBackTile
    , drawGroups
    , drawGroupsSimple
    , drawTile
    , drawTileSimple
    , icon
    , renderTiles
    , tileGap
    , tileGapCss
    , tileHeight
    , tileHeightCss
    , tileHeightDoubleCss
    , tilePath
    , tileScale
    , tileWidth
    )

import FontAwesome
import FontAwesome.Solid exposing (n)
import Group
import Html
import Html.Attributes exposing (class, src, style)
import List.Extra
import Svg.Attributes as SvgA
import Tile


type alias GroupData =
    { group : Group.Group
    , isRepeated : Bool
    , winningTile : Maybe Tile.Tile
    }


breakpoints : Html.Html msg
breakpoints =
    let
        div cls =
            Html.div [ class cls ] [ Html.text cls ]
    in
    Html.div []
        [ div "is-hidden-mobile"
        , div "is-hidden-tablet-only"
        , div "is-hidden-desktop-only"
        , div "is-hidden-widescreen-only"
        , div "is-hidden-fullhd"
        ]


renderTiles : Bool -> List Tile.Tile -> Html.Html msg
renderTiles addNumbers tiles =
    let
        allTiles =
            List.map (drawTileSimple addNumbers) tiles
    in
    Html.div [ class "tiles is-flex is-flex-direction-row", tileGapCss ] allTiles


drawTile : Bool -> List (Html.Attribute msg) -> Tile.Tile -> Html.Html msg
drawTile addNumbers attrs tile =
    let
        path =
            tilePath addNumbers tile
    in
    if String.isEmpty path then
        Html.text ""

    else
        Html.img (tileCss path |> List.append attrs) []


drawTileSimple : Bool -> Tile.Tile -> Html.Html msg
drawTileSimple addNumbers tile =
    drawTile addNumbers [] tile


tilePath : Bool -> Tile.Tile -> String
tilePath addNumbers { number, suit } =
    let
        n =
            String.fromInt number

        n_and_version =
            if addNumbers then
                n ++ "_annotated"

            else
                n
    in
    case suit of
        Tile.Sou ->
            "/img/128px_v2/bamboo/bamboo" ++ n_and_version ++ ".png"

        Tile.Pin ->
            "/img/128px_v2/pin/pin" ++ n_and_version ++ ".png"

        Tile.Man ->
            "/img/128px_v2/man/man" ++ n_and_version ++ ".png"

        Tile.Honor ->
            pathHonorTile number


drawBackTile : Html.Html msg
drawBackTile =
    Html.img (tileCss "/img/128px_v2/face-down-128px.png") []


tileScale : Float
tileScale =
    1.5


tileWidth : Int
tileWidth =
    toFloat 41 * tileScale |> round


tileHeight : Int
tileHeight =
    toFloat 64 * tileScale |> round


tileHeightCss : Html.Attribute msg
tileHeightCss =
    style "height" (String.fromInt tileHeight ++ "px")


tileHeightDoubleCss : Html.Attribute msg
tileHeightDoubleCss =
    style "height" (String.fromInt (2 * tileHeight) ++ "px")


{-| Gap between individual tiles
-}
tileGap : Int
tileGap =
    2


tileGapCss : Html.Attribute msg
tileGapCss =
    Html.Attributes.style "gap" (String.fromInt tileGap ++ "px")


groupGap : Int
groupGap =
    10


groupGapCss : Html.Attribute msg
groupGapCss =
    Html.Attributes.style "gap" (String.fromInt groupGap ++ "px")


tileCss : String -> List (Html.Attribute msg)
tileCss path =
    [ src path
    , class "tile"

    -- needed for nested flex to work when shrinking
    , style "min-width" "20px"
    ]


pathHonorTile : Int -> String
pathHonorTile n =
    case n of
        1 ->
            "/img/128px_v2/winds/wind-east.png"

        2 ->
            "/img/128px_v2/winds/wind-south.png"

        3 ->
            "/img/128px_v2/winds/wind-west.png"

        4 ->
            "/img/128px_v2/winds/wind-north.png"

        5 ->
            "/img/128px_v2/dragons/dragon-haku.png"

        6 ->
            "/img/128px_v2/dragons/dragon-green.png"

        7 ->
            "/img/128px_v2/dragons/dragon-chun.png"

        _ ->
            ""


drawGroups : Bool -> Tile.Tile -> List Group.Group -> Html.Html msg
drawGroups addNumbers winTile groups =
    let
        -- unused
        addGroupIsRepeatedData sg lg =
            case lg of
                [] ->
                    []

                x :: xs ->
                    if List.Extra.find (\e -> e == x) sg /= Nothing then
                        { group = x, isRepeated = True, winningTile = Nothing } :: addGroupIsRepeatedData (List.Extra.remove x sg) xs

                    else
                        { group = x, isRepeated = False, winningTile = Nothing } :: addGroupIsRepeatedData sg xs

        addCointainsWinningTile : List GroupData -> List GroupData
        addCointainsWinningTile groupsData =
            let
                pos =
                    List.Extra.findIndices (\g -> Group.member winTile g.group) groupsData
                        |> List.Extra.last
            in
            case pos of
                Just i ->
                    List.Extra.updateAt i (\g -> { g | winningTile = Just winTile }) groupsData

                Nothing ->
                    groupsData

        groupsWithRepeatedInfo =
            addGroupIsRepeatedData [] groups
                |> addCointainsWinningTile
    in
    Html.div [ class "groups is-flex is-flex-direction-row", groupGapCss ]
        (List.map (\{ group, winningTile } -> drawGroup addNumbers [] winningTile group) groupsWithRepeatedInfo)


drawGroup : Bool -> List (Html.Attribute msg) -> Maybe Tile.Tile -> Group.Group -> Html.Html msg
drawGroup addNumbers attrs winningTile group =
    let
        tiles : List ( Tile.Tile, List (Html.Attribute msg) )
        tiles =
            Group.toTiles group
                |> List.map (\t -> ( t, [] ))

        tilesWithWinInfo =
            case winningTile of
                Just winTile ->
                    let
                        pos =
                            List.Extra.elemIndices ( winTile, [] ) tiles
                                |> List.Extra.last
                    in
                    case pos of
                        Just i ->
                            List.Extra.updateAt i (\( t, _ ) -> ( t, [ winningTileCss ] )) tiles

                        Nothing ->
                            tiles

                Nothing ->
                    tiles
    in
    Html.div (List.append [ class "group is-flex is-flex-direction-row", tileGapCss ] attrs)
        (List.map (\( t, atts ) -> drawTile addNumbers atts t) tilesWithWinInfo)


drawGroupsSimple : Bool -> List Group.Group -> Html.Html msg
drawGroupsSimple addNumbers groups =
    Html.div [ class "groups is-flex is-flex-direction-row", groupGapCss, tileHeightCss ] (List.map (drawGroup addNumbers [] Nothing) groups)


winningTileCss : Html.Attribute msg
winningTileCss =
    Html.Attributes.style "filter" "sepia(50%)"


icon : String -> FontAwesome.Icon hasId -> Html.Html msg
icon classes icn =
    FontAwesome.styled [ SvgA.class classes ] icn |> FontAwesome.view
