#!/usr/bin/env ruby

chapters = {}
chapterHeader = false
chapterNumber = 0
STDIN.each do |line|
    if line.include? '<%'
        line.gsub! '<%', '<%%'
    end
    if line.include? '%>'
        line.gsub! '%>', '%%>'
    end

    if line =~ /^#\s?-+$/                                           # Find chapter header start and end
        if !chapterHeader                                           # Chapter header start
            chapterHeader = true
            chapterNumber += 1
            chapters[chapterNumber] = String.new
        else                                                        # Chapter header end
            chapterHeader = false
        end
        chapters[chapterNumber] << line                             # Chapter name
    else
        if chapterNumber == 1                                       # Not parsing first chapter
            chapters[chapterNumber] << line
        else                                                        # Parsing all other
            if match = /^#(\w+)(\s+)\=(\s+)(.+)/m.match(line)       # Parsing key and part of formating
                key = match[1]
                firstSpace = match[2]
                secondSpace = match[3]
                value = String.new
                restLine = String.new
                tempLineRest = match[4]

                if tempLineRest.instance_of?(String) and tempLineRest.length > 0
                    restMatch = {}
                    if tempLineRest[0] == "'" or tempLineRest[0] == "\""
                        restMatch = /^(['"].*?['"])(\s+.*$)/m.match(tempLineRest)
                    else
                        restMatch = /^(.+?)(\s+.*$)/m.match(tempLineRest)
                    end
                    begin
                        value = restMatch[1]
                        restLine = restMatch[2]
                    rescue
                        print "Could't match [" << tempLineRest << "]"
                        exit 1
                    end
                end

                quot = String.new
                if value =~ /^'/
                    quot = "'"
                end

                chapters[chapterNumber] \
                    << "<% if @postgresql_conf.has_key?('" << key << "') %>" \
                        << key << firstSpace << "=" << secondSpace << quot << "<%= @postgresql_conf['" << key << "'] %>" << quot \
                    << "<% else %>" \
                        << "#" << key << firstSpace << "=" << secondSpace << value \
                    << "<% end %>" \
                    << restLine \
            else
                chapters[chapterNumber] << line
            end
        end
    end
end

chapters.each do |k,v|
    print v
end
