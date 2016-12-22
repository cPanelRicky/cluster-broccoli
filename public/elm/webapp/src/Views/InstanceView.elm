module Views.InstanceView exposing (view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onClick, onCheck, onInput, onSubmit)
import Dict exposing (..)
import Models.Resources.Instance exposing (..)
import Models.Resources.ServiceStatus exposing (..)
import Models.Resources.JobStatus exposing (..)
import Models.Resources.Template exposing (..)
import Models.Ui.InstanceParameterForm as InstanceParameterForm
import Set exposing (Set)
import Maybe
import Date
import Updates.Messages exposing (UpdateBodyViewMsg(..))
import Utils.HtmlUtils exposing (icon, iconButtonText, iconButton)
import Utils.MaybeUtils as MaybeUtils

checkboxColumnWidth = 1
chevronColumnWidth = 30
templateVersionColumnWidth = 1
jobControlsColumnWidth = 170

view instances selectedInstances expandedInstances instanceParameterForms templates =
  let (instancesIds) =
    instances
      |> List.map (\i -> i.id)
      |> Set.fromList
  in
    let (allInstancesSelected, allInstancesExpanded) =
      ( ( instancesIds
          |> Set.intersect selectedInstances
          |> (==) instancesIds
        )
      , (Set.intersect instancesIds expandedInstances) == instancesIds
      )
    in
      table
        [ class "table"
        , style [ ("margin-bottom", "0px") ]
        ]
        [ thead []
          [ tr []
            [ th
              [ width checkboxColumnWidth ]
              [ input
                [ type_ "checkbox"
                , title "Select All"
                , onCheck (AllInstancesSelected (List.map (\i -> i.id) instances))
                , checked allInstancesSelected
                ]
                []
              ]
            , th
              [ width chevronColumnWidth ]
              [ icon
                ( String.concat
                  [ "fa fa-chevron-"
                  , if (allInstancesExpanded) then "down" else "right"
                  ]
                )
                [ attribute "role" "button"
                , onClick
                    ( AllInstancesExpanded
                      (List.map (\i -> i.id) instances)
                      (not allInstancesExpanded)
                    )
                ]
              ]
            , th []
              [ icon "fa fa-hashtag" [ title "Instance ID" ] ]
            , th [ class "text-left hidden-xs" ]
              [ icon "fa fa-cubes" [ title "Services" ] ]
            , th
              [ class "text-center hidden-xs"
              , width templateVersionColumnWidth
              ]
              [ icon "fa fa-code-fork" [ title "Template Version" ] ]
            , th
              [ class "text-center"
              , width jobControlsColumnWidth
              ]
              [ icon "fa fa-cogs" [ title "Job Controls" ] ]
            ]
          ]
        , tbody []
          ( List.concatMap (instanceRow selectedInstances expandedInstances instanceParameterForms templates) instances )
        ]

instanceRow selectedInstances expandedInstances instanceParameterForms templates instance =
  let
    ( instanceExpanded
    , instanceParameterForm
    ) =
    ( (Set.member instance.id expandedInstances)
    , (Dict.get instance.id instanceParameterForms)
    )
  in
    List.append
    [ tr []
      [ td
        [ width checkboxColumnWidth ]
        [ input
          [ type_ "checkbox"
          , onCheck (InstanceSelected instance.id)
          , checked (Set.member instance.id selectedInstances)
          ]
          []
        ]
      , td
        [ width chevronColumnWidth ]
        [ icon
          ( String.concat
            [ "fa fa-chevron-"
            , if (Set.member instance.id expandedInstances) then "down" else "right"
            ]
          )
          [ attribute "role" "button"
          , onClick (InstanceExpanded instance.id (not instanceExpanded))
          ]
        ]
      , td []
        [ span
            [ attribute "role" "button"
            , onClick (InstanceExpanded instance.id (not instanceExpanded))
            ]
            [ text instance.id ]
        ]
      , td [ class "text-left hidden-xs" ]
        ( servicesView instance.services )
      , td
        [ class "text-center hidden-xs"
        , width templateVersionColumnWidth
        ]
        [ span
          [ style [ ("font-family", "monospace") ] ]
          [ text (String.left 8 instance.template.version) ]
        ]
      , td
        [ class "text-center"
        , width jobControlsColumnWidth
        ]
        [ jobStatusView instance.jobStatus
        , text " "
        , iconButton "btn btn-default btn-xs" "glyphicon glyphicon-play" "Start Instance"
        , text " "
        , iconButton "btn btn-default btn-xs" "glyphicon glyphicon-stop" "Stop Instance"
        ]
      ]
    ]
    ( if (instanceExpanded) then
        [ instanceDetailView
            instance
            instanceParameterForm
            templates
        ]
      else
        []
    )

