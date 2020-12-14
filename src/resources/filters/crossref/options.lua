-- options.lua
-- Copyright (C) 2020 by RStudio, PBC

-- initialize options from 'crossref' metadata value
function initOptions()
  return {
    Pandoc = function(doc)
      crossref.options = readFilterOptions(doc, "crossref")
    end
  }
end

-- get option value
function option(name, default)
  return readOption(crossref.options, name, default)
end



