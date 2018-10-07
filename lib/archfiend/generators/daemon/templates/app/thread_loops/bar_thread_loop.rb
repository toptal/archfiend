# A dummy thread loop that logs Hello World every 5 seconds
class BarThreadLoop < Archfiend::ThreadLoop
  def iterate
    msg = "Hello World from #{self.class.name}"
    logger.info(msg)
    sleep 5
  end
end