expandedTdStyle =
  [ ("border-top", "0px")
  , ("padding-top", "0px")
  ]

editingParamColor = "rgba(255, 177, 0, 0.46)"
normalParamColor = "#eee"

-- TODO as "id" is special we should treat it also special
instanceDetailView instance maybeInstanceParameterForm templates =
  let
    ( ( idParameter
      , idParameterValue
      , idParameterInfo
      )
    , ( otherParameters
      , otherParameterValues
      , otherParameterInfos
      )
    , formIsBeingEdited
    , periodicRuns
    ) =
    ( ( "id"
      , Dict.get "id" instance.parameterValues
      , Dict.get "id" instance.template.parameterInfos
      )
    , ( List.filter (\p -> p /= "id") instance.template.parameters
      , Dict.remove "id" instance.parameterValues
      , Dict.remove "id" instance.template.parameterInfos
      )
    , MaybeUtils.isDefined maybeInstanceParameterForm
    , List.reverse (List.sortBy .utcSeconds instance.periodicRuns)
    )
  in
    let (otherParametersLeft, otherParametersRight) =
      let firstHalf =
        otherParameters
          |> List.length
          |> toFloat
          |> (\l -> l / 2)
          |> ceiling
      in
        ( List.take firstHalf otherParameters
        , List.drop firstHalf otherParameters
        )
    in
      tr []
        [ td
          [ style expandedTdStyle
          , width checkboxColumnWidth
          ]
          []
        , td
          [ colspan 5
          , style
            ( List.append
                expandedTdStyle
                [ ("padding-right", "40px") ]
            )
          ]
          ( List.append
            [ Html.form
              [ onSubmit (ApplyParameterValueChanges instance) ]
              [ h5 [] [ text "Template" ]
              , templateSelectionView instance.template templates
              , h5 [] [ text "Parameters" ]
              , div
                [ class "row" ]
                [ div
                  [ class "col-md-6" ]
                  [ ( parameterValueView (instance, idParameter, idParameterValue, idParameterInfo, Nothing, False) ) ]
                ]
              , div
                [ class "row" ]
                [ div
                  [ class "col-md-6" ]
                  ( parameterValuesView instance otherParametersLeft otherParameterValues otherParameterInfos maybeInstanceParameterForm )
                , div
                  [ class "col-md-6" ]
                  ( parameterValuesView instance otherParametersRight otherParameterValues otherParameterInfos maybeInstanceParameterForm )
                ]
              , div
                [ class "row"
                , style [ ("margin-bottom", "15px") ]
                ]
                [ div
                  [ class "col-md-6" ]
                  [ iconButtonText
                      ( if (formIsBeingEdited) then "btn btn-success" else "btn btn-default" )
                      "fa fa-check"
                      "Apply"
                      [ disabled (not formIsBeingEdited)
                      , type_ "submit"
                      ]
                  , text " "
                  , iconButtonText
                      ( if (formIsBeingEdited) then "btn btn-warning" else "btn btn-default" )
                      "fa fa-ban"
                      "Discard"
                      [ disabled (not formIsBeingEdited)
                      , onClick (DiscardParameterValueChanges instance)
                      ]
                  ]
                ]
              ]
            ]
            ( if (List.isEmpty periodicRuns) then
                []
              else
                [ h5 [] [ text "Periodic Runs" ]
                , ul []
                  (List.map periodicRunView periodicRuns)
                ]
            )
          )
        ]

templateSelectionView currentTemplate templates =
  let templatesWithoutCurrentTemplate =
    List.filter (\t -> t /= currentTemplate) templates
  in
    select
      [ class "form-control" ]
      ( List.append
        [ templateOption currentTemplate currentTemplate ]
        ( List.map (templateOption currentTemplate) templatesWithoutCurrentTemplate )
      )

templateOption currentTemplate template =
  let templateOption =
    if (currentTemplate == template) then
      "Unchanged"
    else if (currentTemplate.id == template.id) then
      "Upgrade to"
    else
      "Migrate to"
  in
    option []
      [ text templateOption
      , text ": "
      , text template.id
      , text " ("
      , text template.version
      , text ")"
      ]

