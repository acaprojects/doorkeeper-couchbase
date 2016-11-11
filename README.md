# doorkeeper-couchbase extension

## Installation

doorkeeper-couchbase provides doorkeeper support to couchbase
To start using it, add to your Gemfile:

``` ruby
gem "doorkeeper-couchbase"
```

Run [doorkeeper’s installation generator]:

    rails generate doorkeeper:install

[doorkeeper’s installation generator]: https://github.com/doorkeeper-gem/doorkeeper#installation

This will install the doorkeeper initializer into
`config/initializers/doorkeeper.rb`.

Set the ORM configuration:

``` ruby
Doorkeeper.configure do
  orm :couchbase
end
```

## Tests

To run tests, clone this repository and run `rake`. It will copy and run
doorkeeper’s original test suite, after configuring the ORM according to the
variables defined in `.travis.yml` file.


---

Please refer to https://github.com/doorkeeper-gem/doorkeeper for instructions on
doorkeeper’s project.
