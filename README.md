[![Mihael Isaev](https://user-images.githubusercontent.com/1272610/40946272-af6396fa-686d-11e8-82af-192850fe3216.png)](http://mihaelisaev.com)

<p align="center">
    <a href="LICENSE">
        <img src="https://img.shields.io/badge/license-MIT-brightgreen.svg" alt="MIT License">
    </a>
    <a href="https://swift.org">
        <img src="https://img.shields.io/badge/swift-4.1-brightgreen.svg" alt="Swift 4.1">
    </a>
    <a href="https://twitter.com/VaporRussia">
        <img src="https://img.shields.io/badge/twitter-VaporRussia-5AA9E7.svg" alt="Twitter">
    </a>
</p>

<br>

# Quick Intro

```swift
struct PublicUser: Codable {
    var name: String
    var petName: String
    var petType: String
    var petToysQuantity: Int
}
try FQL()
    .select(all: User.self)
    .select(\Pet.name, as: "petName")
    .select(\PetType.name, as: "petType")
    .select(.count(\PetToy.id), as: "petToysQuantity")
    .from(User.self)
    .join(.left, Pet.self, where: \Pet.id == \User.idPet)
    .join(.left, PetType.self, where: \PetType.id == \Pet.idType)
    .join(.left, PetToy.self, where: \PetToy.idPet == \Pet.id)
    .groupBy(\User.id, \Pet.id, \PetType.id, \PetToy.id)
    .execute(on: conn)
    .decode(PublicUser.self) // -> Future<[PublicUser]> 🔥🔥🔥
```

# Intro

It's a swift lib that gives ability to build complex raw SQL-queries in a more easy way using KeyPaths. I call it **FQL** 😎

Built for Vapor3 and depends on `Fluent` package because it uses `Model.reflectProperty(forKey:)` method to decode KeyPaths.

For now it support Postgres's SQL-syntax only. But I'm working on MySQL support and it will be available soon.
If you're looking for MySQL support please feel free to file an issue with future request to let me know that you need it.

Now it supports: query with most common predicates, building json objects in select, subqueries, subquery into json, joins, aggregate functions, etc.

Note: the project is in active development state and it may cause huge syntax changes before v1.0.0

If you have great ideas of how to improve this package write me (@iMike) in [Vapor's discord chat](http://vapor.team) or just send pull request.

Hope it'll be useful for someone :)

### Install through Swift Package Manager

Edit your `Package.swift`

```swift
//add this repo to dependencies
.package(url: "https://github.com/MihaelIsaev/FluentQuery.git", from: "0.4.29")
//and don't forget about targets
//"FluentQuery"
```
### One more little intro

I love to write raw SQL queries because it gives ability to flexibly use all the power of database engine.

And Vapor's Fleunt allows you to do raw queries, but the biggest problem of raw queries is its hard to maintain them.

I faced with that problem and I started developing this lib to write raw SQL queries in swift-way by using KeyPaths.

And let's take a look what we have :)


### How it works

First of all you need to import the lib

```swift
import FluentQuery
```

Then create `FQL` object, build your SQL query using methods described below and as first step just print it as a raw string

```swift
let query = FQL()
//some building
print("rawQuery: \(query)")
```

### Several examples

#### 1. Simple

```swift
// SELECT * FROM "User" WHERE age > 18
let fql = FQL().select(all: User.self)
               .from(User.self)
               .where(\User.age > 18)
               .execute(on: conn)
               .decode(User.self)
```

#### 2. Simple with join

```swift
// SELECT u.*, r.name as region FROM "User" as u WHERE u.age > 18 LEFT JOIN "UserRegion" as r ON u.idRegion = r.id
let fql = FQL().select(all: User.self)
               .select(\UserRegion.name)
               .from(User.self)
               .where(\User.age > 18)
               .join(.left, UserRegion.self, where: \User.idRegion == \UserRegion.id)
               .execute(on: conn)
               .decode(UserWithRegion.self)
```

#### 3. Medium 🙂 with query into jsonB obejcts

```swift
// SELECT (SELECT to_jsonb(u)) as user, (SELECT to_jsonb(r)) as region FROM "User" as u WHERE u.age > 18 LEFT JOIN "UserRegion" as r ON u.idRegion = r.id
let fql = FQL().select(.row(User.self), as: "user")
               .select(.row(UserRegion.self), as: "region")
               .from(User.self)
               .where(\User.age > 18)
               .join(.left, UserRegion.self, where: \User.idRegion == \UserRegion.id)
               .execute(on: conn)
               .decode(UserWithRegion.self)
// in this case UserWithRegion struct will look like this
struct UserWithRegion: Codable {
    var user: User
    var region: UserRegion
}
```

#### 4. Complex

Let's take a look how to use it with some example request

Imagine that you have a list of cars

So you have `Car` fluent model

```swift
final class Car: Model {
  var id: UUID?
  var year: String
  var color: String
  var engineCapacity: Double
  var idBrand: UUID
  var idModel: UUID
  var idBodyType: UUID
  var idEngineType: UUID
  var idGearboxType: UUID
}
```
and related models

```swift
final class Brand: Decodable {
  var id: UUID?
  var value: String
}
final class Model: Decodable {
  var id: UUID?
  var value: String
}
final class BodyType: Decodable {
  var id: UUID?
  var value: String
}
final class EngineType: Decodable {
  var id: UUID?
  var value: String
}
final class GearboxType: Decodable {
  var id: UUID?
  var value: String
}
```

ok, and you want to get every car as convenient codable model

```swift
struct PublicCar: Content {
  var id: UUID
  var year: String
  var color: String
  var engineCapacity: Double
  var brand: Brand
  var model: Model
  var bodyType: BodyType
  var engineType: EngineType
  var gearboxType: GearboxType
}
```

Here's example request code for that situation

```swift
func getListOfCars(_ req: Request) throws -> Future<[PublicCar]> {
  return req.requestPooledConnection(to: .psql).flatMap { conn -> EventLoopFuture<[PublicCar]> in
      defer { try? req.releasePooledConnection(conn, to: .psql) }
      return FQL()
        .select(distinct: \Car.id)
        .select(\Car.year, as: "year")
        .select(\Car.color, as: "color")
        .select(\Car.engineCapacity, as: "engineCapacity")
        .select(.row(Brand.self), as: "brand")
        .select(.row(Model.self), as: "model")
        .select(.row(BodyType.self), as: "bodyType")
        .select(.row(EngineType.self), as: "engineType")
        .select(.row(GearboxType.self), as: "gearboxType")
        .from(Car.self)
        .join(.left, Brand.self, where: \Brand.id == \Car.idBrand)
        .join(.left, Model.self, where: \Model.id == \Car.idModel)
        .join(.left, BodyType.self, where: \BodyType.id == \Car.idBodyType)
        .join(.left, EngineType.self, where: \EngineType.id == \Car.idEngineType)
        .join(.left, GearboxType.self, where: \GearboxType.id == \Car.idGearboxType)
        .groupBy(\Car.id, \Brand.id, \Model.id, \BodyType.id, \EngineType.id, \GearboxType.id)
        .orderBy(.asc(\Brand.value), .asc(\Model.value))
        .execute(on: conn)
        .decode(PublicCar.self)
  }
}
```

Hahah, that's cool right? 😃

As you can see we've build complex query to get all depended values and decoded postgres raw response to our codable model.

<details>
    <summary>BTW, this is a raw SQL equivalent</summary>
        
    SELECT
    DISTINCT c.id,
    c.year,
    c.color,
    c."engineCapacity",
    (SELECT toJsonb(brand)) as "brand",
    (SELECT toJsonb(model)) as "model",
    (SELECT toJsonb(bt)) as "bodyType",
    (SELECT toJsonb(et)) as "engineType",
    (SELECT toJsonb(gt)) as "gearboxType"
    FROM "Cars" as c
    LEFT JOIN "Brands" as brand ON c."idBrand" = brand.id
    LEFT JOIN "Models" as model ON c."idModel" = model.id
    LEFT JOIN "BodyTypes" as bt ON c."idBodyType" = bt.id
    LEFT JOIN "EngineTypes" as et ON c."idEngineType" = et.id
    LEFT JOIN "GearboxTypes" as gt ON c."idGearboxType" = gt.id
    GROUP BY c.id, brand.id, model.id, bt.id, et.id, gt.id
    ORDER BY brand.value ASC, model.value ASC
</details>


### So why do you need to use this lib for your complex queries?

#### The reason #1 is KeyPaths!
If you will change your models in the future you'll have to remember where you used links to this model properties and rewrite them manually and if you forgot one you will get headache in production. But with KeyPaths you will be able to compile your project only while all links to the models properties are up to date. Even better, you will be able to use `refactor` functionality of Xcode! 😄
#### The reason #2 is `if/else` statements
With `FQL`'s query builder you can use `if/else` wherever you need. And it's super convenient to compare with using `if/else` while createing raw query string. 😉
#### The reason #3
It is faster than multiple consecutive requests
#### The reason #4
You can join on join on join on join on join on join 😁😁😁 

With this lib you can do real complex queries! 🔥 And you still flexible cause you can use if/else statements while building and even create two separate queries with the same basement using `let separateQuery = FQL(copy: originalQuery)` 🕺

### Methods

The list of the methods which `FQL` provide with

#### Select
These methods will add fields which will be used between `SELECT` and `FROM`

`SELECT _here_some_fields_list_ FROM`

So to add what you want to select call these methods one by one

| Method  | SQL equivalent |
| ------- | -------------- |
| .select("*") | * |
| .select(all: Car.self) | "Cars".* |
| .select(all: someAlias) | "some_alias".* |
| .select(\Car.id) | "Car".id |
| .select(someAlias.k(\.id)) | "some_alias".id |
| .select(distinct: \Car.id) | DISTINCT "Car".id |
| .select(distinct: someAlias.k(\.id)) | DISTINCT "some_alias".id |
| .select(.count(\Car.id), as: "count") | COUNT("Cars".id) as "count" |
| .select(.sum(\Car.value), as: "sum") | SUM("Cars".value) as "sum" |
| .select(.average(\Car.value), as: "average") | AVG("Cars".value) as "average" |
| .select(.min(\Car.value), as: "min") | MIN("Cars".value) as "min" |
| .select(.max(\Car.value), as: "max") | MAX("Cars".value) as "max" |
| .select(.extract(.day, .timestamp, \Car.createdAt), as: "creationDay") | EXTRACT(DAY FROM "Cars".value) as "creationDay" |
| .select(.extract(.day, .interval, "40 days 1 minute"), as: "creationDay") | EXTRACT(DAY FROM INTERVAL '40 days 1 minute') as "creationDay" |

_BTW, read about aliases below_

#### Over

If you need to use window `over` function like
```sql
OVER(partition BY "Record".title, "Record".tag ORDER BY "Record".priority ASC) as something
```

then you could build it like this
```swift
let fqo = FQOver(.partition)
            .by(\Record.title, \Record.tag)
            .orderBy(.asc(\Record.priority))
```
and then use it in your query like this
```swift
let FQL().select(\Record.id).over(fqo, as: "test").from(Record.self)
```

#### From

| Method  | SQL equivalent |
| ------- | -------------- |
| .from("Table") | FROM "Table" |
| .from(raw: "Table") | FROM Table |
| .from(Car.self) | FROM "Cars" as "_cars_" |
| .from(someAlias) | FROM "SomeAlias" as "someAlias" |

#### Join

`.join(FQJoinMode, Table, where: FQWhere)`

```swift
enum FQJoinMode {
    case left, right, inner, outer
}
```

As `Table` you can put `Car.self` or `someAlias`

_About `FQWhere` please read below_


#### Where

`.where(FQWhere)`

##### You can write where predicate two ways

First is object oriented
```swift
FQWhere(predicate).and(predicate).or(predicate).and(FQWhere).or(FQWhere)
```

Second is predicate oriented

_Example for AND statements_
```swift
\User.email == "sam@example.com" && \User.password == "qwerty" && \User.active == true
```

_Example for OR statements_
```swift
\User.email == "sam@example.com" || \User.email == "james@example.com" || \User.email == "bob@example.com"
```

_Example for  both AND and OR statements_
```swift
\User.email == "sam@example.com" && FQWhere(\User.role == .admin || \User.role == .staff)
```
_What FQWhere() doing here? It groups OR statements into round brackets to achieve `a AND (b OR c)` sql code._

##### What `predicate` is?
It may be `KeyPath operator KeyPath` or `KeyPath operator Value`

`KeyPath` may be `\Car.id` or `someAlias.k(\.id)`

`Value` may be any value like int, string, uuid, array, or even something optional or nil

List of available operators you saw above in cheatsheet

Some examples

```swift
FQWhere(someAlias.k(\.deletedAt) == nil)
FQWhere(someAlias.k(\.id) == 12).and(\Car.color ~~ ["blue", "red", "white"])
FQWhere(\Car.year == "2018").and(\Brand.value !~ ["Chevrolet", "Toyota"])
FQWhere(\Car.year != "2005").and(someAlias.k(\.engineCapacity) > 1.6)
```

##### Where grouping example

if you need to group predicates like

```sql
"Cars"."engineCapacity" > 1.6 AND ("Brands".value LIKE '%YO%' OR "Brands".value LIKE '%ET')
```

then do it like this

```swift
FQWhere(\Car.engineCapacity > 1.6).and(FQWhere(\Brand.value ~~ "YO").or(\Brand.value ~= "ET"))
```

##### Cheatsheet
| Operator  | SQL equivalent | Description |
| -- | --- | --- |
| == | == / IS | Equals |
| != | != / IS NOT| Not equals |
| > | > | Greater than |
| < | < | Less than |
| >= | >= | Greater or equal |
| <= | <= | Less or equal |
| ~~ | IN () | In array |
| !~ | NOT IN () | Not in array |
| ~= | LIKE '%str' | Case sensitive text search |
| ~~ | LIKE '%str%' | |
| =~ | LIKE 'str%' | |
| ~% | ILIKE '%str' | Case insensitive text search |
| %% | ILIKE '%str%' | |
| %~ | ILIKE 'str%' | |
| !~= | NOT LIKE '%str' | Case sensitive text search where text not like string |
| !~~ | NOT LIKE '%str%' | |
| !=~ | NOT LIKE 'str%' | |
| !~% | NOT ILIKE '%str' | Case insensitive text search where text not like string |
| !%% | NOT ILIKE '%str%' | |
| !%~ | NOT ILIKE 'str%' | |
| ~~~ | @@ 'str' | Full text search |

#### Having

`.having(FQWhere)`

About `FQWhere` you already read above, but as having calls after data aggregation you may additionally filter your results using aggreagate functions such as `SUM, COUNT, AVG, MIN, MAX`

```swift
.having(FQWhere(.count(\Car.id) > 0))
//OR
.having(FQWhere(.count(someAlias.k(\.id)) > 0))
//and of course you an use .and().or().groupStart().groupEnd()
```

#### Group by

```swift
.groupBy(\Car.id, \Brand.id, \Model.id)
```
or
```swift
.groupBy(FQGroupBy(\Car.id).and(\Brand.id).and(\Model.id))
```
or
```swift
let groupBy = FQGroupBy(\Car.id)
groupBy.and(\Brand.id)
groupBy.and(\Model.id)
.groupBy(groupBy)
```

#### Order by

```swift
.orderBy(FQOrderBy(\Car.year, .asc).and(someAlias.k(\.name), .desc))
```
or
```swift
.orderBy(.asc(\Car.year), .desc(someAlias.k(\.name)))
```

#### Offset

| Method  | SQL equivalent |
| ------- | -------------- |
| .offset(0) | OFFSET 0 |

#### Limit

| Method  | SQL equivalent |
| ------- | -------------- |
| .limit(30) | LIMIT 30 |

### JSON

You can build `json` on `jsonb` object by creating `FQJSON` instance

| Instance  | SQL equivalent |
| --------- | -------------- |
| FQJSON(.normal) | build_json_object() |
| FQJSON(.binary) | build_jsonb_object() |

After creating instance you should fill it by calling `.field(key, value)` method like

```swift
FQJSON(.binary).field("brand", \Brand.value).field("model", someAlias.k(\.value))
```

as you may see it accepts keyPaths and aliased keypaths

but also it accept function as value, here's the list of available functions

| Function  | SQL equivalent |
| --------- | -------------- |
| row(Car.self) | SELECT row_to_json("Cars") |
| row(someAlias) | SELECT row_to_json("some_alias") |
| extractEpochFromTime(\Car.createdAt) | extract(epoch from "Cars"."createdAt") |
| extractEpochFromTime(someAlias.k(\.createdAt)) | extract(epoch from "some_alias"."createdAt") |
| count(\Car.id) | COUNT("Cars".id) |
| count(someAlias.k(\.id)) | COUNT("some_alias".id) |
| countWhere(\Car.id, FQWhere(\Car.year == "2012")) | COUNT("Cars".id) filter (where "Cars".year == '2012') |
| countWhere(someAlias.k(\.id), FQWhere(someAlias.k(\.id) > 12)) | COUNT("some_alias".id) filter (where "some_alias".id > 12) |


### Aliases

`FQAlias<OriginalClass>(aliasKey)` or `OriginalClass.alias(aliasKey)`

Also you can use static alias `OriginalClass.alias` if you need only one its variation

And you can generate random alias `OriginalClass.randomAlias` but keep in mind that every call to `randomAlias` generates new alias as it's computed property

#### What's that for?

When you write complex query you may have several joins or subqueries to the same table and you need to use aliases for that like `"Cars" as c`

#### Usage

So with FQL you can create aliases like this

```swift
//"CarBrand" as b
let aliasBrand = CarBrand.alias("b")
//"CarModel" as m
let aliasModel = CarModel.alias("m")
//"EngineType" as e
let aliasEngineType = EngineType.alias("e")
```

and you can use KeyPaths of original tables referenced to these aliases like this

```swift
aliasBrand.k(\.id)
aliasBrand.k(\.value)
aliasModel.k(\.id)
aliasModel.k(\.value)
aliasEngineType.k(\.id)
aliasEngineType.k(\.value)
```

### Executing query

`.execute(on: PostgreSQLConnection)`

```swift
try FQL().select(all: User.self).execute(on: conn)
```

### Decoding query

`.decode(Decodable.Type, dateDecodingstrategy: JSONDecoder.DateDecodingStrategy?)`

```swift
try FQL().select(all: User.self).execute(on: conn).decode(PublicUser.self)
```

### Custom DateDecodingStrategy

By default date decoding strategy is `yyyy-MM-dd'T'HH:mm:ss.SSS'Z'` which is compatible with postgres `timestamp`

But you can specify custom DateDecodingStrategy like this
```swift
try FQL().select(all: User.self).execute(on: conn).decode(PublicUser.self, dateDecodingStrategy: .secondsSince1970)
```

or like this

```swift
let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
try FQL().select(all: User.self).execute(on: conn).decode(PublicUser.self, dateDecodingStrategy: .formatted(formatter))
```

or if you have two or more columns with different date format in the same model then you could create your own date formatter like described in [issue #3](https://github.com/MihaelIsaev/FluentQuery/issues/3#issuecomment-406801436)


### Conslusion

I hope that it'll be useful for someone.

Feedback is really appreciated!

And don't hesitate to asking me questions, I'm ready to help in [Vapor's discord chat](http://vapor.team) find me by @iMike nickname.
