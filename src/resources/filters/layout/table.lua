-- table.lua
-- Copyright (C) 2020 by RStudio, PBC

function tablePanel(divEl, layout, caption, options)
  
  -- empty options by default
  if not options then
    options = {}
  end
  
  -- create panel
  local panel = pandoc.Div({})
  
  -- alignment
  local align = layoutAlignAttribute(divEl)
  
  -- layout
  for i, row in ipairs(layout) do
    
    local aligns = row:map(function() return layoutTableAlign(align) end)
    local widths = row:map(function(cell) 
      -- propagage percents if they are provided
      local layoutPercent = horizontalLayoutPercent(cell)
      if layoutPercent then
        return layoutPercent / 100
      else
        return 0
      end
    end)

    local cells = pandoc.List:new()
    for _, cell in ipairs(row) do
      cells:insert(tableCellContent(cell, align, options))
    end
    
    -- make the table
    local panelTable = pandoc.SimpleTable(
      pandoc.List:new(), -- caption
      aligns,
      widths,
      pandoc.List:new(), -- headers
      { cells }
    )
    
    -- add it to the panel
    panel.content:insert(pandoc.utils.from_simple_table(panelTable))
    
    -- add empty text frame (to prevent a para from being inserted btw the rows)
    if i ~= #layout and options.rowBreak then
      panel.content:insert(options.rowBreak())
    end
  end
  
  -- insert caption
  if caption then
    if options.divCaption then
      caption = options.divCaption(caption, align)
    end
     panel.content:insert(caption)
  end

  -- return panel
  return panel
end


function tableCellContent(cell, align, options)
  
  -- there will be special code if this an image or table
  local image = figureImageFromLayoutCell(cell)
  local tbl = tableFromLayoutCell(cell)
  local isSubRef = hasRefParent(cell) or (image and hasRefParent(image))
 
  if image then
    -- convert layout percent to physical units (if we have a pageWidth)
    -- this ensures that images don't overflow the column as they have
    -- been observed to do in docx
    if options.pageWidth then
      local layoutPercent = horizontalLayoutPercent(cell)
      if layoutPercent then
        local inches = (layoutPercent/100) * options.pageWidth
        image.attr.attributes["width"] = string.format("%2.2f", inches) .. "in"
      end
    end
    
    -- rtf and odt don't write captions in tables so make this explicit
    if #image.caption > 0 and (isRtfOutput() or isOdtOutput()) then
      local caption = image.caption:clone()
      tclear(image.caption)
      local captionPara = pandoc.Para(caption)
      if options.divCaption then
        captionPara = options.divCaption(captionPara, align)
      end
      cell.content:insert(captionPara)
    end
    
    -- we've already aligned the image in a table cell so prevent 
    -- extended handling as it would create a nested table cell
    preventExtendedFigure(image)
  end
  
  if hasFigureRef(cell) then
    -- style div caption if there is a custom caption function
    if options.divCaption then
      local divCaption = options.divCaption(refCaptionFromDiv(cell), align)
      cell.content[#cell.content] = divCaption 
    end
    
    -- we've already aligned the figure in a table cell so prevent 
    -- extended handling as it would create a nested table cell
    preventExtendedFigure(cell)
  end
  
  if tbl then
    
    -- force widths to occupy 100% (for centering)
    if align == "center" then
      layoutEnsureFullTableWidth(tbl)
    end
    
    -- workaround issue w/ docx nested tables: https://github.com/jgm/pandoc/issues/6983
    if isDocxOutput() then
      cell.content:insert(options.rowBreak())
    end
    
  end
 
  return { cell }
  
end


function layoutTableAlign(align)
  if align == "left" then
    return pandoc.AlignLeft
  elseif align == "center" then
    return pandoc.AlignCenter
  elseif align == "right" then
    return pandoc.AlignRight
  end
end

function layoutEnsureFullTableWidth(tbl)
  if not tbl.colspecs:find_if(function(spec) return spec.width ~= nil end) then
    tbl.colspecs = tbl.colspecs:map(function(spec)
      return { spec[1], (1 / #tbl.colspecs) * 0.98 }
    end)
  end
end


