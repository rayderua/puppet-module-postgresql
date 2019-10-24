Facter.add('pg_lsclusters') do
  setcode do
    begin
        clusters = {}
        if File.executable?('/bin/pg_lsclusters')
            result = Facter::Core::Execution.execute("/bin/pg_lsclusters -h", options = {:timeout => 10})
            unless result.nil?
                result.each_line do |line|
                    line.gsub!(/^([0-9\.]+)\s+([0-9a-zA-Z_\.]+)\s+([0-9\.]+)\s+([a-z,]+)\s+.*/) do
                        version = $1
                        cluster = $2
                        port    = $3
                        status  = $4
                        if ! clusters.has_key?("#{version}")
                            clusters[version] = {}
                        end

                        if ! clusters["#{version}"].has_key?("#{cluster}")
                            clusters["#{version}"]["#{cluster}"] = {}
                        end
                        clusters["#{version}"]["#{cluster}"]["port"]    = port
                        clusters["#{version}"]["#{cluster}"]["status"]  = status
                    end
                end
            end
        end
        clusters
    rescue Facter::Core::Execution::ExecutionFailure
        false
    end
  end
end
