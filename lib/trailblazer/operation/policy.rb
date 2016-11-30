class Trailblazer::Operation
  module Policy
    # Step: This generically `call`s a policy and then pushes its result to skills.
    # :private:
    class Eval
      include Uber::Callable

      def initialize(name:, path:)
        @name = name
        @path = path
      end

      def call(input, options)
        condition = options[@path] # this allows dependency injection.
        result    = condition.(options)

        options["policy.#{@name}"]        = result["policy"] # assign the policy as a skill.
        options["result.policy.#{@name}"] = result

        # flow control
        result.success? # since we & this, it's only executed OnRight and the return boolean decides the direction, input is passed straight through.
      end
    end

    # Adds the `yield` result to the pipe and treats it like a policy-compatible object at runtime.
    def self.add!(operation, import, options)
      name = options[:name] || :default

      # configure class level.
      operation[path = "policy.#{name}.eval"] = yield

      # add step.
      import.(:&, Eval.new( name: name, path: path ),
        name: path
      )
    end
  end
end

# how to have more than one policy, and then also replace its interpreter with another ? self.| MyInterpreter, replace: "Policy::Evaluator.after_validate"
