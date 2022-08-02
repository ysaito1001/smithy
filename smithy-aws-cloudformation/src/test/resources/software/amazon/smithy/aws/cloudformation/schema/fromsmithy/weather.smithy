$version: "2.0"

namespace example.weather

use aws.cloudformation#cfnResource
use aws.api#taggable
use aws.api#tagEnabled

/// Provides weather forecasts.
@paginated(inputToken: "nextToken", outputToken: "nextToken",
           pageSize: "pageSize")
@tagEnabled
service Weather {
    version: "2006-03-01",
    resources: [City]
    operations: [GetCurrentTime]
}

operation TagCity {
    input := {
        @required
        cityId: CityId
        @length(max: 128)
        tags: example.tagging#TagList
    }
    output := { }
}

operation UntagCity {
    input := {
        @required
        cityId: CityId
        @required
        @notProperty
        tagKeys: example.tagging#TagKeys
    }
    output := { }
}

operation ListTagsForCity {
    input := {
        @required
        cityId: CityId
    }
    output := { 
        @length(max: 128)
        tags: example.tagging#TagList
    }
}

@cfnResource
@taggable(property: "tags", apiConfig: {tagApi: TagCity, untagApi: UntagCity, listTagsApi: ListTagsForCity})
resource City {
    identifiers: { cityId: CityId },
    properties: {
        name: String
        coordinates: CityCoordinates
        tags: example.tagging#TagList
    }
    create: CreateCity
    read: GetCity,
    update: UpdateCity
    list: ListCities,
    operations: [TagCity, UntagCity, ListTagsForCity],
    resources: [Forecast],
}

operation CreateCity {
    output := {
        @required
        cityId: CityId
    }
    input := {
        name: String
        coordinates: CityCoordinates
    }
}
operation UpdateCity {
    output := {
    }
    input := {
        @required
        cityId: CityId
        name: String
        coordinates: CityCoordinates
    }
}

/// @cfnResource
resource Forecast {
    identifiers: { cityId: CityId },
    read: GetForecast,
}

@pattern("^[A-Za-z0-9 ]+$")
string CityId

@readonly
operation GetCity {
    input: GetCityInput,
    output: GetCityOutput,
    errors: [NoSuchResource]
}

@input
structure GetCityInput {
    // "cityId" provides the identifier for the resource and
    // has to be marked as required.
    @required
    cityId: CityId
}

@output
structure GetCityOutput {
    // "required" is used on output to indicate if the service
    // will always provide a value for the member.
    @required
    name: String,

    @required
    coordinates: CityCoordinates,
}

// This structure is nested within GetCityOutput.
structure CityCoordinates {
    @required
    latitude: Float,

    @required
    longitude: Float,
}

// "error" is a trait that is used to specialize
// a structure as an error.
@error("client")
structure NoSuchResource {
    @required
    resourceType: String
}

// The paginated trait indicates that the operation may
// return truncated results.
@readonly
@paginated(items: "items")
operation ListCities {
    input: ListCitiesInput,
    output: ListCitiesOutput
}

@input
structure ListCitiesInput {
    nextToken: String,
    pageSize: Integer
}

@output
structure ListCitiesOutput {
    nextToken: String,

    @required
    items: CitySummaries,
}

// CitySummaries is a list of CitySummary structures.
list CitySummaries {
    member: CitySummary
}

// CitySummary contains a reference to a City.
@references([{resource: City}])
structure CitySummary {
    @required
    cityId: CityId,

    @required
    name: String,
}

@readonly
operation GetCurrentTime {
    input: GetCurrentTimeInput,
    output: GetCurrentTimeOutput
}

@input
structure GetCurrentTimeInput {}

@output
structure GetCurrentTimeOutput {
    @required
    time: Timestamp
}

@readonly
operation GetForecast {
    input: GetForecastInput,
    output: GetForecastOutput
}

// "cityId" provides the only identifier for the resource since
// a Forecast doesn't have its own.
@input
structure GetForecastInput {
    @required
    cityId: CityId,
}

@output
structure GetForecastOutput {
    chanceOfRain: Float
}

