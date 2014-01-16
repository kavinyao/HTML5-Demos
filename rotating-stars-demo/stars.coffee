# config
wrapper_id = 'wrapper'
width = document.documentElement.clientWidth
height = document.documentElement.clientHeight
star_number = Math.floor 0.001 * width * height
show_trails = false
speed = Math.PI / 100000
max_size = 2
fps = 30

class Sky
    # construct a sky of @width by @height
    # set center of ctx properly
    constructor: (@width, @height, @center_x, @center_y, ctx) ->
        diff_x = Math.max @center_x, @width - @center_x
        diff_y = Math.max @center_y, @height - @center_y
        @max_radius = Math.sqrt diff_x*diff_x + diff_y*diff_y
        @update_boundary()

    update_boundary: () ->
        @x_upper = @width - @center_x
        @x_lower = - @center_x
        @y_upper = @height - @center_y
        @y_lower = - @center_y

    # check if a point is in the visible region
    visible: (x, y) ->
        return x >= @x_lower and x <= @x_upper and y >= @y_lower and y <= @y_upper

    clear: (ctx) ->
        ctx.fillStyle = 'black'
        ctx.fillRect @x_lower, @y_lower, @width, @height

    scale: (new_width, new_height, stars) ->
        # compute scale so that the center stays at relatively the same position
        x_scale_factor = new_width / @width
        y_scale_factor = new_height / @height
        r_scale_factor = (Math.sqrt new_width*new_width + new_height*new_height) /
            (Math.sqrt @width*@width + @height*@height)

        @width = new_width
        @height = new_height
        @center_x = @center_x * x_scale_factor
        @center_y = @center_y * y_scale_factor

        @update_boundary()

        star.scale r_scale_factor for star in stars

class Star
    # initial position, rotating speed, brightness (0-1)
    constructor: (@init_angle, @radius, @size, @speed, @max_brightness, @trail) ->
        @bright_offset = Math.random() * 2 * Math.PI
        @r = @g = @b = 255

    setColor: (@r, @g, @b) ->

    draw: (ctx, sky, time_elapsed) ->
        angle = @init_angle + (time_elapsed*@speed) % (2*Math.PI)
        x = @radius * Math.cos angle
        y = - @radius * Math.sin angle

        if not sky.visible x, y
            return

        brightness = ((1+Math.sin(0.001*time_elapsed+@bright_offset)) / 2 + 0.05) * @max_brightness
        # draw star
        # since we gonna change origin and rotate, save context state first
        ctx.save()
        ctx.fillStyle = ctx.strokeStyle = "rgba(#{@r}, #{@g}, #{@b}, #{brightness})"
        ctx.translate x, y
        ctx.rotate angle
        @drawCross(@size)
        brightness = brightness * 0.75
        ctx.fillStyle = ctx.strokeStyle = "rgba(#{@r}, #{@g}, #{@b}, #{brightness})"
        ctx.rotate 0.25*Math.PI
        @drawCross(@size*4/5)
        ctx.restore()

        if not @trail
            return

        # draw star trail
        real_angle = 2 * Math.PI - angle % (2*Math.PI)
        ctx.strokeStyle = "rgba(#{@r}, #{@g}, #{@b}, #{brightness*2/3})"
        ctx.beginPath()
        ctx.lineWidth = @size
        ctx.arc 0, 0, @radius, real_angle, real_angle+Math.PI/4, false
        ctx.stroke()

    scale: (scale_factor) ->
        @radius = @radius * scale_factor

    drawCross: (size) ->
        ctx.beginPath()
        inner_side = size
        outer_side = 2.5 * inner_side
        ctx.moveTo inner_side, 0
        ctx.lineTo outer_side, -outer_side
        ctx.lineTo 0, -inner_side
        ctx.lineTo -outer_side, -outer_side
        ctx.lineTo -inner_side, 0
        ctx.lineTo -outer_side, outer_side
        ctx.lineTo 0, inner_side
        ctx.lineTo outer_side, outer_side
        ctx.fill()


