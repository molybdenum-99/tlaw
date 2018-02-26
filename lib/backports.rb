# Use Ruby 2.5.0 `Object#yield_self` in older versions of Ruby
#
# @private
class Object
  unless respond_to?(:yield_self)
    def yield_self(*args)
      yield self, *args
    end
  end
end
