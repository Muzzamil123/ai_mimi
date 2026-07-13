# Base class for service objects. Encapsulates a single unit of business logic
# and is invoked with `MyService.call(...)`. Keeps business logic out of
# controllers and models (SOLID: single responsibility).
class ApplicationService
  def self.call(...)
    new(...).call
  end
end