retinafy = (canvas) ->
    # technique from:
    # http://joubert.posterous.com/crisp-html-5-canvas-text-on-mobile-phones-and
    DPR = window.devicePixelRatio
    width = +canvas.getAttribute 'width'
    height = +canvas.getAttribute 'height'
    canvas.style.width = width + 'px'
    canvas.style.height = height + 'px'
    canvas.width = width * DPR
    canvas.height = height * DPR
    canvas.getContext('2d').scale(DPR, DPR)

requestAnimationFrame = window.requestAnimationFrame || window.mozRequestAnimationFrame || window.webkitRequestAnimationFrame || window.msRequestAnimationFrame

div = document.getElementById wrapper_id
canvas = document.createElement 'canvas'
div.appendChild canvas

set_canvas_size = (width, height) ->
    canvas.width = width
    canvas.height = height
    retinafy canvas

set_canvas_size width, height

ctx = canvas.getContext '2d'

random_star = (speed, max_radius, max_size, show_trail) ->
    init_angle = Math.random() * 2 * Math.PI
    radius = Math.random() * max_radius
    size = Math.random() * max_size
    max_brightness = (Math.random()+0.5)/1.5
    s = new Star(init_angle, radius, size, speed, max_brightness, show_trail)

    r = Math.random()
    if r < 0.1
        s.setColor 114, 153, 166
    else if r < 0.4
        s.setColor 148, 131, 116
    else
        s.setColor 242, 254, 255

    return s

center_x = Math.random() * width
center_y = Math.random() * height
sky = new Sky width, height, center_x, center_y, ctx
max_radius = sky.max_radius
stars = (random_star(speed, max_radius, max_size, show_trails) for i in [1..star_number])

set_canvas_origin = () ->
    # always change to new state
    ctx.restore()
    ctx.save()
    # set origin to bottom right corner
    ctx.translate sky.center_x, sky.center_y

set_canvas_origin()

ms_per_frame = 1000 / fps
last_frame = 0

draw_sky = (time_stamp) ->
    if time_stamp - last_frame < ms_per_frame
        requestAnimationFrame draw_sky
        return

    last_frame = time_stamp

    sky.clear ctx
    star.draw ctx, sky, time_stamp for star in stars

    requestAnimationFrame draw_sky

requestAnimationFrame draw_sky

# handle window size change
change_sky = () ->
    width = document.documentElement.clientWidth
    height = document.documentElement.clientHeight

    set_canvas_size  width, height
    sky.scale width, height, stars
    set_canvas_origin()

timeoutID = 0
window.addEventListener 'resize', () ->
    if(timeoutID)
        clearTimeout timeoutID

    timeoutID = setTimeout change_sky, 50

# full screen support
# https://developer.mozilla.org/en-US/docs/Web/Guide/API/DOM/Using_full_screen_mode
# press `f` to toggle full screen
inFullscreen = () ->
    return document.fullscreenElement || document.mozFullScreenElement || document.webkitFullscreenElement || document.msFullscreenElement

enterFullscreen = (elem) ->
    if elem.requestFullscreen
        elem.requestFullscreen()
    else if elem.mozRequestFullScreen
        elem.mozRequestFullScreen()
    else if elem.webkitRequestFullscreen
        elem.webkitRequestFullscreen Element.ALLOW_KEYBOARD_INPUT
    else if elem.msRequestFullscreen
        elem.msRequestFullscreen()

exitFullscreen = () ->
    if document.exitFullscreen
        document.exitFullscreen()
    else if document.mozExitFullscreen
        document.mozExitFullScreen()
    else if document.webkitExitFullScreen
        document.webkitExitFullscreen()
    else if document.msExitFullscreen
        document.msExitFullscreen()

window.addEventListener 'keypress', (e) ->
    key = e.which || e.charCode
    if key == 102
        if inFullscreen()
            exitFullscreen()
        else
            enterFullscreen document.documentElement
