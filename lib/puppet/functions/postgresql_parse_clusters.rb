#
Puppet::Functions.create_function(:'postgresql_parse_clusters') do
    dispatch :parse_clusters do
        param 'Hash', :clusters
    end

    def parse_clusters(clusters)
        result = {}
        ports  = {}
        version = 0
        clusters.each do | name, config |
            if match = /^([0-9\.]+)\/([\w\-]+)\/([0-9]+)$/m.match(name)
                version = match[1]
                cluster = match[2]
                port    = match[3]

                if ! ports.has_key?("#{port}")

                    if ! result.has_key?("#{version}")
                        result[version] = {}
                    end

                    if ! result["#{version}"].has_key?("#{cluster}")
                        result["#{version}"]["#{cluster}"] = { }
                        result["#{version}"]["#{cluster}"] = config
                        result["#{version}"]["#{cluster}"]["port"]   = port
                        if config.has_key?("citus")
                            result["#{version}"]["#{cluster}"]["citus"] = true
                        else
                            result["#{version}"]["#{cluster}"]["citus"] = false
                        end
                    end

                    ports["#{port}"] = true
                end
            end
        end

        result
    end
end
