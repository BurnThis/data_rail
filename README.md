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

``DataRail::Pipeline`` is most commonly used from importing data into the database. You could have a step for normalizing fields, tagging records, and inserting it into the database. 


First an example:

```ruby
hasher = DataRail::ObjectHasher.new(business.key)
logger = Logger.new(STDOUT)

pipeline = DataRail::Pipeline.build do
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
- You must pass in a hash of the field mappings to be applied to the database records. 
- Values in this hash can be customized with callbacks. For example, take a look at the country field in the example.

### DataRail::ObjectHasher
This object calculates a unique key for an object such as facebook:photo:32395. 

Each object that goes into the pipeline must follow two conventions to use it.
1. Implement the source property. This is where the object is coming from, like twitter, or instagram.
2. Implement the source_key property. This is the unique identifier that the source provides. For example, 2az3fa3f as a unique id from instagram.

You can also pass in a namespace into the constructer. In the example above, we are passing in the business.key property as the namespace. This is because, in this example, studios ids are not unique to businesses.

If business 25 and business 97 both each have a studio with an id of 1, then we want the keys to read like business:25/studio:1 and business:97/studio:1 and not conflict like studio:1 and studio:1. Hence the namespaces.

### DataRail::Adapter

The Adapter in DataRail is a mixin that makes it easy to wrap objects for purposes of normalizing data. For example, if you are pulling in business information from different APIs, you will have an easier time writing your code if you normalize all data sources to provide objects with the same fields and in the same formats. This offers two major advantages:

- Extensibility. Adding more sources is mostly a matter of creating adapters for new sources. Think of power adapters. If you import an electrical device from anotehr country, you can buy a small travel adapter for each country. These adapters "normalize" the interface of these devices.
- Resilience to change. If the APIs change their data formats (renames fields, changes time formats, etc), you will only need to modify the adapters implementation.

It is recommended that a pipeline is used in conjunction with an adapter when importing data. If you find yourself sprinkling a lot of data processing code in your pipeline builder, you are probably doing something wrong.

#### Basic Example

```ruby
require 'data_rail/adapter'

class StudioAdapter
    # Including Virtus is currently a requirement before including the adapter
    # There are plans to remove this requirement
    include Virtus
    include DataRail::Adapter
    
    field :source, Symbol
    field :source_key, String, from: :ID
    field :description, String, from: :BusinessDescription, process: [:strip]
    
    # You can call into nested properties
    field :latitude, Float, from: 'Location.Latitude'
    field :longitude, Float, from: 'Location.Longitude'
    
    # if you want to add extra attributes, you override attributes
    # attributes is used by the DataRail UpdateRecord operation
    def attributes
      super.merge(data_source: data_source)
    end
    
    # You can override the source attribute
    # Instead of coming from the data_source, it will come from this method
    def source
      :yelp_studio
    end
    
end
```

You could use this adapter like so (contrived example):
```ruby
raw_studio_data = {ID: 'axb4', BusinessDescription: ' We are a yoga studio        ', location: {longitude: '76.98', latitude: 67.98}}
normalized_studio = StudioAdapter.new(raw_studio_data)

normalized_studio.source # => :yelp_studio
normalized_studio.source_key # => 'axb4'
normalized_studio.description # => 'We are a yoga studio'
normalized_studio.latitude # => 76.98
normalized_studio.longitude # => 67.98
```

If you created an adapter for a studio from different data source, you would want to design it so it has the same interface as the above studio.

#### Defining New Processors
To define additional processing such (like `process: [:strip]` in the example), you must define a processor in the `DataRail::Processor` namespace. For example:

```ruby
module DataRail
  module Processor
    class DollarsToCents
      def call(dollars)
        (dollars.to_f * 100).to_i if dollars.respond_to?(:to_f)
      end
    end
  end
end
```

This will allow you to use `:dollars_to_cents` in your process options.

## Roadmap

- Separate operations into their own separate gem
