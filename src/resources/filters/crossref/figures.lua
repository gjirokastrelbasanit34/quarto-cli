-- figures.lua
-- Copyright (C) 2020 by RStudio, PBC

-- process all figures
function figures()
  return {
    Div = function(el)
      if isFigureDiv(el) then
        local caption = figureDivCaption(el)
        processFigure(el, caption.content)
      end
      return el
    end,

    Para = function(el)
      local image = figureFromPara(el)
      if image and isFigureImage(image) then
        processFigure(image, image.caption)
      end
      return el
    end
  }
end


-- process a figure, re-writing it's caption as necessary and
-- adding it to the global index of figures
function processFigure(el, captionContent)
  -- get label and base caption
  local label = el.attr.identifier
  local caption = captionContent:clone()

  -- determine order, parent, and displayed caption
  local order
  local parent = el.attr.attributes[kRefParent]
  if (parent) then
    el.attr.attributes[kRefParent] = nil
    order = nextSubrefOrder()
    prependSubrefNumber(captionContent, order)
  else
    order = indexNextOrder("fig")
    if not isLatexOutput() then
      tprepend(captionContent, figureTitlePrefix(order))
    end
  end

  -- update the index
  indexAddEntry(label, parent, order, caption)
end


function figureTitlePrefix(order)
  return titlePrefix("fig", "Figure", order)
end
