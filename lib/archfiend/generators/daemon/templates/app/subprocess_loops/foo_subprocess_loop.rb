# A dummy SubprocessLoop that logs Hello World every 10 seconds, offseted by 5 seconds
class FooSubprocessLoop < Archfiend::SubprocessLoop
  def run
    sleep 5
    super
  end

  def iterate
    msg = "Hello World from #{self.class.name}"
    logger.info(msg)
    sleep 10
  end
end
