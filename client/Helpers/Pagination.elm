module Helpers.Pagination exposing (Buttons(..), listToPage, paginationButtons, renderButtons)

import Constants exposing (emptyString)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onInput)


type Buttons
    = Page Int
    | More
    | Current Int
    | Previous (Maybe Int)
    | Next (Maybe Int)


{-| Create pagination widget, current page(list of rows), and the status string
from given list of elements
-}
listToPage :
    (Int -> msg)
    -> Maybe (item -> Bool)
    -> Maybe (item -> item -> Order)
    -> (Int -> item -> Html msg)
    -> Int
    -> Int
    -> List item
    ->
        { paging : Html msg
        , status : String
        , rows : List (Html msg)
        }
listToPage tagger maybeFilter maybeComparator rowRenderer pageIndex pageSize list =
    let
        total =
            List.length list

        filteredList =
            case maybeFilter of
                Nothing ->
                    list

                Just filter ->
                    List.filter filter list

        filteredListSize =
            List.length filteredList

        filteredPages =
            ceiling <| toFloat filteredListSize / toFloat pageSize

        page =
            Basics.clamp 0 (filteredPages - 1) pageIndex

        sortedList =
            case maybeComparator of
                Nothing ->
                    filteredList

                Just comparator ->
                    List.sortWith comparator filteredList

        rows =
            sortedList
                |> List.drop (page * pageSize)
                |> List.take pageSize
                |> List.indexedMap rowRenderer

        totalPages =
            ceiling <| toFloat total / toFloat pageSize

        --starting from One
        firstVisibleIndex =
            (page * pageSize) + 1

        --starting from One
        lastVisibleIndex =
            Basics.min
                filteredListSize
                ((page + 1) * pageSize)

        recordsStatus =
            if filteredListSize == 0 then
                "No records "

            else
                "Records: "
                    ++ toString firstVisibleIndex
                    ++ "-"
                    ++ toString lastVisibleIndex
                    ++ (if total == filteredListSize then
                            emptyString

                        else
                            " Filtered: " ++ toString filteredListSize
                       )

        status =
            recordsStatus ++ " Total: " ++ toString total

        marginPagesLeft =
            3

        marginPagesRight =
            3

        paging =
            paginationButtons filteredPages page marginPagesLeft marginPagesRight
                |> renderButtons tagger
    in
    { paging = paging
    , status = status
    , rows = rows
    }


paginationButtons : Int -> Int -> Int -> Int -> List Buttons
paginationButtons total current marginLeftCount marginRightCount =
    let
        last =
            total - 1

        countLast =
            last - current

        prev =
            Previous <|
                if current > 0 then
                    Just (current - 1)

                else
                    Nothing

        next =
            Next <|
                if current < last then
                    Just (current + 1)

                else
                    Nothing

        currentCount =
            1

        moreCount =
            1

        firstCount =
            1

        lastCount =
            1

        maxPagesCount =
            firstCount + moreCount + marginLeftCount + currentCount + marginRightCount + moreCount + lastCount

        maxLeft =
            maxPagesCount - (currentCount + moreCount + lastCount)

        maxRight =
            maxPagesCount - (firstCount + moreCount + currentCount)

        isLessThenMaxPages =
            total <= maxPagesCount

        isCloseToLeft =
            current < maxLeft

        isCloseToRight =
            countLast < maxRight

        toPage index =
            if index == current then
                Current index

            else
                Page index

        buttonRange from to =
            List.range from to |> List.map toPage

        leftStub =
            [ toPage 0, More ]

        rightStub =
            [ More, toPage last ]

        pagesButtons =
            if isLessThenMaxPages then
                buttonRange 0 last

            else if isCloseToLeft then
                List.concat [ buttonRange 0 maxLeft, rightStub ]

            else if isCloseToRight then
                List.concat [ leftStub, buttonRange (last - maxRight) last ]

            else
                List.concat [ leftStub, buttonRange (current - marginLeftCount) (current + marginRightCount), rightStub ]
    in
    List.concat [ [ prev ], pagesButtons, [ next ] ]


renderButtons : (Int -> msg) -> List Buttons -> Html msg
renderButtons tagger list =
    let
        toLabel index =
            toString (index + 1)

        btnClass =
            "pagination-btn dc-btn dc-pagination-btn"

        btnClassDisabled =
            btnClass ++ " dc-pagination-btn--disabled"

        icon name =
            node "icon" [ class ("dc-icon dc-icon--btn dc-icon--" ++ name) ] []

        disabledButton name =
            button [ disabled True, class btnClassDisabled ] [ icon name ]

        toButton id =
            case id of
                Page index ->
                    button [ onClick (tagger index), class btnClass ] [ text (toLabel index) ]

                Current index ->
                    button [ onClick (tagger index), class (btnClass ++ " dc-pagination-btn--active") ] [ text (toLabel index) ]

                More ->
                    disabledButton "more"

                Previous maybeIndex ->
                    case maybeIndex of
                        Nothing ->
                            disabledButton "arrow-left"

                        Just index ->
                            button [ onClick (tagger index), class btnClass ] [ icon "arrow-left" ]

                Next maybeIndex ->
                    case maybeIndex of
                        Nothing ->
                            disabledButton "arrow-right"

                        Just index ->
                            button [ onClick (tagger index), class btnClass ] [ icon "arrow-right" ]

        buttons =
            List.map toButton list
    in
    span [ class "pagination dc-pagination" ] buttons
