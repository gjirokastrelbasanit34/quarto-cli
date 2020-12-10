-- latex.lua
-- Copyright (C) 2020 by RStudio, PBC

function latexFigureDiv(divEl, subfigures)
  
  -- create panel
  local figure = pandoc.Div({})
  
  -- begin the figure
  local figEnv = attribute(divEl, kFigEnv, "figure")
  figure.content:insert(pandoc.RawBlock("latex", "\\begin{" .. figEnv .. "}"))
  
  -- alignment
  local align = attribute(divEl, kFigAlign, nil)
  if align then
    figure.content:insert(pandoc.RawBlock("latex", latexBeginAlign(align)))
  end
  
  -- subfigures
  if subfigures then
    local subfiguresEl = pandoc.Para({})
    for i, row in ipairs(subfigures) do
      
      for _, image in ipairs(row) do
        
        -- begin subfigure
        subfiguresEl.content:insert(pandoc.RawInline("latex", "\\begin{subfigure}[b]"))
         
        -- check to see if it has a width to apply (if so then reset the
        -- underlying width to 100% as sizing will come from subfigure box)
        local layoutPercent = horizontalLayoutPercent(image)
        if layoutPercent then
          image.attr.attributes["width"] = nil
        else
          layoutPercent = 100
        end
        subfiguresEl.content:insert(pandoc.RawInline("latex", 
          "{" .. string.format("%2.2f", layoutPercent/100) .. "\\linewidth}"
        ))
        
        -- see if have a caption (different depending on whether it's an Image or Div)
        local caption = nil
        if image.t == "Image" then
          caption = image.caption:clone()
          tclear(image.caption)
        else 
          caption = figureDivCaption(image).content
        end
        
        -- build caption
        if inlinesToString(caption) ~= "" then
          caption:insert(1, pandoc.RawInline("latex", "\\caption{"))
          if isReferenceable(image) then
            caption:insert(pandoc.RawInline("latex", "\\label{" .. image.attr.identifier .. "}"))
          end
          caption:insert(pandoc.RawInline("latex", "}"))
        end
        image.attr.identifier = ""
        
        -- begin align
        subfiguresEl.content:insert(pandoc.RawInline("latex", latexBeginAlign(align, "  ")))
        
        -- insert content
        subfiguresEl.content:insert(pandoc.RawInline("latex", "\n  "))
        if image.t == "Div" then
          -- append the div, slicing off the caption block
          tappend(subfiguresEl.content, pandoc.utils.blocks_to_inlines(
            tslice(image.content, 1, #image.content-1),
            { pandoc.LineBreak() }
          ))
        else
          subfiguresEl.content:insert(image)
        end
        subfiguresEl.content:insert(pandoc.RawInline("latex", "\n"))
        
        -- insert caption
        if #caption > 0 then
          subfiguresEl.content:insert(pandoc.RawInline("latex", "  "))
          tappend(subfiguresEl.content, caption)
          subfiguresEl.content:insert(pandoc.RawInline("latex", "\n"))
        end
        
        -- end align
        subfiguresEl.content:insert(pandoc.RawInline("latex", latexEndAlign(align, "  ")))
      
        -- end subfigure
        subfiguresEl.content:insert(pandoc.RawInline("latex", "\\end{subfigure}\n"))
        
      end
      
      -- insert separator unless this is the last row
      if i < #subfigures then
        subfiguresEl.content:insert(pandoc.RawInline("latex", "\\newline\n"))
      end
      
    end
    figure.content:insert(subfiguresEl)
  --  no subfigures, just forward content
  else
    tappend(figure.content, tslice(divEl.content, 1, #divEl.content - 1))
  end

  -- surround caption w/ appropriate latex (and end the figure)
  local caption = figureDivCaption(divEl)
  if caption and #caption.content > 0 then
    if isReferenceable(divEl) then
      caption.content:insert(1, pandoc.RawInline("latex", "\\caption{"))
      tappend(caption.content, {
        pandoc.RawInline("latex", "}\\label{" .. divEl.attr.identifier .. "}\n"),
      })
    end
    figure.content:insert(caption)
  end
  
  -- end alignment
  if align then
    figure.content:insert(pandoc.RawBlock("latex", latexEndAlign(align)))
  end
 
  -- end figure
  figure.content:insert(pandoc.RawBlock("latex", "\\end{" .. figEnv .. "}"))
  
  -- return the figure
  return figure
  
end


function isReferenceable(figEl)
  return figEl.attr.identifier ~= "" and 
         not string.find(figEl.attr.identifier, "^fig:anonymous-")
end

function latexBeginAlign(align, spacing)
  if not spacing then
    spacing = ""
  end
  local beginAlign = "\n" .. spacing
  if align == "center" then
    beginAlign = beginAlign .. "{\\centering"
  elseif align == "right" then
    beginAlign = beginAlign .. "\\hfill{}"      
  end
  return beginAlign
end

function latexEndAlign(align, spacing)
  if not spacing then
    spacing = ""
  end
  local endAlign = spacing
  if align == "center" then
    endAlign = endAlign .. "}"
  elseif align == "left" then
    endAlign = endAlign .. "\\hfill{}"
  end
  return endAlign .. "\n"
end


