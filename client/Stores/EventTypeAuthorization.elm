module Stores.EventTypeAuthorization exposing (..)

import Json.Decode exposing (string, Decoder, field, list, succeed)
import Json.Decode.Pipeline exposing (decode, required, resolve)
import Json.Encode as Encode


type alias AuthorizationAttribute =
    { key : Key
    , data_type : String
    , value : String
    , permission : Permission
    }


type Key
    = User
    | Service
    | All
    | Unknown


type PermissionType
    = Read
    | Write
    | Admin


type alias Permission =
    { read : Bool
    , write : Bool
    , admin : Bool
    }


emptyPermission : Permission
emptyPermission =
    { read = False
    , write = False
    , admin = False
    }


readPermission : Permission
readPermission =
    { read = True
    , write = False
    , admin = False
    }


writePermission : Permission
writePermission =
    { read = False
    , write = True
    , admin = False
    }


adminPermission : Permission
adminPermission =
    { read = False
    , write = False
    , admin = True
    }


type alias Authorization =
    { readers : List AuthorizationAttribute
    , writers : List AuthorizationAttribute
    , admins : List AuthorizationAttribute
    }


emptyEventTypeAuthorization : Authorization
emptyEventTypeAuthorization =
    { readers = []
    , writers = []
    , admins = []
    }



-- Decoders


collectionDecoder : Decoder Authorization
collectionDecoder =
    decode Authorization
        |> required "readers" (list (memberDecoder readPermission))
        |> required "writers" (list (memberDecoder writePermission))
        |> required "admins" (list (memberDecoder adminPermission))


memberDecoder : Permission -> Decoder AuthorizationAttribute
memberDecoder permission =
    decode
        (\dataType value ->
            succeed
                { key = dataTypeToKey dataType
                , data_type = dataType
                , value = value
                , permission = permission
                }
        )
        |> required "data_type" string
        |> required "value" string
        |> resolve


encoder : Authorization -> Encode.Value
encoder authorization =
    Encode.object
        [ ( "readers", Encode.list (authorization.readers |> List.map encodeAttribute) )
        , ( "writers", Encode.list (authorization.writers |> List.map encodeAttribute) )
        , ( "admins", Encode.list (authorization.admins |> List.map encodeAttribute) )
        ]


encodeAttribute : AuthorizationAttribute -> Encode.Value
encodeAttribute attr =
    Encode.object
        [ ( "data_type", Encode.string attr.data_type )
        , ( "value", Encode.string attr.value )
        ]


dataTypeToKey : String -> Key
dataTypeToKey str =
    case str of
        "user" ->
            User

        "service" ->
            Service

        "*" ->
            All

        _ ->
            Unknown
