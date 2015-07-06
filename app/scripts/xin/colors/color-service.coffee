app.factory "colorService", ->
  brand_primary = (variation) ->
    get_color get_color_name("brand-primary"), variation
  brand_success = (variation) ->
    get_color get_color_name("brand-success"), variation
  brand_info = (variation) ->
    get_color get_color_name("brand-info"), variation
  brand_warning = (variation) ->
    get_color get_color_name("brand-warning"), variation
  brand_danger = (variation) ->
    get_color get_color_name("brand-danger"), variation
  theme = (variation) ->
    variation = ((if variation then variation else "base"))
    get_color get_color_name("theme"), variation
  theme_secondary = (variation) ->
    variation = ((if variation then variation else "base"))
    get_color get_color_name("theme-secondary")
  get_color_name = (name) ->
    return theme_colors[name]  if theme_colors[name] isnt `undefined`
    global_colors[name]
  get_color = (color, variation) ->
    variation = ((if variation then variation else "base"))
    global_colors[color][variation]
  get_colors = ->
  brand_primary: brand_primary
  brand_success: brand_success
  brand_info: brand_info
  brand_warning: brand_warning
  brand_danger: brand_danger
  theme: theme
  theme_secondary: theme_secondary
  get_color: get_color
