-- latex.lua
-- Copyright (C) 2020 by RStudio, PBC


function latexPanel(divEl, subfigures)
  return latexDivFigure(divEl, subfigures)
end

function latexImageFigure(image)
  return renderLatexFigure(image, function(figure)
    
    -- make a copy of the caption and clear it
    local caption = image.caption:clone()
    tclear(image.caption)
    
    -- get align
    local align = alignAttribute(image)
   
    -- insert the figure without the caption
    local figurePara = pandoc.Para({
      pandoc.RawInline("latex", latexBeginAlign(align)),
      image,
      pandoc.RawInline("latex", latexEndAlign(align)),
      pandoc.RawInline("latex", "\n")
    })
    figure.content:insert(figurePara)
    
    -- return the caption inlines
    return caption
    
  end)
end

function latexDivFigure(divEl, subfigures)
  
  return renderLatexFigure(divEl, function(figure)
    
    -- subfigures
    if subfigures then
      local subfiguresEl = pandoc.Para({})
      for i, row in ipairs(subfigures) do
        
        for _, image in ipairs(row) do
          
          -- get alignment
          local align = alignAttribute(image)
   
          
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
            markupLatexCaption(image, caption)
          end
          image.attr.identifier = ""
          
          -- insert content
          subfiguresEl.content:insert(pandoc.RawInline("latex", "\n  "))
          subfiguresEl.content:insert(pandoc.RawInline("latex", latexBeginAlign(align)))
          if image.t == "Div" then
            -- append the div, slicing off the caption block
            tappend(subfiguresEl.content, pandoc.utils.blocks_to_inlines(
              tslice(image.content, 1, #image.content-1),
              { pandoc.LineBreak() }
            ))
          else
            subfiguresEl.content:insert(image)
          end
          subfiguresEl.content:insert(pandoc.RawInline("latex", latexEndAlign(align)))
          subfiguresEl.content:insert(pandoc.RawInline("latex", "\n"))
          
          -- insert caption
          if #caption > 0 then
            subfiguresEl.content:insert(pandoc.RawInline("latex", "  "))
            tappend(subfiguresEl.content, caption)
            subfiguresEl.content:insert(pandoc.RawInline("latex", "\n"))
          end
          
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
    if caption then
      return caption.content
    else
      return nil
    end
  end)
  
end

function renderLatexFigure(el, render)
  
  -- create container
  local figure = pandoc.Div({})
  
  -- begin the figure
  local figEnv = attribute(el, kFigEnv, "figure")
  local figPos = attribute(el, kFigPos, nil)
  
  local beginEnv = "\\begin{" .. figEnv .. "}"
  if figPos then
    if not string.find(figPos, "^%[{") then
      figPos = "[" .. figPos .. "]"
    end
    beginEnv = beginEnv .. figPos
  end
  figure.content:insert(pandoc.RawBlock("latex", beginEnv))
  
  -- fill in the body (returns the caption inlines)
  local captionInlines = render(figure)  

  -- surround caption w/ appropriate latex (and end the figure)
  if captionInlines and #captionInlines > 0 then
    markupLatexCaption(el, captionInlines)
    figure.content:insert(pandoc.Para(captionInlines))
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

function markupLatexCaption(el, caption)
  
  -- caption prefix (includes \\caption macro + optional [subcap] + {)
  local captionPrefix = pandoc.List:new({
    pandoc.RawInline("latex", "\\caption")
  })
  local figScap = attribute(el, kFigScap, nil)
  if figScap then
    captionPrefix:insert(pandoc.RawInline("latex", "["))
    tappend(captionPrefix, markdownToInlines(figScap))
    captionPrefix:insert(pandoc.RawInline("latex", "]"))
  end
  captionPrefix:insert(pandoc.RawInline("latex", "{"))
  tprepend(caption, captionPrefix)
  
  -- end the caption
  caption:insert(pandoc.RawInline("latex", "}"))
  
  -- include a label if this is referenceable
  if isReferenceable(el) then
    caption:insert(pandoc.RawInline("latex", "\\label{" .. el.attr.identifier .. "}"))
  end
end


function latexBeginAlign(align)
  if align == "center" then
    return "{\\centering "
  elseif align == "right" then
    return "\\hfill{} "      
  else
    return ""
  end
end

function latexEndAlign(align)
  if align == "center" then
    return "\n\n}"
  elseif align == "left" then
    return " \\hfill{}"
  else
    return ""
  end
end