periodicRunView periodicRun =
  li []
    [ code [ style [ ("margin-right", "12px" ) ] ] [ text periodicRun.jobName ]
    , text " "
    , span
      [ class "hidden-xs"
      , style [ ("margin-right", "12px" ) ]
      ]
      [ icon "fa fa-clock-o" []
      , text " "
      , text (periodicRunDateView (Date.fromTime (toFloat periodicRun.utcSeconds)))
      ]
    , text " "
    , jobStatusView periodicRun.status
    ]

periodicRunDateView date =
  String.concat
    [ toString (Date.hour date)
    , ":"
    , toString (Date.minute date)
    , ":"
    , toString (Date.second date)
    , ":"
    , toString (Date.millisecond date)
    , ", "
    , toString (Date.day date)
    , ". "
    , toString (Date.month date)
    , " "
    , toString (Date.year date)
    ]

parameterValuesView instance parameters parameterValues parameterInfos maybeInstanceParameterForm =
  parameters
  |> List.map ( \p -> (instance, p, Dict.get p parameterValues, Dict.get p parameterInfos, MaybeUtils.concatMap (\f -> (Dict.get p f.changedParameterValues)) maybeInstanceParameterForm, True) )
  |> List.map parameterValueView

parameterValueView (instance, parameter, maybeParameterValue, maybeParameterInfo, maybeEditedValue, enabled) =
  let
    ( placeholderValue
    , parameterValue
    , isSecret
    ) =
    ( maybeParameterInfo
        |> MaybeUtils.concatMap (\i -> i.default)
        |> Maybe.withDefault ""
    , maybeEditedValue
        |> Maybe.withDefault (Maybe.withDefault "" maybeParameterValue)
    , maybeParameterInfo
        |> MaybeUtils.concatMap (\i -> i.secret)
        |> Maybe.withDefault False
    )
  in
    p
      []
      [ div
        [ class "input-group" ]
        ( List.append
          [ span
            [ class "input-group-addon"
            , style
              [ ( "background-color", Maybe.withDefault normalParamColor (Maybe.map (\v -> editingParamColor) maybeEditedValue) )
              ]
            ]
            [ text parameter ]
          , input
            [ type_ ( if isSecret then "password" else "text" )
            , class "form-control"
            , attribute "aria-label" parameter
            , placeholder placeholderValue
            , value parameterValue
            , disabled (not enabled)
            , onInput (EnterParameterValue instance parameter)
            ]
            []
          ]
          ( if (isSecret) then
              [ a
                [ class "input-group-addon"
                , attribute "role" "button"
                ]
                [ icon "glyphicon glyphicon-eye-open" [] ]
              , a
                [ class "input-group-addon"
                , attribute "role" "button"
                ]
                [ icon "glyphicon glyphicon-copy" [] ]
              ]
            else
              []
          )
        )
      ]

jobStatusView jobStatus =
  let (statusLabel, statusText) =
    case jobStatus of
      JobRunning -> ("success", "running")
      JobPending -> ("warning", "pending")
      JobStopped -> ("default", "stopped")
      JobDead    -> ("primary", "completed")
      JobUnknown -> ("warning", "unknown")
  in
    span
      [ class ( String.concat [ "label label-", statusLabel ] )
      , style
        [ ("font-size", "90%")
        , ("width", "80px")
        , ("display", "inline-block")
        , ("margin-right", "8px")
        ]
      ]
      [ text statusText ]

servicesView services =
  if (List.isEmpty services) then
    [ text "-" ]
  else
    List.concatMap serviceView services

serviceView service =
  let (iconClass, textColor) =
    case service.status of
      ServicePassing ->
        ("fa fa-check-circle", "#070")
      ServiceFailing ->
        ("fa fa-times-circle", "#900")
      ServiceUnknown ->
        ("fa fa-question-circle", "grey")
  in
    [ a
      [ href
        ( String.concat
          [ service.protocol
          , "://"
          , service.address
          , ":"
          , (toString service.port_)
          ]
        )
      , style
        [ ("margin-right", "8px")
        , ("color", textColor)
        ]
      ]
      [ icon iconClass [ style [ ("margin-right", "4px") ] ]
      , text service.name
      ]
    , text " "
    ]
