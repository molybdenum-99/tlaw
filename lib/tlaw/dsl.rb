module TLAW
  # This module is core of a TLAW API definition. It works like this:
  #
  # ```ruby
  # class MyAPI < TLAW::API
  #   define do # here starts what DSL does
  #     namespace :ns do
  #
  #       endpoint :es do
  #         param :param1, Integer, default: 1
  #       end
  #     end
  #   end
  # end
  # ```
  #
  # Methods of current namespace documentation describe everything you
  # can use inside `define` blocks. Actual structure of things is a bit
  # more complicated (relate to lib/tlaw/dsl.rb if you wish), but current
  # documentation structure considered to be most informative.
  #
  module DSL
    # @!method base(url)
    #   Allows to set entire API base URL, all endpoints and namespaces
    #   pathes are calculated relative to it.
    #
    #   **Works for:** API
    #
    #   @param url [String]

    # @!method desc(text)
    #   Allows to set description string for your API object. It can
    #   be multiline, and TLAW will automatically un-indent excessive
    #   indentations:
    #
    #   ```ruby
    #       # ...several levels of indents while you create a definition
    #       desc %Q{
    #         This is some endpoint.
    #         And it works!
    #       }
    #
    #   # ...but when you are using it...
    #   p my_api.endpoint(:endpoint).describe
    #   # This is some endpoint.
    #   # And it works!
    #   # ....
    #   ```
    #
    #   **Works for:** API, namespace, endpoint
    #
    #   @param text [String]

    # @!method docs(link)
    #   Allows to add link to documentation as a separate line to
    #   object description. Just to be semantic :)
    #
    #   ```ruby
    #   # you do something like
    #   desc "That's my endpoint"
    #
    #   docs "http://docs.example.com/my/endpoint"
    #
    #   # ...and then somewhere...
    #   p my_api.endpoint(:endpoint).describe
    #   # That is my endpoint.
    #   #
    #   # Docs: http://docs.example.com/my/endpoint
    #   # ....
    #   ```
    #
    #   **Works for:** API, namespace, endpoint
    #
    #   @param link [String]

    # @!method param(name, type = nil, keyword: true, required: false, **opts)
    #   Defines parameter for current API (global), namespace or endpoint.
    #
    #   Param defnition defines several things:
    #
    #   * how method definition to call this namespace/endpoint would
    #     look like: whether the parameter is keyword or regular argument,
    #     whether it is required and what is default value otherwise;
    #   * how parameter is processed: converted and validated from passed
    #     value;
    #   * how param is sent to target API: how it will be called in
    #     the query string and formatted on call.
    #
    #   Note also those things about params:
    #
    #   * as described in {#namespace} and {#endpoint}, setting path template
    #     will implicitly set params. You can rewrite this on implicit
    #     param call, for ex:
    #
    #   ```ruby
    #   endpoint :foo, '/foo/{bar}'
    #   # call-sequence would be foo(bar = nil)
    #
    #   # But you can make it back keyword:
    #   endpoint :foo, '/foo/{bar}' do
    #     param :bar, keyword: true, default: 'test'
    #   end
    #   # call-sequence now is foo(bar: 'test')
    #
    #   # Or make it strictly required
    #   endpoint :foo, '/foo/{bar}/{baz}' do
    #     param :bar, required: true
    #     param :baz, keyword: true, required: true
    #   end
    #   # call-sequence now is foo(bar, baz:)
    #   ```
    #
    #   * param of outer namespace are passed to API on call from inner
    #     namespaces and endpoints, for ex:
    #
    #   ```ruby
    #   namespace :city do
    #     param :city_name
    #
    #     namespace :population do
    #       endpoint :by_year, '/year/{year}'
    #     end
    #   end
    #
    #   # real call:
    #   api.city('London').population.by_year(2015)
    #   # Will get http://api.example.com/city/year/2015?city_name=London
    #   ```
    #
    #   **Works for:** API, namespace, endpoint
    #
    #   @param name [Symbol] Parameter name
    #   @param type [Class, Symbol] Expected parameter type. Could by
    #     some class (then parameter would be checked for being instance
    #     of this class or it would be `ArgumentError`), or duck type
    #     (method name that parameter value should respond to).
    #   @param keyword [true, false] Whether the param will go as a
    #     keyword param to method definition.
    #   @param required [true, false] Whether this param is required.
    #     It will be considered on method definition.
    #   @param opts [Hash] Options
    #   @option opts [Symbol] :field What the field would be called in
    #     API query string (it would be `name` by default).
    #   @option opts [#to_proc] :format How to format this option before
    #     including into URL. By default, it is just `.to_s`.
    #   @option opts [String] :desc Params::Base description. You could do it
    #     multiline and with indents, like {#desc}.
    #   @option opts :default Default value for this param. Would be
    #     rendered in method definition and then passed to target API
    #     _(TODO: in future, there also would be "invisible" params,
    #     that are just passed to target, always the same, as well as
    #     params that aren't passed at all if user gave default value.)_
    #   @option opts [Hash, Array] :enum Whether parameter only accepts
    #     enumerated values. Two forms are accepted:
    #
    #     ```ruby
    #     # array form
    #     param :units, enum: %i[us metric britain]
    #     # parameter accepts only :us, :metric, :britain values, and
    #     # passes them to target API as is
    #
    #     # hash "accepted => passed" form
    #     param :compact, enum: {true => 'gzip', false => nil}
    #     # parameter accepts true or false, on true passes "compact=gzip",
    #     # on false passes nothing.
    #     ```

    # @!method namespace(name, path = nil, &block)
    #   Defines new namespace or updates existing one.
    #
    #   {Namespace} has two roles:
    #
    #   * on Ruby API, defines how you access to the final endpoint,
    #     like `api.namespace1.namespace2(some_param).endpoint(...)`
    #   * on calling API, it adds its path to entire URL.
    #
    #   **NB:** If you call `namespace(:something)` and it was already defined,
    #   current definition will be added to existing one (but it can't
    #   change path of existing one, which is reasonable).
    #
    #   **Works for:** API, namespace
    #
    #   @param name [Symbol] Name of the method by which namespace would
    #     be accessible.
    #   @param path [String] Path to add to API inside this namespace.
    #     When not provided, considered to be `/<name>`. When provided,
    #     taken literally (no slashes or other symbols added). Note, that
    #     you can use `/../` in path, redesigning someone else's APIs on
    #     the fly. Also, you can use [RFC 6570](https://www.rfc-editor.org/rfc/rfc6570.txt)
    #     URL templates to mark params going straightly into URI.
    #
    #     Some examples:
    #
    #     ```ruby
    #     # assuming API base url is http://api.example.com
    #
    #     namespace :foo
    #     # method would be foo(), API URL would be http://api.example.com/foo
    #
    #     namespace :bar, '/foo/bar'
    #     # metod would be bar(), API URL http://api.example.com/foo/bar
    #
    #     namespace :baz, ''
    #     # method baz(), API URL same as base: useful for gathering into
    #     # quazi-namespace from several unrelated endpoints.
    #
    #     namespace :quux, '/foo/quux/{id}'
    #     # method quux(id = nil), API URL http://api.example.com/foo/quux/123
    #     # ...where 123 is what you've passed as id
    #     ```
    #   @param block Definition of current namespace params, and
    #     namespaces and endpoints inside current.
    #     Note that by defining params inside this block, you can change
    #     namespace's method call sequence.
    #
    #     For example:
    #
    #     ```ruby
    #     namespace :foo
    #     # call-sequence: foo()
    #
    #     namespace :foo do
    #       param :bar
    #     end
    #     # call-sequence: foo(bar: nil)
    #
    #     namespace :foo do
    #       param :bar, required: true, keyword: false
    #       param :baz, required: true
    #     end
    #     # call-sequence: foo(bar, baz:)
    #     ```
    #
    #     ...and so on. See also {#param} for understanding what you
    #     can change here.
    #

    # @!method endpoint(name, path = nil, **opts, &block)
    #   Defines new endpoint or updates existing one.
    #
    #   {Endpoint} is the thing doing the real work: providing Ruby API
    #   method to really call target API.
    #
    #   **NB:** If you call `endpoint(:something)` and it was already defined,
    #   current definition will be added to existing one (but it can't
    #   change path of existing one, which is reasonable).
    #
    #   **Works for:** API, namespace
    #
    #   @param name [Symbol] Name of the method by which endpoint would
    #     be accessible.
    #   @param path [String] Path to call API from this endpoint.
    #     When not provided, considered to be `/<name>`. When provided,
    #     taken literally (no slashes or other symbols added). Note, that
    #     you can use `/../` in path, redesigning someone else's APIs on
    #     the fly. Also, you can use [RFC 6570](https://www.rfc-editor.org/rfc/rfc6570.txt)
    #     URL templates to mark params going straightly into URI.
    #
    #     Look at {#namespace} for examples, idea is the same.
    #
    #   @param opts [Hash] Some options, currently only `:xml`.
    #   @option opts [true, false] :xml Whether endpoint's response should
    #     be parsed as XML (JSON otherwise & by default). Parsing in this
    #     case is performed with [crack](https://github.com/jnunemaker/crack),
    #     producing the hash, to which all other rules of post-processing
    #     are applied.
    #   @param block Definition of endpoint's params and docs.
    #     Note that by defining params inside this block, you can change
    #     endpoints's method call sequence.
    #
    #     For example:
    #
    #     ```ruby
    #     endpoint :foo
    #     # call-sequence: foo()
    #
    #     endpoint :foo do
    #       param :bar
    #     end
    #     # call-sequence: foo(bar: nil)
    #
    #     endpoint :foo do
    #       param :bar, required: true, keyword: false
    #       param :baz, required: true
    #     end
    #     # call-sequence: foo(bar, baz:)
    #     ```
    #
    #     ...and so on. See also {#param} for understanding what you
    #     can change here.

    # @!method post_process(key = nil, &block)
    #   Sets post-processors for response.
    #
    #   There are also {#post_process_replace} (for replacing entire
    #   response with something else) and {#post_process_items} (for
    #   post-processing each item of sub-array).
    #
    #   Notes:
    #
    #   * you can set any number of post-processors of any kind, and they
    #     will be applied in exactly the same order they are set;
    #   * you can set post-processors in parent namespace (or for entire
    #     API), in this case post-processors of _outer_ namespace are
    #     always applied before inner ones. That allow you to define some
    #     generic parsing/rewriting on API level, then more specific
    #     key postprocessors on endpoints;
    #   * hashes are flattened again after _each_ post-processor, so if
    #     for some `key` you'll return `{count: 1, continue: false}`,
    #     response hash will immediately have
    #     `{"key.count" => 1, "key.continue" => false}`.
    #
    #   @overload post_process(&block)
    #     Sets post-processor for whole response. Note, that in this case
    #     _return_ value of block is ignored, it is expected that your
    #     block will receive response and modify it inplace, like this:
    #
    #     ```ruby
    #     post_process do |response|
    #       response['coord'] = Geo::Coord.new(response['lat'], response['lng'])
    #     end
    #     ```
    #     If you need to replace entire response with something else,
    #     see {#post_process_replace}
    #
    #   @overload post_process(key, &block)
    #     Sets post-processor for one response key. Post-processor is
    #     called only if key exists in the response, and value by this
    #     key is replaced with post-processor's response.
    #
    #     Note, that if `block` returns `nil`, key will be removed completely.
    #
    #     Usage:
    #
    #     ```ruby
    #     post_process('date') { |val| Date.parse(val) }
    #     # or, btw, just
    #     post_process('date', &Date.method(:parse))
    #     ```
    #
    #     @param key [String]

    # @!method post_process_items(key, &block)
    #   Sets post-processors for each items of array, being at `key` (if
    #   the key is present in response, and if its value is array of
    #   hashes).
    #
    #   Inside `block` you can use {#post_process} method as described
    #   above (but all of its actions will be related only to current
    #   item of array).
    #
    #   Example:
    #
    #   Considering API response like:
    #
    #   ```json
    #   {
    #     "meta": {"count": 100},
    #     "data": [
    #       {"timestamp": "2016-05-01", "value": "10", "dummy": "foo"},
    #       {"timestamp": "2016-05-02", "value": "13", "dummy": "bar"}
    #     ]
    #   }
    #   ```
    #   ...you can define postprocessing like this:
    #
    #   ```ruby
    #   post_process_items 'data' do
    #     post_process 'timestamp', &Date.method(:parse)
    #     post_process 'value', &:to_i
    #     post_process('dummy'){nil} # will be removed
    #   end
    #   ```
    #
    #   See also {#post_process} for some generic explanation of post-processing.
    #
    #   @param key [String]

    # @!method post_process_replace(&block)
    #   Just like {#post_process} for entire response, but _replaces_
    #   it with what block returns.
    #
    #   Real-life usage: WorldBank API typically returns responses this
    #   way:
    #
    #   ```json
    #   [
    #      {"count": 100, "page": 1},
    #      {"some_data_variable": [{}, {}, {}]}
    #   ]
    #   ```
    #   ...e.g. metadata and real response as two items in array, not
    #   two keys in hash. We can easily fix this:
    #
    #   ```ruby
    #   post_process_replace do |response|
    #     {meta: response.first, data: response.last}
    #   end
    #   ```
    #
    #   See also {#post_process} for some generic explanation of post-processing.
  end
end

# require_relative 'dsl/api_wrapper'
# require_relative 'dsl/base_wrapper'
# require_relative 'dsl/endpoint_wrapper'
# require_relative 'dsl/namespace_wrapper'
# require_relative 'dsl/post_process_proxy'


require_relative 'dsl/api_builder'
require_relative 'dsl/base_builder'
require_relative 'dsl/endpoint_builder'
require_relative 'dsl/namespace_builder'
# require_relative 'dsl/post_process_proxy'
