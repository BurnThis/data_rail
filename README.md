[![Build Status](https://travis-ci.org/coderly/data_rail.png)](https://travis-ci.org/coderly/data_rail)
[![Code Climate](https://codeclimate.com/github/coderly/data_rail.png)](https://codeclimate.com/github/coderly/data_rail)

# Overview

DataRail provides two main components to its system.
- A pipeline builder that simplifies the process of importing and processing data
- An operation builder that simplifies the process of executing compound operations

## Installation

Add this line to your application's Gemfile:

    gem 'data_rail', github: 'coderly/data_rail'

And then execute:

    $ bundle

## A simple pipeline example

A pipeline can be built using the build method:

```ruby

class Capitalizer
  attr_reader :field

  def initialize(field)
    @field = field
  end

  def call(item)
    item.public_send("#{field}").capitalize!
    # you must return what will get passed into the next step
    item
  end
end

pipeline = DataRail::Pipeline.build do
  use Capitalizer.new(first_name)
  # anything that responds to .call can be used
  use lambda { |u| u.save; u }  
end
```

- **It is important to note** that each step in a pipeline must return what needs to be used in the next step.

- If you want to process a single object, you can use the .call method for the pipeline: `pipeline.call(george)`

- If you want to process a collection of objects, you can use the .process method: `pipeline.process(recent_users)`

- Pipelines can be used as steps in other pipelines because they respond to .call

## Importing data

``DataRail::Pipeline`` is most commonly used from importing data into the database. You may have a step for normalizing fields, tagging records, and inserting it into the database. 


First an example:

```ruby
hasher = DataRail::ObjectHasher.new(business.key)
logger = Logger.new(STDOUT)

DataRail::Pipeline.build do
  use DataRail::Operation::UpdateRecord.new(BurnThis::Studio,
                                            fields: {
                                              key: hasher,
                                              country: lambda { |studio| studio.location.country }  
                                              business_id: business.id,
                                              business_key: business.key})
  
  use MyApp::Operation::DetermineTimezone.new(logger)
  use DataRail::Operation::SaveRecord.new(logger: logger)
end

```

### DataRail::Operation::SaveRecord
This operation is provided by DataRail out of the box. It saves a record and logs the results of the save out to the screen.

### DataRail::Operation::UpdateRecord
- This operation creates or updates a record in the database.
- Records must have a key column. This column must be a string and have a unique constraint on it. The key column is what determines the identity of a record.
- Key columns are a primary key because data from external sources should have a consistent unique id.
- A suggested convention for keys to prefix data with its source. For example `facebook:photo:32395` or `instagram:photo:4zd3f3af`
- You must pass in a hash of the field mappings to be applied to the database records. Take a look at the example above. Values in this hash can be customized with callbacks. For example, take a look at the country field.

### DataRail::ObjectHasher
This object calculates a unique key for an object such as facebook:photo:32395. 

Each object that goes into the pipeline must follow two conventions to use it.
1. Implement the source property. This is where the object is coming from, like twitter, or instagram.
2. Implement the source_key property. This is the unique identifier that the source provides. For example, 2az3fa3f as a unique id from instagram.

You can also pass in a namespace into the constructer. In the example above, we are passing in the business.key property as the namespace. This is because, in this example, studios ids are not unique to businesses.

If business 25 and business 97 both each have a studio with an id of 1, then we want the keys to read like business:25/studio:1 and business:97/studio:1 and not conflict like studio:1 and studio:1. Hence the namespaces.

### DataRail::Adapter

It is recommended that a pipeline is used in conjunction with an adapter when importing data. If you find yourself sprinkling a lot of data processing code in your pipeline builder, you are probably doing something wrong.

## Roadmap

- Separate operations into their own separate gem
